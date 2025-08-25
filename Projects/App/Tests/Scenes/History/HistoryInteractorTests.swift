import Testing
import Foundation
@testable import App
@testable import Entity
@testable import Core

// MARK: - HistoryInteractor Tests

@Suite("HistoryInteractor 테스트")
struct HistoryInteractorTests {
    
    // MARK: - Spy Classes
    
    @MainActor
    class PresentationLogicSpy: HistoryPresentationLogic {
        var presentTransactionHistoryCalled = false
        var presentTransactionHistoryResponse: HistoryScene.LoadTransactionHistory.Response?
        
        var presentRefreshResultCalled = false
        var presentRefreshResultResponse: HistoryScene.RefreshTransactions.Response?
        
        var presentFilteredTransactionsCalled = false
        var presentFilteredTransactionsResponse: HistoryScene.FilterTransactions.Response?
        
        var presentExportResultCalled = false
        var presentExportResultResponse: HistoryScene.ExportTransactions.Response?
        
        func presentTransactionHistory(response: HistoryScene.LoadTransactionHistory.Response) {
            presentTransactionHistoryCalled = true
            presentTransactionHistoryResponse = response
        }
        
        func presentRefreshResult(response: HistoryScene.RefreshTransactions.Response) {
            presentRefreshResultCalled = true
            presentRefreshResultResponse = response
        }
        
        func presentFilteredTransactions(response: HistoryScene.FilterTransactions.Response) {
            presentFilteredTransactionsCalled = true
            presentFilteredTransactionsResponse = response
        }
        
        func presentExportResult(response: HistoryScene.ExportTransactions.Response) {
            presentExportResultCalled = true
            presentExportResultResponse = response
        }
    }
    
    actor WorkerSpy: HistoryWorkerProtocol {
        var fetchTransactionHistoryCalled = false
        var fetchTransactionHistoryResult: Result<(transactions: [Transaction], hasMore: Bool), Error> = .success((transactions: [], hasMore: false))
        
        var fetchLatestTransactionsCalled = false
        var fetchLatestTransactionsResult: Result<(transactions: [Transaction]), Error> = .success((transactions: []))
        
        var exportTransactionsCalled = false
        var exportTransactionsResult: Result<(data: Data, fileName: String), Error> = .success((data: Data(), fileName: "test.csv"))
        
        func fetchTransactionHistory(walletAddress: String, limit: Int, offset: Int) async throws -> (transactions: [Transaction], hasMore: Bool) {
            fetchTransactionHistoryCalled = true
            switch fetchTransactionHistoryResult {
            case .success(let result):
                return result
            case .failure(let error):
                throw error
            }
        }
        
        func fetchLatestTransactions(walletAddress: String) async throws -> (transactions: [Transaction]) {
            fetchLatestTransactionsCalled = true
            switch fetchLatestTransactionsResult {
            case .success(let result):
                return result
            case .failure(let error):
                throw error
            }
        }
        
        func exportTransactions(transactions: [Transaction], format: ExportFormat) async throws -> (data: Data, fileName: String) {
            exportTransactionsCalled = true
            switch exportTransactionsResult {
            case .success(let result):
                return result
            case .failure(let error):
                throw error
            }
        }
    }
    
    // MARK: - 거래 내역 로드 테스트
    
    @Suite("거래 내역 로드")
    struct LoadTransactionHistory {
        
        @Test("성공 케이스 - 초기 로드")
        func testLoadTransactionHistoryInitialSuccess() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let mockTransactions = [
                createMockTransaction(hash: "0x123", amount: 1.5),
                createMockTransaction(hash: "0x456", amount: 2.3)
            ]
            
            await workerSpy.setFetchTransactionHistoryResult(.success((transactions: mockTransactions, hasMore: true)))
            
            let sut = HistoryInteractor(worker: workerSpy)
            sut.presenter = presenterSpy
            
            let request = HistoryScene.LoadTransactionHistory.Request(
                walletAddress: "0x742d35Cc6634C0Dcc6b9C2b48b9bC4C8b9d9aE3",
                limit: 20,
                offset: 0
            )
            
