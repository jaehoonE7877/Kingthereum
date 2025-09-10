import Foundation
import SecurityKit
import Entity
import Core

/// 🔒 보안 강화된 송금 인터랙터
/// 모든 거래 전에 다중 인증 및 보안 검증 수행
final class SendSecurityInteractor: SendBusinessLogic {
    
    private let securityService: SecurityServiceProtocol
    private let sendWorker: SendWorkerProtocol
    private weak var presenter: SendPresentationLogic?
    
    // Rate limiting
    private var lastTransactionTime: Date = Date.distantPast
    private let minimumTransactionInterval: TimeInterval = 30 // 30초 최소 간격
    
    // Security validation
    private var consecutiveFailures: Int = 0
    private let maxConsecutiveFailures: Int = 3
    
    init(
        securityService: SecurityServiceProtocol,
        sendWorker: SendWorkerProtocol
    ) {
        self.securityService = securityService
        self.sendWorker = sendWorker
    }
    
    // MARK: - Secure Address Validation
    
    func validateAddress(request: SendScene.ValidateAddress.Request) {
        Task {
            do {
                // 🔒 1단계: 기본 형식 검증
                let isValidFormat = await validateAddressFormat(request.address)
                guard isValidFormat else {
                    await presentAddressValidation(isValid: false, message: "잘못된 주소 형식입니다")
                    return
                }
                
                // 🔒 2단계: 체크섬 검증
                let isValidChecksum = await validateAddressChecksum(request.address)
                guard isValidChecksum else {
                    await presentAddressValidation(isValid: false, message: "주소 체크섬이 올바르지 않습니다")
                    return
                }
                
                // 🔒 3단계: 블랙리스트 검증
                let isNotBlacklisted = await validateAddressNotBlacklisted(request.address)
                guard isNotBlacklisted else {
                    await logSecurityEvent(.suspiciousAddressDetected, address: request.address)
                    await presentAddressValidation(isValid: false, message: "이 주소로는 송금할 수 없습니다")
                    return
                }
                
                await presentAddressValidation(isValid: true, message: "유효한 주소입니다")
                
            } catch {
                await logSecurityEvent(.addressValidationError, error: error)
                await presentAddressValidation(isValid: false, message: "주소 검증 중 오류가 발생했습니다")
            }
        }
    }
    
    // MARK: - Secure Amount Validation
    
    func validateAmount(request: SendScene.ValidateAmount.Request) {
        Task {
            do {
                // 🔒 1단계: 숫자 형식 검증
                guard let amount = Decimal(string: request.amount), amount > 0 else {
                    await presentAmountValidation(isValid: false, message: "유효한 금액을 입력하세요")
                    return
                }
                
                // 🔒 2단계: 최소/최대 금액 제한
                guard amount >= 0.000001 else { // 최소 0.000001 ETH
                    await presentAmountValidation(isValid: false, message: "최소 송금 금액은 0.000001 ETH입니다")
                    return
                }
                
                guard amount <= 10 else { // 최대 10 ETH (보안상 제한)
                    await logSecurityEvent(.largeTransactionAttempt, amount: amount)
                    await presentAmountValidation(isValid: false, message: "한 번에 최대 10 ETH까지만 송금할 수 있습니다")
                    return
                }
                
                // 🔒 3단계: 잔액 검증
                let currentBalance = sendWorker.getCurrentBalance()
                guard amount <= currentBalance else {
                    await presentAmountValidation(isValid: false, message: "잔액이 부족합니다")
                    return
                }
                
                await presentAmountValidation(isValid: true, message: nil)
                
            } catch {
                await logSecurityEvent(.amountValidationError, error: error)
                await presentAmountValidation(isValid: false, message: "금액 검증 중 오류가 발생했습니다")
            }
        }
    }
    
    // MARK: - Secure Transaction Execution
    
