import Foundation

// MARK: - Price Errors

public enum PriceError: LocalizedError {
    case networkUnavailable
    case invalidResponse
    case rateLimitExceeded
    case coinNotFound(String)
    case cacheExpired
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "네트워크 연결을 확인해주세요"
        case .invalidResponse:
            return "가격 정보를 가져올 수 없습니다"
        case .rateLimitExceeded:
            return "요청 한도를 초과했습니다. 잠시 후 다시 시도해주세요"
        case .coinNotFound(let symbol):
            return "'\(symbol)' 코인 정보를 찾을 수 없습니다"
        case .cacheExpired:
            return "캐시된 가격 정보가 만료되었습니다"
        case .configurationError(let message):
            return "설정 오류: \(message)"
        }
    }
}