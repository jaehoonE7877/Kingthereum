import Foundation
import BigInt
import LocalAuthentication
import DesignSystem
import Entity
import WalletKit
import Factory
// MARK: - Protocol

protocol SendWorkerProtocol: Sendable {
    func validateEthereumAddress(_ address: String) -> Bool
    func getCurrentBalance() -> Decimal
    func isBalanceSufficient(amount: Decimal, includingGasFee gasFee: Decimal) -> Bool
    func estimateGasFee(recipientAddress: String, amount: String) -> Entity.GasOptions?
    func prepareTransaction(recipientAddress: String, amount: Decimal, gasFee: Entity.GasFee) -> Entity.PendingTransaction?
    func authenticateWithBiometric() async -> Bool
    func sendTransaction(_ transaction: Entity.PendingTransaction) async -> Result<String, Error>
}

// MARK: - Implementation

final class SendWorker: SendWorkerProtocol {
    
    private let mockBalance: Decimal?
    private let walletService: any WalletServiceProtocol
    private let priceProvider: PriceProviderProtocol
    
    init(mockBalance: Decimal? = nil,
         walletService: (any WalletServiceProtocol)? = nil,
         priceProvider: PriceProviderProtocol = MockPriceProvider()) {
        self.mockBalance = mockBalance
        self.priceProvider = priceProvider
        
        // Factory DI를 사용한 안전한 의존성 주입
        if let walletService = walletService {
            self.walletService = walletService
        } else {
            // Container를 통한 안전한 의존성 해결
            self.walletService = Container.shared.walletService()
        }
    }
    
    // MARK: - Address Validation
    
    func validateEthereumAddress(_ address: String) -> Bool {
        // Basic Ethereum address validation
        let pattern = "^0x[a-fA-F0-9]{40}$"
        let regex = try! NSRegularExpression(pattern: pattern)
        return regex.firstMatch(in: address, range: NSRange(location: 0, length: address.count)) != nil
    }
    
    // MARK: - Balance Management
    
    func getCurrentBalance() -> Decimal {
        if let mockBalance = mockBalance {
            return mockBalance
        }
        
        // 실제 구현에서는 지갑에서 현재 ETH 잔액을 가져옴
        // UserDefaults나 Core Data, 또는 블록체인 API에서 조회
        let storedBalance = UserDefaults.standard.string(forKey: "eth_balance") ?? "0"
        return Decimal(string: storedBalance) ?? 0
    }
    
    func isBalanceSufficient(amount: Decimal, includingGasFee gasFee: Decimal) -> Bool {
        let currentBalance = getCurrentBalance()
        let totalRequired = amount + gasFee
        return currentBalance >= totalRequired
    }
    
    // MARK: - Gas Fee Estimation
    
    func estimateGasFee(recipientAddress: String, amount: String) -> Entity.GasOptions? {
        // 실제 구현에서는 Ethereum API를 호출하여 현재 네트워크 상태를 확인
        // 여기서는 Mock 데이터를 반환
        
        guard validateEthereumAddress(recipientAddress),
              Decimal(string: amount) != nil else {
            return nil
        }
        
        let ethPrice = priceProvider.getETHPriceInUSD()
        let baseGasLimit = BigUInt(21000) // 표준 ETH 전송
        
        // 현재 네트워크 상황에 따른 가스 가격 (Gwei 단위)
        let slowGasPrice = BigUInt(20) * BigUInt(1000000000) // 20 Gwei
        let normalGasPrice = BigUInt(25) * BigUInt(1000000000) // 25 Gwei  
        let fastGasPrice = BigUInt(35) * BigUInt(1000000000) // 35 Gwei
        
        let slowFee = calculateGasFee(gasPrice: slowGasPrice, gasLimit: baseGasLimit, ethPrice: ethPrice)
        let normalFee = calculateGasFee(gasPrice: normalGasPrice, gasLimit: baseGasLimit, ethPrice: ethPrice)
        let fastFee = calculateGasFee(gasPrice: fastGasPrice, gasLimit: baseGasLimit, ethPrice: ethPrice)
        
        return Entity.GasOptions(
            slow: Entity.GasFee(
                gasPrice: slowGasPrice.description,
                estimatedTime: 300, // 5분
                feeInETH: slowFee,
                feeInUSD: slowFee * ethPrice
            ),
            normal: Entity.GasFee(
                gasPrice: normalGasPrice.description,
                estimatedTime: 180, // 3분
                feeInETH: normalFee,
                feeInUSD: normalFee * ethPrice
            ),
            fast: Entity.GasFee(
                gasPrice: fastGasPrice.description,
                estimatedTime: 60, // 1분
                feeInETH: fastFee,
                feeInUSD: fastFee * ethPrice
            )
        )
    }
    
