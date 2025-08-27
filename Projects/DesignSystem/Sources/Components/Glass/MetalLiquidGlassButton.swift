import SwiftUI
import Core

/// SwiftUI 기반 Glass 효과를 사용하는 버튼 (Metal 제거됨)
public struct MetalLiquidGlassButton: View {
    
    // MARK: - Properties
    
    private let title: String?
    private let icon: String?
    private let action: () -> Void
    private let style: MetalGlassButtonStyle
    private let isEnabled: Bool
    private let isLoading: Bool
    
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
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
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
        .background(
            Rectangle()
                .fill(.ultraThinMaterial.opacity(0.6))
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.1),
                            Color.clear,
                            style.tintColor.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
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
}

// MARK: - MetalGlassButtonStyle

/// SwiftUI Glass 버튼 스타일
public struct MetalGlassButtonStyle: Sendable {
    let foregroundColor: Color
    let borderColor: Color
    let borderWidth: CGFloat
    let cornerRadius: CGFloat
    let font: Font
    let fontWeight: Font.Weight
    let horizontalPadding: CGFloat
    let tintColor: Color
    
    public init(
        foregroundColor: Color = .systemLabel,
        borderColor: Color = .glassBorderPrimary,
        borderWidth: CGFloat = 1,
        cornerRadius: CGFloat = Constants.UI.cornerRadius,
        font: Font = .headline,
        fontWeight: Font.Weight = .medium,
        horizontalPadding: CGFloat = Constants.UI.padding,
        tintColor: Color = .clear
    ) {
        self.foregroundColor = foregroundColor
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.cornerRadius = cornerRadius
        self.font = font
        self.fontWeight = fontWeight
        self.horizontalPadding = horizontalPadding
        self.tintColor = tintColor
    }
    
    // MARK: - Predefined Styles
    
    /// 주요 액션용 프라이머리 스타일
    public static let primary = MetalGlassButtonStyle(
        foregroundColor: .systemLabel,
        borderColor: .glassBorderPrimary,
        tintColor: .clear
    )
    
    /// 보조 액션용 세컨더리 스타일
    public static let secondary = MetalGlassButtonStyle(
        foregroundColor: .systemLabel,
        borderColor: .glassBorderSecondary,
        tintColor: .clear
    )
    
    /// 성공 상태 스타일
    public static let success = MetalGlassButtonStyle(
        foregroundColor: .systemGreen,
        borderColor: Color.systemGreen.opacity(0.3),
        tintColor: .systemGreen
    )
    
    /// 암호화폐 거래용 스타일
    public static let crypto = MetalGlassButtonStyle(
        foregroundColor: .kingGold,
        borderColor: Color.kingGold.opacity(0.4),
        font: .subheadline,
        fontWeight: .medium,
        tintColor: .kingGold
    )
    
    /// 아이콘 전용 버튼 스타일
    public static let icon = MetalGlassButtonStyle(
        foregroundColor: .systemLabel,
        borderColor: .glassBorderSecondary,
        font: .title3,
        fontWeight: .medium,
        tintColor: .clear
    )
    
    /// ColorScheme에 따른 적응형 스타일 생성
    public static func adaptive(for colorScheme: ColorScheme, baseStyle: MetalGlassButtonStyle = .primary) -> MetalGlassButtonStyle {
        let adaptedTintColor: Color
        
        switch colorScheme {
        case .light:
            adaptedTintColor = .clear
        case .dark:
            adaptedTintColor = .white.opacity(0.1)
        @unknown default:
            adaptedTintColor = baseStyle.tintColor
        }
        
        return MetalGlassButtonStyle(
            foregroundColor: baseStyle.foregroundColor,
            borderColor: baseStyle.borderColor,
            borderWidth: baseStyle.borderWidth,
            cornerRadius: baseStyle.cornerRadius,
            font: baseStyle.font,
            fontWeight: baseStyle.fontWeight,
            horizontalPadding: baseStyle.horizontalPadding,
            tintColor: adaptedTintColor
        )
    }
    
