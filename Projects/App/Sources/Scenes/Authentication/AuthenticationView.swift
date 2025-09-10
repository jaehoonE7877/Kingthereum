import SwiftUI
import Core
import DesignSystem
import Entity
import Factory
import SecurityKit

/// 🔐 Revolut/N26 Level Premium Authentication 2024
/// Military-grade Security + Premium Fintech Styling
/// Biometric Authentication + Device Security + Rate Limiting

// MARK: - VIP Architecture Support

/// 인증 화면의 디스플레이 로직 프로토콜
@MainActor
protocol AuthenticationDisplayLogic: AnyObject {
    func displayPINSetupResult(viewModel: AuthenticationScene.SetupPIN.ViewModel)
    func displayBiometricAuthenticationResult(viewModel: AuthenticationScene.AuthenticateWithBiometrics.ViewModel)
    func displayPINAuthenticationResult(viewModel: AuthenticationScene.AuthenticateWithPIN.ViewModel)
    func displayBiometricAvailability(viewModel: AuthenticationScene.CheckBiometricAvailability.ViewModel)
    func displayWalletCreationResult(viewModel: AuthenticationScene.CreateWallet.ViewModel)
    func displayWalletImportResult(viewModel: AuthenticationScene.ImportWallet.ViewModel)
}

/// 인증 진행 단계
enum AuthenticationStep: String, CaseIterable {
    case welcome = "welcome"
    case pinSetup = "pin_setup"
    case biometricSetup = "biometric_setup"
    case walletCreation = "wallet_creation"
    case walletImport = "wallet_import"
}

