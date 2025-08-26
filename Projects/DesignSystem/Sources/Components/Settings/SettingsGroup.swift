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
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            // 타이틀
            if !title.isEmpty {
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
        .background(KingthereumGradients.card)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                .stroke(KingthereumColors.cardBorder, lineWidth: DesignTokens.BorderWidth.normal)
        )
        .shadow(color: KingthereumColors.cardShadow, radius: 6, x: 0, y: 3)
    }
}