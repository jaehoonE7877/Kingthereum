import Foundation

/// 거래 상태를 나타내는 열거형
public enum TransactionStatus: String, Codable, CaseIterable, Sendable {
    case pending = "pending"
    case confirmed = "confirmed"
    case failed = "failed"
    
    public var displayName: String {
        switch self {
        case .pending:
            return "Pending"
        case .confirmed:
            return "Confirmed"
        case .failed:
            return "Failed"
        }
    }
}

/// 지갑 Scene의 VIP 모델들
public enum WalletScene {
    
    // MARK: - Get Balance
    public enum GetBalance {
        public struct Request {
            public let walletAddress: String
            
            public init(walletAddress: String) {
                self.walletAddress = walletAddress
            }
        }
        
        public struct Response {
            public let balance: String
            public let usdValue: String?
            public let error: Error?
            
            public init(balance: String, usdValue: String? = nil, error: Error? = nil) {
                self.balance = balance
                self.usdValue = usdValue
                self.error = error
            }
        }
        
        public struct ViewModel {
            public let balance: String
            public let usdValue: String
            public let isLoading: Bool
            public let errorMessage: String?
            
            public init(balance: String, usdValue: String, isLoading: Bool, errorMessage: String? = nil) {
                self.balance = balance
                self.usdValue = usdValue
                self.isLoading = isLoading
                self.errorMessage = errorMessage
            }
        }
    }
    
    // MARK: - Send Transaction
    public enum SendTransaction {
        public struct Request {
            public let toAddress: String
            public let amount: String
            public let gasPrice: String?
            public let gasLimit: String?
            
            public init(toAddress: String, amount: String, gasPrice: String? = nil, gasLimit: String? = nil) {
                self.toAddress = toAddress
                self.amount = amount
                self.gasPrice = gasPrice
                self.gasLimit = gasLimit
            }
        }
        
        public struct Response {
            public let success: Bool
            public let transactionHash: String?
            public let error: Error?
            
            public init(success: Bool, transactionHash: String? = nil, error: Error? = nil) {
                self.success = success
                self.transactionHash = transactionHash
                self.error = error
            }
        }
        
        public struct ViewModel {
            public let success: Bool
            public let transactionHash: String?
            public let errorMessage: String?
            
            public init(success: Bool, transactionHash: String? = nil, errorMessage: String? = nil) {
                self.success = success
                self.transactionHash = transactionHash
                self.errorMessage = errorMessage
            }
        }
    }
    
    // MARK: - Load Transactions
    public enum LoadTransactions {
        public struct Request {
            public let walletAddress: String
            
            public init(walletAddress: String) {
                self.walletAddress = walletAddress
            }
        }
        
        public struct Response {
            public let transactions: [TransactionDisplayItem]
            public let error: Error?
            
            public init(transactions: [TransactionDisplayItem], error: Error? = nil) {
                self.transactions = transactions
                self.error = error
            }
        }
        
        public struct ViewModel {
            public let transactions: [TransactionDisplayItem]
            public let isLoading: Bool
            public let errorMessage: String?
            
            public init(transactions: [TransactionDisplayItem], isLoading: Bool, errorMessage: String? = nil) {
                self.transactions = transactions
                self.isLoading = isLoading
                self.errorMessage = errorMessage
            }
        }
    }
    
    // MARK: - Copy Address
    public enum CopyAddress {
        public struct Request {
            public let address: String
            
            public init(address: String) {
                self.address = address
            }
        }
        
        public struct Response {
            public let success: Bool
            
            public init(success: Bool) {
                self.success = success
            }
        }
        
        public struct ViewModel {
            public let message: String
            
            public init(message: String) {
                self.message = message
            }
        }
    }
}

/// 거래 타입 (포괄적 정의)
public enum WalletTransactionType: String, CaseIterable, Sendable {
    case send = "send"
    case receive = "receive"
    case swap = "swap"
    case approval = "approval"
    case contract = "contract"
    
    public var displayName: String {
        switch self {
        case .send: return "송금"
        case .receive: return "수신"
        case .swap: return "스왑"
        case .approval: return "승인"
        case .contract: return "컨트랙트"
        }
    }
    
    public var iconName: String {
        switch self {
        case .send: return "arrow.up.circle.fill"
        case .receive: return "arrow.down.circle.fill"
        case .swap: return "arrow.triangle.2.circlepath"
        case .approval: return "checkmark.circle.fill"
        case .contract: return "doc.text.fill"
        }
    }
    
    public var color: String {
        switch self {
        case .send: return "red"
        case .receive: return "green"
        case .swap: return "blue"
        case .approval: return "orange"
        case .contract: return "purple"
        }
    }
    
    public var symbol: String {
        switch self {
        case .send: return "↗"
        case .receive: return "↙"
        case .swap: return "⇄"
        case .approval: return "✓"
        case .contract: return "📄"
        }
    }
}


/// 거래 표시용 아이템
public struct TransactionDisplayItem: Identifiable {
    public let id = UUID()
    public let hash: String
    public let type: WalletTransactionType
    public let amount: String
    public let address: String
    public let date: String
    public let status: TransactionStatus
    
    public init(hash: String, type: WalletTransactionType, amount: String, address: String, date: String, status: TransactionStatus) {
        self.hash = hash
        self.type = type
        self.amount = amount
        self.address = address
        self.date = date
        self.status = status
    }
}