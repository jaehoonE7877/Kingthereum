import Foundation
import BigInt

import Core
import Entity

import web3swift
import Web3Core

public struct WalletCreationResult: Sendable {
    public let wallet: Wallet
    public let privateKey: String
    public let mnemonic: String?
    
    public init(wallet: Wallet, privateKey: String, mnemonic: String? = nil) {
        self.wallet = wallet
        self.privateKey = privateKey
        self.mnemonic = mnemonic
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
    private var accountAddress: String?
    
    public init(rpcURL: String) throws {
        self.ethereumWorker = try EthereumWorker(rpcURL: rpcURL)
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
        // 기존 방식: 개인키만 생성
        let password = UUID().uuidString
        guard let keystore = try EthereumKeystoreV3(password: password) else {
            throw WalletError.walletCreationFailed
        }
        
        guard let address = keystore.addresses?.first else {
            throw WalletError.walletCreationFailed
        }
        
        let privateKeyData = try keystore.UNSAFE_getPrivateKeyData(password: password, account: address)
        let privateKeyHex = privateKeyData.toHexString()
        
        self.accountAddress = address.address
        
        let wallet = Wallet(
            name: name,
            address: address.address
        )
        
        return WalletCreationResult(wallet: wallet, privateKey: privateKeyHex)
    }
    
    public func createWalletWithMnemonic(name: String) async throws -> WalletCreationResult {
        // 1. 12단어 니모닉 생성 (128 비트 엔트로피)
        guard let mnemonic = try? BIP39.generateMnemonics(bitsOfEntropy: 128) else {
            throw WalletError.walletCreationFailed
        }
        
        // 2. 니모닉으로 지갑 생성
        let password = UUID().uuidString
        guard let keystore = try? BIP32Keystore(
            mnemonics: mnemonic,
            password: password,
            mnemonicsPassword: "",
            language: .english
        ) else {
            throw WalletError.walletCreationFailed
        }
        
        guard let address = keystore.addresses?.first else {
            throw WalletError.walletCreationFailed
        }
        
        // 3. 개인키 추출 (필요시)
        let privateKeyData = try keystore.UNSAFE_getPrivateKeyData(password: password, account: address)
        let privateKeyHex = privateKeyData.toHexString()
        
        self.accountAddress = address.address
        
        let wallet = Wallet(
            name: name,
            address: address.address
        )
        
        return WalletCreationResult(
            wallet: wallet,
            privateKey: privateKeyHex,
            mnemonic: mnemonic
        )
    }
    
    public func importWalletFromMnemonic(name: String, mnemonic: String) async throws -> WalletCreationResult {
        // 1. 니모닉 유효성 검증
        let trimmedMnemonic = mnemonic.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 2. 니모닉으로 지갑 복원
        let password = UUID().uuidString
        guard let keystore = try? BIP32Keystore(
            mnemonics: trimmedMnemonic,
            password: password,
            mnemonicsPassword: "",
            language: .english
        ) else {
            throw WalletError.invalidMnemonic
        }
        
        guard let address = keystore.addresses?.first else {
            throw WalletError.walletCreationFailed
        }
        
        // 3. 개인키 추출
        let privateKeyData = try keystore.UNSAFE_getPrivateKeyData(password: password, account: address)
        let privateKeyHex = privateKeyData.toHexString()
        
        self.accountAddress = address.address
        
        let wallet = Wallet(
            name: name,
            address: address.address
        )
        
        return WalletCreationResult(
            wallet: wallet,
            privateKey: privateKeyHex,
            mnemonic: trimmedMnemonic
        )
    }
    
    /// 지갑을 개인키로 복원
    public func restoreWallet(privateKey: String) async throws -> Wallet {
        // 개인키로부터 지갑 복원
        guard let privateKeyData = Data(hex: privateKey) else {
            throw WalletError.invalidPrivateKey
        }
        
        // web3swift로 개인키에서 주소 생성
        let password = UUID().uuidString
        guard let keystore = try? EthereumKeystoreV3(privateKey: privateKeyData, password: password) else {
            throw WalletError.walletCreationFailed
        }
        
        guard let address = keystore.addresses?.first else {
            throw WalletError.walletCreationFailed
        }
        
        self.accountAddress = address.address
        
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
}

