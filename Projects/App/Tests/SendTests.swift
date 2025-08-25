import Testing
import CoreImage
import BigInt
import Foundation
@testable import Kingthereum
@testable import DesignSystem

/// SOLID 원칙을 완전히 준수하는 송금 Interactor 비즈니스 로직 테스트
@Suite("Send Interactor Business Logic Tests")
struct SendInteractorTests {
    
    // MARK: - Test Fixtures
    
    @MainActor
    private func makeTestDependencies() -> (
        interactor: SendInteractor, 
        presenter: MockSendPresenterProtocol, 
        addressValidator: MockAddressValidatorProtocol,
        balanceProvider: MockBalanceProviderProtocol,
        gasEstimator: MockGasEstimatorProtocol,
        biometricAuth: MockBiometricAuthenticatorProtocol,
        transactionSender: MockTransactionSenderProtocol
    ) {
        let interactor = SendInteractor()
        let presenter = MockSendPresenterProtocol()
        let addressValidator = MockAddressValidatorProtocol()
        let balanceProvider = MockBalanceProviderProtocol()
        let gasEstimator = MockGasEstimatorProtocol()
        let biometricAuth = MockBiometricAuthenticatorProtocol()
        let transactionSender = MockTransactionSenderProtocol()
        
        // SOLID 원칙을 준수하는 테스트 전용 Worker 생성
        let testWorker = TestSendWorker(
            addressValidator: addressValidator,
            balanceProvider: balanceProvider,
            gasEstimator: gasEstimator,
            biometricAuth: biometricAuth,
            transactionSender: transactionSender
        )
        
        interactor.presenter = presenter
        interactor.worker = testWorker
        
        return (interactor, presenter, addressValidator, balanceProvider, gasEstimator, biometricAuth, transactionSender)
    }
    
    // MARK: - Address Validation Business Logic Tests
    
    @Suite("Address Validation")
    struct AddressValidationTests {
        
        @Test("유효한 이더리움 주소 검증 성공", arguments: [
            "0x742B15EcB8E3F6F7e7D58C4f9Ad2dBcEF8A5E9C3",
            "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed",
            "0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359",
            "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045"
        ])
        @MainActor
        func validateValidAddress(validAddress: String) async {
            // Given
            let dependencies = makeTestDependencies()
            await dependencies.addressValidator.setMockResult(true)
            
            let request = Send.ValidateAddress.Request(address: validAddress)
            
            // When
            dependencies.interactor.validateAddress(request: request)
            
            // Then
            let lastValidatedAddress = await dependencies.addressValidator.getLastValidatedAddress()
            let presentationCalled = await dependencies.presenter.isPresentAddressValidationCalled()
            let lastResponse = await dependencies.presenter.getLastAddressValidation()
            
            #expect(lastValidatedAddress == validAddress, "검증된 주소가 일치해야 함")
            #expect(presentationCalled == true, "Presenter 호출되어야 함")
            #expect(lastResponse?.isValid == true, "유효한 주소로 판정되어야 함")
            #expect(lastResponse?.errorMessage == nil, "에러 메시지가 없어야 함")
        }
    
        @Test("무효한 이더리움 주소 검증 실패", arguments: [
            ("invalid_address", "올바른 이더리움 주소를 입력해주세요"),
            ("", "주소를 입력해주세요"),
            ("   ", "주소를 입력해주세요"),
            ("0x123", "올바른 이더리움 주소를 입력해주세요"),
            ("742B15EcB8E3F6F7e7D58C4f9Ad2dBcEF8A5E9C3", "올바른 이더리움 주소를 입력해주세요"),
            ("0xZZZB15EcB8E3F6F7e7D58C4f9Ad2dBcEF8A5E9C3", "올바른 이더리움 주소를 입력해주세요")
        ])
        @MainActor
        func validateInvalidAddress(invalidAddress: String, expectedError: String) async {
            // Given
            let dependencies = makeTestDependencies()
            await dependencies.addressValidator.setMockResult(false)
            
            let request = Send.ValidateAddress.Request(address: invalidAddress)
            
            // When
            dependencies.interactor.validateAddress(request: request)
            
            // Then
            let presentationCalled = await dependencies.presenter.isPresentAddressValidationCalled()
            let lastResponse = await dependencies.presenter.getLastAddressValidation()
            
            #expect(presentationCalled == true, "Presenter 호출되어야 함")
            #expect(lastResponse?.isValid == false, "무효한 주소로 판정되어야 함")
            #expect(lastResponse?.errorMessage == expectedError, "적절한 에러 메시지가 표시되어야 함")
        }
        
        @Test("주소 검증 중 공백 문자 제거")
        @MainActor
        func validateAddressWithWhitespace() async {
            // Given
            let dependencies = makeTestDependencies()
            let addressWithSpaces = "  0x742B15EcB8E3F6F7e7D58C4f9Ad2dBcEF8A5E9C3  "
            let expectedTrimmedAddress = "0x742B15EcB8E3F6F7e7D58C4f9Ad2dBcEF8A5E9C3"
            await dependencies.addressValidator.setMockResult(true)
            
            let request = Send.ValidateAddress.Request(address: addressWithSpaces)
            
            // When
            dependencies.interactor.validateAddress(request: request)
            
            // Then
            let lastValidatedAddress = await dependencies.addressValidator.getLastValidatedAddress()
            #expect(lastValidatedAddress == expectedTrimmedAddress, "공백이 제거된 주소로 검증되어야 함")
        }
    }
    
    // MARK: - Amount Validation Business Logic Tests
    
    @Suite("Amount Validation")
    struct AmountValidationTests {
        
