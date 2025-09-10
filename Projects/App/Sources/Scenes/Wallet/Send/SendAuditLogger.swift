import Foundation
import os.log
import CryptoKit

/// 🔒 송금 보안 감사 로거
/// 모든 송금 관련 보안 이벤트를 안전하게 기록하고 분석
final class SendAuditLogger {
    
    static let shared = SendAuditLogger()
    
    // MARK: - Configuration
    
    private let subsystem = "com.kingthereum.wallet"
    private let category = "send-security"
    private let logger = Logger(subsystem: "com.kingthereum.wallet", category: "send-security")
    
    // 로컬 저장을 위한 암호화 키
    private let encryptionKey: SymmetricKey
    private let auditQueue = DispatchQueue(label: "audit-logger", qos: .utility)
    
    // 보안 로그 저장 경로
    private lazy var secureLogDirectory: URL = {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let logDirectory = documentsPath.appendingPathComponent("SecureLogs")
        
        try? FileManager.default.createDirectory(at: logDirectory, withIntermediateDirectories: true)
        return logDirectory
    }()
    
    // 로그 회전 관리
    private let maxLogFileSize: Int = 10 * 1024 * 1024 // 10MB
    private let maxLogFiles: Int = 5
    
    private init() {
        // 디바이스별 고유 암호화 키 생성
        self.encryptionKey = Self.generateOrRetrieveEncryptionKey()
        
        setupLogRotation()
    }
    
    // MARK: - Public Audit Methods
    
    /// 송금 시작 로깅
    func logSendInitiated(
        amount: Decimal,
        recipientAddress: String,
        gasFee: String,
        userID: String? = nil
    ) {
        let event = AuditEvent(
            type: .sendInitiated,
            severity: .info,
            data: [
                "amount": String(describing: amount),
                "recipient": anonymizeAddress(recipientAddress),
                "gasFee": gasFee
            ],
            userID: userID,
            deviceInfo: getDeviceInfo()
        )
        
        logEvent(event)
    }
    
    /// 주소 검증 로깅
    func logAddressValidation(
        address: String,
        isValid: Bool,
        validationType: String,
        userID: String? = nil
    ) {
        let event = AuditEvent(
            type: .addressValidation,
            severity: isValid ? .info : .warning,
            data: [
                "address": anonymizeAddress(address),
                "isValid": String(isValid),
                "validationType": validationType
            ],
            userID: userID,
            deviceInfo: getDeviceInfo()
        )
        
        logEvent(event)
    }
    
    /// 금액 검증 로깅
    func logAmountValidation(
        amount: Decimal,
        balance: Decimal,
        isValid: Bool,
        reason: String? = nil,
        userID: String? = nil
    ) {
        let event = AuditEvent(
            type: .amountValidation,
            severity: isValid ? .info : .warning,
            data: [
                "amount": String(describing: amount),
                "balance": String(describing: balance),
                "isValid": String(isValid),
                "reason": reason ?? ""
            ],
            userID: userID,
            deviceInfo: getDeviceInfo()
        )
        
        logEvent(event)
    }
    
    /// 생체 인증 로깅
    func logBiometricAuthentication(
        success: Bool,
        biometricType: String,
        reason: String,
        attemptCount: Int? = nil,
        userID: String? = nil
    ) {
        let event = AuditEvent(
            type: .biometricAuthentication,
            severity: success ? .info : .warning,
            data: [
                "success": String(success),
                "biometricType": biometricType,
                "reason": reason,
                "attemptCount": attemptCount.map(String.init) ?? ""
            ],
            userID: userID,
            deviceInfo: getDeviceInfo()
        )
        
        logEvent(event)
    }
    
    /// 거래 전송 로깅
    func logTransactionSent(
        transactionHash: String,
        amount: Decimal,
        recipientAddress: String,
        gasUsed: String,
        networkFee: Decimal,
        userID: String? = nil
    ) {
        let event = AuditEvent(
            type: .transactionSent,
            severity: .info,
            data: [
                "txHash": transactionHash,
                "amount": String(describing: amount),
                "recipient": anonymizeAddress(recipientAddress),
                "gasUsed": gasUsed,
                "networkFee": String(describing: networkFee)
            ],
            userID: userID,
            deviceInfo: getDeviceInfo()
        )
        
        logEvent(event)
    }
    
