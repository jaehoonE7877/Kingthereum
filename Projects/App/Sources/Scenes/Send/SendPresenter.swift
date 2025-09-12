import Foundation
import Entity
import Core

// MARK: - Presentation Logic Protocol

@MainActor
protocol SendPresentationLogic: AnyObject {
    func presentAddressValidation(response: SendScene.ValidateAddress.Response)
    func presentAmountValidation(response: SendScene.ValidateAmount.Response)
    func presentGasEstimation(response: SendScene.EstimateGas.Response)
    func presentTransactionPreparation(response: SendScene.PrepareTransaction.Response)
    func presentTransactionResult(response: SendScene.SendTransaction.Response)
    func presentETHPrice(ethPrice: Decimal)
}

// MARK: - Send Presenter

@MainActor
final class SendPresenter: SendPresentationLogic {
    weak var viewController: SendDisplayLogic?
    
    // Current ETH price for conversions
    private var currentETHPrice: Decimal = 2500.0
    
    // MARK: - Present Address Validation
    
    func presentAddressValidation(response: SendScene.ValidateAddress.Response) {
        Logger.debug("📋 [SendPresenter] Presenting address validation: valid=\(response.isValid)")
        
        let viewModel = SendScene.ValidateAddress.ViewModel(
            isValid: response.isValid,
            errorMessage: response.errorMessage,
            showError: !response.isValid && response.errorMessage != nil
        )
        
        viewController?.displayAddressValidation(viewModel: viewModel)
    }
    
    // MARK: - Present Amount Validation
    
    func presentAmountValidation(response: SendScene.ValidateAmount.Response) {
        Logger.debug("📋 [SendPresenter] Presenting amount validation: valid=\(response.isValid)")
        
        var formattedAmount: String?
        if let parsedAmount = response.parsedAmount {
            // Format the amount nicely
            let formatter = NumberFormatter()
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 6
            formatter.numberStyle = .decimal
            
            if let formatted = formatter.string(from: NSDecimalNumber(decimal: parsedAmount)) {
                formattedAmount = formatted + " ETH"
            }
        }
        
        let viewModel = SendScene.ValidateAmount.ViewModel(
            isValid: response.isValid,
            errorMessage: response.errorMessage,
            showError: !response.isValid && response.errorMessage != nil,
            formattedAmount: formattedAmount
        )
        
        viewController?.displayAmountValidation(viewModel: viewModel)
    }
    
    // MARK: - Present Gas Estimation
    
    func presentGasEstimation(response: SendScene.EstimateGas.Response) {
        Logger.debug("📋 [SendPresenter] Presenting gas estimation")
        
        // If gas estimation succeeded, enhance the gas options with USD values
        var enhancedGasOptions: GasOptions?
        
        if let gasOptions = response.gasOptions {
            enhancedGasOptions = enhanceGasOptionsWithUSD(gasOptions: gasOptions)
        }
        
        let viewModel = SendScene.EstimateGas.ViewModel(
            gasOptions: enhancedGasOptions,
            errorMessage: response.error,
            showError: response.error != nil
        )
        
        viewController?.displayGasEstimation(viewModel: viewModel)
    }
    
    // MARK: - Present Transaction Preparation
    
    func presentTransactionPreparation(response: SendScene.PrepareTransaction.Response) {
        Logger.debug("📋 [SendPresenter] Presenting transaction preparation: ready=\(response.isReadyToSend)")
        
        var totalAmount: String?
        var totalAmountUSD: String?
        
        if let transaction = response.transaction {
            // Calculate total amount (amount + gas fee)
            let totalETH = calculateTotalAmount(transaction: transaction)
            let totalUSD = totalETH * currentETHPrice
            
            // Format amounts
            totalAmount = formatETHAmount(totalETH)
            totalAmountUSD = formatUSDAmount(totalUSD)
        }
        
        let viewModel = SendScene.PrepareTransaction.ViewModel(
            transaction: response.transaction,
            isReadyToSend: response.isReadyToSend,
            errorMessage: response.errorMessage,
            showError: response.errorMessage != nil,
            totalAmount: totalAmount,
            totalAmountUSD: totalAmountUSD
        )
        
        viewController?.displayTransactionPreparation(viewModel: viewModel)
    }
    
    // MARK: - Present Transaction Result
    
    func presentTransactionResult(response: SendScene.SendTransaction.Response) {
        Logger.debug("📋 [SendPresenter] Presenting transaction result: success=\(response.success)")
        
        let viewModel = SendScene.SendTransaction.ViewModel(
            success: response.success,
            transactionHash: response.transactionHash,
            errorMessage: response.errorMessage,
            showSuccess: response.success,
            showError: !response.success && response.errorMessage != nil
        )
        
        viewController?.displayTransactionResult(viewModel: viewModel)
    }
    
