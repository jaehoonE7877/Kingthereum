import Foundation

// MARK: - App Environment Configuration

/// 애플리케이션 실행 환경을 구분하는 열거형
/// 
/// 개발, 스테이징, 프로덕션 환경에 따라 다른 설정과 동작을 제공합니다.
/// 빌드 구성에 따라 적절한 환경이 선택되며, 각 환경은 고유한 특성을 가집니다.
/// 
/// ## 지원 환경:
/// - `.development`: 로컬 개발 환경, 디버깅 기능 활성화
/// - `.staging`: 테스트 서버 환경, 프로덕션 유사 환경에서 검증
/// - `.production`: 실제 서비스 환경, 최적화된 성능과 보안
/// 
/// ## 사용 예시:
/// ```swift
/// let env = AppEnvironment.development
/// if env.isProduction {
///     // 프로덕션 전용 로직
/// }
/// ```
public enum AppEnvironment: String, CaseIterable, Sendable {
    /// 로컬 개발 환경 - 디버깅 및 개발 도구 활성화
    case development = "development"
    
    /// 스테이징 환경 - 프로덕션 유사 환경에서의 통합 테스트
    case staging = "staging"
    
    /// 프로덕션 환경 - 실제 사용자 대상 서비스
    case production = "production"
    
    /// 사용자에게 표시되는 환경 이름 (한국어)
    /// 
    /// 설정 화면이나 디버그 정보에서 사용자 친화적인 이름을 제공합니다.
    /// 
    /// - Returns: 환경에 대응하는 한국어 표시명
    public var displayName: String {
        switch self {
        case .development:
            return "개발 환경"
        case .staging:
            return "스테이징 환경"
        case .production:
            return "운영 환경"
        }
    }
    
    /// 영문 환경 이름 (시스템/로그용)
    /// 
    /// 시스템 로그, API 헤더, 설정 파일 등에서 사용하는 영문 이름입니다.
    /// 
    /// - Returns: 환경에 대응하는 영문 표시명
    public var englishName: String {
        switch self {
        case .development:
            return "Development"
        case .staging:
            return "Staging"
        case .production:
            return "Production"
        }
    }
    
    /// 프로덕션 환경 여부 확인
    /// 
    /// 프로덕션 환경에서만 활성화되어야 하는 기능들을 제어할 때 사용합니다.
    /// 예: 분석 도구, 크래시 리포팅, 성능 모니터링 등
    /// 
    /// - Returns: 프로덕션 환경이면 true, 그렇지 않으면 false
    public var isProduction: Bool {
        return self == .production
    }
    
    /// 개발 환경 여부 확인
    /// 
    /// 개발 중에만 필요한 기능들을 제어할 때 사용합니다.
    /// 예: 디버그 메뉴, 테스트 데이터, Mock 서비스 등
    /// 
    /// - Returns: 개발 환경이면 true, 그렇지 않으면 false
    public var isDevelopment: Bool {
        return self == .development
    }
    
    /// 로깅 레벨 결정
    /// 
    /// 각 환경에 적합한 로깅 상세도를 제공합니다.
    /// 개발 환경에서는 상세한 로그, 프로덕션에서는 필수 로그만 기록합니다.
    /// 
    /// - Returns: 해당 환경에 적합한 로그 레벨
    public var logLevel: LogLevel {
        switch self {
        case .development:
            return .verbose
        case .staging:
            return .info
        case .production:
            return .error
        }
    }
}

/// 로그 레벨 정의
public enum LogLevel: String, CaseIterable {
    case verbose = "verbose"
    case info = "info"
    case warning = "warning"
    case error = "error"
    case off = "off"
}

// MARK: - Infura Configuration

