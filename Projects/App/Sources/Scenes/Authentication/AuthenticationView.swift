import SwiftUI
import Core
import DesignSystem
import Entity
import Factory
import SecurityKit
import UIKit

/// 🔐 Premium Authentication View - Clean Version
/// VIP 패턴을 따르는 인증 화면

// MARK: - Display Logic Protocol

/// 인증 화면의 디스플레이 로직 프로토콜
@MainActor
protocol AuthenticationDisplayLogic: AnyObject {
    func displayPINSetupResult(viewModel: AuthenticationScene.SetupPIN.ViewModel)
    func displayBiometricAuthenticationResult(viewModel: AuthenticationScene.AuthenticateWithBiometrics.ViewModel)
    func displayPINAuthenticationResult(viewModel: AuthenticationScene.AuthenticateWithPIN.ViewModel)
    func displayBiometricAvailability(viewModel: AuthenticationScene.CheckBiometricAvailability.ViewModel)
    func displayWalletCreationResult(viewModel: AuthenticationScene.CreateWallet.ViewModel)
    func displayWalletImportResult(viewModel: AuthenticationScene.ImportWallet.ViewModel)
    func displayFlow(viewModel: AuthenticationScene.Flow.ViewModel)
    func displayLoading(viewModel: AuthenticationScene.Loading.ViewModel)
}

// MARK: - View Store

@MainActor
@Observable
final class AuthenticationViewStore: AuthenticationDisplayLogic {
    // State
    weak var appCoordinator: AppCoordinator?
    var currentStep: AuthenticationScene.Step = .welcome
    var errorMessage: String?
    var showMnemonicView = false
    var isLoading = false
    var biometricAvailable = false
    var biometricIconName = "lock.fill"
    var biometricDescription = ""
    var walletAddress: String?
    var mnemonic: String?
    
    // KingToast Manager
    let toastManager = KingToastManager.shared
    
    // VIP Components
    var interactor: AuthenticationBusinessLogic?
    var presenter: AuthenticationPresentationLogic?
    var router: AuthenticationRoutingLogic?

    private var flowStack: [AuthenticationScene.Step] = []
    private var isNavigatingBack = false

    init() {
        setupVIP()
    }
    
    private func setupVIP() {
        let interactor = AuthenticationInteractor()
        let presenter = AuthenticationPresenter()
        let router = AuthenticationRouter()
        
        self.interactor = interactor
        self.presenter = presenter  
        self.router = router

        interactor.presenter = presenter
        presenter.viewController = self
    }

    @ViewBuilder
    private func methodOption(icon: String, title: String, subtitle: String, accentColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            AuthenticationGlassCard {
                HStack(alignment: .center, spacing: KingDesignTokens.Spacing.md) {
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(accentColor)
                        .frame(width: 48, height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(accentColor.opacity(0.12))
                        )

                    VStack(alignment: .leading, spacing: KingDesignTokens.Spacing.xs) {
                        Text(title)
                            .font(KingDesignTokens.Typography.body)
                            .fontWeight(.semibold)
                            .foregroundColor(KingDesignTokens.Colors.primaryText)

                        Text(subtitle)
                            .font(KingDesignTokens.Typography.caption)
                            .foregroundColor(KingDesignTokens.Colors.secondaryText)
                    }

                    Spacer()

                    Image(systemName: "arrow.forward.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(accentColor)
                }
            }
        }
        .buttonStyle(.plain)
    }

    func clearError() {
        errorMessage = nil
    }

    func attach(coordinator: AppCoordinator) {
        appCoordinator = coordinator
    }

    func requestFlow(_ action: AuthenticationScene.Flow.Action) {
        let request = AuthenticationScene.Flow.Request(action: action)
        interactor?.changeFlow(request: request)
    }

    func createWallet(named walletName: String) {
        let request = AuthenticationScene.CreateWallet.Request(walletName: walletName)
        interactor?.createWallet(request: request)
    }

    func checkBiometricAvailability() {
        let request = AuthenticationScene.CheckBiometricAvailability.Request()
        interactor?.checkBiometricAvailability(request: request)
    }

    func importWallet(request: AuthenticationScene.ImportWallet.Request) {
        interactor?.importWalletFromMnemonic(request: request)
    }

    func setupPIN(pin: String) {
        let request = AuthenticationScene.SetupPIN.Request(pin: pin)
        interactor?.setupPIN(request: request)
    }

    func authenticateWithBiometrics(reason: String) {
        let request = AuthenticationScene.AuthenticateWithBiometrics.Request(reason: reason)
        interactor?.authenticateWithBiometrics(request: request)
    }

