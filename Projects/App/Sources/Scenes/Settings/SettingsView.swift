import SwiftUI
import DesignSystem
import Core
import Entity
import Factory

/// Phase 2.2: SettingsView 프리미엄 피나테크 재설계 (v2.0)
/// 3가지 핵심 키워드: Modern Minimalism + Premium Fintech + Glassmorphism
/// 프리미엄 피나테크 앱(Revolut, N26) 수준의 럭셔리 디자인

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
    // 동적 상태 (관찰 필요)
    var isLoading = false
    var displayMode = "시스템"
    var notificationStatus = "켜짐"
    var securityMode = "Face ID"
    var network = "메인넷"
    var showDisplayModeSelector = false
    var alertMessage: String?
    
    // 정적 데이터 (성능 최적화)
    let fontSize = "기본"
    let currency = "USD"
    let language = "한국어"
    let version = "1.0.0"
    let profileData = ProfileData(
        displayName: "Kingthereum Wallet",
        formattedAddress: "0x742d...9aE3",
        avatarInitials: "KW"
    )
    
    // MARK: - Display Logic
    
    func displaySettings(viewModel: SettingsScene.LoadSettings.ViewModel) {
        displayMode = viewModel.displayMode
        notificationStatus = viewModel.notificationEnabled ? "켜짐" : "꺼짐"
        securityMode = viewModel.securityMode
        network = viewModel.network
        
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
        // profileData는 이제 정적이므로 업데이트 불필요
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
                // 프리미엄 피나테크 배경 - 다크모드 가독성 개선 그라데이션
                LinearGradient(
                    colors: [
                        KingDesignTokens.Colors.background,
                        KingDesignTokens.Colors.secondary,
                        KingDesignTokens.Colors.secondary.opacity(0.85)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if viewStore.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.4)
                            .tint(KingDesignTokens.Colors.accent)
                        
                        Text("설정 로드 중...")
                            .font(KingDesignTokens.Typography.body)
                            .foregroundColor(KingDesignTokens.Colors.secondary)
                    }
                    .padding(32)
                    .trustGlassCard(level: .standard, cornerRadius: 20)
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 32) {
                            // 1. 프리미엄 프로필 히어로 섹션
                            premiumProfileHero
                            
                            // 2. 핵심 보안 설정 (신뢰성 강조)
                            coreSecuritySection
                            
                            // 3. 개인화 설정 그리드
                            preferencesGridSection
                            
                            // 4. 프로페셔널 지원 섹션
                            professionalSupportSection
                            
                            // 5. 프리미엄 브랜딩 푸터
                            premiumBrandingFooter
                            
                            // 하단 여백 (탭바 여유공간)
                            Color.clear.frame(height: 100)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 32)
                    }
                }
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
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
                        .font(KingDesignTokens.Typography.body)
                        .foregroundColor(KingDesignTokens.Colors.secondary)
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

// MARK: - 프리미엄 피나테크 디자인 컴포넌트

extension SettingsView {
    
    // MARK: - 1. 프리미엄 프로필 히어로 섹션
    
