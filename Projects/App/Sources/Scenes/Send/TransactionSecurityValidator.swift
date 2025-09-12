import Foundation
import Combine

import Entity
import Core

/// 🔒 거래 보안 검증기
/// 금액 제한, Rate Limiting, 이상 거래 탐지 등 포괄적 거래 보안 관리
actor TransactionSecurityValidator {
    
    // MARK: - Security Configuration
    
    private struct SecurityLimits {
        static let maxDailyAmount: Decimal = 50.0 // ETH
        static let maxSingleTransaction: Decimal = 10.0 // ETH
        static let minTransactionAmount: Decimal = 0.000001 // ETH
        static let maxTransactionsPerHour: Int = 10
        static let maxTransactionsPerDay: Int = 50
        static let minimumTimeBetweenTransactions: TimeInterval = 30 // seconds
        static let suspiciousTransactionThreshold: Decimal = 5.0 // ETH
    }
    
    // MARK: - State Management
    
    private var dailyTransactionAmount: Decimal = 0
    private var dailyTransactionCount: Int = 0
    private var hourlyTransactionCount: Int = 0
    private var lastTransactionTime: Date = .distantPast
    private var lastDailyReset: Date = Calendar.current.startOfDay(for: Date())
    private var lastHourlyReset: Date = Date().startOfHour
    
    private var recentTransactions: [TransactionRecord] = []
    private var suspiciousActivityLog: [SuspiciousActivity] = []
    
    // Fraud detection patterns
    private var addressFrequency: [String: Int] = [:]
    private var roundNumberTransactions: Int = 0
    private var rapidSuccessionTransactions: [Date] = []
    
    // MARK: - Public Interface
    
    func validateTransaction(
        amount: Decimal,
        recipientAddress: String,
        userBalance: Decimal
    ) async throws -> TransactionValidationResult {
        
        await updateCounters()
        
        // 🔒 1단계: 기본 금액 검증
        try validateBasicAmountLimits(amount)
        
        // 🔒 2단계: 잔액 검증
        try validateSufficientBalance(amount: amount, balance: userBalance)
        
        // 🔒 3단계: Rate Limiting 검증
        try await validateRateLimits()
        
        // 🔒 4단계: 일일/단일 거래 한도 검증
        try await validateTransactionLimits(amount)
        
        // 🔒 5단계: 이상 거래 패턴 탐지
        let riskLevel = await detectSuspiciousPatterns(amount: amount, address: recipientAddress)
        
        // 🔒 6단계: 거래 기록 및 로깅
        await recordTransaction(amount: amount, address: recipientAddress, riskLevel: riskLevel)
        
        return TransactionValidationResult(
            isValid: true,
            riskLevel: riskLevel,
            requiredActions: await getRequiredSecurityActions(for: riskLevel),
            validationDetails: await createValidationDetails(amount: amount, riskLevel: riskLevel)
        )
    }
    
    func checkTransactionEligibility() async -> TransactionEligibility {
        await updateCounters()
        
        let remainingDailyAmount = SecurityLimits.maxDailyAmount - dailyTransactionAmount
        let remainingDailyCount = SecurityLimits.maxTransactionsPerDay - dailyTransactionCount
        let remainingHourlyCount = SecurityLimits.maxTransactionsPerHour - hourlyTransactionCount
        
        let timeSinceLastTransaction = Date().timeIntervalSince(lastTransactionTime)
        let minimumWaitTime = max(0, SecurityLimits.minimumTimeBetweenTransactions - timeSinceLastTransaction)
        
        return TransactionEligibility(
            canTransact: remainingDailyCount > 0 && remainingHourlyCount > 0 && minimumWaitTime <= 0,
            remainingDailyAmount: remainingDailyAmount,
            remainingDailyTransactions: remainingDailyCount,
            remainingHourlyTransactions: remainingHourlyCount,
            minimumWaitTime: minimumWaitTime,
            nextResetTime: getNextResetTime()
        )
    }
    
    func getCurrentSecurityMetrics() async -> TransactionSecurityMetrics {
        await updateCounters()
        
        let recentSuspiciousCount = suspiciousActivityLog.filter { activity in
            Date().timeIntervalSince(activity.timestamp) < 3600 // Last hour
        }.count
        
        let averageTransactionAmount = recentTransactions.isEmpty ? 0 : 
            recentTransactions.reduce(0) { $0 + $1.amount } / Decimal(recentTransactions.count)
        
        return TransactionSecurityMetrics(
            dailyTransactionAmount: dailyTransactionAmount,
            dailyTransactionCount: dailyTransactionCount,
            hourlyTransactionCount: hourlyTransactionCount,
            averageTransactionAmount: averageTransactionAmount,
            recentSuspiciousActivityCount: recentSuspiciousCount,
            riskScore: await calculateRiskScore()
        )
    }
    
    // MARK: - Validation Methods
    
    private func validateBasicAmountLimits(_ amount: Decimal) throws {
        guard amount > 0 else {
            throw TransactionSecurityError.invalidAmount("송금 금액은 0보다 커야 합니다")
        }
        
        guard amount >= SecurityLimits.minTransactionAmount else {
            throw TransactionSecurityError.amountTooSmall("최소 송금 금액은 \(SecurityLimits.minTransactionAmount) ETH입니다")
        }
        
        guard amount <= SecurityLimits.maxSingleTransaction else {
            logSuspiciousActivity(.excessiveAmount, amount: amount)
            throw TransactionSecurityError.amountTooLarge("단일 거래 한도는 \(SecurityLimits.maxSingleTransaction) ETH입니다")
        }
    }
    
    private func validateSufficientBalance(amount: Decimal, balance: Decimal) throws {
        guard amount <= balance else {
            throw TransactionSecurityError.insufficientBalance("잔액이 부족합니다. 현재 잔액: \(balance) ETH")
        }
        
        // 전체 잔액의 90% 이상 송금 시 경고
        if amount >= balance * 0.9 {
            logSuspiciousActivity(.nearFullBalanceTransfer, amount: amount)
        }
    }
    
    private func validateRateLimits() async throws {
        let timeSinceLastTransaction = Date().timeIntervalSince(lastTransactionTime)
        
        guard timeSinceLastTransaction >= SecurityLimits.minimumTimeBetweenTransactions else {
            let remainingTime = SecurityLimits.minimumTimeBetweenTransactions - timeSinceLastTransaction
            throw TransactionSecurityError.rateLimitExceeded("다음 거래까지 \(Int(remainingTime))초 기다려주세요")
        }
        
        guard hourlyTransactionCount < SecurityLimits.maxTransactionsPerHour else {
            throw TransactionSecurityError.hourlyLimitExceeded("시간당 거래 한도를 초과했습니다")
        }
        
        guard dailyTransactionCount < SecurityLimits.maxTransactionsPerDay else {
            throw TransactionSecurityError.dailyLimitExceeded("일일 거래 한도를 초과했습니다")
        }
    }
    
    private func validateTransactionLimits(_ amount: Decimal) async throws {
        let newDailyTotal = dailyTransactionAmount + amount
        
        guard newDailyTotal <= SecurityLimits.maxDailyAmount else {
            let remaining = SecurityLimits.maxDailyAmount - dailyTransactionAmount
            throw TransactionSecurityError.dailyAmountExceeded("일일 송금 한도를 초과합니다. 남은 한도: \(remaining) ETH")
        }
    }
    
    // MARK: - Suspicious Activity Detection
    
    private func detectSuspiciousPatterns(amount: Decimal, address: String) async -> RiskLevel {
        var riskFactors: [RiskFactor] = []
        
        // 1. 거래 금액 패턴 분석
        if amount >= SecurityLimits.suspiciousTransactionThreshold {
            riskFactors.append(.largeAmount)
            logSuspiciousActivity(.largeTransaction, amount: amount, address: address)
        }
        
        // 2. 동일 주소 반복 거래 탐지
        addressFrequency[address, default: 0] += 1
        if addressFrequency[address]! > 5 {
            riskFactors.append(.frequentSameAddress)
            logSuspiciousActivity(.repeatedAddressUsage, address: address)
        }
        
        // 3. 정확한 금액 거래 패턴 (예: 1.0, 2.0 ETH)
        if isRoundNumber(amount) {
            roundNumberTransactions += 1
            if roundNumberTransactions > 3 {
                riskFactors.append(.roundNumberPattern)
                logSuspiciousActivity(.roundNumberPattern, amount: amount)
            }
        }
        
        // 4. 연속적인 거래 패턴
        let now = Date()
        rapidSuccessionTransactions.append(now)
        rapidSuccessionTransactions = rapidSuccessionTransactions.filter { 
            now.timeIntervalSince($0) < 300 // 5분 내
        }
        
        if rapidSuccessionTransactions.count > 5 {
            riskFactors.append(.rapidSuccession)
            logSuspiciousActivity(.rapidSuccessiveTransactions)
        }
        
        // 5. 시간 패턴 분석 (심야 거래 등)
        let hour = Calendar.current.component(.hour, from: now)
        if hour >= 23 || hour <= 5 {
            riskFactors.append(.unusualTime)
        }
        
        return calculateRiskLevel(from: riskFactors)
    }
    
    private func calculateRiskLevel(from factors: [RiskFactor]) -> RiskLevel {
        let score = factors.reduce(0) { $0 + $1.weight }
        
        switch score {
        case 0...2: return .low
        case 3...5: return .medium
        case 6...8: return .high
        default: return .critical
        }
    }
    
    private func calculateRiskScore() async -> Double {
        let recentTransactionCount = Double(recentTransactions.count)
        let suspiciousActivityCount = Double(suspiciousActivityLog.count)
        let averageInterval = calculateAverageTransactionInterval()
        
        var score = 0.0
        
        // 거래 빈도 점수 (0-30)
        score += min(30, recentTransactionCount * 2)
        
        // 의심 활동 점수 (0-40)
        score += min(40, suspiciousActivityCount * 5)
        
        // 거래 간격 점수 (0-30)
        if averageInterval < 60 {
            score += 30
        } else if averageInterval < 300 {
            score += 15
        }
        
        return min(100, score)
    }
    
    // MARK: - Helper Methods
    
    private func updateCounters() async {
        let now = Date()
        let calendar = Calendar.current
        
        // 일일 카운터 리셋
        let startOfToday = calendar.startOfDay(for: now)
        if startOfToday > lastDailyReset {
            dailyTransactionAmount = 0
            dailyTransactionCount = 0
            lastDailyReset = startOfToday
        }
        
        // 시간별 카운터 리셋
        let startOfHour = now.startOfHour
        if startOfHour > lastHourlyReset {
            hourlyTransactionCount = 0
            lastHourlyReset = startOfHour
        }
        
        // 오래된 기록 정리
        cleanupOldRecords()
    }
    
    private func recordTransaction(amount: Decimal, address: String, riskLevel: RiskLevel) async {
        let record = TransactionRecord(
            amount: amount,
            recipientAddress: address,
            timestamp: Date(),
            riskLevel: riskLevel
        )
        
        recentTransactions.append(record)
        
        dailyTransactionAmount += amount
        dailyTransactionCount += 1
        hourlyTransactionCount += 1
        lastTransactionTime = Date()
        
        // 보안 로깅
        logSecurityEvent(.transactionValidated, amount: amount, address: address, riskLevel: riskLevel)
    }
    
    private func logSuspiciousActivity(
        _ type: SuspiciousActivityType,
        amount: Decimal? = nil,
        address: String? = nil
    ) {
        let activity = SuspiciousActivity(
            type: type,
            timestamp: Date(),
            amount: amount,
            address: address
        )
        
        suspiciousActivityLog.append(activity)
        logSecurityEvent(.suspiciousActivityDetected, activityType: type)
    }
    
    private func cleanupOldRecords() {
        let cutoffTime = Date().addingTimeInterval(-24 * 60 * 60) // 24시간 전
        
        recentTransactions = recentTransactions.filter { $0.timestamp > cutoffTime }
        suspiciousActivityLog = suspiciousActivityLog.filter { $0.timestamp > cutoffTime }
        
        // 주소 빈도 정리 (주간 리셋)
        if Calendar.current.component(.weekday, from: Date()) == 1 {
            addressFrequency.removeAll()
        }
    }
    
    private func getRequiredSecurityActions(for riskLevel: RiskLevel) async -> [SecurityAction] {
        switch riskLevel {
        case .low:
            return []
        case .medium:
            return [.biometricAuthentication]
        case .high:
            return [.biometricAuthentication, .additionalVerification]
        case .critical:
            return [.biometricAuthentication, .additionalVerification, .manualReview]
        }
    }
    
    private func createValidationDetails(amount: Decimal, riskLevel: RiskLevel) async -> TransactionValidationDetails {
        let eligibility = await checkTransactionEligibility()
        
        return TransactionValidationDetails(
            amount: amount,
            riskLevel: riskLevel,
            remainingDailyAmount: eligibility.remainingDailyAmount,
            remainingDailyTransactions: eligibility.remainingDailyTransactions,
            estimatedProcessingTime: getEstimatedProcessingTime(for: riskLevel),
            securityRecommendations: getSecurityRecommendations(for: riskLevel)
        )
    }
    
    private func getNextResetTime() -> Date {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        return calendar.startOfDay(for: tomorrow)
    }
    
    private func calculateAverageTransactionInterval() -> TimeInterval {
        guard recentTransactions.count > 1 else { return .infinity }
        
        let sortedTransactions = recentTransactions.sorted { $0.timestamp < $1.timestamp }
        var totalInterval: TimeInterval = 0
        
        for i in 1..<sortedTransactions.count {
            totalInterval += sortedTransactions[i].timestamp.timeIntervalSince(sortedTransactions[i-1].timestamp)
        }
        
        return totalInterval / Double(sortedTransactions.count - 1)
    }
    
    private func isRoundNumber(_ amount: Decimal) -> Bool {
        let integerPart = NSDecimalNumber(decimal: amount).intValue
        let reconstructed = Decimal(integerPart)
        return amount == reconstructed
    }
    
    private func getEstimatedProcessingTime(for riskLevel: RiskLevel) -> TimeInterval {
        switch riskLevel {
        case .low: return 30
        case .medium: return 60
        case .high: return 120
        case .critical: return 300
        }
    }
    
    private func getSecurityRecommendations(for riskLevel: RiskLevel) -> [String] {
        switch riskLevel {
        case .low:
            return ["정상적인 거래입니다."]
        case .medium:
            return ["생체 인증이 필요합니다.", "거래 내역을 다시 한번 확인해주세요."]
        case .high:
            return [
                "높은 위험도 거래입니다.",
                "생체 인증 및 추가 인증이 필요합니다.",
                "수신 주소를 다시 한번 확인해주세요."
            ]
        case .critical:
            return [
                "매우 높은 위험도 거래입니다.",
                "모든 인증 절차가 필요합니다.",
                "거래 내역이 검토될 수 있습니다.",
                "고객 지원팀에 문의하는 것을 권장합니다."
            ]
        }
    }
    
    private func logSecurityEvent(
        _ event: SecurityEventType,
        amount: Decimal? = nil,
        address: String? = nil,
        riskLevel: RiskLevel? = nil,
        activityType: SuspiciousActivityType? = nil
    ) {
        var info: [String: Any] = ["event": event.rawValue]
        
        if let amount = amount { info["amount"] = String(describing: amount) }
        if let address = address { info["address"] = address }
        if let riskLevel = riskLevel { info["riskLevel"] = riskLevel.rawValue }
        if let activityType = activityType { info["activityType"] = activityType.rawValue }
        
        print("🔒 Transaction Security Event: \(event.rawValue) - \(info)")
    }
}

