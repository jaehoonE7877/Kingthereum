import Foundation
import Entity
import Core
import WalletKit
import SecurityKit
import PriceKit
import Factory

// MARK: - Business Logic Protocol

@MainActor
protocol SendBusinessLogic: AnyObject {
    func validateAddress(request: SendScene.ValidateAddress.Request)
    func validateAmount(request: SendScene.ValidateAmount.Request)
    func estimateGas(request: SendScene.EstimateGas.Request)
    func prepareTransaction(request: SendScene.PrepareTransaction.Request)
    func sendTransaction(request: SendScene.SendTransaction.Request)
    func loadETHPrice()
}

// MARK: - Send Interactor

@MainActor
final class SendInteractor: SendBusinessLogic {
    var presenter: SendPresentationLogic?
    private(set) lazy var worker: SendWorkerProtocol = SendWorker(walletService: walletService)
    
    @Injected(\.walletService) private var walletService: WalletServiceProtocol
    @Injected(\.securityService) private var securityService: SecurityServiceProtocol
    
    init() {
        // No need to initialize worker here as it's lazy
    }
    
    // MARK: - Address Validation
    
    func validateAddress(request: SendScene.ValidateAddress.Request) {
        Logger.debug("🔍 [SendInteractor] Validating address: \(request.address)")
        
        // Basic validation
        guard !request.address.isEmpty else {
            let response = SendScene.ValidateAddress.Response(
                isValid: false,
                errorMessage: "주소를 입력해주세요"
            )
            presenter?.presentAddressValidation(response: response)
            return
        }
        
        // Check Ethereum address format
        let isValidFormat = walletService.isValidEthereumAddress(request.address)
        
        if !isValidFormat {
            let response = SendScene.ValidateAddress.Response(
                isValid: false,
                errorMessage: "올바른 이더리움 주소 형식이 아닙니다"
            )
            presenter?.presentAddressValidation(response: response)
            return
        }
        
        // Additional validation - check if it's not the user's own address
        Task {
            do {
                let currentAddress = try await walletService.getCurrentWalletAddress()
                
                if request.address.lowercased() == currentAddress.lowercased() {
                    let response = SendScene.ValidateAddress.Response(
                        isValid: false,
                        errorMessage: "자신의 지갑 주소로는 전송할 수 없습니다"
                    )
                    await MainActor.run {
                        presenter?.presentAddressValidation(response: response)
                    }
                    return
                }
                
                // Address is valid
                let response = SendScene.ValidateAddress.Response(
                    isValid: true,
                    errorMessage: nil
                )
                await MainActor.run {
                    presenter?.presentAddressValidation(response: response)
                }
                
            } catch {
                Logger.error("❌ [SendInteractor] Failed to get current wallet address: \(error)")
                let response = SendScene.ValidateAddress.Response(
                    isValid: false,
                    errorMessage: "지갑 주소 확인 중 오류가 발생했습니다"
                )
                await MainActor.run {
                    presenter?.presentAddressValidation(response: response)
                }
            }
        }
    }
    
    // MARK: - Amount Validation
    
    func validateAmount(request: SendScene.ValidateAmount.Request) {
        Logger.debug("🔍 [SendInteractor] Validating amount: \(request.amount) with balance: \(request.availableBalance)")
        
        // Basic validation
        guard !request.amount.isEmpty else {
            let response = SendScene.ValidateAmount.Response(
                isValid: false,
                errorMessage: "금액을 입력해주세요"
            )
            presenter?.presentAmountValidation(response: response)
            return
        }
        
        // Parse amount
        guard let amountDecimal = Decimal(string: request.amount), amountDecimal > 0 else {
            let response = SendScene.ValidateAmount.Response(
                isValid: false,
                errorMessage: "올바른 금액을 입력해주세요"
            )
            presenter?.presentAmountValidation(response: response)
            return
        }
        
        // Parse available balance
        guard let balanceDecimal = Decimal(string: request.availableBalance) else {
            let response = SendScene.ValidateAmount.Response(
                isValid: false,
                errorMessage: "잔액 정보를 확인할 수 없습니다"
            )
            presenter?.presentAmountValidation(response: response)
            return
        }
        
        // Check minimum amount (0.000001 ETH)
        let minimumAmount = Decimal(string: "0.000001")!
        if amountDecimal < minimumAmount {
            let response = SendScene.ValidateAmount.Response(
                isValid: false,
                errorMessage: "최소 전송 금액은 0.000001 ETH입니다"
            )
            presenter?.presentAmountValidation(response: response)
            return
        }
        
        // Estimate gas for balance check (reserve gas fee)
        let estimatedGasFee = Decimal(string: "0.005")! // 0.005 ETH estimated gas
        let requiredBalance = amountDecimal + estimatedGasFee
        
        if requiredBalance > balanceDecimal {
            let response = SendScene.ValidateAmount.Response(
                isValid: false,
                errorMessage: "잔액이 부족합니다 (가스비 포함)"
            )
            presenter?.presentAmountValidation(response: response)
            return
        }
        
        // Amount is valid
        let response = SendScene.ValidateAmount.Response(
            isValid: true,
            errorMessage: nil,
            parsedAmount: amountDecimal
        )
        presenter?.presentAmountValidation(response: response)
    }
    
