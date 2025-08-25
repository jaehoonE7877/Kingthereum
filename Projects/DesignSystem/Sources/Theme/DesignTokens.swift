import SwiftUI

/// 디자인 시스템 토큰
/// 색상, 타이포그래피, 간격, 크기 등의 디자인 상수들을 중앙 관리
public enum DesignTokens {
    
    // MARK: - Spacing
    
    public enum Spacing {
        /// 매우 작은 간격 (4pt)
        public static let xs: CGFloat = 4
        /// 작은 간격 (8pt)
        public static let sm: CGFloat = 8
        /// 기본 간격 (12pt)
        public static let md: CGFloat = 12
        /// 큰 간격 (16pt)
        public static let lg: CGFloat = 16
        /// 매우 큰 간격 (24pt)
        public static let xl: CGFloat = 24
        /// 엑스트라 큰 간격 (32pt)
        public static let xxl: CGFloat = 32
        /// 점보 간격 (48pt)
        public static let jumbo: CGFloat = 48
        
        /// 패딩 프리셋
        public enum Padding {
            public static let card: EdgeInsets = EdgeInsets(top: lg, leading: lg, bottom: lg, trailing: lg)
            public static let button: EdgeInsets = EdgeInsets(top: md, leading: xl, bottom: md, trailing: xl)
            public static let screen: EdgeInsets = EdgeInsets(top: lg, leading: lg, bottom: lg, trailing: lg)
            public static let section: EdgeInsets = EdgeInsets(top: xl, leading: 0, bottom: xl, trailing: 0)
        }
    }
    
    // MARK: - Corner Radius
    
    public enum CornerRadius {
        /// 작은 둥근 모서리 (4pt)
        public static let sm: CGFloat = 4
        /// 기본 둥근 모서리 (8pt)
        public static let md: CGFloat = 8
        /// 큰 둥근 모서리 (12pt)
        public static let lg: CGFloat = 12
        /// 매우 큰 둥근 모서리 (16pt)
        public static let xl: CGFloat = 16
        /// 엑스트라 큰 둥근 모서리 (24pt)
        public static let xxl: CGFloat = 24
        /// 완전한 원형 (50% = 1000pt)
        public static let circle: CGFloat = 1000
    }
    
    // MARK: - Size
    
    public enum Size {
        /// 아이콘 크기
        public enum Icon {
            public static let xs: CGFloat = 12
            public static let sm: CGFloat = 16
            public static let md: CGFloat = 24
            public static let lg: CGFloat = 32
            public static let xl: CGFloat = 48
        }
        
        /// 버튼 높이
        public enum Button {
            public static let sm: CGFloat = 32
            public static let md: CGFloat = 44
            public static let lg: CGFloat = 56
        }
        
        /// 카드 크기
        public enum Card {
            public static let minHeight: CGFloat = 120
            public static let maxWidth: CGFloat = 400
        }
        
        /// 입력 필드 높이
        public enum Input {
            public static let sm: CGFloat = 36
            public static let md: CGFloat = 44
            public static let lg: CGFloat = 52
        }
    }
    
    // MARK: - Border Width
    
    public enum BorderWidth {
        public static let thin: CGFloat = 0.5
        public static let normal: CGFloat = 1
        public static let thick: CGFloat = 2
        public static let heavy: CGFloat = 4
    }
    
    // MARK: - Shadow
    
    @MainActor
    public enum Shadow {
        public struct ShadowStyle: Sendable {
            let color: Color
            let radius: CGFloat
            let x: CGFloat
            let y: CGFloat
        }
        