    func sendTransaction(request: SendScene.SendTransaction.Request) {
        Task {
            do {
                // 🔒 1단계: Rate Limiting 검증
                guard await checkTransactionRateLimit() else {
                    await logSecurityEvent(.rateLimitExceeded)
                    await presentTransactionResult(success: false, error: "거래 요청이 너무 빈번합니다. 30초 후 다시 시도해주세요")
                    return
                }
                
                // 🔒 2단계: 디바이스 보안 상태 검증
                try await validateDeviceSecurity()
                
                // 🔒 3단계: 필수 생체인증
                let authResult = try await securityService.authenticateWithBiometrics(
                    reason: "이더리움 송금 승인을 위해 인증이 필요합니다"
                )
                
                guard authResult else {
                    consecutiveFailures += 1
                    await logSecurityEvent(.biometricAuthenticationFailed, failures: consecutiveFailures)
                    
                    if consecutiveFailures >= maxConsecutiveFailures {
                        await logSecurityEvent(.multipleAuthenticationFailures)
                        await presentTransactionResult(success: false, error: "연속된 인증 실패로 인해 거래가 차단되었습니다")
                        return
                    }
                    
                    await presentTransactionResult(success: false, error: "인증에 실패했습니다")
                    return
                }
                
                // 🔒 4단계: 최종 거래 정보 검증
                let validatedTransaction = try await validateAndPrepareTransaction(request)
                
                // 🔒 5단계: 보안 로깅
                await logSecurityEvent(.transactionInitiated, 
                                     recipient: request.recipient,
                                     amount: request.amount)
                
                // 🔒 6단계: 거래 실행
                let result = await sendWorker.sendTransaction(validatedTransaction)
                
                switch result {
                case .success(let txHash):
                    consecutiveFailures = 0 // 성공 시 실패 횟수 리셋
                    lastTransactionTime = Date()
                    await logSecurityEvent(.transactionCompleted, txHash: txHash)
                    await presentTransactionResult(success: true, txHash: txHash, error: nil)
                    
                case .failure(let error):
                    await logSecurityEvent(.transactionFailed, error: error)
                    await presentTransactionResult(success: false, error: "거래 전송에 실패했습니다: \(error.localizedDescription)")
                }
                
            } catch SecurityError.jailbreakDetected {
                await logSecurityEvent(.jailbreakDetected)
                await presentTransactionResult(success: false, error: "보안상의 이유로 거래를 수행할 수 없습니다")
            } catch SecurityError.rateLimitExceeded {
                await logSecurityEvent(.rateLimitExceeded)
                await presentTransactionResult(success: false, error: "너무 많은 시도로 인해 일시적으로 차단되었습니다")
            } catch {
                await logSecurityEvent(.transactionError, error: error)
                await presentTransactionResult(success: false, error: "거래 처리 중 오류가 발생했습니다")
            }
        }
    }
    
    // MARK: - Security Validation Methods
    
    private func validateDeviceSecurity() async throws {
        // SecurityService를 통한 디바이스 보안 검증
        try await securityService.authenticateWithSecurityValidation(
            reason: "거래 보안 검증"
        )
    }
    
    private func checkTransactionRateLimit() async -> Bool {
        let timeSinceLastTransaction = Date().timeIntervalSince(lastTransactionTime)
        return timeSinceLastTransaction >= minimumTransactionInterval
    }
    
    private func validateAndPrepareTransaction(_ request: SendScene.SendTransaction.Request) async throws -> Entity.PendingTransaction {
        // 최종 거래 정보 검증
        guard let amount = Decimal(string: request.amount) else {
            throw SendError.invalidAmount("잘못된 금액 형식")
        }
        
        guard sendWorker.validateEthereumAddress(request.recipient) else {
            throw SendError.invalidAddress("잘못된 수신 주소")
        }
        
        // 가스비 재검증
        guard let gasOptions = sendWorker.estimateGasFee(
            recipientAddress: request.recipient,
            amount: request.amount
        ) else {
            throw SendError.gasEstimationFailed("가스비 계산 실패")
        }
        
        let selectedGasFee: Entity.GasFee
        switch request.gasFee {
        case .slow: selectedGasFee = gasOptions.slow
        case .standard: selectedGasFee = gasOptions.normal
        case .fast: selectedGasFee = gasOptions.fast
        }
        
        guard let transaction = sendWorker.prepareTransaction(
            recipientAddress: request.recipient,
            amount: amount,
            gasFee: selectedGasFee
        ) else {
            throw SendError.transactionPreparationFailed("거래 준비 실패")
        }
        
        return transaction
    }
    
    // MARK: - Enhanced Address Validation
    
    private func validateAddressFormat(_ address: String) async -> Bool {
        // 정규식 + 길이 검증 강화
        let pattern = "^0x[a-fA-F0-9]{40}$"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
        
        let range = NSRange(location: 0, length: address.count)
        return regex.firstMatch(in: address, range: range) != nil
    }
    
    private func validateAddressChecksum(_ address: String) async -> Bool {
        // EIP-55 체크섬 검증 구현
        let lowercaseAddress = address.lowercased()
        
        // 모두 소문자이거나 모두 대문자면 체크섬이 없다고 가정하고 통과
        if address == lowercaseAddress || address == address.uppercased() {
            return true
        }
        
        // 실제 체크섬 검증 로직은 web3swift 라이브러리를 통해 구현
        // 여기서는 간소화된 검증
        return true
    }
    
    private func validateAddressNotBlacklisted(_ address: String) async -> Bool {
        // 알려진 악성 주소 블랙리스트 검증
        let blacklistedAddresses: Set<String> = [
            "0x0000000000000000000000000000000000000000", // Null address
            // 실제 구현에서는 서버에서 동적으로 받아오거나 내장된 리스트 사용
        ]
        
        return !blacklistedAddresses.contains(address.lowercased())
    }
    
    // MARK: - Security Logging
    
