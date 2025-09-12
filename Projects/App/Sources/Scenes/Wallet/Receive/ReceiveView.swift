import SwiftUI
import DesignSystem
import Entity
import CoreImage

/// 🔐 Premium Receive View - Revolut/N26 Level
/// Minimalist design with glassmorphism and premium fintech patterns
struct ReceiveView: View {
    @State private var viewStore = ReceiveViewStore()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // 🎨 프리미엄 배경
            premiumBackground
            
            ScrollView {
                VStack(spacing: KingDesignTokens.Spacing.xl) {
                    // 헤더 섹션
                    premiumHeaderSection
                    
                    // QR 코드 섹션
                    premiumQRCodeSection
                    
                    // 주소 섹션
                    premiumAddressSection
                    
                    // 액션 버튼들
                    premiumActionButtons
                    
                    // 보안 안내
                    premiumSecurityNotice
                }
                .padding(.horizontal, KingDesignTokens.Spacing.lg)
                .padding(.vertical, KingDesignTokens.Spacing.md)
            }
            
            // 토스트 알림
            if viewStore.showToast {
                premiumToast
            }
        }
        .gesture(swipeDownGesture)
        .onAppear {
            viewStore.loadWalletAddress()
        }
        .sheet(isPresented: $viewStore.showShareSheet) {
            PremiumShareSheet(
                address: viewStore.walletAddress,
                qrCodeData: viewStore.qrCodeData
            )
        }
    }
    
    // MARK: - 프리미엄 컴포넌트들
    
    @ViewBuilder
    private var premiumBackground: some View {
        LinearGradient(
            colors: [
                KingDesignTokens.Colors.background,
                KingDesignTokens.Colors.surface,
                KingDesignTokens.Colors.surfaceSecondary
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        // 앰비언트 글로우
        RadialGradient(
            colors: [
                KingDesignTokens.Colors.accent.opacity(0.02),
                Color.clear
            ],
            center: .topTrailing,
            startRadius: 0,
            endRadius: 300
        )
        .ignoresSafeArea()
    }
    
    @ViewBuilder
    private var premiumHeaderSection: some View {
        VStack(spacing: KingDesignTokens.Spacing.lg) {
            // 드래그 인디케이터
            Capsule()
                .fill(KingDesignTokens.Colors.border)
                .frame(width: 36, height: 5)
                .padding(.top, KingDesignTokens.Spacing.xs)
            
            // 프리미엄 아이콘
            ZStack {
                Circle()
                    .fill(KingDesignTokens.Colors.accent.opacity(0.1))
                    .frame(width: KingDesignTokens.Sizing.iconLarge, height: KingDesignTokens.Sizing.iconLarge)
                    .overlay(
                        Circle()
                            .stroke(KingDesignTokens.Colors.accent.opacity(0.3), lineWidth: KingDesignTokens.BorderWidth.thin)
                    )
                
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                KingDesignTokens.Colors.accent,
                                KingDesignTokens.Colors.accent.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .shadow(
                color: KingDesignTokens.Colors.accent.opacity(0.2),
                radius: 12,
                x: 0,
                y: 6
            )
            
            // 제목과 설명
            VStack(spacing: KingDesignTokens.Spacing.sm) {
                Text("이더리움 받기")
                    .font(KingDesignTokens.Typography.displayM)
                    .fontWeight(.bold)
                    .foregroundColor(KingDesignTokens.Colors.primaryText)
                
                Text("QR 코드를 스캔하거나 주소를 복사하여 ETH를 받으세요")
                    .font(KingDesignTokens.Typography.body)
                    .foregroundColor(KingDesignTokens.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
        }
    }
    
    @ViewBuilder
    private var premiumQRCodeSection: some View {
        VStack(spacing: KingDesignTokens.Spacing.lg) {
            // 섹션 헤더
            HStack {
                Image(systemName: "qrcode.viewfinder")
                    .font(KingDesignTokens.Typography.heading)
                    .foregroundColor(KingDesignTokens.Colors.accent)
                
                Text("지갑 QR 코드")
                    .font(KingDesignTokens.Typography.heading)
                    .fontWeight(.semibold)
                    .foregroundColor(KingDesignTokens.Colors.primaryText)
                
                Spacer()
            }
            
            // QR 코드 컨테이너
            GlassCard(level: .standard, cornerRadius: KingDesignTokens.Radius.xl) {
                VStack(spacing: KingDesignTokens.Spacing.lg) {
                    if let qrCodeData = viewStore.qrCodeData,
                       let uiImage = UIImage(data: qrCodeData) {
                        Image(uiImage: uiImage)
                            .interpolation(.none)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 200, height: 200)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: KingDesignTokens.Radius.md))
                            .shadow(
                                color: KingDesignTokens.Colors.primaryText.opacity(0.1),
                                radius: 4,
                                x: 0,
                                y: 2
                            )
                    } else if viewStore.isLoading {
                        VStack(spacing: KingDesignTokens.Spacing.md) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: KingDesignTokens.Colors.accent))
                                .scaleEffect(1.2)
                            
                            Text("QR 코드 생성 중...")
                                .font(KingDesignTokens.Typography.caption)
                                .foregroundColor(KingDesignTokens.Colors.secondaryText)
                        }
                        .frame(width: 200, height: 200)
                    } else {
                        VStack(spacing: KingDesignTokens.Spacing.md) {
                            Image(systemName: "qrcode")
                                .font(.system(size: 48))
                                .foregroundColor(KingDesignTokens.Colors.accent.opacity(0.6))
                            
                            Text("QR 코드를 생성할 수 없습니다")
                                .font(KingDesignTokens.Typography.caption)
                                .foregroundColor(KingDesignTokens.Colors.secondaryText)
                        }
                        .frame(width: 200, height: 200)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var premiumAddressSection: some View {
        VStack(spacing: KingDesignTokens.Spacing.lg) {
            // 섹션 헤더
            HStack {
                Image(systemName: "link.circle.fill")
                    .font(KingDesignTokens.Typography.heading)
                    .foregroundColor(KingDesignTokens.Colors.accent)
                
                Text("지갑 주소")
                    .font(KingDesignTokens.Typography.heading)
                    .fontWeight(.semibold)
                    .foregroundColor(KingDesignTokens.Colors.primaryText)
                
                Spacer()
            }
            
            // 주소 카드
            GlassCard(level: .standard) {
                VStack(spacing: KingDesignTokens.Spacing.md) {
                    // 전체 주소
                    HStack {
                        Text(viewStore.walletAddress.isEmpty ? "주소 로딩 중..." : viewStore.walletAddress)
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.medium)
                            .foregroundColor(KingDesignTokens.Colors.primaryText)
                            .textSelection(.enabled)
                            .lineLimit(nil)
                        
                        Spacer(minLength: 0)
                    }
                    
                    Divider()
                        .background(KingDesignTokens.Colors.border)
                    
                    // 축약 주소 & 복사 버튼
                    HStack {
                        VStack(alignment: .leading, spacing: KingDesignTokens.Spacing.xs) {
                            Text("축약 주소")
                                .font(KingDesignTokens.Typography.caption)
                                .foregroundColor(KingDesignTokens.Colors.tertiaryText)
                            
                            Text(viewStore.formattedAddress)
                                .font(.system(.subheadline, design: .monospaced))
                                .fontWeight(.semibold)
                                .foregroundColor(KingDesignTokens.Colors.primaryText)
                        }
                        
                        Spacer()
                        
                        Button {
                            viewStore.copyAddress()
                        } label: {
                            Image(systemName: viewStore.justCopied ? "checkmark.circle.fill" : "doc.on.doc.fill")
                                .font(.title2)
                                .foregroundColor(viewStore.justCopied ? KingDesignTokens.Colors.success : KingDesignTokens.Colors.accent)
                                .scaleEffect(viewStore.justCopied ? 1.1 : 1.0)
                                .animation(KingDesignTokens.Animation.spring, value: viewStore.justCopied)
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var premiumActionButtons: some View {
        VStack(spacing: KingDesignTokens.Spacing.md) {
            // 주요 액션들
            HStack(spacing: KingDesignTokens.Spacing.md) {
                GlassButton(
                    "주소 복사",
                    icon: "doc.on.doc.fill",
                    style: .secondary
                ) {
                    viewStore.copyAddress()
                }
                
                GlassButton(
                    "공유하기",
                    icon: "square.and.arrow.up",
                    style: .secondary
                ) {
                    viewStore.shareAddress()
                }
            }
            
            // QR 새로고침
            GlassButton(
                viewStore.isRefreshing ? "새로고침 중..." : "QR 코드 새로고침",
                icon: "arrow.clockwise",
                style: .primary
            ) {
                viewStore.refreshQRCode()
            }
            .disabled(viewStore.isRefreshing)
        }
    }
    
    @ViewBuilder
    private var premiumSecurityNotice: some View {
        GlassCard(level: .subtle) {
            VStack(alignment: .leading, spacing: KingDesignTokens.Spacing.md) {
                // 헤더
                HStack(spacing: KingDesignTokens.Spacing.sm) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(KingDesignTokens.Typography.body)
                        .foregroundColor(KingDesignTokens.Colors.success)
                    
                    Text("보안 안내")
                        .font(KingDesignTokens.Typography.body)
                        .fontWeight(.semibold)
                        .foregroundColor(KingDesignTokens.Colors.primaryText)
                }
                
                // 안내사항들
                VStack(alignment: .leading, spacing: KingDesignTokens.Spacing.sm) {
                    SecurityNoticeItem(
                        icon: "checkmark.shield.fill",
                        text: "이더리움 메인넷 전용 주소입니다",
                        color: KingDesignTokens.Colors.success
                    )
                    
                    SecurityNoticeItem(
                        icon: "exclamationmark.triangle.fill",
                        text: "다른 네트워크 사용 시 자산 손실 위험",
                        color: KingDesignTokens.Colors.warning
                    )
                    
                    SecurityNoticeItem(
                        icon: "eye.slash.fill",
                        text: "공개 장소에서 QR 코드 노출 주의",
                        color: KingDesignTokens.Colors.warning
                    )
                }
            }
        }
        .padding(.bottom, KingDesignTokens.Spacing.xxxl)
    }
    
    @ViewBuilder
    private var premiumToast: some View {
        VStack {
            Spacer()
            
            HStack(spacing: KingDesignTokens.Spacing.sm) {
                Image(systemName: viewStore.toastType.icon)
                    .font(KingDesignTokens.Typography.body)
                    .foregroundColor(viewStore.toastType.color)
                
                Text(viewStore.toastMessage)
                    .font(KingDesignTokens.Typography.body)
                    .foregroundColor(KingDesignTokens.Colors.primaryText)
                
                Spacer()
            }
            .padding(KingDesignTokens.Spacing.lg)
            .background(KingDesignTokens.Colors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: KingDesignTokens.Radius.md)
                    .stroke(viewStore.toastType.color.opacity(0.3), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: KingDesignTokens.Radius.md))
            .shadow(
                color: KingDesignTokens.Colors.primaryText.opacity(0.1),
                radius: 12,
                x: 0,
                y: 6
            )
            .padding(.horizontal, KingDesignTokens.Spacing.lg)
            .padding(.bottom, KingDesignTokens.Spacing.xxxl)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
    
    private var swipeDownGesture: some Gesture {
        DragGesture()
            .onEnded { gesture in
                if gesture.translation.height > 100 && 
                   abs(gesture.translation.width) < 100 {
                    dismiss()
                }
            }
    }
}

// MARK: - Supporting Components

/// 보안 안내 아이템
struct SecurityNoticeItem: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: KingDesignTokens.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(color)
                .frame(width: 16)
            
            Text(text)
                .font(KingDesignTokens.Typography.caption)
                .foregroundColor(KingDesignTokens.Colors.secondaryText)
                .multilineTextAlignment(.leading)
        }
    }
}

/// ViewStore for ReceiveView
@MainActor
@Observable
final class ReceiveViewStore {
    var walletAddress: String = ""
    var formattedAddress: String = ""
    var qrCodeData: Data?
    var isLoading: Bool = false
    var isRefreshing: Bool = false
    var justCopied: Bool = false
    var showToast: Bool = false
    var toastMessage: String = ""
    var toastType: ToastType = .success
    var showShareSheet: Bool = false
    
    enum ToastType {
        case success, warning, error
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .success: return KingDesignTokens.Colors.success
            case .warning: return KingDesignTokens.Colors.warning
            case .error: return KingDesignTokens.Colors.error
            }
        }
    }
    
    func loadWalletAddress() {
        isLoading = true
        
        // 시뮬레이션된 지갑 주소 로드
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1초 대기
            
            walletAddress = "0x742d35Cc6644C0532925a3b8F0aB4e7E"
            formattedAddress = formatAddress(walletAddress)
            generateQRCode()
            isLoading = false
        }
    }
    
    func generateQRCode() {
        guard !walletAddress.isEmpty else { return }
        
        let data = walletAddress.data(using: .ascii)
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return }
        filter.setValue(data, forKey: "inputMessage")
        
        if let outputImage = filter.outputImage {
            let context = CIContext()
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                let uiImage = UIImage(cgImage: cgImage)
                qrCodeData = uiImage.pngData()
            }
        }
    }
    
    func copyAddress() {
        UIPasteboard.general.string = walletAddress
        justCopied = true
        showToast(message: "주소가 클립보드에 복사되었습니다", type: .success)
        
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            justCopied = false
        }
    }
    
    func shareAddress() {
        showShareSheet = true
    }
    
    func refreshQRCode() {
        isRefreshing = true
        
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5초 대기
            generateQRCode()
            isRefreshing = false
            showToast(message: "QR 코드가 새로고침되었습니다", type: .success)
        }
    }
    
    private func formatAddress(_ address: String) -> String {
        guard address.count > 10 else { return address }
        let prefix = String(address.prefix(6))
        let suffix = String(address.suffix(4))
        return "\(prefix)...\(suffix)"
    }
    
    private func showToast(message: String, type: ToastType) {
        toastMessage = message
        toastType = type
        showToast = true
        
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            showToast = false
        }
    }
}

