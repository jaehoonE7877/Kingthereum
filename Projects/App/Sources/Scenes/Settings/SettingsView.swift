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
                        Color.clear.frame(height: DesignTokens.Spacing.scrollBottomPadding)
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
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("프로필")
                .kingStyle(.headlinePrimary)
                .padding(.horizontal, DesignTokens.Spacing.md)
            
            Button {
                selectProfile()
            } label: {
                HStack(spacing: DesignTokens.Spacing.lg) {
                    // 고급스러운 프로필 이미지
                    ZStack {
                        // 배경 그라데이션 원형
                        Circle()
                            .fill(KingthereumGradients.accent)
                            .frame(width: 80, height: 80)
                        
                        // Glass 효과 테두리
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.6),
                                        Color.clear,
                                        KingthereumColors.accent.opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 80, height: 80)
                        
                        // 내부 하이라이트 효과
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.white.opacity(0.2),
                                        Color.clear
                                    ],
                                    center: .init(x: 0.3, y: 0.3),
                                    startRadius: 5,
                                    endRadius: 30
                                )
                            )
                            .frame(width: 78, height: 78)
                        
                        // 아바타 텍스트
                        Text(viewStore.profileData.avatarInitials)
                            .kingStyle(KingthereumTextStyle(
                                font: KingthereumTypography.headlineLarge,
                                color: KingthereumColors.textInverse
                            ))
                    }
                    
                    // 프로필 정보
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text(viewStore.profileData.displayName)
                            .kingStyle(.headlinePrimary)
                        
                        HStack(spacing: DesignTokens.Spacing.xs) {
                            Image(systemName: "link.circle.fill")
                                .font(.caption)
                                .foregroundColor(KingthereumColors.accent)
                            
                            Text(viewStore.profileData.formattedAddress)
                                .kingStyle(.bodySecondary)
                        }
                        
                        // 상태 표시 배지
                        HStack(spacing: DesignTokens.Spacing.xs) {
                            Circle()
                                .fill(KingthereumColors.success)
                                .frame(width: 8, height: 8)
                            
                            Text("활성화됨")
                                .kingStyle(KingthereumTextStyle(
                                    font: KingthereumTypography.caption,
                                    color: KingthereumColors.success
                                ))
                        }
                    }
                    
                    Spacer()
                    
                    // 우아한 화살표 아이콘
                    ZStack {
                        Circle()
                            .fill(KingthereumColors.accent.opacity(0.1))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(KingthereumColors.accent)
                    }
                }
                .padding(DesignTokens.Spacing.lg)
            }
            .buttonStyle(PlainButtonStyle())
            .background(
                ZStack {
                    // 메인 배경
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xl)
                        .fill(KingthereumGradients.cardElevated)
                    
                    // 상단 하이라이트
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xl)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.1),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                    
                    // 테두리 효과
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xl)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    KingthereumColors.accent.opacity(0.2),
                                    Color.clear,
                                    KingthereumColors.accentSecondary.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .shadow(color: KingthereumColors.cardShadow, radius: 10, x: 0, y: 4)
            .shadow(color: KingthereumColors.accent.opacity(0.1), radius: 20, x: 0, y: 8)
        }
    }
    
    private var displaySection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("디스플레이")
                .kingStyle(.headlinePrimary)
                .padding(.horizontal, DesignTokens.Spacing.md)
            
            VStack(spacing: DesignTokens.Spacing.xs) {
                // 화면 모드 - 고급 카드
                Button {
                    viewStore.showDisplayModeSelector = true
                } label: {
                    HStack(spacing: DesignTokens.Spacing.lg) {
                        // 아이콘 배경
                        ZStack {
                            Circle()
                                .fill(KingthereumGradients.aurora.opacity(0.3))
                                .frame(width: 48, height: 48)
                            
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.purple.opacity(0.6),
                                            Color.clear,
                                            Color.indigo.opacity(0.3)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                                .frame(width: 48, height: 48)
                            
                            Image(systemName: "moon.circle.fill")
                                .font(.title2)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.purple, Color.indigo],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                            Text("화면 모드")
                                .kingStyle(.bodyPrimary)
                            
                            Text(viewStore.displayMode)
                                .kingStyle(KingthereumTextStyle(
                                    font: KingthereumTypography.labelMedium,
                                    color: Color.purple
                                ))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(KingthereumColors.textTertiary)
                    }
                    .padding(DesignTokens.Spacing.lg)
                }
                .buttonStyle(PlainButtonStyle())
                .background(
                    ZStack {
                        // 메인 배경
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                            .fill(.ultraThinMaterial)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                                    .fill(KingthereumGradients.aurora.opacity(0.1))
                            )
                        
                        // 상단 하이라이트
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.purple.opacity(0.1),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                        
                        // 테두리
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.purple.opacity(0.2),
                                        Color.indigo.opacity(0.1),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                )
                .shadow(color: Color.purple.opacity(0.1), radius: 8, x: 0, y: 4)
                
                // 글자 크기 - 고급 카드
                Button {
                    selectFontSize()
                } label: {
                    HStack(spacing: DesignTokens.Spacing.lg) {
                        // 아이콘 배경
                        ZStack {
                            Circle()
                                .fill(KingthereumGradients.neon.opacity(0.3))
                                .frame(width: 48, height: 48)
                            
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.blue.opacity(0.6),
                                            Color.clear,
                                            Color.cyan.opacity(0.3)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                                .frame(width: 48, height: 48)
                            
                            Image(systemName: "textformat.size")
                                .font(.title2)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.blue, Color.cyan],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                            Text("글자 크기")
                                .kingStyle(.bodyPrimary)
                            
                            Text(viewStore.fontSize)
                                .kingStyle(KingthereumTextStyle(
                                    font: KingthereumTypography.labelMedium,
                                    color: Color.blue
                                ))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(KingthereumColors.textTertiary)
                    }
                    .padding(DesignTokens.Spacing.lg)
                }
                .buttonStyle(PlainButtonStyle())
                .background(
                    ZStack {
                        // 메인 배경
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                            .fill(.ultraThinMaterial)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                                    .fill(KingthereumGradients.neon.opacity(0.1))
                            )
                        
                        // 상단 하이라이트
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.blue.opacity(0.1),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                        
                        // 테두리
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.blue.opacity(0.2),
                                        Color.cyan.opacity(0.1),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                )
                .shadow(color: Color.blue.opacity(0.1), radius: 8, x: 0, y: 4)
            }
        }
    }
    
    private func selectFontSize() {
        // 글자 크기 선택 로직
        Logger.debug("Font size selection requested")
    }
    
    private var generalSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            Text("일반")
                .kingStyle(.headlinePrimary)
                .padding(.horizontal, DesignTokens.Spacing.md)
            
            // 알림 - 특별한 스타일 (중요한 설정)
            notificationCard
            
            // 나머지 설정들 - 그리드 형태의 컴팩트한 디자인
            settingsGrid
        }
    }
    
    @ViewBuilder
    private var notificationCard: some View {
        Button {
            toggleNotification()
        } label: {
            HStack(spacing: DesignTokens.Spacing.lg) {
                notificationIcon
                notificationInfo
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(KingthereumColors.textTertiary)
            }
            .padding(DesignTokens.Spacing.lg)
        }
        .buttonStyle(PlainButtonStyle())
        .background(notificationBackground)
        .shadow(color: KingthereumColors.warning.opacity(0.1), radius: 12, x: 0, y: 6)
        .accessibilityLabel("알림 설정")
        .accessibilityValue(viewStore.notificationStatus)
        .accessibilityHint("탭하여 알림을 켜거나 끕니다")
    }
    
    @ViewBuilder
    private var notificationIcon: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            KingthereumColors.warning.opacity(0.4),
                            KingthereumColors.warning.opacity(0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 24
                    )
                )
                .frame(width: 52, height: 52)
            
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 48, height: 48)
            
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            KingthereumColors.warning,
                            Color.orange,
                            KingthereumColors.warning
                        ],
                        center: .center
                    ),
                    lineWidth: 2
                )
                .frame(width: 48, height: 48)
            
            Image(systemName: "bell.circle.fill")
                .font(.title2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [KingthereumColors.warning, Color.orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }
    
    @ViewBuilder
    private var notificationInfo: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text("알림")
                .kingStyle(.bodyPrimary)
            
            HStack(spacing: DesignTokens.Spacing.xs) {
                let isEnabled = viewStore.notificationStatus == "켜짐"
                let statusColor = isEnabled ? KingthereumColors.success : KingthereumColors.textTertiary
                
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                
                Text(viewStore.notificationStatus)
                    .kingStyle(KingthereumTextStyle(
                        font: KingthereumTypography.labelMedium,
                        color: statusColor
                    ))
            }
        }
    }
    
    @ViewBuilder
    private var notificationBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xl)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xl)
                        .fill(KingthereumGradients.warning.opacity(0.05))
                )
            
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xl)
                .stroke(
                    LinearGradient(
                        colors: [
                            KingthereumColors.warning.opacity(0.3),
                            Color.clear,
                            Color.orange.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }
    
    @ViewBuilder
    private var settingsGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DesignTokens.Spacing.md), count: 2), spacing: DesignTokens.Spacing.md) {
            // 보안 설정
            SettingCompactCard(
                icon: "lock.circle.fill",
                title: "보안",
                value: viewStore.securityMode,
                accentColor: KingthereumColors.success,
                gradient: KingthereumGradients.success
            ) {
                selectSecurity()
            }
            .accessibilityLabel("보안 설정")
            .accessibilityValue(viewStore.securityMode)
            .accessibilityHint("탭하여 보안 설정을 변경합니다")
            
            // 네트워크 설정
            SettingCompactCard(
                icon: "network",
                title: "네트워크",
                value: viewStore.network,
                accentColor: KingthereumColors.accent,
                gradient: LinearGradient(colors: [KingthereumColors.accent.opacity(0.1)], startPoint: .top, endPoint: .bottom)
            ) {
                selectNetwork()
            }
            
            // 통화 설정
            SettingCompactCard(
                icon: "dollarsign.circle.fill",
                title: "통화",
                value: viewStore.currency,
                accentColor: KingthereumColors.bitcoin,
                gradient: LinearGradient(colors: [KingthereumColors.bitcoin.opacity(0.1)], startPoint: .top, endPoint: .bottom)
            ) {
                selectCurrency()
            }
            
            // 언어 설정
            SettingCompactCard(
                icon: "globe",
                title: "언어",
                value: viewStore.language,
                accentColor: KingthereumColors.info,
                gradient: KingthereumGradients.info
            ) {
                selectLanguage()
            }
        }
    }
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            Text("정보")
                .kingStyle(.headlinePrimary)
                .padding(.horizontal, DesignTokens.Spacing.md)
            
            VStack(spacing: DesignTokens.Spacing.sm) {
                // 도움말 & 이용약관 - 상단 그룹
                HStack(spacing: DesignTokens.Spacing.md) {
                    AboutCompactCard(
                        icon: "questionmark.circle.fill",
                        title: "도움말",
                        accentColor: KingthereumColors.info
                    ) {
                        selectHelp()
                    }
                    
                    AboutCompactCard(
                        icon: "doc.text.fill",
                        title: "이용약관",
                        accentColor: KingthereumColors.textSecondary
                    ) {
                        selectTermsOfService()
                    }
                }
                
                // 개인정보 처리방침 - 와이드 카드
                Button {
                    selectPrivacyPolicy()
                } label: {
                    HStack(spacing: DesignTokens.Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(KingthereumGradients.holographic.opacity(0.2))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "hand.raised.fill")
                                .font(.title3)
                                .foregroundStyle(KingthereumGradients.holographic)
                        }
                        
                        Text("개인정보 처리방침")
                            .kingStyle(.bodyPrimary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundColor(KingthereumColors.textTertiary)
                    }
                    .padding(DesignTokens.Spacing.md)
                }
                .buttonStyle(PlainButtonStyle())
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                        .fill(.ultraThinMaterial)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                                .fill(KingthereumGradients.holographic.opacity(0.05))
                        )
                )
                
                // 버전 정보 - 특별한 디자인
                HStack(spacing: DesignTokens.Spacing.lg) {
                    ZStack {
                        // 버전 아이콘 배경 - 홀로그래픽 효과
                        Circle()
                            .fill(
                                AngularGradient(
                                    colors: [
                                        KingthereumColors.accent,
                                        KingthereumColors.accentSecondary,
                                        KingthereumColors.success,
                                        KingthereumColors.warning,
                                        KingthereumColors.accent
                                    ],
                                    center: .center
                                )
                            )
                            .frame(width: 48, height: 48)
                        
                        Circle()
                            .fill(.ultraThickMaterial)
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "info.circle.fill")
                            .font(.title2)
                            .foregroundStyle(KingthereumGradients.accent)
                    }
                    
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text("버전")
                            .kingStyle(.bodyPrimary)
                        
                        Text("v\(viewStore.version)")
                            .kingStyle(KingthereumTextStyle(
                                font: KingthereumTypography.labelMedium,
                                color: KingthereumColors.accent
                            ))
                    }
                    
                    Spacer()
                    
                    // 앱 로고 미니어처
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(KingthereumGradients.accent)
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "crown.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(KingthereumColors.textInverse)
                    }
                }
                .padding(DesignTokens.Spacing.lg)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                            .fill(.ultraThinMaterial)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                                    .fill(KingthereumGradients.web3Rainbow.opacity(0.03))
                            )
                        
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        KingthereumColors.accent.opacity(0.2),
                                        Color.clear,
                                        KingthereumColors.accentSecondary.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                )
                .onTapGesture {
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

// MARK: - Helper Components

struct SettingCompactCard: View {
    let icon: String
    let title: String
    let value: String
    let accentColor: Color
    let gradient: LinearGradient
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignTokens.Spacing.md) {
                // 아이콘
                ZStack {
                    Circle()
                        .fill(gradient.opacity(0.3))
                        .frame(width: 44, height: 44)
                    
                    Circle()
                        .stroke(accentColor.opacity(0.4), lineWidth: 1)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(accentColor)
                }
                
                // 제목과 값
                VStack(spacing: DesignTokens.Spacing.xs) {
                    Text(title)
                        .kingStyle(KingthereumTextStyle(
                            font: KingthereumTypography.labelMedium,
                            color: KingthereumColors.textPrimary
                        ))
                        .lineLimit(1)
                    
                    Text(value)
                        .kingStyle(KingthereumTextStyle(
                            font: KingthereumTypography.caption,
                            color: accentColor
                        ))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignTokens.Spacing.lg)
            .padding(.horizontal, DesignTokens.Spacing.md)
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                    .fill(.ultraThinMaterial)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                            .fill(gradient.opacity(0.05))
                    )
                
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                    .stroke(accentColor.opacity(0.2), lineWidth: 0.5)
            }
        )
        .shadow(color: accentColor.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct AboutCompactCard: View {
    let icon: String
    let title: String
    let accentColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignTokens.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(accentColor)
                }
                
                Text(title)
                    .kingStyle(KingthereumTextStyle(
                        font: KingthereumTypography.caption,
                        color: KingthereumColors.textPrimary
                    ))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignTokens.Spacing.md)
            .padding(.horizontal, DesignTokens.Spacing.sm)
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                        .fill(accentColor.opacity(0.05))
                )
        )
    }
}

// MARK: - Legacy SettingsViewModel removed - now using VIP + @Observable pattern

// MARK: - Previews
#Preview("SettingsView") {
    SettingsView(showTabBar: .constant(true))
}

#Preview("SettingsView - Dark Mode") {
    SettingsView(showTabBar: .constant(true))
        .preferredColorScheme(.dark)
}
