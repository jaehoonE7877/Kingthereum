import Testing
import Foundation
@testable import App
@testable import Entity
@testable import Core
@testable import WalletKit

@Suite("HistoryWorker 테스트")
struct HistoryWorkerTests {
    
    // MARK: - Mock Classes
    
    actor MockWalletService: WalletServiceProtocol {
        var getTransactionHistoryCalled = false
        var getTransactionHistoryResult: Result<[Transaction], WalletError> = .success([])
        var getTransactionHistoryWalletAddress: String?
        var getTransactionHistoryLimit: Int?
        var getTransactionHistoryOffset: Int?
        
        func getTransactionHistory(
            walletAddress: String,
            limit: Int,
            offset: Int
        ) async -> Result<[Transaction], WalletError> {
            getTransactionHistoryCalled = true
            getTransactionHistoryWalletAddress = walletAddress
            getTransactionHistoryLimit = limit
            getTransactionHistoryOffset = offset
            return getTransactionHistoryResult
        }
        
        var refreshTransactionsCalled = false
        var refreshTransactionsResult: Result<[Transaction], WalletError> = .success([])
        var refreshTransactionsWalletAddress: String?
        
        func refreshTransactions(walletAddress: String) async -> Result<[Transaction], WalletError> {
            refreshTransactionsCalled = true
            refreshTransactionsWalletAddress = walletAddress
            return refreshTransactionsResult
        }
    }
    
    actor MockDataExportService: DataExportServiceProtocol {
        var exportTransactionsCalled = false
        var exportTransactionsResult: Result<Data, ExportError> = .success(Data())
        var exportTransactionsTransactions: [Transaction]?
        var exportTransactionsFormat: ExportFormat?
        
        func exportTransactions(
            _ transactions: [Transaction],
            format: ExportFormat
        ) async -> Result<Data, ExportError> {
            exportTransactionsCalled = true
            exportTransactionsTransactions = transactions
            exportTransactionsFormat = format
            return exportTransactionsResult
        }
    }
    
    // MARK: - 거래 내역 조회 테스트
    
    @Suite("거래 내역 조회")
    struct GetTransactionHistory {
        
        @Test("성공 케이스 - 정상 데이터 반환")
        func testGetTransactionHistorySuccess() async {
            // Given
            let mockWalletService = MockWalletService()
            let mockDataExportService = MockDataExportService()
            
            let expectedTransactions = [
                Transaction(
                    hash: "0x123",
                    from: "0xabc",
                    to: "0xdef",
                    value: "1000000000000000000",
                    gasUsed: "21000",
                    gasPrice: "20000000000",
                    timestamp: Date(),
                    status: .success,
                    blockNumber: 12345678
                ),
                Transaction(
                    hash: "0x456",
                    from: "0xdef",
                    to: "0xabc",
                    value: "2000000000000000000",
                    gasUsed: "21000",
                    gasPrice: "25000000000",
                    timestamp: Date().addingTimeInterval(-3600),
                    status: .success,
                    blockNumber: 12345679
                )
            ]
            
            await mockWalletService.getTransactionHistoryResult = .success(expectedTransactions)
            
            let sut = HistoryWorker(
                walletService: mockWalletService,
                dataExportService: mockDataExportService
            )
            
            let request = HistoryWorkerRequest.GetTransactionHistory(
                walletAddress: "0xabc123",
                limit: 20,
                offset: 0
            )
            
            // When
            let result = await sut.getTransactionHistory(request: request)
            
            // Then
            switch result {
            case .success(let transactions):
                #expect(transactions.count == 2, "반환된 거래 수가 일치해야 함")
                #expect(transactions.first?.hash == "0x123", "첫 번째 거래 해시가 일치해야 함")
                #expect(transactions.last?.hash == "0x456", "마지막 거래 해시가 일치해야 함")
                
                // 파라미터 전달 검증
                #expect(await mockWalletService.getTransactionHistoryCalled == true, "WalletService가 호출되어야 함")
                #expect(await mockWalletService.getTransactionHistoryWalletAddress == "0xabc123", "지갑 주소가 올바르게 전달되어야 함")
                #expect(await mockWalletService.getTransactionHistoryLimit == 20, "제한 수가 올바르게 전달되어야 함")
                #expect(await mockWalletService.getTransactionHistoryOffset == 0, "오프셋이 올바르게 전달되어야 함")
                
            case .failure:
                Issue.record("거래 내역 조회가 성공해야 함")
            }
        }
        
