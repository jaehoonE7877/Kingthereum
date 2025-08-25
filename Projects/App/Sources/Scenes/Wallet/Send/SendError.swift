import Foundation

enum SendError: LocalizedError {
    case invalidAddress(String)
    case insufficientBalance(String)
    case invalidAmount(String)
    case gasEstimationFailed(String)
    case transactionPreparationFailed(String)
    case biometricAuthenticationFailed(String)
    case transactionFailed(String)
    case networkError(String)
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidAddress(let message):
            return message
        case .insufficientBalance(let message):
            return message
        case .invalidAmount(let message):
            return message
        case .gasEstimationFailed(let message):
            return message
        case .transactionPreparationFailed(let message):
            return message
        case .biometricAuthenticationFailed(let message):
            return message
        case .transactionFailed(let message):
            return message
        case .networkError(let message):
            return message
        case .unknownError(let message):
            return message
        }
    }
    
    var title: String {
        switch self {
        case .invalidAddress:
            return "잘못된 주소"
        case .insufficientBalance:
            return "잔액 부족"
        case .invalidAmount:
            return "잘못된 금액"
        case .gasEstimationFailed:
            return "가스비 계산 실패"
        case .transactionPreparationFailed:
            return "거래 준비 실패"
        case .biometricAuthenticationFailed:
            return "인증 실패"
        case .transactionFailed:
            return "거래 실패"
        case .networkError:
            return "네트워크 오류"
        case .unknownError:
            return "알 수 없는 오류"
        }
    }
    
    var suggestion: String? {
        switch self {
        case .invalidAddress:
            return "올바른 이더리움 주소를 입력해주세요. 주소는 0x로 시작하고 42자리여야 합니다."
        case .insufficientBalance:
            return "잔액을 확인하고 송금 금액을 줄여주세요."
        case .invalidAmount:
            return "유효한 금액을 입력해주세요. 0보다 큰 숫자여야 합니다."
        case .gasEstimationFailed:
            return "네트워크 상태를 확인하고 다시 시도해주세요."
        case .transactionPreparationFailed:
            return "입력 정보를 확인하고 다시 시도해주세요."
        case .biometricAuthenticationFailed:
            return "생체 인증을 다시 시도해주세요."
        case .transactionFailed:
            return "네트워크 상태를 확인하고 다시 시도해주세요."
        case .networkError:
            return "인터넷 연결을 확인하고 다시 시도해주세요."
        case .unknownError:
            return "앱을 다시 시작하고 다시 시도해주세요."
        }
    }
}