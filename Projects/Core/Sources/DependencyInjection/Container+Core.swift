import Foundation
import Factory

// MARK: - Core Services Factory Registration

/// Core 모듈의 서비스들을 Factory 방식으로 등록
/// Swift Concurrency 환경에서 안전한 의존성 주입 제공
public extension Container {
    
    /// Configuration 서비스
    /// 앱 설정 및 환경 변수 관리
    /// - Note: Singleton으로 관리되어 앱 전체에서 동일한 설정 인스턴스 사용
    var configurationService: Factory<any ConfigurationServiceProtocol> {
        self { ConfigurationService() as any ConfigurationServiceProtocol }
            .singleton
    }
    
}

// MARK: - Async-Safe Container Helpers

/// Swift Concurrency 환경에서의 안전한 Factory 사용을 위한 확장
public extension Container {
    
    
    /// async 컨텍스트에서 안전하게 Configuration 서비스를 가져오는 헬퍼 메서드
    /// - Returns: Sendable을 준수하는 ConfigurationServiceProtocol 인스턴스
    func resolveConfigurationService() -> any ConfigurationServiceProtocol {
        return configurationService()
    }
}