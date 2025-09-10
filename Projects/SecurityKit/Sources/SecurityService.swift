import UIKit
import Darwin.sys.sysctl
import Core
import Entity

public protocol SecurityServiceProtocol: Sendable {
    func authenticateWithBiometrics(reason: String) async throws -> Bool
    func authenticateWithPIN(_ pin: String) async throws -> Bool
    func setupPIN(_ pin: String) async throws
    func changePIN(oldPIN: String, newPIN: String) async throws
    func isSecuritySetup() async -> Bool
    func getBiometricType() -> BiometricType
    func isBiometricAvailable() -> Bool
    func deleteWalletData() async throws
    func storeWalletAddress(_ address: String) async throws
    func storeWalletData(privateKey: String) async throws
    func retrievePrivateKey() async throws -> String?
}

public actor SecurityService: SecurityServiceProtocol {
    
    private let biometricManager: BiometricAuthManagerProtocol
    private let pinManager: PINManagerProtocol
    private let keychainManager: KeychainManagerProtocol
    
    // Rate limiting properties
    private var failedAttempts: Int = 0
    private var lastFailedAttemptTime: Date = Date.distantPast
    private let maxAttempts: Int = 5
    private let lockoutDuration: TimeInterval = 300 // 5분
    
    public init(
        biometricManager: BiometricAuthManagerProtocol = BiometricAuthManager(),
        pinManager: PINManagerProtocol = PINManager(),
        keychainManager: KeychainManagerProtocol = KeychainManager()
    ) {
        self.biometricManager = biometricManager
        self.pinManager = pinManager
        self.keychainManager = keychainManager
    }
    
    // MARK: - Authentication Methods
    
    public func authenticateWithBiometrics(reason: String) async throws -> Bool {
        // Rate limiting check
        guard await checkRateLimit() else {
            await logSecurityEvent(.authenticationAttemptBlocked, reason: "Rate limit exceeded")
            throw SecurityError.rateLimitExceeded
        }
        
        guard biometricManager.isAvailable else {
            await logSecurityEvent(.biometricUnavailable, reason: reason)
            throw SecurityError.biometricNotAvailable
        }
        
        await logSecurityEvent(.biometricAuthenticationAttempt, reason: reason)
        
        do {
            let success = try await biometricManager.authenticate(reason: reason)
            if success {
                await logSecurityEvent(.biometricAuthenticationSuccess, reason: reason)
                await resetRateLimit()
            } else {
                await logSecurityEvent(.biometricAuthenticationFailure, reason: reason)
                await incrementFailedAttempts()
            }
            return success
        } catch {
            await logSecurityEvent(.biometricAuthenticationError, reason: "\(reason): \(error.localizedDescription)")
            await incrementFailedAttempts()
            throw error
        }
    }
    
    public func authenticateWithPIN(_ pin: String) async throws -> Bool {
        return try await pinManager.verifyPIN(pin)
    }
    
    public func setupPIN(_ pin: String) async throws {
        try await pinManager.setPIN(pin)
    }
    
    public func changePIN(oldPIN: String, newPIN: String) async throws {
        try await pinManager.changePIN(oldPIN: oldPIN, newPIN: newPIN)
    }
    
    public func isSecuritySetup() async -> Bool {
        return await pinManager.hasPIN()
    }
    
    nonisolated public func getBiometricType() -> BiometricType {
        return biometricManager.biometricType
    }
    
    nonisolated public func isBiometricAvailable() -> Bool {
        return biometricManager.isAvailable
    }
    
    // MARK: - Wallet Security Methods
    
    public func storeWalletData(privateKey: String) async throws {
        try await keychainManager.storePrivateKey(privateKey)
    }
    
    public func retrievePrivateKey() async throws -> String? {
        return try await keychainManager.retrievePrivateKey()
    }
    
    public func storeWalletAddress(_ address: String) async throws {
        try await keychainManager.storeWalletAddress(address)
    }
    
    public func deleteWalletData() async throws {
        try await keychainManager.deleteAll()
    }
    
    // MARK: - Security Enhancement Features
    
    public func authenticateWithSecurityValidation(reason: String) async throws -> Bool {
        // Validate device security first
        try await validateDeviceSecurity()
        
        // Perform authentication with enhanced security
        return try await authenticateWithBiometrics(reason: reason)
    }
    
    // MARK: - Rate Limiting
    
    private func checkRateLimit() async -> Bool {
        if failedAttempts >= maxAttempts {
            if Date().timeIntervalSince(lastFailedAttemptTime) < lockoutDuration {
                return false
            } else {
                await resetRateLimit()
            }
        }
        return true
    }
    
    private func incrementFailedAttempts() async {
        failedAttempts += 1
        lastFailedAttemptTime = Date()
    }
    
    private func resetRateLimit() async {
        failedAttempts = 0
        lastFailedAttemptTime = Date.distantPast
    }
    
    // MARK: - Device Security Validation
    
    private func validateDeviceSecurity() async throws {
        if await isJailbroken() {
            await logSecurityEvent(.jailbreakDetected, reason: "Jailbreak detected")
            throw SecurityError.jailbreakDetected
        }
        
        if await isDebuggerAttached() {
            await logSecurityEvent(.debuggerDetected, reason: "Debugger attached")
            throw SecurityError.suspiciousActivity
        }
    }
    
    private func isJailbroken() async -> Bool {
        // Check for common jailbreak indicators
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/var/lib/apt/"
        ]
        
        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        
        // Check if app can write to protected directories
        let testPath = "/private/test_jailbreak.txt"
        if FileManager.default.createFile(atPath: testPath, contents: nil, attributes: nil) {
            try? FileManager.default.removeItem(atPath: testPath)
            return true
        }
        
        return false
    }
    
    private func isDebuggerAttached() async -> Bool {
        var info = kinfo_proc()
        var mib = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout<kinfo_proc>.stride
        let result = sysctl(&mib, u_int(mib.count), &info, &size, nil, 0)
        
        return result == 0 && (info.kp_proc.p_flag & P_TRACED) != 0
    }
    
    // MARK: - Security Logging
    
    private func logSecurityEvent(_ event: SecurityEvent, reason: String = "", additionalInfo: [String: Any] = [:]) async {
        let entry = SecurityLogEntry(
            event: event,
            timestamp: Date(),
            reason: reason,
            additionalInfo: additionalInfo.mapValues { String(describing: $0) },
            deviceInfo: await getDeviceSecurityInfo()
        )
        
        await storeSecurityLog(entry)
        
        // Handle critical events
        if event.severity == .critical {
            await handleCriticalSecurityEvent(entry)
        }
    }
    
    private func storeSecurityLog(_ entry: SecurityLogEntry) async {
        // Store in UserDefaults or send to analytics service
        // Implementation depends on requirements
        print("Security Event: \(entry.event.rawValue) - \(entry.reason)")
    }
    
    private func handleCriticalSecurityEvent(_ entry: SecurityLogEntry) async {
        // Implement critical event handling
        // Could include: immediate app lock, data wipe, server notification
        print("CRITICAL Security Event: \(entry.event.rawValue)")
    }
    
    private func getDeviceSecurityInfo() async -> DeviceSecurityInfo {
        let deviceInfo = await MainActor.run {
            return (UIDevice.current.model, UIDevice.current.systemVersion)
        }
        
        return DeviceSecurityInfo(
            deviceModel: deviceInfo.0,
            systemVersion: deviceInfo.1,
            isJailbroken: await isJailbroken(),
            hasDebugger: await isDebuggerAttached(),
            biometricType: getBiometricType().description,
            timestamp: Date()
        )
    }
}

