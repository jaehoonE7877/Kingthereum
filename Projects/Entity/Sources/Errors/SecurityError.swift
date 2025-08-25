import Foundation

/// 보안 관련 오류를 나타내는 열거형
public enum SecurityError: LocalizedError {
    case keychainAccessFailed
    case biometricAuthenticationFailed
    case pinVerificationFailed
    case encryptionFailed
    case decryptionFailed
    case invalidCredentials
    case authenticationRequired
    case biometricNotAvailable
    case biometricNotEnrolled
    case biometricLockout
    case unknownError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .keychainAccessFailed:
            return "키체인 접근에 실패했습니다"
        case .biometricAuthenticationFailed:
            return "생체 인증에 실패했습니다"
        case .pinVerificationFailed:
            return "PIN 확인에 실패했습니다"
        case .encryptionFailed:
            return "암호화에 실패했습니다"
        case .decryptionFailed:
            return "복호화에 실패했습니다"
        case .invalidCredentials:
            return "잘못된 인증 정보입니다"
        case .authenticationRequired:
            return "인증이 필요합니다"
        case .biometricNotAvailable:
            return "생체 인증을 사용할 수 없습니다"
        case .biometricNotEnrolled:
            return "생체 인증이 등록되지 않았습니다"
        case .biometricLockout:
            return "생체 인증이 잠금되었습니다"
        case .unknownError(let error):
            return "알 수 없는 보안 오류: \(error.localizedDescription)"
        }
    }
}

/// 지원되는 생체인증 타입을 나타내는 열거형
public enum BiometricType: Sendable {
    case none
    case touchID
    case faceID
    case opticID
    
    /// 각 생체인증 타입의 사용자 친화적인 설명
    public var description: String {
        switch self {
        case .none:
            return "없음"
        case .touchID:
            return "Touch ID"
        case .faceID:
            return "Face ID"
        case .opticID:
            return "Optic ID"
        }
    }
    
    public var localizedDescription: String {
        switch self {
        case .none:
            return "생체 인증 없음"
        case .touchID:
            return "Touch ID"
        case .faceID:
            return "Face ID"
        case .opticID:
            return "Optic ID"
        }
    }
    
    public var iconName: String {
        switch self {
        case .none:
            return "lock.fill"
        case .touchID:
            return "touchid"
        case .faceID:
            return "faceid"
        case .opticID:
            return "opticid"
        }
    }
}

/// 생체 인증 관련 오류를 나타내는 열거형
public enum BiometricError: LocalizedError, Equatable {
    case notAvailable
    case notEnrolled
    case authenticationFailed
    case userCancel
    case userFallback
    case biometryLockout
    case biometryNotAvailable
    case invalidContext
    case unknown(Error)
    
    public var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "생체 인증을 사용할 수 없습니다"
        case .notEnrolled:
            return "생체 인증이 설정되지 않았습니다"
        case .authenticationFailed:
            return "생체 인증에 실패했습니다"
        case .userCancel:
            return "사용자가 인증을 취소했습니다"
        case .userFallback:
            return "사용자가 대체 인증을 선택했습니다"
        case .biometryLockout:
            return "생체 인증이 잠금되었습니다"
        case .biometryNotAvailable:
            return "생체 인증이 비활성화되었습니다"
        case .invalidContext:
            return "유효하지 않은 인증 컨텍스트입니다"
        case .unknown(let error):
            return "알 수 없는 오류: \(error.localizedDescription)"
        }
    }
    
    public static func == (lhs: BiometricError, rhs: BiometricError) -> Bool {
        switch (lhs, rhs) {
        case (.notAvailable, .notAvailable),
             (.notEnrolled, .notEnrolled),
             (.authenticationFailed, .authenticationFailed),
             (.userCancel, .userCancel),
             (.userFallback, .userFallback),
             (.biometryLockout, .biometryLockout),
             (.biometryNotAvailable, .biometryNotAvailable),
             (.invalidContext, .invalidContext):
            return true
        case (.unknown(let lhsError), .unknown(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

/// PIN 관련 오류를 나타내는 열거형
public enum PINError: LocalizedError {
    case invalidPIN
    case pinMismatch
    case tooManyAttempts
    case pinNotSet
    case pinTooShort
    case pinTooLong
    case keychainError
    case unknown(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidPIN:
            return "잘못된 PIN입니다"
        case .pinMismatch:
            return "PIN이 일치하지 않습니다"
        case .tooManyAttempts:
            return "너무 많은 시도로 인해 잠금되었습니다"
        case .pinNotSet:
            return "PIN이 설정되지 않았습니다"
        case .pinTooShort:
            return "PIN이 너무 짧습니다"
        case .pinTooLong:
            return "PIN이 너무 깁니다"
        case .keychainError:
            return "키체인 오류가 발생했습니다"
        case .unknown(let error):
            return "알 수 없는 오류: \(error.localizedDescription)"
        }
    }
}
