import Foundation
import Entity
import WalletKit
import Core
import Factory

// Use ExportFormat from HistoryRouter (same module)
// ExportFormat is defined in HistoryRouter.swift

@MainActor
protocol HistoryBusinessLogic {
    func loadTransactionHistory(request: HistoryScene.LoadTransactionHistory.Request)
    func refreshTransactions(request: HistoryScene.RefreshTransactions.Request)
    func filterTransactions(request: HistoryScene.FilterTransactions.Request)
    func exportTransactions(request: HistoryScene.ExportTransactions.Request)
}

@MainActor
protocol HistoryDataStore {
    var currentTransactions: [Transaction] { get set }
    var filteredTransactions: [Transaction] { get set }
    var currentFilter: TransactionFilterType { get set }
    var walletAddress: String? { get set }
    var isLoading: Bool { get set }
    var hasMoreTransactions: Bool { get set }
}

@MainActor
final class HistoryInteractor: HistoryBusinessLogic, HistoryDataStore {
    var presenter: HistoryPresentationLogic?
    private var _worker: HistoryWorkerProtocol?
    
    @Injected(\.configurationService) private var configurationService
    
    // MARK: - Data Store
    var currentTransactions: [Transaction] = []
    var filteredTransactions: [Transaction] = []
    var currentFilter: TransactionFilterType = .all
    var walletAddress: String?
    var isLoading = false
    var hasMoreTransactions = false
    
    init(worker: HistoryWorkerProtocol? = nil) {
        self._worker = worker
        loadWalletAddress()
    }
    
    // MARK: - Lazy Worker Initialization
    
    private var worker: HistoryWorkerProtocol {
        if let worker = _worker {
            return worker
        }
        
        do {
            let walletService = try WalletService.initialize(rpcURL: configurationService.ethereumRPCURL)
            let newWorker = HistoryWorker(walletService: walletService)
            self._worker = newWorker
            return newWorker
        } catch {
            // In production, this should be handled more gracefully
            fatalError("Failed to initialize WalletService: \(error)")
        }
    }
    
    // MARK: - Business Logic
    
