import Foundation

/// ConfigurationServiceProtocol의 구체적인 구현체
/// 
/// 앱의 환경별 설정과 API 키를 안전하게 관리합니다.
/// 다층 구조의 설정 로딩 전략을 사용하여 보안과 유연성을 동시에 확보합니다.
/// 
/// ## 설정 로딩 우선순위:
/// 1. 환경변수 (ProcessInfo.processInfo.environment)
/// 2. Bundle의 Info.plist (Xcode Build Settings 주입)
/// 3. 기본값 또는 오류 처리
/// 
/// ## 보안 특성:
/// - API 키는 소스 코드에 하드코딩되지 않음
/// - Sendable 준수로 동시성 안전성 보장
/// - 프로덕션 빌드에서 디버그 정보 제거
public final class ConfigurationService: ConfigurationServiceProtocol, Sendable {
    
    // MARK: - Properties
    
    /// 현재 앱이 실행되는 환경 (개발/스테이징/운영)
    public let currentEnvironment: AppEnvironment
    
    /// 디버그 모드 여부 (컴파일 타임에 결정)
    public let isDebugMode: Bool
    
    /// UserDefaults 저장용 키 (향후 확장용)
    private let userDefaultsKey = "AppConfiguration"
    
    // MARK: - Initialization
    
    /// 환경에 따른 초기화
    /// 컴파일 타임 플래그를 사용하여 안전하게 환경을 구분합니다.
    public init() {
        #if DEBUG
        self.currentEnvironment = .development
        self.isDebugMode = true
        #else
        self.currentEnvironment = .production
        self.isDebugMode = false
        #endif
        
        Logger.debug("ConfigurationService 초기화 완료 - 환경: \(currentEnvironment.displayName)")
    }
    
    // MARK: - Infura Configuration
    
    /// Infura 프로젝트 ID를 안전하게 로드
    /// 
    /// 다층 구조의 설정 로딩을 통해 환경변수 → Bundle → 오류 순서로 처리합니다.
    /// API 키가 소스 코드에 노출되지 않도록 보장합니다.
    /// 
    /// - Returns: Infura 프로젝트 ID
    /// - Throws: fatalError (설정되지 않은 경우)
    /// 
    /// ## 설정 방법:
    /// 1. Xcode Build Settings에서 INFURA_PROJECT_ID 설정
    /// 2. 환경변수로 INFURA_PROJECT_ID 설정
    public var infuraProjectID: String {
        get async {
            // 1순위: 환경변수에서 읽기 (배포용)
            if let envProjectID = ProcessInfo.processInfo.environment["INFURA_PROJECT_ID"], 
               !envProjectID.isEmpty {
                Logger.debug("Infura Project ID를 환경변수에서 로드")
                return envProjectID
            }
            
            // 2순위: Bundle의 Info.plist에서 읽기 (Xcode Build Settings를 통해 주입)
            if let projectID = Bundle.main.object(forInfoDictionaryKey: "INFURA_PROJECT_ID") as? String, 
               !projectID.isEmpty {
                Logger.debug("Infura Project ID를 Bundle에서 로드")
                return projectID
            }
            
            // 설정되지 않은 경우 명확한 오류 메시지와 함께 종료
            Logger.error("INFURA_PROJECT_ID 설정 오류")
            fatalError("""
                INFURA_PROJECT_ID가 설정되지 않았습니다.
                
                설정 방법:
                1. Xcode → Project Settings → Build Settings → User-Defined에서 INFURA_PROJECT_ID 추가
                2. 환경변수로 export INFURA_PROJECT_ID=your_project_id 설정
                
                자세한 내용은 README.md를 참조하세요.
                """)
        }
    }
    
    /// Infura 프로젝트 시크릿 (선택사항)
    /// 
    /// 보안이 중요한 환경에서만 사용되는 선택적 설정입니다.
    /// 없어도 기본 Infura 서비스는 정상적으로 작동합니다.
    /// 
    /// - Returns: Infura 프로젝트 시크릿 또는 nil
    public var infuraProjectSecret: String? {
        get async {
            // 1순위: 환경변수에서 읽기
            if let envSecret = ProcessInfo.processInfo.environment["INFURA_PROJECT_SECRET"], 
               !envSecret.isEmpty {
                Logger.debug("Infura Project Secret을 환경변수에서 로드")
                return envSecret
            }
            
            // 2순위: Bundle의 Info.plist에서 읽기
            if let secret = Bundle.main.object(forInfoDictionaryKey: "INFURA_PROJECT_SECRET") as? String, 
               !secret.isEmpty {
                Logger.debug("Infura Project Secret을 Bundle에서 로드")
                return secret
            }
            
            // Secret은 선택사항이므로 nil 반환 (오류가 아님)
            Logger.debug("Infura Project Secret 설정되지 않음 (선택사항)")
            return nil
        }
    }
    
