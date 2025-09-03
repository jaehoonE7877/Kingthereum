import Foundation
import BigInt

import Core
import Entity
import SecurityKit

import web3swift
import Web3Core

public struct WalletCreationResult: Sendable {
    public let wallet: Wallet
    public let privateKey: String // 보안 강화: 실제 개인키가 아닌 키 참조 (keyTag)
    public let mnemonic: String?
    public let keyTag: String? // 안전한 키 참조 식별자
    
    public init(wallet: Wallet, privateKey: String, mnemonic: String? = nil, keyTag: String? = nil) {
        self.wallet = wallet
        self.privateKey = privateKey
        self.mnemonic = mnemonic
        self.keyTag = keyTag
    }
}

// Internal protocol for WalletService specific methods
public protocol WalletServiceImplementation: Sendable {
    func createWallet(name: String) async throws -> WalletCreationResult
    func createWalletWithMnemonic(name: String) async throws -> WalletCreationResult
    func importWalletFromMnemonic(name: String, mnemonic: String) async throws -> WalletCreationResult
    func restoreWallet(privateKey: String) async throws -> Wallet
    func importWallet(name: String, mnemonic: String) async throws -> Wallet
    func importWallet(name: String, privateKey: String) async throws -> Wallet
    func getWalletBalance(address: String) async throws -> String
    func getTokenBalances(address: String, tokenAddresses: [String]) async throws -> [TokenBalance]
    func sendETH(from: String, to: String, amount: String, gasPrice: String?, gasLimit: String?) async throws -> String
    func sendToken(contractAddress: String, from: String, to: String, amount: String, gasPrice: String?, gasLimit: String?) async throws -> String
    func estimateGas(from: String, to: String, amount: String, isToken: Bool, contractAddress: String?) async throws -> String
    func getCurrentGasPrice() async throws -> String
    func getTransactionHistory(address: String) async throws -> [Transaction]
}

