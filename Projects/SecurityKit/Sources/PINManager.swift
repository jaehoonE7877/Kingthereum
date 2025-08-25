import Foundation
import KeychainAccess
import Core
import Entity

public protocol PINManagerProtocol: Sendable {
    func setPIN(_ pin: String) async throws
    func verifyPIN(_ pin: String) async throws -> Bool
    func hasPIN() async -> Bool
    func changePIN(oldPIN: String, newPIN: String) async throws
    func deletePIN() async throws
}

public actor PINManager: PINManagerProtocol {
    
    private let keychain: Keychain
    private let pinKey = "user_pin"
    
    public init() {
        self.keychain = Keychain(service: "com.kingthereum.security")
            .accessibility(.whenUnlockedThisDeviceOnly)
    }
    
    public func setPIN(_ pin: String) async throws {
        guard pin.count == 6, pin.allSatisfy({ $0.isNumber }) else {
            throw PINError.invalidFormat
        }
        
        do {
            try keychain.set(pin, key: pinKey)
        } catch {
            throw PINError.keychainError
        }
    }
    
    public func verifyPIN(_ pin: String) async throws -> Bool {
        guard let storedPIN = try keychain.getString(pinKey) else {
            throw PINError.noPINSet
        }
        
        return storedPIN == pin
    }
    
    public func hasPIN() async -> Bool {
        do {
            return try keychain.getString(pinKey) != nil
        } catch {
            return false
        }
    }
    
    public func changePIN(oldPIN: String, newPIN: String) async throws {
        let isValid = try await verifyPIN(oldPIN)
        guard isValid else {
            throw PINError.incorrectPIN
        }
        
        try await setPIN(newPIN)
    }
    
    public func deletePIN() async throws {
        do {
            try keychain.remove(pinKey)
        } catch {
            throw PINError.keychainError
        }
    }
}

public enum PINError: LocalizedError {
    case invalidFormat
    case noPINSet
    case incorrectPIN
    case keychainError
    
    public var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "PIN은 6자리 숫자여야 합니다"
        case .noPINSet:
            return "PIN이 설정되지 않았습니다"
        case .incorrectPIN:
            return "잘못된 PIN입니다"
        case .keychainError:
            return "키체인 오류가 발생했습니다"
        }
    }
}