    func loadTransactionHistory(request: HistoryScene.LoadTransactionHistory.Request) {
        guard !isLoading else { return }
        
        isLoading = true
        walletAddress = request.walletAddress
        
        Task { [weak self] in
            do {
                let result = try await self?.worker.fetchTransactionHistory(
                    walletAddress: request.walletAddress,
                    limit: request.limit,
                    offset: request.offset
                )
                
                guard let result = result else { return }
                
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    
                    if request.offset == 0 {
                        // 새로운 로드
                        self.currentTransactions = result.0
                    } else {
                        // 페이지네이션 로드
                        self.currentTransactions.append(contentsOf: result.0)
                    }
                    
                    self.filteredTransactions = self.currentTransactions
                    self.hasMoreTransactions = result.1
                    self.isLoading = false
                    
                    let response = HistoryScene.LoadTransactionHistory.Response(
                        transactions: self.currentTransactions,
                        hasMore: result.1,
                        error: nil
                    )
                    self.presenter?.presentTransactionHistory(response: response)
                }
            } catch {
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    
                    self.isLoading = false
                    
                    let response = HistoryScene.LoadTransactionHistory.Response(
                        transactions: [],
                        hasMore: false,
                        error: error
                    )
                    self.presenter?.presentTransactionHistory(response: response)
                }
            }
        }
    }
    
    func refreshTransactions(request: HistoryScene.RefreshTransactions.Request) {
        Task { [weak self] in
            do {
                let result = try await self?.worker.fetchLatestTransactions(
                    walletAddress: request.walletAddress
                )
                
                guard let result = result else { return }
                
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    
                    let newTransactionsCount = result.count - self.currentTransactions.count
                    self.currentTransactions = result
                    self.filteredTransactions = self.applyCurrentFilter(to: result)
                    
                    let response = HistoryScene.RefreshTransactions.Response(
                        transactions: self.filteredTransactions,
                        newTransactionsCount: max(0, newTransactionsCount),
                        error: nil
                    )
                    self.presenter?.presentRefreshResult(response: response)
                }
            } catch {
                await MainActor.run { [weak self] in
                    let response = HistoryScene.RefreshTransactions.Response(
                        transactions: [],
                        newTransactionsCount: 0,
                        error: error
                    )
                    self?.presenter?.presentRefreshResult(response: response)
                }
            }
        }
    }
    
    func filterTransactions(request: HistoryScene.FilterTransactions.Request) {
        currentFilter = request.filterType
        
        var filtered = currentTransactions
        
        // 타입별 필터링
        switch request.filterType {
        case .all:
            break // 모든 거래
        case .sent:
            // 현재 지갑 주소에서 보낸 거래 필터링
            filtered = filtered.filter { transaction in
                guard let currentWalletAddress = walletAddress else { return false }
                return transaction.from.lowercased() == currentWalletAddress.lowercased()
            }
        case .received:
            // 현재 지갑 주소로 받은 거래 필터링
            filtered = filtered.filter { transaction in
                guard let currentWalletAddress = walletAddress else { return false }
                return transaction.to.lowercased() == currentWalletAddress.lowercased()
            }
        case .pending:
            filtered = filtered.filter { $0.status == .pending }
        case .failed:
            filtered = filtered.filter { $0.status == .failed }
        }
        
        // 날짜 범위 필터링
        if let dateRange = request.dateRange {
            filtered = filtered.filter { transaction in
                transaction.timestamp >= dateRange.startDate && transaction.timestamp <= dateRange.endDate
            }
        }
        
        // 금액 범위 필터링
        if let amountRange = request.amountRange {
            filtered = filtered.filter { transaction in
                // String value를 Decimal로 변환해서 비교
                if let amount = Decimal(string: transaction.value) {
                    return amount >= amountRange.minAmount && amount <= amountRange.maxAmount
                }
                return false
            }
        }
        
        filteredTransactions = filtered
        
        let response = HistoryScene.FilterTransactions.Response(
            filteredTransactions: filtered,
            filterType: request.filterType,
            totalCount: currentTransactions.count
        )
        presenter?.presentFilteredTransactions(response: response)
    }
    
    func exportTransactions(request: HistoryScene.ExportTransactions.Request) {
        Task { [weak self] in
            do {
                // Convert Entity.HistoryScene.ExportFormat to local ExportFormat
                let localFormat = ExportFormat(rawValue: request.format.rawValue) ?? .csv
                let exportResult = try await self?.worker.exportTransactions(
                    transactions: request.transactions,
                    format: localFormat
                )
                
                guard let exportResult = exportResult else { return }
                
                await MainActor.run { [weak self] in
                    let response = HistoryScene.ExportTransactions.Response(
                        exportData: exportResult.0,
                        fileName: exportResult.1,
                        format: request.format,
                        error: nil
                    )
                    self?.presenter?.presentExportResult(response: response)
                }
            } catch {
                await MainActor.run { [weak self] in
                    let response = HistoryScene.ExportTransactions.Response(
                        exportData: nil,
                        fileName: "",
                        format: request.format,
                        error: error
                    )
                    self?.presenter?.presentExportResult(response: response)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func loadWalletAddress() {
        walletAddress = UserDefaults.standard.string(forKey: Constants.UserDefaults.selectedWalletAddress)
    }
    
    private func applyCurrentFilter(to transactions: [Transaction]) -> [Transaction] {
        var filtered = transactions
        
        switch currentFilter {
        case .all:
            break
        case .sent:
            // 현재 지갑 주소에서 보낸 거래 필터링
            filtered = filtered.filter { transaction in
                guard let currentWalletAddress = walletAddress else { return false }
                return transaction.from.lowercased() == currentWalletAddress.lowercased()
            }
        case .received:
            // 현재 지갑 주소로 받은 거래 필터링
            filtered = filtered.filter { transaction in
                guard let currentWalletAddress = walletAddress else { return false }
                return transaction.to.lowercased() == currentWalletAddress.lowercased()
            }
        case .pending:
            filtered = filtered.filter { $0.status == .pending }
        case .failed:
            filtered = filtered.filter { $0.status == .failed }
        }
        
        return filtered
    }
}