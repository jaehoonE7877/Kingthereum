import SwiftUI
import Core
import DesignSystem
import Entity
import Factory
import SecurityKit

/// 극한 미니멀리즘 AuthenticationView 2024
/// 670줄 → 200줄 이내로 압축, 핵심 기능만 유지

// MARK: - ViewStore는 기존 것 그대로 사용 (비즈니스 로직 유지)

/// Kingthereum 지갑의 극한 미니멀 인증 화면
/// Clean Swift VIP 패턴 + 미니멀리즘 + 프리미엄 피나테크 + 글래스모피즘
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
        ZStack {
            // 극도로 미니멀한 배경
            KingGradients.minimalistBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // 중앙 메인 카드 - 하나로 통합
                mainAuthenticationCard
                
                Spacer()
            }
            .padding(.horizontal, 24)
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
                    .font(KingTypography.bodyMedium)
                    .foregroundColor(KingColors.textSecondary)
            }
        }
        .onAppear {
            presenter.viewController = viewStore
            viewStore.appCoordinator = appCoordinator
            checkBiometricAvailability()
        }
        .sheet(isPresented: $viewStore.showMnemonicView) {
            minimalistMnemonicView
        }
    }
    
    // MARK: - Main Components
    
    @ViewBuilder
    private var mainAuthenticationCard: some View {
        VStack(spacing: 32) {
            
            // 미니멀 브랜드 섹션
            VStack(spacing: 12) {
                // 단순한 아이콘 (복잡한 홀로그래픽 링 제거)
                ZStack {
                    Circle()
                        .frame(width: 80, height: 80)
                        .goldAccentGlass(level: .subtle, cornerRadius: 40, intensity: 0.6)
                    
                    Image(systemName: "crown.fill")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(KingColors.exclusiveGold)
                }
                
                // 미니멀 타이틀
                VStack(spacing: 4) {
                    Text("Kingthereum")
                        .font(KingTypography.displayLarge)
                        .foregroundColor(KingColors.textPrimary)
                    
                    Text("프리미엄 이더리움 지갑")
                        .font(KingTypography.bodyMedium)
                        .foregroundColor(KingColors.textSecondary)
                }
            }
            
            // 인증 버튼들 - 단순화
            VStack(spacing: 16) {
                
                // 생체 인증 (있을 경우에만)
                if viewStore.biometricAvailable {
                    Button {
                        authenticateWithBiometrics()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: viewStore.isLoading ? "hourglass" : "faceid")
                                .font(.title3)
                                .foregroundColor(KingColors.trustPurple)
                            
                            Text("생체 인증으로 시작")
                                .font(KingTypography.labelLarge)
                                .foregroundColor(KingColors.textPrimary)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                    .disabled(viewStore.isLoading)
                    .premiumFinTechGlass(level: .standard)
                    .scaleEffect(viewStore.isLoading ? 0.98 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: viewStore.isLoading)
                }
                
                // PIN 인증
                Button {
                    authenticateWithPIN()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "key.fill")
                            .font(.title3)
                            .foregroundColor(KingColors.trustPurple)
                        
                        Text("PIN으로 잠금 해제")
                            .font(KingTypography.labelLarge)
                            .foregroundColor(KingColors.textPrimary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .premiumFinTechGlass(level: .standard)
                
                // 구분선 - 극도로 서브틀
                Rectangle()
                    .fill(KingColors.separator)
                    .frame(height: 0.5)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                
                // 추가 옵션들 - 단순화
                HStack(spacing: 12) {
                    // 새 지갑
                    Button {
                        createWallet()
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "plus.circle")
                                .font(.title3)
                                .foregroundColor(KingColors.exclusiveGold)
                            
                            Text("새 지갑")
                                .font(KingTypography.captionMedium)
                                .foregroundColor(KingColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .ultraMinimalGlass(level: .subtle)
                    
                    // 지갑 복원
                    Button {
                        print("지갑 복원 요청") // 향후 구현
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise.circle")
                                .font(.title3)
                                .foregroundColor(KingColors.info)
                            
                            Text("복원")
                                .font(KingTypography.captionMedium)
                                .foregroundColor(KingColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .ultraMinimalGlass(level: .subtle)
                }
            }
        }
        .padding(32)
        .trustGlassCard(level: .prominent, cornerRadius: 24)
    }
    
    @ViewBuilder
    private var minimalistMnemonicView: some View {
        VStack(spacing: 24) {
            Text("복구 구문")
                .font(KingTypography.headlineLarge)
                .foregroundColor(KingColors.textPrimary)
            
            Text("지갑의 니모닉 복구 구문을 안전하게 보관하세요")
                .font(KingTypography.bodyMedium)
                .foregroundColor(KingColors.textSecondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding(32)
        .background(KingGradients.minimalistBackground)
    }
    
    // MARK: - Action Methods (기존과 동일)
    
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
}

// MARK: - Preview

#Preview("AuthenticationView") {
    AuthenticationView()
        .environmentObject(AppCoordinator())
}

#Preview("AuthenticationView - Dark Mode") {
    AuthenticationView()
        .environmentObject(AppCoordinator())
        .preferredColorScheme(.dark)
}