        @Test("유효한 금액 검증 성공", arguments: [
            ("1.5", "2.0", true),
            ("0.001", "1.0", true),
            ("1.999999", "2.0", true),
            ("0.1", "0.1", true),
            ("10", "15.5", true)
        ])
        @MainActor
        func validateValidAmount(amount: String, balance: String, expected: Bool) async {
            // Given
            let dependencies = makeTestDependencies()
            let balanceDecimal = Decimal(string: balance)!
            await dependencies.balanceProvider.setCurrentBalance(balanceDecimal)
            
            let request = Send.ValidateAmount.Request(
                amount: amount,
                availableBalance: balance
            )
            
            // When
            dependencies.interactor.validateAmount(request: request)
            
            // Then
            let balanceCheckCalled = await dependencies.balanceProvider.isGetCurrentBalanceCalled()
            let presentationCalled = await dependencies.presenter.isPresentAmountValidationCalled()
            let lastResponse = await dependencies.presenter.getLastAmountValidation()
            
            #expect(balanceCheckCalled == true, "잤액 확인이 호출되어야 함")
            #expect(presentationCalled == true, "Presenter 호출되어야 함")
            #expect(lastResponse?.isValid == expected, "금액 검증 결과가 예상과 일치해야 함")
            
            if expected {
                #expect(lastResponse?.errorMessage == nil, "성공 시 에러 메시지가 없어야 함")
                #expect(lastResponse?.parsedAmount == Decimal(string: amount), "파싱된 금액이 일치해야 함")
            }
        }
        
        @Test("무효한 금액 검증 실패", arguments: [
            ("", "금액을 입력해주세요"),
            ("   ", "금액을 입력해주세요"),
            ("abc", "유효한 금액을 입력해주세요"),
            ("-1.5", "유효한 금액을 입력해주세요"),
            ("0", "유효한 금액을 입력해주세요"),
            ("0.0", "유효한 금액을 입력해주세요")
        ])
        @MainActor
        func validateInvalidAmount(invalidAmount: String, expectedError: String) async {
            // Given
            let dependencies = makeTestDependencies()
            await dependencies.balanceProvider.setCurrentBalance(Decimal(2.0))
            
            let request = Send.ValidateAmount.Request(
                amount: invalidAmount,
                availableBalance: "2.0"
            )
            
            // When
            dependencies.interactor.validateAmount(request: request)
            
            // Then
            let presentationCalled = await dependencies.presenter.isPresentAmountValidationCalled()
            let lastResponse = await dependencies.presenter.getLastAmountValidation()
            
            #expect(presentationCalled == true, "Presenter 호출되어야 함")
            #expect(lastResponse?.isValid == false, "무효한 금액으로 판정되어야 함")
            #expect(lastResponse?.errorMessage == expectedError, "적절한 에러 메시지가 표시되어야 함")
        }
        
        @Test("잤액 부족 검증", arguments: [
            ("3.0", "2.0"),
            ("1.1", "1.0"),
            ("0.001", "0.0")
        ])
        @MainActor
        func validateInsufficientBalance(amount: String, balance: String) async {
            // Given
            let dependencies = makeTestDependencies()
            let balanceDecimal = Decimal(string: balance)!
            await dependencies.balanceProvider.setCurrentBalance(balanceDecimal)
            
            let request = Send.ValidateAmount.Request(
                amount: amount,
                availableBalance: balance
            )
            
            // When
            dependencies.interactor.validateAmount(request: request)
            
            // Then
            let presentationCalled = await dependencies.presenter.isPresentAmountValidationCalled()
            let lastResponse = await dependencies.presenter.getLastAmountValidation()
            
            #expect(presentationCalled == true, "Presenter 호출되어야 함")
            #expect(lastResponse?.isValid == false, "잤액 부족으로 판정되어야 함")
            #expect(lastResponse?.errorMessage == "잤액이 부족합니다", "잤액 부족 메시지가 표시되어야 함")
            #expect(lastResponse?.parsedAmount == Decimal(string: amount), "파싱된 금액이 저장되어야 함")
        }
        
        @Test("금액 검증 중 공백 문자 제거")
        @MainActor
        func validateAmountWithWhitespace() async {
            // Given
            let dependencies = makeTestDependencies()
            let amountWithSpaces = "  1.5  "
            let expectedAmount = Decimal(string: "1.5")!
            await dependencies.balanceProvider.setCurrentBalance(Decimal(2.0))
            
            let request = Send.ValidateAmount.Request(
                amount: amountWithSpaces,
                availableBalance: "2.0"
            )
            
            // When
            dependencies.interactor.validateAmount(request: request)
            
            // Then
            let lastResponse = await dependencies.presenter.getLastAmountValidation()
            #expect(lastResponse?.isValid == true, "공백이 제거된 금액으로 검증되어야 함")
            #expect(lastResponse?.parsedAmount == expectedAmount, "파싱된 금액이 일치해야 함")
        }
    }
    
    // MARK: - Gas Fee Estimation Business Logic Tests
    
    @Suite("Gas Fee Estimation")
    struct GasFeeEstimationTests {
        
        @Test("가스비 추정 성공")
        @MainActor
        func estimateGasFeeSuccess() async {
            // Given
            let dependencies = makeTestDependencies()
            let mockGasOptions = Send.GasOptions(
                slow: Send.GasFee(gasPrice: BigUInt(20000000000), estimatedTime: 300, feeInETH: 0.002, feeInUSD: 4.0),
                normal: Send.GasFee(gasPrice: BigUInt(25000000000), estimatedTime: 180, feeInETH: 0.003, feeInUSD: 6.0),
                fast: Send.GasFee(gasPrice: BigUInt(35000000000), estimatedTime: 60, feeInETH: 0.004, feeInUSD: 8.0)
            )
            await dependencies.gasEstimator.setMockGasOptions(mockGasOptions)
            
            let request = Send.EstimateGas.Request(
                recipientAddress: "0x742B15EcB8E3F6F7e7D58C4f9Ad2dBcEF8A5E9C3",
                amount: "1.5"
            )
            
            // When
            dependencies.interactor.estimateGasFee(request: request)
            
            // Then
            let estimationCalled = await dependencies.gasEstimator.isEstimateGasFeeCalled()
            let presentationCalled = await dependencies.presenter.isPresentGasEstimationCalled()
            let lastResponse = await dependencies.presenter.getLastGasEstimation()
            
            #expect(estimationCalled == true, "가스비 추정이 호출되어야 함")
            #expect(presentationCalled == true, "Presenter 호출되어야 함")
            #expect(lastResponse?.gasOptions?.normal.feeInETH == 0.003, "정상 가스비가 일치해야 함")
            #expect(lastResponse?.error == nil, "성공 시 에러가 없어야 함")
        }
        
