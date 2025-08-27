import SwiftUI

/// Kingthereum 프리미엄 미니멀리즘 글래스 컴포넌트 시스템 2024
/// 극도로 서브틀한 글래스모피즘 효과 + 네이비+퍼플+골드 액센트

// MARK: - UltraMinimalGlass ViewModifier

/// 극도로 미니멀한 글래스 효과
public struct UltraMinimalGlass: ViewModifier {
    let level: GlassTokens.EffectLevel
    let context: GlassTokens.Context
    
    public init(level: GlassTokens.EffectLevel = .subtle, context: GlassTokens.Context = .card) {
        self.level = level
        self.context = context
    }
    
    public func body(content: Content) -> some View {
        content
            .background {
                // 극도로 서브틀한 글래스 배경
                RoundedRectangle(cornerRadius: context.defaultCornerRadius)
                    .fill(KingColors.glassMinimalBase)
                    .overlay {
                        // 미니멀한 하이라이트
                        RoundedRectangle(cornerRadius: context.defaultCornerRadius)
                            .stroke(
                                KingColors.glassBorder,
                                lineWidth: level.minimalistBorderWidth
                            )
                    }
                    .shadow(
                        color: KingColors.glassShadow,
                        radius: level.minimalistShadowRadius,
                        x: 0,
                        y: level.minimalistShadowOffset
                    )
            }
    }
}

// MARK: - PremiumFinTechGlass ViewModifier

/// 프리미엄 피나테크 글래스 효과 - 신뢰감 있는 퍼플 힌트
public struct PremiumFinTechGlass: ViewModifier {
    let level: GlassTokens.EffectLevel
    let context: GlassTokens.Context
    
    public init(level: GlassTokens.EffectLevel = .standard, context: GlassTokens.Context = .card) {
        self.level = level
        self.context = context
    }
    
    public func body(content: Content) -> some View {
        content
            .background {
                // 신뢰감 있는 퍼플 힌트 글래스
                RoundedRectangle(cornerRadius: context.defaultCornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                KingColors.glassCardBackground,
                                KingColors.glassTrustHighlight
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: context.defaultCornerRadius)
                            .stroke(
                                KingColors.trustPurple.opacity(level.minimalistOpacity * 0.5),
                                lineWidth: level.minimalistBorderWidth
                            )
                    }
                    .shadow(
                        color: KingColors.trustPurple.opacity(0.1),
                        radius: level.minimalistShadowRadius,
                        x: 0,
                        y: level.minimalistShadowOffset
                    )
            }
    }
}

// MARK: - TrustGlassCard ViewModifier

/// 신뢰 글래스 카드 - 보안 및 중요 기능용
public struct TrustGlassCard: ViewModifier {
    let level: GlassTokens.EffectLevel
    let cornerRadius: CGFloat
    let showBorder: Bool
    
    public init(
        level: GlassTokens.EffectLevel = .prominent,
        cornerRadius: CGFloat = 16,
        showBorder: Bool = true
    ) {
        self.level = level
        self.cornerRadius = cornerRadius
        self.showBorder = showBorder
    }
    
    public func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                KingColors.glassCardBackground,
                                KingColors.glassTrustHighlight,
                                KingColors.glassCardBackground.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        if showBorder {
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .stroke(
                                    KingColors.trustPurple.opacity(level.minimalistOpacity),
                                    lineWidth: level.minimalistBorderWidth * 1.5
                                )
                        }
                    }
                    .shadow(
                        color: KingColors.trustPurple.opacity(0.15),
                        radius: level.minimalistShadowRadius * 1.2,
                        x: 0,
                        y: level.minimalistShadowOffset * 1.5
                    )
            }
    }
}

// MARK: - GoldAccentGlass ViewModifier

/// 골드 액센트 글래스 - 오직 중요한 요소에만 사용
public struct GoldAccentGlass: ViewModifier {
    let level: GlassTokens.EffectLevel
    let cornerRadius: CGFloat
    let intensity: Double
    
