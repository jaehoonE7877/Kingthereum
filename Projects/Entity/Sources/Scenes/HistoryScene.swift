import Foundation

/// 거래 내역 Scene의 VIP 모델들
public enum HistoryScene {
    
    // MARK: - Use Cases
    public enum LoadTransactionHistory {
        public struct Request {
            public let walletAddress: String
            public let limit: Int
            public let offset: Int
            
            public init(walletAddress: String, limit: Int = 20, offset: Int = 0) {
                self.walletAddress = walletAddress
                self.limit = limit
                self.offset = offset
            }
        }
        
        public struct Response: Sendable {
            public let transactions: [Transaction]
            public let hasMore: Bool
            public let error: Error?
            
            public init(transactions: [Transaction], hasMore: Bool = false, error: Error? = nil) {
                self.transactions = transactions
                self.hasMore = hasMore
                self.error = error
            }
        }
        
        public struct ViewModel {
            public let transactionViewModels: [TransactionViewModel]
            public let hasMoreTransactions: Bool
            public let isEmpty: Bool
            public let errorMessage: String?
            
            public init(transactionViewModels: [TransactionViewModel], hasMoreTransactions: Bool, isEmpty: Bool, errorMessage: String? = nil) {
                self.transactionViewModels = transactionViewModels
                self.hasMoreTransactions = hasMoreTransactions
                self.isEmpty = isEmpty
                self.errorMessage = errorMessage
            }
        }
    }
    
    public enum FilterTransactions {
        public struct Request {
            public let filterType: TransactionFilterType
            public let dateRange: DateRange?
            public let amountRange: AmountRange?
            
            public init(filterType: TransactionFilterType, dateRange: DateRange? = nil, amountRange: AmountRange? = nil) {
                self.filterType = filterType
                self.dateRange = dateRange
                self.amountRange = amountRange
            }
        }
        
        public struct Response: Sendable {
            public let filteredTransactions: [Transaction]
            public let filterType: TransactionFilterType
            public let totalCount: Int
            
            public init(filteredTransactions: [Transaction], filterType: TransactionFilterType, totalCount: Int) {
                self.filteredTransactions = filteredTransactions
                self.filterType = filterType
                self.totalCount = totalCount
            }
        }
        
        public struct ViewModel {
            public let transactionViewModels: [TransactionViewModel]
            public let filterTitle: String
            public let resultCount: String
            public let isEmpty: Bool
            
            public init(transactionViewModels: [TransactionViewModel], filterTitle: String, resultCount: String, isEmpty: Bool) {
                self.transactionViewModels = transactionViewModels
                self.filterTitle = filterTitle
                self.resultCount = resultCount
                self.isEmpty = isEmpty
            }
        }
    }
    
    public enum ExportTransactions {
        public struct Request {
            public let transactions: [Transaction]
            public let format: ExportFormat
            
            public init(transactions: [Transaction], format: ExportFormat) {
                self.transactions = transactions
                self.format = format
            }
        }
        
        public struct Response: Sendable {
            public let exportData: Data?
            public let fileName: String
            public let format: ExportFormat
            public let error: Error?
            
            public init(exportData: Data?, fileName: String, format: ExportFormat, error: Error? = nil) {
                self.exportData = exportData
                self.fileName = fileName
                self.format = format
                self.error = error
            }
        }
        
        public struct ViewModel {
            public let shareItems: [Any]
            public let successMessage: String?
            public let errorMessage: String?
            
            public init(shareItems: [Any] = [], successMessage: String? = nil, errorMessage: String? = nil) {
                self.shareItems = shareItems
                self.successMessage = successMessage
                self.errorMessage = errorMessage
            }
        }
    }
    
    public enum RefreshTransactions {
        public struct Request {
            public let walletAddress: String
            
            public init(walletAddress: String) {
                self.walletAddress = walletAddress
            }
        }
        
        public struct Response: Sendable {
            public let transactions: [Transaction]
            public let newTransactionsCount: Int
            public let error: Error?
            
            public init(transactions: [Transaction], newTransactionsCount: Int = 0, error: Error? = nil) {
                self.transactions = transactions
                self.newTransactionsCount = newTransactionsCount
                self.error = error
            }
        }
        
        public struct ViewModel {
            public let transactionViewModels: [TransactionViewModel]
            public let refreshMessage: String?
            public let errorMessage: String?
            
            public init(transactionViewModels: [TransactionViewModel], refreshMessage: String? = nil, errorMessage: String? = nil) {
                self.transactionViewModels = transactionViewModels
                self.refreshMessage = refreshMessage
                self.errorMessage = errorMessage
            }
        }
    }
}

// MARK: - Supporting Types

public enum TransactionFilterType: String, CaseIterable, Sendable {
    case all = "전체"
    case sent = "보낸 거래"
    case received = "받은 거래"
    case pending = "대기 중"
    case failed = "실패"
    
    public var systemIcon: String {
        switch self {
        case .all: return "list.bullet"
        case .sent: return "arrow.up.circle.fill"
        case .received: return "arrow.down.circle.fill"
        case .pending: return "clock.circle.fill"
        case .failed: return "exclamationmark.circle.fill"
        }
    }
}

public struct DateRange: Sendable {
    public let startDate: Date
    public let endDate: Date
    
    public init(startDate: Date, endDate: Date) {
        self.startDate = startDate
        self.endDate = endDate
    }
}

public struct AmountRange: Sendable {
    public let minAmount: Decimal
    public let maxAmount: Decimal
    
    public init(minAmount: Decimal, maxAmount: Decimal) {
        self.minAmount = minAmount
        self.maxAmount = maxAmount
    }
}

public enum ExportFormat: String, CaseIterable, Sendable {
    case csv = "CSV"
    case json = "JSON"
    case pdf = "PDF"
    
    public var fileExtension: String {
        switch self {
        case .csv: return "csv"
        case .json: return "json"
        case .pdf: return "pdf"
        }
    }
    
    public var mimeType: String {
        switch self {
        case .csv: return "text/csv"
        case .json: return "application/json"
        case .pdf: return "application/pdf"
        }
    }
}

public struct TransactionViewModel: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let amount: String
    public let formattedDate: String
    public let statusIcon: String
    public let statusColor: String
    public let isIncoming: Bool
    
    public init(id: String, title: String, subtitle: String, amount: String, formattedDate: String, statusIcon: String, statusColor: String, isIncoming: Bool) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.amount = amount
        self.formattedDate = formattedDate
        self.statusIcon = statusIcon
        self.statusColor = statusColor
        self.isIncoming = isIncoming
    }
}