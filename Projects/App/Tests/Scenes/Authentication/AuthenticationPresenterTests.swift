import Testing
import Foundation
@testable import App
@testable import Entity
@testable import Core

@MainActor @Suite("AuthenticationPresenter 테스트")
struct AuthenticationPresenterTests {
    
    // MARK: - Spy Classes
    
    class DisplayLogicSpy: AuthenticationDisplayLogic {
        var displayWalletCreationResultCalled = false
        var displayWalletCreationResultViewModel: AuthenticationScene.CreateWallet.ViewModel?
        
        func displayWalletCreationResult(viewModel: AuthenticationScene.CreateWallet.ViewModel) {
            displayWalletCreationResultCalled = true
            displayWalletCreationResultViewModel = viewModel
        }
        
        var displayWalletImportResultCalled = false
        var displayWalletImportResultViewModel: AuthenticationScene.ImportWallet.ViewModel?
        
        func displayWalletImportResult(viewModel: AuthenticationScene.ImportWallet.ViewModel) {
            displayWalletImportResultCalled = true
            displayWalletImportResultViewModel = viewModel
        }
        
        var displayPinSetupResultCalled = false
        var displayPinSetupResultViewModel: AuthenticationScene.SetupPin.ViewModel?
        
        func displayPinSetupResult(viewModel: AuthenticationScene.SetupPin.ViewModel) {
            displayPinSetupResultCalled = true
            displayPinSetupResultViewModel = viewModel
        }
        
        var displayPinValidationResultCalled = false
        var displayPinValidationResultViewModel: AuthenticationScene.ValidatePin.ViewModel?
        
        func displayPinValidationResult(viewModel: AuthenticationScene.ValidatePin.ViewModel) {
            displayPinValidationResultCalled = true
            displayPinValidationResultViewModel = viewModel
        }
        
        var displayBiometricSetupResultCalled = false
        var displayBiometricSetupResultViewModel: AuthenticationScene.SetupBiometric.ViewModel?
        
        func displayBiometricSetupResult(viewModel: AuthenticationScene.SetupBiometric.ViewModel) {
            displayBiometricSetupResultCalled = true
            displayBiometricSetupResultViewModel = viewModel
        }
        
        var displayBiometricAuthResultCalled = false
        var displayBiometricAuthResultViewModel: AuthenticationScene.AuthenticateBiometric.ViewModel?
        
        func displayBiometricAuthResult(viewModel: AuthenticationScene.AuthenticateBiometric.ViewModel) {
            displayBiometricAuthResultCalled = true
            displayBiometricAuthResultViewModel = viewModel
        }
        
        var displayWalletCheckResultCalled = false
        var displayWalletCheckResultViewModel: AuthenticationScene.CheckExistingWallet.ViewModel?
        
        func displayWalletCheckResult(viewModel: AuthenticationScene.CheckExistingWallet.ViewModel) {
            displayWalletCheckResultCalled = true
            displayWalletCheckResultViewModel = viewModel
        }
        
        var displayErrorCalled = false
        var displayErrorViewModel: AuthenticationScene.Error.ViewModel?
        
        func displayError(viewModel: AuthenticationScene.Error.ViewModel) {
            displayErrorCalled = true
            displayErrorViewModel = viewModel
        }
    }
    
    // MARK: - 지갑 생성 결과 표시 테스트
    
    @Suite("지갑 생성 결과")
    struct WalletCreationResult {
        
        @Test("지갑 생성 성공")
        func testPresentWalletCreationSuccess() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = AuthenticationPresenter(viewController: displayLogicSpy)
            
            let wallet = Wallet(
                address: "0x742E9B86e97B1d4E3FBc",
                name: "내 지갑",
                privateKey: "testPrivateKey",
                mnemonic: "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
            )
            
            let response = AuthenticationScene.CreateWallet.Response(
                success: true,
                wallet: wallet,
                error: nil
            )
            
            // When
            sut.presentWalletCreationResult(response: response)
            
            // Then
            #expect(displayLogicSpy.displayWalletCreationResultCalled == true, "지갑 생성 결과 표시가 호출되어야 함")
            
            guard let viewModel = displayLogicSpy.displayWalletCreationResultViewModel else {
                Issue.record("지갑 생성 ViewModel이 생성되어야 함")
                return
            }
            
