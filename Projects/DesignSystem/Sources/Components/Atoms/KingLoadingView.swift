import SwiftUI

// MARK: - Premium Loading View Component
public struct KingLoadingView: View {
    public enum Style {
        case spinner        // 기본 스피너
        case dots           // 점 애니메이션
        case progress       // 진행률 표시
        case skeleton       // 스켈레톤 로딩
        case fullScreen     // 전체 화면 로딩
    }
    
    public enum Size {
        case small
        case medium
        case large
        
        var dimension: CGFloat {
            switch self {
            case .small: return 20
            case .medium: return 40
            case .large: return 60
            }
        }
        
        var strokeWidth: CGFloat {
            switch self {
            case .small: return 2
            case .medium: return 3
            case .large: return 4
            }
        }
    }
    
    let style: Style
    let size: Size
    let message: String?
    let progress: Double?
    
    @State private var isAnimating = false
    @State private var dotScale: [CGFloat] = [1, 1, 1]
    @State private var rotation: Double = 0
    
    public init(
        style: Style = .spinner,
        size: Size = .medium,
        message: String? = nil,
        progress: Double? = nil
    ) {
        self.style = style
        self.size = size
        self.message = message
        self.progress = progress
    }
    
    public var body: some View {
        VStack(spacing: KingDesignTokens.Spacing.m) {
            switch style {
            case .spinner:
                spinnerView
            case .dots:
                dotsView
            case .progress:
                progressView
            case .skeleton:
                skeletonView
            case .fullScreen:
                fullScreenView
            }
            
            if let message = message, style != .fullScreen {
                Text(message)
                    .font(KingDesignTokens.Typography.caption)
                    .foregroundColor(KingDesignTokens.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            isAnimating = false
        }
    }
    
    // MARK: - Loading Styles
    
    @ViewBuilder
    private var spinnerView: some View {
        ZStack {
            // Background Circle
            Circle()
                .stroke(
                    KingDesignTokens.Colors.border,
                    lineWidth: size.strokeWidth
                )
                .frame(width: size.dimension, height: size.dimension)
            
            // Animated Arc
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(
                    LinearGradient(
                        colors: [
                            KingDesignTokens.Colors.primary,
                            KingDesignTokens.Colors.primary.opacity(0.5)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(
                        lineWidth: size.strokeWidth,
                        lineCap: .round
                    )
                )
                .frame(width: size.dimension, height: size.dimension)
                .rotationEffect(.degrees(rotation))
                .animation(
                    Animation.linear(duration: 1)
                        .repeatForever(autoreverses: false),
                    value: rotation
                )
        }
        .accessibilityLabel("로딩 중")
    }
    
    @ViewBuilder
    private var dotsView: some View {
        HStack(spacing: KingDesignTokens.Spacing.xs) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(KingDesignTokens.Colors.primary)
                    .frame(width: size.dimension / 3, height: size.dimension / 3)
                    .scaleEffect(dotScale[index])
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: dotScale[index]
                    )
            }
        }
        .accessibilityLabel("로딩 중")
    }
    
    @ViewBuilder
    private var progressView: some View {
        VStack(spacing: KingDesignTokens.Spacing.sm) {
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: KingDesignTokens.Radius.xs)
                    .fill(KingDesignTokens.Colors.surfaceVariant)
                    .frame(height: 8)
                
                // Progress
                if let progress = progress {
                    RoundedRectangle(cornerRadius: KingDesignTokens.Radius.xs)
                        .fill(
                            LinearGradient(
                                colors: [
                                    KingDesignTokens.Colors.primary,
                                    KingDesignTokens.Colors.accent
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: size.dimension * 3 * CGFloat(progress), height: 8)
                        .animation(KingDesignTokens.Animation.normal, value: progress)
                }
            }
            .frame(width: size.dimension * 3)
            
            if let progress = progress {
                Text("\(Int(progress * 100))%")
                    .font(KingDesignTokens.Typography.micro)
                    .foregroundColor(KingDesignTokens.Colors.tertiaryText)
            }
        }
        .accessibilityLabel("진행률 \(Int((progress ?? 0) * 100))%")
    }
    
    @ViewBuilder
    private var skeletonView: some View {
        VStack(spacing: KingDesignTokens.Spacing.sm) {
            // Title Skeleton
            RoundedRectangle(cornerRadius: KingDesignTokens.Radius.xs)
                .fill(shimmerGradient)
                .frame(height: 20)
                .frame(maxWidth: .infinity)
                .animation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false),
                    value: isAnimating
                )
            
            // Content Skeletons
            ForEach(0..<3) { index in
                RoundedRectangle(cornerRadius: KingDesignTokens.Radius.xs)
                    .fill(shimmerGradient)
                    .frame(height: 16)
                    .frame(maxWidth: .infinity)
                    .opacity(1.0 - Double(index) * 0.2)
                    .animation(
                        Animation.linear(duration: 1.5)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.1),
                        value: isAnimating
                    )
            }
            
