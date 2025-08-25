import Foundation

/// ConfigurationServiceProtocol의 구현체
/// 앱 설정과 API 키를 안전하게 관리
/// Sendable 준수로 Actor 간 안전한 전달 보장
public final class ConfigurationService: ConfigurationServiceProtocol, Sendable {
    
    // MARK: - Properties
    
    public let currentEnvironment: AppEnvironment
    public let isDebugMode: Bool
    
    private let userDefaultsKey = "AppConfiguration"
    
    // MARK: - Initialization
    
    public init() {
        #if DEBUG
        self.currentEnvironment = .development
        self.isDebugMode = true
        #else
        self.currentEnvironment = .production
        self.isDebugMode = false
        #endif
    }
    
    // MARK: - Infura Configuration
    
    public var infuraProjectID: String {
        get async {
            // 1순위: 환경변수에서 읽기 (배포용)
            if let envProjectID = ProcessInfo.processInfo.environment["INFURA_PROJECT_ID"], !envProjectID.isEmpty {
                return envProjectID
            }
            
            // 2순위: Bundle의 Info.plist에서 읽기 (Xcode Build Settings를 통해 주입)
            if let projectID = Bundle.main.object(forInfoDictionaryKey: "INFURA_PROJECT_ID") as? String, !projectID.isEmpty {
                return projectID
            }
            
            // 3순위: 개발용 플레이스홀더 (실제 사용 시 오류 발생)
            fatalError("INFURA_PROJECT_ID가 설정되지 않았습니다. Xcode Build Settings에서 INFURA_PROJECT_ID를 설정하거나 환경변수를 추가하세요.")
        }
    }
    
    public var infuraProjectSecret: String? {
        get async {
            // 1순위: 환경변수에서 읽기
            if let envSecret = ProcessInfo.processInfo.environment["INFURA_PROJECT_SECRET"], !envSecret.isEmpty {
                return envSecret
            }
            
            // 2순위: Bundle의 Info.plist에서 읽기 (Xcode Build Settings를 통해 주입)
            if let secret = Bundle.main.object(forInfoDictionaryKey: "INFURA_PROJECT_SECRET") as? String, !secret.isEmpty {
                return secret
            }
            
            // Secret은 선택사항이므로 nil 반환
            return nil
        }
    }
    
    public var ethereumRPCURL: String {
        // 동기적으로 기본 이더리움 RPC URL 제공
        // 환경변수나 Bundle에서 프로젝트 ID를 읽어올 수 없는 경우 오류 발생
        if let envProjectID = ProcessInfo.processInfo.environment["INFURA_PROJECT_ID"], !envProjectID.isEmpty {
            return "https://mainnet.infura.io/v3/\(envProjectID)"
        }
        
        if let projectID = Bundle.main.object(forInfoDictionaryKey: "INFURA_PROJECT_ID") as? String, !projectID.isEmpty {
            return "https://mainnet.infura.io/v3/\(projectID)"
        }
        
        fatalError("INFURA_PROJECT_ID가 설정되지 않았습니다. Xcode Build Settings에서 INFURA_PROJECT_ID를 설정하거나 환경변수를 추가하세요.")
    }
    
    public func getRPCURL(for network: NetworkType) async -> String {
        let projectID = await infuraProjectID
        return "https://\(network.subdomain).infura.io/v3/\(projectID)"
    }
    
    // MARK: - API Configuration
    
    public var etherscanAPIKey: String {
        get async {
            // 1순위: 환경변수에서 읽기
            if let envKey = ProcessInfo.processInfo.environment["ETHERSCAN_API_KEY"], !envKey.isEmpty {
                return envKey
            }
            
            // 2순위: Bundle의 Info.plist에서 읽기 (Xcode Build Settings를 통해 주입)
            if let apiKey = Bundle.main.object(forInfoDictionaryKey: "ETHERSCAN_API_KEY") as? String, !apiKey.isEmpty {
                return apiKey
            }
            
            // API 키가 설정되지 않은 경우 오류 발생
            fatalError("ETHERSCAN_API_KEY가 설정되지 않았습니다. Xcode Build Settings에서 ETHERSCAN_API_KEY를 설정하거나 환경변수를 추가하세요.")
        }
    }
    
    public var etherscanBaseURL: String {
        get async {
            switch currentEnvironment {
            case .development, .staging:
                return "https://api-goerli.etherscan.io/api"
            case .production:
                return "https://api.etherscan.io/api"
            }
        }
    }
}