        @Test("가스비 추정 실패 - 네트워크 오류")
        @MainActor
        func estimateGasFeeNetworkFailure() async {
            // Given
            let dependencies = makeTestDependencies()
            await dependencies.gasEstimator.setMockGasOptions(nil) // 네트워크 오류 시밬레이션
            
            let request = Send.EstimateGas.Request(
                recipientAddress: "0x742B15EcB8E3F6F7e7D58C4f9Ad2dBcEF8A5E9C3",
                amount: "1.5"
            )
            
            // When
            dependencies.interactor.estimateGasFee(request: request)
            
            // Then
            let presentationCalled = await dependencies.presenter.isPresentGasEstimationCalled()
            let lastResponse = await dependencies.presenter.getLastGasEstimation()
            
            #expect(presentationCalled == true, "Presenter 호출되어야 함")
            #expect(lastResponse?.gasOptions == nil, "실패 시 가스 옵션이 비어있어야 함")
            #expect(lastResponse?.error == "가스비를 계산할 수 없습니다. 네트워크 상태를 확인해주세요.", "적절한 에러 메시지가 표시되어야 함")
        }
        
        @Test("가스비 옵션 비교 검증")
        @MainActor
        func verifyGasFeeOptionsComparison() async {
            // Given
            let dependencies = makeTestDependencies()
            let mockGasOptions = Send.GasOptions(
                slow: Send.GasFee(gasPrice: BigUInt(20000000000), estimatedTime: 300, feeInETH: 0.002, feeInUSD: 4.0),
                normal: Send.GasFee(gasPrice: BigUInt(25000000000), estimatedTime: 180, feeInETH: 0.003, feeInUSD: 6.0),
                fast: Send.GasFee(gasPrice: BigUInt(35000000000), estimatedTime: 60, feeInETH: 0.004, feeInUSD: 8.0)
            )
            await dependencies.gasEstimator.setMockGasOptions(mockGasOptions)
            
            let request = Send.EstimateGas.Request(
                recipientAddress: "0x742B15EcB8E3F6F7e7D58C4f9Ad2dBcEF8A5E9C3",
                amount: "1.5"
            )
            
            // When
            dependencies.interactor.estimateGasFee(request: request)
            
            // Then
            let lastResponse = await dependencies.presenter.getLastGasEstimation()
            let gasOptions = lastResponse?.gasOptions
            
            #expect(gasOptions?.slow.feeInETH < gasOptions?.normal.feeInETH, "느림 옵션이 보통보다 저렴해야 함")
            #expect(gasOptions?.normal.feeInETH < gasOptions?.fast.feeInETH, "보통 옵션이 빠름보다 저렴해야 함")
            #expect(gasOptions?.slow.estimatedTime > gasOptions?.normal.estimatedTime, "느림 옵션이 보통보다 오래 걸려야 함")
            #expect(gasOptions?.normal.estimatedTime > gasOptions?.fast.estimatedTime, "보통 옵션이 빠름보다 오래 걸려야 함")
        }
    }
    
    // MARK: - Transaction Preparation Business Logic Tests
    
    @Suite("Transaction Preparation")
    struct TransactionPreparationTests {
        
        @Test("모든 입력값 검증 후 거래 준비 성공")
        @MainActor
        func prepareTransactionSuccess() async {
            // Given
            let dependencies = makeTestDependencies()
            let recipientAddress = "0x742B15EcB8E3F6F7e7D58C4f9Ad2dBcEF8A5E9C3"
            let amount = "1.5"
            let gasOption = Send.GasFee(gasPrice: BigUInt(25000000000), estimatedTime: 180, feeInETH: 0.003, feeInUSD: 6.0)
            
            // Mock 설정
            await dependencies.addressValidator.setMockResult(true)
            await dependencies.balanceProvider.setCurrentBalance(Decimal(2.0))
            let expectedTransaction = Send.Transaction(
                recipientAddress: recipientAddress,
                amount: Decimal(string: amount)!,
                gasPrice: gasOption.gasPrice,
                gasLimit: BigUInt(21000),
                nonce: BigUInt(42)
            )
            await dependencies.transactionSender.setMockTransaction(expectedTransaction)
            
            let request = Send.PrepareTransaction.Request(
                recipientAddress: recipientAddress,
                amount: amount,
                selectedGasFee: gasOption
            )
            
            // When
            dependencies.interactor.prepareTransaction(request: request)
            
            // Then
            let addressValidationCalled = await dependencies.addressValidator.isValidateEthereumAddressCalled()
            let balanceCheckCalled = await dependencies.balanceProvider.isBalanceSufficientCalled()
            let transactionPrepCalled = await dependencies.transactionSender.isPrepareTransactionCalled()
            let presentationCalled = await dependencies.presenter.isPresentTransactionPreparationCalled()
            let lastResponse = await dependencies.presenter.getLastTransactionPreparation()
            
            #expect(addressValidationCalled == true, "주소 검증이 호출되어야 함")
            #expect(balanceCheckCalled == true, "잤액 확인이 호출되어야 함")
            #expect(transactionPrepCalled == true, "거래 준비가 호출되어야 함")
            #expect(presentationCalled == true, "Presenter 호출되어야 함")
            #expect(lastResponse?.isReadyToSend == true, "거래 준비 완료 상태여야 함")
            #expect(lastResponse?.transaction != nil, "거래 객체가 생성되어야 함")
            #expect(lastResponse?.errorMessage == nil, "성공 시 에러 메시지가 없어야 함")
        }
        
