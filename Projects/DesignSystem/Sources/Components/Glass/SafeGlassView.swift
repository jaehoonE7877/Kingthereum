import SwiftUI
import Core

/// SwiftUI 네이티브 Glass 효과 (Metal 제거됨)
public struct SafeGlassView<Content: View>: View {
    
    // MARK: - Properties
    
    let content: Content
    let opacity: Double
    let tintColor: Color
    let cornerRadius: CGFloat
    
    @State private var animationOffset: CGSize = .zero
    @State private var isAnimating: Bool = false
    
    // MARK: - Initialization
    
    public init(
        opacity: Double = 0.8,
        tintColor: Color = .clear,
        cornerRadius: CGFloat = 12,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.opacity = opacity
        self.tintColor = tintColor
        self.cornerRadius = cornerRadius
    }
    
    // MARK: - Body
    
    public var body: some View {
        content
            .background(swiftUIGlassEffect)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .onAppear {
                startContinuousAnimation()
            }
    }
    
    // MARK: - SwiftUI Glass Effect
    
    @ViewBuilder
    private var swiftUIGlassEffect: some View {
        ZStack {
            // 기본 블러 효과
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(opacity)
            
            // 글로시 오버레이
            LinearGradient(
                colors: [
                    Color.white.opacity(0.3),
                    Color.white.opacity(0.1),
                    Color.white.opacity(0.05),
                    Color.white.opacity(0.1),
                    Color.white.opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(0.6)
            
            // 애니메이팅 글레어 효과
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.15),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .rotationEffect(.degrees(45))
                .offset(animationOffset)
                .opacity(isAnimating ? 0.7 : 0.0)
                .animation(
                    .easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true),
                    value: isAnimating
                )
            
            // 틴트 색상 오버레이
            if tintColor != .clear {
                Rectangle()
                    .fill(tintColor.opacity(0.1))
            }
            
            // 가장자리 하이라이트
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            Color.clear,
                            Color.clear,
                            Color.white.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }
    
    // MARK: - Animation
    
    private func startContinuousAnimation() {
        withAnimation {
            isAnimating = true
            animationOffset = CGSize(width: 200, height: 200)
        }
    }
}

/// SwiftUI Glass 효과를 적용하는 View Extension
public extension View {
    /// 안전한 SwiftUI Glass 효과 적용
    func safeSwiftUIGlass(
        opacity: Double = 0.8,
        tintColor: Color = .clear,
        cornerRadius: CGFloat = 12
    ) -> some View {
        SafeGlassView(
            opacity: opacity,
            tintColor: tintColor,
            cornerRadius: cornerRadius
        ) {
            self
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        SafeGlassView {
            VStack {
                Text("SwiftUI Glass Effect")
                    .font(.headline)
                Text("Metal 없이 순수 SwiftUI로 구현")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .frame(height: 100)
        
        Text("SwiftUI Glass 효과")
            .font(.caption)
            .padding()
            .safeSwiftUIGlass()
    }
    .padding()
    .background(
        LinearGradient(
            colors: [.blue, .purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}