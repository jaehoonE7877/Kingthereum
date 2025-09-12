import Foundation
import Core
import Entity
import WalletKit

// MARK: - Send Worker Protocol

/// Send 기능을 위한 비즈니스 로직 처리 프로토콜
@MainActor
protocol SendWorkerProtocol {
    /// 이더리움 주소 유효성 검증
    func validateEthereumAddress(_ address: String) -> Bool
    
    /// 거래 금액 유효성 검증
    func validateAmount(_ amount: Double, balance: Double) -> Bool
    
    /// 가스비 계산
    func calculateGasFee(gasPrice: String, gasLimit: String) -> Double?
    
    /// 거래 전송
    func sendTransaction(
        to address: String,
        amount: Double,
        gasPrice: String,
        gasLimit: String,
        privateKey: String
    ) async throws -> String
    
    /// 가스 옵션 생성
    func createGasOptions(baseGasPrice: String, gasLimit: String) async -> GasOptions
    
    /// ETH 가격 조회
    func fetchETHPrice() async throws -> Decimal
    
    /// 거래 안전성 검증
    func validateTransactionSafety(transaction: PendingTransaction) async -> Bool
}

// MARK: - Send Worker Implementation

/// Send 기능의 실제 비즈니스 로직 구현체
@MainActor
final class SendWorker: SendWorkerProtocol {
    
    // MARK: - Dependencies
    
    private let walletService: WalletServiceProtocol
    
    // MARK: - Initialization
    
    init(walletService: WalletServiceProtocol) {
        self.walletService = walletService
    }
    
    // MARK: - Address Validation
    
    /// 이더리움 주소 유효성 검증
    func validateEthereumAddress(_ address: String) -> Bool {
        // 1. 기본 형식 검증
        guard address.hasPrefix("0x") else { return false }
        
        // 2. 길이 검증 (0x + 40글자 = 42글자)
        guard address.count == 42 else { return false }
        
        // 3. 16진수 문자 검증
        let hexString = String(address.dropFirst(2))
        let hexCharacterSet = CharacterSet(charactersIn: "0123456789ABCDEFabcdef")
        return hexString.unicodeScalars.allSatisfy { hexCharacterSet.contains($0) }
    }
    
    // MARK: - Amount Validation
    
    /// 거래 금액 유효성 검증
    func validateAmount(_ amount: Double, balance: Double) -> Bool {
        // 1. 양수 검증
        guard amount > 0 else { return false }
        
        // 2. 잔액 충분성 검증
        guard amount <= balance else { return false }
        
        // 3. 최소 거래 금액 검증 (0.000001 ETH)
        guard amount >= 0.000001 else { return false }
        
        return true
    }
    
    // MARK: - Gas Calculation
    
    /// 가스비 계산
    func calculateGasFee(gasPrice: String, gasLimit: String) -> Double? {
        guard let gasPriceWei = Double(gasPrice),
              let gasLimitValue = Double(gasLimit) else {
            return nil
        }
        
        // Wei를 ETH로 변환 (1 ETH = 10^18 Wei)
        let gasFeeWei = gasPriceWei * gasLimitValue
        let gasFeeETH = gasFeeWei / pow(10, 18)
        
        return gasFeeETH
    }
    
    // MARK: - Transaction Sending
    
    /// 거래 전송
    func sendTransaction(
        to address: String,
        amount: Double,
        gasPrice: String,
        gasLimit: String,
        privateKey: String
    ) async throws -> String {
        
        // WalletService를 통해 실제 거래 전송
        // 현재 WalletService에 sendTransaction 메서드가 없으므로 
        // 향후 구현 예정
        throw WalletError.transactionFailed
    }
    
    // MARK: - SendWorkerLogic Implementation (통합된 메서드들)
    
