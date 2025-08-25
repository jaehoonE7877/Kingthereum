import Foundation
import Entity
import CoreImage
import UIKit
import Core
import DesignSystem
import WalletKit

// MARK: - SOLID 원칙 적용: Interface Segregation Principle (ISP)
// 기능별로 인터페이스를 분리하여 의존성을 최소화

/// QR 코드 생성 전용 프로토콜
protocol QRCodeGeneratorProtocol {
    func generateQRCode(from address: String) -> Data?
}

/// 지갑 주소 관리 전용 프로토콜  
protocol WalletAddressProviderProtocol {
    func getWalletAddress() -> String
    func formatAddress(_ address: String) -> String
    func isValidEthereumAddress(_ address: String) -> Bool
}

/// 통합 프로토콜 (기존 호환성 유지)
protocol ReceiveWorkerProtocol: QRCodeGeneratorProtocol, WalletAddressProviderProtocol {}

// MARK: - SOLID 원칙 적용된 ReceiveWorker 구현
final class ReceiveWorker: ReceiveWorkerProtocol {
    
    private let walletService: WalletServiceProtocol
    
    init(walletService: WalletServiceProtocol) {
        self.walletService = walletService
    }
    
    // MARK: - QRCodeGeneratorProtocol 구현
    
    func generateQRCode(from address: String) -> Data? {
        // 주소 유효성 검증
        guard isValidEthereumAddress(address) else {
            return nil
        }
        
        // QR 코드 생성을 직접 구현
        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter?.setValue(address.data(using: .utf8), forKey: "inputMessage")
        filter?.setValue("H", forKey: "inputCorrectionLevel")
        
        guard let ciImage = filter?.outputImage else { return nil }
        
        // 고해상도로 스케일링
        let scaleX = 512 / ciImage.extent.size.width
        let scaleY = 512 / ciImage.extent.size.height
        let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }
        
        let uiImage = UIImage(cgImage: cgImage)
        return uiImage.pngData()
    }
    
    // MARK: - WalletAddressProviderProtocol 구현
    
    func getWalletAddress() -> String {
        // UserDefaults에서 현재 선택된 지갑 주소를 가져옴
        if let address = UserDefaults.standard.string(forKey: Constants.UserDefaults.selectedWalletAddress),
           walletService.isValidEthereumAddress(address) {
            return address
        }
        
        // 백업 옵션: 키체인에서 가져오기 (향후 구현 가능)
        // 또는 WalletManager를 통한 현재 활성 지갑 조회
        
        // 기본값 반환 (개발/테스트용)
        return "0x742B15EcB8E3F6F7e7D58C4f9Ad2dBcEF8A5E9C3"
    }
    
    func formatAddress(_ address: String) -> String {
        // 주소를 0x...abc 형식으로 축약
        guard address.count > 10 else { return address }
        let prefix = String(address.prefix(6))
        let suffix = String(address.suffix(4))
        return "\(prefix)...\(suffix)"
    }
    
    func isValidEthereumAddress(_ address: String) -> Bool {
        return walletService.isValidEthereumAddress(address)
    }
}
