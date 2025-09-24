import SwiftUI
import Foundation
import Entity

/// DisplayModeServiceProtocol의 구체적인 구현체
/// 
/// 앱의 다크모드/라이트모드 설정을 관리하고 시스템 전반에 일관되게 적용합니다.
/// SwiftUI의 @Observable과 UIKit의 overrideUserInterfaceStyle을 모두 지원하여
/// 하이브리드 UI 환경에서도 완벽하게 작동합니다.
/// 
/// ## 주요 기능:
/// - 사용자 선호도 영구 저장 (UserDefaults)
/// - 시스템 설정 추적 (.system 모드)
/// - 실시간 테마 변경 (애니메이션 포함)
/// - 모든 UIWindow에 일관된 테마 적용
/// 
/// ## 지원 모드:
/// - `.system`: 시스템 설정 따름
/// - `.light`: 항상 라이트 모드
/// - `.dark`: 항상 다크 모드
@MainActor
public final class DisplayModeService: DisplayModeServiceProtocol, ObservableObject {
    
    // MARK: - Published Properties
    
    /// 현재 선택된 디스플레이 모드
    /// 
    /// 사용자가 설정한 모드로, UserDefaults에 영구 저장됩니다.
    /// 값이 변경되면 자동으로 effectiveColorScheme도 업데이트됩니다.
    @Published public private(set) var currentMode: DisplayMode = .system {
        didSet {
            // currentMode가 변경될 때마다 effectiveColorScheme도 업데이트
            effectiveColorScheme = currentMode.colorScheme
            Logger.debug("디스플레이 모드 변경: \(oldValue.rawValue) → \(currentMode.rawValue)")
        }
    }
    
    /// SwiftUI에서 사용할 실제 ColorScheme
    /// 
    /// SwiftUI의 .preferredColorScheme() modifier에서 사용됩니다.
    /// .system 모드일 때는 nil을 반환하여 시스템 설정을 따릅니다.
    @Published public private(set) var effectiveColorScheme: ColorScheme?
    
    // MARK: - Private Properties
    
    /// UserDefaults 인스턴스 (테스트 가능성을 위해 주입 가능)
    private let userDefaults: UserDefaults
    private let shouldApplyToSystem: Bool
    
    /// UserDefaults에서 사용할 키 이름
    private let displayModeKey = "DisplayMode"
    
    /// 애니메이션 지속시간
    private let animationDuration: Double = 0.3
    
    // MARK: - Initialization
    
    /// DisplayModeService 초기화
    /// 
    /// UserDefaults에서 이전에 저장된 설정을 복원하고,
    /// 시스템에 초기 테마를 적용합니다.
    /// 
    /// - Parameter userDefaults: 사용할 UserDefaults 인스턴스 (기본값: .standard)
    public init(userDefaults: UserDefaults = .standard, applyToSystem: Bool = true) {
        self.userDefaults = userDefaults
        self.shouldApplyToSystem = applyToSystem
        
        // UserDefaults에서 저장된 값 로드, 기본값은 system
        let savedModeRawValue = userDefaults.string(forKey: displayModeKey) ?? DisplayMode.system.rawValue
        let restoredMode = DisplayMode(rawValue: savedModeRawValue) ?? .system
        
        // 초기값 설정 (didSet이 호출되지 않으므로 수동으로 effectiveColorScheme 설정)
        self.currentMode = restoredMode
        self.effectiveColorScheme = restoredMode.colorScheme
        
        Logger.debug("DisplayModeService 초기화: \(restoredMode.rawValue) 모드로 복원")
        
        // 복원된 설정을 시스템에 적용
        applyDisplayModeToSystem(restoredMode)
    }
    
    // MARK: - Public Methods
    
