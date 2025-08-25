import Foundation

/// 송금 Scene의 VIP 모델들
public enum SendScene {
    
    // MARK: - Use Cases
    
    public enum ValidateAddress {
        public struct Request {
            public let address: String
            
            public init(address: String) {
                self.address = address
            }
        }
        
        public struct Response {
            public let isValid: Bool
            public let errorMessage: String?
            
            public init(isValid: Bool, errorMessage: String? = nil) {
                self.isValid = isValid
                self.errorMessage = errorMessage
            }
        }
        
        public struct ViewModel {
            public let isValid: Bool
            public let errorMessage: String?
            public let showError: Bool
            
            public init(isValid: Bool, errorMessage: String? = nil, showError: Bool) {
                self.isValid = isValid
                self.errorMessage = errorMessage
                self.showError = showError
            }
        }
    }
    
    public enum ValidateAmount {
        public struct Request {
            public let amount: String
            public let availableBalance: String
            
            public init(amount: String, availableBalance: String) {
                self.amount = amount
                self.availableBalance = availableBalance
            }
        }
        
        public struct Response {
            public let isValid: Bool
            public let errorMessage: String?
            public let parsedAmount: Decimal?
            
            public init(isValid: Bool, errorMessage: String? = nil, parsedAmount: Decimal? = nil) {
                self.isValid = isValid
                self.errorMessage = errorMessage
                self.parsedAmount = parsedAmount
            }
        }
        
        public struct ViewModel {
            public let isValid: Bool
            public let errorMessage: String?
            public let showError: Bool
            public let formattedAmount: String?
            
            public init(isValid: Bool, errorMessage: String? = nil, showError: Bool, formattedAmount: String? = nil) {
                self.isValid = isValid
                self.errorMessage = errorMessage
                self.showError = showError
                self.formattedAmount = formattedAmount
            }
        }
    }
    
    public enum EstimateGas {
        public struct Request {
            public let recipientAddress: String
            public let amount: String
            
            public init(recipientAddress: String, amount: String) {
                self.recipientAddress = recipientAddress
                self.amount = amount
            }
        }
        
        public struct Response {
            public let gasOptions: GasOptions?
            public let error: String?
            
            public init(gasOptions: GasOptions? = nil, error: String? = nil) {
                self.gasOptions = gasOptions
                self.error = error
            }
        }
        
        public struct ViewModel {
            public let gasOptions: GasOptions?
            public let errorMessage: String?
            public let showError: Bool
            
            public init(gasOptions: GasOptions? = nil, errorMessage: String? = nil, showError: Bool) {
                self.gasOptions = gasOptions
                self.errorMessage = errorMessage
                self.showError = showError
            }
        }
    }
    
    public enum PrepareTransaction {
        public struct Request {
            public let recipientAddress: String
            public let amount: String
            public let selectedGasFee: GasFee
            
            public init(recipientAddress: String, amount: String, selectedGasFee: GasFee) {
                self.recipientAddress = recipientAddress
                self.amount = amount
                self.selectedGasFee = selectedGasFee
            }
        }
        
        public struct Response {
            public let transaction: PendingTransaction?
            public let isReadyToSend: Bool
            public let errorMessage: String?
            
            public init(transaction: PendingTransaction? = nil, isReadyToSend: Bool, errorMessage: String? = nil) {
                self.transaction = transaction
                self.isReadyToSend = isReadyToSend
                self.errorMessage = errorMessage
            }
        }
        
        public struct ViewModel {
            public let transaction: PendingTransaction?
            public let isReadyToSend: Bool
            public let errorMessage: String?
            public let showError: Bool
            public let totalAmount: String?
            public let totalAmountUSD: String?
            
            public init(
                transaction: PendingTransaction? = nil,
                isReadyToSend: Bool,
                errorMessage: String? = nil,
                showError: Bool,
                totalAmount: String? = nil,
                totalAmountUSD: String? = nil
            ) {
                self.transaction = transaction
                self.isReadyToSend = isReadyToSend
                self.errorMessage = errorMessage
                self.showError = showError
                self.totalAmount = totalAmount
                self.totalAmountUSD = totalAmountUSD
            }
        }
    }
    
    public enum SendTransaction {
        public struct Request {
            public let transaction: PendingTransaction
            
            public init(transaction: PendingTransaction) {
                self.transaction = transaction
            }
        }
        
        public struct Response {
            public let success: Bool
            public let transactionHash: String?
            public let errorMessage: String?
            
