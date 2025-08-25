import Testing
import Foundation
@testable import Kingthereum
@testable import Entity
@testable import Core
@testable import WalletKit

@Suite("AuthenticationInteractor 테스트")
struct AuthenticationInteractorTests {
    
    // MARK: - Spy Classes
    
    @MainActor
    class PresentationLogicSpy: AuthenticationPresentationLogic {
        var presentWalletCreationResultCalled = false
        var presentWalletCreationResultResponse: AuthenticationScene.CreateWallet.Response?
        
        func presentWalletCreationResult(response: AuthenticationScene.CreateWallet.Response) {
            presentWalletCreationResultCalled = true
            presentWalletCreationResultResponse = response
        }
        
        var presentWalletImportResultCalled = false
        var presentWalletImportResultResponse: AuthenticationScene.ImportWallet.Response?
        
        func presentWalletImportResult(response: AuthenticationScene.ImportWallet.Response) {
            presentWalletImportResultCalled = true
            presentWalletImportResultResponse = response
        }
        
        var presentPinSetupResultCalled = false
        var presentPinSetupResultResponse: AuthenticationScene.SetupPin.Response?
        
        func presentPinSetupResult(response: AuthenticationScene.SetupPin.Response) {
            presentPinSetupResultCalled = true
            presentPinSetupResultResponse = response
        }
        
        var presentPinValidationResultCalled = false
        var presentPinValidationResultResponse: AuthenticationScene.ValidatePin.Response?
        
        func presentPinValidationResult(response: AuthenticationScene.ValidatePin.Response) {
            presentPinValidationResultCalled = true
            presentPinValidationResultResponse = response
        }
        
        var presentBiometricSetupResultCalled = false
        var presentBiometricSetupResultResponse: AuthenticationScene.SetupBiometric.Response?
        
        func presentBiometricSetupResult(response: AuthenticationScene.SetupBiometric.Response) {
            presentBiometricSetupResultCalled = true
            presentBiometricSetupResultResponse = response
        }
        
        var presentBiometricAuthResultCalled = false
        var presentBiometricAuthResultResponse: AuthenticationScene.AuthenticateBiometric.Response?
        
        func presentBiometricAuthResult(response: AuthenticationScene.AuthenticateBiometric.Response) {
            presentBiometricAuthResultCalled = true
            presentBiometricAuthResultResponse = response
        }
        
        var presentWalletCheckResultCalled = false
        var presentWalletCheckResultResponse: AuthenticationScene.CheckExistingWallet.Response?
        
        func presentWalletCheckResult(response: AuthenticationScene.CheckExistingWallet.Response) {
            presentWalletCheckResultCalled = true
            presentWalletCheckResultResponse = response
        }
        
        var presentErrorCalled = false
        var presentErrorResponse: AuthenticationScene.Error.Response?
        
        func presentError(response: AuthenticationScene.Error.Response) {
            presentErrorCalled = true
            presentErrorResponse = response
        }
    }
    
    class WorkerSpy: AuthenticationWorkerProtocol {
        var createWalletCalled = false
        var createWalletName: String?
        var createWalletResult: Result<Wallet, WalletError> = .success(
            Wallet(address: "0x123", name: "Test Wallet", privateKey: "testKey", mnemonic: "test mnemonic")
        )
        
        func createWallet(name: String) async -> Result<Wallet, WalletError> {
            createWalletCalled = true
            createWalletName = name
            return createWalletResult
        }
        
        var importWalletCalled = false
        var importWalletMnemonic: String?
        var importWalletName: String?
        var importWalletResult: Result<Wallet, WalletError> = .success(
            Wallet(address: "0x456", name: "Imported Wallet", privateKey: "importedKey", mnemonic: "imported mnemonic")
        )
        
        func importWallet(mnemonic: String, name: String) async -> Result<Wallet, WalletError> {
            importWalletCalled = true
            importWalletMnemonic = mnemonic
            importWalletName = name
            return importWalletResult
        }
        
        var setupPinCalled = false
        var setupPinValue: String?
        var setupPinResult: Result<Void, AuthenticationError> = .success(())
        
        func setupPin(_ pin: String) async -> Result<Void, AuthenticationError> {
            setupPinCalled = true
            setupPinValue = pin
            return setupPinResult
        }
        