            // When
            sut.loadTransactionHistory(request: request)
            
            // Wait for async operation to complete
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초
            
            // Then
            #expect(await workerSpy.fetchTransactionHistoryCalled == true, "Worker가 호출되어야 함")
            #expect(presenterSpy.presentTransactionHistoryCalled == true, "Presenter가 호출되어야 함")
            
            let response = presenterSpy.presentTransactionHistoryResponse
            #expect(response != nil, "Response가 전달되어야 함")
            #expect(response?.transactions.count == 2, "2개의 거래가 반환되어야 함")
            #expect(response?.hasMore == true, "더 많은 거래가 있음을 표시해야 함")
            #expect(response?.error == nil, "에러가 없어야 함")
            
            // DataStore 상태 확인
            #expect(sut.currentTransactions.count == 2, "DataStore에 2개의 거래가 저장되어야 함")
            #expect(sut.hasMoreTransactions == true, "더 많은 거래 플래그가 설정되어야 함")
            #expect(sut.isLoading == false, "로딩 상태가 해제되어야 함")
        }
        
        @Test("성공 케이스 - 페이지네이션")
        func testLoadTransactionHistoryPaginationSuccess() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let initialTransactions = [
                createMockTransaction(hash: "0x111", amount: 1.0),
                createMockTransaction(hash: "0x222", amount: 2.0)
            ]
            
            let additionalTransactions = [
                createMockTransaction(hash: "0x333", amount: 3.0),
                createMockTransaction(hash: "0x444", amount: 4.0)
            ]
            
            let sut = HistoryInteractor(worker: workerSpy)
            sut.presenter = presenterSpy
            sut.currentTransactions = initialTransactions
            
            await workerSpy.setFetchTransactionHistoryResult(.success((transactions: additionalTransactions, hasMore: false)))
            
            let request = HistoryScene.LoadTransactionHistory.Request(
                walletAddress: "0x742d35Cc6634C0Dcc6b9C2b48b9bC4C8b9d9aE3",
                limit: 20,
                offset: 20
            )
            
            // When
            sut.loadTransactionHistory(request: request)
            
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            // Then
            #expect(await workerSpy.fetchTransactionHistoryCalled == true, "Worker가 호출되어야 함")
            #expect(presenterSpy.presentTransactionHistoryCalled == true, "Presenter가 호출되어야 함")
            
