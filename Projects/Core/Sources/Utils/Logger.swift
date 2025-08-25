import Foundation

/// 조건부 로깅을 위한 Logger 유틸리티
public enum Logger {
    
    /// 디버그 로그 출력 (DEBUG 빌드에서만)
    public static func debug(_ message: String) {
        guard Constants.Debug.isLoggingEnabled else { return }
        print(message)
    }
    
    /// 정보 로그 출력 (항상 출력)
    public static func info(_ message: String) {
        print(message)
    }
    
    /// 경고 로그 출력 (항상 출력)
    public static func warning(_ message: String) {
        print("⚠️ \(message)")
    }
    
    /// 에러 로그 출력 (항상 출력)
    public static func error(_ message: String) {
        print("❌ \(message)")
    }
}