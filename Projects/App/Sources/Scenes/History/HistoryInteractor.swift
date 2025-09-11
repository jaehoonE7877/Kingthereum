import Foundation
import SwiftUI

import Core
import Entity
import Factory

// MARK: - Protocols (VIP)

/// History 비즈니스 로직을 위한 서비스 프로토콜 (네이밍 통일)
protocol HistoryServiceProtocol: Sendable {
    func fetchTransactionHistory(walletAddress: String, limit: Int, offset: Int) async throws -> ([Entity.Transaction], Bool)
    func searchTransactions(walletAddress: String, query: String) async throws -> [Entity.Transaction]
    func exportTransactions(transactions: [Entity.Transaction], format: ExportFormat) async throws -> (Data, String)
}

/// View가 Interactor에게 요청하는 비즈니스 로직을 정의합니다.
@MainActor
protocol HistoryBusinessLogic {
    var presenter: HistoryPresentationLogic? { get set }

    func loadTransactionHistory(request: HistoryScene.LoadTransactionHistory.Request)
    func loadMoreTransactions(request: HistoryScene.LoadMoreTransactions.Request)
    func refreshTransactionHistory(request: HistoryScene.RefreshTransactionHistory.Request)
    func searchTransactions(request: HistoryScene.SearchTransactions.Request)
    func exportTransactions(request: HistoryScene.ExportTransactions.Request)
}

/// 다른 Scene의 Router가 현재 Scene의 데이터에 접근할 수 있는 통로를 정의합니다.
@MainActor
protocol HistoryDataStore {
    var transactions: [Entity.Transaction] { get }
    var walletAddress: String? { get }
}

// MARK: - Interactor (Production Level)

@MainActor
final class HistoryInteractor: ObservableObject, HistoryBusinessLogic, HistoryDataStore {
    
    // MARK: - VIP Properties
    
    weak var presenter: HistoryPresentationLogic?
    private let service: HistoryServiceProtocol

    // MARK: - DataStore Properties
    
    private(set) var transactions: [Entity.Transaction] = []
    private(set) var walletAddress: String?
    private(set) var hasMore = true

    // MARK: - State Management
    
    @Published public var isLoading = false
    @Published public var isLoadingMore = false
    
    private var loadedTransactionsCount = 0
    private let batchSize = 50
    
    // MARK: - Initialization (AuthenticationInteractor 패턴 따라함)
    
    init(service: HistoryServiceProtocol = HistoryService()) {
        self.service = service
    }
    
    // MARK: - Business Logic Implementation
    
    func loadTransactionHistory(request: HistoryScene.LoadTransactionHistory.Request) {
        guard !isLoading else { return }
        
        isLoading = true
        walletAddress = request.walletAddress
        loadedTransactionsCount = 0
        hasMore = true
        
        Task {
            do {
                let (fetchedTransactions, hasMoreData) = try await service.fetchTransactionHistory(
                    walletAddress: request.walletAddress,
                    limit: batchSize,
                    offset: 0
                )
                
                await MainActor.run {
                    self.transactions = fetchedTransactions
                    self.hasMore = hasMoreData
                    self.loadedTransactionsCount = self.transactions.count
                    
                    let response = HistoryScene.LoadTransactionHistory.Response(
                        transactions: self.transactions, 
                        hasMore: self.hasMore
                    )
                    presenter?.presentTransactionHistory(response: response)
                }
                
            } catch {
                await MainActor.run {
                    let response = HistoryScene.LoadTransactionHistory.Response(
                        transactions: [], 
                        hasMore: false, 
                        error: error
                    )
                    presenter?.presentTransactionHistory(response: response)
                }
            }
            
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    func loadMoreTransactions(request: HistoryScene.LoadMoreTransactions.Request) {
        guard !isLoadingMore, hasMore, let walletAddress else { return }
        
        isLoadingMore = true
        
        Task {
            do {
                let (newTransactions, hasMoreData) = try await service.fetchTransactionHistory(
                    walletAddress: walletAddress,
                    limit: batchSize,
                    offset: loadedTransactionsCount
                )
                
                await MainActor.run {
                    self.transactions.append(contentsOf: newTransactions)
                    self.hasMore = hasMoreData
                    self.loadedTransactionsCount += newTransactions.count
                    
                    let response = HistoryScene.LoadMoreTransactions.Response(
                        newTransactions: newTransactions, 
                        hasMore: self.hasMore
                    )
                    presenter?.presentMoreTransactions(response: response)
                }
                
            } catch {
                await MainActor.run {
                    let response = HistoryScene.LoadMoreTransactions.Response(
                        newTransactions: [], 
                        hasMore: false, 
                        error: error
                    )
                    presenter?.presentMoreTransactions(response: response)
                }
            }
            
            await MainActor.run {
                self.isLoadingMore = false
            }
        }
    }
    
    func refreshTransactionHistory(request: HistoryScene.RefreshTransactionHistory.Request) {
        guard !isLoading else { return }
        
        isLoading = true
        hasMore = true
        
        Task {
            do {
                let (fetchedTransactions, hasMoreData) = try await service.fetchTransactionHistory(
                    walletAddress: request.walletAddress,
                    limit: batchSize,
                    offset: 0
                )
                
                await MainActor.run {
                    self.transactions = fetchedTransactions
                    self.hasMore = hasMoreData
                    self.loadedTransactionsCount = self.transactions.count
                    
                    let response = HistoryScene.RefreshTransactionHistory.Response(
                        transactions: self.transactions, 
                        hasMore: self.hasMore
                    )
                    presenter?.presentRefreshedHistory(response: response)
                }
                
            } catch {
                await MainActor.run {
                    let response = HistoryScene.RefreshTransactionHistory.Response(
                        transactions: [], 
                        hasMore: false, 
                        error: error
                    )
                    presenter?.presentRefreshedHistory(response: response)
                }
            }
            
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    func searchTransactions(request: HistoryScene.SearchTransactions.Request) {
        guard !isLoading, let walletAddress = self.walletAddress else { return }
        isLoading = true
        
        Task {
            do {
                let results = try await service.searchTransactions(
                    walletAddress: walletAddress, 
                    query: request.query
                )
                
                await MainActor.run {
                    let response = HistoryScene.SearchTransactions.Response(
                        results: results, 
                        query: request.query
                    )
                    presenter?.presentSearchResults(response: response)
                }
                
            } catch {
                await MainActor.run {
                    let response = HistoryScene.SearchTransactions.Response(
                        results: [], 
                        query: request.query, 
                        error: error
                    )
                    presenter?.presentSearchResults(response: response)
                }
            }
            
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    func exportTransactions(request: HistoryScene.ExportTransactions.Request) {
        Task {
            do {
                let exportResult = try await service.exportTransactions(
                    transactions: request.transactions, 
                    format: request.format
                )
                
                let tempDir = FileManager.default.temporaryDirectory
                let fileURL = tempDir.appendingPathComponent(exportResult.1)
                try exportResult.0.write(to: fileURL)

                await MainActor.run {
                    let response = HistoryScene.ExportTransactions.Response(
                        exportURL: fileURL, 
                        format: request.format
                    )
                    presenter?.presentExportResult(response: response)
                }
                
            } catch {
                await MainActor.run {
                    let response = HistoryScene.ExportTransactions.Response(
                        exportURL: nil, 
                        format: request.format, 
                        error: error
                    )
                    presenter?.presentExportResult(response: response)
                }
            }
        }
    }
}