    private func calculateGasFee(gasPrice: BigUInt, gasLimit: BigUInt, ethPrice: Decimal) -> Decimal {
        let totalWei = gasPrice * gasLimit
        let ethAmount = Decimal(string: totalWei.description) ?? 0
        return ethAmount / pow(10, 18) // Wei를 ETH로 변환
    }
    
    // MARK: - Transaction Preparation
    
    func prepareTransaction(recipientAddress: String, amount: Decimal, gasFee: Entity.GasFee) -> Entity.PendingTransaction? {
        guard validateEthereumAddress(recipientAddress) else {
            return nil
        }
        
        guard amount > 0 else {
            return nil
        }
        
        guard isBalanceSufficient(amount: amount, includingGasFee: gasFee.feeInETH) else {
            return nil
        }
        
        // 실제 구현에서는 현재 계정의 nonce를 블록체인에서 조회
        let nonce = getCurrentNonce()
        
        return Entity.PendingTransaction(
            recipientAddress: recipientAddress,
            amount: amount,
            gasPrice: gasFee.gasPrice,
            gasLimit: "21000",
            nonce: nonce.description
        )
    }
    
    private func getCurrentNonce() -> BigUInt {
        // Mock implementation
        // 실제 구현에서는 Web3 라이브러리를 사용하여 현재 nonce를 조회
        return BigUInt(42)
    }
    
    // MARK: - Biometric Authentication
    
    func authenticateWithBiometric() async -> Bool {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            print("생체 인증을 사용할 수 없습니다: \(error?.localizedDescription ?? "알 수 없는 오류")")
            return false
        }
        
        do {
            let reason = "이더리움 거래를 승인하려면 인증이 필요합니다"
            let result = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
            return result
        } catch {
            print("생체 인증 실패: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Transaction Sending
    
    func sendTransaction(_ transaction: Entity.PendingTransaction) async -> Result<String, Error> {
        // Mock implementation for testing
        // 실제 구현에서는 Web3 라이브러리를 사용하여 Ethereum 네트워크에 거래를 전송
        
        // 2초 지연 시뮬레이션 (실제 네트워크 시간)
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        // 90% 확률로 성공하도록 시뮬레이션
        if Int.random(in: 1...10) <= 9 {
            let mockTransactionHash = generateMockTransactionHash()
            return .success(mockTransactionHash)
        } else {
            return .failure(SendError.transactionFailed("네트워크 오류로 인해 거래가 실패했습니다"))
        }
    }
    
    private func generateMockTransactionHash() -> String {
        let characters = "0123456789abcdef"
        let hash = "0x" + (0..<64).map { _ in
            String(characters.randomElement()!)
        }.joined()
        return hash
    }
}

// MARK: - Sendable Conformance

/// SendWorker가 Sendable을 준수하도록 확장
/// Worker는 보통 stateless하고 주입된 의존성들이 thread-safe하므로 안전
extension SendWorker: @unchecked Sendable {}

// MARK: - Supporting Protocols

protocol PriceProviderProtocol: Sendable {
    func getETHPriceInUSD() -> Decimal
}

struct MockPriceProvider: PriceProviderProtocol {
    func getETHPriceInUSD() -> Decimal {
        // Mock ETH price: $2,000
        return Decimal(2000)
    }
}

// 실제 구현에서는 CoinGecko API나 다른 가격 제공 서비스를 사용
struct CoinGeckoPriceProvider: PriceProviderProtocol {
    func getETHPriceInUSD() -> Decimal {
        // 실제 API 호출 구현 필요
        return Decimal(2000)
    }
}
