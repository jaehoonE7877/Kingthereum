import SwiftUI

/// 4단계 GlassMorphism 효과 시스템의 디자인 토큰
/// 각 레벨은 시각적 깊이와 강조 수준에 따라 구분됨
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
        
        /// 각 레벨별 블러 반경
        public var blurRadius: CGFloat {
            switch self {
            case .subtle: return 8
            case .standard: return 12
            case .prominent: return 16
            case .intense: return 24
            }
        }
        
        /// 각 레벨별 투명도
        public var opacity: Double {
            switch self {
            case .subtle: return 0.4
            case .standard: return 0.6
            case .prominent: return 0.8
            case .intense: return 0.95
            }
        }
        
        /// 각 레벨별 테두리 두께
        public var borderWidth: CGFloat {
            switch self {
            case .subtle: return 0.5
            case .standard: return 1.0
            case .prominent: return 1.5
            case .intense: return 2.0
            }
        }
        
        /// 각 레벨별 그림자 반경
        public var shadowRadius: CGFloat {
            switch self {
            case .subtle: return 4
            case .standard: return 8
            case .prominent: return 12
            case .intense: return 20
            }
        }
        
        /// 각 레벨별 그림자 Y 오프셋
        public var shadowOffset: CGFloat {
            switch self {
            case .subtle: return 2
            case .standard: return 4
            case .prominent: return 6
            case .intense: return 10
            }
        }
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
        
        /// 기본 색상 적응 설정
        public static let `default` = ColorAdaptation(light: 0.6, dark: 0.8, vibrant: 0.7)
        
        /// 테두리용 색상 적응 설정
        public static let border = ColorAdaptation(light: 0.3, dark: 0.5, vibrant: 0.4)
        
        /// 그림자용 색상 적응 설정
        public static let shadow = ColorAdaptation(light: 0.2, dark: 0.6, vibrant: 0.5)
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