import SwiftUI
import DesignSystem
import Core
import Entity
import Factory

/// Phase 2.2: SettingsView 프리미엄 피나테크 재설계
/// AuthenticationView와 동일한 극한 미니멀리즘 + 신뢰감 있는 피나테크 스타일
/// 1000줄 → 300줄 이내로 압축

@MainActor
protocol SettingsDisplayLogic: AnyObject {
    func displaySettings(viewModel: SettingsScene.LoadSettings.ViewModel)
    func displayDisplayModeUpdate(viewModel: SettingsScene.UpdateDisplayMode.ViewModel)
    func displayNotificationUpdate(viewModel: SettingsScene.UpdateNotification.ViewModel)
    func displaySecurityUpdate(viewModel: SettingsScene.UpdateSecurity.ViewModel)
    func displayNetworkUpdate(viewModel: SettingsScene.UpdateNetwork.ViewModel)
    func displayProfile(viewModel: SettingsScene.LoadProfile.ViewModel)
}

@MainActor
protocol SettingsRoutingLogic {
    func routeToProfile()
    func routeToSecuritySettings()
    func routeToNetworkSettings()
    func routeToCurrencySettings()
    func routeToLanguageSettings()
    func routeToHelp()
    func routeToTermsOfService()
    func routeToPrivacyPolicy()
}

/// SwiftUI용 Settings ViewStore (DisplayLogic 구현)
@MainActor
@Observable
final class SettingsViewStore: SettingsDisplayLogic {
    var isLoading = false
    var displayMode = "시스템"
    var fontSize = "기본"
    var notificationStatus = "켜짐"
    var securityMode = "Face ID"
    var network = "메인넷"
    var currency = "USD"
    var language = "한국어"
    var version = "1.0.0"
    var profileData = ProfileData(
        displayName: "Kingthereum Wallet",
        formattedAddress: "0x742d...9aE3",
        avatarInitials: "K"
    )
    var showDisplayModeSelector = false
    var alertMessage: String?
    
    // MARK: - Display Logic
    
    func displaySettings(viewModel: SettingsScene.LoadSettings.ViewModel) {
        displayMode = viewModel.displayMode
        fontSize = viewModel.fontSize
        notificationStatus = viewModel.notificationEnabled ? "켜짐" : "꺼짐"
        securityMode = viewModel.securityMode
        network = viewModel.network
        currency = viewModel.currency
        language = viewModel.language
        profileData = viewModel.profileData
        
        if let errorMessage = viewModel.errorMessage {
            alertMessage = errorMessage
        }
    }
    
    func displayDisplayModeUpdate(viewModel: SettingsScene.UpdateDisplayMode.ViewModel) {
        displayMode = viewModel.displayMode
        
        if let errorMessage = viewModel.errorMessage {
            alertMessage = errorMessage
        } else if let successMessage = viewModel.successMessage {
            alertMessage = successMessage
        }
    }
    
    func displayNotificationUpdate(viewModel: SettingsScene.UpdateNotification.ViewModel) {
        notificationStatus = viewModel.statusText
        
        if let errorMessage = viewModel.errorMessage {
            alertMessage = errorMessage
        } else if let successMessage = viewModel.successMessage {
            alertMessage = successMessage
        }
    }
    
    func displaySecurityUpdate(viewModel: SettingsScene.UpdateSecurity.ViewModel) {
        securityMode = viewModel.securityMode
        
        if let errorMessage = viewModel.errorMessage {
            alertMessage = errorMessage
        } else if let successMessage = viewModel.successMessage {
            alertMessage = successMessage
        }
    }
    
    func displayNetworkUpdate(viewModel: SettingsScene.UpdateNetwork.ViewModel) {
        network = viewModel.network
        
        if let errorMessage = viewModel.errorMessage {
            alertMessage = errorMessage
        } else if let successMessage = viewModel.successMessage {
            alertMessage = successMessage
        }
    }
    
