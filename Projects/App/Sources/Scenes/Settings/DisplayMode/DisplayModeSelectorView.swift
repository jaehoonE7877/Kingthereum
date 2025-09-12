import SwiftUI
import DesignSystem
import Core
import Entity
import Factory

/// Premium Fintech Display Mode Selector - Minimalist Design
struct DisplayModeSelectorView: View {
    @EnvironmentObject private var displayModeService: DisplayModeService
    @State private var selectedMode: DisplayMode = .system
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Top spacing
                Spacer()
                    .frame(height: KingDesignTokens.Spacing.xxxl * 2)
                
                // Header section - Minimal
                VStack(spacing: KingDesignTokens.Spacing.xl) {
                    // Simple theme icon
                    Image(systemName: "paintbrush.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(KingDesignTokens.Colors.accent)
                    
                    VStack(spacing: KingDesignTokens.Spacing.sm) {
                        Text("Display Mode")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(KingDesignTokens.Colors.primaryText)
                        
                        Text("Choose your preferred theme")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(KingDesignTokens.Colors.secondaryText)
                    }
                }
                
                // Flexible spacer
                Spacer()
                
                // Mode selection cards - Clean design
                VStack(spacing: KingDesignTokens.Spacing.md) {
                    ForEach(DisplayMode.allCases, id: \.self) { mode in
                        MinimalistDisplayModeCard(
                            mode: mode,
                            isSelected: selectedMode == mode
                        ) {
                            selectedMode = mode
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                        }
                    }
                }
                .padding(.horizontal, KingDesignTokens.Spacing.xl)
                
                // Flexible spacer
                Spacer()
                
                // Action button - Professional
                actionButton
            }
            .background(KingDesignTokens.Colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(KingDesignTokens.Colors.secondaryText)
                }
            }
            .onAppear {
                selectedMode = displayModeService.currentMode
            }
        }
    }
    
    // MARK: - Clean Components
    
    @ViewBuilder
    private var actionButton: some View {
        VStack(spacing: KingDesignTokens.Spacing.md) {
            Button {
                displayModeService.setDisplayMode(selectedMode)
                
                let successFeedback = UINotificationFeedbackGenerator()
                successFeedback.notificationOccurred(.success)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    dismiss()
                }
            } label: {
                Text("Apply Mode")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(KingDesignTokens.Colors.accent)
                    .cornerRadius(12)
            }
            
            Text("Changes apply immediately")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(KingDesignTokens.Colors.tertiaryText)
        }
        .padding(.horizontal, KingDesignTokens.Spacing.xl)
        .padding(.bottom, KingDesignTokens.Spacing.xxxl)
    }
}

/// Minimalist Display Mode Card
struct MinimalistDisplayModeCard: View {
    let mode: DisplayMode
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: KingDesignTokens.Spacing.lg) {
                // Simple mode icon
                ZStack {
                    Circle()
                        .fill(isSelected ? KingDesignTokens.Colors.accent : KingDesignTokens.Colors.surface)
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: mode.iconName)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isSelected ? .white : KingDesignTokens.Colors.accent)
                }
                
                // Mode info
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.displayName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(KingDesignTokens.Colors.primaryText)
                    
                    Text(mode.description)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(KingDesignTokens.Colors.secondaryText)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(KingDesignTokens.Colors.accent)
                } else {
                    Circle()
                        .stroke(KingDesignTokens.Colors.border, lineWidth: 1.5)
                        .frame(width: 20, height: 20)
                }
            }
            .padding(KingDesignTokens.Spacing.lg)
        }
        .buttonStyle(PlainButtonStyle())
        .background(KingDesignTokens.Colors.surface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isSelected ? KingDesignTokens.Colors.accent : Color.clear,
                    lineWidth: 2
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Preview

#Preview("Minimalist DisplayModeSelector") {
    DisplayModeSelectorView()
        .environmentObject(DisplayModeService())
        .preferredColorScheme(.dark)
}

#Preview("Minimalist DisplayModeSelector - Light") {
    DisplayModeSelectorView()
        .environmentObject(DisplayModeService())
        .preferredColorScheme(.light)
}
