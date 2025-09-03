import Foundation

/// VIP 패턴을 위한 DI Container 확장
/// Clean Swift 아키텍처의 각 컴포넌트들을 자동으로 등록하고 관리
public extension DIContainer {
    
    // MARK: - VIP Components Auto-Registration
    
    /// VIP Scene 컴포넌트들을 자동으로 등록하는 메서드
    /// - Parameter sceneType: Scene의 타입 (예: "Send", "Receive", "Authentication")
    func registerVIPComponents<I, P, W, R>(
        sceneType: String,
        interactor: I.Type,
        presenter: P.Type, 
        worker: W.Type,
        router: R.Type
    ) {
        Logger.debug("🎭 VIP 컴포넌트 등록 시작 - \(sceneType) Scene")
        
        // Worker 등록 (데이터 레이어)
        registerWorker(worker) {
            // Worker는 실제 구현 클래스의 인스턴스를 생성
            // 컴파일 타임에 구체적인 타입으로 변경 필요
            Logger.error("❌ Worker 팩토리 구현 필요: \(String(describing: worker))")
            fatalError("구체적인 Worker 팩토리 구현 필요")
        }
        
        // Presenter 등록 (프레젠테이션 레이어)
        registerPresenter(presenter) {
            // Presenter도 실제 구현 클래스의 인스턴스를 생성
            Logger.error("❌ Presenter 팩토리 구현 필요: \(String(describing: presenter))")
            fatalError("구체적인 Presenter 팩토리 구현 필요")
        }
        
        // Interactor 등록 (비즈니스 로직 레이어)
        registerInteractor(interactor) {
            // Interactor는 Worker를 주입받아서 생성
            Logger.error("❌ Interactor 팩토리 구현 필요: \(String(describing: interactor))")
            fatalError("구체적인 Interactor 팩토리 구현 필요")
        }
        
        // Router 등록 (네비게이션 레이어)
        registerRouter(router) {
            // Router는 싱글톤으로 관리
            Logger.error("❌ Router 팩토리 구현 필요: \(String(describing: router))")
            fatalError("구체적인 Router 팩토리 구현 필요")
        }
        
        Logger.debug("✅ VIP 컴포넌트 등록 완료 - \(sceneType) Scene")
    }
}

// MARK: - Send Scene DI Registration

/// Send Scene의 VIP 컴포넌트들을 등록하는 확장
public extension DIContainer {
    
    /// Send Scene 컴포넌트들을 등록하는 팩토리 메서드
    /// - Note: 실제 VIP 컴포넌트 등록은 App 모듈에서 직접 처리
    func setupSendSceneDI() {
        Logger.debug("📤 Send Scene DI 설정 준비 완료")
        // App 모듈에서 실제 등록 로직을 호출하도록 함
        // Cross-module 의존성 문제를 방지하기 위해 
        // 구체적인 프로토콜 참조는 App 모듈에서 처리
    }
}

// MARK: - Receive Scene DI Registration

/// Receive Scene의 VIP 컴포넌트들을 등록하는 확장  
public extension DIContainer {
    
    /// Receive Scene 컴포넌트들을 등록하는 팩토리 메서드
    /// - Note: 실제 VIP 컴포넌트 등록은 App 모듈에서 직접 처리
    func setupReceiveSceneDI() {
        Logger.debug("📥 Receive Scene DI 설정 준비 완료")
        // App 모듈에서 실제 등록 로직을 호출하도록 함
        // Cross-module 의존성 문제를 방지하기 위해
        // 구체적인 프로토콜 참조는 App 모듈에서 처리
    }
}

// MARK: - App-wide DI Setup

/// 앱 전체의 DI 컴포넌트들을 설정하는 확장
public extension DIContainer {
    
