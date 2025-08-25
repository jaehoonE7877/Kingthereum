import Testing
import SwiftUI
import Foundation
@testable import App
@testable import Core
@testable import Entity

@MainActor @Suite("HistoryRouter 테스트")
struct HistoryRouterTests {
    
    // MARK: - Mock Classes
    
    class MockHistoryDataStore: HistoryDataStore {
        var currentTransactions: [Transaction] = []
        var filteredTransactions: [Transaction] = []
        var currentFilter: TransactionFilterType = .all
        var isLoading: Bool = false
        var isLoadingMore: Bool = false
        var hasMoreTransactions: Bool = false
        var walletAddress: String = ""
        var selectedTransaction: Transaction?
        var exportData: Data?
    }
    
    class MockNavigationController: ObservableObject {
        @Published var navigationPath: [AnyHashable] = []
        @Published var presentedSheet: AnyHashable?
        @Published var presentedFullScreen: AnyHashable?
        
        var pushCalled = false
        var presentSheetCalled = false
        var presentFullScreenCalled = false
        var dismissCalled = false
        
        func push(_ destination: AnyHashable) {
            pushCalled = true
            navigationPath.append(destination)
        }
        
        func presentSheet(_ sheet: AnyHashable) {
            presentSheetCalled = true
            presentedSheet = sheet
        }
        
        func presentFullScreen(_ screen: AnyHashable) {
            presentFullScreenCalled = true
            presentedFullScreen = screen
        }
        
        func dismiss() {
            dismissCalled = true
            presentedSheet = nil
            presentedFullScreen = nil
        }
        
        func popToRoot() {
            navigationPath.removeAll()
        }
    }
    
    // MARK: - 기본 라우팅 테스트
    
    @Suite("기본 화면 전환")
    struct BasicNavigation {
        
        @Test("홈 화면으로 이동")
        func testRouteToHome() {
            // Given
            let mockDataStore = MockHistoryDataStore()
            let mockNavigationController = MockNavigationController()
            let sut = HistoryRouter(
                dataStore: mockDataStore,
                navigationController: mockNavigationController
            )
            
            // When
            sut.routeToHome()
            
            // Then
            #expect(mockNavigationController.pushCalled == true, "Push 네비게이션이 호출되어야 함")
            #expect(mockNavigationController.navigationPath.count == 1, "네비게이션 경로에 1개 항목이 추가되어야 함")
            
            if let destination = mockNavigationController.navigationPath.first as? String {
                #expect(destination == "Home", "홈 화면 경로가 설정되어야 함")
            } else {
                Issue.record("네비게이션 경로가 올바르지 않음")
            }
        }
        
        @Test("송금 화면으로 이동")
        func testRouteToSend() {
            // Given
            let mockDataStore = MockHistoryDataStore()
            mockDataStore.walletAddress = "0xabc123"
            
            let mockNavigationController = MockNavigationController()
            let sut = HistoryRouter(
                dataStore: mockDataStore,
                navigationController: mockNavigationController
            )
            
            // When
            sut.routeToSend()
            
            // Then
            #expect(mockNavigationController.pushCalled == true, "Push 네비게이션이 호출되어야 함")
            #expect(mockNavigationController.navigationPath.count == 1, "네비게이션 경로에 1개 항목이 추가되어야 함")
            
            if let destination = mockNavigationController.navigationPath.first as? SendDestination {
                #expect(destination.walletAddress == "0xabc123", "지갑 주소가 전달되어야 함")
            } else {
                Issue.record("송금 화면 경로가 올바르지 않음")
            }
        }
        
