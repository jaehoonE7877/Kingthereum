import SwiftUI
import Core
import DesignSystem
import Entity
import Factory
import SecurityKit

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
}

// MARK: - View Store

@MainActor
@Observable
final class AuthenticationViewStore: AuthenticationDisplayLogic {
    // State
    weak var appCoordinator: AppCoordinator?
    var currentStep: AuthenticationStep = .welcome
    var errorMessage: String?
    var showMnemonicView = false
    var isLoading = false
    var biometricAvailable = false
    var walletAddress: String?
    var mnemonic: String?
    
    // VIP Components
    var interactor: AuthenticationBusinessLogic?
    var presenter: AuthenticationPresentationLogic?
    var router: AuthenticationRoutingLogic?
    
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
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - AuthenticationDisplayLogic
    
    func displayPINSetupResult(viewModel: AuthenticationScene.SetupPIN.ViewModel) {
        isLoading = false
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
        isLoading = false
        if viewModel.success {
            walletAddress = viewModel.walletAddress
            mnemonic = viewModel.mnemonic
            currentStep = .walletCreation
        } else {
            errorMessage = viewModel.errorMessage
        }
    }
    
    func displayWalletImportResult(viewModel: AuthenticationScene.ImportWallet.ViewModel) {
        isLoading = false
        if viewModel.success {
            walletAddress = viewModel.walletAddress
            currentStep = .pinSetup
        } else {
            errorMessage = viewModel.errorMessage
        }
    }
}

// MARK: - Authentication Steps

enum AuthenticationStep: String, CaseIterable {
    case welcome = "welcome"
    case methodSelection = "method_selection"
    case pinSetup = "pin_setup"
    case biometricSetup = "biometric_setup" 
    case walletCreation = "wallet_creation"
    case walletImport = "wallet_import"
    case congratulations = "congratulations"
}

// MARK: - Main View

struct AuthenticationView: View {
    @State private var viewStore = AuthenticationViewStore()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                KingDesignTokens.Colors.background
                    .ignoresSafeArea()
                
