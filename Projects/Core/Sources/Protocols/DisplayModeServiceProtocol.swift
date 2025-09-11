import SwiftUI
import Foundation
import Entity

/// 앱의 화면 테마 관리를 위한 서비스 인터페이스
/// 
/// 다크모드/라이트모드 전환 기능을 추상화하여 의존성 주입과 테스트 가능성을 제공합니다.
/// SwiftUI와 UIKit 모두에서 일관된 테마 적용을 보장하는 계약을 정의합니다.
/// 
/// ## 설계 원칙:
/// - 인터페이스 분리: 구현체와 독립적인 추상 인터페이스
/// - 테스트 용이성: Mock 구현체를 통한 단위 테스트 지원
/// - 플랫폼 중립성: SwiftUI/UIKit 모두에서 사용 가능
/// - 동시성 안전: @MainActor를 통한 UI 스레드 보장
/// 
/// ## 구현 요구사항:
/// - 모든 메서드는 메인 스레드에서 실행되어야 함
/// - 상태 변경 시 적절한 알림 메커니즘 제공 필요
/// - UserDefaults를 통한 설정 영구 저장 권장
@MainActor
public protocol DisplayModeServiceProtocol: Sendable {
    
    // MARK: - Core Properties
    
    /// 사용자가 선택한 현재 디스플레이 모드
    /// 
    /// 앱에서 설정된 테마 모드를 나타냅니다.
    /// 변경 시 관련된 UI 요소들이 자동으로 업데이트되어야 합니다.
    /// 
    /// - Returns: 현재 설정된 DisplayMode (.system, .light, .dark 중 하나)
    var currentMode: DisplayMode { get }
    
    /// SwiftUI에서 사용할 실제 ColorScheme 값
    /// 
    /// SwiftUI의 .preferredColorScheme() modifier에서 직접 사용됩니다.
    /// .system 모드일 때는 nil을 반환하여 시스템 설정을 따라야 합니다.
    /// 
    /// - Returns: SwiftUI ColorScheme 또는 nil (시스템 설정 사용)
    var effectiveColorScheme: ColorScheme? { get }
    
    // MARK: - Core Methods
    
    /// 디스플레이 모드를 새로운 값으로 변경
    /// 
    /// 지정된 모드로 앱의 테마를 변경하고 모든 UI 요소에 적용합니다.
    /// 변경사항은 영구적으로 저장되어 다음 앱 실행 시에도 유지되어야 합니다.
    /// 
    /// - Parameter mode: 새로 적용할 디스플레이 모드
    /// 
    /// ## 구현 요구사항:
    /// - UserDefaults에 설정 저장
    /// - 모든 UIWindow에 즉시 적용
    /// - SwiftUI Observable 패턴을 통한 UI 업데이트
    /// - 부드러운 전환 애니메이션 제공 (권장)
    /// 
    /// ## 사용 예시:
    /// ```swift
    /// // 다크 모드로 변경
    /// displayModeService.setDisplayMode(.dark)
    /// 
    /// // 시스템 설정 따름
    /// displayModeService.setDisplayMode(.system)
    /// ```
    func setDisplayMode(_ mode: DisplayMode)
}

// MARK: - Optional Protocol Extensions

/// DisplayModeServiceProtocol의 선택적 확장 기능들
/// 
/// 기본 구현을 제공하여 구현체의 부담을 줄이고,
/// 편의 기능들을 표준화합니다.
public extension DisplayModeServiceProtocol {
    
    /// 현재 다크 모드 적용 여부를 확인하는 편의 속성
    /// 
    /// UI 요소의 조건부 스타일링이나 로직 분기에서 사용할 수 있습니다.
    /// 시스템 모드일 때는 실제 시스템 설정을 확인해야 합니다.
    /// 
    /// - Returns: 다크 모드가 적용되었으면 true, 그렇지 않으면 false
    /// 
    /// ## 기본 구현:
    /// ```swift
    /// var isDarkMode: Bool {
    ///     switch currentMode {
    ///     case .dark: return true
    ///     case .light: return false  
    ///     case .system: return UITraitCollection.current.userInterfaceStyle == .dark
    ///     }
    /// }
    /// ```
    var isDarkMode: Bool {
        switch currentMode {
        case .dark:
            return true
        case .light:
            return false
        case .system:
            return UITraitCollection.current.userInterfaceStyle == .dark
        }
    }
    
    /// 현재 라이트 모드 적용 여부를 확인하는 편의 속성
    /// 
    /// isDarkMode의 반대 값을 제공하는 편의 속성입니다.
    /// 
    /// - Returns: 라이트 모드가 적용되었으면 true, 그렇지 않으면 false
    var isLightMode: Bool {
        return !isDarkMode
    }
}

// MARK: - Testing Support

#if DEBUG
/// 테스트용 Mock DisplayModeService 구현
/// 
/// 단위 테스트에서 사용할 수 있는 간단한 Mock 구현체입니다.
/// 실제 시스템 변경 없이 상태만 추적합니다.
@MainActor
public final class MockDisplayModeService: DisplayModeServiceProtocol {
    
    public var currentMode: DisplayMode
    public var effectiveColorScheme: ColorScheme?
    
    /// 설정 변경 이벤트 추적용 (테스트 검증)
    private(set) public var setDisplayModeCallCount = 0
    private(set) public var lastSetMode: DisplayMode?
    
    public init(initialMode: DisplayMode = .system) {
        self.currentMode = initialMode
        self.effectiveColorScheme = initialMode.colorScheme
    }
    
    public func setDisplayMode(_ mode: DisplayMode) {
        currentMode = mode
        effectiveColorScheme = mode.colorScheme
        setDisplayModeCallCount += 1
        lastSetMode = mode
        
        print("MockDisplayModeService: 모드 변경됨 → \(mode.rawValue)")
    }
    
    /// 테스트 상태 초기화
    public func resetTestState() {
        setDisplayModeCallCount = 0
        lastSetMode = nil
    }
}
#endif
