import SwiftUI
import Core

/// 설정 그룹을 위한 재사용 가능한 컴포넌트
/// 설정 화면에서 관련 항목들을 그룹화하여 표시할 때 사용
public struct SettingsGroup<Content: View>: View {
    let title: String
    let content: Content
    
    public init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: KingDesignTokens.Spacing.sm) {
            // 타이틀
            if !title.isEmpty {
                Text(title)
                    .font(KingDesignTokens.Typography.heading)
                    .foregroundColor(KingDesignTokens.Colors.primary)
                    .padding(.horizontal, KingDesignTokens.Spacing.md)
                    .padding(.top, KingDesignTokens.Spacing.sm)
            }
            
            // 컨텐츠
            VStack(spacing: 0) {
                content
            }
        }
        .background(
            LinearGradient(
                colors: [KingDesignTokens.Colors.accent.opacity(0.1),
                         KingDesignTokens.Colors.surface],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: KingDesignTokens.Radius.lg))
        .overlay(
            RoundedRectangle(
                cornerRadius: KingDesignTokens.Radius.lg
            )
                .stroke(KingDesignTokens.Colors.border, lineWidth: 1)
        )
        .shadow(color: KingDesignTokens.Shadow.md.color, radius: 6, x: 0, y: 3)
    }
}
