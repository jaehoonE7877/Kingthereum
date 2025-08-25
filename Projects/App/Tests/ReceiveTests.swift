import Testing
import CoreImage
import Foundation
@testable import Kingthereum

@Suite("Receive Interactor Tests")
struct ReceiveTests {
    
    // MARK: - Test Fixtures
    
    private func makeTestDependencies() -> (interactor: ReceiveInteractor, presenter: MockReceivePresenter, worker: MockReceiveWorker) {
        let interactor = ReceiveInteractor()
        let presenter = MockReceivePresenter()
        let worker = MockReceiveWorker()
        
        interactor.presenter = presenter
        interactor.worker = worker
        
        return (interactor, presenter, worker)
    }
    
    // MARK: - Load Wallet Address Tests
    
    @Test("Should get address from worker")
    func loadWalletAddress() {
        // Given
        let (interactor, presenter, worker) = makeTestDependencies()
        let expectedAddress = "0x742B15EcB8E3F6F7e7D58C4f9Ad2dBcEF8A5E9C3"
        worker.mockWalletAddress = expectedAddress
        
        // When
        interactor.loadWalletAddress(request: Receive.LoadWalletAddress.Request())
        
        // Then
        #expect(worker.getWalletAddressCalled)
        #expect(interactor.walletAddress == expectedAddress)
        #expect(presenter.presentWalletAddressCalled)
        #expect(presenter.lastWalletAddressResponse?.walletAddress == expectedAddress)
    }
    
    @Test("Should format address correctly")
    func formatWalletAddress() {
        // Given
        let (interactor, presenter, worker) = makeTestDependencies()
        let fullAddress = "0x742B15EcB8E3F6F7e7D58C4f9Ad2dBcEF8A5E9C3"
        let expectedFormattedAddress = "0x742B...E9C3"
        worker.mockWalletAddress = fullAddress
        worker.mockFormattedAddress = expectedFormattedAddress
        
        // When
        interactor.loadWalletAddress(request: Receive.LoadWalletAddress.Request())
        
        // Then
        #expect(worker.formatAddressCalled)
        #expect(presenter.lastWalletAddressResponse?.formattedAddress == expectedFormattedAddress)
    }
    
    // MARK: - Copy Address Tests
    
    @Test("Should copy address to clipboard")
    func copyAddress() {
        // Given
        let (interactor, presenter, _) = makeTestDependencies()
        let testAddress = "0x742B15EcB8E3F6F7e7D58C4f9Ad2dBcEF8A5E9C3"
        let request = Receive.CopyAddress.Request(address: testAddress)
        
        // When
        interactor.copyAddress(request: request)
        
        // Then
        #expect(presenter.presentCopyResultCalled)
        #expect(presenter.lastCopyResponse?.success == true)
        
        // Verify clipboard content (this requires UIKit testing)
        #if canImport(UIKit)
        #expect(UIPasteboard.general.string == testAddress)
        #endif
    }
    
    // MARK: - Share Address Tests
    
    @Test("Should create share items")
    func shareAddress() {
        // Given
        let (interactor, presenter, _) = makeTestDependencies()
        let testAddress = "0x742B15EcB8E3F6F7e7D58C4f9Ad2dBcEF8A5E9C3"
        let request = Receive.ShareAddress.Request(address: testAddress)
        
        // When
        interactor.shareAddress(request: request)
        
        // Then
        #expect(presenter.presentShareSheetCalled)
        let shareItems = presenter.lastShareResponse?.shareItems
        #expect(shareItems != nil)
        #expect(shareItems?.count == 2)
        
        // Verify share content contains address
        let shareContent = shareItems?.first as? String
        #expect(shareContent?.contains(testAddress) == true)
        #expect(shareContent?.contains("내 이더리움 지갑 주소") == true)
    }
    
    // MARK: - Generate QR Code Tests
    
    @Test("Should call worker and presenter for QR code generation")
    func generateQRCode() {
        // Given
        let (interactor, presenter, worker) = makeTestDependencies()
        let testAddress = "0x742B15EcB8E3F6F7e7D58C4f9Ad2dBcEF8A5E9C3"
        let mockQRData = "test qr data".data(using: .utf8)
        worker.mockQRCodeData = mockQRData
        let request = Receive.GenerateQRCode.Request(address: testAddress)
        
        // When
        interactor.generateQRCode(request: request)
        
        // Then
        #expect(worker.generateQRCodeCalled)
        #expect(worker.lastQRAddress == testAddress)
        #expect(presenter.presentQRCodeCalled)
        #expect(presenter.lastQRResponse?.qrCodeData == mockQRData)
    }
}

// MARK: - Mock Classes

