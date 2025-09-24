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
public enum ConfigurationError: Error, Sendable, CustomStringConvertible {
    case missingValue(key: String)
    case invalidValue(key: String)
    
    public var description: String {
        switch self {
        case .missingValue(let key):
            return "필수 설정 값이 비어 있습니다: \(key)"
        case .invalidValue(let key):
            return "설정 값이 올바르지 않습니다: \(key)"
        }
    }
}

public final class ConfigurationService: ConfigurationServiceProtocol, Sendable {
    
    // MARK: - Properties
    
    /// 현재 앱이 실행되는 환경 (개발/스테이징/운영)
    public let currentEnvironment: AppEnvironment
    
    /// 디버그 모드 여부 (컴파일 타임에 결정)
    public let isDebugMode: Bool
    
    private let cachedInfuraProjectID: String?
    private let cachedInfuraProjectSecret: String?
    private let cachedEtherscanAPIKey: String?
    private let cachedEtherscanBaseURL: String
    
    // MARK: - Initialization
    
    /// 환경에 따른 초기화
    /// 컴파일 타임 플래그를 사용하여 안전하게 환경을 구분합니다.
    public init(processInfo: ProcessInfo = .processInfo, bundle: Bundle = .main) {
        #if DEBUG
        self.currentEnvironment = .development
        self.isDebugMode = true
        #else
        self.currentEnvironment = .production
        self.isDebugMode = false
        #endif
        
        self.cachedInfuraProjectID = ConfigurationService.resolveValue(
            forKey: "INFURA_PROJECT_ID",
            environment: processInfo.environment,
            bundle: bundle
        )
        self.cachedInfuraProjectSecret = ConfigurationService.resolveValue(
            forKey: "INFURA_PROJECT_SECRET",
            environment: processInfo.environment,
            bundle: bundle
        )
        self.cachedEtherscanAPIKey = ConfigurationService.resolveValue(
            forKey: "ETHERSCAN_API_KEY",
            environment: processInfo.environment,
            bundle: bundle
        )
        self.cachedEtherscanBaseURL = ConfigurationService.resolveEtherscanBaseURL(for: currentEnvironment)
        
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
    public func infuraProjectID() throws -> String {
        guard let projectID = cachedInfuraProjectID, !projectID.isEmpty else {
            Logger.error(ConfigurationError.missingValue(key: "INFURA_PROJECT_ID").description)
            throw ConfigurationError.missingValue(key: "INFURA_PROJECT_ID")
        }
        return projectID
    }
    
    /// Infura 프로젝트 시크릿 (선택사항)
    /// 
    /// 보안이 중요한 환경에서만 사용되는 선택적 설정입니다.
    /// 없어도 기본 Infura 서비스는 정상적으로 작동합니다.
    /// 
    /// - Returns: Infura 프로젝트 시크릿 또는 nil
    public func infuraProjectSecret() -> String? {
        guard let secret = cachedInfuraProjectSecret, !secret.isEmpty else {
            return nil
        }
        return secret
    }
    
    /// 메인넷 이더리움 RPC URL (동기적 접근)
    /// 
    /// 앱 초기화 단계에서 즉시 필요한 경우를 위한 동기적 메서드입니다.
    /// async 버전과 동일한 로직을 사용하지만 동기적으로 처리합니다.
    /// 
    /// - Returns: 이더리움 메인넷 RPC URL
    /// - Throws: fatalError (설정되지 않은 경우)
    public func ethereumRPCURL() throws -> String {
        let projectID = try infuraProjectID()
        return "https://mainnet.infura.io/v3/\(projectID)"
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
    public func getRPCURL(for network: NetworkType) throws -> String {
        let projectID = try infuraProjectID()
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
    public func etherscanAPIKey() throws -> String {
        guard let apiKey = cachedEtherscanAPIKey, !apiKey.isEmpty else {
            Logger.error(ConfigurationError.missingValue(key: "ETHERSCAN_API_KEY").description)
            throw ConfigurationError.missingValue(key: "ETHERSCAN_API_KEY")
        }
        return apiKey
    }
    
    /// 환경별 Etherscan API 베이스 URL
    /// 
    /// 개발/스테이징 환경에서는 테스트넷 API를,
    /// 운영 환경에서는 메인넷 API를 사용합니다.
    /// 
    /// - Returns: 환경에 적합한 Etherscan API 베이스 URL
    public func etherscanBaseURL() -> String {
        Logger.debug("Etherscan Base URL: \(currentEnvironment.displayName) → \(cachedEtherscanBaseURL)")
        return cachedEtherscanBaseURL
    }

    // MARK: - Helpers

    private static func resolveValue(
        forKey key: String,
        environment: [String: String],
        bundle: Bundle
    ) -> String? {
        if let envValue = environment[key]?.trimmingCharacters(in: .whitespacesAndNewlines), !envValue.isEmpty {
            Logger.debug("\(key)를 환경변수에서 로드")
            return envValue
        }
        if let bundleValue = bundle.object(forInfoDictionaryKey: key) as? String,
           !bundleValue.isEmpty,
           !bundleValue.hasPrefix("$(") {
            Logger.debug("\(key)를 Bundle에서 로드")
            return bundleValue
        }
        return nil
    }
    
    private static func resolveEtherscanBaseURL(for environment: AppEnvironment) -> String {
        switch environment {
        case .development, .staging:
            return "https://api-sepolia.etherscan.io/api"
        case .production:
            return "https://api.etherscan.io/api"
        }
    }
}
