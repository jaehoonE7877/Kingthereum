import Foundation
import Entity
import WalletKit
import Factory

@MainActor
protocol ReceivePresentationLogic {
    func presentWalletAddress(response: ReceiveScene.LoadWalletAddress.Response)
    func presentCopyResult(response: ReceiveScene.CopyAddress.Response)
    func presentShareSheet(response: ReceiveScene.ShareAddress.Response)
    func presentQRCode(response: ReceiveScene.GenerateQRCode.Response)
}

@MainActor
final class ReceivePresenter: ReceivePresentationLogic {
    @Injected(\.walletService) private var walletService
    
    // MARK: - Presentation Logic
    
    func presentWalletAddress(response: ReceiveScene.LoadWalletAddress.Response) {
        let displayModel = ReceiveScene.LoadWalletAddress.ViewModel(
            walletAddress: response.walletAddress,
            formattedAddress: response.formattedAddress,
            qrCodeData: nil // QR 코드는 별도 요청으로 생성
        )
        
        viewController?.displayWalletAddress(viewModel: displayModel)
        
        // 지갑 주소 로드 후 자동으로 QR 코드 생성 요청
        presentQRCode(response: ReceiveScene.GenerateQRCode.Response(
            qrCodeData: generateQRCodeData(from: response.walletAddress),
            isRefresh: false // 초기 로드
        ))
    }
    
    func presentCopyResult(response: ReceiveScene.CopyAddress.Response) {
        let displayModel = ReceiveScene.CopyAddress.ViewModel(
            showCopyAlert: response.success
        )
        
        viewController?.displayCopyResult(viewModel: displayModel)
    }
    
    func presentShareSheet(response: ReceiveScene.ShareAddress.Response) {
        let displayModel = ReceiveScene.ShareAddress.ViewModel(
            shareItems: response.shareItems,
            showShareSheet: true
        )
        
        viewController?.displayShareSheet(viewModel: displayModel)
    }
    
    func presentQRCode(response: ReceiveScene.GenerateQRCode.Response) {        
        // 실제 QR 코드 생성 (새로고침 시마다 새로 생성됨)
        let qrCodeData = response.qrCodeData ?? generateQRCodeData(from: getCurrentWalletAddress())
        
        let displayModel = ReceiveScene.GenerateQRCode.ViewModel(
            qrCodeData: qrCodeData,
            isRefresh: response.isRefresh,
            showSuccessAnimation: response.isRefresh && qrCodeData != nil
        )
        
        viewController?.displayQRCode(viewModel: displayModel)
    }
    
    private func getCurrentWalletAddress() -> String {
        let worker = ReceiveWorker(walletService: walletService)
        return worker.getWalletAddress()
    }
    
    // MARK: - Private Helpers
    
    private func generateQRCodeData(from address: String) -> Data? {
        let worker = ReceiveWorker(walletService: walletService)
        return worker.generateQRCode(from: address)
    }
}
