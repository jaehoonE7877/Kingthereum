import SwiftUI

// MARK: - Premium Button Component
public struct KingButton: View {
    public enum Style {
        case primary    // Gold - 중요 액션
        case secondary  // Ghost - 보조 액션
        case danger     // Red - 위험 액션
    }
    
    public enum Size {
        case small
        case medium
        case large
        
        var verticalPadding: CGFloat {
            switch self {
            case .small: return 10
            case .medium: return 14
            case .large: return 18
            }
        }
        
        var horizontalPadding: CGFloat {
            switch self {
            case .small: return 16
            case .medium: return 24
            case .large: return 32
            }
        }
        
        var font: Font {
            switch self {
            case .small: return KingDesignTokens.Typography.caption
            case .medium: return KingDesignTokens.Typography.body
            case .large: return KingDesignTokens.Typography.heading
            }
        }
    }
    
    let title: String
    let style: Style
    let size: Size
    let isLoading: Bool
    let action: () -> Void
    
    public init(
        _ title: String,
        style: Style = .primary,
        size: Size = .medium,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.size = size
        self.isLoading = isLoading
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: KingDesignTokens.Spacing.xs) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.8)
                }
                
                Text(title)
                    .font(size.font)
                    .fontWeight(.medium)
            }
            .foregroundColor(foregroundColor)
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .frame(maxWidth: style == .primary ? .infinity : nil)
            .background(background)
            .cornerRadius(KingDesignTokens.Radius.md)
            .overlay(
                RoundedRectangle(cornerRadius: KingDesignTokens.Radius.md)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
        }
        .disabled(isLoading)
        .animation(KingDesignTokens.Animation.fast, value: isLoading)
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary:
            return KingDesignTokens.Colors.background
        case .secondary:
            return KingDesignTokens.Colors.primary
        case .danger:
            return KingDesignTokens.Colors.background
        }
    }
    
    private var background: some View {
        Group {
            switch style {
            case .primary:
                KingDesignTokens.Colors.accent
            case .secondary:
                Color.clear
            case .danger:
                KingDesignTokens.Colors.error
            }
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .primary:
            return Color.clear
        case .secondary:
            return KingDesignTokens.Colors.border
        case .danger:
            return Color.clear
        }
    }
    
    private var borderWidth: CGFloat {
        style == .secondary ? 1 : 0
    }
}

// MARK: - Icon Button
public struct KingIconButton: View {
    let icon: String
    let action: () -> Void
    
    public init(icon: String, action: @escaping () -> Void) {
        self.icon = icon
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(KingDesignTokens.Colors.primary)
                .frame(width: 44, height: 44)
                .glass(
                    material: KingDesignTokens.Glass.ultraThin,
                    cornerRadius: KingDesignTokens.Radius.full
                )
        }
    }
}

// MARK: - Preview
#Preview("KingButton Variants") {
    VStack(spacing: KingDesignTokens.Spacing.lg) {
        KingButton("Primary Action", style: .primary) { }
        KingButton("Secondary Action", style: .secondary) { }
        KingButton("Danger Action", style: .danger) { }
        
        HStack(spacing: KingDesignTokens.Spacing.md) {
            KingButton("Small", style: .primary, size: .small) { }
            KingButton("Large", style: .primary, size: .large) { }
        }
        
        KingButton("Loading...", style: .primary, isLoading: true) { }
        
        HStack(spacing: KingDesignTokens.Spacing.md) {
            KingIconButton(icon: "arrow.up") { }
            KingIconButton(icon: "arrow.down") { }
            KingIconButton(icon: "plus") { }
        }
    }
    .padding()
    .background(KingDesignTokens.Colors.background)
}
