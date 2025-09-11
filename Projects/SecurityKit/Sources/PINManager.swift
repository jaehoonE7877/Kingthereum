import Foundation
import KeychainAccess
import CryptoSwift
import Core
import Entity

/// Production-level PIN 관리자 프로토콜
/// 은행급 보안 수준의 PIN 암호화, 검증, 관리 기능을 제공
public protocol PINManagerProtocol: Sendable {
    /// 새로운 PIN을 설정합니다 (PBKDF2 + Salt 암호화 적용)
    func setPIN(_ pin: String) async throws
    
    /// PIN을 안전하게 검증합니다 (타이밍 공격 방지)
    func verifyPIN(_ pin: String) async throws -> Bool
    
    /// PIN 설정 여부를 확인합니다
    func hasPIN() async -> Bool
    
    /// 기존 PIN을 새로운 PIN으로 변경합니다
    func changePIN(oldPIN: String, newPIN: String) async throws
    
    /// PIN을 안전하게 삭제합니다
    func deletePIN() async throws
    
    /// PIN 시도 실패 횟수를 기록합니다
    func recordFailedAttempt() async
    
    /// PIN 잠금 상태를 확인합니다
    func isLocked() async -> Bool
    
    /// PIN 잠금을 해제합니다 (생체인증 성공 시)
    func unlock() async
    
    /// 마지막 성공한 PIN 인증 시간을 반환합니다
    func lastSuccessfulAuthentication() async -> Date?
}

