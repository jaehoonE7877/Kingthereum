import SwiftUI
import DesignSystem
import Entity

@MainActor
protocol ReceiveDisplayLogic: AnyObject {
    func displayWalletAddress(viewModel: ReceiveScene.LoadWalletAddress.ViewModel)
    func displayCopyResult(viewModel: ReceiveScene.CopyAddress.ViewModel)
    func displayShareSheet(viewModel: ReceiveScene.ShareAddress.ViewModel)
    func displayQRCode(viewModel: ReceiveScene.GenerateQRCode.ViewModel)
}

struct ReceiveView: View {
    @StateObject private var coordinator = ReceiveCoordinator()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient.enhancedBackgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    qrCodeSection
                    addressSection
                    actionButtons
                    securityNotice
                }
                .padding(.horizontal, 20)
                .padding(.top, 8) // 네비게이션 바 제거로 상단 여백 줄임
            }
            
            // 토스트 알림
            if coordinator.showSuccessToast {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ToastView(message: coordinator.toastMessage)
                        Spacer()
                    }
                    .padding(.bottom, 100)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .gesture(
            DragGesture()
                .onEnded { gesture in
                    // 아래로 스와이프하여 닫기
                    if gesture.translation.height > 100 && abs(gesture.translation.width) < 100 {
                        dismiss()
                    }
                }
        )
        .onAppear {
            coordinator.loadWalletAddress()
        }
        .onDisappear {
            coordinator.stopSecurityMonitoring()
        }
        .alert("주소 복사", isPresented: $coordinator.showCopyAlert) {
            Button("확인") { }
        } message: {
            Text("지갑 주소가 클립보드에 복사되었습니다.")
        }
        .sheet(isPresented: $coordinator.showShareSheet) {
            ShareSheet(items: coordinator.shareItems)
        }
        .alert("보안 경고", isPresented: $coordinator.showSecurityWarning) {
            Button("확인") {
                // QR 코드 재생성
                coordinator.generateQRCode()
            }
        } message: {
            Text(coordinator.securityWarningMessage)
        }
        .alert(coordinator.errorTitle, isPresented: $coordinator.showErrorAlert) {
            Button("확인") { }
            if coordinator.errorSuggestion != nil {
                Button("재시도") {
                    coordinator.generateQRCode()
                }
            }
        } message: {
            VStack(alignment: .leading, spacing: 8) {
                Text(coordinator.errorMessage)
                if let suggestion = coordinator.errorSuggestion {
                    Text(suggestion)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Header Section

extension ReceiveView {
    private var headerSection: some View {
        VStack(spacing: 12) {
            // 닫기 제스처 힌트 - 상단에 더 가깝게
            RoundedRectangle(cornerRadius: 3)
                .fill(.secondary.opacity(0.3))
                .frame(width: 40, height: 6)
                .padding(.top, 4)
                .padding(.bottom, 16)
            
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 64, height: 64)
                
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(LinearGradient.primaryGradient)
            }
            
            Text("이더리움 받기")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 4) {
                Text("아래 QR 코드를 스캔하거나 주소를 복사하여 사용하세요")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text("아래로 스와이프하여 닫기")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.7))
            }
        }
        .padding(.top, 12)
    }
}

// MARK: - QR Code Section

extension ReceiveView {
    private var qrCodeSection: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .frame(width: 240, height: 240)
                
                if let qrCodeData = coordinator.qrCodeData,
                   let uiImage = UIImage(data: qrCodeData) {
                    Image(uiImage: uiImage)
                        .interpolation(.none)
                        .resizable()
                        .frame(width: 200, height: 200)
                        .cornerRadius(DesignTokens.CornerRadius.md)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "qrcode")
                            .font(.system(size: 48))
                            .foregroundStyle(LinearGradient.primaryGradient)
                        
                        Text("QR 코드 생성 중...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .metalLiquidGlassCard(style: .wallet)
        }
    }
}

// MARK: - Address Section