public actor WalletService: WalletServiceImplementation, WalletServiceProtocol {
    
    public static var shared: WalletService?
    
    private let ethereumWorker: EthereumWorkerProtocol
    private let secureKeyManager: SecureKeyManager
    private var accountAddress: String?
    
    public init(rpcURL: String) throws {
        self.ethereumWorker = try EthereumWorker(rpcURL: rpcURL)
        self.secureKeyManager = SecureKeyManager()
    }
    
    public static func initialize(rpcURL: String) throws -> WalletService {
        if let existing = shared {
            Logger.debug("✅ WalletService already initialized, reusing existing instance")
            return existing
        }
        
        let newService = try WalletService(rpcURL: rpcURL)
        shared = newService
        Logger.debug("✅ WalletService initialized successfully")
        return newService
    }
    
    public func createWallet(name: String) async throws -> WalletCreationResult {
        Logger.debug("🔐 안전한 지갑 생성 시작: \(name)")
        
        // 1. 안전한 개인키 생성 (Secure Enclave 또는 암호화된 Keychain)
        let keyTag = "wallet_\(UUID().uuidString)"
        let secureKeyRef = try await secureKeyManager.generatePrivateKey(
            tag: keyTag,
            options: .default
        )
        
        // 2. 공개키로부터 이더리움 주소 생성
        let ethereumAddress = try deriveEthereumAddress(from: secureKeyRef.publicKeyData)
        
        // 3. 지갑 주소 설정
        self.accountAddress = ethereumAddress
        
        Logger.debug("✅ 안전한 지갑 생성 완료: \(ethereumAddress)")
        
        let wallet = Wallet(
            name: name,
            address: ethereumAddress
        )
        
        // 개인키는 더 이상 평문으로 반환하지 않음 (보안 강화)
        // 필요시 keyTag를 통해 안전하게 접근
        return WalletCreationResult(
            wallet: wallet, 
            privateKey: keyTag, // 키 참조로 변경
            keyTag: keyTag
        )
    }
    
    public func createWalletWithMnemonic(name: String) async throws -> WalletCreationResult {
        // 1. 12단어 니모닉 생성 (128 비트 엔트로피)
        guard let mnemonic = try? BIP39.generateMnemonics(bitsOfEntropy: 128) else {
            throw WalletError.walletCreationFailed
        }
        
        // 2. 니모닉으로 지갑 생성
        let securePassword = try generateSecurePassword()
        guard let keystore = try? BIP32Keystore(
            mnemonics: mnemonic,
            password: securePassword,
            mnemonicsPassword: "",
            language: .english
        ) else {
            throw WalletError.walletCreationFailed
        }
        
        guard let address = keystore.addresses?.first else {
            throw WalletError.walletCreationFailed
        }
        
        // 3. 안전한 개인키 추출 및 보관
        let keyTag = "wallet_mnemonic_\(UUID().uuidString)"
        try await storeWalletSecurely(keystore: keystore, password: securePassword, keyTag: keyTag)
        
        self.accountAddress = address.address
        
        let wallet = Wallet(
            name: name,
            address: address.address
        )
        
        return WalletCreationResult(
            wallet: wallet,
            privateKey: keyTag, // 키 참조로 변경
            mnemonic: mnemonic,
            keyTag: keyTag
        )
    }
    
    public func importWalletFromMnemonic(name: String, mnemonic: String) async throws -> WalletCreationResult {
        // 1. 니모닉 유효성 검증
        let trimmedMnemonic = mnemonic.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 2. 니모닉으로 지갑 복원
        let securePassword = try generateSecurePassword()
        guard let keystore = try? BIP32Keystore(
            mnemonics: trimmedMnemonic,
            password: securePassword,
            mnemonicsPassword: "",
            language: .english
        ) else {
            throw WalletError.invalidMnemonic
        }
        
        guard let address = keystore.addresses?.first else {
            throw WalletError.walletCreationFailed
        }
        
        // 3. 안전한 개인키 추출 및 보관
        let keyTag = "wallet_import_\(UUID().uuidString)"
        try await storeWalletSecurely(keystore: keystore, password: securePassword, keyTag: keyTag)
        
        self.accountAddress = address.address
        
        let wallet = Wallet(
            name: name,
            address: address.address
        )
        
        return WalletCreationResult(
            wallet: wallet,
            privateKey: keyTag, // 키 참조로 변경
            mnemonic: trimmedMnemonic,
            keyTag: keyTag
        )
    }
    
    /// 지갑을 개인키로 복원 (보안 강화)
    public func restoreWallet(privateKey: String) async throws -> Wallet {
        Logger.debug("🔄 개인키로 지갑 복원 시작")
        
        // 개인키 데이터 검증
        guard let privateKeyData = Data(hex: privateKey) else {
            throw WalletError.invalidPrivateKey
        }
        
        // 안전한 비밀번호 생성
        let securePassword = try generateSecurePassword()
        
        // 안전한 keystore 생성
        guard let keystore = try? EthereumKeystoreV3(privateKey: privateKeyData, password: securePassword) else {
            throw WalletError.walletCreationFailed
        }
        
        guard let address = keystore.addresses?.first else {
            throw WalletError.walletCreationFailed
        }
        
        // 안전한 키 저장
        let keyTag = "wallet_restore_\(UUID().uuidString)"
        try await storeWalletSecurely(keystore: keystore, password: securePassword, keyTag: keyTag)
        
        // 메모리에서 개인키 데이터 즉시 제거
        privateKeyData.withUnsafeMutableBytes { bytes in
            bytes.bindMemory(to: UInt8.self).initialize(repeating: 0)
        }
        
        self.accountAddress = address.address
        
        Logger.debug("✅ 지갑 복원 완료: \(address.address)")
        
        return Wallet(
            name: "Restored Wallet",
            address: address.address
        )
    }
    
    public func importWallet(name: String, mnemonic: String) async throws -> Wallet {
        // 기존 구현된 importWalletFromMnemonic 함수 활용
        let result = try await importWalletFromMnemonic(name: name, mnemonic: mnemonic)
        return result.wallet
    }
    
    public func importWallet(name: String, privateKey: String) async throws -> Wallet {
        // 기존 구현된 restoreWallet 함수 활용
        return try await restoreWallet(privateKey: privateKey)
    }
    
    public func getWalletBalance(address: String) async throws -> String {
        return try await ethereumWorker.getBalance(for: address)
    }
    
    public func getTokenBalances(address: String, tokenAddresses: [String]) async throws -> [TokenBalance] {
        // TokenWorker 제거로 인해 빈 배열 반환
        return []
    }
    
    public func sendETH(
        from: String,
        to: String,
        amount: String,
        gasPrice: String?,
        gasLimit: String?
    ) async throws -> String {
        return try await ethereumWorker.sendTransaction(
            from: from,
            to: to,
            value: amount,
            gasPrice: gasPrice,
            gasLimit: gasLimit
        )
    }
    
    public func sendToken(
        contractAddress: String,
        from: String,
        to: String,
        amount: String,
        gasPrice: String?,
        gasLimit: String?
    ) async throws -> String {
        // TokenWorker 제거로 인해 에러 던짐
        throw WalletError.transactionFailed
    }
    
    public func estimateGas(
        from: String,
        to: String,
        amount: String,
        isToken: Bool,
        contractAddress: String?
    ) async throws -> String {
        if isToken, let _ = contractAddress {
            return "100000"
        } else {
            return try await ethereumWorker.estimateGas(from: from, to: to, value: amount)
        }
    }
    
    public func getCurrentGasPrice() async throws -> String {
        return try await ethereumWorker.getCurrentGasPrice()
    }
    
    public func getTransactionHistory(address: String) async throws -> [Transaction] {
        return []
    }
}

