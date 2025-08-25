import SwiftUI
import Foundation
import Entity
import Core

/// 설정 화면의 네비게이션을 관리하는 Router
/// SwiftUI의 선언적 패러다임에 맞춘 새로운 Router 패턴 적용
@Observable
@MainActor
public final class SettingsRouter: SettingsRoutingLogic {
    
    // MARK: - Router Dependencies
    
    private let appRouter: AppRouter
    
    // MARK: - VIP Components
    weak var viewController: SettingsDisplayLogic?
    var dataStore: SettingsDataStore?
    
    // MARK: - Initialization
    
    public init(appRouter: AppRouter = RouterCoordinator.shared) {
        self.appRouter = appRouter
    }
    
    // MARK: - Navigation Methods
    
    /// 디스플레이 모드 설정 화면으로 이동
    public func routeToDisplayModeSelector() {
        print("⚙️ Navigating to display mode settings")
        appRouter.navigate(to: .settings(.displayMode))
    }
    
    /// 알림 설정 화면으로 이동
    public func routeToNotificationSettings() {
        print("⚙️ Navigating to notification settings")
        appRouter.navigate(to: .settings(.notifications))
    }
    
    /// 보안 설정 화면으로 이동
    public func routeToSecuritySettings() {
        print("⚙️ Navigating to security settings")
        appRouter.navigate(to: .settings(.security))
    }
    
    /// 네트워크 설정 화면으로 이동
    public func routeToNetworkSettings() {
        print("⚙️ Navigating to network settings")
        appRouter.navigate(to: .settings(.network))
    }
    
    /// 통화 설정 화면으로 이동
    public func routeToCurrencySettings() {
        print("⚙️ Navigating to currency settings")
        appRouter.navigate(to: .settings(.currency))
    }
    
    /// 언어 설정 화면으로 이동
    public func routeToLanguageSettings() {
        print("⚙️ Navigating to language settings")
        appRouter.navigate(to: .settings(.language))
    }
    
    /// 프로필 화면으로 이동
    public func routeToProfile() {
        print("⚙️ Navigating to profile")
        appRouter.navigate(to: .settings(.profile))
    }
    
    /// 도움말 화면으로 이동
    public func routeToHelp() {
        print("⚙️ Navigating to help")
        appRouter.navigate(to: .settings(.help))
    }
    
    /// 서비스 약관 화면으로 이동
    public func routeToTermsOfService() {
        print("⚙️ Navigating to terms of service")
        appRouter.navigate(to: .settings(.termsOfService))
    }
    
    /// 개인정보 정책 화면으로 이동
    public func routeToPrivacyPolicy() {
        print("⚙️ Navigating to privacy policy")
        appRouter.navigate(to: .settings(.privacyPolicy))
    }
    
    // MARK: - Error Handling
    
    /// 설정 변경 오류 표시
    public func showSettingsError(_ message: String) {
        let error = AppError.validationError(message)
        appRouter.showError(error)
    }
    
    /// 네트워크 오류 표시
    public func showNetworkError(_ message: String) {
        let error = AppError.networkError(message)
        appRouter.showError(error)
    }
    
    // MARK: - Modal Presentations
    
    /// 로딩 화면 표시
    public func showLoading(_ message: String = "설정 저장 중...") {
        appRouter.showLoading(message)
    }
    
    /// 로딩 화면 닫기
    public func hideLoading() {
        appRouter.dismissModal()
    }
    
    /// 설정 변경 확인 다이얼로그 표시
    public func showSettingsConfirmation(title: String, message: String, action: String = "저장") {
        appRouter.showConfirmation(title: title, message: message, action: action)
    }
    
    /// 앱 재시작 필요 알림
    public func showRestartRequired() {
        appRouter.presentModal(.alert(
            title: "재시작 필요", 
            message: "이 설정을 적용하려면 앱을 재시작해야 합니다."
        ))
    }
    
    // MARK: - Navigation State
    
    /// 뒤로 가기 가능 여부
    public var canGoBack: Bool {
        appRouter.canGoBack
    }
    
    /// 뒤로 가기
    public func goBack() {
        appRouter.goBack()
    }
    