    func displayProfile(viewModel: SettingsScene.LoadProfile.ViewModel) {
        profileData = viewModel.profileData
        
        if let errorMessage = viewModel.errorMessage {
            alertMessage = errorMessage
        }
    }
    
    func clearAlert() {
        alertMessage = nil
    }
}

struct SettingsView: View {
    @State private var viewStore = SettingsViewStore()
    @Binding var showTabBar: Bool
    @EnvironmentObject private var displayModeService: DisplayModeService
    
    // MARK: - VIP Architecture Components
    private let interactor: SettingsBusinessLogic
    private let presenter: SettingsPresenter
    private let router: SettingsRouter
    
    init(showTabBar: Binding<Bool>) {
        self._showTabBar = showTabBar
        
        let interactor = SettingsInteractor()
        let presenter = SettingsPresenter()
        let router = SettingsRouter()
        
        interactor.presenter = presenter
        
        self.interactor = interactor
        self.presenter = presenter
        self.router = router
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 극한 미니멀 배경
                KingGradients.minimalistBackground
                    .ignoresSafeArea()
                
                if viewStore.isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(KingColors.trustPurple)
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // 메인 설정 카드 - 하나로 통합
                            mainSettingsCard
                            
                            // 추가 옵션 카드
                            additionalOptionsCard
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 32)
                    }
                }
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $viewStore.showDisplayModeSelector) {
                DisplayModeSelectorView()
                    .environmentObject(displayModeService)
            }
            .alert("알림", isPresented: Binding<Bool>(
                get: { viewStore.alertMessage != nil },
                set: { _ in viewStore.clearAlert() }
            )) {
                Button("확인") {
                    viewStore.clearAlert()
                }
            } message: {
                if let message = viewStore.alertMessage {
                    Text(message)
                        .font(KingTypography.bodyMedium)
                        .foregroundColor(KingColors.textSecondary)
                }
            }
        }
        .onAppear {
            presenter.viewController = viewStore
            router.viewController = viewStore
            router.dataStore = interactor as? SettingsDataStore
            loadSettings()
        }
    }
    
    // MARK: - Business Logic Methods
    
    private func loadSettings() {
        let userId = getCurrentUserId()
        let request = SettingsScene.LoadSettings.Request(userId: userId)
        interactor.loadSettings(request: request)
    }
    
    private func selectProfile() {
        router.routeToProfile()
    }
    
    private func toggleNotification() {
        let currentlyEnabled = viewStore.notificationStatus == "켜짐"
        let request = SettingsScene.UpdateNotification.Request(enabled: !currentlyEnabled)
        interactor.updateNotification(request: request)
    }
    
    private func selectSecurity() {
        router.routeToSecuritySettings()
    }
    
    private func selectNetwork() {
        router.routeToNetworkSettings()
    }
    
    private func selectCurrency() {
        router.routeToCurrencySettings()
    }
    
    private func selectLanguage() {
        router.routeToLanguageSettings()
    }
    
    private func selectHelp() {
        router.routeToHelp()
    }
    
    private func selectTermsOfService() {
        router.routeToTermsOfService()
    }
    
    private func selectPrivacyPolicy() {
        router.routeToPrivacyPolicy()
    }
    
    private func getCurrentUserId() -> String {
        return UserDefaults.standard.string(forKey: "userId") ?? "default"
    }
}

// MARK: - 미니멀 디자인 컴포넌트