    // MARK: - Gas Estimation
    
    func estimateGas(request: SendScene.EstimateGas.Request) {
        Logger.debug("⛽ [SendInteractor] Estimating gas for transaction")
        
        Task {
            do {
                // Get current wallet address
                _ = try await walletService.getCurrentWalletAddress()
                
                // Estimate gas limit
                let gasLimit = try await walletService.estimateGas(
                    to: request.recipientAddress,
                    amount: request.amount
                )
                
                // Get current gas prices
                let currentGasPrice = try await walletService.getCurrentGasPrice()
                
                // Create gas options based on current gas price
                let gasOptions = await worker.createGasOptions(
                    baseGasPrice: currentGasPrice,
                    gasLimit: gasLimit.gasLimit
                )
                
                let response = SendScene.EstimateGas.Response(
                    gasOptions: gasOptions,
                    estimatedGas: gasLimit.gasLimit,
                    error: nil
                )
                
                await MainActor.run {
                    presenter?.presentGasEstimation(response: response)
                }
                
            } catch {
                Logger.error("❌ [SendInteractor] Gas estimation failed: \(error)")
                
                let errorMessage: String
                if let walletError = error as? WalletError {
                    errorMessage = walletError.localizedDescription
                } else {
                    errorMessage = "가스비 계산 중 오류가 발생했습니다"
                }
                
                let response = SendScene.EstimateGas.Response(
                    gasOptions: nil,
                    estimatedGas: nil,
                    error: errorMessage
                )
                
                await MainActor.run {
                    presenter?.presentGasEstimation(response: response)
                }
            }
        }
    }
    
    // MARK: - Transaction Preparation
    
    func prepareTransaction(request: SendScene.PrepareTransaction.Request) {
        Logger.debug("📝 [SendInteractor] Preparing transaction")
        
        Task {
            do {
                // Get current wallet address and nonce
                _ = try await walletService.getCurrentWalletAddress()
                
                // Parse amount to proper format
                guard let amountDecimal = Decimal(string: request.amount) else {
                    throw WalletError.invalidAmount
                }
                
                // Create pending transaction
                let pendingTransaction = PendingTransaction(
                    recipientAddress: request.recipientAddress,
                    amount: amountDecimal,
                    gasPrice: request.selectedGasFee.gasPrice,
                    gasLimit: "21000", // Standard ETH transfer gas limit
                    nonce: "0" // Will be set by wallet service
                )
                
                let response = SendScene.PrepareTransaction.Response(
                    transaction: pendingTransaction,
                    isReadyToSend: true,
                    errorMessage: nil
                )
                
                await MainActor.run {
                    presenter?.presentTransactionPreparation(response: response)
                }
                
            } catch {
                Logger.error("❌ [SendInteractor] Transaction preparation failed: \(error)")
                
                let errorMessage: String
                if let walletError = error as? WalletError {
                    errorMessage = walletError.localizedDescription
                } else {
                    errorMessage = "거래 준비 중 오류가 발생했습니다"
                }
                
                let response = SendScene.PrepareTransaction.Response(
                    transaction: nil,
                    isReadyToSend: false,
                    errorMessage: errorMessage
                )
                
                await MainActor.run {
                    presenter?.presentTransactionPreparation(response: response)
                }
            }
        }
    }
    
    // MARK: - Send Transaction
    