    /// 모든 Scene의 DI 설정을 준비
    func setupAllSceneDI() {
        Logger.debug("🚀 전체 Scene DI 설정 시작")
        
        setupSendSceneDI()
        setupReceiveSceneDI()
        
        // 향후 다른 Scene들 추가
        // setupAuthenticationSceneDI()
        // setupWalletSceneDI()
        // setupHistorySceneDI()
        
        Logger.debug("🎉 전체 Scene DI 설정 완료")
    }
}

// MARK: - Generic VIP PropertyWrapper Extensions

/// 안전한 의존성 주입을 위한 Generic 속성 래퍼들
public extension DIContainer {
    
    /// 안전한 VIP 컴포넌트 주입을 위한 속성 래퍼
    @propertyWrapper
    struct SafeInjected<T> {
        private let serviceType: T.Type
        private var cachedValue: T?
        
        public init(_ serviceType: T.Type) {
            self.serviceType = serviceType
        }
        
        public var wrappedValue: T? {
            mutating get {
                if let cached = cachedValue {
                    return cached
                }
                
                // 안전한 해결 시도
                guard let resolved = DIContainer.shared.resolveOptional(serviceType) else {
                    Logger.warning("⚠️ 서비스 해결 실패: \(String(describing: serviceType))")
                    return nil
                }
                
                cachedValue = resolved
                return resolved
            }
        }
    }
    
    /// 필수 VIP 컴포넌트 주입을 위한 속성 래퍼 (fatalError 대신 Logger 사용)
    @propertyWrapper
    struct RequiredInjected<T> {
        private let serviceType: T.Type
        private let fallbackFactory: () -> T
        private var cachedValue: T?
        
        public init(_ serviceType: T.Type, fallback: @escaping () -> T) {
            self.serviceType = serviceType
            self.fallbackFactory = fallback
        }
        
        public var wrappedValue: T {
            mutating get {
                if let cached = cachedValue {
                    return cached
                }
                
                // DI Container에서 해결 시도
                if let resolved = DIContainer.shared.resolveOptional(serviceType) {
                    cachedValue = resolved
                    return resolved
                }
                
                // fallback 팩토리 사용
                Logger.warning("⚠️ DI 해결 실패, fallback 사용: \(String(describing: serviceType))")
                let fallbackValue = fallbackFactory()
                cachedValue = fallbackValue
                return fallbackValue
            }
        }
    }
}

// MARK: - Scene Factory Pattern

/// Scene 생성을 위한 안전한 팩토리 패턴
public protocol SafeSceneFactory {
    associatedtype SceneType
    static func createScene() -> SceneType?
}

/// VIP Scene 생성 결과
public enum VIPSceneCreationResult<T> {
    case success(T)
    case missingDependencies([String])
    case creationFailed(Error)
    
    /// 안전한 값 추출
    public var scene: T? {
        switch self {
        case .success(let scene):
            return scene
        case .missingDependencies(let missing):
            Logger.error("❌ 필수 의존성 누락: \(missing.joined(separator: ", "))")
            return nil
        case .creationFailed(let error):
            Logger.error("❌ Scene 생성 실패: \(error)")
            return nil
        }
    }
}

/// 안전한 VIP Scene 팩토리 기본 구현
public struct SafeVIPSceneFactory {
    
    /// 의존성 해결 상태 검사
    public static func checkDependencies<T>(for serviceTypes: [T.Type]) -> [String] {
        var missingServices: [String] = []
        
        for serviceType in serviceTypes {
            let typeName = String(describing: serviceType)
            if DIContainer.shared.resolveOptional(serviceType) == nil {
                missingServices.append(typeName)
            }
        }
        
        return missingServices
    }
    
    /// 안전한 서비스 해결
    public static func resolveService<T>(_ serviceType: T.Type) -> T? {
        guard let service = DIContainer.shared.resolveOptional(serviceType) else {
            Logger.warning("⚠️ 서비스 해결 실패: \(String(describing: serviceType))")
            return nil
        }
        
        Logger.debug("✅ 서비스 해결 성공: \(String(describing: serviceType))")
        return service
    }
}