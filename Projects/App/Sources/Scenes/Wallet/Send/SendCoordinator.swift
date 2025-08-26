import SwiftUI
import Combine
import Entity
import Core
import DesignSystem

// MARK: - Validation Rules

struct EthereumAddressValidationRule {
    func validate(_ address: String) -> ValidationResult {
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedAddress.isEmpty {
            return ValidationResult(isValid: false, message: "주소를 입력해주세요")
        }
        
        let pattern = "^0x[a-fA-F0-9]{40}$"
        let regex = try! NSRegularExpression(pattern: pattern)
        let isValid = regex.firstMatch(in: trimmedAddress, range: NSRange(location: 0, length: trimmedAddress.count)) != nil
        
        return ValidationResult(
            isValid: isValid,
            message: isValid ? nil : "올바른 이더리움 주소를 입력해주세요"
        )
    }
}

struct AmountValidationRule {
    let balance: Double
    
    func validate(_ amount: String) -> ValidationResult {
        let trimmedAmount = amount.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedAmount.isEmpty {
            return ValidationResult(isValid: false, message: "금액을 입력해주세요")
        }
        
        guard let amountValue = Double(trimmedAmount), amountValue > 0 else {
            return ValidationResult(isValid: false, message: "유효한 금액을 입력해주세요")
        }
        
        if amountValue > balance {
            return ValidationResult(isValid: false, message: "잔액이 부족합니다")
        }
        
        return ValidationResult(isValid: true, message: nil)
    }
}

struct ValidationResult {
    let isValid: Bool
    let message: String?
}

@MainActor
@Observable
final class SendCoordinator {
    
    // MARK: - Observable Properties
    
    var recipientAddress = ""
    var amountText = ""
    var availableBalance = "0.00 ETH"
    var amountInUSD: String?
    
    // Validation States using new Validation system
    var addressValidation: ValidationState = .none
    var amountValidation: ValidationState = .none
    
    // Additional error states for compatibility
    var showAddressError = false
    var addressErrorMessage = ""
    var showAmountError = false
    var amountErrorMessage = ""
    
    // Computed properties for backward compatibility
    var isAddressValid: Bool { addressValidation.isValid }
    var isAmountValid: Bool { amountValidation.isValid }
    
    // Gas Fee States
    var showGasOptions = false
    var gasOptions: GasOptions?
    var selectedGasPriority: GasPriority?
    var selectedGasFee: GasFee?
    
    // Transaction States
    var isReadyToSend = false
    var isSending = false
    var formattedRecipientAddress = ""
    var formattedAmount = ""
    var totalAmount = ""
    var totalAmountUSD: String?
    
    // UI States
    var showErrorAlert = false
    var showSuccessView = false
    var errorMessage = ""
    var errorSuggestion: String?
    var transactionHash: String?
    
    // MARK: - Private Properties
    
    @ObservationIgnored private var interactor: SendBusinessLogic?
    @ObservationIgnored private let priceProvider: PriceProviderProtocol = MockPriceProvider()
    @ObservationIgnored private var debounceTask: Task<Void, Never>?
    @ObservationIgnored private var lastAction: (() -> Void)?
    
    // MARK: - Initialization
    
    init() {
        setupVIP()
    }
    
    private func setupVIP() {
        let interactor = SendInteractor()
        let presenter = SendPresenter()
        
        interactor.presenter = presenter
        presenter.viewController = self
        
        self.interactor = interactor
    }
    
    // MARK: - Public Methods
    
    func loadInitialData() {
        loadAvailableBalance()
    }
    
    func validateRecipientAddress(_ address: String) {
        let rule = EthereumAddressValidationRule()
        let result = rule.validate(address)
        
        if result.isValid {
            addressValidation = .valid
            showAddressError = false
            addressErrorMessage = ""
            formattedRecipientAddress = formatAddress(address)
        } else {
            addressValidation = .invalid(result.message ?? "유효하지 않은 주소입니다")
            showAddressError = true
            addressErrorMessage = result.message ?? "유효하지 않은 주소입니다"
        }
        
        // Check if both validations are complete and valid for gas estimation
        checkReadyForGasEstimation()
        
        // VIP 아키텍처도 유지
        let request = SendScene.ValidateAddress.Request(address: address)
        interactor?.validateAddress(request: request)
    }
    
