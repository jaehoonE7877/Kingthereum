import SwiftUI
import DesignSystem
import Core
import Entity
import Factory

struct DisplayModeSelectorView: View {
    @MainActor @Injected(\.displayModeService) private var displayModeService
    @State private var selectedMode: DisplayMode = .system
    @Environment(\.dismiss) private var dismiss
    
    init() {
        // Factory를 통한 자동 주입
    }
    
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
                    dismiss()
                } label: {
                    Text("적용")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            .linearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(16)
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
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.secondary.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                isSelected
                                ? AnyShapeStyle(.linearGradient(
                                    colors: [.blue.opacity(0.5), .purple.opacity(0.5)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                : AnyShapeStyle(.clear),
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