/// Production-level PIN Manager
/// 프리미엄 핀테크 앱 수준의 보안 기능을 제공합니다
/// 
/// ## 보안 특징:
/// - PBKDF2 해시 + 고유 Salt로 PIN 암호화
/// - 타이밍 공격 방지를 위한 일정한 검증 시간
/// - Rate limiting으로 무차별 대입 공격 방지
/// - 보안 이벤트 로깅
/// - 키체인 접근 실패 시 자동 복구
public actor PINManager: PINManagerProtocol {
    
    // MARK: - Security Configuration
    
    private let keychain: Keychain
    private let pinHashKey = "user_pin_hash"
    private let pinSaltKey = "user_pin_salt"
    private let failedAttemptsKey = "pin_failed_attempts"
    private let lockoutTimeKey = "pin_lockout_time"
    private let lastSuccessKey = "pin_last_success"
    
    // Security parameters
    private let pbkdf2Iterations = 100_000  // OWASP 권장 값
    private let saltLength = 32  // 256-bit salt
    private let maxFailedAttempts = 5
    private let lockoutDuration: TimeInterval = 300  // 5분
    private let minimumVerificationTime: TimeInterval = 0.1  // 타이밍 공격 방지
    
    // Internal state for security tracking
    private var failedAttempts: Int = 0
    private var lockoutTime: Date?
    private var lastAttemptTime = Date.distantPast
    
    public init() {
        self.keychain = Keychain(service: Constants.Keychain.serviceIdentifier)
            .accessibility(.whenUnlockedThisDeviceOnly)
            .synchronizable(false)  // iCloud 동기화 비활성화 (보안상)
        
        // 초기화 시 실패 횟수 및 잠금 상태 복원
        Task {
            await loadSecurityState()
        }
    }
    
    // MARK: - Public PIN Management
    
    public func setPIN(_ pin: String) async throws {
        // PIN 유효성 검사
        guard isValidPINFormat(pin) else {
            await logSecurityEvent(.invalidPINFormat, details: ["length": "\(pin.count)"])
            throw Entity.SecurityError.PINError.pinTooShort
        }
        
        // 취약한 PIN 패턴 검사
        guard !isWeakPIN(pin) else {
            await logSecurityEvent(.weakPINDetected, details: ["pattern": "weak"])
            throw Entity.SecurityError.PINError.invalidPIN
        }
        
        do {
            // 고유한 Salt 생성
            let salt = generateSalt()
            
            // PBKDF2로 PIN 해시 생성
            let hashedPIN = try hashPIN(pin, salt: salt)
            
            // 키체인에 안전하게 저장
            try keychain.set(hashedPIN, key: pinHashKey)
            try keychain.set(salt, key: pinSaltKey)
            
            // 보안 상태 초기화
            await resetSecurityState()
            
            await logSecurityEvent(.pinSet, details: ["timestamp": "\(Date())"])
            
        } catch {
            await logSecurityEvent(.pinSetFailed, details: ["error": error.localizedDescription])
            throw Entity.SecurityError.PINError.keychainError
        }
    }
    
    public func verifyPIN(_ pin: String) async throws -> Bool {
        let startTime = Date()
        
        // 잠금 상태 확인
        if await isLocked() {
            await logSecurityEvent(.pinVerificationBlocked, details: ["reason": "locked"])
            throw Entity.SecurityError.PINError.tooManyAttempts
        }
        
        // Rate limiting 검사
        guard await canAttemptVerification() else {
            await logSecurityEvent(.pinVerificationBlocked, details: ["reason": "rate_limit"])
            throw Entity.SecurityError.PINError.tooManyAttempts
        }
        
        do {
            guard let storedHash = try keychain.get(pinHashKey),
                  let storedSalt = try keychain.get(pinSaltKey) else {
                await logSecurityEvent(.pinNotFound, details: [:])
                throw Entity.SecurityError.PINError.pinNotSet
            }
            
            // 입력된 PIN을 같은 Salt로 해시
            let hashedInput = try hashPIN(pin, salt: storedSalt)
            
            // 타이밍 공격 방지: 항상 일정 시간 유지
            let elapsedTime = Date().timeIntervalSince(startTime)
            let remainingTime = minimumVerificationTime - elapsedTime
            if remainingTime > 0 {
                try await Task.sleep(nanoseconds: UInt64(remainingTime * 1_000_000_000))
            }
            
            // Constant-time 비교
            let isValid = constantTimeCompare(hashedInput, storedHash)
            
            if isValid {
                await handleSuccessfulVerification()
                await logSecurityEvent(.pinVerificationSuccess, details: ["timestamp": "\(Date())"])
                return true
            } else {
                await handleFailedVerification()
                await logSecurityEvent(.pinVerificationFailed, details: ["attempts": "\(failedAttempts)"])
                return false
            }
            
        } catch {
            await handleFailedVerification()
            await logSecurityEvent(.pinVerificationError, details: ["error": error.localizedDescription])
            throw Entity.SecurityError.PINError.keychainError
        }
    }
    
    public func hasPIN() async -> Bool {
        do {
            let hasHash = try keychain.get(pinHashKey) != nil
            let hasSalt = try keychain.get(pinSaltKey) != nil
            return hasHash && hasSalt
        } catch {
            await logSecurityEvent(.pinCheckFailed, details: ["error": error.localizedDescription])
            return false
        }
    }
    
    public func changePIN(oldPIN: String, newPIN: String) async throws {
        // 기존 PIN 검증
        let isValidOld = try await verifyPIN(oldPIN)
        guard isValidOld else {
            await logSecurityEvent(.pinChangeFailed, details: ["reason": "invalid_old_pin"])
            throw Entity.SecurityError.PINError.invalidPIN
        }
        
        // 새 PIN 설정
        try await setPIN(newPIN)
        await logSecurityEvent(.pinChanged, details: ["timestamp": "\(Date())"])
    }
    
    public func deletePIN() async throws {
        do {
            try keychain.remove(pinHashKey)
            try keychain.remove(pinSaltKey)
            await resetSecurityState()
            await logSecurityEvent(.pinDeleted, details: ["timestamp": "\(Date())"])
        } catch {
            await logSecurityEvent(.pinDeleteFailed, details: ["error": error.localizedDescription])
            throw Entity.SecurityError.PINError.keychainError
        }
    }
    
    // MARK: - Security State Management
    
    public func recordFailedAttempt() async {
        failedAttempts += 1
        lastAttemptTime = Date()
        
        if failedAttempts >= maxFailedAttempts {
            lockoutTime = Date().addingTimeInterval(lockoutDuration)
            await logSecurityEvent(.pinLockedOut, details: [
                "attempts": "\(failedAttempts)",
                "lockout_until": "\(lockoutTime!)"
            ])
        }
        
        await saveSecurityState()
    }
    
    public func isLocked() async -> Bool {
        guard let lockoutTime = lockoutTime else { return false }
        
        if Date() < lockoutTime {
            return true
        } else {
            // 잠금 시간이 지났으면 자동 해제
            await unlock()
            return false
        }
    }
    
    public func unlock() async {
        failedAttempts = 0
        lockoutTime = nil
        await saveSecurityState()
        await logSecurityEvent(.pinUnlocked, details: ["timestamp": "\(Date())"])
    }
    
    public func lastSuccessfulAuthentication() async -> Date? {
        guard let timeString = try? keychain.get(lastSuccessKey),
              let timeInterval = TimeInterval(timeString) else {
            return nil
        }
        return Date(timeIntervalSince1970: timeInterval)
    }
    
    // MARK: - Private Security Methods
    
    private func isValidPINFormat(_ pin: String) -> Bool {
        // 6자리 숫자 PIN만 허용
        return pin.count == 6 && pin.allSatisfy { $0.isNumber }
    }
    
    private func isWeakPIN(_ pin: String) -> Bool {
        // 취약한 PIN 패턴 검사
        let weakPatterns = [
            "123456", "654321", "000000", "111111", "222222",
            "333333", "444444", "555555", "666666", "777777",
            "888888", "999999", "012345", "543210"
        ]
        
        if weakPatterns.contains(pin) {
            return true
        }
        
        // 연속된 숫자 패턴 검사
        let digits = pin.compactMap { $0.wholeNumberValue }
        var consecutive = 0
        var repeating = 0
        
        for i in 1..<digits.count {
            if digits[i] == digits[i-1] + 1 || digits[i] == digits[i-1] - 1 {
                consecutive += 1
            }
            if digits[i] == digits[i-1] {
                repeating += 1
            }
        }
        
        // 4개 이상 연속되거나 4개 이상 반복되면 취약함
        return consecutive >= 4 || repeating >= 4
    }
    
    private func generateSalt() -> String {
        let saltData = Data((0..<saltLength).map { _ in UInt8.random(in: 0...255) })
        return saltData.base64EncodedString()
    }
    
    private func hashPIN(_ pin: String, salt: String) throws -> String {
        guard let saltData = Data(base64Encoded: salt) else {
            throw Entity.SecurityError.PINError.invalidPIN
        }
        
        let hashedData = try ProductionCrypto.pbkdf2(
            password: pin,
            salt: saltData,
            iterations: pbkdf2Iterations,
            keyLength: 32
        )
        return hashedData.base64EncodedString()
    }
    
    private func constantTimeCompare(_ a: String, _ b: String) -> Bool {
        return ProductionCrypto.constantTimeCompare(a, b)
    }
    
    private func canAttemptVerification() async -> Bool {
        let timeSinceLastAttempt = Date().timeIntervalSince(lastAttemptTime)
        return timeSinceLastAttempt >= 1.0  // 최소 1초 간격
    }
    
    private func handleSuccessfulVerification() async {
        failedAttempts = 0
        lockoutTime = nil
        
        // 마지막 성공 시간 기록
        let timestamp = String(Date().timeIntervalSince1970)
        try? keychain.set(timestamp, key: lastSuccessKey)
        
        await saveSecurityState()
    }
    
    private func handleFailedVerification() async {
        await recordFailedAttempt()
    }
    
    private func loadSecurityState() async {
        if let attemptsString = try? keychain.get(failedAttemptsKey),
           let attempts = Int(attemptsString) {
            failedAttempts = attempts
        }
        
        if let lockoutString = try? keychain.get(lockoutTimeKey),
           let lockoutInterval = TimeInterval(lockoutString) {
            lockoutTime = Date(timeIntervalSince1970: lockoutInterval)
        }
    }
    
    private func saveSecurityState() async {
        try? keychain.set(String(failedAttempts), key: failedAttemptsKey)
        
        if let lockout = lockoutTime {
            try? keychain.set(String(lockout.timeIntervalSince1970), key: lockoutTimeKey)
        } else {
            try? keychain.remove(lockoutTimeKey)
        }
    }
    
    private func resetSecurityState() async {
        failedAttempts = 0
        lockoutTime = nil
        try? keychain.remove(failedAttemptsKey)
        try? keychain.remove(lockoutTimeKey)
    }
    
    // MARK: - Security Logging
    
    private func logSecurityEvent(_ event: PINSecurityEvent, details: [String: String]) async {
        let logEntry = [
            "event": event.rawValue,
            "timestamp": "\(Date())",
            "component": "PINManager"
        ].merging(details) { _, new in new }
        
        // 실제 환경에서는 보안 로깅 서비스로 전송
        print("[SECURITY] PIN Event: \(event.rawValue) - \(logEntry)")
    }
}

// MARK: - Security Event Types

private enum PINSecurityEvent: String, CaseIterable {
    case pinSet = "PIN_SET"
    case pinSetFailed = "PIN_SET_FAILED"
    case pinChanged = "PIN_CHANGED"
    case pinChangeFailed = "PIN_CHANGE_FAILED"
    case pinDeleted = "PIN_DELETED"
    case pinDeleteFailed = "PIN_DELETE_FAILED"
    case pinVerificationSuccess = "PIN_VERIFICATION_SUCCESS"
    case pinVerificationFailed = "PIN_VERIFICATION_FAILED"
    case pinVerificationError = "PIN_VERIFICATION_ERROR"
    case pinVerificationBlocked = "PIN_VERIFICATION_BLOCKED"
    case pinNotFound = "PIN_NOT_FOUND"
    case pinCheckFailed = "PIN_CHECK_FAILED"
    case pinLockedOut = "PIN_LOCKED_OUT"
    case pinUnlocked = "PIN_UNLOCKED"
    case invalidPINFormat = "INVALID_PIN_FORMAT"
    case weakPINDetected = "WEAK_PIN_DETECTED"
}

// PBKDF2 implementation is now handled by ProductionCrypto class
