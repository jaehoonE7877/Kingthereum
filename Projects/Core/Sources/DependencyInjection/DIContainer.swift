import Foundation

/// 의존성 주입 컨테이너
/// Clean Swift VIP 패턴을 위한 중앙집중식 의존성 관리 시스템
/// Swift 6.0 Strict Concurrency를 지원하는 Actor 기반 DI Container
public actor DIContainer {
    
    // MARK: - Singleton
    
    /// 전역 DI Container 인스턴스
    public static let shared = DIContainer()
    
    // MARK: - Private Properties
    
    /// 등록된 서비스들을 저장하는 딕셔너리
    /// Key: 서비스 타입의 식별자, Value: 서비스 인스턴스 또는 팩토리
    private var services: [String: Any] = [:]
    
    /// 싱글톤 서비스들을 저장하는 딕셔너리  
    private var singletons: [String: Any] = [:]
    
    private init() {
        // Actor 내부에서는 직접 비동기 작업 수행 가능
        Task {
            await MainActor.run {
                Logger.debug("🏭 DIContainer 초기화")
            }
            await registerCoreServices()
        }
    }
    
    // MARK: - Service Registration
    
    /// 서비스 등록 (Transient - 매번 새 인스턴스 생성)
    /// - Parameters:
    ///   - serviceType: 등록할 서비스의 프로토콜 타입
    ///   - factory: 서비스 인스턴스를 생성하는 팩토리 클로저
    public func register<T>(_ serviceType: T.Type, factory: @escaping @Sendable () async -> T) {
        let key = String(reflecting: serviceType)
        // Actor 내부에서 직접 동기 작업 수행
        services[key] = factory
        
        // 로깅은 필요시에만 MainActor로
        Task { @MainActor in
            Logger.debug("📝 서비스 등록 (Transient): \(key)")
        }
    }
    
    /// 서비스 등록 (Singleton - 한 번만 생성하여 재사용)  
    /// - Parameters:
    ///   - serviceType: 등록할 서비스의 프로토콜 타입
    ///   - factory: 서비스 인스턴스를 생성하는 팩토리 클로저
    public func registerSingleton<T>(_ serviceType: T.Type, factory: @escaping @Sendable () async -> T) {
        let key = String(reflecting: serviceType)
        services[key] = SingletonFactory(factory: factory)
        
        // 로깅은 필요시에만 MainActor로
        Task { @MainActor in
            Logger.debug("📝 서비스 등록 (Singleton): \(key)")
        }
    }
    
    /// 기존 인스턴스를 싱글톤으로 등록
    /// - Parameters:
    ///   - serviceType: 등록할 서비스의 프로토콜 타입
    ///   - instance: 등록할 서비스 인스턴스
    public func registerSingleton<T>(_ serviceType: T.Type, instance: T) where T: Sendable {
        let key = String(reflecting: serviceType)
        singletons[key] = instance
        
        // 로깅은 필요시에만 MainActor로
        Task { @MainActor in
            Logger.debug("📝 인스턴스 등록 (Singleton): \(key)")
        }
    }
    
    // MARK: - Service Resolution
    
    /// 서비스 해결 (의존성 주입)
    /// - Parameter serviceType: 가져올 서비스의 프로토콜 타입
    /// - Returns: 요청된 서비스 인스턴스
    /// - Throws: DIError.serviceNotRegistered 서비스가 등록되지 않은 경우
    public func resolve<T>(_ serviceType: T.Type) async throws -> T {
        let key = String(reflecting: serviceType)
        
        // 1. 먼저 싱글톤 캐시에서 확인
        if let singleton = singletons[key] as? T {
            await MainActor.run {
                Logger.debug("🔍 싱글톤 서비스 반환: \(key)")
            }
            return singleton
        }
        
        // 2. 팩토리에서 새 인스턴스 생성
        guard let factory = services[key] else {
            await MainActor.run {
                Logger.error("❌ 등록되지 않은 서비스: \(key)")
            }
            throw DIError.serviceNotRegistered(String(describing: serviceType))
        }
        
        // Transient factory
        if let transientFactory = factory as? (@Sendable () async -> T) {
            await MainActor.run {
                Logger.debug("🔍 Transient 서비스 생성: \(key)")
            }
            return await transientFactory()
        }
        
        // Singleton factory
        if let singletonFactory = factory as? SingletonFactory<T> {
            await MainActor.run {
                Logger.debug("🔍 Singleton 서비스 생성 및 캐시: \(key)")
            }
            let instance = await singletonFactory.createInstance()
            
            // 싱글톤 캐시에 저장
            singletons[key] = instance
            
            return instance
        }
        
        await MainActor.run {
            Logger.error("❌ 잘못된 팩토리 타입: \(key)")
        }
        throw DIError.invalidFactory(String(describing: serviceType))
    }
    
    /// Optional 서비스 해결 (실패 시 nil 반환)
    /// - Parameter serviceType: 가져올 서비스의 프로토콜 타입
    /// - Returns: 요청된 서비스 인스턴스 또는 nil
    public func resolveOptional<T>(_ serviceType: T.Type) async -> T? {
        do {
            return try await resolve(serviceType)
        } catch {
            await MainActor.run {
                Logger.debug("⚠️ Optional 서비스 해결 실패: \(String(describing: serviceType))")
            }
            return nil
        }
    }
    
    // MARK: - Container Management
    
    /// 특정 서비스 등록 해제
    /// - Parameter serviceType: 등록 해제할 서비스 타입
    public func unregister<T>(_ serviceType: T.Type) {
        let key = String(reflecting: serviceType)
        Task { @MainActor in
            Logger.debug("🗑️ 서비스 등록 해제: \(key)")
        }
        
        services.removeValue(forKey: key)
        singletons.removeValue(forKey: key)
    }
    
    /// 모든 서비스 등록 해제 (테스트용)
    public func reset() async {
        await MainActor.run {
            Logger.debug("🧹 DI Container 초기화")
        }
        
        services.removeAll()
        singletons.removeAll()
        
        // 핵심 서비스 재등록
        await registerCoreServices()
    }
    
    /// 등록된 서비스 목록 확인 (디버깅용)
    public func listRegisteredServices() -> [String] {
        return Array(services.keys)
    }
    
    // MARK: - Core Services Registration
    
    /// 핵심 서비스들을 자동으로 등록
    private func registerCoreServices() async {
        await MainActor.run {
            Logger.debug("🔧 핵심 서비스 등록 시작")
        }
        
        // Configuration Service
        await registerSingleton(ConfigurationServiceProtocol.self) {
            return ConfigurationService()
        }
        
        // Display Mode Service  
        await registerSingleton(DisplayModeServiceProtocol.self) {
            await MainActor.run {
                return DisplayModeService()
            }
        }
        
        await MainActor.run {
            Logger.debug("✅ 핵심 서비스 등록 완료")
        }
    }
}