        @Test("수신 화면으로 이동")
        func testRouteToReceive() {
            // Given
            let mockDataStore = MockHistoryDataStore()
            mockDataStore.walletAddress = "0xdef456"
            
            let mockNavigationController = MockNavigationController()
            let sut = HistoryRouter(
                dataStore: mockDataStore,
                navigationController: mockNavigationController
            )
            
            // When
            sut.routeToReceive()
            
            // Then
            #expect(mockNavigationController.pushCalled == true, "Push 네비게이션이 호출되어야 함")
            #expect(mockNavigationController.navigationPath.count == 1, "네비게이션 경로에 1개 항목이 추가되어야 함")
            
            if let destination = mockNavigationController.navigationPath.first as? ReceiveDestination {
                #expect(destination.walletAddress == "0xdef456", "지갑 주소가 전달되어야 함")
            } else {
                Issue.record("수신 화면 경로가 올바르지 않음")
            }
        }
    }
    
    // MARK: - 거래 상세 화면 테스트
    
    @Suite("거래 상세 화면")
    struct TransactionDetail {
        
        @Test("거래 상세 화면으로 이동 - 정상 케이스")
        func testRouteToTransactionDetailSuccess() {
            // Given
            let mockDataStore = MockHistoryDataStore()
            let transaction = Transaction(
                hash: "0x123abc",
                from: "0xabc123",
                to: "0xdef456",
                value: "1000000000000000000",
                gasUsed: "21000",
                gasPrice: "20000000000",
                timestamp: Date(),
                status: .success,
                blockNumber: 12345678
            )
            mockDataStore.selectedTransaction = transaction
            
            let mockNavigationController = MockNavigationController()
            let sut = HistoryRouter(
                dataStore: mockDataStore,
                navigationController: mockNavigationController
            )
            
            // When
            sut.routeToTransactionDetail(transactionHash: "0x123abc")
            
            // Then
            #expect(mockNavigationController.pushCalled == true, "Push 네비게이션이 호출되어야 함")
            #expect(mockNavigationController.navigationPath.count == 1, "네비게이션 경로에 1개 항목이 추가되어야 함")
            #expect(mockDataStore.selectedTransaction?.hash == "0x123abc", "선택된 거래가 DataStore에 설정되어야 함")
            
            if let destination = mockNavigationController.navigationPath.first as? TransactionDetailDestination {
                #expect(destination.transactionHash == "0x123abc", "거래 해시가 전달되어야 함")
                #expect(destination.transaction?.hash == "0x123abc", "거래 객체가 전달되어야 함")
            } else {
                Issue.record("거래 상세 화면 경로가 올바르지 않음")
            }
        }
        
        @Test("거래 상세 화면으로 이동 - 해시만 있는 케이스")
        func testRouteToTransactionDetailHashOnly() {
            // Given
            let mockDataStore = MockHistoryDataStore()
            let mockNavigationController = MockNavigationController()
            let sut = HistoryRouter(
                dataStore: mockDataStore,
                navigationController: mockNavigationController
            )
            
            // When
            sut.routeToTransactionDetail(transactionHash: "0xunknown")
            
            // Then
            #expect(mockNavigationController.pushCalled == true, "Push 네비게이션이 호출되어야 함")
            #expect(mockNavigationController.navigationPath.count == 1, "네비게이션 경로에 1개 항목이 추가되어야 함")
            
            if let destination = mockNavigationController.navigationPath.first as? TransactionDetailDestination {
                #expect(destination.transactionHash == "0xunknown", "거래 해시가 전달되어야 함")
                #expect(destination.transaction == nil, "알 수 없는 거래는 nil이어야 함")
            } else {
                Issue.record("거래 상세 화면 경로가 올바르지 않음")
            }
        }
        
        @Test("빈 해시로 거래 상세 화면 이동 시도")
        func testRouteToTransactionDetailEmptyHash() {
            // Given
            let mockDataStore = MockHistoryDataStore()
            let mockNavigationController = MockNavigationController()
            let sut = HistoryRouter(
                dataStore: mockDataStore,
                navigationController: mockNavigationController
            )
            
            // When
            sut.routeToTransactionDetail(transactionHash: "")
            
            // Then
            #expect(mockNavigationController.pushCalled == false, "빈 해시로는 네비게이션이 호출되지 않아야 함")
            #expect(mockNavigationController.navigationPath.isEmpty == true, "네비게이션 경로가 추가되지 않아야 함")
        }
    }
    