    func completeAuthentication() {
        appCoordinator?.completeAuthentication()
    }

    func showError(_ message: String) {
        errorMessage = message
    }

    func skipBiometricSetup() {
        if !UserDefaults.standard.bool(forKey: "has_completed_biometric_setup") {
            UserDefaults.standard.set(false, forKey: "biometric_enabled")
            UserDefaults.standard.set(true, forKey: "has_completed_biometric_setup")
        }
        completeAuthentication()
    }

    // MARK: - AuthenticationDisplayLogic

    func displayPINSetupResult(viewModel: AuthenticationScene.SetupPIN.ViewModel) {
        if viewModel.success {
            // Flow change handled via presenter
        } else {
            errorMessage = viewModel.errorMessage
        }
    }

    func displayBiometricAuthenticationResult(viewModel: AuthenticationScene.AuthenticateWithBiometrics.ViewModel) {
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
        biometricIconName = viewModel.biometricIcon
        biometricDescription = viewModel.biometricTypeDescription
    }

    func displayWalletCreationResult(viewModel: AuthenticationScene.CreateWallet.ViewModel) {
        if viewModel.success {
            walletAddress = viewModel.walletAddress
            mnemonic = viewModel.mnemonic
            // Flow change handled via presenter
        } else {
            errorMessage = viewModel.errorMessage
        }
    }

    func displayWalletImportResult(viewModel: AuthenticationScene.ImportWallet.ViewModel) {
        if viewModel.success {
            walletAddress = viewModel.walletAddress
            // Flow change handled via presenter
        } else {
            errorMessage = viewModel.errorMessage
        }
    }

    func displayFlow(viewModel: AuthenticationScene.Flow.ViewModel) {
        guard currentStep != viewModel.step else { return }

        if isNavigatingBack {
            isNavigatingBack = false
        } else {
            flowStack.append(currentStep)
        }

        currentStep = viewModel.step
    }

    func displayLoading(viewModel: AuthenticationScene.Loading.ViewModel) {
        isLoading = viewModel.isLoading
    }

    var canGoBack: Bool {
        !flowStack.isEmpty
    }

    func goBack() {
        guard canGoBack else { return }
        isNavigatingBack = true
        let previousStep = flowStack.removeLast()
        interactor?.changeFlow(request: AuthenticationScene.Flow.Request(action: flowAction(for: previousStep)))
    }

    private func flowAction(for step: AuthenticationScene.Step) -> AuthenticationScene.Flow.Action {
        switch step {
        case .welcome:
            return .showWelcome
        case .methodSelection:
            return .showMethodSelection
        case .walletCreation:
            return .showWalletCreation
        case .walletImport:
            return .showWalletImport
        case .pinSetup:
            return .showPINSetup
        case .biometricSetup:
            return .showBiometricSetup
        case .congratulations:
            return .showCongratulations
        }
    }
}

// MARK: - Main View

struct AuthenticationView: View {
    @EnvironmentObject private var appCoordinator: AppCoordinator
    @State private var viewStore = AuthenticationViewStore()

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()

                // Content
                stepView()

                // Loading Overlay
                if viewStore.isLoading {
                    LoadingOverlay()
                }
                
                // Error Overlay
                if let errorMessage = viewStore.errorMessage {
                    ErrorOverlay(message: errorMessage) {
                        viewStore.clearError()
                    }
                }
                
