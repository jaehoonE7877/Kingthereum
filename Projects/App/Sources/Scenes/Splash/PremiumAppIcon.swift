import SwiftUI
import DesignSystem

/// 프리미엄 앱 아이콘 컴포넌트
/// Revolut/N26 스타일의 럭셔리 앱 아이콘 표현
struct PremiumAppIcon: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // 베이스 아이콘 이미지 (다크모드 대응)
            Image(iconName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(
                    // 프리미엄 보더 효과
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    KingDesignTokens.Colors.accent.opacity(0.3),
                                    KingDesignTokens.Colors.accent.opacity(0.1),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(
                    color: KingDesignTokens.Colors.accent.opacity(0.2),
                    radius: 12,
                    x: 0,
                    y: 6
                )
        }
    }
    
    /// 다크모드에 따라 적절한 아이콘 이미지 선택
    private var iconName: String {
        switch colorScheme {
        case .dark:
            return "AppIcon_black"
        case .light:
            return "AppIcon_purle"  // 기본 보라색 아이콘
        @unknown default:
            return "AppIcon_purle"
        }
    }
}

/// 프리미엄 앱 아이콘 프리뷰
#Preview("Premium App Icon") {
    VStack(spacing: 40) {
        // 라이트 모드
        VStack {
            Text("Light Mode")
                .font(.caption)
                .foregroundColor(.secondary)
            
            PremiumAppIcon()
                .frame(width: 120, height: 120)
        }
        .environment(\.colorScheme, .light)
        
        // 다크 모드
        VStack {
            Text("Dark Mode")
                .font(.caption)
                .foregroundColor(.secondary)
            
            PremiumAppIcon()
                .frame(width: 120, height: 120)
        }
        .environment(\.colorScheme, .dark)
    }
    .padding()
    .background(Color.black)
}