import SwiftUI
import Combine
import Foundation

// MARK: - Receive Coordinator

@MainActor
final class ReceiveCoordinator: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var realTimeBalance: String = "0.0000"
    @Published var balanceUSD: String = "$0.00"
    @Published var ethereumPrice: Double = 0.0
    @Published var isLoadingBalance: Bool = false
    @Published var balanceError: String?
    
    @Published var currentAddress: String = ""
    @Published var qrCodeImage: UIImage?
    @Published var isGeneratingQR: Bool = false
    
    @Published var securityStatus: SecurityStatus = .secure
    @Published var securityAlerts: [SecurityAlert] = []
    
    @Published var toastMessage: ToastMessage?
    @Published var isRefreshing: Bool = false
    
    // MARK: - Additional Properties for compatibility
    @Published var walletAddress: String = ""
    @Published var formattedAddress: String = ""
    @Published var qrCodeData: Data?
    @Published var currentBalance: Double = 0.0
    @Published var formattedBalance: String = "0.0000"
    @Published var usdValue: Double = 0.0
    @Published var formattedUSDValue: String = "0.00"
    @Published var lastBalanceUpdate: Date = Date()
    @Published var lastUpdateTimeString: String = ""
    @Published var isUpdatingBalance: Bool = false
    @Published var isLoading: Bool = false
    @Published var justCopied: Bool = false
    @Published var showToast: Bool = false
    @Published var toastType: ToastView.ToastType = .info
    @Published var showSecurityAlert: Bool = false
    @Published var securityAlertMessage: String = ""
    @Published var showShareSheet: Bool = false
    
    // MARK: - Security Manager
    let securityManager = ReceiveSecurityManager()
    
    // MARK: - Dependencies
    
    private let receiveWorker: ReceiveWorker
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Balance Update Timer
    
    private var balanceUpdateTimer: Timer?
    private let balanceUpdateInterval: TimeInterval = 10.0 // 10초마다 업데이트
    
    // MARK: - Initialization
    
    init(
        receiveWorker: ReceiveWorker = ReceiveWorker()
    ) {
        self.receiveWorker = receiveWorker
        
        setupBindings()
        startRealTimeUpdates()
    }
    
    deinit {
        stopRealTimeUpdates()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Security Manager 바인딩
        securityManager.$currentSecurityStatus
            .receive(on: DispatchQueue.main)
            .assign(to: &$securityStatus)
        
        securityManager.$activeAlerts
            .receive(on: DispatchQueue.main)
            .assign(to: &$securityAlerts)
        
        // 주소 변경 시 QR 코드 재생성
        $currentAddress
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] address in
                if !address.isEmpty {
                    self?.generateQRCode(for: address)
                }
            }
            .store(in: &cancellables)
            
        // walletAddress와 currentAddress 동기화
        $walletAddress
            .assign(to: &$currentAddress)
        
        // realTimeBalance와 formattedBalance 동기화
        $realTimeBalance
            .assign(to: &$formattedBalance)
        
        // 실시간 잔액을 Double로 변환
        $formattedBalance
            .map { Double($0) ?? 0.0 }
            .assign(to: &$currentBalance)
    }
    
    // MARK: - Real-Time Updates
    
    private func startRealTimeUpdates() {
        balanceUpdateTimer = Timer.scheduledTimer(withTimeInterval: balanceUpdateInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.updateBalance()
                await self?.updateEthereumPrice()
            }
        }
        
        // 초기 로드
        Task {
            await loadInitialData()
        }
    }
    
    private func stopRealTimeUpdates() {
        balanceUpdateTimer?.invalidate()
        balanceUpdateTimer = nil
    }
    
    // MARK: - Data Loading
    
    func loadWalletData() {
        Task {
            await loadInitialData()
        }
    }
    
    func refreshWalletData() async {
        await refreshData()
    }
    
    func cleanup() {
        stopRealTimeUpdates()
        securityManager.stopSecurityMonitoring()
    }
    
    func loadInitialData() async {
        isLoadingBalance = true
        isLoading = true
        balanceError = nil
        
        do {
            async let balanceTask = updateBalance()
            async let priceTask = updateEthereumPrice()
            async let addressTask = loadWalletAddress()
            
            _ = await (balanceTask, priceTask, addressTask)
            
        } catch {
            balanceError = "데이터 로드 실패: \(error.localizedDescription)"
            showToast(message: "데이터 로드에 실패했습니다", type: .error)
        }
        
        isLoadingBalance = false
        isLoading = false
    }
    
    @MainActor
    private func updateBalance() async {
        guard !walletAddress.isEmpty else { return }
        
        isUpdatingBalance = true
        
        do {
            let balance = try await receiveWorker.getWalletBalance(address: walletAddress)
            realTimeBalance = formatBalance(balance)
            currentBalance = balance
            formattedBalance = realTimeBalance
            updateBalanceUSD()
            lastBalanceUpdate = Date()
            updateLastUpdateTimeString()
        } catch {
            print("Balance update failed: \(error)")
        }
        
        isUpdatingBalance = false
    }
    
    @MainActor
    private func updateEthereumPrice() async {
        do {
            let price = try await receiveWorker.getEthereumPrice()
            ethereumPrice = price
            updateBalanceUSD()
        } catch {
            print("Price update failed: \(error)")
        }
    }
    
    @MainActor
    private func loadWalletAddress() async {
        do {
            let address = try await receiveWorker.getCurrentWalletAddress()
            walletAddress = address
            currentAddress = address
            formattedAddress = formatAddress(address)
            
            // QR 코드 생성
            generateQRCode(for: address)
        } catch {
            balanceError = "지갑 주소 로드 실패"
            showToast(message: "지갑 주소를 불러올 수 없습니다", type: .error)
        }
    }
    
    // MARK: - QR Code Generation
    
    @MainActor
    private func generateQRCode(for address: String) {
        isGeneratingQR = true
        
        Task {
            do {
                let qrImage = try await receiveWorker.generateQRCode(for: address, size: CGSize(width: 200, height: 200))
                qrCodeImage = qrImage
                
                // Convert UIImage to Data
                if let imageData = qrImage.pngData() {
                    qrCodeData = imageData
                }
            } catch {
                showToast(message: "QR 코드 생성에 실패했습니다", type: .error)
            }
            isGeneratingQR = false
        }
    }
    
    func refreshQRCode() {
        guard !walletAddress.isEmpty else { return }
        generateQRCode(for: walletAddress)
    }
    
    // MARK: - User Actions
    
    func refreshData() async {
        guard !isRefreshing else { return }
        
        isRefreshing = true
        await loadInitialData()
        
        // 햅틱 피드백
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        showToast(message: "데이터가 업데이트되었습니다", type: .success)
        
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5초 대기
        isRefreshing = false
    }
    
    func copyAddress() {
        guard !walletAddress.isEmpty else {
            showToast(message: "복사할 주소가 없습니다", type: .error)
            return
        }
        
        UIPasteboard.general.string = walletAddress
        
        // 햅틱 피드백
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // 복사 애니메이션 효과
        justCopied = true
        showToast(message: "주소가 복사되었습니다", type: .success)
        
        // 2초 후 복사 상태 리셋
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.justCopied = false
        }
    }
    
    func shareAddress() {
        shareWalletInfo()
    }
    
    func shareWalletInfo() {
        guard !walletAddress.isEmpty else {
            showToast(message: "공유할 주소가 없습니다", type: .error)
            return
        }
        
        showShareSheet = true
    }
    
    func requestPayment() {
        // TODO: 결제 요청 기능 구현
        showToast(message: "결제 요청 기능이 곧 제공될 예정입니다", type: .info)
    }
    
    // MARK: - Security Actions
    
    func dismissSecurityAlert(_ alert: SecurityAlert) {
        securityManager.dismissAlert(alert)
    }
    
    func refreshSecurityStatus() {
        securityManager.performSecurityCheck()
        showToast(message: "보안 상태가 확인되었습니다", type: .info)
    }
    
    func handleSecurityAlertAction() {
        // 보안 경고 액션 처리
        showSecurityAlert = false
    }
    
    func resetSecurity() {
        securityManager.resetSecurityStatus()
        showToast(message: "보안 상태가 초기화되었습니다", type: .info)
    }
    
    // MARK: - Helper Methods
    
    private func formatBalance(_ balance: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 4
        formatter.maximumFractionDigits = 4
        return formatter.string(from: NSNumber(value: balance)) ?? "0.0000"
    }
    
    private func formatAddress(_ address: String) -> String {
        guard address.count > 10 else { return address }
        let start = String(address.prefix(6))
        let end = String(address.suffix(4))
        return "\(start)...\(end)"
    }
    
    private func updateBalanceUSD() {
        guard currentBalance > 0, ethereumPrice > 0 else {
            balanceUSD = "$0.00"
            usdValue = 0.0
            formattedUSDValue = "0.00"
            return
        }
        
        let usdValue = currentBalance * ethereumPrice
        self.usdValue = usdValue
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        balanceUSD = formatter.string(from: NSNumber(value: usdValue)) ?? "$0.00"
        
        // formattedUSDValue는 숫자만
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 2
        numberFormatter.maximumFractionDigits = 2
        formattedUSDValue = numberFormatter.string(from: NSNumber(value: usdValue)) ?? "0.00"
    }
    
    private func updateLastUpdateTimeString() {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ko_KR")
        lastUpdateTimeString = formatter.string(from: lastBalanceUpdate)
    }
    
    private func showToast(message: String, type: ToastView.ToastType) {
        toastMessage = ToastMessage(text: message, type: type)
        self.toastType = type
        showToast = true
        
        // 3초 후 자동 삭제
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3초
            if toastMessage?.text == message {
                toastMessage = nil
                showToast = false
            }
        }
    }
}