        var validatePinCalled = false
        var validatePinValue: String?
        var validatePinResult: Result<Bool, AuthenticationError> = .success(true)
        
        func validatePin(_ pin: String) async -> Result<Bool, AuthenticationError> {
            validatePinCalled = true
            validatePinValue = pin
            return validatePinResult
        }
        
        var setupBiometricCalled = false
        var setupBiometricResult: Result<Void, AuthenticationError> = .success(())
        
        func setupBiometric() async -> Result<Void, AuthenticationError> {
            setupBiometricCalled = true
            return setupBiometricResult
        }
        
        var authenticateWithBiometricCalled = false
        var authenticateWithBiometricResult: Result<Bool, AuthenticationError> = .success(true)
        
        func authenticateWithBiometric() async -> Result<Bool, AuthenticationError> {
            authenticateWithBiometricCalled = true
            return authenticateWithBiometricResult
        }
        
        var checkExistingWalletCalled = false
        var checkExistingWalletResult: Result<Bool, AuthenticationError> = .success(false)
        
        func checkExistingWallet() async -> Result<Bool, AuthenticationError> {
            checkExistingWalletCalled = true
            return checkExistingWalletResult
        }
    }
    
    // MARK: - 지갑 생성 테스트
    
    @Suite("지갑 생성")
    struct CreateWallet {
        
        @Test("지갑 생성 성공")
        func testCreateWalletSuccess() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let expectedWallet = Wallet(
                address: "0xNewWallet",
                name: "내 지갑",
                privateKey: "newPrivateKey",
                mnemonic: "word1 word2 word3 word4 word5 word6 word7 word8 word9 word10 word11 word12"
            )
            workerSpy.createWalletResult = .success(expectedWallet)
            
            let sut = AuthenticationInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            let request = AuthenticationScene.CreateWallet.Request(walletName: "내 지갑")
            
            // When
            await sut.createWallet(request: request)
            
            // Then
            #expect(workerSpy.createWalletCalled == true, "Worker의 지갑 생성이 호출되어야 함")
            #expect(workerSpy.createWalletName == "내 지갑", "지갑 이름이 올바르게 전달되어야 함")
            #expect(await presenterSpy.presentWalletCreationResultCalled == true, "Presenter가 호출되어야 함")
            
            let response = await presenterSpy.presentWalletCreationResultResponse
            #expect(response?.success == true, "성공 응답이 반환되어야 함")
            #expect(response?.wallet?.address == "0xNewWallet", "지갑 주소가 일치해야 함")
            #expect(response?.wallet?.name == "내 지갑", "지갑 이름이 일치해야 함")
            #expect(response?.error == nil, "에러가 없어야 함")
        }
        
        @Test("지갑 생성 실패 - 니모닉 생성 오류")
        func testCreateWalletMnemonicError() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let mnemonicError = WalletError.mnemonicGenerationFailed
            workerSpy.createWalletResult = .failure(mnemonicError)
            
            let sut = AuthenticationInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            let request = AuthenticationScene.CreateWallet.Request(walletName: "실패할 지갑")
            
            // When
            await sut.createWallet(request: request)
            
            // Then
            #expect(workerSpy.createWalletCalled == true, "Worker가 호출되어야 함")
            #expect(await presenterSpy.presentWalletCreationResultCalled == true, "Presenter가 호출되어야 함")
            
