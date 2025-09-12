import SwiftUI
import DesignSystem

/// 프리미엄 앱 아이콘 컴포넌트
/// Revolut/N26 스타일의 럭셔리 앱 아이콘 표현
struct PremiumAppIcon: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // 프리미엄 배경 그라데이션
            RoundedRectangle(cornerRadius: 24)
                .fill(backgroundGradient)
            
            // 이더리움 다이아몬드 아이콘
            EthereumDiamondIcon()
                .frame(width: 80, height: 80)
                .shadow(
                    color: KingDesignTokens.Colors.accent.opacity(0.3),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        }
        .overlay(
            // 프리미엄 보더 효과
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        colors: [
                            KingDesignTokens.Colors.accent.opacity(0.6),
                            KingDesignTokens.Colors.accent.opacity(0.3),
                            Color.white.opacity(0.2),
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
    
    /// 배경 그라데이션 (다크모드 대응)
    private var backgroundGradient: LinearGradient {
        switch colorScheme {
        case .dark:
            return LinearGradient(
                colors: [
                    Color.black.opacity(0.9),
                    Color.gray.opacity(0.8),
                    KingDesignTokens.Colors.accent.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .light:
            return LinearGradient(
                colors: [
                    KingDesignTokens.Colors.accent.opacity(0.15),
                    Color.white.opacity(0.9),
                    KingDesignTokens.Colors.accent.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        @unknown default:
            return LinearGradient(
                colors: [
                    KingDesignTokens.Colors.accent.opacity(0.15),
                    Color.white.opacity(0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

/// 이더리움 다이아몬드 아이콘 - 순수 SwiftUI로 그린 벡터 그래픽
struct EthereumDiamondIcon: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // 상단 다이아몬드 (밝은 면)
            Path { path in
                path.move(to: CGPoint(x: 50, y: 10))    // 꼭대기
                path.addLine(to: CGPoint(x: 80, y: 45)) // 우측
                path.addLine(to: CGPoint(x: 50, y: 50)) // 중앙
                path.addLine(to: CGPoint(x: 20, y: 45)) // 좌측
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: ethereumTopGradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            
            // 하단 다이아몬드 (어두운 면)
            Path { path in
                path.move(to: CGPoint(x: 20, y: 45))    // 좌측
                path.addLine(to: CGPoint(x: 50, y: 50)) // 중앙
                path.addLine(to: CGPoint(x: 80, y: 45)) // 우측
                path.addLine(to: CGPoint(x: 50, y: 90)) // 바닥
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: ethereumBottomGradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            
            // 중앙 하이라이트 라인
            Path { path in
                path.move(to: CGPoint(x: 50, y: 10))
                path.addLine(to: CGPoint(x: 50, y: 90))
            }
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.6),
                        Color.white.opacity(0.3),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 1.5
            )
            
            // 좌측 하이라이트
            Path { path in
                path.move(to: CGPoint(x: 20, y: 45))
                path.addLine(to: CGPoint(x: 50, y: 50))
                path.addLine(to: CGPoint(x: 50, y: 90))
            }
            .stroke(
                Color.white.opacity(0.2),
                lineWidth: 1
            )
        }
        .frame(width: 100, height: 100)
    }
    
    /// 상단 다이아몬드 그라데이션
    private var ethereumTopGradient: [Color] {
        switch colorScheme {
        case .dark:
            return [
                Color(red: 0.4, green: 0.4, blue: 0.9),  // 밝은 보라-파랑
                Color(red: 0.3, green: 0.3, blue: 0.7),  // 중간 보라-파랑
                Color(red: 0.2, green: 0.2, blue: 0.5)   // 어두운 보라-파랑
            ]
        case .light:
            return [
                Color(red: 0.5, green: 0.5, blue: 1.0),  // 밝은 파랑
                Color(red: 0.4, green: 0.4, blue: 0.8),  // 중간 파랑
                Color(red: 0.3, green: 0.3, blue: 0.6)   // 어두운 파랑
            ]
        @unknown default:
            return [
                Color(red: 0.5, green: 0.5, blue: 1.0),
                Color(red: 0.4, green: 0.4, blue: 0.8)
            ]
        }
    }
    
    /// 하단 다이아몬드 그라데이션
    private var ethereumBottomGradient: [Color] {
        switch colorScheme {
        case .dark:
            return [
                Color(red: 0.2, green: 0.2, blue: 0.5),  // 어두운 보라-파랑
                Color(red: 0.15, green: 0.15, blue: 0.4), // 더 어두운
                Color(red: 0.1, green: 0.1, blue: 0.3)   // 가장 어두운
            ]
        case .light:
            return [
                Color(red: 0.3, green: 0.3, blue: 0.6),  // 어두운 파랑
                Color(red: 0.2, green: 0.2, blue: 0.5),  // 더 어두운
                Color(red: 0.15, green: 0.15, blue: 0.4) // 가장 어두운
            ]
        @unknown default:
            return [
                Color(red: 0.3, green: 0.3, blue: 0.6),
                Color(red: 0.2, green: 0.2, blue: 0.5)
            ]
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
                .foregroundColor(KingDesignTokens.Colors.secondaryText)
            
            PremiumAppIcon()
                .frame(width: 120, height: 120)
        }
        .environment(\.colorScheme, .light)
        
        // 다크 모드
        VStack {
            Text("Dark Mode")
                .font(.caption)
                .foregroundColor(KingDesignTokens.Colors.secondaryText)
            
            PremiumAppIcon()
                .frame(width: 120, height: 120)
        }
        .environment(\.colorScheme, .dark)
    }
    .padding()
    .background(KingDesignTokens.Colors.systemBlack)
}