    // MARK: - 필터 화면 테스트
    
    @Suite("필터 설정 화면")
    struct FilterSettings {
        
        @Test("필터 설정 화면 모달 표시")
        func testRouteToFilterSettings() {
            // Given
            let mockDataStore = MockHistoryDataStore()
            mockDataStore.currentFilter = .incoming
            
            let mockNavigationController = MockNavigationController()
            let sut = HistoryRouter(
                dataStore: mockDataStore,
                navigationController: mockNavigationController
            )
            
            // When
            sut.routeToFilterSettings()
            
            // Then
            #expect(mockNavigationController.presentSheetCalled == true, "시트 표시가 호출되어야 함")
            
            if let presentedSheet = mockNavigationController.presentedSheet as? FilterSettingsDestination {
                #expect(presentedSheet.currentFilter == .incoming, "현재 필터가 전달되어야 함")
            } else {
                Issue.record("필터 설정 시트가 올바르지 않음")
            }
        }
        
        @Test("필터 설정 완료 후 화면 닫기")
        func testDismissFilterSettings() {
            // Given
            let mockDataStore = MockHistoryDataStore()
            let mockNavigationController = MockNavigationController()
            mockNavigationController.presentedSheet = FilterSettingsDestination(currentFilter: .all)
            
            let sut = HistoryRouter(
                dataStore: mockDataStore,
                navigationController: mockNavigationController
            )
            
            // When
            sut.dismissFilterSettings()
            
            // Then
            #expect(mockNavigationController.dismissCalled == true, "화면 닫기가 호출되어야 함")
            #expect(mockNavigationController.presentedSheet == nil, "표시된 시트가 제거되어야 함")
        }
    }
    
    // MARK: - 내보내기 화면 테스트
    
    @Suite("내보내기 옵션")
    struct ExportOptions {
        
        @Test("내보내기 옵션 화면 표시")
        func testRouteToExportOptions() {
            // Given
            let mockDataStore = MockHistoryDataStore()
            let transactions = [
                Transaction(
                    hash: "0x111",
                    from: "0xaaa",
                    to: "0xbbb",
                    value: "1000000000000000000",
                    gasUsed: "21000",
                    gasPrice: "20000000000",
                    timestamp: Date(),
                    status: .success,
                    blockNumber: 12345678
                ),
                Transaction(
                    hash: "0x222",
                    from: "0xbbb",
                    to: "0xccc",
                    value: "2000000000000000000",
                    gasUsed: "21000",
                    gasPrice: "25000000000",
                    timestamp: Date().addingTimeInterval(-3600),
                    status: .success,
                    blockNumber: 12345679
                )
            ]
            mockDataStore.filteredTransactions = transactions
            
            let mockNavigationController = MockNavigationController()
            let sut = HistoryRouter(
                dataStore: mockDataStore,
                navigationController: mockNavigationController
            )
            
            // When
            sut.routeToExportOptions()
            
            // Then
            #expect(mockNavigationController.presentSheetCalled == true, "시트 표시가 호출되어야 함")
            
            if let presentedSheet = mockNavigationController.presentedSheet as? ExportOptionsDestination {
                #expect(presentedSheet.transactions.count == 2, "필터된 거래들이 전달되어야 함")
                #expect(presentedSheet.transactions.first?.hash == "0x111", "첫 번째 거래가 일치해야 함")
                #expect(presentedSheet.transactions.last?.hash == "0x222", "마지막 거래가 일치해야 함")
            } else {
                Issue.record("내보내기 옵션 시트가 올바르지 않음")
            }
        }
        
