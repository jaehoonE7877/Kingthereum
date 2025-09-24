import SwiftUI
import Core
import DesignSystem
import Entity

// MARK: - Display Logic

@MainActor
protocol SplashDisplayLogic: AnyObject {
    func displayInitialAnimations(viewModel: SplashScene.Appear.ViewModel)
    func displayCompletion(viewModel: SplashScene.Complete.ViewModel)
}

// MARK: - SplashViewStore (성능 최적화된 상태 관리)
@MainActor
@Observable
final class SplashViewStore: SplashDisplayLogic {
    // 시각적 애니메이션 상태 그룹
    struct VisualState {
        var logoScale: CGFloat = 0.95
        var logoOpacity: Double = 0.0
        var brandOpacity: Double = 0.0
        var taglineOpacity: Double = 0.0
        var subtleGlow: Double = 0.0
        var overallOpacity: Double = 1.0
    }
    
    // 프로그레스 상태 그룹
    struct ProgressState {
        var progressOpacity: Double = 0.0
        var loadingProgress: Double = 0.0
        var isCompleting: Bool = false
    }
    
    // 애니메이션 제어 상태
    struct AnimationState {
        var breathingEffect: Bool = false
    }
    
    var visualState = VisualState()
    var progressState = ProgressState()
    var animationState = AnimationState()
    private(set) var interactor: SplashBusinessLogic?

    init(interactor: SplashBusinessLogic? = nil) {
        setupVIP(interactor: interactor)
    }

    private func setupVIP(interactor: SplashBusinessLogic?) {
        let interactor = interactor ?? SplashInteractor()
        let presenter = SplashPresenter()

        self.interactor = interactor
        interactor.presenter = presenter
        presenter.viewController = self
    }

    func onAppear(reduceMotion: Bool) {
        let request = SplashScene.Appear.Request(reduceMotion: reduceMotion)
        interactor?.handleAppear(request: request)
    }

    func completeSplash() {
        interactor?.completeSplash(request: SplashScene.Complete.Request())
    }

    // 🚀 성능 최적화: 상태 업데이트 액션들
    private func startFullAnimations() {
        visualState.logoScale = 1.0
        visualState.logoOpacity = 1.0
        visualState.brandOpacity = 1.0
        visualState.taglineOpacity = 1.0
        visualState.subtleGlow = 1.0
        progressState.progressOpacity = 1.0
        progressState.loadingProgress = 1.0
        animationState.breathingEffect = true
    }

    private func startReducedAnimations() {
        visualState.logoScale = 1.0
        visualState.logoOpacity = 1.0
        visualState.brandOpacity = 1.0
        visualState.taglineOpacity = 1.0
        progressState.progressOpacity = 1.0
        progressState.loadingProgress = 1.0
        visualState.subtleGlow = 1.0
    }

    private func completeAnimation() {
        progressState.isCompleting = true
        visualState.overallOpacity = 0.0
    }

    // MARK: - Display Logic

    func displayInitialAnimations(viewModel: SplashScene.Appear.ViewModel) {
        switch viewModel.animationStyle {
        case .full:
            startFullAnimations()
        case .reduced:
            startReducedAnimations()
        }
    }

    func displayCompletion(viewModel: SplashScene.Complete.ViewModel) {
        guard viewModel.shouldFadeOut else { return }
        completeAnimation()
    }
}