        @Test("실패 케이스 - 네트워크 오류")
        func testGetTransactionHistoryNetworkError() async {
            // Given
            let mockWalletService = MockWalletService()
            let mockDataExportService = MockDataExportService()
            
            let networkError = WalletError.networkError("Connection timeout")
            await mockWalletService.getTransactionHistoryResult = .failure(networkError)
            
            let sut = HistoryWorker(
                walletService: mockWalletService,
                dataExportService: mockDataExportService
            )
            
            let request = HistoryWorkerRequest.GetTransactionHistory(
                walletAddress: "0xabc123",
                limit: 20,
                offset: 0
            )
            
            // When
            let result = await sut.getTransactionHistory(request: request)
            
            // Then
            switch result {
            case .success:
                Issue.record("네트워크 오류가 발생해야 함")
            case .failure(let error):
                #expect(
                    error as? WalletError == networkError,
                    "네트워크 오류가 반환되어야 함"
                )
                #expect(await mockWalletService.getTransactionHistoryCalled == true, "WalletService가 호출되어야 함")
            }
        }
        
        @Test("실패 케이스 - 잘못된 지갑 주소")
        func testGetTransactionHistoryInvalidWalletAddress() async {
            // Given
            let mockWalletService = MockWalletService()
            let mockDataExportService = MockDataExportService()
            
            let invalidAddressError = WalletError.invalidAddress
            await mockWalletService.getTransactionHistoryResult = .failure(invalidAddressError)
            
            let sut = HistoryWorker(
                walletService: mockWalletService,
                dataExportService: mockDataExportService
            )
            
            let request = HistoryWorkerRequest.GetTransactionHistory(
                walletAddress: "invalid-address",
                limit: 20,
                offset: 0
            )
            
            // When
            let result = await sut.getTransactionHistory(request: request)
            
            // Then
            switch result {
            case .success:
                Issue.record("잘못된 주소 오류가 발생해야 함")
            case .failure(let error):
                #expect(
                    error as? WalletError == WalletError.invalidAddress,
                    "잘못된 주소 오류가 반환되어야 함"
                )
            }
        }
        
        @Test("빈 결과 처리")
        func testGetTransactionHistoryEmptyResult() async {
            // Given
            let mockWalletService = MockWalletService()
            let mockDataExportService = MockDataExportService()
            
            await mockWalletService.getTransactionHistoryResult = .success([])
            
            let sut = HistoryWorker(
                walletService: mockWalletService,
                dataExportService: mockDataExportService
            )
            
            let request = HistoryWorkerRequest.GetTransactionHistory(
                walletAddress: "0xabc123",
                limit: 20,
                offset: 0
            )
            
            // When
            let result = await sut.getTransactionHistory(request: request)
            
            // Then
            switch result {
            case .success(let transactions):
                #expect(transactions.isEmpty == true, "빈 배열이 반환되어야 함")
                #expect(await mockWalletService.getTransactionHistoryCalled == true, "WalletService가 호출되어야 함")
                
            case .failure:
                Issue.record("빈 결과도 성공으로 처리되어야 함")
            }
        }
    }
    
    // MARK: - 거래 내역 새로고침 테스트
    
    @Suite("거래 내역 새로고침")
    struct RefreshTransactions {
        
        @Test("새로고침 성공 - 새 거래 있음")
        func testRefreshTransactionsWithNewTransactions() async {
            // Given
            let mockWalletService = MockWalletService()
            let mockDataExportService = MockDataExportService()
            
            let newTransactions = [
                Transaction(
                    hash: "0xnew1",
                    from: "0xabc",
                    to: "0xdef",
                    value: "500000000000000000",
                    gasUsed: "21000",
                    gasPrice: "30000000000",
                    timestamp: Date(),
                    status: .success,
                    blockNumber: 12345680
                ),
                Transaction(
                    hash: "0xnew2",
                    from: "0xdef",
                    to: "0xghi",
                    value: "1500000000000000000",
                    gasUsed: "21000",
                    gasPrice: "35000000000",
                    timestamp: Date().addingTimeInterval(-1800),
                    status: .success,
                    blockNumber: 12345681
                )
            ]
            
            await mockWalletService.refreshTransactionsResult = .success(newTransactions)
            
            let sut = HistoryWorker(
                walletService: mockWalletService,
                dataExportService: mockDataExportService
            )
            
            let request = HistoryWorkerRequest.RefreshTransactions(
                walletAddress: "0xabc123"
            )
            
            // When
            let result = await sut.refreshTransactions(request: request)
            
            // Then
            switch result {
            case .success(let transactions):
                #expect(transactions.count == 2, "새로운 거래 2개가 반환되어야 함")
                #expect(transactions.first?.hash == "0xnew1", "첫 번째 새 거래가 일치해야 함")
                #expect(await mockWalletService.refreshTransactionsCalled == true, "새로고침이 호출되어야 함")
                #expect(await mockWalletService.refreshTransactionsWalletAddress == "0xabc123", "지갑 주소가 전달되어야 함")
                
            case .failure:
                Issue.record("새로고침이 성공해야 함")
            }
        }
        
        @Test("새로고침 성공 - 새 거래 없음")
        func testRefreshTransactionsNoNewTransactions() async {
            // Given
            let mockWalletService = MockWalletService()
            let mockDataExportService = MockDataExportService()
            
            await mockWalletService.refreshTransactionsResult = .success([])
            
            let sut = HistoryWorker(
                walletService: mockWalletService,
                dataExportService: mockDataExportService
            )
            
            let request = HistoryWorkerRequest.RefreshTransactions(
                walletAddress: "0xabc123"
            )
            
            // When
            let result = await sut.refreshTransactions(request: request)
            
            // Then
            switch result {
            case .success(let transactions):
                #expect(transactions.isEmpty == true, "새로운 거래가 없어야 함")
                #expect(await mockWalletService.refreshTransactionsCalled == true, "새로고침이 호출되어야 함")
                
            case .failure:
                Issue.record("새 거래가 없어도 성공해야 함")
            }
        }
        
        @Test("새로고침 실패 - 네트워크 오류")
        func testRefreshTransactionsNetworkError() async {
            // Given
            let mockWalletService = MockWalletService()
            let mockDataExportService = MockDataExportService()
            
            let networkError = WalletError.networkError("Failed to refresh")
            await mockWalletService.refreshTransactionsResult = .failure(networkError)
            
            let sut = HistoryWorker(
                walletService: mockWalletService,
                dataExportService: mockDataExportService
            )
            
            let request = HistoryWorkerRequest.RefreshTransactions(
                walletAddress: "0xabc123"
            )
            
            // When
            let result = await sut.refreshTransactions(request: request)
            
            // Then
            switch result {
            case .success:
                Issue.record("네트워크 오류가 발생해야 함")
            case .failure(let error):
                #expect(
                    error as? WalletError == networkError,
                    "네트워크 오류가 반환되어야 함"
                )
            }
        }
    }
    
    // MARK: - 거래 내역 내보내기 테스트
    
    @Suite("거래 내역 내보내기")
    struct ExportTransactions {
        
        @Test("CSV 내보내기 성공")
        func testExportTransactionsCSVSuccess() async {
            // Given
            let mockWalletService = MockWalletService()
            let mockDataExportService = MockDataExportService()
            
            let transactions = [
                Transaction(
                    hash: "0x123",
                    from: "0xabc",
                    to: "0xdef",
                    value: "1000000000000000000",
                    gasUsed: "21000",
                    gasPrice: "20000000000",
                    timestamp: Date(),
                    status: .success,
                    blockNumber: 12345678
                )
            ]
            
            let expectedCSVData = "Hash,From,To,Value,Status\n0x123,0xabc,0xdef,1 ETH,Success".data(using: .utf8)!
            await mockDataExportService.exportTransactionsResult = .success(expectedCSVData)
            
            let sut = HistoryWorker(
                walletService: mockWalletService,
                dataExportService: mockDataExportService
            )
            
            let request = HistoryWorkerRequest.ExportTransactions(
                transactions: transactions,
                format: .csv
            )
            
            // When
            let result = await sut.exportTransactions(request: request)
            
            // Then
            switch result {
            case .success(let data):
                #expect(data == expectedCSVData, "CSV 데이터가 올바르게 반환되어야 함")
                #expect(await mockDataExportService.exportTransactionsCalled == true, "Export 서비스가 호출되어야 함")
                #expect(await mockDataExportService.exportTransactionsFormat == .csv, "CSV 형식이 전달되어야 함")
                
                // 전달된 거래 데이터 검증
                let exportedTransactions = await mockDataExportService.exportTransactionsTransactions
                #expect(exportedTransactions?.count == 1, "거래 데이터가 전달되어야 함")
                #expect(exportedTransactions?.first?.hash == "0x123", "거래 해시가 일치해야 함")
                
            case .failure:
                Issue.record("CSV 내보내기가 성공해야 함")
            }
        }
        
        @Test("JSON 내보내기 성공")
        func testExportTransactionsJSONSuccess() async {
            // Given
            let mockWalletService = MockWalletService()
            let mockDataExportService = MockDataExportService()
            
            let transactions = [
                Transaction(
                    hash: "0x456",
                    from: "0xdef",
                    to: "0xghi",
                    value: "2000000000000000000",
                    gasUsed: "21000",
                    gasPrice: "25000000000",
                    timestamp: Date(),
                    status: .success,
                    blockNumber: 12345679
                )
            ]
            
            let jsonData = try! JSONEncoder().encode(transactions)
            await mockDataExportService.exportTransactionsResult = .success(jsonData)
            
            let sut = HistoryWorker(
                walletService: mockWalletService,
                dataExportService: mockDataExportService
            )
            
            let request = HistoryWorkerRequest.ExportTransactions(
                transactions: transactions,
                format: .json
            )
            
            // When
            let result = await sut.exportTransactions(request: request)
            
            // Then
            switch result {
            case .success(let data):
                #expect(data == jsonData, "JSON 데이터가 올바르게 반환되어야 함")
                #expect(await mockDataExportService.exportTransactionsFormat == .json, "JSON 형식이 전달되어야 함")
                
            case .failure:
                Issue.record("JSON 내보내기가 성공해야 함")
            }
        }
        
        @Test("빈 거래 목록 내보내기")
        func testExportEmptyTransactionsList() async {
            // Given
            let mockWalletService = MockWalletService()
            let mockDataExportService = MockDataExportService()
            
            let emptyData = "No transactions to export".data(using: .utf8)!
            await mockDataExportService.exportTransactionsResult = .success(emptyData)
            
            let sut = HistoryWorker(
                walletService: mockWalletService,
                dataExportService: mockDataExportService
            )
            
            let request = HistoryWorkerRequest.ExportTransactions(
                transactions: [],
                format: .csv
            )
            
            // When
            let result = await sut.exportTransactions(request: request)
            
            // Then
            switch result {
            case .success(let data):
                #expect(data == emptyData, "빈 목록 메시지가 반환되어야 함")
                #expect(await mockDataExportService.exportTransactionsCalled == true, "Export 서비스가 호출되어야 함")
                
                let exportedTransactions = await mockDataExportService.exportTransactionsTransactions
                #expect(exportedTransactions?.isEmpty == true, "빈 배열이 전달되어야 함")
                
            case .failure:
                Issue.record("빈 목록 내보내기도 성공해야 함")
            }
        }
        
        @Test("내보내기 실패 - 파일 생성 오류")
        func testExportTransactionsFileError() async {
            // Given
            let mockWalletService = MockWalletService()
            let mockDataExportService = MockDataExportService()
            
            let fileError = ExportError.fileCreationFailed
            await mockDataExportService.exportTransactionsResult = .failure(fileError)
            
            let sut = HistoryWorker(
                walletService: mockWalletService,
                dataExportService: mockDataExportService
            )
            
            let transactions = [
                Transaction(
                    hash: "0x789",
                    from: "0xghi",
                    to: "0xjkl",
                    value: "3000000000000000000",
                    gasUsed: "21000",
                    gasPrice: "30000000000",
                    timestamp: Date(),
                    status: .success,
                    blockNumber: 12345680
                )
            ]
            
            let request = HistoryWorkerRequest.ExportTransactions(
                transactions: transactions,
                format: .pdf
            )
            
            // When
            let result = await sut.exportTransactions(request: request)
            
            // Then
            switch result {
            case .success:
                Issue.record("파일 생성 오류가 발생해야 함")
            case .failure(let error):
                #expect(
                    error as? ExportError == ExportError.fileCreationFailed,
                    "파일 생성 오류가 반환되어야 함"
                )
                #expect(await mockDataExportService.exportTransactionsCalled == true, "Export 서비스가 호출되어야 함")
            }
        }
        
        @Test("대용량 거래 내역 내보내기")
        func testExportLargeTransactionsList() async {
            // Given
            let mockWalletService = MockWalletService()
            let mockDataExportService = MockDataExportService()
            
            // 1000개의 거래 생성
            var largeTransactionsList: [Transaction] = []
            for i in 0..<1000 {
                let transaction = Transaction(
                    hash: "0x\(i)",
                    from: "0xabc\(i)",
                    to: "0xdef\(i)",
                    value: "\(i * 1000000000000000000)",
                    gasUsed: "21000",
                    gasPrice: "20000000000",
                    timestamp: Date().addingTimeInterval(TimeInterval(-i * 3600)),
                    status: .success,
                    blockNumber: 12345678 + i
                )
                largeTransactionsList.append(transaction)
            }
            
            let largeDataResult = "Large CSV data with 1000 transactions".data(using: .utf8)!
            await mockDataExportService.exportTransactionsResult = .success(largeDataResult)
            
            let sut = HistoryWorker(
                walletService: mockWalletService,
                dataExportService: mockDataExportService
            )
            
            let request = HistoryWorkerRequest.ExportTransactions(
                transactions: largeTransactionsList,
                format: .csv
            )
            
            // When
            let result = await sut.exportTransactions(request: request)
            
            // Then
            switch result {
            case .success(let data):
                #expect(data == largeDataResult, "대용량 데이터가 올바르게 반환되어야 함")
                
                let exportedTransactions = await mockDataExportService.exportTransactionsTransactions
                #expect(exportedTransactions?.count == 1000, "1000개 거래가 전달되어야 함")
                
            case .failure:
                Issue.record("대용량 데이터 내보내기가 성공해야 함")
            }
        }
    }
    
    // MARK: - 통합 테스트
    
    @Suite("Worker 통합 테스트")
    struct Integration {
        
        @Test("전체 워크플로우 - 조회 → 새로고침 → 내보내기")
        func testCompleteWorkflow() async {
            // Given
            let mockWalletService = MockWalletService()
            let mockDataExportService = MockDataExportService()
            
            let initialTransactions = [
                Transaction(
                    hash: "0xinitial",
                    from: "0xabc",
                    to: "0xdef",
                    value: "1000000000000000000",
                    gasUsed: "21000",
                    gasPrice: "20000000000",
                    timestamp: Date().addingTimeInterval(-7200),
                    status: .success,
                    blockNumber: 12345678
                )
            ]
            
            let refreshedTransactions = [
                Transaction(
                    hash: "0xrefreshed",
                    from: "0xdef",
                    to: "0xghi",
                    value: "2000000000000000000",
                    gasUsed: "21000",
                    gasPrice: "25000000000",
                    timestamp: Date(),
                    status: .success,
                    blockNumber: 12345679
                )
            ]
            
            let exportData = "Complete transaction history".data(using: .utf8)!
            
            await mockWalletService.getTransactionHistoryResult = .success(initialTransactions)
            await mockWalletService.refreshTransactionsResult = .success(refreshedTransactions)
            await mockDataExportService.exportTransactionsResult = .success(exportData)
            
            let sut = HistoryWorker(
                walletService: mockWalletService,
                dataExportService: mockDataExportService
            )
            
            let walletAddress = "0xabc123"
            
            // When & Then - 1단계: 초기 거래 내역 조회
            let getHistoryRequest = HistoryWorkerRequest.GetTransactionHistory(
                walletAddress: walletAddress,
                limit: 20,
                offset: 0
            )
            
            let getHistoryResult = await sut.getTransactionHistory(request: getHistoryRequest)
            
            switch getHistoryResult {
            case .success(let transactions):
                #expect(transactions.count == 1, "초기 거래 1개가 조회되어야 함")
                #expect(transactions.first?.hash == "0xinitial", "초기 거래 해시가 일치해야 함")
            case .failure:
                Issue.record("초기 거래 조회가 성공해야 함")
            }
            
            // When & Then - 2단계: 거래 내역 새로고침
            let refreshRequest = HistoryWorkerRequest.RefreshTransactions(
                walletAddress: walletAddress
            )
            
            let refreshResult = await sut.refreshTransactions(request: refreshRequest)
            
            switch refreshResult {
            case .success(let newTransactions):
                #expect(newTransactions.count == 1, "새로운 거래 1개가 조회되어야 함")
                #expect(newTransactions.first?.hash == "0xrefreshed", "새로운 거래 해시가 일치해야 함")
            case .failure:
                Issue.record("거래 새로고침이 성공해야 함")
            }
            
            // When & Then - 3단계: 전체 거래 내역 내보내기
            let allTransactions = initialTransactions + refreshedTransactions
            let exportRequest = HistoryWorkerRequest.ExportTransactions(
                transactions: allTransactions,
                format: .csv
            )
            
            let exportResult = await sut.exportTransactions(request: request: exportRequest)
            
            switch exportResult {
            case .success(let data):
                #expect(data == exportData, "내보내기 데이터가 일치해야 함")
                
                let exportedTransactions = await mockDataExportService.exportTransactionsTransactions
                #expect(exportedTransactions?.count == 2, "전체 거래 2개가 내보내져야 함")
                
            case .failure:
                Issue.record("거래 내보내기가 성공해야 함")
            }
            
            // 모든 서비스가 호출되었는지 확인
            #expect(await mockWalletService.getTransactionHistoryCalled == true, "거래 조회 서비스가 호출되어야 함")
            #expect(await mockWalletService.refreshTransactionsCalled == true, "새로고침 서비스가 호출되어야 함")
            #expect(await mockDataExportService.exportTransactionsCalled == true, "내보내기 서비스가 호출되어야 함")
        }
    }
}