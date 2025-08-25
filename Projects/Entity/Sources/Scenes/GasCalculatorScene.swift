import Foundation

/// 가스 계산기 Scene의 VIP 모델들
public enum GasCalculatorScene {
    
    // MARK: - Use Cases
    
    public enum CalculateCost {
        public struct Request {
            public let transactionType: TransactionType
            public let priorityFee: Double
            public let customGasLimit: Int?
            
            public init(transactionType: TransactionType, priorityFee: Double, customGasLimit: Int? = nil) {
                self.transactionType = transactionType
                self.priorityFee = priorityFee
                self.customGasLimit = customGasLimit
            }
        }
        
        public struct Response {
            public let cost: TransactionCost
            public let ethPrice: Double
            
            public init(cost: TransactionCost, ethPrice: Double) {
                self.cost = cost
                self.ethPrice = ethPrice
            }
        }
        
        public struct ViewModel {
            public let transactionTypeName: String
            public let gasLimit: String
            public let baseFee: String
            public let priorityFee: String
            public let totalGwei: String
            public let totalETH: String
            public let totalUSD: String
            public let formattedETH: String
            public let formattedUSD: String
            
            public init(
                transactionTypeName: String,
                gasLimit: String,
                baseFee: String,
                priorityFee: String,
                totalGwei: String,
                totalETH: String,
                totalUSD: String,
                formattedETH: String,
                formattedUSD: String
            ) {
                self.transactionTypeName = transactionTypeName
                self.gasLimit = gasLimit
                self.baseFee = baseFee
                self.priorityFee = priorityFee
                self.totalGwei = totalGwei
                self.totalETH = totalETH
                self.totalUSD = totalUSD
                self.formattedETH = formattedETH
                self.formattedUSD = formattedUSD
            }
        }
    }
    
    public enum UpdateTransactionType {
        public struct Request {
            public let transactionType: TransactionType
            
            public init(transactionType: TransactionType) {
                self.transactionType = transactionType
            }
        }
        
        public struct Response {
            public let transactionType: TransactionType
            
            public init(transactionType: TransactionType) {
                self.transactionType = transactionType
            }
        }
        
        public struct ViewModel {
            public let transactionTypeName: String
            public let gasLimit: String
            
            public init(transactionTypeName: String, gasLimit: String) {
                self.transactionTypeName = transactionTypeName
                self.gasLimit = gasLimit
            }
        }
    }
    
    public enum UpdatePriorityFee {
        public struct Request {
            public let priorityFee: Double
            
            public init(priorityFee: Double) {
                self.priorityFee = priorityFee
            }
        }
        
        public struct Response {
            public let priorityFee: Double
            
            public init(priorityFee: Double) {
                self.priorityFee = priorityFee
            }
        }
        
        public struct ViewModel {
            public let priorityFee: String
            public let formattedPriorityFee: String
            
            public init(priorityFee: String, formattedPriorityFee: String) {
                self.priorityFee = priorityFee
                self.formattedPriorityFee = formattedPriorityFee
            }
        }
    }
}

// MARK: - Transaction Types (Open/Closed Principle)

public protocol TransactionType: Sendable {
    var gasLimit: Int { get }
    var name: String { get }
    var icon: String { get }
}

public struct ETHTransfer: TransactionType {
    public let gasLimit = 21000
    public let name = "ETH 송금"
    public let icon = "arrow.up.circle"
    
    public init() {}
}

public struct TokenTransfer: TransactionType {
    public let gasLimit = 65000
    public let name = "토큰 전송" 
    public let icon = "dollarsign.circle"
    
    public init() {}
}

public struct UniswapSwap: TransactionType {
    public let gasLimit = 150000
    public let name = "Uniswap 스왑"
    public let icon = "arrow.triangle.2.circlepath"
    
    public init() {}
}

public struct NFTMinting: TransactionType {
    public let gasLimit = 200000
    public let name = "NFT 민팅"
    public let icon = "photo.artframe"
    
    public init() {}
}

public struct CustomTransaction: TransactionType {
    public let gasLimit: Int
    public let name = "커스텀"
    public let icon = "slider.horizontal.3"
    
    public init(gasLimit: Int) {
        self.gasLimit = gasLimit
    }
}

// MARK: - Core Models

public struct TransactionCost {
    public let gasLimit: Int
    public let baseFee: Double
    public let priorityFee: Double
    public let ethPrice: Double
    
    public init(gasLimit: Int, baseFee: Double, priorityFee: Double, ethPrice: Double) {
        self.gasLimit = gasLimit
        self.baseFee = baseFee
        self.priorityFee = priorityFee
        self.ethPrice = ethPrice
    }
    
    // Computed properties for Single Responsibility
    public var totalGwei: Double {
        return Double(gasLimit) * (baseFee + priorityFee)
    }
    
    public var totalETH: Double {
        return totalGwei / 1_000_000_000.0 // Convert Gwei to ETH
    }
    
    public var totalUSD: Double {
        return totalETH * ethPrice
    }
    
    // Formatted strings for presentation
    public var formattedETH: String {
        return String(format: "%.6f ETH", totalETH)
    }
    
    public var formattedUSD: String {
        return String(format: "$%.2f", totalUSD)
    }
    
    public var formattedGwei: String {
        return String(format: "%.0f Gwei", totalGwei)
    }
}

// MARK: - Available Transaction Types

public final class TransactionTypeFactory: @unchecked Sendable {
    public static let availableTypes: [TransactionType] = [
        ETHTransfer(),
        TokenTransfer(),
        UniswapSwap(),
        NFTMinting()
    ]
    
    public static func createCustom(gasLimit: Int) -> TransactionType {
        return CustomTransaction(gasLimit: gasLimit)
    }
}