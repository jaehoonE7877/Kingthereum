import SwiftUI
import SecurityKit
import DesignSystem

// MARK: - Premium Address Input Component

/// 🔒 Ultra-secure address input with real-time validation and QR scanning
struct PremiumAddressInput: View {
    @Binding var address: String
    let validation: AddressValidation
    let onQRScan: () -> Void
    let onPasteClipboard: () -> Void
    
    @State private var isShowingQRScanner = false
    @State private var animationOffset: CGFloat = 0
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header with Security Indicator
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(KingDesignTokens.Colors.primary)
                        .font(.title3)
                    
                    Text("받는 주소")
                        .font(KingDesignTokens.Typography.headlineSmall)
                        .foregroundColor(KingDesignTokens.Colors.onSurface)
                }
                
                Spacer()
                
                // Security Status Indicator
                if !address.isEmpty {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(validation.isValid ? Color.green : validation.isValidating ? Color.orange : Color.red)
                            .frame(width: 8, height: 8)
                        
                        Text(validation.isValid ? "검증됨" : validation.isValidating ? "검증 중" : "오류")
                            .font(KingDesignTokens.Typography.captionMedium)
                            .foregroundColor(validation.isValid ? Color.green : validation.isValidating ? Color.orange : Color.red)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.2))
                    )
                }
            }
            
            // Premium Address Input Field
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    // Main Input Field
                    TextField("0x1234567890abcdef...", text: $address)
                        .focused($isFieldFocused)
                        .font(KingDesignTokens.Typography.bodyLarge)
                        .foregroundColor(KingDesignTokens.Colors.onSurface)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onChange(of: address) { oldValue, newValue in
                            // Animate on input change
                            withAnimation(.easeInOut(duration: 0.2)) {
                                animationOffset = 2
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    animationOffset = 0
                                }
                            }
                        }
                    
                    // Action Buttons
                    HStack(spacing: 8) {
                        // Paste Button
                        Button(action: onPasteClipboard) {
                            Image(systemName: "doc.on.clipboard")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(KingDesignTokens.Colors.primary)
                        }
                        .disabled(validation.isValidating)
                        
                        // QR Scanner Button
                        Button(action: onQRScan) {
                            Image(systemName: "qrcode.viewfinder")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(KingDesignTokens.Colors.primary)
                        }
                        .disabled(validation.isValidating)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(KingDesignTokens.Colors.surfaceVariant.opacity(0.6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        colors: validation.isValid ? [Color.green, Color.green.opacity(0.3)] :
                                               validation.isValidating ? [Color.orange, Color.orange.opacity(0.3)] :
                                               isFieldFocused ? [KingDesignTokens.Colors.primary, KingDesignTokens.Colors.primary.opacity(0.3)] :
                                               [KingDesignTokens.Colors.outline.opacity(0.3), KingDesignTokens.Colors.outline.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: validation.isValid ? 2 : 1.5
                                )
                        )
                )
                .offset(x: animationOffset)
                
                // Validation Message
                if let message = validation.message {
                    HStack(spacing: 8) {
                        Image(systemName: validation.isValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(validation.isValid ? Color.green : Color.red)
                        
                        Text(message)
                            .font(KingDesignTokens.Typography.captionMedium)
                            .foregroundColor(validation.isValid ? Color.green : Color.red)
                        
                        Spacer()
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, 4)
                }
            }
        }
    }
}

// MARK: - Premium Amount Input Component

/// 💰 Advanced amount input with balance validation and max amount selection
struct PremiumAmountInput: View {
    @Binding var amount: String
    let validation: AmountValidation
    let availableBalance: String
    let onMaxAmount: () -> Void
    
    @State private var showingBalanceDetail = false
    @State private var pulseAnimation = false
    @FocusState private var isAmountFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with Balance Info
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(KingDesignTokens.Colors.primary)
                        .font(.title3)
                    