    /// 프리미엄 암호화폐 지갑용 특별 스타일
    public static func premium(for colorScheme: ColorScheme) -> MetalGlassButtonStyle {
        let baseStyle: MetalGlassButtonStyle = colorScheme == .dark ? .crypto : .primary
        return adaptive(for: colorScheme, baseStyle: baseStyle)
    }
}

// MARK: - Ultra Lightweight Button for WalletHomeView

/// CPU 사용량 최적화를 위한 초경량 SwiftUI Glass 버튼 (WalletHomeView 전용)
public struct UltraLightweightSwiftUIButton: View {
    private let title: String?
    private let icon: String?
    private let action: () -> Void
    private let style: UltraLightweightButtonStyle
    private let isEnabled: Bool
    
    @State private var isPressed = false
    
    public init(
        icon: String,
        title: String? = nil,
        style: UltraLightweightButtonStyle = .default,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.action = action
        self.style = style
        self.isEnabled = isEnabled
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(style.foregroundColor)
                }
                
                if let title = title {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(style.foregroundColor)
                }
            }
            .frame(maxWidth: title != nil ? .infinity : nil)
            .frame(height: Constants.UI.buttonHeight)
            .padding(.horizontal, 16)
            .background(
                // 초경량 SwiftUI Glass 효과 - Metal 없이 순수 SwiftUI만 사용
                Rectangle()
                    .fill(.ultraThinMaterial.opacity(0.4))
                    .overlay(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.1),
                                Color.clear,
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(style.borderColor, lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isEnabled)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .opacity(isEnabled ? 1.0 : 0.6)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

/// 초경량 버튼 스타일
@MainActor
public struct UltraLightweightButtonStyle {
    let foregroundColor: Color
    let borderColor: Color  
    let tintColor: Color
    
    public static let `default` = UltraLightweightButtonStyle(
        foregroundColor: .primary,
        borderColor: .glassBorderSecondary,
        tintColor: .clear
    )
    
    public static let success = UltraLightweightButtonStyle(
        foregroundColor: .systemGreen,
        borderColor: Color.systemGreen.opacity(0.2),
        tintColor: .systemGreen.opacity(0.1)
    )
    
    public static let crypto = UltraLightweightButtonStyle(
        foregroundColor: .kingGold,
        borderColor: Color.kingGold.opacity(0.2),
        tintColor: .kingGold.opacity(0.1)
    )
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // 기존 SwiftUI Glass 버튼들
        VStack(spacing: 12) {
            Text("SwiftUI Glass 버튼 (Metal 제거됨)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            MetalLiquidGlassButton("Primary Button", style: .primary) { }
            MetalLiquidGlassButton("Secondary Button", style: .secondary) { }
            MetalLiquidGlassButton("Success Button", style: .success) { }
            
            HStack(spacing: 16) {
                MetalLiquidGlassButton(icon: "plus", style: .icon) { }
                MetalLiquidGlassButton(icon: "heart", style: .icon) { }
                MetalLiquidGlassButton(icon: "star", style: .icon) { }
            }
            
            MetalLiquidGlassButton("Crypto Button", style: .crypto) { }
        }
        
        Divider()
        
        // 초경량 버튼들
        VStack(spacing: 12) {
            Text("초경량 SwiftUI 버튼 (CPU 5-10%)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            UltraLightweightSwiftUIButton(icon: "arrow.up.circle.fill", title: "보내기", style: .crypto) { }
            UltraLightweightSwiftUIButton(icon: "arrow.down.circle.fill", title: "받기", style: .success) { }
            
            HStack(spacing: 16) {
                UltraLightweightSwiftUIButton(icon: "plus") { }
                UltraLightweightSwiftUIButton(icon: "heart") { }
                UltraLightweightSwiftUIButton(icon: "star") { }
            }
        }
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