    /// 메인넷 이더리움 RPC URL (동기적 접근)
    /// 
    /// 앱 초기화 단계에서 즉시 필요한 경우를 위한 동기적 메서드입니다.
    /// async 버전과 동일한 로직을 사용하지만 동기적으로 처리합니다.
    /// 
    /// - Returns: 이더리움 메인넷 RPC URL
    /// - Throws: fatalError (설정되지 않은 경우)
    public var ethereumRPCURL: String {
        // 동기적으로 기본 이더리움 RPC URL 제공
        if let envProjectID = ProcessInfo.processInfo.environment["INFURA_PROJECT_ID"], 
           !envProjectID.isEmpty {
            return "https://mainnet.infura.io/v3/\(envProjectID)"
        }
        
        if let projectID = Bundle.main.object(forInfoDictionaryKey: "INFURA_PROJECT_ID") as? String, 
           !projectID.isEmpty {
            return "https://mainnet.infura.io/v3/\(projectID)"
        }
        
        Logger.error("이더리움 RPC URL 생성 실패")
        fatalError("""
            INFURA_PROJECT_ID가 설정되지 않아 RPC URL을 생성할 수 없습니다.
            
            설정 방법은 infuraProjectID 속성의 문서를 참조하세요.
            """)
    }
    
    /// 특정 네트워크에 대한 RPC URL 생성
    /// 
    /// 다양한 블록체인 네트워크 (메인넷, 테스트넷, L2 등)에 대한
    /// Infura RPC URL을 동적으로 생성합니다.
    /// 
    /// - Parameter network: 대상 네트워크 타입
    /// - Returns: 해당 네트워크의 완전한 RPC URL
    /// 
    /// ## 지원 네트워크:
    /// - 이더리움: mainnet, sepolia, goerli
    /// - Polygon: polygon-mainnet, polygon-mumbai
    /// - Arbitrum: arbitrum-mainnet, arbitrum-goerli
    /// - Optimism: optimism-mainnet, optimism-goerli
    public func getRPCURL(for network: NetworkType) async -> String {
        let projectID = await infuraProjectID
        let url = "https://\(network.subdomain).infura.io/v3/\(projectID)"
        
        Logger.debug("RPC URL 생성: \(network.displayName) → \(url)")
        return url
    }
    
    // MARK: - API Configuration
    
    /// Etherscan API 키 로드
    /// 
    /// 블록체인 데이터 조회를 위한 Etherscan API 키를 안전하게 로드합니다.
    /// 트랜잭션 조회, 잔액 확인, 가스비 추정 등에 사용됩니다.
    /// 
    /// - Returns: Etherscan API 키
    /// - Throws: fatalError (설정되지 않은 경우)
    public var etherscanAPIKey: String {
        get async {
            // 1순위: 환경변수에서 읽기
            if let envKey = ProcessInfo.processInfo.environment["ETHERSCAN_API_KEY"], 
               !envKey.isEmpty {
                Logger.debug("Etherscan API Key를 환경변수에서 로드")
                return envKey
            }
            
            // 2순위: Bundle의 Info.plist에서 읽기
            if let apiKey = Bundle.main.object(forInfoDictionaryKey: "ETHERSCAN_API_KEY") as? String, 
               !apiKey.isEmpty {
                Logger.debug("Etherscan API Key를 Bundle에서 로드")
                return apiKey
            }
            
            // API 키가 설정되지 않은 경우 오류 처리
            Logger.error("ETHERSCAN_API_KEY 설정 오류")
            fatalError("""
                ETHERSCAN_API_KEY가 설정되지 않았습니다.
                
                설정 방법:
                1. https://etherscan.io/apis에서 API 키 발급
                2. Xcode Build Settings에서 ETHERSCAN_API_KEY 설정
                3. 또는 환경변수로 export ETHERSCAN_API_KEY=your_api_key 설정
                """)
        }
    }
    
    /// 환경별 Etherscan API 베이스 URL
    /// 
    /// 개발/스테이징 환경에서는 테스트넷 API를,
    /// 운영 환경에서는 메인넷 API를 사용합니다.
    /// 
    /// - Returns: 환경에 적합한 Etherscan API 베이스 URL
    public var etherscanBaseURL: String {
        get async {
            let baseURL: String
            
            switch currentEnvironment {
            case .development, .staging:
                // 개발/스테이징: Sepolia 테스트넷 사용
                baseURL = "https://api-sepolia.etherscan.io/api"
                
            case .production:
                // 운영: 이더리움 메인넷 사용
                baseURL = "https://api.etherscan.io/api"
            }
            
            Logger.debug("Etherscan Base URL: \(currentEnvironment.displayName) → \(baseURL)")
            return baseURL
        }
    }
}