                    Text("송금 금액")
                        .font(KingDesignTokens.Typography.headlineSmall)
                        .foregroundColor(KingDesignTokens.Colors.onSurface)
                }
                
                Spacer()
                
                // Available Balance
                Button(action: { showingBalanceDetail.toggle() }) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("사용 가능")
                            .font(KingDesignTokens.Typography.captionSmall)
                            .foregroundColor(KingDesignTokens.Colors.onSurfaceVariant)
                        
                        Text("\(availableBalance) ETH")
                            .font(KingDesignTokens.Typography.labelMedium)
                            .foregroundColor(KingDesignTokens.Colors.primary)
                            .fontWeight(.semibold)
                    }
                }
            }
            
            // Premium Amount Input
            VStack(spacing: 0) {
                HStack {
                    // Amount Input
                    TextField("0.00", text: $amount)
                        .focused($isAmountFocused)
                        .font(.system(size: 28, weight: .medium, design: .monospaced))
                        .foregroundColor(KingDesignTokens.Colors.onSurface)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.leading)
                    
                    // Currency and Max Button
                    VStack(alignment: .trailing, spacing: 8) {
                        Text("ETH")
                            .font(KingDesignTokens.Typography.titleMedium)
                            .foregroundColor(KingDesignTokens.Colors.onSurfaceVariant)
                            .fontWeight(.medium)
                        
                        Button(action: onMaxAmount) {
                            Text("MAX")
                                .font(KingDesignTokens.Typography.labelSmall)
                                .fontWeight(.bold)
                                .foregroundColor(KingDesignTokens.Colors.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(KingDesignTokens.Colors.primary.opacity(0.1))
                                        .overlay(
                                            Capsule()
                                                .stroke(KingDesignTokens.Colors.primary.opacity(0.3), lineWidth: 1)
                                        )
                                )
                        }
                        .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: pulseAnimation)
                        .onAppear {
                            pulseAnimation = true
                        }
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(KingDesignTokens.Colors.surfaceVariant.opacity(0.4))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        colors: validation.isValid ? [Color.green.opacity(0.6), Color.green.opacity(0.2)] :
                                               isAmountFocused ? [KingDesignTokens.Colors.primary.opacity(0.8), KingDesignTokens.Colors.primary.opacity(0.2)] :
                                               [KingDesignTokens.Colors.outline.opacity(0.3), KingDesignTokens.Colors.outline.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: validation.isValid ? 2 : 1.5
                                )
                        )
                )
                
                // Validation Message
                if let message = validation.message {
                    HStack(spacing: 8) {
                        Image(systemName: validation.isValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(validation.isValid ? Color.green : Color.red)
                        
                        Text(message)
                            .font(KingDesignTokens.Typography.captionMedium)
                            .foregroundColor(validation.isValid ? Color.green : Color.red)
                        
                        Spacer()
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, 4)
                }
            }
        }
    }
}

// MARK: - Premium Gas Fee Selector

/// ⚡ Intelligent gas fee selector with real-time estimation and priority options
struct PremiumGasFeeSelector: View {
    @Binding var selectedSpeed: GasSpeed
    let gasEstimate: GasEstimate?
    let isEstimating: Bool
    
    @State private var animateEstimation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "speedometer")
                        .foregroundColor(KingDesignTokens.Colors.primary)
                        .font(.title3)
                    
                    Text("네트워크 수수료")
                        .font(KingDesignTokens.Typography.headlineSmall)
                        .foregroundColor(KingDesignTokens.Colors.onSurface)
                }
                
                Spacer()
                
                if isEstimating {
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(KingDesignTokens.Colors.primary)
                        
                        Text("계산 중...")
                            .font(KingDesignTokens.Typography.captionMedium)
                            .foregroundColor(KingDesignTokens.Colors.onSurfaceVariant)
                    }
                }
            }
            
            if let estimate = gasEstimate, !isEstimating {
                // Gas Speed Options
                VStack(spacing: 12) {
                    // Speed Options Grid
                    HStack(spacing: 12) {
                        GasSpeedOption(
                            speed: .slow,
                            title: "절약",
                            subtitle: "~5분",
                            fee: "0.001",
                            gasPrice: "\(estimate.slowGasPrice)",
                            isSelected: selectedSpeed == .slow,
                            color: .green
                        ) {
                            selectedSpeed = .slow
                        }
                        
                        GasSpeedOption(
                            speed: .normal,
                            title: "표준",
                            subtitle: "~2분",
                            fee: "0.0015",
                            gasPrice: "\(estimate.normalGasPrice)",
                            isSelected: selectedSpeed == .normal,
                            color: .blue
                        ) {
                            selectedSpeed = .normal
                        }
                        
                        GasSpeedOption(
                            speed: .fast,
                            title: "빠름",
                            subtitle: "~30초",
                            fee: "0.002",
                            gasPrice: "\(estimate.fastGasPrice)",
                            isSelected: selectedSpeed == .fast,
                            color: .orange
                        ) {
                            selectedSpeed = .fast
                        }
                    }
                    
                    // Network Status Info
                    HStack(spacing: 12) {
                        Image(systemName: "network")
                            .foregroundColor(KingDesignTokens.Colors.primary)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("네트워크 상태: 보통")
                                .font(KingDesignTokens.Typography.captionMedium)
                                .foregroundColor(KingDesignTokens.Colors.onSurface)
                            
                            Text("평균 가스비: \(estimate.normalGasPrice) gwei")
                                .font(KingDesignTokens.Typography.captionSmall)
                                .foregroundColor(KingDesignTokens.Colors.onSurfaceVariant)
                        }
                        
                        Spacer()
                        
                        // Last Updated Indicator
                        Text("방금 업데이트")
                            .font(KingDesignTokens.Typography.captionSmall)
                            .foregroundColor(KingDesignTokens.Colors.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(KingDesignTokens.Colors.primary.opacity(0.1))
                            )
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(KingDesignTokens.Colors.surfaceVariant.opacity(0.3))
                    )
                }
            }
        }
    }
}

