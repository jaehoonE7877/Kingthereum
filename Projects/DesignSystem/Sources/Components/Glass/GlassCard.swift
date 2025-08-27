import SwiftUI
import Core

// GlassTokens는 같은 모듈 내에 있으므로 별도 import 불필요

/// 4단계 GlassMorphism 효과를 지원하는 Glass Card 컴포넌트
/// 효과 레벨과 테마에 따라 동적으로 스타일이 적용됨
public struct GlassCard<Content: View>: View {
    let content: Content
    let effectLevel: GlassTokens.EffectLevel
    let context: GlassTokens.Context
    let customCornerRadius: CGFloat?
    
    @Environment(\.glassTheme) private var theme
    @Environment(\.glassEffectLevel) private var environmentEffectLevel
    @Environment(\.colorScheme) private var colorScheme
    
    /// 효과 레벨을 명시적으로 지정하여 초기화
    public init(
        level: GlassTokens.EffectLevel,
        context: GlassTokens.Context = .card,
        cornerRadius: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.effectLevel = level
        self.context = context
        self.customCornerRadius = cornerRadius
    }
    
    /// 환경에서 효과 레벨을 상속받아 초기화
    public init(
        context: GlassTokens.Context = .card,
        cornerRadius: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.effectLevel = context.defaultEffectLevel
        self.context = context
        self.customCornerRadius = cornerRadius
    }
    
    public var body: some View {
        content
            .background(
                effectiveMaterial,
                in: RoundedRectangle(cornerRadius: effectiveCornerRadius)
            )
            .overlay(
                RoundedRectangle(cornerRadius: effectiveCornerRadius)
                    .stroke(effectiveBorderColor, lineWidth: effectiveBorderWidth)
            )
            .shadow(
                color: effectiveShadowColor,
                radius: effectiveShadowRadius,
                x: 0,
                y: effectiveShadowOffset
            )
    }
    
    // MARK: - Dynamic Properties
    
    /// 테마와 효과 레벨에 따른 Material 결정
    private var effectiveMaterial: Material {
        let baseMaterial = effectLevel.material
        
        switch theme {
        case .system:
            return baseMaterial
        case .light:
            return .regularMaterial
        case .dark:
            return .thickMaterial
        case .vibrant:
            return colorScheme == .dark ? .ultraThickMaterial : .thinMaterial
        }
    }
    
    /// 효과적인 코너 반경
    private var effectiveCornerRadius: CGFloat {
        customCornerRadius ?? context.defaultCornerRadius
    }
    
    /// 테마와 효과 레벨에 따른 테두리 색상
    private var effectiveBorderColor: Color {
        let adaptation = GlassTokens.ColorAdaptation.border
        let baseColor = KingColors.glassBorder
        
        switch theme {
        case .system:
            return baseColor.opacity(effectLevel.opacity * 0.5)
        case .light:
            return baseColor.opacity(adaptation.light)
        case .dark:
            return baseColor.opacity(adaptation.dark)
        case .vibrant:
            return baseColor.opacity(adaptation.vibrant)
        }
    }
    
    /// 효과 레벨에 따른 테두리 두께
    private var effectiveBorderWidth: CGFloat {
        effectLevel.borderWidth
    }
    
    /// 테마와 효과 레벨에 따른 그림자 색상
    private var effectiveShadowColor: Color {
        let adaptation = GlassTokens.ColorAdaptation.shadow
        let baseColor = KingColors.glassShadow
        
        switch theme {
        case .system:
            return baseColor.opacity(effectLevel.opacity * 0.3)
        case .light:
            return baseColor.opacity(adaptation.light)
        case .dark:
            return Color.black.opacity(adaptation.dark)
        case .vibrant:
            return baseColor.opacity(adaptation.vibrant)
        }
    }
    
    /// 효과 레벨에 따른 그림자 반경
    private var effectiveShadowRadius: CGFloat {
        let baseRadius = effectLevel.shadowRadius
        
        switch theme {
        case .system:
            return baseRadius
        case .light:
            return baseRadius * 0.7
        case .dark:
            return baseRadius * 1.2
        case .vibrant:
            return baseRadius * 1.5
        }
    }
    
    /// 효과 레벨에 따른 그림자 오프셋
    private var effectiveShadowOffset: CGFloat {
        effectLevel.shadowOffset
    }
}

// MARK: - Legacy GlassCardStyle (하위 호환성)

/// 기존 GlassCardStyle (하위 호환성을 위해 유지)
@available(*, deprecated, message: "Use GlassCard with GlassTokens.EffectLevel instead")
public struct GlassCardStyle: Sendable {
    public static let `default` = GlassCardStyle(
        material: .ultraThinMaterial,
        cornerRadius: Constants.UI.cornerRadius,
        borderColor: .glassBorderSecondary,
        borderWidth: 1,
        shadowColor: .glassShadowLight,
        shadowRadius: 8,
        shadowOffset: 4
    )
    
