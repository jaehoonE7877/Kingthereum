import Foundation

/// 네트워크 통신에서 발생할 수 있는 모든 오류 상황을 정의한 열거형
/// 
/// 이더리움 블록체인과의 RPC 통신, 가스 트래커 API 호출, 토큰 정보 조회 등
/// 다양한 네트워크 작업에서 발생할 수 있는 오류들을 체계적으로 분류합니다.
/// 
/// ## 오류 카테고리:
/// ### 클라이언트 오류 (4xx)
/// - `invalidURL`: 잘못된 URL 형식
/// - `unauthorized`: 인증 실패 (401)
/// - `forbidden`: 권한 없음 (403) 
/// - `notFound`: 리소스 없음 (404)
/// - `tooManyRequests`: 요청 한도 초과 (429)
/// 
/// ### 서버 오류 (5xx)
/// - `serverError`: 일반 서버 오류
/// - `internalServerError`: 내부 서버 오류 (500)
/// - `serviceUnavailable`: 서비스 불가 (503)
/// 
/// ### 네트워크 오류
/// - `noConnection`: 네트워크 연결 없음
/// - `timeout`: 요청 시간 초과
/// - `invalidResponse`: 잘못된 응답 형식
/// 
/// ### 데이터 처리 오류
/// - `decodingError`: JSON 파싱 실패
/// - `encodingError`: 데이터 직렬화 실패
/// 
/// ## 사용 예시:
/// ```swift
/// do {
///     let response = try await networkService.fetchGasPrice()
/// } catch NetworkError.timeout {
///     showAlert("네트워크가 불안정합니다. 다시 시도해주세요.")
/// } catch NetworkError.tooManyRequests {
///     showAlert("잠시 후 다시 시도해주세요.")
/// } catch {
///     showAlert("네트워크 오류가 발생했습니다.")
/// }
/// ```
public enum NetworkError: Error, LocalizedError {
    /// 잘못된 URL 형식 또는 구성 오류
    ///
    /// 발생 상황:
    /// - 잘못된 RPC 엔드포인트 URL
    /// - 필수 URL 구성 요소 누락
    /// - 유효하지 않은 문자나 형식
    case invalidURL
    
    /// 네트워크 연결 불가 상태
    ///
    /// 발생 상황:
    /// - WiFi/모바일 데이터 비활성화
    /// - 네트워크 설정 문제
    /// - ISP 또는 방화벽 차단
    case noConnection
    
    /// 요청 처리 시간 초과
    ///
    /// 발생 상황:
    /// - 서버 응답 지연
    /// - 네트워크 지연 또는 패킷 손실
    /// - 대용량 데이터 전송 시간 초과
    case timeout
    
    /// 서버에서 반환한 HTTP 오류 상태
    ///
    /// - Parameter statusCode: HTTP 상태 코드 (400~599)
    case serverError(Int)
    
    /// JSON 응답 파싱 또는 디코딩 실패
    ///
    /// 발생 상황:
    /// - 예상과 다른 JSON 구조
    /// - 필수 필드 누락
    /// - 타입 불일치 (String 대신 Int 등)
    case decodingError
    
    /// 요청 데이터 인코딩 실패
    ///
    /// 발생 상황:
    /// - JSON 직렬화 오류
    /// - 지원되지 않는 문자 인코딩
    /// - 순환 참조 객체
    case encodingError
    
    /// 예상과 다른 응답 형식 수신
    ///
    /// 발생 상황:
    /// - Content-Type 불일치
    /// - 빈 응답 본문
    /// - 손상된 데이터
    case invalidResponse
    
    /// 인증이 필요한 리소스에 대한 접근 (HTTP 401)
    ///
    /// 발생 상황:
    /// - API 키 없음 또는 잘못됨
    /// - 토큰 만료
    /// - 인증 헤더 누락
    case unauthorized
    
    /// 권한이 없는 리소스에 대한 접근 (HTTP 403)
    ///
    /// 발생 상황:
    /// - 계정 권한 부족
    /// - 지역 제한 (geo-blocking)
    /// - API 사용 제한
    case forbidden
    
    /// 요청한 리소스가 존재하지 않음 (HTTP 404)
    ///
    /// 발생 상황:
    /// - 잘못된 트랜잭션 해시 조회
    /// - 존재하지 않는 블록 번호
    /// - 잘못된 API 엔드포인트
    case notFound
    
    /// 내부 서버 오류 (HTTP 500)
    ///
    /// 발생 상황:
    /// - 노드 소프트웨어 오류
    /// - 데이터베이스 연결 실패
    /// - 예상치 못한 서버 예외
    case internalServerError
    
    /// 서비스 일시적 불가 (HTTP 503)
    ///
    /// 발생 상황:
    /// - 서버 유지보수
    /// - 과부하 상태
    /// - 노드 동기화 중
    case serviceUnavailable
    
    /// 요청 빈도 제한 초과 (HTTP 429)
    ///
    /// 발생 상황:
    /// - API 호출 한도 초과
    /// - DDoS 방어 시스템 작동
    /// - 단시간 과도한 요청
    case tooManyRequests
    