// MARK: - WalletServiceProtocol Implementation
extension WalletService {
    
    public func getCurrentWalletAddress() async throws -> String {
        guard let address = accountAddress else {
            throw WalletError.noWalletFound
        }
        return address
    }
    
    public func getBalance(for address: String) async throws -> String {
        return try await getWalletBalance(address: address)
    }
    
    public func getBalanceInWei(for address: String) async throws -> String {
        return try await ethereumWorker.getBalanceInWei(for: address)
    }
    
    public func sendTransaction(
        to: String,
        amount: String,
        gasPrice: String?,
        gasLimit: String?
    ) async throws -> String {
        guard let from = accountAddress else {
            throw WalletError.noWalletFound
        }
        return try await sendETH(from: from, to: to, amount: amount, gasPrice: gasPrice, gasLimit: gasLimit)
    }
    
    public func estimateGas(to: String, amount: String) async throws -> GasEstimate {
        guard let from = accountAddress else {
            throw WalletError.noWalletFound
        }
        return try await estimateGasFee(from: from, to: to, amount: amount)
    }
    
    private func estimateGasFee(from: String, to: String, amount: String) async throws -> GasEstimate {
        let gasLimit = try await ethereumWorker.estimateGas(from: from, to: to, value: amount)
        let gasPrice = try await ethereumWorker.getCurrentGasPrice()
        
        return GasEstimate(
            gasLimit: gasLimit,
            gasPrice: gasPrice
        )
    }
    
    public func getTransactionStatus(transactionHash: String) async throws -> TransactionStatus {
        // 실제 구현 시 트랜잭션 상태를 확인하는 로직 추가
        return .confirmed
    }
    
    public nonisolated func isValidEthereumAddress(_ address: String) -> Bool {
        // 이더리움 주소 패턴 직접 검증 (간단한 검증)
        let pattern = "^0x[a-fA-F0-9]{40}$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: address.count)
        return regex?.firstMatch(in: address, range: range) != nil
    }
    
    public nonisolated func toChecksumAddress(_ address: String) throws -> String {
        // 기본적인 체크섬 구현 (실제로는 Keccak256 해싱이 필요)
        return address.lowercased()
    }
    
    // MARK: - 보안 유틸리티 함수들
    
    /// 암호학적으로 안전한 비밀번호 생성
    /// SecRandomCopyBytes를 사용하여 예측 불가능한 비밀번호 생성
    private func generateSecurePassword() throws -> String {
        Logger.debug("🔐 안전한 비밀번호 생성 중...")
        
        var randomBytes = Data(count: 32) // 256비트 랜덤 데이터
        let result = randomBytes.withUnsafeMutableBytes { bytes in
            // 안전한 포인터 접근
            guard let baseAddress = bytes.bindMemory(to: UInt8.self).baseAddress else {
                Logger.error("❌ 메모리 포인터 접근 실패")
                return errSecParam // 파라미터 에러 반환
            }
            return SecRandomCopyBytes(kSecRandomDefault, 32, baseAddress)
        }
        
        guard result == errSecSuccess else {
            Logger.error("❌ 안전한 랜덤 데이터 생성 실패")
            throw WalletError.networkError // 적절한 에러 타입으로 변경 예정
        }
        
        // Base64로 인코딩하여 문자열로 변환
        let securePassword = randomBytes.base64EncodedString()
        Logger.debug("✅ 안전한 비밀번호 생성 완료")
        
        return securePassword
    }
    
