import SwiftUI
import DesignSystem
import Entity
import WalletKit
import SecurityKit
import Factory
import Combine

// MARK: - Premium Send View with Real-Time Balance

/// Premium Send Interface with Real-Time Balance Display and Enhanced Security
/// Features: Live balance updates, glassmorphism design, comprehensive security
@MainActor
struct PremiumSendView: View {
    @StateObject private var coordinator = PremiumSendCoordinator()
    @StateObject private var balanceMonitor = RealTimeBalanceMonitor()
    @Environment(\.dismiss) private var dismiss
    
    // Animation states
    @State private var appearanceAnimation = false
    @State private var balanceUpdateAnimation = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Premium glassmorphism background
                KingDesignTokens.Gradients.minimalistBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Premium header with real-time balance
                        premiumHeaderSection(geometry: geometry)
                            .padding(.bottom, 32)
                        
                        // Send form with glassmorphism design
                        sendFormSection
                            .padding(.horizontal, 20)
                            .padding(.bottom, 120) // Bottom action area space
                    }
                }
                .refreshable {
                    await coordinator.refreshData()
                }
                
                // Bottom action area
                bottomActionArea
                    .ignoresSafeArea(edges: .bottom)
                
                // Security overlay
                if coordinator.securityStatus != .secure {
                    securityOverlay
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                appearanceAnimation = true
            }
        }
        .task {
            await coordinator.loadInitialData()
            await balanceMonitor.startMonitoring()
        }
        .onDisappear {
            Task {
                await balanceMonitor.stopMonitoring()
            }
        }
        .alert("보안 알림", isPresented: .constant(coordinator.securityAlerts.count > 0)) {
            ForEach(coordinator.securityAlerts, id: \.id) { alert in
                Button("확인") {
                    coordinator.dismissSecurityAlert(alert)
                }
            }
        } message: {
            if let firstAlert = coordinator.securityAlerts.first {
                Text(firstAlert.message)
                    .font(KingDesignTokens.Typography.bodyMedium)
            }
        }
        .sheet(isPresented: $coordinator.showTransactionSuccess) {
            PremiumTransactionSuccessView(
                transactionHash: coordinator.lastTransactionHash,
                amount: coordinator.amount,
                recipient: coordinator.recipientAddress
            )
        }
    }
    
    // MARK: - Premium Header with Real-Time Balance
    
    @ViewBuilder
    private func premiumHeaderSection(geometry: GeometryProxy) -> some View {
        VStack(spacing: 24) {
            // Dismiss gesture indicator
            RoundedRectangle(cornerRadius: 2.5)
                .fill(KingDesignTokens.Colors.outline.opacity(0.4))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
            
            // Premium balance card with live updates
            realTimeBalanceCard
                .scaleEffect(appearanceAnimation ? 1.0 : 0.95)
                .opacity(appearanceAnimation ? 1.0 : 0.7)
                .animation(.spring(response: 0.8, dampingFraction: 0.8), value: appearanceAnimation)
            
            // Send title and security status
            VStack(spacing: 12) {
                HStack {
                    Text("이더리움 송금")
                        .font(KingDesignTokens.Typography.displaySmall)
                        .fontWeight(.bold)
                        .foregroundColor(KingDesignTokens.Colors.primary)
                    
                    Spacer()
                    
                    // Security status indicator
                    securityStatusIndicator
                }
                
                Text("안전하고 빠른 ETH 전송")
                    .font(KingDesignTokens.Typography.bodyMedium)
                    .foregroundColor(KingDesignTokens.Colors.onSurface)
                    .opacity(0.8)
            }
            .padding(.horizontal, 20)
        }
    }
    
    @ViewBuilder
    private var realTimeBalanceCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("현재 잔액")
                        .font(KingDesignTokens.Typography.labelMedium)
                        .foregroundColor(KingDesignTokens.Colors.onSurface)
                        .opacity(0.7)
                    
                    HStack(spacing: 8) {
                        Text(balanceMonitor.formattedBalance)
                            .font(KingDesignTokens.Typography.headlineLarge)
                            .fontWeight(.bold)
                            .foregroundColor(KingDesignTokens.Colors.primary)
                            .scaleEffect(balanceUpdateAnimation ? 1.05 : 1.0)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: balanceUpdateAnimation)
                        
                        Text("ETH")
                            .font(KingDesignTokens.Typography.labelLarge)
                            .fontWeight(.semibold)
                            .foregroundColor(KingDesignTokens.Colors.tertiary)
                        
                        if balanceMonitor.isUpdating {
                            ProgressView()
                                .scaleEffect(0.7)
                                .progressViewStyle(CircularProgressViewStyle(tint: KingDesignTokens.Colors.primary))
                        }
                    }
                    
                    Text(balanceMonitor.formattedBalanceUSD)
                        .font(KingDesignTokens.Typography.bodySmall)
                        .foregroundColor(KingDesignTokens.Colors.onSurface)
                        .opacity(0.6)
                }
                
                Spacer()
                
                // Balance trend indicator
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: balanceMonitor.priceChangeIcon)
                            .font(.caption)
                            .foregroundColor(balanceMonitor.priceChangeColor)
                        
                        Text(balanceMonitor.priceChangeText)
                            .font(KingDesignTokens.Typography.caption)
                            .foregroundColor(balanceMonitor.priceChangeColor)
                    }
                    
                    Text("24시간")
                        .font(KingDesignTokens.Typography.caption)
                        .foregroundColor(KingDesignTokens.Colors.onSurface)
                        .opacity(0.5)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(KingDesignTokens.Gradients.surfaceGradient)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(KingDesignTokens.Gradients.borderGradient, lineWidth: 1)
            )
            .shadow(
                color: KingDesignTokens.Colors.shadow.opacity(0.1),
                radius: 12,
                x: 0,
                y: 4
            )
        }
        .padding(.horizontal, 20)
        .onChange(of: balanceMonitor.balance) { _, _ in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                balanceUpdateAnimation.toggle()
            }
        }
    }
    
    @ViewBuilder
    private var securityStatusIndicator: some View {
        HStack(spacing: 6) {
            Image(systemName: coordinator.securityStatus.icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(coordinator.securityStatus.color)
            
            Text(coordinator.securityStatus.displayName)
                .font(KingDesignTokens.Typography.caption)
                .foregroundColor(coordinator.securityStatus.color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(coordinator.securityStatus.color.opacity(0.1))
        )
        .overlay(
            Capsule()
                .stroke(coordinator.securityStatus.color.opacity(0.3), lineWidth: 0.5)
        )
    }
    
    // MARK: - Send Form Section
    
    @ViewBuilder
    private var sendFormSection: some View {
        VStack(spacing: 24) {
            // Recipient address input
            recipientAddressSection
            
            // Amount input with balance validation
            amountInputSection
            
            // Gas fee selector
            gasFeeSection
            
            // Transaction preview
            if coordinator.showTransactionPreview {
                transactionPreviewSection
            }
        }
    }
    
    @ViewBuilder
    private var recipientAddressSection: some View {
        VStack(spacing: 16) {
            SectionHeader(
                title: "받는 사람 주소",
                subtitle: "ETH를 보낼 주소를 입력하세요",
                icon: "person.circle.fill"
            )
            
            PremiumAddressInput(
                address: $coordinator.recipientAddress,
                validation: coordinator.addressValidation,
                onQRScan: { coordinator.showQRScanner = true },
                onAddressBook: { coordinator.showAddressBook = true },
                onPaste: coordinator.pasteFromClipboard
            )
            
            if coordinator.addressValidation.showSuggestions {
                addressSuggestions
            }
        }
    }
    
    @ViewBuilder
    private var amountInputSection: some View {
        VStack(spacing: 16) {
            SectionHeader(
                title: "송금 금액",
                subtitle: "전송할 ETH 금액을 입력하세요",
                icon: "bitcoinsign.circle.fill"
            )
            
            PremiumAmountInput(
                amount: $coordinator.amount,
                availableBalance: balanceMonitor.balance,
                formattedBalance: balanceMonitor.formattedBalance,
                usdValue: coordinator.amountUSD,
                validation: coordinator.amountValidation,
                onMaxAmount: coordinator.setMaxAmount,
                onPercentage: coordinator.setPercentageAmount
            )
        }
    }
    
    @ViewBuilder
    private var gasFeeSection: some View {
        VStack(spacing: 16) {
            SectionHeader(
                title: "네트워크 수수료",
                subtitle: "거래 처리 속도를 선택하세요",
                icon: "speedometer"
            )
            
            PremiumGasFeeSelector(
                selectedLevel: $coordinator.selectedGasFee,
                gasEstimates: coordinator.gasEstimates,
                isEstimating: coordinator.isEstimatingGas,
                onEstimate: coordinator.estimateGasFees
            )
        }
    }
    
    @ViewBuilder
    private var transactionPreviewSection: some View {
        VStack(spacing: 16) {
            SectionHeader(
                title: "거래 요약",
                subtitle: "송금 정보를 확인하세요",
                icon: "doc.text.fill"
            )
            
            PremiumTransactionPreview(
                recipient: coordinator.recipientAddress,
                amount: coordinator.amount,
                gasEstimate: coordinator.selectedGasEstimate,
                totalAmount: coordinator.totalAmount,
                estimatedTime: coordinator.estimatedTransactionTime
            )
        }
    }
    
    @ViewBuilder
    private var addressSuggestions: some View {
        VStack(spacing: 8) {
            ForEach(coordinator.addressSuggestions, id: \.address) { suggestion in
                AddressSuggestionRow(
                    suggestion: suggestion,
                    onSelect: { coordinator.selectAddress(suggestion.address) }
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(KingDesignTokens.Colors.surface.opacity(0.8))
                )
        )
        .transition(.scale.combined(with: .opacity))
    }
    
    // MARK: - Bottom Action Area
    
    @ViewBuilder
    private var bottomActionArea: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 16) {
                // Security validation status
                if coordinator.securityValidation.isRequired {
                    securityValidationPrompt
                }
                
                // Send button
                PremiumSendButton(
                    title: coordinator.sendButtonTitle,
                    isEnabled: coordinator.canSend,
                    isLoading: coordinator.isSending,
                    securityLevel: coordinator.securityStatus,
                    onSend: coordinator.initiateTransaction
                )
                .disabled(!coordinator.canSend)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 34) // Safe area bottom
            .background(
                LinearGradient(
                    colors: [
                        Color.clear,
                        KingDesignTokens.Colors.background.opacity(0.8),
                        KingDesignTokens.Colors.background
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(edges: .bottom)
            )
        }
    }
    
    @ViewBuilder
    private var securityValidationPrompt: some View {
        HStack(spacing: 12) {
            Image(systemName: "shield.checkered")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(KingDesignTokens.Colors.warning)
            
            Text("생체 인증이 필요합니다")
                .font(KingDesignTokens.Typography.bodySmall)
                .foregroundColor(KingDesignTokens.Colors.onSurface)
            
            Spacer()
            
            Button("인증") {
                Task {
                    await coordinator.performSecurityValidation()
                }
            }
            .font(KingDesignTokens.Typography.labelMedium)
            .foregroundColor(KingDesignTokens.Colors.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(KingDesignTokens.Colors.warning.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(KingDesignTokens.Colors.warning.opacity(0.3), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private var securityOverlay: some View {
        Rectangle()
            .fill(Color.black.opacity(0.4))
            .ignoresSafeArea()
            .onTapGesture {
                coordinator.dismissSecurityOverlay()
            }
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String
    let subtitle: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(KingDesignTokens.Colors.primary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(KingDesignTokens.Typography.labelLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(KingDesignTokens.Colors.primary)
                
                Text(subtitle)
                    .font(KingDesignTokens.Typography.bodySmall)
                    .foregroundColor(KingDesignTokens.Colors.onSurface)
                    .opacity(0.7)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

struct AddressSuggestionRow: View {
    let suggestion: AddressSuggestion
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: suggestion.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(KingDesignTokens.Colors.primary)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(suggestion.name)
                        .font(KingDesignTokens.Typography.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(KingDesignTokens.Colors.primary)
                    
                    Text(suggestion.shortAddress)
                        .font(KingDesignTokens.Typography.caption)
                        .foregroundColor(KingDesignTokens.Colors.onSurface)
                        .opacity(0.6)
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(KingDesignTokens.Colors.onSurface)
                    .opacity(0.4)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Real-Time Balance Monitor

@MainActor
final class RealTimeBalanceMonitor: ObservableObject {
    @Published var balance: Double = 0.0
    @Published var balanceUSD: Double = 0.0
    @Published var ethereumPrice: Double = 0.0
    @Published var priceChange24h: Double = 0.0
    @Published var isUpdating: Bool = false
    
    private var updateTimer: Timer?
    private let updateInterval: TimeInterval = 5.0 // 5 seconds
    
    var formattedBalance: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 4
        formatter.maximumFractionDigits = 6
        return formatter.string(from: NSNumber(value: balance)) ?? "0.0000"
    }
    
    var formattedBalanceUSD: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: balanceUSD)) ?? "$0.00"
    }
    
    var priceChangeIcon: String {
        priceChange24h >= 0 ? "arrow.up.right" : "arrow.down.right"
    }
    
    var priceChangeColor: Color {
        priceChange24h >= 0 ? KingDesignTokens.Colors.success : KingDesignTokens.Colors.error
    }
    
    var priceChangeText: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 2
        let percentage = abs(priceChange24h / 100)
        return formatter.string(from: NSNumber(value: percentage)) ?? "0%"
    }
    
    func startMonitoring() async {
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.updateBalance()
            }
        }
        
        // Initial update
        await updateBalance()
    }
    
    func stopMonitoring() async {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    @MainActor
    private func updateBalance() async {
        isUpdating = true
        defer { isUpdating = false }
        
        do {
            // Mock implementation - replace with actual wallet service
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
            
            // Simulate balance updates
            balance = Double.random(in: 1.5...5.2)
            ethereumPrice = Double.random(in: 2800...3200)
            priceChange24h = Double.random(in: -5.0...5.0)
            balanceUSD = balance * ethereumPrice
            
        } catch {
            print("Failed to update balance: \(error)")
        }
    }
}

// MARK: - Supporting Types

struct AddressSuggestion {
    let name: String
    let address: String
    let icon: String
    
    var shortAddress: String {
        String(address.prefix(6)) + "..." + String(address.suffix(4))
    }
}

// MARK: - Preview

#Preview("Premium Send View") {
    PremiumSendView()
        .preferredColorScheme(.dark)
}