import SwiftUI
import Core
import DesignSystem

/// Phase 2.3: 럭셔리 미니멀 브랜딩 SplashView
/// Modern Minimalism + Premium Fintech + Luxury Branding
/// Revolut, N26 수준의 프리미엄 피나테크 브랜딩
struct SplashView: View {
    @State private var logoScale: CGFloat = 0.95
    @State private var logoOpacity: Double = 0.0
    @State private var brandOpacity: Double = 0.0
    @State private var taglineOpacity: Double = 0.0
    @State private var progressOpacity: Double = 0.0
    @State private var subtleGlow: Double = 0.0
    @State private var breathingEffect: Bool = false
    @State private var loadingProgress: Double = 0.0
    @State private var isCompleting: Bool = false
    @State private var overallOpacity: Double = 1.0
    
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
                luxuryLoadingSection
                    .padding(.bottom, 80)
            }
        }
        .opacity(overallOpacity)
        .onAppear {
            startPremiumAnimations()
        }
    }
    
    // MARK: - 프리미엄 컴포넌트들
    
    @ViewBuilder
    private var luxuryBackground: some View {
        ZStack {
            // 프리미엄 미니멀 그라데이션
            LinearGradient(
                colors: [
                    KingColors.backgroundPrimary,
                    KingColors.minimalistNavy.opacity(0.15),
                    KingColors.trustPurple.opacity(0.05),
                    KingColors.backgroundSecondary
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // 서브틀한 앰비언트 글로우 (호흡 효과)
            if breathingEffect {
                RadialGradient(
                    colors: [
                        KingColors.exclusiveGold.opacity(subtleGlow * 0.02),
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
                    value: subtleGlow
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
                .scaleEffect(logoScale + (breathingEffect ? 0.02 : 0.0))
                .opacity(logoOpacity)
                .shadow(
                    color: KingColors.exclusiveGold.opacity(subtleGlow * 0.3),
                    radius: subtleGlow * 15,
                    x: 0,
                    y: subtleGlow * 8
                )
                .animation(
                    .easeInOut(duration: 3.0)
                    .repeatForever(autoreverses: true),
                    value: breathingEffect
                )
            
            // 프리미엄 브랜드명
            VStack(spacing: 12) {
                Text("Kingthereum")
                    .font(KingTypography.displayLarge)
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                KingColors.textPrimary,
                                KingColors.exclusiveGold.opacity(0.9),
                                KingColors.textPrimary
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(brandOpacity)
                    .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 0.5)
                
                // 프리미엄 태그라인
                Text("Premium Ethereum Wallet")
                    .font(KingTypography.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(KingColors.textSecondary)
                    .opacity(taglineOpacity)
                    .shadow(color: Color.black.opacity(0.15), radius: 0.5, x: 0, y: 0.5)
            }
        }
    }
    
    @ViewBuilder
    private var luxuryLoadingSection: some View {
        VStack(spacing: 20) {
            // 프리미엄 미니멀 프로그레스 인디케이터
            ZStack {
                // 베이스 서클
                Circle()
                    .stroke(
                        KingColors.exclusiveGold.opacity(0.15),
                        style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
                    )
                    .frame(width: 28, height: 28)
                
                // 프로그레스 서클 - 부드러운 채움 효과
                Circle()
                    .trim(from: 0, to: loadingProgress)
                    .stroke(
                        LinearGradient(
                            colors: [
                                KingColors.exclusiveGold.opacity(0.9),
                                KingColors.trustPurple.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
                    )
                    .frame(width: 28, height: 28)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 2.5), value: loadingProgress)
            }
            .opacity(progressOpacity)
            
            // 프리미엄 로딩 텍스트 - 동적 텍스트 변경
            Text(isCompleting ? "Premium Experience Ready" : "Initializing Premium Experience...")
                .font(KingTypography.caption)
                .fontWeight(.regular)
                .foregroundColor(isCompleting ? KingColors.exclusiveGold : KingColors.textTertiary)
                .opacity(progressOpacity)
                .shadow(color: Color.black.opacity(0.1), radius: 0.5, x: 0, y: 0.25)
                .animation(.easeInOut(duration: 0.8), value: isCompleting)
        }
    }
    
    private func startPremiumAnimations() {
        // 1. 미묘한 배경 글로우 시작
        withAnimation(.easeIn(duration: 0.6)) {
            breathingEffect = true
            subtleGlow = 1.0
        }
        
        // 2. 로고 우아한 등장 - 부드러운 페이드인과 스케일
        withAnimation(.spring(response: 1.2, dampingFraction: 0.8).delay(0.3)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // 3. 브랜드명 세련된 등장
        withAnimation(.easeOut(duration: 0.8).delay(0.7)) {
            brandOpacity = 1.0
        }
        
        // 4. 태그라인 미니멀 등장
        withAnimation(.easeOut(duration: 0.6).delay(1.0)) {
            taglineOpacity = 1.0
        }
        
        // 5. 프로그레스 인디케이터 등장
        withAnimation(.easeOut(duration: 0.5).delay(1.2)) {
            progressOpacity = 1.0
        }
        
        // 6. 프로그레스 채움 애니메이션 - 자연스러운 진행
        withAnimation(.easeInOut(duration: 2.0).delay(1.5)) {
            loadingProgress = 1.0
        }
        
        // 7. 완료 상태로 전환 - 텍스트 변경
        withAnimation(.easeInOut(duration: 0.4).delay(2.4)) {
            isCompleting = true
        }
        
        // 8. 전체 페이드아웃 - 부드러운 전환을 위한 준비
        withAnimation(.easeInOut(duration: 0.6).delay(3.0)) {
            overallOpacity = 0.0
        }
    }
}

/// 프리미엄 럭셔리 앱 아이콘
struct PremiumAppIcon: View {
    var body: some View {
        ZStack {
            // 외부 글로우 효과
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    RadialGradient(
                        colors: [
                            KingColors.exclusiveGold.opacity(0.4),
                            KingColors.exclusiveGold.opacity(0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 40,
                        endRadius: 80
                    )
                )
                .frame(width: 140, height: 140)
            
            // 메인 아이콘 배경 - 럭셔리 그라데이션
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            KingColors.minimalistNavy,
                            KingColors.trustPurple,
                            KingColors.exclusiveGold.opacity(0.3),
                            KingColors.minimalistNavy.opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    KingColors.exclusiveGold.opacity(0.6),
                                    Color.clear,
                                    KingColors.exclusiveGold.opacity(0.4)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
            
            // 중앙 글래스 컨테이너
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(KingColors.exclusiveGold.opacity(0.1))
                )
                .frame(width: 72, height: 72)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            AngularGradient(
                                colors: [
                                    KingColors.exclusiveGold,
                                    Color.clear,
                                    KingColors.exclusiveGold.opacity(0.5),
                                    Color.clear,
                                    KingColors.exclusiveGold
                                ],
                                center: .center
                            ),
                            lineWidth: 1
                        )
                )
            
            // 프리미엄 이더리움 심볼
            PremiumEthereumSymbol()
                .frame(width: 28, height: 42)
        }
        .shadow(color: KingColors.exclusiveGold.opacity(0.3), radius: 16, x: 0, y: 8)
    }
}

/// 럭셔리 이더리움 심볼
struct PremiumEthereumSymbol: View {
    var body: some View {
        ZStack {
            // 상단 다이아몬드 - 골드 그라데이션
            Path { path in
                path.move(to: CGPoint(x: 14, y: 0))     // 상단
                path.addLine(to: CGPoint(x: 28, y: 16)) // 우측
                path.addLine(to: CGPoint(x: 14, y: 21)) // 중앙
                path.addLine(to: CGPoint(x: 0, y: 16))  // 좌측
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [
                        KingColors.exclusiveGold,
                        KingColors.exclusiveGold.opacity(0.8),
                        KingColors.exclusiveGold.opacity(0.6)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(color: KingColors.exclusiveGold.opacity(0.4), radius: 4, x: 0, y: 2)
            
            // 하단 다이아몬드 - 퍼플 그라데이션
            Path { path in
                path.move(to: CGPoint(x: 14, y: 21))    // 중앙
                path.addLine(to: CGPoint(x: 28, y: 16)) // 우측
                path.addLine(to: CGPoint(x: 14, y: 42)) // 하단
                path.addLine(to: CGPoint(x: 0, y: 16))  // 좌측
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [
                        KingColors.trustPurple,
                        KingColors.trustPurple.opacity(0.8),
                        KingColors.minimalistNavy.opacity(0.9)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(color: KingColors.trustPurple.opacity(0.3), radius: 2, x: 0, y: 1)
            
            // 중앙 하이라이트
            Path { path in
                path.move(to: CGPoint(x: 14, y: 8))
                path.addLine(to: CGPoint(x: 20, y: 16))
                path.addLine(to: CGPoint(x: 14, y: 18))
                path.addLine(to: CGPoint(x: 8, y: 16))
                path.closeSubpath()
            }
            .fill(Color.white.opacity(0.3))
        }
    }
}

// MARK: - Preview

#Preview("Luxury SplashView") {
    SplashView()
        .preferredColorScheme(.dark)
}

#Preview("Luxury SplashView - Light") {
    SplashView()
        .preferredColorScheme(.light)
}

#Preview("Premium App Icon") {
    PremiumAppIcon()
        .frame(width: 160, height: 160)
        .background(KingColors.backgroundPrimary)
        .preferredColorScheme(.dark)
}

#Preview("Premium App Icon - Light") {
    PremiumAppIcon()
        .frame(width: 160, height: 160)
        .background(KingColors.backgroundPrimary)
        .preferredColorScheme(.light)
}
