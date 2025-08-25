import Testing
import Foundation
@testable import App
@testable import Entity
@testable import Core

// MARK: - HistoryPresenter Tests

@MainActor @Suite("HistoryPresenter 테스트")
struct HistoryPresenterTests {
    
    // MARK: - Spy Classes
    
    class DisplayLogicSpy: HistoryDisplayLogic {
        var displayTransactionHistoryCalled = false
        var displayTransactionHistoryViewModel: HistoryScene.LoadTransactionHistory.ViewModel?
        
        var displayRefreshResultCalled = false
        var displayRefreshResultViewModel: HistoryScene.RefreshTransactions.ViewModel?
        
        var displayFilteredTransactionsCalled = false
        var displayFilteredTransactionsViewModel: HistoryScene.FilterTransactions.ViewModel?
        
        var displayExportResultCalled = false
        var displayExportResultViewModel: HistoryScene.ExportTransactions.ViewModel?
        
        func displayTransactionHistory(viewModel: HistoryScene.LoadTransactionHistory.ViewModel) {
            displayTransactionHistoryCalled = true
            displayTransactionHistoryViewModel = viewModel
        }
        
        func displayRefreshResult(viewModel: HistoryScene.RefreshTransactions.ViewModel) {
            displayRefreshResultCalled = true
            displayRefreshResultViewModel = viewModel
        }
        
        func displayFilteredTransactions(viewModel: HistoryScene.FilterTransactions.ViewModel) {
            displayFilteredTransactionsCalled = true
            displayFilteredTransactionsViewModel = viewModel
        }
        
        func displayExportResult(viewModel: HistoryScene.ExportTransactions.ViewModel) {
            displayExportResultCalled = true
            displayExportResultViewModel = viewModel
        }
    }
    
    // MARK: - 거래 내역 표시 테스트
    
    @Suite("거래 내역 표시")
    struct PresentTransactionHistory {
        
        @Test("성공 케이스 - 거래 내역 포맷팅")
        func testPresentTransactionHistorySuccess() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = HistoryPresenter()
            sut.viewController = displayLogicSpy
            
            let transactions = [
                createMockTransaction(
                    hash: "0x742d35Cc6634C0Dcc6b9C2b48b9bC4C8b9d9aE3",
                    amount: 1.5,
                    isIncoming: true,
                    date: Date(timeIntervalSince1970: 1699200000) // 2023-11-05 18:13:20
                ),
                createMockTransaction(
                    hash: "0x123456789abcdef",
                    amount: 0.5,
                    isIncoming: false,
                    date: Date(timeIntervalSince1970: 1699100000)
                )
            ]
            
            let response = HistoryScene.LoadTransactionHistory.Response(
                transactions: transactions,
                hasMore: true,
                error: nil
            )
            
            // When
            sut.presentTransactionHistory(response: response)
            
            // Then
            #expect(displayLogicSpy.displayTransactionHistoryCalled == true, "Display 메서드가 호출되어야 함")
            
            let viewModel = displayLogicSpy.displayTransactionHistoryViewModel
            #expect(viewModel != nil, "ViewModel이 전달되어야 함")
            #expect(viewModel?.transactionViewModels.count == 2, "2개의 TransactionViewModel이 생성되어야 함")
            #expect(viewModel?.hasMoreTransactions == true, "더 많은 거래가 있음을 표시해야 함")
            #expect(viewModel?.isEmpty == false, "비어있지 않음을 표시해야 함")
            #expect(viewModel?.errorMessage == nil, "에러 메시지가 없어야 함")
            
            // 첫 번째 거래 (받은 거래) 검증
            let firstTransaction = viewModel?.transactionViewModels.first
            #expect(firstTransaction?.title == "받음", "받은 거래 타이틀이 올바른가")
            #expect(firstTransaction?.subtitle?.contains("0x742d...9aE3") == true, "주소가 단축 형식으로 표시되어야 함")
            #expect(firstTransaction?.statusIcon == "arrow.down.circle.fill", "받은 거래 아이콘이 올바른가")
            #expect(firstTransaction?.statusColor == "systemGreen", "받은 거래 색상이 올바른가")
            #expect(firstTransaction?.amount.contains("1.5") == true, "금액이 포함되어야 함")
            #expect(firstTransaction?.amount.contains("ETH") == true, "통화 단위가 포함되어야 함")
            #expect(firstTransaction?.isIncoming == true, "받은 거래임을 표시해야 함")
            
