import SwiftUI
import DesignSystem

struct SecurityGuideItem: View {
    let text: String
    
    var body: some View {
        HStack(spacing: KingDesignTokens.Spacing.sm) {
            Circle()
                .fill(KingDesignTokens.Colors.success)
                .frame(width: 6, height: 6)
            
            Text(text)
                .font(KingDesignTokens.Typography.caption)
                .foregroundColor(KingDesignTokens.Colors.secondaryText)
        }
    }
}