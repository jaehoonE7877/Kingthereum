import SwiftUI
import Core

/// Metal 기반 Liquid Glass 효과를 사용하는 개선된 버튼
public struct MetalLiquidGlassButton: View {
    
    // MARK: - Properties
    
    private let title: String?
    private let icon: String?
    private let action: () -> Void
    private let style: MetalGlassButtonStyle
    private let isEnabled: Bool
    private let isLoading: Bool
    
    @State private var glassSettings: LiquidGlassSettings
    @State private var isPressed = false
    
    // MARK: - Initializers
    
    /// 텍스트 버튼 초기화
    public init(
        _ title: String,
        style: MetalGlassButtonStyle = .primary,
        isEnabled: Bool = true,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = nil
        self.action = action
        self.style = style
        self.isEnabled = isEnabled
        self.isLoading = isLoading
        self._glassSettings = State(initialValue: style.glassSettings)
    }
    
    /// 아이콘 버튼 초기화
    public init(
        icon: String,
        title: String? = nil,
        style: MetalGlassButtonStyle = .icon,
        isEnabled: Bool = true,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.action = action
        self.style = style
        self.isEnabled = isEnabled
        self.isLoading = isLoading
        self._glassSettings = State(initialValue: style.glassSettings)
    }
    
    // MARK: - Body
    
    public var body: some View {
        Button(action: handleButtonPress) {
            buttonContent
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isEnabled || isLoading)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .opacity(isEnabled ? 1.0 : 0.6)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        withAnimation(.easeOut(duration: 0.1)) {
                            isPressed = true
                        }
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isPressed = false
                    }
                }
        )
    }
    
    // MARK: - Button Content
    
    @ViewBuilder
    private var buttonContent: some View {
        HStack(spacing: 8) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: style.foregroundColor))
                    .scaleEffect(0.8)
            } else {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(style.foregroundColor)
                }
                
                if let title = title {
                    Text(title)
                        .font(style.font)
                        .fontWeight(style.fontWeight)
                        .foregroundColor(style.foregroundColor)
                }
            }
        }
        .frame(maxWidth: title != nil ? .infinity : nil)
        .frame(minWidth: icon != nil && title == nil ? Constants.UI.buttonHeight : nil)
        .frame(height: Constants.UI.buttonHeight)
        .padding(.horizontal, style.horizontalPadding)
        .metalLiquidGlass(settings: $glassSettings) { touchPoint in
            handleTouchRipple(at: touchPoint)
        }
        .overlay(
            RoundedRectangle(cornerRadius: style.cornerRadius)
                .stroke(style.borderColor, lineWidth: style.borderWidth)
        )
        .clipShape(RoundedRectangle(cornerRadius: style.cornerRadius))
    }
    
    // MARK: - Interaction Handlers
    
    private func handleButtonPress() {
        if isEnabled && !isLoading {
            action()
        }
    }
    
    private func handleTouchRipple(at point: CGPoint) {
        // 터치 지점에서 파급 효과
        let originalReflection = glassSettings.reflectionStrength
        
        withAnimation(.easeOut(duration: 0.3)) {
            glassSettings.reflectionStrength = min(1.0, originalReflection * 1.5)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.4)) {
                glassSettings.reflectionStrength = originalReflection
            }
        }
    }
}

// MARK: - MetalGlassButtonStyle

/// Metal Liquid Glass 버튼 스타일
public struct MetalGlassButtonStyle {
    let foregroundColor: Color
    let borderColor: Color
    let borderWidth: CGFloat
    let cornerRadius: CGFloat
    let font: Font
    let fontWeight: Font.Weight
    let horizontalPadding: CGFloat
    let glassSettings: LiquidGlassSettings
    
