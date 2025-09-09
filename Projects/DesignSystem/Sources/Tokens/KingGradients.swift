import SwiftUI

/// Kingthereum 프리미엄 그라데이션 시스템 2024
/// 모던 미니멀리즘 + 프리미엄 피나테크 + 글래스모피즘 기반 서브틀 그라데이션
public struct KingGradients {
    
    // MARK: - 미니멀리즘 Core Gradients
    
    /// 프리미엄 미니멀 그라데이션 - 네이비 to 순수 블랙 (극도로 서브틀)
    public static let minimalistPrimary = LinearGradient(
        colors: [
            KingColors.minimalistNavy,
            KingColors.minimalistNavy.opacity(0.9)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 신뢰감 그라데이션 - 퍼플 기반 (피나테크 신뢰성)
    public static let trustGradient = LinearGradient(
        colors: [
            KingColors.trustPurple,
            KingColors.trustPurple.opacity(0.8)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 골드 액센트 그라데이션 - 오직 중요 요소에만 (극도로 절제적)
    public static let premiumGold = LinearGradient(
        colors: [
            KingColors.exclusiveGold,
            KingColors.exclusiveGold.opacity(0.85)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // MARK: - Legacy Brand Gradients (호환성을 위해 매핑)
    
    /// 메인 브랜드 → minimalistPrimary로 매핑
    public static let primary = minimalistPrimary
    
    /// 라이트 브랜드 → 서브틀 화이트 그라데이션
    public static let primaryLight = LinearGradient(
        colors: [
            KingColors.pureWhite,
            KingColors.subtleGray
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 액센트 → trustGradient로 매핑
    public static let accent = trustGradient
    
    // MARK: - 미니멀리즘 Background Gradients
    
    /// 극도로 서브틀한 배경 그라데이션 - 거의 순수 단색
    public static let minimalistBackground = LinearGradient(
        colors: [
            KingColors.pureWhite,
            KingColors.pureWhite.opacity(0.98)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 프리미엄 앰비언트 배경 - 아주 연한 네이비 힌트
    public static let premiumAmbient = LinearGradient(
        colors: [
            KingColors.pureWhite,
            KingColors.minimalistNavy.opacity(0.02),
            KingColors.pureWhite.opacity(0.95)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 미니멀 글래스 서피스 - 완전 투명에 가까운
    public static let glassMinimal = LinearGradient(
        colors: [
            Color.clear,
            KingColors.glassMinimalBase
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // MARK: - Legacy Background Gradients (호환성 유지)
    
    /// 기존 background → minimalistBackground로 매핑
    public static let background = minimalistBackground
    
    /// 기존 backgroundAmbient → premiumAmbient로 매핑
    public static let backgroundAmbient = premiumAmbient
    
    /// 기존 surface → glassMinimal로 매핑
    public static let surface = glassMinimal
    
    // MARK: - 미니멀리즘 Card Gradients
    
    /// 극도로 서브틀한 카드 그라데이션 - 거의 단색
    public static let minimalistCard = LinearGradient(
        colors: [
            KingColors.glassCardBackground,
            KingColors.glassCardBackground.opacity(0.9)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 프리미엄 엘리베이티드 카드 - 중요 요소용
    public static let premiumElevatedCard = LinearGradient(
        colors: [
            KingColors.premiumElevated,
            KingColors.premiumElevated.opacity(0.95)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 순수 글래스 효과 - 완전 투명 기반
    public static let pureGlass = LinearGradient(
        colors: [
            Color.white.opacity(0.08),
            Color.white.opacity(0.03),
            Color.clear
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Legacy Card Gradients (호환성 유지)
    
    /// 기존 card → minimalistCard로 매핑
    public static let card = minimalistCard
    
    /// 기존 cardElevated → premiumElevatedCard로 매핑
    public static let cardElevated = premiumElevatedCard
    
    /// 기존 cardGlass → pureGlass로 매핑
    public static let cardGlass = pureGlass
    
    // MARK: - 미니멀리즘 Button Gradients
    
    /// 프리미엄 골드 버튼 - 오직 중요한 액션에만
    public static let premiumGoldButton = LinearGradient(
        colors: [
            KingColors.exclusiveGold,
            KingColors.exclusiveGold.opacity(0.9)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// 신뢰감 퍼플 버튼 - 보안 기능용
    public static let trustButton = LinearGradient(
        colors: [
            KingColors.trustPurple,
            KingColors.trustPurple.opacity(0.9)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// 극도로 서브틀한 세컨더리 버튼
    public static let minimalistSecondary = LinearGradient(
        colors: [
            KingColors.buttonSecondary,
            KingColors.buttonSecondary.opacity(0.95)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// 서브틀한 성공 버튼
    public static let subtleSuccess = LinearGradient(
        colors: [
            KingColors.success,
            KingColors.success.opacity(0.9)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// 서브틀한 위험 버튼
    public static let subtleDanger = LinearGradient(
        colors: [
            KingColors.error,
            KingColors.error.opacity(0.9)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // MARK: - Legacy Button Gradients (호환성 유지)
    
    /// 기존 buttonPrimary → premiumGoldButton로 매핑
    public static let buttonPrimary = premiumGoldButton
    
    /// 기존 buttonSecondary → minimalistSecondary로 매핑
    public static let buttonSecondary = minimalistSecondary
    
    /// 기존 buttonHover → trustButton로 매핑
    public static let buttonHover = trustButton
    
    /// 기존 buttonSuccess → subtleSuccess로 매핑
    public static let buttonSuccess = subtleSuccess
    
    /// 기존 buttonDanger → subtleDanger로 매핑
    public static let buttonDanger = subtleDanger
    
    // MARK: - 미니멀리즘 State Gradients (극도로 서브틀)
    
    /// 서브틀한 성공 상태
    public static let subtleSuccessState = LinearGradient(
        colors: [
            KingColors.success.opacity(0.08),
            Color.clear
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 서브틀한 경고 상태  
    public static let subtleWarningState = LinearGradient(
        colors: [
            KingColors.warning.opacity(0.08),
            Color.clear
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 서브틀한 에러 상태
    public static let subtleErrorState = LinearGradient(
        colors: [
            KingColors.error.opacity(0.08),
            Color.clear
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 서브틀한 신뢰 정보 상태
    public static let subtleInfoState = LinearGradient(
        colors: [
            KingColors.trustPurple.opacity(0.08),
            Color.clear
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Legacy State Gradients (호환성 유지)
    
    /// 기존 success → subtleSuccessState로 매핑
    public static let success = subtleSuccessState
    
    /// 기존 warning → subtleWarningState로 매핑
    public static let warning = subtleWarningState
    
    /// 기존 error → subtleErrorState로 매핑
    public static let error = subtleErrorState
    
    /// 기존 info → subtleInfoState로 매핑
    public static let info = subtleInfoState
    
    // MARK: - 미니멀리즘 Transaction Gradients
    
    /// 극도로 서브틀한 송금 표시
    public static let minimalistSend = LinearGradient(
        colors: [
            KingColors.error.opacity(0.06),
            Color.clear
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    /// 극도로 서브틀한 수신 표시
    public static let minimalistReceive = LinearGradient(
        colors: [
            KingColors.success.opacity(0.06),
            Color.clear
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    /// 극도로 서브틀한 대기 표시
    public static let minimalistPending = LinearGradient(
        colors: [
            KingColors.warning.opacity(0.06),
            Color.clear
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // MARK: - Legacy Transaction Gradients (호환성 유지)
    
    /// 기존 transactionSend → minimalistSend로 매핑
    public static let transactionSend = minimalistSend
    
    /// 기존 transactionReceive → minimalistReceive로 매핑
    public static let transactionReceive = minimalistReceive
    
    /// 기존 transactionPending → minimalistPending로 매핑
    public static let transactionPending = minimalistPending
    
    // MARK: - 프리미엄 피나테크 Crypto Gradients
    
    /// 이더리움 신뢰 그라데이션 - 퍼플 기반 
    public static let ethereumTrust = LinearGradient(
        colors: [
            KingColors.trustPurple,
            KingColors.trustPurple.opacity(0.8)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 비트코인 프리미엄 골드 그라데이션
    public static let bitcoinGold = LinearGradient(
        colors: [
            KingColors.exclusiveGold,
            KingColors.exclusiveGold.opacity(0.8)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 미니멀 암호화폐 그라데이션 - 네이비+퍼플+골드 조합 (극도로 서브틀)
    public static let cryptoMinimal = LinearGradient(
        colors: [
            KingColors.minimalistNavy.opacity(0.05),
            KingColors.trustPurple.opacity(0.03),
            KingColors.exclusiveGold.opacity(0.02)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Legacy Crypto Gradients (호환성 유지)
    
    /// 기존 ethereum → ethereumTrust로 매핑
    public static let ethereum = ethereumTrust
    
    /// 기존 bitcoin → bitcoinGold로 매핑
    public static let bitcoin = bitcoinGold
    
    /// 기존 web3Rainbow → cryptoMinimal로 매핑 (복잡한 무지개 효과 제거)
    public static let web3Rainbow = cryptoMinimal
    
    // MARK: - 미니멀리즘 Glass Effects (복잡한 특수 효과 대신 서브틀한 글래스만)
    
    /// 순수 글래스모피즘 - 최소한의 반투명 효과
    public static let pureGlassMorphism = LinearGradient(
        colors: [
            Color.white.opacity(0.05),
            Color.white.opacity(0.02),
            Color.clear
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 프리미엄 글래스 하이라이트 - 골드 힌트
    public static let premiumGlassHighlight = LinearGradient(
        colors: [
            KingColors.exclusiveGold.opacity(0.08),
            Color.clear
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Legacy Special Effects (호환성을 위해 매핑, 복잡한 효과들은 제거)
    
    /// 기존 holographic → pureGlassMorphism로 매핑 (홀로그래픽 효과 제거)
    public static let holographic = pureGlassMorphism
    
    /// 기존 aurora → pureGlassMorphism로 매핑 (오로라 효과 제거)
    public static let aurora = pureGlassMorphism
    
    /// 기존 neon → premiumGlassHighlight로 매핑 (네온 효과 제거)
    public static let neon = premiumGlassHighlight
    
    /// 기존 glassMorphism → pureGlassMorphism로 매핑
    public static let glassMorphism = pureGlassMorphism
}

// MARK: - 미니멀리즘 Radial Gradients
public extension KingGradients {
    
    /// 극도로 서브틀한 퍼플 스포트라이트 - 신뢰감 표현
    static let minimalistTrustSpotlight = RadialGradient(
        colors: [
            KingColors.trustPurple.opacity(0.08),
            KingColors.trustPurple.opacity(0.03),
            Color.clear
        ],
        center: .center,
        startRadius: 50,
        endRadius: 200
    )
    
    /// 미니멀 글래스 카드용 라디얼
    static let minimalistGlassCard = RadialGradient(
        colors: [
            Color.white.opacity(0.04),
            Color.white.opacity(0.02),
            Color.clear
        ],
        center: .topLeading,
        startRadius: 0,
        endRadius: 150
    )
    
    /// 프리미엄 골드 버튼용 라디얼 - 중요 액션에만
    static let premiumGoldRadial = RadialGradient(
        colors: [
            KingColors.exclusiveGold.opacity(0.15),
            Color.clear
        ],
        center: .center,
        startRadius: 0,
        endRadius: 50
    )
    
    // MARK: - Legacy Radial Gradients (호환성 유지)
    
    /// 기존 radialSpotlight → minimalistTrustSpotlight로 매핑
    static let radialSpotlight = minimalistTrustSpotlight
    
    /// 기존 radialCard → minimalistGlassCard로 매핑
    static let radialCard = minimalistGlassCard
    
    /// 기존 radialButton → premiumGoldRadial로 매핑
    static let radialButton = premiumGoldRadial
}

// MARK: - 미니멀리즘 Angular Gradients (복잡한 무지개 효과 제거)
public extension KingGradients {
    
    /// 서브틀한 신뢰감 원형 그라데이션 - 네이비+퍼플+골드
    static let minimalistAngular = AngularGradient(
        colors: [
            KingColors.minimalistNavy.opacity(0.1),
            KingColors.trustPurple.opacity(0.08),
            KingColors.exclusiveGold.opacity(0.06),
            KingColors.minimalistNavy.opacity(0.1)
        ],
        center: .center
    )
    
    /// 극도로 서브틀한 원형 그라데이션
    static let ultraMinimalAngular = AngularGradient(
        colors: [
            KingColors.trustPurple.opacity(0.06),
            KingColors.trustPurple.opacity(0.04),
            KingColors.trustPurple.opacity(0.06)
        ],
        center: .center
    )
    
    // MARK: - Legacy Angular Gradients (호환성 유지)
    
    /// 기존 angularRainbow → minimalistAngular로 매핑 (무지개 효과 제거)
    static let angularRainbow = minimalistAngular
    
    /// 기존 angularSubtle → ultraMinimalAngular로 매핑
    static let angularSubtle = ultraMinimalAngular
}

// MARK: - 미니멀리즘 Gradient View Modifiers
public extension View {
    
    /// 서브틀한 배경 그라데이션 적용
    func minimalistBackground(_ gradient: LinearGradient) -> some View {
        background(gradient)
    }
    
    /// 극도로 서브틀한 오버레이 그라데이션
    func subtleOverlay(_ gradient: LinearGradient, opacity: Double = 0.5) -> some View {
        overlay(gradient.opacity(opacity))
    }
    
    /// 미니멀 그라데이션 보더 - 거의 보이지 않는 수준
    func minimalistBorder(_ gradient: LinearGradient, width: CGFloat = 0.5) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(gradient, lineWidth: width)
        )
    }
    
    /// 프리미엄 미니멀 카드 스타일 - 극도로 깔끔함
    func premiumMinimalCard() -> some View {
        background(KingGradients.minimalistCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(KingColors.glassBorder, lineWidth: 0.5)
            )
    }
    
    /// 골드 액센트 카드 스타일 - 중요 요소용
    func premiumGoldCard() -> some View {
        background(KingGradients.premiumElevatedCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(KingColors.exclusiveGold.opacity(0.3), lineWidth: 1)
            )
    }
    
    // MARK: - Legacy Modifiers (호환성 유지)
    
    /// 기존 backgroundGradient → minimalistBackground로 매핑
    func backgroundGradient(_ gradient: LinearGradient) -> some View {
        minimalistBackground(gradient)
    }
    
    /// 기존 overlayGradient → subtleOverlay로 매핑
    func overlayGradient(_ gradient: LinearGradient, opacity: Double = 1.0) -> some View {
        subtleOverlay(gradient, opacity: opacity * 0.5) // 더 서브틀하게
    }
    
    /// 기존 gradientBorder → minimalistBorder로 매핑
    func gradientBorder(_ gradient: LinearGradient, width: CGFloat = 1) -> some View {
        minimalistBorder(gradient, width: width * 0.5) // 더 얇게
    }
    
    /// 기존 cardGradientStyle → premiumMinimalCard로 매핑
    func cardGradientStyle() -> some View {
        premiumMinimalCard()
    }
}

// MARK: - Preview Support
#Preview("Kingthereum Gradients") {
    ScrollView {
        LazyVStack(spacing: 24) {
            // Brand Gradients
            GradientSection(
                title: "Brand Gradients",
                gradients: [
                    ("Primary", KingGradients.primary),
                    ("Primary Light", KingGradients.primaryLight),
                    ("Accent", KingGradients.accent)
                ]
            )
            
            // Background Gradients
            GradientSection(
                title: "Background Gradients",
                gradients: [
                    ("Background", KingGradients.background),
                    ("Background Ambient", KingGradients.backgroundAmbient),
                    ("Surface", KingGradients.surface)
                ]
            )
            
            // Card Gradients
            GradientSection(
                title: "Card Gradients",
                gradients: [
                    ("Card", KingGradients.card),
                    ("Card Elevated", KingGradients.cardElevated),
                    ("Card Glass", KingGradients.cardGlass)
                ]
            )
            
            // Button Gradients
            GradientSection(
                title: "Button Gradients",
                gradients: [
                    ("Primary", KingGradients.buttonPrimary),
                    ("Secondary", KingGradients.buttonSecondary),
                    ("Success", KingGradients.buttonSuccess)
                ]
            )
            
            // Transaction Gradients
            GradientSection(
                title: "Transaction Gradients",
                gradients: [
                    ("Send", KingGradients.transactionSend),
                    ("Receive", KingGradients.transactionReceive),
                    ("Pending", KingGradients.transactionPending)
                ]
            )
            
            // Special Effect Gradients
            GradientSection(
                title: "Special Effects",
                gradients: [
                    ("Holographic", KingGradients.holographic),
                    ("Aurora", KingGradients.aurora),
                    ("Neon", KingGradients.neon)
                ]
            )
        }
        .padding()
    }
    .background(KingColors.backgroundPrimary)
}

// MARK: - Helper Views for Preview
private struct GradientSection: View {
    let title: String
    let gradients: [(String, LinearGradient)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(KingColors.textPrimary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 1), spacing: 12) {
                ForEach(gradients, id: \.0) { name, gradient in
                    VStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(gradient)
                            .frame(height: 60)
                        
                        Text(name)
                            .font(.caption)
                            .foregroundColor(KingColors.textSecondary)
                    }
                }
            }
        }
        .padding()
        .cardGradientStyle()
    }
}