        @Test("잘못된 수신자 주소로 거래 준비 실패")
        @MainActor
        func prepareTransactionInvalidAddress() async {
            // Given
            let dependencies = makeTestDependencies()
            let invalidAddress = "invalid_address"
            let amount = "1.5"
            let gasOption = Send.GasFee(gasPrice: BigUInt(25000000000), estimatedTime: 180, feeInETH: 0.003, feeInUSD: 6.0)
            
            await dependencies.addressValidator.setMockResult(false)
            
            let request = Send.PrepareTransaction.Request(
                recipientAddress: invalidAddress,
                amount: amount,
                selectedGasFee: gasOption
            )
            
            // When
            dependencies.interactor.prepareTransaction(request: request)
            
            // Then
            let presentationCalled = await dependencies.presenter.isPresentTransactionPreparationCalled()
            let lastResponse = await dependencies.presenter.getLastTransactionPreparation()
            
            #expect(presentationCalled == true, "Presenter 호출되어야 함")
            #expect(lastResponse?.isReadyToSend == false, "거래 준비 실패 상태여야 함")
            #expect(lastResponse?.transaction == nil, "실패 시 거래 객체가 없어야 함")
            #expect(lastResponse?.errorMessage == "잘못된 수신자 주소입니다", "적절한 에러 메시지가 표시되어야 함")
        }
        
        @Test("잘못된 금액으로 거래 준비 실패", arguments: [
            ("", "잘못된 금액입니다"),
            ("abc", "잘못된 금액입니다"),
            ("-1.5", "잘못된 금액입니다"),
            ("0", "잘못된 금액입니다")
        ])
        @MainActor
        func prepareTransactionInvalidAmount(invalidAmount: String, expectedError: String) async {
            // Given
            let dependencies = makeTestDependencies()
            let validAddress = "0x742B15EcB8E3F6F7e7D58C4f9Ad2dBcEF8A5E9C3"
            let gasOption = Send.GasFee(gasPrice: BigUInt(25000000000), estimatedTime: 180, feeInETH: 0.003, feeInUSD: 6.0)
            
            await dependencies.addressValidator.setMockResult(true)
            
            let request = Send.PrepareTransaction.Request(
                recipientAddress: validAddress,
                amount: invalidAmount,
                selectedGasFee: gasOption
            )
            
            // When
            dependencies.interactor.prepareTransaction(request: request)
            
            // Then
            let lastResponse = await dependencies.presenter.getLastTransactionPreparation()
            #expect(lastResponse?.isReadyToSend == false, "거래 준비 실패 상태여야 함")
            #expect(lastResponse?.errorMessage == expectedError, "적절한 에러 메시지가 표시되어야 함")
        }
        
        @Test("잤액 부족으로 거래 준비 실패")
        @MainActor
        func prepareTransactionInsufficientBalance() async {
            // Given
            let dependencies = makeTestDependencies()
            let validAddress = "0x742B15EcB8E3F6F7e7D58C4f9Ad2dBcEF8A5E9C3"
            let amount = "2.0"
            let gasOption = Send.GasFee(gasPrice: BigUInt(25000000000), estimatedTime: 180, feeInETH: 0.003, feeInUSD: 6.0)
            
            await dependencies.addressValidator.setMockResult(true)
            await dependencies.balanceProvider.setCurrentBalance(Decimal(1.0)) // 부족한 잤액
            await dependencies.balanceProvider.setBalanceSufficientResult(false)
            
            let request = Send.PrepareTransaction.Request(
                recipientAddress: validAddress,
                amount: amount,
                selectedGasFee: gasOption
            )
            
            // When
            dependencies.interactor.prepareTransaction(request: request)
            
            // Then
            let lastResponse = await dependencies.presenter.getLastTransactionPreparation()
            #expect(lastResponse?.isReadyToSend == false, "거래 준비 실패 상태여야 함")
            #expect(lastResponse?.errorMessage == "잤액이 부족합니다 (가스비 포함)", "적절한 에러 메시지가 표시되어야 함")
        }
    }
    
    // MARK: - Biometric Authentication Business Logic Tests
    
    @Suite("Biometric Authentication & Transaction Sending")
    struct BiometricAuthenticationAndTransactionSendingTests {
        
        @Test("생체 인증 성공 후 거래 전송 성공")
        @MainActor
        func sendTransactionWithSuccessfulBiometricAuth() async {
            // Given
            let dependencies = makeTestDependencies()
            let transaction = Send.Transaction(
                recipientAddress: "0x742B15EcB8E3F6F7e7D58C4f9Ad2dBcEF8A5E9C3",
                amount: Decimal(1.5),
                gasPrice: BigUInt(25000000000),
                gasLimit: BigUInt(21000),
                nonce: BigUInt(42)
            )
            
            let expectedTxHash = "0xabcd1234567890abcdef1234567890abcdef1234567890abcdef1234567890ab"
            await dependencies.biometricAuth.setMockResult(true)
            await dependencies.transactionSender.setMockSendResult(.success(expectedTxHash))
            
            let request = Send.SendTransaction.Request(transaction: transaction)
            
            // When
            await dependencies.interactor.sendTransaction(request: request)
            
            // Then
            let biometricCalled = await dependencies.biometricAuth.isAuthenticateWithBiometricCalled()
            let transactionSentCalled = await dependencies.transactionSender.isSendTransactionCalled()
            let presentationCalled = await dependencies.presenter.isPresentTransactionResultCalled()
            let lastResponse = await dependencies.presenter.getLastTransactionResult()
            
            #expect(biometricCalled == true, "생체 인증이 호출되어야 함")
            #expect(transactionSentCalled == true, "거래 전송이 호출되어야 함")
            #expect(presentationCalled == true, "Presenter 호출되어야 함")
            #expect(lastResponse?.success == true, "거래 전송 성공 상태여야 함")
            #expect(lastResponse?.transactionHash == expectedTxHash, "트랜잭션 해시가 일치해야 함")
            #expect(lastResponse?.errorMessage == nil, "성공 시 에러 메시지가 없어야 함")
        }
        