        public static let none = ShadowStyle(color: .clear, radius: 0, x: 0, y: 0)
        public static let subtle = ShadowStyle(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        public static let light = ShadowStyle(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        public static let medium = ShadowStyle(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        public static let heavy = ShadowStyle(color: .black.opacity(0.2), radius: 16, x: 0, y: 8)
        public static let card = ShadowStyle(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
    }
    
    // MARK: - Opacity
    
    public enum Opacity {
        public static let disabled: Double = 0.4
        public static let secondary: Double = 0.6
        public static let overlay: Double = 0.8
        public static let backdrop: Double = 0.3
    }
    
    // MARK: - Z-Index (Layer Priority)
    
    public enum ZIndex {
        public static let background: Double = -1
        public static let content: Double = 0
        public static let overlay: Double = 1
        public static let modal: Double = 2
        public static let toast: Double = 3
        public static let tooltip: Double = 4
    }
    
    // MARK: - Animation Duration
    
    public enum Duration {
        public static let instant: Double = 0.1
        public static let fast: Double = 0.2
        public static let normal: Double = 0.3
        public static let slow: Double = 0.5
        public static let verySlow: Double = 0.8
    }
    
    // MARK: - Breakpoints (for responsive design)
    
    public enum Breakpoint {
        public static let sm: CGFloat = 390  // iPhone mini
        public static let md: CGFloat = 430  // iPhone Pro
        public static let lg: CGFloat = 768  // iPad mini
        public static let xl: CGFloat = 1024 // iPad
        public static let xxl: CGFloat = 1366 // iPad Pro
    }
}

// MARK: - Semantic Color Tokens

public extension Color {
    
    // MARK: - Status Colors
    
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    static let info = Color.blue
    
    // MARK: - Surface Colors
    
    static let surfacePrimary = Color(UIColor.systemBackground)
    static let surfaceSecondary = Color(UIColor.secondarySystemBackground)
    static let surfaceTertiary = Color(UIColor.tertiarySystemBackground)
    
    // MARK: - Border Colors
    
    static let borderPrimary = Color(UIColor.separator)
    static let borderSecondary = Color(UIColor.separator).opacity(0.5)
    static let borderFocus = Color.blue
    
    // MARK: - Text Colors
    
    static let textPrimary = Color(UIColor.label)
    static let textSecondary = Color(UIColor.secondaryLabel)
    static let textTertiary = Color(UIColor.tertiaryLabel)
    static let textDisabled = Color(UIColor.quaternaryLabel)
    
    // MARK: - Interactive Colors
    
    static let interactive = Color.blue
    static let interactiveHover = Color.blue.opacity(0.8)
    static let interactivePressed = Color.blue.opacity(0.6)
    static let interactiveDisabled = Color.gray
}

// MARK: - Typography Scale

public enum Typography {
    
    public enum Scale {
        public static let xs = Font.system(size: 12, weight: .regular)
        public static let sm = Font.system(size: 14, weight: .regular)
        public static let md = Font.system(size: 16, weight: .regular)
        public static let lg = Font.system(size: 18, weight: .regular)
        public static let xl = Font.system(size: 20, weight: .regular)
        public static let xxl = Font.system(size: 24, weight: .regular)
        public static let jumbo = Font.system(size: 32, weight: .regular)
    }
    
    public enum Weight {
        public static let light = Font.Weight.light
        public static let regular = Font.Weight.regular
        public static let medium = Font.Weight.medium
        public static let semibold = Font.Weight.semibold
        public static let bold = Font.Weight.bold
        public static let heavy = Font.Weight.heavy
    }
    
    public enum Heading {
        public static let h1 = Font.system(size: 32, weight: .bold)
        public static let h2 = Font.system(size: 28, weight: .bold)
        public static let h3 = Font.system(size: 24, weight: .semibold)
        public static let h4 = Font.system(size: 20, weight: .semibold)
        public static let h5 = Font.system(size: 18, weight: .medium)
        public static let h6 = Font.system(size: 16, weight: .medium)
    }
    
    public enum Body {
        public static let large = Font.system(size: 18, weight: .regular)
        public static let medium = Font.system(size: 16, weight: .regular)
        public static let small = Font.system(size: 14, weight: .regular)
    }
    
    public enum Caption {
        public static let large = Font.system(size: 14, weight: .medium)
        public static let medium = Font.system(size: 12, weight: .medium)
        public static let small = Font.system(size: 10, weight: .medium)
    }
}

// MARK: - View Extensions for Design Tokens

public extension View {
    
    // MARK: - Spacing
    
    func spacingXS() -> some View { padding(DesignTokens.Spacing.xs) }
    func spacingSM() -> some View { padding(DesignTokens.Spacing.sm) }
    func spacingMD() -> some View { padding(DesignTokens.Spacing.md) }
    func spacingLG() -> some View { padding(DesignTokens.Spacing.lg) }
    func spacingXL() -> some View { padding(DesignTokens.Spacing.xl) }
    func spacingXXL() -> some View { padding(DesignTokens.Spacing.xxl) }
    
    // MARK: - Corner Radius
    
    func cornerRadiusSM() -> some View { cornerRadius(DesignTokens.CornerRadius.sm) }
    func cornerRadiusMD() -> some View { cornerRadius(DesignTokens.CornerRadius.md) }
    func cornerRadiusLG() -> some View { cornerRadius(DesignTokens.CornerRadius.lg) }
    func cornerRadiusXL() -> some View { cornerRadius(DesignTokens.CornerRadius.xl) }
    func cornerRadiusXXL() -> some View { cornerRadius(DesignTokens.CornerRadius.xxl) }
    
    // MARK: - Shadow
    
    @MainActor
    func shadowToken(_ shadow: DesignTokens.Shadow.ShadowStyle) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
    
    @MainActor
    func shadowSubtle() -> some View { shadowToken(DesignTokens.Shadow.subtle) }
    @MainActor
    func shadowLight() -> some View { shadowToken(DesignTokens.Shadow.light) }
    @MainActor
    func shadowMedium() -> some View { shadowToken(DesignTokens.Shadow.medium) }
    @MainActor
    func shadowHeavy() -> some View { shadowToken(DesignTokens.Shadow.heavy) }
    @MainActor
    func shadowCard() -> some View { shadowToken(DesignTokens.Shadow.card) }
    
    // MARK: - Frame Sizes
    
    func buttonFrameSM() -> some View {
        frame(height: DesignTokens.Size.Button.sm)
    }
    
    func buttonFrameMD() -> some View {
        frame(height: DesignTokens.Size.Button.md)
    }
    
    func buttonFrameLG() -> some View {
        frame(height: DesignTokens.Size.Button.lg)
    }
    
    func inputFrameSM() -> some View {
        frame(height: DesignTokens.Size.Input.sm)
    }
    
    func inputFrameMD() -> some View {
        frame(height: DesignTokens.Size.Input.md)
    }
    
    func inputFrameLG() -> some View {
        frame(height: DesignTokens.Size.Input.lg)
    }
}

// MARK: - Responsive Design Helpers

public extension View {
    
    /// 화면 크기에 따른 조건부 뷰
    @ViewBuilder
    func responsive<Content: View>(
        @ViewBuilder content: @escaping (CGFloat) -> Content
    ) -> some View {
        GeometryReader { geometry in
            content(geometry.size.width)
        }
    }
}
