import UIKit
import Foundation

// MARK: - 보안 강화된 수신 기능 관리자

/// 수신 화면 보안 이벤트 프로토콜
@MainActor
protocol ReceiveSecurityDelegate: AnyObject {
    func didDetectScreenshot()
    func didDetectScreenRecording()
    func didDetectAppBackgrounded()
}

/// QR 코드 수신 화면 보안 관리자
final class ReceiveSecurityManager: @unchecked Sendable {
    
    weak var delegate: ReceiveSecurityDelegate?
    
    private var isMonitoringActive = false
    private let notificationCenter = NotificationCenter.default
    
    // MARK: - 보안 모니터링 시작/중지
    
    func startSecurityMonitoring() {
        guard !isMonitoringActive else { return }
        
        isMonitoringActive = true
        setupNotificationObservers()
        
        #if DEBUG
        print("🔒 수신 화면 보안 모니터링 시작")
        #endif
    }
    
    func stopSecurityMonitoring() {
        guard isMonitoringActive else { return }
        
        isMonitoringActive = false
        removeNotificationObservers()
        
        #if DEBUG
        print("🔓 수신 화면 보안 모니터링 종료")
        #endif
    }
    
    // MARK: - Private Methods
    
    private func setupNotificationObservers() {
        // 스크린샷 감지
        notificationCenter.addObserver(
            self,
            selector: #selector(handleScreenshotNotification),
            name: UIApplication.userDidTakeScreenshotNotification,
            object: nil
        )
        
        // 화면 녹화 감지
        notificationCenter.addObserver(
            self,
            selector: #selector(handleScreenRecordingNotification),
            name: UIScreen.capturedDidChangeNotification,
            object: nil
        )
        
        // 앱 백그라운드 감지
        notificationCenter.addObserver(
            self,
            selector: #selector(handleAppBackgroundNotification),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        // 앱 포그라운드 감지
        notificationCenter.addObserver(
            self,
            selector: #selector(handleAppForegroundNotification),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    private func removeNotificationObservers() {
        notificationCenter.removeObserver(self)
    }
    
    // MARK: - Notification Handlers
    
    @objc private func handleScreenshotNotification() {
        #if DEBUG
        print("📸 스크린샷 감지됨")
        #endif
        
        Task { @MainActor in
            delegate?.didDetectScreenshot()
        }
    }
    
    @MainActor
    @objc private func handleScreenRecordingNotification() {
        let isRecording = UIScreen.main.isCaptured
        
        #if DEBUG
        print("🎥 화면 녹화 상태 변경: \(isRecording ? "시작" : "종료")")
        #endif
        
        if isRecording {
            delegate?.didDetectScreenRecording()
        }
    }
    
    @objc private func handleAppBackgroundNotification() {
        #if DEBUG
        print("📱 앱이 백그라운드로 이동")
        #endif
        Task { @MainActor in
            delegate?.didDetectAppBackgrounded()
        }
    }
    
    @objc private func handleAppForegroundNotification() {
        #if DEBUG
        print("📱 앱이 포그라운드로 복귀")
        #endif
    }
    
    deinit {
        stopSecurityMonitoring()
    }
}

// MARK: - QR 코드 보안 유틸리티

final class QRCodeSecurityUtility {
    
    /// QR 코드 이미지에 워터마크 추가
    static func addWatermark(to qrImage: UIImage, watermarkText: String = "Kingthereum") -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: qrImage.size)
        
        return renderer.image { context in
            // 원본 QR 코드 그리기
            qrImage.draw(at: .zero)
            
            // 워터마크 텍스트 설정
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .medium),
                .foregroundColor: UIColor.black.withAlphaComponent(0.1)
            ]
            
            let attributedText = NSAttributedString(string: watermarkText, attributes: attributes)
            let textSize = attributedText.size()
            
            // 워터마크 위치 (우하단)
            let textRect = CGRect(
                x: qrImage.size.width - textSize.width - 10,
                y: qrImage.size.height - textSize.height - 10,
                width: textSize.width,
                height: textSize.height
            )
            
            attributedText.draw(in: textRect)
        }
    }
    
    /// QR 코드 무결성 검증
    static func verifyQRCodeIntegrity(originalAddress: String, qrImage: UIImage) -> Bool {
        // QR 코드 디코딩하여 원본 주소와 비교
        // 실제 구현에서는 CIDetector나 Vision 프레임워크 사용
        
        guard let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]) else {
            return false
        }
        
        guard let ciImage = CIImage(image: qrImage) else {
            return false
        }
        
        let features = detector.features(in: ciImage)
        
        for feature in features {
            if let qrFeature = feature as? CIQRCodeFeature,
               let decodedString = qrFeature.messageString {
                // ethereum: URI 형식 고려
                let cleanAddress = decodedString.replacingOccurrences(of: "ethereum:", with: "")
                return cleanAddress.lowercased() == originalAddress.lowercased()
            }
        }
        
        return false
    }
    
    /// 민감한 정보 마스킹
    static func maskSensitiveInfo(address: String, showLast: Int = 4) -> String {
        guard address.count > showLast + 2 else { return address }
        
        let prefix = address.hasPrefix("0x") ? "0x" : ""
        let start = prefix.count
        let maskLength = address.count - start - showLast
        
        let visiblePart = String(address.suffix(showLast))
        let mask = String(repeating: "•", count: min(maskLength, 8))
        
        return "\(prefix)\(mask)\(visiblePart)"
    }
}
