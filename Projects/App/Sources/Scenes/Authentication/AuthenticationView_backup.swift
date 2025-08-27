import SwiftUI
import Core
import DesignSystem
import Entity
import Factory
import SecurityKit

/// 인증 화면의 디스플레이 로직을 정의하는 프로토콜
/// VIP 아키텍처에서 Presenter가 View에게 데이터를 전달하기 위한 인터페이스
@MainActor
protocol AuthenticationDisplayLogic: AnyObject {
    /// PIN 설정 결과를 화면에 표시
    func displayPINSetupResult(viewModel: AuthenticationScene.SetupPIN.ViewModel)
    /// 생체인증 결과를 화면에 표시
    func displayBiometricAuthenticationResult(viewModel: AuthenticationScene.AuthenticateWithBiometrics.ViewModel)
    /// PIN 인증 결과를 화면에 표시
    func displayPINAuthenticationResult(viewModel: AuthenticationScene.AuthenticateWithPIN.ViewModel)
    /// 생체인증 가능 여부를 화면에 표시
    func displayBiometricAvailability(viewModel: AuthenticationScene.CheckBiometricAvailability.ViewModel)
    /// 지갑 생성 결과를 화면에 표시
    func displayWalletCreationResult(viewModel: AuthenticationScene.CreateWallet.ViewModel)
    /// 지갑 복원 결과를 화면에 표시
    func displayWalletImportResult(viewModel: AuthenticationScene.ImportWallet.ViewModel)
}

/// 인증 화면의 진행 단계
enum AuthenticationStep: String, CaseIterable {
    case welcome = "welcome"
    case pinSetup = "pin_setup"
    case biometricSetup = "biometric_setup"
    case walletCreation = "wallet_creation"
    case walletImport = "wallet_import"
    case backup = "backup"
}

/// SwiftUI용 Authentication ViewStore (DisplayLogic 구현)
@MainActor
@Observable
final class AuthenticationViewStore: AuthenticationDisplayLogic {
    weak var appCoordinator: AppCoordinator?
    var currentStep: AuthenticationStep = .welcome
    var errorMessage: String?
    var showMnemonicView = false
    var isLoading = false
    var biometricAvailable = false
    
    func displayPINSetupResult(viewModel: AuthenticationScene.SetupPIN.ViewModel) {
        if viewModel.success {
            currentStep = .biometricSetup
        } else {
            errorMessage = viewModel.errorMessage
        }
    }
    
    func displayBiometricAuthenticationResult(viewModel: AuthenticationScene.AuthenticateWithBiometrics.ViewModel) {
        isLoading = false
        if viewModel.success {
            // 인증 성공 시 메인 앱으로 이동
            appCoordinator?.completeAuthentication()
        } else {
            errorMessage = viewModel.errorMessage
        }
    }
    
    func displayPINAuthenticationResult(viewModel: AuthenticationScene.AuthenticateWithPIN.ViewModel) {
        isLoading = false
        if viewModel.success {
            // 인증 성공 시 메인 앱으로 이동
            appCoordinator?.completeAuthentication()
        } else {
            errorMessage = viewModel.errorMessage
        }
    }
    
    func displayBiometricAvailability(viewModel: AuthenticationScene.CheckBiometricAvailability.ViewModel) {
        biometricAvailable = viewModel.isAvailable
    }
    
    func displayWalletCreationResult(viewModel: AuthenticationScene.CreateWallet.ViewModel) {
        if viewModel.success {
            showMnemonicView = true
        } else {
            errorMessage = viewModel.errorMessage
        }
    }
    
