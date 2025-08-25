import SwiftUI
import Core

/// 글래스모피즘 효과를 가진 커스텀 버튼 컴포넌트
/// 속이 비치는 유리 질감과 뉴모피즘 효과를 제공
public struct GlassButton: View {
    let title: String?
    let icon: String?
    let action: () -> Void
    let style: GlassButtonStyle
    let isEnabled: Bool
    let isLoading: Bool
    
    @State private var isPressed = false
    
    /// 텍스트 버튼 초기화
    public init(
        _ title: String,
        style: GlassButtonStyle = .primary,
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
        style: GlassButtonStyle = .icon,
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
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: style.foregroundColor))
                        .scaleEffect(0.8)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(style.font)
                            .fontWeight(style.fontWeight)
                    }
                    
                    if let title = title {
                        Text(title)
                            .font(style.font)
                            .fontWeight(style.fontWeight)
                    }
                }
            }
            .foregroundStyle(
                style.id == "wallet" ? 
                AnyShapeStyle(LinearGradient.primaryGradient) : 
                AnyShapeStyle(style.foregroundColor)
            )
            .frame(maxWidth: title != nil ? .infinity : nil)
            .frame(height: Constants.UI.buttonHeight)
            .frame(minWidth: icon != nil && title == nil ? Constants.UI.buttonHeight : nil)
            .background(style.backgroundColor, in: RoundedRectangle(cornerRadius: style.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: style.cornerRadius)
                    .stroke(style.borderColor, lineWidth: style.borderWidth)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.6)
            .shadow(
                color: style.shadowColor,
                radius: style.shadowRadius,
                x: 0,
                y: style.shadowOffset
            )
        }
        .disabled(!isEnabled || isLoading)
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: .infinity,
            pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            },
            perform: {}
        )
    }
}

/// GlassButton의 시각적 스타일을 정의하는 구조체
/// 배경, 텍스트, 음영, 그림자 등의 시각적 속성들을 설정
public struct GlassButtonStyle: Sendable {
    let id: String
    let backgroundColor: Material
    let foregroundColor: Color
    let borderColor: Color
    let borderWidth: CGFloat
    let cornerRadius: CGFloat
    let shadowColor: Color
    let shadowRadius: CGFloat
    let shadowOffset: CGFloat
    let font: Font
    let fontWeight: Font.Weight
    
    /// GlassButtonStyle 초기화
    /// - Parameters:
    ///   - backgroundColor: 배경 색상 (기본값: .ultraThickMaterial)
    ///   - foregroundColor: 텍스트 색상 (기본값: .primary)
    ///   - borderColor: 테두리 색상 (기본값: 반투명 흰색)
    ///   - borderWidth: 테두리 두께 (기본값: 1)
    ///   - cornerRadius: 모서리 둘글기 (기본값: Constants.UI.cornerRadius)
    ///   - shadowColor: 그림자 색상 (기본값: 반투명 검은색)
    ///   - shadowRadius: 그림자 연화 반경 (기본값: 8)
    ///   - shadowOffset: 그림자 오프셋 (기본값: 4)
    ///   - font: 텍스트 폰트 (기본값: .headline)
    ///   - fontWeight: 텍스트 굵기 (기본값: .medium)
    public init(
        id: String = "default",
        backgroundColor: Material = .ultraThickMaterial,
        foregroundColor: Color = .primary,
        borderColor: Color = Color.white.opacity(0.3),
        borderWidth: CGFloat = 1,
        cornerRadius: CGFloat = Constants.UI.cornerRadius,
        shadowColor: Color = .black.opacity(0.2),
        shadowRadius: CGFloat = 8,
        shadowOffset: CGFloat = 4,
        font: Font = .headline,
        fontWeight: Font.Weight = .medium
    ) {
        self.id = id
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.cornerRadius = cornerRadius
        self.shadowColor = shadowColor
        self.shadowRadius = shadowRadius
        self.shadowOffset = shadowOffset
        self.font = font
        self.fontWeight = fontWeight
    }
    
    /// 주요 액션용 기본 스타일
    public static let primary = GlassButtonStyle(
        id: "primary",
        backgroundColor: .ultraThickMaterial,
        foregroundColor: .systemLabel,
        borderColor: .glassBorderPrimary,
        shadowColor: .glassShadowMedium,
        shadowRadius: 10,
        shadowOffset: 5
    )
    
    /// 보조 액션용 보조 스타일
    public static let secondary = GlassButtonStyle(
        id: "secondary",
        backgroundColor: .thinMaterial,
        foregroundColor: .systemLabel,
        borderColor: .glassBorderSecondary,
        shadowColor: .glassShadowLight,
        shadowRadius: 6,
        shadowOffset: 3
    )
    
