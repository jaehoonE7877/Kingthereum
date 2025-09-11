import Foundation

/// HTTP 요청 메서드를 정의하는 열거형
/// 
/// RESTful API 통신과 블록체인 RPC 호출에서 사용하는 표준 HTTP 메서드를 제공합니다.
/// 각 메서드는 특정한 의미와 용도를 가지며, 서버와의 일관된 통신을 보장합니다.
/// 
/// ## 지원 메서드:
/// - **GET**: 리소스 조회 (읽기 전용)
/// - **POST**: 리소스 생성 또는 데이터 전송
/// - **PUT**: 리소스 전체 업데이트
/// - **DELETE**: 리소스 삭제
/// - **PATCH**: 리소스 부분 업데이트
/// - **HEAD**: 헤더 정보만 조회 (바디 없음)
/// - **OPTIONS**: 지원하는 메서드 확인 (CORS 프리플라이트)
/// 
/// ## 블록체인 컨텍스트에서의 사용:
/// - **POST**: JSON-RPC 호출 (이더리움 노드 통신 표준)
/// - **GET**: RESTful API 엔드포인트 (Etherscan, 토큰 가격 조회 등)
/// 
/// ## 사용 예시:
/// ```swift
/// let rpcMethod: HTTPMethod = .POST  // JSON-RPC 호출
/// let apiMethod: HTTPMethod = .GET   // REST API 조회
/// 
/// // HTTP 헤더 설정
/// urlRequest.httpMethod = rpcMethod.rawValue
/// ```
public enum HTTPMethod: String, CaseIterable, Sendable {
    /// GET - 리소스 조회
    /// 
    /// 서버로부터 리소스를 조회할 때 사용합니다.
    /// 요청 바디 없이 URL 파라미터로 데이터를 전달합니다.
    /// 
    /// **특징:**
    /// - 안전(Safe): 서버 상태를 변경하지 않음
    /// - 멱등(Idempotent): 여러 번 호출해도 같은 결과
    /// - 캐시 가능: 브라우저나 프록시에서 캐싱 지원
    /// 
    /// **블록체인 용도:**
    /// - 토큰 가격 조회 API
    /// - Etherscan API 호출
    /// - 블록 익스플로러 데이터 조회
    case GET = "GET"
    
    /// POST - 데이터 전송/리소스 생성
    /// 
    /// 서버에 데이터를 전송하거나 새로운 리소스를 생성할 때 사용합니다.
    /// 요청 바디에 데이터를 포함하여 전송합니다.
    /// 
    /// **특징:**
    /// - 비안전(Unsafe): 서버 상태 변경 가능
    /// - 비멱등(Non-idempotent): 여러 번 호출 시 다른 결과 가능
    /// - 캐시 불가능: 일반적으로 캐싱하지 않음
    /// 
    /// **블록체인 용도:**
    /// - JSON-RPC 호출 (이더리움 노드 통신 표준)
    /// - 거래 전송 요청
    /// - 스마트 컨트랙트 호출
    case POST = "POST"
    
    /// PUT - 리소스 전체 교체
    /// 
    /// 특정 리소스를 완전히 새로운 내용으로 교체할 때 사용합니다.
    /// 리소스가 존재하지 않으면 생성하고, 존재하면 교체합니다.
    /// 
    /// **특징:**
    /// - 비안전(Unsafe): 서버 상태 변경
    /// - 멱등(Idempotent): 같은 요청 반복 시 동일한 상태
    /// - 전체 교체: 부분 수정이 아닌 완전한 교체
    /// 
    /// **블록체인 용도:**
    /// - 사용자 설정 전체 업데이트
    /// - 지갑 메타데이터 교체
    case PUT = "PUT"
    
    /// DELETE - 리소스 삭제
    /// 
    /// 서버의 특정 리소스를 삭제할 때 사용합니다.
    /// 
    /// **특징:**
    /// - 비안전(Unsafe): 서버 상태 변경
    /// - 멱등(Idempotent): 같은 삭제 요청 반복 시 동일한 결과
    /// - 되돌릴 수 없음: 신중하게 사용 필요
    /// 
    /// **블록체인 용도:**
    /// - 저장된 지갑 삭제
    /// - 트랜잭션 히스토리 정리
    /// - 사용자 설정 초기화
    case DELETE = "DELETE"
    
    /// PATCH - 리소스 부분 수정
    /// 
    /// 리소스의 일부분만 수정할 때 사용합니다.
    /// PUT과 달리 전체가 아닌 특정 필드만 업데이트합니다.
    /// 
    /// **특징:**
    /// - 비안전(Unsafe): 서버 상태 변경
    /// - 멱등성: 구현에 따라 다름 (일반적으로 멱등)
    /// - 부분 수정: 지정된 필드만 변경
    /// 
    /// **블록체인 용도:**
    /// - 지갑 이름만 수정
    /// - 네트워크 활성화 상태만 변경
    /// - 사용자 선호 설정 일부 업데이트
    case PATCH = "PATCH"
    