    @ViewBuilder
    private var premiumProfileHero: some View {
        VStack(spacing: 24) {
            // 럭셔리 골드 아바타
            Button(action: selectProfile) {
                VStack(spacing: 16) {
                    // 프리미엄 아바타 컨테이너
                    ZStack {
                        // 외부 골드 글로우 (최적화된 단순 버전)
                        Circle()
                            .fill(KingDesignTokens.Colors.accent.opacity(0.15))
                            .frame(width: 120, height: 120)
                        
                        // 메인 아바타 (단순화된 계층)
                        Text(viewStore.profileData.avatarInitials)
                            .font(KingDesignTokens.Typography.body)
                            .fontWeight(.bold)
                            .foregroundColor(KingDesignTokens.Colors.systemWhite)
                            .frame(width: 88, height: 88)
                            .background(.ultraThinMaterial)
                            .background(KingDesignTokens.Colors.accent.opacity(0.4))
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(KingDesignTokens.Colors.accent.opacity(0.6), lineWidth: 2)
                            )
                        .shadow(color: KingDesignTokens.Colors.accent.opacity(0.2), radius: 10, x: 0, y: 4)
                    }
                    
                    // 프리미엄 프로필 정보
                    VStack(spacing: 8) {
                        Text(viewStore.profileData.displayName)
                            .font(KingDesignTokens.Typography.body)
                            .fontWeight(.semibold)
                            .foregroundColor(KingDesignTokens.Colors.onSurface)
                        
                        // 이더리움 주소 캡슐
                        HStack(spacing: 8) {
                            Image(systemName: "link.circle.fill")
                                .font(.body)
                                .foregroundColor(KingDesignTokens.Colors.secondary)
                            
                            Text(viewStore.profileData.formattedAddress)
                                .font(KingDesignTokens.Typography.body)
                                .foregroundColor(KingDesignTokens.Colors.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .background(
                                    Capsule()
                                        .fill(KingDesignTokens.Colors.secondary.opacity(0.1))
                                )
                        )
                        .overlay(
                            Capsule()
                                .stroke(KingDesignTokens.Colors.secondary.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(32)
        .trustGlassCard(level: .prominent, cornerRadius: 24)
        .shadow(color: KingDesignTokens.Colors.accent.opacity(0.15), radius: 12, x: 0, y: 6)
    }
    
    // MARK: - 2. 핵심 보안 설정 섹션
    
    @ViewBuilder
    private var coreSecuritySection: some View {
        VStack(spacing: 20) {
            // 섹션 헤더 - 가독성 강화
            HStack {
                Text("보안 및 인증")
                    .font(KingDesignTokens.Typography.body)
                    .fontWeight(.bold)
                    .foregroundColor(KingDesignTokens.Colors.onSurface)
                    .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
                Spacer()
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.ultraThinMaterial)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(KingDesignTokens.Colors.surfaceVariant.opacity(0.1))
                    )
            )
            
            VStack(spacing: 16) {
                // 생체인증 설정 (최우선)
                premiumSettingCard(
                    icon: "faceid",
                    title: "생체 인증",
                    value: viewStore.securityMode,
                    accentColor: Color.green,
                    isPrimary: true
                ) {
                    selectSecurity()
                }
                
                // 알림 설정
                premiumSettingCard(
                    icon: "bell.circle.fill",
                    title: "알림",
                    value: viewStore.notificationStatus,
                    accentColor: KingDesignTokens.Colors.secondary,
                    isPrimary: false
                ) {
                    toggleNotification()
                }
                
                // 네트워크 설정
                premiumSettingCard(
                    icon: "network",
                    title: "네트워크",
                    value: viewStore.network,
                    accentColor: KingDesignTokens.Colors.secondary,
                    isPrimary: false
                ) {
                    selectNetwork()
                }
                
                // 화면 모드
                premiumSettingCard(
                    icon: "moon.circle.fill",
                    title: "화면 모드",
                    value: viewStore.displayMode,
                    accentColor: KingDesignTokens.Colors.secondary,
                    isPrimary: false
                ) {
                    viewStore.showDisplayModeSelector = true
                }
            }
        }
    }
    
    // MARK: - 3. 개인화 설정 그리드
    
    @ViewBuilder
    private var preferencesGridSection: some View {
        VStack(spacing: 20) {
            // 섹션 헤더 - 가독성 강화
            HStack {
                Text("개인화")
                    .font(KingDesignTokens.Typography.body)
                    .fontWeight(.bold)
                    .foregroundColor(KingDesignTokens.Colors.onSurface)
                    .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
                Spacer()
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.ultraThinMaterial)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(KingDesignTokens.Colors.surfaceVariant.opacity(0.1))
                    )
            )
            
            // 2x2 그리드
            HStack(spacing: 16) {
                // 언어 설정
                premiumQuickCard(
                    icon: "globe",
                    title: "언어",
                    value: viewStore.language,
                    accentColor: KingDesignTokens.Colors.secondary
                ) {
                    selectLanguage()
                }
                
                // 통화 설정
                premiumQuickCard(
                    icon: "dollarsign.circle.fill",
                    title: "통화",
                    value: viewStore.currency,
                    accentColor: KingDesignTokens.Colors.accent
                ) {
                    selectCurrency()
                }
            }
        }
    }
    
    // MARK: - 4. 프로페셔널 지원 섹션
    
    @ViewBuilder
    private var professionalSupportSection: some View {
        VStack(spacing: 20) {
            // 섹션 헤더 - 가독성 강화
            HStack {
                Text("지원 및 정보")
                    .font(KingDesignTokens.Typography.body)
                    .fontWeight(.bold)
                    .foregroundColor(KingDesignTokens.Colors.onSurface)
                    .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
                Spacer()
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.ultraThinMaterial)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(KingDesignTokens.Colors.surfaceVariant.opacity(0.1))
                    )
            )
            
            VStack(spacing: 12) {
                professionalSupportRow(
                    icon: "questionmark.circle.fill",
                    title: "도움말 및 지원",
                    subtitle: "24/7 프리미엄 지원",
                    iconColor: KingDesignTokens.Colors.secondary
                ) {
                    selectHelp()
                }
                
                professionalSupportRow(
                    icon: "doc.text.fill",
                    title: "이용약관",
                    subtitle: "서비스 약관 및 정책",
                    iconColor: KingDesignTokens.Colors.secondary
                ) {
                    selectTermsOfService()
                }
                
                professionalSupportRow(
                    icon: "hand.raised.fill",
                    title: "개인정보 처리방침",
                    subtitle: "데이터 보호 정책",
                    iconColor: KingDesignTokens.Colors.secondary
                ) {
                    selectPrivacyPolicy()
                }
            }
        }
        .padding(24)
        .ultraMinimalGlass(level: .standard)
    }
    
