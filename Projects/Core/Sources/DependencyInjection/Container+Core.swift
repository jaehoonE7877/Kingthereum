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
    
    /// HTTP 서비스
    /// HTTP 통신 담당 (Sendable 준수로 Actor 간 안전한 전달 보장)
    /// - Note: URLSession 기반으로 비동기 HTTP 요청 처리
    // HTTP 서비스 제거 (더이상 사용되지 않음)
    
    /// RPC 서비스
    /// JSON-RPC 통신 담당 (이더리움 블록체인 통신)
    /// - Note: HTTPService에 의존하며, Sendable 준수로 동시성 안전성 확보
    // RPC 서비스 제거 (더이상 사용되지 않음)
    
    /// Network 서비스 (통합)
    /// 기존 인터페이스 호환성을 위한 통합 서비스
    /// - Note: HTTP와 RPC 서비스를 조합하여 단일 네트워크 인터페이스 제공
    // Network 서비스 제거 (더이상 사용되지 않음)
}

// MARK: - Async-Safe Container Helpers

/// Swift Concurrency 환경에서의 안전한 Factory 사용을 위한 확장
public extension Container {
    
    // HTTP 서비스 헬퍼 제거 (더이상 사용되지 않음)
    
    // RPC 서비스 헬퍼 제거 (더이상 사용되지 않음)
    
    // Network 서비스 헬퍼 제거 (더이상 사용되지 않음)
    
    /// async 컨텍스트에서 안전하게 Configuration 서비스를 가져오는 헬퍼 메서드
    /// - Returns: Sendable을 준수하는 ConfigurationServiceProtocol 인스턴스
    func resolveConfigurationService() -> any ConfigurationServiceProtocol {
        return configurationService()
    }
}