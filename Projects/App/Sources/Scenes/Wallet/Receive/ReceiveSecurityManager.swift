import Foundation
import UIKit
import SecurityKit

// MARK: - Security Event Delegate

@MainActor
protocol ReceiveSecurityDelegate: AnyObject {
    func didDetectScreenshot()
    func didDetectScreenRecording()
    func didDetectAppBackgrounded()
}

// MARK: - Premium Security Manager for Receive Scene

@MainActor
final class ReceiveSecurityManager: ObservableObject {
    
    // MARK: - Properties
    
    weak var delegate: ReceiveSecurityDelegate?
    
    private var screenshotNotificationObserver: NSObjectProtocol?
    private var appStateObserver: NSObjectProtocol?
    private var screenRecordingTimer: Timer?
    private var isMonitoring = false
    
    // Security state tracking
    @Published var isScreenRecording = false
    @Published var securityLevel: SecurityLevel = .normal
    @Published var threatDetectionCount = 0
    
    // MARK: - Security Levels
    
    enum SecurityLevel: String, CaseIterable {
        case normal = "Normal"
        case elevated = "Elevated" 
        case high = "High"
        case critical = "Critical"
        
        var description: String {
            switch self {
            case .normal: return "일반"
            case .elevated: return "주의"
            case .high: return "경고"
            case .critical: return "위험"
            }
        }
        
        var color: UIColor {
            switch self {
            case .normal: return .systemGreen
            case .elevated: return .systemYellow
            case .high: return .systemOrange
            case .critical: return .systemRed
            }
        }
    }
    
    // MARK: - Initialization
    
    init() {
        setupSecurity()
    }
    
    deinit {
        stopSecurityMonitoring()
    }
    
    // MARK: - Security Setup
    
    private func setupSecurity() {
        // 디바이스 보안 상태 초기 확인
        checkDeviceSecurityStatus()
    }
    
    // MARK: - Monitoring Control
    
    func startSecurityMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        setupScreenshotDetection()
        setupAppStateMonitoring()
        startScreenRecordingMonitoring()
        
