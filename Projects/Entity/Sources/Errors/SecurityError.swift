import Foundation

/// 암호화폐 지갑의 보안 시스템에서 발생할 수 있는 모든 오류를 정의한 열거형
/// 
/// iOS의 생체인증(Face ID/Touch ID), 키체인, PIN 인증, 암호화/복호화 등
/// 지갑의 보안 기능에서 발생할 수 있는 다양한 오류들을 포괄적으로 다룹니다.
/// 
/// ## 보안 오류 카테고리:
/// ### 키체인 및 저장소 보안
/// - `keychainAccessFailed`: iOS 키체인 접근 실패
/// - `encryptionFailed`: 데이터 암호화 실패
/// - `decryptionFailed`: 데이터 복호화 실패
/// 
/// ### 생체 인증 (Biometric Authentication)
/// - `biometricAuthenticationFailed`: Face ID/Touch ID 인증 실패
/// - `biometricNotAvailable`: 생체인증 하드웨어 없음
/// - `biometricNotEnrolled`: 생체인증 미등록
/// - `biometricLockout`: 생체인증 잠금 (실패 횟수 초과)
/// 
/// ### PIN 및 패스코드 인증
/// - `pinVerificationFailed`: PIN 번호 확인 실패
/// - `invalidCredentials`: 잘못된 인증 정보
/// 
/// ### 일반 인증
/// - `authenticationRequired`: 추가 인증 필요
/// - `unknownError`: 분류되지 않은 보안 오류
/// 
/// ## 사용 예시:
/// ```swift
/// do {
///     let privateKey = try await securityManager.getPrivateKey()
/// } catch SecurityError.biometricLockout {
///     showAlert("생체인증 잠금", "패스코드로 잠금을 해제해주세요")
/// } catch SecurityError.keychainAccessFailed {
///     showAlert("보안 오류", "키체인 접근이 거부되었습니다")
/// } catch {
///     showAlert("인증 실패", "다시 시도해주세요")
/// }
/// ```
public enum SecurityError: LocalizedError {
    /// iOS 키체인 시스템 접근 실패
    ///
    /// 발생 상황:
    /// - 키체인 서비스 비활성화
    /// - 시스템 권한 부족
    /// - 키체인 데이터 손상
    /// - 디바이스 잠금 상태에서 접근 시도
    case keychainAccessFailed
    
    /// 생체 인증 (Face ID/Touch ID/Optic ID) 실패
    ///
    /// 발생 상황:
    /// - 생체인식 매칭 실패
    /// - 센서 오류 또는 더러움
    /// - 사용자 취소
    /// - 하드웨어 일시적 오류
    case biometricAuthenticationFailed
    
    /// PIN 번호 확인 실패
    ///
    /// 발생 상황:
    /// - 잘못된 PIN 입력
    /// - PIN 입력 시간 초과
    /// - 최대 시도 횟수 초과
    /// - PIN 데이터 손상
    case pinVerificationFailed
    
    /// 데이터 암호화 처리 실패
    ///
    /// 발생 상황:
    /// - 암호화 키 생성 실패
    /// - 암호화 알고리즘 오류
    /// - 메모리 부족
    /// - 시스템 암호화 서비스 오류
    case encryptionFailed
    
    /// 암호화된 데이터 복호화 실패
    ///
    /// 발생 상황:
    /// - 잘못된 복호화 키
    /// - 손상된 암호화 데이터
    /// - 키 버전 불일치
    /// - 복호화 알고리즘 오류
    case decryptionFailed
    
    /// 제공된 인증 정보가 유효하지 않음
    ///
    /// 발생 상황:
    /// - 만료된 토큰 또는 세션
    /// - 잘못된 사용자 자격증명
    /// - 권한이 없는 접근 시도
    /// - 인증 정보 형식 오류
    case invalidCredentials
    
    /// 작업 수행을 위해 추가 인증이 필요함
    ///
    /// 발생 상황:
    /// - 민감한 작업 수행 시
    /// - 인증 세션 만료
    /// - 보안 정책에 의한 재인증 요구
    /// - 높은 권한이 필요한 기능 접근
    case authenticationRequired
    
    /// 생체 인증 기능을 사용할 수 없음
    ///
    /// 발생 상황:
    /// - 생체인증 하드웨어 없음
    /// - iOS 버전 미지원
    /// - 하드웨어 고장 또는 비활성화
    /// - 제한된 접근 모드
    case biometricNotAvailable
    
    /// 생체 인증이 디바이스에 등록되지 않음
    ///
    /// 발생 상황:
    /// - Face ID/Touch ID 미설정
    /// - 모든 생체정보 삭제됨
    /// - 생체인증 설정 초기화
    /// - 새 디바이스 초기 상태
    case biometricNotEnrolled
    
    /// 생체 인증이 잠금 상태 (실패 횟수 초과)
    ///
    /// 발생 상황:
    /// - 연속 인증 실패 (보통 5회)
    /// - 보안 정책에 의한 일시 잠금
    /// - 디바이스 재시작 후 미인증
    /// - 패스코드 입력 대기 상태
    case biometricLockout
    
    /// 분류되지 않은 보안 관련 오류
    ///
    /// - Parameter underlyingError: 원본 오류 객체
    case unknownError(Error)
    
    /// 사용자에게 표시할 현지화된 오류 메시지
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
    
