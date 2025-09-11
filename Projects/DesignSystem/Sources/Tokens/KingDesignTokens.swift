import SwiftUI

// MARK: - Kingthereum Premium Fintech Design System
// Inspired by Revolut & N26 - Extreme Minimalism + Premium Feel
// Version: 2.0.0 (2024)

public enum KingDesignTokens {
    
    // MARK: - Colors (A급 프리미엄 핀테크 디자인)
    public enum Colors {
        // MARK: - Base Semantic Colors (라이트/다크 자동 대응)
        
        /// 메인 텍스트 컬러 - 최고 가독성
        public static let primaryText = Color.adaptive(
            light: Color(hex: "#0A0E1B"),  // 거의 검정
            dark: Color(hex: "#FFFFFF")    // 순백
        )
        
        /// 보조 텍스트 컬러 - 중간 중요도
        public static let secondaryText = Color.adaptive(
            light: Color(hex: "#64748B"),  // 회색
            dark: Color(hex: "#A1A8B7")    // 밝은 회색
        )
        
        /// 세컨더리 컬러 (네비게이션, 인터랙션용)
        public static let secondary = Color.adaptive(
            light: Color(hex: "#64748B"),  // 회색
            dark: Color(hex: "#A1A8B7")    // 밝은 회색
        )
        
        /// 비활성/힌트 텍스트 컬러
        public static let tertiaryText = Color.adaptive(
            light: Color(hex: "#94A3B8"),  // 연한 회색
            dark: Color(hex: "#6B7280")    // 중간 회색
        )
        
        /// 서피스 위의 변형 텍스트 컬러
        public static let onSurfaceVariant = Color.adaptive(
            light: Color(hex: "#64748B"),  // 회색
            dark: Color(hex: "#A1A8B7")    // 밝은 회색
        )
        
        // MARK: - Background Colors
        
        /// 메인 배경색
        public static let background = Color.adaptive(
            light: Color(hex: "#FFFFFF"),  // 순백
            dark: Color(hex: "#0A0E1B")    // 딥 다크
        )
        
        /// 카드/서피스 배경색 - 레이어링
        public static let surface = Color.adaptive(
            light: Color(hex: "#FFFFFF"),  // 순백
            dark: Color(hex: "#1A1D2E")    // 다크 서피스
        )
        
        /// 세컨더리 서피스 - 입력필드, 버튼 등
        public static let surfaceSecondary = Color.adaptive(
            light: Color(hex: "#F8FAFC"),  // 극도로 연한 회색
            dark: Color(hex: "#252838")    // 다크 세컨더리
        )
        
        /// 서피스 변형 색상
        public static let surfaceVariant = Color.adaptive(
            light: Color(hex: "#F1F5F9"),  // 연한 변형 서피스
            dark: Color(hex: "#2D3748")    // 다크 변형 서피스
        )
        
        /// 구분선/보더 색상
        public static let border = Color.adaptive(
            light: Color(hex: "#E2E8F0"),  // 연한 구분선
            dark: Color(hex: "#334155")    // 다크 구분선
        )
        
        /// 아웃라인/스트로크 색상 (프리미엄 글래스모피즘용)
        public static let outline = Color.adaptive(
            light: Color(hex: "#F1F5F9"),  // 극도로 연한 스트로크
            dark: Color(hex: "#2D3748")    // 다크 스트로크
        )
        
        /// 그림자 색상 (깊이감 표현)
        public static let shadow = Color.adaptive(
            light: Color(hex: "#000000"),  // 라이트모드 그림자
            dark: Color(hex: "#000000")    // 다크모드 그림자
        )
        
        // MARK: - Brand & Action Colors (모든 모드 동일)
        
        /// 프리미엄 골드 액센트 - 브랜드 컬러 (모든 모드 동일)
        public static let accent = Color(hex: "#D4AF37")
        
        /// 프라이머리 액션 - 골드 기반
        public static let primary = Color(hex: "#D4AF37")
        
        /// 프라이머리 액션 텍스트 (골드 배경용)
        public static let onPrimary = Color(hex: "#0A0E1B")
        
        // MARK: - Semantic Colors (상황별 - 모든 모드 동일)
        
        /// 성공/긍정 컬러
        public static let success = Color(hex: "#059669")
        
        /// 성공 텍스트 (성공 배경용)
        public static let onSuccess = Color(hex: "#FFFFFF")
        
        /// 위험/부정 컬러
        public static let error = Color(hex: "#DC2626")
        
        /// 에러 텍스트 (에러 배경용)
        public static let onError = Color(hex: "#FFFFFF")
        