    func displayWalletImportResult(viewModel: AuthenticationScene.ImportWallet.ViewModel) {
        if viewModel.success {
            currentStep = .pinSetup
        } else {
            errorMessage = viewModel.errorMessage
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
}

/// Kingthereum 지갑의 인증 화면
/// Clean Swift VIP 패턴을 따르는 SwiftUI 네이티브 구현
struct AuthenticationView: View {
    @EnvironmentObject private var appCoordinator: AppCoordinator
    @State private var viewStore = AuthenticationViewStore()
    
    // MARK: - VIP Architecture Components
    private let interactor: AuthenticationBusinessLogic
    private let presenter: AuthenticationPresenter
    
    init() {
        let interactor = AuthenticationInteractor()
        let presenter = AuthenticationPresenter()
        
        interactor.presenter = presenter
        self.interactor = interactor
        self.presenter = presenter
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 프리미엄 배경 그라데이션
                KingGradients.backgroundAmbient
                    .ignoresSafeArea()
                
                // 홀로그래픽 오버레이 효과
                RadialGradient(
                    colors: [
                        KingColors.accent.opacity(0.1),
                        Color.clear,
                        KingColors.accentSecondary.opacity(0.05)
                    ],
                    center: .topLeading,
                    startRadius: 100,
                    endRadius: geometry.size.width
                )
                .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: DesignTokens.Spacing.xxl) {
                        // 프리미엄 헤더 섹션
                        premiumHeaderSection
                        
                        // 고급 인증 옵션들
                        authenticationOptionsSection
                        
                        // 하단 여백
                        Color.clear.frame(height: DesignTokens.Spacing.xl)
                    }
                    .padding(.horizontal, DesignTokens.Spacing.xl)
                    .padding(.vertical, DesignTokens.Spacing.xxl)
                }
            }
        }
        .alert("알림", isPresented: Binding<Bool>(
            get: { viewStore.errorMessage != nil },
            set: { _ in viewStore.clearError() }
        )) {
            Button("확인", role: .cancel) {
                viewStore.clearError()
            }
        } message: {
            if let errorMessage = viewStore.errorMessage {
                Text(errorMessage)
                    .kingStyle(.bodyPrimary)
            }
        }
        .onAppear {
            // Connect presenter to viewStore after view initialization
            presenter.viewController = viewStore
            viewStore.appCoordinator = appCoordinator
            checkBiometricAvailability()
        }
        .sheet(isPresented: $viewStore.showMnemonicView) {
            premiumMnemonicView
        }
    }
    
    // MARK: - Action Methods
    
    private func authenticateWithBiometrics() {
        viewStore.isLoading = true
        let request = AuthenticationScene.AuthenticateWithBiometrics.Request(reason: "지갑에 접근하기 위해 생체 인증을 사용하세요")
        interactor.authenticateWithBiometrics(request: request)
    }
    
    private func authenticateWithPIN() {
        // PIN 입력 로직 구현 예정
        print("PIN 인증 요청")
    }
    
    // MARK: - Helper Methods
    private func checkBiometricAvailability() {
        let request = AuthenticationScene.CheckBiometricAvailability.Request()
        interactor.checkBiometricAvailability(request: request)
    }
    
    private func setupPIN(_ pin: String) {
        let request = AuthenticationScene.SetupPIN.Request(pin: pin)
        interactor.setupPIN(request: request)
    }
    
    private func createWallet() {
        let request = AuthenticationScene.CreateWallet.Request(walletName: "My Wallet")
        interactor.createWallet(request: request)
    }
    
    // MARK: - Premium UI Components
    
    @ViewBuilder
    private var premiumHeaderSection: some View {
        VStack(spacing: DesignTokens.Spacing.xxl) {
            // 프리미엄 앱 아이콘 - 다층 구조
            ZStack {
                // 외부 홀로그래픽 링
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                KingColors.accent,
                                KingColors.accentSecondary,
                                KingColors.success,
                                KingColors.warning,
                                KingColors.accent
                            ],
                            center: .center
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 140, height: 140)
                    .blur(radius: 1)
                
                // 중간 그라데이션 원
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                KingColors.accent.opacity(0.3),
                                KingColors.accent.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 65
                        )
                    )
                    .frame(width: 130, height: 130)
                
                // 메인 아이콘 컨테이너 - VibrancyGlass로 업그레이드
                ZStack {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 120, height: 120)
                    
                    // 내부 하이라이트
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.4),
                                    Color.clear
                                ],
                                center: .init(x: 0.3, y: 0.3),
                                startRadius: 10,
                                endRadius: 50
                            )
                        )
                        .frame(width: 118, height: 118)
                    
                    // 크라운 아이콘 - 동적 효과 적용
                    Image(systemName: "crown.fill")
                        .font(.system(size: 52, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    KingColors.warning,
                                    Color.yellow,
                                    Color.orange
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: KingColors.warning.opacity(0.5), radius: 8, x: 0, y: 4)
                        .symbolEffect(.pulse, isActive: true)
                }
                .vibrancyGlassCard(level: .intense)
                .shadow(color: KingColors.cardShadow.opacity(0.3), radius: 20, x: 0, y: 10)
                .shadow(color: KingColors.accent.opacity(0.2), radius: 40, x: 0, y: 20)
            }
            
            // 프리미엄 타이틀 섹션
            VStack(spacing: DesignTokens.Spacing.lg) {
                // 메인 타이틀
                VStack(spacing: DesignTokens.Spacing.xs) {
                    Text("Kingthereum")
                        .kingStyle(KingTextStyle(
                            font: KingTypography.displayLarge,
                            color: KingColors.textPrimary
                        ))
                        .foregroundStyle(KingGradients.web3Rainbow)
                        .accessibilityLabel("Kingthereum 지갑")
                    
                    // 언더라인 효과
                    Rectangle()
                        .fill(KingGradients.accent)
                        .frame(height: DesignTokens.Size.Divider.thick)
                        .frame(width: 120)
                        .blur(radius: 1)
                }
                
                // 서브타이틀 & 설명
                VStack(spacing: DesignTokens.Spacing.sm) {
                    Text("프리미엄 이더리움 지갑")
                        .kingStyle(KingTextStyle(
                            font: KingTypography.headlineMedium,
                            color: KingColors.textSecondary
                        ))
                    
                    Text("차세대 Web3 보안 기술로 당신의 자산을 보호합니다")
                        .kingStyle(KingTextStyle(
                            font: KingTypography.bodyMedium,
                            color: KingColors.textTertiary
                        ))
                        .multilineTextAlignment(.center)
                        .accessibilityLabel("차세대 Web3 보안 기술로 당신의 자산을 보호합니다")
                }
            }
            
            // 보안 배지들
            HStack(spacing: DesignTokens.Spacing.md) {
                securityBadge(icon: "shield.checkered", text: "군사급 암호화")
                securityBadge(icon: "key.horizontal.fill", text: "Hardware Security")
                securityBadge(icon: "network.badge.shield.half.filled", text: "Secure Enclave")
            }
        }
        .padding(.top, DesignTokens.Spacing.xl)
    }
    
    @ViewBuilder
    private func securityBadge(icon: String, text: String) -> some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(KingColors.success)
            
            Text(text)
                .kingStyle(KingTextStyle(
                    font: KingTypography.helper,
                    color: KingColors.success
                ))
        }
        .padding(.horizontal, DesignTokens.Spacing.sm)
        .padding(.vertical, DesignTokens.Spacing.xs)
        .glassCard(level: .subtle, context: .button)
    }
    
    @ViewBuilder
    private var authenticationOptionsSection: some View {
        VStack(spacing: DesignTokens.Spacing.xxl) {
            // 섹션 타이틀
            VStack(spacing: DesignTokens.Spacing.sm) {
                Text("안전한 인증")
                    .kingStyle(KingTextStyle(
                        font: KingTypography.headlineLarge,
                        color: KingColors.textPrimary
                    ))
                
                Text("원하는 인증 방법을 선택하세요")
                    .kingStyle(KingTextStyle(
                        font: KingTypography.bodyMedium,
                        color: KingColors.textSecondary
                    ))
            }
            
            // 프리미엄 생체인증 카드
            if viewStore.biometricAvailable {
                premiumBiometricCard
            }
            
            // 프리미엄 PIN 인증 카드
            premiumPINCard
            
            // 추가 인증 옵션들
            additionalAuthOptions
        }
    }
    
    @ViewBuilder
    private var premiumBiometricCard: some View {
        Button {
            authenticateWithBiometrics()
        } label: {
            VStack(spacing: DesignTokens.Spacing.lg) {
                // 생체인증 아이콘 섹션
                ZStack {
                    // 홀로그래픽 배경
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            RadialGradient(
                                colors: [
                                    KingColors.success.opacity(0.3),
                                    KingColors.success.opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 80
                            )
                        )
                        .frame(width: 100, height: 80)
                    
                    // 메인 아이콘 - 향상된 동적 효과
                    Image(systemName: viewStore.isLoading ? "hourglass" : "faceid")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    KingColors.success,
                                    Color.green,
                                    KingColors.success.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolEffect(.variableColor, isActive: viewStore.isLoading)
                }
                
                // 텍스트 정보
                VStack(spacing: DesignTokens.Spacing.sm) {
                    Text("생체 인증")
                        .kingStyle(KingTextStyle(
                            font: KingTypography.headlineMedium,
                            color: KingColors.textPrimary
                        ))
                    
                    Text("Face ID 또는 Touch ID로 빠르고 안전하게")
                        .kingStyle(KingTextStyle(
                            font: KingTypography.bodySmall,
                            color: KingColors.textSecondary
                        ))
                        .multilineTextAlignment(.center)
                }
                
                // 상태 인디케이터
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Circle()
                        .fill(KingColors.success)
                        .frame(width: 6, height: 6)
                    
                    Text("권장")
                        .kingStyle(KingTextStyle(
                            font: KingTypography.helper,
                            color: KingColors.success
                        ))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(DesignTokens.Spacing.xl)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(viewStore.isLoading)
        .glassCard(level: .prominent, context: .card, cornerRadius: DesignTokens.CornerRadius.xl)
        .shadow(color: KingColors.success.opacity(0.2), radius: 15, x: 0, y: 8)
        .shadow(color: KingColors.cardShadow.opacity(0.1), radius: 30, x: 0, y: 15)
        .scaleEffect(viewStore.isLoading ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: viewStore.isLoading)
        .accessibilityLabel("생체 인증으로 시작")
        .accessibilityHint("Face ID 또는 Touch ID를 사용하여 지갑에 접근합니다")
    }
    
    @ViewBuilder
    private var premiumPINCard: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            // PIN 입력 프리뷰 카드
            HStack(spacing: DesignTokens.Spacing.lg) {
                // PIN 아이콘
                ZStack {
                    Circle()
                        .fill(KingGradients.neon.opacity(0.2))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "key.fill")
                        .font(.title3)
                        .foregroundStyle(KingGradients.accent)
                }
                
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("6자리 PIN 입력")
                        .kingStyle(KingTextStyle(
                            font: KingTypography.bodyEmphasized,
                            color: KingColors.textPrimary
                        ))
                    
                    Text("설정된 PIN 코드를 입력하세요")
                        .kingStyle(KingTextStyle(
                            font: KingTypography.bodySmall,
                            color: KingColors.textSecondary
                        ))
                }
                
                Spacer()
                
                // PIN 도트들
                HStack(spacing: DesignTokens.Spacing.xs) {
                    ForEach(0..<6, id: \.self) { index in
                        Circle()
                            .fill(KingColors.textTertiary.opacity(0.3))
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(KingColors.accent.opacity(0.5), lineWidth: 1)
                            )
                    }
                }
            }
            .padding(DesignTokens.Spacing.lg)
            .glassCard(level: .standard, context: .card, cornerRadius: DesignTokens.CornerRadius.lg)
            
            // PIN 인증 버튼
            Button {
                authenticateWithPIN()
            } label: {
                HStack(spacing: DesignTokens.Spacing.md) {
                    Image(systemName: "lock.open.fill")
                        .font(.title3)
                    
                    Text("PIN으로 잠금 해제")
                        .kingStyle(KingTextStyle(
                            font: KingTypography.buttonPrimary,
                            color: KingColors.textInverse
                        ))
                }
                .frame(maxWidth: .infinity)
                .frame(height: DesignTokens.Size.Button.lg)
                .background(KingGradients.buttonPrimary)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg))
                .shadow(color: KingColors.accent.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(viewStore.isLoading)
            .accessibilityLabel("PIN으로 잠금 해제")
            .accessibilityHint("6자리 PIN 코드를 입력하여 지갑에 접근합니다")
        }
    }
    
    @ViewBuilder
    private var additionalAuthOptions: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            // 구분선
            HStack {
                Rectangle()
                    .fill(KingColors.textTertiary.opacity(0.3))
                    .frame(height: DesignTokens.Size.Divider.thin)
                
                Text("또는")
                    .kingStyle(KingTextStyle(
                        font: KingTypography.caption,
                        color: KingColors.textTertiary
                    ))
                    .padding(.horizontal, DesignTokens.Spacing.md)
                
                Rectangle()
                    .fill(KingColors.textTertiary.opacity(0.3))
                    .frame(height: DesignTokens.Size.Divider.thin)
            }
            
            // 추가 옵션들
            HStack(spacing: DesignTokens.Spacing.md) {
                // 지갑 생성
                quickActionCard(
                    icon: "plus.circle.fill",
                    title: "새 지갑",
                    subtitle: "생성",
                    color: KingColors.accent
                ) {
                    createWallet()
                }
                
                // 지갑 복원
                quickActionCard(
                    icon: "arrow.clockwise.circle.fill",
                    title: "지갑 복원",
                    subtitle: "Import",
                    color: KingColors.info
                ) {
                    // 복원 로직 구현 예정
                    print("지갑 복원 요청")
                }
            }
        }
    }
    
    @ViewBuilder
    private func quickActionCard(
        icon: String,
        title: String,
        subtitle: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: DesignTokens.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                }
                
                VStack(spacing: 2) {
                    Text(title)
                        .kingStyle(KingTextStyle(
                            font: KingTypography.labelMedium,
                            color: KingColors.textPrimary
                        ))
                    
                    Text(subtitle)
                        .kingStyle(KingTextStyle(
                            font: KingTypography.helper,
                            color: color
                        ))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignTokens.Spacing.lg)
            .glassCard(level: .subtle, context: .button, cornerRadius: DesignTokens.CornerRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private var premiumMnemonicView: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Text("복구 구문")
                .kingStyle(KingTextStyle(
                    font: KingTypography.headlineLarge,
                    color: KingColors.textPrimary
                ))
            
            Text("지갑의 니모닉 복구 구문을 안전하게 보관하세요")
                .kingStyle(KingTextStyle(
                    font: KingTypography.bodyMedium,
                    color: KingColors.textSecondary
                ))
                .multilineTextAlignment(.center)
            
            // 향후 MnemonicView 구현 예정
            Spacer()
        }
        .padding(DesignTokens.Spacing.xl)
        .background(KingGradients.backgroundAmbient)
    }
}

// MARK: - Previews
#Preview("AuthenticationView") {
    AuthenticationView()
        .environmentObject(AppCoordinator())
}

#Preview("AuthenticationView - Dark Mode") {
    AuthenticationView()
        .environmentObject(AppCoordinator())
        .preferredColorScheme(.dark)
}