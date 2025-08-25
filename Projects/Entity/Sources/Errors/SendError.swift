import Foundation

/// 송금 관련 오류를 나타내는 열거형
public enum SendError: LocalizedError {
    case invalidAddress
    case invalidAmount
    case insufficientBalance
    case insufficientGasFunds
    case gasEstimationFailed
    case transactionFailed
    case networkError
    case userCancelled
    case authenticationFailed
    case unknown(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidAddress:
            return "잘못된 주소입니다"
        case .invalidAmount:
            return "잘못된 금액입니다"
        case .insufficientBalance:
            return "잔액이 부족합니다"
        case .insufficientGasFunds:
            return "가스비가 부족합니다"
        case .gasEstimationFailed:
            return "가스 추정에 실패했습니다"
        case .transactionFailed:
            return "거래 전송에 실패했습니다"
        case .networkError:
            return "네트워크 오류가 발생했습니다"
        case .userCancelled:
            return "사용자가 거래를 취소했습니다"
        case .authenticationFailed:
            return "인증에 실패했습니다"
        case .unknown(let error):
            return "알 수 없는 오류: \(error.localizedDescription)"
        }
    }
}