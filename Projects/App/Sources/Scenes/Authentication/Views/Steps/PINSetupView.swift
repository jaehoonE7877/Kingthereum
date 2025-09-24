import SwiftUI
import DesignSystem

/// 🔐 Professional PIN Setup
struct PremiumPINSetupView: View {
    @Bindable var viewStore: AuthenticationViewStore

    @State private var pinCode = ""
    @State private var confirmPIN = ""
    @State private var isConfirmingPIN = false

    var body: some View {
        ScrollView {
            VStack(spacing: KingDesignTokens.Spacing.xl) {
                AuthenticationGlassCard {
                    VStack(alignment: .leading, spacing: KingDesignTokens.Spacing.sm) {
                        Image(systemName: "lock.square.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(KingDesignTokens.Colors.accent)
                            .padding(.bottom, KingDesignTokens.Spacing.sm)

                        Text(isConfirmingPIN ? "PIN 확인" : "PIN 생성")
                            .font(KingDesignTokens.Typography.displayM)
                            .foregroundColor(KingDesignTokens.Colors.primaryText)

                        Text(isConfirmingPIN ? "같은 PIN을 다시 입력해 주세요." : "6자리 숫자로 PIN을 설정하세요.")
                            .font(KingDesignTokens.Typography.caption)
                            .foregroundColor(KingDesignTokens.Colors.secondaryText)
                    }
                }

                AuthenticationGlassCard {
                    VStack(spacing: KingDesignTokens.Spacing.xl) {
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

                        VStack(alignment: .leading, spacing: KingDesignTokens.Spacing.sm) {
                            Label {
                                Text("생성 팁")
                                    .font(KingDesignTokens.Typography.caption)
                                    .foregroundColor(KingDesignTokens.Colors.secondaryText)
                            } icon: {
                                Image(systemName: "shield.lefthalf.filled")
                                    .foregroundColor(KingDesignTokens.Colors.warning)
                            }

                            Text("생일이나 반복되는 숫자 조합은 피하고, 주기적으로 변경하면 보안이 강화됩니다.")
                                .font(KingDesignTokens.Typography.caption)
                                .foregroundColor(KingDesignTokens.Colors.secondaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(.horizontal, KingDesignTokens.Spacing.lg)
            .padding(.top, KingDesignTokens.Spacing.xl)
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
            viewStore.setupPIN(pin: pinCode)
        } else {
            withAnimation(KingDesignTokens.Animation.normal) {
                isConfirmingPIN = false
                pinCode = ""
                confirmPIN = ""
            }
            viewStore.showError("PIN이 일치하지 않습니다. 다시 설정해주세요.")
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