// MARK: - Gas Speed Option Component

private struct GasSpeedOption: View {
    let speed: GasSpeed
    let title: String
    let subtitle: String
    let fee: String
    let gasPrice: String
    let isSelected: Bool
    let color: Color
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                // Icon and Title
                VStack(spacing: 4) {
                    Image(systemName: speed.iconName)
                        .font(.title2)
                        .foregroundColor(isSelected ? color : KingDesignTokens.Colors.onSurfaceVariant)
                    
                    Text(title)
                        .font(KingDesignTokens.Typography.labelMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? color : KingDesignTokens.Colors.onSurface)
                }
                
                // Time Estimate
                Text(subtitle)
                    .font(KingDesignTokens.Typography.captionSmall)
                    .foregroundColor(KingDesignTokens.Colors.onSurfaceVariant)
                
                // Fee Amount
                VStack(spacing: 2) {
                    Text("\(fee) ETH")
                        .font(KingDesignTokens.Typography.labelSmall)
                        .fontWeight(.bold)
                        .foregroundColor(isSelected ? color : KingDesignTokens.Colors.onSurface)
                    
                    Text("\(gasPrice) gwei")
                        .font(KingDesignTokens.Typography.captionSmall)
                        .foregroundColor(KingDesignTokens.Colors.onSurfaceVariant)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? color.opacity(0.1) : KingDesignTokens.Colors.surface.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? color.opacity(0.6) : KingDesignTokens.Colors.outline.opacity(0.3),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Premium Transaction Preview

/// 📋 Comprehensive transaction preview with security verification
struct PremiumTransactionPreview: View {
    let recipientAddress: String
    let amount: String
    let gasSpeed: GasSpeed
    let gasFee: String
    let totalAmount: String
    let securityStatus: SecurityStatus
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "doc.text.fill")
                        .foregroundColor(KingDesignTokens.Colors.primary)
                        .font(.title3)
                    
                    Text("거래 미리보기")
                        .font(KingDesignTokens.Typography.headlineSmall)
                        .foregroundColor(KingDesignTokens.Colors.onSurface)
                }
                
                Spacer()
                
                // Security Badge
                HStack(spacing: 6) {
                    Image(systemName: securityStatus.iconName)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(securityStatus.color)
                    
                    Text(securityStatus.displayText)
                        .font(KingDesignTokens.Typography.captionSmall)
                        .fontWeight(.semibold)
                        .foregroundColor(securityStatus.color)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(securityStatus.color.opacity(0.15))
                )
            }
            
            // Transaction Details
            VStack(spacing: 0) {
                // Recipient
                TransactionDetailRow(
                    title: "받는 주소",
                    value: formatAddress(recipientAddress),
                    icon: "person.circle",
                    isAddress: true
                )
                
                Divider()
                    .background(KingDesignTokens.Colors.outline.opacity(0.3))
                
                // Send Amount
                TransactionDetailRow(
                    title: "송금 금액",
                    value: "\(amount) ETH",
                    icon: "arrow.up.circle",
                    isHighlighted: true
                )
                
                Divider()
                    .background(KingDesignTokens.Colors.outline.opacity(0.3))
                
                // Gas Fee
                TransactionDetailRow(
                    title: "네트워크 수수료",
                    value: "\(gasFee) ETH",
                    subtitle: "(\(gasSpeed.displayName))",
                    icon: "speedometer"
                )
                
                Divider()
                    .background(KingDesignTokens.Colors.outline.opacity(0.3))
                
                // Total Amount
                TransactionDetailRow(
                    title: "총 금액",
                    value: "\(totalAmount) ETH",
                    icon: "equal.circle.fill",
                    isTotal: true
                )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(KingDesignTokens.Colors.surfaceVariant.opacity(0.4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        KingDesignTokens.Colors.primary.opacity(0.3),
                                        KingDesignTokens.Colors.primary.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
        }
    }
    
    private func formatAddress(_ address: String) -> String {
        guard address.count > 10 else { return address }
        return "\(address.prefix(6))...\(address.suffix(4))"
    }
}

