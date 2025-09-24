import SwiftUI
import DesignSystem
import Entity

/// 🔐 Premium Fintech Welcome - Minimalist Design
struct PremiumWelcomeView: View {
    @Bindable var viewStore: AuthenticationViewStore
    
    var body: some View {
        VStack(spacing: 0) {
            // Top spacing
            Spacer()
                .frame(height: KingDesignTokens.Spacing.xxxl * 2)
            
            // Brand section - Minimal geometric logo
            VStack(spacing: KingDesignTokens.Spacing.xxxl) {
                // Abstract geometric logo
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(KingDesignTokens.Colors.accent, lineWidth: 3)
                        .frame(width: 80, height: 80)
                    
                    // Inner elements - abstract geometric shapes
                    VStack(spacing: 2) {
                        Rectangle()
                            .fill(KingDesignTokens.Colors.accent)
                            .frame(width: 24, height: 3)
                            .cornerRadius(1.5)
                        
                        Rectangle()
                            .fill(KingDesignTokens.Colors.accent)
                            .frame(width: 16, height: 3)
                            .cornerRadius(1.5)
                        
                        Rectangle()
                            .fill(KingDesignTokens.Colors.accent)
                            .frame(width: 20, height: 3)
                            .cornerRadius(1.5)
                    }
                }
                
                // Brand identity - Professional & minimal
                VStack(spacing: KingDesignTokens.Spacing.md) {
                    Text("Kingthereum")
                        .font(.system(size: 32, weight: .semibold, design: .default))
                        .foregroundColor(KingDesignTokens.Colors.primaryText)
                    
                    Text("Secure crypto wallet")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(KingDesignTokens.Colors.secondaryText)
                }
            }
            
            // Flexible spacer for vertical centering
            Spacer()
            
            // Action buttons - Bottom anchored iOS pattern
            VStack(spacing: KingDesignTokens.Spacing.md) {
                // Primary CTA - Create wallet
                Button {
                    viewStore.createWallet(named: "My Wallet")
                } label: {
                    HStack {
                        Text("Create Wallet")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(KingDesignTokens.Colors.systemWhite)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(KingDesignTokens.Colors.accent)
                    .cornerRadius(12)
                }
                .disabled(viewStore.isLoading)
                .opacity(viewStore.isLoading ? 0.6 : 1.0)
                
                // Secondary CTA - Import wallet
                Button {
                    viewStore.requestFlow(.showWalletImport)
                } label: {
                    HStack {
                        Text("Import Wallet")
                            .font(.system(size: 17, weight: .medium))
                    }
                    .foregroundColor(KingDesignTokens.Colors.accent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(KingDesignTokens.Colors.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(KingDesignTokens.Colors.accent, lineWidth: 1)
                    )
                }
                .disabled(viewStore.isLoading)
                .opacity(viewStore.isLoading ? 0.6 : 1.0)
                
                // Legal disclaimer - Professional trust indicator
                Text("Your keys, your crypto. Always.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(KingDesignTokens.Colors.tertiaryText)
                    .padding(.top, KingDesignTokens.Spacing.sm)
            }
            .padding(.horizontal, KingDesignTokens.Spacing.xl)
            .padding(.bottom, KingDesignTokens.Spacing.xxxl)
        }
        .background(KingDesignTokens.Colors.background)
        .overlay(
            // Loading overlay
            Group {
                if viewStore.isLoading {
                    LoadingOverlay()
                }
            }
        )
    }
    
    // MARK: - Private Methods
    
}

// MARK: - Supporting Views

/// Professional loading overlay
private struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            KingDesignTokens.Colors.background.opacity(0.9)
                .ignoresSafeArea(.all)
            
            VStack(spacing: KingDesignTokens.Spacing.md) {
                ProgressView()
                    .tint(KingDesignTokens.Colors.accent)
                
                Text("Creating wallet...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(KingDesignTokens.Colors.secondaryText)
            }
        }
    }
}
