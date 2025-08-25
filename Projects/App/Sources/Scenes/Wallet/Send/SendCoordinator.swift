import SwiftUI
import Combine


import Entity

@MainActor
final class SendCoordinator: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var recipientAddress = ""
    @Published var amountText = ""
    @Published var availableBalance = "0.00 ETH"
    @Published var amountInUSD: String?
    
    // Validation States
    @Published var isAddressValid = false
    @Published var isAmountValid = false
    @Published var showAddressError = false
    @Published var showAmountError = false
    @Published var addressErrorMessage = ""
    @Published var amountErrorMessage = ""
    
    // Gas Fee States
    @Published var showGasOptions = false
    @Published var gasOptions: GasOptions?
    @Published var selectedGasPriority: GasPriority?
    @Published var selectedGasFee: GasFee?
    
    // Transaction States
    @Published var isReadyToSend = false
    @Published var isSending = false
    @Published var formattedRecipientAddress = ""
    @Published var formattedAmount = ""
    @Published var totalAmount = ""
    @Published var totalAmountUSD: String?
    
    // UI States
    @Published var showErrorAlert = false
    @Published var showSuccessView = false
    @Published var errorMessage = ""
    @Published var errorSuggestion: String?
    @Published var transactionHash: String?
    
    // MARK: - Private Properties
    
    private var interactor: SendBusinessLogic?
    private let priceProvider: PriceProviderProtocol = MockPriceProvider()
    private var cancellables = Set<AnyCancellable>()
    private var lastAction: (() -> Void)?
    
    // MARK: - Initialization
    
    init() {
        setupVIP()
        setupBindings()
    }
    
    private func setupVIP() {
        let interactor = SendInteractor()
        let presenter = SendPresenter()
        
        interactor.presenter = presenter
        presenter.viewController = self
        
        self.interactor = interactor
    }
    
    private func setupBindings() {
        // 주소와 금액이 모두 유효할 때 가스비 계산
        Publishers.CombineLatest($isAddressValid, $isAmountValid)
            .removeDuplicates { $0.0 == $1.0 && $0.1 == $1.1 }
            .sink { [weak self] addressValid, amountValid in
                if addressValid && amountValid {
                    self?.estimateGasFee()
                } else {
                    self?.showGasOptions = false
                    self?.isReadyToSend = false
                }
            }
            .store(in: &cancellables)
        
        // 금액 변경 시 USD 환율 계산
        $amountText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] amountText in
                self?.updateUSDValue(amountText)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func loadInitialData() {
        loadAvailableBalance()
    }
    
    func validateRecipientAddress(_ address: String) {
        let request = SendScene.ValidateAddress.Request(address: address)
        interactor?.validateAddress(request: request)
    }
    
    func validateAmount(_ amount: String) {
        let request = SendScene.ValidateAmount.Request(
            amount: amount,
            availableBalance: getCurrentBalanceValue()
        )
        interactor?.validateAmount(request: request)
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
    
    private func showError(title: String, message: String, suggestion: String?) {
        errorMessage = message
        errorSuggestion = suggestion
        showErrorAlert = true
    }
}

// MARK: - Display Logic

extension SendCoordinator: SendDisplayLogic {
    
    func displayAddressValidation(viewModel: SendScene.ValidateAddress.ViewModel) {
        isAddressValid = viewModel.isValid
        showAddressError = viewModel.showError
        addressErrorMessage = viewModel.errorMessage ?? ""
        
        if isAddressValid {
            formattedRecipientAddress = formatAddress(recipientAddress)
        }
    }
    
    func displayAmountValidation(viewModel: SendScene.ValidateAmount.ViewModel) {
        isAmountValid = viewModel.isValid
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
