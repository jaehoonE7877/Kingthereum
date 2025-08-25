import Foundation

/// 절약 인사이트 Scene의 VIP 모델들
public enum SavingInsightsScene {
    
    // MARK: - Use Cases
    
    public enum GenerateInsights {
        public struct Request {
            public let currentGasPrice: GasPriceInfo
            public let transactionCost: TransactionCost?
            
            public init(currentGasPrice: GasPriceInfo, transactionCost: TransactionCost? = nil) {
                self.currentGasPrice = currentGasPrice
                self.transactionCost = transactionCost
            }
        }
        
        public struct Response {
            public let insight: SavingInsight
            public let networkStatus: NetworkStatus
            public let costComparison: CostComparison?
            
            public init(insight: SavingInsight, networkStatus: NetworkStatus, costComparison: CostComparison? = nil) {
                self.insight = insight
                self.networkStatus = networkStatus
                self.costComparison = costComparison
            }
        }
        
        public struct ViewModel {
            public let insightTitle: String
            public let insightMessage: String
            public let insightIcon: String
            public let insightColorName: String // Color를 String으로 변경 (Entity는 SwiftUI 의존성 없음)
            public let networkStatusText: String
            public let networkUsageText: String
            public let costComparisonText: String?
            public let recommendationText: String
            
            public init(
                insightTitle: String,
                insightMessage: String,
                insightIcon: String,
                insightColorName: String,
                networkStatusText: String,
                networkUsageText: String,
                costComparisonText: String? = nil,
                recommendationText: String
            ) {
                self.insightTitle = insightTitle
                self.insightMessage = insightMessage
                self.insightIcon = insightIcon
                self.insightColorName = insightColorName
                self.networkStatusText = networkStatusText
                self.networkUsageText = networkUsageText
                self.costComparisonText = costComparisonText
                self.recommendationText = recommendationText
            }
        }
    }
    
    public enum UpdateGasData {
        public struct Request {
            public let gasData: GasPriceInfo
            
            public init(gasData: GasPriceInfo) {
                self.gasData = gasData
            }
        }
        
        public struct Response {
            public let gasData: GasPriceInfo
            
            public init(gasData: GasPriceInfo) {
                self.gasData = gasData
            }
        }
        
        public struct ViewModel {
            public let baseFee: String
            public let networkCongestion: String
            public let status: String
            
            public init(baseFee: String, networkCongestion: String, status: String) {
                self.baseFee = baseFee
                self.networkCongestion = networkCongestion
                self.status = status
            }
        }
    }
}

// MARK: - Core Models

public enum SavingInsight {
    case excellent(String)
    case good(String)
    case wait(String)
    
    public var title: String {
        switch self {
        case .excellent:
            return "최적의 거래 시간!"
        case .good:
            return "괜찮은 시간이에요"
        case .wait:
            return "잠시만 기다려보세요"
        }
    }
    
    public var icon: String {
        switch self {
        case .excellent:
            return "checkmark.circle.fill"
        case .good:
            return "clock.circle.fill"
        case .wait:
            return "exclamationmark.circle.fill"
        }
    }
    
    public var colorName: String {
        switch self {
        case .excellent:
            return "green"
        case .good:
            return "orange"
        case .wait:
            return "red"
        }
    }
    
    public var message: String {
        switch self {
        case .excellent(let message),
             .good(let message),
             .wait(let message):
            return message
        }
    }
    
    // Factory method applying business rules
    public static func generate(baseFee: Double, networkCongestion: Double) -> SavingInsight {
        let totalGasPrice = baseFee + 2.0 // Standard priority fee
        
        // Business rules for insight generation
        if totalGasPrice < 10.0 && networkCongestion < 0.3 {
            return .excellent("평소보다 30% 이상 저렴해요! 💰")
        } else if totalGasPrice < 15.0 && networkCongestion < 0.5 {
            return .good("평균적인 가스비예요")
        } else if totalGasPrice < 20.0 && networkCongestion < 0.7 {
            return .good("조금 높지만 괜찮아요")
        } else {
            let savingPercentage = Int((totalGasPrice - 10.0) / 10.0 * 100)
            return .wait("잠시 후 거래하면 \(savingPercentage)% 절약 가능해요")
        }
    }
}

public struct NetworkStatus {
    public let congestionLevel: Double // 0.0 ~ 1.0
    public let description: String
    public let colorName: String // Color를 String으로 변경
    public let estimatedWaitTime: String
    
    public init(congestionLevel: Double) {
        self.congestionLevel = congestionLevel
        
        if congestionLevel < 0.3 {
            self.description = "원활"
            self.colorName = "green"
            self.estimatedWaitTime = "30초 이내"
        } else if congestionLevel < 0.7 {
            self.description = "보통"
            self.colorName = "orange"
            self.estimatedWaitTime = "1-2분"
        } else {
            self.description = "혼잡"
            self.colorName = "red"
            self.estimatedWaitTime = "5분 이상"
        }
    }
}

public struct CostComparison {
    public let currentCost: Double
    public let averageCost: Double
    public let percentageDifference: Double
    public let savingsAmount: Double
    
    public init(currentCost: Double, averageCost: Double = 15.0) { // Default average
        self.currentCost = currentCost
        self.averageCost = averageCost
        self.percentageDifference = ((currentCost - averageCost) / averageCost) * 100
        self.savingsAmount = averageCost - currentCost
    }
    
    public var isSaving: Bool {
        return currentCost < averageCost
    }
    
    public var formattedSavings: String {
        if isSaving {
            return String(format: "%.1f%% 저렴", abs(percentageDifference))
        } else {
            return String(format: "%.1f%% 비싸", percentageDifference)
        }
    }
}

// MARK: - Supporting Models

public struct GasPriceInfo {
    public let baseFee: Double
    public let priorityFee: Double
    public let congestionLevel: Double
    public let timestamp: Date
    
    public init(baseFee: Double, priorityFee: Double, congestionLevel: Double, timestamp: Date = Date()) {
        self.baseFee = baseFee
        self.priorityFee = priorityFee
        self.congestionLevel = congestionLevel
        self.timestamp = timestamp
    }
    
    public var totalGasPrice: Double {
        return baseFee + priorityFee
    }
}