final class MockReceivePresenter: ReceivePresentationLogic, @unchecked Sendable {
    var presentWalletAddressCalled = false
    var presentCopyResultCalled = false
    var presentShareSheetCalled = false
    var presentQRCodeCalled = false
    
    var lastWalletAddressResponse: Receive.LoadWalletAddress.Response?
    var lastCopyResponse: Receive.CopyAddress.Response?
    var lastShareResponse: Receive.ShareAddress.Response?
    var lastQRResponse: Receive.GenerateQRCode.Response?
    
    func presentWalletAddress(response: Receive.LoadWalletAddress.Response) {
        presentWalletAddressCalled = true
        lastWalletAddressResponse = response
    }
    
    func presentCopyResult(response: Receive.CopyAddress.Response) {
        presentCopyResultCalled = true
        lastCopyResponse = response
    }
    
    func presentShareSheet(response: Receive.ShareAddress.Response) {
        presentShareSheetCalled = true
        lastShareResponse = response
    }
    
    func presentQRCode(response: Receive.GenerateQRCode.Response) {
        presentQRCodeCalled = true
        lastQRResponse = response
    }
}

final class MockReceiveWorker: ReceiveWorkerProtocol, @unchecked Sendable {
    var getWalletAddressCalled = false
    var formatAddressCalled = false
    var generateQRCodeCalled = false
    
    var mockWalletAddress = "0x742B15EcB8E3F6F7e7D58C4f9Ad2dBcEF8A5E9C3"
    var mockFormattedAddress = "0x742B...E9C3"
    var mockQRCodeData: Data?
    var lastQRAddress: String?
    
    func getWalletAddress() -> String {
        getWalletAddressCalled = true
        return mockWalletAddress
    }
    
    func formatAddress(_ address: String) -> String {
        formatAddressCalled = true
        return mockFormattedAddress
    }
    
    func isValidEthereumAddress(_ address: String) -> Bool {
        return address.hasPrefix("0x") && address.count == 42
    }
    
    func generateQRCode(from address: String) -> Data? {
        generateQRCodeCalled = true
        lastQRAddress = address
        return mockQRCodeData
    }
}

// MARK: - Receive Worker Tests

@Suite("Receive Worker Tests")
struct ReceiveWorkerTests {
    
    // MARK: - Test Fixtures
    
    private func makeWorker() -> ReceiveWorker {
        return ReceiveWorker()
    }
    
    // MARK: - Address Formatting Tests
    
    @Test("Should return original for short address")
    func formatShortAddress() {
        // Given
        let worker = makeWorker()
        let shortAddress = "0x123"
        
        // When
        let formattedAddress = worker.formatAddress(shortAddress)
        
        // Then
        #expect(formattedAddress == shortAddress)
    }
    
    // MARK: - Address Validation Tests
    
    @Test("Should validate correct Ethereum address")
    func validateCorrectAddress() {
        // Given
        let worker = makeWorker()
        let validAddress = "0x742B15EcB8E3F6F7e7D58C4f9Ad2dBcEF8A5E9C3"
        
        // When
        let isValid = worker.isValidEthereumAddress(validAddress)
        
        // Then
        #expect(isValid)
    }
    
    @Test("Should reject invalid addresses", arguments: [
        "742B15EcB8E3F6F7e7D58C4f9Ad2dBcEF8A5E9C3", // No 0x prefix
        "0x742B15EcB8E3F6F7e7D58C4f9Ad2dBcEF8A5E9C", // Too short
        "0x742B15EcB8E3F6F7e7D58C4f9Ad2dBcEF8A5E9C32", // Too long
        "0xZZZB15EcB8E3F6F7e7D58C4f9Ad2dBcEF8A5E9C3", // Invalid hex
        ""
    ])
    func validateInvalidAddress(invalidAddress: String) {
        // Given
        let worker = makeWorker()
        
        // When
        let isValid = worker.isValidEthereumAddress(invalidAddress)
        
        // Then
        #expect(isValid == false, "Address should be invalid: \(invalidAddress)")
    }
    
    // MARK: - QR Code Generation Tests
    
    @Test("Should return data for valid address")
    func generateQRCodeForValidAddress() {
        // Given
        let worker = makeWorker()
        let validAddress = "0x742B15EcB8E3F6F7e7D58C4f9Ad2dBcEF8A5E9C3"
        
        // When
        let qrData = worker.generateQRCode(from: validAddress)
        
        // Then
        #expect(qrData != nil)
        #expect((qrData?.count ?? 0) > 0)
    }
    
    @Test("Should return nil for empty string")
    func generateQRCodeForEmptyString() {
        // Given
        let worker = makeWorker()
        let emptyAddress = ""
        
        // When
        let qrData = worker.generateQRCode(from: emptyAddress)
        
        // Then
        #expect(qrData == nil)
    }
}