            #expect(viewModel.success == true, "성공 상태가 표시되어야 함")
            #expect(viewModel.walletAddress == "0x742E9B86e97B1d4E3FBc", "지갑 주소가 표시되어야 함")
            #expect(viewModel.walletName == "내 지갑", "지갑 이름이 표시되어야 함")
            #expect(viewModel.displayAddress == "0x742E...3FBc", "축약된 주소가 표시되어야 함")
            #expect(viewModel.mnemonicWords.count == 12, "니모닉이 12개 단어로 분리되어야 함")
            #expect(viewModel.mnemonicWords.first == "abandon", "첫 번째 니모닉 단어가 일치해야 함")
            #expect(viewModel.mnemonicWords.last == "about", "마지막 니모닉 단어가 일치해야 함")
            #expect(viewModel.showMnemonic == true, "니모닉이 표시되어야 함")
            #expect(viewModel.errorMessage == nil, "에러 메시지가 없어야 함")
            #expect(viewModel.showAlert == false, "알림이 표시되지 않아야 함")
            #expect(viewModel.nextButtonTitle == "계속", "다음 버튼 제목이 설정되어야 함")
            #expect(viewModel.nextButtonEnabled == true, "다음 버튼이 활성화되어야 함")
        }
        
        @Test("지갑 생성 실패 - 니모닉 생성 실패")
        func testPresentWalletCreationMnemonicFailure() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = AuthenticationPresenter(viewController: displayLogicSpy)
            
            let response = AuthenticationScene.CreateWallet.Response(
                success: false,
                wallet: nil,
                error: WalletError.mnemonicGenerationFailed
            )
            
            // When
            sut.presentWalletCreationResult(response: response)
            
            // Then
            guard let viewModel = displayLogicSpy.displayWalletCreationResultViewModel else {
                Issue.record("지갑 생성 ViewModel이 생성되어야 함")
                return
            }
            
