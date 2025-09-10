import SwiftUI

/// 프리미엄 Glass 카드 컴포넌트
/// Revolut/N26 스타일의 글래스모피즘 카드
public struct GlassCard<Content: View>: View {
    public enum Level {
        case subtle
        case standard
        case prominent
    }
    
    private let content: () -> Content
    private let level: Level
    private let padding: CGFloat
    private let cornerRadius: CGFloat
    
    public init(
        level: Level = .standard,
        padding: CGFloat = KingDesignTokens.Spacing.lg,
        cornerRadius: CGFloat = KingDesignTokens.Radius.lg,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.level = level
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.content = content
    }
    
    public var body: some View {
        content()
            .padding(padding)
            .background(backgroundMaterial)
            .overlay(borderOverlay)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowOffset)
    }
    
    @ViewBuilder
    private var backgroundMaterial: some View {
        switch level {
        case .subtle:
            Rectangle()
                .fill(.clear)
                .background(KingDesignTokens.Glass.ultraThin)
        case .standard:
            Rectangle()
                .fill(.clear)
                .background(KingDesignTokens.Glass.thin)
        case .prominent:
            Rectangle()
                .fill(.clear)
                .background(KingDesignTokens.Glass.regular)
        }
    }
    
    @ViewBuilder
    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .stroke(
                LinearGradient(
                    colors: [
                        KingDesignTokens.Colors.border.opacity(borderOpacity),
                        KingDesignTokens.Colors.border.opacity(borderOpacity * 0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }
    
    private var borderOpacity: Double {
        switch level {
        case .subtle: return 0.3
        case .standard: return 0.5
        case .prominent: return 0.8
        }
    }
    
    private var shadowColor: Color {
        KingDesignTokens.Colors.primaryText.opacity(0.1)
    }
    
    private var shadowRadius: CGFloat {
        switch level {
        case .subtle: return 4
        case .standard: return 8
        case .prominent: return 16
        }
    }
    
    private var shadowOffset: CGFloat {
        switch level {
        case .subtle: return 2
        case .standard: return 4
        case .prominent: return 8
        }
    }
}

/// 알럿 카드 컴포넌트
public struct GlassAlertCard: View {
    public enum AlertType {
        case info
        case success
        case warning
        case error
    }
    
    private let type: AlertType
    private let title: String
    private let message: String
    
    public init(type: AlertType, title: String, message: String) {
        self.type = type
        self.title = title
        self.message = message
    }
    
    public var body: some View {
        GlassCard(level: .prominent) {
            VStack(alignment: .leading, spacing: KingDesignTokens.Spacing.md) {
                HStack(spacing: KingDesignTokens.Spacing.sm) {
                    Image(systemName: iconName)
                        .font(KingDesignTokens.Typography.body)
                        .foregroundColor(iconColor)
                    
                    Text(title)
                        .font(KingDesignTokens.Typography.heading)
                        .fontWeight(.semibold)
                        .foregroundColor(KingDesignTokens.Colors.primaryText)
                }
                
                Text(message)
                    .font(KingDesignTokens.Typography.body)
                    .foregroundColor(KingDesignTokens.Colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    private var iconName: String {
        switch type {
        case .info: return "info.circle.fill"
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        }
    }
    
    private var iconColor: Color {
        switch type {
        case .info: return KingDesignTokens.Colors.info
        case .success: return KingDesignTokens.Colors.success
        case .warning: return KingDesignTokens.Colors.warning
        case .error: return KingDesignTokens.Colors.error
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        GlassCard(level: .subtle) {
            Text("Subtle Glass Card")
                .foregroundColor(KingDesignTokens.Colors.primaryText)
        }
        
        GlassCard(level: .standard) {
            Text("Standard Glass Card")
                .foregroundColor(KingDesignTokens.Colors.primaryText)
        }
        
        GlassCard(level: .prominent) {
            Text("Prominent Glass Card")
                .foregroundColor(KingDesignTokens.Colors.primaryText)
        }
        
        GlassAlertCard(
            type: .error,
            title: "오류 발생",
            message: "처리 중 오류가 발생했습니다."
        )
    }
    .padding()
    .background(KingDesignTokens.Colors.background)
}
