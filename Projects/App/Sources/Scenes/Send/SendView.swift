import SwiftUI
import Entity
import DesignSystem
import Core

// MARK: - Display Logic Protocol

@MainActor
protocol SendDisplayLogic: AnyObject {
    func displayAddressValidation(viewModel: SendScene.ValidateAddress.ViewModel)
    func displayAmountValidation(viewModel: SendScene.ValidateAmount.ViewModel)
    func displayGasEstimation(viewModel: SendScene.EstimateGas.ViewModel)
    func displayTransactionPreparation(viewModel: SendScene.PrepareTransaction.ViewModel)
    func displayTransactionResult(viewModel: SendScene.SendTransaction.ViewModel)
    func displayETHPrice(ethPrice: Decimal)
}

// MARK: - Send View Store

@MainActor
@Observable
final class SendViewStore: SendDisplayLogic {
    // MARK: - State Properties
    var currentStep: SendStep = .enterRecipient
    var recipientAddress = ""
    var amount = ""
    var selectedGasPriority: GasPriority = .normal
    var gasOptions: GasOptions?
    var pendingTransaction: PendingTransaction?
    var ethPriceUSD: Decimal = 0
    
    // Validation States
    var isAddressValid = false
    var isAmountValid = false
    var addressErrorMessage: String?
    var amountErrorMessage: String?
    
    // UI States
    var isLoading = false
    var showError = false
    var errorMessage = ""
    var showSuccess = false
    var transactionHash: String?
    
    // Amount input toggle
    var isAmountInUSD = false
    var userBalance: Decimal = 0
    
    // MARK: - VIP Components
    var interactor: SendBusinessLogic?
    var router: SendRoutingLogic?
    
    init() {
        setupVIP()
        loadUserBalance()
        loadETHPrice()
    }
    
    private func setupVIP() {
        let interactor = SendInteractor()
        let presenter = SendPresenter()
        let router = SendRouter()
        
        self.interactor = interactor
        self.router = router
        
        interactor.presenter = presenter
        presenter.viewController = self
    }
    
    private func loadUserBalance() {
        // Load user's ETH balance (mock for now)
        userBalance = 1.5 // Example balance
    }
    
    private func loadETHPrice() {
        // Load current ETH price (mock for now)
        ethPriceUSD = 2500.0 // Example price
    }
    
    // MARK: - Display Logic Implementation
    
    func displayAddressValidation(viewModel: SendScene.ValidateAddress.ViewModel) {
        isAddressValid = viewModel.isValid
        addressErrorMessage = viewModel.errorMessage
        showError = viewModel.showError
        
        if viewModel.isValid && !amount.isEmpty && isAmountValid {
            estimateGas()
        }
    }
    
    func displayAmountValidation(viewModel: SendScene.ValidateAmount.ViewModel) {
        isAmountValid = viewModel.isValid
        amountErrorMessage = viewModel.errorMessage
        
        if viewModel.isValid && !recipientAddress.isEmpty && isAddressValid {
            estimateGas()
        }
    }
    
    func displayGasEstimation(viewModel: SendScene.EstimateGas.ViewModel) {
        isLoading = false
        gasOptions = viewModel.gasOptions
        errorMessage = viewModel.errorMessage ?? ""
        showError = viewModel.showError
    }
    
    func displayTransactionPreparation(viewModel: SendScene.PrepareTransaction.ViewModel) {
        pendingTransaction = viewModel.transaction
        errorMessage = viewModel.errorMessage ?? ""
        showError = viewModel.showError
        
        if viewModel.isReadyToSend {
            currentStep = .authenticating
        }
    }
    
    func displayTransactionResult(viewModel: SendScene.SendTransaction.ViewModel) {
        isLoading = false
        showSuccess = viewModel.showSuccess
        showError = viewModel.showError
        errorMessage = viewModel.errorMessage ?? ""
        transactionHash = viewModel.transactionHash
        
        if viewModel.success {
            currentStep = .completed
        } else {
            currentStep = .failed
        }
    }
    
    func displayETHPrice(ethPrice: Decimal) {
        ethPriceUSD = ethPrice
    }
    
    // MARK: - User Actions
    
    func validateAddress() {
        guard !recipientAddress.isEmpty else { return }
        
        let request = SendScene.ValidateAddress.Request(address: recipientAddress)
        interactor?.validateAddress(request: request)
    }
    
