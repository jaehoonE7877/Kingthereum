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
    
    /// 일반 인증 프로세스 실패
    ///
    /// 발생 상황:
    /// - 생체인증 및 PIN 모두 실패
    /// - 인증 서비스 전체 오류
    /// - 보안 정책 위반
    /// - 시스템 보안 서비스 오류
    case authenticationFailed
    
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
    
    /// 사용자가 인증 또는 보안 작업을 취소함
    ///
    /// 발생 상황:
    /// - 생체인증 중 사용자가 취소 버튼 클릭
    /// - PIN 입력 중 취소
    /// - 거래 승인 프로세스에서 사용자 취소
    /// - 보안 작업 진행 중 사용자 중단
    case userCanceled
    
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
        case .authenticationFailed:
            return "인증에 실패했습니다"
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
        case .userCanceled:
            return "사용자가 취소했습니다"
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
        case .authenticationFailed:
            return "General authentication failed - both biometric and PIN authentication failed"
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
        case .userCanceled:
            return "User canceled authentication or security operation"
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
        case .authenticationFailed:
            return "생체인증 또는 PIN으로 다시 인증을 시도해주세요."
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
        case .userCanceled:
            return "다시 시도하려면 인증을 진행해주세요."
        case .unknownError:
            return "앱을 재시작하고 다시 시도해주세요."
        }
    }
    
    /// 오류가 사용자 액션으로 해결 가능한지 확인
    public var isUserRecoverable: Bool {
        switch self {
        case .biometricAuthenticationFailed, .pinVerificationFailed, .authenticationRequired,
                .biometricNotEnrolled, .biometricLockout, .authenticationFailed, .userCanceled:
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
                .authenticationRequired, .authenticationFailed, .userCanceled, .unknownError:
            return true
        case .encryptionFailed, .decryptionFailed, .invalidCredentials,
                .biometricNotAvailable, .biometricNotEnrolled, .biometricLockout:
            return false
        }
    }
    
    /// 오류 심각도 레벨 (문자열로 반환)
    public var severityLevel: String {
        switch self {
        case .encryptionFailed, .decryptionFailed, .keychainAccessFailed:
            return "critical" // 데이터 보안에 직접적 영향
        case .biometricLockout, .invalidCredentials:
            return "high" // 사용자 인증 차단
        case .biometricAuthenticationFailed, .pinVerificationFailed, .authenticationRequired, .authenticationFailed:
            return "medium" // 일시적 접근 제한
        case .userCanceled:
            return "low" // 사용자 의도적 취소
        case .biometricNotAvailable, .biometricNotEnrolled:
            return "low" // 대안 인증 방법 사용 가능
        case .unknownError:
            return "medium" // 분석 필요
        }
    }
    
    /// 보안 오류 카테고리 (문자열로 반환)
    public var errorCategory: String {
        switch self {
        case .biometricAuthenticationFailed, .biometricNotAvailable, .biometricNotEnrolled, .biometricLockout:
            return "biometric"
        case .pinVerificationFailed:
            return "pin"
        case .keychainAccessFailed:
            return "keychain"
        case .encryptionFailed, .decryptionFailed:
            return "cryptography"
        case .invalidCredentials, .authenticationRequired, .authenticationFailed:
            return "authentication"
        case .userCanceled:
            return "user_action"
        case .unknownError:
            return "system"
        }
    }
    
    /// 사용자 액션 버튼 텍스트
    public var actionTitle: String? {
        switch self {
        case .biometricAuthenticationFailed, .authenticationRequired, .authenticationFailed:
            return "다시 인증"
        case .pinVerificationFailed:
            return "PIN 재입력"
        case .biometricNotEnrolled:
            return "설정으로 이동"
        case .biometricLockout:
            return "패스코드 입력"
        case .userCanceled:
            return "다시 시도"
        case .keychainAccessFailed, .encryptionFailed, .decryptionFailed, .unknownError:
            return "재시도"
        default:
            return nil
        }
    }
    
    // MARK: - Supporting Types
    
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
    
    /// PIN 인증 관련 오류를 나타내는 열거형
    public enum PINError: LocalizedError, Equatable {
        case invalidPIN
        case pinTooShort
        case pinTooLong
        case weakPIN
        case pinMismatch
        case maxAttemptsExceeded
        case tooManyAttempts
        case pinNotSet
        case encryptionFailed
        case decryptionFailed
        case keychainError
        case invalidFormat
        case unknown(Error)
        
        public var errorDescription: String? {
            switch self {
            case .invalidPIN:
                return "올바르지 않은 PIN입니다"
            case .pinTooShort:
                return "PIN이 너무 짧습니다"
            case .pinTooLong:
                return "PIN이 너무 깁니다"
            case .weakPIN:
                return "보안이 약한 PIN입니다"
            case .pinMismatch:
                return "PIN이 일치하지 않습니다"
            case .maxAttemptsExceeded:
                return "최대 시도 횟수를 초과했습니다"
            case .tooManyAttempts:
                return "PIN 시도 횟수가 너무 많습니다"
            case .pinNotSet:
                return "PIN이 설정되지 않았습니다"
            case .encryptionFailed:
                return "PIN 암호화에 실패했습니다"
            case .decryptionFailed:
                return "PIN 복호화에 실패했습니다"
            case .keychainError:
                return "키체인 접근 오류입니다"
            case .invalidFormat:
                return "유효하지 않은 PIN 형식입니다"
            case .unknown(let error):
                return "알 수 없는 PIN 오류: \(error.localizedDescription)"
            }
        }
        
        public var recoverySuggestion: String? {
            switch self {
            case .invalidPIN:
                return "올바른 PIN을 입력해주세요"
            case .pinTooShort:
                return "최소 4자리 PIN을 입력해주세요"
            case .pinTooLong:
                return "최대 8자리 PIN을 입력해주세요"
            case .weakPIN:
                return "연속된 숫자나 반복되는 숫자는 피해주세요"
            case .pinMismatch:
                return "같은 PIN을 두 번 입력해주세요"
            case .maxAttemptsExceeded:
                return "잠시 후 다시 시도하거나 지갑을 복원해주세요"
            case .tooManyAttempts:
                return "잠시 후 다시 시도해주세요"
            case .pinNotSet:
                return "먼저 PIN을 설정해주세요"
            case .encryptionFailed, .decryptionFailed, .keychainError:
                return "앱을 재시작하고 다시 시도해주세요"
            case .invalidFormat:
                return "숫자로만 구성된 PIN을 입력해주세요"
            case .unknown:
                return "앱을 재시작하고 다시 시도해주세요"
            }
        }
        
        public static func == (lhs: PINError, rhs: PINError) -> Bool {
            switch (lhs, rhs) {
            case (.invalidPIN, .invalidPIN),
                (.pinTooShort, .pinTooShort),
                (.pinTooLong, .pinTooLong),
                (.weakPIN, .weakPIN),
                (.pinMismatch, .pinMismatch),
                (.maxAttemptsExceeded, .maxAttemptsExceeded),
                (.tooManyAttempts, .tooManyAttempts),
                (.pinNotSet, .pinNotSet),
                (.encryptionFailed, .encryptionFailed),
                (.decryptionFailed, .decryptionFailed),
                (.keychainError, .keychainError),
                (.invalidFormat, .invalidFormat):
                return true
            case (.unknown(let lhsError), .unknown(let rhsError)):
                return lhsError.localizedDescription == rhsError.localizedDescription
            default:
                return false
            }
        }
    }
}