// MARK: - Supporting Types

enum SecurityStatus: String, CaseIterable {
    case secure = "secure"
    case warning = "warning" 
    case danger = "danger"
    
    var displayName: String {
        switch self {
        case .secure: return "안전"
        case .warning: return "주의"
        case .danger: return "위험"
        }
    }
    
    var color: Color {
        switch self {
        case .secure: return .green
        case .warning: return .orange
        case .danger: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .secure: return "shield.checkered"
        case .warning: return "shield.lefthalf.filled.trianglebadge.exclamationmark"
        case .danger: return "shield.slash"
        }
    }
}

struct SecurityAlert: Identifiable, Equatable {
    let id = UUID()
    let type: AlertType
    let message: String
    let timestamp: Date
    let severity: SecurityStatus
    
    enum AlertType: String, CaseIterable {
        case screenshot = "screenshot"
        case screenRecording = "screenRecording"
        case suspiciousActivity = "suspiciousActivity"
        case networkIssue = "networkIssue"
        
        var displayName: String {
            switch self {
            case .screenshot: return "스크린샷 감지"
            case .screenRecording: return "화면 녹화 감지"
            case .suspiciousActivity: return "의심스러운 활동"
            case .networkIssue: return "네트워크 문제"
            }
        }
    }
}

struct ToastMessage: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let type: ToastView.ToastType
    let timestamp = Date()
}

