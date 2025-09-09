import Foundation
import BigInt

/// 송금 과정에서 발생할 수 있는 모든 에러 타입
/// 실제 이더리움 네트워크와의 상호작용에서 발생하는 실제 에러들
public enum SendError: Error, Sendable, Equatable {
    // MARK: - 주소 검증 에러
    case invalidAddress(reason: String)
    case checksumMismatch(provided: String, expected: String)
    case unsupportedAddressFormat
    
    // MARK: - 잔액 및 금액 에러
    case insufficientBalance(required: String, available: String)
    case invalidAmount(reason: String)
    case amountTooSmall(minimum: String)
    case amountTooLarge(maximum: String)
    
    // MARK: - 가스 관련 에러
    case gasEstimationFailed(reason: String)
    case gasPriceTooLow(minimum: String)
    case gasPriceTooHigh(maximum: String)
    case gasLimitExceeded(limit: String)
    case insufficientGas(required: String, available: String)
    
    // MARK: - 네트워크 에러
    case networkUnavailable
    case rpcEndpointError(endpoint: String, reason: String)
    case chainIdMismatch(expected: BigUInt, actual: BigUInt)
    case blockchainSyncError
    case nodeConnectionTimeout
    
    // MARK: - 거래 서명 에러
    case privateKeyNotFound
    case keyDerivationFailed
    case signatureGenerationFailed(reason: String)
    case invalidKeystore(reason: String)
    case biometricAuthenticationFailed
    case pinVerificationFailed
    
    // MARK: - 거래 전송 에러
    case transactionBroadcastFailed(reason: String)
    case nonceTooLow(expected: BigUInt, provided: BigUInt)
    case nonceTooHigh(expected: BigUInt, provided: BigUInt)
    case replacementTransactionUnderpriced
    case transactionPoolFull
    case transactionRejected(reason: String)
    
    // MARK: - 거래 확인 에러
    case transactionTimeout(hash: String)
    case transactionReverted(hash: String, reason: String?)
    case transactionDropped(hash: String)
    case blockConfirmationTimeout
    case reorgDetected(originalHash: String, newHash: String?)
    
    // MARK: - 보안 에러
    case keychainAccessError(reason: String)
    case encryptionError(reason: String)
    case deviceNotSecure
    case jailbreakDetected
    
    // MARK: - 시스템 에러
    case memoryPressure
    case diskSpaceInsufficient
    case networkPermissionDenied
    case backgroundTaskExpired
    
    // MARK: - 사용자 에러
    case userCancelled
    case sessionExpired
    case rateLimitExceeded(retryAfter: TimeInterval)
    case maintenanceMode
    
