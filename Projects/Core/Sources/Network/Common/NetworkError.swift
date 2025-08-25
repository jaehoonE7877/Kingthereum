import Foundation

/// 네트워크 에러 타입
public enum NetworkError: Error, LocalizedError {
    case invalidResponse
    case clientError(Int)
    case serverError(Int) 
    case unexpectedStatusCode(Int)
    case unsupportedHTTPMethod(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "유효하지 않은 응답입니다."
        case .clientError(let code):
            return "클라이언트 오류 (HTTP \(code))"
        case .serverError(let code):
            return "서버 오류 (HTTP \(code))"
        case .unexpectedStatusCode(let code):
            return "예상하지 못한 상태 코드 (HTTP \(code))"
        case .unsupportedHTTPMethod(let method):
            return "지원하지 않는 HTTP 메서드: \(method)"
        }
    }
}