    /// 가스 옵션 생성
    func createGasOptions(baseGasPrice: String, gasLimit: String) async -> GasOptions {
        Logger.debug("⛽ [SendWorker] Creating gas options with base price: \(baseGasPrice)")
        
        guard let basePriceDecimal = Decimal(string: baseGasPrice),
              let gasLimitDecimal = Decimal(string: gasLimit) else {
            Logger.error("❌ [SendWorker] Invalid gas price or limit format")
            return createFallbackGasOptions()
        }
        
        // Convert gas price from Wei to Gwei for calculations
        let basePriceGwei = basePriceDecimal / Decimal(pow(10.0, 9))
        
        // Create different speed options
        let slowMultiplier = Decimal(0.85) // 15% lower
        let normalMultiplier = Decimal(1.0) // Base price
        let fastMultiplier = Decimal(1.3)   // 30% higher
        
        let slowPriceGwei = basePriceGwei * slowMultiplier
        let normalPriceGwei = basePriceGwei * normalMultiplier
        let fastPriceGwei = basePriceGwei * fastMultiplier
        
        // Convert back to Wei
        let slowPriceWei = slowPriceGwei * Decimal(pow(10.0, 9))
        let normalPriceWei = normalPriceGwei * Decimal(pow(10.0, 9))
        let fastPriceWei = fastPriceGwei * Decimal(pow(10.0, 9))
        
        // Calculate fees in ETH
        let slowFeeETH = (slowPriceWei * gasLimitDecimal) / Decimal(pow(10.0, 18))
        let normalFeeETH = (normalPriceWei * gasLimitDecimal) / Decimal(pow(10.0, 18))
        let fastFeeETH = (fastPriceWei * gasLimitDecimal) / Decimal(pow(10.0, 18))
        
        // Get ETH price for USD conversion
        let ethPriceUSD = await getETHPriceForCalculation()
        
        let slowFeeUSD = slowFeeETH * ethPriceUSD
        let normalFeeUSD = normalFeeETH * ethPriceUSD
        let fastFeeUSD = fastFeeETH * ethPriceUSD
        
        // Create gas fee objects
        let slowGas = GasFee(
            gasPrice: String(describing: slowPriceWei),
            estimatedTime: 420, // 7 minutes
            feeInETH: slowFeeETH,
            feeInUSD: slowFeeUSD
        )
        
        let normalGas = GasFee(
            gasPrice: String(describing: normalPriceWei),
            estimatedTime: 180, // 3 minutes
            feeInETH: normalFeeETH,
            feeInUSD: normalFeeUSD
        )
        
        let fastGas = GasFee(
            gasPrice: String(describing: fastPriceWei),
            estimatedTime: 90, // 1.5 minutes
            feeInETH: fastFeeETH,
            feeInUSD: fastFeeUSD
        )
        
        return GasOptions(slow: slowGas, normal: normalGas, fast: fastGas)
    }
    
    /// ETH 가격 조회
    func fetchETHPrice() async throws -> Decimal {
        Logger.debug("💰 [SendWorker] Fetching ETH price")
        
        // For now, return a mock price - replace with actual API call
        return Decimal(2500.0)
    }
    
    /// 거래 안전성 검증
    func validateTransactionSafety(transaction: PendingTransaction) async -> Bool {
        Logger.debug("🛡️ [SendWorker] Validating transaction safety")
        
        // Basic safety checks
        guard !transaction.recipientAddress.isEmpty,
              transaction.amount > 0,
              !transaction.gasPrice.isEmpty,
              !transaction.gasLimit.isEmpty else {
            return false
        }
        
        // Check if gas price is reasonable (not too high)
        if let gasPriceDecimal = Decimal(string: transaction.gasPrice) {
            let maxReasonableGasPrice = Decimal(100) * Decimal(pow(10.0, 9)) // 100 Gwei in Wei
            if gasPriceDecimal > maxReasonableGasPrice {
                Logger.warning("⚠️ [SendWorker] Gas price seems too high: \(gasPriceDecimal)")
                return false
            }
        }
        
        return true
    }
    
    // MARK: - Private Helpers
    
    private func createFallbackGasOptions() -> GasOptions {
        Logger.debug("🔄 [SendWorker] Creating fallback gas options")
        
        let slowGas = GasFee(
            gasPrice: "20000000000", // 20 Gwei in Wei
            estimatedTime: 420,
            feeInETH: Decimal(string: "0.00042")!,
            feeInUSD: Decimal(string: "1.05")!
        )
        
        let normalGas = GasFee(
            gasPrice: "25000000000", // 25 Gwei in Wei
            estimatedTime: 180,
            feeInETH: Decimal(string: "0.000525")!,
            feeInUSD: Decimal(string: "1.31")!
        )
        
        let fastGas = GasFee(
            gasPrice: "35000000000", // 35 Gwei in Wei
            estimatedTime: 90,
            feeInETH: Decimal(string: "0.000735")!,
            feeInUSD: Decimal(string: "1.84")!
        )
        
        return GasOptions(slow: slowGas, normal: normalGas, fast: fastGas)
    }
    
    private func getETHPriceForCalculation() async -> Decimal {
        do {
            return try await fetchETHPrice()
        } catch {
            Logger.warning("⚠️ [SendWorker] Using fallback ETH price for gas calculation")
            return Decimal(2500.0)
        }
    }
}

// MARK: - Validation Helpers

extension SendWorker {
    
    /// 체크섬 주소 검증 (EIP-55)
    private func isValidChecksumAddress(_ address: String) -> Bool {
        // EIP-55 체크섬 검증 로직
        // 현재는 기본 형식 검증만 수행
        return validateEthereumAddress(address)
    }
    
    /// ENS 도메인 검증
    private func isValidENSDomain(_ domain: String) -> Bool {
        // ENS 도메인 형식 검증
        return domain.hasSuffix(".eth") && domain.count > 4
    }
}