        /// 경고 컬러
        public static let warning = Color(hex: "#F59E0B")
        
        /// 경고 텍스트 (경고 배경용)
        public static let onWarning = Color(hex: "#0A0E1B")
        
        /// 정보 컬러
        public static let info = Color(hex: "#3B82F6")
        
        /// 정보 텍스트 (정보 배경용)
        public static let onInfo = Color(hex: "#FFFFFF")
        
        // MARK: - Interactive States
        
        /// 비활성화된 요소
        public static let disabled = Color.adaptive(
            light: Color(hex: "#CBD5E1"),
            dark: Color(hex: "#475569")
        )
        
        /// 포커스 상태 (골드 기반)
        public static let focus = Color(hex: "#D4AF37").opacity(0.3)
        
        /// 표면 위 텍스트 (배경 표면 위용)
        public static let onSurface = Color.adaptive(
            light: Color(hex: "#1E293B"),
            dark: Color(hex: "#F1F5F9")
        )
        
        /// 호버 상태
        public static let hover = Color.adaptive(
            light: Color(hex: "#F1F5F9"),
            dark: Color(hex: "#334155")
        )
    }
    
    // MARK: - Typography (숫자 중심 설계)
    public enum Typography {
        // Display - 큰 숫자용 (잔액, 금액)
        public static let displayXL = Font.system(size: 56, weight: .bold, design: .rounded)
        public static let displayL = Font.system(size: 40, weight: .semibold, design: .rounded)
        public static let displayM = Font.system(size: 32, weight: .medium, design: .rounded)
        
        // Text - 일반 텍스트
        public static let headlineLarge = Font.system(size: 28, weight: .bold)
        public static let heading = Font.system(size: 20, weight: .semibold)
        public static let bodyLarge = Font.system(size: 18, weight: .regular)
        public static let body = Font.system(size: 16, weight: .regular)
        public static let bodyMedium = Font.system(size: 14, weight: .regular)
        public static let caption = Font.system(size: 14, weight: .regular)
        public static let labelLarge = Font.system(size: 16, weight: .medium)
        public static let labelMedium = Font.system(size: 14, weight: .medium)
        public static let micro = Font.system(size: 12, weight: .regular)
        
        // Mono - 주소, 해시용
        public static let mono = Font.system(size: 14, weight: .medium, design: .monospaced)
        public static let monoSmall = Font.system(size: 12, weight: .regular, design: .monospaced)
    }
    
    // MARK: - Spacing (8px 그리드 시스템)
    public enum Spacing {
        public static let xxs: CGFloat = 4
        public static let xs: CGFloat = 8
        public static let s: CGFloat = 10
        public static let sm: CGFloat = 12
        public static let m: CGFloat = 16
        public static let md: CGFloat = 16
        public static let l: CGFloat = 20
        public static let lg: CGFloat = 24
        public static let xl: CGFloat = 32
        public static let xxl: CGFloat = 48
        public static let xxxl: CGFloat = 64
    }
    
    // MARK: - Radius (일관된 모서리)
    public enum Radius {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let m: CGFloat = 12
        public static let md: CGFloat = 12
        public static let l: CGFloat = 16
        public static let lg: CGFloat = 16
        public static let xl: CGFloat = 20
        public static let full: CGFloat = 999
    }
    
    // MARK: - Sizing (컴포넌트 크기)
    public enum Sizing {
        // Icon Sizes
        public static let iconXS: CGFloat = 16
        public static let iconSM: CGFloat = 20
        public static let iconMD: CGFloat = 24
        public static let iconLG: CGFloat = 32
        public static let iconXL: CGFloat = 48
        public static let iconXXL: CGFloat = 64
        public static let iconLarge: CGFloat = 80
        
        // Button Heights
        public static let buttonSM: CGFloat = 32
        public static let buttonMD: CGFloat = 40
        public static let buttonLG: CGFloat = 48
        public static let buttonXL: CGFloat = 56
        
        // Input Field Heights
        public static let inputSM: CGFloat = 36
        public static let inputMD: CGFloat = 44
        public static let inputLG: CGFloat = 52
    }
    
    // MARK: - BorderWidth (테두리 두께)
    public enum BorderWidth {
        public static let hairline: CGFloat = 0.5
        public static let thin: CGFloat = 1
        public static let regular: CGFloat = 2
        public static let thick: CGFloat = 3
        public static let bold: CGFloat = 4
    }
    
    // MARK: - Glass (Native Material 기반)
    public enum Glass {
        // Material Levels
        public static let ultraThin = Material.ultraThinMaterial
        public static let thin = Material.thinMaterial
        public static let regular = Material.regularMaterial
        public static let thick = Material.thickMaterial
        