extension ReceiveView {
    private var addressSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "link")
                    .font(.title3)
                    .foregroundStyle(LinearGradient.primaryGradient)
                
                Text("지갑 주소")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                // 전체 주소 표시
                HStack {
                    Text(coordinator.walletAddress)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.primary)
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
                .padding(16)
                .background(.ultraThinMaterial)
                .cornerRadius(DesignTokens.CornerRadius.md)
                
                // 축약된 주소와 복사 버튼
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("축약 주소")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(coordinator.formattedAddress)
                            .font(.system(.subheadline, design: .monospaced))
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    GlassButton(icon: "doc.on.doc.fill", style: .icon) {
                        coordinator.copyAddress()
                    }
                }
                .padding(16)
                .metalLiquidGlassCard(style: .default)
            }
        }
    }
}

// MARK: - Action Buttons

extension ReceiveView {
    private var actionButtons: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                GlassButton(
                    icon: "doc.on.doc.fill",
                    title: "주소 복사",
                    style: .secondary
                ) {
                    coordinator.copyAddress()
                }
                
                GlassButton(
                    icon: "square.and.arrow.up",
                    title: "공유하기",
                    style: .secondary
                ) {
                    coordinator.shareAddress()
                }
            }
            
            Button {
                coordinator.generateQRCode()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: coordinator.isRefreshing ? "arrow.clockwise" : "qrcode.viewfinder")
                        .font(.system(size: 16, weight: .medium))
                        .rotationEffect(.degrees(coordinator.isRefreshing ? 360 : 0))
                        .animation(coordinator.isRefreshing ? .linear(duration: 1.0).repeatForever(autoreverses: false) : .default, value: coordinator.isRefreshing)
                    
                    Text(coordinator.isRefreshing ? "새로고침 중..." : "QR 코드 새로고침")
                        .font(.system(size: 16, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .frame(height: DesignTokens.Size.Button.md)
                .background(.ultraThinMaterial)
                .foregroundStyle(LinearGradient.primaryGradient)
                .cornerRadius(DesignTokens.CornerRadius.md)
                .metalLiquidGlassCard(style: .wallet)
            }
            .scaleEffect(coordinator.isRefreshing ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: coordinator.isRefreshing)
            .disabled(coordinator.isRefreshing)
        }
    }
}

// MARK: - Security Notice

extension ReceiveView {
    private var securityNotice: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "shield.checkered")
                    .font(.title3)
                    .foregroundStyle(LinearGradient.warningGradient)
                
                Text("보안 안내")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                SecurityNoticeItem(
                    icon: "checkmark.circle.fill",
                    text: "이더리움 네트워크에서만 ETH와 ERC-20 토큰을 받을 수 있습니다"
                )
                
                SecurityNoticeItem(
                    icon: "exclamationmark.triangle.fill",
                    text: "다른 네트워크에서 전송하면 자산을 잃을 수 있습니다"
                )
                
                SecurityNoticeItem(
                    icon: "eye.slash.fill",
                    text: "공개된 장소에서 QR 코드를 스캔할 때 주의하세요"
                )
            }
            .padding(16)
            .metalLiquidGlassCard(style: .default)
        }
        .padding(.bottom, 40)
    }
}

// MARK: - Security Notice Item

struct SecurityNoticeItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(LinearGradient.warningGradient)
                .frame(width: 16)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Coordinator

@MainActor
final class ReceiveCoordinator: ObservableObject {
    @Published var walletAddress: String = ""
    @Published var formattedAddress: String = ""
    @Published var qrCodeData: Data?
    @Published var showCopyAlert = false
    @Published var showShareSheet = false
    @Published var shareItems: [Any] = []
    @Published var showSecurityWarning = false
    @Published var securityWarningMessage = ""
    @Published var showErrorAlert = false
    @Published var errorTitle = ""
    @Published var errorMessage = ""
    @Published var errorSuggestion: String?
    @Published var isRefreshing = false
    @Published var showSuccessToast = false
    @Published var toastMessage = ""
    
    private var interactor: ReceiveBusinessLogic?
    private let securityManager = ReceiveSecurityManager()
    private let errorHandler = ReceiveErrorHandler()
    
    init() {
        setupVIP()
        setupSecurity()
    }
    
