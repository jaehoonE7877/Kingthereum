import SwiftUI

/// Kingthereum 프리미엄 글래스모피즘 시스템 2024
/// 모던 미니멀리즘 + 프리미엄 피나테크 + 극도로 서브틀한 글래스 효과
public struct GlassTokens {
    
    // MARK: - Glass Effect Levels
    
    /// Glass 효과의 4단계 레벨
    public enum EffectLevel: String, CaseIterable, Sendable {
        case subtle = "subtle"           // 1레벨: 미묘한 효과
        case standard = "standard"       // 2레벨: 표준 효과
        case prominent = "prominent"     // 3레벨: 강조된 효과
        case intense = "intense"         // 4레벨: 강력한 효과
        
        public var displayName: String {
            switch self {
            case .subtle: return "미묘한"
            case .standard: return "표준"
            case .prominent: return "강조된"
            case .intense: return "강력한"
            }
        }
        
        /// 각 레벨별 Material 강도
        public var material: Material {
            switch self {
            case .subtle: return .thinMaterial
            case .standard: return .regularMaterial
            case .prominent: return .thickMaterial
            case .intense: return .ultraThickMaterial
            }
        }
        
        /// 접근성 설정에 따른 적응형 Material (2024 최적화)
        @MainActor
        public func accessibilityAdaptedMaterial(
            reduceTransparency: Bool = false,
            increaseContrast: Bool = false
        ) -> Material {
            // 투명도 감소 설정이 켜져 있으면 더 두꺼운 Material 사용
            if reduceTransparency {
                switch self {
                case .subtle: return .regularMaterial
                case .standard: return .thickMaterial
                case .prominent: return .ultraThickMaterial
                case .intense: return .ultraThickMaterial
                }
            }
            
            // 대비 증가 설정이 켜져 있으면 한 단계 두꺼운 Material 사용
            if increaseContrast {
                switch self {
                case .subtle: return .regularMaterial
                case .standard: return .thickMaterial
                case .prominent: return .ultraThickMaterial
                case .intense: return .ultraThickMaterial
                }
            }
            
            return material
        }
        
        /// Material (향후 확장)
        public var modernMaterial: Material {
            switch self {
            case .subtle: return .bar  // iOS 18+ 새로운 Material
            case .standard: return .regularMaterial
            case .prominent: return .thickMaterial  // iOS 18+ 새로운 Material
            case .intense: return .ultraThickMaterial
            }
        }
        
        /// 미니멀리즘 블러 반경 - 극도로 서브틀한 효과
        public var minimalistBlurRadius: CGFloat {
            switch self {
            case .subtle: return 4    // 더 연하게
            case .standard: return 6  // 더 연하게
            case .prominent: return 8 // 더 연하게
            case .intense: return 12  // 더 연하게
            }
        }
        
        /// 미니멀리즘 투명도 - 거의 보이지 않을 정도로 서브틀
        public var minimalistOpacity: Double {
            switch self {
            case .subtle: return 0.15    // 극도로 연하게
            case .standard: return 0.25  // 연하게
            case .prominent: return 0.4  // 중간
            case .intense: return 0.6    // 최대 60%만
            }
        }
        
        /// 미니멀리즘 테두리 두께 - 거의 보이지 않는 수준
        public var minimalistBorderWidth: CGFloat {
            switch self {
            case .subtle: return 0.25   // 극도로 얇게
            case .standard: return 0.5  // 얇게
            case .prominent: return 0.75 // 중간
            case .intense: return 1.0   // 최대 1pt
            }
        }
        
        /// 미니멀리즘 그림자 반경 - 극도로 서브틀한 깊이감
        public var minimalistShadowRadius: CGFloat {
            switch self {
            case .subtle: return 2    // 매우 연하게
            case .standard: return 4  // 연하게
            case .prominent: return 6 // 중간
            case .intense: return 8   // 최대 8pt
            }
        }
        
        /// 미니멀리즘 그림자 오프셋 - 서브틀한 깊이
        public var minimalistShadowOffset: CGFloat {
            switch self {
            case .subtle: return 1    // 매우 연하게
            case .standard: return 2  // 연하게  
            case .prominent: return 3 // 중간
            case .intense: return 4   // 최대 4pt
            }
        }
        
        // MARK: - Legacy Properties (호환성 유지)
        
        /// 기존 blurRadius → minimalistBlurRadius로 매핑
        public var blurRadius: CGFloat { minimalistBlurRadius }
        
        /// 기존 opacity → minimalistOpacity로 매핑
        public var opacity: Double { minimalistOpacity }
        
        /// 기존 borderWidth → minimalistBorderWidth로 매핑
        public var borderWidth: CGFloat { minimalistBorderWidth }
        
        /// 기존 shadowRadius → minimalistShadowRadius로 매핑
        public var shadowRadius: CGFloat { minimalistShadowRadius }
        