    public init(
        foregroundColor: Color = .systemLabel,
        borderColor: Color = .glassBorderPrimary,
        borderWidth: CGFloat = 1,
        cornerRadius: CGFloat = Constants.UI.cornerRadius,
        font: Font = .headline,
        fontWeight: Font.Weight = .medium,
        horizontalPadding: CGFloat = Constants.UI.padding,
        glassSettings: LiquidGlassSettings = LiquidGlassSettings()
    ) {
        self.foregroundColor = foregroundColor
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.cornerRadius = cornerRadius
        self.font = font
        self.fontWeight = fontWeight
        self.horizontalPadding = horizontalPadding
        self.glassSettings = glassSettings
    }
    
    // MARK: - Predefined Styles
    
    /// 주요 액션용 프라이머리 스타일
    public static let primary = MetalGlassButtonStyle(
        foregroundColor: .systemLabel,
        borderColor: .glassBorderPrimary,
        glassSettings: {
            var settings = LiquidGlassSettings()
            settings.thickness = 0.6
            settings.refractionStrength = 0.4
            settings.reflectionStrength = 0.3
            settings.opacity = 0.85
            settings.tintColor = (0.9, 0.95, 1.0)
            return settings
        }()
    )
    
    /// 보조 액션용 세컨더리 스타일
    public static let secondary = MetalGlassButtonStyle(
        foregroundColor: .systemLabel,
        borderColor: .glassBorderSecondary,
        glassSettings: {
            var settings = LiquidGlassSettings()
            settings.thickness = 0.4
            settings.refractionStrength = 0.2
            settings.reflectionStrength = 0.2
            settings.opacity = 0.75
            settings.tintColor = (0.95, 0.98, 1.0)
            return settings
        }()
    )
    
    /// 성공 상태 스타일
    public static let success = MetalGlassButtonStyle(
        foregroundColor: .systemGreen,
        borderColor: Color.systemGreen.opacity(0.3),
        glassSettings: {
            var settings = LiquidGlassSettings()
            settings.thickness = 0.5
            settings.refractionStrength = 0.3
            settings.reflectionStrength = 0.25
            settings.opacity = 0.8
            settings.tintColor = (0.85, 1.0, 0.85)
            return settings
        }()
    )
    
    /// 암호화폐 거래용 스타일
    public static let crypto = MetalGlassButtonStyle(
        foregroundColor: .kingGold,
        borderColor: Color.kingGold.opacity(0.25),
        font: .subheadline,
        fontWeight: .medium,
        glassSettings: {
            var settings = LiquidGlassSettings()
            settings.thickness = 0.6
            settings.refractionStrength = 0.4
            settings.reflectionStrength = 0.5
            settings.opacity = 0.85
            settings.tintColor = (1.0, 0.95, 0.8)
            return settings
        }()
    )
    
    /// 아이콘 전용 버튼 스타일
    public static let icon = MetalGlassButtonStyle(
        foregroundColor: .systemLabel,
        borderColor: .glassBorderSecondary,
        font: .title3,
        fontWeight: .medium,
        glassSettings: {
            var settings = LiquidGlassSettings()
            settings.thickness = 0.3
            settings.refractionStrength = 0.2
            settings.reflectionStrength = 0.15
            settings.opacity = 0.7
            settings.tintColor = (0.95, 0.98, 1.0)
            return settings
        }()
    )
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        MetalLiquidGlassButton("Primary Button", style: .primary) { }
        MetalLiquidGlassButton("Secondary Button", style: .secondary) { }
        MetalLiquidGlassButton("Success Button", style: .success) { }
        
        HStack(spacing: 16) {
            MetalLiquidGlassButton(icon: "plus", style: .icon) { }
            MetalLiquidGlassButton(icon: "heart", style: .icon) { }
            MetalLiquidGlassButton(icon: "star", style: .icon) { }
        }
        
        MetalLiquidGlassButton("Crypto Button", style: .crypto) { }
        MetalLiquidGlassButton("Loading Button", isLoading: true) { }
    }
    .padding()
    .background(
        LinearGradient(
            colors: [.systemBlue, .systemPurple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}