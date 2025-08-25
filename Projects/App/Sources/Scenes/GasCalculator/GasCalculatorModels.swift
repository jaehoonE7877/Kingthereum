import Foundation
import Core
import Entity

/// Gas Calculator에서 사용하는 TransactionType은 LocalTransactionType
typealias GasTransactionType = LocalTransactionType

enum GasCalculator {
    
    // MARK: - Use Cases
    
    enum CalculateCost {
        struct Request {
            let transactionType: GasTransactionType
            let priorityFee: Double
            let customGasLimit: Int?
        }
        
        struct Response {
            let cost: TransactionCost
            let ethPrice: Double
        }
        
        struct ViewModel {
            let transactionTypeName: String
            let gasLimit: String
            let baseFee: String
            let priorityFee: String
            let totalGwei: String
            let totalETH: String
            let totalUSD: String
            let formattedETH: String
            let formattedUSD: String
        }
    }
    
    enum UpdateTransactionType {
        struct Request {
            let transactionType: GasTransactionType
        }
        
        struct Response {
            let transactionType: GasTransactionType
        }
        
        struct ViewModel {
            let transactionTypeName: String
            let gasLimit: String
        }
    }
    
    enum UpdatePriorityFee {
        struct Request {
            let priorityFee: Double
        }
        
        struct Response {
            let priorityFee: Double
        }
        
        struct ViewModel {
            let priorityFee: String
            let formattedPriorityFee: String
        }
    }
}

// MARK: - Transaction Types (Open/Closed Principle)

protocol LocalTransactionType: Sendable {
    var gasLimit: Int { get }
    var name: String { get }
    var icon: String { get }
}

struct ETHTransfer: LocalTransactionType {
    let gasLimit = 21000
    let name = "ETH 송금"
    let icon = "arrow.up.circle"
}

struct TokenTransfer: LocalTransactionType {
    let gasLimit = 65000
    let name = "토큰 전송" 
    let icon = "dollarsign.circle"
}

struct UniswapSwap: LocalTransactionType {
    let gasLimit = 150000
    let name = "Uniswap 스왑"
    let icon = "arrow.triangle.2.circlepath"
}

struct NFTMinting: LocalTransactionType {
    let gasLimit = 200000
    let name = "NFT 민팅"
    let icon = "photo.artframe"
}

struct CustomTransaction: LocalTransactionType {
    let gasLimit: Int
    let name = "커스텀"
    let icon = "slider.horizontal.3"
    
    init(gasLimit: Int) {
        self.gasLimit = gasLimit
    }
}

// MARK: - Core Models

struct TransactionCost {
    let gasLimit: Int
    let baseFee: Double
    let priorityFee: Double
    let ethPrice: Double
    
    // Computed properties for Single Responsibility
    var totalGwei: Double {
        return Double(gasLimit) * (baseFee + priorityFee)
    }
    
    var totalETH: Double {
        return totalGwei / 1_000_000_000.0 // Convert Gwei to ETH
    }
    
    var totalUSD: Double {
        return totalETH * ethPrice
    }
    
    // Formatted strings for presentation
    var formattedETH: String {
        return String(format: "%.6f ETH", totalETH)
    }
    
    var formattedUSD: String {
        return String(format: "$%.2f", totalUSD)
    }
    
    var formattedGwei: String {
        return String(format: "%.0f Gwei", totalGwei)
    }
}

// MARK: - Available Transaction Types

final class TransactionTypeFactory: @unchecked Sendable {
    static let availableTypes: [LocalTransactionType] = [
        ETHTransfer(),
        TokenTransfer(),
        UniswapSwap(),
        NFTMinting()
    ]
    
    static func createCustom(gasLimit: Int) -> LocalTransactionType {
        return CustomTransaction(gasLimit: gasLimit)
    }
}