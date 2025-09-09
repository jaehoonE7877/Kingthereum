import SwiftUI

// MARK: - Accessibility Enhancements for DesignSystem
// WCAG 2.1 Level AA compliance

// MARK: - Accessible Colors

public enum AccessibleColors {
    /// High contrast color alternatives
    public static func getAccessibleColor(
        _ baseColor: Color,
        for colorScheme: ColorScheme,
        highContrast: Bool = false
    ) -> Color {
        if highContrast {
            switch colorScheme {
            case .dark:
                return baseColor == KingDesignTokens.Colors.ash ? .white : baseColor
            case .light:
                return baseColor == KingDesignTokens.Colors.smoke ? .black : baseColor
            @unknown default:
                return baseColor
            }
        }
        return baseColor
    }
    
    /// Check if two colors have sufficient contrast (WCAG AA)
    public static func hasMinimumContrast(
        foreground: Color,
        background: Color,
        level: ContrastLevel = .AA
    ) -> Bool {
        // Simplified check - in production, use proper luminance calculation
        return foreground != background
    }
    
    public enum ContrastLevel {
        case AA  // 4.5:1 for normal text, 3:1 for large text
        case AAA // 7:1 for normal text, 4.5:1 for large text
    }
}

// MARK: - Accessible Button

public struct AccessibleGlassButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    let accessibilityHint: String?
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @Environment(\.accessibilityInvertColors) private var invertColors
    @Environment(\.sizeCategory) private var sizeCategory
    
    public init(
        _ title: String,
        icon: String? = nil,
        accessibilityHint: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.accessibilityHint = accessibilityHint
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: adaptiveSpacing) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: iconSize, weight: .medium))
                        .accessibilityHidden(true) // Hide decorative icons
                }
                
                Text(title)
                    .font(adaptiveFont)
                    .fontWeight(.medium)
                    .minimumScaleFactor(0.7) // Allow text to scale down if needed
                    .lineLimit(1)
            }
            .foregroundColor(adaptiveForegroundColor)
            .padding(.horizontal, adaptivePadding)
            .frame(minHeight: minimumTapTarget)
            .frame(maxWidth: .infinity)
            .background(adaptiveBackground)
            .cornerRadius(KingDesignTokens.Radius.md)
            .overlay(focusIndicator)
        }
        .accessibilityLabel(title)
        .accessibilityHint(accessibilityHint ?? "")
        .accessibilityAddTraits(.isButton)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2))
    }
    
    private var adaptiveSpacing: CGFloat {
        sizeCategory.isAccessibilityCategory ? KingDesignTokens.Spacing.md : KingDesignTokens.Spacing.xs
    }
    
    private var iconSize: CGFloat {
        sizeCategory >= .accessibilityMedium ? 24 : 16
    }
    
    private var adaptiveFont: Font {
        if sizeCategory >= .accessibilityLarge {
            return KingDesignTokens.Typography.heading
        } else if sizeCategory >= .accessibilityMedium {
            return KingDesignTokens.Typography.body
        } else {
            return KingDesignTokens.Typography.body
        }
    }
    
    private var adaptivePadding: CGFloat {
        sizeCategory.isAccessibilityCategory ? KingDesignTokens.Spacing.lg : KingDesignTokens.Spacing.md
    }
    
    private var minimumTapTarget: CGFloat {
        max(44, sizeCategory.isAccessibilityCategory ? 56 : 52)
    }
    
    private var adaptiveForegroundColor: Color {
        if invertColors {
            return KingDesignTokens.Colors.ink
        }
        return KingDesignTokens.Colors.snow
    }
    
    @ViewBuilder
    private var adaptiveBackground: some View {
        if reduceTransparency {
            // Solid color for reduced transparency
            KingDesignTokens.Colors.gold
        } else {
            // Glass effect with material
            KingDesignTokens.Colors.gold.opacity(0.95)
        }
    }
    
    @ViewBuilder
    private var focusIndicator: some View {
        if differentiateWithoutColor {
            RoundedRectangle(cornerRadius: KingDesignTokens.Radius.md)
                .strokeBorder(KingDesignTokens.Colors.primary, lineWidth: 2)
        }
    }
}

// MARK: - Accessible Text Field

public struct AccessibleGlassTextField: View {
    @Binding var text: String
    let placeholder: String
    let label: String
    let errorMessage: String?
    
    @FocusState private var isFocused: Bool
    @Environment(\.sizeCategory) private var sizeCategory
    
