import SwiftUI

// MARK: - Glass TextField (Minimalist Revolut Style)
public struct GlassTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String?
    let isSecure: Bool
    let keyboardType: UIKeyboardType
    let validation: ValidationState?
    
    @State private var isEditing = false
    @State private var showPassword = false
    
    public enum ValidationState {
        case valid
        case invalid(String)
        
        var color: Color {
            switch self {
            case .valid: return KingDesignTokens.Colors.success
            case .invalid: return KingDesignTokens.Colors.error
            }
        }
        
        var icon: String {
            switch self {
            case .valid: return "checkmark.circle"
            case .invalid: return "xmark.circle"
            }
        }
    }
    
    public init(
        text: Binding<String>,
        placeholder: String,
        icon: String? = nil,
        isSecure: Bool = false,
        keyboardType: UIKeyboardType = .default,
        validation: ValidationState? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.icon = icon
        self.isSecure = isSecure
        self.keyboardType = keyboardType
        self.validation = validation
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: KingDesignTokens.Spacing.xs) {
            // Input Field
            HStack(spacing: KingDesignTokens.Spacing.sm) {
                // Leading Icon
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(
                            isEditing
                            ? KingDesignTokens.Colors.primary
                            : KingDesignTokens.Colors.secondaryText
                        )
                        .frame(width: 20)
                }
                
                // Text Field
                Group {
                    if isSecure && !showPassword {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text, onEditingChanged: { editing in
                            withAnimation(KingDesignTokens.Animation.fast) {
                                isEditing = editing
                            }
                        })
                    }
                }
                .font(KingDesignTokens.Typography.body)
                .foregroundColor(KingDesignTokens.Colors.primary)
                .keyboardType(keyboardType)
                .textFieldStyle(PlainTextFieldStyle())
                
                // Trailing Actions
                HStack(spacing: KingDesignTokens.Spacing.xs) {
                    // Validation Icon
                    if let validation = validation, !text.isEmpty {
                        Image(systemName: validation.icon)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(validation.color)
                    }
                    
                    // Password Toggle
                    if isSecure {
                        Button(action: { showPassword.toggle() }) {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(KingDesignTokens.Colors.secondaryText)
                        }
                    }
                    
                    // Clear Button
                    if !text.isEmpty && !isSecure {
                        Button(action: { text = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(KingDesignTokens.Colors.tertiaryText)
                        }
                    }
                }
            }
            .padding(KingDesignTokens.Spacing.md)
            .background(KingDesignTokens.Glass.ultraThin)
            .cornerRadius(KingDesignTokens.Radius.md)
            .overlay(
                RoundedRectangle(cornerRadius: KingDesignTokens.Radius.md)
                    .strokeBorder(
                        isEditing ? KingDesignTokens.Colors.accent : KingDesignTokens.Colors.border,
                        lineWidth: isEditing ? 1.5 : 1
                    )
            )
            
            // Error Message
            if case .invalid(let message) = validation {
                Text(message)
                    .font(KingDesignTokens.Typography.caption)
                    .foregroundColor(KingDesignTokens.Colors.error)
                    .padding(.horizontal, KingDesignTokens.Spacing.xs)
            }
        }
    }
}

// MARK: - Glass Search Field
public struct GlassSearchField: View {
    @Binding var text: String
    let placeholder: String
    let onSearch: () -> Void
    
    @State private var isEditing = false
    
    public init(
        text: Binding<String>,
        placeholder: String = "Search",
        onSearch: @escaping () -> Void = {}
    ) {
        self._text = text
        self.placeholder = placeholder
        self.onSearch = onSearch
    }
    
    public var body: some View {
        HStack(spacing: KingDesignTokens.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(KingDesignTokens.Colors.secondaryText)
            
            TextField(placeholder, text: $text, onEditingChanged: { editing in
                withAnimation(KingDesignTokens.Animation.fast) {
                    isEditing = editing
                }
            })
            .font(KingDesignTokens.Typography.body)
            .foregroundColor(KingDesignTokens.Colors.primary)
            .textFieldStyle(PlainTextFieldStyle())
            .onSubmit(onSearch)
            
            if !text.isEmpty {
                Button(action: { 
                    text = ""
                    onSearch()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(KingDesignTokens.Colors.tertiaryText)
                }
            }
        }
        .padding(KingDesignTokens.Spacing.sm)
        .background(KingDesignTokens.Glass.ultraThin)
        .cornerRadius(KingDesignTokens.Radius.full)
    }
}

// MARK: - Glass Text Area
public struct GlassTextArea: View {
    @Binding var text: String
    let placeholder: String
    let minHeight: CGFloat
    let maxHeight: CGFloat
    
    @State private var isEditing = false
    @State private var textHeight: CGFloat = 0
    
    public init(
        text: Binding<String>,
        placeholder: String,
        minHeight: CGFloat = 100,
        maxHeight: CGFloat = 200
    ) {
        self._text = text
        self.placeholder = placeholder
        self.minHeight = minHeight
        self.maxHeight = maxHeight
    }
    