    public var localizedDescription: String {
        switch self {
        // 주소 검증 에러
        case .invalidAddress(let reason):
            return "유효하지 않은 이더리움 주소입니다: \(reason)"
        case .checksumMismatch(_, let expected):
            return "주소 체크섬이 일치하지 않습니다. 올바른 주소: \(expected)"
        case .unsupportedAddressFormat:
            return "지원하지 않는 주소 형식입니다."
            
        // 잔액 및 금액 에러
        case .insufficientBalance(let required, let available):
            return "잔액이 부족합니다. 필요: \(required) ETH, 보유: \(available) ETH"
        case .invalidAmount(let reason):
            return "유효하지 않은 금액입니다: \(reason)"
        case .amountTooSmall(let minimum):
            return "최소 전송 금액은 \(minimum) ETH 입니다."
        case .amountTooLarge(let maximum):
            return "최대 전송 금액은 \(maximum) ETH 입니다."
            
        // 가스 관련 에러
        case .gasEstimationFailed(let reason):
            return "가스비 추정에 실패했습니다: \(reason)"
        case .gasPriceTooLow(let minimum):
            return "가스 가격이 너무 낮습니다. 최소: \(minimum) Gwei"
        case .gasPriceTooHigh(let maximum):
            return "가스 가격이 너무 높습니다. 최대: \(maximum) Gwei"
        case .gasLimitExceeded(let limit):
            return "가스 한도를 초과했습니다. 최대: \(limit)"
        case .insufficientGas(let required, let available):
            return "가스비가 부족합니다. 필요: \(required) ETH, 보유: \(available) ETH"
            
        // 네트워크 에러
        case .networkUnavailable:
            return "네트워크에 연결할 수 없습니다. 인터넷 연결을 확인해주세요."
        case .rpcEndpointError(let endpoint, let reason):
            return "RPC 엔드포인트 오류 (\(endpoint)): \(reason)"
        case .chainIdMismatch(let expected, let actual):
            return "네트워크 ID가 일치하지 않습니다. 예상: \(expected), 실제: \(actual)"
        case .blockchainSyncError:
            return "블록체인 동기화 중 오류가 발생했습니다."
        case .nodeConnectionTimeout:
            return "노드 연결 시간이 초과되었습니다."
            
        // 거래 서명 에러
        case .privateKeyNotFound:
            return "개인키를 찾을 수 없습니다. 지갑을 다시 설정해주세요."
        case .keyDerivationFailed:
            return "키 파생에 실패했습니다."
        case .signatureGenerationFailed(let reason):
            return "거래 서명에 실패했습니다: \(reason)"
        case .invalidKeystore(let reason):
            return "키스토어가 유효하지 않습니다: \(reason)"
        case .biometricAuthenticationFailed:
            return "생체 인증에 실패했습니다. 다시 시도해주세요."
        case .pinVerificationFailed:
            return "PIN 확인에 실패했습니다."
            
        // 거래 전송 에러
        case .transactionBroadcastFailed(let reason):
            return "거래 전송에 실패했습니다: \(reason)"
        case .nonceTooLow(let expected, let provided):
            return "Nonce가 너무 낮습니다. 예상: \(expected), 제공: \(provided)"
        case .nonceTooHigh(let expected, let provided):
            return "Nonce가 너무 높습니다. 예상: \(expected), 제공: \(provided)"
        case .replacementTransactionUnderpriced:
            return "대체 거래의 가스비가 너무 낮습니다."
        case .transactionPoolFull:
            return "거래 풀이 가득 찼습니다. 잠시 후 다시 시도해주세요."
        case .transactionRejected(let reason):
            return "거래가 거부되었습니다: \(reason)"
            
        // 거래 확인 에러
        case .transactionTimeout(let hash):
            return "거래 확인 시간이 초과되었습니다. 거래 해시: \(hash)"
        case .transactionReverted(let hash, let reason):
            let reasonText = reason ?? "알 수 없음"
            return "거래가 실패했습니다 (\(hash)): \(reasonText)"
        case .transactionDropped(let hash):
            return "거래가 메모리풀에서 제거되었습니다: \(hash)"
        case .blockConfirmationTimeout:
            return "블록 확인 시간이 초과되었습니다."
        case .reorgDetected(let originalHash, let newHash):
            let newHashText = newHash ?? "알 수 없음"
            return "체인 재구성이 감지되었습니다. 원본: \(originalHash), 신규: \(newHashText)"
            
        // 보안 에러
        case .keychainAccessError(let reason):
            return "키체인 접근 오류: \(reason)"
        case .encryptionError(let reason):
            return "암호화 오류: \(reason)"
        case .deviceNotSecure:
            return "기기가 안전하지 않습니다. 화면 잠금을 설정해주세요."
        case .jailbreakDetected:
            return "탈옥된 기기에서는 보안상 사용할 수 없습니다."
            
        // 시스템 에러
        case .memoryPressure:
            return "메모리가 부족합니다. 다른 앱을 종료해주세요."
        case .diskSpaceInsufficient:
            return "저장 공간이 부족합니다."
        case .networkPermissionDenied:
            return "네트워크 접근 권한이 필요합니다."
        case .backgroundTaskExpired:
            return "백그라운드 작업 시간이 만료되었습니다."
            
        // 사용자 에러
        case .userCancelled:
            return "사용자가 취소했습니다."
        case .sessionExpired:
            return "세션이 만료되었습니다. 다시 로그인해주세요."
        case .rateLimitExceeded(let retryAfter):
            return "요청 한도를 초과했습니다. \(Int(retryAfter))초 후 다시 시도해주세요."
        case .maintenanceMode:
            return "현재 시스템 점검 중입니다. 잠시 후 다시 시도해주세요."
        }
    }
    
    /// 에러의 심각도 수준
    public var severity: ErrorSeverity {
        switch self {
        case .jailbreakDetected, .deviceNotSecure, .privateKeyNotFound:
            return .critical
        case .transactionReverted, .transactionTimeout, .insufficientBalance:
            return .high
        case .networkUnavailable, .gasEstimationFailed, .invalidAddress:
            return .medium
        case .userCancelled, .sessionExpired:
            return .low
        default:
            return .medium
        }
    }
    
