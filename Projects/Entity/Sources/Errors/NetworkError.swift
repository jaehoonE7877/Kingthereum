import Foundation

/// 네트워크 관련 오류를 나타내는 열거형
public enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noConnection
    case timeout
    case serverError(Int)
    case decodingError
    case encodingError
    case invalidResponse
    case unauthorized
    case forbidden
    case notFound
    case internalServerError
    case serviceUnavailable
    case tooManyRequests
    case unknownError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "잘못된 URL입니다"
        case .noConnection:
            return "네트워크 연결을 확인해주세요"
        case .timeout:
            return "요청 시간이 초과되었습니다"
        case .serverError(let code):
            return "서버 오류가 발생했습니다 (코드: \(code))"
        case .decodingError:
            return "데이터 파싱에 실패했습니다"
        case .encodingError:
            return "데이터 인코딩에 실패했습니다"
        case .invalidResponse:
            return "유효하지 않은 응답입니다"
        case .unauthorized:
            return "인증이 필요합니다"
        case .forbidden:
            return "접근이 거부되었습니다"
        case .notFound:
            return "요청한 리소스를 찾을 수 없습니다"
        case .internalServerError:
            return "내부 서버 오류입니다"
        case .serviceUnavailable:
            return "서비스를 사용할 수 없습니다"
        case .tooManyRequests:
            return "너무 많은 요청이 발생했습니다"
        case .unknownError(let error):
            return "알 수 없는 오류: \(error.localizedDescription)"
        }
    }
}