        /// 기존 shadowOffset → minimalistShadowOffset으로 매핑
        public var shadowOffset: CGFloat { minimalistShadowOffset }
    }
    
    // MARK: - Glass Context
    
    /// Glass 컴포넌트의 사용 맥락
    public enum Context: String, CaseIterable, Sendable {
        case card = "card"               // 카드 형태
        case button = "button"           // 버튼 요소
        case navigation = "navigation"   // 네비게이션 요소
        case modal = "modal"             // 모달/팝업
        case background = "background"   // 배경 요소
        
        /// 맥락별 기본 효과 레벨
        public var defaultEffectLevel: EffectLevel {
            switch self {
            case .card: return .standard
            case .button: return .subtle
            case .navigation: return .prominent
            case .modal: return .intense
            case .background: return .subtle
            }
        }
        
        /// 맥락별 기본 모서리 반경
        public var defaultCornerRadius: CGFloat {
            switch self {
            case .card: return DesignTokens.CornerRadius.lg
            case .button: return DesignTokens.CornerRadius.md
            case .navigation: return DesignTokens.CornerRadius.xl
            case .modal: return DesignTokens.CornerRadius.lg
            case .background: return 0
            }
        }
    }
    
    // MARK: - Color Adaptation
    
    /// 테마별 색상 적응 설정
    public struct ColorAdaptation: Sendable {
        public let light: Double
        public let dark: Double
        public let vibrant: Double
        
        public init(light: Double, dark: Double, vibrant: Double) {
            self.light = light
            self.dark = dark
            self.vibrant = vibrant
        }
        
        /// 미니멀리즘 기본 색상 적응 - 극도로 서브틀
        public static let minimalist = ColorAdaptation(light: 0.15, dark: 0.25, vibrant: 0.2)
        
        /// 미니멀리즘 테두리 색상 적응 - 거의 보이지 않는 수준
        public static let minimalistBorder = ColorAdaptation(light: 0.08, dark: 0.15, vibrant: 0.12)
        
        /// 미니멀리즘 그림자 색상 적응 - 극도로 연한 깊이감
        public static let minimalistShadow = ColorAdaptation(light: 0.05, dark: 0.2, vibrant: 0.15)
        
        // MARK: - Legacy Adaptations (호환성 유지)
        
        /// 기존 default → minimalist로 매핑
        public static let `default` = minimalist
        
        /// 기존 border → minimalistBorder로 매핑
        public static let border = minimalistBorder
        
        /// 기존 shadow → minimalistShadow로 매핑  
        public static let shadow = minimalistShadow
    }
    
    // MARK: - Animation Settings
    
    /// Glass 효과 애니메이션 설정
    public struct AnimationTokens: Sendable {
        public let duration: TimeInterval
        public let curve: Animation
        
        public init(duration: TimeInterval, curve: Animation) {
            self.duration = duration
            self.curve = curve
        }
        
        /// 빠른 전환 애니메이션
        public static let quick = AnimationTokens(
            duration: 0.15,
            curve: .easeInOut(duration: 0.15)
        )
        
        /// 표준 전환 애니메이션
        public static let standard = AnimationTokens(
            duration: 0.3,
            curve: .easeInOut(duration: 0.3)
        )
        
        /// 부드러운 전환 애니메이션
        public static let smooth = AnimationTokens(
            duration: 0.5,
            curve: .spring(response: 0.5, dampingFraction: 0.8)
        )
        
        /// 탄성 효과 애니메이션
        public static let bouncy = AnimationTokens(
            duration: 0.6,
            curve: .spring(response: 0.4, dampingFraction: 0.7)
        )
    }
}

// MARK: - Environment Support

/// GlassTheme를 위한 환경 키
public struct GlassThemeKey: EnvironmentKey {
    public static let defaultValue = GlassTheme.system
}

/// GlassEffectLevel을 위한 환경 키
public struct GlassEffectLevelKey: EnvironmentKey {
    public static let defaultValue = GlassTokens.EffectLevel.standard
}

public extension EnvironmentValues {
    var glassTheme: GlassTheme {
        get { self[GlassThemeKey.self] }
        set { self[GlassThemeKey.self] = newValue }
    }
    
    var glassEffectLevel: GlassTokens.EffectLevel {
        get { self[GlassEffectLevelKey.self] }
        set { self[GlassEffectLevelKey.self] = newValue }
    }
}

/// Glass 컴포넌트의 테마 (기존 GlassTheme과 호환성 유지)
public enum GlassTheme: String, CaseIterable, Sendable {
    case system = "system"
    case light = "light" 
    case dark = "dark"
    case vibrant = "vibrant"
    
    public var displayName: String {
        switch self {
        case .system: return "시스템"
        case .light: return "라이트"
        case .dark: return "다크"
        case .vibrant: return "생생한"
        }
    }
}
