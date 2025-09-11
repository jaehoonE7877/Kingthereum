import SwiftUI
import DesignSystem

/// iOS 18 스타일의 커스텀 Tab Bar 구현
/// Liquid Glass 효과를 SwiftUI의 Material과 blur로 재현
/// Premium Glassmorphism TabBar - iOS 18 Style with Crypto Wallet Aesthetics
/// Features: Ultra-smooth transitions, haptic feedback, premium glass effects
struct CustomTabBar: View {
    @Binding var selectedTab: AppTab
    @Namespace private var animation
    @State private var hoveredTab: AppTab?
    
    // MARK: - Design Tokens (Premium 2024 Standards)
    private let tabBarHeight: CGFloat = 80
    private let horizontalPadding: CGFloat = KingDesignTokens.Spacing.lg
    private let iconSize: CGFloat = 22
    private let itemSpacing: CGFloat = KingDesignTokens.Spacing.xs
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                PremiumTabBarItem(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    isHovered: hoveredTab == tab,
                    namespace: animation
                ) {
                    selectTab(tab)
                }
                .onHover { isHovered in
                    withAnimation(KingDesignTokens.Animation.fast) {
                        hoveredTab = isHovered ? tab : nil
                    }
                }
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, KingDesignTokens.Spacing.md)
        .frame(height: tabBarHeight)
        .background(premiumGlassBackground)
        .overlay(premiumBorderOverlay)
        .shadow(color: KingDesignTokens.Colors.primaryText.opacity(0.08), radius: 24, x: 0, y: 12)
        .shadow(color: KingDesignTokens.Colors.accent.opacity(0.1), radius: 8, x: 0, y: 4)
        .padding(.horizontal, horizontalPadding)
        .padding(.bottom, KingDesignTokens.Spacing.sm)
    }
    
    // MARK: - Premium Glass Background
    private var premiumGlassBackground: some View {
        ZStack {
            // 강화된 글래스모피즘 효과
            RoundedRectangle(cornerRadius: 28)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(
                            KingDesignTokens.Gradients.pureGlassMorphism
                        )
                )
            
            // 서브틀한 컬러 오버레이
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        colors: [
                            KingDesignTokens.Colors.accent.opacity(0.03),
                            Color.white.opacity(0.05),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }
    
    // MARK: - Premium Border Overlay
    private var premiumBorderOverlay: some View {
        RoundedRectangle(cornerRadius: 28)
            .stroke(
                LinearGradient(
                    colors: [
                        KingDesignTokens.Colors.accent.opacity(0.3),
                        Color.white.opacity(0.2),
                        KingDesignTokens.Colors.accent.opacity(0.1),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1.5
            )
            .overlay(
                // Inner highlight for premium effect
                RoundedRectangle(cornerRadius: 28)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.4),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .center
                        ),
                        lineWidth: 0.5
                    )
                    .blendMode(.overlay)
            )
    }
    
    // MARK: - Tab Selection with Premium Haptics
    private func selectTab(_ tab: AppTab) {
        guard selectedTab != tab else { 
            // Enhanced haptic feedback for already selected tab
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.warning)
            return 
        }
        
        // Premium haptic sequence for tab change
        let impactLight = UIImpactFeedbackGenerator(style: .light)
        let impactMedium = UIImpactFeedbackGenerator(style: .medium)
        
        impactLight.impactOccurred()
        
        withAnimation(KingDesignTokens.Animation.spring) {
            selectedTab = tab
        }
        
        // Delayed medium impact for premium feel
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            impactMedium.impactOccurred(intensity: 0.7)
        }
    }
}

