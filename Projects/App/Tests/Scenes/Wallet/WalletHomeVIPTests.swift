import Testing
import Foundation
@testable import App

// MARK: - WalletHomeInteractor Tests

@Suite("WalletHomeInteractor 테스트")
struct WalletHomeInteractorTests {
    
    // MARK: - Spy Classes
    
    @MainActor
    class PresentationLogicSpy: WalletHomePresentationLogic {
        var presentBalanceCalled = false
        var presentBalanceResponse: WalletHome.FetchBalance.Response?
        
        var presentTransactionHistoryCalled = false
        var presentTransactionHistoryResponse: WalletHome.FetchTransactionHistory.Response?
        
        var presentSendNavigationCalled = false
        var presentSendNavigationResponse: WalletHome.NavigateToSend.Response?
        
        var presentReceiveNavigationCalled = false
        var presentReceiveNavigationResponse: WalletHome.NavigateToReceive.Response?
        
        var presentScrollStateCalled = false
        var presentScrollStateResponse: WalletHome.HandleScrollState.Response?
        
        var presentGlassThemeCalled = false
        var presentGlassThemeResponse: WalletHome.ChangeGlassTheme.Response?
        
        func presentBalance(response: WalletHome.FetchBalance.Response) {
            presentBalanceCalled = true
            presentBalanceResponse = response
        }
        
        func presentTransactionHistory(response: WalletHome.FetchTransactionHistory.Response) {
            presentTransactionHistoryCalled = true
            presentTransactionHistoryResponse = response
        }
        
        func presentSendNavigation(response: WalletHome.NavigateToSend.Response) {
            presentSendNavigationCalled = true
            presentSendNavigationResponse = response
        }
        
        func presentReceiveNavigation(response: WalletHome.NavigateToReceive.Response) {
            presentReceiveNavigationCalled = true
            presentReceiveNavigationResponse = response
        }
        
        func presentScrollState(response: WalletHome.HandleScrollState.Response) {
            presentScrollStateCalled = true
            presentScrollStateResponse = response
        }
        
        func presentGlassTheme(response: WalletHome.ChangeGlassTheme.Response) {
            presentGlassThemeCalled = true
            presentGlassThemeResponse = response
        }
    }
    
    actor WalletServiceSpy: WalletServiceProtocol {
        var fetchBalanceCalled = false
        var fetchBalanceResult: Result<WalletBalanceResponse, Error> = .success(
            WalletBalanceResponse(balance: "2.5", symbol: "ETH", usdValue: "4250.00")
        )
        
        var fetchTransactionHistoryCalled = false
        var fetchTransactionHistoryResult: Result<[TransactionEntity], Error> = .success([])
        
        var validateAddressCalled = false
        var validateAddressResult = true
        
        var estimateGasFeeCalled = false
        var estimateGasFeeResult: Result<String, Error> = .success("0.0021")
        
        var sendTransactionCalled = false
        var sendTransactionResult: Result<String, Error> = .success("0xabcdef123456789")
        
        func fetchBalance(address: String) async -> Result<WalletBalanceResponse, Error> {
            fetchBalanceCalled = true
            return fetchBalanceResult
        }
        
        func fetchTransactionHistory(address: String, limit: Int) async -> Result<[TransactionEntity], Error> {
            fetchTransactionHistoryCalled = true
            return fetchTransactionHistoryResult
        }
        
        func validateAddress(_ address: String) -> Bool {
            validateAddressCalled = true
            return validateAddressResult
        }
        
        func estimateGasFee(to: String, amount: String) async -> Result<String, Error> {
            estimateGasFeeCalled = true
            return estimateGasFeeResult
        }
        
        func sendTransaction(to: String, amount: String, gasPrice: String) async -> Result<String, Error> {
            sendTransactionCalled = true
            return sendTransactionResult
        }
    }
    
    actor QRCodeServiceSpy: QRCodeServiceProtocol {
        var generateQRCodeCalled = false
        var generateQRCodeResult: Result<Data, Error> = .success(Data())
        
        var scanQRCodeCalled = false
        var scanQRCodeResult: Result<String, Error> = .success("0x1234567890abcdef")
        
        func generateQRCode(from address: String) async -> Result<Data, Error> {
            generateQRCodeCalled = true
            return generateQRCodeResult
        }
        
        func scanQRCode() async -> Result<String, Error> {
            scanQRCodeCalled = true
            return scanQRCodeResult
        }
    }
    
    // MARK: - 잔액 조회 테스트
    
    @Suite("잔액 조회")
    struct FetchBalance {
        