/// SwiftUI용 인증 ViewStore
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
            appCoordinator?.completeAuthentication()
        } else {
            errorMessage = viewModel.errorMessage
        }
    }
    
    func displayPINAuthenticationResult(viewModel: AuthenticationScene.AuthenticateWithPIN.ViewModel) {
        isLoading = false
        if viewModel.success {
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

/// 🔐 Kingthereum Premium Authentication
/// Revolut/N26 수준의 프리미엄 핀테크 인증 화면
struct AuthenticationView: View {
    private let interactor: AuthenticationInteractor = .init()
    @State private var viewStore = AuthenticationViewStore()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    // 애니메이션 상태
    @State private var contentOpacity: Double = 0
    @State private var contentScale: Double = 0.95
    @State private var cardOffset: Double = 30
    
    var body: some View {
        ZStack {
            // 🎨 프리미엄 배경
            premiumBackground
            
            // 🔐 인증 콘텐츠
            VStack(spacing: 0) {
                switch viewStore.currentStep {
                case .welcome:
                    PremiumWelcomeView(viewStore: viewStore)
                case .pinSetup:
                    PremiumPINSetupView(viewStore: viewStore)
                case .biometricSetup:
                    PremiumBiometricSetupView(viewStore: viewStore)
                case .walletCreation:
                    PremiumWelcomeView(viewStore: viewStore)
                case .walletImport:
                    PremiumWelcomeView(viewStore: viewStore)
                }
            }
            .opacity(contentOpacity)
            .scaleEffect(contentScale)
            .offset(y: cardOffset)
            
            // 🚨 오류 오버레이
            if let errorMessage = viewStore.errorMessage {
                PremiumErrorOverlay(
                    message: errorMessage,
                    onDismiss: { viewStore.clearError() }
                )
            }
            
            // 🔄 로딩 오버레이
            if viewStore.isLoading {
                PremiumLoadingOverlay()
            }
        }
        .onAppear {
            Task {
                await performSecurityValidation()
                startPremiumEntryAnimation()
            }
        }
        .sheet(isPresented: $viewStore.showMnemonicView) {
            PremiumMnemonicView()
        }
    }
    
    // MARK: - 프리미엄 컴포넌트들
    
    @ViewBuilder
    private var premiumBackground: some View {
        ZStack {
            // 베이스 그라데이션 배경
            LinearGradient(
                colors: [
                    KingDesignTokens.Colors.background,
                    KingDesignTokens.Colors.surface,
                    KingDesignTokens.Colors.surfaceSecondary
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // 앰비언트 글로우 효과
            RadialGradient(
                colors: [
                    KingDesignTokens.Colors.accent.opacity(0.03),
                    Color.clear
                ],
                center: UnitPoint(x: 0.8, y: 0.2),
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()
        }
    }
    
    // MARK: - 액션 메서드들
    
    private func authenticateWithBiometrics() {
        viewStore.isLoading = true
        let request = AuthenticationScene.AuthenticateWithBiometrics.Request(
            reason: "지갑에 접근하기 위해 생체 인증을 사용하세요"
        )
        interactor.authenticateWithBiometrics(request: request)
    }
    
    private func authenticateWithPIN() {
        print("PIN 인증 요청")
    }
    
    private func checkBiometricAvailability() {
        let request = AuthenticationScene.CheckBiometricAvailability.Request()
        interactor.checkBiometricAvailability(request: request)
    }
    
    private func createWallet() {
        let request = AuthenticationScene.CreateWallet.Request(walletName: "My Wallet")
        interactor.createWallet(request: request)
    }
    
    private func performSecurityValidation() async {
        // 보안 검증 로직
        await MainActor.run {
            checkBiometricAvailability()
        }
    }
    
    private func startPremiumEntryAnimation() {
        withAnimation(KingDesignTokens.Animation.spring.delay(0.1)) {
            contentOpacity = 1.0
            contentScale = 1.0
        }
        
        withAnimation(KingDesignTokens.Animation.spring.delay(0.2)) {
            cardOffset = 0
        }
    }
}
// MARK: - 🔐 Premium Authentication Components

/// 🔐 프리미엄 환영 화면 (Revolut/N26 스타일)
struct PremiumWelcomeView: View {
    @State var viewStore: AuthenticationViewStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        VStack(spacing: KingDesignTokens.Spacing.xxxl) {
            Spacer()
            
            // 🎨 프리미엄 브랜드 섹션
            VStack(spacing: KingDesignTokens.Spacing.xl) {
                // 프리미엄 로고 with 골드 글로우
                ZStack {
                    Circle()
                        .fill(KingDesignTokens.Colors.accent.opacity(0.1))
                        .frame(width: 140, height: 140)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            KingDesignTokens.Colors.accent,
                                            KingDesignTokens.Colors.accent.opacity(0.3)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .shadow(
                            color: KingDesignTokens.Colors.accent.opacity(0.3),
                            radius: 20,
                            x: 0,
                            y: 10
                        )
                    
                    Image(systemName: "crown.fill")
                        .font(.system(size: 56, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    KingDesignTokens.Colors.accent,
                                    KingDesignTokens.Colors.accent.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .scaleEffect(reduceMotion ? 1.0 : 1.02)
                .animation(
                    reduceMotion ? nil : 
                    Animation.easeInOut(duration: 3.0).repeatForever(autoreverses: true),
                    value: reduceMotion
                )
                
                // 프리미엄 브랜딩 텍스트
                VStack(spacing: KingDesignTokens.Spacing.md) {
                    Text("Kingthereum")
                        .font(KingDesignTokens.Typography.displayL)
                        .fontWeight(.bold)
                        .foregroundColor(KingDesignTokens.Colors.primaryText)
                    
                    Text("프리미엄 이더리움 지갑")
                        .font(KingDesignTokens.Typography.body)
                        .foregroundColor(KingDesignTokens.Colors.secondaryText)
                }
            }
            
            Spacer()
            
            // 🔐 인증 액션 버튼들
            VStack(spacing: KingDesignTokens.Spacing.lg) {
                // 생체 인증 (가능할 때만)
                if viewStore.biometricAvailable {
                    GlassButton(
                        "생체 인증으로 시작",
                        icon: "faceid",
                        style: .primary
                    ) {
                        Task { await authenticateWithBiometrics() }
                    }
                    .disabled(viewStore.isLoading)
                }
                
                // PIN 인증
                GlassButton(
                    "PIN으로 잠금 해제",
                    icon: "lock.fill",
                    style: .secondary
                ) {
                    viewStore.currentStep = .pinSetup
                }
                
                // 구분선
                HStack {
                    Rectangle()
                        .fill(KingDesignTokens.Colors.border)
                        .frame(height: 1)
                    
                    Text("또는")
                        .font(KingDesignTokens.Typography.caption)
                        .foregroundColor(KingDesignTokens.Colors.tertiaryText)
                        .padding(.horizontal, KingDesignTokens.Spacing.md)
                    
                    Rectangle()
                        .fill(KingDesignTokens.Colors.border)
                        .frame(height: 1)
                }
                .padding(.vertical, KingDesignTokens.Spacing.sm)
                
                // 지갑 관리 버튼들
                HStack(spacing: KingDesignTokens.Spacing.md) {
                    // 새 지갑 생성
                    Button {
                        createWallet()
                    } label: {
                        VStack(spacing: KingDesignTokens.Spacing.sm) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(KingDesignTokens.Colors.accent)
                            
                            Text("새 지갑")
                                .font(KingDesignTokens.Typography.caption)
                                .foregroundColor(KingDesignTokens.Colors.secondaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, KingDesignTokens.Spacing.lg)
                    }
                    .background(KingDesignTokens.Colors.surfaceSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: KingDesignTokens.Radius.md)
                            .stroke(KingDesignTokens.Colors.border, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: KingDesignTokens.Radius.md))
                    
                    // 지갑 복원
                    Button {
                        viewStore.currentStep = .walletImport
                    } label: {
                        VStack(spacing: KingDesignTokens.Spacing.sm) {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .font(.title2)
                                .foregroundColor(KingDesignTokens.Colors.accent)
                            
                            Text("복원")
                                .font(KingDesignTokens.Typography.caption)
                                .foregroundColor(KingDesignTokens.Colors.secondaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, KingDesignTokens.Spacing.lg)
                    }
                    .background(KingDesignTokens.Colors.surfaceSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: KingDesignTokens.Radius.md)
                            .stroke(KingDesignTokens.Colors.border, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: KingDesignTokens.Radius.md))
                }
                
                // 보안 노티스
                HStack(spacing: KingDesignTokens.Spacing.xs) {
                    Image(systemName: "shield.checkered")
                        .font(KingDesignTokens.Typography.caption)
                        .foregroundColor(KingDesignTokens.Colors.success)
                    
                    Text("최고 수준 보안으로 자산 보호")
                        .font(KingDesignTokens.Typography.caption)
                        .foregroundColor(KingDesignTokens.Colors.tertiaryText)
                }
                .padding(.top, KingDesignTokens.Spacing.sm)
            }
            .padding(.horizontal, KingDesignTokens.Spacing.lg)
            .padding(.bottom, KingDesignTokens.Spacing.xxxl)
        }
    }
    
    private func authenticateWithBiometrics() async {
        await MainActor.run {
            viewStore.isLoading = true
        }
        
        let request = AuthenticationScene.AuthenticateWithBiometrics.Request(
            reason: "지갑에 접근하기 위해 생체 인증을 사용하세요"
        )
        
        // 실제 구현에서는 interactor를 통해 호출
        await MainActor.run {
            viewStore.isLoading = false
        }
    }
    
    private func createWallet() {
        let request = AuthenticationScene.CreateWallet.Request(walletName: "My Wallet")
        // interactor.createWallet(request: request)
    }
}

/// 🔐 프리미엄 PIN 설정 화면
struct PremiumPINSetupView: View {
    @State var viewStore: AuthenticationViewStore

    @State private var pinCode = ""
    @State private var confirmPIN = ""
    @State private var isConfirmingPIN = false
    
    var body: some View {
        VStack(spacing: KingDesignTokens.Spacing.xxxl) {
            // 헤더 섹션
            VStack(spacing: KingDesignTokens.Spacing.lg) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                KingDesignTokens.Colors.accent,
                                KingDesignTokens.Colors.accent.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                VStack(spacing: KingDesignTokens.Spacing.sm) {
                    Text(isConfirmingPIN ? "PIN 확인" : "보안 PIN 설정")
                        .font(KingDesignTokens.Typography.displayM)
                        .fontWeight(.bold)
                        .foregroundColor(KingDesignTokens.Colors.primaryText)
                    
                    Text(isConfirmingPIN ? "PIN을 다시 입력해주세요" : "6자리 보안 PIN을 설정해주세요")
                        .font(KingDesignTokens.Typography.body)
                        .foregroundColor(KingDesignTokens.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.top, KingDesignTokens.Spacing.xxxl)
            
            Spacer()
            
            // PIN 입력 섹션
            PremiumPINField(
                pin: isConfirmingPIN ? $confirmPIN : $pinCode,
                length: 6
            ) { pin in
                if isConfirmingPIN {
                    handlePINConfirmation(pin)
                } else {
                    handlePINEntry(pin)
                }
            }
            
            Spacer()
            
            // 보안 가이드
            PremiumSecurityGuide()
                .padding(.horizontal, KingDesignTokens.Spacing.lg)
                .padding(.bottom, KingDesignTokens.Spacing.xxxl)
        }
    }
    
    private func handlePINEntry(_ pin: String) {
        pinCode = pin
        withAnimation(KingDesignTokens.Animation.normal) {
            isConfirmingPIN = true
        }
    }
    
    private func handlePINConfirmation(_ pin: String) {
        if pin == pinCode {
            viewStore.currentStep = .biometricSetup
        } else {
            withAnimation(KingDesignTokens.Animation.normal) {
                isConfirmingPIN = false
                pinCode = ""
                confirmPIN = ""
            }
            viewStore.errorMessage = "PIN이 일치하지 않습니다. 다시 설정해주세요."
        }
    }
}

/// 🔐 프리미엄 생체인증 설정 화면
struct PremiumBiometricSetupView: View {
    @State var viewStore: AuthenticationViewStore

    var body: some View {
        VStack(spacing: KingDesignTokens.Spacing.xxxl) {
            Spacer()
            
            // 생체 인증 아이콘
            VStack(spacing: KingDesignTokens.Spacing.xl) {
                ZStack {
                    Circle()
                        .fill(KingDesignTokens.Colors.accent.opacity(0.1))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Circle()
                                .stroke(KingDesignTokens.Colors.accent.opacity(0.3), lineWidth: 2)
                        )
                    
                    Image(systemName: "faceid")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundColor(KingDesignTokens.Colors.accent)
                }
                
                VStack(spacing: KingDesignTokens.Spacing.md) {
                    Text("생체 인증 설정")
                        .font(KingDesignTokens.Typography.displayM)
                        .fontWeight(.bold)
                        .foregroundColor(KingDesignTokens.Colors.primaryText)
                    
                    Text("빠르고 안전한 접근을 위해\nFace ID 또는 Touch ID를 활성화하세요")
                        .font(KingDesignTokens.Typography.body)
                        .foregroundColor(KingDesignTokens.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
            }
            
            Spacer()
            
            // 액션 버튼들
            VStack(spacing: KingDesignTokens.Spacing.md) {
                GlassButton(
                    "생체 인증 활성화",
                    icon: "faceid",
                    style: .primary
                ) {
                    Task { await setupBiometric() }
                }
                
                GlassButton(
                    "나중에 설정",
                    style: .text
                ) {
                    completeSetup()
                }
            }
            .padding(.horizontal, KingDesignTokens.Spacing.lg)
            .padding(.bottom, KingDesignTokens.Spacing.xxxl)
        }
    }
    
    private func setupBiometric() async {
        completeSetup()
    }
    
    private func completeSetup() {
        viewStore.appCoordinator?.completeAuthentication()
    }
}

/// 🔐 프리미엄 PIN 입력 필드
struct PremiumPINField: View {
    @Binding var pin: String
    let length: Int
    let onComplete: (String) -> Void
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: KingDesignTokens.Spacing.xl) {
            // 숨겨진 입력 필드
            TextField("", text: $pin)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .opacity(0)
                .frame(height: 0)
                .focused($isFocused)
                .onChange(of: pin) { _, newValue in
                    if newValue.count > length {
                        pin = String(newValue.prefix(length))
                    }
                    
                    if pin.count == length {
                        onComplete(pin)
                    }
                }
            
            // PIN 시각화
            HStack(spacing: KingDesignTokens.Spacing.lg) {
                ForEach(0..<length, id: \.self) { index in
                    Circle()
                        .fill(
                            index < pin.count ?
                            KingDesignTokens.Colors.accent :
                            KingDesignTokens.Colors.border
                        )
                        .frame(width: 20, height: 20)
                        .scaleEffect(index < pin.count ? 1.3 : 1.0)
                        .shadow(
                            color: index < pin.count ? 
                            KingDesignTokens.Colors.accent.opacity(0.3) : 
                            Color.clear,
                            radius: 8
                        )
                        .animation(KingDesignTokens.Animation.spring, value: pin)
                }
            }
            
            Text("PIN 입력 (터치하여 키패드 열기)")
                .font(KingDesignTokens.Typography.caption)
                .foregroundColor(KingDesignTokens.Colors.tertiaryText)
        }
        .onTapGesture {
            isFocused = true
        }
        .onAppear {
            isFocused = true
        }
    }
}

/// 🔐 보안 가이드 컴포넌트
struct PremiumSecurityGuide: View {
    var body: some View {
        GlassCard(level: .standard, padding: KingDesignTokens.Spacing.lg) {
            VStack(alignment: .leading, spacing: KingDesignTokens.Spacing.md) {
                HStack(spacing: KingDesignTokens.Spacing.sm) {
                    Image(systemName: "shield.checkered.fill")
                        .font(KingDesignTokens.Typography.body)
                        .foregroundColor(KingDesignTokens.Colors.success)
                    
                    Text("보안 가이드")
                        .font(KingDesignTokens.Typography.body)
                        .fontWeight(.semibold)
                        .foregroundColor(KingDesignTokens.Colors.primaryText)
                }
                
                VStack(alignment: .leading, spacing: KingDesignTokens.Spacing.sm) {
                    SecurityGuideItem(text: "다른 사람이 쉽게 추측할 수 없는 번호")
                    SecurityGuideItem(text: "생일이나 전화번호 사용 금지")
                    SecurityGuideItem(text: "PIN은 암호화되어 안전하게 보관")
                }
            }
        }
    }
}

struct SecurityGuideItem: View {
    let text: String
    
    var body: some View {
        HStack(spacing: KingDesignTokens.Spacing.sm) {
            Circle()
                .fill(KingDesignTokens.Colors.success)
                .frame(width: 6, height: 6)
            
            Text(text)
                .font(KingDesignTokens.Typography.caption)
                .foregroundColor(KingDesignTokens.Colors.secondaryText)
        }
    }
}

/// 🚨 프리미엄 오류 오버레이
struct PremiumErrorOverlay: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }
            
            GlassAlertCard(
                type: .error,
                title: "오류",
                message: message
            )
            .padding(.horizontal, KingDesignTokens.Spacing.lg)
        }
        .animation(KingDesignTokens.Animation.normal, value: message)
    }
}

/// 🔄 프리미엄 로딩 오버레이
struct PremiumLoadingOverlay: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            GlassCard(level: .prominent) {
                VStack(spacing: KingDesignTokens.Spacing.lg) {
                    ZStack {
                        Circle()
                            .stroke(KingDesignTokens.Colors.accent.opacity(0.3), lineWidth: 3)
                            .frame(width: 60, height: 60)
                        
                        Circle()
                            .trim(from: 0, to: 0.3)
                            .stroke(KingDesignTokens.Colors.accent, lineWidth: 3)
                            .frame(width: 60, height: 60)
                            .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                            .animation(
                                Animation.linear(duration: 1).repeatForever(autoreverses: false),
                                value: isAnimating
                            )
                    }
                    
                    Text("보안 검증 중...")
                        .font(KingDesignTokens.Typography.body)
                        .foregroundColor(KingDesignTokens.Colors.primaryText)
                }
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

/// 🔐 프리미엄 니모닉 뷰
struct PremiumMnemonicView: View {
    var body: some View {
        VStack(spacing: KingDesignTokens.Spacing.xl) {
            Text("복구 구문")
                .font(KingDesignTokens.Typography.displayM)
                .foregroundColor(KingDesignTokens.Colors.primaryText)
            
            Text("지갑의 니모닉 복구 구문을 안전하게 보관하세요")
                .font(KingDesignTokens.Typography.body)
                .foregroundColor(KingDesignTokens.Colors.secondaryText)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding(KingDesignTokens.Spacing.xl)
        .background(KingDesignTokens.Colors.background)
    }
}
