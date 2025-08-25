import SwiftUI
import Foundation
import Entity

/// DisplayModeServiceProtocol의 Mock 구현체
/// 테스트 목적으로 사용
@MainActor
public final class MockDisplayModeService: DisplayModeServiceProtocol {
    
    @Published public private(set) var currentMode: DisplayMode = .system
    
    public init(initialMode: DisplayMode = .system) {
        self.currentMode = initialMode
    }
    
    public func setDisplayMode(_ mode: DisplayMode) {
        currentMode = mode
    }
    
    public var effectiveColorScheme: ColorScheme? {
        return currentMode.colorScheme
    }
}