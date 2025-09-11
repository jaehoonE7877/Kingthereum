import Foundation
import SwiftUI

/// 앱의 화면 테마 모드를 정의하는 열거형
/// 
/// 사용자가 선택할 수 있는 화면 테마 옵션을 제공합니다.
/// SwiftUI와 UIKit 모두에서 일관된 테마 적용을 지원하며,
/// 시스템 설정을 따르거나 수동으로 라이트/다크 모드를 선택할 수 있습니다.
/// 
/// ## 지원 모드:
/// - `.system`: 기기의 시스템 설정을 따름 (iOS 13+ 다크모드 지원)
/// - `.light`: 항상 라이트 테마로 고정
/// - `.dark`: 항상 다크 테마로 고정
/// 
/// ## 사용 예시:
/// ```swift
/// // SwiftUI에서 사용
/// @State private var displayMode: DisplayMode = .system
/// 
/// var body: some View {
///     ContentView()
///         .preferredColorScheme(displayMode.colorScheme)
/// }
/// 
/// // 설정 화면에서 사용
/// Picker("테마", selection: $displayMode) {
///     ForEach(DisplayMode.allCases) { mode in
///         Label(mode.displayName, systemImage: mode.iconName)
///             .tag(mode)
///     }
/// }
/// ```
public enum DisplayMode: String, CaseIterable, Identifiable, Sendable {
    /// 라이트 모드 (밝은 테마)
    case light = "light"
    
    /// 다크 모드 (어두운 테마)
    case dark = "dark"
    
    /// 시스템 설정 따름 (자동)
    case system = "system"
    
    // MARK: - Identifiable Conformance
    
    /// SwiftUI ForEach에서 사용하는 식별자
    public var id: String { rawValue }
    
    // MARK: - Display Properties
    
    /// 사용자에게 표시되는 모드 이름 (한국어)
    /// 
    /// 설정 화면, 메뉴, 토글 버튼 등에서 사용자에게 표시되는 텍스트입니다.
    /// 
    /// - Returns: 각 모드에 해당하는 한국어 표시명
    public var displayName: String {
        switch self {
        case .light:
            return "라이트 모드"
        case .dark:
            return "다크 모드"
        case .system:
            return "시스템 설정"
        }
    }
    
    /// SF Symbols 아이콘 이름
    /// 
    /// 각 테마 모드를 시각적으로 표현하는 SF Symbols 아이콘입니다.
    /// SwiftUI의 Image(systemName:)에서 직접 사용할 수 있습니다.
    /// 
    /// - Returns: 해당 모드의 SF Symbols 아이콘 이름
    public var iconName: String {
        switch self {
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        case .system:
            return "gearshape.fill"
        }
    }
    
    /// 영문 모드 이름 (시스템/로그용)
    /// 
    /// API 통신, 로그 기록, 설정 파일 저장 등에서 사용하는 영문 이름입니다.
    /// 
    /// - Returns: 해당 모드의 영문 이름
    public var englishName: String {
        switch self {
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        case .system:
            return "System"
        }
    }
    
    /// 모드 설명 텍스트
    /// 
    /// 각 테마 모드의 동작을 설명하는 텍스트입니다.
    /// 도움말, 툴팁, 온보딩 화면 등에서 사용할 수 있습니다.
    /// 
    /// - Returns: 해당 모드의 상세 설명
    public var description: String {
        switch self {
        case .light:
            return "항상 밝은 테마를 사용합니다"
        case .dark:
            return "항상 어두운 테마를 사용합니다"
        case .system:
            return "기기의 시스템 설정을 따릅니다"
        }
    }
    
    // MARK: - SwiftUI Integration
    
    /// SwiftUI ColorScheme으로 변환
    /// 
    /// SwiftUI의 .preferredColorScheme() modifier에서 직접 사용할 수 있는
    /// ColorScheme 값으로 변환합니다. nil을 반환하면 시스템 설정을 따릅니다.
    /// 
    /// - Returns: 
    ///   - `.light`: ColorScheme.light
    ///   - `.dark`: ColorScheme.dark  
    ///   - `.system`: nil (시스템 설정 사용)
    /// 
    /// ## 사용 예시:
    /// ```swift
    /// ContentView()
    ///     .preferredColorScheme(displayMode.colorScheme)
    /// ```
    public var colorScheme: ColorScheme? {
        switch self {
        case .system: 
            return nil  // 시스템 설정을 따름
        case .light: 
            return .light
        case .dark: 
            return .dark
        }
    }
    
    /// 현재 실제로 적용되는 ColorScheme 계산
    /// 
    /// .system 모드일 때 현재 시스템의 실제 테마를 반환합니다.
    /// 실제 UI 렌더링에서 어떤 테마가 적용될지 확인할 때 사용합니다.
    /// 
    /// - Returns: 실제 적용되는 ColorScheme (.light 또는 .dark)
    public var effectiveColorScheme: ColorScheme {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            // iOS 시스템의 현재 인터페이스 스타일 확인
            return UITraitCollection.current.userInterfaceStyle == .dark ? .dark : .light
        }
    }
    
    // MARK: - Utility Methods
    
    /// 다음 모드로 순환
    /// 
    /// system → light → dark → system 순서로 순환합니다.
    /// 토글 버튼이나 제스처를 통한 빠른 테마 전환에 유용합니다.
    /// 
    /// - Returns: 다음 순서의 DisplayMode
    public func next() -> DisplayMode {
        switch self {
        case .system: return .light
        case .light: return .dark
        case .dark: return .system
        }
    }
    
    /// 특정 ColorScheme과 일치하는지 확인
    /// 
    /// - Parameter colorScheme: 비교할 ColorScheme
    /// - Returns: 현재 모드가 지정된 ColorScheme와 일치하면 true
    public func matches(_ colorScheme: ColorScheme) -> Bool {
        return effectiveColorScheme == colorScheme
    }
}
