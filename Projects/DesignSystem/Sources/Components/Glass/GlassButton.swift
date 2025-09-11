import SwiftUI

/// 프리미엄 Glass 버튼 컴포넌트
/// Revolut/N26 스타일의 글래스모피즘 버튼
public struct GlassButton: View {
    public enum Style {
        case primary
        case secondary
        case text
    }
    
    private let title: String
    private let icon: String?
    private let style: Style
    private let action: () -> Void
    
    public init(
        _ title: String,
        icon: String? = nil,
        style: Style = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: KingDesignTokens.Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(KingDesignTokens.Typography.body)
                        .fontWeight(.medium)
                }
                
                Text(title)
                    .font(KingDesignTokens.Typography.body)
                    .fontWeight(.medium)
            }
            .foregroundColor(foregroundColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, KingDesignTokens.Spacing.md)
            .padding(.horizontal, KingDesignTokens.Spacing.lg)
            .background(backgroundView)
            .overlay(overlayView)
            .clipShape(RoundedRectangle(cornerRadius: KingDesignTokens.Radius.md))
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            KingDesignTokens.Colors.accent
        case .secondary:
            Rectangle()
                .fill(.clear)
                .background(KingDesignTokens.Glass.ultraThin)
        case .text:
            Color.clear
        }
    }
    
    @ViewBuilder
    private var overlayView: some View {
        switch style {
        case .primary:
            RoundedRectangle(cornerRadius: KingDesignTokens.Radius.md)
                .stroke(KingDesignTokens.Colors.accent.opacity(0.3), lineWidth: 1)
        case .secondary:
            RoundedRectangle(cornerRadius: KingDesignTokens.Radius.md)
                .stroke(KingDesignTokens.Colors.border, lineWidth: 1)
        case .text:
            EmptyView()
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary:
            KingDesignTokens.Colors.onPrimary
        case .secondary:
            KingDesignTokens.Colors.primaryText
        case .text:
            KingDesignTokens.Colors.accent
        }
    }
}

/// 버튼 스케일 애니메이션 스타일
private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(KingDesignTokens.Animation.fast, value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: 16) {
        GlassButton("Primary Button", icon: "star.fill", style: .primary) { }
        GlassButton("Secondary Button", icon: "gear", style: .secondary) { }
        GlassButton("Text Button", style: .text) { }
    }
    .padding()
    .background(KingDesignTokens.Colors.background)
}
