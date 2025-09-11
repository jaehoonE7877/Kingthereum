import Foundation

import Core
import Entity

import BigInt
import Factory
import Web3Core


// MARK: - Send Worker Protocol

protocol SendWorkerProtocol: Sendable {
    func validateEthereumAddress(_ address: String) -> Bool
    func getCurrentBalance() async -> Decimal
    func validateAmount(amount: String, availableBalance: String) async -> (isValid: Bool, errorMessage: String?, parsedAmount: Decimal?)
    func isBalanceSufficient(amount: Decimal, includingGasFee gasFee: Decimal) async -> Bool
    func estimateGasFee(recipientAddress: String, amount: String) async -> Entity.GasOptions?
    func prepareTransaction(recipientAddress: String, amount: Decimal, gasFee: Entity.GasFee) async -> Entity.PendingTransaction?
    func sendTransaction(_ transaction: Entity.PendingTransaction) async -> Result<String, Error>
}

// MARK: - Send Worker Implementation

actor SendWorker: SendWorkerProtocol {
    
    // MARK: - Dependencies
    @Injected(\.walletService) private var walletService
    @Injected(\.etherscanService) private var etherscanService
    
    // MARK: - Private Properties
    private var currentBalance: Decimal = 0
    private var gasEstimateCache: [String: Entity.GasOptions] = [:]
    
    // MARK: - Address Validation
    
    nonisolated func validateEthereumAddress(_ address: String) -> Bool {
        // 기본 이더리움 주소 검증
        guard address.hasPrefix("0x"),
              address.count == 42 else {
            return false
        }
        
        // Hex 문자열 검증
        let hex = String(address.dropFirst(2))
        return hex.allSatisfy { $0.isHexDigit }
    }
    
    // MARK: - Balance Management
    
    func getCurrentBalance() async -> Decimal {
        // 실제 구현에서는 walletService를 통해 잔액 조회
        // 현재는 모의 값 반환
        return 10.5
    }
    
    func isBalanceSufficient(amount: Decimal, includingGasFee gasFee: Decimal) async -> Bool {
        let balance = await getCurrentBalance()
        let totalRequired = amount + gasFee
        return balance >= totalRequired
    }
    
    // MARK: - Amount Validation
    
    func validateAmount(amount: String, availableBalance: String) async -> (isValid: Bool, errorMessage: String?, parsedAmount: Decimal?) {
        // 빈 값 체크
        guard !amount.isEmpty else {
            return (false, "금액을 입력해주세요", nil)
        }
        
        // 숫자 변환 시도
        guard let amountDecimal = Decimal(string: amount),
              amountDecimal > 0 else {
            return (false, "올바른 금액을 입력해주세요", nil)
        }
        
        // 잔액 체크
        guard let balance = Decimal(string: availableBalance) else {
            return (false, "잔액을 확인할 수 없습니다", nil)
        }
        
        if amountDecimal > balance {
            return (false, "잔액이 부족합니다", nil)
        }
        
        // 최소 금액 체크 (0.000001 ETH)
        let minimumAmount = Decimal(string: "0.000001") ?? 0
        if amountDecimal < minimumAmount {
            return (false, "최소 송금 금액은 0.000001 ETH입니다", nil)
        }
        
        return (true, nil, amountDecimal)
    }
    
    // MARK: - Gas Estimation
    
    func estimateGasFee(recipientAddress: String, amount: String) async -> Entity.GasOptions? {
        // 캐시 확인
        let cacheKey = "\(recipientAddress)_\(amount)"
        if let cached = gasEstimateCache[cacheKey] {
            return cached
        }
        
        // 모의 가스 옵션 생성
        let slowGas = Entity.GasFee(
            gasPrice: "10000000000", // 10 Gwei
            estimatedTime: 600, // 10분
            feeInETH: 0.0021,
            feeInUSD: 5.25
        )
        
        let normalGas = Entity.GasFee(
            gasPrice: "20000000000", // 20 Gwei  
            estimatedTime: 180, // 3분
            feeInETH: 0.0042,
            feeInUSD: 10.50
        )
        
        let fastGas = Entity.GasFee(
            gasPrice: "30000000000", // 30 Gwei
            estimatedTime: 60, // 1분
            feeInETH: 0.0063,
            feeInUSD: 15.75
        )
        
        let options = Entity.GasOptions(
            slow: slowGas,
            normal: normalGas,
            fast: fastGas
        )
        
        // 캐시 저장
        gasEstimateCache[cacheKey] = options
        
        return options
    }
    
    // MARK: - Transaction Preparation
    
    func prepareTransaction(recipientAddress: String, amount: Decimal, gasFee: Entity.GasFee) async -> Entity.PendingTransaction? {
        // 주소 검증
        guard validateEthereumAddress(recipientAddress) else {
            return nil
        }
        
        // 잔액 확인
        let balance = await getCurrentBalance()
        let totalRequired = amount + gasFee.feeInETH
        guard balance >= totalRequired else {
            return nil
        }
        
        // Nonce 생성 (실제로는 블록체인에서 조회)
        let nonce = String(Int.random(in: 1...999999))
        
        // 트랜잭션 생성
        let transaction = Entity.PendingTransaction(
            recipientAddress: recipientAddress,
            amount: amount,
            gasPrice: gasFee.gasPrice,
            gasLimit: "21000", // 기본 이더 전송 가스 한계
            nonce: nonce
        )
        
        return transaction
    }
    
    // MARK: - Transaction Sending
    
    func sendTransaction(_ transaction: Entity.PendingTransaction) async -> Result<String, Error> {
        // 실제 구현에서는 Web3 라이브러리를 통해 트랜잭션 전송
        // 현재는 모의 구현
        
        // 트랜잭션 검증
        guard validateEthereumAddress(transaction.recipientAddress) else {
            return .failure(SendError.invalidAddress)
        }
        
        guard transaction.amount > 0 else {
            return .failure(SendError.invalidAmount)
        }
        
        // 모의 지연
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2초
        
        // 모의 트랜잭션 해시 생성
        let transactionHash = "0x" + UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        
        return .success(transactionHash)
    }
    
    // MARK: - Helper Methods
    
    private func clearGasCache() {
        gasEstimateCache.removeAll()
    }
    
    private func updateBalance(_ newBalance: Decimal) {
        currentBalance = newBalance
    }
}