        @Test("빈 거래 목록으로 내보내기 시도")
        func testRouteToExportOptionsEmptyTransactions() {
            // Given
            let mockDataStore = MockHistoryDataStore()
            mockDataStore.filteredTransactions = []
            
            let mockNavigationController = MockNavigationController()
            let sut = HistoryRouter(
                dataStore: mockDataStore,
                navigationController: mockNavigationController
            )
            
            // When
            sut.routeToExportOptions()
            
            // Then
            #expect(mockNavigationController.presentSheetCalled == false, "빈 목록으로는 내보내기 시트가 표시되지 않아야 함")
            #expect(mockNavigationController.presentedSheet == nil, "시트가 표시되지 않아야 함")
        }
        
        @Test("내보내기 완료 후 공유 화면 표시")
        func testRouteToShareExportedData() {
            // Given
            let mockDataStore = MockHistoryDataStore()
            let exportedData = "Exported transaction data".data(using: .utf8)!
            mockDataStore.exportData = exportedData
            
            let mockNavigationController = MockNavigationController()
            let sut = HistoryRouter(
                dataStore: mockDataStore,
                navigationController: mockNavigationController
            )
            
            // When
            sut.routeToShareExportedData(fileName: "transactions.csv", format: .csv)
            
            // Then
            #expect(mockNavigationController.presentSheetCalled == true, "공유 시트가 표시되어야 함")
            
            if let presentedSheet = mockNavigationController.presentedSheet as? ShareDestination {
                #expect(presentedSheet.fileName == "transactions.csv", "파일명이 전달되어야 함")
                #expect(presentedSheet.data == exportedData, "내보낸 데이터가 전달되어야 함")
                #expect(presentedSheet.format == .csv, "파일 형식이 전달되어야 함")
            } else {
                Issue.record("공유 화면이 올바르지 않음")
            }
        }
        
        @Test("내보낸 데이터가 없을 때 공유 시도")
        func testRouteToShareExportedDataNoData() {
            // Given
            let mockDataStore = MockHistoryDataStore()
            mockDataStore.exportData = nil
            
            let mockNavigationController = MockNavigationController()
            let sut = HistoryRouter(
                dataStore: mockDataStore,
                navigationController: mockNavigationController
            )
            
            // When
            sut.routeToShareExportedData(fileName: "transactions.csv", format: .csv)
            
            // Then
            #expect(mockNavigationController.presentSheetCalled == false, "데이터가 없으면 공유 시트가 표시되지 않아야 함")
            #expect(mockNavigationController.presentedSheet == nil, "시트가 표시되지 않아야 함")
        }
    }
    
    // MARK: - 데이터 전달 테스트
    
    @Suite("데이터 전달 검증")
    struct DataPassing {
        
        @Test("DataStore 프로퍼티 설정 검증")
        func testDataStorePropertiesUpdate() {
            // Given
            let mockDataStore = MockHistoryDataStore()
            let mockNavigationController = MockNavigationController()
            let sut = HistoryRouter(
                dataStore: mockDataStore,
                navigationController: mockNavigationController
            )
            
            let testTransaction = Transaction(
                hash: "0xtest",
                from: "0xfrom",
                to: "0xto",
                value: "1000000000000000000",
                gasUsed: "21000",
                gasPrice: "20000000000",
                timestamp: Date(),
                status: .success,
                blockNumber: 12345678
            )
            
            // When
            sut.updateSelectedTransaction(testTransaction)
            
            // Then
            #expect(mockDataStore.selectedTransaction?.hash == "0xtest", "선택된 거래가 DataStore에 설정되어야 함")
            #expect(mockDataStore.selectedTransaction?.from == "0xfrom", "송신자 주소가 일치해야 함")
            #expect(mockDataStore.selectedTransaction?.to == "0xto", "수신자 주소가 일치해야 함")
        }
        