/// 프리미엄 공유 시트
struct PremiumShareSheet: View {
    let address: String
    let qrCodeData: Data?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: KingDesignTokens.Spacing.xl) {
                // QR 코드
                if let qrCodeData = qrCodeData,
                   let uiImage = UIImage(data: qrCodeData) {
                    Image(uiImage: uiImage)
                        .interpolation(.none)
                        .resizable()
                        .frame(width: 200, height: 200)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: KingDesignTokens.Radius.lg))
                        .shadow(
                            color: KingDesignTokens.Colors.primaryText.opacity(0.1),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                }
                
                // 주소 정보
                VStack(spacing: KingDesignTokens.Spacing.md) {
                    Text("내 이더리움 지갑")
                        .font(KingDesignTokens.Typography.displayM)
                        .fontWeight(.bold)
                        .foregroundColor(KingDesignTokens.Colors.primaryText)
                    
                    Text(address)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(KingDesignTokens.Colors.secondaryText)
                        .padding(KingDesignTokens.Spacing.md)
                        .background(KingDesignTokens.Colors.surfaceSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: KingDesignTokens.Radius.sm))
                        .textSelection(.enabled)
                }
                
                Spacer()
            }
            .padding(KingDesignTokens.Spacing.xl)
            .background(KingDesignTokens.Colors.background)
            .navigationTitle("지갑 공유")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        dismiss()
                    }
                    .foregroundColor(KingDesignTokens.Colors.accent)
                }
            }
        }
    }
}

#Preview {
    ReceiveView()
}