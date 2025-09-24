import SwiftUI
import DesignSystem

struct AuthenticationCTAContainer<Content: View>: View {
    @ViewBuilder private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: KingDesignTokens.Spacing.md) {
            content
        }
        .padding(.horizontal, KingDesignTokens.Spacing.lg)
        .padding(.vertical, KingDesignTokens.Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Divider()
                .background(KingDesignTokens.Colors.border.opacity(0.3))
        }
    }
}