// MARK: - Security Error Types

public enum SecurityError: LocalizedError, Equatable {
    case biometricNotAvailable
    case biometricNotEnrolled
    case biometricAuthenticationFailed
    case biometricLockout
    case biometricFailedPINRequired
    case pinRequired
    case noSecuritySetup
    case authenticationRequired
    case rateLimitExceeded
    case jailbreakDetected
    case suspiciousActivity
    
    public var errorDescription: String? {
        switch self {
        case .biometricNotAvailable:
            return "생체 인증을 사용할 수 없습니다"
        case .biometricNotEnrolled:
            return "생체 인증이 설정되지 않았습니다"
        case .biometricAuthenticationFailed:
            return "생체 인증에 실패했습니다"
        case .biometricLockout:
            return "생체 인증이 일시적으로 잠겼습니다"
        case .biometricFailedPINRequired:
            return "생체 인증 실패로 PIN이 필요합니다"
        case .pinRequired:
            return "PIN 입력이 필요합니다"
        case .noSecuritySetup:
            return "보안 설정이 필요합니다"
        case .authenticationRequired:
            return "인증이 필요합니다"
        case .rateLimitExceeded:
            return "너무 많은 시도로 인해 일시적으로 차단되었습니다"
        case .jailbreakDetected:
            return "보안상의 이유로 앱을 사용할 수 없습니다"
        case .suspiciousActivity:
            return "의심스러운 활동이 감지되었습니다"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .biometricNotAvailable:
            return "설정에서 생체 인증을 활성화해주세요"
        case .biometricNotEnrolled:
            return "설정에서 Face ID 또는 Touch ID를 설정해주세요"
        case .biometricAuthenticationFailed:
            return "다시 시도하거나 PIN을 입력해주세요"
        case .biometricLockout:
            return "잠시 후 다시 시도하거나 PIN을 입력해주세요"
        case .rateLimitExceeded:
            return "잠시 후 다시 시도해주세요"
        default:
            return "고객 서비스에 문의해주세요"
        }
    }
    