    /// HEAD - 헤더 정보만 조회
    /// 
    /// GET과 동일하지만 응답 바디 없이 헤더만 반환받습니다.
    /// 리소스 존재 여부나 메타데이터만 확인할 때 사용합니다.
    /// 
    /// **특징:**
    /// - 안전(Safe): 서버 상태 변경 없음
    /// - 멱등(Idempotent): 여러 번 호출해도 동일
    /// - 효율적: 바디 없이 헤더만 전송받아 빠름
    /// 
    /// **블록체인 용도:**
    /// - RPC 엔드포인트 연결 확인
    /// - API 응답 크기 사전 확인
    /// - 서버 헬스체크
    case HEAD = "HEAD"
    
    /// OPTIONS - 지원 메서드 확인
    /// 
    /// 서버가 지원하는 HTTP 메서드를 확인할 때 사용합니다.
    /// 주로 CORS 프리플라이트 요청에서 자동으로 발생합니다.
    /// 
    /// **특징:**
    /// - 안전(Safe): 서버 상태 변경 없음
    /// - 멱등(Idempotent): 항상 동일한 결과
    /// - 메타데이터: 리소스가 아닌 메서드 정보 조회
    /// 
    /// **블록체인 용도:**
    /// - CORS 프리플라이트 (브라우저 자동 처리)
    /// - API 엔드포인트 기능 확인
    /// - 크로스 도메인 요청 사전 검증
    case OPTIONS = "OPTIONS"
    
    // MARK: - Properties
    
    /// 해당 메서드가 서버 상태를 변경하지 않는 안전한 메서드인지 확인
    /// 
    /// 안전한 메서드는 여러 번 호출해도 서버에 부작용이 없습니다.
    /// 캐싱이나 재시도 로직에서 중요한 판단 기준이 됩니다.
    /// 
    /// - Returns: 안전한 메서드면 true (GET, HEAD, OPTIONS)
    public var isSafe: Bool {
        switch self {
        case .GET, .HEAD, .OPTIONS:
            return true
        case .POST, .PUT, .DELETE, .PATCH:
            return false
        }
    }
    
    /// 해당 메서드가 멱등성을 가지는지 확인
    /// 
    /// 멱등한 메서드는 같은 요청을 여러 번 보내도 결과가 동일합니다.
    /// 네트워크 재시도나 에러 복구에서 중요한 특성입니다.
    /// 
    /// - Returns: 멱등한 메서드면 true (GET, HEAD, PUT, DELETE, OPTIONS)
    public var isIdempotent: Bool {
        switch self {
        case .GET, .HEAD, .PUT, .DELETE, .OPTIONS:
            return true
        case .POST, .PATCH:
            return false // 구현에 따라 다르지만 일반적으로 비멱등
        }
    }
    
    /// 해당 메서드가 요청 바디를 가질 수 있는지 확인
    /// 
    /// HTTP 명세상 모든 메서드가 바디를 가질 수 있지만,
    /// 실제로는 관례적으로 특정 메서드들만 바디를 사용합니다.
    /// 
    /// - Returns: 일반적으로 바디를 가지는 메서드면 true
    public var allowsRequestBody: Bool {
        switch self {
        case .POST, .PUT, .PATCH:
            return true
        case .GET, .DELETE, .HEAD, .OPTIONS:
            return false
        }
    }
    
    /// 해당 메서드의 일반적인 사용 목적 설명
    /// 
    /// 개발자가 올바른 메서드를 선택할 수 있도록 도움을 제공합니다.
    /// 
    /// - Returns: 메서드의 주요 사용 목적을 설명하는 문자열
    public var description: String {
        switch self {
        case .GET:
            return "리소스 조회 - 데이터를 읽어올 때 사용"
        case .POST:
            return "데이터 전송 - JSON-RPC 호출이나 리소스 생성 시 사용"
        case .PUT:
            return "전체 교체 - 리소스를 완전히 새로운 내용으로 교체"
        case .DELETE:
            return "삭제 - 리소스를 제거할 때 사용"
        case .PATCH:
            return "부분 수정 - 리소스의 특정 필드만 업데이트"
        case .HEAD:
            return "헤더 조회 - 바디 없이 메타데이터만 확인"
        case .OPTIONS:
            return "옵션 확인 - 지원하는 메서드나 CORS 설정 확인"
        }
    }
}