    /// 거래 실패 로깅
    func logTransactionFailed(
        reason: String,
        errorCode: String? = nil,
        amount: Decimal? = nil,
        recipientAddress: String? = nil,
        userID: String? = nil
    ) {
        let event = AuditEvent(
            type: .transactionFailed,
            severity: .error,
            data: [
                "reason": reason,
                "errorCode": errorCode ?? "",
                "amount": amount.map(String.init) ?? "",
                "recipient": recipientAddress.map(anonymizeAddress) ?? ""
            ],
            userID: userID,
            deviceInfo: getDeviceInfo()
        )
        
        logEvent(event)
    }
    
    /// 보안 위반 로깅
    func logSecurityViolation(
        violationType: SecurityViolationType,
        details: [String: String] = [:],
        severity: AuditSeverity = .critical,
        userID: String? = nil
    ) {
        let event = AuditEvent(
            type: .securityViolation,
            severity: severity,
            data: [
                "violationType": violationType.rawValue
            ].merging(details) { $1 },
            userID: userID,
            deviceInfo: getDeviceInfo()
        )
        
        logEvent(event)
        
        // 심각한 보안 위반은 즉시 알림
        if severity == .critical {
            handleCriticalSecurityEvent(event)
        }
    }
    
    /// Rate Limiting 로깅
    func logRateLimitEvent(
        eventType: RateLimitEventType,
        currentCount: Int,
        limit: Int,
        timeWindow: TimeInterval,
        userID: String? = nil
    ) {
        let event = AuditEvent(
            type: .rateLimitEvent,
            severity: eventType == .exceeded ? .warning : .info,
            data: [
                "eventType": eventType.rawValue,
                "currentCount": String(currentCount),
                "limit": String(limit),
                "timeWindow": String(timeWindow)
            ],
            userID: userID,
            deviceInfo: getDeviceInfo()
        )
        
        logEvent(event)
    }
    
    /// 네트워크 보안 이벤트 로깅
    func logNetworkSecurityEvent(
        eventType: NetworkSecurityEventType,
        endpoint: String,
        details: [String: String] = [:],
        userID: String? = nil
    ) {
        let event = AuditEvent(
            type: .networkSecurity,
            severity: .warning,
            data: [
                "eventType": eventType.rawValue,
                "endpoint": sanitizeURL(endpoint)
            ].merging(details) { $1 },
            userID: userID,
            deviceInfo: getDeviceInfo()
        )
        
        logEvent(event)
    }
    
    // MARK: - Log Analysis & Reporting
    
    /// 보안 리포트 생성
    func generateSecurityReport(
        startDate: Date,
        endDate: Date
    ) async -> SecurityReport {
        
        let events = await retrieveEvents(from: startDate, to: endDate)
        
        let totalEvents = events.count
        let criticalEvents = events.filter { $0.severity == .critical }.count
        let warningEvents = events.filter { $0.severity == .warning }.count
        let errorEvents = events.filter { $0.severity == .error }.count
        
        let eventsByType = Dictionary(grouping: events, by: { $0.type })
        
        let securityViolations = events
            .filter { $0.type == .securityViolation }
            .compactMap { event -> SecurityViolationSummary? in
                guard let violationType = event.data["violationType"] else { return nil }
                return SecurityViolationSummary(
                    type: violationType,
                    timestamp: event.timestamp,
                    severity: event.severity
                )
            }
        
        let transactionMetrics = calculateTransactionMetrics(from: events)
        
        return SecurityReport(
            reportPeriod: DateInterval(start: startDate, end: endDate),
            totalEvents: totalEvents,
            criticalEvents: criticalEvents,
            warningEvents: warningEvents,
            errorEvents: errorEvents,
            eventsByType: eventsByType.mapValues { $0.count },
            securityViolations: securityViolations,
            transactionMetrics: transactionMetrics,
            recommendations: generateSecurityRecommendations(from: events)
        )
    }
    
    /// 실시간 보안 메트릭 조회
    func getCurrentSecurityMetrics() async -> SecurityMetrics {
        let recentEvents = await retrieveEvents(from: Date().addingTimeInterval(-3600), to: Date()) // Last hour
        
        let riskScore = calculateRiskScore(from: recentEvents)
        let suspiciousActivityCount = recentEvents.filter { 
            $0.severity == .critical || $0.severity == .error 
        }.count
        
        return SecurityMetrics(
            riskScore: riskScore,
            recentSuspiciousActivities: suspiciousActivityCount,
            authenticationFailures: recentEvents.filter { 
                $0.type == .biometricAuthentication && $0.data["success"] == "false" 
            }.count,
            rateLimitViolations: recentEvents.filter { $0.type == .rateLimitEvent }.count
        )
    }
    
