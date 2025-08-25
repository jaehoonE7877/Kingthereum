import Foundation
import Entity
@MainActor
protocol SendPresentationLogic {
    func presentAddressValidation(response: SendScene.ValidateAddress.Response)
    func presentAmountValidation(response: SendScene.ValidateAmount.Response)
    func presentGasEstimation(response: SendScene.EstimateGas.Response)
    func presentTransactionPreparation(response: SendScene.PrepareTransaction.Response)
    func presentTransactionResult(response: SendScene.SendTransaction.Response)
}

@MainActor
final class SendPresenter: SendPresentationLogic {
    weak var viewController: SendDisplayLogic?
    
    private let priceProvider: PriceProviderProtocol
    
    init(priceProvider: PriceProviderProtocol = MockPriceProvider()) {
        self.priceProvider = priceProvider
    }
    
    // MARK: - Presentation Logic
    
    func presentAddressValidation(response: SendScene.ValidateAddress.Response) {
        let displayModel = SendScene.ValidateAddress.ViewModel(
            isValid: response.isValid,
            errorMessage: response.errorMessage,
            showError: !response.isValid && response.errorMessage != nil
        )
        
        viewController?.displayAddressValidation(viewModel: displayModel)
    }
    
    func presentAmountValidation(response: SendScene.ValidateAmount.Response) {
        var formattedAmount: String?
        
        if let amount = response.parsedAmount {
            formattedAmount = formatETHAmount(amount)
        }
        
        let displayModel = SendScene.ValidateAmount.ViewModel(
            isValid: response.isValid,
            errorMessage: response.errorMessage,
            showError: !response.isValid && response.errorMessage != nil,
            formattedAmount: formattedAmount
        )
        
        viewController?.displayAmountValidation(viewModel: displayModel)
    }
    
    func presentGasEstimation(response: SendScene.EstimateGas.Response) {
        let displayModel = SendScene.EstimateGas.ViewModel(
            gasOptions: response.gasOptions,
            errorMessage: response.error,
            showError: response.error != nil
        )
        
        viewController?.displayGasEstimation(viewModel: displayModel)
    }
    
    func presentTransactionPreparation(response: SendScene.PrepareTransaction.Response) {
        var totalAmount: String?
        var totalAmountUSD: String?
        
        if let transaction = response.transaction {
            let ethPrice = priceProvider.getETHPriceInUSD()
            let total = transaction.amount
            
            totalAmount = formatETHAmount(total)
            totalAmountUSD = formatUSDAmount(total * ethPrice)
        }
        
        let displayModel = SendScene.PrepareTransaction.ViewModel(
            transaction: response.transaction,
            isReadyToSend: response.isReadyToSend,
            errorMessage: response.errorMessage,
            showError: !response.isReadyToSend && response.errorMessage != nil,
            totalAmount: totalAmount,
            totalAmountUSD: totalAmountUSD
        )
        
        viewController?.displayTransactionPreparation(viewModel: displayModel)
    }
    
    func presentTransactionResult(response: SendScene.SendTransaction.Response) {
        let displayModel = SendScene.SendTransaction.ViewModel(
            success: response.success,
            transactionHash: response.transactionHash,
            errorMessage: response.errorMessage,
            showSuccess: response.success,
            showError: !response.success && response.errorMessage != nil
        )
        
        viewController?.displayTransactionResult(viewModel: displayModel)
    }
    
    // MARK: - Private Formatters
    
    private func formatETHAmount(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 6
        formatter.locale = Locale.current
        
        let number = NSDecimalNumber(decimal: amount)
        return (formatter.string(from: number) ?? "0") + " ETH"
    }
    
    private func formatUSDAmount(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.locale = Locale(identifier: "en_US")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        let number = NSDecimalNumber(decimal: amount)
        return formatter.string(from: number) ?? "$0.00"
    }
}
