import Foundation
import Entity
import UIKit
import Factory
import WalletKit

@MainActor
protocol ReceiveBusinessLogic {
    func loadWalletAddress(request: ReceiveScene.LoadWalletAddress.Request) async
    func copyAddress(request: ReceiveScene.CopyAddress.Request)
    func shareAddress(request: ReceiveScene.ShareAddress.Request)
    func generateQRCode(request: ReceiveScene.GenerateQRCode.Request)
}

@MainActor
protocol ReceiveDataStore {
    var walletAddress: String? { get set }
}

@MainActor
final class ReceiveInteractor: ReceiveBusinessLogic, ReceiveDataStore {
    var presenter: ReceivePresentationLogic?
    var worker: ReceiveWorker?
    
    @Injected(\.walletService) private var walletService: WalletServiceProtocol
    
    // MARK: - Data Store
    var walletAddress: String?
    
    // MARK: - Business Logic
    
    func loadWalletAddress(request: ReceiveScene.LoadWalletAddress.Request) async {
        let worker: ReceiveWorker
        if let existingWorker = self.worker {
            worker = existingWorker
        } else {
            worker = ReceiveWorker()
        }
        
        let address = await worker.getWalletAddress()
        let formattedAddress = await worker.formatAddress(address)
        
        // 데이터 스토어에 저장
        self.walletAddress = address
        
        let response = ReceiveScene.LoadWalletAddress.Response(
            walletAddress: address,
            formattedAddress: formattedAddress
        )
        
        presenter?.presentWalletAddress(response: response)
    }
    
    func copyAddress(request: ReceiveScene.CopyAddress.Request) {
        // 클립보드에 주소 복사
        UIPasteboard.general.string = request.address
        
        let response = ReceiveScene.CopyAddress.Response(success: true)
        presenter?.presentCopyResult(response: response)
    }
    
    func shareAddress(request: ReceiveScene.ShareAddress.Request) {
        let shareText = "내 이더리움 지갑 주소:"
        let shareItems: [Any] = [shareText, request.address]
        
        let response = ReceiveScene.ShareAddress.Response(shareItems: shareItems)
        presenter?.presentShareSheet(response: response)
    }
    
    func generateQRCode(request: ReceiveScene.GenerateQRCode.Request) {
        let worker: ReceiveWorker
        if let existingWorker = self.worker {
            worker = existingWorker
        } else {
            worker = ReceiveWorker()
        }
        
        let qrCodeData = worker.generateQRCode(from: request.address)
        
        let response = ReceiveScene.GenerateQRCode.Response(
            qrCodeData: qrCodeData,
            isRefresh: true // 수동 새로고침
        )
        
        presenter?.presentQRCode(response: response)
    }
}