    /// 위험한 액션용 경고 스타일
    public static let destructive = GlassButtonStyle(
        id: "destructive",
        backgroundColor: .thickMaterial,
        foregroundColor: .systemRed,
        borderColor: Color.adaptive(
            light: Color.systemRed.opacity(0.3),
            dark: Color.systemRed.opacity(0.5)
        ),
        shadowColor: .glassShadowMedium,
        shadowRadius: 8,
        shadowOffset: 4
    )
    
    /// 지갑 관련 액션용 스타일 (그라데이션 효과)
    public static let wallet = GlassButtonStyle(
        backgroundColor: .thickMaterial,
        foregroundColor: .kingBlue, // 그라데이션은 View에서 직접 적용
        borderColor: Color.adaptive(
            light: Color.kingBlue.opacity(0.25),
            dark: Color.kingPurple.opacity(0.3)
        ),
        shadowColor: .glassShadowMedium,
        shadowRadius: 12,
        shadowOffset: 6,
        font: .headline,
        fontWeight: .semibold
    )
    
    /// 암호화폐 거래용 스타일
    public static let crypto = GlassButtonStyle(
        id: "crypto",
        backgroundColor: .regularMaterial,
        foregroundColor: .kingGold,
        borderColor: Color.adaptive(
            light: Color.kingGold.opacity(0.25),
            dark: Color.kingGold.opacity(0.4)
        ),
        shadowColor: .glassShadowMedium,
        shadowRadius: 10,
        shadowOffset: 5,
        font: .subheadline,
        fontWeight: .medium
    )
    
    /// 아이콘 전용 버튼 스타일
    public static let icon = GlassButtonStyle(
        backgroundColor: .thinMaterial,
        foregroundColor: .systemLabel,
        borderColor: .glassBorderSecondary,
        shadowColor: .glassShadowLight,
        shadowRadius: 4,
        shadowOffset: 2,
        font: .title3,
        fontWeight: .medium
    )
    
    /// 플로팅 액션 버튼 스타일
    public static let floating = GlassButtonStyle(
        backgroundColor: .ultraThickMaterial,
        foregroundColor: Color.adaptive(
            light: Color.systemLabel,
            dark: Color.systemLabel
        ),
        borderColor: .glassBorderPrimary,
        shadowColor: .glassShadowStrong,
        shadowRadius: 16,
        shadowOffset: 8,
        font: .headline,
        fontWeight: .semibold
    )
    
    /// 성공 상태 스타일
    public static let success = GlassButtonStyle(
        backgroundColor: .thickMaterial,
        foregroundColor: .systemGreen,
        borderColor: Color.adaptive(
            light: Color.systemGreen.opacity(0.3),
            dark: Color.systemGreen.opacity(0.5)
        ),
        shadowColor: .glassShadowMedium,
        shadowRadius: 8,
        shadowOffset: 4
    )
    
    /// 경고 상태 스타일
    public static let warning = GlassButtonStyle(
        backgroundColor: .thickMaterial,
        foregroundColor: .systemOrange,
        borderColor: Color.adaptive(
            light: Color.systemOrange.opacity(0.3),
            dark: Color.systemOrange.opacity(0.5)
        ),
        shadowColor: .glassShadowMedium,
        shadowRadius: 8,
        shadowOffset: 4
    )
    
    /// 에러 상태 스타일
    public static let error = GlassButtonStyle(
        backgroundColor: .thickMaterial,
        foregroundColor: .systemRed,
        borderColor: Color.adaptive(
            light: Color.systemRed.opacity(0.3),
            dark: Color.systemRed.opacity(0.5)
        ),
        shadowColor: .glassShadowMedium,
        shadowRadius: 8,
        shadowOffset: 4
    )
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            Group {
                GlassButton("기본 버튼", style: .primary) { }
                GlassButton("지갑 버튼", style: .wallet) { }
                GlassButton("암호화폐 버튼", style: .crypto) { }
            }
            
            Group {
                GlassButton(icon: "wallet.pass.fill", title: "지갑", style: .wallet) { }
                GlassButton(icon: "arrow.up.circle.fill", title: "송금", style: .crypto) { }
                GlassButton(icon: "arrow.down.circle.fill", title: "수신", style: .success) { }
            }
            
            HStack(spacing: 16) {
                GlassButton(icon: "qrcode", style: .icon) { }
                GlassButton(icon: "doc.on.doc.fill", style: .icon) { }
                GlassButton(icon: "gearshape.fill", style: .icon) { }
            }
            
            Group {
                GlassButton("플로팅 액션", style: .floating) { }
                GlassButton("성공", style: .success) { }
                GlassButton("경고", style: .warning) { }
                GlassButton("에러", style: .error) { }
            }
            
            GlassButton("로딩 버튼", isLoading: true) { }
        }
        .padding()
    }
    .background(
        LinearGradient(
            colors: [.systemBlue, .systemPurple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
