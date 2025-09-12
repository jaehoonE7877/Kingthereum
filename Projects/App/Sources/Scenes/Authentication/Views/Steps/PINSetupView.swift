import SwiftUI
import DesignSystem

/// 🔐 Professional PIN Setup
struct PremiumPINSetupView: View {
    @State var viewStore: AuthenticationViewStore

    @State private var pinCode = ""
    @State private var confirmPIN = ""
    @State private var isConfirmingPIN = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Top spacing
            Spacer()
                .frame(height: KingDesignTokens.Spacing.xxxl * 2)
            
            // Header section - Minimal & professional
            VStack(spacing: KingDesignTokens.Spacing.xl) {
                // Simple lock icon - no gradients
                Image(systemName: "lock.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(KingDesignTokens.Colors.accent)
                
                VStack(spacing: KingDesignTokens.Spacing.sm) {
                    Text(isConfirmingPIN ? "Confirm PIN" : "Create PIN")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(KingDesignTokens.Colors.primaryText)
                    
                    Text(isConfirmingPIN ? "Enter your PIN again" : "Enter 6-digit PIN")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(KingDesignTokens.Colors.secondaryText)
                }
            }
            
            Spacer()
            
            // PIN 입력 섹션
            PremiumPINField(
                pin: isConfirmingPIN ? $confirmPIN : $pinCode,
                length: 6
            ) { pin in
                if isConfirmingPIN {
                    handlePINConfirmation(pin)
                } else {
                    handlePINEntry(pin)
                }
            }
            
            // Flexible spacer
            Spacer()
            
            // Minimal security guide
            VStack(spacing: KingDesignTokens.Spacing.sm) {
                Text("Keep your PIN secure")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(KingDesignTokens.Colors.primaryText)
                
                Text("Don't use birthdays or obvious patterns")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(KingDesignTokens.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, KingDesignTokens.Spacing.xl)
            .padding(.bottom, KingDesignTokens.Spacing.xxxl)
        }
    }
    
    private func handlePINEntry(_ pin: String) {
        pinCode = pin
        withAnimation(KingDesignTokens.Animation.normal) {
            isConfirmingPIN = true
        }
    }
    
    private func handlePINConfirmation(_ pin: String) {
        if pin == pinCode {
            viewStore.currentStep = .biometricSetup
        } else {
            withAnimation(KingDesignTokens.Animation.normal) {
                isConfirmingPIN = false
                pinCode = ""
                confirmPIN = ""
            }
            viewStore.errorMessage = "PIN이 일치하지 않습니다. 다시 설정해주세요."
        }
    }
}

// MARK: - Supporting Components

/// Professional PIN Input Field
struct PremiumPINField: View {
    @Binding var pin: String
    let length: Int
    let onComplete: (String) -> Void
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: KingDesignTokens.Spacing.xl) {
            // Hidden input field
            TextField("", text: $pin)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .opacity(0)
                .frame(height: 0)
                .focused($isFocused)
                .onChange(of: pin) { _, newValue in
                    if newValue.count > length {
                        pin = String(newValue.prefix(length))
                    }
                    
                    if pin.count == length {
                        onComplete(pin)
                    }
                }
            
            // PIN visualization - Minimal circles
            HStack(spacing: KingDesignTokens.Spacing.lg) {
                ForEach(0..<length, id: \.self) { index in
                    Circle()
                        .fill(
                            index < pin.count ?
                            KingDesignTokens.Colors.accent :
                            KingDesignTokens.Colors.border
                        )
                        .frame(width: 16, height: 16)
                        .animation(.easeInOut(duration: 0.2), value: pin)
                }
            }
            
            Text("Tap to enter PIN")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(KingDesignTokens.Colors.tertiaryText)
        }
        .onTapGesture {
            isFocused = true
        }
        .onAppear {
            isFocused = true
        }
    }
}

