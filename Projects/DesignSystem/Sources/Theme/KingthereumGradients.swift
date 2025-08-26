import SwiftUI

/// Kingthereum 앱 전용 세련된 그라데이션 시스템
/// 다양한 용도별 그라데이션을 제공하여 프리미엄 느낌의 UI 구현
public struct KingthereumGradients {
    
    // MARK: - Primary Brand Gradients
    
    /// 메인 브랜드 그라데이션 - 네이비 to 퍼플
    public static let primary = LinearGradient(
        colors: [
            KingthereumColors.primaryDark,
            KingthereumColors.accentSecondary
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 라이트 브랜드 그라데이션 - 더 서브틀한 톤
    public static let primaryLight = LinearGradient(
        colors: [
            KingthereumColors.primaryLight,
            KingthereumColors.accent.opacity(0.8)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 액센트 그라데이션 - 블루 to 퍼플
    public static let accent = LinearGradient(
        colors: [
            KingthereumColors.accent,
            KingthereumColors.accentSecondary
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // MARK: - Background Gradients
    
    /// 메인 배경 그라데이션 - 매우 서브틀
    public static let background = LinearGradient(
        colors: [
            KingthereumColors.backgroundPrimary,
            KingthereumColors.backgroundSecondary.opacity(0.6)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 앰비언트 배경 그라데이션 - 분위기 있는 배경용
    public static let backgroundAmbient = LinearGradient(
        colors: [
            KingthereumColors.backgroundPrimary,
            KingthereumColors.accent.opacity(0.02),
            KingthereumColors.backgroundSecondary.opacity(0.4)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 서피스 그라데이션 - 카드 및 패널용
    public static let surface = LinearGradient(
        colors: [
            KingthereumColors.surface,
            KingthereumColors.backgroundSecondary.opacity(0.3)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // MARK: - Card Gradients
    
    /// 기본 카드 그라데이션 - 3단계 서브틀
    public static let card = LinearGradient(
        colors: [
            KingthereumColors.cardBackground,
            KingthereumColors.cardBackground.opacity(0.95),
            KingthereumColors.backgroundSecondary.opacity(0.8)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 엘리베이티드 카드 그라데이션
    public static let cardElevated = LinearGradient(
        colors: [
            KingthereumColors.cardElevated,
            KingthereumColors.cardElevated.opacity(0.9),
            KingthereumColors.backgroundTertiary.opacity(0.6)
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
            KingthereumColors.accent,
            KingthereumColors.accentSecondary
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// 세컨더리 버튼 그라데이션
    public static let buttonSecondary = LinearGradient(
        colors: [
            KingthereumColors.buttonSecondary,
            KingthereumColors.backgroundTertiary
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// 버튼 호버 그라데이션
    public static let buttonHover = LinearGradient(
        colors: [
            KingthereumColors.accent.opacity(0.9),
            KingthereumColors.accentSecondary.opacity(0.8)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// 성공 버튼 그라데이션
    public static let buttonSuccess = LinearGradient(
        colors: [
            KingthereumColors.success,
            KingthereumColors.success.opacity(0.8)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// 위험 버튼 그라데이션
    public static let buttonDanger = LinearGradient(
        colors: [
            KingthereumColors.error,
            KingthereumColors.error.opacity(0.8)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // MARK: - Semantic State Gradients
    
    /// 성공 상태 그라데이션
    public static let success = LinearGradient(
        colors: [
            KingthereumColors.success.opacity(0.2),
            KingthereumColors.success.opacity(0.1),
            Color.clear
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 경고 상태 그라데이션
    public static let warning = LinearGradient(
        colors: [
            KingthereumColors.warning.opacity(0.2),
            KingthereumColors.warning.opacity(0.1),
            Color.clear
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 에러 상태 그라데이션
    public static let error = LinearGradient(
        colors: [
            KingthereumColors.error.opacity(0.2),
            KingthereumColors.error.opacity(0.1),
            Color.clear
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 정보 상태 그라데이션
    public static let info = LinearGradient(
        colors: [
            KingthereumColors.info.opacity(0.2),
            KingthereumColors.info.opacity(0.1),
            Color.clear
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Transaction Gradients
    
    /// 송금 트랜잭션 그라데이션
    public static let transactionSend = LinearGradient(
        colors: [
            KingthereumColors.transactionSend.opacity(0.15),
            KingthereumColors.transactionSend.opacity(0.05)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    /// 수신 트랜잭션 그라데이션
    public static let transactionReceive = LinearGradient(
        colors: [
            KingthereumColors.transactionReceive.opacity(0.15),
            KingthereumColors.transactionReceive.opacity(0.05)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    /// 대기중 트랜잭션 그라데이션
    public static let transactionPending = LinearGradient(
        colors: [
            KingthereumColors.transactionPending.opacity(0.15),
            KingthereumColors.transactionPending.opacity(0.05)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // MARK: - Crypto & Web3 Gradients
    
    /// 이더리움 그라데이션
    public static let ethereum = LinearGradient(
        colors: [
            KingthereumColors.ethereum,
            KingthereumColors.ethereum.opacity(0.7),
            KingthereumColors.accent.opacity(0.3)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 비트코인 그라데이션
    public static let bitcoin = LinearGradient(
        colors: [
            KingthereumColors.bitcoin,
            KingthereumColors.warning.opacity(0.8)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 웹3 글로벌 그라데이션 - 멀티컬러
    public static let web3Rainbow = LinearGradient(
        colors: [
            KingthereumColors.accent,
            KingthereumColors.accentSecondary,
            KingthereumColors.success,
            KingthereumColors.bitcoin
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
public extension KingthereumGradients {
    
    /// 중심에서 퍼지는 라디얼 그라데이션
    static let radialSpotlight = RadialGradient(
        colors: [
            KingthereumColors.accent.opacity(0.3),
            KingthereumColors.accent.opacity(0.1),
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
public extension KingthereumGradients {
    
    /// 회전하는 앵귤러 그라데이션
    static let angularRainbow = AngularGradient(
        colors: [
            KingthereumColors.accent,
            KingthereumColors.accentSecondary,
            KingthereumColors.success,
            KingthereumColors.warning,
            KingthereumColors.error,
            KingthereumColors.accent
        ],
        center: .center
    )
    
    /// 서브틀 앵귤러 그라데이션
    static let angularSubtle = AngularGradient(
        colors: [
            KingthereumColors.accent.opacity(0.3),
            KingthereumColors.accentSecondary.opacity(0.2),
            KingthereumColors.accent.opacity(0.3)
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
        background(KingthereumGradients.card)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(KingthereumColors.cardBorder, lineWidth: 1)
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
                    ("Primary", KingthereumGradients.primary),
                    ("Primary Light", KingthereumGradients.primaryLight),
                    ("Accent", KingthereumGradients.accent)
                ]
            )
            
            // Background Gradients
            GradientSection(
                title: "Background Gradients",
                gradients: [
                    ("Background", KingthereumGradients.background),
                    ("Background Ambient", KingthereumGradients.backgroundAmbient),
                    ("Surface", KingthereumGradients.surface)
                ]
            )
            
            // Card Gradients
            GradientSection(
                title: "Card Gradients",
                gradients: [
                    ("Card", KingthereumGradients.card),
                    ("Card Elevated", KingthereumGradients.cardElevated),
                    ("Card Glass", KingthereumGradients.cardGlass)
                ]
            )
            
            // Button Gradients
            GradientSection(
                title: "Button Gradients",
                gradients: [
                    ("Primary", KingthereumGradients.buttonPrimary),
                    ("Secondary", KingthereumGradients.buttonSecondary),
                    ("Success", KingthereumGradients.buttonSuccess)
                ]
            )
            
            // Transaction Gradients
            GradientSection(
                title: "Transaction Gradients",
                gradients: [
                    ("Send", KingthereumGradients.transactionSend),
                    ("Receive", KingthereumGradients.transactionReceive),
                    ("Pending", KingthereumGradients.transactionPending)
                ]
            )
            
            // Special Effect Gradients
            GradientSection(
                title: "Special Effects",
                gradients: [
                    ("Holographic", KingthereumGradients.holographic),
                    ("Aurora", KingthereumGradients.aurora),
                    ("Neon", KingthereumGradients.neon)
                ]
            )
        }
        .padding()
    }
    .background(KingthereumColors.backgroundPrimary)
}

// MARK: - Helper Views for Preview
private struct GradientSection: View {
    let title: String
    let gradients: [(String, LinearGradient)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(KingthereumColors.textPrimary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 1), spacing: 12) {
                ForEach(gradients, id: \.0) { name, gradient in
                    VStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(gradient)
                            .frame(height: 60)
                        
                        Text(name)
                            .font(.caption)
                            .foregroundColor(KingthereumColors.textSecondary)
                    }
                }
            }
        }
        .padding()
        .cardGradientStyle()
    }
}