// MARK: - Supporting Types

/// Singleton factory wrapper for lazy instantiation
/// Actor 내부에서만 사용되므로 별도의 동기화 메커니즘 불필요
private struct SingletonFactory<T>: Sendable where T: Sendable {
    private let factory: @Sendable () async -> T
    
    init(factory: @escaping @Sendable () async -> T) {
        self.factory = factory
    }
    
    func createInstance() async -> T {
        // Actor가 이미 동기화를 보장하므로 추가 lock 불필요
        return await factory()
    }
}

// MARK: - DI Errors

/// 의존성 주입 관련 오류 타입
public enum DIError: LocalizedError, Equatable {
    case serviceNotRegistered(String)
    case invalidFactory(String)
    case circularDependency(String)
    case resolutionFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .serviceNotRegistered(let service):
            return "서비스가 등록되지 않았습니다: \(service)"
        case .invalidFactory(let service):
            return "잘못된 팩토리 타입: \(service)"
        case .circularDependency(let service):
            return "순환 의존성 발견: \(service)"
        case .resolutionFailed(let service):
            return "서비스 해결 실패: \(service)"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .serviceNotRegistered:
            return "DIContainer.shared.register() 메서드로 서비스를 먼저 등록하세요."
        case .invalidFactory:
            return "팩토리 클로저의 반환 타입을 확인하세요."
        case .circularDependency:
            return "서비스 간의 순환 참조를 제거하세요."
        case .resolutionFailed:
            return "서비스 팩토리 내부의 오류를 확인하세요."
        }
    }
}