/// Infura 블록체인 서비스 설정 정보
/// 
/// 이더리움 및 기타 블록체인 네트워크 접근을 위한 Infura API 설정을 관리합니다.
/// 프로젝트 ID와 시크릿을 안전하게 보관하고, 다양한 네트워크 연결에 활용됩니다.
/// 
/// ## 보안 주의사항:
/// - 프로젝트 시크릿은 민감한 정보이므로 안전하게 관리 필요
/// - 소스 코드에 직접 하드코딩하지 말고 환경변수 또는 키체인 사용 권장
/// - 각 환경별로 다른 프로젝트 ID 사용 권장
/// 
/// ## 사용 예시:
/// ```swift
/// let config = InfuraConfig(
///     projectId: "your-project-id",
///     projectSecret: "your-project-secret"
/// )
/// let rpcUrl = config.getRPCURL(for: .mainnet)
/// ```
public struct InfuraConfig: Sendable {
    /// Infura 프로젝트 ID (필수)
    /// 
    /// Infura 대시보드에서 발급받는 프로젝트 고유 식별자입니다.
    /// 모든 API 호출에서 인증에 사용됩니다.
    public let projectId: String
    
    /// Infura 프로젝트 시크릿 (선택사항)
    /// 
    /// 추가 보안이 필요한 경우 사용하는 시크릿 키입니다.
    /// 일반적인 읽기 전용 작업에서는 필수가 아닙니다.
    public let projectSecret: String?
    
    /// Infura 설정 초기화
    /// 
    /// - Parameters:
    ///   - projectId: Infura 프로젝트 ID (필수)
    ///   - projectSecret: Infura 프로젝트 시크릿 (선택사항)
    public init(projectId: String, projectSecret: String? = nil) {
        self.projectId = projectId
        self.projectSecret = projectSecret
    }
    
    /// 특정 네트워크에 대한 RPC URL 생성
    /// 
    /// Infura에서 지원하는 다양한 블록체인 네트워크의 RPC 엔드포인트를 생성합니다.
    /// 
    /// - Parameter network: 대상 블록체인 네트워크
    /// - Returns: 완전한 RPC URL 문자열
    /// 
    /// ## 지원 네트워크:
    /// - 이더리움: mainnet, sepolia, goerli
    /// - Polygon: polygon-mainnet, polygon-mumbai
    /// - Arbitrum: arbitrum-mainnet, arbitrum-goerli
    /// - Optimism: optimism-mainnet, optimism-goerli
    public func getRPCURL(for network: InfuraNetwork) -> String {
        return "https://\(network.subdomain).infura.io/v3/\(projectId)"
    }
    
    /// WebSocket 연결 URL 생성
    /// 
    /// 실시간 블록체인 이벤트 구독을 위한 WebSocket 엔드포인트를 생성합니다.
    /// 
    /// - Parameter network: 대상 블록체인 네트워크
    /// - Returns: WebSocket URL 문자열
    public func getWebSocketURL(for network: InfuraNetwork) -> String {
        return "wss://\(network.subdomain).infura.io/ws/v3/\(projectId)"
    }
    
    /// 설정 유효성 검증
    /// 
    /// 프로젝트 ID의 형식과 길이가 올바른지 확인합니다.
    /// 
    /// - Returns: 설정이 유효하면 true, 그렇지 않으면 false
    public var isValid: Bool {
        return !projectId.isEmpty && projectId.count >= 32
    }
}

/// Infura에서 지원하는 블록체인 네트워크
public enum InfuraNetwork: String, CaseIterable {
    case mainnet
    case sepolia
    case goerli
    case polygonMainnet = "polygon-mainnet"
    case polygonMumbai = "polygon-mumbai"
    case arbitrumMainnet = "arbitrum-mainnet"
    case arbitrumGoerli = "arbitrum-goerli"
    case optimismMainnet = "optimism-mainnet"
    case optimismGoerli = "optimism-goerli"
    
    /// Infura URL에서 사용하는 서브도메인
    public var subdomain: String {
        return rawValue
    }
    
    /// 사용자에게 표시되는 네트워크 이름
    public var displayName: String {
        switch self {
        case .mainnet: return "이더리움 메인넷"
        case .sepolia: return "Sepolia 테스트넷"
        case .goerli: return "Goerli 테스트넷"
        case .polygonMainnet: return "Polygon 메인넷"
        case .polygonMumbai: return "Polygon Mumbai 테스트넷"
        case .arbitrumMainnet: return "Arbitrum 메인넷"
        case .arbitrumGoerli: return "Arbitrum Goerli 테스트넷"
        case .optimismMainnet: return "Optimism 메인넷"
        case .optimismGoerli: return "Optimism Goerli 테스트넷"
        }
    }
}