        // Glass Effect Modifier
        public struct Effect: ViewModifier {
            var material: Material = Glass.ultraThin
            var cornerRadius: CGFloat = Radius.lg
            var borderOpacity: Double = 0.1
            var shadowOpacity: Double = 0.05
            
            public func body(content: Content) -> some View {
                content
                    .background(material)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(borderOpacity), lineWidth: 0.5)
                    )
                    .shadow(
                        color: Color.black.opacity(shadowOpacity),
                        radius: 8,
                        x: 0,
                        y: 2
                    )
            }
        }
    }
    
    // MARK: - Shadows (서브틀한 깊이감)
    public enum Shadow {
        public typealias ShadowTuple = (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat)
        
        public static let xs: ShadowTuple = (color: Color.black.opacity(0.04), radius: 2.0, x: 0.0, y: 1.0)
        public static let sm: ShadowTuple = (color: Color.black.opacity(0.06), radius: 4.0, x: 0.0, y: 2.0)
        public static let md: ShadowTuple = (color: Color.black.opacity(0.08), radius: 8.0, x: 0.0, y: 4.0)
        public static let lg: ShadowTuple = (color: Color.black.opacity(0.10), radius: 16.0, x: 0.0, y: 8.0)
    }
    
    // MARK: - Gradients (프리미엄 그래디언트)
    public enum Gradients {
        
        /// 배경용 그래디언트
        public static let background = LinearGradient(
            gradient: Gradient(colors: [
                Color(hex: "#1A1B2E"),
                Color(hex: "#16213E")
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        /// 프라이머리 버튼 그래디언트
        public static let primaryButton = LinearGradient(
            gradient: Gradient(colors: [
                Color(hex: "#D4AF37"),
                Color(hex: "#F4E076")
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        /// 프라이머리 버튼용 골드 그래디언트
        public static let buttonPrimary = LinearGradient(
            gradient: Gradient(colors: [
                Color(hex: "#D4AF37"),
                Color(hex: "#F4E076")
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        /// 프리미엄 글래스모피즘 효과 (순수)
        public static let pureGlassMorphism = LinearGradient(
            gradient: Gradient(colors: [
                Color.white.opacity(0.15),
                Color.white.opacity(0.05)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        /// 다크모드용 글래스모피즘
        public static let darkGlassMorphism = LinearGradient(
            gradient: Gradient(colors: [
                Color.white.opacity(0.1),
                Color.white.opacity(0.02)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        /// 카드 배경용 서브틀 그래디언트
        public static let cardBackground = LinearGradient(
            gradient: Gradient(colors: [
                Color.white.opacity(0.8),
                Color.white.opacity(0.4)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        
        /// 성공 상태 그래디언트
        public static let success = LinearGradient(
            gradient: Gradient(colors: [
                Color(hex: "#059669"),
                Color(hex: "#065F46")
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        /// 에러 상태 그래디언트
        public static let error = LinearGradient(
            gradient: Gradient(colors: [
                Color(hex: "#DC2626"),
                Color(hex: "#991B1B")
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Effects (프리미엄 효과)
    public enum Effects {
        /// 글래스모피즘 효과를 적용하는 ViewModifier
        public static func glassMorphism(
            cornerRadius: CGFloat = Radius.l,
            material: Material = .ultraThin
        ) -> some View {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Colors.border.opacity(0.5), lineWidth: 0.5)
                )
        }
    }
    
    // MARK: - Animation (일관된 모션)
    public enum Animation {
        public static let fast = SwiftUI.Animation.easeInOut(duration: 0.15)
        public static let normal = SwiftUI.Animation.easeInOut(duration: 0.25)
        public static let slow = SwiftUI.Animation.easeInOut(duration: 0.35)
        public static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.75)
    }
}

// MARK: - View Extensions
public extension View {
    /// Apply glass effect with default settings
    func glass(
        material: Material = KingDesignTokens.Glass.ultraThin,
        cornerRadius: CGFloat = KingDesignTokens.Radius.lg
    ) -> some View {
        self.modifier(
            KingDesignTokens.Glass.Effect(
                material: material,
                cornerRadius: cornerRadius
            )
        )
    }
    
    /// Apply consistent shadow
    func shadow(_ level: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat)) -> some View {
        self.shadow(
            color: level.color,
            radius: level.radius,
            x: level.x,
            y: level.y
        )
    }
}

// MARK: - Color Extensions
private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    static func adaptive(light: Color, dark: Color) -> Color {
        #if canImport(UIKit)
        Color(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
        #else
        light
        #endif
    }
}
