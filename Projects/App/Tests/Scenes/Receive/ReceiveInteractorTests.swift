import Testing
import Foundation
@testable import Scenes
@testable import Entity
@testable import WalletKit

// MARK: - ReceiveInteractor 테스트

@MainActor @Suite("ReceiveInteractor 테스트")
struct ReceiveInteractorTests {
    
    // MARK: - Spy Classes
    
    class PresentationLogicSpy: ReceivePresentationLogic {
        var presentWalletAddressCalled = false
        var presentWalletAddressResponse: ReceiveScene.LoadWalletAddress.Response?
        
        func presentWalletAddress(response: ReceiveScene.LoadWalletAddress.Response) {
            presentWalletAddressCalled = true
            presentWalletAddressResponse = response
        }
        
        var presentQRCodeCalled = false
        var presentQRCodeResponse: ReceiveScene.GenerateQRCode.Response?
        
        func presentQRCode(response: ReceiveScene.GenerateQRCode.Response) {
            presentQRCodeCalled = true
            presentQRCodeResponse = response
        }
        
        var presentSecurityValidationCalled = false
        var presentSecurityValidationResponse: ReceiveScene.ValidateSecurity.Response?
        
        func presentSecurityValidation(response: ReceiveScene.ValidateSecurity.Response) {
            presentSecurityValidationCalled = true
            presentSecurityValidationResponse = response
        }
        
        var presentAddressCopyCalled = false
        var presentAddressCopyResponse: ReceiveScene.CopyAddress.Response?
        
        func presentAddressCopy(response: ReceiveScene.CopyAddress.Response) {
            presentAddressCopyCalled = true
            presentAddressCopyResponse = response
        }
    }
    
    class WorkerSpy: ReceiveWorkerProtocol {
        var getCurrentWalletAddressCalled = false
        var getCurrentWalletAddressResult: String?
        
        func getCurrentWalletAddress() -> String? {
            getCurrentWalletAddressCalled = true
            return getCurrentWalletAddressResult
        }
        
        var generateQRCodeCalled = false
        var generateQRCodeResult: Data?
        var generateQRCodeAddress: String?
        
        func generateQRCode(for address: String) -> Data? {
            generateQRCodeCalled = true
            generateQRCodeAddress = address
            return generateQRCodeResult
        }
        
        var validateSecurityCalled = false
        var validateSecurityResult: ReceiveSecurityValidationResult = .valid
        
        func validateSecurity() -> ReceiveSecurityValidationResult {
            validateSecurityCalled = true
            return validateSecurityResult
        }
        
        var copyAddressToPasteboardCalled = false
        var copyAddressToPasteboardAddress: String?
        
        func copyAddressToPasteboard(_ address: String) {
            copyAddressToPasteboardCalled = true
            copyAddressToPasteboardAddress = address
        }
    }
    
    // MARK: - Wallet Address Loading Tests
    
    @Suite("지갑 주소 로딩")
    struct WalletAddressLoading {
        