    // MARK: - 5. 프리미엄 브랜딩 푸터
    
    @ViewBuilder
    private var premiumBrandingFooter: some View {
        VStack(spacing: 16) {
            // Kingthereum 로고 (단순화)
            HStack(spacing: 12) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(KingDesignTokens.Colors.systemWhite)
                    .frame(width: 32, height: 32)
                    .background(KingDesignTokens.Colors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Kingthereum")
                        .font(KingDesignTokens.Typography.body)
                        .fontWeight(.semibold)
                        .foregroundColor(KingDesignTokens.Colors.onSurface)
                    
                    Text("v\(viewStore.version)")
                        .font(KingDesignTokens.Typography.body)
                        .foregroundColor(KingDesignTokens.Colors.secondary)
                }
                
                Spacer()
                
                Text("프리미엄 이더리움 지갑")
                    .font(KingDesignTokens.Typography.body)
                    .foregroundColor(KingDesignTokens.Colors.accent)
            }
            .padding(24)
            .ultraMinimalGlass(level: .subtle)
        }
    }
    
    // MARK: - 보조 컴포넌트들
    
    @ViewBuilder
    private func premiumSettingCard(
        icon: String,
        title: String,
        value: String,
        accentColor: Color,
        isPrimary: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // 프리미엄 아이콘 (단순화)
                Image(systemName: icon)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(accentColor)
                    .frame(width: 44, height: 44)
                    .background(accentColor.opacity(isPrimary ? 0.2 : 0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // 텍스트 정보
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(KingDesignTokens.Typography.body)
                        .fontWeight(.semibold)
                        .foregroundColor(KingDesignTokens.Colors.onSurface)
                        .shadow(color: Color.black.opacity(0.2), radius: 0.5, x: 0, y: 0.5)
                    
                    Text(value)
                        .font(KingDesignTokens.Typography.body)
                        .foregroundColor(accentColor)
                }
                
                Spacer()
                
                // 화살표
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(KingDesignTokens.Colors.secondary)
            }
            .padding(24)
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(accentColor.opacity(isPrimary ? 0.08 : 0.03))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            accentColor.opacity(isPrimary ? 0.2 : 0.1),
                            lineWidth: isPrimary ? 1 : 0.5
                        )
                )
        )
        .shadow(color: accentColor.opacity(0.1), radius: 6, x: 0, y: 3)
    }
    
    @ViewBuilder
    private func premiumQuickCard(
        icon: String,
        title: String,
        value: String,
        accentColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 16) {
                // 아이콘 (단순화)
                Image(systemName: icon)
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(accentColor)
                    .frame(width: 56, height: 56)
                    .background(accentColor.opacity(0.15))
                    .clipShape(Circle())
                
                // 텍스트 정보
                VStack(spacing: 4) {
                    Text(title)
                        .font(KingDesignTokens.Typography.body)
                        .fontWeight(.semibold)
                        .foregroundColor(KingDesignTokens.Colors.onSurface)
                        .shadow(color: Color.black.opacity(0.2), radius: 0.5, x: 0, y: 0.5)
                    
                    Text(value)
                        .font(KingDesignTokens.Typography.body)
                        .foregroundColor(accentColor)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .padding(.horizontal, 16)
        }
        .buttonStyle(PlainButtonStyle())
        .ultraMinimalGlass(level: .standard)
        .shadow(color: accentColor.opacity(0.08), radius: 4, x: 0, y: 2)
    }
    
    @ViewBuilder
    private func professionalSupportRow(
        icon: String,
        title: String,
        subtitle: String,
        iconColor: Color = KingDesignTokens.Colors.secondary,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // 아이콘
                Image(systemName: icon)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(iconColor)
                    .frame(width: 20)
                
                // 텍스트 정보
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(KingDesignTokens.Typography.body)
                        .fontWeight(.semibold)
                        .foregroundColor(KingDesignTokens.Colors.onSurface)
                        .shadow(color: Color.black.opacity(0.2), radius: 0.5, x: 0, y: 0.5)
                    
                    Text(subtitle)
                        .font(KingDesignTokens.Typography.body)
                        .foregroundColor(KingDesignTokens.Colors.secondary)
                }
                
                Spacer()
                
                // 화살표
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(KingDesignTokens.Colors.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview("Premium SettingsView") {
    SettingsView(showTabBar: .constant(true))
        .preferredColorScheme(.dark)
}

#Preview("Premium SettingsView - Light") {
    SettingsView(showTabBar: .constant(true))
        .preferredColorScheme(.light)
}
