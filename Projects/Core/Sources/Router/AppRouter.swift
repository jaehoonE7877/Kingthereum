import SwiftUI
import Foundation
import Entity

// MARK: - Route Definitions

/// 앱의 모든 네비게이션 경로를 정의하는 Type-Safe Route Enum
public enum AppRoute: Hashable, Sendable {
    // Authentication Flow
    case authentication(AuthenticationRoute)
    
    // Main App Flows
    case wallet(WalletRoute)
    case settings(SettingsRoute)
    case history(HistoryRoute)
    
    // Modal Presentations
    case modal(ModalRoute)
}

/// 인증 관련 라우팅
public enum AuthenticationRoute: Hashable, Sendable {
    case welcome
    case pinSetup(isFirstTime: Bool)
    case biometricSetup
    case walletCreation
    case walletImport(method: WalletImportMethod)
    case securityOptions
    case backup
}

/// 지갑 관련 라우팅
public enum WalletRoute: Hashable, Sendable {
    case send(walletAddress: String)
    case receive(walletAddress: String)
    case transactionDetail(transactionID: String)
    case tokenDetail(token: String)
}

/// 설정 관련 라우팅
public enum SettingsRoute: Hashable, Sendable {
    case displayMode
    case notifications
    case security
    case network
    case currency
    case language
    case profile
    case help
    case termsOfService
    case privacyPolicy
}

/// 거래 내역 관련 라우팅
public enum HistoryRoute: Hashable, Sendable {
    case transactionList
    case transactionDetail(id: String)
    case filter
    case export
}

/// 모달 표시 라우팅
public enum ModalRoute: Hashable, Sendable {
    case alert(title: String, message: String)
    case confirmation(title: String, message: String, action: String)
    case loading(message: String)
    case error(message: String)
}

/// 지갑 가져오기 방법
public enum WalletImportMethod: String, CaseIterable, Sendable {
    case mnemonic = "mnemonic"
    case privateKey = "privateKey"
    case keystore = "keystore"
    
    public var displayName: String {
        switch self {
        case .mnemonic: return "니모닉 구문"
        case .privateKey: return "개인키"
        case .keystore: return "키스토어"
        }
    }
}

/// 앱 공통 오류 타입
public enum AppError: LocalizedError, Sendable {
    case networkError(String)
    case validationError(String)
    case authenticationError(String)
    case walletError(String)
    case unknownError(String)
    
    public var errorDescription: String? {
        switch self {
        case .networkError(let message): return "네트워크 오류: \(message)"
        case .validationError(let message): return "입력 오류: \(message)"
        case .authenticationError(let message): return "인증 오류: \(message)"
        case .walletError(let message): return "지갑 오류: \(message)"
        case .unknownError(let message): return "알 수 없는 오류: \(message)"
        }
    }
}

// MARK: - App Router

/// SwiftUI NavigationStack 기반 앱 라우터
/// @Observable 매크로를 사용하여 Swift 6 Concurrency 안전성 보장
@Observable
@MainActor
public final class AppRouter {
    
    // MARK: - Navigation State
    
    /// NavigationStack의 경로 관리
    public var navigationPath = NavigationPath()
    
    /// 현재 표시 중인 모달
    public var presentedModal: ModalRoute?
    
    /// 모달 표시 상태
    public var isModalPresented: Bool = false
    
    /// 네비게이션 히스토리 (디버깅용)
    private var navigationHistory: [NavigationEvent] = []
    
    // MARK: - Navigation Methods
    
    /// 새 화면으로 네비게이션
    public func navigate(to route: AppRoute) {
        logNavigation(to: route)
        navigationPath.append(route)
    }
    
    /// 이전 화면으로 돌아가기
    public func goBack() {
        guard !navigationPath.isEmpty else { return }
        logNavigation(action: "Back")
        navigationPath.removeLast()
    }
    
    /// 루트 화면으로 돌아가기
    public func goToRoot() {
        logNavigation(action: "ToRoot")
        navigationPath = NavigationPath()
    }
    
    /// 특정 경로까지 팝 (단순화된 구현)
    public func popTo<T: Hashable>(_ routeType: T.Type) {
        // NavigationPath의 제한으로 인해 단순화된 구현
        // 실제 구현에서는 별도의 path tracking이 필요
        logNavigation(action: "PopTo(\(routeType))")
        // 현재는 단순히 이전 화면으로 이동
        if canGoBack {
            goBack()
        }
    }
    
    // MARK: - Modal Methods
    
    /// 모달 표시
    public func presentModal(_ modal: ModalRoute) {
        logNavigation(to: AppRoute.modal(modal))
        presentedModal = modal
        isModalPresented = true
    }
    
    /// 모달 닫기
    public func dismissModal() {
        logNavigation(action: "DismissModal")
        presentedModal = nil
        isModalPresented = false
    }
    
    // MARK: - Navigation Context
    
    /// 현재 경로 깊이
    public var currentDepth: Int {
        navigationPath.count
    }
    
    /// 네비게이션 가능 여부
    public var canGoBack: Bool {
        !navigationPath.isEmpty
    }
    
    /// 현재 경로가 특정 타입인지 확인 (단순화된 구현)
    public func isCurrentRoute<T: Hashable>(_ routeType: T.Type) -> Bool {
        // NavigationPath의 제한으로 인해 단순화된 구현
        // 실제 구현에서는 별도의 current route tracking이 필요
        return navigationPath.count > 0
    }
    
    // MARK: - Logging
    
    private func logNavigation(to route: AppRoute) {
        let event = NavigationEvent(
            timestamp: Date(),
            action: "Navigate",
            route: "\(route)",
            depth: currentDepth + 1
        )
        navigationHistory.append(event)
        print("🧭 Navigation: → \(route)")
    }
    
    private func logNavigation(action: String) {
        let event = NavigationEvent(
            timestamp: Date(),
            action: action,
            route: nil,
            depth: currentDepth
        )
        navigationHistory.append(event)
        print("🧭 Navigation: \(action)")
    }
    
    /// 네비게이션 히스토리 조회 (디버깅용)
    public func getNavigationHistory() -> [NavigationEvent] {
        return navigationHistory
    }
    
    /// 네비게이션 히스토리 초기화
    public func clearNavigationHistory() {
        navigationHistory.removeAll()
    }
}

// MARK: - Navigation Event

/// 네비게이션 이벤트 (로깅 및 디버깅용)
public struct NavigationEvent: Identifiable, Sendable {
    public let id = UUID()
    public let timestamp: Date
    public let action: String
    public let route: String?
    public let depth: Int
}

// MARK: - Router Extensions

public extension AppRouter {
    
    /// 인증 플로우 시작
    func startAuthenticationFlow() {
        goToRoot()
        navigate(to: .authentication(.welcome))
    }
    
    /// 메인 앱으로 이동
    func enterMainApp() {
        goToRoot()
        // 메인 화면은 별도의 네비게이션 없이 AppCoordinator에서 관리
    }
    
    /// 에러 표시
    func showError(_ error: Error) {
        presentModal(.error(message: error.localizedDescription))
    }
    
    /// 로딩 표시
    func showLoading(_ message: String = "로딩 중...") {
        presentModal(.loading(message: message))
    }
    
    /// 확인 다이얼로그 표시
    func showConfirmation(title: String, message: String, action: String) {
        presentModal(.confirmation(title: title, message: message, action: action))
    }
}