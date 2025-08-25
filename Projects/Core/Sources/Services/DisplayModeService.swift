import SwiftUI
import Foundation
import Entity

/// DisplayModeServiceProtocol의 구현체
/// 기존 DisplayModeManager를 프로토콜 기반으로 리팩토링
@MainActor
public final class DisplayModeService: DisplayModeServiceProtocol {
    
    @Published public private(set) var currentMode: DisplayMode = .system
    
    private let userDefaults = UserDefaults.standard
    private let displayModeKey = "DisplayMode"
    
    public init() {
        // UserDefaults에서 저장된 값 로드, 기본값은 system
        let savedMode = userDefaults.string(forKey: displayModeKey) ?? DisplayMode.system.rawValue
        self.currentMode = DisplayMode(rawValue: savedMode) ?? .system
        
        // 초기 설정 적용
        applyDisplayMode(currentMode)
    }
    
    public func setDisplayMode(_ mode: DisplayMode) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMode = mode
        }
        
        // UserDefaults에 저장
        userDefaults.set(mode.rawValue, forKey: displayModeKey)
        
        // 실제 시스템에 적용
        applyDisplayMode(mode)
    }
    
    public var effectiveColorScheme: ColorScheme? {
        return currentMode.colorScheme
    }
    
    /// 실제로 디스플레이 모드를 시스템에 적용하는 내부 메서드
    private func applyDisplayMode(_ mode: DisplayMode) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }
        
        switch mode {
        case .system:
            window.overrideUserInterfaceStyle = .unspecified
        case .light:
            window.overrideUserInterfaceStyle = .light
        case .dark:
            window.overrideUserInterfaceStyle = .dark
        }
    }
}
