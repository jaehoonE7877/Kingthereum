import SwiftUI

// MARK: - Premium Card Component with Glassmorphism
public struct KingCard<Content: View>: View {
    public enum Style {
        case elevated    // 그림자 있는 카드
        case flat       // 플랫 카드
        case glass      // 글래스모피즘 카드
        case outlined   // 테두리 카드
    }
    
    public enum Size {
        case compact    // 작은 카드
        case regular    // 기본 크기
        case expanded   // 큰 카드
        
        var padding: CGFloat {
            switch self {
            case .compact: return KingDesignTokens.Spacing.sm
            case .regular: return KingDesignTokens.Spacing.m
            case .expanded: return KingDesignTokens.Spacing.lg
            }
        }
        
        var cornerRadius: CGFloat {
            switch self {
            case .compact: return KingDesignTokens.Radius.sm
            case .regular: return KingDesignTokens.Radius.md
            case .expanded: return KingDesignTokens.Radius.lg
            }
        }
    }
    
    let style: Style
    let size: Size
    let isInteractive: Bool
    let content: () -> Content
    
    @State private var isPressed = false
    
    public init(
        style: Style = .elevated,
        size: Size = .regular,
        isInteractive: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.style = style
        self.size = size
        self.isInteractive = isInteractive
        self.content = content
    }
    
    public var body: some View {
        content()
            .padding(size.padding)
            .frame(maxWidth: .infinity)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius))
            .overlay(cardOverlay)
            .shadow(cardShadow)
            .scaleEffect(isPressed && isInteractive ? 0.98 : 1.0)
            .animation(KingDesignTokens.Animation.fast, value: isPressed)
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(isInteractive ? .isButton : [])
            .onTapGesture {
                guard isInteractive else { return }
                withAnimation(KingDesignTokens.Animation.fast) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                }
            }
    }
    
    @ViewBuilder
    private var cardBackground: some View {
        switch style {
        case .elevated, .flat, .outlined:
            KingDesignTokens.Colors.surface
        case .glass:
            Rectangle()
                .fill(.clear)
                .background(KingDesignTokens.Glass.ultraThin)
        }
    }
    
    @ViewBuilder
    private var cardOverlay: some View {
        switch style {
        case .outlined:
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .stroke(KingDesignTokens.Colors.border, lineWidth: KingDesignTokens.BorderWidth.thin)
        case .glass:
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .stroke(KingDesignTokens.Colors.outline, lineWidth: KingDesignTokens.BorderWidth.hairline)
        default:
            EmptyView()
        }
    }
    
    private var cardShadow: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        switch style {
        case .elevated:
            return KingDesignTokens.Shadow.md
        case .glass:
            return KingDesignTokens.Shadow.sm
        default:
            return (color: Color.clear, radius: 0, x: 0, y: 0)
        }
    }
}

// MARK: - Info Card (특수 목적)
public struct KingInfoCard: View {
    let title: String
    let subtitle: String?
    let icon: String?
    let style: KingCard<AnyView>.Style
    
    public init(
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        style: KingCard<AnyView>.Style = .elevated
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.style = style
    }
    
    public var body: some View {
        KingCard(style: style) {
            AnyView(
                HStack(spacing: KingDesignTokens.Spacing.m) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: KingDesignTokens.Sizing.iconMD))
                            .foregroundColor(KingDesignTokens.Colors.primary)
                            .frame(width: KingDesignTokens.Sizing.iconLG, height: KingDesignTokens.Sizing.iconLG)
                            .background(KingDesignTokens.Colors.primary.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    VStack(alignment: .leading, spacing: KingDesignTokens.Spacing.xxs) {
                        Text(title)
                            .font(KingDesignTokens.Typography.body)
                            .foregroundColor(KingDesignTokens.Colors.primaryText)
                            .lineLimit(1)
                        
                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(KingDesignTokens.Typography.caption)
                                .foregroundColor(KingDesignTokens.Colors.secondaryText)
                                .lineLimit(2)
                        }
                    }
                    
                    Spacer()
                }
            )
        }
    }
}

// MARK: - Balance Card (잔액 표시용)
public struct KingBalanceCard: View {
    let title: String
    let balance: String
    let subtitle: String?
    let trend: Double? // 퍼센트 변화량
    
    public init(
        title: String,
        balance: String,
        subtitle: String? = nil,
        trend: Double? = nil
    ) {
        self.title = title
        self.balance = balance
        self.subtitle = subtitle
        self.trend = trend
    }
    
    public var body: some View {
        KingCard(style: .glass, size: .expanded) {
            VStack(alignment: .leading, spacing: KingDesignTokens.Spacing.m) {
                // Title
                Text(title)
                    .font(KingDesignTokens.Typography.caption)
                    .foregroundColor(KingDesignTokens.Colors.secondaryText)
                
                // Balance
                Text(balance)
                    .font(KingDesignTokens.Typography.displayL)
                    .foregroundColor(KingDesignTokens.Colors.primaryText)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                
                // Bottom Row
                HStack {
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(KingDesignTokens.Typography.micro)
                            .foregroundColor(KingDesignTokens.Colors.tertiaryText)
                    }
                    
                    Spacer()
                    
                    if let trend = trend {
                        HStack(spacing: KingDesignTokens.Spacing.xxs) {
                            Image(systemName: trend >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.system(size: 12))
                            Text("\(abs(trend), specifier: "%.2f")%")
                                .font(KingDesignTokens.Typography.micro)
                        }
                        .foregroundColor(trend >= 0 ? KingDesignTokens.Colors.success : KingDesignTokens.Colors.error)
                    }
                }
            }
        }
        .accessibilityLabel("\(title): \(balance)")
        .accessibilityHint(subtitle ?? "")
    }
}

// MARK: - Preview
#Preview("KingCard Variants") {
    ScrollView {
        VStack(spacing: KingDesignTokens.Spacing.lg) {
            // Style Variants
            Group {
                KingCard(style: .elevated) {
                    Text("Elevated Card")
                        .foregroundColor(KingDesignTokens.Colors.primaryText)
                }
                
                KingCard(style: .flat) {
                    Text("Flat Card")
                        .foregroundColor(KingDesignTokens.Colors.primaryText)
                }
                
                KingCard(style: .glass) {
                    Text("Glass Card")
                        .foregroundColor(KingDesignTokens.Colors.primaryText)
                }
                
                KingCard(style: .outlined) {
                    Text("Outlined Card")
                        .foregroundColor(KingDesignTokens.Colors.primaryText)
                }
            }
            
            // Size Variants
            Group {
                KingCard(size: .compact) {
                    Text("Compact Card")
                        .foregroundColor(KingDesignTokens.Colors.primaryText)
                }
                
                KingCard(size: .expanded) {
                    Text("Expanded Card")
                        .foregroundColor(KingDesignTokens.Colors.primaryText)
                }
            }
            
            // Interactive Card
            KingCard(style: .glass, isInteractive: true) {
                HStack {
                    Image(systemName: "hand.tap.fill")
                    Text("Tap me!")
                }
                .foregroundColor(KingDesignTokens.Colors.primary)
            }
            
            // Info Card
            KingInfoCard(
                title: "Security Alert",
                subtitle: "Your wallet is protected with biometric authentication",
                icon: "shield.fill",
                style: .glass
            )
            
            // Balance Card
            KingBalanceCard(
                title: "Total Balance",
                balance: "$12,345.67",
                subtitle: "≈ 0.45 ETH",
                trend: 5.23
            )
        }
        .padding()
    }
    .background(KingDesignTokens.Colors.background)
}