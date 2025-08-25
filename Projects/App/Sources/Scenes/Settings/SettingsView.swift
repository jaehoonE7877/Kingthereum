import SwiftUI
import DesignSystem
import Core
import Entity
import Factory

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
            ScrollView {
                if viewStore.isLoading {
                    LoadingView(style: .spinner, size: .medium)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: DesignTokens.Spacing.xl) {
                        profileSection
                        displaySection
                        generalSection
                        aboutSection
                        
                        // 추가 스크롤 여백
                        Color.clear.frame(height: 120)
                    }
                    .padding(DesignTokens.Spacing.lg)
                }
            }
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentOffset.y
            } action: { _, newValue in
                let threshold: CGFloat = 50
                withAnimation(.easeInOut(duration: 0.3)) {
                    showTabBar = newValue < threshold
                }
            }
            .navigationTitle("설정")
            .sheet(isPresented: $viewStore.showDisplayModeSelector) {
                DisplayModeSelectorView()
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
                }
            }
        }
        .onAppear {
            // Connect presenter to viewStore after view initialization
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

extension SettingsView {
    private var profileSection: some View {
        SettingsGroup(title: "프로필") {
            HStack(spacing: 16) {
                // 프로필 이미지
                Circle()
                    .fill(LinearGradient.primaryGradient)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(viewStore.profileData.avatarInitials)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewStore.profileData.displayName)
                        .font(Typography.Heading.h5)
                    Text(viewStore.profileData.formattedAddress)
                        .font(Typography.Caption.medium)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding()
            .glassCard()
            .onTapGesture {
                selectProfile()
            }
        }
    }
    
    private var displaySection: some View {
        SettingsGroup(title: "디스플레이") {
            VStack(spacing: 0) {
                SettingsRow(
                    icon: "moon.circle.fill",
                    iconColor: .systemPurple,
                    title: "화면 모드",
                    value: viewStore.displayMode
                ) {
                    viewStore.showDisplayModeSelector = true
                }
                
                Divider()
                    .padding(.leading, DesignTokens.Spacing.xxl + DesignTokens.Spacing.xl)
                
                SettingsRow(
                    icon: "textformat.size",
                    iconColor: .systemBlue,
                    title: "글자 크기",
                    value: viewStore.fontSize
                ) {
                    selectFontSize()
                }
            }
        }
    }
    
    private func selectFontSize() {
        // 글자 크기 선택 로직
        Logger.debug("Font size selection requested")
    }
    
    private var generalSection: some View {
        SettingsGroup(title: "일반") {
            VStack(spacing: 0) {
                SettingsRow(
                    icon: "bell.circle.fill",
                    iconColor: .systemOrange,
                    title: "알림",
                    value: viewStore.notificationStatus
                ) {
                    toggleNotification()
                }
                
                Divider()
                    .padding(.leading, DesignTokens.Spacing.xxl + DesignTokens.Spacing.xl)
                
                SettingsRow(
                    icon: "lock.circle.fill",
                    iconColor: .systemGreen,
                    title: "보안",
                    value: viewStore.securityMode
                ) {
                    selectSecurity()
                }
                
                Divider()
                    .padding(.leading, DesignTokens.Spacing.xxl + DesignTokens.Spacing.xl)
                
                SettingsRow(
                    icon: "network",
                    iconColor: .systemIndigo,
                    title: "네트워크",
                    value: viewStore.network
                ) {
                    selectNetwork()
                }
                
                Divider()
                    .padding(.leading, DesignTokens.Spacing.xxl + DesignTokens.Spacing.xl)
                
                SettingsRow(
                    icon: "dollarsign.circle.fill",
                    iconColor: .systemMint,
                    title: "통화",
                    value: viewStore.currency
                ) {
                    selectCurrency()
                }
                
                Divider()
                    .padding(.leading, DesignTokens.Spacing.xxl + DesignTokens.Spacing.xl)
                
                SettingsRow(
                    icon: "globe",
                    iconColor: .systemCyan,
                    title: "언어",
                    value: viewStore.language
                ) {
                    selectLanguage()
                }
            }
        }
    }
    
    private var aboutSection: some View {
        SettingsGroup(title: "정보") {
            VStack(spacing: 0) {
                SettingsRow(
                    icon: "questionmark.circle.fill",
                    iconColor: .systemGray,
                    title: "도움말",
                    value: nil
                ) {
                    selectHelp()
                }
                
                Divider()
                    .padding(.leading, DesignTokens.Spacing.xxl + DesignTokens.Spacing.xl)
                
                SettingsRow(
                    icon: "doc.text.fill",
                    iconColor: .systemGray,
                    title: "이용약관",
                    value: nil
                ) {
                    selectTermsOfService()
                }
                
                Divider()
                    .padding(.leading, DesignTokens.Spacing.xxl + DesignTokens.Spacing.xl)
                
                SettingsRow(
                    icon: "hand.raised.fill",
                    iconColor: .systemGray,
                    title: "개인정보 처리방침",
                    value: nil
                ) {
                    selectPrivacyPolicy()
                }
                
                Divider()
                    .padding(.leading, DesignTokens.Spacing.xxl + DesignTokens.Spacing.xl)
                
                SettingsRow(
                    icon: "info.circle.fill",
                    iconColor: .systemGray,
                    title: "버전",
                    value: viewStore.version
                ) {
                    selectVersion()
                }
            }
        }
    }
    
    private func selectVersion() {
        // 버전 정보 표시 로직
        Logger.debug("Version info requested")
    }
}

// MARK: - Legacy SettingsViewModel removed - now using VIP + @Observable pattern
