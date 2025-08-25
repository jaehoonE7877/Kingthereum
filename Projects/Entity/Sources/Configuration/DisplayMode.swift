import Foundation
import SwiftUI

/// 디스플레이 모드를 나타내는 열거형
public enum DisplayMode: String, CaseIterable, Identifiable, Sendable {
    case light = "light"
    case dark = "dark"
    case system = "system"
    
    public var id: String { rawValue }
    
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
    
    // 테스트 호환을 위한 추가 프로퍼티
    public var name: String {
        switch self {
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        case .system:
            return "System"
        }
    }
    
    public var description: String {
        switch self {
        case .light:
            return "Light mode"
        case .dark:
            return "Dark mode"
        case .system:
            return "Follow system setting"
        }
    }
    
    public var systemIcon: String {
        switch self {
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        case .system:
            return "gear"
        }
    }
    
    /// SwiftUI의 ColorScheme으로 변환
    /// nil을 반환하면 시스템 설정을 따름
    public var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil  // 시스템 설정 따라하기
        case .light: return .light
        case .dark: return .dark
        }
    }
}