// MARK: - Supporting Types

struct TransactionValidationResult {
    let isValid: Bool
    let riskLevel: RiskLevel
    let requiredActions: [SecurityAction]
    let validationDetails: TransactionValidationDetails
}

struct TransactionEligibility {
    let canTransact: Bool
    let remainingDailyAmount: Decimal
    let remainingDailyTransactions: Int
    let remainingHourlyTransactions: Int
    let minimumWaitTime: TimeInterval
    let nextResetTime: Date
}

struct TransactionSecurityMetrics {
    let dailyTransactionAmount: Decimal
    let dailyTransactionCount: Int
    let hourlyTransactionCount: Int
    let averageTransactionAmount: Decimal
    let recentSuspiciousActivityCount: Int
    let riskScore: Double
}

struct TransactionValidationDetails {
    let amount: Decimal
    let riskLevel: RiskLevel
    let remainingDailyAmount: Decimal
    let remainingDailyTransactions: Int
    let estimatedProcessingTime: TimeInterval
    let securityRecommendations: [String]
}

struct TransactionRecord {
    let amount: Decimal
    let recipientAddress: String
    let timestamp: Date
    let riskLevel: RiskLevel
}

struct SuspiciousActivity {
    let type: SuspiciousActivityType
    let timestamp: Date
    let amount: Decimal?
    let address: String?
}