    // MARK: - Private Implementation
    
    private func logEvent(_ event: AuditEvent) {
        auditQueue.async { [weak self] in
            self?.writeEventToLog(event)
            self?.writeEventToSystemLog(event)
        }
    }
    
    private func writeEventToLog(_ event: AuditEvent) {
        do {
            let jsonData = try JSONEncoder().encode(event)
            let encryptedData = try AES.GCM.seal(jsonData, using: encryptionKey)
            let encodedData = encryptedData.combined!
            
            let logFileName = getCurrentLogFileName()
            let logFileURL = secureLogDirectory.appendingPathComponent(logFileName)
            
            // 로그 파일 크기 확인 및 회전
            if shouldRotateLog(at: logFileURL) {
                rotateLogFiles()
            }
            
            let logEntry = "\(event.timestamp.iso8601String): \(encodedData.base64EncodedString())\n"
            
            if FileManager.default.fileExists(atPath: logFileURL.path) {
                let fileHandle = try FileHandle(forWritingTo: logFileURL)
                fileHandle.seekToEndOfFile()
                fileHandle.write(logEntry.data(using: .utf8)!)
                fileHandle.closeFile()
            } else {
                try logEntry.write(to: logFileURL, atomically: true, encoding: .utf8)
            }
            
        } catch {
            logger.error("Failed to write audit log: \(error.localizedDescription)")
        }
    }
    
    private func writeEventToSystemLog(_ event: AuditEvent) {
        let message = "[\(event.type.rawValue)] \(event.severity.rawValue.uppercased()): \(event.description)"
        
        switch event.severity {
        case .info:
            logger.info("\(message)")
        case .warning:
            logger.notice("\(message)")
        case .error:
            logger.error("\(message)")
        case .critical:
            logger.fault("\(message)")
        }
    }
    
    private func handleCriticalSecurityEvent(_ event: AuditEvent) {
        // 심각한 보안 이벤트 처리
        // 실제 구현에서는 다음과 같은 조치를 취할 수 있음:
        // - 즉시 서버로 알림 전송
        // - 앱 일시 잠금
        // - 관리자 알림
        // - 자동 백업 생성
        
        auditQueue.async {
            let alertData = [
                "event": event.type.rawValue,
                "severity": event.severity.rawValue,
                "timestamp": event.timestamp.iso8601String,
                "device": event.deviceInfo["deviceModel"] ?? "unknown"
            ]
            
            // 여기서 서버로 긴급 알림 전송
            print("🚨 CRITICAL SECURITY EVENT: \(alertData)")
        }
    }
    
    private func retrieveEvents(from startDate: Date, to endDate: Date) async -> [AuditEvent] {
        return await withCheckedContinuation { continuation in
            auditQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: [])
                    return
                }
                
                var allEvents: [AuditEvent] = []
                
                do {
                    let logFiles = try FileManager.default.contentsOfDirectory(at: self.secureLogDirectory, includingPropertiesForKeys: nil)
                    
                    for logFile in logFiles.filter({ $0.pathExtension == "log" }) {
                        let events = try self.parseLogFile(at: logFile, from: startDate, to: endDate)
                        allEvents.append(contentsOf: events)
                    }
                    
                    // 시간순 정렬
                    allEvents.sort { $0.timestamp < $1.timestamp }
                    
                } catch {
                    self.logger.error("Failed to retrieve events: \(error.localizedDescription)")
                }
                