    func validateAmount() {
        guard !amount.isEmpty else { return }
        
        let balanceString = String(describing: userBalance)
        let request = SendScene.ValidateAmount.Request(
            amount: amount,
            availableBalance: balanceString
        )
        interactor?.validateAmount(request: request)
    }
    
    func estimateGas() {
        guard isAddressValid && isAmountValid else { return }
        
        isLoading = true
        let request = SendScene.EstimateGas.Request(
            recipientAddress: recipientAddress,
            amount: amount,
            gasFeeLevel: selectedGasPriority
        )
        interactor?.estimateGas(request: request)
    }
    
    func prepareTransaction() {
        guard let gasOptions = gasOptions else { return }
        
        let selectedGasFee: GasFee
        switch selectedGasPriority {
        case .slow: selectedGasFee = gasOptions.slow
        case .normal: selectedGasFee = gasOptions.normal
        case .fast: selectedGasFee = gasOptions.fast
        }
        
        let request = SendScene.PrepareTransaction.Request(
            recipientAddress: recipientAddress,
            amount: amount,
            selectedGasFee: selectedGasFee
        )
        interactor?.prepareTransaction(request: request)
    }
    
    func sendTransaction() {
        guard let pendingTransaction = pendingTransaction else { return }
        
        isLoading = true
        currentStep = .sending
        
        let request = SendScene.SendTransaction.Request(transaction: pendingTransaction)
        interactor?.sendTransaction(request: request)
    }
    
    func toggleAmountCurrency() {
        isAmountInUSD.toggle()
        
        // Convert the current amount to the other currency
        if let amountDecimal = Decimal(string: amount) {
            if isAmountInUSD {
                // Convert ETH to USD
                let usdAmount = amountDecimal * ethPriceUSD
                amount = String(format: "%.2f", NSDecimalNumber(decimal: usdAmount).doubleValue)
            } else {
                // Convert USD to ETH
                let ethAmount = amountDecimal / ethPriceUSD
                amount = String(format: "%.6f", NSDecimalNumber(decimal: ethAmount).doubleValue)
            }
        }
    }
    
    func setMaxAmount() {
        // Set maximum available balance (minus estimated gas fee)
        let estimatedGasFee: Decimal = 0.005 // Example gas fee
        let maxAmount = max(0, userBalance - estimatedGasFee)
        
        if isAmountInUSD {
            let usdAmount = maxAmount * ethPriceUSD
            amount = String(format: "%.2f", NSDecimalNumber(decimal: usdAmount).doubleValue)
        } else {
            amount = String(format: "%.6f", NSDecimalNumber(decimal: maxAmount).doubleValue)
        }
        
        validateAmount()
    }
    
    func goBack() {
        switch currentStep {
        case .enterAmount:
            currentStep = .enterRecipient
        case .selectGasFee:
            currentStep = .enterAmount
        case .confirmTransaction:
            currentStep = .selectGasFee
        case .authenticating:
            currentStep = .confirmTransaction
        default:
            break
        }
    }
    
    func resetSend() {
        currentStep = .enterRecipient
        recipientAddress = ""
        amount = ""
        selectedGasPriority = .normal
        gasOptions = nil
        pendingTransaction = nil
        isAddressValid = false
        isAmountValid = false
        addressErrorMessage = nil
        amountErrorMessage = nil
        showError = false
        showSuccess = false
        transactionHash = nil
    }
}

// MARK: - Main Send View

struct SendView: View {
    @State private var viewStore = SendViewStore()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                KingDesignTokens.Colors.background
                    .ignoresSafeArea()
                
                // Content based on current step
                Group {
                    switch viewStore.currentStep {
                    case .enterRecipient:
                        EnterRecipientView(viewStore: viewStore)
                    case .enterAmount:
                        EnterAmountView(viewStore: viewStore)
                    case .selectGasFee:
                        SelectGasFeeView(viewStore: viewStore)
                    case .confirmTransaction:
                        ConfirmTransactionView(viewStore: viewStore)
                    case .authenticating, .sending:
                        SendingView(viewStore: viewStore)
                    case .completed:
                        TransactionCompletedView(viewStore: viewStore)
                    case .failed:
                        TransactionFailedView(viewStore: viewStore)
                    }
                }
                