// MARK: - Transaction Detail Row

private struct TransactionDetailRow: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    let icon: String
    var isAddress: Bool = false
    var isHighlighted: Bool = false
    var isTotal: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isTotal ? KingDesignTokens.Colors.primary : KingDesignTokens.Colors.onSurfaceVariant)
                .frame(width: 20)
            
            // Title and Subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(isTotal ? KingDesignTokens.Typography.labelLarge : KingDesignTokens.Typography.bodyMedium)
                    .fontWeight(isTotal ? .semibold : .regular)
                    .foregroundColor(KingDesignTokens.Colors.onSurface)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(KingDesignTokens.Typography.captionSmall)
                        .foregroundColor(KingDesignTokens.Colors.onSurfaceVariant)
                }
            }
            
            Spacer()
            
            // Value
            VStack(alignment: .trailing) {
                Text(value)
                    .font(isTotal ? KingDesignTokens.Typography.titleMedium : 
                          isHighlighted ? KingDesignTokens.Typography.labelLarge : KingDesignTokens.Typography.bodyMedium)
                    .fontWeight(isTotal ? .bold : isHighlighted ? .semibold : .medium)
                    .foregroundColor(isTotal ? KingDesignTokens.Colors.primary : 
                                   isHighlighted ? KingDesignTokens.Colors.onSurface : KingDesignTokens.Colors.onSurface)
                    .font(isAddress ? .system(.caption, design: .monospaced) : .system(.body))
            }
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Premium Send Button

/// 🚀 Ultra-secure send button with biometric authentication
struct PremiumSendButton: View {
    let isEnabled: Bool
    let isProcessing: Bool
    let securityLevel: SecurityLevel
    let onSend: () -> Void
    
    @State private var glowAnimation = false
    @State private var pulseAnimation = false
    
    var body: some View {
        Button(action: onSend) {
            HStack(spacing: 12) {
                // Security Icon
                if securityLevel == .biometric {
                    Image(systemName: "faceid")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                } else if isProcessing {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.9)
                }
                
                // Button Text
                Text(buttonTitle)
                    .font(KingDesignTokens.Typography.titleMedium)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isEnabled ? 
                        LinearGradient(
                            colors: [
                                KingDesignTokens.Colors.primary,
                                KingDesignTokens.Colors.primary.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [
                                KingDesignTokens.Colors.onSurface.opacity(0.3),
                                KingDesignTokens.Colors.onSurface.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: isEnabled ? KingDesignTokens.Colors.primary.opacity(0.4) : Color.clear,
                        radius: glowAnimation ? 20 : 8,
                        x: 0,
                        y: 4
                    )
            )
            .scaleEffect(pulseAnimation ? 1.02 : 1.0)
            .disabled(!isEnabled || isProcessing)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            if isEnabled {
                startAnimations()
            }
        }
        .onChange(of: isEnabled) { oldValue, newValue in
            if newValue {
                startAnimations()
            } else {
                stopAnimations()
            }
        }
    }
    
    private var buttonTitle: String {
        if isProcessing {
            return "거래 처리 중..."
        } else if securityLevel == .biometric {
            return "생체인증으로 송금"
        } else {
            return "송금하기"
        }
    }
    
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            glowAnimation = true
        }
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseAnimation = true
        }
    }
    
    private func stopAnimations() {
        glowAnimation = false
        pulseAnimation = false
    }
}

// MARK: - Premium Transaction Success View

/// 🎉 Beautiful success animation and transaction details
struct PremiumTransactionSuccessView: View {
    let transactionHash: String
    let amount: String
    let recipient: String
    let onDone: () -> Void
    let onViewOnExplorer: () -> Void
    
