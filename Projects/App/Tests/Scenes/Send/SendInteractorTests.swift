import Testing
import Foundation
@testable import Scenes
@testable import Entity
@testable import WalletKit

// MARK: - SendInteractor 테스트

@MainActor @Suite("SendInteractor 테스트")
struct SendInteractorTests {
    
    // MARK: - Spy Classes
    
    class PresentationLogicSpy: SendPresentationLogic {
        var presentAddressValidationCalled = false
        var presentAddressValidationResponse: SendScene.ValidateAddress.Response?
        
        func presentAddressValidation(response: SendScene.ValidateAddress.Response) {
            presentAddressValidationCalled = true
            presentAddressValidationResponse = response
        }
        
        var presentAmountValidationCalled = false
        var presentAmountValidationResponse: SendScene.ValidateAmount.Response?
        
        func presentAmountValidation(response: SendScene.ValidateAmount.Response) {
            presentAmountValidationCalled = true
            presentAmountValidationResponse = response
        }
        
        var presentGasEstimationCalled = false
        var presentGasEstimationResponse: SendScene.EstimateGas.Response?
        
        func presentGasEstimation(response: SendScene.EstimateGas.Response) {
            presentGasEstimationCalled = true
            presentGasEstimationResponse = response
        }
        
        var presentTransactionPreparationCalled = false
        var presentTransactionPreparationResponse: SendScene.PrepareTransaction.Response?
        
        func presentTransactionPreparation(response: SendScene.PrepareTransaction.Response) {
            presentTransactionPreparationCalled = true
            presentTransactionPreparationResponse = response
        }
        
        var presentTransactionResultCalled = false
        var presentTransactionResultResponse: SendScene.SendTransaction.Response?
        
        func presentTransactionResult(response: SendScene.SendTransaction.Response) {
            presentTransactionResultCalled = true
            presentTransactionResultResponse = response
        }
        
        var presentBiometricAuthResultCalled = false
        var presentBiometricAuthResultResponse: SendScene.BiometricAuth.Response?
        
        func presentBiometricAuthResult(response: SendScene.BiometricAuth.Response) {
            presentBiometricAuthResultCalled = true
            presentBiometricAuthResultResponse = response
        }
        
        var presentQRScannerCalled = false
        var presentQRScannerResponse: SendScene.QRScanner.Response?
        
        func presentQRScanner(response: SendScene.QRScanner.Response) {
            presentQRScannerCalled = true
            presentQRScannerResponse = response
        }
    }
    
    class WorkerSpy: SendWorkerProtocol {
        var validateEthereumAddressCalled = false
        var validateEthereumAddressResult = false
        
        func validateEthereumAddress(_ address: String) -> Bool {
            validateEthereumAddressCalled = true
            return validateEthereumAddressResult
        }
        
        var getCurrentBalanceCalled = false
        var getCurrentBalanceResult: Decimal = 1.0
        
        func getCurrentBalance() -> Decimal {
            getCurrentBalanceCalled = true
            return getCurrentBalanceResult
        }
        
        var isBalanceSufficientCalled = false
        var isBalanceSufficientResult = true
        
        func isBalanceSufficient(amount: Decimal, includingGasFee gasFee: Decimal) -> Bool {
            isBalanceSufficientCalled = true
            return isBalanceSufficientResult
        }
        
        var estimateGasFeeCalled = false
        var estimateGasFeeResult: Entity.GasOptions?
        
        func estimateGasFee(recipientAddress: String, amount: String) -> Entity.GasOptions? {
            estimateGasFeeCalled = true
            return estimateGasFeeResult
        }
        
        var prepareTransactionCalled = false
        var prepareTransactionResult: Entity.PendingTransaction?
        
        func prepareTransaction(recipientAddress: String, amount: Decimal, gasFee: Entity.GasFee) -> Entity.PendingTransaction? {
            prepareTransactionCalled = true
            return prepareTransactionResult
        }
        
        var authenticateWithBiometricCalled = false
        var authenticateWithBiometricResult = false
        
        func authenticateWithBiometric() async -> Bool {
            authenticateWithBiometricCalled = true
            return authenticateWithBiometricResult
        }
        
        var sendTransactionCalled = false
        var sendTransactionResult: Result<String, Error> = .success("0x123hash")
        
        func sendTransaction(_ transaction: Entity.PendingTransaction) async -> Result<String, Error> {
            sendTransactionCalled = true
            return sendTransactionResult
        }
    }
    
