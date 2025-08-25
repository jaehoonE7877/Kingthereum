import Foundation
import BigInt
@testable import Kingthereum
@testable import DesignSystem

// MARK: - Test-Only SendWorker Extension
// 테스트 전용 SendWorker 확장 - 프로덕션 코드와 분리

/// 테스트 전용 SendWorker 구현체
final class TestSendWorker: SendWorkerProtocol {
    
    // MARK: - Mock Dependencies (SOLID 원칙 적용)
    private let addressValidator: MockAddressValidatorProtocol
    private let balanceProvider: MockBalanceProviderProtocol
    private let gasEstimator: MockGasEstimatorProtocol
    private let biometricAuth: MockBiometricAuthenticatorProtocol
    private let transactionSender: MockTransactionSenderProtocol
    
    init(
        addressValidator: MockAddressValidatorProtocol,
        balanceProvider: MockBalanceProviderProtocol,
        gasEstimator: MockGasEstimatorProtocol,
        biometricAuth: MockBiometricAuthenticatorProtocol,
        transactionSender: MockTransactionSenderProtocol
    ) {
        self.addressValidator = addressValidator
        self.balanceProvider = balanceProvider
        self.gasEstimator = gasEstimator
        self.biometricAuth = biometricAuth
        self.transactionSender = transactionSender
    }
    
    // MARK: - SendWorkerProtocol Implementation
    
    func validateEthereumAddress(_ address: String) -> Bool {
        return addressValidator.isValidEthereumAddress(address)
    }
    
    func getCurrentBalance() -> Decimal {
        return Task {
            await balanceProvider.getCurrentBalance()
        }.result.get() ?? Decimal(0)
    }
    
    func isBalanceSufficient(amount: Decimal, includingGasFee gasFee: Decimal) -> Bool {
        return Task {
            await balanceProvider.isBalanceSufficient(amount: amount, includingGasFee: gasFee)
        }.result.get() ?? false
    }
    
    func estimateGasFee(recipientAddress: String, amount: String) -> Send.GasOptions? {
        return Task {
            await gasEstimator.estimateGasFee(recipientAddress: recipientAddress, amount: amount)
        }.result.get() ?? nil
    }
    
    func prepareTransaction(recipientAddress: String, amount: Decimal, gasFee: Send.GasFee) -> Send.Transaction? {
        return Task {
            await transactionSender.prepareTransaction(recipientAddress: recipientAddress, amount: amount, gasFee: gasFee)
        }.result.get() ?? nil
    }
    
    func authenticateWithBiometric() async -> Bool {
        return await biometricAuth.authenticateWithBiometric()
    }
    
    func sendTransaction(_ transaction: Send.Transaction) async -> Result<String, Error> {
        return await transactionSender.sendTransaction(transaction)
    }
}

// MARK: - Task Result Extension for Sync/Async Bridge
extension Task where Success: Sendable, Failure == Never {
    var result: Result<Success, Error> {
        if Task.isCancelled {
            return .failure(CancellationError())
        }
        
        do {
            let value = try Task.detached { await self.value }.result.get()
            return .success(value)
        } catch {
            return .failure(error)
        }
    }
}

extension Task where Success: Sendable, Failure: Error {
    var result: Result<Success, Failure> {
        if Task.isCancelled {
            return .failure(CancellationError() as! Failure)
        }
        
        return Task.detached { try await self.value }.result
    }
}