    public static let prominent = GlassCardStyle(
        material: .thickMaterial,
        cornerRadius: Constants.UI.cornerRadius,
        borderColor: .glassBorderPrimary,
        borderWidth: 1.2,
        shadowColor: .glassShadowMedium,
        shadowRadius: 16,
        shadowOffset: 8
    )
    
    public static let subtle = GlassCardStyle(
        material: .ultraThinMaterial,
        cornerRadius: Constants.UI.cornerRadius,
        borderColor: .glassBorderSecondary,
        borderWidth: 0.7,
        shadowColor: .glassShadowLight,
        shadowRadius: 6,
        shadowOffset: 3
    )
    
    public static let wallet = GlassCardStyle(
        material: .regularMaterial,
        cornerRadius: DesignTokens.CornerRadius.lg,
        borderColor: .glassBorderAccent,
        borderWidth: 1.1,
        shadowColor: .glassShadowMedium,
        shadowRadius: 14,
        shadowOffset: 7
    )
    
    public static let transaction = GlassCardStyle(
        material: .thinMaterial,
        cornerRadius: DesignTokens.CornerRadius.md,
        borderColor: .glassBorderSecondary,
        borderWidth: 0.6,
        shadowColor: .glassShadowLight,
        shadowRadius: 6,
        shadowOffset: 3
    )
    
    let material: Material
    let cornerRadius: CGFloat
    let borderColor: Color
    let borderWidth: CGFloat
    let shadowColor: Color
    let shadowRadius: CGFloat
    let shadowOffset: CGFloat
    
    public init(
        material: Material,
        cornerRadius: CGFloat, 
        borderColor: Color,
        borderWidth: CGFloat,
        shadowColor: Color,
        shadowRadius: CGFloat,
        shadowOffset: CGFloat
    ) {
        self.material = material
        self.cornerRadius = cornerRadius
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.shadowColor = shadowColor
        self.shadowRadius = shadowRadius
        self.shadowOffset = shadowOffset
    }
    
    /// GlassCardStyle을 EffectLevel로 변환
    var toEffectLevel: GlassTokens.EffectLevel {
        switch shadowRadius {
        case 0..<7: return .subtle
        case 7..<12: return .standard
        case 12..<18: return .prominent
        default: return .intense
        }
    }
}

/// 하위 호환성을 위한 레거시 GlassCard
@available(*, deprecated, message: "Use new GlassCard(level:context:) initializer")
public struct LegacyGlassCard<Content: View>: View {
    let content: Content
    let style: GlassCardStyle
    @Environment(\.glassTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    
    public init(
        style: GlassCardStyle = .default,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.style = style
    }
    
    public var body: some View {
        GlassCard(level: style.toEffectLevel, context: .card) {
            content
        }
    }
}

// MARK: - Convenience Extensions

public extension View {
    /// 새로운 4단계 Glass Card 적용 (권장)
    func glassCard(
        level: GlassTokens.EffectLevel,
        context: GlassTokens.Context = .card,
        cornerRadius: CGFloat? = nil
    ) -> some View {
        GlassCard(level: level, context: context, cornerRadius: cornerRadius) {
            self
        }
    }
    
    /// 하위 호환성을 위한 기존 방식 (deprecated)
    @available(*, deprecated, message: "Use glassCard(level:context:) instead")
    func glassCard(style: GlassCardStyle = .default) -> some View {
        LegacyGlassCard(style: style) {
            self
        }
    }
    
    /// 컨텍스트 기반 기본 Glass Card
    func glassCard(context: GlassTokens.Context = .card) -> some View {
        GlassCard(context: context) {
            self
        }
    }
}

// MARK: - Specialized Glass Cards

/// 잔액 표시 전용 카드
public struct BalanceCard: View {
    let balance: String
    let symbol: String
    let usdValue: String?
    
    public init(balance: String, symbol: String, usdValue: String? = nil) {
        self.balance = balance
        self.symbol = symbol
        self.usdValue = usdValue
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "wallet.pass.fill")
                    .font(.title2)
                    .foregroundStyle(LinearGradient.primaryGradient)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(balance)
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text(symbol)
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                
                if let usdValue = usdValue {
                    Text(usdValue)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(DesignTokens.Spacing.lg)
        .glassCard(level: .prominent, context: .card)
    }
}

/// 거래 내역 전용 카드
public struct TransactionCard: View {
    let type: TransactionType
    let amount: String
    let symbol: String
    let timestamp: String
    let status: TransactionStatus
    
    public enum TransactionType {
        case send, receive
        
        var icon: String {
            switch self {
            case .send: return "arrow.up.circle.fill"
            case .receive: return "arrow.down.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .send: return .systemRed
            case .receive: return .systemGreen
            }
        }
    }
    