                // KingToast Overlay
                KingToastContainer(position: .top)
            }
            .animation(.easeInOut(duration: 0.3), value: viewStore.currentStep)
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top) {
                AuthenticationNavigationBar(
                    metadata: metadata(for: viewStore.currentStep),
                    progress: progress(for: viewStore.currentStep),
                    canGoBack: viewStore.canGoBack,
                    onBack: viewStore.goBack
                )
            }
        }
        .onAppear {
            viewStore.attach(coordinator: appCoordinator)
            viewStore.requestFlow(.showWelcome)
            viewStore.checkBiometricAvailability()
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                KingDesignTokens.Colors.background,
                KingDesignTokens.Colors.surface.opacity(0.4)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private let orderedSteps: [AuthenticationScene.Step] = [
        .welcome,
        .methodSelection,
        .walletCreation,
        .walletImport,
        .pinSetup,
        .biometricSetup,
        .congratulations
    ]

    private func metadata(for step: AuthenticationScene.Step) -> StepMetadata {
        switch step {
        case .welcome:
            return StepMetadata(
                title: "Kingthereum",
                subtitle: "신뢰할 수 있는 프리미엄 이더리움 지갑",
                iconSystemName: "crown.fill"
            )
        case .methodSelection:
            return StepMetadata(
                title: "지갑 시작하기",
                subtitle: "새 지갑을 만들거나 기존 지갑을 불러오세요",
                iconSystemName: "sparkles"
            )
        case .walletCreation:
            return StepMetadata(
                title: "지갑 생성 완료",
                subtitle: "복구 구문을 안전하게 보관하세요",
                iconSystemName: "checkmark.seal.fill"
            )
        case .walletImport:
            return StepMetadata(
                title: "지갑 복구",
                subtitle: "12개 단어 복구 구문을 입력하세요",
                iconSystemName: "square.and.arrow.down.on.square.fill"
            )
        case .pinSetup:
            return StepMetadata(
                title: "PIN 보안",
                subtitle: "6자리 PIN으로 지갑을 보호합니다",
                iconSystemName: "lock.circle.fill"
            )
        case .biometricSetup:
            return StepMetadata(
                title: "생체 인증",
                subtitle: "Face ID 또는 Touch ID로 빠르게 잠금 해제",
                iconSystemName: "faceid"
            )
        case .congratulations:
            return StepMetadata(
                title: "모든 준비 완료",
                subtitle: "이제 Kingthereum을 사용할 준비가 됐어요",
                iconSystemName: "party.popper.fill"
            )
        }
    }

    private func progress(for step: AuthenticationScene.Step) -> Double {
        guard let index = orderedSteps.firstIndex(of: step), orderedSteps.count > 1 else {
            return 0
        }
        return Double(index) / Double(orderedSteps.count - 1)
    }

    private struct StepMetadata {
        let title: String
        let subtitle: String?
        let iconSystemName: String?
    }

    // MARK: - Child Views

    @ViewBuilder
    private func stepView() -> some View {
        switch viewStore.currentStep {
        case .welcome:
            PremiumWelcomeView(viewStore: viewStore)
        case .methodSelection:
            MethodSelectionView()
        case .walletCreation:
            WalletCreationView()
        case .walletImport:
            MnemonicImportView(viewStore: viewStore)
        case .pinSetup:
            PremiumPINSetupView(viewStore: viewStore)
        case .biometricSetup:
            PremiumBiometricSetupView(viewStore: viewStore)
        case .congratulations:
            CongratulationsView()
        }
    }

    @ViewBuilder
    private func MethodSelectionView() -> some View {
        ScrollView {
            VStack(spacing: KingDesignTokens.Spacing.xl) {
                AuthenticationGlassCard {
                    VStack(alignment: .leading, spacing: KingDesignTokens.Spacing.sm) {
                        Text("어떤 방법으로 시작할까요?")
                            .font(KingDesignTokens.Typography.displayS)
                            .foregroundColor(KingDesignTokens.Colors.primaryText)

                        Text("지갑 생성은 새로운 키쌍을 만들고, 지갑 복구는 기존 복구 구문을 불러옵니다.")
                            .font(KingDesignTokens.Typography.caption)
                            .foregroundColor(KingDesignTokens.Colors.secondaryText)
                    }
                }

                VStack(spacing: KingDesignTokens.Spacing.md) {
                    methodOption(
                        icon: "wand.and.stars.inverse",
                        title: "새 지갑 생성",
                        subtitle: "니모닉과 프라이빗 키를 자동 생성",
                        accentColor: KingDesignTokens.Colors.accent,
                        action: createWallet
                    )

                    methodOption(
                        icon: "arrow.clockwise.square",
                        title: "지갑 복구",
                        subtitle: "기존 복구 구문 입력으로 즉시 접근",
                        accentColor: KingDesignTokens.Colors.primaryText,
                        action: { viewStore.requestFlow(.showWalletImport) }
                    )
                }
            }
            .padding(.horizontal, KingDesignTokens.Spacing.lg)
            .padding(.top, KingDesignTokens.Spacing.xl)
            .padding(.bottom, 140)
        }
        .safeAreaInset(edge: .bottom) {
            AuthenticationCTAContainer {
                Button(action: viewStore.goBack) {
                    Text("이전 단계")
                        .font(KingDesignTokens.Typography.body)
                        .foregroundColor(viewStore.canGoBack ? KingDesignTokens.Colors.secondaryText : KingDesignTokens.Colors.secondaryText.opacity(0.5))
                        .frame(maxWidth: .infinity)
                }
                .disabled(!viewStore.canGoBack)
            }
        }
    }

    @ViewBuilder
    private func WalletCreationView() -> some View {
        ScrollView {
            VStack(spacing: KingDesignTokens.Spacing.xl) {
                VStack(spacing: KingDesignTokens.Spacing.md) {
                    Text("지갑 생성 완료")
                        .font(KingDesignTokens.Typography.displayM)
                        .fontWeight(.bold)
                        .foregroundColor(KingDesignTokens.Colors.primaryText)

                    Text("지갑이 성공적으로 생성되었습니다")
                        .font(KingDesignTokens.Typography.body)
                        .foregroundColor(KingDesignTokens.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, KingDesignTokens.Spacing.xxxl)

                if let address = viewStore.walletAddress {
                    VStack(spacing: KingDesignTokens.Spacing.sm) {
                        Text("지갑 주소")
                            .font(KingDesignTokens.Typography.body)
                            .fontWeight(.semibold)
                            .foregroundColor(KingDesignTokens.Colors.primaryText)

                        Text(address)
                            .font(KingDesignTokens.Typography.caption)
                            .foregroundColor(KingDesignTokens.Colors.secondaryText)
                            .padding()
                            .background(KingDesignTokens.Colors.surfaceSecondary)
                            .cornerRadius(KingDesignTokens.Radius.md)
                            .textSelection(.enabled)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let mnemonic = viewStore.mnemonic {
                    VStack(spacing: KingDesignTokens.Spacing.md) {
                        Text("복구 구문")
                            .font(KingDesignTokens.Typography.body)
                            .fontWeight(.semibold)
                            .foregroundColor(KingDesignTokens.Colors.error)

                        Text("이 구문을 안전한 곳에 보관하세요")
                            .font(KingDesignTokens.Typography.caption)
                            .foregroundColor(KingDesignTokens.Colors.secondaryText)

                        VStack(spacing: KingDesignTokens.Spacing.sm) {
                            Text(mnemonic)
                                .font(KingDesignTokens.Typography.caption)
                                .foregroundColor(KingDesignTokens.Colors.primaryText)
                                .padding()
                                .background(KingDesignTokens.Colors.surfaceSecondary)
                                .cornerRadius(KingDesignTokens.Radius.md)
                                .textSelection(.enabled)

                            Button {
                                copyMnemonicToClipboard(mnemonic)
                            } label: {
                                HStack(spacing: KingDesignTokens.Spacing.sm) {
                                    Image(systemName: "doc.on.clipboard")
                                        .font(.system(size: 14, weight: .medium))
                                    Text("복구 구문 복사")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(KingDesignTokens.Colors.accent)
                                .padding(.vertical, KingDesignTokens.Spacing.xs)
                                .padding(.horizontal, KingDesignTokens.Spacing.md)
                                .background(KingDesignTokens.Colors.accent.opacity(0.1))
                                .cornerRadius(KingDesignTokens.Radius.sm)
                            }
                            .accessibilityLabel("복구 구문 복사")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, KingDesignTokens.Spacing.lg)
            .padding(.bottom, 120)
        }
        .safeAreaInset(edge: .bottom) {
            AuthenticationCTAContainer {
                Button {
                    viewStore.requestFlow(.showPINSetup)
                } label: {
                    Text("복구 구문 저장 완료")
                        .font(KingDesignTokens.Typography.body)
                        .fontWeight(.semibold)
                        .foregroundColor(KingDesignTokens.Colors.systemWhite)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(KingDesignTokens.Colors.accent)
                        .cornerRadius(KingDesignTokens.Radius.lg)
                }
            }
        }
    }
    
    @ViewBuilder
    private func CongratulationsView() -> some View {
        ScrollView {
            VStack(spacing: KingDesignTokens.Spacing.xl) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(KingDesignTokens.Colors.success)
                    .padding(.top, KingDesignTokens.Spacing.xxxl)

                VStack(spacing: KingDesignTokens.Spacing.md) {
                    Text("지갑 설정 완료!")
                        .font(KingDesignTokens.Typography.displayL)
                        .fontWeight(.bold)
                        .foregroundColor(KingDesignTokens.Colors.primaryText)

                    Text("이제 Kingthereum 지갑을 사용할 수 있습니다")
                        .font(KingDesignTokens.Typography.body)
                        .foregroundColor(KingDesignTokens.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, KingDesignTokens.Spacing.lg)

                Spacer(minLength: KingDesignTokens.Spacing.xxxl)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 120)
        }
        .safeAreaInset(edge: .bottom) {
            AuthenticationCTAContainer {
                Button(action: completeSetup) {
                    Text("시작하기")
                        .font(KingDesignTokens.Typography.body)
                        .fontWeight(.semibold)
                        .foregroundColor(KingDesignTokens.Colors.systemWhite)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(KingDesignTokens.Colors.accent)
                        .cornerRadius(KingDesignTokens.Radius.lg)
                }
                .accessibilityIdentifier("authentication.finish")
            }
        }
    }
    
    @ViewBuilder
    private func LoadingOverlay() -> some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: KingDesignTokens.Spacing.lg) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: KingDesignTokens.Colors.accent))
                    .scaleEffect(1.5)
                
                Text("처리 중...")
                    .font(KingDesignTokens.Typography.body)
                    .foregroundColor(KingDesignTokens.Colors.systemWhite)
            }
            .padding()
            .background(KingDesignTokens.Colors.systemBlack.opacity(0.8))
            .cornerRadius(KingDesignTokens.Radius.lg)
        }
    }
    
    @ViewBuilder
    private func ErrorOverlay(message: String, onDismiss: @escaping () -> Void) -> some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: KingDesignTokens.Spacing.lg) {
                Text("오류")
                    .font(KingDesignTokens.Typography.body)
                    .fontWeight(.bold)
                    .foregroundColor(KingDesignTokens.Colors.error)

                Text(message)
                    .font(KingDesignTokens.Typography.body)
                    .foregroundColor(KingDesignTokens.Colors.primaryText)
                    .multilineTextAlignment(.center)

                Button("확인") {
                    onDismiss()
                }
                .font(KingDesignTokens.Typography.body)
                .fontWeight(.semibold)
                .foregroundColor(KingDesignTokens.Colors.systemWhite)
                .padding(.horizontal, KingDesignTokens.Spacing.xl)
                .padding(.vertical, KingDesignTokens.Spacing.md)
                .background(KingDesignTokens.Colors.accent)
                .cornerRadius(KingDesignTokens.Radius.md)
            }
            .padding()
            .background(KingDesignTokens.Colors.background)
            .cornerRadius(KingDesignTokens.Radius.lg)
            .padding(.horizontal, KingDesignTokens.Spacing.lg)
        }
    }

    // MARK: - Actions
    
    private func createWallet() {
        viewStore.createWallet(named: "My Wallet")
    }

    private func completeSetup() {
        viewStore.completeAuthentication()
    }
    
    private func copyMnemonicToClipboard(_ mnemonic: String) {
        // 클립보드에 복사
        UIPasteboard.general.string = mnemonic
        
        // 햅틱 피드백
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // KingToast로 복사 완료 메시지 표시
        KingToastManager.shared.show(
            KingToastItem(
                type: .success,
                title: "복사 완료",
                message: "복구 구문이 클립보드에 복사되었습니다",
                duration: 3.0
            )
        )
        
        // 보안: 30초 후 클립보드 자동 삭제
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            if UIPasteboard.general.string == mnemonic {
                UIPasteboard.general.string = ""
            }
        }
    }
}

