import SwiftUI
import DesignSystem
import SecurityKit
import Entity

/// 🔐 Professional Biometric Setup
struct PremiumBiometricSetupView: View {
    @State var viewStore: AuthenticationViewStore
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let biometricManager = BiometricAuthManager()
    
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
            if !isBiometricAvailable {
                VStack(spacing: KingDesignTokens.Spacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.orange)
                    
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
                    Task { await setupBiometric() }
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text(buttonTitle)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(buttonBackground)
                    .cornerRadius(12)
                }
                .disabled(isLoading || !isBiometricAvailable)
                
                // Text link - subtle
                Button {
                    completeSetup()
                } label: {
                    Text("Skip for now")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(KingDesignTokens.Colors.secondaryText)
                }
                .padding(.top, KingDesignTokens.Spacing.sm)
                .disabled(isLoading)
            }
            .padding(.horizontal, KingDesignTokens.Spacing.xl)
            .padding(.bottom, KingDesignTokens.Spacing.xxxl)
        }
        .alert("Biometric Setup", isPresented: $showError) {
            if !isBiometricAvailable {
                Button("Go to Settings") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                Button("Skip") { 
                    completeSetup()
                }
            } else {
                Button("Retry") {
                    Task { await setupBiometric() }
                }
                Button("Skip") { 
                    completeSetup()
                }
            }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var isBiometricAvailable: Bool {
        biometricManager.isAvailable
    }
    
    private var buttonTitle: String {
        if isLoading {
            return "Setting up..."
        } else if !isBiometricAvailable {
            return "Not Available"
        } else {
            return "Enable Biometrics"
        }
    }
    
    private var buttonBackground: Color {
        if isLoading {
            return KingDesignTokens.Colors.accent.opacity(0.7)
        } else if !isBiometricAvailable {
            return KingDesignTokens.Colors.accent.opacity(0.3)
        } else {
            return KingDesignTokens.Colors.accent
        }
    }
    
    private var biometricIconName: String {
        switch biometricManager.biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .opticID:
            return "opticid"
        case .none:
            return "lock.fill"
        }
    }
    
    private var biometricDescription: String {
        switch biometricManager.biometricType {
        case .faceID:
            return "Use Face ID for secure and quick access to your wallet"
        case .touchID:
            return "Use Touch ID for secure and quick access to your wallet"
        case .opticID:
            return "Use Optic ID for secure and quick access to your wallet"
        case .none:
            return "Biometric authentication is not available on this device"
        }
    }
    
    private func setupBiometric() async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            // 실제 생체 인증 설정 및 테스트
            let isAuthenticated = try await biometricManager.authenticate(
                reason: "Enable biometric authentication for secure wallet access"
            )
            
            if isAuthenticated {
                // 생체 인증 성공 시 설정 저장
                UserDefaults.standard.set(true, forKey: "biometric_enabled")
                UserDefaults.standard.set(true, forKey: "has_completed_biometric_setup")
                
                await MainActor.run {
                    isLoading = false
                    completeSetup()
                }
            }
            
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = handleBiometricError(error)
                showError = true
            }
        }
    }
    
    private func handleBiometricError(_ error: Error) -> String {
        if let biometricError = error as? Entity.SecurityError.BiometricError {
            switch biometricError {
            case .userCancel:
                return "Biometric authentication was cancelled. You can enable it later in Settings."
            case .userFallback:
                return "Please try again or enable biometric authentication later in Settings."
            case .biometryNotAvailable:
                return "Biometric authentication is not available on this device."
            case .notEnrolled:
                return "No biometric data is enrolled. Please set up Face ID or Touch ID in device Settings first."
            case .biometryLockout:
                return "Biometric authentication is temporarily locked. Please try again later or use your device passcode."
            case .authenticationFailed:
                return "Biometric authentication failed. Please try again."
            case .notAvailable:
                return "Biometric authentication is not available on this device."
            case .invalidContext:
                return "Biometric authentication context is invalid. Please try again."
            case .unknown(let underlyingError):
                return "An unexpected error occurred: \(underlyingError.localizedDescription)"
            }
        } else {
            return "An unexpected error occurred while setting up biometric authentication. Please try again."
        }
    }
    
    private func completeSetup() {
        // Skip 버튼의 경우 생체 인증 비활성화 상태로 저장
        if !UserDefaults.standard.bool(forKey: "has_completed_biometric_setup") {
            UserDefaults.standard.set(false, forKey: "biometric_enabled")
            UserDefaults.standard.set(true, forKey: "has_completed_biometric_setup")
        }
        
        viewStore.appCoordinator?.completeAuthentication()
    }
}