    public var body: some View {
        ZStack(alignment: .topLeading) {
            // Placeholder
            if text.isEmpty {
                Text(placeholder)
                    .font(KingDesignTokens.Typography.body)
                    .foregroundColor(KingDesignTokens.Colors.tertiaryText)
                    .padding(KingDesignTokens.Spacing.md)
            }
            
            // Text Editor
            TextEditor(text: $text)
                .font(KingDesignTokens.Typography.body)
                .foregroundColor(KingDesignTokens.Colors.primary)
                .scrollContentBackground(.hidden)
                .background(KingDesignTokens.Colors.clear)
                .padding(KingDesignTokens.Spacing.sm)
                .onTapGesture {
                    withAnimation(KingDesignTokens.Animation.fast) {
                        isEditing = true
                    }
                }
                .onChange(of: text) {
                    withAnimation(KingDesignTokens.Animation.fast) {
                        isEditing = !text.isEmpty
                    }
                }
        }
        .frame(minHeight: minHeight, maxHeight: maxHeight)
        .background(KingDesignTokens.Glass.ultraThin)
        .cornerRadius(KingDesignTokens.Radius.md)
        .overlay(
            RoundedRectangle(cornerRadius: KingDesignTokens.Radius.md)
                .strokeBorder(
                    isEditing ? KingDesignTokens.Colors.accent : KingDesignTokens.Colors.border,
                    lineWidth: isEditing ? 1.5 : 1
                )
        )
    }
}

// MARK: - Glass PIN Field
public struct GlassPINField: View {
    @Binding var pin: String
    let length: Int
    let onComplete: (String) -> Void
    
    @State private var digits: [String] = []
    @FocusState private var isFieldFocused: Bool
    
    public init(
        pin: Binding<String>,
        length: Int = 6,
        onComplete: @escaping (String) -> Void
    ) {
        self._pin = pin
        self.length = length
        self.onComplete = onComplete
        self._digits = State(initialValue: Array(repeating: "", count: length))
    }
    
    public var body: some View {
        HStack(spacing: KingDesignTokens.Spacing.sm) {
            ForEach(0..<length, id: \.self) { index in
                PINDigitView(
                    digit: index < pin.count ? String(pin[pin.index(pin.startIndex, offsetBy: index)]) : "",
                    isFocused: isFieldFocused && index == pin.count
                )
            }
        }
        .background(
            TextField("", text: $pin)
                .keyboardType(.numberPad)
                .textFieldStyle(PlainTextFieldStyle())
                .focused($isFieldFocused)
                .opacity(0)
                .onChange(of: pin) {
                    if pin.count > length {
                        pin = String(pin.prefix(length))
                    }
                    if pin.count == length {
                        onComplete(pin)
                    }
                }
        )
        .onTapGesture {
            isFieldFocused = true
        }
    }
}

private struct PINDigitView: View {
    let digit: String
    let isFocused: Bool
    
    var body: some View {
        Text(digit.isEmpty ? "" : "•")
            .font(KingDesignTokens.Typography.heading)
            .foregroundColor(KingDesignTokens.Colors.primary)
            .frame(width: 44, height: 52)
            .background(KingDesignTokens.Glass.ultraThin)
            .cornerRadius(KingDesignTokens.Radius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: KingDesignTokens.Radius.sm)
                    .strokeBorder(
                        isFocused ? KingDesignTokens.Colors.accent : KingDesignTokens.Colors.border,
                        lineWidth: isFocused ? 1.5 : 1
                    )
            )
            .animation(KingDesignTokens.Animation.fast, value: isFocused)
    }
}

// MARK: - Preview
#Preview("Glass Text Fields") {
    ScrollView {
        VStack(spacing: KingDesignTokens.Spacing.lg) {
            // Standard Text Fields
            Group {
                Text("Text Fields")
                    .font(KingDesignTokens.Typography.heading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                GlassTextField(
                    text: .constant(""),
                    placeholder: "Email",
                    icon: "envelope"
                )
                
                GlassTextField(
                    text: .constant(""),
                    placeholder: "Password",
                    icon: "lock",
                    isSecure: true
                )
                
                GlassTextField(
                    text: .constant("john@example.com"),
                    placeholder: "Email",
                    icon: "envelope",
                    validation: .valid
                )
                
                GlassTextField(
                    text: .constant("weak"),
                    placeholder: "Password",
                    icon: "lock",
                    isSecure: true,
                    validation: .invalid("Password must be at least 8 characters")
                )
            }
            
            Divider()
            
            // Search Field
            Group {
                Text("Search Field")
                    .font(KingDesignTokens.Typography.heading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                GlassSearchField(text: .constant(""))
                GlassSearchField(text: .constant("Bitcoin"))
            }
            
            Divider()
            
            // Text Area
            Group {
                Text("Text Area")
                    .font(KingDesignTokens.Typography.heading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                GlassTextArea(
                    text: .constant(""),
                    placeholder: "Enter your message..."
                )
            }
            
            Divider()
            
            // PIN Field
            Group {
                Text("PIN Field")
                    .font(KingDesignTokens.Typography.heading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                GlassPINField(pin: .constant("123")) { pin in
                    print("PIN Complete: \(pin)")
                }
            }
        }
        .padding()
    }
    .background(KingDesignTokens.Colors.background)
}
