import SwiftUI
import DesignSystem
import Entity
import Core

@MainActor
protocol SendDisplayLogic: AnyObject {
    func displayAddressValidation(viewModel: SendScene.ValidateAddress.ViewModel)
    func displayAmountValidation(viewModel: SendScene.ValidateAmount.ViewModel)
    func displayGasEstimation(viewModel: SendScene.EstimateGas.ViewModel)
    func displayTransactionPreparation(viewModel: SendScene.PrepareTransaction.ViewModel)
    func displayTransactionResult(viewModel: SendScene.SendTransaction.ViewModel)
}

struct SendView: View {
    @State private var coordinator = SendCoordinator()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient.enhancedBackgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    recipientSection
                    amountSection
                    
                    if coordinator.showGasOptions {
                        gasFeeSection
                    }
                    
                    if coordinator.isReadyToSend {
                        confirmationSection
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
        .gesture(
            DragGesture()
                .onEnded { gesture in
                    if gesture.translation.height > 100 && abs(gesture.translation.width) < 100 {
                        dismiss()
                    }
                }
        )
        .onAppear {
            coordinator.loadInitialData()
        }
        .alert("송금 실패", isPresented: $coordinator.showErrorAlert) {
            Button("확인") { }
            if coordinator.errorSuggestion != nil {
                Button("재시도") {
                    coordinator.retryLastAction()
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
        .sheet(isPresented: $coordinator.showSuccessView) {
            SendSuccessView(transactionHash: coordinator.transactionHash)
        }
    }
}

// MARK: - Header Section

extension SendView {
    private var headerSection: some View {
        VStack(spacing: 12) {
            // 닫기 제스처 힌트
            RoundedRectangle(cornerRadius: 3)
                .fill(.secondary.opacity(0.3))
                .frame(width: 40, height: 6)
                .padding(.top, 4)
                .padding(.bottom, 16)
            
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 64, height: 64)
                
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(LinearGradient.primaryGradient)
            }
            
            Text("이더리움 송금")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 4) {
                Text("안전하게 ETH를 보내세요")
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

// MARK: - Recipient Section

extension SendView {
    private var recipientSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "person.circle")
                    .font(.title3)
                    .foregroundStyle(LinearGradient.primaryGradient)
                
                Text("받는 사람")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            HStack(spacing: 8) {
                GlassTextField(
                    text: $coordinator.recipientAddress,
                    placeholder: "이더리움 주소 입력",
                    style: .default,
                    keyboardType: .default,
                    validation: coordinator.addressValidation,
                    onEditingChanged: { _ in },
                    onSubmit: { }
                )
                .onChange(of: coordinator.recipientAddress) { _, newValue in
                    coordinator.validateRecipientAddress(newValue)
                }
                
                HStack(spacing: 8) {
                    GlassButton(icon: "qrcode.viewfinder", style: .icon) {
                        coordinator.showQRScanner()
                    }
                    .accessibilityLabel("QR 스캔")
                    .accessibilityHint("QR 코드를 스캔하여 주소를 입력합니다")
                    
                    GlassButton(icon: "person.2.fill", style: .icon) {
                        coordinator.showAddressBook()
                    }
                    .accessibilityLabel("주소록")
                    .accessibilityHint("저장된 주소 목록을 확인합니다")
                }
            }
            }
        }
        .glassCard(style: .default)
    }
}

// MARK: - Amount Section

extension SendView {
    private var amountSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "dollarsign.circle")
                    .font(.title3)
                    .foregroundStyle(LinearGradient.primaryGradient)
                
                Text("보낼 금액")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                VStack(spacing: 8) {
                    HStack {
                        TextField("0.0", text: $coordinator.amountText)
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .onChange(of: coordinator.amountText) { _, newValue in
                                coordinator.validateAmount(newValue)
                            }
                        
                        Text("ETH")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    if let usdValue = coordinator.amountInUSD {
                        Text("≈ \(usdValue)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(20)
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            coordinator.isAmountValid ? 
                            LinearGradient.primaryGradient : 
                            LinearGradient(colors: [.clear], startPoint: .leading, endPoint: .trailing),
                            lineWidth: coordinator.isAmountValid ? 1 : 0
                        )
                )
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("사용 가능한 잔액")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(coordinator.availableBalance)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    GlassButton(icon: "arrow.up.to.line", title: "최대", style: .secondary) {
                        coordinator.setMaxAmount()
                    }
                }
                
                if coordinator.showAmountError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                        
                        Text(coordinator.amountErrorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .glassCard(style: .default)
    }
}

// MARK: - Gas Fee Section

