import Foundation
import Factory

// MARK: - Core Services Factory Registration

/// Core 모듈의 의존성 주입 컨테이너 확장
/// 
/// Factory 패턴을 사용하여 Core 모듈의 서비스들을 등록하고 관리합니다.
/// Swift Concurrency 환경에서 안전하게 작동하며, 서비스의 생명주기를 적절히 관리합니다.
/// 
/// ## 등록된 서비스:
/// - ConfigurationService: 앱 설정 및 환경 변수 관리
/// - DisplayModeService: 다크/라이트 모드 관리 (추가 예정)
/// 
/// ## 설계 원칙:
/// - 인터페이스 분리: 프로토콜을 통한 추상화
/// - 단일 책임: 각 서비스는 하나의 책임만 담당
/// - 의존성 역전: 구체 타입이 아닌 추상화에 의존
public extension Container {
    
    /// 앱 전반의 설정과 환경 변수를 관리하는 서비스
    /// 
    /// API 키, 네트워크 설정, 환경별 구성 등을 중앙에서 관리합니다.
    /// Singleton 패턴으로 구현되어 앱 전체에서 일관된 설정을 보장합니다.
    /// 
    /// ## 주요 기능:
    /// - Infura 프로젝트 설정 관리
    /// - 네트워크별 RPC URL 제공
    /// - 환경별 API 키 관리
    /// - 앱 환경 (개발/스테이징/운영) 구분
    /// 
    /// - Returns: ConfigurationServiceProtocol을 준수하는 서비스 인스턴스
    var configurationService: Factory<any ConfigurationServiceProtocol> {
        self { ConfigurationService() as any ConfigurationServiceProtocol }
            .singleton
    }
    
    /// 다크 모드/라이트 모드 상태를 관리하는 서비스
    ///
    /// Core 모듈에서 직접 Factory를 등록하여, App 모듈 등에서
    /// 중복 정의 없이 동일한 인스턴스를 사용할 수 있도록 합니다.
    var displayModeService: Factory<DisplayModeService> {
        self {
            MainActor.assumeIsolated {
                DisplayModeService()
            }
        }
            .singleton
    }
}

// MARK: - Swift Concurrency Support

/// Swift Concurrency 환경에서의 안전한 의존성 주입을 위한 헬퍼 확장
/// 
/// async/await 컨텍스트에서 Factory를 안전하게 사용할 수 있도록 
/// 명시적인 해결(resolution) 메서드를 제공합니다.
/// 
/// ## 필요성:
/// - Factory의 () 호출은 @MainActor가 필요할 수 있음
/// - async 함수에서의 명확한 의존성 해결
/// - 컴파일 타임 안전성 향상
public extension Container {
    
    /// async 컨텍스트에서 안전하게 Configuration 서비스를 해결
    /// 
    /// Factory를 직접 호출하는 대신 이 메서드를 사용하여
    /// Swift Concurrency 환경에서의 안전성을 보장합니다.
    /// 
    /// - Returns: Sendable을 준수하는 ConfigurationServiceProtocol 인스턴스
    /// 
    /// ## 사용 예시:
    /// ```swift
    /// let config = container.resolveConfigurationService()
    /// let rpcURL = try config.getRPCURL(for: .mainnet)
    /// ```
    func resolveConfigurationService() -> any ConfigurationServiceProtocol {
        return configurationService()
    }
    
    /// 모든 Core 서비스를 한 번에 예열(warm-up)하는 유틸리티 메서드
    /// 
    /// 앱 시작 시 서비스들을 미리 초기화하여 첫 번째 접근 시의 지연을 방지합니다.
    /// Singleton 서비스들의 초기화 비용을 앱 시작 시점으로 분산시킵니다.
    /// 
    /// ## 사용 시점:
    /// - 앱 시작 시 (AppDelegate 또는 App 구조체)
    /// - 백그라운드에서 비동기적으로 실행 권장
    func warmUpCoreServices() {
        // Configuration 서비스 예열
        _ = configurationService()
        
        // 추가 서비스들도 여기서 예열
        // _ = displayModeService()
        
        Logger.debug("Core 서비스 예열 완료")
    }
}
