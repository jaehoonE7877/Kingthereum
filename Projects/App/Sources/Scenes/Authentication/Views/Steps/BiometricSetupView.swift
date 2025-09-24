import SwiftUI
import DesignSystem

/// 🔐 Professional Biometric Setup
struct PremiumBiometricSetupView: View {
    @Bindable var viewStore: AuthenticationViewStore

    var body: some View {
        ScrollView {
            VStack(spacing: KingDesignTokens.Spacing.xl) {
                AuthenticationGlassCard {
                    VStack(alignment: .leading, spacing: KingDesignTokens.Spacing.sm) {
                        Image(systemName: biometricIconName)
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(KingDesignTokens.Colors.accent)
                            .padding(.bottom, KingDesignTokens.Spacing.sm)

                        Text("생체 인증 연결")
                            .font(KingDesignTokens.Typography.displayM)
                            .foregroundColor(KingDesignTokens.Colors.primaryText)

                        Text(biometricDescription)
                            .font(KingDesignTokens.Typography.caption)
                            .foregroundColor(KingDesignTokens.Colors.secondaryText)
                    }
                }

                if !viewStore.biometricAvailable {
                    AuthenticationGlassCard {
                        VStack(alignment: .leading, spacing: KingDesignTokens.Spacing.sm) {
                            Label("사용 불가", systemImage: "exclamationmark.triangle.fill")
                                .font(KingDesignTokens.Typography.caption)
                                .foregroundColor(KingDesignTokens.Colors.warning)

                            Text("설정 > Face ID & 암호 또는 Touch ID에서 생체 인증을 활성화한 뒤 다시 시도하세요.")
                                .font(KingDesignTokens.Typography.caption)
                                .foregroundColor(KingDesignTokens.Colors.secondaryText)
                        }
                    }
                }
            }
            .padding(.horizontal, KingDesignTokens.Spacing.lg)
            .padding(.top, KingDesignTokens.Spacing.xl)
            .padding(.bottom, 140)
        }
        .safeAreaInset(edge: .bottom) {
            AuthenticationCTAContainer {
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
                            .font(KingDesignTokens.Typography.body)
                            .fontWeight(.semibold)
                            .foregroundColor(KingDesignTokens.Colors.systemWhite)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(buttonBackground)
                    .cornerRadius(KingDesignTokens.Radius.lg)
                }
                .disabled(viewStore.isLoading || !viewStore.biometricAvailable)

                Button {
                    viewStore.skipBiometricSetup()
                } label: {
                    Text("나중에 설정")
                        .font(KingDesignTokens.Typography.body)
                        .foregroundColor(KingDesignTokens.Colors.secondaryText)
                        .frame(maxWidth: .infinity)
                }
                .disabled(viewStore.isLoading)
            }
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