/// Revolut, N26 수준의 프리미엄 핀테크 브랜딩
struct SplashView: View {
    // 🚀 성능 최적화: @State 10개 → ViewStore 1개로 통합 (90% 감소)
    @State private var viewStore = SplashViewStore()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        ZStack {
            // 프리미엄 럭셔리 배경
            luxuryBackground
            
            // 메인 브랜딩 컨테이너
            VStack(spacing: 0) {
                Spacer()
                
                // 프리미엄 로고 섹션
                premiumLogoSection
                
                Spacer()
                
                // 럭셔리 로딩 인디케이터
                luxuryLoadingSection.padding(.bottom, 80)
            }
        }
        .opacity(viewStore.visualState.overallOpacity)
        .onAppear {
            viewStore.onAppear(reduceMotion: reduceMotion)
        }
    }
    
    // MARK: - 프리미엄 컴포넌트들
    
    @ViewBuilder
    private var luxuryBackground: some View {
        ZStack {
            // 프리미엄 미니멀 그라데이션
            LinearGradient(
                colors: [
                    KingDesignTokens.Colors.background,
                    KingDesignTokens.Colors.surface.opacity(0.15),
                    KingDesignTokens.Colors.accent.opacity(0.05),
                    KingDesignTokens.Colors.surface
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // 서브틀한 앰비언트 글로우 (호흡 효과)
            if viewStore.animationState.breathingEffect {
                RadialGradient(
                    colors: [
                        KingDesignTokens.Colors.accent.opacity(viewStore.visualState.subtleGlow * 0.02),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 400
                )
                .ignoresSafeArea()
                .animation(
                    .easeInOut(duration: 4.0)
                    .repeatForever(autoreverses: true),
                    value: viewStore.visualState.subtleGlow
                )
            }
        }
    }
    
    @ViewBuilder
    private var premiumLogoSection: some View {
        VStack(spacing: 28) {
            // 프리미엄 로고 아이콘 - 미묘한 호흡 효과
            PremiumAppIcon()
                .frame(width: 120, height: 120)
                .scaleEffect(viewStore.visualState.logoScale + (viewStore.animationState.breathingEffect ? 0.02 : 0.0))
                .opacity(viewStore.visualState.logoOpacity)
                .shadow(
                    color: KingDesignTokens.Colors.accent.opacity(viewStore.visualState.subtleGlow * 0.3),
                    radius: viewStore.visualState.subtleGlow * 15,
                    x: 0,
                    y: viewStore.visualState.subtleGlow * 8
                )
                .animation(
                    Animation.easeInOut(duration: 3.0)
                    .repeatForever(autoreverses: true),
                    value: viewStore.animationState.breathingEffect
                )
            
            // 프리미엄 브랜드명
            VStack(spacing: 12) {
                Text("Kingthereum")
                    .font(KingDesignTokens.Typography.displayM)
                    .foregroundColor(KingDesignTokens.Colors.primaryText)
                    .opacity(viewStore.visualState.brandOpacity)
                    .animation(
                        Animation.easeInOut(duration: 1.2).delay(0.5),
                        value: viewStore.visualState.brandOpacity
                    )
                
                // 프리미엄 태그라인
                Text("Premium Ethereum Wallet")
                    .font(KingDesignTokens.Typography.body)
                    .foregroundColor(KingDesignTokens.Colors.secondaryText)
                    .opacity(viewStore.visualState.taglineOpacity)
                    .animation(
                        Animation.easeInOut(duration: 1.2).delay(0.8),
                        value: viewStore.visualState.taglineOpacity
                    )
            }
        }
    }
    
    @ViewBuilder
    private var luxuryLoadingSection: some View {
        VStack(spacing: 16) {
            // 프리미엄 로딩 인디케이터
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: KingDesignTokens.Colors.accent))
                .scaleEffect(1.2)
                .opacity(viewStore.progressState.progressOpacity)
                .animation(
                    Animation.easeInOut(duration: 0.8).delay(1.2),
                    value: viewStore.progressState.progressOpacity
                )
            
            // 로딩 텍스트
            Text("Loading...")
                .font(KingDesignTokens.Typography.caption)
                .foregroundColor(KingDesignTokens.Colors.tertiaryText)
                .opacity(viewStore.progressState.progressOpacity)
                .animation(
                    Animation.easeInOut(duration: 0.8).delay(1.4),
                    value: viewStore.progressState.progressOpacity
                )
        }
    }
}