                // Error overlay
                if viewStore.showError {
                    ErrorOverlay(
                        message: viewStore.errorMessage,
                        onDismiss: {
                            viewStore.showError = false
                        }
                    )
                }
            }
            .navigationTitle("ETH 보내기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if viewStore.currentStep != .enterRecipient {
                        Button {
                            viewStore.goBack()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(KingDesignTokens.Colors.primaryText)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(KingDesignTokens.Colors.primaryText)
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewStore.currentStep)
    }
}

// MARK: - Step Views

private struct EnterRecipientView: View {
    @Bindable var viewStore: SendViewStore
    
    var body: some View {
        VStack(spacing: KingDesignTokens.Spacing.xl) {
            // Progress indicator
            ProgressIndicator(currentStep: 1, totalSteps: 4)
                .padding(.top, KingDesignTokens.Spacing.lg)
            
            Spacer()
            
            VStack(spacing: KingDesignTokens.Spacing.lg) {
                VStack(spacing: KingDesignTokens.Spacing.md) {
                    Text("받는 사람")
                        .font(KingDesignTokens.Typography.heading)
                        .fontWeight(.semibold)
                        .foregroundColor(KingDesignTokens.Colors.primaryText)
                    
                    Text("이더리움 주소를 입력하세요")
                        .font(KingDesignTokens.Typography.body)
                        .foregroundColor(KingDesignTokens.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: KingDesignTokens.Spacing.sm) {
                    KingTextField(
                        "0x...",
                        text: $viewStore.recipientAddress,
                        style: .outlined
                    )
                    .onChange(of: viewStore.recipientAddress) {
                        viewStore.validateAddress()
                    }
                    
                    if let errorMessage = viewStore.addressErrorMessage {
                        HStack {
                            Text(errorMessage)
                                .font(KingDesignTokens.Typography.caption)
                                .foregroundColor(KingDesignTokens.Colors.error)
                            Spacer()
                        }
                    }
                }
                
                // Quick actions
                VStack(spacing: KingDesignTokens.Spacing.sm) {
                    KingButton(
                        "QR 코드 스캔",
                        style: .secondary,
                        size: .medium
                    ) {
                        // TODO: Implement QR scanning
                    }
                    
                    KingButton(
                        "주소록에서 선택",
                        style: .secondary,
                        size: .medium
                    ) {
                        // TODO: Implement address book
                    }
                }
            }
            
            Spacer()
            
            // Next button
            KingButton(
                "다음",
                style: .primary,
                size: .large,
                isLoading: viewStore.isLoading
            ) {
                if viewStore.isAddressValid {
                    viewStore.currentStep = .enterAmount
                }
            }
            .disabled(!viewStore.isAddressValid)
            .padding(.horizontal, KingDesignTokens.Spacing.lg)
            .padding(.bottom, KingDesignTokens.Spacing.xl)
        }
    }
}

private struct EnterAmountView: View {
    @Bindable var viewStore: SendViewStore
    
