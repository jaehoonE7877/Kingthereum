import Foundation
import Core
import Entity
import SecurityKit

// MARK: - Send Security Interactor

@MainActor
final class SendSecurityInteractor {
    
    // MARK: - Properties
    
    private let securityService: SecurityServiceProtocol
    private let sendWorker: SendWorkerProtocol
    
    // MARK: - Security State
    
    private var isAuthenticated = false
    private var lastAuthenticationTime: Date?
    private let authenticationTimeout: TimeInterval = 300 // 5분
    
    // MARK: - Risk Assessment
    
    private var riskScore: Double = 0.0
    private var securityFlags: Set<SecurityFlag> = []
    
    // MARK: - Initialization
    
    init(securityService: SecurityServiceProtocol, sendWorker: SendWorkerProtocol) {
        self.securityService = securityService
        self.sendWorker = sendWorker
    }
    
    // MARK: - Main Security Functions
    
    /// 트랜잭션 보안 검증
    func validateTransaction(_ transaction: PendingTransaction) async -> Bool {
        // 1. 주소 검증
        guard sendWorker.validateEthereumAddress(transaction.recipientAddress) else {
            await logSecurityEvent(.invalidAddress)
            return false
        }
        
        // 2. 금액 검증
        guard transaction.amount > 0 else {
            await logSecurityEvent(.invalidAmount)
            return false
        }
        
        // 3. 리스크 평가
        let risk = await assessTransactionRisk(transaction)
        guard risk < 0.7 else {
            await logSecurityEvent(.highRiskTransaction)
            return false
        }
        
        // 4. 생체 인증
        do {
            let _ = try await securityService.authenticateWithBiometrics(
                reason: "거래 승인을 위해 인증이 필요합니다"
            )
            isAuthenticated = true
            lastAuthenticationTime = Date()
            return true
        } catch {
            await logSecurityEvent(.authenticationFailed)
            return false
        }
    }
    
    /// 리스크 평가
    private func assessTransactionRisk(_ transaction: PendingTransaction) async -> Double {
        var score = 0.0
        
        // 금액 기반 리스크
        if transaction.amount > 10 {
            score += 0.3
        }
        if transaction.amount > 100 {
            score += 0.4
        }
        
        // 주소 검증
        if await isKnownMaliciousAddress(transaction.recipientAddress) {
            score += 0.5
        }
        
        // 빈도 기반 리스크
        if await hasRecentTransactions() {
            score += 0.2
        }
        
        self.riskScore = score
        return score
    }
    
    /// 악성 주소 확인
    private func isKnownMaliciousAddress(_ address: String) async -> Bool {
        // 실제로는 외부 API나 블랙리스트 DB 확인
        let blacklist = [
            "0x0000000000000000000000000000000000000000",
            "0xdeaddeaddeaddeaddeaddeaddeaddeaddeaddead"
        ]
        return blacklist.contains(address.lowercased())
    }
    
    /// 최근 거래 확인
    private func hasRecentTransactions() async -> Bool {
        // 실제로는 거래 히스토리 확인
        return false
    }
    
    /// 보안 이벤트 로깅
    private func logSecurityEvent(_ event: SecurityEvent) async {
        print("[Security] Event: \(event.rawValue) at \(Date())")
        
        // 실제로는 보안 로그 서비스에 전송
        switch event {
        case .highRiskTransaction, .authenticationFailed:
            // 알림 전송
            await notifySecurityAlert(event)
        default:
            break
        }
    }
    
    /// 보안 알림
    private func notifySecurityAlert(_ event: SecurityEvent) async {
        // 실제로는 푸시 알림이나 이메일 전송
        print("[Security Alert] \(event.rawValue)")
    }
    
    // MARK: - Authentication Management
    
    /// 인증 상태 확인
    func isCurrentlyAuthenticated() -> Bool {
        guard isAuthenticated,
              let lastAuth = lastAuthenticationTime else {
            return false
        }
        
        let elapsed = Date().timeIntervalSince(lastAuth)
        return elapsed < authenticationTimeout
    }
    
    /// 인증 갱신
    func refreshAuthentication() async -> Bool {
        do {
            let _ = try await securityService.authenticateWithBiometrics(
                reason: "인증을 갱신합니다"
            )
            isAuthenticated = true
            lastAuthenticationTime = Date()
            return true
        } catch {
            isAuthenticated = false
            lastAuthenticationTime = nil
            return false
        }
    }
    
    /// 인증 취소
    func revokeAuthentication() {
        isAuthenticated = false
        lastAuthenticationTime = nil
    }
    
    // MARK: - Additional Security Features
    
    /// 2FA 인증
    func verify2FA(code: String) async -> Bool {
        // 실제로는 서버에서 2FA 코드 검증
        return code == "123456"
    }
    
    /// 거래 한도 확인
    func checkTransactionLimit(_ amount: Decimal) async -> Bool {
        let dailyLimit: Decimal = 1000
        let monthlyLimit: Decimal = 10000
        
        // 실제로는 DB에서 누적 거래액 조회
        let dailyTotal: Decimal = 0
        let monthlyTotal: Decimal = 0
        
        return (dailyTotal + amount <= dailyLimit) && 
               (monthlyTotal + amount <= monthlyLimit)
    }
    
    /// 생체 인증
    func authenticateWithBiometrics() async {
        // SecurityService 위임
        do {
            let _ = try await securityService.authenticateWithBiometrics(
                reason: "거래 승인을 위해 인증이 필요합니다"
            )
            // Biometric auth result handled elsewhere
        } catch {
            // Handle error
        }
    }
    
    /// QR 코드 스캔
    func scanQRCode() {
        // QR 스캐너 구현 위임
    }
}

// MARK: - Supporting Types

/// 보안 플래그
enum SecurityFlag {
    case highAmount
    case unknownAddress
    case rapidTransactions
    case suspiciousPattern
}

/// 보안 이벤트
enum SecurityEvent: String {
    case invalidAddress = "Invalid Address"
    case invalidAmount = "Invalid Amount"
    case highRiskTransaction = "High Risk Transaction"
    case authenticationFailed = "Authentication Failed"
    case transactionApproved = "Transaction Approved"
    case transactionDenied = "Transaction Denied"
}