import SwiftUI
import DesignSystem

/// iOS 18 스타일의 커스텀 Tab Bar 구현
/// Liquid Glass 효과를 SwiftUI의 Material과 blur로 재현
struct CustomTabBar: View {
    @Binding var selectedTab: AppTab
    @Namespace private var animation
    @State private var hoveredTab: AppTab?
    
    // 탭바 높이 및 패딩
    private let tabBarHeight: CGFloat = 72
    private let horizontalPadding: CGFloat = DesignTokens.Spacing.lg
    private let iconSize: CGFloat = DesignTokens.Size.Icon.md
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                TabBarItem(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    isHovered: hoveredTab == tab,
                    namespace: animation
                ) {
                    // 이미 선택된 탭을 다시 누르면 무시
                    guard selectedTab != tab else { return }
                    
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                        selectedTab = tab
                    }
                    
                    // 햅틱 피드백 (가벼운 햅틱만)
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                }
                .onHover { isHovered in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        hoveredTab = isHovered ? tab : nil
                    }
                }
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, DesignTokens.Spacing.md)
        .frame(height: tabBarHeight)
        .background(
            ZStack {
                // Metal Liquid Glass 반투명 배경
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                KingGradients.glassMorphism
                                    .opacity(0.3)
                            )
                    )
                
                // 고급스러운 테두리 효과
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [
                                KingColors.accent.opacity(0.2),
                                KingColors.accentSecondary.opacity(0.1),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                
                // 내부 하이라이트 효과
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.clear,
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.5
                    )
                    .blendMode(.overlay)
            }
        )
        .shadow(color: KingColors.cardShadow, radius: 12, x: 0, y: 8)
        .shadow(color: KingColors.accent.opacity(0.1), radius: 6, x: 0, y: 4)
        .padding(.horizontal, horizontalPadding)
        .padding(.bottom, DesignTokens.Spacing.sm)
    }
}

/// 개별 Tab Bar 아이템
struct TabBarItem: View {
    let tab: AppTab
    let isSelected: Bool
    let isHovered: Bool
    let namespace: Namespace.ID
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignTokens.Spacing.xs) {
                // 아이콘
                Image(systemName: isSelected ? tab.icon : tab.icon.replacingOccurrences(of: ".fill", with: ""))
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(
                        isSelected ? 
                        KingGradients.accent : 
                        LinearGradient(
                            colors: [KingColors.textSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(isPressed ? 0.9 : (isSelected ? 1.05 : 1.0))
                    .animation(.easeInOut(duration: 0.15), value: isPressed)
                    .animation(.easeInOut(duration: 0.15), value: isSelected)
                
                // 라벨
                Text(tab.title)
                    .kingStyle(isSelected ? 
                        KingTextStyle(
                            font: KingTypography.tabBar,
                            color: KingColors.textPrimary
                        ) : 
                        KingTextStyle(
                            font: KingTypography.tabBar,
                            color: KingColors.textSecondary
                        )
                    )
                    .scaleEffect(isSelected ? 1.02 : 1.0)
                    .animation(.easeInOut(duration: 0.15), value: isSelected)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(
                ZStack {
                    if isSelected {
                        // 선택된 탭 배경
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        KingColors.accent.opacity(0.15),
                                        KingColors.accentSecondary.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .matchedGeometryEffect(id: "selectedTab", in: namespace)
                        
                        // 선택된 탭 테두리 효과
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        KingColors.accent.opacity(0.3),
                                        KingColors.accentSecondary.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                            .matchedGeometryEffect(id: "selectedTabBorder", in: namespace)
                    }
                    
                    if isHovered && !isSelected {
                        // 호버 효과
                        Capsule()
                            .fill(KingColors.textSecondary.opacity(0.08))
                            .animation(.easeInOut(duration: 0.2), value: isHovered)
                    }
                }
            )
            .accessibilityLabel(tab.title)
            .accessibilityHint("탭 \(tab.title)로 이동")
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