        @Test("성공 케이스 - 유효한 잔액 반환")
        func testFetchBalanceSuccess() async {
            // Given
            let presenterSpy = await PresentationLogicSpy()
            let walletServiceSpy = WalletServiceSpy()
            let qrCodeServiceSpy = QRCodeServiceSpy()
            
            let expectedBalance = WalletBalanceResponse(
                balance: "2.5",
                symbol: "ETH",
                usdValue: "4250.00"
            )
            await walletServiceSpy.fetchBalanceResult = .success(expectedBalance)
            
            let sut = WalletHomeInteractor(
                presenter: presenterSpy,
                walletService: walletServiceSpy,
                qrCodeService: qrCodeServiceSpy
            )
            
            let request = WalletHome.FetchBalance.Request(
                walletAddress: "0x1234567890abcdef1234567890abcdef12345678"
            )
            
            // When
            sut.fetchBalance(request: request)
            
            // Then
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1초 대기
            
            #expect(await walletServiceSpy.fetchBalanceCalled == true, "WalletService가 호출되어야 함")
            
            await MainActor.run {
                #expect(presenterSpy.presentBalanceCalled == true, "Presenter가 호출되어야 함")
                #expect(
                    presenterSpy.presentBalanceResponse?.balance == "2.5",
                    "올바른 잔액이 Presenter로 전달되어야 함"
                )
                #expect(
                    presenterSpy.presentBalanceResponse?.error == nil,
                    "에러가 없어야 함"
                )
            }
        }
        
        @Test("실패 케이스 - 네트워크 오류")
        func testFetchBalanceNetworkError() async {
            // Given
            let presenterSpy = await PresentationLogicSpy()
            let walletServiceSpy = WalletServiceSpy()
            let qrCodeServiceSpy = QRCodeServiceSpy()
            
            let networkError = WalletHomeError.networkError("Connection failed")
            await walletServiceSpy.fetchBalanceResult = .failure(networkError)
            
            let sut = WalletHomeInteractor(
                presenter: presenterSpy,
                walletService: walletServiceSpy,
                qrCodeService: qrCodeServiceSpy
            )
            
            let request = WalletHome.FetchBalance.Request(
                walletAddress: "0x1234567890abcdef1234567890abcdef12345678"
            )
            
            // When
            sut.fetchBalance(request: request)
            
            // Then
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1초 대기
            
            #expect(await walletServiceSpy.fetchBalanceCalled == true, "WalletService가 호출되어야 함")
            
            await MainActor.run {
                #expect(presenterSpy.presentBalanceCalled == true, "Presenter가 호출되어야 함")
                #expect(
                    presenterSpy.presentBalanceResponse?.error != nil,
                    "에러가 Presenter로 전달되어야 함"
                )
            }
        }
    }
    
    // MARK: - 거래 내역 조회 테스트
    
    @Suite("거래 내역 조회")
    struct FetchTransactionHistory {
        
        @Test("성공 케이스 - 거래 내역 반환")
        func testFetchTransactionHistorySuccess() async {
            // Given
            let presenterSpy = await PresentationLogicSpy()
            let walletServiceSpy = WalletServiceSpy()
            let qrCodeServiceSpy = QRCodeServiceSpy()
            
            let mockTransaction = TransactionEntity(
                id: "1",
                type: .receive,
                amount: "0.5",
                symbol: "ETH",
                timestamp: Date(),
                status: .confirmed,
                hash: "0xabcdef",
                fromAddress: "0x1111",
                toAddress: "0x2222"
            )
            
            await walletServiceSpy.fetchTransactionHistoryResult = .success([mockTransaction])
            
            let sut = WalletHomeInteractor(
                presenter: presenterSpy,
                walletService: walletServiceSpy,
                qrCodeService: qrCodeServiceSpy
            )
            
            let request = WalletHome.FetchTransactionHistory.Request(
                walletAddress: "0x1234567890abcdef1234567890abcdef12345678",
                limit: 10
            )
            
            // When
            sut.fetchTransactionHistory(request: request)
            
            // Then
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1초 대기
            
            #expect(await walletServiceSpy.fetchTransactionHistoryCalled == true, "WalletService가 호출되어야 함")
            
            await MainActor.run {
                #expect(presenterSpy.presentTransactionHistoryCalled == true, "Presenter가 호출되어야 함")
                #expect(
                    presenterSpy.presentTransactionHistoryResponse?.transactions.count == 1,
                    "거래 내역이 Presenter로 전달되어야 함"
                )
                #expect(
                    presenterSpy.presentTransactionHistoryResponse?.error == nil,
                    "에러가 없어야 함"
                )
            }
        }
    }
    
    // MARK: - 스크롤 상태 처리 테스트
    
    @Suite("스크롤 상태 처리")
    struct HandleScrollState {
        
        @Test("아래로 스크롤 감지")
        func testScrollingDown() async {
            // Given
            let presenterSpy = await PresentationLogicSpy()
            let walletServiceSpy = WalletServiceSpy()
            let qrCodeServiceSpy = QRCodeServiceSpy()
            
            let sut = WalletHomeInteractor(
                presenter: presenterSpy,
                walletService: walletServiceSpy,
                qrCodeService: qrCodeServiceSpy
            )
            
            let request = WalletHome.HandleScrollState.Request(
                scrollOffset: -50, // 아래로 스크롤
                lastScrollOffset: -10
            )
            
            // When
            sut.handleScrollState(request: request)
            
            // Then
            await MainActor.run {
                #expect(presenterSpy.presentScrollStateCalled == true, "Presenter가 호출되어야 함")
                #expect(
                    presenterSpy.presentScrollStateResponse?.isScrollingDown == true,
                    "아래로 스크롤 상태가 전달되어야 함"
                )
            }
        }
        
        @Test("위로 스크롤 감지")
        func testScrollingUp() async {
            // Given
            let presenterSpy = await PresentationLogicSpy()
            let walletServiceSpy = WalletServiceSpy()
            let qrCodeServiceSpy = QRCodeServiceSpy()
            
            let sut = WalletHomeInteractor(
                presenter: presenterSpy,
                walletService: walletServiceSpy,
                qrCodeService: qrCodeServiceSpy
            )
            
            let request = WalletHome.HandleScrollState.Request(
                scrollOffset: 0, // 위로 스크롤하여 원위치
                lastScrollOffset: -30
            )
            
            // When
            sut.handleScrollState(request: request)
            
            // Then
            await MainActor.run {
                #expect(presenterSpy.presentScrollStateCalled == true, "Presenter가 호출되어야 함")
                #expect(
                    presenterSpy.presentScrollStateResponse?.isScrollingDown == false,
                    "위로 스크롤 상태가 전달되어야 함"
                )
            }
        }
    }
}