    /// 재시도 가능 여부
    public var isRetryable: Bool {
        switch self {
        case .networkUnavailable, .rpcEndpointError, .nodeConnectionTimeout,
             .transactionPoolFull, .gasEstimationFailed, .blockchainSyncError,
             .memoryPressure, .backgroundTaskExpired:
            return true
        case .userCancelled, .privateKeyNotFound, .jailbreakDetected,
             .deviceNotSecure, .invalidAddress, .checksumMismatch:
            return false
        default:
            return true
        }
    }
    
    /// 권장 재시도 지연 시간 (초)
    public var recommendedRetryDelay: TimeInterval {
        switch self {
        case .networkUnavailable, .nodeConnectionTimeout:
            return 5.0
        case .transactionPoolFull, .gasEstimationFailed:
            return 10.0
        case .rateLimitExceeded(let retryAfter):
            return retryAfter
        case .blockchainSyncError, .rpcEndpointError:
            return 15.0
        default:
            return 3.0
        }
    }
    
    /// 사용자에게 표시할 권장 액션
    public var recommendedAction: String? {
        switch self {
        case .insufficientBalance:
            return "ETH를 충전하거나 전송 금액을 줄여주세요."
        case .networkUnavailable:
            return "인터넷 연결을 확인하고 다시 시도해주세요."
        case .gasEstimationFailed:
            return "네트워크 상태를 확인하고 잠시 후 다시 시도해주세요."
        case .privateKeyNotFound:
            return "지갑을 복원하거나 새로 생성해주세요."
        case .biometricAuthenticationFailed:
            return "생체 인증을 다시 시도하거나 PIN을 사용해주세요."
        case .transactionTimeout:
            return "거래 상태를 확인하거나 가스비를 높여서 재전송해주세요."
        case .deviceNotSecure:
            return "기기 설정에서 화면 잠금을 활성화해주세요."
        default:
            return nil
        }
    }
}

/// 에러 심각도 수준
public enum ErrorSeverity: String, CaseIterable, Sendable {
    case low = "낮음"        // 사용자 취소, 세션 만료 등
    case medium = "보통"     // 네트워크 오류, 유효성 검증 실패 등
    case high = "높음"       // 거래 실패, 잔액 부족 등
    case critical = "심각"   // 보안 위험, 키 분실 등
    
    /// 에러 로그 레벨
    public var logLevel: String {
        switch self {
        case .low: return "INFO"
        case .medium: return "WARNING"
        case .high: return "ERROR"
        case .critical: return "CRITICAL"
        }
    }
}

// MARK: - 편의 생성자들

public extension SendError {
    /// Web3Swift 에러를 SendError로 변환
    static func fromWeb3Error(_ error: Error) -> SendError {
        let errorDescription = error.localizedDescription.lowercased()
        
        if errorDescription.contains("insufficient") && errorDescription.contains("balance") {
            return .insufficientBalance(required: "알 수 없음", available: "알 수 없음")
        } else if errorDescription.contains("gas") && errorDescription.contains("limit") {
            return .gasLimitExceeded(limit: "알 수 없음")
        } else if errorDescription.contains("nonce") && errorDescription.contains("low") {
            return .nonceTooLow(expected: 0, provided: 0)
        } else if errorDescription.contains("connection") || errorDescription.contains("network") {
            return .networkUnavailable
        } else if errorDescription.contains("private") && errorDescription.contains("key") {
            return .privateKeyNotFound
        } else if errorDescription.contains("invalid") && errorDescription.contains("address") {
            return .invalidAddress(reason: error.localizedDescription)
        } else if errorDescription.contains("timeout") {
            return .nodeConnectionTimeout
        } else {
            return .transactionBroadcastFailed(reason: error.localizedDescription)
        }
    }
    
    /// URLError를 SendError로 변환
    static func fromURLError(_ error: URLError) -> SendError {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .networkUnavailable
        case .timedOut:
            return .nodeConnectionTimeout
        case .cannotFindHost, .cannotConnectToHost:
            return .rpcEndpointError(endpoint: error.failingURL?.absoluteString ?? "알 수 없음", 
                                   reason: error.localizedDescription)
        default:
            return .networkUnavailable
        }
    }
}
