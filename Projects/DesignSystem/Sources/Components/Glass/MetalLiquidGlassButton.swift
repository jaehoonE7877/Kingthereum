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
    @State private var touchPoint: CGPoint = .zero
    @State private var rippleRadius: Float = 0.0
    @Environment(\.colorScheme) private var colorScheme
    
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
                .onChanged { value in
                    if !isPressed {
                        withAnimation(.easeOut(duration: 0.1)) {
                            isPressed = true
                        }
                        // 터치 위치에서 ripple 효과
                        handleTouchRipple(at: value.startLocation)
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isPressed = false
                    }
                }
        )
        .onLongPressGesture(minimumDuration: 0.5) {
            // 길게 누르기 시 특별한 Glass 효과
            handleLongPress()
        }
        .onChange(of: colorScheme) { _, newColorScheme in
            // ColorScheme 변경 시 Glass 효과 자동 적응
            updateGlassForColorScheme(newColorScheme)
        }
        .onAppear {
            // 초기 로드 시에도 ColorScheme에 맞게 Glass 효과 설정
            updateGlassForColorScheme(colorScheme)
        }
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
        .safeMetalLiquidGlass(settings: $glassSettings)
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
        // 터치 위치 저장
        touchPoint = point
        
        // 기존 값 백업
        let originalReflection = glassSettings.reflectionStrength
        let originalDistortion = glassSettings.distortionStrength
        let originalThickness = glassSettings.thickness
        
        // 터치 시 즉각적인 Glass 강화 효과
        withAnimation(.easeOut(duration: 0.15)) {
            glassSettings.reflectionStrength = min(1.0, originalReflection * 1.8)
            glassSettings.distortionStrength = min(1.0, originalDistortion * 2.0)
            glassSettings.thickness = min(1.0, originalThickness * 1.3)
            rippleRadius = 1.0
        }
        
        // Ripple 확산 효과
        withAnimation(.easeInOut(duration: 0.4)) {
            rippleRadius = 0.0
        }
        
        // 원상 복구
        Task { @MainActor in
            try await Task.sleep(nanoseconds: 200_000_000) // 0.2초
            withAnimation(.easeInOut(duration: 0.6)) {
                glassSettings.reflectionStrength = originalReflection
                glassSettings.distortionStrength = originalDistortion
                glassSettings.thickness = originalThickness
            }
        }
    }
    
    /// 길게 누르기 시 특별한 Glass 효과
    private func handleLongPress() {
        let originalChromaticAberration = glassSettings.chromaticAberration
        let originalTintColor = glassSettings.tintColor
        
        withAnimation(.easeInOut(duration: 0.3)) {
            glassSettings.chromaticAberration = min(1.0, originalChromaticAberration * 2.5)
            // 색상을 더 화려하게 변경
            switch colorScheme {
            case .light:
                glassSettings.tintColor = LiquidGlassSettings.TintColor(r: 0.9, g: 0.95, b: 1.0)
            case .dark:
                glassSettings.tintColor = LiquidGlassSettings.TintColor(r: 1.0, g: 0.8, b: 0.9)
            @unknown default:
                break
            }
        }
        
        Task { @MainActor in
            try await Task.sleep(nanoseconds: 800_000_000) // 0.8초
            withAnimation(.easeInOut(duration: 0.5)) {
                glassSettings.chromaticAberration = originalChromaticAberration
                glassSettings.tintColor = originalTintColor
            }
        }
    }
    
    private func updateGlassForColorScheme(_ colorScheme: ColorScheme) {
        let adaptiveStyle = MetalGlassButtonStyle.adaptive(for: colorScheme, baseStyle: style)
        
        withAnimation(.easeInOut(duration: 0.5)) {
            glassSettings = adaptiveStyle.glassSettings
        }
    }
}

// MARK: - MetalGlassButtonStyle