        @Test("지갑 주소 로딩 성공")
        func testLoadWalletAddressSuccess() {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let expectedAddress = "0x742d35Cc6644C0532925a3b8F0aB4e7E6a7bDdD1"
            workerSpy.getCurrentWalletAddressResult = expectedAddress
            
            let sut = ReceiveInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            let request = ReceiveScene.LoadWalletAddress.Request()
            
            // When
            sut.loadWalletAddress(request: request)
            
            // Then
            #expect(workerSpy.getCurrentWalletAddressCalled == true, "Worker의 주소 조회가 호출되어야 함")
            #expect(presenterSpy.presentWalletAddressCalled == true, "Presenter가 호출되어야 함")
            #expect(
                presenterSpy.presentWalletAddressResponse?.address == expectedAddress,
                "올바른 주소가 Presenter로 전달되어야 함"
            )
            #expect(
                presenterSpy.presentWalletAddressResponse?.success == true,
                "주소 로딩 성공이 전달되어야 함"
            )
        }
        
        @Test("지갑 주소 로딩 실패 - 주소 없음")
        func testLoadWalletAddressFailure() {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            workerSpy.getCurrentWalletAddressResult = nil
            
            let sut = ReceiveInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            let request = ReceiveScene.LoadWalletAddress.Request()
            
            // When
            sut.loadWalletAddress(request: request)
            
            // Then
            #expect(workerSpy.getCurrentWalletAddressCalled == true, "Worker의 주소 조회가 호출되어야 함")
            #expect(presenterSpy.presentWalletAddressCalled == true, "Presenter가 호출되어야 함")
            #expect(
                presenterSpy.presentWalletAddressResponse?.success == false,
                "주소 로딩 실패가 전달되어야 함"
            )
            #expect(
                presenterSpy.presentWalletAddressResponse?.error != nil,
                "에러가 전달되어야 함"
            )
        }
        
        @Test("지갑 주소 로딩 실패 - 빈 주소")
        func testLoadWalletAddressEmptyAddress() {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            workerSpy.getCurrentWalletAddressResult = ""
            
            let sut = ReceiveInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            let request = ReceiveScene.LoadWalletAddress.Request()
            
            // When
            sut.loadWalletAddress(request: request)
            
            // Then
            #expect(
                presenterSpy.presentWalletAddressResponse?.success == false,
                "빈 주소는 실패로 처리되어야 함"
            )
        }
    }
    
    // MARK: - QR Code Generation Tests
    
    @Suite("QR 코드 생성")
    struct QRCodeGeneration {
        
        @Test("QR 코드 생성 성공")
        func testGenerateQRCodeSuccess() {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let testAddress = "0x742d35Cc6644C0532925a3b8F0aB4e7E6a7bDdD1"
            let mockQRData = "mock-qr-data".data(using: .utf8)!
            workerSpy.generateQRCodeResult = mockQRData
            
            let sut = ReceiveInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            let request = ReceiveScene.GenerateQRCode.Request(address: testAddress)
            
            // When
            sut.generateQRCode(request: request)
            
            // Then
            #expect(workerSpy.generateQRCodeCalled == true, "Worker의 QR 코드 생성이 호출되어야 함")
            #expect(
                workerSpy.generateQRCodeAddress == testAddress,
                "올바른 주소로 QR 코드가 생성되어야 함"
            )
            #expect(presenterSpy.presentQRCodeCalled == true, "Presenter가 호출되어야 함")
            #expect(
                presenterSpy.presentQRCodeResponse?.success == true,
                "QR 코드 생성 성공이 전달되어야 함"
            )
            #expect(
                presenterSpy.presentQRCodeResponse?.qrCodeData == mockQRData,
                "QR 코드 데이터가 전달되어야 함"
            )
        }
        
        @Test("QR 코드 생성 실패")
        func testGenerateQRCodeFailure() {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let testAddress = "invalid-address"
            workerSpy.generateQRCodeResult = nil
            
            let sut = ReceiveInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            let request = ReceiveScene.GenerateQRCode.Request(address: testAddress)
            
            // When
            sut.generateQRCode(request: request)
            
            // Then
            #expect(workerSpy.generateQRCodeCalled == true, "Worker가 호출되어야 함")
            #expect(presenterSpy.presentQRCodeCalled == true, "Presenter가 호출되어야 함")
            #expect(
                presenterSpy.presentQRCodeResponse?.success == false,
                "QR 코드 생성 실패가 전달되어야 함"
            )
            #expect(
                presenterSpy.presentQRCodeResponse?.error != nil,
                "에러가 전달되어야 함"
            )
        }
        
        @Test("빈 주소로 QR 코드 생성 시도")
        func testGenerateQRCodeEmptyAddress() {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let sut = ReceiveInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            let request = ReceiveScene.GenerateQRCode.Request(address: "")
            
            // When
            sut.generateQRCode(request: request)
            
            // Then
            #expect(workerSpy.generateQRCodeCalled == false, "빈 주소는 Worker를 호출하지 않아야 함")
            #expect(presenterSpy.presentQRCodeCalled == true, "Presenter가 호출되어야 함")
            #expect(
                presenterSpy.presentQRCodeResponse?.success == false,
                "빈 주소는 실패로 처리되어야 함"
            )
        }
    }
    
    // MARK: - Security Validation Tests
    
    @Suite("보안 검증")
    struct SecurityValidation {
        
        @Test("보안 검증 성공")
        func testValidateSecuritySuccess() {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            workerSpy.validateSecurityResult = .valid
            
            let sut = ReceiveInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            let request = ReceiveScene.ValidateSecurity.Request()
            
            // When
            sut.validateSecurity(request: request)
            
            // Then
            #expect(workerSpy.validateSecurityCalled == true, "Worker의 보안 검증이 호출되어야 함")
            #expect(presenterSpy.presentSecurityValidationCalled == true, "Presenter가 호출되어야 함")
            #expect(
                presenterSpy.presentSecurityValidationResponse?.isSecure == true,
                "보안 검증 성공이 전달되어야 함"
            )
        }
        
        @Test("보안 검증 실패 - 루팅 탐지")
        func testValidateSecurityRootDetected() {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            workerSpy.validateSecurityResult = .rootDetected
            
            let sut = ReceiveInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            let request = ReceiveScene.ValidateSecurity.Request()
            
            // When
            sut.validateSecurity(request: request)
            
            // Then
            #expect(presenterSpy.presentSecurityValidationCalled == true, "Presenter가 호출되어야 함")
            #expect(
                presenterSpy.presentSecurityValidationResponse?.isSecure == false,
                "보안 검증 실패가 전달되어야 함"
            )
            #expect(
                presenterSpy.presentSecurityValidationResponse?.riskLevel == .high,
                "높은 위험도가 전달되어야 함"
            )
            #expect(
                presenterSpy.presentSecurityValidationResponse?.warnings?.contains(.rootDetected) == true,
                "루팅 탐지 경고가 포함되어야 함"
            )
        }
        
        @Test("보안 검증 실패 - 디버깅 탐지")
        func testValidateSecurityDebuggingDetected() {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            workerSpy.validateSecurityResult = .debuggingDetected
            
            let sut = ReceiveInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            let request = ReceiveScene.ValidateSecurity.Request()
            
            // When
            sut.validateSecurity(request: request)
            
            // Then
            #expect(
                presenterSpy.presentSecurityValidationResponse?.isSecure == false,
                "보안 검증 실패가 전달되어야 함"
            )
            #expect(
                presenterSpy.presentSecurityValidationResponse?.warnings?.contains(.debuggingDetected) == true,
                "디버깅 탐지 경고가 포함되어야 함"
            )
        }
        
        @Test("보안 검증 - 여러 위험 요소")
        func testValidateSecurityMultipleThreats() {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            workerSpy.validateSecurityResult = .multipleThreatsDetected([.rootDetected, .debuggingDetected])
            
            let sut = ReceiveInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            let request = ReceiveScene.ValidateSecurity.Request()
            
            // When
            sut.validateSecurity(request: request)
            
            // Then
            #expect(
                presenterSpy.presentSecurityValidationResponse?.isSecure == false,
                "보안 검증 실패가 전달되어야 함"
            )
            #expect(
                presenterSpy.presentSecurityValidationResponse?.riskLevel == .critical,
                "위험 수준이 매우 높음으로 전달되어야 함"
            )
            #expect(
                presenterSpy.presentSecurityValidationResponse?.warnings?.count == 2,
                "2개의 경고가 전달되어야 함"
            )
        }
    }
    
    // MARK: - Address Copy Tests
    
    @Suite("주소 복사")
    struct AddressCopy {
        
        @Test("주소 복사 성공")
        func testCopyAddressSuccess() {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let testAddress = "0x742d35Cc6644C0532925a3b8F0aB4e7E6a7bDdD1"
            
            let sut = ReceiveInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            let request = ReceiveScene.CopyAddress.Request(address: testAddress)
            
            // When
            sut.copyAddress(request: request)
            
            // Then
            #expect(workerSpy.copyAddressToPasteboardCalled == true, "Worker의 클립보드 복사가 호출되어야 함")
            #expect(
                workerSpy.copyAddressToPasteboardAddress == testAddress,
                "올바른 주소가 클립보드에 복사되어야 함"
            )
            #expect(presenterSpy.presentAddressCopyCalled == true, "Presenter가 호출되어야 함")
            #expect(
                presenterSpy.presentAddressCopyResponse?.success == true,
                "복사 성공이 전달되어야 함"
            )
        }
        
        @Test("빈 주소 복사 시도")
        func testCopyEmptyAddress() {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let sut = ReceiveInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            let request = ReceiveScene.CopyAddress.Request(address: "")
            
            // When
            sut.copyAddress(request: request)
            
            // Then
            #expect(workerSpy.copyAddressToPasteboardCalled == false, "빈 주소는 복사하지 않아야 함")
            #expect(presenterSpy.presentAddressCopyCalled == true, "Presenter가 호출되어야 함")
            #expect(
                presenterSpy.presentAddressCopyResponse?.success == false,
                "빈 주소 복사는 실패로 처리되어야 함"
            )
        }
    }
    
    // MARK: - Data Store Tests
    
    @Suite("데이터 저장소")
    struct DataStore {
        
        @Test("데이터 저장소 초기화")
        func testDataStoreInitialization() {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let sut = ReceiveInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            // When & Then
            #expect(sut.walletAddress == nil, "초기 지갑 주소는 nil이어야 함")
            #expect(sut.qrCodeData == nil, "초기 QR 코드 데이터는 nil이어야 함")
            #expect(sut.securityLevel == .unknown, "초기 보안 수준은 unknown이어야 함")
        }
        
        @Test("데이터 저장소 상태 업데이트")
        func testDataStoreStateUpdate() {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let testAddress = "0x742d35Cc6644C0532925a3b8F0aB4e7E6a7bDdD1"
            let testQRData = "test-qr-data".data(using: .utf8)!
            
            workerSpy.getCurrentWalletAddressResult = testAddress
            workerSpy.generateQRCodeResult = testQRData
            workerSpy.validateSecurityResult = .valid
            
            let sut = ReceiveInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            // When
            sut.loadWalletAddress(request: ReceiveScene.LoadWalletAddress.Request())
            sut.generateQRCode(request: ReceiveScene.GenerateQRCode.Request(address: testAddress))
            sut.validateSecurity(request: ReceiveScene.ValidateSecurity.Request())
            
            // Then
            #expect(sut.walletAddress == testAddress, "지갑 주소가 업데이트되어야 함")
            #expect(sut.qrCodeData == testQRData, "QR 코드 데이터가 업데이트되어야 함")
            #expect(sut.securityLevel == .secure, "보안 수준이 업데이트되어야 함")
        }
    }
    
    // MARK: - Integration Tests
    
    @Suite("통합 테스트")
    struct IntegrationTests {
        
        @Test("전체 Receive 플로우")
        func testCompleteReceiveFlow() {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let testAddress = "0x742d35Cc6644C0532925a3b8F0aB4e7E6a7bDdD1"
            let testQRData = "test-qr-data".data(using: .utf8)!
            
            workerSpy.getCurrentWalletAddressResult = testAddress
            workerSpy.generateQRCodeResult = testQRData
            workerSpy.validateSecurityResult = .valid
            
            let sut = ReceiveInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            // When & Then
            // 1. 보안 검증
            sut.validateSecurity(request: ReceiveScene.ValidateSecurity.Request())
            #expect(
                presenterSpy.presentSecurityValidationResponse?.isSecure == true,
                "보안 검증이 성공해야 함"
            )
            
            // 2. 지갑 주소 로딩
            sut.loadWalletAddress(request: ReceiveScene.LoadWalletAddress.Request())
            #expect(
                presenterSpy.presentWalletAddressResponse?.success == true,
                "주소 로딩이 성공해야 함"
            )
            
            // 3. QR 코드 생성
            sut.generateQRCode(request: ReceiveScene.GenerateQRCode.Request(address: testAddress))
            #expect(
                presenterSpy.presentQRCodeResponse?.success == true,
                "QR 코드 생성이 성공해야 함"
            )
            
            // 4. 주소 복사
            sut.copyAddress(request: ReceiveScene.CopyAddress.Request(address: testAddress))
            #expect(
                presenterSpy.presentAddressCopyResponse?.success == true,
                "주소 복사가 성공해야 함"
            )
            
            // 5. 데이터 저장소 상태 확인
            #expect(sut.walletAddress == testAddress, "지갑 주소가 저장되어야 함")
            #expect(sut.qrCodeData == testQRData, "QR 코드 데이터가 저장되어야 함")
            #expect(sut.securityLevel == .secure, "보안 수준이 저장되어야 함")
        }
        
        @Test("보안 실패 시나리오")
        func testSecurityFailureScenario() {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            workerSpy.validateSecurityResult = .rootDetected
            
            let sut = ReceiveInteractor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            // When
            sut.validateSecurity(request: ReceiveScene.ValidateSecurity.Request())
            
            // Then
            #expect(
                presenterSpy.presentSecurityValidationResponse?.isSecure == false,
                "보안 실패가 전달되어야 함"
            )
            #expect(
                sut.securityLevel == .compromised,
                "보안 수준이 위험으로 설정되어야 함"
            )
        }
    }
}