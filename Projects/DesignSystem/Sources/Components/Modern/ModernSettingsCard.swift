import SwiftUI

/// 모던 설정 카드 컴포넌트
/// KingColors와 그라데이션을 활용한 세련된 설정 그룹 표시
public struct ModernSettingsCard<Content: View>: View {
    let title: String?
    let content: Content
    let style: ModernCardStyle
    
    public init(
        title: String? = nil,
        style: ModernCardStyle = .default,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.content = content()
        self.style = style
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            // 타이틀 (옵셔널)
            if let title = title {
                Text(title)
                    .kingStyle(.cardTitle)
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.top, DesignTokens.Spacing.sm)
            }
            
            // 컨텐츠
            VStack(spacing: 0) {
                content
            }
        }
        .background(backgroundStyle)
        .clipShape(RoundedRectangle(cornerRadius: style.cornerRadius))
        .overlay(borderOverlay)
        .shadow(color: style.shadowColor, radius: style.shadowRadius, x: 0, y: style.shadowY)
    }
    
    @ViewBuilder
    private var backgroundStyle: some View {
        switch style.backgroundType {
        case .solid:
            KingColors.cardBackground
        case .gradient:
            KingGradients.card
        case .elevated:
            KingGradients.cardElevated
        case .glass:
            KingGradients.cardGlass
        }
    }
    
    @ViewBuilder
    private var borderOverlay: some View {
        if style.showBorder {
            RoundedRectangle(cornerRadius: style.cornerRadius)
                .stroke(KingColors.cardBorder, lineWidth: DesignTokens.BorderWidth.normal)
        }
    }
}

// MARK: - Modern Card Style
public struct ModernCardStyle: Sendable {
    let backgroundType: BackgroundType
    let cornerRadius: CGFloat
    let showBorder: Bool
    let shadowColor: Color
    let shadowRadius: CGFloat
    let shadowY: CGFloat
    
    public enum BackgroundType: Sendable {
        case solid
        case gradient
        case elevated
        case glass
    }
    
    public init(
        backgroundType: BackgroundType = .gradient,
        cornerRadius: CGFloat = DesignTokens.CornerRadius.lg,
        showBorder: Bool = true,
        shadowColor: Color = KingColors.cardShadow,
        shadowRadius: CGFloat = 6,
        shadowY: CGFloat = 3
    ) {
        self.backgroundType = backgroundType
        self.cornerRadius = cornerRadius
        self.showBorder = showBorder
        self.shadowColor = shadowColor
        self.shadowRadius = shadowRadius
        self.shadowY = shadowY
    }
    
    // MARK: - Predefined Styles
    
    public static let `default` = ModernCardStyle()
    
    public static let elevated = ModernCardStyle(
        backgroundType: .elevated,
        shadowRadius: 8,
        shadowY: 4
    )
    
    public static let glass = ModernCardStyle(
        backgroundType: .glass,
        showBorder: false,
        shadowRadius: 12,
        shadowY: 6
    )
    
    public static let minimal = ModernCardStyle(
        backgroundType: .solid,
        showBorder: false,
        shadowRadius: 2,
        shadowY: 1
    )
}

// MARK: - Modern Settings Row
public struct ModernSettingsRow: View {
    let item: SettingsItem
    
    public init(_ item: SettingsItem) {
        self.item = item
    }
    
    public var body: some View {
        Button(action: {
            item.action?()
        }) {
            HStack(spacing: DesignTokens.Spacing.md) {
                // 아이콘
                iconView
                
                // 컨텐츠
                contentView
                
                Spacer()
                
                // 트레일링
                trailingView
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)
        }
        .buttonStyle(ModernRowButtonStyle())
    }
    
    @ViewBuilder
    private var iconView: some View {
        if let iconName = item.iconName {
            Group {
                if item.iconType == .system {
                    Image(systemName: iconName)
                } else {
                    Image(iconName)
                }
            }
            .font(.system(size: 18, weight: .medium))
            .foregroundColor(item.iconColor ?? KingColors.accent)
            .frame(width: 24, height: 24)
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(item.title)
                .kingStyle(.listTitle)
            
            if let subtitle = item.subtitle {
                Text(subtitle)
                    .kingStyle(.listSubtitle)
            }
        }
    }
    
    @ViewBuilder
    private var trailingView: some View {
        switch item.type {
        case .navigation:
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(KingColors.textTertiary)
        
        case .toggle(let binding):
            Toggle("", isOn: binding)
                .labelsHidden()
                .scaleEffect(0.8)
        
        case .value(let text):
            Text(text)
                .kingStyle(.listSubtitle)
        
        case .badge(let text, let color):
            Text(text)
                .kingStyle(KingTextStyle(
                    font: KingTypography.labelSmall,
                    color: KingColors.textInverse
                ))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color ?? KingColors.accent)
                )
        
