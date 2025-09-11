import Foundation
import LocalAuthentication
import Core
import Entity

public protocol BiometricAuthManagerProtocol: Sendable {
    var isAvailable: Bool { get }
    var biometricType: Entity.SecurityError.BiometricType { get }
    func authenticate(reason: String) async throws -> Bool
}

public actor BiometricAuthManager: BiometricAuthManagerProtocol {
    
    private let context = LAContext()
    
    public init() {}
    
    public nonisolated var isAvailable: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    public nonisolated var biometricType: Entity.SecurityError.BiometricType {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        
        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        case .opticID:
            return .opticID
        case .none:
            return .none
        @unknown default:
            return .none
        }
    }
    
    public func authenticate(reason: String) async throws -> Bool {
        let context = LAContext()
        
        do {
            let result = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            return result
        } catch let error as LAError {
            switch error.code {
            case .userCancel:
                throw Entity.SecurityError.BiometricError.userCancel
            case .userFallback:
                throw Entity.SecurityError.BiometricError.userFallback
            case .biometryNotAvailable:
                throw Entity.SecurityError.BiometricError.biometryNotAvailable
            case .biometryNotEnrolled:
                throw Entity.SecurityError.BiometricError.notEnrolled
            case .biometryLockout:
                throw Entity.SecurityError.BiometricError.biometryLockout
            default:
                throw Entity.SecurityError.BiometricError.authenticationFailed
            }
        }
    }
}