// MARK: - WalletHomePresenter Tests

@Suite("WalletHomePresenter 테스트")
struct WalletHomePresenterTests {
    
    // MARK: - Spy Classes
    
    @MainActor
    class DisplayLogicSpy: WalletHomeDisplayLogic {
        var displayBalanceCalled = false
        var displayBalanceViewModel: WalletHome.FetchBalance.ViewModel?
        
        var displayTransactionHistoryCalled = false
        var displayTransactionHistoryViewModel: WalletHome.FetchTransactionHistory.ViewModel?
        
        var displaySendNavigationCalled = false
        var displaySendNavigationViewModel: WalletHome.NavigateToSend.ViewModel?
        
        var displayReceiveNavigationCalled = false
        var displayReceiveNavigationViewModel: WalletHome.NavigateToReceive.ViewModel?
        
        var displayScrollStateCalled = false
        var displayScrollStateViewModel: WalletHome.HandleScrollState.ViewModel?
        
        var displayGlassThemeCalled = false
        var displayGlassThemeViewModel: WalletHome.ChangeGlassTheme.ViewModel?
        
        func displayBalance(viewModel: WalletHome.FetchBalance.ViewModel) {
            displayBalanceCalled = true
            displayBalanceViewModel = viewModel
        }
        
        func displayTransactionHistory(viewModel: WalletHome.FetchTransactionHistory.ViewModel) {
            displayTransactionHistoryCalled = true
            displayTransactionHistoryViewModel = viewModel
        }
        
        func displaySendNavigation(viewModel: WalletHome.NavigateToSend.ViewModel) {
            displaySendNavigationCalled = true
            displaySendNavigationViewModel = viewModel
        }
        
        func displayReceiveNavigation(viewModel: WalletHome.NavigateToReceive.ViewModel) {
            displayReceiveNavigationCalled = true
            displayReceiveNavigationViewModel = viewModel
        }
        
        func displayScrollState(viewModel: WalletHome.HandleScrollState.ViewModel) {
            displayScrollStateCalled = true
            displayScrollStateViewModel = viewModel
        }
        
        func displayGlassTheme(viewModel: WalletHome.ChangeGlassTheme.ViewModel) {
            displayGlassThemeCalled = true
            displayGlassThemeViewModel = viewModel
        }
    }
    
