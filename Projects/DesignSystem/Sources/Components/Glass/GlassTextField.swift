import SwiftUI
import Core

/// 검증 상태를 나타내는 열거형
public enum ValidationState {
    case none
    case valid
    case invalid(String)
    
    public var isValid: Bool {
        switch self {
        case .none, .valid: return true
        case .invalid: return false
        }
    }
    
    var errorMessage: String? {
        switch self {
        case .none, .valid: return nil
        case .invalid(let message): return message
        }
    }
}

public struct GlassTextField: View {
    @Binding var text: String
    let placeholder: String
    let style: GlassTextFieldStyle
    let isSecure: Bool
    let keyboardType: UIKeyboardType
    let textContentType: UITextContentType?
    let submitLabel: SubmitLabel
    let validation: ValidationState
    let onEditingChanged: (Bool) -> Void
    let onSubmit: () -> Void
    
    @State private var isEditing = false
    @State private var showSecureText = false
    
    public init(
        text: Binding<String>,
        placeholder: String,
        style: GlassTextFieldStyle = .default,
        isSecure: Bool = false,
        keyboardType: UIKeyboardType = .default,
        textContentType: UITextContentType? = nil,
        submitLabel: SubmitLabel = .return,
        validation: ValidationState = .none,
        onEditingChanged: @escaping (Bool) -> Void = { _ in },
        onSubmit: @escaping () -> Void = {}
    ) {
        self._text = text
        self.placeholder = placeholder
        self.style = style
        self.isSecure = isSecure
        self.keyboardType = keyboardType
        self.textContentType = textContentType
        self.submitLabel = submitLabel
        self.validation = validation
        self.onEditingChanged = onEditingChanged
        self.onSubmit = onSubmit
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Group {
                    if isSecure && !showSecureText {
                        SecureField(placeholder, text: $text)
                            .submitLabel(submitLabel)
                            .onSubmit {
                                onSubmit()
                            }
                    } else {
                        TextField(placeholder, text: $text, onEditingChanged: { editing in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isEditing = editing
                            }
                            onEditingChanged(editing)
                        })
                        .submitLabel(submitLabel)
                        .onSubmit {
                            onSubmit()
                        }
                    }
                }
                .font(style.font)
                .foregroundColor(style.textColor)
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                
                // Validation Icon
                if !text.isEmpty {
                    Image(systemName: validation.isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(validation.isValid ? .green : .red)
                        .font(.system(size: 16))
                }
                
                if isSecure {
                    Button(action: {
                        showSecureText.toggle()
                    }) {
                        Image(systemName: showSecureText ? "eye.slash" : "eye")
                            .foregroundColor(style.iconColor)
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(.horizontal, style.horizontalPadding)
            .padding(.vertical, style.verticalPadding)
            .background(style.backgroundColor, in: RoundedRectangle(cornerRadius: style.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: style.cornerRadius)
                    .stroke(
                        !validation.isValid ? .red :
                        isEditing ? style.focusedBorderColor : style.borderColor,
                        lineWidth: style.borderWidth
                    )
            )
            .shadow(
                color: style.shadowColor,
                radius: style.shadowRadius,
                x: 0,
                y: style.shadowOffset
            )
            
            // Error Message
            if let errorMessage = validation.errorMessage, !text.isEmpty {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

public struct GlassTextFieldStyle: Sendable {
    let backgroundColor: Material
    let textColor: Color
    let borderColor: Color
    let focusedBorderColor: Color
    let borderWidth: CGFloat
    let cornerRadius: CGFloat
    let shadowColor: Color
    let shadowRadius: CGFloat
    let shadowOffset: CGFloat
    let font: Font
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let iconColor: Color
    
    public init(
        backgroundColor: Material = .ultraThinMaterial,
        textColor: Color = .primary,
        borderColor: Color = .glassBorderSecondary,
        focusedBorderColor: Color = .glassBorderPrimary,
        borderWidth: CGFloat = 1,
        cornerRadius: CGFloat = Constants.UI.cornerRadius,
        shadowColor: Color = .glassShadowLight,
        shadowRadius: CGFloat = 5,
        shadowOffset: CGFloat = 2,
        font: Font = .body,
        horizontalPadding: CGFloat = Constants.UI.padding,
        verticalPadding: CGFloat = Constants.UI.smallPadding,
        iconColor: Color = .secondary
    ) {
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.borderColor = borderColor
        self.focusedBorderColor = focusedBorderColor
        self.borderWidth = borderWidth
        self.cornerRadius = cornerRadius
        self.shadowColor = shadowColor
        self.shadowRadius = shadowRadius
        self.shadowOffset = shadowOffset
        self.font = font
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
        self.iconColor = iconColor
    }
    
    public static let `default` = GlassTextFieldStyle()
    
    public static let prominent = GlassTextFieldStyle(
        backgroundColor: .thickMaterial,
        borderColor: .glassBorderPrimary,
        focusedBorderColor: .glassBorderAccent,
        shadowColor: .glassShadowMedium,
        shadowRadius: 8,
        shadowOffset: 4
    )
}

public struct GlassTextEditor: View {
    @Binding var text: String
    let placeholder: String
    let style: GlassTextFieldStyle
    let minHeight: CGFloat
    
    @State private var isEditing = false
    
    public init(
        text: Binding<String>,
        placeholder: String,
        style: GlassTextFieldStyle = .default,
        minHeight: CGFloat = 100
    ) {
        self._text = text
        self.placeholder = placeholder
        self.style = style
        self.minHeight = minHeight
    }
    
    public var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(.secondary)
                    .font(style.font)
                    .padding(.horizontal, style.horizontalPadding)
                    .padding(.vertical, style.verticalPadding + 8)
            }
            
            TextEditor(text: $text)
                .font(style.font)
                .foregroundColor(style.textColor)
                .background(Color.clear)
                .padding(.horizontal, style.horizontalPadding - 4)
                .padding(.vertical, style.verticalPadding)
                .onTapGesture {
                    isEditing = true
                }
        }
        .frame(minHeight: minHeight)
        .background(style.backgroundColor, in: RoundedRectangle(cornerRadius: style.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: style.cornerRadius)
                .stroke(
                    isEditing ? style.focusedBorderColor : style.borderColor,
                    lineWidth: style.borderWidth
                )
        )
        .shadow(
            color: style.shadowColor,
            radius: style.shadowRadius,
            x: 0,
            y: style.shadowOffset
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        GlassTextField(
            text: .constant(""),
            placeholder: "Enter your email"
        )
        
        GlassTextField(
            text: .constant(""),
            placeholder: "Enter your password",
            isSecure: true
        )
        
        GlassTextField(
            text: .constant("Sample text"),
            placeholder: "Prominent style",
            style: .prominent
        )
        
        GlassTextEditor(
            text: .constant(""),
            placeholder: "Enter your message"
        )
    }
    .padding()
    .background(
        LinearGradient(
            colors: [.blue, .purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
