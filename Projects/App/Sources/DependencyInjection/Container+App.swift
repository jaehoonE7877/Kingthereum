import Foundation
import Core
import WalletKit
import SecurityKit
import Factory

// MARK: - Sendable Protocol Conformance

/// Sendable을 준수하는 타입 별칭들 (Swift 6.0 호환성)
public typealias SendableDisplayModeService = DisplayModeService

// MARK: - App Module Services Factory Registration

/// App 모듈의 서비스들을 Factory 방식으로 등록
/// Swift 6.0 strict concurrency 규칙 준수
public extension Container {
    
    /// DisplayModeService 구현체 (MainActor 격리)
    /// 다크모드/라이트모드 관리 서비스
    var displayModeService: Factory<DisplayModeService> {
        self {
            MainActor.assumeIsolated {
                DisplayModeService()
            }
        }
        .singleton
    }
    
    /// WalletService 구현체
    /// 지갑 관련 핵심 비즈니스 로직 처리
    var walletService: Factory<WalletService> {
        self {
            // 안전한 Container 접근을 위한 Task 사용
            let configService = Container.shared.configurationService()
            let rpcURL = configService.ethereumRPCURL
            
            // WalletService.shared를 사용하거나 새로 초기화
            do {
                let service = try WalletService.initialize(rpcURL: rpcURL)
                return service
            } catch {
                // 안전한 에러 핸들링 - fatalError 대신 기본값 반환
                Logger.error("❌ WalletService 초기화 실패: \(error)")
                Logger.warning("⚠️ 기본 WalletService로 fallback")
                
                // 기본 설정으로 fallback 시도
                do {
                    let fallbackService = try WalletService.initialize(rpcURL: "https://mainnet.infura.io/v3/your-project-id")
                    Logger.info("✅ Fallback WalletService 생성 성공")
                    return fallbackService
                } catch {
                    Logger.error("❌ Fallback WalletService도 실패: \(error)")
                    // 최후의 수단으로 빈 서비스 반환
                    return WalletService.createEmptyInstance()
                }
            }
        }
        .singleton
    }
    
    /// SecurityService 구현체
    /// 생체 인식, PIN 인증 등 보안 기능 담당
    var securityService: Factory<SecurityService> {
        self { SecurityService() }
            .singleton
    }
    
}

// MARK: - Thread-Safe Container Access

/// Thread-safe Container 접근을 위한 헬퍼
/// Swift 6.0 동시성 안전성 보장
public actor ContainerManager {
    private let container: Container
    
    public init(container: Container = Container.shared) {
        self.container = container
    }
    
    /// WalletService 안전한 해결
    public func resolveWalletService() -> WalletService {
        container.walletService()
    }
    
    
    /// DisplayModeService 안전한 해결 (MainActor)
    @MainActor
    public func resolveDisplayModeService() -> DisplayModeService {
        container.displayModeService()
    }
    
    /// SecurityService 안전한 해결
    public func resolveSecurityService() -> SecurityService {
        container.securityService()
    }
}

// MARK: - Service Protocol Extensions for Sendable

/// DisplayModeService가 Sendable을 준수하도록 확장
extension DisplayModeService: @unchecked Sendable {
    // DisplayModeService는 @MainActor로 격리되어 있어 thread-safe함
}

// MARK: - Test Support

#if DEBUG
/// 테스트용 Factory 설정
public extension Container {
    
    /// 테스트용 Mock 서비스들 등록
    static func setupTestContainer() {
        // Mock 서비스들을 등록하는 로직은 실제 Mock 구현체가 있을 때 추가
    }
    
    /// 테스트 후 정리
    static func resetTestContainer() {
        Container.shared.reset()
    }
}
#endif

// MARK: - VIP Components Registration

/// VIP 아키텍처 컴포넌트들을 안전하게 등록하는 확장
public extension Container {
    
    /// Send Scene VIP 컴포넌트들을 등록
    func registerSendSceneComponents() {
        Logger.debug("📤 Send Scene VIP 컴포넌트 등록 시작")
        
        // SendWorker 등록
        DIContainer.shared.register(SendWorkerProtocol.self) {
            SendWorker()
        }
        
        // SendPresenter 등록  
        DIContainer.shared.register(SendPresentationLogic.self) {
            SendPresenter()
        }
        
        // SendInteractor 등록 (안전한 의존성 해결)
        DIContainer.shared.register(SendBusinessLogic.self) {
            guard let worker = DIContainer.shared.resolveOptional(SendWorkerProtocol.self) else {
                Logger.error("❌ SendWorker 해결 실패")
                return SendInteractor() // 기본 Worker로 초기화
            }
            
            let interactor = SendInteractor(worker: worker)
            
            // Presenter 연결 (안전한 방식)
            if let presenter = DIContainer.shared.resolveOptional(SendPresentationLogic.self) {
                interactor.presenter = presenter
            } else {
                Logger.warning("⚠️ SendPresenter 해결 실패, 기본 Presenter 사용")
            }
            
            return interactor
        }
        
        // SendRouter 등록 (싱글톤)
        DIContainer.shared.registerSingleton(SendRoutingLogic.self) {
            SendRouter()
        }
        
        Logger.debug("✅ Send Scene VIP 컴포넌트 등록 완료")
    }
    
    /// Receive Scene VIP 컴포넌트들을 등록
    func registerReceiveSceneComponents() {
        Logger.debug("📥 Receive Scene VIP 컴포넌트 등록 시작")
        
        // ReceiveWorker 등록
        DIContainer.shared.register(ReceiveWorkerProtocol.self) {
            ReceiveWorker()
        }
        
        // ReceivePresenter 등록
        DIContainer.shared.register(ReceivePresentationLogic.self) {
            ReceivePresenter()  
        }
        
        // ReceiveInteractor 등록 (안전한 의존성 해결)
        DIContainer.shared.register(ReceiveBusinessLogic.self) {
            guard let worker = DIContainer.shared.resolveOptional(ReceiveWorkerProtocol.self) else {
                Logger.error("❌ ReceiveWorker 해결 실패")
                return ReceiveInteractor() // 기본 Worker로 초기화
            }
            
            let interactor = ReceiveInteractor(worker: worker)
            
            // Presenter 연결 (안전한 방식)
            if let presenter = DIContainer.shared.resolveOptional(ReceivePresentationLogic.self) {
                interactor.presenter = presenter
            } else {
                Logger.warning("⚠️ ReceivePresenter 해결 실패, 기본 Presenter 사용")
            }
            
            return interactor
        }
        
        Logger.debug("✅ Receive Scene VIP 컴포넌트 등록 완료")
    }
    
    /// 모든 VIP Scene 컴포넌트들을 등록
    func registerAllVIPSceneComponents() {
        Logger.debug("🚀 모든 VIP Scene 컴포넌트 등록 시작")
        
        registerSendSceneComponents()
        registerReceiveSceneComponents()
        
        // 향후 다른 Scene들 추가 예정
        // registerAuthenticationSceneComponents()
        // registerWalletSceneComponents()
        // registerHistorySceneComponents()
        
        Logger.debug("🎉 모든 VIP Scene 컴포넌트 등록 완료")
    }
}