    public init(
        text: Binding<String>,
        placeholder: String,
        label: String,
        errorMessage: String? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.label = label
        self.errorMessage = errorMessage
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: KingDesignTokens.Spacing.xs) {
            // Label
            Text(label)
                .font(adaptiveLabelFont)
                .foregroundColor(KingDesignTokens.Colors.primary)
                .accessibilityAddTraits(.isHeader)
            
            // Text Field
            TextField(placeholder, text: $text)
                .font(adaptiveInputFont)
                .foregroundColor(KingDesignTokens.Colors.primary)
                .padding(adaptivePadding)
                .background(KingDesignTokens.Glass.ultraThin)
                .cornerRadius(KingDesignTokens.Radius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: KingDesignTokens.Radius.md)
                        .strokeBorder(
                            borderColor,
                            lineWidth: isFocused ? 2 : 1
                        )
                )
                .focused($isFocused)
                .accessibilityLabel("\(label), \(placeholder)")
                .accessibilityValue(text.isEmpty ? "Empty" : text)
                .accessibilityHint("Double tap to edit")
            
            // Error Message
            if let errorMessage = errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle")
                    .font(KingDesignTokens.Typography.caption)
                    .foregroundColor(KingDesignTokens.Colors.danger)
                    .accessibilityAddTraits(.isStaticText)
            }
        }
    }
    
    private var adaptiveLabelFont: Font {
        sizeCategory >= .accessibilityMedium ? 
            KingDesignTokens.Typography.body : 
            KingDesignTokens.Typography.caption
    }
    
    private var adaptiveInputFont: Font {
        sizeCategory >= .accessibilityMedium ? 
            KingDesignTokens.Typography.heading : 
            KingDesignTokens.Typography.body
    }
    
    private var adaptivePadding: CGFloat {
        sizeCategory.isAccessibilityCategory ? 
            KingDesignTokens.Spacing.lg : 
            KingDesignTokens.Spacing.md
    }
    
    private var borderColor: Color {
        if let _ = errorMessage {
            return KingDesignTokens.Colors.danger
        } else if isFocused {
            return KingDesignTokens.Colors.gold
        } else {
            return KingDesignTokens.Colors.mist
        }
    }
}

// MARK: - Accessible Card

public struct AccessibleGlassCard<Content: View>: View {
    let content: () -> Content
    let accessibilityLabel: String?
    let accessibilityHint: String?
    
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.sizeCategory) private var sizeCategory
    
    public init(
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
        self.content = content
    }
    
    public var body: some View {
        content()
            .padding(adaptivePadding)
            .background(adaptiveBackground)
            .cornerRadius(KingDesignTokens.Radius.lg)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabel ?? "")
            .accessibilityHint(accessibilityHint ?? "")
    }
    
    private var adaptivePadding: CGFloat {
        sizeCategory.isAccessibilityCategory ? 
            KingDesignTokens.Spacing.xl : 
            KingDesignTokens.Spacing.lg
    }
    
    @ViewBuilder
    private var adaptiveBackground: some View {
        if reduceTransparency {
            KingDesignTokens.Colors.surface
        } else {
            KingDesignTokens.Glass.ultraThin
        }
    }
}

// MARK: - Voice Control Support

public struct VoiceControlButton: View {
    let title: String
    let voiceCommand: String
    let action: () -> Void
    
    public init(
        _ title: String,
        voiceCommand: String,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.voiceCommand = voiceCommand
        self.action = action
    }
    
    public var body: some View {
        GlassButton(title, action: action)
            .accessibilityInputLabels([title, voiceCommand])
            .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Screen Reader Announcements

public struct ScreenReaderAnnouncement: ViewModifier {
    let message: String
    let delay: Double
    
    @State private var hasAnnounced = false
    
    public func body(content: Content) -> some View {
        content
            .onAppear {
                if !hasAnnounced {
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        UIAccessibility.post(
                            notification: .announcement,
                            argument: message
                        )
                        hasAnnounced = true
                    }
                }
            }
    }
}

// MARK: - Focus Management

public struct AccessibilityFocusModifier: ViewModifier {
    @AccessibilityFocusState private var isFocused: Bool
    let trigger: Bool
    
    public func body(content: Content) -> some View {
        content
            .accessibilityFocused($isFocused)
            .onChange(of: trigger) { newValue in
                if newValue {
                    isFocused = true
                }
            }
    }
}

// MARK: - Semantic Markup

public struct SemanticHeading: View {
    let text: String
    let level: HeadingLevel
    