    /// 개발자를 위한 상세한 디버깅 정보
    public var debugDescription: String {
        switch self {
        case .keychainAccessFailed:
            return "iOS Keychain access denied - check entitlements and device lock state"
        case .biometricAuthenticationFailed:
            return "Biometric authentication failed - user cancelled or biometry not recognized"
        case .pinVerificationFailed:
            return "PIN verification failed - incorrect PIN or too many attempts"
        case .encryptionFailed:
            return "Data encryption failed - crypto service error or insufficient memory"
        case .decryptionFailed:
            return "Data decryption failed - wrong key or corrupted data"
        case .invalidCredentials:
            return "Invalid credentials - expired token or wrong authentication data"
        case .authenticationRequired:
            return "Authentication required - sensitive operation needs user verification"
        case .biometricNotAvailable:
            return "Biometric authentication not available - no hardware or disabled"
        case .biometricNotEnrolled:
            return "No biometric enrolled - user hasn't set up Face ID/Touch ID"
        case .biometricLockout:
            return "Biometric locked out - too many failed attempts, requires passcode"
        case .unknownError(let error):
            return "Unknown security error: \(error)"
        }
    }
    
    /// 사용자에게 제안할 해결 방법
    public var recoverySuggestion: String? {
        switch self {
        case .keychainAccessFailed:
            return "디바이스 잠금을 해제하고 앱을 재시작해주세요."
        case .biometricAuthenticationFailed:
            return "생체인증을 다시 시도하거나 패스코드를 사용해주세요."
        case .pinVerificationFailed:
            return "올바른 PIN을 입력하거나 지갑을 복원해주세요."
        case .encryptionFailed, .decryptionFailed:
            return "앱을 재시작하고 다시 시도해주세요. 문제가 계속되면 지갑을 복원해주세요."
        case .invalidCredentials:
            return "다시 로그인하거나 인증 정보를 갱신해주세요."
        case .authenticationRequired:
            return "생체인증 또는 패스코드로 인증을 완료해주세요."
        case .biometricNotAvailable:
            return "설정에서 Face ID/Touch ID를 활성화하거나 패스코드를 사용해주세요."
        case .biometricNotEnrolled:
            return "설정에서 Face ID/Touch ID를 등록해주세요."
        case .biometricLockout:
            return "패스코드를 입력하여 잠금을 해제한 후 다시 시도해주세요."
        case .unknownError:
            return "앱을 재시작하고 다시 시도해주세요."
        }
    }
    
    /// 오류가 사용자 액션으로 해결 가능한지 확인
    public var isUserRecoverable: Bool {
        switch self {
        case .biometricAuthenticationFailed, .pinVerificationFailed, .authenticationRequired,
                .biometricNotEnrolled, .biometricLockout:
            return true
        case .keychainAccessFailed, .encryptionFailed, .decryptionFailed,
                .invalidCredentials, .biometricNotAvailable, .unknownError:
            return false
        }
    }
    
    /// 재시도 가능한 오류인지 확인
    public var isRetryable: Bool {
        switch self {
        case .biometricAuthenticationFailed, .pinVerificationFailed, .keychainAccessFailed,
                .authenticationRequired, .unknownError:
            return true
        case .encryptionFailed, .decryptionFailed, .invalidCredentials,
                .biometricNotAvailable, .biometricNotEnrolled, .biometricLockout:
            return false
        }
    }
    
    /// 오류 심각도 레벨
    public var severity: SecurityErrorSeverity {
        switch self {
        case .encryptionFailed, .decryptionFailed, .keychainAccessFailed:
            return .critical // 데이터 보안에 직접적 영향
        case .biometricLockout, .invalidCredentials:
            return .high // 사용자 인증 차단
        case .biometricAuthenticationFailed, .pinVerificationFailed, .authenticationRequired:
            return .medium // 일시적 접근 제한
        case .biometricNotAvailable, .biometricNotEnrolled:
            return .low // 대안 인증 방법 사용 가능
        case .unknownError:
            return .medium // 분석 필요
        }
    }
    
    /// 보안 오류 카테고리
    public var category: SecurityErrorCategory {
        switch self {
        case .biometricAuthenticationFailed, .biometricNotAvailable, .biometricNotEnrolled, .biometricLockout:
            return .biometric
        case .pinVerificationFailed:
            return .pin
        case .keychainAccessFailed:
            return .keychain
        case .encryptionFailed, .decryptionFailed:
            return .cryptography
        case .invalidCredentials, .authenticationRequired:
            return .authentication
        case .unknownError:
            return .system
        }
    }
    
    /// 사용자 액션 버튼 텍스트
    public var actionTitle: String? {
        switch self {
        case .biometricAuthenticationFailed, .authenticationRequired:
            return "다시 인증"
        case .pinVerificationFailed:
            return "PIN 재입력"
        case .biometricNotEnrolled:
            return "설정으로 이동"
        case .biometricLockout:
            return "패스코드 입력"
        case .keychainAccessFailed, .encryptionFailed, .decryptionFailed, .unknownError:
            return "재시도"
        default:
            return nil
        }
    }
    
    
    // MARK: - Supporting Types
    
    /// 보안 오류 심각도 레벨
    public enum SecurityErrorSeverity {
        /// 낮은 심각도 - 대안 방법 사용 가능
        case low
        /// 중간 심각도 - 기능 제한이나 재시도 필요
        case medium
        /// 높은 심각도 - 사용자 인증 차단
        case high
        /// 치명적 심각도 - 데이터 보안에 직접적 위험
        case critical
    }
    
    /// 보안 오류 카테고리
    public enum SecurityErrorCategory {
        /// 생체 인증 관련 (Face ID, Touch ID, Optic ID)
        case biometric
        /// PIN 번호 인증 관련
        case pin
        /// iOS 키체인 관련
        case keychain
        /// 암호화/복호화 관련
        case cryptography
        /// 일반 인증 및 자격증명 관련
        case authentication
        /// 시스템 및 분류되지 않은 오류
        case system
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
}
