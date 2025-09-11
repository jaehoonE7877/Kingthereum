import SwiftUI
import Foundation
import Entity
import Core

/// 인증 화면의 네비게이션을 관리하는 Router
/// SwiftUI의 선언적 패러다임에 맞춘 새로운 Router 패턴 적용
@Observable
@MainActor
public final class AuthenticationRouter {
    
    // MARK: - Router Dependencies
    
    private let appRouter: AppRouter
    
    // MARK: - Initialization
    
    public init(appRouter: AppRouter = RouterCoordinator.shared) {
        self.appRouter = appRouter
    }
    
    // MARK: - Navigation Methods
    
    /// 메인 앱으로 이동 (인증 완료)
    public func routeToMain() {
        appRouter.enterMainApp()
    }
    
    /// 지갑 생성 화면으로 이동
    public func routeToWalletCreation() {
        appRouter.navigate(to: .authentication(.walletCreation))
    }
    
    /// 지갑 가져오기 화면으로 이동
    public func routeToWalletImport(method: WalletImportMethod) {
        appRouter.navigate(to: .authentication(.walletImport(method: method)))
    }
    
    /// 생체인증 설정 화면으로 이동
    public func routeToBiometricSetup() {
        appRouter.navigate(to: .authentication(.biometricSetup))
    }
    
    /// PIN 설정 화면으로 이동
    public func routeToPINSetup(isFirstTime: Bool = true) {
        appRouter.navigate(to: .authentication(.pinSetup(isFirstTime: isFirstTime)))
    }
    
    /// 보안 옵션 화면으로 이동
    public func routeToSecurityOptions() {
        appRouter.navigate(to: .authentication(.securityOptions))
    }
    
    /// 지갑 백업 화면으로 이동
    public func routeToBackup() {
        appRouter.navigate(to: .authentication(.backup))
    }
    
    /// 설정 화면으로 이동 (인증 관련 설정)
    public func routeToSettings() {
        appRouter.navigate(to: .settings(.security))
    }
    
    // MARK: - Error Handling
    
    /// 인증 오류 표시
    public func showAuthenticationError(_ message: String) {
        appRouter.presentModal(.error(message: "인증 오류: \(message)"))
    }
    
    /// 유효성 검증 오류 표시
    public func showValidationError(_ message: String) {
        appRouter.presentModal(.error(message: "입력 오류: \(message)"))
    }
    
    // MARK: - Modal Presentations
    
    /// 로딩 화면 표시
    public func showLoading(_ message: String = "처리 중...") {
        appRouter.showLoading(message)
    }
    
    /// 로딩 화면 닫기
    public func hideLoading() {
        appRouter.dismissModal()
    }
    
    /// 확인 다이얼로그 표시
    public func showConfirmation(title: String, message: String, action: String = "확인") {
        appRouter.showConfirmation(title: title, message: message, action: action)
    }
    
    // MARK: - Navigation State
    
    /// 현재 인증 플로우가 활성화되어 있는지
    public var isInAuthenticationFlow: Bool {
        // AppRouter를 통해 현재 경로 확인 로직
        return true // 실제 구현에서는 현재 라우트 체크
    }
    
    /// 뒤로 가기 가능 여부
    public var canGoBack: Bool {
        appRouter.canGoBack
    }
    
    /// 뒤로 가기
    public func goBack() {
        appRouter.goBack()
    }
    
    /// 인증 플로우 루트로 돌아가기
    public func goToAuthRoot() {
        appRouter.popTo(AuthenticationRoute.self)
    }
}

// MARK: - Authentication Context Data

/// 인증 과정에서 전달되는 컨텍스트 데이터
/// Sendable을 준수하여 Swift 6 Concurrency 안전성 보장
public struct AuthenticationContext: Sendable {
    public let isSetupMode: Bool
    public let hasExistingWallet: Bool
    public let availableBiometricTypes: [Entity.SecurityError.BiometricType]
    public let recommendedSecurityMethod: SecurityMethod?
    public let walletAddress: String?
    
    public init(
        isSetupMode: Bool = false,
        hasExistingWallet: Bool = false,
        availableBiometricTypes: [Entity.SecurityError.BiometricType] = [],
        recommendedSecurityMethod: SecurityMethod? = nil,
        walletAddress: String? = nil
    ) {
        self.isSetupMode = isSetupMode
        self.hasExistingWallet = hasExistingWallet
        self.availableBiometricTypes = availableBiometricTypes
        self.recommendedSecurityMethod = recommendedSecurityMethod
        self.walletAddress = walletAddress
    }
}

/// 보안 방법 옵션
public enum SecurityMethod: String, CaseIterable, Sendable {
    case none = "none"
    case pin = "pin"
    case biometric = "biometric"
    case pinAndBiometric = "pinAndBiometric"
    
    public var displayName: String {
        switch self {
        case .none: return "없음"
        case .pin: return "PIN"
        case .biometric: return "생체 인증"
        case .pinAndBiometric: return "PIN + 생체 인증"
        }
    }
    
    public var description: String {
        switch self {
        case .none: return "추가 보안 없이 지갑에 접근"
        case .pin: return "PIN 번호로 지갑 보호"
        case .biometric: return "지문 또는 Face ID로 지갑 보호"
        case .pinAndBiometric: return "PIN과 생체 인증으로 이중 보호"
        }
    }
    
    public var iconName: String {
        switch self {
        case .none: return "lock.open.fill"
        case .pin: return "number.circle.fill"
        case .biometric: return "faceid"
        case .pinAndBiometric: return "lock.shield.fill"
        }
    }
}

/// 백업 방법 옵션
public enum BackupMethod: String, CaseIterable, Sendable {
    case mnemonic = "mnemonic"
    case cloud = "cloud"
    case manual = "manual"
    
    public var displayName: String {
        switch self {
        case .mnemonic: return "니모닉 구문"
        case .cloud: return "클라우드 백업"
        case .manual: return "수동 백업"
        }
    }
    
    public var description: String {
        switch self {
        case .mnemonic: return "12개 단어로 구성된 복구 구문"
        case .cloud: return "iCloud 키체인에 안전하게 저장"
        case .manual: return "사용자가 직접 안전한 장소에 보관"
        }
    }
    
    public var iconName: String {
        switch self {
        case .mnemonic: return "text.quote"
        case .cloud: return "icloud.fill"
        case .manual: return "hand.raised.fill"
        }
    }
}
