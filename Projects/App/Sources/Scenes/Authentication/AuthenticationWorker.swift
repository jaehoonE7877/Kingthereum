import Foundation
import Core
import Entity
import SecurityKit
import WalletKit

actor AuthenticationWorker {
    private let securityService: SecurityServiceProtocol
    private var walletService: WalletService?
    private let maxRetryAttempts = 3
    
    init(securityService: SecurityServiceProtocol = SecurityService()) {
        self.securityService = securityService
        
        // 초기화 시 WalletService 설정 시도
        Task {
            await initializeWalletService()
        }
    }
    
    /// WalletService 초기화 (재시도 로직 포함)
    private func initializeWalletService() async {
        for attempt in 1...maxRetryAttempts {
            do {
                // 싱글톤 WalletService 사용
                self.walletService = try WalletService.initialize(rpcURL: Network.ethereum.rpcURL)
                Logger.debug("✅ WalletService initialized successfully on attempt \(attempt)")
                return
            } catch {
                Logger.debug("❌ WalletService initialization failed (attempt \(attempt)/\(maxRetryAttempts)): \(error)")
                
                if attempt < maxRetryAttempts {
                    // 지수 백오프로 재시도 간격 증가
                    let delay = TimeInterval(attempt * attempt) // 1, 4, 9 seconds
                    try? await Task.sleep(for: .seconds(delay))
                }
            }
        }
        
        Logger.error("Failed to initialize WalletService after \(maxRetryAttempts) attempts")
        self.walletService = nil
    }
    
    /// WalletService가 필요한 작업 전 가용성 확인
    private func ensureWalletService() async throws -> WalletService {
        if let walletService = walletService {
            return walletService
        }
        
        // 재초기화 시도
        await initializeWalletService()
        
        guard let walletService = walletService else {
            throw SecurityError.noSecuritySetup
        }
        
        return walletService
    }
    
    func setupPIN(_ pin: String) async throws {
        try await securityService.setupPIN(pin)
    }
    
    func authenticateWithBiometrics(reason: String) async throws -> Bool {
        return try await securityService.authenticateWithBiometrics(reason: reason)
    }
    
    func authenticateWithPIN(_ pin: String) async throws -> Bool {
        return try await securityService.authenticateWithPIN(pin)
    }
    
    func isBiometricAvailable() -> Bool {
        return securityService.isBiometricAvailable()
    }
    
    func getBiometricType() -> BiometricType {
        return securityService.getBiometricType()
    }
    
    func createWallet(name: String) async throws -> Wallet {
        // 1. WalletService 가용성 확인
        let walletService = try await ensureWalletService()
        
        // 2. 새 지갑 생성 (개인키만)
        let result = try await walletService.createWallet(name: name)
        
        // 3. 개인키를 키체인에 안전하게 저장
        try await securityService.storeWalletData(privateKey: result.privateKey)
        
        // 4. 지갑 주소 저장
        try await securityService.storeWalletAddress(result.wallet.address)
        
        // 5. UserDefaults에 지갑 정보 저장
        UserDefaults.standard.set(result.wallet.address, forKey: Constants.UserDefaults.selectedWalletAddress)
        UserDefaults.standard.set(true, forKey: Constants.UserDefaults.hasCompletedOnboarding)
        
        return result.wallet
    }
    
    func createWalletWithMnemonic(name: String) async throws -> (wallet: Wallet, mnemonic: String) {
        // 1. WalletService 가용성 확인
        let walletService = try await ensureWalletService()
        
        // 2. 니모닉과 함께 새 지갑 생성
        let result = try await walletService.createWalletWithMnemonic(name: name)
        
        // 3. 개인키를 키체인에 안전하게 저장 (니모닉은 저장하지 않음)
        try await securityService.storeWalletData(privateKey: result.privateKey)
        
        // 4. 지갑 주소 저장
        try await securityService.storeWalletAddress(result.wallet.address)
        
        // 5. UserDefaults에 지갑 정보 저장
        UserDefaults.standard.set(result.wallet.address, forKey: Constants.UserDefaults.selectedWalletAddress)
        UserDefaults.standard.set(true, forKey: Constants.UserDefaults.hasCompletedOnboarding)
        
        return (wallet: result.wallet, mnemonic: result.mnemonic ?? "")
    }
    
    func importWalletFromMnemonic(name: String, mnemonic: String) async throws -> Wallet {
        // 1. WalletService 가용성 확인
        let walletService = try await ensureWalletService()
        
        // 2. 니모닉으로 지갑 복원
        let result = try await walletService.importWalletFromMnemonic(name: name, mnemonic: mnemonic)
        
        // 3. 개인키를 키체인에 안전하게 저장 (니모닉은 저장하지 않음)
        try await securityService.storeWalletData(privateKey: result.privateKey)
        
        // 4. 지갑 주소 저장
        try await securityService.storeWalletAddress(result.wallet.address)
        
        // 5. UserDefaults에 지갑 정보 저장
        UserDefaults.standard.set(result.wallet.address, forKey: Constants.UserDefaults.selectedWalletAddress)
        UserDefaults.standard.set(true, forKey: Constants.UserDefaults.hasCompletedOnboarding)
        
        return result.wallet
    }
    
    /// 로그인 시 기존 지갑을 복원
    func restoreExistingWallet() async throws -> Wallet? {
        // 저장된 지갑 주소 확인
        guard let walletAddress = UserDefaults.standard.string(forKey: Constants.UserDefaults.selectedWalletAddress) else {
            return nil
        }
        
        // 키체인에서 개인키 복원
        guard let privateKey = try await securityService.retrievePrivateKey() else {
            throw WalletError.privateKeyExtractionFailed
        }
        
        // 개인키로 지갑 복원 (WalletService 가용성 확인)
        let walletService = try await ensureWalletService()
        
        let restoredWallet = try await walletService.restoreWallet(privateKey: privateKey)
        
        // 주소가 일치하는지 확인
        guard restoredWallet.address.lowercased() == walletAddress.lowercased() else {
            throw WalletError.invalidAddress
        }
        
        return restoredWallet
    }
    
}