// MARK: - Convenience Extensions

/// DIContainer의 편의 기능을 위한 확장
public extension DIContainer {
    
    /// VIP 패턴의 Interactor 등록을 위한 헬퍼
    /// - Parameters:
    ///   - interactorType: Interactor 프로토콜 타입
    ///   - factory: Interactor 인스턴스를 생성하는 팩토리 클로저
    func registerInteractor<T>(_ interactorType: T.Type, factory: @escaping @Sendable () async -> T) async {
        await MainActor.run {
            Logger.debug("🎭 Interactor 등록: \(String(describing: interactorType))")
        }
        await register(interactorType, factory: factory)
    }
    
    /// VIP 패턴의 Presenter 등록을 위한 헬퍼  
    /// - Parameters:
    ///   - presenterType: Presenter 프로토콜 타입
    ///   - factory: Presenter 인스턴스를 생성하는 팩토리 클로저
    func registerPresenter<T>(_ presenterType: T.Type, factory: @escaping @Sendable () async -> T) async {
        await MainActor.run {
            Logger.debug("🎨 Presenter 등록: \(String(describing: presenterType))")
        }
        await register(presenterType, factory: factory)
    }
    
    /// VIP 패턴의 Worker 등록을 위한 헬퍼
    /// - Parameters:
    ///   - workerType: Worker 프로토콜 타입
    ///   - factory: Worker 인스턴스를 생성하는 팩토리 클로저
    func registerWorker<T>(_ workerType: T.Type, factory: @escaping @Sendable () async -> T) async {
        await MainActor.run {
            Logger.debug("⚙️ Worker 등록: \(String(describing: workerType))")
        }
        await register(workerType, factory: factory)
    }
    
    /// VIP 패턴의 Router 등록을 위한 헬퍼
    /// - Parameters:
    ///   - routerType: Router 프로토콜 타입
    ///   - factory: Router 인스턴스를 생성하는 팩토리 클로저
    func registerRouter<T>(_ routerType: T.Type, factory: @escaping @Sendable () async -> T) async {
        await MainActor.run {
            Logger.debug("🧭 Router 등록: \(String(describing: routerType))")
        }
        await registerSingleton(routerType, factory: factory)
    }
}

// MARK: - PropertyWrapper for Dependency Injection

/// 비동기 의존성 주입을 위한 속성 래퍼
/// Swift 6.0 Strict Concurrency 호환
/// 사용법: @AsyncInjected var service: ServiceProtocol
@propertyWrapper
public struct AsyncInjected<T> {
    private var value: T?
    
    public init() {
        self.value = nil
    }
    
    public var wrappedValue: T {
        get async {
            if let existingValue = value {
                return existingValue
            }
            
            do {
                let newValue = try await DIContainer.shared.resolve(T.self)
                value = newValue
                return newValue
            } catch {
                await MainActor.run {
                    Logger.error("❌ 의존성 주입 실패: \(String(describing: T.self)) - \(error)")
                }
                fatalError("의존성 주입 실패: \(String(describing: T.self))")
            }
        }
    }
}

/// Optional 비동기 의존성 주입을 위한 속성 래퍼
/// 사용법: @AsyncOptionalInjected var service: ServiceProtocol?
@propertyWrapper  
public struct AsyncOptionalInjected<T> {
    private var value: T??
    
    public init() {
        self.value = nil
    }
    
    public var wrappedValue: T? {
        get async {
            if value == nil {
                value = await DIContainer.shared.resolveOptional(T.self)
            }
            
            // Optional의 optional을 안전하게 해제
            switch value {
            case .some(let wrappedValue):
                return wrappedValue
            case .none:
                return nil
            }
        }
    }
}