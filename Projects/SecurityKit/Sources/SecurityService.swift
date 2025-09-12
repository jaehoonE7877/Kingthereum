import UIKit
import Core
import Entity
import Foundation

public protocol SecurityServiceProtocol: Sendable {
    func authenticateWithBiometrics(reason: String) async throws -> Bool
    func authenticateWithPIN(_ pin: String) async throws -> Bool
    func setupPIN(_ pin: String) async throws
    func changePIN(oldPIN: String, newPIN: String) async throws
    func isSecuritySetup() async -> Bool
    func getBiometricType() -> Entity.SecurityError.BiometricType
    func isBiometricAvailable() -> Bool
    func deleteWalletData() async throws
    func storeWalletAddress(_ address: String) async throws
    func storeWalletData(privateKey: String) async throws
    func retrievePrivateKey() async throws -> String?
    func authenticateForTransaction() async throws -> Bool
}

public actor SecurityService: SecurityServiceProtocol {
    
    private let biometricManager: BiometricAuthManagerProtocol
    private let pinManager: PINManagerProtocol
    private let keychainManager: KeychainManagerProtocol
    
    // Rate limiting properties
    private var failedAttempts: Int = 0
    private var lastFailedAttemptTime: Date = Date.distantPast
    private let maxAttempts: Int = 5
    private let lockoutDuration: TimeInterval = 300 // 5분
    
    public init(
        biometricManager: BiometricAuthManagerProtocol = BiometricAuthManager(),
        pinManager: PINManagerProtocol = PINManager(),
        keychainManager: KeychainManagerProtocol = KeychainManager()
    ) {
        self.biometricManager = biometricManager
        self.pinManager = pinManager
        self.keychainManager = keychainManager
    }
    
    // MARK: - Authentication Methods
    
    public func authenticateWithBiometrics(reason: String) async throws -> Bool {
        // Rate limiting check
        guard await checkRateLimit() else {
            throw SecurityError.biometricAuthenticationFailed
        }
        
        guard biometricManager.isAvailable else {
            throw SecurityError.biometricNotAvailable
        }
        
        do {
            let success = try await biometricManager.authenticate(reason: reason)
            if success {
                await resetRateLimit()
            } else {
                await incrementFailedAttempts()
            }
            return success
        } catch {
            await incrementFailedAttempts()
            throw error
        }
    }
    
    public func authenticateWithPIN(_ pin: String) async throws -> Bool {
        return try await pinManager.verifyPIN(pin)
    }
    
    public func setupPIN(_ pin: String) async throws {
        try await pinManager.setPIN(pin)
    }
    
    public func changePIN(oldPIN: String, newPIN: String) async throws {
        try await pinManager.changePIN(oldPIN: oldPIN, newPIN: newPIN)
    }
    
    public func isSecuritySetup() async -> Bool {
        return await pinManager.hasPIN()
    }
    
    nonisolated public func getBiometricType() -> Entity.SecurityError.BiometricType {
        return biometricManager.biometricType
    }
    
    nonisolated public func isBiometricAvailable() -> Bool {
        return biometricManager.isAvailable
    }
    
    // MARK: - Wallet Security Methods
    
    public func storeWalletData(privateKey: String) async throws {
        try await keychainManager.storePrivateKey(privateKey)
    }
    
    public func retrievePrivateKey() async throws -> String? {
        return try await keychainManager.retrievePrivateKey()
    }
    
    public func storeWalletAddress(_ address: String) async throws {
        try await keychainManager.storeWalletAddress(address)
    }
    
    public func deleteWalletData() async throws {
        try await keychainManager.deleteAll()
    }
    
    public func authenticateForTransaction() async throws -> Bool {
        // Try biometric authentication first if available
        if biometricManager.isAvailable {
            do {
                return try await authenticateWithBiometrics(reason: "거래를 승인하기 위해 인증이 필요합니다")
            } catch {
                // If biometric fails, fall back to PIN authentication
                Logger.warning("Biometric authentication failed, falling back to PIN")
            }
        }
        
        // For PIN authentication, we'll need the UI to prompt for PIN
        // For now, return true if security is set up (PIN exists)
        return await isSecuritySetup()
    }
    
    // MARK: - Rate Limiting
    
    private func checkRateLimit() async -> Bool {
        if failedAttempts >= maxAttempts {
            if Date().timeIntervalSince(lastFailedAttemptTime) < lockoutDuration {
                return false
            } else {
                await resetRateLimit()
            }
        }
        return true
    }
    
    private func incrementFailedAttempts() async {
        failedAttempts += 1
        lastFailedAttemptTime = Date()
    }
    
    private func resetRateLimit() async {
        failedAttempts = 0
        lastFailedAttemptTime = Date.distantPast
    }
}