    public enum TransactionStatus {
        case pending, confirmed, failed
        
        var icon: String {
            switch self {
            case .pending: return "clock.fill"
            case .confirmed: return "checkmark.circle.fill"
            case .failed: return "xmark.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .pending: return .systemOrange
            case .confirmed: return .systemGreen
            case .failed: return .systemRed
            }
        }
    }
    
    public init(type: TransactionType, amount: String, symbol: String, timestamp: String, status: TransactionStatus) {
        self.type = type
        self.amount = amount
        self.symbol = symbol
        self.timestamp = timestamp
        self.status = status
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .font(.title2)
                .foregroundColor(type.color)
                .frame(width: DesignTokens.Size.Icon.lg, height: DesignTokens.Size.Icon.lg)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("\(type == .send ? "-" : "+")\(amount) \(symbol)")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(type.color)
                    
                    Spacer()
                    
                    Image(systemName: status.icon)
                        .font(.caption)
                        .foregroundColor(status.color)
                }
                
                Text(timestamp)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .glassCard(level: .subtle, context: .card)
    }
}

/// 액션 버튼 그룹 카드
public struct ActionCard: View {
    let title: String
    let actions: [ActionItem]
    
    public struct ActionItem {
        let icon: String
        let title: String
        let action: () -> Void
        
        public init(icon: String, title: String, action: @escaping () -> Void) {
            self.icon = icon
            self.title = title
            self.action = action
        }
    }
    
    public init(title: String, actions: [ActionItem]) {
        self.title = title
        self.actions = actions
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: min(actions.count, 3)), spacing: 12) {
                ForEach(actions.indices, id: \.self) { index in
                    let action = actions[index]
                    Button(action: action.action) {
                        VStack(spacing: 8) {
                            Image(systemName: action.icon)
                                .font(.title2)
                                .foregroundStyle(LinearGradient.primaryGradient)
                            Text(action.title)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignTokens.Spacing.md)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .glassCard(level: .standard, context: .card)
    }
}

/// 정보 표시 카드
public struct InfoCard: View {
    let icon: String
    let title: String
    let subtitle: String?
    let value: String
    let style: InfoCardStyle
    
    public enum InfoCardStyle {
        case `default`, success, warning, error
        
        var iconColor: Color {
            switch self {
            case .default: return .kingBlue
            case .success: return .systemGreen
            case .warning: return .systemOrange
            case .error: return .systemRed
            }
        }
    }
    
    public init(icon: String, title: String, subtitle: String? = nil, value: String, style: InfoCardStyle = .default) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.style = style
    }
    
    public var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(style.iconColor)
                .frame(width: DesignTokens.Size.Icon.lg, height: DesignTokens.Size.Icon.lg)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(DesignTokens.Spacing.lg)
        .glassCard(level: .subtle, context: .card)
    }
}

#Preview("Default Theme") {
    ScrollView {
        VStack(spacing: 20) {
            BalanceCard(balance: "2.5", symbol: "ETH", usdValue: "$4,250.00")
            
            TransactionCard(
                type: .receive,
                amount: "0.5",
                symbol: "ETH",
                timestamp: "5분 전",
                status: .confirmed
            )
            
            ActionCard(title: "빠른 액션", actions: [
                .init(icon: "arrow.up.circle.fill", title: "송금") { },
                .init(icon: "arrow.down.circle.fill", title: "수신") { },
                .init(icon: "qrcode", title: "QR코드") { }
            ])
        }
        .padding()
    }
    .background(
        LinearGradient(
            colors: [.systemBlue, .systemPurple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
    .environment(\.glassTheme, .system)
}

#Preview("Vibrant Theme") {
    ScrollView {
        VStack(spacing: 20) {
            BalanceCard(balance: "2.5", symbol: "ETH", usdValue: "$4,250.00")
            
            TransactionCard(
                type: .send,
                amount: "1.2",
                symbol: "ETH",
                timestamp: "방금 전",
                status: .pending
            )
            
            InfoCard(
                icon: "network",
                title: "네트워크",
                subtitle: "이더리움 메인넷",
                value: "ETH",
                style: .success
            )
        }
        .padding()
    }
    .background(
        LinearGradient(
            colors: [.systemPink, .systemOrange],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
    .environment(\.glassTheme, .vibrant)
}

#Preview("Dark Theme") {
    ScrollView {
        VStack(spacing: 20) {
            BalanceCard(balance: "2.5", symbol: "ETH", usdValue: "$4,250.00")
            
            TransactionCard(
                type: .receive,
                amount: "0.5",
                symbol: "ETH",
                timestamp: "5분 전",
                status: .confirmed
            )
        }
        .padding()
    }
    .background(Color.black)
    .preferredColorScheme(.dark)
    .environment(\.glassTheme, .dark)
}