            #expect(viewModel.success == false, "실패 상태가 표시되어야 함")
            #expect(viewModel.walletAddress == nil, "지갑 주소가 없어야 함")
            #expect(viewModel.walletName == nil, "지갑 이름이 없어야 함")
            #expect(viewModel.displayAddress == nil, "축약된 주소가 없어야 함")
            #expect(viewModel.mnemonicWords.isEmpty == true, "니모닉 단어가 없어야 함")
            #expect(viewModel.showMnemonic == false, "니모닉이 표시되지 않아야 함")
            #expect(viewModel.errorMessage == "지갑 생성 중 오류가 발생했습니다. 니모닉 생성에 실패했습니다.", "니모닉 생성 실패 메시지가 표시되어야 함")
            #expect(viewModel.showAlert == true, "에러 알림이 표시되어야 함")
            #expect(viewModel.alertTitle == "지갑 생성 실패", "알림 제목이 설정되어야 함")
            #expect(viewModel.nextButtonTitle == "다시 시도", "다시 시도 버튼이 표시되어야 함")
            #expect(viewModel.nextButtonEnabled == true, "버튼이 활성화되어야 함")
        }
        
        @Test("지갑 생성 실패 - 키체인 오류")
        func testPresentWalletCreationKeychainError() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = AuthenticationPresenter(viewController: displayLogicSpy)
            
            let response = AuthenticationScene.CreateWallet.Response(
                success: false,
                wallet: nil,
                error: WalletError.keychainError("Cannot save to keychain")
            )
            
            // When
            sut.presentWalletCreationResult(response: response)
            
            // Then
            guard let viewModel = displayLogicSpy.displayWalletCreationResultViewModel else {
                Issue.record("지갑 생성 ViewModel이 생성되어야 함")
                return
            }
            
            #expect(viewModel.success == false, "실패 상태가 표시되어야 함")
            #expect(viewModel.errorMessage == "지갑을 안전하게 저장할 수 없습니다. 기기 설정을 확인해주세요.", "키체인 오류 메시지가 표시되어야 함")
            #expect(viewModel.showAlert == true, "에러 알림이 표시되어야 함")
            #expect(viewModel.alertTitle == "지갑 생성 실패", "알림 제목이 설정되어야 함")
        }
        
        @Test("지갑 주소 축약 표시")
        func testPresentWalletAddressFormatting() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = AuthenticationPresenter(viewController: displayLogicSpy)
            
            let testCases = [
                ("0x742E9B86e97B1d4E3FBc", "0x742E...3FBc"),
                ("0x1234567890abcdef", "0x1234...cdef"),
                ("0xA", "0xA"),  // 너무 짧은 주소
                ("", ""),  // 빈 주소
                ("invalid", "invalid")  // 잘못된 형식
            ]
            
            for (fullAddress, expectedDisplay) in testCases {
                let wallet = Wallet(
                    address: fullAddress,
                    name: "테스트 지갑",
                    privateKey: "key",
                    mnemonic: "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
                )
                
                let response = AuthenticationScene.CreateWallet.Response(
                    success: true,
                    wallet: wallet,
                    error: nil
                )
                
                // When
                sut.presentWalletCreationResult(response: response)
                
                // Then
                guard let viewModel = displayLogicSpy.displayWalletCreationResultViewModel else {
                    Issue.record("ViewModel이 생성되어야 함")
                    continue
                }
                
                #expect(
                    viewModel.displayAddress == expectedDisplay,
                    "주소 '\(fullAddress)'가 '\(expectedDisplay)'로 축약되어야 함"
                )
            }
        }
    }
    
    // MARK: - 지갑 가져오기 결과 표시 테스트
    
    @Suite("지갑 가져오기 결과")
    struct WalletImportResult {
        
        @Test("지갑 가져오기 성공")
        func testPresentWalletImportSuccess() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = AuthenticationPresenter(viewController: displayLogicSpy)
            
            let wallet = Wallet(
                address: "0xImportedAddress",
                name: "가져온 지갑",
                privateKey: "importedKey",
                mnemonic: "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
            )
            
            let response = AuthenticationScene.ImportWallet.Response(
                success: true,
                wallet: wallet,
                error: nil
            )
            
            // When
            sut.presentWalletImportResult(response: response)
            
            // Then
            #expect(displayLogicSpy.displayWalletImportResultCalled == true, "지갑 가져오기 결과 표시가 호출되어야 함")
            
            guard let viewModel = displayLogicSpy.displayWalletImportResultViewModel else {
                Issue.record("지갑 가져오기 ViewModel이 생성되어야 함")
                return
            }
            
            #expect(viewModel.success == true, "성공 상태가 표시되어야 함")
            #expect(viewModel.walletAddress == "0xImportedAddress", "지갑 주소가 표시되어야 함")
            #expect(viewModel.walletName == "가져온 지갑", "지갑 이름이 표시되어야 함")
            #expect(viewModel.displayAddress == "0xImpo...ress", "축약된 주소가 표시되어야 함")
            #expect(viewModel.successMessage == "지갑을 성공적으로 가져왔습니다!", "성공 메시지가 표시되어야 함")
            #expect(viewModel.errorMessage == nil, "에러 메시지가 없어야 함")
            #expect(viewModel.showAlert == false, "알림이 표시되지 않아야 함")
            #expect(viewModel.nextButtonTitle == "계속", "다음 버튼 제목이 설정되어야 함")
            #expect(viewModel.nextButtonEnabled == true, "다음 버튼이 활성화되어야 함")
        }
        
        @Test("지갑 가져오기 실패 - 잘못된 니모닉")
        func testPresentWalletImportInvalidMnemonic() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = AuthenticationPresenter(viewController: displayLogicSpy)
            
            let response = AuthenticationScene.ImportWallet.Response(
                success: false,
                wallet: nil,
                error: WalletError.invalidMnemonic
            )
            
            // When
            sut.presentWalletImportResult(response: response)
            
            // Then
            guard let viewModel = displayLogicSpy.displayWalletImportResultViewModel else {
                Issue.record("지갑 가져오기 ViewModel이 생성되어야 함")
                return
            }
            
            #expect(viewModel.success == false, "실패 상태가 표시되어야 함")
            #expect(viewModel.walletAddress == nil, "지갑 주소가 없어야 함")
            #expect(viewModel.successMessage == nil, "성공 메시지가 없어야 함")
            #expect(viewModel.errorMessage == "올바르지 않은 니모닉 구문입니다. 12개의 영단어를 정확히 입력해주세요.", "잘못된 니모닉 메시지가 표시되어야 함")
            #expect(viewModel.showAlert == true, "에러 알림이 표시되어야 함")
            #expect(viewModel.alertTitle == "지갑 가져오기 실패", "알림 제목이 설정되어야 함")
            #expect(viewModel.nextButtonTitle == "다시 시도", "다시 시도 버튼이 표시되어야 함")
        }
        
        @Test("지갑 가져오기 실패 - 이미 존재하는 지갑")
        func testPresentWalletImportAlreadyExists() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = AuthenticationPresenter(viewController: displayLogicSpy)
            
            let response = AuthenticationScene.ImportWallet.Response(
                success: false,
                wallet: nil,
                error: WalletError.walletAlreadyExists
            )
            
            // When
            sut.presentWalletImportResult(response: response)
            
            // Then
            guard let viewModel = displayLogicSpy.displayWalletImportResultViewModel else {
                Issue.record("ViewModel이 생성되어야 함")
                return
            }
            
            #expect(viewModel.success == false, "실패 상태가 표시되어야 함")
            #expect(viewModel.errorMessage == "이미 존재하는 지갑입니다. 다른 니모닉 구문을 사용해주세요.", "중복 지갑 메시지가 표시되어야 함")
            #expect(viewModel.showAlert == true, "에러 알림이 표시되어야 함")
        }
    }
    
    // MARK: - PIN 설정 결과 표시 테스트
    
    @Suite("PIN 설정 결과")
    struct PinSetupResult {
        
        @Test("PIN 설정 성공")
        func testPresentPinSetupSuccess() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = AuthenticationPresenter(viewController: displayLogicSpy)
            
            let response = AuthenticationScene.SetupPin.Response(
                success: true,
                error: nil
            )
            
            // When
            sut.presentPinSetupResult(response: response)
            
            // Then
            #expect(displayLogicSpy.displayPinSetupResultCalled == true, "PIN 설정 결과 표시가 호출되어야 함")
            
            guard let viewModel = displayLogicSpy.displayPinSetupResultViewModel else {
                Issue.record("PIN 설정 ViewModel이 생성되어야 함")
                return
            }
            
            #expect(viewModel.success == true, "성공 상태가 표시되어야 함")
            #expect(viewModel.message == "PIN이 성공적으로 설정되었습니다", "성공 메시지가 표시되어야 함")
            #expect(viewModel.showAlert == false, "알림이 표시되지 않아야 함")
            #expect(viewModel.nextButtonTitle == "계속", "다음 버튼 제목이 설정되어야 함")
            #expect(viewModel.nextButtonEnabled == true, "다음 버튼이 활성화되어야 함")
            #expect(viewModel.showPinInput == false, "PIN 입력이 숨겨져야 함")
        }
        
        @Test("PIN 설정 실패 - 키체인 오류")
        func testPresentPinSetupKeychainError() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = AuthenticationPresenter(viewController: displayLogicSpy)
            
            let response = AuthenticationScene.SetupPin.Response(
                success: false,
                error: AuthenticationError.keychainError("Cannot save PIN")
            )
            
            // When
            sut.presentPinSetupResult(response: response)
            
            // Then
            guard let viewModel = displayLogicSpy.displayPinSetupResultViewModel else {
                Issue.record("PIN 설정 ViewModel이 생성되어야 함")
                return
            }
            
            #expect(viewModel.success == false, "실패 상태가 표시되어야 함")
            #expect(viewModel.message == "PIN 설정 중 오류가 발생했습니다. 다시 시도해주세요.", "실패 메시지가 표시되어야 함")
            #expect(viewModel.showAlert == true, "에러 알림이 표시되어야 함")
            #expect(viewModel.alertTitle == "PIN 설정 실패", "알림 제목이 설정되어야 함")
            #expect(viewModel.nextButtonTitle == "다시 시도", "다시 시도 버튼이 표시되어야 함")
            #expect(viewModel.showPinInput == true, "PIN 입력이 다시 표시되어야 함")
        }
        
        @Test("PIN 설정 실패 - 시스템 오류")
        func testPresentPinSetupSystemError() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = AuthenticationPresenter(viewController: displayLogicSpy)
            
            let response = AuthenticationScene.SetupPin.Response(
                success: false,
                error: AuthenticationError.systemError("System unavailable")
            )
            
            // When
            sut.presentPinSetupResult(response: response)
            
            // Then
            guard let viewModel = displayLogicSpy.displayPinSetupResultViewModel else {
                Issue.record("ViewModel이 생성되어야 함")
                return
            }
            
            #expect(viewModel.success == false, "실패 상태가 표시되어야 함")
            #expect(viewModel.message == "시스템 오류가 발생했습니다. 잠시 후 다시 시도해주세요.", "시스템 오류 메시지가 표시되어야 함")
            #expect(viewModel.showAlert == true, "에러 알림이 표시되어야 함")
        }
    }
    
    // MARK: - PIN 검증 결과 표시 테스트
    
    @Suite("PIN 검증 결과")
    struct PinValidationResult {
        
        @Test("PIN 검증 성공")
        func testPresentPinValidationSuccess() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = AuthenticationPresenter(viewController: displayLogicSpy)
            
            let response = AuthenticationScene.ValidatePin.Response(
                isValid: true,
                error: nil
            )
            
            // When
            sut.presentPinValidationResult(response: response)
            
            // Then
            #expect(displayLogicSpy.displayPinValidationResultCalled == true, "PIN 검증 결과 표시가 호출되어야 함")
            
            guard let viewModel = displayLogicSpy.displayPinValidationResultViewModel else {
                Issue.record("PIN 검증 ViewModel이 생성되어야 함")
                return
            }
            
            #expect(viewModel.isValid == true, "유효한 PIN으로 표시되어야 함")
            #expect(viewModel.message == "PIN이 확인되었습니다", "성공 메시지가 표시되어야 함")
            #expect(viewModel.showError == false, "에러가 표시되지 않아야 함")
            #expect(viewModel.clearPin == false, "PIN이 지워지지 않아야 함")
            #expect(viewModel.nextButtonEnabled == true, "다음 버튼이 활성화되어야 함")
            #expect(viewModel.authenticationSuccess == true, "인증 성공 상태가 설정되어야 함")
        }
        
        @Test("PIN 검증 실패 - 틀린 PIN")
        func testPresentPinValidationIncorrect() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = AuthenticationPresenter(viewController: displayLogicSpy)
            
            let response = AuthenticationScene.ValidatePin.Response(
                isValid: false,
                error: nil
            )
            
            // When
            sut.presentPinValidationResult(response: response)
            
            // Then
            guard let viewModel = displayLogicSpy.displayPinValidationResultViewModel else {
                Issue.record("PIN 검증 ViewModel이 생성되어야 함")
                return
            }
            
            #expect(viewModel.isValid == false, "유효하지 않은 PIN으로 표시되어야 함")
            #expect(viewModel.message == "올바르지 않은 PIN입니다", "실패 메시지가 표시되어야 함")
            #expect(viewModel.showError == true, "에러가 표시되어야 함")
            #expect(viewModel.clearPin == true, "PIN이 지워져야 함")
            #expect(viewModel.nextButtonEnabled == false, "다음 버튼이 비활성화되어야 함")
            #expect(viewModel.authenticationSuccess == false, "인증 실패 상태가 설정되어야 함")
            #expect(viewModel.errorColor == "red", "에러 색상이 빨간색이어야 함")
        }
        
        @Test("PIN 검증 오류")
        func testPresentPinValidationError() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = AuthenticationPresenter(viewController: displayLogicSpy)
            
            let response = AuthenticationScene.ValidatePin.Response(
                isValid: false,
                error: AuthenticationError.keychainError("Cannot read PIN")
            )
            
            // When
            sut.presentPinValidationResult(response: response)
            
            // Then
            guard let viewModel = displayLogicSpy.displayPinValidationResultViewModel else {
                Issue.record("ViewModel이 생성되어야 함")
                return
            }
            
            #expect(viewModel.isValid == false, "유효하지 않은 상태로 표시되어야 함")
            #expect(viewModel.message == "PIN 확인 중 오류가 발생했습니다", "오류 메시지가 표시되어야 함")
            #expect(viewModel.showError == true, "에러가 표시되어야 함")
            #expect(viewModel.clearPin == true, "PIN이 지워져야 함")
        }
    }
    
    // MARK: - 생체 인증 설정 결과 표시 테스트
    
    @Suite("생체 인증 설정 결과")
    struct BiometricSetupResult {
        
        @Test("생체 인증 설정 성공")
        func testPresentBiometricSetupSuccess() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = AuthenticationPresenter(viewController: displayLogicSpy)
            
            let response = AuthenticationScene.SetupBiometric.Response(
                success: true,
                error: nil
            )
            
            // When
            sut.presentBiometricSetupResult(response: response)
            
            // Then
            #expect(displayLogicSpy.displayBiometricSetupResultCalled == true, "생체 인증 설정 결과 표시가 호출되어야 함")
            
            guard let viewModel = displayLogicSpy.displayBiometricSetupResultViewModel else {
                Issue.record("생체 인증 설정 ViewModel이 생성되어야 함")
                return
            }
            
            #expect(viewModel.success == true, "성공 상태가 표시되어야 함")
            #expect(viewModel.message == "생체 인증이 성공적으로 설정되었습니다", "성공 메시지가 표시되어야 함")
            #expect(viewModel.biometricIcon == "faceid", "생체 인증 아이콘이 설정되어야 함")
            #expect(viewModel.biometricTitle == "Face ID 설정 완료", "생체 인증 제목이 설정되어야 함")
            #expect(viewModel.showAlert == false, "알림이 표시되지 않아야 함")
            #expect(viewModel.nextButtonTitle == "완료", "완료 버튼이 표시되어야 함")
            #expect(viewModel.nextButtonEnabled == true, "다음 버튼이 활성화되어야 함")
            #expect(viewModel.showBiometricPrompt == false, "생체 인증 프롬프트가 숨겨져야 함")
        }
        
        @Test("생체 인증 설정 실패 - 사용 불가")
        func testPresentBiometricSetupUnavailable() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = AuthenticationPresenter(viewController: displayLogicSpy)
            
            let response = AuthenticationScene.SetupBiometric.Response(
                success: false,
                error: AuthenticationError.biometricUnavailable
            )
            
            // When
            sut.presentBiometricSetupResult(response: response)
            
            // Then
            guard let viewModel = displayLogicSpy.displayBiometricSetupResultViewModel else {
                Issue.record("생체 인증 설정 ViewModel이 생성되어야 함")
                return
            }
            
            #expect(viewModel.success == false, "실패 상태가 표시되어야 함")
            #expect(viewModel.message == "이 기기에서는 생체 인증을 사용할 수 없습니다", "사용 불가 메시지가 표시되어야 함")
            #expect(viewModel.biometricIcon == "exclamationmark.shield", "경고 아이콘이 설정되어야 함")
            #expect(viewModel.biometricTitle == "생체 인증 사용 불가", "사용 불가 제목이 설정되어야 함")
            #expect(viewModel.showAlert == true, "에러 알림이 표시되어야 함")
            #expect(viewModel.alertTitle == "생체 인증 설정 실패", "알림 제목이 설정되어야 함")
            #expect(viewModel.nextButtonTitle == "건너뛰기", "건너뛰기 버튼이 표시되어야 함")
        }
        
        @Test("생체 인증 설정 실패 - 권한 거부")
        func testPresentBiometricSetupPermissionDenied() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = AuthenticationPresenter(viewController: displayLogicSpy)
            
            let response = AuthenticationScene.SetupBiometric.Response(
                success: false,
                error: AuthenticationError.biometricPermissionDenied
            )
            
            // When
            sut.presentBiometricSetupResult(response: response)
            
            // Then
            guard let viewModel = displayLogicSpy.displayBiometricSetupResultViewModel else {
                Issue.record("ViewModel이 생성되어야 함")
                return
            }
            
            #expect(viewModel.success == false, "실패 상태가 표시되어야 함")
            #expect(viewModel.message == "생체 인증 권한이 거부되었습니다. 설정에서 권한을 허용해주세요", "권한 거부 메시지가 표시되어야 함")
            #expect(viewModel.showAlert == true, "에러 알림이 표시되어야 함")
            #expect(viewModel.nextButtonTitle == "설정으로 이동", "설정 이동 버튼이 표시되어야 함")
        }
    }
    
    // MARK: - 생체 인증 결과 표시 테스트
    
    @Suite("생체 인증 결과")
    struct BiometricAuthResult {
        
        @Test("생체 인증 성공")
        func testPresentBiometricAuthSuccess() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = AuthenticationPresenter(viewController: displayLogicSpy)
            
            let response = AuthenticationScene.AuthenticateBiometric.Response(
                success: true,
                error: nil
            )
            
            // When
            sut.presentBiometricAuthResult(response: response)
            
            // Then
            #expect(displayLogicSpy.displayBiometricAuthResultCalled == true, "생체 인증 결과 표시가 호출되어야 함")
            
            guard let viewModel = displayLogicSpy.displayBiometricAuthResultViewModel else {
                Issue.record("생체 인증 ViewModel이 생성되어야 함")
                return
            }
            
            #expect(viewModel.success == true, "인증 성공 상태가 표시되어야 함")
            #expect(viewModel.message == "생체 인증이 완료되었습니다", "성공 메시지가 표시되어야 함")
            #expect(viewModel.biometricIcon == "faceid", "생체 인증 아이콘이 설정되어야 함")
            #expect(viewModel.showError == false, "에러가 표시되지 않아야 함")
            #expect(viewModel.authenticationSuccess == true, "인증 성공 상태가 설정되어야 함")
            #expect(viewModel.showBiometricPrompt == false, "생체 인증 프롬프트가 숨겨져야 함")
        }
        
        @Test("생체 인증 실패")
        func testPresentBiometricAuthFailure() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = AuthenticationPresenter(viewController: displayLogicSpy)
            
            let response = AuthenticationScene.AuthenticateBiometric.Response(
                success: false,
                error: nil
            )
            
            // When
            sut.presentBiometricAuthResult(response: response)
            
            // Then
            guard let viewModel = displayLogicSpy.displayBiometricAuthResultViewModel else {
                Issue.record("생체 인증 ViewModel이 생성되어야 함")
                return
            }
            
            #expect(viewModel.success == false, "인증 실패 상태가 표시되어야 함")
            #expect(viewModel.message == "생체 인증에 실패했습니다", "실패 메시지가 표시되어야 함")
            #expect(viewModel.showError == true, "에러가 표시되어야 함")
            #expect(viewModel.authenticationSuccess == false, "인증 실패 상태가 설정되어야 함")
            #expect(viewModel.showFallbackButton == true, "대체 인증 버튼이 표시되어야 함")
            #expect(viewModel.fallbackButtonTitle == "PIN으로 인증", "대체 인증 버튼 제목이 설정되어야 함")
        }
        
        @Test("생체 인증 오류")
        func testPresentBiometricAuthError() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = AuthenticationPresenter(viewController: displayLogicSpy)
            
            let response = AuthenticationScene.AuthenticateBiometric.Response(
                success: false,
                error: AuthenticationError.systemError("Touch ID not available")
            )
            
            // When
            sut.presentBiometricAuthResult(response: response)
            
            // Then
            guard let viewModel = displayLogicSpy.displayBiometricAuthResultViewModel else {
                Issue.record("ViewModel이 생성되어야 함")
                return
            }
            
            #expect(viewModel.success == false, "인증 실패 상태가 표시되어야 함")
            #expect(viewModel.message == "생체 인증 시스템 오류가 발생했습니다", "시스템 오류 메시지가 표시되어야 함")
            #expect(viewModel.showError == true, "에러가 표시되어야 함")
            #expect(viewModel.showFallbackButton == true, "대체 인증 버튼이 표시되어야 함")
        }
    }
    
    // MARK: - 기존 지갑 확인 결과 표시 테스트
    
    @Suite("기존 지갑 확인 결과")
    struct ExistingWalletCheckResult {
        
        @Test("기존 지갑 존재")
        func testPresentWalletCheckExists() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = AuthenticationPresenter(viewController: displayLogicSpy)
            
            let response = AuthenticationScene.CheckExistingWallet.Response(
                hasExistingWallet: true,
                error: nil
            )
            
            // When
            sut.presentWalletCheckResult(response: response)
            
            // Then
            #expect(displayLogicSpy.displayWalletCheckResultCalled == true, "지갑 확인 결과 표시가 호출되어야 함")
            
            guard let viewModel = displayLogicSpy.displayWalletCheckResultViewModel else {
                Issue.record("지갑 확인 ViewModel이 생성되어야 함")
                return
            }
            
            #expect(viewModel.hasExistingWallet == true, "기존 지갑 존재 상태가 표시되어야 함")
            #expect(viewModel.isSetupMode == false, "설정 모드가 아니어야 함")
            #expect(viewModel.isLoginMode == true, "로그인 모드여야 함")
            #expect(viewModel.title == "환영합니다!", "환영 메시지가 표시되어야 함")
            #expect(viewModel.subtitle == "지갑에 접근하려면 인증이 필요합니다", "부제목이 표시되어야 함")
            #expect(viewModel.primaryButtonTitle == "지갑 열기", "주요 버튼 제목이 설정되어야 함")
            #expect(viewModel.secondaryButtonTitle == "새 지갑 만들기", "보조 버튼 제목이 설정되어야 함")
            #expect(viewModel.showBiometricButton == true, "생체 인증 버튼이 표시되어야 함")
            #expect(viewModel.showError == false, "에러가 표시되지 않아야 함")
        }
        
        @Test("기존 지갑 없음")
        func testPresentWalletCheckNotExists() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = AuthenticationPresenter(viewController: displayLogicSpy)
            
            let response = AuthenticationScene.CheckExistingWallet.Response(
                hasExistingWallet: false,
                error: nil
            )
            
            // When
            sut.presentWalletCheckResult(response: response)
            
            // Then
            guard let viewModel = displayLogicSpy.displayWalletCheckResultViewModel else {
                Issue.record("지갑 확인 ViewModel이 생성되어야 함")
                return
            }
            
            #expect(viewModel.hasExistingWallet == false, "기존 지갑 없음 상태가 표시되어야 함")
            #expect(viewModel.isSetupMode == true, "설정 모드여야 함")
            #expect(viewModel.isLoginMode == false, "로그인 모드가 아니어야 함")
            #expect(viewModel.title == "Kingtherum에 오신 것을 환영합니다", "환영 메시지가 표시되어야 함")
            #expect(viewModel.subtitle == "안전한 암호화폐 지갑을 시작해보세요", "부제목이 표시되어야 함")
            #expect(viewModel.primaryButtonTitle == "새 지갑 만들기", "주요 버튼 제목이 설정되어야 함")
            #expect(viewModel.secondaryButtonTitle == "지갑 가져오기", "보조 버튼 제목이 설정되어야 함")
            #expect(viewModel.showBiometricButton == false, "생체 인증 버튼이 숨겨져야 함")
            #expect(viewModel.showError == false, "에러가 표시되지 않아야 함")
        }
        
        @Test("지갑 확인 오류")
        func testPresentWalletCheckError() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = AuthenticationPresenter(viewController: displayLogicSpy)
            
            let response = AuthenticationScene.CheckExistingWallet.Response(
                hasExistingWallet: false,
                error: AuthenticationError.keychainError("Cannot access keychain")
            )
            
            // When
            sut.presentWalletCheckResult(response: response)
            
            // Then
            guard let viewModel = displayLogicSpy.displayWalletCheckResultViewModel else {
                Issue.record("ViewModel이 생성되어야 함")
                return
            }
            
            #expect(viewModel.hasExistingWallet == false, "에러 시 지갑 없음으로 처리되어야 함")
            #expect(viewModel.showError == true, "에러가 표시되어야 함")
            #expect(viewModel.errorMessage == "지갑 정보를 확인하는 중 오류가 발생했습니다", "에러 메시지가 표시되어야 함")
            #expect(viewModel.primaryButtonTitle == "다시 시도", "다시 시도 버튼이 표시되어야 함")
        }
    }
    
    // MARK: - 에러 처리 테스트
    
    @Suite("에러 처리")
    struct ErrorHandling {
        
        @Test("일반 에러 표시")
        func testPresentGeneralError() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = AuthenticationPresenter(viewController: displayLogicSpy)
            
            let response = AuthenticationScene.Error.Response(
                error: AuthenticationError.generalError("알 수 없는 오류")
            )
            
            // When
            sut.presentError(response: response)
            
            // Then
            #expect(displayLogicSpy.displayErrorCalled == true, "에러 표시가 호출되어야 함")
            
            guard let viewModel = displayLogicSpy.displayErrorViewModel else {
                Issue.record("에러 ViewModel이 생성되어야 함")
                return
            }
            
            #expect(viewModel.title == "오류", "에러 제목이 설정되어야 함")
            #expect(viewModel.message == "알 수 없는 오류가 발생했습니다. 다시 시도해주세요.", "일반 에러 메시지가 표시되어야 함")
            #expect(viewModel.errorType == "general", "에러 타입이 설정되어야 함")
            #expect(viewModel.primaryButtonTitle == "확인", "확인 버튼이 표시되어야 함")
            #expect(viewModel.secondaryButtonTitle == nil, "보조 버튼이 없어야 함")
            #expect(viewModel.showAlert == true, "알림이 표시되어야 함")
        }
        
        @Test("키체인 에러 표시")
        func testPresentKeychainError() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = AuthenticationPresenter(viewController: displayLogicSpy)
            
            let response = AuthenticationScene.Error.Response(
                error: AuthenticationError.keychainError("Keychain access denied")
            )
            
            // When
            sut.presentError(response: response)
            
            // Then
            guard let viewModel = displayLogicSpy.displayErrorViewModel else {
                Issue.record("에러 ViewModel이 생성되어야 함")
                return
            }
            
            #expect(viewModel.title == "보안 저장소 오류", "키체인 오류 제목이 설정되어야 함")
            #expect(viewModel.message == "보안 정보에 접근할 수 없습니다. 기기를 재시작하거나 설정을 확인해주세요.", "키체인 에러 메시지가 표시되어야 함")
            #expect(viewModel.errorType == "keychain", "키체인 에러 타입이 설정되어야 함")
            #expect(viewModel.primaryButtonTitle == "설정 확인", "설정 확인 버튼이 표시되어야 함")
            #expect(viewModel.secondaryButtonTitle == "다시 시도", "다시 시도 버튼이 표시되어야 함")
        }
        
        @Test("생체 인증 사용 불가 에러 표시")
        func testPresentBiometricUnavailableError() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = AuthenticationPresenter(viewController: displayLogicSpy)
            
            let response = AuthenticationScene.Error.Response(
                error: AuthenticationError.biometricUnavailable
            )
            
            // When
            sut.presentError(response: response)
            
            // Then
            guard let viewModel = displayLogicSpy.displayErrorViewModel else {
                Issue.record("ViewModel이 생성되어야 함")
                return
            }
            
            #expect(viewModel.title == "생체 인증 사용 불가", "생체 인증 사용 불가 제목이 설정되어야 함")
            #expect(viewModel.message == "이 기기에서는 생체 인증을 사용할 수 없습니다. PIN으로 인증해주세요.", "생체 인증 사용 불가 메시지가 표시되어야 함")
            #expect(viewModel.errorType == "biometric", "생체 인증 에러 타입이 설정되어야 함")
            #expect(viewModel.primaryButtonTitle == "PIN으로 인증", "PIN 인증 버튼이 표시되어야 함")
        }
        
        @Test("시스템 에러 표시")
        func testPresentSystemError() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = AuthenticationPresenter(viewController: displayLogicSpy)
            
            let response = AuthenticationScene.Error.Response(
                error: AuthenticationError.systemError("System service unavailable")
            )
            
            // When
            sut.presentError(response: response)
            
            // Then
            guard let viewModel = displayLogicSpy.displayErrorViewModel else {
                Issue.record("ViewModel이 생성되어야 함")
                return
            }
            
            #expect(viewModel.title == "시스템 오류", "시스템 오류 제목이 설정되어야 함")
            #expect(viewModel.message == "시스템 오류가 발생했습니다. 잠시 후 다시 시도해주세요.", "시스템 에러 메시지가 표시되어야 함")
            #expect(viewModel.errorType == "system", "시스템 에러 타입이 설정되어야 함")
        }
    }
}