            public init(success: Bool, transactionHash: String? = nil, errorMessage: String? = nil) {
                self.success = success
                self.transactionHash = transactionHash
                self.errorMessage = errorMessage
            }
        }
        
        public struct ViewModel {
            public let success: Bool
            public let transactionHash: String?
            public let errorMessage: String?
            public let showSuccess: Bool
            public let showError: Bool
            
            public init(
                success: Bool,
                transactionHash: String? = nil,
                errorMessage: String? = nil,
                showSuccess: Bool,
                showError: Bool
            ) {
                self.success = success
                self.transactionHash = transactionHash
                self.errorMessage = errorMessage
                self.showSuccess = showSuccess
                self.showError = showError
            }
        }
    }
}

// MARK: - Supporting Models

/// 송금 준비 단계의 거래 정보 (Core.Transaction과 구분)
public struct PendingTransaction {
    public let recipientAddress: String
    public let amount: Decimal
    public let gasPrice: String // BigUInt 대신 String 사용 (Entity 모듈은 BigInt 의존성 없음)
    public let gasLimit: String
    public let nonce: String
    
    public init(recipientAddress: String, amount: Decimal, gasPrice: String, gasLimit: String, nonce: String) {
        self.recipientAddress = recipientAddress
        self.amount = amount
        self.gasPrice = gasPrice
        self.gasLimit = gasLimit
        self.nonce = nonce
    }
}

/// 가스 옵션
public struct GasOptions {
    public let slow: GasFee
    public let normal: GasFee
    public let fast: GasFee
    
    public init(slow: GasFee, normal: GasFee, fast: GasFee) {
        self.slow = slow
        self.normal = normal
        self.fast = fast
    }
}

/// 가스 수수료
public struct GasFee {
    public let gasPrice: String // BigUInt 대신 String 사용
    public let estimatedTime: TimeInterval
    public let feeInETH: Decimal
    public let feeInUSD: Decimal
    
    public init(gasPrice: String, estimatedTime: TimeInterval, feeInETH: Decimal, feeInUSD: Decimal) {
        self.gasPrice = gasPrice
        self.estimatedTime = estimatedTime
        self.feeInETH = feeInETH
        self.feeInUSD = feeInUSD
    }
    
    public var formattedTime: String {
        let minutes = Int(estimatedTime / 60)
        return "\(minutes)분"
    }
    
    public var formattedFeeETH: String {
        return String(format: "%.6f ETH", NSDecimalNumber(decimal: feeInETH).doubleValue)
    }
    
    public var formattedFeeUSD: String {
        return String(format: "$%.2f", NSDecimalNumber(decimal: feeInUSD).doubleValue)
    }
}

/// 송금 표시용 아이템
public struct SendDisplayItem {
    public let recipientAddress: String
    public let formattedRecipientAddress: String
    public let amount: String
    public let amountInUSD: String
    public let selectedGasFee: GasFee
    public let totalAmount: String
    public let totalAmountInUSD: String
    public let isReadyToSend: Bool
    
    public init(
        recipientAddress: String,
        formattedRecipientAddress: String,
        amount: String,
        amountInUSD: String,
        selectedGasFee: GasFee,
        totalAmount: String,
        totalAmountInUSD: String,
        isReadyToSend: Bool
    ) {
        self.recipientAddress = recipientAddress
        self.formattedRecipientAddress = formattedRecipientAddress
        self.amount = amount
        self.amountInUSD = amountInUSD
        self.selectedGasFee = selectedGasFee
        self.totalAmount = totalAmount
        self.totalAmountInUSD = totalAmountInUSD
        self.isReadyToSend = isReadyToSend
    }
}

/// 송금 단계
public enum SendStep {
    case enterRecipient
    case enterAmount
    case selectGasFee
    case confirmTransaction
    case authenticating
    case sending
    case completed
    case failed
}

/// 가스 우선순위 옵션
public enum GasPriority: String, CaseIterable {
    case slow = "slow"
    case normal = "normal"
    case fast = "fast"
    
    public var title: String {
        switch self {
        case .slow: return "느림"
        case .normal: return "보통"
        case .fast: return "빠름"
        }
    }
    
    public var icon: String {
        switch self {
        case .slow: return "tortoise.fill"
        case .normal: return "hare.fill"
        case .fast: return "bolt.fill"
        }
    }
    
    public var description: String {
        switch self {
        case .slow: return "가장 저렴한 수수료"
        case .normal: return "권장 수수료"
        case .fast: return "빠른 처리 보장"
        }
    }
}