            // Image Skeleton
            RoundedRectangle(cornerRadius: KingDesignTokens.Radius.sm)
                .fill(shimmerGradient)
                .frame(height: 120)
                .frame(maxWidth: .infinity)
                .animation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                        .delay(0.3),
                    value: isAnimating
                )
        }
        .accessibilityLabel("콘텐츠 로딩 중")
    }
    
    @ViewBuilder
    private var fullScreenView: some View {
        ZStack {
            // Background
            KingDesignTokens.Colors.background
                .opacity(0.95)
                .ignoresSafeArea()
            
            // Content
            VStack(spacing: KingDesignTokens.Spacing.lg) {
                // Large Spinner
                ZStack {
                    Circle()
                        .stroke(
                            KingDesignTokens.Colors.border.opacity(0.3),
                            lineWidth: 4
                        )
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    KingDesignTokens.Colors.primary,
                                    KingDesignTokens.Colors.accent
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(
                                lineWidth: 4,
                                lineCap: .round
                            )
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(rotation))
                        .animation(
                            Animation.linear(duration: 1)
                                .repeatForever(autoreverses: false),
                            value: rotation
                        )
                }
                
                if let message = message {
                    Text(message)
                        .font(KingDesignTokens.Typography.body)
                        .foregroundColor(KingDesignTokens.Colors.primaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, KingDesignTokens.Spacing.xl)
                }
                
                if let progress = progress {
                    Text("\(Int(progress * 100))%")
                        .font(KingDesignTokens.Typography.heading)
                        .foregroundColor(KingDesignTokens.Colors.primary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // MARK: - Helpers
    
    private var shimmerGradient: LinearGradient {
        LinearGradient(
            colors: [
                KingDesignTokens.Colors.surfaceVariant,
                KingDesignTokens.Colors.surface,
                KingDesignTokens.Colors.surfaceVariant
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private func startAnimation() {
        switch style {
        case .spinner, .fullScreen:
            withAnimation {
                rotation = 360
            }
        case .dots:
            for index in 0..<3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.2) {
                    withAnimation {
                        dotScale[index] = 1.3
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation {
                            dotScale[index] = 1.0
                        }
                    }
                }
            }
        case .skeleton:
            isAnimating = true
        default:
            break
        }
        isAnimating = true
    }
}

// MARK: - Loading Overlay Modifier
public struct LoadingOverlay: ViewModifier {
    let isLoading: Bool
    let message: String?
    
    public func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isLoading)
                .blur(radius: isLoading ? 3 : 0)
            
            if isLoading {
                KingLoadingView(
                    style: .fullScreen,
                    message: message
                )
                .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(KingDesignTokens.Animation.normal, value: isLoading)
    }
}

public extension View {
    /// Apply loading overlay to any view
    func loadingOverlay(isLoading: Bool, message: String? = nil) -> some View {
        self.modifier(LoadingOverlay(isLoading: isLoading, message: message))
    }
}

// MARK: - Preview
#Preview("KingLoadingView Variants") {
    ScrollView {
        VStack(spacing: KingDesignTokens.Spacing.xxxl) {
            // Spinner Sizes
            HStack(spacing: KingDesignTokens.Spacing.xl) {
                KingLoadingView(style: .spinner, size: .small)
                KingLoadingView(style: .spinner, size: .medium)
                KingLoadingView(style: .spinner, size: .large)
            }
            
            // Dots Animation
            KingLoadingView(
                style: .dots,
                size: .medium,
                message: "Loading your wallet..."
            )
            
            // Progress Bar
            KingLoadingView(
                style: .progress,
                size: .medium,
                message: "Syncing blockchain...",
                progress: 0.65
            )
            
            // Skeleton Loading
            KingLoadingView(style: .skeleton)
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
            
            // Sample View with Loading Overlay
            KingCard(style: .glass) {
                VStack(spacing: KingDesignTokens.Spacing.m) {
                    Text("Sample Content")
                        .font(KingDesignTokens.Typography.heading)
                    Text("This content has a loading overlay")
                        .font(KingDesignTokens.Typography.body)
                }
                .foregroundColor(KingDesignTokens.Colors.primaryText)
            }
            .loadingOverlay(isLoading: true, message: "Processing transaction...")
            .frame(height: 200)
            .padding(.horizontal)
        }
        .padding()
    }
    .background(KingDesignTokens.Colors.background)
}