    private func setupVIP() {
        let interactor = ReceiveInteractor()
        let presenter = ReceivePresenter()
        
        interactor.presenter = presenter
        presenter.viewController = self
        
        self.interactor = interactor
    }
    
    private func setupSecurity() {
        securityManager.delegate = self
        securityManager.startSecurityMonitoring()
    }
    
    func stopSecurityMonitoring() {
        securityManager.stopSecurityMonitoring()
    }
    
    func loadWalletAddress() {
        interactor?.loadWalletAddress(request: ReceiveScene.LoadWalletAddress.Request())
    }
    
    func copyAddress() {
        interactor?.copyAddress(request: ReceiveScene.CopyAddress.Request(address: walletAddress))
    }
    
    func shareAddress() {
        interactor?.shareAddress(request: ReceiveScene.ShareAddress.Request(address: walletAddress))
    }
    
    func generateQRCode() {
        guard !walletAddress.isEmpty else {
            handleError(ReceiveError.invalidWalletAddress("주소가 비어있습니다"))
            return
        }
        
        isRefreshing = true
        interactor?.generateQRCode(request: ReceiveScene.GenerateQRCode.Request(address: walletAddress))
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ error: Error) {
        let errorInfo = errorHandler.handleError(error)
        
        errorTitle = errorInfo.title
        errorMessage = errorInfo.message
        errorSuggestion = errorInfo.suggestion
        showErrorAlert = true
    }
}

// MARK: - Display Logic

extension ReceiveCoordinator: ReceiveDisplayLogic {
    func displayWalletAddress(viewModel: ReceiveScene.LoadWalletAddress.ViewModel) {
        self.walletAddress = viewModel.walletAddress
        self.formattedAddress = viewModel.formattedAddress
        self.qrCodeData = viewModel.qrCodeData
    }
    
    func displayCopyResult(viewModel: ReceiveScene.CopyAddress.ViewModel) {
        self.showCopyAlert = viewModel.showCopyAlert
    }
    
    func displayShareSheet(viewModel: ReceiveScene.ShareAddress.ViewModel) {
        self.shareItems = viewModel.shareItems
        self.showShareSheet = viewModel.showShareSheet
    }
    
    func displayQRCode(viewModel: ReceiveScene.GenerateQRCode.ViewModel) {
        self.qrCodeData = viewModel.qrCodeData
        self.isRefreshing = false
        
        // QR 새로고침 완료 피드백
        if viewModel.showSuccessAnimation {
            showRefreshSuccessFeedback()
        }
    }
    
    private func showRefreshSuccessFeedback() {
        // 햅틱 피드백
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // 토스트 메시지 설정
        toastMessage = "QR 코드가 새로고침되었습니다"
        
        // 토스트 표시
        withAnimation(.easeInOut(duration: 0.3)) {
            showSuccessToast = true
        }
        
        // 2초 후 토스트 자동 숨김
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.showSuccessToast = false
            }
        }
    }
}

// MARK: - Security Delegate

extension ReceiveCoordinator: ReceiveSecurityDelegate {
    func didDetectScreenshot() {
        self.securityWarningMessage = "보안 경고: 스크린샷이 감지되었습니다. QR 코드를 타인과 공유하지 마세요."
        self.showSecurityWarning = true
    }
    
    func didDetectScreenRecording() {
        self.securityWarningMessage = "보안 경고: 화면 녹화가 감지되었습니다. 보안을 위해 QR 코드가 숨겨집니다."
        self.showSecurityWarning = true
        // QR 코드 데이터를 임시로 제거하여 녹화에서 보호
        self.qrCodeData = nil
    }
    
    func didDetectAppBackgrounded() {
        // 앱이 백그라운드로 갈 때 민감한 정보 숨기기
        self.qrCodeData = nil
    }
}

// MARK: - Toast View

struct ToastView: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(LinearGradient.primaryGradient)
            
            Text(message)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
        .cornerRadius(DesignTokens.CornerRadius.md)
        .metalLiquidGlassCard(style: .default)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    ReceiveView()
}

#Preview("Toast") {
    ZStack {
        LinearGradient.enhancedBackgroundGradient
            .ignoresSafeArea()
        
        ToastView(message: "QR 코드가 새로고침되었습니다")
    }
}