    // MARK: - Address Validation Tests
    
    @Suite("주소 검증")
    struct AddressValidation {
        
        @Test("유효한 이더리움 주소 - 성공")
        func testValidEthereumAddress() {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            workerSpy.validateEthereumAddressResult = true
            
            let sut = SendInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            let validAddress = "0x742d35Cc6644C0532925a3b8F0aB4e7E6a7bDdD1"
            let request = SendScene.ValidateAddress.Request(address: validAddress)
            
            // When
            sut.validateAddress(request: request)
            
            // Then
            #expect(workerSpy.validateEthereumAddressCalled == true, "Worker의 주소 검증이 호출되어야 함")
            #expect(presenterSpy.presentAddressValidationCalled == true, "Presenter가 호출되어야 함")
            #expect(
                presenterSpy.presentAddressValidationResponse?.isValid == true,
                "유효한 주소는 성공으로 처리되어야 함"
            )
            #expect(
                presenterSpy.presentAddressValidationResponse?.message == nil,
                "유효한 주소는 에러 메시지가 없어야 함"
            )
        }
        
        @Test("유효하지 않은 이더리움 주소 - 실패")
        func testInvalidEthereumAddress() {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            workerSpy.validateEthereumAddressResult = false
            
            let sut = SendInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            let invalidAddress = "invalid-address"
            let request = SendScene.ValidateAddress.Request(address: invalidAddress)
            
            // When
            sut.validateAddress(request: request)
            
            // Then
            #expect(workerSpy.validateEthereumAddressCalled == true, "Worker의 주소 검증이 호출되어야 함")
            #expect(presenterSpy.presentAddressValidationCalled == true, "Presenter가 호출되어야 함")
            #expect(
                presenterSpy.presentAddressValidationResponse?.isValid == false,
                "유효하지 않은 주소는 실패로 처리되어야 함"
            )
            #expect(
                presenterSpy.presentAddressValidationResponse?.message != nil,
                "유효하지 않은 주소는 에러 메시지가 있어야 함"
            )
        }
        
        @Test("빈 주소 - 실패")
        func testEmptyAddress() {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let sut = SendInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            let request = SendScene.ValidateAddress.Request(address: "")
            
            // When
            sut.validateAddress(request: request)
            
            // Then
            #expect(workerSpy.validateEthereumAddressCalled == false, "빈 주소는 Worker를 호출하지 않아야 함")
            #expect(presenterSpy.presentAddressValidationCalled == true, "Presenter가 호출되어야 함")
            #expect(
                presenterSpy.presentAddressValidationResponse?.isValid == false,
                "빈 주소는 실패로 처리되어야 함"
            )
        }
    }
    
    // MARK: - Amount Validation Tests
    
    @Suite("금액 검증")
    struct AmountValidation {
        
        @Test("유효한 금액 & 충분한 잔액 - 성공")
        func testValidAmountWithSufficientBalance() {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            workerSpy.getCurrentBalanceResult = 2.0
            workerSpy.isBalanceSufficientResult = true
            
            let sut = SendInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            let request = SendScene.ValidateAmount.Request(amount: "1.0")
            
            // When
            sut.validateAmount(request: request)
            
            // Then
            #expect(workerSpy.getCurrentBalanceCalled == true, "현재 잔액 조회가 호출되어야 함")
            #expect(workerSpy.isBalanceSufficientCalled == true, "잔액 충분성 검사가 호출되어야 함")
            #expect(presenterSpy.presentAmountValidationCalled == true, "Presenter가 호출되어야 함")
            #expect(
                presenterSpy.presentAmountValidationResponse?.isValid == true,
                "유효한 금액과 충분한 잔액은 성공으로 처리되어야 함"
            )
        }
        
        @Test("유효한 금액이지만 잔액 부족 - 실패")
        func testValidAmountButInsufficientBalance() {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            workerSpy.getCurrentBalanceResult = 0.5
            workerSpy.isBalanceSufficientResult = false
            
            let sut = SendInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            let request = SendScene.ValidateAmount.Request(amount: "1.0")
            
            // When
            sut.validateAmount(request: request)
            
            // Then
            #expect(presenterSpy.presentAmountValidationCalled == true, "Presenter가 호출되어야 함")
            #expect(
                presenterSpy.presentAmountValidationResponse?.isValid == false,
                "잔액이 부족하면 실패로 처리되어야 함"
            )
            #expect(
                presenterSpy.presentAmountValidationResponse?.message?.contains("잔액이 부족합니다") == true,
                "잔액 부족 메시지가 포함되어야 함"
            )
        }
        
        @Test("유효하지 않은 금액 형식 - 실패")
        func testInvalidAmountFormat() {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let sut = SendInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            let request = SendScene.ValidateAmount.Request(amount: "invalid-amount")
            
            // When
            sut.validateAmount(request: request)
            
            // Then
            #expect(workerSpy.getCurrentBalanceCalled == false, "잘못된 형식은 잔액 조회를 하지 않아야 함")
            #expect(presenterSpy.presentAmountValidationCalled == true, "Presenter가 호출되어야 함")
            #expect(
                presenterSpy.presentAmountValidationResponse?.isValid == false,
                "잘못된 금액 형식은 실패로 처리되어야 함"
            )
        }
        
        @Test("0 이하의 금액 - 실패")
        func testZeroOrNegativeAmount() {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let sut = SendInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            let request = SendScene.ValidateAmount.Request(amount: "0")
            
            // When
            sut.validateAmount(request: request)
            
            // Then
            #expect(presenterSpy.presentAmountValidationCalled == true, "Presenter가 호출되어야 함")
            #expect(
                presenterSpy.presentAmountValidationResponse?.isValid == false,
                "0 이하 금액은 실패로 처리되어야 함"
            )
        }
    }
    
    // MARK: - Gas Estimation Tests
    
    @Suite("가스비 추정")
    struct GasEstimation {
        
        @Test("가스비 추정 성공")
        func testGasEstimationSuccess() {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let mockGasOptions = Entity.GasOptions(
                slow: Entity.GasFee(gasPrice: "20000000000", estimatedTime: 300, feeInETH: 0.0005, feeInUSD: 1.0),
                normal: Entity.GasFee(gasPrice: "25000000000", estimatedTime: 180, feeInETH: 0.00063, feeInUSD: 1.25),
                fast: Entity.GasFee(gasPrice: "35000000000", estimatedTime: 60, feeInETH: 0.00088, feeInUSD: 1.75)
            )
            workerSpy.estimateGasFeeResult = mockGasOptions
            
            let sut = SendInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            let request = SendScene.EstimateGas.Request(
                recipient: "0x742d35Cc6644C0532925a3b8F0aB4e7E6a7bDdD1",
                amount: "1.0",
                gasFeeLevel: .standard
            )
            
            // When
            sut.estimateGas(request: request)
            
            // Then
            #expect(workerSpy.estimateGasFeeCalled == true, "Worker의 가스비 추정이 호출되어야 함")
            #expect(presenterSpy.presentGasEstimationCalled == true, "Presenter가 호출되어야 함")
            #expect(
                presenterSpy.presentGasEstimationResponse?.gasOptions != nil,
                "가스비 옵션이 반환되어야 함"
            )
        }
        
        @Test("가스비 추정 실패")
        func testGasEstimationFailure() {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            workerSpy.estimateGasFeeResult = nil
            
            let sut = SendInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            let request = SendScene.EstimateGas.Request(
                recipient: "invalid-address",
                amount: "1.0",
                gasFeeLevel: .standard
            )
            
            // When
            sut.estimateGas(request: request)
            
            // Then
            #expect(workerSpy.estimateGasFeeCalled == true, "Worker의 가스비 추정이 호출되어야 함")
            #expect(presenterSpy.presentGasEstimationCalled == true, "Presenter가 호출되어야 함")
            #expect(
                presenterSpy.presentGasEstimationResponse?.error != nil,
                "가스비 추정 실패 시 에러가 반환되어야 함"
            )
        }
    }
    
    // MARK: - Transaction Tests
    
    @Suite("거래 처리")
    struct TransactionHandling {
        
        @Test("거래 준비 성공")
        func testTransactionPreparationSuccess() {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let mockTransaction = Entity.PendingTransaction(
                recipientAddress: "0x742d35Cc6644C0532925a3b8F0aB4e7E6a7bDdD1",
                amount: Decimal(1.0),
                gasPrice: "25000000000",
                gasLimit: "21000",
                nonce: "42"
            )
            workerSpy.prepareTransactionResult = mockTransaction
            
            let sut = SendInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            let mockGasFee = Entity.GasFee(
                gasPrice: "25000000000",
                estimatedTime: 180,
                feeInETH: 0.00063,
                feeInUSD: 1.25
            )
            
            let request = SendScene.PrepareTransaction.Request(
                recipient: "0x742d35Cc6644C0532925a3b8F0aB4e7E6a7bDdD1",
                amount: "1.0",
                gasFee: mockGasFee
            )
            
            // When
            sut.prepareTransaction(request: request)
            
            // Then
            #expect(workerSpy.prepareTransactionCalled == true, "Worker의 거래 준비가 호출되어야 함")
            #expect(presenterSpy.presentTransactionPreparationCalled == true, "Presenter가 호출되어야 함")
            #expect(
                presenterSpy.presentTransactionPreparationResponse?.isReady == true,
                "거래가 준비되었음을 알려야 함"
            )
        }
        
        @Test("거래 전송 성공")
        func testTransactionSendingSuccess() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let mockTransactionHash = "0x123abc...def789"
            workerSpy.sendTransactionResult = .success(mockTransactionHash)
            
            let sut = SendInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            let mockTransaction = Entity.PendingTransaction(
                recipientAddress: "0x742d35Cc6644C0532925a3b8F0aB4e7E6a7bDdD1",
                amount: Decimal(1.0),
                gasPrice: "25000000000",
                gasLimit: "21000",
                nonce: "42"
            )
            
            let request = SendScene.SendTransaction.Request(
                recipient: "0x742d35Cc6644C0532925a3b8F0aB4e7E6a7bDdD1",
                amount: "1.0",
                gasFee: .standard
            )
            
            // When
            await sut.sendTransaction(request: request)
            
            // Then
            #expect(workerSpy.sendTransactionCalled == true, "Worker의 거래 전송이 호출되어야 함")
            #expect(presenterSpy.presentTransactionResultCalled == true, "Presenter가 호출되어야 함")
            #expect(
                presenterSpy.presentTransactionResultResponse?.success == true,
                "거래 성공이 전달되어야 함"
            )
            #expect(
                presenterSpy.presentTransactionResultResponse?.transactionHash == mockTransactionHash,
                "거래 해시가 전달되어야 함"
            )
        }
        
        @Test("거래 전송 실패")
        func testTransactionSendingFailure() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let networkError = NSError(domain: "NetworkError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Network failed"])
            workerSpy.sendTransactionResult = .failure(networkError)
            
            let sut = SendInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            let request = SendScene.SendTransaction.Request(
                recipient: "0x742d35Cc6644C0532925a3b8F0aB4e7E6a7bDdD1",
                amount: "1.0",
                gasFee: .standard
            )
            
            // When
            await sut.sendTransaction(request: request)
            
            // Then
            #expect(presenterSpy.presentTransactionResultCalled == true, "Presenter가 호출되어야 함")
            #expect(
                presenterSpy.presentTransactionResultResponse?.success == false,
                "거래 실패가 전달되어야 함"
            )
            #expect(
                presenterSpy.presentTransactionResultResponse?.error != nil,
                "에러가 전달되어야 함"
            )
        }
    }
    
    // MARK: - Biometric Authentication Tests
    
    @Suite("생체 인증")
    struct BiometricAuthentication {
        
        @Test("생체 인증 성공")
        func testBiometricAuthenticationSuccess() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            workerSpy.authenticateWithBiometricResult = true
            
            let sut = SendInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            let request = SendScene.BiometricAuth.Request()
            
            // When
            await sut.authenticateWithBiometrics(request: request)
            
            // Then
            #expect(workerSpy.authenticateWithBiometricCalled == true, "Worker의 생체 인증이 호출되어야 함")
            #expect(presenterSpy.presentBiometricAuthResultCalled == true, "Presenter가 호출되어야 함")
            #expect(
                presenterSpy.presentBiometricAuthResultResponse?.success == true,
                "생체 인증 성공이 전달되어야 함"
            )
        }
        
        @Test("생체 인증 실패")
        func testBiometricAuthenticationFailure() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            workerSpy.authenticateWithBiometricResult = false
            
            let sut = SendInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            let request = SendScene.BiometricAuth.Request()
            
            // When
            await sut.authenticateWithBiometrics(request: request)
            
            // Then
            #expect(presenterSpy.presentBiometricAuthResultCalled == true, "Presenter가 호출되어야 함")
            #expect(
                presenterSpy.presentBiometricAuthResultResponse?.success == false,
                "생체 인증 실패가 전달되어야 함"
            )
        }
    }
}