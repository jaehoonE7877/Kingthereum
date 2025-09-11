import Foundation
import Core
import Entity
import Factory

// MARK: - Business Logic Protocols

@MainActor
protocol SendBusinessLogic: AnyObject {
    func validateAddress(request: SendScene.ValidateAddress.Request) async
    func validateAmount(request: SendScene.ValidateAmount.Request) async
    func estimateGas(request: SendScene.EstimateGas.Request) async
    func prepareTransaction(request: SendScene.PrepareTransaction.Request) async
    func sendTransaction(request: SendScene.SendTransaction.Request) async
}

@MainActor
protocol SendDataStore: AnyObject {
    var recipientAddress: String { get set }
    var amount: String { get set }
    var selectedGasFee: GasFee? { get set }
    var pendingTransaction: PendingTransaction? { get set }
    var wallet: Entity.Wallet? { get set }
}

// MARK: - Main Send Interactor

@MainActor
final class SendInteractor: SendBusinessLogic, SendDataStore {
    
    // MARK: - VIP Components
    var presenter: SendPresentationLogic?
    
    // MARK: - Dependencies
    private let sendWorker: SendWorkerProtocol
    private let securityInteractor: SendSecurityInteractor
    
    // MARK: - Data Store Properties
    var recipientAddress: String = ""
    var amount: String = ""
    var selectedGasFee: GasFee?
    var pendingTransaction: PendingTransaction?
    var wallet: Entity.Wallet?
    
    // MARK: - Initialization
    
    init() {
        self.sendWorker = SendWorker()
        let service = Container.shared.securityService()
        self.securityInteractor = SendSecurityInteractor(
            securityService: service,
            sendWorker: sendWorker
        )
    }
    
    // MARK: - Business Logic Implementation
    
    func validateAddress(request: SendScene.ValidateAddress.Request) async {
        let isValid = sendWorker.validateEthereumAddress(request.address)
        let response: SendScene.ValidateAddress.Response
        
        if isValid {
            // 유효한 주소인 경우 데이터 스토어에 저장
            self.recipientAddress = request.address
            response = SendScene.ValidateAddress.Response(
                isValid: true,
                errorMessage: nil
            )
        } else {
            response = SendScene.ValidateAddress.Response(
                isValid: false,
                errorMessage: "유효하지 않은 이더리움 주소입니다"
            )
        }
        
        presenter?.presentAddressValidation(response: response)
    }
    
    func validateAmount(request: SendScene.ValidateAmount.Request) async {
        let currentBalance = await sendWorker.getCurrentBalance()
        let validationResult = await sendWorker.validateAmount(
            amount: request.amount,
            availableBalance: String(describing: currentBalance)
        )
        
        if validationResult.isValid {
            // 유효한 금액인 경우 데이터 스토어에 저장
            self.amount = request.amount
        }
        
        let response = SendScene.ValidateAmount.Response(
            isValid: validationResult.isValid,
            errorMessage: validationResult.errorMessage,
            parsedAmount: validationResult.parsedAmount
        )
        
        presenter?.presentAmountValidation(response: response)
    }
    
    func estimateGas(request: SendScene.EstimateGas.Request) async {
        let gasOptions = await sendWorker.estimateGasFee(
            recipientAddress: request.recipientAddress,
            amount: request.amount
        )
        
        let response = SendScene.EstimateGas.Response(
            gasOptions: gasOptions,
            estimatedGas: nil,
            error: gasOptions == nil ? "가스비 추정에 실패했습니다" : nil
        )
        
        presenter?.presentGasEstimation(response: response)
    }
    
    func prepareTransaction(request: SendScene.PrepareTransaction.Request) async {
        // 선택된 가스비 저장
        self.selectedGasFee = request.selectedGasFee
        
        guard let amountDecimal = Decimal(string: request.amount) else {
            let response = SendScene.PrepareTransaction.Response(
                transaction: nil,
                isReadyToSend: false,
                errorMessage: "잘못된 금액 형식입니다"
            )
            presenter?.presentTransactionPreparation(response: response)
            return
        }
        
        let transaction = await sendWorker.prepareTransaction(
            recipientAddress: request.recipientAddress,
            amount: amountDecimal,
            gasFee: request.selectedGasFee
        )
        
        if let transaction = transaction {
            // 준비된 거래 저장
            self.pendingTransaction = transaction
            
            let response = SendScene.PrepareTransaction.Response(
                transaction: transaction,
                isReadyToSend: true,
                errorMessage: nil
            )
            
            presenter?.presentTransactionPreparation(response: response)
        } else {
            let response = SendScene.PrepareTransaction.Response(
                transaction: nil,
                isReadyToSend: false,
                errorMessage: "거래 준비에 실패했습니다"
            )
            presenter?.presentTransactionPreparation(response: response)
        }
    }
    
    func sendTransaction(request: SendScene.SendTransaction.Request) async {
        // 보안 검증을 위해 SecurityInteractor 사용
        let isSecure = await securityInteractor.validateTransaction(request.transaction)
        
        guard isSecure else {
            let response = SendScene.SendTransaction.Response(
                success: false,
                transactionHash: nil,
                errorMessage: "보안 검증에 실패했습니다"
            )
            presenter?.presentTransactionResult(response: response)
            return
        }
        
        // 실제 거래 전송
        let result = await sendWorker.sendTransaction(request.transaction)
        
        switch result {
        case .success(let transactionHash):
            let response = SendScene.SendTransaction.Response(
                success: true,
                transactionHash: transactionHash,
                errorMessage: nil
            )
            presenter?.presentTransactionResult(response: response)
            
        case .failure(let error):
            let response = SendScene.SendTransaction.Response(
                success: false,
                transactionHash: nil,
                errorMessage: error.localizedDescription
            )
            presenter?.presentTransactionResult(response: response)
        }
    }
}

// MARK: - Supporting Extensions

private extension SendInteractor {
    
    /// 현재 지갑 정보 로드
    func loadCurrentWallet() async throws -> Entity.Wallet {
        // Simplified wallet loading for now
        let wallet = Entity.Wallet(
            name: "Kingthereum Wallet",
            address: "0x742d35Cc6634C0532925a3b8D04Cc3e14b01B9E6"
        )
        self.wallet = wallet
        return wallet
    }
    
    /// 거래 전 최종 검증
    func performFinalValidation(transaction: PendingTransaction) async -> Bool {
        // 주소 재검증
        guard !recipientAddress.isEmpty,
              recipientAddress == transaction.recipientAddress else {
            return false
        }
        
        // 금액 재검증
        guard !amount.isEmpty,
              transaction.amount > 0 else {
            return false
        }
        
        // 가스비 검증
        guard selectedGasFee != nil else {
            return false
        }
        
        return true
    }
}