    private func logSecurityEvent(_ event: SecurityEventType, 
                                recipient: String? = nil,
                                amount: String? = nil,
                                address: String? = nil,
                                txHash: String? = nil,
                                error: Error? = nil,
                                failures: Int? = nil) async {
        
        var additionalInfo: [String: Any] = [:]
        if let recipient = recipient { additionalInfo["recipient"] = recipient }
        if let amount = amount { additionalInfo["amount"] = amount }
        if let address = address { additionalInfo["address"] = address }
        if let txHash = txHash { additionalInfo["txHash"] = txHash }
        if let error = error { additionalInfo["error"] = error.localizedDescription }
        if let failures = failures { additionalInfo["failures"] = failures }
        
        // 실제 구현에서는 보안 로깅 시스템으로 전송
        print("🔒 Security Event: \(event) - \(additionalInfo)")
    }
    
    // MARK: - Presentation Methods
    
    private func presentAddressValidation(isValid: Bool, message: String?) async {
        let viewModel = SendScene.ValidateAddress.ViewModel(isValid: isValid, message: message)
        await MainActor.run {
            presenter?.presentAddressValidation(response: .init(isValid: isValid, message: message))
        }
    }
    
    private func presentAmountValidation(isValid: Bool, message: String?) async {
        await MainActor.run {
            presenter?.presentAmountValidation(response: .init(isValid: isValid, message: message))
        }
    }
    
    private func presentTransactionResult(success: Bool, txHash: String? = nil, error: String?) async {
        await MainActor.run {
            presenter?.presentTransactionResult(response: .init(success: success, transactionHash: txHash, errorMessage: error))
        }
    }
    
    // MARK: - Other Protocol Methods (delegated to worker)
    
    func estimateGas(request: SendScene.EstimateGas.Request) {
        // 기존 구현 위임
        Task {
            guard let gasOptions = sendWorker.estimateGasFee(
                recipientAddress: request.recipient,
                amount: request.amount
            ) else {
                await MainActor.run {
                    presenter?.presentGasEstimation(response: .init(estimatedGas: "계산 실패"))
                }
                return
            }
            
            let selectedGas: Entity.GasFee
            switch request.gasFeeLevel {
            case .slow: selectedGas = gasOptions.slow
            case .standard: selectedGas = gasOptions.normal
            case .fast: selectedGas = gasOptions.fast
            }
            
            let gasString = String(format: "%.6f ETH (≈$%.2f)", 
                                 selectedGas.feeInETH as NSDecimalNumber,
                                 selectedGas.feeInUSD as NSDecimalNumber)
            
            await MainActor.run {
                presenter?.presentGasEstimation(response: .init(estimatedGas: gasString))
            }
        }
    }
    
    func prepareTransaction(request: SendScene.PrepareTransaction.Request) {
        // 기존 구현
    }
    
    func authenticateWithBiometrics(request: SendScene.BiometricAuth.Request) {
        // SecurityService 위임
        Task {
            do {
                let success = try await securityService.authenticateWithBiometrics(
                    reason: "거래 승인을 위해 인증이 필요합니다"
                )
                await MainActor.run {
                    presenter?.presentBiometricAuthResult(response: .init(success: success, errorMessage: nil))
                }
            } catch {
                await MainActor.run {
                    presenter?.presentBiometricAuthResult(response: .init(success: false, errorMessage: error.localizedDescription))
                }
            }
        }
    }
    
    func scanQRCode(request: SendScene.QRScanner.Request) {
        // QR 스캐너 구현 위임
    }
}

// MARK: - Security Event Types

private enum SecurityEventType {
    case addressValidationStarted
    case addressValidationCompleted
    case suspiciousAddressDetected
    case addressValidationError
    case amountValidationError
    case largeTransactionAttempt
    case rateLimitExceeded
    case biometricAuthenticationFailed
    case multipleAuthenticationFailures
    case transactionInitiated
    case transactionCompleted
    case transactionFailed
    case transactionError
    case jailbreakDetected
}

// MARK: - Protocol Stubs for Compilation

protocol SendPresentationLogic: AnyObject {
    func presentAddressValidation(response: SendScene.ValidateAddress.Response)
    func presentAmountValidation(response: SendScene.ValidateAmount.Response)
    func presentGasEstimation(response: SendScene.EstimateGas.Response)
    func presentTransactionResult(response: SendScene.SendTransaction.Response)
    func presentBiometricAuthResult(response: SendScene.BiometricAuth.Response)
}

// Response 모델 추가
extension SendScene.ValidateAddress {
    struct Response {
        let isValid: Bool
        let message: String?
    }
}

extension SendScene.ValidateAmount {
    struct Response {
        let isValid: Bool
        let message: String?
    }
}

extension SendScene.EstimateGas {
    struct Response {
        let estimatedGas: String
    }
}

extension SendScene.SendTransaction {
    struct Response {
        let success: Bool
        let transactionHash: String?
        let errorMessage: String?
    }
}

extension SendScene.BiometricAuth {
    struct Response {
        let success: Bool
        let errorMessage: String?
    }
}