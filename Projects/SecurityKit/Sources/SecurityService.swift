import Foundation

import Core
import Entity

public protocol SecurityServiceProtocol: Sendable {
    func authenticateWithBiometrics(reason: String) async throws -> Bool
    func authenticateWithPIN(_ pin: String) async throws -> Bool
    func setupPIN(_ pin: String) async throws
    func changePIN(oldPIN: String, newPIN: String) async throws
    func isSecuritySetup() async -> Bool
    func getBiometricType() -> BiometricType
    func isBiometricAvailable() -> Bool
    func deleteWalletData() async throws
    func storeWalletAddress(_ address: String) async throws
    func storeWalletData(privateKey: String) async throws
    func retrievePrivateKey() async throws -> String?
}

public actor SecurityService: SecurityServiceProtocol {
    
    private let biometricManager: BiometricAuthManagerProtocol
    private let pinManager: PINManagerProtocol
    private let keychainManager: KeychainManagerProtocol
    
    public init(
        biometricManager: BiometricAuthManagerProtocol = BiometricAuthManager(),
        pinManager: PINManagerProtocol = PINManager(),
        keychainManager: KeychainManagerProtocol = KeychainManager()
    ) {
        self.biometricManager = biometricManager
        self.pinManager = pinManager
        self.keychainManager = keychainManager
    }
    
    public func authenticateWithBiometrics(reason: String) async throws -> Bool {
        guard biometricManager.isAvailable else {
            throw BiometricError.notAvailable
        }
        
        return try await biometricManager.authenticate(reason: reason)
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
    
    nonisolated public func getBiometricType() -> BiometricType {
        return biometricManager.biometricType
    }
    
    nonisolated public func isBiometricAvailable() -> Bool {
        return biometricManager.isAvailable
    }
}

// MARK: - Wallet Security Methods
public extension SecurityService {
    
    func storeWalletData(privateKey: String) async throws {
        try await keychainManager.storePrivateKey(privateKey)
    }
    
    func retrievePrivateKey() async throws -> String? {
        return try await keychainManager.retrievePrivateKey()
    }
    
    
    func deleteWalletData() async throws {
        try await keychainManager.deletePrivateKey()
        try await pinManager.deletePIN()
    }
    
    func storeWalletAddress(_ address: String) async throws {
        // Store wallet address in keychain for security
        try await keychainManager.storeWalletAddress(address)
    }
    
    func authenticateForWalletAccess(reason: String = "Access your wallet") async throws -> Bool {
        if isBiometricAvailable() {
            do {
                return try await authenticateWithBiometrics(reason: reason)
            } catch {
                if await pinManager.hasPIN() {
                    throw SecurityError.biometricFailedPINRequired
                } else {
                    throw error
                }
            }
        } else if await pinManager.hasPIN() {
            throw SecurityError.pinRequired
        } else {
            throw SecurityError.noSecuritySetup
        }
    }
}

public enum SecurityError: LocalizedError {
    case biometricFailedPINRequired
    case pinRequired
    case noSecuritySetup
    case authenticationRequired
    
    public var errorDescription: String? {
        switch self {
        case .biometricFailedPINRequired:
            return "Biometric authentication failed. Please enter your PIN."
        case .pinRequired:
            return "Please enter your PIN to continue."
        case .noSecuritySetup:
            return "No security method has been set up."
        case .authenticationRequired:
            return "Authentication is required to access this feature."
        }
    }
}