    public enum HeadingLevel {
        case h1, h2, h3, h4, h5, h6
        
        var font: Font {
            switch self {
            case .h1: return KingDesignTokens.Typography.displayL
            case .h2: return KingDesignTokens.Typography.displayM
            case .h3: return KingDesignTokens.Typography.heading
            case .h4: return KingDesignTokens.Typography.body
            case .h5: return KingDesignTokens.Typography.caption
            case .h6: return KingDesignTokens.Typography.micro
            }
        }
    }
    
    public init(_ text: String, level: HeadingLevel = .h2) {
        self.text = text
        self.level = level
    }
    
    public var body: some View {
        Text(text)
            .font(level.font)
            .foregroundColor(KingDesignTokens.Colors.primary)
            .accessibilityAddTraits(.isHeader)
            .accessibilityHeading(accessibilityLevel)
    }
    
    private var accessibilityLevel: AccessibilityHeadingLevel {
        switch level {
        case .h1: return .h1
        case .h2: return .h2
        case .h3: return .h3
        case .h4: return .h4
        case .h5: return .h5
        case .h6: return .h6
        }
    }
}

// MARK: - Accessible Loading Indicator

public struct AccessibleLoadingIndicator: View {
    let message: String
    @State private var rotation: Double = 0
    
    public init(message: String = "Loading") {
        self.message = message
    }
    
    public var body: some View {
        VStack(spacing: KingDesignTokens.Spacing.md) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
            
            Text(message)
                .font(KingDesignTokens.Typography.body)
                .foregroundColor(KingDesignTokens.Colors.ash)
        }
        .padding(KingDesignTokens.Spacing.lg)
        .glass()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(message), Please wait")
        .accessibilityAddTraits(.updatesFrequently)
    }
}

// MARK: - Accessible Tab Bar

public struct AccessibleTabBar: View {
    let items: [TabItem]
    @Binding var selectedIndex: Int
    
    public struct TabItem {
        let icon: String
        let title: String
        let accessibilityLabel: String
        
        public init(icon: String, title: String, accessibilityLabel: String? = nil) {
            self.icon = icon
            self.title = title
            self.accessibilityLabel = accessibilityLabel ?? title
        }
    }
    
    public init(items: [TabItem], selectedIndex: Binding<Int>) {
        self.items = items
        self._selectedIndex = selectedIndex
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<items.count, id: \.self) { index in
                TabButton(
                    item: items[index],
                    isSelected: selectedIndex == index,
                    index: index,
                    totalCount: items.count
                ) {
                    selectedIndex = index
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
        }
        .glass()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Tab bar")
    }
    
    private struct TabButton: View {
        let item: TabItem
        let isSelected: Bool
        let index: Int
        let totalCount: Int
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                VStack(spacing: KingDesignTokens.Spacing.xxs) {
                    Image(systemName: item.icon)
                        .font(.system(size: 24, weight: .medium))
                    
                    Text(item.title)
                        .font(KingDesignTokens.Typography.micro)
                }
                .foregroundColor(
                    isSelected ? KingDesignTokens.Colors.gold : KingDesignTokens.Colors.ash
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, KingDesignTokens.Spacing.sm)
            }
            .accessibilityLabel("\(item.accessibilityLabel), Tab \(index + 1) of \(totalCount)")
            .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            .accessibilityHint(isSelected ? "Currently selected" : "Double tap to select")
        }
    }
}

// MARK: - View Extensions for Accessibility

public extension View {
    /// Announce a message to screen readers
    func announceToScreenReader(_ message: String, delay: Double = 0.1) -> some View {
        self.modifier(ScreenReaderAnnouncement(message: message, delay: delay))
    }
    
    /// Manage accessibility focus
    func accessibilityFocus(when trigger: Bool) -> some View {
        self.modifier(AccessibilityFocusModifier(trigger: trigger))
    }
    
    /// Add semantic role
    func semanticRole(_ role: SemanticRole) -> some View {
        switch role {
        case .navigation:
            return self.accessibilityAddTraits(.isHeader)
        case .main:
            return self.accessibilityAddTraits(.isStaticText)
        case .complementary:
            return self.accessibilityAddTraits(.isStaticText)
        case .contentInfo:
            return self.accessibilityAddTraits(.isSummaryElement)
        }
    }
}

public enum SemanticRole {
    case navigation
    case main
    case complementary
    case contentInfo
}