        @Test("생체 인증 실패로 거래 전송 비허용")
        @MainActor
        func sendTransactionWithFailedBiometricAuth() async {
            // Given
            let dependencies = makeTestDependencies()
            let transaction = Send.Transaction(
                recipientAddress: "0x742B15EcB8E3F6F7e7D58C4f9Ad2dBcEF8A5E9C3",
                amount: Decimal(1.5),
                gasPrice: BigUInt(25000000000),
                gasLimit: BigUInt(21000),
                nonce: BigUInt(42)
            )
            
            await dependencies.biometricAuth.setMockResult(false)
            
            let request = Send.SendTransaction.Request(transaction: transaction)
            
            // When
            await dependencies.interactor.sendTransaction(request: request)
            
            // Then
            let biometricCalled = await dependencies.biometricAuth.isAuthenticateWithBiometricCalled()
            let transactionSentCalled = await dependencies.transactionSender.isSendTransactionCalled()
            let presentationCalled = await dependencies.presenter.isPresentTransactionResultCalled()
            let lastResponse = await dependencies.presenter.getLastTransactionResult()
            
            #expect(biometricCalled == true, "생체 인증이 호출되어야 함")
            #expect(transactionSentCalled == false, "생체 인증 실패 시 거래 전송이 호출되지 않아야 함")
            #expect(presentationCalled == true, "Presenter 호출되어야 함")
            #expect(lastResponse?.success == false, "거래 전송 실패 상태여야 함")
            #expect(lastResponse?.transactionHash == nil, "실패 시 트랜잭션 해시가 없어야 함")
            #expect(lastResponse?.errorMessage == "생체 인증에 실패했습니다", "생체 인증 실패 메시지가 표시되어야 함")
        }
        
        @Test("네트워크 오류로 거래 전송 실패")
        @MainActor
        func sendTransactionNetworkFailure() async {
            // Given
            let dependencies = makeTestDependencies()
            let transaction = Send.Transaction(
                recipientAddress: "0x742B15EcB8E3F6F7e7D58C4f9Ad2dBcEF8A5E9C3",
                amount: Decimal(1.5),
                gasPrice: BigUInt(25000000000),
                gasLimit: BigUInt(21000),
                nonce: BigUInt(42)
            )
            
            await dependencies.biometricAuth.setMockResult(true)
            await dependencies.transactionSender.setMockSendResult(.failure(SendError.transactionFailed("네트워크 오류로 인해 거래가 실패했습니다")))
            
            let request = Send.SendTransaction.Request(transaction: transaction)
            
            // When
            await dependencies.interactor.sendTransaction(request: request)
            
            // Then
            let biometricCalled = await dependencies.biometricAuth.isAuthenticateWithBiometricCalled()
            let transactionSentCalled = await dependencies.transactionSender.isSendTransactionCalled()
            let lastResponse = await dependencies.presenter.getLastTransactionResult()
            
            #expect(biometricCalled == true, "생체 인증이 호출되어야 함")
            #expect(transactionSentCalled == true, "거래 전송이 시도되어야 함")
            #expect(lastResponse?.success == false, "거래 전송 실패 상태여야 함")
            #expect(lastResponse?.transactionHash == nil, "실패 시 트랜잭션 해시가 없어야 함")
            #expect(lastResponse?.errorMessage?.contains("네트워크 오류") == true, "네트워크 오류 메시지가 포함되어야 함")
        }
        
        @Test("거래 전송 타임아웃")
        @MainActor
        func sendTransactionTimeout() async {
            // Given
            let dependencies = makeTestDependencies()
            let transaction = Send.Transaction(
                recipientAddress: "0x742B15EcB8E3F6F7e7D58C4f9Ad2dBcEF8A5E9C3",
                amount: Decimal(1.5),
                gasPrice: BigUInt(25000000000),
                gasLimit: BigUInt(21000),
                nonce: BigUInt(42)
            )
            
            await dependencies.biometricAuth.setMockResult(true)
            await dependencies.transactionSender.setMockSendResult(.failure(SendError.transactionFailed("요청 시간이 초과되었습니다")))
            
            let request = Send.SendTransaction.Request(transaction: transaction)
            
            // When
            await dependencies.interactor.sendTransaction(request: request)
            
            // Then
            let lastResponse = await dependencies.presenter.getLastTransactionResult()
            #expect(lastResponse?.success == false, "타임아웃으로 실패 상태여야 함")
            #expect(lastResponse?.errorMessage?.contains("시간이 초과") == true, "타임아웃 메시지가 포함되어야 함")
        }
    }
}

// MARK: - SOLID 원칙을 준수하는 Mock 클래스들

// MARK: - Single Responsibility Principle (SRP) 적용
// 각 Mock 클래스는 하나의 책임만 가짐