    // MARK: - Present ETH Price
    
    func presentETHPrice(ethPrice: Decimal) {
        Logger.debug("📋 [SendPresenter] Presenting ETH price: $\(ethPrice)")
        
        currentETHPrice = ethPrice
        viewController?.displayETHPrice(ethPrice: ethPrice)
    }
    
    // MARK: - Private Helper Methods
    
    private func enhanceGasOptionsWithUSD(gasOptions: GasOptions) -> GasOptions {
        // Enhance gas options with accurate USD calculations using current ETH price
        let enhancedSlow = enhanceGasFeeWithUSD(gasFee: gasOptions.slow)
        let enhancedNormal = enhanceGasFeeWithUSD(gasFee: gasOptions.normal)
        let enhancedFast = enhanceGasFeeWithUSD(gasFee: gasOptions.fast)
        
        return GasOptions(
            slow: enhancedSlow,
            normal: enhancedNormal,
            fast: enhancedFast
        )
    }
    
    private func enhanceGasFeeWithUSD(gasFee: GasFee) -> GasFee {
        // Recalculate USD value with current ETH price
        let updatedFeeInUSD = gasFee.feeInETH * currentETHPrice
        
        return GasFee(
            gasPrice: gasFee.gasPrice,
            estimatedTime: gasFee.estimatedTime,
            feeInETH: gasFee.feeInETH,
            feeInUSD: updatedFeeInUSD
        )
    }
    
    private func calculateTotalAmount(transaction: PendingTransaction) -> Decimal {
        // Calculate gas fee in ETH
        guard let gasPriceWei = Decimal(string: transaction.gasPrice),
              let gasLimit = Decimal(string: transaction.gasLimit) else {
            Logger.error("❌ [SendPresenter] Invalid gas price or limit in transaction")
            return transaction.amount
        }
        
        // Convert gas fee from Wei to ETH
        let gasFeeWei = gasPriceWei * gasLimit
        let gasFeeETH = gasFeeWei / Decimal(pow(10.0, 18))
        
        return transaction.amount + gasFeeETH
    }
    
    private func formatETHAmount(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 6
        formatter.numberStyle = .decimal
        
        if let formatted = formatter.string(from: NSDecimalNumber(decimal: amount)) {
            return formatted + " ETH"
        }
        
        return String(format: "%.6f ETH", NSDecimalNumber(decimal: amount).doubleValue)
    }
    
    private func formatUSDAmount(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        
        if let formatted = formatter.string(from: NSDecimalNumber(decimal: amount)) {
            return formatted
        }
        
        return String(format: "$%.2f", NSDecimalNumber(decimal: amount).doubleValue)
    }
    
    // MARK: - Conversion Utilities
    
    /// Convert ETH amount to USD
    func convertETHToUSD(_ ethAmount: Decimal) -> Decimal {
        return ethAmount * currentETHPrice
    }
    
    /// Convert USD amount to ETH
    func convertUSDToETH(_ usdAmount: Decimal) -> Decimal {
        guard currentETHPrice > 0 else { return 0 }
        return usdAmount / currentETHPrice
    }
    
    /// Format amount based on currency preference
    func formatAmount(_ amount: Decimal, inUSD: Bool) -> String {
        if inUSD {
            let usdAmount = convertETHToUSD(amount)
            return formatUSDAmount(usdAmount)
        } else {
            return formatETHAmount(amount)
        }
    }
    
    /// Get display amount for UI
    func getDisplayAmount(ethAmount: Decimal, showInUSD: Bool) -> (primary: String, secondary: String) {
        let ethString = formatETHAmount(ethAmount)
        let usdAmount = convertETHToUSD(ethAmount)
        let usdString = formatUSDAmount(usdAmount)
        
        if showInUSD {
            return (primary: usdString, secondary: "≈ \(ethString)")
        } else {
            return (primary: ethString, secondary: "≈ \(usdString)")
        }
    }
    
