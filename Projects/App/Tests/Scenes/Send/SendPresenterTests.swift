import Testing
import Foundation
@testable import Scenes
@testable import Entity

// MARK: - SendPresenter 테스트

@MainActor @Suite("SendPresenter 테스트")
struct SendPresenterTests {
    
    // MARK: - Spy Classes
    
    class DisplayLogicSpy: SendDisplayLogic {
        var displayAddressValidationCalled = false
        var displayAddressValidationViewModel: SendScene.ValidateAddress.ViewModel?
        
        func displayAddressValidation(viewModel: SendScene.ValidateAddress.ViewModel) {
            displayAddressValidationCalled = true
            displayAddressValidationViewModel = viewModel
        }
        
        var displayAmountValidationCalled = false
        var displayAmountValidationViewModel: SendScene.ValidateAmount.ViewModel?
        
        func displayAmountValidation(viewModel: SendScene.ValidateAmount.ViewModel) {
            displayAmountValidationCalled = true
            displayAmountValidationViewModel = viewModel
        }
        
        var displayGasEstimationCalled = false
        var displayGasEstimationViewModel: SendScene.EstimateGas.ViewModel?
        
        func displayGasEstimation(viewModel: SendScene.EstimateGas.ViewModel) {
            displayGasEstimationCalled = true
            displayGasEstimationViewModel = viewModel
        }
        
        var displayTransactionPreparationCalled = false
        var displayTransactionPreparationViewModel: SendScene.PrepareTransaction.ViewModel?
        
        func displayTransactionPreparation(viewModel: SendScene.PrepareTransaction.ViewModel) {
            displayTransactionPreparationCalled = true
            displayTransactionPreparationViewModel = viewModel
        }
        
        var displayTransactionResultCalled = false
        var displayTransactionResultViewModel: SendScene.SendTransaction.ViewModel?
        
        func displayTransactionResult(viewModel: SendScene.SendTransaction.ViewModel) {
            displayTransactionResultCalled = true
            displayTransactionResultViewModel = viewModel
        }
        
        var displayBiometricAuthResultCalled = false
        var displayBiometricAuthResultViewModel: SendScene.BiometricAuth.ViewModel?
        
        func displayBiometricAuthResult(viewModel: SendScene.BiometricAuth.ViewModel) {
            displayBiometricAuthResultCalled = true
            displayBiometricAuthResultViewModel = viewModel
        }
        
        var displayQRScannerCalled = false
        var displayQRScannerViewModel: SendScene.QRScanner.ViewModel?
        
        func displayQRScanner(viewModel: SendScene.QRScanner.ViewModel) {
            displayQRScannerCalled = true
            displayQRScannerViewModel = viewModel
        }
    }
    
    // MARK: - Address Validation Presentation Tests
    
    @Suite("주소 검증 표시")
    struct AddressValidationPresentation {
        
        @Test("유효한 주소 표시")
        func testPresentValidAddress() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = SendPresenter(viewController: displayLogicSpy)
            
            let response = SendScene.ValidateAddress.Response(
                isValid: true,
                message: nil
            )
            
            // When
            sut.presentAddressValidation(response: response)
            