    public init(
        level: GlassTokens.EffectLevel = .intense,
        cornerRadius: CGFloat = 12,
        intensity: Double = 1.0
    ) {
        self.level = level
        self.cornerRadius = cornerRadius
        self.intensity = intensity
    }
    
    public func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                KingColors.premiumElevated,
                                KingColors.glassGoldHighlight.opacity(intensity * 0.6),
                                KingColors.premiumElevated.opacity(0.9)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                KingColors.exclusiveGold.opacity(level.minimalistOpacity * intensity),
                                lineWidth: level.minimalistBorderWidth * 1.2
                            )
                    }
                    .shadow(
                        color: KingColors.exclusiveGold.opacity(0.2 * intensity),
                        radius: level.minimalistShadowRadius * 1.5,
                        x: 0,
                        y: level.minimalistShadowOffset * 2
                    )
            }
    }
}

// MARK: - View Extensions

public extension View {
    
    /// 극도로 미니멀한 글래스 효과 적용
    func ultraMinimalGlass(
        level: GlassTokens.EffectLevel = .subtle,
        context: GlassTokens.Context = .card
    ) -> some View {
        modifier(UltraMinimalGlass(level: level, context: context))
    }
    
    /// 프리미엄 피나테크 글래스 효과 적용
    func premiumFinTechGlass(
        level: GlassTokens.EffectLevel = .standard,
        context: GlassTokens.Context = .card
    ) -> some View {
        modifier(PremiumFinTechGlass(level: level, context: context))
    }
    
    /// 신뢰 글래스 카드 효과 적용 - 보안 기능용
    func trustGlassCard(
        level: GlassTokens.EffectLevel = .prominent,
        cornerRadius: CGFloat = 16,
        showBorder: Bool = true
    ) -> some View {
        modifier(TrustGlassCard(level: level, cornerRadius: cornerRadius, showBorder: showBorder))
    }
    
    /// 골드 액센트 글래스 효과 - 중요 요소에만 사용
    func goldAccentGlass(
        level: GlassTokens.EffectLevel = .intense,
        cornerRadius: CGFloat = 12,
        intensity: Double = 1.0
    ) -> some View {
        modifier(GoldAccentGlass(level: level, cornerRadius: cornerRadius, intensity: intensity))
    }
}

// MARK: - Preview

#Preview("Minimalist Glass Components") {
    ScrollView {
        VStack(spacing: 24) {
            
            // Ultra Minimal Glass
            VStack(spacing: 8) {
                Text("Ultra Minimal Glass")
                    .font(.headline)
                    .foregroundColor(KingColors.textPrimary)
                
                Text("극도로 서브틀한 글래스 효과")
                    .font(.caption)
                    .foregroundColor(KingColors.textSecondary)
                    .padding()
                    .ultraMinimalGlass(level: .subtle)
            }
            
            // Premium FinTech Glass
            VStack(spacing: 8) {
                Text("Premium FinTech Glass")
                    .font(.headline)
                    .foregroundColor(KingColors.textPrimary)
                
                Text("신뢰감 있는 퍼플 힌트")
                    .font(.caption)
                    .foregroundColor(KingColors.textSecondary)
                    .padding()
                    .premiumFinTechGlass(level: .standard)
            }
            
            // Trust Glass Card
            VStack(spacing: 8) {
                Text("Trust Glass Card")
                    .font(.headline)
                    .foregroundColor(KingColors.textPrimary)
                
                Text("보안 및 중요 기능용")
                    .font(.caption)
                    .foregroundColor(KingColors.textSecondary)
                    .padding()
                    .trustGlassCard(level: .prominent)
            }
            
            // Gold Accent Glass (중요 요소만)
            VStack(spacing: 8) {
                Text("Gold Accent Glass")
                    .font(.headline)
                    .foregroundColor(KingColors.textGold)
                
                Text("오직 중요한 요소에만")
                    .font(.caption)
                    .foregroundColor(KingColors.textSecondary)
                    .padding()
                    .goldAccentGlass(level: .intense, intensity: 0.8)
            }
        }
        .padding()
    }
    .background(KingGradients.minimalistBackground)
}