    @State private var showSuccessAnimation = false
    @State private var showContent = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Success Animation
            ZStack {
                // Outer Glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.green.opacity(0.3),
                                Color.green.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: showSuccessAnimation ? 100 : 50
                        )
                    )
                    .frame(width: 200, height: 200)
                
                // Success Icon
                ZStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(showSuccessAnimation ? 1.0 : 0.5)
                .rotation3DEffect(
                    .degrees(showSuccessAnimation ? 0 : 180),
                    axis: (x: 0, y: 1, z: 0)
                )
            }
            
            if showContent {
                VStack(spacing: 16) {
                    // Success Title
                    Text("송금 완료!")
                        .font(KingDesignTokens.Typography.displaySmall)
                        .fontWeight(.bold)
                        .foregroundColor(KingDesignTokens.Colors.onSurface)
                    
                    Text("\(amount) ETH가 성공적으로 전송되었습니다")
                        .font(KingDesignTokens.Typography.bodyLarge)
                        .foregroundColor(KingDesignTokens.Colors.onSurfaceVariant)
                        .multilineTextAlignment(.center)
                    
                    // Transaction Details
                    VStack(spacing: 12) {
                        TransactionSuccessRow(title: "받는 주소", value: formatAddress(recipient))
                        TransactionSuccessRow(title: "송금 금액", value: "\(amount) ETH")
                        TransactionSuccessRow(title: "거래 해시", value: formatHash(transactionHash), isHash: true)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(KingDesignTokens.Colors.surfaceVariant.opacity(0.5))
                    )
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            Spacer()
            
            if showContent {
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: onViewOnExplorer) {
                        HStack(spacing: 8) {
                            Image(systemName: "globe")
                            Text("Etherscan에서 보기")
                        }
                        .font(KingDesignTokens.Typography.labelLarge)
                        .foregroundColor(KingDesignTokens.Colors.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(KingDesignTokens.Colors.primary, lineWidth: 1.5)
                        )
                    }
                    
                    Button(action: onDone) {
                        Text("완료")
                            .font(KingDesignTokens.Typography.titleMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                KingDesignTokens.Colors.primary,
                                                KingDesignTokens.Colors.primary.opacity(0.8)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(24)
        .background(KingDesignTokens.Colors.surface)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) {
                showSuccessAnimation = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showContent = true
                }
            }
        }
    }
    
    private func formatAddress(_ address: String) -> String {
        guard address.count > 10 else { return address }
        return "\(address.prefix(6))...\(address.suffix(4))"
    }
    
    private func formatHash(_ hash: String) -> String {
        guard hash.count > 10 else { return hash }
        return "\(hash.prefix(6))...\(hash.suffix(4))"
    }
}

// MARK: - Transaction Success Row

private struct TransactionSuccessRow: View {
    let title: String
    let value: String
    var isHash: Bool = false
    
    var body: some View {
        HStack {
            Text(title)
                .font(KingDesignTokens.Typography.bodyMedium)
                .foregroundColor(KingDesignTokens.Colors.onSurfaceVariant)
            
            Spacer()
            
            Text(value)
                .font(isHash ? .system(.caption, design: .monospaced) : KingDesignTokens.Typography.bodyMedium)
                .fontWeight(.medium)
                .foregroundColor(KingDesignTokens.Colors.onSurface)
        }
    }
}

// MARK: - Extension for GasSpeed

extension GasSpeed {
    var iconName: String {
        switch self {
        case .slow:
            return "tortoise.fill"
        case .normal:
            return "hare.fill"
        case .fast:
            return "bolt.fill"
        }
    }
    
    var displayName: String {
        switch self {
        case .slow:
            return "절약"
        case .normal:
            return "표준"
        case .fast:
            return "빠름"
        }
    }
}

// MARK: - Extension for SecurityStatus

extension SecurityStatus {
    var iconName: String {
        switch self {
        case .secure:
            return "shield.checkered"
        case .warning:
            return "exclamationmark.shield"
        case .danger:
            return "xmark.shield"
        }
    }
    
    var color: Color {
        switch self {
        case .secure:
            return .green
        case .warning:
            return .orange
        case .danger:
            return .red
        }
    }
    
    var displayText: String {
        switch self {
        case .secure:
            return "안전"
        case .warning:
            return "주의"
        case .danger:
            return "위험"
        }
    }
}

// MARK: - Security Level Enum

enum SecurityLevel {
    case basic
    case biometric
    case multiFactor
}