            // Then
            #expect(displayLogicSpy.displayAddressValidationCalled == true, "Display 메서드가 호출되어야 함")
            #expect(
                displayLogicSpy.displayAddressValidationViewModel?.isValid == true,
                "유효한 주소로 표시되어야 함"
            )
            #expect(
                displayLogicSpy.displayAddressValidationViewModel?.message == nil,
                "유효한 주소는 에러 메시지가 없어야 함"
            )
        }
        
        @Test("유효하지 않은 주소 표시")
        func testPresentInvalidAddress() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = SendPresenter(viewController: displayLogicSpy)
            
            let response = SendScene.ValidateAddress.Response(
                isValid: false,
                message: "올바른 이더리움 주소 형식이 아닙니다"
            )
            
            // When
            sut.presentAddressValidation(response: response)
            
            // Then
            #expect(displayLogicSpy.displayAddressValidationCalled == true, "Display 메서드가 호출되어야 함")
            #expect(
                displayLogicSpy.displayAddressValidationViewModel?.isValid == false,
                "유효하지 않은 주소로 표시되어야 함"
            )
            #expect(
                displayLogicSpy.displayAddressValidationViewModel?.message == "올바른 이더리움 주소 형식이 아닙니다",
                "적절한 에러 메시지가 표시되어야 함"
            )
        }
    }
    
    // MARK: - Amount Validation Presentation Tests
    
    @Suite("금액 검증 표시")
    struct AmountValidationPresentation {
        
        @Test("유효한 금액 표시")
        func testPresentValidAmount() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = SendPresenter(viewController: displayLogicSpy)
            
            let response = SendScene.ValidateAmount.Response(
                isValid: true,
                message: nil,
                currentBalance: Decimal(2.5)
            )
            
            // When
            sut.presentAmountValidation(response: response)
            
            // Then
            #expect(displayLogicSpy.displayAmountValidationCalled == true, "Display 메서드가 호출되어야 함")
            #expect(
                displayLogicSpy.displayAmountValidationViewModel?.isValid == true,
                "유효한 금액으로 표시되어야 함"
            )
            #expect(
                displayLogicSpy.displayAmountValidationViewModel?.message == nil,
                "유효한 금액은 에러 메시지가 없어야 함"
            )
            #expect(
                displayLogicSpy.displayAmountValidationViewModel?.formattedBalance == "2.5000 ETH",
                "잔액이 올바른 형식으로 표시되어야 함"
            )
        }
        
        @Test("잔액 부족 금액 표시")
        func testPresentInsufficientAmount() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = SendPresenter(viewController: displayLogicSpy)
            
            let response = SendScene.ValidateAmount.Response(
                isValid: false,
                message: "잔액이 부족합니다",
                currentBalance: Decimal(0.5)
            )
            
            // When
            sut.presentAmountValidation(response: response)
            
            // Then
            #expect(
                displayLogicSpy.displayAmountValidationViewModel?.isValid == false,
                "잔액 부족은 유효하지 않은 금액으로 표시되어야 함"
            )
            #expect(
                displayLogicSpy.displayAmountValidationViewModel?.message == "잔액이 부족합니다",
                "잔액 부족 메시지가 표시되어야 함"
            )
            #expect(
                displayLogicSpy.displayAmountValidationViewModel?.formattedBalance == "0.5000 ETH",
                "현재 잔액이 올바른 형식으로 표시되어야 함"
            )
        }
        
        @Test("잘못된 금액 형식 표시")
        func testPresentInvalidAmountFormat() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = SendPresenter(viewController: displayLogicSpy)
            
            let response = SendScene.ValidateAmount.Response(
                isValid: false,
                message: "올바른 숫자 형식이 아닙니다",
                currentBalance: Decimal(1.0)
            )
            
            // When
            sut.presentAmountValidation(response: response)
            
            // Then
            #expect(
                displayLogicSpy.displayAmountValidationViewModel?.message == "올바른 숫자 형식이 아닙니다",
                "형식 오류 메시지가 표시되어야 함"
            )
        }
    }
    
    // MARK: - Gas Estimation Presentation Tests
    
    @Suite("가스비 추정 표시")
    struct GasEstimationPresentation {
        
        @Test("가스비 추정 성공 표시")
        func testPresentGasEstimationSuccess() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = SendPresenter(viewController: displayLogicSpy)
            
            let mockGasOptions = Entity.GasOptions(
                slow: Entity.GasFee(gasPrice: "20000000000", estimatedTime: 300, feeInETH: 0.0005, feeInUSD: 1.0),
                normal: Entity.GasFee(gasPrice: "25000000000", estimatedTime: 180, feeInETH: 0.00063, feeInUSD: 1.25),
                fast: Entity.GasFee(gasPrice: "35000000000", estimatedTime: 60, feeInETH: 0.00088, feeInUSD: 1.75)
            )
            
            let response = SendScene.EstimateGas.Response(
                gasOptions: mockGasOptions,
                error: nil
            )
            
            // When
            sut.presentGasEstimation(response: response)
            
            // Then
            #expect(displayLogicSpy.displayGasEstimationCalled == true, "Display 메서드가 호출되어야 함")
            #expect(
                displayLogicSpy.displayGasEstimationViewModel?.gasOptions != nil,
                "가스비 옵션이 전달되어야 함"
            )
            #expect(
                displayLogicSpy.displayGasEstimationViewModel?.formattedSlowFee == "0.0005 ETH ($1.00)",
                "느림 가스비가 올바른 형식으로 표시되어야 함"
            )
            #expect(
                displayLogicSpy.displayGasEstimationViewModel?.formattedNormalFee == "0.0006 ETH ($1.25)",
                "보통 가스비가 올바른 형식으로 표시되어야 함"
            )
            #expect(
                displayLogicSpy.displayGasEstimationViewModel?.formattedFastFee == "0.0009 ETH ($1.75)",
                "빠름 가스비가 올바른 형식으로 표시되어야 함"
            )
        }
        
        @Test("가스비 추정 실패 표시")
        func testPresentGasEstimationFailure() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = SendPresenter(viewController: displayLogicSpy)
            
            let networkError = NSError(domain: "NetworkError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Network failed"])
            
            let response = SendScene.EstimateGas.Response(
                gasOptions: nil,
                error: networkError
            )
            
            // When
            sut.presentGasEstimation(response: response)
            
            // Then
            #expect(
                displayLogicSpy.displayGasEstimationViewModel?.errorMessage == "가스비를 추정할 수 없습니다. 네트워크 연결을 확인해주세요.",
                "가스비 추정 실패 메시지가 표시되어야 함"
            )
        }
    }
    
    // MARK: - Transaction Result Presentation Tests
    
    @Suite("거래 결과 표시")
    struct TransactionResultPresentation {
        
        @Test("거래 성공 표시")
        func testPresentTransactionSuccess() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = SendPresenter(viewController: displayLogicSpy)
            
            let transactionHash = "0x123abc...def789"
            let response = SendScene.SendTransaction.Response(
                success: true,
                transactionHash: transactionHash,
                error: nil
            )
            
            // When
            sut.presentTransactionResult(response: response)
            
            // Then
            #expect(displayLogicSpy.displayTransactionResultCalled == true, "Display 메서드가 호출되어야 함")
            #expect(
                displayLogicSpy.displayTransactionResultViewModel?.success == true,
                "거래 성공이 표시되어야 함"
            )
            #expect(
                displayLogicSpy.displayTransactionResultViewModel?.transactionHash == transactionHash,
                "거래 해시가 전달되어야 함"
            )
            #expect(
                displayLogicSpy.displayTransactionResultViewModel?.formattedHash == "0x123a...f789",
                "거래 해시가 축약 형식으로 표시되어야 함"
            )
        }
        
        @Test("거래 실패 표시")
        func testPresentTransactionFailure() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = SendPresenter(viewController: displayLogicSpy)
            
            let networkError = NSError(domain: "TransactionError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Transaction failed"])
            let response = SendScene.SendTransaction.Response(
                success: false,
                transactionHash: nil,
                error: networkError
            )
            
            // When
            sut.presentTransactionResult(response: response)
            
            // Then
            #expect(
                displayLogicSpy.displayTransactionResultViewModel?.success == false,
                "거래 실패가 표시되어야 함"
            )
            #expect(
                displayLogicSpy.displayTransactionResultViewModel?.errorMessage == "거래를 처리할 수 없습니다. 다시 시도해주세요.",
                "거래 실패 메시지가 표시되어야 함"
            )
        }
    }
    
    // MARK: - Currency Formatting Tests
    
    @Suite("통화 포맷팅")
    struct CurrencyFormatting {
        
        @Test("ETH 금액 포맷팅")
        func testFormatETHAmount() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = SendPresenter(viewController: displayLogicSpy)
            
            // When & Then - ETH 포맷팅 테스트
            #expect(
                sut.formatETH(Decimal(1.23456789)) == "1.2346 ETH",
                "ETH가 4자리까지 반올림되어 표시되어야 함"
            )
            
            #expect(
                sut.formatETH(Decimal(0.0001)) == "0.0001 ETH",
                "작은 ETH 금액이 올바르게 표시되어야 함"
            )
            
            #expect(
                sut.formatETH(Decimal(1000.5)) == "1000.5000 ETH",
                "큰 ETH 금액이 올바르게 표시되어야 함"
            )
        }
        
        @Test("USD 금액 포맷팅")
        func testFormatUSDAmount() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = SendPresenter(viewController: displayLogicSpy)
            
            // When & Then - USD 포맷팅 테스트
            #expect(
                sut.formatUSD(Decimal(1.23)) == "$1.23",
                "USD가 2자리까지 표시되어야 함"
            )
            
            #expect(
                sut.formatUSD(Decimal(1000.50)) == "$1,000.50",
                "큰 USD 금액에 쉼표가 포함되어야 함"
            )
            
            #expect(
                sut.formatUSD(Decimal(0.01)) == "$0.01",
                "작은 USD 금액이 올바르게 표시되어야 함"
            )
        }
        
        @Test("주소 축약 포맷팅")
        func testFormatAddress() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = SendPresenter(viewController: displayLogicSpy)
            
            let fullAddress = "0x742d35Cc6644C0532925a3b8F0aB4e7E6a7bDdD1"
            
            // When & Then
            #expect(
                sut.formatAddress(fullAddress) == "0x742d...DdD1",
                "주소가 축약 형식으로 표시되어야 함"
            )
        }
        
        @Test("시간 포맷팅")
        func testFormatTime() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = SendPresenter(viewController: displayLogicSpy)
            
            // When & Then
            #expect(
                sut.formatEstimatedTime(60) == "~1분",
                "1분이 올바르게 포맷되어야 함"
            )
            
            #expect(
                sut.formatEstimatedTime(120) == "~2분",
                "2분이 올바르게 포맷되어야 함"
            )
            
            #expect(
                sut.formatEstimatedTime(300) == "~5분",
                "5분이 올바르게 포맷되어야 함"
            )
            
            #expect(
                sut.formatEstimatedTime(3600) == "~60분",
                "1시간이 분으로 표시되어야 함"
            )
        }
    }
    
    // MARK: - Error Message Localization Tests
    
    @Suite("에러 메시지 현지화")
    struct ErrorMessageLocalization {
        
        @Test("네트워크 에러 메시지")
        func testNetworkErrorMessage() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = SendPresenter(viewController: displayLogicSpy)
            
            let networkErrors = [
                NSError(domain: "NSURLErrorDomain", code: -1009, userInfo: nil), // No internet
                NSError(domain: "NetworkError", code: 500, userInfo: nil),       // Server error
                NSError(domain: "RequestError", code: 408, userInfo: nil)        // Timeout
            ]
            
            // When & Then
            for error in networkErrors {
                let message = sut.localizedErrorMessage(error)
                #expect(
                    message.contains("네트워크") || message.contains("연결"),
                    "네트워크 관련 에러 메시지가 포함되어야 함"
                )
            }
        }
        
        @Test("거래 에러 메시지")
        func testTransactionErrorMessage() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = SendPresenter(viewController: displayLogicSpy)
            
            let transactionError = NSError(
                domain: "TransactionError", 
                code: 400, 
                userInfo: [NSLocalizedDescriptionKey: "Insufficient funds"]
            )
            
            // When
            let message = sut.localizedErrorMessage(transactionError)
            
            // Then
            #expect(
                message == "거래를 처리할 수 없습니다. 다시 시도해주세요.",
                "거래 에러 메시지가 현지화되어야 함"
            )
        }
    }
}