    var body: some View {
        VStack(spacing: KingDesignTokens.Spacing.xl) {
            // Progress indicator
            ProgressIndicator(currentStep: 2, totalSteps: 4)
                .padding(.top, KingDesignTokens.Spacing.lg)
            
            Spacer()
            
            VStack(spacing: KingDesignTokens.Spacing.lg) {
                VStack(spacing: KingDesignTokens.Spacing.md) {
                    Text("보낼 금액")
                        .font(KingDesignTokens.Typography.heading)
                        .fontWeight(.semibold)
                        .foregroundColor(KingDesignTokens.Colors.primaryText)
                    
                    Text("보내실 ETH 금액을 입력하세요")
                        .font(KingDesignTokens.Typography.body)
                        .foregroundColor(KingDesignTokens.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                
                // Amount input with currency toggle
                VStack(spacing: KingDesignTokens.Spacing.md) {
                    HStack {
                        TextField("0", text: $viewStore.amount)
                            .font(KingDesignTokens.Typography.displayM)
                            .fontWeight(.semibold)
                            .foregroundColor(KingDesignTokens.Colors.primaryText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .onChange(of: viewStore.amount) {
                                viewStore.validateAmount()
                            }
                        
                        Button(action: viewStore.toggleAmountCurrency) {
                            Text(viewStore.isAmountInUSD ? "USD" : "ETH")
                                .font(KingDesignTokens.Typography.bodyLarge)
                                .fontWeight(.medium)
                                .foregroundColor(KingDesignTokens.Colors.accent)
                                .padding(.horizontal, KingDesignTokens.Spacing.md)
                                .padding(.vertical, KingDesignTokens.Spacing.sm)
                                .background(KingDesignTokens.Colors.accent.opacity(0.1))
                                .cornerRadius(KingDesignTokens.Radius.sm)
                        }
                    }
                    
                    // Converted amount display
                    if !viewStore.amount.isEmpty,
                       let amountDecimal = Decimal(string: viewStore.amount) {
                        let convertedAmount = viewStore.isAmountInUSD 
                            ? amountDecimal / viewStore.ethPriceUSD
                            : amountDecimal * viewStore.ethPriceUSD
                        
                        Text(viewStore.isAmountInUSD 
                             ? String(format: "≈ %.6f ETH", NSDecimalNumber(decimal: convertedAmount).doubleValue)
                             : String(format: "≈ $%.2f", NSDecimalNumber(decimal: convertedAmount).doubleValue))
                            .font(KingDesignTokens.Typography.body)
                            .foregroundColor(KingDesignTokens.Colors.secondaryText)
                    }
                    
                    if let errorMessage = viewStore.amountErrorMessage {
                        Text(errorMessage)
                            .font(KingDesignTokens.Typography.caption)
                            .foregroundColor(KingDesignTokens.Colors.error)
                    }
                }
                
                // Balance info and MAX button
                VStack(spacing: KingDesignTokens.Spacing.sm) {
                    HStack {
                        Text("사용 가능:")
                            .font(KingDesignTokens.Typography.body)
                            .foregroundColor(KingDesignTokens.Colors.secondaryText)
                        
                        Text(String(format: "%.6f ETH", NSDecimalNumber(decimal: viewStore.userBalance).doubleValue))
                            .font(KingDesignTokens.Typography.body)
                            .fontWeight(.medium)
                            .foregroundColor(KingDesignTokens.Colors.primaryText)
                        
                        Spacer()
                        
                        Button("MAX") {
                            viewStore.setMaxAmount()
                        }
                        .font(KingDesignTokens.Typography.labelMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(KingDesignTokens.Colors.accent)
                        .padding(.horizontal, KingDesignTokens.Spacing.sm)
                        .padding(.vertical, KingDesignTokens.Spacing.xs)
                        .background(KingDesignTokens.Colors.accent.opacity(0.1))
                        .cornerRadius(KingDesignTokens.Radius.sm)
                    }
                }
            }
            
            Spacer()
            
            // Next button
            KingButton(
                "다음",
                style: .primary,
                size: .large,
                isLoading: viewStore.isLoading
            ) {
                if viewStore.isAmountValid {
                    viewStore.currentStep = .selectGasFee
                }
            }
            .disabled(!viewStore.isAmountValid || viewStore.isLoading)
            .padding(.horizontal, KingDesignTokens.Spacing.lg)
            .padding(.bottom, KingDesignTokens.Spacing.xl)
        }
    }
}

private struct SelectGasFeeView: View {
    @Bindable var viewStore: SendViewStore
    
    var body: some View {
        VStack(spacing: KingDesignTokens.Spacing.xl) {
            // Progress indicator
            ProgressIndicator(currentStep: 3, totalSteps: 4)
                .padding(.top, KingDesignTokens.Spacing.lg)
            
            Spacer()
            
            VStack(spacing: KingDesignTokens.Spacing.lg) {
                VStack(spacing: KingDesignTokens.Spacing.md) {
                    Text("가스비 선택")
                        .font(KingDesignTokens.Typography.heading)
                        .fontWeight(.semibold)
                        .foregroundColor(KingDesignTokens.Colors.primaryText)
                    
                    Text("트랜잭션 처리 속도를 선택하세요")
                        .font(KingDesignTokens.Typography.body)
                        .foregroundColor(KingDesignTokens.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                
                if let gasOptions = viewStore.gasOptions {
                    VStack(spacing: KingDesignTokens.Spacing.md) {
                        GasFeeOptionCard(
                            option: .slow,
                            gasFee: gasOptions.slow,
                            isSelected: viewStore.selectedGasPriority == .slow
                        ) {
                            viewStore.selectedGasPriority = .slow
                        }
                        
                        GasFeeOptionCard(
                            option: .normal,
                            gasFee: gasOptions.normal,
                            isSelected: viewStore.selectedGasPriority == .normal
                        ) {
                            viewStore.selectedGasPriority = .normal
                        }
                        
                        GasFeeOptionCard(
                            option: .fast,
                            gasFee: gasOptions.fast,
                            isSelected: viewStore.selectedGasPriority == .fast
                        ) {
                            viewStore.selectedGasPriority = .fast
                        }
                    }
                } else if viewStore.isLoading {
                    ProgressView("가스비 계산 중...")
                        .font(KingDesignTokens.Typography.body)
                        .foregroundColor(KingDesignTokens.Colors.secondaryText)
                        .padding(.vertical, KingDesignTokens.Spacing.xxl)
                }
            }
            
            Spacer()
            
            // Next button
            KingButton(
                "다음",
                style: .primary,
                size: .large
            ) {
                viewStore.currentStep = .confirmTransaction
            }
            .disabled(viewStore.gasOptions == nil)
            .padding(.horizontal, KingDesignTokens.Spacing.lg)
            .padding(.bottom, KingDesignTokens.Spacing.xl)
        }
        .onAppear {
            if viewStore.gasOptions == nil {
                viewStore.estimateGas()
            }
        }
    }
}

private struct ConfirmTransactionView: View {
    @Bindable var viewStore: SendViewStore
    
    var body: some View {
        VStack(spacing: KingDesignTokens.Spacing.xl) {
            // Progress indicator
            ProgressIndicator(currentStep: 4, totalSteps: 4)
                .padding(.top, KingDesignTokens.Spacing.lg)
            
            Spacer()
            
            VStack(spacing: KingDesignTokens.Spacing.lg) {
                VStack(spacing: KingDesignTokens.Spacing.md) {
                    Text("거래 확인")
                        .font(KingDesignTokens.Typography.heading)
                        .fontWeight(.semibold)
                        .foregroundColor(KingDesignTokens.Colors.primaryText)
                    
                    Text("거래 내용을 확인하고 전송하세요")
                        .font(KingDesignTokens.Typography.body)
                        .foregroundColor(KingDesignTokens.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                
                // Transaction summary
                VStack(spacing: KingDesignTokens.Spacing.md) {
                    TransactionSummaryCard(viewStore: viewStore)
                }
            }
            
            Spacer()
            
            // Send button
            KingButton(
                "전송하기",
                style: .primary,
                size: .large
            ) {
                viewStore.prepareTransaction()
            }
            .padding(.horizontal, KingDesignTokens.Spacing.lg)
            .padding(.bottom, KingDesignTokens.Spacing.xl)
        }
    }
}

private struct SendingView: View {
    let viewStore: SendViewStore
    
    var body: some View {
        VStack(spacing: KingDesignTokens.Spacing.xl) {
            Spacer()
            
            VStack(spacing: KingDesignTokens.Spacing.lg) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: KingDesignTokens.Colors.accent))
                    .scaleEffect(1.5)
                
                Text(viewStore.currentStep == .authenticating ? "인증 중..." : "전송 중...")
                    .font(KingDesignTokens.Typography.heading)
                    .fontWeight(.medium)
                    .foregroundColor(KingDesignTokens.Colors.primaryText)
                
                Text("잠시만 기다려주세요")
                    .font(KingDesignTokens.Typography.body)
                    .foregroundColor(KingDesignTokens.Colors.secondaryText)
            }
            
            Spacer()
        }
    }
}

private struct TransactionCompletedView: View {
    let viewStore: SendViewStore
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: KingDesignTokens.Spacing.xl) {
            Spacer()
            
            VStack(spacing: KingDesignTokens.Spacing.lg) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(KingDesignTokens.Colors.success)
                
                Text("전송 완료!")
                    .font(KingDesignTokens.Typography.displayM)
                    .fontWeight(.bold)
                    .foregroundColor(KingDesignTokens.Colors.primaryText)
                
                if let hash = viewStore.transactionHash {
                    VStack(spacing: KingDesignTokens.Spacing.sm) {
                        Text("트랜잭션 해시")
                            .font(KingDesignTokens.Typography.body)
                            .foregroundColor(KingDesignTokens.Colors.secondaryText)
                        
                        Text(hash.prefix(10) + "..." + hash.suffix(10))
                            .font(KingDesignTokens.Typography.mono)
                            .foregroundColor(KingDesignTokens.Colors.primaryText)
                            .padding(.horizontal, KingDesignTokens.Spacing.md)
                            .padding(.vertical, KingDesignTokens.Spacing.sm)
                            .background(KingDesignTokens.Colors.surfaceSecondary)
                            .cornerRadius(KingDesignTokens.Radius.sm)
                    }
                }
            }
            
            Spacer()
            
            VStack(spacing: KingDesignTokens.Spacing.md) {
                KingButton(
                    "다른 거래하기",
                    style: .primary,
                    size: .large
                ) {
                    viewStore.resetSend()
                }
                
                KingButton(
                    "닫기",
                    style: .secondary,
                    size: .large
                ) {
                    dismiss()
                }
            }
            .padding(.horizontal, KingDesignTokens.Spacing.lg)
            .padding(.bottom, KingDesignTokens.Spacing.xl)
        }
    }
}

private struct TransactionFailedView: View {
    let viewStore: SendViewStore
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: KingDesignTokens.Spacing.xl) {
            Spacer()
            
            VStack(spacing: KingDesignTokens.Spacing.lg) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(KingDesignTokens.Colors.error)
                
                Text("전송 실패")
                    .font(KingDesignTokens.Typography.displayM)
                    .fontWeight(.bold)
                    .foregroundColor(KingDesignTokens.Colors.primaryText)
                
                Text(viewStore.errorMessage)
                    .font(KingDesignTokens.Typography.body)
                    .foregroundColor(KingDesignTokens.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            VStack(spacing: KingDesignTokens.Spacing.md) {
                KingButton(
                    "다시 시도",
                    style: .primary,
                    size: .large
                ) {
                    viewStore.currentStep = .confirmTransaction
                }
                
                KingButton(
                    "닫기",
                    style: .secondary,
                    size: .large
                ) {
                    dismiss()
                }
            }
            .padding(.horizontal, KingDesignTokens.Spacing.lg)
            .padding(.bottom, KingDesignTokens.Spacing.xl)
        }
    }
}

// MARK: - Supporting Views

private struct ProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        HStack(spacing: KingDesignTokens.Spacing.sm) {
            ForEach(1...totalSteps, id: \.self) { step in
                Circle()
                    .frame(width: 8, height: 8)
                    .foregroundColor(
                        step <= currentStep 
                            ? KingDesignTokens.Colors.accent
                            : KingDesignTokens.Colors.disabled
                    )
                
                if step < totalSteps {
                    Rectangle()
                        .frame(width: 20, height: 2)
                        .foregroundColor(
                            step < currentStep 
                                ? KingDesignTokens.Colors.accent
                                : KingDesignTokens.Colors.disabled
                        )
                }
            }
        }
    }
}