        @Test("Export 데이터 설정 검증")
        func testExportDataUpdate() {
            // Given
            let mockDataStore = MockHistoryDataStore()
            let mockNavigationController = MockNavigationController()
            let sut = HistoryRouter(
                dataStore: mockDataStore,
                navigationController: mockNavigationController
            )
            
            let exportData = "Test export data".data(using: .utf8)!
            
            // When
            sut.updateExportData(exportData)
            
            // Then
            #expect(mockDataStore.exportData == exportData, "내보내기 데이터가 DataStore에 설정되어야 함")
        }
        
        @Test("여러 프로퍼티 동시 업데이트")
        func testMultiplePropertiesUpdate() {
            // Given
            let mockDataStore = MockHistoryDataStore()
            let mockNavigationController = MockNavigationController()
            let sut = HistoryRouter(
                dataStore: mockDataStore,
                navigationController: mockNavigationController
            )
            
            let transactions = [
                Transaction(
                    hash: "0x1",
                    from: "0xa",
                    to: "0xb",
                    value: "1000000000000000000",
                    gasUsed: "21000",
                    gasPrice: "20000000000",
                    timestamp: Date(),
                    status: .success,
                    blockNumber: 12345678
                )
            ]
            
            // When
            sut.updateFilteredTransactions(transactions)
            sut.updateCurrentFilter(.outgoing)
            sut.updateWalletAddress("0xwallet123")
            
            // Then
            #expect(mockDataStore.filteredTransactions.count == 1, "필터된 거래가 설정되어야 함")
            #expect(mockDataStore.currentFilter == .outgoing, "필터가 업데이트되어야 함")
            #expect(mockDataStore.walletAddress == "0xwallet123", "지갑 주소가 업데이트되어야 함")
        }
    }
    
    // MARK: - 에러 처리 테스트
    
    @Suite("에러 처리")
    struct ErrorHandling {
        
        @Test("잘못된 거래 해시로 라우팅 시도")
        func testRouteWithInvalidTransactionHash() {
            // Given
            let mockDataStore = MockHistoryDataStore()
            let mockNavigationController = MockNavigationController()
            let sut = HistoryRouter(
                dataStore: mockDataStore,
                navigationController: mockNavigationController
            )
            
            // When & Then - nil 해시
            sut.routeToTransactionDetail(transactionHash: nil)
            #expect(mockNavigationController.pushCalled == false, "nil 해시로는 네비게이션이 호출되지 않아야 함")
            
            // When & Then - 빈 해시
            sut.routeToTransactionDetail(transactionHash: "")
            #expect(mockNavigationController.pushCalled == false, "빈 해시로는 네비게이션이 호출되지 않아야 함")
            
            // When & Then - 잘못된 형식 해시
            sut.routeToTransactionDetail(transactionHash: "invalid")
            #expect(mockNavigationController.pushCalled == false, "잘못된 형식 해시로는 네비게이션이 호출되지 않아야 함")
        }
        
        @Test("네비게이션 컨트롤러가 nil인 경우")
        func testNavigationControllerNil() {
            // Given
            let mockDataStore = MockHistoryDataStore()
            let sut = HistoryRouter(
                dataStore: mockDataStore,
                navigationController: nil
            )
            
            // When & Then - 에러가 발생하지 않아야 함
            sut.routeToHome()
            sut.routeToSend()
            sut.routeToReceive()
            sut.routeToFilterSettings()
            sut.routeToExportOptions()
            
            // 에러가 발생하지 않으면 테스트 성공
            #expect(true, "네비게이션 컨트롤러가 nil이어도 앱이 크래시되지 않아야 함")
        }
    }
    
    // MARK: - 통합 테스트
    
    @Suite("Router 통합 테스트")
    struct Integration {
        