// MARK: - Extensions for ReceiveWorker

extension ReceiveWorker {
    
    func getWalletBalance(address: String) async throws -> Double {
        // TODO: 실제 블록체인에서 잔액 조회
        // 현재는 임시 데이터 반환
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5초 대기
        return Double.random(in: 0.1...10.0)
    }
    
    func getEthereumPrice() async throws -> Double {
        // TODO: 실제 가격 API 연동
        // 현재는 임시 데이터 반환
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3초 대기
        return Double.random(in: 2000...4000)
    }
    
    func getCurrentWalletAddress() async throws -> String {
        // TODO: 실제 지갑에서 주소 가져오기
        // 현재는 임시 데이터 반환
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2초 대기
        return "0x742d35Cc6C834C6532C5C4b4c8C8D7C47dA84F4f"
    }
    
    func generateQRCode(for address: String, size: CGSize) async throws -> UIImage {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let data = address.data(using: .utf8) else {
                    continuation.resume(returning: UIImage())
                    return
                }
                
                let context = CIContext()
                let filter = CIFilter.qrCodeGenerator()
                filter.setValue(data, forKey: "inputMessage")
                
                if let qrCodeImage = filter.outputImage {
                    let scaleX = size.width / qrCodeImage.extent.size.width
                    let scaleY = size.height / qrCodeImage.extent.size.height
                    let transformedImage = qrCodeImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
                    
                    if let cgImage = context.createCGImage(transformedImage, from: transformedImage.extent) {
                        let uiImage = UIImage(cgImage: cgImage)
                        continuation.resume(returning: uiImage)
                    } else {
                        continuation.resume(returning: UIImage())
                    }
                } else {
                    continuation.resume(returning: UIImage())
                }
            }
        }
    }
}