// MARK: - Send Error

enum SendError: LocalizedError {
    case invalidAddress
    case invalidAmount
    case insufficientBalance
    case networkError
    case transactionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidAddress:
            return "유효하지 않은 이더리움 주소입니다"
        case .invalidAmount:
            return "유효하지 않은 금액입니다"
        case .insufficientBalance:
            return "잔액이 부족합니다"
        case .networkError:
            return "네트워크 오류가 발생했습니다"
        case .transactionFailed(let reason):
            return "거래 실패: \(reason)"
        }
    }
}

// MARK: - Mock Send Worker (For Testing)

actor MockSendWorker: SendWorkerProtocol {
    
    nonisolated func validateEthereumAddress(_ address: String) -> Bool {
        return address.hasPrefix("0x") && address.count == 42
    }
    
    func getCurrentBalance() async -> Decimal {
        return 100.0
    }
    
    func validateAmount(amount: String, availableBalance: String) async -> (isValid: Bool, errorMessage: String?, parsedAmount: Decimal?) {
        guard let parsedAmount = Decimal(string: amount) else {
            return (false, "잘못된 금액 형식입니다", nil)
        }
        
        guard parsedAmount > 0 else {
            return (false, "0보다 큰 금액을 입력해주세요", nil)
        }
        
        guard let balance = Decimal(string: availableBalance), parsedAmount <= balance else {
            return (false, "잔액이 부족합니다", nil)
        }
        
        return (true, nil, parsedAmount)
    }
    
    func isBalanceSufficient(amount: Decimal, includingGasFee gasFee: Decimal) async -> Bool {
        let balance = await getCurrentBalance()
        return balance >= (amount + gasFee)
    }
    
    func estimateGasFee(recipientAddress: String, amount: String) async -> Entity.GasOptions? {
        let fee = Entity.GasFee(
            gasPrice: "20000000000",
            estimatedTime: 180,
            feeInETH: 0.002,
            feeInUSD: 5.0
        )
        
        return Entity.GasOptions(slow: fee, normal: fee, fast: fee)
    }
    
    func prepareTransaction(recipientAddress: String, amount: Decimal, gasFee: Entity.GasFee) async -> Entity.PendingTransaction? {
        return Entity.PendingTransaction(
            recipientAddress: recipientAddress,
            amount: amount,
            gasPrice: gasFee.gasPrice,
            gasLimit: "21000",
            nonce: "1"
        )
    }
    
    func sendTransaction(_ transaction: Entity.PendingTransaction) async -> Result<String, Error> {
        return .success("0xmocktransactionhash123456789")
    }
}