private struct GasFeeOptionCard: View {
    let option: GasPriority
    let gasFee: GasFee
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: KingDesignTokens.Spacing.xs) {
                    HStack {
                        Image(systemName: option.icon)
                            .font(.system(size: 16, weight: .medium))
                        Text(option.title)
                            .font(KingDesignTokens.Typography.bodyLarge)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(isSelected ? KingDesignTokens.Colors.accent : KingDesignTokens.Colors.primaryText)
                    
                    Text(option.description)
                        .font(KingDesignTokens.Typography.caption)
                        .foregroundColor(KingDesignTokens.Colors.secondaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: KingDesignTokens.Spacing.xs) {
                    Text(gasFee.formattedFeeETH)
                        .font(KingDesignTokens.Typography.body)
                        .fontWeight(.medium)
                        .foregroundColor(KingDesignTokens.Colors.primaryText)
                    
                    Text(gasFee.formattedTime)
                        .font(KingDesignTokens.Typography.caption)
                        .foregroundColor(KingDesignTokens.Colors.secondaryText)
                }
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(KingDesignTokens.Colors.accent)
                }
            }
            .padding(KingDesignTokens.Spacing.md)
            .background(isSelected ? KingDesignTokens.Colors.accent.opacity(0.1) : KingDesignTokens.Colors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: KingDesignTokens.Radius.md)
                    .stroke(
                        isSelected ? KingDesignTokens.Colors.accent : KingDesignTokens.Colors.border,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .cornerRadius(KingDesignTokens.Radius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct TransactionSummaryCard: View {
    let viewStore: SendViewStore
    
    var body: some View {
        VStack(spacing: KingDesignTokens.Spacing.md) {
            // Recipient
            SendTransactionRow(
                title: "받는 사람",
                value: viewStore.recipientAddress.prefix(10) + "..." + viewStore.recipientAddress.suffix(10),
                isMonospace: true
            )
            
            // Amount
            if let amountDecimal = Decimal(string: viewStore.amount) {
                let usdValue = amountDecimal * viewStore.ethPriceUSD
                SendTransactionRow(
                    title: "보낼 금액",
                    value: "\(viewStore.amount) ETH",
                    subtitle: String(format: "$%.2f", NSDecimalNumber(decimal: usdValue).doubleValue)
                )
            }
            
            // Gas fee
            if let gasOptions = viewStore.gasOptions {
                let selectedGas: GasFee = {
                    switch viewStore.selectedGasPriority {
                    case .slow: return gasOptions.slow
                    case .normal: return gasOptions.normal  
                    case .fast: return gasOptions.fast
                    }
                }()
                
                SendTransactionRow(
                    title: "가스비",
                    value: selectedGas.formattedFeeETH,
                    subtitle: selectedGas.formattedFeeUSD
                )
            }
            
            Divider()
                .foregroundColor(KingDesignTokens.Colors.border)
            
            // Total
            if let amountDecimal = Decimal(string: viewStore.amount),
               let gasOptions = viewStore.gasOptions {
                let selectedGas: GasFee = {
                    switch viewStore.selectedGasPriority {
                    case .slow: return gasOptions.slow
                    case .normal: return gasOptions.normal  
                    case .fast: return gasOptions.fast
                    }
                }()
                
                let totalETH = amountDecimal + selectedGas.feeInETH
                let totalUSD = totalETH * viewStore.ethPriceUSD
                
                SendTransactionRow(
                    title: "총 금액",
                    value: String(format: "%.6f ETH", NSDecimalNumber(decimal: totalETH).doubleValue),
                    subtitle: String(format: "$%.2f", NSDecimalNumber(decimal: totalUSD).doubleValue),
                    isTotal: true
                )
            }
        }
        .padding(KingDesignTokens.Spacing.md)
        .background(KingDesignTokens.Colors.surface)
        .cornerRadius(KingDesignTokens.Radius.lg)
        .shadow(KingDesignTokens.Shadow.sm)
    }
}

private struct SendTransactionRow: View {
    let title: String
    let value: String
    let subtitle: String?
    let isMonospace: Bool
    let isTotal: Bool
    
    init(title: String, value: String, subtitle: String? = nil, isMonospace: Bool = false, isTotal: Bool = false) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.isMonospace = isMonospace
        self.isTotal = isTotal
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(isTotal ? KingDesignTokens.Typography.bodyLarge : KingDesignTokens.Typography.body)
                .fontWeight(isTotal ? .semibold : .regular)
                .foregroundColor(KingDesignTokens.Colors.secondaryText)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(value)
                    .font(isTotal ? KingDesignTokens.Typography.bodyLarge : (isMonospace ? KingDesignTokens.Typography.mono : KingDesignTokens.Typography.body))
                    .fontWeight(isTotal ? .semibold : .medium)
                    .foregroundColor(KingDesignTokens.Colors.primaryText)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(KingDesignTokens.Typography.caption)
                        .foregroundColor(KingDesignTokens.Colors.secondaryText)
                }
            }
        }
    }
}

private struct ErrorOverlay: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }
            
            VStack(spacing: KingDesignTokens.Spacing.lg) {
                Text("오류")
                    .font(KingDesignTokens.Typography.heading)
                    .fontWeight(.semibold)
                    .foregroundColor(KingDesignTokens.Colors.error)
                
                Text(message)
                    .font(KingDesignTokens.Typography.body)
                    .foregroundColor(KingDesignTokens.Colors.primaryText)
                    .multilineTextAlignment(.center)
                
                KingButton(
                    "확인",
                    style: .primary,
                    size: .medium
                ) {
                    onDismiss()
                }
            }
            .padding(KingDesignTokens.Spacing.lg)
            .background(KingDesignTokens.Colors.background)
            .cornerRadius(KingDesignTokens.Radius.lg)
            .padding(.horizontal, KingDesignTokens.Spacing.lg)
        }
    }
}