    // MARK: - 잔액 포맷팅 테스트
    
    @Suite("잔액 데이터 포맷팅")
    struct BalanceFormatting {
        
        @Test("성공 응답 포맷팅")
        func testFormatSuccessfulBalance() async {
            // Given
            let displayLogicSpy = await DisplayLogicSpy()
            let sut = WalletHomePresenter(viewController: displayLogicSpy)
            
            let response = WalletHome.FetchBalance.Response(
                balance: "2.5",
                symbol: "ETH",
                usdValue: "4250.00",
                error: nil
            )
            
            // When
            sut.presentBalance(response: response)
            
            // Then
            await MainActor.run {
                #expect(displayLogicSpy.displayBalanceCalled == true, "Display 메서드가 호출되어야 함")
                #expect(
                    displayLogicSpy.displayBalanceViewModel?.displayedBalance == "2.50",
                    "잔액이 올바른 형식으로 포맷되어야 함"
                )
                #expect(
                    displayLogicSpy.displayBalanceViewModel?.displayedUSDValue == "$4,250.00",
                    "USD 가치가 올바른 형식으로 포맷되어야 함"
                )
                #expect(
                    displayLogicSpy.displayBalanceViewModel?.errorMessage == nil,
                    "에러 메시지가 없어야 함"
                )
            }
        }
        
        @Test("에러 응답 포맷팅")
        func testFormatErrorResponse() async {
            // Given
            let displayLogicSpy = await DisplayLogicSpy()
            let sut = WalletHomePresenter(viewController: displayLogicSpy)
            
            let error = WalletHomeError.networkError("Connection timeout")
            let response = WalletHome.FetchBalance.Response(
                balance: "",
                symbol: "",
                usdValue: "",
                error: error
            )
            
            // When
            sut.presentBalance(response: response)
            
            // Then
            await MainActor.run {
                #expect(displayLogicSpy.displayBalanceCalled == true, "Display 메서드가 호출되어야 함")
                #expect(
                    displayLogicSpy.displayBalanceViewModel?.displayedBalance == "0.00",
                    "기본 잔액이 표시되어야 함"
                )
                #expect(
                    displayLogicSpy.displayBalanceViewModel?.errorMessage?.contains("네트워크 오류") == true,
                    "사용자 친화적인 에러 메시지가 표시되어야 함"
                )
            }
        }
    }
    
    // MARK: - 거래 내역 포맷팅 테스트
    
    @Suite("거래 내역 포맷팅")
    struct TransactionFormatting {
        
        @Test("거래 내역 시간 포맷팅")
        func testFormatTransactionTimestamp() async {
            // Given
            let displayLogicSpy = await DisplayLogicSpy()
            let sut = WalletHomePresenter(viewController: displayLogicSpy)
            
            let fiveMinutesAgo = Date().addingTimeInterval(-300) // 5분 전
            let transaction = TransactionEntity(
                id: "1",
                type: .receive,
                amount: "0.5",
                symbol: "ETH",
                timestamp: fiveMinutesAgo,
                status: .confirmed,
                hash: "0xabcdef",
                fromAddress: "0x1111",
                toAddress: "0x2222"
            )
            
            let response = WalletHome.FetchTransactionHistory.Response(
                transactions: [transaction],
                error: nil
            )
            
            // When
            sut.presentTransactionHistory(response: response)
            
            // Then
            await MainActor.run {
                #expect(displayLogicSpy.displayTransactionHistoryCalled == true, "Display 메서드가 호출되어야 함")
                
                let displayedTransaction = displayLogicSpy.displayTransactionHistoryViewModel?.displayedTransactions.first
                #expect(
                    displayedTransaction?.displayedTimestamp == "5분 전",
                    "시간이 올바르게 포맷되어야 함"
                )
                #expect(
                    displayedTransaction?.displayedAmount == "+0.50",
                    "수신 거래는 + 기호가 붙어야 함"
                )
                #expect(
                    displayedTransaction?.iconName == "arrow.down.circle.fill",
                    "수신 거래는 아래쪽 화살표 아이콘이어야 함"
                )
            }
        }
        
        @Test("전송 거래 포맷팅")
        func testFormatSendTransaction() async {
            // Given
            let displayLogicSpy = await DisplayLogicSpy()
            let sut = WalletHomePresenter(viewController: displayLogicSpy)
            
            let transaction = TransactionEntity(
                id: "1",
                type: .send,
                amount: "1.2",
                symbol: "ETH",
                timestamp: Date().addingTimeInterval(-3600), // 1시간 전
                status: .pending,
                hash: "0xabcdef",
                fromAddress: "0x1111",
                toAddress: "0x2222"
            )
            
            let response = WalletHome.FetchTransactionHistory.Response(
                transactions: [transaction],
                error: nil
            )
            
            // When
            sut.presentTransactionHistory(response: response)
            
            // Then
            await MainActor.run {
                let displayedTransaction = displayLogicSpy.displayTransactionHistoryViewModel?.displayedTransactions.first
                #expect(
                    displayedTransaction?.displayedAmount == "-1.20",
                    "전송 거래는 - 기호가 붙어야 함"
                )
                #expect(
                    displayedTransaction?.statusColor == "orange",
                    "대기중 상태는 오렌지색이어야 함"
                )
                #expect(
                    displayedTransaction?.iconName == "arrow.up.circle.fill",
                    "전송 거래는 위쪽 화살표 아이콘이어야 함"
                )
            }
        }
    }
}