/// Presentation Logic Mock - 데이터 표시 체크 전담
actor MockSendPresenterProtocol: SendPresentationLogic {
    private var addressValidationCalled = false
    private var amountValidationCalled = false
    private var gasEstimationCalled = false
    private var transactionPreparationCalled = false
    private var transactionResultCalled = false
    
    private var lastAddressValidation: Send.ValidateAddress.Response?
    private var lastAmountValidation: Send.ValidateAmount.Response?
    private var lastGasEstimation: Send.EstimateGas.Response?
    private var lastTransactionPreparation: Send.PrepareTransaction.Response?
    private var lastTransactionResult: Send.SendTransaction.Response?
    
    nonisolated func presentAddressValidation(response: Send.ValidateAddress.Response) {
        Task {
            await self.setAddressValidation(response: response)
        }
    }
    
    nonisolated func presentAmountValidation(response: Send.ValidateAmount.Response) {
        Task {
            await self.setAmountValidation(response: response)
        }
    }
    
    nonisolated func presentGasEstimation(response: Send.EstimateGas.Response) {
        Task {
            await self.setGasEstimation(response: response)
        }
    }
    
    nonisolated func presentTransactionPreparation(response: Send.PrepareTransaction.Response) {
        Task {
            await self.setTransactionPreparation(response: response)
        }
    }
    
    nonisolated func presentTransactionResult(response: Send.SendTransaction.Response) {
        Task {
            await self.setTransactionResult(response: response)
        }
    }
    
    // MARK: - Actor-safe setters
    private func setAddressValidation(response: Send.ValidateAddress.Response) {
        addressValidationCalled = true
        lastAddressValidation = response
    }
    
    private func setAmountValidation(response: Send.ValidateAmount.Response) {
        amountValidationCalled = true
        lastAmountValidation = response
    }
    
    private func setGasEstimation(response: Send.EstimateGas.Response) {
        gasEstimationCalled = true
        lastGasEstimation = response
    }
    
    private func setTransactionPreparation(response: Send.PrepareTransaction.Response) {
        transactionPreparationCalled = true
        lastTransactionPreparation = response
    }
    
    private func setTransactionResult(response: Send.SendTransaction.Response) {
        transactionResultCalled = true
        lastTransactionResult = response
    }
    
    // MARK: - Test Verification Methods
    func isPresentAddressValidationCalled() -> Bool {
        return addressValidationCalled
    }
    
    func isPresentAmountValidationCalled() -> Bool {
        return amountValidationCalled
    }
    
    func isPresentGasEstimationCalled() -> Bool {
        return gasEstimationCalled
    }
    
    func isPresentTransactionPreparationCalled() -> Bool {
        return transactionPreparationCalled
    }
    
    func isPresentTransactionResultCalled() -> Bool {
        return transactionResultCalled
    }
    
    func getLastAddressValidation() -> Send.ValidateAddress.Response? {
        return lastAddressValidation
    }
    
    func getLastAmountValidation() -> Send.ValidateAmount.Response? {
        return lastAmountValidation
    }
    
    func getLastGasEstimation() -> Send.EstimateGas.Response? {
        return lastGasEstimation
    }
    
    func getLastTransactionPreparation() -> Send.PrepareTransaction.Response? {
        return lastTransactionPreparation
    }
    
    func getLastTransactionResult() -> Send.SendTransaction.Response? {
        return lastTransactionResult
    }
}

/// Address Validation Mock - 주소 검증 전담
actor MockAddressValidatorProtocol: AddressValidatorProtocol {
    private var validateEthereumAddressCalled = false
    private var mockResult = true
    private var lastValidatedAddress: String?
    
    nonisolated func isValidEthereumAddress(_ address: String) -> Bool {
        Task {
            await self.recordValidation(address: address)
        }
        return mockResult
    }
    
    nonisolated func formatAddress(_ address: String) -> String {
        guard address.count > 10 else { return address }
        let start = String(address.prefix(6))
        let end = String(address.suffix(4))
        return "\(start)...\(end)"
    }
    
    private func recordValidation(address: String) {
        validateEthereumAddressCalled = true
        lastValidatedAddress = address
    }
    
    func setMockResult(_ result: Bool) {
        mockResult = result
    }
    
    func isValidateEthereumAddressCalled() -> Bool {
        return validateEthereumAddressCalled
    }
    
    func getLastValidatedAddress() -> String? {
        return lastValidatedAddress
    }
}

/// Balance Provider Mock - 잤액 관리 전담
actor MockBalanceProviderProtocol {
    private var getCurrentBalanceCalled = false
    private var balanceSufficientCalled = false
    private var currentBalance = Decimal(0)
    private var balanceSufficientResult = true
    
    func getCurrentBalance() -> Decimal {
        getCurrentBalanceCalled = true
        return currentBalance
    }
    
    func isBalanceSufficient(amount: Decimal, includingGasFee gasFee: Decimal) -> Bool {
        balanceSufficientCalled = true
        return balanceSufficientResult
    }
    
    func setCurrentBalance(_ balance: Decimal) {
        currentBalance = balance
    }
    
    func setBalanceSufficientResult(_ result: Bool) {
        balanceSufficientResult = result
    }
    
    func isGetCurrentBalanceCalled() -> Bool {
        return getCurrentBalanceCalled
    }
    
    func isBalanceSufficientCalled() -> Bool {
        return balanceSufficientCalled
    }
}

/// Gas Estimator Mock - 가스비 추정 전담
actor MockGasEstimatorProtocol {
    private var estimateGasFeeCalled = false
    private var mockGasOptions: Send.GasOptions?
    
    func estimateGasFee(recipientAddress: String, amount: String) -> Send.GasOptions? {
        estimateGasFeeCalled = true
        return mockGasOptions
    }
    
    func setMockGasOptions(_ options: Send.GasOptions?) {
        mockGasOptions = options
    }
    
    func isEstimateGasFeeCalled() -> Bool {
        return estimateGasFeeCalled
    }
}

/// Biometric Authenticator Mock - 생체 인증 전담
actor MockBiometricAuthenticatorProtocol {
    private var authenticateWithBiometricCalled = false
    private var mockResult = true
    
    func authenticateWithBiometric() async -> Bool {
        authenticateWithBiometricCalled = true
        return mockResult
    }
    
    func setMockResult(_ result: Bool) {
        mockResult = result
    }
    
    func isAuthenticateWithBiometricCalled() -> Bool {
        return authenticateWithBiometricCalled
    }
}

/// Transaction Sender Mock - 거래 전송 전담
actor MockTransactionSenderProtocol {
    private var prepareTransactionCalled = false
    private var sendTransactionCalled = false
    private var mockTransaction: Send.Transaction?
    private var mockSendResult: Result<String, Error> = .success("0x123")
    
    func prepareTransaction(recipientAddress: String, amount: Decimal, gasFee: Send.GasFee) -> Send.Transaction? {
        prepareTransactionCalled = true
        return mockTransaction
    }
    
    func sendTransaction(_ transaction: Send.Transaction) async -> Result<String, Error> {
        sendTransactionCalled = true
        return mockSendResult
    }
    
    func setMockTransaction(_ transaction: Send.Transaction?) {
        mockTransaction = transaction
    }
    
    func setMockSendResult(_ result: Result<String, Error>) {
        mockSendResult = result
    }
    
    func isPrepareTransactionCalled() -> Bool {
        return prepareTransactionCalled
    }
    
    func isSendTransactionCalled() -> Bool {
        return sendTransactionCalled
    }
}