/// 개별 Tab Bar 아이템
/// Premium Tab Bar Item with Glassmorphism and Smooth Transitions
struct PremiumTabBarItem: View {
    let tab: AppTab
    let isSelected: Bool
    let isHovered: Bool
    let namespace: Namespace.ID
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: KingDesignTokens.Spacing.xs) {
                // Premium Icon with Dynamic Symbol Effects
                premiumIcon
                
                // Premium Label with Typography
                premiumLabel
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, KingDesignTokens.Spacing.sm)
            .background(premiumItemBackground)
            .scaleEffect(pressedScale)
            .accessibilityLabel(tab.title)
            .accessibilityHint("탭 \(tab.title)로 이동")
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: handlePress) {}
        // 무한 회전 애니메이션 제거
    }
    
    // MARK: - Premium Icon
    private var premiumIcon: some View {
        Image(systemName: iconName)
            .font(.system(size: 22, weight: iconWeight, design: .rounded))
            .symbolRenderingMode(.palette)
            .foregroundStyle(iconForegroundStyle)
            .symbolEffect(.bounce, options: .speed(0.5), value: isSelected)
            .symbolEffect(.pulse.wholeSymbol, options: .repeat(.continuous), value: isSelected)
            .scaleEffect(iconScale)
            .animation(KingDesignTokens.Animation.spring, value: isSelected)
            .animation(KingDesignTokens.Animation.fast, value: isPressed)
    }
    
    // MARK: - Premium Label  
    private var premiumLabel: some View {
        Text(tab.title)
            .font(KingDesignTokens.Typography.micro)
            .fontWeight(isSelected ? .semibold : .medium)
            .foregroundStyle(labelForegroundStyle)
            .scaleEffect(labelScale)
            .animation(KingDesignTokens.Animation.spring, value: isSelected)
    }
    
    // MARK: - Premium Item Background
    private var premiumItemBackground: some View {
        ZStack {
            if isSelected {
                // Selected state with premium glass effect
                Capsule()
                    .fill(selectedBackgroundGradient)
                    .matchedGeometryEffect(id: "selectedTabBackground", in: namespace)
                    .overlay(
                        Capsule()
                            .stroke(selectedBorderGradient, lineWidth: 1.5)
                            .matchedGeometryEffect(id: "selectedTabBorder", in: namespace)
                    )
                    .shadow(color: KingDesignTokens.Colors.accent.opacity(0.3), radius: 8, x: 0, y: 2)
                    .shadow(color: KingDesignTokens.Colors.accent.opacity(0.1), radius: 16, x: 0, y: 4)
            }
            
            if isHovered && !isSelected {
                // Hover state with subtle glass effect
                Capsule()
                    .fill(hoveredBackgroundGradient)
                    .animation(KingDesignTokens.Animation.normal, value: isHovered)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var iconName: String {
        isSelected ? tab.icon : tab.icon.replacingOccurrences(of: ".fill", with: "")
    }
    
    private var iconWeight: Font.Weight {
        isSelected ? .semibold : .medium
    }
    
    private var iconForegroundStyle: some ShapeStyle {
        if isSelected {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        KingDesignTokens.Colors.accent,
                        KingDesignTokens.Colors.accent.opacity(0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        } else {
            return AnyShapeStyle(Color.gray)
        }
    }
    
    private var labelForegroundStyle: some ShapeStyle {
        isSelected ? 
        AnyShapeStyle(KingDesignTokens.Colors.primaryText) : 
        AnyShapeStyle(Color.gray)
    }
    
    private var selectedBackgroundGradient: some ShapeStyle {
        LinearGradient(
            colors: [
                KingDesignTokens.Colors.accent.opacity(0.15),
                KingDesignTokens.Colors.accent.opacity(0.08),
                Color.white.opacity(0.1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var selectedBorderGradient: some ShapeStyle {
        LinearGradient(
            colors: [
                KingDesignTokens.Colors.accent.opacity(0.6),
                KingDesignTokens.Colors.accent.opacity(0.3),
                Color.white.opacity(0.2)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var hoveredBackgroundGradient: some ShapeStyle {
        LinearGradient(
            colors: [
                Color.white.opacity(0.08),
                Color.clear
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var pressedScale: Double {
        isPressed ? 0.92 : 1.0
    }
    
    private var iconScale: Double {
        if isPressed { return 0.85 }
        return isSelected ? 1.1 : 1.0
    }
    
    private var labelScale: Double {
        isSelected ? 1.05 : 1.0
    }
    
    // MARK: - Interaction Handlers
    
    private func handlePress(_ pressing: Bool) {
        withAnimation(KingDesignTokens.Animation.fast) {
            isPressed = pressing
        }
        
        if pressing {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred(intensity: 0.5)
        }
    }
    
    // 무한 회전 애니메이션 메서드 제거
}

