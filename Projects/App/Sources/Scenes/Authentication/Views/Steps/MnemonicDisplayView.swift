import SwiftUI
import DesignSystem

/// 🔐 프리미엄 니모닉 뷰 (디스플레이용)
struct PremiumMnemonicView: View {
    var body: some View {
        VStack(spacing: KingDesignTokens.Spacing.xl) {
            Text("복구 구문")
                .font(KingDesignTokens.Typography.displayM)
                .foregroundColor(KingDesignTokens.Colors.primaryText)
            
            Text("지갑의 니모닉 복구 구문을 안전하게 보관하세요")
                .font(KingDesignTokens.Typography.body)
                .foregroundColor(KingDesignTokens.Colors.secondaryText)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding(KingDesignTokens.Spacing.xl)
        .background(KingDesignTokens.Colors.background)
    }
}