    /// 공개키로부터 이더리움 주소 유도
    /// - Parameter publicKeyData: 공개키 데이터
    /// - Returns: 이더리움 주소 (0x 형식)
    private func deriveEthereumAddress(from publicKeyData: Data) throws -> String {
        Logger.debug("🔢 공개키로부터 이더리움 주소 유도 중...")
        
        // 실제 구현에서는 secp256k1 공개키를 Keccak-256으로 해싱하여 주소 생성
        // 여기서는 임시 구현 (추후 web3swift의 PublicKey 클래스 사용)
        
        // 임시 주소 생성 (실제로는 공개키 해싱 필요)
        let tempAddress = "0x" + publicKeyData.prefix(20).map { String(format: "%02x", $0) }.joined()
        
        Logger.debug("✅ 이더리움 주소 유도 완료: \(tempAddress)")
        return tempAddress
    }
    
    /// keystore를 안전하게 저장
    /// - Parameters:
    ///   - keystore: 저장할 keystore
    ///   - password: keystore 비밀번호
    ///   - keyTag: 키 식별자
    private func storeWalletSecurely(
        keystore: AbstractKeystore, 
        password: String, 
        keyTag: String
    ) async throws {
        Logger.debug("💾 Keystore 안전 저장 시작: \(keyTag)")
        
        // keystore JSON 데이터 생성
        guard let keystoreData = try? keystore.serialize() else {
            throw WalletError.walletCreationFailed
        }
        
        // Keychain에 암호화된 상태로 저장
        let keystoreQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: "com.kingthereum.keystores",
            kSecAttrAccount: keyTag,
            kSecValueData: keystoreData,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let keystoreStatus = SecItemAdd(keystoreQuery as CFDictionary, nil)
        guard keystoreStatus == errSecSuccess else {
            Logger.error("❌ Keystore 저장 실패: \(keystoreStatus)")
            throw WalletError.keychainError
        }
        
        // 비밀번호도 별도로 안전하게 저장
        let passwordQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: "com.kingthereum.passwords",
            kSecAttrAccount: keyTag,
            kSecValueData: {
                guard let data = password.data(using: .utf8) else {
                    Logger.error("❌ 비밀번호를 UTF-8 데이터로 변환 실패")
                    return Data() // 빈 데이터 fallback
                }
                return data
            }(),
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let passwordStatus = SecItemAdd(passwordQuery as CFDictionary, nil)
        guard passwordStatus == errSecSuccess else {
            // Keystore 저장 실패 시 이미 저장된 keystore도 삭제
            _ = SecItemDelete(keystoreQuery as CFDictionary)
            Logger.error("❌ 비밀번호 저장 실패: \(passwordStatus)")
            throw WalletError.keychainError
        }
        
        Logger.debug("✅ Keystore 및 비밀번호 안전 저장 완료")
    }
    
    /// 안전하게 저장된 keystore 불러오기
    /// - Parameter keyTag: 키 식별자
    /// - Returns: (keystore, password) 튜플
    private func retrieveWalletSecurely(keyTag: String) async throws -> (AbstractKeystore, String) {
        Logger.debug("📥 안전한 Keystore 불러오기 시작: \(keyTag)")
        
        // Keystore 데이터 가져오기
        let keystoreQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: "com.kingthereum.keystores",
            kSecAttrAccount: keyTag,
            kSecReturnData: true
        ]
        
        var keystoreItem: CFTypeRef?
        let keystoreStatus = SecItemCopyMatching(keystoreQuery as CFDictionary, &keystoreItem)
        
        guard keystoreStatus == errSecSuccess,
              let keystoreData = keystoreItem as? Data else {
            Logger.error("❌ Keystore를 찾을 수 없음: \(keyTag)")
            throw WalletError.noWalletFound
        }
        
        // 비밀번호 가져오기
        let passwordQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: "com.kingthereum.passwords",
            kSecAttrAccount: keyTag,
            kSecReturnData: true
        ]
        
        var passwordItem: CFTypeRef?
        let passwordStatus = SecItemCopyMatching(passwordQuery as CFDictionary, &passwordItem)
        
        guard passwordStatus == errSecSuccess,
              let passwordData = passwordItem as? Data,
              let password = String(data: passwordData, encoding: .utf8) else {
            Logger.error("❌ 비밀번호를 찾을 수 없음: \(keyTag)")
            throw WalletError.noWalletFound
        }
        
        // Keystore 역직렬화
        guard let keystore = try? AbstractKeystore.deserialize(keystoreData) else {
            Logger.error("❌ Keystore 역직렬화 실패")
            throw WalletError.walletCreationFailed
        }
        
        Logger.debug("✅ 안전한 Keystore 불러오기 완료")
        return (keystore, password)
    }
}