        case .icon(let iconName):
            Image(systemName: iconName)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(KingColors.textTertiary)
        
        case .none:
            EmptyView()
        }
    }
}

// MARK: - Settings Item Model
public struct SettingsItem: Identifiable {
    public let id = UUID()
    public let title: String
    public let subtitle: String?
    public let iconName: String?
    public let iconColor: Color?
    public let iconType: IconType
    public let type: RowType
    public let action: (() -> Void)?
    
    public enum IconType {
        case system
        case custom
    }
    
    public enum RowType {
        case navigation
        case toggle(Binding<Bool>)
        case value(String)
        case badge(String, Color?)
        case icon(String)
        case none
    }
    
    public init(
        title: String,
        subtitle: String? = nil,
        iconName: String? = nil,
        iconColor: Color? = nil,
        iconType: IconType = .system,
        type: RowType = .navigation,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.iconColor = iconColor
        self.iconType = iconType
        self.type = type
        self.action = action
    }
}

// MARK: - Modern Row Button Style
struct ModernRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                    .fill(
                        configuration.isPressed
                            ? KingColors.accent.opacity(0.1)
                            : Color.clear
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: DesignTokens.Duration.fast), value: configuration.isPressed)
    }
}

// MARK: - Convenience Functions

/// 여러 설정 아이템을 자동으로 구분선과 함께 표시하는 ModernSettingsCard
@MainActor
public func ModernSettingsCardWithItems(
    title: String? = nil,
    style: ModernCardStyle = .default,
    items: [SettingsItem]
) -> some View {
    ModernSettingsCard(title: title, style: style) {
        ForEach(items.indices, id: \.self) { index in
            ModernSettingsRow(items[index])
            
            // 마지막 아이템이 아니면 구분선 추가
            if index < items.count - 1 {
                Divider()
                    .background(KingColors.separator)
                    .padding(.leading, DesignTokens.Spacing.md)
            }
        }
    }
}

// MARK: - Preview Support
#Preview("Modern Settings Components") {
    ScrollView {
        VStack(spacing: DesignTokens.Spacing.xl) {
            // Profile Card
            ModernSettingsCard(title: "프로필") {
                ModernSettingsRow(SettingsItem(
                    title: "Kingthereum Wallet",
                    subtitle: "0x7b...3020 • 계정보기",
                    iconName: "person.crop.circle.fill",
                    iconColor: KingColors.accent,
                    type: .navigation
                ) {
                    print("Profile tapped")
                })
            }
            
            // Display Card with Multiple Items
            ModernSettingsCardWithItems(
                title: "디스플레이",
                items: [
                    SettingsItem(
                        title: "화면 모드",
                        subtitle: "시스템 설정에 따라 자동으로 전환",
                        iconName: "moon.circle.fill",
                        iconColor: KingColors.accentSecondary,
                        type: .value("시스템")
                    ) {
                        print("Display mode tapped")
                    },
                    SettingsItem(
                        title: "글자 크기",
                        iconName: "textformat.size",
                        iconColor: KingColors.info,
                        type: .navigation
                    ) {
                        print("Font size tapped")
                    }
                ]
            )
            
            // General Settings
            ModernSettingsCardWithItems(
                title: "일반",
                style: .elevated,
                items: [
                    SettingsItem(
                        title: "알림",
                        subtitle: "새로운 트랜잭션 및 보안 알림 수신",
                        iconName: "bell.circle.fill",
                        iconColor: KingColors.warning,
                        type: .toggle(.constant(true))
                    ),
                    SettingsItem(
                        title: "보안",
                        subtitle: "PIN, 생체인증 및 백업 설정",
                        iconName: "lock.circle.fill",
                        iconColor: KingColors.success,
                        type: .badge("활성화됨", KingColors.success)
                    ) {
                        print("Security tapped")
                    },
                    SettingsItem(
                        title: "네트워크",
                        subtitle: "이더리움 메인넷에 연결됨",
                        iconName: "network",
                        iconColor: KingColors.ethereum,
                        type: .navigation
                    ) {
                        print("Network tapped")
                    }
                ]
            )
            
            // Language Settings (Glass Style)
            ModernSettingsCard(title: "언어", style: .glass) {
                ModernSettingsRow(SettingsItem(
                    title: "한국어",
                    subtitle: "시스템 언어",
                    iconName: "globe.circle.fill",
                    iconColor: KingColors.accent,
                    type: .navigation
                ) {
                    print("Language tapped")
                })
            }
        }
        .padding()
    }
    .background(KingColors.backgroundPrimary)
}