enum RiskLevel: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

enum RiskFactor {
    case largeAmount
    case frequentSameAddress
    case roundNumberPattern
    case rapidSuccession
    case unusualTime
    
    var weight: Int {
        switch self {
        case .largeAmount: return 3
        case .frequentSameAddress: return 2
        case .roundNumberPattern: return 1
        case .rapidSuccession: return 2
        case .unusualTime: return 1
        }
    }
}

enum SecurityAction {
    case biometricAuthentication
    case additionalVerification
    case manualReview
}

enum SuspiciousActivityType: String {
    case excessiveAmount = "excessive_amount"
    case nearFullBalanceTransfer = "near_full_balance_transfer"
    case largeTransaction = "large_transaction"
    case repeatedAddressUsage = "repeated_address_usage"
    case roundNumberPattern = "round_number_pattern"
    case rapidSuccessiveTransactions = "rapid_successive_transactions"
}

enum SecurityEventType: String {
    case transactionValidated = "transaction_validated"
    case suspiciousActivityDetected = "suspicious_activity_detected"
}

enum TransactionSecurityError: LocalizedError {
    case invalidAmount(String)
    case amountTooSmall(String)
    case amountTooLarge(String)
    case insufficientBalance(String)
    case rateLimitExceeded(String)
    case hourlyLimitExceeded(String)
    case dailyLimitExceeded(String)
    case dailyAmountExceeded(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidAmount(let message),
             .amountTooSmall(let message),
             .amountTooLarge(let message),
             .insufficientBalance(let message),
             .rateLimitExceeded(let message),
             .hourlyLimitExceeded(let message),
             .dailyLimitExceeded(let message),
             .dailyAmountExceeded(let message):
            return message
        }
    }
}

// MARK: - Date Extension

private extension Date {
    var startOfHour: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour], from: self)
        return calendar.date(from: components) ?? self
    }
}