// MARK: - 비즈니스 로직 완전 테스트 커버리지 구성

@Suite("Complete Business Logic Coverage Tests")
struct CompleteBusinessLogicTests {
    
    @Test("전체 송금 프로세스 통합 테스트")
    @MainActor
    func completeTransferProcessIntegrationTest() async {
        // Given
        let dependencies = makeTestDependencies()
        
        // 모든 Mock 설정
        await dependencies.addressValidator.setMockResult(true)
        await dependencies.balanceProvider.setCurrentBalance(Decimal(5.0))
        await dependencies.balanceProvider.setBalanceSufficientResult(true)
        
        let gasOptions = Send.GasOptions(
            slow: Send.GasFee(gasPrice: BigUInt(20000000000), estimatedTime: 300, feeInETH: 0.002, feeInUSD: 4.0),
            normal: Send.GasFee(gasPrice: BigUInt(25000000000), estimatedTime: 180, feeInETH: 0.003, feeInUSD: 6.0),
            fast: Send.GasFee(gasPrice: BigUInt(35000000000), estimatedTime: 60, feeInETH: 0.004, feeInUSD: 8.0)
        )
        await dependencies.gasEstimator.setMockGasOptions(gasOptions)
        
        let mockTransaction = Send.Transaction(
            recipientAddress: "0x742B15EcB8E3F6F7e7D58C4f9Ad2dBcEF8A5E9C3",
            amount: Decimal(1.5),
            gasPrice: BigUInt(25000000000),
            gasLimit: BigUInt(21000),
            nonce: BigUInt(42)
        )
        await dependencies.transactionSender.setMockTransaction(mockTransaction)
        await dependencies.biometricAuth.setMockResult(true)
        await dependencies.transactionSender.setMockSendResult(.success("0xabcdef1234567890"))
        
        // When - 전체 송금 프로세스 실행
        
        // 1. 주소 검증
        let addressRequest = Send.ValidateAddress.Request(address: "0x742B15EcB8E3F6F7e7D58C4f9Ad2dBcEF8A5E9C3")
        dependencies.interactor.validateAddress(request: addressRequest)
        
        // 2. 금액 검증
        let amountRequest = Send.ValidateAmount.Request(amount: "1.5", availableBalance: "5.0")
        dependencies.interactor.validateAmount(request: amountRequest)
        
        // 3. 가스비 추정
        let gasRequest = Send.EstimateGas.Request(recipientAddress: "0x742B15EcB8E3F6F7e7D58C4f9Ad2dBcEF8A5E9C3", amount: "1.5")
        dependencies.interactor.estimateGasFee(request: gasRequest)
        
        // 4. 거래 준비
        let prepareRequest = Send.PrepareTransaction.Request(
            recipientAddress: "0x742B15EcB8E3F6F7e7D58C4f9Ad2dBcEF8A5E9C3",
            amount: "1.5",
            selectedGasFee: gasOptions.normal
        )
        dependencies.interactor.prepareTransaction(request: prepareRequest)
        
        // 5. 거래 전송
        let sendRequest = Send.SendTransaction.Request(transaction: mockTransaction)
        await dependencies.interactor.sendTransaction(request: sendRequest)
        
        // Then - 전체 프로세스 검증
        let addressValidation = await dependencies.presenter.getLastAddressValidation()
        let amountValidation = await dependencies.presenter.getLastAmountValidation()
        let gasEstimation = await dependencies.presenter.getLastGasEstimation()
        let transactionPreparation = await dependencies.presenter.getLastTransactionPreparation()
        let transactionResult = await dependencies.presenter.getLastTransactionResult()
        
        #expect(addressValidation?.isValid == true, "주소 검증 성공")
        #expect(amountValidation?.isValid == true, "금액 검증 성공")
        #expect(gasEstimation?.gasOptions != nil, "가스비 추정 성공")
        #expect(transactionPreparation?.isReadyToSend == true, "거래 준비 성공")
        #expect(transactionResult?.success == true, "거래 전송 성공")
        #expect(transactionResult?.transactionHash == "0xabcdef1234567890", "트랜잭션 해시 일치")
    }
    
    @Test("예외 상황 대응 테스트 - 연속된 실패")
    @MainActor
    func handleMultipleFailuresGracefully() async {
        // Given
        let dependencies = makeTestDependencies()
        
        // 연속된 실패 상황 설정
        await dependencies.addressValidator.setMockResult(false)
        await dependencies.balanceProvider.setBalanceSufficientResult(false)
        await dependencies.gasEstimator.setMockGasOptions(nil)
        await dependencies.biometricAuth.setMockResult(false)
        
        // When - 연속된 실패 상황 실행
        let addressRequest = Send.ValidateAddress.Request(address: "invalid")
        dependencies.interactor.validateAddress(request: addressRequest)
        
        let amountRequest = Send.ValidateAmount.Request(amount: "100", availableBalance: "1")
        dependencies.interactor.validateAmount(request: amountRequest)
        
        let gasRequest = Send.EstimateGas.Request(recipientAddress: "invalid", amount: "100")
        dependencies.interactor.estimateGasFee(request: gasRequest)
        
        // Then - 오류 처리 검증
        let addressValidation = await dependencies.presenter.getLastAddressValidation()
        let amountValidation = await dependencies.presenter.getLastAmountValidation()
        let gasEstimation = await dependencies.presenter.getLastGasEstimation()
        
        #expect(addressValidation?.isValid == false, "주소 검증 실패 처리")
        #expect(amountValidation?.isValid == false, "금액 검증 실패 처리")
        #expect(gasEstimation?.error != nil, "가스비 추정 실패 처리")
        
        // 에러 메시지 정확성 검증
        #expect(addressValidation?.errorMessage?.isEmpty == false, "주소 에러 메시지 존재")
        #expect(amountValidation?.errorMessage?.isEmpty == false, "금액 에러 메시지 존재")
        #expect(gasEstimation?.error?.isEmpty == false, "가스비 에러 메시지 존재")
    }
}

