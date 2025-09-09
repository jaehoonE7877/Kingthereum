import Foundation

/// 보안 관련 오류를 나타내는 열거형
public enum SecurityError: LocalizedError, Sendable {
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
    case setupFailed
    case unknownError(String)
    
    // SecurityKit에서 사용하는 추가 케이스들
    case secureEnclaveUnavailable
    case keyGenerationFailed(String)
    case publicKeyExtractionFailed
    case keyNotFound(String)
    case signingFailed(String)
    case keyDeletionFailed(String)
    case randomGenerationFailed
    case keychainStoreFailed(String)
    case biometricFailedPINRequired
    case pinRequired
    case noSecuritySetup
    
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
        case .setupFailed:
            return "설정에 실패했습니다"
        case .unknownError(let errorMessage):
            return "알 수 없는 보안 오류: \(errorMessage)"
        case .secureEnclaveUnavailable:
            return "Secure Enclave를 사용할 수 없습니다"
        case .keyGenerationFailed(let reason):
            return "키 생성 실패: \(reason)"
        case .publicKeyExtractionFailed:
            return "공개키 추출에 실패했습니다"
        case .keyNotFound(let identifier):
            return "키를 찾을 수 없습니다: \(identifier)"
        case .signingFailed(let reason):
            return "서명 실패: \(reason)"
        case .keyDeletionFailed(let reason):
            return "키 삭제 실패: \(reason)"
        case .randomGenerationFailed:
            return "안전한 랜덤 데이터 생성 실패"
        case .keychainStoreFailed(let reason):
            return "Keychain 저장 실패: \(reason)"
        case .biometricFailedPINRequired:
            return "생체 인증에 실패했습니다. PIN을 입력해 주세요"
        case .pinRequired:
            return "계속하려면 PIN을 입력해 주세요"
        case .noSecuritySetup:
            return "보안 설정이 되어 있지 않습니다"
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
public enum BiometricError: LocalizedError, Equatable, Sendable {
    case notAvailable
    case notEnrolled
    case authenticationFailed
    case userCancel
    case userFallback
    case biometryLockout
    case biometryNotAvailable
    case invalidContext
    case unknown(String)
    
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
        case .unknown(let errorMessage):
            return "알 수 없는 오류: \(errorMessage)"
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
        case (.unknown(let lhsMessage), .unknown(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}

/// PIN 관련 오류를 나타내는 열거형
public enum PINError: LocalizedError, Sendable {
    case invalidPIN
    case pinMismatch
    case tooManyAttempts
    case pinNotSet
    case pinTooShort
    case pinTooLong
    case keychainError
    case unknown(String)
    
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
        case .unknown(let errorMessage):
            return "알 수 없는 오류: \(errorMessage)"
        }
    }
}
