import Foundation

/// 앱 설정 관리를 위한 프로토콜
/// API 키, 환경 설정 등을 안전하게 관리
public protocol ConfigurationServiceProtocol: Sendable {
    
    // MARK: - Infura Configuration
    
    /// Infura Project ID
    var infuraProjectID: String { get async }
    
    /// Infura Project Secret (옵션)
    var infuraProjectSecret: String? { get async }
    
    /// 이더리움 메인넷 RPC URL (기본 네트워크용)
    var ethereumRPCURL: String { get }
    
    /// 특정 네트워크에 대한 RPC URL 생성
    /// - Parameter network: 네트워크 타입
    /// - Returns: 해당 네트워크의 RPC URL
    func getRPCURL(for network: NetworkType) async -> String
    
    // MARK: - API Configuration
    
    /// Etherscan API 키
    var etherscanAPIKey: String { get async }
    
    /// Etherscan Base URL
    var etherscanBaseURL: String { get async }
    
    // MARK: - App Configuration
    
    /// 현재 앱 환경 (Development, Staging, Production)
    var currentEnvironment: AppEnvironment { get }
    
    /// 디버그 모드 여부
    var isDebugMode: Bool { get }
}

/// 앱 환경 타입
public enum AppEnvironment: String, CaseIterable, Sendable {
    case development = "development"
    case staging = "staging" 
    case production = "production"
    
    public var displayName: String {
        switch self {
        case .development: return "개발"
        case .staging: return "스테이징"
        case .production: return "운영"
        }
    }
}

/// Infura에서 지원하는 네트워크 타입
public enum NetworkType: String, CaseIterable, Sendable {
    case mainnet
    case sepolia
    case goerli
    case polygon
    case polygonMumbai
    case arbitrum
    case arbitrumGoerli
    case optimism
    case optimismGoerli
    
    public var subdomain: String {
        switch self {
        case .mainnet: return "mainnet"
        case .sepolia: return "sepolia"
        case .goerli: return "goerli"
        case .polygon: return "polygon-mainnet"
        case .polygonMumbai: return "polygon-mumbai"
        case .arbitrum: return "arbitrum-mainnet"
        case .arbitrumGoerli: return "arbitrum-goerli"
        case .optimism: return "optimism-mainnet"
        case .optimismGoerli: return "optimism-goerli"
        }
    }
    
    public var displayName: String {
        switch self {
        case .mainnet: return "이더리움 메인넷"
        case .sepolia: return "Sepolia 테스트넷"
        case .goerli: return "Goerli 테스트넷"
        case .polygon: return "Polygon 메인넷"
        case .polygonMumbai: return "Polygon Mumbai 테스트넷"
        case .arbitrum: return "Arbitrum 메인넷"
        case .arbitrumGoerli: return "Arbitrum Goerli 테스트넷"
        case .optimism: return "Optimism 메인넷"
        case .optimismGoerli: return "Optimism Goerli 테스트넷"
        }
    }
}