    /// Validate amount string for proper decimal format
    func validateAmountFormat(_ amountString: String, isUSD: Bool) -> (isValid: Bool, errorMessage: String?) {
        // Remove any currency symbols and whitespace
        let cleanedAmount = amountString.replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if it's a valid decimal number
        guard let amount = Decimal(string: cleanedAmount), amount >= 0 else {
            return (false, "올바른 숫자 형식을 입력해주세요")
        }
        
        // Check for reasonable limits
        if isUSD {
            // USD limits (assuming ETH around $1000-$10000)
            let minUSD = Decimal(0.01) // $0.01
            let maxUSD = Decimal(1000000) // $1M
            
            if amount < minUSD {
                return (false, "최소 금액은 $0.01입니다")
            }
            
            if amount > maxUSD {
                return (false, "금액이 너무 큽니다")
            }
        } else {
            // ETH limits
            let minETH = Decimal(string: "0.000001")! // 1 μETH
            let maxETH = Decimal(1000) // 1000 ETH
            
            if amount < minETH {
                return (false, "최소 금액은 0.000001 ETH입니다")
            }
            
            if amount > maxETH {
                return (false, "금액이 너무 큽니다")
            }
        }
        
        // Check decimal places
        let decimalPlaces = getDecimalPlaces(from: amount)
        
        if isUSD {
            if decimalPlaces > 2 {
                return (false, "USD는 최대 소수점 둘째 자리까지 입력 가능합니다")
            }
        } else {
            if decimalPlaces > 8 {
                return (false, "ETH는 최대 소수점 여덟째 자리까지 입력 가능합니다")
            }
        }
        
        return (true, nil)
    }
    
    private func getDecimalPlaces(from decimal: Decimal) -> Int {
        let decimalString = String(describing: decimal)
        
        if let dotIndex = decimalString.firstIndex(of: ".") {
            return decimalString.distance(from: dotIndex, to: decimalString.endIndex) - 1
        }
        
        return 0
    }
    
    // MARK: - Address Formatting
    
    /// Format Ethereum address for display
    func formatAddress(_ address: String, style: AddressDisplayStyle = .truncated) -> String {
        guard address.count >= 10 else { return address }
        
        switch style {
        case .truncated:
            return String(address.prefix(6)) + "..." + String(address.suffix(4))
        case .middle:
            return String(address.prefix(10)) + "..." + String(address.suffix(10))
        case .full:
            return address
        }
    }
    
    /// Validate and format address input
    func processAddressInput(_ input: String) -> (address: String, isValid: Bool, errorMessage: String?) {
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if empty
        if trimmedInput.isEmpty {
            return (address: trimmedInput, isValid: false, errorMessage: nil)
        }
        
        // Check basic Ethereum address format
        let ethereumAddressPattern = "^0x[a-fA-F0-9]{40}$"
        let regex = try? NSRegularExpression(pattern: ethereumAddressPattern)
        let range = NSRange(location: 0, length: trimmedInput.count)
        let isValidFormat = regex?.firstMatch(in: trimmedInput, range: range) != nil
        
        if !isValidFormat {
            // Check if it might be an ENS domain
            if trimmedInput.contains(".eth") {
                // TODO: Handle ENS resolution
                return (address: trimmedInput, isValid: false, errorMessage: "ENS 도메인은 아직 지원되지 않습니다")
            }
            
            return (address: trimmedInput, isValid: false, errorMessage: "올바른 이더리움 주소 형식이 아닙니다")
        }
        
        return (address: trimmedInput, isValid: true, errorMessage: nil)
    }
}

// MARK: - Supporting Types

enum AddressDisplayStyle {
    case truncated  // 0x1234...abcd
    case middle     // 0x1234567890...1234567890
    case full       // Full address
}

// MARK: - Currency Conversion Extension

extension SendPresenter {
    /// Convert between ETH and USD amounts
    func convertCurrency(amount: String, from: CurrencyType, to: CurrencyType) -> String? {
        guard let amountDecimal = Decimal(string: amount) else { return nil }
        
        let convertedAmount: Decimal
        
        switch (from, to) {
        case (.ETH, .USD):
            convertedAmount = convertETHToUSD(amountDecimal)
        case (.USD, .ETH):
            convertedAmount = convertUSDToETH(amountDecimal)
        case (.ETH, .ETH), (.USD, .USD):
            convertedAmount = amountDecimal // No conversion needed
        }
        
        // Format the converted amount
        switch to {
        case .ETH:
            return String(format: "%.6f", NSDecimalNumber(decimal: convertedAmount).doubleValue)
        case .USD:
            return String(format: "%.2f", NSDecimalNumber(decimal: convertedAmount).doubleValue)
        }
    }
    
    /// Get current exchange rate
    func getCurrentExchangeRate() -> Decimal {
        return currentETHPrice
    }
    
    /// Format exchange rate for display
    func formatExchangeRate() -> String {
        return "1 ETH = " + formatUSDAmount(currentETHPrice)
    }
}

enum CurrencyType {
    case ETH
    case USD
}