            // 두 번째 거래 (보낸 거래) 검증
            let secondTransaction = viewModel?.transactionViewModels[1]
            #expect(secondTransaction?.title == "보냄", "보낸 거래 타이틀이 올바른가")
            #expect(secondTransaction?.statusIcon == "arrow.up.circle.fill", "보낸 거래 아이콘이 올바른가")
            #expect(secondTransaction?.statusColor == "systemRed", "보낸 거래 색상이 올바른가")
            #expect(secondTransaction?.isIncoming == false, "보낸 거래임을 표시해야 함")
        }
        
        @Test("성공 케이스 - 빈 거래 목록")
        func testPresentTransactionHistoryEmpty() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = HistoryPresenter()
            sut.viewController = displayLogicSpy
            
            let response = HistoryScene.LoadTransactionHistory.Response(
                transactions: [],
                hasMore: false,
                error: nil
            )
            
            // When
            sut.presentTransactionHistory(response: response)
            
            // Then
            let viewModel = displayLogicSpy.displayTransactionHistoryViewModel
            #expect(viewModel?.transactionViewModels.isEmpty == true, "빈 목록이어야 함")
            #expect(viewModel?.hasMoreTransactions == false, "더 많은 거래가 없어야 함")
            #expect(viewModel?.isEmpty == true, "비어있음을 표시해야 함")
        }
        
        @Test("실패 케이스 - 에러 처리")
        func testPresentTransactionHistoryError() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = HistoryPresenter()
            sut.viewController = displayLogicSpy
            
            let networkError = NetworkError.noConnection
            let response = HistoryScene.LoadTransactionHistory.Response(
                transactions: [],
                hasMore: false,
                error: networkError
            )
            
            // When
            sut.presentTransactionHistory(response: response)
            
            // Then
            let viewModel = displayLogicSpy.displayTransactionHistoryViewModel
            #expect(viewModel?.transactionViewModels.isEmpty == true, "거래 목록이 비어있어야 함")
            #expect(viewModel?.errorMessage == "인터넷 연결을 확인해주세요", "사용자 친화적인 에러 메시지로 변환되어야 함")
        }
        
        @Test("거래 상태별 아이콘 및 색상")
        func testTransactionStatusIconsAndColors() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = HistoryPresenter()
            sut.viewController = displayLogicSpy
            
            let transactions = [
                createMockTransaction(hash: "0x111", status: .pending, isIncoming: true),
                createMockTransaction(hash: "0x222", status: .failed, isIncoming: false),
                createMockTransaction(hash: "0x333", status: .confirmed, isIncoming: true)
            ]
            
            let response = HistoryScene.LoadTransactionHistory.Response(
                transactions: transactions,
                hasMore: false,
                error: nil
            )
            
            // When
            sut.presentTransactionHistory(response: response)
            
            // Then
            let viewModels = displayLogicSpy.displayTransactionHistoryViewModel?.transactionViewModels ?? []
            #expect(viewModels.count == 3, "3개의 ViewModel이 생성되어야 함")
            
            // Pending 거래
            #expect(viewModels[0].statusIcon == "clock.circle.fill", "Pending 거래는 시계 아이콘이어야 함")
            #expect(viewModels[0].statusColor == "systemOrange", "Pending 거래는 주황색이어야 함")
            
            // Failed 거래
            #expect(viewModels[1].statusIcon == "exclamationmark.circle.fill", "Failed 거래는 느낌표 아이콘이어야 함")
            #expect(viewModels[1].statusColor == "systemRed", "Failed 거래는 빨간색이어야 함")
            
            // Confirmed 받은 거래
            #expect(viewModels[2].statusIcon == "arrow.down.circle.fill", "Confirmed 받은 거래는 아래 화살표 아이콘이어야 함")
            #expect(viewModels[2].statusColor == "systemGreen", "Confirmed 받은 거래는 초록색이어야 함")
        }
    }
    
    // MARK: - 새로고침 결과 표시 테스트
    
    @Suite("새로고침 결과 표시")
    struct PresentRefreshResult {
        
        @Test("성공 케이스 - 새로운 거래 있음")
        func testPresentRefreshResultWithNewTransactions() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = HistoryPresenter()
            sut.viewController = displayLogicSpy
            
            let transactions = [
                createMockTransaction(hash: "0x111", amount: 1.0),
                createMockTransaction(hash: "0x222", amount: 2.0)
            ]
            
            let response = HistoryScene.RefreshTransactions.Response(
                transactions: transactions,
                newTransactionsCount: 2,
                error: nil
            )
            
            // When
            sut.presentRefreshResult(response: response)
            
            // Then
            #expect(displayLogicSpy.displayRefreshResultCalled == true, "Display 메서드가 호출되어야 함")
            
            let viewModel = displayLogicSpy.displayRefreshResultViewModel
            #expect(viewModel != nil, "ViewModel이 전달되어야 함")
            #expect(viewModel?.transactionViewModels.count == 2, "2개의 거래가 표시되어야 함")
            #expect(viewModel?.refreshMessage == "2개의 새로운 거래가 있습니다", "새 거래 메시지가 올바른가")
            #expect(viewModel?.errorMessage == nil, "에러 메시지가 없어야 함")
        }
        
        @Test("성공 케이스 - 새로운 거래 없음")
        func testPresentRefreshResultWithoutNewTransactions() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = HistoryPresenter()
            sut.viewController = displayLogicSpy
            
            let transactions = [createMockTransaction(hash: "0x111", amount: 1.0)]
            
            let response = HistoryScene.RefreshTransactions.Response(
                transactions: transactions,
                newTransactionsCount: 0,
                error: nil
            )
            
            // When
            sut.presentRefreshResult(response: response)
            
            // Then
            let viewModel = displayLogicSpy.displayRefreshResultViewModel
            #expect(viewModel?.refreshMessage == "최신 상태입니다", "최신 상태 메시지가 표시되어야 함")
        }
        
        @Test("실패 케이스 - 새로고침 에러")
        func testPresentRefreshResultError() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = HistoryPresenter()
            sut.viewController = displayLogicSpy
            
            let timeoutError = NetworkError.timeout
            let response = HistoryScene.RefreshTransactions.Response(
                transactions: [],
                newTransactionsCount: 0,
                error: timeoutError
            )
            
            // When
            sut.presentRefreshResult(response: response)
            
            // Then
            let viewModel = displayLogicSpy.displayRefreshResultViewModel
            #expect(viewModel?.transactionViewModels.isEmpty == true, "거래 목록이 비어있어야 함")
            #expect(viewModel?.errorMessage == "요청 시간이 초과되었습니다", "타임아웃 에러 메시지가 표시되어야 함")
            #expect(viewModel?.refreshMessage == nil, "새로고침 메시지가 없어야 함")
        }
    }
    
    // MARK: - 필터링된 거래 표시 테스트
    
    @Suite("필터링된 거래 표시")
    struct PresentFilteredTransactions {
        
        @Test("필터링 결과 포맷팅")
        func testPresentFilteredTransactions() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = HistoryPresenter()
            sut.viewController = displayLogicSpy
            
            let filteredTransactions = [
                createMockTransaction(hash: "0x111", amount: 1.0, isIncoming: true),
                createMockTransaction(hash: "0x222", amount: 2.0, isIncoming: true)
            ]
            
            let response = HistoryScene.FilterTransactions.Response(
                filteredTransactions: filteredTransactions,
                filterType: .received,
                totalCount: 10
            )
            
            // When
            sut.presentFilteredTransactions(response: response)
            
            // Then
            #expect(displayLogicSpy.displayFilteredTransactionsCalled == true, "Display 메서드가 호출되어야 함")
            
            let viewModel = displayLogicSpy.displayFilteredTransactionsViewModel
            #expect(viewModel != nil, "ViewModel이 전달되어야 함")
            #expect(viewModel?.transactionViewModels.count == 2, "2개의 필터링된 거래가 표시되어야 함")
            #expect(viewModel?.filterTitle == "받음", "필터 타이틀이 올바른가")
            #expect(viewModel?.resultCount == "2 / 10", "결과 개수가 올바르게 포맷되어야 함")
            #expect(viewModel?.isEmpty == false, "비어있지 않음을 표시해야 함")
        }
        
        @Test("빈 필터링 결과")
        func testPresentFilteredTransactionsEmpty() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = HistoryPresenter()
            sut.viewController = displayLogicSpy
            
            let response = HistoryScene.FilterTransactions.Response(
                filteredTransactions: [],
                filterType: .failed,
                totalCount: 5
            )
            
            // When
            sut.presentFilteredTransactions(response: response)
            
            // Then
            let viewModel = displayLogicSpy.displayFilteredTransactionsViewModel
            #expect(viewModel?.transactionViewModels.isEmpty == true, "빈 목록이어야 함")
            #expect(viewModel?.filterTitle == "실패", "필터 타이틀이 올바른가")
            #expect(viewModel?.resultCount == "0 / 5", "빈 결과 개수가 올바르게 표시되어야 함")
            #expect(viewModel?.isEmpty == true, "비어있음을 표시해야 함")
        }
    }
    
    // MARK: - 내보내기 결과 표시 테스트
    
    @Suite("내보내기 결과 표시")
    struct PresentExportResult {
        
        @Test("성공 케이스 - CSV 내보내기")
        func testPresentExportResultCSVSuccess() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = HistoryPresenter()
            sut.viewController = displayLogicSpy
            
            let csvData = "Hash,Amount\n0x111,1.0".data(using: .utf8)!
            let response = HistoryScene.ExportTransactions.Response(
                exportData: csvData,
                fileName: "transactions_2023.csv",
                format: .csv,
                error: nil
            )
            
            // When
            sut.presentExportResult(response: response)
            
            // Then
            #expect(displayLogicSpy.displayExportResultCalled == true, "Display 메서드가 호출되어야 함")
            
            let viewModel = displayLogicSpy.displayExportResultViewModel
            #expect(viewModel != nil, "ViewModel이 전달되어야 함")
            #expect(viewModel?.shareItems.isEmpty == false, "공유 아이템이 있어야 함")
            #expect(viewModel?.successMessage == "CSV 파일이 생성되었습니다", "성공 메시지가 올바른가")
            #expect(viewModel?.errorMessage == nil, "에러 메시지가 없어야 함")
        }
        
        @Test("성공 케이스 - JSON 내보내기")
        func testPresentExportResultJSONSuccess() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = HistoryPresenter()
            sut.viewController = displayLogicSpy
            
            let jsonData = "{\"transactions\": []}".data(using: .utf8)!
            let response = HistoryScene.ExportTransactions.Response(
                exportData: jsonData,
                fileName: "transactions.json",
                format: .json,
                error: nil
            )
            
            // When
            sut.presentExportResult(response: response)
            
            // Then
            let viewModel = displayLogicSpy.displayExportResultViewModel
            #expect(viewModel?.successMessage == "JSON 파일이 생성되었습니다", "JSON 성공 메시지가 올바른가")
        }
        
        @Test("실패 케이스 - 내보내기 에러")
        func testPresentExportResultError() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = HistoryPresenter()
            sut.viewController = displayLogicSpy
            
            let exportError = ExportError.dataConversionFailed
            let response = HistoryScene.ExportTransactions.Response(
                exportData: nil,
                fileName: "",
                format: .pdf,
                error: exportError
            )
            
            // When
            sut.presentExportResult(response: response)
            
            // Then
            let viewModel = displayLogicSpy.displayExportResultViewModel
            #expect(viewModel?.shareItems.isEmpty == true, "공유 아이템이 없어야 함")
            #expect(viewModel?.successMessage == nil, "성공 메시지가 없어야 함")
            #expect(viewModel?.errorMessage == "데이터 변환에 실패했습니다", "에러 메시지가 올바르게 표시되어야 함")
        }
        
        @Test("실패 케이스 - 데이터 없음")
        func testPresentExportResultNoData() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = HistoryPresenter()
            sut.viewController = displayLogicSpy
            
            let response = HistoryScene.ExportTransactions.Response(
                exportData: nil,
                fileName: "test.csv",
                format: .csv,
                error: nil
            )
            
            // When
            sut.presentExportResult(response: response)
            
            // Then
            let viewModel = displayLogicSpy.displayExportResultViewModel
            #expect(viewModel?.shareItems.isEmpty == true, "공유 아이템이 없어야 함")
            #expect(viewModel?.errorMessage == "내보내기 데이터를 생성할 수 없습니다", "데이터 없음 에러 메시지가 표시되어야 함")
        }
    }
    
    // MARK: - 주소 및 금액 포맷팅 테스트
    
    @Suite("포맷팅 기능")
    struct FormattingFunctions {
        
        @Test("주소 단축 포맷팅")
        func testAddressFormatting() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = HistoryPresenter()
            sut.viewController = displayLogicSpy
            
            let longAddress = "0x742d35Cc6634C0Dcc6b9C2b48b9bC4C8b9d9aE3"
            let shortAddress = "0x123"
            
            let transactions = [
                createMockTransaction(hash: longAddress, from: longAddress),
                createMockTransaction(hash: shortAddress, from: shortAddress)
            ]
            
            let response = HistoryScene.LoadTransactionHistory.Response(
                transactions: transactions,
                hasMore: false,
                error: nil
            )
            
            // When
            sut.presentTransactionHistory(response: response)
            
            // Then
            let viewModels = displayLogicSpy.displayTransactionHistoryViewModel?.transactionViewModels ?? []
            
            // 긴 주소는 단축되어야 함
            #expect(viewModels[0].subtitle?.contains("0x742d...9aE3") == true, "긴 주소가 단축 형식으로 표시되어야 함")
            
            // 짧은 주소는 그대로 표시되어야 함
            #expect(viewModels[1].subtitle?.contains("0x123") == true, "짧은 주소는 그대로 표시되어야 함")
        }
        
        @Test("금액 포맷팅")
        func testAmountFormatting() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = HistoryPresenter()
            sut.viewController = displayLogicSpy
            
            let transactions = [
                createMockTransaction(hash: "0x111", amount: 1.234567890123456), // 소수점 많은 경우
                createMockTransaction(hash: "0x222", amount: 1000.0),           // 큰 정수
                createMockTransaction(hash: "0x333", amount: 0.0001),           // 작은 소수
                createMockTransaction(hash: "0x444", amount: 0.0, symbol: "USDT") // 다른 토큰
            ]
            
            let response = HistoryScene.LoadTransactionHistory.Response(
                transactions: transactions,
                hasMore: false,
                error: nil
            )
            
            // When
            sut.presentTransactionHistory(response: response)
            
            // Then
            let viewModels = displayLogicSpy.displayTransactionHistoryViewModel?.transactionViewModels ?? []
            #expect(viewModels.count == 4, "4개의 ViewModel이 생성되어야 함")
            
            // 각 금액이 적절히 포맷되었는지 확인
            #expect(viewModels[0].amount.contains("1.2345678") == true, "소수점이 적절히 표시되어야 함")
            #expect(viewModels[0].amount.contains("ETH") == true, "기본 통화 단위가 표시되어야 함")
            
            #expect(viewModels[1].amount.contains("1,000") == true, "큰 수는 콤마로 구분되어야 함")
            
            #expect(viewModels[2].amount.contains("0.0001") == true, "작은 소수가 정확히 표시되어야 함")
            
            #expect(viewModels[3].amount.contains("USDT") == true, "다른 토큰 단위가 표시되어야 함")
        }
        
        @Test("에러 메시지 현지화")
        func testErrorMessageLocalization() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = HistoryPresenter()
            sut.viewController = displayLogicSpy
            
            let networkErrors = [
                NetworkError.noConnection,
                NetworkError.timeout,
                NetworkError.serverError
            ]
            
            let expectedMessages = [
                "인터넷 연결을 확인해주세요",
                "요청 시간이 초과되었습니다",
                "서버 오류가 발생했습니다"
            ]
            
            // When & Then
            for (index, error) in networkErrors.enumerated() {
                let response = HistoryScene.LoadTransactionHistory.Response(
                    transactions: [],
                    hasMore: false,
                    error: error
                )
                
                sut.presentTransactionHistory(response: response)
                
                let viewModel = displayLogicSpy.displayTransactionHistoryViewModel
                #expect(viewModel?.errorMessage == expectedMessages[index], "\(error) 에러 메시지가 올바르게 현지화되어야 함")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private static func createMockTransaction(
        hash: String,
        amount: Double = 1.0,
        isIncoming: Bool = true,
        date: Date = Date(),
        status: TransactionStatus = .confirmed,
        from: String? = nil,
        symbol: String = "ETH"
    ) -> Transaction {
        return Transaction(
            hash: hash,
            from: from ?? (isIncoming ? "0xsender" : "0x742d35Cc6634C0Dcc6b9C2b48b9bC4C8b9d9aE3"),
            to: isIncoming ? "0x742d35Cc6634C0Dcc6b9C2b48b9bC4C8b9d9aE3" : "0xrecipient",
            value: String(amount),
            gasPrice: "20000000000",
            gasUsed: "21000",
            blockNumber: "12345678",
            blockHash: "0xblockhash",
            transactionIndex: "0",
            date: date,
            status: status,
            symbol: symbol,
            amount: Decimal(amount),
            gasFee: Decimal(0.0042),
            isIncoming: isIncoming
        )
    }
}