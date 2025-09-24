import SwiftUI
import DesignSystem

struct AuthenticationGlassCard<Content: View>: View {
    @ViewBuilder private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, KingDesignTokens.Spacing.lg)
            .padding(.vertical, KingDesignTokens.Spacing.xl)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: KingDesignTokens.Radius.xl, style: .continuous)
                    .fill(KingDesignTokens.Colors.surface.opacity(0.65))
                    .overlay(
                        RoundedRectangle(cornerRadius: KingDesignTokens.Radius.xl, style: .continuous)
                            .stroke(KingDesignTokens.Colors.surfaceSecondary.opacity(0.4), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.15), radius: 24, x: 0, y: 12)
            )
    }
}
