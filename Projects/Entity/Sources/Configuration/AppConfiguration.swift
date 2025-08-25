import Foundation

/// 앱 환경을 나타내는 열거형
public enum AppEnvironment: String, CaseIterable, Sendable {
    case development = "development"
    case staging = "staging"
    case production = "production"
    
    public var displayName: String {
        switch self {
        case .development:
            return "Development"
        case .staging:
            return "Staging"
        case .production:
            return "Production"
        }
    }
    
    public var isProduction: Bool {
        return self == .production
    }
}

/// 인푸라 설정 정보를 나타내는 모델
public struct InfuraConfig {
    public let projectId: String
    public let projectSecret: String
    
    public init(projectId: String, projectSecret: String) {
        self.projectId = projectId
        self.projectSecret = projectSecret
    }
}