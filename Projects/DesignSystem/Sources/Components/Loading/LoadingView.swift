import SwiftUI

/// 재사용 가능한 로딩 뷰 컴포넌트
/// 다양한 로딩 스타일과 크기를 지원하는 공통 컴포넌트
public struct LoadingView: View {
    
    let style: LoadingStyle
    let size: LoadingSize
    let message: String?
    
    @State private var isAnimating = false
    
    public init(
        style: LoadingStyle = .spinner,
        size: LoadingSize = .medium,
        message: String? = nil
    ) {
        self.style = style
        self.size = size
        self.message = message
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            loadingIndicator
            
            if let message = message {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            startAnimation()
        }
    }
    
    @ViewBuilder
    private var loadingIndicator: some View {
        switch style {
        case .spinner:
            spinnerView
        case .dots:
            dotsView
        case .skeleton:
            skeletonView
        case .pulse:
            pulseView
        }
    }
    
    private var spinnerView: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(
                LinearGradient.primaryGradient,
                style: StrokeStyle(lineWidth: size.lineWidth, lineCap: .round)
            )
            .frame(width: size.dimension, height: size.dimension)
            .rotationEffect(.degrees(isAnimating ? 360 : 0))
            .animation(
                .linear(duration: 1.0).repeatForever(autoreverses: false),
                value: isAnimating
            )
    }
    
    private var dotsView: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(LinearGradient.primaryGradient)
                    .frame(width: size.dotSize, height: size.dotSize)
                    .scaleEffect(isAnimating ? 1.0 : 0.5)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.2),
                        value: isAnimating
                    )
            }
        }
    }
    
    private var skeletonView: some View {
        VStack(spacing: 12) {
            ForEach(0..<3) { _ in
                RoundedRectangle(cornerRadius: 8)
                    .fill(.ultraThinMaterial)
                    .frame(height: size.skeletonHeight)
                    .opacity(isAnimating ? 0.3 : 0.6)
                    .animation(
                        .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
        }
        .frame(width: size.skeletonWidth)
    }
    
    private var pulseView: some View {
        Circle()
            .fill(LinearGradient.primaryGradient.opacity(0.3))
            .frame(width: size.dimension, height: size.dimension)
            .scaleEffect(isAnimating ? 1.2 : 0.8)
            .opacity(isAnimating ? 0.3 : 0.8)
            .animation(
                .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                value: isAnimating
            )
    }
    
    private func startAnimation() {
        withAnimation {
            isAnimating = true
        }
    }
}

/// 로딩 스타일
public enum LoadingStyle: String, CaseIterable {
    case spinner = "spinner"
    case dots = "dots"
    case skeleton = "skeleton"
    case pulse = "pulse"
    
    public var displayName: String {
        switch self {
        case .spinner: return "Spinner"
        case .dots: return "Dots"
        case .skeleton: return "Skeleton"
        case .pulse: return "Pulse"
        }
    }
}

/// 로딩 크기
public enum LoadingSize: String, CaseIterable {
    case small = "small"
    case medium = "medium"
    case large = "large"
    
    var dimension: CGFloat {
        switch self {
        case .small: return 20
        case .medium: return 40
        case .large: return 60
        }
    }
    
    var lineWidth: CGFloat {
        switch self {
        case .small: return 2
        case .medium: return 3
        case .large: return 4
        }
    }
    
    var dotSize: CGFloat {
        switch self {
        case .small: return 4
        case .medium: return 8
        case .large: return 12
        }
    }
    
    var skeletonHeight: CGFloat {
        switch self {
        case .small: return 12
        case .medium: return 20
        case .large: return 28
        }
    }
    
    var skeletonWidth: CGFloat {
        switch self {
        case .small: return 120
        case .medium: return 200
        case .large: return 280
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        LoadingView(style: .spinner, size: .medium, message: "로딩 중...")
        
        LoadingView(style: .dots, size: .medium)
        
        LoadingView(style: .skeleton, size: .medium)
        
        LoadingView(style: .pulse, size: .medium)
    }
    .padding()
}