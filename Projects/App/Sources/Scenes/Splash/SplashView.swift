import SwiftUI
import Core
import DesignSystem

/// 앱 시작 시 나타나는 스플래시 화면
/// iOS 네이티브한 모던 디자인으로 브랜드를 표시
struct SplashView: View {
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0.0
    @State private var contentOpacity: Double = 0.0
    @State private var backgroundOpacity: Double = 0.0
    
    var body: some View {
        ZStack {
            // iOS 스타일 그라데이션 배경
            LinearGradient(
                colors: [
                    Color.systemBackground,
                    Color.systemSecondaryBackground,
                    Color.systemTertiaryBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(backgroundOpacity)
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // 앱 아이콘
                AppIconView()
                    .frame(width: 100, height: 100)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                
                // 앱 이름과 설명
                VStack(spacing: 12) {
                    Text("Kingthereum")
                        .font(.system(size: 32, weight: .medium, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Ethereum Wallet")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.secondary)
                }
                .opacity(contentOpacity)
                
                Spacer()
                
                // 하단 인디케이터
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.systemBlue)
                    
                    Text("Loading...")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .opacity(contentOpacity)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // 1. 배경 페이드인
        withAnimation(.easeOut(duration: 0.3)) {
            backgroundOpacity = 1.0
        }
        
        // 2. 로고 등장
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // 3. 텍스트 등장
        withAnimation(.easeOut(duration: 0.6).delay(0.5)) {
            contentOpacity = 1.0
        }
    }
}

/// 앱 아이콘을 SwiftUI로 재현한 뷰
struct AppIconView: View {
    var body: some View {
        ZStack {
            // iOS 스타일 앱 아이콘 배경
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.45, green: 0.35, blue: 0.85), // 보라색
                            Color(red: 0.35, green: 0.25, blue: 0.75)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(
                    color: .glassShadowMedium,
                    radius: 8,
                    x: 0,
                    y: 4
                )
            
            // 중앙 카드
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.systemBackground)
                .frame(width: 60, height: 60)
                .shadow(
                    color: .glassShadowLight,
                    radius: 2,
                    x: 0,
                    y: 1
                )
            
            // 이더리움 심볼
            EthereumSymbolView()
                .frame(width: 20, height: 30)
        }
    }
}

/// 이더리움 심볼을 SwiftUI로 재현한 뷰 (모던하고 심플하게)
struct EthereumSymbolView: View {
    var body: some View {
        ZStack {
            // 상단 다이아몬드
            Path { path in
                path.move(to: CGPoint(x: 10, y: 0))     // 상단
                path.addLine(to: CGPoint(x: 20, y: 12)) // 우측
                path.addLine(to: CGPoint(x: 10, y: 15)) // 중앙
                path.addLine(to: CGPoint(x: 0, y: 12))  // 좌측
                path.closeSubpath()
            }
            .fill(Color(red: 0.4, green: 0.3, blue: 0.8))
            
            // 하단 다이아몬드
            Path { path in
                path.move(to: CGPoint(x: 10, y: 15))    // 중앙
                path.addLine(to: CGPoint(x: 20, y: 12)) // 우측
                path.addLine(to: CGPoint(x: 10, y: 30)) // 하단
                path.addLine(to: CGPoint(x: 0, y: 12))  // 좌측
                path.closeSubpath()
            }
            .fill(Color(red: 0.3, green: 0.2, blue: 0.7))
        }
    }
}

#Preview("SplashView") {
    SplashView()
}

#Preview("AppIcon Light") {
    AppIconView()
        .frame(width: 120, height: 120)
        .background(Color.systemBackground)
}

#Preview("AppIcon Dark") {
    AppIconView()
        .frame(width: 120, height: 120)
        .background(Color.systemBackground.opacity(0.1))
        .preferredColorScheme(.dark)
}
