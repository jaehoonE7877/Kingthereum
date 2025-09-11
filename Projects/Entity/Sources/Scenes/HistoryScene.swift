import Foundation

/// 거래 내역 Scene의 VIP 모델들 (Swift 6 Concurrency 준수)
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
            public let isRealTimeEnabled: Bool // OPTIMIZED
            
            public init(transactions: [Transaction], hasMore: Bool, error: Error? = nil, isRealTimeEnabled: Bool = false) {
                self.transactions = transactions
                self.hasMore = hasMore
                self.error = error
                self.isRealTimeEnabled = isRealTimeEnabled
            }
        }
        
        public struct ViewModel {
            public let transactionViewModels: [TransactionViewModel]
            public let hasMoreTransactions: Bool
            public let isEmpty: Bool
            public let errorMessage: String?
            public let isRealTimeEnabled: Bool
            
            public init(transactionViewModels: [TransactionViewModel], hasMoreTransactions: Bool, isEmpty: Bool, errorMessage: String? = nil, isRealTimeEnabled: Bool = false) {
                self.transactionViewModels = transactionViewModels
                self.hasMoreTransactions = hasMoreTransactions
                self.isEmpty = isEmpty
                self.errorMessage = errorMessage
                self.isRealTimeEnabled = isRealTimeEnabled
            }
        }
    }
    
    public enum LoadMoreTransactions { // OPTIMIZED
        public struct Request {
            public let walletAddress: String
            
            public init(walletAddress: String) {
                self.walletAddress = walletAddress
            }
        }
        
        public struct Response: Sendable {
            public let newTransactions: [Transaction]
            public let hasMore: Bool
            public let error: Error?
            
            public init(newTransactions: [Transaction], hasMore: Bool, error: Error? = nil) {
                self.newTransactions = newTransactions
                self.hasMore = hasMore
                self.error = error
            }
        }
        
        public struct ViewModel {
            public let newTransactionViewModels: [TransactionViewModel]
            public let hasMoreTransactions: Bool
            public let errorMessage: String?
            
            public init(newTransactionViewModels: [TransactionViewModel], hasMoreTransactions: Bool, errorMessage: String? = nil) {
                self.newTransactionViewModels = newTransactionViewModels
                self.hasMoreTransactions = hasMoreTransactions
                self.errorMessage = errorMessage
            }
        }
    }
    
    public enum RefreshTransactionHistory { // OPTIMIZED (Replaces RefreshTransactions)
        public struct Request {
            public let walletAddress: String
            
            public init(walletAddress: String) {
                self.walletAddress = walletAddress
            }
        }
        
        public struct Response: Sendable {
            public let transactions: [Transaction]
            public let hasMore: Bool
            public let error: Error?
            
            public init(transactions: [Transaction], hasMore: Bool, error: Error? = nil) {
                self.transactions = transactions
                self.hasMore = hasMore
                self.error = error
            }
        }
        
        public struct ViewModel {
            public let transactionViewModels: [TransactionViewModel]
            public let hasMore: Bool
            public let errorMessage: String?
            
            public init(transactionViewModels: [TransactionViewModel], hasMore: Bool, errorMessage: String? = nil) {
                self.transactionViewModels = transactionViewModels
                self.hasMore = hasMore
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
    
    public enum SearchTransactions { // OPTIMIZED
        public struct Request {
            public let walletAddress: String
            public let query: String
            
            public init(walletAddress: String, query: String) {
                self.walletAddress = walletAddress
                self.query = query
            }
        }
        
        public struct Response: Sendable {
            public let results: [Transaction]
            public let query: String
            public let error: Error?
            
            public init(results: [Transaction], query: String, error: Error? = nil) {
                self.results = results
                self.query = query
                self.error = error
            }
        }
        
        public struct ViewModel {
            public let transactionViewModels: [TransactionViewModel]
            public let query: String
            public let errorMessage: String?
            
            public init(transactionViewModels: [TransactionViewModel], query: String, errorMessage: String? = nil) {
                self.transactionViewModels = transactionViewModels
                self.query = query
                self.errorMessage = errorMessage
            }
        }
    }
    
    public enum ExportTransactions { // OPTIMIZED (Replaces old one)
        public struct Request {
            public let transactions: [Transaction]
            public let format: ExportFormat
            public let dateRange: DateRange?

            public init(transactions: [Transaction], format: ExportFormat, dateRange: DateRange? = nil) {
                self.transactions = transactions
                self.format = format
                self.dateRange = dateRange
            }
        }
        
        public struct Response: Sendable {
            public let exportURL: URL?
            public let format: ExportFormat
            public let error: Error?
            
            public init(exportURL: URL?, format: ExportFormat, error: Error? = nil) {
                self.exportURL = exportURL
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

public struct DateRange: Sendable, Hashable {
    public let startDate: Date
    public let endDate: Date
    
    public init(startDate: Date, endDate: Date) {
        self.startDate = startDate
        self.endDate = endDate
    }
}

public struct AmountRange: Sendable, Hashable {
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
    case xlsx = "XLSX"
    
    public var fileExtension: String {
        switch self {
        case .csv: return "csv"
        case .json: return "json"
        case .pdf: return "pdf"
        case .xlsx: return "xlsx"
        }
    }
    
    public var mimeType: String {
        switch self {
        case .csv: return "text/csv"
        case .json: return "application/json"
        case .pdf: return "application/pdf"
        case .xlsx: return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        }
    }
}

public struct TransactionViewModel: Identifiable, Sendable, Hashable {
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
