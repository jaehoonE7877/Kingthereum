import Foundation

/// 구조화된 로깅을 제공하는 유틸리티
/// 
/// 다양한 로그 레벨을 지원하며, 디버그 빌드에서만 작동하는 조건부 로깅을 제공합니다.
/// 각 로그 레벨은 시각적 구분을 위해 이모지를 사용하고, 프로덕션에서의 성능 영향을 최소화합니다.
/// 
/// ## 사용 예시:
/// ```swift
/// Logger.debug("상세한 디버깅 정보")
/// Logger.info("일반적인 정보")
/// Logger.warning("주의가 필요한 상황")
/// Logger.error("오류 발생")
/// ```
public enum Logger {
    
    /// 개발 중 상세한 디버깅 정보를 출력 (DEBUG 빌드에서만)
    /// 
    /// 프로덕션 빌드에서는 컴파일 타임에 제거되어 성능에 영향을 주지 않습니다.
    /// 변수 값, 함수 호출 순서, 상태 변화 등을 추적할 때 사용합니다.
    /// 
    /// - Parameter message: 출력할 디버그 메시지
    public static func debug(_ message: String) {
        guard Constants.Debug.isLoggingEnabled else { return }
        print("🔍 [DEBUG] \(message)")
    }
    
    /// 일반적인 정보성 로그 출력
    /// 
    /// 애플리케이션의 정상적인 흐름을 추적하거나 사용자에게 유용한 정보를 기록할 때 사용합니다.
    /// 프로덕션 환경에서도 출력되므로 민감한 정보는 포함하지 않아야 합니다.
    /// 
    /// - Parameter message: 출력할 정보 메시지
    public static func info(_ message: String) {
        print("ℹ️ [INFO] \(message)")
    }
    
    /// 경고성 메시지 출력
    /// 
    /// 오류는 아니지만 주의가 필요한 상황이나 권장하지 않는 동작을 기록할 때 사용합니다.
    /// 예: 폐기 예정인 API 사용, 성능 경고, 설정 문제 등
    /// 
    /// - Parameter message: 출력할 경고 메시지
    public static func warning(_ message: String) {
        print("⚠️ [WARNING] \(message)")
    }
    
    /// 오류 상황 로그 출력
    /// 
    /// 예외, 실패, 복구 가능한 오류 등을 기록할 때 사용합니다.
    /// 오류의 원인과 컨텍스트 정보를 함께 기록하는 것을 권장합니다.
    /// 
    /// - Parameter message: 출력할 오류 메시지
    public static func error(_ message: String) {
        print("❌ [ERROR] \(message)")
    }
    
    /// 파일과 라인 정보를 포함한 상세 디버그 로그 (DEBUG 빌드에서만)
    /// 
    /// 특정 코드 위치에서의 디버깅이 필요할 때 사용합니다.
    /// 호출 위치를 자동으로 추적하여 더 정확한 디버깅 정보를 제공합니다.
    /// 
    /// - Parameters:
    ///   - message: 출력할 디버그 메시지
    ///   - file: 호출한 파일 경로 (자동 제공)
    ///   - line: 호출한 라인 번호 (자동 제공)
    public static func verbose(
        _ message: String,
        file: String = #file,
        line: Int = #line
    ) {
        guard Constants.Debug.isLoggingEnabled else { return }
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        print("🔍 [VERBOSE] [\(fileName):\(line)] \(message)")
    }
}