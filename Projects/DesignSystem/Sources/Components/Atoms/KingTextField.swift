import SwiftUI

// MARK: - Premium Text Field Component
public struct KingTextField: View {
    public enum Style {
        case standard   // 기본 스타일
        case filled     // 채워진 배경
        case outlined   // 테두리 스타일
        case glass      // 글래스모피즘
    }
    
    public enum InputType {
        case text
        case email
        case number
        case secure
        case multiline(lines: Int = 3)
    }
    
    @Binding var text: String
    let placeholder: String
    let label: String?
    let helper: String?
    let error: String?
    let icon: String?
    let style: Style
    let inputType: InputType
    let isRequired: Bool
    
    @State private var isFocused = false
    @State private var isSecureTextVisible = false
    @FocusState private var fieldFocus: Bool
    
    public init(
        _ placeholder: String,
        text: Binding<String>,
        label: String? = nil,
        helper: String? = nil,
        error: String? = nil,
        icon: String? = nil,
        style: Style = .standard,
        inputType: InputType = .text,
        isRequired: Bool = false
    ) {
        self.placeholder = placeholder
        self._text = text
        self.label = label
        self.helper = helper
        self.error = error
        self.icon = icon
        self.style = style
        self.inputType = inputType
        self.isRequired = isRequired
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: KingDesignTokens.Spacing.xs) {
            // Label
            if let label = label {
                HStack(spacing: KingDesignTokens.Spacing.xxs) {
                    Text(label)
                        .font(KingDesignTokens.Typography.labelMedium)
                        .foregroundColor(KingDesignTokens.Colors.primaryText)
                    
                    if isRequired {
                        Text("*")
                            .font(KingDesignTokens.Typography.labelMedium)
                            .foregroundColor(KingDesignTokens.Colors.error)
                    }
                }
                .accessibilityElement(children: .combine)
            }
            
            // Input Field
            HStack(spacing: KingDesignTokens.Spacing.sm) {
                // Leading Icon
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: KingDesignTokens.Sizing.iconSM))
                        .foregroundColor(iconColor)
                        .frame(width: KingDesignTokens.Sizing.iconMD)
                }
                
                // Text Input
                inputFieldView
                    .font(KingDesignTokens.Typography.body)
                    .foregroundColor(KingDesignTokens.Colors.primaryText)
                    .accentColor(KingDesignTokens.Colors.primary)
                
                // Trailing Elements
                HStack(spacing: KingDesignTokens.Spacing.xs) {
                    // Clear Button
                    if !text.isEmpty && isFocused {
                        Button(action: { text = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: KingDesignTokens.Sizing.iconSM))
                                .foregroundColor(KingDesignTokens.Colors.tertiaryText)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Secure Text Toggle
                    if case .secure = inputType {
                        Button(action: { isSecureTextVisible.toggle() }) {
                            Image(systemName: isSecureTextVisible ? "eye.slash.fill" : "eye.fill")
                                .font(.system(size: KingDesignTokens.Sizing.iconSM))
                                .foregroundColor(KingDesignTokens.Colors.tertiaryText)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Error Icon
                    if error != nil {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: KingDesignTokens.Sizing.iconSM))
                            .foregroundColor(KingDesignTokens.Colors.error)
                    }
                }
            }
            .padding(.horizontal, KingDesignTokens.Spacing.m)
            .padding(.vertical, KingDesignTokens.Spacing.sm)
            .background(fieldBackground)
            .overlay(fieldOverlay)
            .clipShape(RoundedRectangle(cornerRadius: KingDesignTokens.Radius.sm))
            .animation(KingDesignTokens.Animation.fast, value: isFocused)
            .animation(KingDesignTokens.Animation.fast, value: error != nil)
            
            // Helper/Error Text
            if let error = error {
                Text(error)
                    .font(KingDesignTokens.Typography.micro)
                    .foregroundColor(KingDesignTokens.Colors.error)
                    .accessibilityLabel("오류: \(error)")
            } else if let helper = helper {
                Text(helper)
                    .font(KingDesignTokens.Typography.micro)
                    .foregroundColor(KingDesignTokens.Colors.tertiaryText)
            }
        }
        .onChange(of: fieldFocus) { _, focused in
            withAnimation(KingDesignTokens.Animation.fast) {
                isFocused = focused
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(helper ?? "")
    }
    
    // MARK: - Computed Properties
    
    @ViewBuilder
    private var inputFieldView: some View {
        Group {
            switch inputType {
            case .text, .email, .number:
                TextField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(TextInputAutocapitalization(autocapitalization))
                    .focused($fieldFocus)
            
            case .secure:
                if isSecureTextVisible {
                    TextField(placeholder, text: $text)
                        .textFieldStyle(.plain)
                        .focused($fieldFocus)
                } else {
                    SecureField(placeholder, text: $text)
                        .textFieldStyle(.plain)
                        .focused($fieldFocus)
                }
            
            case .multiline(let lines):
                TextEditor(text: $text)
                    .frame(minHeight: CGFloat(lines * 20))
                    .scrollContentBackground(.hidden)
                    .focused($fieldFocus)
            }
        }
    }
    
    @ViewBuilder
    private var fieldBackground: some View {
        switch style {
        case .standard:
            KingDesignTokens.Colors.surfaceSecondary
        case .filled:
            KingDesignTokens.Colors.surfaceVariant
        case .outlined:
            KingDesignTokens.Colors.surface
        case .glass:
            Rectangle()
                .fill(.clear)
                .background(KingDesignTokens.Glass.ultraThin)
        }
    }
    
    @ViewBuilder
    private var fieldOverlay: some View {
        RoundedRectangle(cornerRadius: KingDesignTokens.Radius.sm)
            .stroke(borderColor, lineWidth: borderWidth)
    }
    
    private var borderColor: Color {
        if error != nil {
            return KingDesignTokens.Colors.error
        } else if isFocused {
            return KingDesignTokens.Colors.primary
        } else {
            switch style {
            case .outlined:
                return KingDesignTokens.Colors.border
            case .glass:
                return KingDesignTokens.Colors.outline
            default:
                return Color.clear
            }
        }
    }
    
    private var borderWidth: CGFloat {
        if isFocused {
            return KingDesignTokens.BorderWidth.regular
        } else {
            switch style {
            case .outlined, .glass:
                return KingDesignTokens.BorderWidth.thin
            default:
                return 0
            }
        }
    }
    
    private var iconColor: Color {
        if error != nil {
            return KingDesignTokens.Colors.error
        } else if isFocused {
            return KingDesignTokens.Colors.primary
        } else {
            return KingDesignTokens.Colors.tertiaryText
        }
    }
    
    private var keyboardType: UIKeyboardType {
        switch inputType {
        case .email:
            return .emailAddress
        case .number:
            return .decimalPad
        default:
            return .default
        }
    }
    
    private var autocapitalization: UITextAutocapitalizationType {
        switch inputType {
        case .email:
            return .none
        default:
            return .sentences
        }
    }
    
    private var accessibilityLabel: String {
        var result = label ?? placeholder
        if isRequired {
            result += ", 필수 입력"
        }
        if let error = error {
            result += ", 오류: \(error)"
        }
        return result
    }
}