    /// 디스플레이 모드를 변경하고 시스템에 적용
    /// 
    /// 새로운 모드를 설정하고 UserDefaults에 저장한 후,
    /// 모든 UIWindow에 변경사항을 적용합니다.
    /// 부드러운 전환을 위해 애니메이션을 사용합니다.
    /// 
    /// - Parameter mode: 새로 설정할 디스플레이 모드
    /// 
    /// ## 사용 예시:
    /// ```swift
    /// displayModeService.setDisplayMode(.dark)
    /// ```
    public func setDisplayMode(_ mode: DisplayMode) {
        // 같은 모드로 설정하려는 경우 무시
        guard currentMode != mode else { 
            Logger.debug("동일한 모드로 설정 요청 무시: \(mode.rawValue)")
            return 
        }
        
        Logger.info("디스플레이 모드 변경 요청: \(currentMode.rawValue) → \(mode.rawValue)")
        
        // SwiftUI 애니메이션과 함께 상태 업데이트
        if shouldApplyToSystem {
            withAnimation(.easeInOut(duration: animationDuration)) {
                currentMode = mode
            }
        } else {
            currentMode = mode
        }
        
        // UserDefaults에 영구 저장
        userDefaults.set(mode.rawValue, forKey: displayModeKey)
        
        // 시스템 레벨 적용 (UIKit)
        applyDisplayModeToSystem(mode)
    }
    
    /// 현재 시스템의 실제 ColorScheme 반환 (읽기 전용)
    /// 
    /// .system 모드일 때 실제로 시스템이 어떤 테마를 사용하고 있는지 확인할 때 사용합니다.
    /// 디버깅이나 UI 상태 확인 용도로 활용됩니다.
    /// 
    /// - Returns: 현재 시스템의 실제 ColorScheme
    public var systemColorScheme: ColorScheme {
        return UITraitCollection.current.userInterfaceStyle == .dark ? .dark : .light
    }
    
    // MARK: - Private Methods
    
    /// 실제로 디스플레이 모드를 시스템에 적용하는 내부 메서드
    /// 
    /// 모든 연결된 UIWindowScene의 모든 UIWindow에 대해
    /// overrideUserInterfaceStyle을 설정합니다.
    /// 
    /// - Parameter mode: 적용할 디스플레이 모드
    private func applyDisplayModeToSystem(_ mode: DisplayMode) {
        guard shouldApplyToSystem else { return }

        Logger.debug("시스템에 디스플레이 모드 적용 중: \(mode.rawValue)")
        
        // 적용할 UIUserInterfaceStyle 결정
        let interfaceStyle: UIUserInterfaceStyle
        switch mode {
        case .system:
            interfaceStyle = .unspecified  // 시스템 설정 따름
        case .light:
            interfaceStyle = .light        // 강제 라이트 모드
        case .dark:
            interfaceStyle = .dark         // 강제 다크 모드
        }
        
        // 모든 연결된 윈도우 씬에 적용
        var windowCount = 0
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            
            for window in windowScene.windows {
                window.overrideUserInterfaceStyle = interfaceStyle
                windowCount += 1
            }
        }
        
        Logger.debug("디스플레이 모드 적용 완료: \(windowCount)개 윈도우에 \(mode.rawValue) 적용")
        
        // @MainActor 컨텍스트이므로 즉시 변경 알림을 전파
        objectWillChange.send()
    }
}

// MARK: - Convenience Extensions

public extension DisplayModeService {
    
    /// 다크 모드인지 여부를 확인하는 편의 속성
    /// 
    /// 현재 설정이 다크 모드이거나, 시스템 모드이면서 시스템이 다크 모드인 경우 true를 반환합니다.
    /// UI 요소의 조건부 스타일링에 유용합니다.
    /// 
    /// - Returns: 현재 다크 모드 적용 여부
    var isDarkMode: Bool {
        switch currentMode {
        case .dark:
            return true
        case .light:
            return false
        case .system:
            return systemColorScheme == .dark
        }
    }
    
    /// 라이트 모드인지 여부를 확인하는 편의 속성
    /// 
    /// isDarkMode의 반대 값을 반환합니다.
    /// 
    /// - Returns: 현재 라이트 모드 적용 여부
    var isLightMode: Bool {
        return !isDarkMode
    }
    
    /// 다음 모드로 순환 변경하는 편의 메서드
    /// 
    /// system → light → dark → system 순서로 순환합니다.
    /// 토글 버튼이나 제스처를 통한 빠른 모드 전환에 유용합니다.
    func toggleToNextMode() {
        let nextMode: DisplayMode
        switch currentMode {
        case .system:
            nextMode = .light
        case .light:
            nextMode = .dark
        case .dark:
            nextMode = .system
        }
        
        Logger.debug("다음 모드로 순환: \(currentMode.rawValue) → \(nextMode.rawValue)")
        setDisplayMode(nextMode)
    }
}
