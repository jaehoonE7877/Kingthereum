import SwiftUI
import DesignSystem
import Core
import Entity
import Factory

/// 프리미엄 피나테크 화면 모드 선택기
/// Modern Minimalism + Premium Fintech + Glassmorphism 적용
struct DisplayModeSelectorView: View {
    @EnvironmentObject private var displayModeService: DisplayModeService
    @State private var selectedMode: DisplayMode = .system
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // 프리미엄 피나테크 배경 - 다크모드 가독성 개선 그라데이션
                LinearGradient(
                    colors: [
                        KingColors.backgroundPrimary,
                        KingColors.backgroundSecondary,
                        KingColors.trustPurple.opacity(0.85)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    // 프리미엄 헤더 섹션
                    premiumHeader
                    
                    // 모드 선택 카드들
                    VStack(spacing: 20) {
                        ForEach(DisplayMode.allCases, id: \.self) { mode in
                            PremiumDisplayModeCard(
                                mode: mode,
                                isSelected: selectedMode == mode
                            ) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    selectedMode = mode
                                    // 햅틱 피드백
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    // 프리미엄 액션 버튼
                    premiumActionButton
                }
                .padding(.top, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("취소") {
                        dismiss()
                    }
                    .font(KingTypography.bodyMedium)
                    .foregroundColor(KingColors.textSecondary)
                }
            }
            .onAppear {
                selectedMode = displayModeService.currentMode
            }
        }
    }
    
    // MARK: - 프리미엄 컴포넌트들
    
    @ViewBuilder
    private var premiumHeader: some View {
        VStack(spacing: 16) {
            // 글래스 아이콘 컨테이너
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                KingColors.trustPurple.opacity(0.3),
                                KingColors.trustPurple.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 40
                        )
                    )
                    .frame(width: 80, height: 80)
                
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .background(
                            Circle()
                                .fill(KingColors.trustPurple.opacity(0.2))
                        )
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: "moon.circle.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    KingColors.trustPurple,
                                    KingColors.trustPurple.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .shadow(color: KingColors.trustPurple.opacity(0.3), radius: 12, x: 0, y: 6)
            }
            
            VStack(spacing: 8) {
                Text("화면 모드 선택")
                    .font(KingTypography.displaySmall)
                    .fontWeight(.bold)
                    .foregroundColor(KingColors.textPrimary)
                    .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                
                Text("앱 테마를 개인화하세요")
                    .font(KingTypography.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(KingColors.textSecondary)
                    .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 0.5)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 24)
    }
    
    @ViewBuilder
    private var premiumActionButton: some View {
        VStack(spacing: 16) {
            Button {
                displayModeService.setDisplayMode(selectedMode)
                
                // 성공 햅틱 피드백
                let successFeedback = UINotificationFeedbackGenerator()
                successFeedback.notificationOccurred(.success)
                
                // UI 업데이트를 강제로 트리거
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    dismiss()
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(KingTypography.bodyLarge)
                        .foregroundColor(KingColors.textInverse)
                    
                    Text("모드 적용")
                        .font(KingTypography.buttonPrimary)
                        .fontWeight(.bold)
                        .foregroundColor(KingColors.textInverse)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [
                            KingColors.trustPurple,
                            KingColors.trustPurple.opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(
                    color: KingColors.trustPurple.opacity(0.4),
                    radius: 12,
                    x: 0,
                    y: 6
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // 부가 정보
            Text("변경사항은 즉시 적용됩니다")
                .font(KingTypography.caption)
                .fontWeight(.medium)
                .foregroundColor(KingColors.textTertiary)
                .shadow(color: Color.black.opacity(0.2), radius: 0.5, x: 0, y: 0.5)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }
}

/// 프리미엄 화면 모드 선택 카드
struct PremiumDisplayModeCard: View {
    let mode: DisplayMode
    let isSelected: Bool
    let action: () -> Void
    
    // 모드별 액센트 컬러
    private var accentColor: Color {
        switch mode {
        case .light:
            return KingColors.exclusiveGold
        case .dark:
            return KingColors.trustPurple
        case .system:
            return KingColors.info
        }
    }
    
    private var premiumIcon: some View {
        ZStack {
            // 외부 글로우 효과
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            accentColor.opacity(isSelected ? 0.4 : 0.2),
                            accentColor.opacity(isSelected ? 0.2 : 0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 30
                    )
                )
                .frame(width: 60, height: 60)
            
            // 메인 아이콘 컨테이너
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .background(
                        Circle()
                            .fill(accentColor.opacity(isSelected ? 0.3 : 0.15))
                    )
                    .frame(width: 48, height: 48)
                
                // 테두리 효과 (선택 시)
                if isSelected {
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [
                                    accentColor,
                                    accentColor.opacity(0.3),
                                    accentColor,
                                    accentColor.opacity(0.6),
                                    accentColor
                                ],
                                center: .center
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 48, height: 48)
                }
                
                // 아이콘
                Image(systemName: mode.iconName)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                accentColor,
                                accentColor.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .shadow(color: accentColor.opacity(isSelected ? 0.3 : 0.1), radius: isSelected ? 8 : 4, x: 0, y: 2)
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                // 프리미엄 아이콘
                premiumIcon
                
                // 텍스트 정보
                VStack(alignment: .leading, spacing: 6) {
                    Text(mode.displayName)
                        .font(KingTypography.bodyLarge)
                        .fontWeight(.bold)
                        .foregroundColor(KingColors.textPrimary)
                        .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 0.5)
                    
                    Text(mode.description)
                        .font(KingTypography.bodySmall)
                        .fontWeight(.medium)
                        .foregroundColor(KingColors.textSecondary)
                        .shadow(color: Color.black.opacity(0.2), radius: 0.5, x: 0, y: 0.5)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // 선택 상태 표시
                ZStack {
                    // 배경 원
                    Circle()
                        .fill(isSelected ? accentColor.opacity(0.2) : KingColors.textTertiary.opacity(0.1))
                        .frame(width: 28, height: 28)
                    
                    if isSelected {
                        // 체크마크 아이콘
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(accentColor)
                    } else {
                        // 빈 원 테두리
                        Circle()
                            .stroke(KingColors.textTertiary.opacity(0.3), lineWidth: 1.5)
                            .frame(width: 18, height: 18)
                    }
                }
            }
            .padding(24)
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            isSelected 
                            ? accentColor.opacity(0.05)
                            : KingColors.glassMinimalBase
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isSelected 
                            ? accentColor.opacity(0.3) 
                            : KingColors.glassBorder,
                            lineWidth: isSelected ? 1.5 : 0.5
                        )
                )
        )
        .shadow(
            color: isSelected 
            ? accentColor.opacity(0.2) 
            : KingColors.glassShadow,
            radius: isSelected ? 12 : 6,
            x: 0,
            y: isSelected ? 6 : 3
        )
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Preview

#Preview("Premium DisplayModeSelector") {
    DisplayModeSelectorView()
        .environmentObject(DisplayModeService())
        .preferredColorScheme(.dark)
}

#Preview("Premium DisplayModeSelector - Light") {
    DisplayModeSelectorView()
        .environmentObject(DisplayModeService())
        .preferredColorScheme(.light)
}