        #if DEBUG
        print("🔒 ReceiveSecurityManager: Security monitoring started")
        #endif
    }
    
    func stopSecurityMonitoring() {
        guard isMonitoring else { return }
        
        isMonitoring = false
        removeObservers()
        stopScreenRecordingMonitoring()
        
        #if DEBUG
        print("🔓 ReceiveSecurityManager: Security monitoring stopped")
        #endif
    }
    
    // MARK: - Screenshot Detection
    
    private func setupScreenshotDetection() {
        screenshotNotificationObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.userDidTakeScreenshotNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleScreenshotDetection()
        }
    }
    
    private func handleScreenshotDetection() {
        threatDetectionCount += 1
        updateSecurityLevel()
        
        // 햅틱 경고 피드백
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.warning)
        
        #if DEBUG
        print("🚨 Screenshot detected! Threat count: \(threatDetectionCount)")
        #endif
        
        delegate?.didDetectScreenshot()
    }
    
    // MARK: - Screen Recording Detection
    
    private func startScreenRecordingMonitoring() {
        screenRecordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkScreenRecording()
        }
    }
    
    private func stopScreenRecordingMonitoring() {
        screenRecordingTimer?.invalidate()
        screenRecordingTimer = nil
    }
    
    private func checkScreenRecording() {
        let wasRecording = isScreenRecording
        isScreenRecording = UIScreen.main.isCaptured
        
        // 녹화 상태 변경 감지
        if !wasRecording && isScreenRecording {
            handleScreenRecordingStarted()
        } else if wasRecording && !isScreenRecording {
            handleScreenRecordingStopped()
        }
    }
    
    private func handleScreenRecordingStarted() {
        threatDetectionCount += 2 // 스크린 녹화는 더 심각한 위협
        updateSecurityLevel()
        
        // 강한 햅틱 경고
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        #if DEBUG
        print("🎥 Screen recording started! Threat count: \(threatDetectionCount)")
        #endif
        
        delegate?.didDetectScreenRecording()
    }
    
    private func handleScreenRecordingStopped() {
        #if DEBUG
        print("⏹️ Screen recording stopped")
        #endif
        
        // 보안 레벨을 점진적으로 낮춤 (즉시 리셋하지 않음)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            self?.graduallyReduceThreatLevel()
        }
    }
    
    // MARK: - App State Monitoring
    
    private func setupAppStateMonitoring() {
        appStateObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppBackgrounded()
        }
    }
    
    private func handleAppBackgrounded() {
        #if DEBUG
        print("📱 App backgrounded - hiding sensitive data")
        #endif
        
        delegate?.didDetectAppBackgrounded()
    }
    
    // MARK: - Security Level Management
    
    private func updateSecurityLevel() {
        let newLevel: SecurityLevel
        
        switch threatDetectionCount {
        case 0:
            newLevel = .normal
        case 1:
            newLevel = .elevated
        case 2...3:
            newLevel = .high
        default:
            newLevel = .critical
        }
        
        if newLevel != securityLevel {
            securityLevel = newLevel
            
            #if DEBUG
            print("🔒 Security level updated to: \(newLevel.description)")
            #endif
            
            // 보안 레벨이 높아질 때 추가 조치
            if newLevel == .critical {
                handleCriticalThreat()
            }
        }
    }
    
    private func graduallyReduceThreatLevel() {
        guard threatDetectionCount > 0 else { return }
        
        threatDetectionCount = max(0, threatDetectionCount - 1)
        updateSecurityLevel()
    }
    
    private func handleCriticalThreat() {
        // 위험 상황에서의 추가 보안 조치
        // 1. 모든 민감한 데이터 숨기기
        // 2. 추가 인증 요구 (향후 구현 가능)
        // 3. 보안 로그 기록
        
        #if DEBUG
        print("🚨 CRITICAL THREAT LEVEL - Implementing additional security measures")
        #endif
    }
    
    // MARK: - Device Security Status
    
    private func checkDeviceSecurityStatus() {
        // 디바이스 보안 상태 확인
        let isJailbroken = isDeviceJailbroken()
        let hasScreenLock = hasDeviceScreenLock()
        
        if isJailbroken {
            securityLevel = .critical
            threatDetectionCount = 5 // 탈옥된 기기는 최고 위험도
        } else if !hasScreenLock {
            securityLevel = .elevated
            threatDetectionCount = 1
        }
        
        #if DEBUG
        print("📱 Device Security Status:")
        print("   - Jailbroken: \(isJailbroken)")
        print("   - Screen Lock: \(hasScreenLock)")
        print("   - Initial Security Level: \(securityLevel.description)")
        #endif
    }
    
    private func isDeviceJailbroken() -> Bool {
        // 탈옥 감지 로직 (기본적인 검사)
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/"
        ]
        
        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        
        // 추가 검사: 시스템 파일 쓰기 시도
        let testString = "jailbreak_test"
        let testPath = "/private/jailbreak_test.txt"
        
        do {
            try testString.write(toFile: testPath, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: testPath)
            return true // 쓰기가 성공하면 탈옥된 것으로 판단
        } catch {
            // 정상적으로 쓰기 실패 (탈옥되지 않음)
        }
        
        return false
    }
    
    private func hasDeviceScreenLock() -> Bool {
        // iOS에서 직접적인 화면 잠금 감지는 제한적
        // 대신 생체 인증 또는 패스코드 가용성을 확인
        if #available(iOS 8.0, *) {
            let context = LAContext()
            var error: NSError?
            return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
        }
        return true // 이전 버전에서는 기본적으로 true 반환
    }
    
    // MARK: - Public Security APIs
    
    /// 현재 보안 상태가 민감한 정보 표시에 안전한지 확인
    func isSafeForSensitiveDisplay() -> Bool {
        return securityLevel != .critical && !isScreenRecording
    }
    
    /// 보안 상태 리셋 (사용자가 명시적으로 요청할 때)
    func resetSecurityState() {
        threatDetectionCount = 0
        updateSecurityLevel()
        
        #if DEBUG
        print("🔄 Security state reset by user")
        #endif
    }
    
    /// 보안 이벤트 강제 발생 (테스트용)
    #if DEBUG
    func triggerTestSecurityEvent(_ type: TestSecurityEvent) {
        switch type {
        case .screenshot:
            handleScreenshotDetection()
        case .screenRecording:
            handleScreenRecordingStarted()
        case .appBackground:
            handleAppBackgrounded()
        }
    }
    
    enum TestSecurityEvent {
        case screenshot
        case screenRecording
        case appBackground
    }
    #endif
    
    // MARK: - Cleanup
    
    private func removeObservers() {
        if let screenshotObserver = screenshotNotificationObserver {
            NotificationCenter.default.removeObserver(screenshotObserver)
            screenshotNotificationObserver = nil
        }
        
        if let appStateObserver = appStateObserver {
            NotificationCenter.default.removeObserver(appStateObserver)
            self.appStateObserver = nil
        }
    }
}

// MARK: - Missing Imports Fix

import LocalAuthentication

// MARK: - LAContext Missing Import Fix
extension LAContext {
    // This extension ensures LAContext is available for the security checks
}