    func validateAmount(_ amount: String) {
        let balance = getCurrentBalanceDecimal()
        let rule = AmountValidationRule(balance: NSDecimalNumber(decimal: balance).doubleValue)
        let result = rule.validate(amount)
        
        if result.isValid {
            amountValidation = .valid
            showAmountError = false
            amountErrorMessage = ""
            
            // Format amount
            if let amountDecimal = Decimal(string: amount) {
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal
                formatter.minimumFractionDigits = 0
                formatter.maximumFractionDigits = 6
                formattedAmount = (formatter.string(from: NSDecimalNumber(decimal: amountDecimal)) ?? "0") + " ETH"
            }
        } else {
            amountValidation = .invalid(result.message ?? "유효하지 않은 금액입니다")
            showAmountError = true
            amountErrorMessage = result.message ?? "유효하지 않은 금액입니다"
        }
        
        // Update USD value
        updateUSDValue(amount)
        
        // Check if both validations are complete and valid for gas estimation
        checkReadyForGasEstimation()
        
        // VIP 아키텍처도 유지
        let request = SendScene.ValidateAmount.Request(
            amount: amount,
            availableBalance: getCurrentBalanceValue()
        )
        interactor?.validateAmount(request: request)
    }
    
    private func checkReadyForGasEstimation() {
        if isAddressValid && isAmountValid && !recipientAddress.isEmpty && !amountText.isEmpty {
            estimateGasFee()
        } else {
            showGasOptions = false
            isReadyToSend = false
        }
    }
    
    func showQRScanner() {
        // QR 코드 스캐너 구현
        // 실제 구현에서는 AVFoundation을 사용하여 QR 코드 스캔
        print("QR 스캐너 표시")
    }
    
    func showAddressBook() {
        // 주소록 구현
        // 실제 구현에서는 저장된 주소 목록을 표시
        print("주소록 표시")
    }
    
    func setMaxAmount() {
        let currentBalance = getCurrentBalanceDecimal()
        
        // 가스비를 고려한 최대 금액 계산
        // 예상 가스비 0.003 ETH를 차감
        let estimatedGasFee = Decimal(0.003)
        let maxAmount = max(currentBalance - estimatedGasFee, 0)
        
        if maxAmount > 0 {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 6
            
            amountText = formatter.string(from: NSDecimalNumber(decimal: maxAmount)) ?? "0"
        }
    }
    
    func selectGasFee(_ priority: GasPriority, gasFee: GasFee) {
        selectedGasPriority = priority
        selectedGasFee = gasFee
        
        // 거래 준비
        let request = SendScene.PrepareTransaction.Request(
            recipientAddress: recipientAddress,
            amount: amountText,
            selectedGasFee: gasFee
        )
        interactor?.prepareTransaction(request: request)
    }
    
    func copyRecipientAddress() {
        UIPasteboard.general.string = recipientAddress
        // 토스트 알림 표시 (실제 구현에서)
        print("주소가 클립보드에 복사되었습니다")
    }
    
    func sendTransaction() {
        guard let pendingTransaction = (interactor as? SendDataStore)?.currentTransaction else {
            showError(title: "거래 오류", message: "거래 정보를 찾을 수 없습니다", suggestion: nil)
            return
        }
        
        isSending = true
        
        let request = SendScene.SendTransaction.Request(transaction: pendingTransaction)
        lastAction = { [weak self] in
            let request = SendScene.SendTransaction.Request(transaction: pendingTransaction)
            self?.interactor?.sendTransaction(request: request)
        }
        
        interactor?.sendTransaction(request: request)
    }
    
    // MARK: - Helper Methods
    
    private func convertToPendingTransaction(_ transaction: Entity.Transaction) -> PendingTransaction {
        return PendingTransaction(
            recipientAddress: transaction.to,
            amount: Decimal(string: transaction.value) ?? Decimal.zero,
            gasPrice: transaction.gasPrice ?? "0",
            gasLimit: transaction.gasUsed ?? "21000",
            nonce: "0" // This should be fetched from the network in real implementation
        )
    }
    
    func retryLastAction() {
        lastAction?()
    }
    
    // MARK: - Private Methods
    
    private func loadAvailableBalance() {
        let worker = SendWorker()
        let balance = worker.getCurrentBalance()
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 6
        
        let balanceString = formatter.string(from: NSDecimalNumber(decimal: balance)) ?? "0.00"
        availableBalance = "\(balanceString) ETH"
    }
    