// MARK: - 성능 및 보안 테스트

@Suite("Performance and Security Tests")
struct PerformanceAndSecurityTests {
    
    @Test("대용량 금액 처리 성능 테스트")
    @MainActor
    func performanceTestWithLargeAmounts() async {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let dependencies = makeTestDependencies()
        await dependencies.balanceProvider.setCurrentBalance(Decimal(1000000)) // 1M ETH
        
        // 대용량 거래 처리
        let request = Send.ValidateAmount.Request(amount: "999999.999999", availableBalance: "1000000")
        dependencies.interactor.validateAmount(request: request)
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let executionTime = endTime - startTime
        
        // 성능 기준: 100ms 이하
        #expect(executionTime < 0.1, "대용량 금액 처리 시간이 100ms 이하여야 함")
        
        let result = await dependencies.presenter.getLastAmountValidation()
        #expect(result?.isValid == true, "대용량 거래 처리 성공")
    }
    
    @Test("동시성 안전성 테스트")
    @MainActor
    func concurrencySafetyTest() async {
        let dependencies = makeTestDependencies()
        await dependencies.addressValidator.setMockResult(true)
        
        // 동시에 여러 요청 처리
        await withTaskGroup(of: Void.self) { group in
            for i in 1...10 {
                group.addTask {
                    let request = Send.ValidateAddress.Request(address: "0x742B15EcB8E3F6F7e7D58C4f9Ad2dBcEF8A5E9C\(i)")
                    dependencies.interactor.validateAddress(request: request)
                }
            }
        }
        
        // Actor 기반 Mock이 동시성 안전성을 보장해야 함
        let validationCalled = await dependencies.addressValidator.isValidateEthereumAddressCalled()
        #expect(validationCalled == true, "동시 요청 처리 성공")
    }
    
    @Test("보안 검증 - 생체 인증 필수")
    @MainActor
    func securityTestBiometricRequired() async {
        let dependencies = makeTestDependencies()
        let transaction = Send.Transaction(
            recipientAddress: "0x742B15EcB8E3F6F7e7D58C4f9Ad2dBcEF8A5E9C3",
            amount: Decimal(1000), // 대용량 거래
            gasPrice: BigUInt(25000000000),
            gasLimit: BigUInt(21000),
            nonce: BigUInt(42)
        )
        
        // 생체 인증 없이 거래 시도
        await dependencies.biometricAuth.setMockResult(false)
        
        let request = Send.SendTransaction.Request(transaction: transaction)
        await dependencies.interactor.sendTransaction(request: request)
        
        let result = await dependencies.presenter.getLastTransactionResult()
        let biometricCalled = await dependencies.biometricAuth.isAuthenticateWithBiometricCalled()
        let transactionSent = await dependencies.transactionSender.isSendTransactionCalled()
        
        #expect(biometricCalled == true, "생체 인증 필수 호출")
        #expect(transactionSent == false, "생체 인증 실패 시 거래 차단")
        #expect(result?.success == false, "보안 검증 실패")
        #expect(result?.errorMessage?.contains("생체 인증") == true, "보안 에러 메시지")
    }
}

// MARK: - Legacy Send Worker Tests (기존 테스트 유지)

@Suite("Send Worker Tests")
struct SendWorkerTests {
    
    // MARK: - Test Fixtures
    
    private func makeWorker() -> SendWorker {
        return SendWorker()
    }
    
    private func makeWorkerWithMockBalance(_ balance: Decimal) -> SendWorker {
        return SendWorker(mockBalance: balance)
    }
    
    // MARK: - Address Validation Tests
    
    @Test("Should accept valid Ethereum addresses", arguments: [
        "0x742B15EcB8E3F6F7e7D58C4f9Ad2dBcEF8A5E9C3",
        "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed",
        "0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359"
    ])
    func validateValidEthereumAddress(validAddress: String) {
        // Given
        let worker = makeWorker()
        
        // When
        let isValid = worker.validateEthereumAddress(validAddress)
        
        // Then
        #expect(isValid, "Address should be valid: \(validAddress)")
    }
    
    @Test("Should reject invalid Ethereum addresses", arguments: [
        "742B15EcB8E3F6F7e7D58C4f9Ad2dBcEF8A5E9C3", // No 0x prefix
        "0x742B15EcB8E3F6F7e7D58C4f9Ad2dBcEF8A5E9C", // Too short
        "0x742B15EcB8E3F6F7e7D58C4f9Ad2dBcEF8A5E9C32", // Too long
        "0xZZZB15EcB8E3F6F7e7D58C4f9Ad2dBcEF8A5E9C3", // Invalid hex
        "",
        "invalid_address"
    ])
    func validateInvalidEthereumAddress(invalidAddress: String) {
        // Given
        let worker = makeWorker()
        
        // When
        let isValid = worker.validateEthereumAddress(invalidAddress)
        
        // Then
        #expect(isValid == false, "Address should be invalid: \(invalidAddress)")
    }
    
    // MARK: - Balance Tests
    
    @Test("Should return true when balance is sufficient")
    func checkSufficientBalance() {
        // Given
        let worker = makeWorkerWithMockBalance(Decimal(2.0))
        let amount = Decimal(1.5)
        let gasFee = Decimal(0.003)
        
        // When
        let isSufficient = worker.isBalanceSufficient(amount: amount, includingGasFee: gasFee)
        
        // Then
        #expect(isSufficient)
    }
    
    @Test("Should return false when balance is insufficient")
    func checkInsufficientBalance() {
        // Given
        let worker = makeWorkerWithMockBalance(Decimal(1.0))
        let amount = Decimal(1.5)
        let gasFee = Decimal(0.003)
        
        // When
        let isSufficient = worker.isBalanceSufficient(amount: amount, includingGasFee: gasFee)
        
        // Then
        #expect(isSufficient == false)
    }
}