extension SettingsView {
    @ViewBuilder
    private var mainSettingsCard: some View {
        VStack(spacing: 24) {
            // 미니멀 프로필 섹션
            VStack(spacing: 16) {
                // 미니멀 프로필 아이콘
                ZStack {
                    Circle()
                        .frame(width: 60, height: 60)
                        .goldAccentGlass(level: .subtle, cornerRadius: 30, intensity: 0.4)
                    
                    Text(viewStore.profileData.avatarInitials)
                        .font(KingTypography.headlineSmall)
                        .foregroundColor(KingColors.exclusiveGold)
                }
                
                VStack(spacing: 4) {
                    Text(viewStore.profileData.displayName)
                        .font(KingTypography.headlineMedium)
                        .foregroundColor(KingColors.textPrimary)
                    
                    Text(viewStore.profileData.formattedAddress)
                        .font(KingTypography.bodySmall)
                        .foregroundColor(KingColors.textSecondary)
                }
            }
            
            // 미니멀 설정 리스트
            VStack(spacing: 12) {
                settingRow(icon: "moon.circle", title: "화면 모드", value: viewStore.displayMode, color: KingColors.trustPurple) {
                    viewStore.showDisplayModeSelector = true
                }
                
                settingRow(icon: "bell.circle", title: "알림", value: viewStore.notificationStatus, color: KingColors.info) {
                    toggleNotification()
                }
                
                settingRow(icon: "lock.circle", title: "보안", value: viewStore.securityMode, color: KingColors.success) {
                    selectSecurity()
                }
                
                settingRow(icon: "network", title: "네트워크", value: viewStore.network, color: KingColors.trustPurple) {
                    selectNetwork()
                }
            }
        }
        .padding(28)
        .trustGlassCard(level: .prominent, cornerRadius: 20)
    }

    @ViewBuilder 
    private func settingRow(icon: String, title: String, value: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 20)
                
                Text(title)
                    .font(KingTypography.bodyMedium)
                    .foregroundColor(KingColors.textPrimary)
                
                Spacer()
                
                Text(value)
                    .font(KingTypography.caption)
                    .foregroundColor(color)
                
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(KingColors.textTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(PlainButtonStyle())
        .premiumFinTechGlass(level: .subtle)
    }

    @ViewBuilder
    private var additionalOptionsCard: some View {
        VStack(spacing: 16) {
            // 추가 옵션들
            HStack(spacing: 12) {
                // 언어
                quickOptionCard(
                    icon: "globe", 
                    title: "언어",
                    value: viewStore.language,
                    color: KingColors.info
                ) {
                    selectLanguage()
                }
                
                // 통화
                quickOptionCard(
                    icon: "dollarsign.circle",
                    title: "통화", 
                    value: viewStore.currency,
                    color: KingColors.exclusiveGold
                ) {
                    selectCurrency() 
                }
            }
            
            // 지원 옵션들
            VStack(spacing: 8) {
                supportRow(icon: "questionmark.circle", title: "도움말") {
                    selectHelp()
                }
                
                supportRow(icon: "doc.text", title: "이용약관") {
                    selectTermsOfService()
                }
                
                supportRow(icon: "hand.raised", title: "개인정보 처리방침") {
                    selectPrivacyPolicy()
                }
            }
            
            // 버전 정보
            HStack {
                Spacer()
                Text("v\(viewStore.version)")
                    .font(KingTypography.caption)
                    .foregroundColor(KingColors.textTertiary)
                Spacer()
            }
        }
        .padding(24)
        .ultraMinimalGlass(level: .subtle)
    }

    @ViewBuilder
    private func quickOptionCard(icon: String, title: String, value: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(KingTypography.caption)
                        .foregroundColor(KingColors.textPrimary)
                    
                    Text(value)
                        .font(KingTypography.helper)
                        .foregroundColor(color)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .buttonStyle(PlainButtonStyle())
        .ultraMinimalGlass(level: .subtle)
    }

    @ViewBuilder
    private func supportRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(KingColors.textSecondary)
                    .frame(width: 16)
                
                Text(title)
                    .font(KingTypography.bodySmall)
                    .foregroundColor(KingColors.textSecondary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(KingColors.textTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview("SettingsView") {
    SettingsView(showTabBar: .constant(true))
}

#Preview("SettingsView - Dark Mode") {
    SettingsView(showTabBar: .constant(true))
        .preferredColorScheme(.dark)
}