    private func getCurrentBalanceValue() -> String {
        let worker = SendWorker()
        let balance = worker.getCurrentBalance()
        return balance.description
    }
    
    private func getCurrentBalanceDecimal() -> Decimal {
        let worker = SendWorker()
        return worker.getCurrentBalance()
    }
    
    private func estimateGasFee() {
        let request = SendScene.EstimateGas.Request(
            recipientAddress: recipientAddress,
            amount: amountText
        )
        interactor?.estimateGasFee(request: request)
    }
    
    private func updateUSDValue(_ amountText: String) {
        // Cancel previous debounce task
        debounceTask?.cancel()
        
        // Create new debounced task for USD value calculation
        debounceTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
            
            guard !Task.isCancelled else { return }
            
            guard let amount = Decimal(string: amountText), amount > 0 else {
                amountInUSD = nil
                return
            }
            
            let ethPrice = priceProvider.getETHPriceInUSD()
            let usdValue = amount * ethPrice
            
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "USD"
            formatter.locale = Locale(identifier: "en_US")
            
            amountInUSD = formatter.string(from: NSDecimalNumber(decimal: usdValue))
        }
    }
    
    private func showError(title: String, message: String, suggestion: String?) {
        errorMessage = message
        errorSuggestion = suggestion
        showErrorAlert = true
    }
}

// MARK: - Display Logic

extension SendCoordinator: SendDisplayLogic {
    
    func displayAddressValidation(viewModel: SendScene.ValidateAddress.ViewModel) {
        // Update validation state based on VIP response
        if viewModel.isValid {
            addressValidation = .valid
        } else {
            addressValidation = .invalid(viewModel.errorMessage ?? "유효하지 않은 주소입니다")
        }
        
        showAddressError = viewModel.showError
        addressErrorMessage = viewModel.errorMessage ?? ""
        
        if viewModel.isValid {
            formattedRecipientAddress = formatAddress(recipientAddress)
        }
    }
    
    func displayAmountValidation(viewModel: SendScene.ValidateAmount.ViewModel) {
        // Update validation state based on VIP response
        if viewModel.isValid {
            amountValidation = .valid
        } else {
            amountValidation = .invalid(viewModel.errorMessage ?? "유효하지 않은 금액입니다")
        }
        
        showAmountError = viewModel.showError
        amountErrorMessage = viewModel.errorMessage ?? ""
        
        if let formatted = viewModel.formattedAmount {
            formattedAmount = formatted
        }
    }
    
    func displayGasEstimation(viewModel: SendScene.EstimateGas.ViewModel) {
        if let gasOptions = viewModel.gasOptions {
            self.gasOptions = gasOptions
            showGasOptions = true
            
            // 기본적으로 보통 옵션 선택
            selectGasFee(.normal, gasFee: gasOptions.normal)
        } else {
            showGasOptions = false
            if let errorMessage = viewModel.errorMessage {
                showError(title: "가스비 계산 실패", message: errorMessage, suggestion: "네트워크 상태를 확인해주세요")
            }
        }
    }
    
    func displayTransactionPreparation(viewModel: SendScene.PrepareTransaction.ViewModel) {
        isReadyToSend = viewModel.isReadyToSend
        
        if let totalAmount = viewModel.totalAmount {
            self.totalAmount = totalAmount
        }
        
        if let totalUSD = viewModel.totalAmountUSD {
            self.totalAmountUSD = totalUSD
        }
        
        if viewModel.showError, let errorMessage = viewModel.errorMessage {
            showError(title: "거래 준비 실패", message: errorMessage, suggestion: "입력 정보를 확인해주세요")
        }
    }
    
    func displayTransactionResult(viewModel: SendScene.SendTransaction.ViewModel) {
        isSending = false
        
        if viewModel.showSuccess {
            transactionHash = viewModel.transactionHash
            showSuccessView = true
        }
        
        if viewModel.showError, let errorMessage = viewModel.errorMessage {
            showError(title: "거래 전송 실패", message: errorMessage, suggestion: "다시 시도해주세요")
        }
    }
    
    private func formatAddress(_ address: String) -> String {
        guard address.count >= 10 else { return address }
        let start = String(address.prefix(6))
        let end = String(address.suffix(4))
        return "\(start)...\(end)"
    }
}