/// Metal Liquid Glass 버튼 스타일
public struct MetalGlassButtonStyle: Sendable {
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
            settings.thickness = 0.8                    // 0.6 → 0.8
            settings.refractionStrength = 0.6           // 0.4 → 0.6
            settings.reflectionStrength = 0.5           // 0.3 → 0.5
            settings.distortionStrength = 0.2           // 추가
            settings.chromaticAberration = 0.2          // 0.1 → 0.2
            settings.opacity = 0.9                      // 0.85 → 0.9
            settings.tintColor = LiquidGlassSettings.TintColor(r: 0.9, g: 0.95, b: 1.0)
            return settings
        }()
    )
    
    /// 보조 액션용 세컨더리 스타일
    public static let secondary = MetalGlassButtonStyle(
        foregroundColor: .systemLabel,
        borderColor: .glassBorderSecondary,
        glassSettings: {
            var settings = LiquidGlassSettings()
            settings.thickness = 0.7                    // 0.4 → 0.7
            settings.refractionStrength = 0.4           // 0.2 → 0.4
            settings.reflectionStrength = 0.3           // 0.2 → 0.3
            settings.distortionStrength = 0.15          // 추가
            settings.chromaticAberration = 0.15         // 추가
            settings.opacity = 0.85                     // 0.75 → 0.85
            settings.tintColor = LiquidGlassSettings.TintColor(r: 0.95, g: 0.98, b: 1.0)
            return settings
        }()
    )
    
    /// 성공 상태 스타일
    public static let success = MetalGlassButtonStyle(
        foregroundColor: .systemGreen,
        borderColor: Color.systemGreen.opacity(0.3),
        glassSettings: {
            var settings = LiquidGlassSettings()
            settings.thickness = 0.8                    // 0.5 → 0.8
            settings.refractionStrength = 0.5           // 0.3 → 0.5
            settings.reflectionStrength = 0.4           // 0.25 → 0.4
            settings.distortionStrength = 0.2           // 추가
            settings.chromaticAberration = 0.18         // 추가
            settings.opacity = 0.9                      // 0.8 → 0.9
            settings.tintColor = LiquidGlassSettings.TintColor(r: 0.85, g: 1.0, b: 0.85)
            return settings
        }()
    )
    
    /// 암호화폐 거래용 스타일 (최고 강도)
    public static let crypto = MetalGlassButtonStyle(
        foregroundColor: .kingGold,
        borderColor: Color.kingGold.opacity(0.4),
        font: .subheadline,
        fontWeight: .medium,
        glassSettings: {
            var settings = LiquidGlassSettings()
            settings.thickness = 0.9                    // 0.6 → 0.9
            settings.refractionStrength = 0.7           // 0.4 → 0.7
            settings.reflectionStrength = 0.6           // 0.5 → 0.6
            settings.distortionStrength = 0.3           // 추가
            settings.chromaticAberration = 0.25         // 추가
            settings.opacity = 0.95                     // 0.85 → 0.95
            settings.tintColor = LiquidGlassSettings.TintColor(r: 1.0, g: 0.95, b: 0.8)
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
            settings.thickness = 0.6                    // 0.3 → 0.6
            settings.refractionStrength = 0.4           // 0.2 → 0.4
            settings.reflectionStrength = 0.3           // 0.15 → 0.3
            settings.distortionStrength = 0.15          // 추가
            settings.chromaticAberration = 0.12         // 추가
            settings.opacity = 0.8                      // 0.7 → 0.8
            settings.tintColor = LiquidGlassSettings.TintColor(r: 0.95, g: 0.98, b: 1.0)
            return settings
        }()
    )
    
    // MARK: - Adaptive Styles for ColorScheme
    
    /// ColorScheme에 따른 적응형 스타일 생성
    public static func adaptive(for colorScheme: ColorScheme, baseStyle: MetalGlassButtonStyle = .primary) -> MetalGlassButtonStyle {
        var adaptedSettings = baseStyle.glassSettings
        
        switch colorScheme {
        case .light:
            // Light Mode: 밝고 투명한 크리스탈 효과
            adaptedSettings.thickness *= 0.85              // 살짝 얇게
            adaptedSettings.opacity *= 0.9                 // 더 투명하게
            adaptedSettings.tintColor = LiquidGlassSettings.TintColor(r: 0.98, g: 0.99, b: 1.0) // 차가운 색조
            adaptedSettings.reflectionStrength *= 1.1     // 밝은 반사
            
        case .dark:
            // Dark Mode: 어둡고 신비로운 액체 유리 효과
            adaptedSettings.thickness *= 1.15             // 더 두껍게
            adaptedSettings.reflectionStrength *= 1.3     // 강한 반사
            adaptedSettings.chromaticAberration *= 1.4    // 색수차 강화
            adaptedSettings.tintColor = LiquidGlassSettings.TintColor(r: 0.8, g: 0.85, b: 0.95) // 따뜻한 색조
            adaptedSettings.distortionStrength *= 1.2     // 액체 같은 왜곡
            
        @unknown default:
            break
        }
        
        return MetalGlassButtonStyle(
            foregroundColor: baseStyle.foregroundColor,
            borderColor: baseStyle.borderColor,
            borderWidth: baseStyle.borderWidth,
            cornerRadius: baseStyle.cornerRadius,
            font: baseStyle.font,
            fontWeight: baseStyle.fontWeight,
            horizontalPadding: baseStyle.horizontalPadding,
            glassSettings: adaptedSettings
        )
    }
    
    /// 프리미엄 암호화폐 지갑용 특별 스타일
    public static func premium(for colorScheme: ColorScheme) -> MetalGlassButtonStyle {
        let baseStyle: MetalGlassButtonStyle = colorScheme == .dark ? .crypto : .primary
        return adaptive(for: colorScheme, baseStyle: baseStyle)
    }
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