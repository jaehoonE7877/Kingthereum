import SwiftUI
import DesignSystem
import Core
import Entity
import Factory

struct DisplayModeSelectorView: View {
    @EnvironmentObject private var displayModeService: DisplayModeService
    @State private var selectedMode: DisplayMode = .system
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("화면 모드를 선택하세요")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                
                VStack(spacing: 16) {
                    ForEach(DisplayMode.allCases, id: \.self) { mode in
                        DisplayModeOptionCard(
                            mode: mode,
                            isSelected: selectedMode == mode
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedMode = mode
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                Button {
                    displayModeService.setDisplayMode(selectedMode)
                    // UI 업데이트를 강제로 트리거
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        dismiss()
                    }
                } label: {
                    Text("적용")
                        .kingStyle(.buttonPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: DesignTokens.Size.Button.md)
                        .background(KingthereumGradients.buttonPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("취소") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                selectedMode = displayModeService.currentMode
            }
        }
    }
}

struct DisplayModeOptionCard: View {
    let mode: DisplayMode
    let isSelected: Bool
    let action: () -> Void
    
    private var iconView: some View {
        ZStack {
            Circle()
                .fill(isSelected ? Color.blue : Color.secondary.opacity(0.1))
                .frame(width: 48, height: 48)
            
            Image(systemName: mode.iconName)
                .font(.system(size: 20))
                .foregroundColor(isSelected ? .white : .secondary)
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // 아이콘
                iconView
                
                // 텍스트
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(mode.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // 체크마크
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(
                            .linearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                    .fill(isSelected ? KingthereumGradients.cardElevated : KingthereumGradients.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                    .stroke(isSelected ? KingthereumColors.accent : KingthereumColors.cardBorder, lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: KingthereumColors.cardShadow, radius: isSelected ? 8 : 4, x: 0, y: isSelected ? 4 : 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