private struct AuthenticationNavigationBar: View {
    let metadata: AuthenticationView.StepMetadata
    let progress: Double
    let canGoBack: Bool
    let onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: KingDesignTokens.Spacing.sm) {
            HStack(spacing: KingDesignTokens.Spacing.md) {
                if canGoBack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(KingDesignTokens.Colors.primaryText)
                            .frame(width: 38, height: 38)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(KingDesignTokens.Colors.surface.opacity(0.6))
                            )
                    }
                    .buttonStyle(.plain)
                }

                Spacer(minLength: 0)

                if let icon = metadata.iconSystemName {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(KingDesignTokens.Colors.accent)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(KingDesignTokens.Colors.surface.opacity(0.4))
                        )
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(metadata.title)
                    .font(KingDesignTokens.Typography.displayS)
                    .foregroundColor(KingDesignTokens.Colors.primaryText)

                if let subtitle = metadata.subtitle {
                    Text(subtitle)
                        .font(KingDesignTokens.Typography.caption)
                        .foregroundColor(KingDesignTokens.Colors.secondaryText)
                }
            }

            if progress > 0 {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .tint(KingDesignTokens.Colors.accent)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, KingDesignTokens.Spacing.lg)
        .padding(.vertical, KingDesignTokens.Spacing.md)
        .background(
            LinearGradient(
                colors: [
                    KingDesignTokens.Colors.surface.opacity(0.85),
                    KingDesignTokens.Colors.surface.opacity(0.55)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .blur(radius: 0)
            .overlay(
                Divider()
                    .background(KingDesignTokens.Colors.surfaceSecondary.opacity(0.4)),
                alignment: .bottom
            )
        )
    }
}
