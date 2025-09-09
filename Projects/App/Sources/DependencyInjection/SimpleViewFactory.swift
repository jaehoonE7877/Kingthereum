import SwiftUI
import Core
import WalletKit
import SecurityKit

// MARK: - 단순한 View 팩토리
/// 복잡한 DI 시스템 대신 간단한 팩토리 패턴으로 View 생성

@MainActor
public struct SimpleViewFactory {
    
    // MARK: - Singleton
    public static let shared = SimpleViewFactory()
    private init() {}
    
    // MARK: - SendView 생성
    
    /// SendView를 완전히 구성된 상태로 생성합니다
    public func createSendView() -> SendView {
        // Worker 생성
        let worker = SendWorker(
            walletService: createWalletService(),
            securityService: createSecurityService()
        )
        
        // Presenter 생성
        let presenter = SendPresenter()
        
        // Interactor 생성 (VIP 연결)
        let interactor = SendInteractor(
            presenter: presenter,
            worker: worker
        )
        
        // Router 생성
        let router = SendRouter()
        
        // View 생성 (완전히 구성된 상태)
        let sendView = SendView(
            interactor: interactor,
            router: router
        )
        
        // ViewStore에 presenter 연결
        return sendView
    }
    
    // MARK: - AuthenticationView 생성
    
    /// AuthenticationView를 완전히 구성된 상태로 생성합니다
    func createAuthenticationView() -> AuthenticationView {
        // Worker 생성
        let worker = AuthenticationWorker(
            securityService: createSecurityService()
        )
        
        // Presenter 생성
        let presenter = AuthenticationPresenter()
        
        // Interactor 생성
        let interactor = AuthenticationInteractor(
            presenter: presenter,
            worker: worker
        )
        
        // Router 생성
        let router = AuthenticationRouter()
        
        // View 생성
        return AuthenticationView(
            interactor: interactor,
            router: router
        )
    }
    
    // MARK: - ReceiveView 생성
    
    /// ReceiveView를 완전히 구성된 상태로 생성합니다
    func createReceiveView() -> ReceiveView {
        // ReceiveView는 arguments 없이 생성됨
        return ReceiveView()
    }
    
    // MARK: - SettingsView 생성
    
    /// SettingsView를 완전히 구성된 상태로 생성합니다
    func createSettingsView() -> SettingsView {
        // SettingsView는 showTabBar binding만 필요
        return SettingsView(showTabBar: .constant(true))
    }
    
    // MARK: - Core Services (간단한 싱글톤 방식)
    
    private func createWalletService() -> WalletService {
        return WalletService.shared
    }
    
    private func createSecurityService() -> SecurityService {
        return SecurityService.shared
    }
    
    private func createConfigurationService() -> ConfigurationService {
        return ConfigurationService.shared
    }
}

// MARK: - Core Services Extensions (싱글톤 추가)

extension WalletService {
    static let shared = try! WalletService(
        rpcURL: "https://mainnet.infura.io/v3/YOUR_PROJECT_ID"
    )
}

extension SecurityService {
    static let shared = SecurityService()
}

extension ConfigurationService {
    static let shared = ConfigurationService()
}

extension DisplayModeService {
    static let shared = DisplayModeService()
}
