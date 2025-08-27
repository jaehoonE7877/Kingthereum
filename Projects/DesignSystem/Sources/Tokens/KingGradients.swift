import SwiftUI

/// King 앱 전용 세련된 그라데이션 시스템
/// 다양한 용도별 그라데이션을 제공하여 프리미엄 느낌의 UI 구현
public struct KingGradients {
    
    // MARK: - Primary Brand Gradients
    
    /// 메인 브랜드 그라데이션 - 네이비 to 퍼플
    public static let primary = LinearGradient(
        colors: [
            KingColors.primaryDark,
            KingColors.accentSecondary
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 라이트 브랜드 그라데이션 - 더 서브틀한 톤
    public static let primaryLight = LinearGradient(
        colors: [
            KingColors.primaryLight,
            KingColors.accent.opacity(0.8)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 액센트 그라데이션 - 블루 to 퍼플
    public static let accent = LinearGradient(
        colors: [
            KingColors.accent,
            KingColors.accentSecondary
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // MARK: - Background Gradients
    
    /// 메인 배경 그라데이션 - 매우 서브틀
    public static let background = LinearGradient(
        colors: [
            KingColors.backgroundPrimary,
            KingColors.backgroundSecondary.opacity(0.6)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 앰비언트 배경 그라데이션 - 분위기 있는 배경용
    public static let backgroundAmbient = LinearGradient(
        colors: [
            KingColors.backgroundPrimary,
            KingColors.accent.opacity(0.02),
            KingColors.backgroundSecondary.opacity(0.4)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 서피스 그라데이션 - 카드 및 패널용
    public static let surface = LinearGradient(
        colors: [
            KingColors.surface,
            KingColors.backgroundSecondary.opacity(0.3)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // MARK: - Card Gradients
    
    /// 기본 카드 그라데이션 - 3단계 서브틀
    public static let card = LinearGradient(
        colors: [
            KingColors.cardBackground,
            KingColors.cardBackground.opacity(0.95),
            KingColors.backgroundSecondary.opacity(0.8)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 엘리베이티드 카드 그라데이션
    public static let cardElevated = LinearGradient(
        colors: [
            KingColors.cardElevated,
            KingColors.cardElevated.opacity(0.9),
            KingColors.backgroundTertiary.opacity(0.6)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 글래시 카드 그라데이션 - 글래스 효과와 조화
    public static let cardGlass = LinearGradient(
        colors: [
            Color.white.opacity(0.1),
            Color.white.opacity(0.05),
            Color.clear
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Button Gradients
    
    /// 프라이머리 버튼 그라데이션
    public static let buttonPrimary = LinearGradient(
        colors: [
            KingColors.accent,
            KingColors.accentSecondary
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// 세컨더리 버튼 그라데이션
    public static let buttonSecondary = LinearGradient(
        colors: [
            KingColors.buttonSecondary,
            KingColors.backgroundTertiary
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// 버튼 호버 그라데이션
    public static let buttonHover = LinearGradient(
        colors: [
            KingColors.accent.opacity(0.9),
            KingColors.accentSecondary.opacity(0.8)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// 성공 버튼 그라데이션
    public static let buttonSuccess = LinearGradient(
        colors: [
            KingColors.success,
            KingColors.success.opacity(0.8)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// 위험 버튼 그라데이션
    public static let buttonDanger = LinearGradient(
        colors: [
            KingColors.error,
            KingColors.error.opacity(0.8)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // MARK: - Semantic State Gradients
    
    /// 성공 상태 그라데이션
    public static let success = LinearGradient(
        colors: [
            KingColors.success.opacity(0.2),
            KingColors.success.opacity(0.1),
            Color.clear
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 경고 상태 그라데이션
    public static let warning = LinearGradient(
        colors: [
            KingColors.warning.opacity(0.2),
            KingColors.warning.opacity(0.1),
            Color.clear
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 에러 상태 그라데이션
    public static let error = LinearGradient(
        colors: [
            KingColors.error.opacity(0.2),
            KingColors.error.opacity(0.1),
            Color.clear
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 정보 상태 그라데이션
    public static let info = LinearGradient(
        colors: [
            KingColors.info.opacity(0.2),
            KingColors.info.opacity(0.1),
            Color.clear
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Transaction Gradients
    
    /// 송금 트랜잭션 그라데이션
    public static let transactionSend = LinearGradient(
        colors: [
            KingColors.transactionSend.opacity(0.15),
            KingColors.transactionSend.opacity(0.05)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    /// 수신 트랜잭션 그라데이션
    public static let transactionReceive = LinearGradient(
        colors: [
            KingColors.transactionReceive.opacity(0.15),
            KingColors.transactionReceive.opacity(0.05)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    /// 대기중 트랜잭션 그라데이션
    public static let transactionPending = LinearGradient(
        colors: [
            KingColors.transactionPending.opacity(0.15),
            KingColors.transactionPending.opacity(0.05)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // MARK: - Crypto & Web3 Gradients
    
    /// 이더리움 그라데이션
    public static let ethereum = LinearGradient(
        colors: [
            KingColors.ethereum,
            KingColors.ethereum.opacity(0.7),
            KingColors.accent.opacity(0.3)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 비트코인 그라데이션
    public static let bitcoin = LinearGradient(
        colors: [
            KingColors.bitcoin,
            KingColors.warning.opacity(0.8)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 웹3 글로벌 그라데이션 - 멀티컬러
    public static let web3Rainbow = LinearGradient(
        colors: [
            KingColors.accent,
            KingColors.accentSecondary,
            KingColors.success,
            KingColors.bitcoin
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Special Effect Gradients
    
    /// 홀로그래픽 효과 그라데이션
    public static let holographic = LinearGradient(
        colors: [
            Color.blue.opacity(0.3),
            Color.purple.opacity(0.3),
            Color.pink.opacity(0.3),
            Color.blue.opacity(0.3)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 오로라 효과 그라데이션
    public static let aurora = LinearGradient(
        colors: [
            Color.blue.opacity(0.4),
            Color.purple.opacity(0.3),
            Color.cyan.opacity(0.2),
            Color.indigo.opacity(0.3)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 네온 효과 그라데이션
    public static let neon = LinearGradient(
        colors: [
            Color.cyan.opacity(0.6),
            Color.blue.opacity(0.4),
            Color.purple.opacity(0.6)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    /// Glass Morphism 효과를 위한 반투명 그라데이션
    public static let glassMorphism = LinearGradient(
        colors: [
            Color.white.opacity(0.15),
            Color.white.opacity(0.08),
            Color.clear,
            Color.black.opacity(0.05)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Radial Gradients
public extension KingGradients {
    
    /// 중심에서 퍼지는 라디얼 그라데이션
    static let radialSpotlight = RadialGradient(
        colors: [
            KingColors.accent.opacity(0.3),
            KingColors.accent.opacity(0.1),
            Color.clear
        ],
        center: .center,
        startRadius: 50,
        endRadius: 200
    )
    
    /// 카드용 라디얼 그라데이션
    static let radialCard = RadialGradient(
        colors: [
            Color.white.opacity(0.1),
            Color.white.opacity(0.05),
            Color.clear
        ],
        center: .topLeading,
        startRadius: 0,
        endRadius: 150
    )
    
    /// 버튼용 라디얼 그라데이션
    static let radialButton = RadialGradient(
        colors: [
            Color.white.opacity(0.3),
            Color.clear
        ],
        center: .center,
        startRadius: 0,
        endRadius: 50
    )
}

// MARK: - Angular Gradients
public extension KingGradients {
    
    /// 회전하는 앵귤러 그라데이션
    static let angularRainbow = AngularGradient(
        colors: [
            KingColors.accent,
            KingColors.accentSecondary,
            KingColors.success,
            KingColors.warning,
            KingColors.error,
            KingColors.accent
        ],
        center: .center
    )
    
    /// 서브틀 앵귤러 그라데이션
    static let angularSubtle = AngularGradient(
        colors: [
            KingColors.accent.opacity(0.3),
            KingColors.accentSecondary.opacity(0.2),
            KingColors.accent.opacity(0.3)
        ],
        center: .center
    )
}

// MARK: - Gradient View Modifiers
public extension View {
    
    /// 배경에 그라데이션 적용
    func backgroundGradient(_ gradient: LinearGradient) -> some View {
        background(gradient)
    }
    
    /// 오버레이에 그라데이션 적용
    func overlayGradient(_ gradient: LinearGradient, opacity: Double = 1.0) -> some View {
        overlay(gradient.opacity(opacity))
    }
    
    /// 그라데이션 보더 적용
    func gradientBorder(_ gradient: LinearGradient, width: CGFloat = 1) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(gradient, lineWidth: width)
        )
    }
    
    /// 카드 스타일 그라데이션 적용
    func cardGradientStyle() -> some View {
        background(KingGradients.card)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(KingColors.cardBorder, lineWidth: 1)
            )
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