    /// 설정 메인으로 돌아가기
    public func goToSettingsRoot() {
        appRouter.popTo(SettingsRoute.self)
    }
}

// MARK: - Settings Context Data

/// 설정 관련 컨텍스트 데이터
/// Sendable을 준수하여 Swift 6 Concurrency 안전성 보장
public struct SettingsContext: Sendable {
    public let currentDisplayMode: DisplayMode
    public let currentLanguage: String
    public let currentCurrency: String
    public let notificationsEnabled: Bool
    public let biometricEnabled: Bool
    public let networkType: NetworkType
    
    public init(
        currentDisplayMode: DisplayMode = .system,
        currentLanguage: String = "ko",
        currentCurrency: String = "KRW",
        notificationsEnabled: Bool = true,
        biometricEnabled: Bool = false,
        networkType: NetworkType = .mainnet
    ) {
        self.currentDisplayMode = currentDisplayMode
        self.currentLanguage = currentLanguage
        self.currentCurrency = currentCurrency
        self.notificationsEnabled = notificationsEnabled
        self.biometricEnabled = biometricEnabled
        self.networkType = networkType
    }
}

/// 지원되는 네트워크 타입
public enum NetworkType: String, CaseIterable, Sendable {
    case mainnet = "mainnet"
    case testnet = "testnet"
    case sepolia = "sepolia"
    case goerli = "goerli"
    
    public var displayName: String {
        switch self {
        case .mainnet: return "메인넷"
        case .testnet: return "테스트넷"
        case .sepolia: return "세폴리아"
        case .goerli: return "고얼리"
        }
    }
    
    public var description: String {
        switch self {
        case .mainnet: return "이더리움 메인 네트워크"
        case .testnet: return "테스트 전용 네트워크"
        case .sepolia: return "세폴리아 테스트넷"
        case .goerli: return "고얼리 테스트넷"
        }
    }
    
    public var chainId: Int {
        switch self {
        case .mainnet: return 1
        case .testnet: return 11155111
        case .sepolia: return 11155111
        case .goerli: return 5
        }
    }
    
    public var iconName: String {
        switch self {
        case .mainnet: return "globe.asia.australia.fill"
        case .testnet: return "testtube.2"
        case .sepolia: return "s.circle.fill"
        case .goerli: return "g.circle.fill"
        }
    }
}

/// 지원되는 통화 타입
public enum CurrencyType: String, CaseIterable, Sendable {
    case krw = "KRW"
    case usd = "USD"
    case eur = "EUR"
    case jpy = "JPY"
    case cny = "CNY"
    
    public var displayName: String {
        switch self {
        case .krw: return "KRW (원)"
        case .usd: return "USD (달러)"
        case .eur: return "EUR (유로)"
        case .jpy: return "JPY (엔)"
        case .cny: return "CNY (위안)"
        }
    }
    
    public var symbol: String {
        switch self {
        case .krw: return "₩"
        case .usd: return "$"
        case .eur: return "€"
        case .jpy: return "¥"
        case .cny: return "¥"
        }
    }
    
    public var flagEmoji: String {
        switch self {
        case .krw: return "🇰🇷"
        case .usd: return "🇺🇸"
        case .eur: return "🇪🇺"
        case .jpy: return "🇯🇵"
        case .cny: return "🇨🇳"
        }
    }
}

/// 지원되는 언어 타입
public enum LanguageType: String, CaseIterable, Sendable {
    case korean = "ko"
    case english = "en"
    case japanese = "ja"
    case chinese = "zh"
    
    public var displayName: String {
        switch self {
        case .korean: return "한국어"
        case .english: return "English"
        case .japanese: return "日本語"
        case .chinese: return "中文"
        }
    }
    
    public var localizedName: String {
        switch self {
        case .korean: return "Korean"
        case .english: return "English"
        case .japanese: return "Japanese"
        case .chinese: return "Chinese"
        }
    }
    
    public var flagEmoji: String {
        switch self {
        case .korean: return "🇰🇷"
        case .english: return "🇺🇸"
        case .japanese: return "🇯🇵"
        case .chinese: return "🇨🇳"
        }
    }
}