    /// 보안 등급 (낮음/중간/높음/심각)
    public var securityLevel: SecurityLevel {
        switch self {
        case .biometricFailedPINRequired, .pinRequired, .authenticationRequired:
            return .low
        case .biometricNotAvailable, .biometricNotEnrolled, .biometricAuthenticationFailed:
            return .medium
        case .noSecuritySetup, .biometricLockout, .rateLimitExceeded:
            return .high
        case .suspiciousActivity, .jailbreakDetected:
            return .critical
        }
    }
}

public enum SecurityLevel: Int, Comparable {
    case low = 1
    case medium = 2
    case high = 3
    case critical = 4
    
    public static func < (lhs: SecurityLevel, rhs: SecurityLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Supporting Types

private struct SecurityLogEntry: Codable {
    let event: SecurityEvent
    let timestamp: Date
    let reason: String
    let additionalInfo: [String: String]
    let deviceInfo: DeviceSecurityInfo
}

private enum SecurityEvent: String, Codable {
    case biometricAuthenticationAttempt
    case biometricAuthenticationSuccess
    case biometricAuthenticationFailure
    case biometricAuthenticationError
    case biometricUnavailable
    case authenticationAttemptBlocked
    case jailbreakDetected
    case debuggerDetected
    case appTamperingDetected
    case suspiciousActivityDetected
    
    var severity: SecurityLevel {
        switch self {
        case .biometricAuthenticationAttempt, .biometricAuthenticationSuccess:
            return .low
        case .biometricAuthenticationFailure, .biometricAuthenticationError, .biometricUnavailable:
            return .medium
        case .authenticationAttemptBlocked:
            return .high
        case .jailbreakDetected, .debuggerDetected, .appTamperingDetected, .suspiciousActivityDetected:
            return .critical
        }
    }
}

private struct DeviceSecurityInfo: Codable {
    let deviceModel: String
    let systemVersion: String
    let isJailbroken: Bool
    let hasDebugger: Bool
    let biometricType: String
    let timestamp: Date
}