extension SendView {
    private var gasFeeSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "fuelpump")
                    .font(.title3)
                    .foregroundStyle(LinearGradient.warningGradient)
                
                Text("가스비 (네트워크 수수료)")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            if let gasOptions = coordinator.gasOptions {
                VStack(spacing: 12) {
                    GasFeeOptionView(
                        priority: .slow,
                        gasFee: gasOptions.slow,
                        isSelected: coordinator.selectedGasPriority == .slow
                    ) {
                        coordinator.selectGasFee(.slow, gasFee: gasOptions.slow)
                    }
                    
                    GasFeeOptionView(
                        priority: .normal,
                        gasFee: gasOptions.normal,
                        isSelected: coordinator.selectedGasPriority == .normal
                    ) {
                        coordinator.selectGasFee(.normal, gasFee: gasOptions.normal)
                    }
                    
                    GasFeeOptionView(
                        priority: .fast,
                        gasFee: gasOptions.fast,
                        isSelected: coordinator.selectedGasPriority == .fast
                    ) {
                        coordinator.selectGasFee(.fast, gasFee: gasOptions.fast)
                    }
                }
            } else {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("가스비 계산 중...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(16)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
            }
        }
        .glassCard(style: .default)
    }
}

// MARK: - Confirmation Section

extension SendView {
    private var confirmationSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "checkmark.shield")
                    .font(.title3)
                    .foregroundStyle(LinearGradient.primaryGradient)
                
                Text("거래 요약")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                ConfirmationRow(
                    title: "받는 사람",
                    value: coordinator.formattedRecipientAddress,
                    showCopy: true
                ) {
                    coordinator.copyRecipientAddress()
                }
                
                ConfirmationRow(
                    title: "보낼 금액",
                    value: coordinator.formattedAmount
                )
                
                if let selectedGasFee = coordinator.selectedGasFee {
                    ConfirmationRow(
                        title: "가스비",
                        value: "\(selectedGasFee.formattedFeeETH) (\(selectedGasFee.formattedFeeUSD))"
                    )
                }
                
                Divider()
                    .background(.secondary.opacity(0.3))
                
                ConfirmationRow(
                    title: "총 금액",
                    value: coordinator.totalAmount,
                    valueStyle: .prominent
                )
                
                if let totalUSD = coordinator.totalAmountUSD {
                    Text("≈ \(totalUSD)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Button {
                coordinator.sendTransaction()
            } label: {
                HStack(spacing: 8) {
                    if coordinator.isSending {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16, weight: .medium))
                    }
                    
                    Text(coordinator.isSending ? "전송 중..." : "🔒 Face ID로 송금하기")
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    coordinator.isSending ? 
                    AnyShapeStyle(Color.secondary.opacity(0.3)) : 
                    AnyShapeStyle(LinearGradient.primaryGradient)
                )
                .foregroundColor(.white)
                .cornerRadius(16)
                .shadow(
                    color: coordinator.isSending ? .clear : .kingBlue.opacity(0.3), 
                    radius: coordinator.isSending ? 0 : 8, 
                    x: 0, 
                    y: coordinator.isSending ? 0 : 4
                )
            }
            .disabled(coordinator.isSending)
            .scaleEffect(coordinator.isSending ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: coordinator.isSending)
        }
        .glassCard(style: .prominent)
    }
}

// MARK: - Gas Fee Option View

struct GasFeeOptionView: View {
    let priority: GasPriority
    let gasFee: GasFee
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: priority.icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? AnyShapeStyle(LinearGradient.primaryGradient) : AnyShapeStyle(.secondary))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(priority.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(priority.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(gasFee.formattedFeeETH)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 4) {
                        Text(gasFee.formattedFeeUSD)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(gasFee.formattedTime)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(16)
            .background(
                isSelected ? 
                AnyShapeStyle(LinearGradient.primaryGradient.opacity(0.1)) : 
                AnyShapeStyle(Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? 
                        AnyShapeStyle(LinearGradient.primaryGradient) : 
                        AnyShapeStyle(Color.secondary.opacity(0.3)),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Confirmation Row

struct ConfirmationRow: View {
    let title: String
    let value: String
    let valueStyle: ValueStyle
    let showCopy: Bool
    let copyAction: (() -> Void)?
    
    enum ValueStyle {
        case normal
        case prominent
    }
    
    init(title: String, value: String, valueStyle: ValueStyle = .normal, showCopy: Bool = false, copyAction: (() -> Void)? = nil) {
        self.title = title
        self.value = value
        self.valueStyle = valueStyle
        self.showCopy = showCopy
        self.copyAction = copyAction
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            HStack(spacing: 8) {
                Text(value)
                    .font(valueStyle == .prominent ? .headline : .subheadline)
                    .fontWeight(valueStyle == .prominent ? .semibold : .medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if showCopy {
                    Button {
                        copyAction?()
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    SendView()
}