            let response = await presenterSpy.presentWalletCreationResultResponse
            #expect(response?.success == false, "실패 응답이 반환되어야 함")
            #expect(response?.wallet == nil, "지갑이 생성되지 않아야 함")
            #expect(response?.error != nil, "에러가 있어야 함")
        }
        
        @Test("지갑 생성 실패 - 빈 지갑 이름")
        func testCreateWalletEmptyName() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let sut = AuthenticationInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            let request = AuthenticationScene.CreateWallet.Request(walletName: "")
            
            // When
            await sut.createWallet(request: request)
            
            // Then
            #expect(workerSpy.createWalletCalled == false, "빈 이름으로는 Worker가 호출되지 않아야 함")
            #expect(await presenterSpy.presentErrorCalled == true, "에러 Presenter가 호출되어야 함")
            
            let errorResponse = await presenterSpy.presentErrorResponse
            #expect(errorResponse?.error != nil, "유효성 검증 에러가 있어야 함")
        }
    }
    
    // MARK: - 지갑 가져오기 테스트
    
    @Suite("지갑 가져오기")
    struct ImportWallet {
        
        @Test("지갑 가져오기 성공")
        func testImportWalletSuccess() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let expectedWallet = Wallet(
                address: "0xImportedWallet",
                name: "가져온 지갑",
                privateKey: "importedPrivateKey",
                mnemonic: "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
            )
            workerSpy.importWalletResult = .success(expectedWallet)
            
            let sut = AuthenticationInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            let request = AuthenticationScene.ImportWallet.Request(
                mnemonic: "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about",
                walletName: "가져온 지갑"
            )
            
            // When
            await sut.importWallet(request: request)
            
            // Then
            #expect(workerSpy.importWalletCalled == true, "Worker의 지갑 가져오기가 호출되어야 함")
            #expect(workerSpy.importWalletName == "가져온 지갑", "지갑 이름이 올바르게 전달되어야 함")
            #expect(workerSpy.importWalletMnemonic?.hasPrefix("abandon") == true, "니모닉이 올바르게 전달되어야 함")
            #expect(await presenterSpy.presentWalletImportResultCalled == true, "Presenter가 호출되어야 함")
            
            let response = await presenterSpy.presentWalletImportResultResponse
            #expect(response?.success == true, "성공 응답이 반환되어야 함")
            #expect(response?.wallet?.address == "0xImportedWallet", "지갑 주소가 일치해야 함")
            #expect(response?.error == nil, "에러가 없어야 함")
        }
        
        @Test("지갑 가져오기 실패 - 잘못된 니모닉")
        func testImportWalletInvalidMnemonic() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let invalidMnemonicError = WalletError.invalidMnemonic
            workerSpy.importWalletResult = .failure(invalidMnemonicError)
            
            let sut = AuthenticationInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            let request = AuthenticationScene.ImportWallet.Request(
                mnemonic: "invalid mnemonic phrase",
                walletName: "테스트 지갑"
            )
            
            // When
            await sut.importWallet(request: request)
            
            // Then
            #expect(workerSpy.importWalletCalled == true, "Worker가 호출되어야 함")
            #expect(await presenterSpy.presentWalletImportResultCalled == true, "Presenter가 호출되어야 함")
            
            let response = await presenterSpy.presentWalletImportResultResponse
            #expect(response?.success == false, "실패 응답이 반환되어야 함")
            #expect(response?.wallet == nil, "지갑이 생성되지 않아야 함")
            #expect(response?.error != nil, "에러가 있어야 함")
        }
        
        @Test("지갑 가져오기 - 니모닉 유효성 검증")
        func testImportWalletMnemonicValidation() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let sut = AuthenticationInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            // When & Then - 빈 니모닉
            let emptyRequest = AuthenticationScene.ImportWallet.Request(
                mnemonic: "",
                walletName: "테스트"
            )
            await sut.importWallet(request: emptyRequest)
            #expect(workerSpy.importWalletCalled == false, "빈 니모닉으로는 Worker가 호출되지 않아야 함")
            #expect(await presenterSpy.presentErrorCalled == true, "에러가 표시되어야 함")
            
            // Reset spy state
            await MainActor.run {
                presenterSpy.presentErrorCalled = false
            }
            
            // When & Then - 11개 단어 (12개 미만)
            let shortRequest = AuthenticationScene.ImportWallet.Request(
                mnemonic: "word1 word2 word3 word4 word5 word6 word7 word8 word9 word10 word11",
                walletName: "테스트"
            )
            await sut.importWallet(request: shortRequest)
            #expect(workerSpy.importWalletCalled == false, "부족한 단어로는 Worker가 호출되지 않아야 함")
            #expect(await presenterSpy.presentErrorCalled == true, "에러가 표시되어야 함")
        }
    }
    
    // MARK: - PIN 설정 테스트
    
    @Suite("PIN 설정")
    struct SetupPin {
        
        @Test("PIN 설정 성공")
        func testSetupPinSuccess() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            workerSpy.setupPinResult = .success(())
            
            let sut = AuthenticationInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            let request = AuthenticationScene.SetupPin.Request(pin: "123456")
            
            // When
            await sut.setupPin(request: request)
            
            // Then
            #expect(workerSpy.setupPinCalled == true, "Worker의 PIN 설정이 호출되어야 함")
            #expect(workerSpy.setupPinValue == "123456", "PIN이 올바르게 전달되어야 함")
            #expect(await presenterSpy.presentPinSetupResultCalled == true, "Presenter가 호출되어야 함")
            
            let response = await presenterSpy.presentPinSetupResultResponse
            #expect(response?.success == true, "성공 응답이 반환되어야 함")
            #expect(response?.error == nil, "에러가 없어야 함")
        }
        
        @Test("PIN 설정 실패 - 키체인 오류")
        func testSetupPinKeychainError() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let keychainError = AuthenticationError.keychainError("Keychain access denied")
            workerSpy.setupPinResult = .failure(keychainError)
            
            let sut = AuthenticationInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            let request = AuthenticationScene.SetupPin.Request(pin: "123456")
            
            // When
            await sut.setupPin(request: request)
            
            // Then
            #expect(workerSpy.setupPinCalled == true, "Worker가 호출되어야 함")
            #expect(await presenterSpy.presentPinSetupResultCalled == true, "Presenter가 호출되어야 함")
            
            let response = await presenterSpy.presentPinSetupResultResponse
            #expect(response?.success == false, "실패 응답이 반환되어야 함")
            #expect(response?.error != nil, "에러가 있어야 함")
        }
        
        @Test("PIN 유효성 검증")
        func testSetupPinValidation() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let sut = AuthenticationInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            let testCases = [
                ("", false),        // 빈 PIN
                ("123", false),     // 너무 짧음
                ("12345", false),   // 5자리
                ("123456", true),   // 정상 6자리
                ("1234567", false), // 7자리 (너무 김)
                ("abcdef", false),  // 숫자가 아님
                ("12345a", false)   // 숫자 + 문자
            ]
            
            for (pin, shouldCallWorker) in testCases {
                // Reset spy state
                workerSpy.setupPinCalled = false
                await MainActor.run {
                    presenterSpy.presentErrorCalled = false
                    presenterSpy.presentPinSetupResultCalled = false
                }
                
                let request = AuthenticationScene.SetupPin.Request(pin: pin)
                
                // When
                await sut.setupPin(request: request)
                
                // Then
                if shouldCallWorker {
                    #expect(workerSpy.setupPinCalled == true, "PIN '\(pin)'은 유효해야 함")
                    #expect(await presenterSpy.presentPinSetupResultCalled == true, "PIN 설정 결과가 표시되어야 함")
                } else {
                    #expect(workerSpy.setupPinCalled == false, "PIN '\(pin)'은 유효하지 않아 Worker가 호출되지 않아야 함")
                    #expect(await presenterSpy.presentErrorCalled == true, "유효성 검증 에러가 표시되어야 함")
                }
            }
        }
    }
    
    // MARK: - PIN 검증 테스트
    
    @Suite("PIN 검증")
    struct ValidatePin {
        
        @Test("PIN 검증 성공")
        func testValidatePinSuccess() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            workerSpy.validatePinResult = .success(true)
            
            let sut = AuthenticationInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            let request = AuthenticationScene.ValidatePin.Request(pin: "123456")
            
            // When
            await sut.validatePin(request: request)
            
            // Then
            #expect(workerSpy.validatePinCalled == true, "Worker의 PIN 검증이 호출되어야 함")
            #expect(workerSpy.validatePinValue == "123456", "PIN이 올바르게 전달되어야 함")
            #expect(await presenterSpy.presentPinValidationResultCalled == true, "Presenter가 호출되어야 함")
            
            let response = await presenterSpy.presentPinValidationResultResponse
            #expect(response?.isValid == true, "PIN이 유효해야 함")
            #expect(response?.error == nil, "에러가 없어야 함")
        }
        
        @Test("PIN 검증 실패 - 잘못된 PIN")
        func testValidatePinIncorrect() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            workerSpy.validatePinResult = .success(false)
            
            let sut = AuthenticationInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            let request = AuthenticationScene.ValidatePin.Request(pin: "000000")
            
            // When
            await sut.validatePin(request: request)
            
            // Then
            #expect(workerSpy.validatePinCalled == true, "Worker가 호출되어야 함")
            #expect(await presenterSpy.presentPinValidationResultCalled == true, "Presenter가 호출되어야 함")
            
            let response = await presenterSpy.presentPinValidationResultResponse
            #expect(response?.isValid == false, "PIN이 유효하지 않아야 함")
            #expect(response?.error == nil, "검증 실패는 에러가 아님")
        }
        
        @Test("PIN 검증 오류")
        func testValidatePinError() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let keychainError = AuthenticationError.keychainError("Cannot read from keychain")
            workerSpy.validatePinResult = .failure(keychainError)
            
            let sut = AuthenticationInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            let request = AuthenticationScene.ValidatePin.Request(pin: "123456")
            
            // When
            await sut.validatePin(request: request)
            
            // Then
            #expect(workerSpy.validatePinCalled == true, "Worker가 호출되어야 함")
            #expect(await presenterSpy.presentPinValidationResultCalled == true, "Presenter가 호출되어야 함")
            
            let response = await presenterSpy.presentPinValidationResultResponse
            #expect(response?.isValid == false, "PIN 검증이 실패해야 함")
            #expect(response?.error != nil, "에러가 있어야 함")
        }
    }
    
    // MARK: - 생체 인증 설정 테스트
    
    @Suite("생체 인증 설정")
    struct SetupBiometric {
        
        @Test("생체 인증 설정 성공")
        func testSetupBiometricSuccess() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            workerSpy.setupBiometricResult = .success(())
            
            let sut = AuthenticationInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            let request = AuthenticationScene.SetupBiometric.Request()
            
            // When
            await sut.setupBiometric(request: request)
            
            // Then
            #expect(workerSpy.setupBiometricCalled == true, "Worker의 생체 인증 설정이 호출되어야 함")
            #expect(await presenterSpy.presentBiometricSetupResultCalled == true, "Presenter가 호출되어야 함")
            
            let response = await presenterSpy.presentBiometricSetupResultResponse
            #expect(response?.success == true, "성공 응답이 반환되어야 함")
            #expect(response?.error == nil, "에러가 없어야 함")
        }
        
        @Test("생체 인증 설정 실패 - 사용 불가")
        func testSetupBiometricUnavailable() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let unavailableError = AuthenticationError.biometricUnavailable
            workerSpy.setupBiometricResult = .failure(unavailableError)
            
            let sut = AuthenticationInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            let request = AuthenticationScene.SetupBiometric.Request()
            
            // When
            await sut.setupBiometric(request: request)
            
            // Then
            #expect(workerSpy.setupBiometricCalled == true, "Worker가 호출되어야 함")
            #expect(await presenterSpy.presentBiometricSetupResultCalled == true, "Presenter가 호출되어야 함")
            
            let response = await presenterSpy.presentBiometricSetupResultResponse
            #expect(response?.success == false, "실패 응답이 반환되어야 함")
            #expect(response?.error != nil, "에러가 있어야 함")
        }
        
        @Test("생체 인증 설정 실패 - 권한 거부")
        func testSetupBiometricPermissionDenied() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let permissionError = AuthenticationError.biometricPermissionDenied
            workerSpy.setupBiometricResult = .failure(permissionError)
            
            let sut = AuthenticationInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            let request = AuthenticationScene.SetupBiometric.Request()
            
            // When
            await sut.setupBiometric(request: request)
            
            // Then
            let response = await presenterSpy.presentBiometricSetupResultResponse
            #expect(response?.success == false, "실패 응답이 반환되어야 함")
            #expect(response?.error != nil, "권한 거부 에러가 있어야 함")
        }
    }
    
    // MARK: - 생체 인증 테스트
    
    @Suite("생체 인증")
    struct AuthenticateBiometric {
        
        @Test("생체 인증 성공")
        func testAuthenticateBiometricSuccess() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            workerSpy.authenticateWithBiometricResult = .success(true)
            
            let sut = AuthenticationInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            let request = AuthenticationScene.AuthenticateBiometric.Request()
            
            // When
            await sut.authenticateBiometric(request: request)
            
            // Then
            #expect(workerSpy.authenticateWithBiometricCalled == true, "Worker의 생체 인증이 호출되어야 함")
            #expect(await presenterSpy.presentBiometricAuthResultCalled == true, "Presenter가 호출되어야 함")
            
            let response = await presenterSpy.presentBiometricAuthResultResponse
            #expect(response?.success == true, "인증 성공 응답이 반환되어야 함")
            #expect(response?.error == nil, "에러가 없어야 함")
        }
        
        @Test("생체 인증 실패 - 인증 거부")
        func testAuthenticateBiometricDenied() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            workerSpy.authenticateWithBiometricResult = .success(false)
            
            let sut = AuthenticationInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            let request = AuthenticationScene.AuthenticateBiometric.Request()
            
            // When
            await sut.authenticateBiometric(request: request)
            
            // Then
            let response = await presenterSpy.presentBiometricAuthResultResponse
            #expect(response?.success == false, "인증 실패 응답이 반환되어야 함")
            #expect(response?.error == nil, "인증 실패는 에러가 아님")
        }
        
        @Test("생체 인증 오류")
        func testAuthenticateBiometricError() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let systemError = AuthenticationError.systemError("Touch ID not available")
            workerSpy.authenticateWithBiometricResult = .failure(systemError)
            
            let sut = AuthenticationInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            let request = AuthenticationScene.AuthenticateBiometric.Request()
            
            // When
            await sut.authenticateBiometric(request: request)
            
            // Then
            let response = await presenterSpy.presentBiometricAuthResultResponse
            #expect(response?.success == false, "인증 실패 응답이 반환되어야 함")
            #expect(response?.error != nil, "시스템 에러가 있어야 함")
        }
    }
    
    // MARK: - 기존 지갑 확인 테스트
    
    @Suite("기존 지갑 확인")
    struct CheckExistingWallet {
        
        @Test("기존 지갑 존재함")
        func testCheckExistingWalletExists() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            workerSpy.checkExistingWalletResult = .success(true)
            
            let sut = AuthenticationInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            let request = AuthenticationScene.CheckExistingWallet.Request()
            
            // When
            await sut.checkExistingWallet(request: request)
            
            // Then
            #expect(workerSpy.checkExistingWalletCalled == true, "Worker의 지갑 확인이 호출되어야 함")
            #expect(await presenterSpy.presentWalletCheckResultCalled == true, "Presenter가 호출되어야 함")
            
            let response = await presenterSpy.presentWalletCheckResultResponse
            #expect(response?.hasExistingWallet == true, "기존 지갑이 존재해야 함")
            #expect(response?.error == nil, "에러가 없어야 함")
        }
        
        @Test("기존 지갑 없음")
        func testCheckExistingWalletNotExists() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            workerSpy.checkExistingWalletResult = .success(false)
            
            let sut = AuthenticationInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            let request = AuthenticationScene.CheckExistingWallet.Request()
            
            // When
            await sut.checkExistingWallet(request: request)
            
            // Then
            let response = await presenterSpy.presentWalletCheckResultResponse
            #expect(response?.hasExistingWallet == false, "기존 지갑이 없어야 함")
            #expect(response?.error == nil, "에러가 없어야 함")
        }
        
        @Test("지갑 확인 오류")
        func testCheckExistingWalletError() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let keychainError = AuthenticationError.keychainError("Cannot access keychain")
            workerSpy.checkExistingWalletResult = .failure(keychainError)
            
            let sut = AuthenticationInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            let request = AuthenticationScene.CheckExistingWallet.Request()
            
            // When
            await sut.checkExistingWallet(request: request)
            
            // Then
            let response = await presenterSpy.presentWalletCheckResultResponse
            #expect(response?.hasExistingWallet == false, "에러 시 지갑 없음으로 처리되어야 함")
            #expect(response?.error != nil, "에러가 있어야 함")
        }
    }
    
    // MARK: - 통합 테스트
    
    @Suite("Interactor 통합 테스트")
    struct Integration {
        
        @Test("완전한 지갑 생성 플로우")
        func testCompleteWalletCreationFlow() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            // 모든 작업이 성공하도록 설정
            workerSpy.checkExistingWalletResult = .success(false)
            workerSpy.createWalletResult = .success(
                Wallet(address: "0xComplete", name: "완전한 지갑", privateKey: "key", mnemonic: "mnemonic")
            )
            workerSpy.setupPinResult = .success(())
            workerSpy.setupBiometricResult = .success(())
            
            let sut = AuthenticationInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            // When & Then - 1단계: 기존 지갑 확인
            let checkRequest = AuthenticationScene.CheckExistingWallet.Request()
            await sut.checkExistingWallet(request: checkRequest)
            
            let checkResponse = await presenterSpy.presentWalletCheckResultResponse
            #expect(checkResponse?.hasExistingWallet == false, "기존 지갑이 없어야 함")
            
            // When & Then - 2단계: 지갑 생성
            let createRequest = AuthenticationScene.CreateWallet.Request(walletName: "완전한 지갑")
            await sut.createWallet(request: createRequest)
            
            let createResponse = await presenterSpy.presentWalletCreationResultResponse
            #expect(createResponse?.success == true, "지갑 생성이 성공해야 함")
            
            // When & Then - 3단계: PIN 설정
            let pinRequest = AuthenticationScene.SetupPin.Request(pin: "123456")
            await sut.setupPin(request: pinRequest)
            
            let pinResponse = await presenterSpy.presentPinSetupResultResponse
            #expect(pinResponse?.success == true, "PIN 설정이 성공해야 함")
            
            // When & Then - 4단계: 생체 인증 설정
            let biometricRequest = AuthenticationScene.SetupBiometric.Request()
            await sut.setupBiometric(request: biometricRequest)
            
            let biometricResponse = await presenterSpy.presentBiometricSetupResultResponse
            #expect(biometricResponse?.success == true, "생체 인증 설정이 성공해야 함")
            
            // 모든 Worker 메서드가 호출되었는지 확인
            #expect(workerSpy.checkExistingWalletCalled == true, "지갑 확인이 호출되어야 함")
            #expect(workerSpy.createWalletCalled == true, "지갑 생성이 호출되어야 함")
            #expect(workerSpy.setupPinCalled == true, "PIN 설정이 호출되어야 함")
            #expect(workerSpy.setupBiometricCalled == true, "생체 인증 설정이 호출되어야 함")
        }
        
        @Test("완전한 로그인 플로우")
        func testCompleteLoginFlow() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            // 기존 지갑이 있고 모든 인증이 성공하도록 설정
            workerSpy.checkExistingWalletResult = .success(true)
            workerSpy.authenticateWithBiometricResult = .success(true)
            workerSpy.validatePinResult = .success(true)
            
            let sut = AuthenticationInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            // When & Then - 1단계: 기존 지갑 확인
            let checkRequest = AuthenticationScene.CheckExistingWallet.Request()
            await sut.checkExistingWallet(request: checkRequest)
            
            let checkResponse = await presenterSpy.presentWalletCheckResultResponse
            #expect(checkResponse?.hasExistingWallet == true, "기존 지갑이 있어야 함")
            
            // When & Then - 2단계: 생체 인증
            let biometricRequest = AuthenticationScene.AuthenticateBiometric.Request()
            await sut.authenticateBiometric(request: biometricRequest)
            
            let biometricResponse = await presenterSpy.presentBiometricAuthResultResponse
            #expect(biometricResponse?.success == true, "생체 인증이 성공해야 함")
            
            // When & Then - 3단계: PIN 검증 (백업)
            let pinRequest = AuthenticationScene.ValidatePin.Request(pin: "123456")
            await sut.validatePin(request: pinRequest)
            
            let pinResponse = await presenterSpy.presentPinValidationResultResponse
            #expect(pinResponse?.isValid == true, "PIN 검증이 성공해야 함")
            
            // 모든 Worker 메서드가 호출되었는지 확인
            #expect(workerSpy.checkExistingWalletCalled == true, "지갑 확인이 호출되어야 함")
            #expect(workerSpy.authenticateWithBiometricCalled == true, "생체 인증이 호출되어야 함")
            #expect(workerSpy.validatePinCalled == true, "PIN 검증이 호출되어야 함")
        }
    }
}