import Foundation
import LocalAuthentication
import Core
import Entity

public protocol BiometricAuthManagerProtocol: Sendable {
    var isAvailable: Bool { get }
    var biometricType: BiometricType { get }
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
    
    public nonisolated var biometricType: BiometricType {
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
                throw BiometricError.userCancel
            case .userFallback:
                throw BiometricError.userFallback
            case .biometryNotAvailable:
                throw BiometricError.biometryNotAvailable
            case .biometryNotEnrolled:
                throw BiometricError.notEnrolled
            case .biometryLockout:
                throw BiometricError.biometryLockout
            default:
                throw BiometricError.authenticationFailed
            }
        }
    }
}