        @Test("전체 네비게이션 플로우")
        func testCompleteNavigationFlow() {
            // Given
            let mockDataStore = MockHistoryDataStore()
            let mockNavigationController = MockNavigationController()
            let sut = HistoryRouter(
                dataStore: mockDataStore,
                navigationController: mockNavigationController
            )
            
            let testTransactions = [
                Transaction(
                    hash: "0x1",
                    from: "0xa",
                    to: "0xb",
                    value: "1000000000000000000",
                    gasUsed: "21000",
                    gasPrice: "20000000000",
                    timestamp: Date(),
                    status: .success,
                    blockNumber: 12345678
                ),
                Transaction(
                    hash: "0x2",
                    from: "0xb",
                    to: "0xc",
                    value: "2000000000000000000",
                    gasUsed: "21000",
                    gasPrice: "25000000000",
                    timestamp: Date().addingTimeInterval(-3600),
                    status: .success,
                    blockNumber: 12345679
                )
            ]
            
            mockDataStore.currentTransactions = testTransactions
            mockDataStore.filteredTransactions = testTransactions
            mockDataStore.walletAddress = "0xwallet"
            
            // When & Then - 1. 필터 설정 화면 표시
            sut.routeToFilterSettings()
            #expect(mockNavigationController.presentSheetCalled == true, "필터 설정 시트가 표시되어야 함")
            
            // When & Then - 2. 필터 설정 완료 후 닫기
            sut.dismissFilterSettings()
            #expect(mockNavigationController.dismissCalled == true, "필터 설정이 닫혀야 함")
            
            // Reset mock state
            mockNavigationController.presentSheetCalled = false
            mockNavigationController.dismissCalled = false
            
            // When & Then - 3. 거래 상세 화면으로 이동
            sut.routeToTransactionDetail(transactionHash: "0x1")
            #expect(mockNavigationController.pushCalled == true, "거래 상세 화면으로 이동해야 함")
            #expect(mockDataStore.selectedTransaction?.hash == "0x1", "선택된 거래가 설정되어야 함")
            
            // When & Then - 4. 내보내기 옵션 표시
            sut.routeToExportOptions()
            #expect(mockNavigationController.presentSheetCalled == true, "내보내기 옵션이 표시되어야 함")
            
            // When & Then - 5. 송금 화면으로 이동
            sut.routeToSend()
            #expect(mockNavigationController.pushCalled == true, "송금 화면으로 이동해야 함")
            
            // When & Then - 6. 홈으로 이동
            sut.routeToHome()
            #expect(mockNavigationController.pushCalled == true, "홈 화면으로 이동해야 함")
            
            // 네비게이션 스택 확인
            #expect(mockNavigationController.navigationPath.count > 0, "네비게이션 경로가 쌓여야 함")
        }
        
        @Test("DataStore와 Navigation 상태 일관성")
        func testDataStoreNavigationConsistency() {
            // Given
            let mockDataStore = MockHistoryDataStore()
            let mockNavigationController = MockNavigationController()
            let sut = HistoryRouter(
                dataStore: mockDataStore,
                navigationController: mockNavigationController
            )
            
            let transaction = Transaction(
                hash: "0xconsistency",
                from: "0xfrom",
                to: "0xto",
                value: "1000000000000000000",
                gasUsed: "21000",
                gasPrice: "20000000000",
                timestamp: Date(),
                status: .success,
                blockNumber: 12345678
            )
            
            // When
            sut.updateSelectedTransaction(transaction)
            sut.routeToTransactionDetail(transactionHash: "0xconsistency")
            
            // Then
            #expect(mockDataStore.selectedTransaction?.hash == "0xconsistency", "DataStore 거래가 설정되어야 함")
            #expect(mockNavigationController.pushCalled == true, "네비게이션이 호출되어야 함")
            
            if let destination = mockNavigationController.navigationPath.first as? TransactionDetailDestination {
                #expect(
                    destination.transactionHash == mockDataStore.selectedTransaction?.hash,
                    "네비게이션 목적지와 DataStore가 일치해야 함"
                )
            }
        }
    }
}