import SwiftUI
import Foundation
import Entity

/// 앱의 화면 모드 관리를 위한 프로토콜
/// DisplayModeManager의 인터페이스를 정의하여 의존성 주입과 테스트 가능성 확보
@MainActor
public protocol DisplayModeServiceProtocol: Sendable {
    
    /// 현재 선택된 디스플레이 모드
    var currentMode: DisplayMode { get }
    
    /// 디스플레이 모드 변경
    /// - Parameter mode: 새로운 디스플레이 모드
    func setDisplayMode(_ mode: DisplayMode)
    
    /// 현재 효과적인 ColorScheme 반환
    /// SwiftUI의 preferredColorScheme에서 사용
    var effectiveColorScheme: ColorScheme? { get }
}