// MARK: - Specialized Fields

/// 주소 입력 전용 필드
public struct KingAddressField: View {
    @Binding var address: String
    let label: String
    let helper: String?
    let onScan: (() -> Void)?
    let onPaste: (() -> Void)?
    
    public init(
        address: Binding<String>,
        label: String = "지갑 주소",
        helper: String? = nil,
        onScan: (() -> Void)? = nil,
        onPaste: (() -> Void)? = nil
    ) {
        self._address = address
        self.label = label
        self.helper = helper
        self.onScan = onScan
        self.onPaste = onPaste
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: KingDesignTokens.Spacing.xs) {
            Text(label)
                .font(KingDesignTokens.Typography.labelMedium)
                .foregroundColor(KingDesignTokens.Colors.primaryText)
            
            HStack(spacing: KingDesignTokens.Spacing.xs) {
                KingTextField(
                    "0x...",
                    text: $address,
                    helper: helper,
                    icon: "wallet.pass",
                    style: .glass
                )
                
                // Action Buttons
                HStack(spacing: KingDesignTokens.Spacing.xs) {
                    if let onScan = onScan {
                        Button(action: onScan) {
                            Image(systemName: "qrcode.viewfinder")
                                .font(.system(size: KingDesignTokens.Sizing.iconMD))
                                .foregroundColor(KingDesignTokens.Colors.primary)
                                .frame(width: 44, height: 44)
                                .background(
                                    Rectangle()
                                        .fill(.clear)
                                        .background(KingDesignTokens.Glass.ultraThin)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: KingDesignTokens.Radius.sm))
                        }
                    }
                    
                    if let onPaste = onPaste {
                        Button(action: onPaste) {
                            Image(systemName: "doc.on.clipboard")
                                .font(.system(size: KingDesignTokens.Sizing.iconMD))
                                .foregroundColor(KingDesignTokens.Colors.primary)
                                .frame(width: 44, height: 44)
                                .background(
                                    Rectangle()
                                        .fill(.clear)
                                        .background(KingDesignTokens.Glass.ultraThin)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: KingDesignTokens.Radius.sm))
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview("KingTextField Variants") {
    ScrollView {
        VStack(spacing: KingDesignTokens.Spacing.xl) {
            // Standard Fields
            KingTextField(
                "Enter your name",
                text: .constant("John Doe"),
                label: "Full Name",
                helper: "Please enter your full legal name",
                icon: "person.fill",
                style: .standard,
                isRequired: true
            )
            
            // Filled Style
            KingTextField(
                "Email address",
                text: .constant(""),
                label: "Email",
                icon: "envelope.fill",
                style: .filled,
                inputType: .email
            )
            
            // Outlined Style
            KingTextField(
                "Amount",
                text: .constant("0.0"),
                label: "ETH Amount",
                helper: "Minimum: 0.001 ETH",
                icon: "bitcoinsign.circle.fill",
                style: .outlined,
                inputType: .number
            )
            
            // Glass Style with Error
            KingTextField(
                "Password",
                text: .constant(""),
                label: "Password",
                error: "Password must be at least 8 characters",
                icon: "lock.fill",
                style: .glass,
                inputType: .secure,
                isRequired: true
            )
            
            // Multiline Field
            KingTextField(
                "Enter your message...",
                text: .constant(""),
                label: "Message",
                helper: "Maximum 500 characters",
                style: .glass,
                inputType: .multiline(lines: 4)
            )
            
            // Address Field
            KingAddressField(
                address: .constant(""),
                helper: "Enter recipient's wallet address",
                onScan: { print("Scan QR") },
                onPaste: { print("Paste from clipboard") }
            )
        }
        .padding()
    }
    .background(KingDesignTokens.Colors.background)
}