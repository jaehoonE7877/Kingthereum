import SwiftUI
import DesignSystem
import SecurityKit
import Entity

/// 🔐 Professional Biometric Setup
struct PremiumBiometricSetupView: View {
    @Bindable var viewStore: AuthenticationViewStore
    
    var body: some View {
        VStack(spacing: 0) {
            // Top spacing
            Spacer()
                .frame(height: KingDesignTokens.Spacing.xxxl * 2)
            
            // Biometric icon and content
            VStack(spacing: KingDesignTokens.Spacing.xl) {
                // Simple Face ID icon - no decorative circle
                Image(systemName: biometricIconName)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(KingDesignTokens.Colors.accent)
                
                VStack(spacing: KingDesignTokens.Spacing.sm) {
                    Text("Enable Biometrics")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(KingDesignTokens.Colors.primaryText)
                    
                    Text(biometricDescription)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(KingDesignTokens.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Flexible spacer
            Spacer()
            
            // Biometric not available warning
            if !viewStore.biometricAvailable {
                VStack(spacing: KingDesignTokens.Spacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(KingDesignTokens.Colors.warning)
                    
                    Text("Biometric authentication is not available")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(KingDesignTokens.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                    
                    Text("Please enable Face ID or Touch ID in device Settings")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(KingDesignTokens.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, KingDesignTokens.Spacing.xl)
                .padding(.bottom, KingDesignTokens.Spacing.md)
            }
            
            // Action buttons - Professional style
            VStack(spacing: KingDesignTokens.Spacing.md) {
                // Primary CTA
                Button {
                    viewStore.authenticateWithBiometrics(
                        reason: "Enable biometric authentication for secure wallet access"
                    )
                } label: {
                    HStack {
                        if viewStore.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text(buttonTitle)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(KingDesignTokens.Colors.systemWhite)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(buttonBackground)
                    .cornerRadius(12)
                }
                .disabled(viewStore.isLoading || !viewStore.biometricAvailable)

                // Text link - subtle
                Button {
                    viewStore.skipBiometricSetup()
                } label: {
                    Text("Skip for now")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(KingDesignTokens.Colors.secondaryText)
                }
                .padding(.top, KingDesignTokens.Spacing.sm)
                .disabled(viewStore.isLoading)
            }
            .padding(.horizontal, KingDesignTokens.Spacing.xl)
            .padding(.bottom, KingDesignTokens.Spacing.xxxl)
        }
    }

    private var buttonTitle: String {
        if viewStore.isLoading {
            return "Setting up..."
        } else if !viewStore.biometricAvailable {
            return "Not Available"
        } else {
            return "Enable Biometrics"
        }
    }

    private var buttonBackground: Color {
        if viewStore.isLoading {
            return KingDesignTokens.Colors.accent.opacity(0.7)
        } else if !viewStore.biometricAvailable {
            return KingDesignTokens.Colors.accent.opacity(0.3)
        } else {
            return KingDesignTokens.Colors.accent
        }
    }

    private var biometricIconName: String {
        viewStore.biometricIconName
    }

    private var biometricDescription: String {
        viewStore.biometricDescription
    }
}