    /// 예상하지 못한 기타 오류
    ///
    /// - Parameter underlyingError: 원본 오류 객체
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
    
    /// 개발자를 위한 상세한 오류 정보
    public var debugDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL format or configuration"
        case .noConnection:
            return "No network connection available"
        case .timeout:
            return "Request timeout exceeded"
        case .serverError(let code):
            return "Server returned HTTP \(code)"
        case .decodingError:
            return "Failed to decode JSON response"
        case .encodingError:
            return "Failed to encode request data"
        case .invalidResponse:
            return "Invalid or unexpected response format"
        case .unauthorized:
            return "HTTP 401: Authentication required"
        case .forbidden:
            return "HTTP 403: Access forbidden"
        case .notFound:
            return "HTTP 404: Resource not found"
        case .internalServerError:
            return "HTTP 500: Internal server error"
        case .serviceUnavailable:
            return "HTTP 503: Service unavailable"
        case .tooManyRequests:
            return "HTTP 429: Too many requests"
        case .unknownError(let error):
            return "Unknown error: \(error)"
        }
    }
    
    /// HTTP 상태 코드 (해당하는 경우)
    public var httpStatusCode: Int? {
        switch self {
        case .unauthorized: return 401
        case .forbidden: return 403
        case .notFound: return 404
        case .tooManyRequests: return 429
        case .internalServerError: return 500
        case .serviceUnavailable: return 503
        case .serverError(let code): return code
        default: return nil
        }
    }
    
    /// 재시도 가능한 오류인지 확인
    public var isRetryable: Bool {
        switch self {
        case .timeout, .serviceUnavailable, .tooManyRequests:
            return true
        case .serverError(let code):
            return code >= 500 // 5xx 오류는 재시도 가능
        case .noConnection:
            return true // 네트워크 복구 후 재시도 가능
        default:
            return false
        }
    }
    
    /// 사용자 액션이 필요한 오류인지 확인
    public var requiresUserAction: Bool {
        switch self {
        case .noConnection, .unauthorized, .forbidden:
            return true
        default:
            return false
        }
    }
    
    /// 오류 심각도 레벨
    public var severity: ErrorSeverity {
        switch self {
        case .invalidURL, .encodingError, .decodingError:
            return .high // 개발자 오류
        case .unauthorized, .forbidden:
            return .medium // 사용자 권한 문제
        case .timeout, .tooManyRequests, .serviceUnavailable:
            return .low // 일시적 문제
        case .noConnection:
            return .medium // 사용자 환경 문제
        case .notFound:
            return .medium // 데이터 문제
        case .internalServerError, .serverError:
            return .high // 서버 문제
        case .invalidResponse:
            return .high // 프로토콜 문제
        case .unknownError:
            return .medium // 알 수 없는 문제
        }
    }
    
    /// 에러 카테고리
    public var category: ErrorCategory {
        switch self {
        case .invalidURL, .encodingError, .decodingError, .invalidResponse:
            return .client
        case .unauthorized, .forbidden, .notFound:
            return .authentication
        case .noConnection, .timeout:
            return .network
        case .serverError, .internalServerError, .serviceUnavailable:
            return .server
        case .tooManyRequests:
            return .rateLimit
        case .unknownError:
            return .unknown
        }
    }
}
    // MARK: - NetworkError Extensions
    
    public extension NetworkError {
        /// HTTP URLResponse에서 NetworkError 생성
        static func from(response: HTTPURLResponse) -> NetworkError {
            switch response.statusCode {
            case 401:
                return .unauthorized
            case 403:
                return .forbidden
            case 404:
                return .notFound
            case 429:
                return .tooManyRequests
            case 500:
                return .internalServerError
            case 503:
                return .serviceUnavailable
            case 400...499:
                return .serverError(response.statusCode)
            case 500...599:
                return .serverError(response.statusCode)
            default:
                return .serverError(response.statusCode)
            }
        }
        
        /// URLError에서 NetworkError로 변환
        static func from(urlError: URLError) -> NetworkError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .noConnection
            case .timedOut:
                return .timeout
            case .badURL, .unsupportedURL:
                return .invalidURL
            case .badServerResponse, .cannotParseResponse:
                return .invalidResponse
            default:
                return .unknownError(urlError)
            }
        }
    }
    
    // MARK: - Supporting Types
    
    /// 오류 심각도 레벨
    public enum ErrorSeverity {
        /// 낮은 심각도 - 일시적이거나 사용자가 해결 가능
        case low
        /// 중간 심각도 - 사용자 개입이 필요하거나 기능 제한
        case medium
        /// 높은 심각도 - 시스템 오류나 개발자 개입 필요
        case high
    }
    
    /// 오류 카테고리
    public enum ErrorCategory {
        /// 클라이언트 측 오류 (앱 코드 문제)
        case client
        /// 인증/권한 관련 오류
        case authentication
        /// 네트워크 연결 오류
        case network
        /// 서버 측 오류
        case server
        /// 요청 빈도 제한 오류
        case rateLimit
        /// 분류되지 않은 오류
        case unknown
    }