    func sendTransaction(request: SendScene.SendTransaction.Request) {
        Logger.debug("🚀 [SendInteractor] Sending transaction")
        
        Task {
            do {
                // First, authenticate with biometric/PIN
                let authResult = try await securityService.authenticateForTransaction()
                
                guard authResult else {
                    let response = SendScene.SendTransaction.Response(
                        success: false,
                        transactionHash: nil,
                        errorMessage: "인증이 필요합니다"
                    )
                    await MainActor.run {
                        presenter?.presentTransactionResult(response: response)
                    }
                    return
                }
                
                // Convert decimal amount to string for wallet service
                let amountString = String(describing: request.transaction.amount)
                
                // Send transaction through wallet service
                let transactionHash = try await walletService.sendTransaction(
                    to: request.transaction.recipientAddress,
                    amount: amountString,
                    gasPrice: request.transaction.gasPrice,
                    gasLimit: request.transaction.gasLimit
                )
                
                Logger.info("✅ [SendInteractor] Transaction sent successfully: \(transactionHash)")
                
                let response = SendScene.SendTransaction.Response(
                    success: true,
                    transactionHash: transactionHash,
                    errorMessage: nil
                )
                
                await MainActor.run {
                    presenter?.presentTransactionResult(response: response)
                }
                
            } catch {
                Logger.error("❌ [SendInteractor] Transaction failed: \(error)")
                
                let errorMessage: String
                if let walletError = error as? WalletError {
                    switch walletError {
                    case .insufficientFunds:
                        errorMessage = "잔액이 부족합니다"
                    case .transactionFailed:
                        errorMessage = "거래 실행에 실패했습니다"
                    case .networkError:
                        errorMessage = "네트워크 오류가 발생했습니다"
                    default:
                        errorMessage = "거래 전송 중 오류가 발생했습니다"
                    }
                } else if let securityError = error as? SecurityError {
                    switch securityError {
                    case .authenticationFailed:
                        errorMessage = "인증에 실패했습니다"
                    case .biometricNotAvailable:
                        errorMessage = "생체 인증을 사용할 수 없습니다"
                    case .userCanceled:
                        errorMessage = "사용자가 취소했습니다"
                    default:
                        errorMessage = "인증 오류가 발생했습니다"
                    }
                } else {
                    errorMessage = error.localizedDescription
                }
                
                let response = SendScene.SendTransaction.Response(
                    success: false,
                    transactionHash: nil,
                    errorMessage: errorMessage
                )
                
                await MainActor.run {
                    presenter?.presentTransactionResult(response: response)
                }
            }
        }
    }
    
    // MARK: - Load ETH Price
    
    func loadETHPrice() {
        Logger.debug("💰 [SendInteractor] Loading ETH price")
        
        Task {
            do {
                let ethPrice = try await worker.fetchETHPrice()
                await MainActor.run {
                    presenter?.presentETHPrice(ethPrice: ethPrice)
                }
            } catch {
                Logger.error("❌ [SendInteractor] Failed to load ETH price: \(error)")
                // Use fallback price
                await MainActor.run {
                    presenter?.presentETHPrice(ethPrice: Decimal(2500.0))
                }
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func createDefaultGasOptions() -> GasOptions {
        // Default gas options as fallback
        let basePrice = Decimal(string: "20")! // 20 Gwei base
        
        let slowGas = GasFee(
            gasPrice: String(describing: basePrice * 0.8), // 16 Gwei
            estimatedTime: 300, // 5 minutes
            feeInETH: Decimal(string: "0.000336")!, // 21000 * 16 Gwei
            feeInUSD: Decimal(string: "0.84")! // Example USD value
        )
        
        let normalGas = GasFee(
            gasPrice: String(describing: basePrice), // 20 Gwei
            estimatedTime: 180, // 3 minutes
            feeInETH: Decimal(string: "0.00042")!, // 21000 * 20 Gwei
            feeInUSD: Decimal(string: "1.05")! // Example USD value
        )
        
        let fastGas = GasFee(
            gasPrice: String(describing: basePrice * 1.5), // 30 Gwei
            estimatedTime: 60, // 1 minute
            feeInETH: Decimal(string: "0.00063")!, // 21000 * 30 Gwei
            feeInUSD: Decimal(string: "1.58")! // Example USD value
        )
        
        return GasOptions(slow: slowGas, normal: normalGas, fast: fastGas)
    }
}



