import SwiftUI
import Foundation
import Entity

/// DisplayModeServiceProtocol의 구현체
/// 기존 DisplayModeManager를 프로토콜 기반으로 리팩토링
@MainActor
public final class DisplayModeService: DisplayModeServiceProtocol, ObservableObject {
    
    @Published public private(set) var currentMode: DisplayMode = .system {
        didSet {
            // currentMode가 변경될 때마다 effectiveColorScheme도 업데이트
            effectiveColorScheme = currentMode.colorScheme
        }
    }
    
    @Published public private(set) var effectiveColorScheme: ColorScheme?
    
    private let userDefaults = UserDefaults.standard
    private let displayModeKey = "DisplayMode"
    
    public init() {
        // UserDefaults에서 저장된 값 로드, 기본값은 system
        let savedMode = userDefaults.string(forKey: displayModeKey) ?? DisplayMode.system.rawValue
        let mode = DisplayMode(rawValue: savedMode) ?? .system
        
        // 초기값 설정
        self.currentMode = mode
        self.effectiveColorScheme = mode.colorScheme
        
        // 초기 설정 적용
        applyDisplayMode(mode)
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
    
    /// 실제로 디스플레이 모드를 시스템에 적용하는 내부 메서드
    private func applyDisplayMode(_ mode: DisplayMode) {
        // 모든 연결된 윈도우 씬에 적용
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            
            for window in windowScene.windows {
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
        
        // 메인 쓰레드에서 UI 업데이트 강제 실행
        DispatchQueue.main.async { [weak self] in
            self?.objectWillChange.send()
        }
    }
}