// MARK: - SendFlowInteractor Tests

@Suite("SendFlowInteractor 테스트")
struct SendFlowInteractorTests {
    
    @MainActor
    class SendFlowPresentationLogicSpy: SendFlowPresentationLogic {
        var presentRecipientValidationCalled = false
        var presentRecipientValidationResponse: SendFlow.SelectRecipient.Response?
        
        var presentAmountValidationCalled = false
        var presentAmountValidationResponse: SendFlow.EnterAmount.Response?
        
        var presentTransactionConfirmationCalled = false
        var presentTransactionConfirmationResponse: SendFlow.ConfirmTransaction.Response?
        
        func presentRecipientValidation(response: SendFlow.SelectRecipient.Response) {
            presentRecipientValidationCalled = true
            presentRecipientValidationResponse = response
        }
        
        func presentAmountValidation(response: SendFlow.EnterAmount.Response) {
            presentAmountValidationCalled = true
            presentAmountValidationResponse = response
        }
        
        func presentTransactionConfirmation(response: SendFlow.ConfirmTransaction.Response) {
            presentTransactionConfirmationCalled = true
            presentTransactionConfirmationResponse = response
        }
    }
    
    // MARK: - 주소 유효성 검증 테스트
    
    @Suite("주소 유효성 검증")
    struct ValidateRecipient {
        
        @Test("유효한 이더리움 주소")
        func testValidEthereumAddress() async {
            // Given
            let presenterSpy = await SendFlowPresentationLogicSpy()
            let walletServiceSpy = WalletServiceSpy()
            
            await walletServiceSpy.validateAddressResult = true
            
            let sut = SendFlowInteractor(
                presenter: presenterSpy,
                walletService: walletServiceSpy
            )
            
            let request = SendFlow.SelectRecipient.Request(
                scannedAddress: "0x1234567890abcdef1234567890abcdef12345678"
            )
            
            // When
            sut.validateRecipient(request: request)
            
            // Then
            await MainActor.run {
                #expect(presenterSpy.presentRecipientValidationCalled == true, "Presenter가 호출되어야 함")
                #expect(
                    presenterSpy.presentRecipientValidationResponse?.isValidAddress == true,
                    "유효한 주소로 인식되어야 함"
                )
                #expect(
                    presenterSpy.presentRecipientValidationResponse?.addressValidationMessage == "유효한 주소입니다",
                    "성공 메시지가 전달되어야 함"
                )
            }
        }
        
        @Test("유효하지 않은 주소")
        func testInvalidAddress() async {
            // Given
            let presenterSpy = await SendFlowPresentationLogicSpy()
            let walletServiceSpy = WalletServiceSpy()
            
            await walletServiceSpy.validateAddressResult = false
            
            let sut = SendFlowInteractor(
                presenter: presenterSpy,
                walletService: walletServiceSpy
            )
            
            let request = SendFlow.SelectRecipient.Request(
                scannedAddress: "invalid-address"
            )
            
            // When
            sut.validateRecipient(request: request)
            
            // Then
            await MainActor.run {
                #expect(presenterSpy.presentRecipientValidationCalled == true, "Presenter가 호출되어야 함")
                #expect(
                    presenterSpy.presentRecipientValidationResponse?.isValidAddress == false,
                    "유효하지 않은 주소로 인식되어야 함"
                )
                #expect(
                    presenterSpy.presentRecipientValidationResponse?.addressValidationMessage == "올바른 주소 형식이 아닙니다",
                    "실패 메시지가 전달되어야 함"
                )
            }
        }
    }
}