            // DataStore에 기존 거래 + 새 거래가 모두 있어야 함
            #expect(sut.currentTransactions.count == 4, "총 4개의 거래가 있어야 함")
            #expect(sut.hasMoreTransactions == false, "더 이상 거래가 없음을 표시해야 함")
        }
        
        @Test("실패 케이스 - 네트워크 오류")
        func testLoadTransactionHistoryNetworkError() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let networkError = NetworkError.noConnection
            await workerSpy.setFetchTransactionHistoryResult(.failure(networkError))
            
            let sut = HistoryInteractor(worker: workerSpy)
            sut.presenter = presenterSpy
            
            let request = HistoryScene.LoadTransactionHistory.Request(
                walletAddress: "0x742d35Cc6634C0Dcc6b9C2b48b9bC4C8b9d9aE3",
                limit: 20,
                offset: 0
            )
            
            // When
            sut.loadTransactionHistory(request: request)
            
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            // Then
            #expect(await workerSpy.fetchTransactionHistoryCalled == true, "Worker가 호출되어야 함")
            #expect(presenterSpy.presentTransactionHistoryCalled == true, "Presenter가 호출되어야 함")
            
            let response = presenterSpy.presentTransactionHistoryResponse
            #expect(response != nil, "Response가 전달되어야 함")
            #expect(response?.transactions.isEmpty == true, "거래 목록이 비어있어야 함")
            #expect(response?.error != nil, "에러가 전달되어야 함")
            #expect(sut.isLoading == false, "로딩 상태가 해제되어야 함")
        }
        
        @Test("중복 로딩 방지")
        func testLoadTransactionHistoryPreventDuplicateLoading() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let sut = HistoryInteractor(worker: workerSpy)
            sut.presenter = presenterSpy
            sut.isLoading = true // 이미 로딩 중
            
            let request = HistoryScene.LoadTransactionHistory.Request(
                walletAddress: "0x742d35Cc6634C0Dcc6b9C2b48b9bC4C8b9d9aE3",
                limit: 20,
                offset: 0
            )
            
            // When
            sut.loadTransactionHistory(request: request)
            
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            // Then
            #expect(await workerSpy.fetchTransactionHistoryCalled == false, "이미 로딩 중이므로 Worker가 호출되지 않아야 함")
            #expect(presenterSpy.presentTransactionHistoryCalled == false, "Presenter가 호출되지 않아야 함")
        }
    }
    
    // MARK: - 거래 새로고침 테스트
    
    @Suite("거래 새로고침")
    struct RefreshTransactions {
        
        @Test("성공 케이스 - 새로운 거래 있음")
        func testRefreshTransactionsWithNewTransactions() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let existingTransactions = [
                createMockTransaction(hash: "0x111", amount: 1.0)
            ]
            
            let updatedTransactions = [
                createMockTransaction(hash: "0x222", amount: 2.0), // 새 거래
                createMockTransaction(hash: "0x111", amount: 1.0)  // 기존 거래
            ]
            
            await workerSpy.setFetchLatestTransactionsResult(.success((transactions: updatedTransactions)))
            
            let sut = HistoryInteractor(worker: workerSpy)
            sut.presenter = presenterSpy
            sut.currentTransactions = existingTransactions
            
            let request = HistoryScene.RefreshTransactions.Request(
                walletAddress: "0x742d35Cc6634C0Dcc6b9C2b48b9bC4C8b9d9aE3"
            )
            
            // When
            sut.refreshTransactions(request: request)
            
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            // Then
            #expect(await workerSpy.fetchLatestTransactionsCalled == true, "Worker가 호출되어야 함")
            #expect(presenterSpy.presentRefreshResultCalled == true, "Presenter가 호출되어야 함")
            
            let response = presenterSpy.presentRefreshResultResponse
            #expect(response != nil, "Response가 전달되어야 함")
            #expect(response?.transactions.count == 2, "업데이트된 거래 목록이 전달되어야 함")
            #expect(response?.newTransactionsCount == 1, "1개의 새 거래가 있어야 함")
            #expect(response?.error == nil, "에러가 없어야 함")
            
            // DataStore 업데이트 확인
            #expect(sut.currentTransactions.count == 2, "DataStore가 업데이트되어야 함")
        }
        
        @Test("성공 케이스 - 새로운 거래 없음")
        func testRefreshTransactionsWithoutNewTransactions() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let existingTransactions = [
                createMockTransaction(hash: "0x111", amount: 1.0)
            ]
            
            await workerSpy.setFetchLatestTransactionsResult(.success((transactions: existingTransactions)))
            
            let sut = HistoryInteractor(worker: workerSpy)
            sut.presenter = presenterSpy
            sut.currentTransactions = existingTransactions
            
            let request = HistoryScene.RefreshTransactions.Request(
                walletAddress: "0x742d35Cc6634C0Dcc6b9C2b48b9bC4C8b9d9aE3"
            )
            
            // When
            sut.refreshTransactions(request: request)
            
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            // Then
            let response = presenterSpy.presentRefreshResultResponse
            #expect(response?.newTransactionsCount == 0, "새 거래가 없어야 함")
        }
    }
    
    // MARK: - 거래 필터링 테스트
    
    @Suite("거래 필터링")
    struct FilterTransactions {
        
        @Test("전체 거래 필터")
        func testFilterTransactionsAll() {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let allTransactions = [
                createMockTransaction(hash: "0x111", amount: 1.0, isIncoming: true),
                createMockTransaction(hash: "0x222", amount: 2.0, isIncoming: false),
                createMockTransaction(hash: "0x333", amount: 3.0, isIncoming: true)
            ]
            
            let sut = HistoryInteractor(worker: workerSpy)
            sut.presenter = presenterSpy
            sut.currentTransactions = allTransactions
            
            let request = HistoryScene.FilterTransactions.Request(filterType: .all)
            
            // When
            sut.filterTransactions(request: request)
            
            // Then
            #expect(presenterSpy.presentFilteredTransactionsCalled == true, "Presenter가 호출되어야 함")
            
            let response = presenterSpy.presentFilteredTransactionsResponse
            #expect(response?.filteredTransactions.count == 3, "모든 거래가 반환되어야 함")
            #expect(response?.filterType == .all, "필터 타입이 전체여야 함")
            #expect(response?.totalCount == 3, "전체 개수가 3이어야 함")
            
            #expect(sut.currentFilter == .all, "현재 필터가 업데이트되어야 함")
            #expect(sut.filteredTransactions.count == 3, "필터링된 거래가 저장되어야 함")
        }
        
        @Test("받은 거래만 필터")
        func testFilterTransactionsReceived() {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let allTransactions = [
                createMockTransaction(hash: "0x111", amount: 1.0, isIncoming: true),
                createMockTransaction(hash: "0x222", amount: 2.0, isIncoming: false),
                createMockTransaction(hash: "0x333", amount: 3.0, isIncoming: true)
            ]
            
            let sut = HistoryInteractor(worker: workerSpy)
            sut.presenter = presenterSpy
            sut.currentTransactions = allTransactions
            
            let request = HistoryScene.FilterTransactions.Request(filterType: .received)
            
            // When
            sut.filterTransactions(request: request)
            
            // Then
            let response = presenterSpy.presentFilteredTransactionsResponse
            #expect(response?.filteredTransactions.count == 2, "받은 거래 2개만 반환되어야 함")
            #expect(response?.filterType == .received, "필터 타입이 received여야 함")
            
            // 모든 필터링된 거래가 받은 거래인지 확인
            let filteredTransactions = response?.filteredTransactions ?? []
            for transaction in filteredTransactions {
                #expect(transaction.isIncoming == true, "모든 거래가 받은 거래여야 함")
            }
        }
        
        @Test("보낸 거래만 필터")
        func testFilterTransactionsSent() {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let allTransactions = [
                createMockTransaction(hash: "0x111", amount: 1.0, isIncoming: true),
                createMockTransaction(hash: "0x222", amount: 2.0, isIncoming: false),
                createMockTransaction(hash: "0x333", amount: 3.0, isIncoming: true)
            ]
            
            let sut = HistoryInteractor(worker: workerSpy)
            sut.presenter = presenterSpy
            sut.currentTransactions = allTransactions
            
            let request = HistoryScene.FilterTransactions.Request(filterType: .sent)
            
            // When
            sut.filterTransactions(request: request)
            
            // Then
            let response = presenterSpy.presentFilteredTransactionsResponse
            #expect(response?.filteredTransactions.count == 1, "보낸 거래 1개만 반환되어야 함")
            #expect(response?.filterType == .sent, "필터 타입이 sent여야 함")
        }
        
        @Test("날짜 범위 필터")
        func testFilterTransactionsByDateRange() {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let calendar = Calendar.current
            let today = Date()
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
            
            let allTransactions = [
                createMockTransaction(hash: "0x111", amount: 1.0, date: today),
                createMockTransaction(hash: "0x222", amount: 2.0, date: yesterday),
                createMockTransaction(hash: "0x333", amount: 3.0, date: twoDaysAgo)
            ]
            
            let sut = HistoryInteractor(worker: workerSpy)
            sut.presenter = presenterSpy
            sut.currentTransactions = allTransactions
            
            let dateRange = DateRange(startDate: yesterday, endDate: today)
            let request = HistoryScene.FilterTransactions.Request(
                filterType: .all,
                dateRange: dateRange
            )
            
            // When
            sut.filterTransactions(request: request)
            
            // Then
            let response = presenterSpy.presentFilteredTransactionsResponse
            #expect(response?.filteredTransactions.count == 2, "날짜 범위 내 거래 2개만 반환되어야 함")
        }
    }
    
    // MARK: - 거래 내보내기 테스트
    
    @Suite("거래 내보내기")
    struct ExportTransactions {
        
        @Test("CSV 내보내기 성공")
        func testExportTransactionsCSVSuccess() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let transactions = [
                createMockTransaction(hash: "0x111", amount: 1.0),
                createMockTransaction(hash: "0x222", amount: 2.0)
            ]
            
            let csvData = "Hash,Amount\n0x111,1.0\n0x222,2.0".data(using: .utf8)!
            await workerSpy.setExportTransactionsResult(.success((data: csvData, fileName: "transactions.csv")))
            
            let sut = HistoryInteractor(worker: workerSpy)
            sut.presenter = presenterSpy
            
            let request = HistoryScene.ExportTransactions.Request(
                transactions: transactions,
                format: .csv
            )
            
            // When
            sut.exportTransactions(request: request)
            
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            // Then
            #expect(await workerSpy.exportTransactionsCalled == true, "Worker가 호출되어야 함")
            #expect(presenterSpy.presentExportResultCalled == true, "Presenter가 호출되어야 함")
            
            let response = presenterSpy.presentExportResultResponse
            #expect(response != nil, "Response가 전달되어야 함")
            #expect(response?.exportData != nil, "내보내기 데이터가 있어야 함")
            #expect(response?.fileName == "transactions.csv", "파일명이 일치해야 함")
            #expect(response?.format == .csv, "형식이 CSV여야 함")
            #expect(response?.error == nil, "에러가 없어야 함")
        }
        
        @Test("내보내기 실패")
        func testExportTransactionsFailure() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let transactions = [createMockTransaction(hash: "0x111", amount: 1.0)]
            let exportError = ExportError.dataConversionFailed
            await workerSpy.setExportTransactionsResult(.failure(exportError))
            
            let sut = HistoryInteractor(worker: workerSpy)
            sut.presenter = presenterSpy
            
            let request = HistoryScene.ExportTransactions.Request(
                transactions: transactions,
                format: .json
            )
            
            // When
            sut.exportTransactions(request: request)
            
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            // Then
            let response = presenterSpy.presentExportResultResponse
            #expect(response?.exportData == nil, "내보내기 데이터가 없어야 함")
            #expect(response?.error != nil, "에러가 전달되어야 함")
        }
    }
    
    // MARK: - Helper Methods
    
    private static func createMockTransaction(
        hash: String,
        amount: Double,
        isIncoming: Bool = true,
        date: Date = Date(),
        status: TransactionStatus = .confirmed
    ) -> Transaction {
        return Transaction(
            hash: hash,
            from: isIncoming ? "0xsender" : "0x742d35Cc6634C0Dcc6b9C2b48b9bC4C8b9d9aE3",
            to: isIncoming ? "0x742d35Cc6634C0Dcc6b9C2b48b9bC4C8b9d9aE3" : "0xrecipient",
            value: String(amount),
            gasPrice: "20000000000",
            gasUsed: "21000",
            blockNumber: "12345678",
            blockHash: "0xblockhash",
            transactionIndex: "0",
            date: date,
            status: status,
            symbol: "ETH",
            amount: Decimal(amount),
            gasFee: Decimal(0.0042),
            isIncoming: isIncoming
        )
    }
}

// MARK: - WorkerSpy Extensions

extension HistoryInteractorTests.WorkerSpy {
    func setFetchTransactionHistoryResult(_ result: Result<(transactions: [Transaction], hasMore: Bool), Error>) {
        fetchTransactionHistoryResult = result
    }
    
    func setFetchLatestTransactionsResult(_ result: Result<(transactions: [Transaction]), Error>) {
        fetchLatestTransactionsResult = result
    }
    
    func setExportTransactionsResult(_ result: Result<(data: Data, fileName: String), Error>) {
        exportTransactionsResult = result
    }
}