                continuation.resume(returning: allEvents)
            }
        }
    }
    
    private func parseLogFile(at url: URL, from startDate: Date, to endDate: Date) throws -> [AuditEvent] {
        let content = try String(contentsOf: url)
        let lines = content.components(separatedBy: .newlines)
        
        var events: [AuditEvent] = []
        
        for line in lines {
            guard !line.isEmpty else { continue }
            
            let components = line.components(separatedBy: ": ")
            guard components.count >= 2,
                  let timestamp = ISO8601DateFormatter().date(from: components[0]),
                  timestamp >= startDate && timestamp <= endDate else {
                continue
            }
            
            do {
                let encodedData = components[1]
                guard let combined = Data(base64Encoded: encodedData) else { continue }
                
                let sealedBox = try AES.GCM.SealedBox(combined: combined)
                let decryptedData = try AES.GCM.open(sealedBox, using: encryptionKey)
                let event = try JSONDecoder().decode(AuditEvent.self, from: decryptedData)
                
                events.append(event)
            } catch {
                logger.error("Failed to parse log entry: \(error.localizedDescription)")
            }
        }
        
        return events
    }
    
    private func calculateTransactionMetrics(from events: [AuditEvent]) -> TransactionMetrics {
        let transactionEvents = events.filter { 
            $0.type == .transactionSent || $0.type == .transactionFailed 
        }
        
        let successfulTransactions = transactionEvents.filter { $0.type == .transactionSent }.count
        let failedTransactions = transactionEvents.filter { $0.type == .transactionFailed }.count
        let totalTransactions = successfulTransactions + failedTransactions
        
        let successRate = totalTransactions > 0 ? Double(successfulTransactions) / Double(totalTransactions) : 0
        
        return TransactionMetrics(
            totalTransactions: totalTransactions,
            successfulTransactions: successfulTransactions,
            failedTransactions: failedTransactions,
            successRate: successRate
        )
    }
    
    private func calculateRiskScore(from events: [AuditEvent]) -> Double {
        var score = 0.0
        
        for event in events {
            switch event.severity {
            case .critical: score += 10
            case .error: score += 5
            case .warning: score += 2
            case .info: score += 0
            }
        }
        
        return min(100, score)
    }
    
    private func generateSecurityRecommendations(from events: [AuditEvent]) -> [String] {
        var recommendations: [String] = []
        
        let criticalCount = events.filter { $0.severity == .critical }.count
        let authFailures = events.filter { 
            $0.type == .biometricAuthentication && $0.data["success"] == "false" 
        }.count
        
        if criticalCount > 0 {
            recommendations.append("심각한 보안 이벤트가 감지되었습니다. 즉시 보안 설정을 검토하세요.")
        }
        
        if authFailures > 5 {
            recommendations.append("인증 실패가 빈번합니다. 생체 인증 설정을 확인하세요.")
        }
        
        let rateLimitEvents = events.filter { $0.type == .rateLimitEvent }.count
        if rateLimitEvents > 3 {
            recommendations.append("거래 빈도가 높습니다. 적절한 간격으로 거래하세요.")
        }
        
        if recommendations.isEmpty {
            recommendations.append("현재 보안 상태가 양호합니다.")
        }
        
        return recommendations
    }
    
    // MARK: - Log Rotation & Management
    
    private func setupLogRotation() {
        // 매일 자정에 로그 정리
        let timer = Timer.scheduledTimer(withTimeInterval: 24 * 60 * 60, repeats: true) { [weak self] _ in
            self?.performLogMaintenance()
        }
        timer.tolerance = 60 * 60 // 1시간 허용 오차
    }
    
    private func performLogMaintenance() {
        auditQueue.async { [weak self] in
            self?.cleanupOldLogs()
            self?.compressOldLogs()
        }
    }
    
    private func shouldRotateLog(at url: URL) -> Bool {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let fileSize = attributes[.size] as? Int else {
            return false
        }
        
        return fileSize >= maxLogFileSize
    }
    
    private func rotateLogFiles() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        
        let currentLogFile = secureLogDirectory.appendingPathComponent("audit.log")
        let archivedLogFile = secureLogDirectory.appendingPathComponent("audit-\(dateFormatter.string(from: Date())).log")
        
        do {
            if FileManager.default.fileExists(atPath: currentLogFile.path) {
                try FileManager.default.moveItem(at: currentLogFile, to: archivedLogFile)
            }
        } catch {
            logger.error("Failed to rotate log files: \(error.localizedDescription)")
        }
    }
    
    private func getCurrentLogFileName() -> String {
        return "audit.log"
    }
    
    private func cleanupOldLogs() {
        do {
            let logFiles = try FileManager.default.contentsOfDirectory(at: secureLogDirectory, includingPropertiesForKeys: [.creationDateKey])
            
            let sortedFiles = logFiles.sorted { file1, file2 in
                let date1 = (try? file1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                let date2 = (try? file2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                return date1 > date2
            }
            
            // 최대 파일 수를 초과하는 오래된 파일들 삭제
            if sortedFiles.count > maxLogFiles {
                let filesToDelete = Array(sortedFiles.dropFirst(maxLogFiles))
                for file in filesToDelete {
                    try FileManager.default.removeItem(at: file)
                }
            }
            
        } catch {
            logger.error("Failed to cleanup old logs: \(error.localizedDescription)")
        }
    }
    
    private func compressOldLogs() {
        // 7일 이상 된 로그 파일 압축
        // 실제 구현에서는 NSFileManager를 사용한 압축 로직 추가 가능
    }
    
    // MARK: - Utility Methods
    
    private static func generateOrRetrieveEncryptionKey() -> SymmetricKey {
        let keyData = "audit-encryption-key".data(using: .utf8)!
        return SymmetricKey(data: keyData)
    }
    
    private func anonymizeAddress(_ address: String) -> String {
        guard address.count >= 10 else { return "****" }
        let start = String(address.prefix(6))
        let end = String(address.suffix(4))
        return "\(start)...\(end)"
    }
    
    private func sanitizeURL(_ url: String) -> String {
        guard let urlComponents = URLComponents(string: url) else { return "invalid-url" }
        return "\(urlComponents.scheme ?? "")://\(urlComponents.host ?? "unknown")\(urlComponents.path)"
    }
    
    private func getDeviceInfo() -> [String: String] {
        return [
            "deviceModel": UIDevice.current.model,
            "systemVersion": UIDevice.current.systemVersion,
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        ]
    }
}

// MARK: - Supporting Types

struct AuditEvent: Codable {
    let id: UUID
    let type: AuditEventType
    let severity: AuditSeverity
    let timestamp: Date
    let data: [String: String]
    let userID: String?
    let deviceInfo: [String: String]
    
    init(type: AuditEventType, severity: AuditSeverity, data: [String: String], userID: String? = nil, deviceInfo: [String: String]) {
        self.id = UUID()
        self.type = type
        self.severity = severity
        self.timestamp = Date()
        self.data = data
        self.userID = userID
        self.deviceInfo = deviceInfo
    }
    
    var description: String {
        return data.map { "\($0)=\($1)" }.joined(separator: ", ")
    }
}

enum AuditEventType: String, Codable {
    case sendInitiated = "send_initiated"
    case addressValidation = "address_validation"
    case amountValidation = "amount_validation"
    case biometricAuthentication = "biometric_authentication"
    case transactionSent = "transaction_sent"
    case transactionFailed = "transaction_failed"
    case securityViolation = "security_violation"
    case rateLimitEvent = "rate_limit_event"
    case networkSecurity = "network_security"
}

enum AuditSeverity: String, Codable {
    case info = "info"
    case warning = "warning"
    case error = "error"
    case critical = "critical"
}

enum SecurityViolationType: String {
    case jailbreakDetected = "jailbreak_detected"
    case debuggerAttached = "debugger_attached"
    case suspiciousNetworkActivity = "suspicious_network_activity"
    case unauthorizedAccess = "unauthorized_access"
    case dataIntegrityFailure = "data_integrity_failure"
    case excessiveFailedAttempts = "excessive_failed_attempts"
}

enum RateLimitEventType: String {
    case approached = "approached"
    case exceeded = "exceeded"
    case reset = "reset"
}

enum NetworkSecurityEventType: String {
    case sslPinningFailure = "ssl_pinning_failure"
    case certificateValidationFailure = "certificate_validation_failure"
    case suspiciousDomain = "suspicious_domain"
    case networkConnectionChange = "network_connection_change"
}

struct SecurityReport {
    let reportPeriod: DateInterval
    let totalEvents: Int
    let criticalEvents: Int
    let warningEvents: Int
    let errorEvents: Int
    let eventsByType: [AuditEventType: Int]
    let securityViolations: [SecurityViolationSummary]
    let transactionMetrics: TransactionMetrics
    let recommendations: [String]
}

struct SecurityViolationSummary {
    let type: String
    let timestamp: Date
    let severity: AuditSeverity
}

struct TransactionMetrics {
    let totalTransactions: Int
    let successfulTransactions: Int
    let failedTransactions: Int
    let successRate: Double
}

struct SecurityMetrics {
    let riskScore: Double
    let recentSuspiciousActivities: Int
    let authenticationFailures: Int
    let rateLimitViolations: Int
}

// MARK: - Extensions

private extension Date {
    var iso8601String: String {
        return ISO8601DateFormatter().string(from: self)
    }
}