                // Content
                Group {
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
            }
            .animation(.easeInOut(duration: 0.3), value: viewStore.currentStep)
        }
        .onAppear {
            checkBiometricAvailability()
        }
    }
    
    // MARK: - Child Views
    
    @ViewBuilder
    private func MethodSelectionView() -> some View {
        VStack(spacing: KingDesignTokens.Spacing.xxxl) {
            // Header
            VStack(spacing: KingDesignTokens.Spacing.lg) {
                Text("지갑 설정")
                    .font(KingDesignTokens.Typography.displayL)
                    .fontWeight(.bold)
                    .foregroundColor(KingDesignTokens.Colors.primaryText)
                
                Text("새 지갑을 생성하거나 기존 지갑을 복구하세요")
                    .font(KingDesignTokens.Typography.body)
                    .foregroundColor(KingDesignTokens.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, KingDesignTokens.Spacing.xxxl)
            
            Spacer()
            
            // Options
            VStack(spacing: KingDesignTokens.Spacing.lg) {
                // Create Wallet Button
                Button {
                    createWallet()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                        Text("새 지갑 생성")
                            .font(KingDesignTokens.Typography.body)
                            .fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(KingDesignTokens.Colors.accent)
                    .cornerRadius(KingDesignTokens.Radius.lg)
                }
                .disabled(viewStore.isLoading)
                
                // Import Wallet Button  
                Button {
                    viewStore.currentStep = .walletImport
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .font(.title2)
                        Text("지갑 복구")
                            .font(KingDesignTokens.Typography.body)
                            .fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .foregroundColor(KingDesignTokens.Colors.accent)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(KingDesignTokens.Colors.accent.opacity(0.1))
                    .cornerRadius(KingDesignTokens.Radius.lg)
                }
                .disabled(viewStore.isLoading)
            }
            .padding(.horizontal, KingDesignTokens.Spacing.lg)
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private func WalletCreationView() -> some View {
        VStack(spacing: KingDesignTokens.Spacing.xl) {
            // Header
            VStack(spacing: KingDesignTokens.Spacing.md) {
                Text("지갑 생성 완료")
                    .font(KingDesignTokens.Typography.displayM)
                    .fontWeight(.bold)
                    .foregroundColor(KingDesignTokens.Colors.primaryText)
                
                Text("지갑이 성공적으로 생성되었습니다")
                    .font(KingDesignTokens.Typography.body)
                    .foregroundColor(KingDesignTokens.Colors.secondaryText)
            }
            .padding(.top, KingDesignTokens.Spacing.xxxl)
            
            Spacer()
            
            // Wallet Info
            if let address = viewStore.walletAddress {
                VStack(spacing: KingDesignTokens.Spacing.lg) {
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
                    }
                }
            }
            
            if let mnemonic = viewStore.mnemonic {
                VStack(spacing: KingDesignTokens.Spacing.lg) {
                    VStack(spacing: KingDesignTokens.Spacing.sm) {
                        Text("복구 구문")
                            .font(KingDesignTokens.Typography.body)
                            .fontWeight(.semibold)
                            .foregroundColor(KingDesignTokens.Colors.error)
                        
                        Text("이 구문을 안전한 곳에 보관하세요")
                            .font(KingDesignTokens.Typography.caption)
                            .foregroundColor(KingDesignTokens.Colors.secondaryText)
                        
                        // 복구 구문 표시
                        VStack(spacing: KingDesignTokens.Spacing.sm) {
                            Text(mnemonic)
                                .font(KingDesignTokens.Typography.caption)
                                .foregroundColor(KingDesignTokens.Colors.primaryText)
                                .padding()
                                .background(KingDesignTokens.Colors.surfaceSecondary)
                                .cornerRadius(KingDesignTokens.Radius.md)
                                .textSelection(.enabled) // iOS 15+ 텍스트 선택 가능
                            
                            // 복사 버튼
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
                        }
                    }
                    
                    Button {
                        viewStore.currentStep = .pinSetup
                    } label: {
                        Text("복구 구문 저장 완료")
                            .font(KingDesignTokens.Typography.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(KingDesignTokens.Colors.accent)
                            .cornerRadius(KingDesignTokens.Radius.lg)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, KingDesignTokens.Spacing.lg)
    }
    
    @ViewBuilder
    private func CongratulationsView() -> some View {
        VStack(spacing: KingDesignTokens.Spacing.xxxl) {
            Spacer()
            
            VStack(spacing: KingDesignTokens.Spacing.xl) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(KingDesignTokens.Colors.success)
                
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
            }
            
            Spacer()
            
            Button {
                completeSetup()
            } label: {
                Text("시작하기")
                    .font(KingDesignTokens.Typography.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(KingDesignTokens.Colors.accent)
                    .cornerRadius(KingDesignTokens.Radius.lg)
            }
            .padding(.horizontal, KingDesignTokens.Spacing.lg)
            .padding(.bottom, KingDesignTokens.Spacing.xxxl)
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
                    .foregroundColor(.white)
            }
            .padding()
            .background(Color.black.opacity(0.8))
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
                .foregroundColor(.white)
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
        viewStore.isLoading = true
        let request = AuthenticationScene.CreateWallet.Request(walletName: "My Wallet")
        viewStore.interactor?.createWallet(request: request)
    }
    
    private func checkBiometricAvailability() {
        let request = AuthenticationScene.CheckBiometricAvailability.Request()
        viewStore.interactor?.checkBiometricAvailability(request: request)
    }
    
    private func completeSetup() {
        viewStore.appCoordinator?.completeAuthentication()
    }
    
    private func copyMnemonicToClipboard(_ mnemonic: String) {
        // 클립보드에 복사
        UIPasteboard.general.string = mnemonic
        
        // 햅틱 피드백
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // TODO: 토스트 메시지 표시 (옵션)
        // showToast("복구 구문이 클립보드에 복사되었습니다")
        
        // 보안: 30초 후 클립보드 자동 삭제
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            if UIPasteboard.general.string == mnemonic {
                UIPasteboard.general.string = ""
            }
        }
    }
}