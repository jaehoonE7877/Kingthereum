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
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.xxl) {
                // Header Section
                headerSection
                
                // Content Section
                contentSection
            }
            .padding(.horizontal, DesignTokens.Spacing.xl)
            .padding(.vertical, DesignTokens.Spacing.xxl)
        }
        .background(LinearGradient.enhancedBackgroundGradient.ignoresSafeArea())
        .alert("오류", isPresented: Binding<Bool>(
            get: { viewStore.errorMessage != nil },
            set: { _ in viewStore.clearError() }
        )) {
            Button("확인", role: .cancel) {
                viewStore.clearError()
            }
        } message: {
            if let errorMessage = viewStore.errorMessage {
                Text(errorMessage)
            }
        }
        .onAppear {
            // Connect presenter to viewStore after view initialization
            presenter.viewController = viewStore
            viewStore.appCoordinator = appCoordinator
            checkBiometricAvailability()
        }
        .sheet(isPresented: $viewStore.showMnemonicView) {
            // MnemonicView 구현 필요
            Text("니모닉 뷰")
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
    
    // MARK: - UI Components
    
    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            // App Icon with Glass Effect
            ZStack {
                Circle()
                    .fill(.ultraThickMaterial)
                    .overlay(
                        Circle()
                            .stroke(Color.glassBorderPrimary, lineWidth: 2)
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: .glassShadowMedium, radius: 15, x: 0, y: 8)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.kingGold, .systemYellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            // Title and Subtitle
            VStack(spacing: DesignTokens.Spacing.sm) {
                Text("Kingthereum")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(LinearGradient.primaryGradient)
                
                Text("안전하고 쉬운 이더리움 지갑")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, DesignTokens.Spacing.xl)
    }
    
    @ViewBuilder
    private var contentSection: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            // 생체인증 버튼
            if viewStore.biometricAvailable {
                GlassButton(
                    icon: "faceid",
                    title: "생체 인증으로 시작",
                    style: .success,
                    isEnabled: !viewStore.isLoading,
                    isLoading: viewStore.isLoading
                ) {
                    authenticateWithBiometrics()
                }
            }
            
            // PIN 인증 섹션
            VStack(spacing: DesignTokens.Spacing.lg) {
                // PIN Input Card (간소화)
                HStack(spacing: 12) {
                    Image(systemName: "key.fill")
                        .font(.title3)
                        .foregroundStyle(LinearGradient.primaryGradient)
                        .frame(width: 24)
                    
                    Text("PIN을 입력하세요")
                        .foregroundColor(.secondary)
                }
                .padding(DesignTokens.Spacing.lg)
                .glassCard(style: .subtle)
                
                // PIN Auth Button
                GlassButton(
                    icon: "lock.open.fill",
                    title: "PIN으로 잠금 해제",
                    style: .primary,
                    isEnabled: !viewStore.isLoading,
                    isLoading: viewStore.isLoading
                ) {
                    authenticateWithPIN()
                }
            }
        }
    }
}