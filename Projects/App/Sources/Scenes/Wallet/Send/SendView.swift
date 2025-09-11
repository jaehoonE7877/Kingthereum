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
}

// MARK: - Send View Store

@MainActor
final class SendViewStore: ObservableObject, SendDisplayLogic {
    // MARK: - Published Properties
    @Published var currentStep: SendStep = .enterRecipient
    @Published var recipientAddress = ""
    @Published var amount = ""
    @Published var selectedGasPriority: GasPriority = .normal
    @Published var gasOptions: GasOptions?
    @Published var pendingTransaction: PendingTransaction?
    
    // Validation States
    @Published var isAddressValid = false
    @Published var isAmountValid = false
    @Published var addressErrorMessage: String?
    @Published var amountErrorMessage: String?
    
    // UI States
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var showSuccess = false
    @Published var transactionHash: String?
    
    // MARK: - VIP Components
    var interactor: SendBusinessLogic?
    var router: SendRoutingLogic?
    
    // MARK: - Display Logic Implementation
    
    func displayAddressValidation(viewModel: SendScene.ValidateAddress.ViewModel) {
        isAddressValid = viewModel.isValid
        addressErrorMessage = viewModel.errorMessage
        showError = viewModel.showError
        
        if viewModel.isValid {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                currentStep = .enterAmount
            }
        }
    }
    
    func displayAmountValidation(viewModel: SendScene.ValidateAmount.ViewModel) {
        isAmountValid = viewModel.isValid
        amountErrorMessage = viewModel.errorMessage
        
        if viewModel.isValid {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                currentStep = .selectGasFee
            }
        }
    }
    
    func displayGasEstimation(viewModel: SendScene.EstimateGas.ViewModel) {
        gasOptions = viewModel.gasOptions
        errorMessage = viewModel.errorMessage ?? ""
        showError = viewModel.showError
        
        if viewModel.gasOptions != nil {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                currentStep = .confirmTransaction
            }
        }
    }
    
    func displayTransactionPreparation(viewModel: SendScene.PrepareTransaction.ViewModel) {
        pendingTransaction = viewModel.transaction
        errorMessage = viewModel.errorMessage ?? ""
        showError = viewModel.showError
        
        if viewModel.isReadyToSend {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                currentStep = .authenticating
            }
        }
    }
    
    func displayTransactionResult(viewModel: SendScene.SendTransaction.ViewModel) {
        showSuccess = viewModel.showSuccess
        showError = viewModel.showError
        errorMessage = viewModel.errorMessage ?? ""
        transactionHash = viewModel.transactionHash
        
        if viewModel.success {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                currentStep = .completed
            }
        } else {
            currentStep = .failed
        }
    }
}

// MARK: - Send View

struct SendView: View {
    @StateObject private var viewStore = SendViewStore()
    @Environment(\.dismiss) private var dismiss
    @State private var keyboardHeight: CGFloat = 0
    @State private var showQRScanner = false
    
    var body: some View {
        ZStack {
            // Premium gradient background
            LinearGradient(
                colors: [
                    KingDesignTokens.Colors.background,
                    KingDesignTokens.Colors.background.opacity(0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Glassmorphism decoration elements
            GeometryReader { geometry in
                Circle()
                    .fill(KingDesignTokens.Colors.accent.opacity(0.05))
                    .blur(radius: 100)
                    .frame(width: 300, height: 300)
                    .position(x: geometry.size.width * 0.8, y: geometry.size.height * 0.2)
                
                Circle()
                    .fill(KingDesignTokens.Colors.primary.opacity(0.03))
                    .blur(radius: 120)
                    .frame(width: 400, height: 400)
                    .position(x: geometry.size.width * 0.2, y: geometry.size.height * 0.8)
            }
            
            VStack(spacing: 0) {
                // Premium Navigation Bar
                navigationBar
                
                // Progress Indicator
                progressIndicator
                    .padding(.horizontal, KingDesignTokens.Spacing.l)
                    .padding(.vertical, KingDesignTokens.Spacing.m)
                
                // Main Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: KingDesignTokens.Spacing.xl) {
                        // Step Content
                        stepContent
                            .padding(.horizontal, KingDesignTokens.Spacing.l)
                            .padding(.top, KingDesignTokens.Spacing.l)
                        
                        Spacer(minLength: 100)
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: viewStore.currentStep)
                
                // Bottom Action Button
                if viewStore.currentStep != .completed && viewStore.currentStep != .failed {
                    bottomActionButton
                        .padding(.horizontal, KingDesignTokens.Spacing.l)
                        .padding(.bottom, KingDesignTokens.Spacing.l)
                }
            }
        }
        .onAppear {
            setupVIP()
            observeKeyboard()
        }
        .sheet(isPresented: $showQRScanner) {
            QRScannerView { address in
                if let address = address {
                    viewStore.recipientAddress = address
                    validateAddress()
                }
                showQRScanner = false
            }
        }
    }
    
    // MARK: - Navigation Bar
    
    private var navigationBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(KingDesignTokens.Colors.primaryText)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(KingDesignTokens.Colors.surface)
                            .overlay(
                                Circle()
                                    .stroke(KingDesignTokens.Colors.border, lineWidth: 1)
                            )
                    )
            }
            
            Spacer()
            
            Text("송금")
                .font(KingDesignTokens.Typography.heading)
                .foregroundColor(KingDesignTokens.Colors.primaryText)
            
            Spacer()
            
            // Placeholder for symmetry
            Color.clear
                .frame(width: 40, height: 40)
        }
        .padding(.horizontal, KingDesignTokens.Spacing.l)
        .padding(.vertical, KingDesignTokens.Spacing.m)
        .background(
            KingDesignTokens.Effects.glassMorphism(
                cornerRadius: 0,
                material: .ultraThin
            )
        )
    }
    
    // MARK: - Progress Indicator
    
    private var progressIndicator: some View {
        HStack(spacing: KingDesignTokens.Spacing.s) {
            ForEach([SendStep.enterRecipient, .enterAmount, .selectGasFee, .confirmTransaction], id: \.self) { step in
                progressStep(for: step)
            }
        }
        .padding(.vertical, KingDesignTokens.Spacing.xs)
    }
    
    private func progressStep(for step: SendStep) -> some View {
        let isActive = viewStore.currentStep.rawValue >= step.rawValue
        let isCurrent = viewStore.currentStep == step
        
        return RoundedRectangle(cornerRadius: 2)
            .fill(
                isActive
                    ? KingDesignTokens.Colors.accent
                    : KingDesignTokens.Colors.border
            )
            .frame(height: 4)
            .scaleEffect(isCurrent ? CGSize(width: 1, height: 1.5) : CGSize(width: 1, height: 1))
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isCurrent)
    }
    
    // MARK: - Step Content
    
    @ViewBuilder
    private var stepContent: some View {
        switch viewStore.currentStep {
        case .enterRecipient:
            recipientStepView
        case .enterAmount:
            amountStepView
        case .selectGasFee:
            gasSelectionView
        case .confirmTransaction:
            confirmationView
        case .authenticating:
            authenticatingView
        case .sending:
            sendingView
        case .completed:
            completedView
        case .failed:
            failedView
        }
    }
    
    // MARK: - Recipient Step
    
    private var recipientStepView: some View {
        VStack(alignment: .leading, spacing: KingDesignTokens.Spacing.m) {
            Text("받는 사람")
                .font(KingDesignTokens.Typography.displayM)
                .foregroundColor(KingDesignTokens.Colors.primaryText)
            
            Text("이더리움 주소를 입력하세요")
                .font(KingDesignTokens.Typography.body)
                .foregroundColor(KingDesignTokens.Colors.secondaryText)
            
            // Premium Input Field with Glassmorphism
            VStack(spacing: KingDesignTokens.Spacing.xs) {
                HStack {
                    TextField("0x...", text: $viewStore.recipientAddress)
                        .font(KingDesignTokens.Typography.mono)
                        .foregroundColor(KingDesignTokens.Colors.primaryText)
                        .textFieldStyle(.plain)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    Button(action: { showQRScanner = true }) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 20))
                            .foregroundColor(KingDesignTokens.Colors.accent)
                    }
                }
                .padding(KingDesignTokens.Spacing.m)
                .background(
                    RoundedRectangle(cornerRadius: KingDesignTokens.Radius.m)
                        .fill(KingDesignTokens.Colors.surfaceSecondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: KingDesignTokens.Radius.m)
                                .stroke(
                                    viewStore.addressErrorMessage != nil
                                        ? KingDesignTokens.Colors.error
                                        : KingDesignTokens.Colors.border,
                                    lineWidth: 1
                                )
                        )
                )
                
                if let error = viewStore.addressErrorMessage {
                    Text(error)
                        .font(KingDesignTokens.Typography.caption)
                        .foregroundColor(KingDesignTokens.Colors.error)
                }
            }
        }
    }
    
    // MARK: - Amount Step
    
    private var amountStepView: some View {
        VStack(alignment: .leading, spacing: KingDesignTokens.Spacing.m) {
            Text("금액")
                .font(KingDesignTokens.Typography.displayM)
                .foregroundColor(KingDesignTokens.Colors.primaryText)
            
            Text("보낼 ETH 수량을 입력하세요")
                .font(KingDesignTokens.Typography.body)
                .foregroundColor(KingDesignTokens.Colors.secondaryText)
            
            // Premium Amount Input
            VStack(spacing: KingDesignTokens.Spacing.xs) {
                HStack {
                    TextField("0.0", text: $viewStore.amount)
                        .font(KingDesignTokens.Typography.displayL)
                        .foregroundColor(KingDesignTokens.Colors.primaryText)
                        .textFieldStyle(.plain)
                        .keyboardType(.decimalPad)
                    
                    Text("ETH")
                        .font(KingDesignTokens.Typography.heading)
                        .foregroundColor(KingDesignTokens.Colors.secondaryText)
                }
                .padding(KingDesignTokens.Spacing.m)
                .background(
                    RoundedRectangle(cornerRadius: KingDesignTokens.Radius.m)
                        .fill(KingDesignTokens.Colors.surfaceSecondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: KingDesignTokens.Radius.m)
                                .stroke(
                                    viewStore.amountErrorMessage != nil
                                        ? KingDesignTokens.Colors.error
                                        : KingDesignTokens.Colors.border,
                                    lineWidth: 1
                                )
                        )
                )
                
                if let error = viewStore.amountErrorMessage {
                    Text(error)
                        .font(KingDesignTokens.Typography.caption)
                        .foregroundColor(KingDesignTokens.Colors.error)
                }
            }
        }
    }
    
    // MARK: - Gas Selection
    
    private var gasSelectionView: some View {
        VStack(alignment: .leading, spacing: KingDesignTokens.Spacing.m) {
            Text("가스비 선택")
                .font(KingDesignTokens.Typography.displayM)
                .foregroundColor(KingDesignTokens.Colors.primaryText)
            
            Text("거래 처리 속도를 선택하세요")
                .font(KingDesignTokens.Typography.body)
                .foregroundColor(KingDesignTokens.Colors.secondaryText)
            
            VStack(spacing: KingDesignTokens.Spacing.s) {
                ForEach(GasPriority.allCases, id: \.self) { priority in
                    gasOptionCard(for: priority)
                }
            }
        }
    }
    
    private func gasOptionCard(for priority: GasPriority) -> some View {
        let isSelected = viewStore.selectedGasPriority == priority
        let gasFee = getGasFee(for: priority)
        
        return Button(action: { viewStore.selectedGasPriority = priority }) {
            HStack {
                VStack(alignment: .leading, spacing: KingDesignTokens.Spacing.xs) {
                    HStack {
                        Image(systemName: priority.icon)
                            .font(.system(size: 16))
                        Text(priority.title)
                            .font(KingDesignTokens.Typography.heading)
                    }
                    .foregroundColor(isSelected ? KingDesignTokens.Colors.accent : KingDesignTokens.Colors.primaryText)
                    
                    Text(priority.description)
                        .font(KingDesignTokens.Typography.caption)
                        .foregroundColor(KingDesignTokens.Colors.secondaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: KingDesignTokens.Spacing.xs) {
                    Text(gasFee?.formattedFeeETH ?? "계산 중...")
                        .font(KingDesignTokens.Typography.body)
                        .foregroundColor(KingDesignTokens.Colors.primaryText)
                    
                    Text(gasFee?.formattedTime ?? "")
                        .font(KingDesignTokens.Typography.caption)
                        .foregroundColor(KingDesignTokens.Colors.secondaryText)
                }
            }
            .padding(KingDesignTokens.Spacing.m)
            .background(
                RoundedRectangle(cornerRadius: KingDesignTokens.Radius.m)
                    .fill(isSelected ? KingDesignTokens.Colors.accent.opacity(0.1) : KingDesignTokens.Colors.surfaceSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: KingDesignTokens.Radius.m)
                            .stroke(
                                isSelected ? KingDesignTokens.Colors.accent : KingDesignTokens.Colors.border,
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
    }
    
    // MARK: - Confirmation View
    
    private var confirmationView: some View {
        VStack(spacing: KingDesignTokens.Spacing.l) {
            Text("거래 확인")
                .font(KingDesignTokens.Typography.displayM)
                .foregroundColor(KingDesignTokens.Colors.primaryText)
            
            // Glassmorphism Card for Transaction Details
            VStack(spacing: KingDesignTokens.Spacing.m) {
                transactionDetailRow(label: "받는 사람", value: formatAddress(viewStore.recipientAddress))
                Divider().foregroundColor(KingDesignTokens.Colors.border)
                transactionDetailRow(label: "금액", value: "\(viewStore.amount) ETH")
                Divider().foregroundColor(KingDesignTokens.Colors.border)
                transactionDetailRow(label: "가스비", value: getSelectedGasFee()?.formattedFeeETH ?? "")
                Divider().foregroundColor(KingDesignTokens.Colors.border)
                transactionDetailRow(label: "총 금액", value: calculateTotal(), isTotal: true)
            }
            .padding(KingDesignTokens.Spacing.l)
            .background(
                KingDesignTokens.Effects.glassMorphism(
                    cornerRadius: KingDesignTokens.Radius.l,
                    material: .thin
                )
            )
        }
    }
    
    private func transactionDetailRow(label: String, value: String, isTotal: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(isTotal ? KingDesignTokens.Typography.heading : KingDesignTokens.Typography.body)
                .foregroundColor(KingDesignTokens.Colors.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(isTotal ? KingDesignTokens.Typography.heading : KingDesignTokens.Typography.body)
                .foregroundColor(isTotal ? KingDesignTokens.Colors.accent : KingDesignTokens.Colors.primaryText)
        }
    }
    
    // MARK: - Authenticating View
    
    private var authenticatingView: some View {
        VStack(spacing: KingDesignTokens.Spacing.l) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(KingDesignTokens.Colors.accent)
            
            Text("생체 인증 중...")
                .font(KingDesignTokens.Typography.heading)
                .foregroundColor(KingDesignTokens.Colors.primaryText)
        }
        .padding(KingDesignTokens.Spacing.xxl)
    }
    
    // MARK: - Sending View
    
    private var sendingView: some View {
        VStack(spacing: KingDesignTokens.Spacing.l) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(KingDesignTokens.Colors.accent)
            
            Text("거래 처리 중...")
                .font(KingDesignTokens.Typography.heading)
                .foregroundColor(KingDesignTokens.Colors.primaryText)
            
            Text("잠시만 기다려주세요")
                .font(KingDesignTokens.Typography.body)
                .foregroundColor(KingDesignTokens.Colors.secondaryText)
        }
        .padding(KingDesignTokens.Spacing.xxl)
    }
    
    // MARK: - Completed View
    
    private var completedView: some View {
        VStack(spacing: KingDesignTokens.Spacing.l) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(KingDesignTokens.Colors.success)
            
            Text("송금 완료!")
                .font(KingDesignTokens.Typography.displayM)
                .foregroundColor(KingDesignTokens.Colors.primaryText)
            
            if let hash = viewStore.transactionHash {
                Text(formatAddress(hash))
                    .font(KingDesignTokens.Typography.mono)
                    .foregroundColor(KingDesignTokens.Colors.secondaryText)
            }
            
            Button(action: { dismiss() }) {
                Text("완료")
                    .font(KingDesignTokens.Typography.heading)
                    .foregroundColor(KingDesignTokens.Colors.onPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(KingDesignTokens.Spacing.m)
                    .background(
                        RoundedRectangle(cornerRadius: KingDesignTokens.Radius.m)
                            .fill(KingDesignTokens.Colors.accent)
                    )
            }
        }
        .padding(KingDesignTokens.Spacing.xxl)
    }
    
    // MARK: - Failed View
    
    private var failedView: some View {
        VStack(spacing: KingDesignTokens.Spacing.l) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(KingDesignTokens.Colors.error)
            
            Text("송금 실패")
                .font(KingDesignTokens.Typography.displayM)
                .foregroundColor(KingDesignTokens.Colors.primaryText)
            
            Text(viewStore.errorMessage)
                .font(KingDesignTokens.Typography.body)
                .foregroundColor(KingDesignTokens.Colors.secondaryText)
                .multilineTextAlignment(.center)
            
            Button(action: { viewStore.currentStep = .enterRecipient }) {
                Text("다시 시도")
                    .font(KingDesignTokens.Typography.heading)
                    .foregroundColor(KingDesignTokens.Colors.onPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(KingDesignTokens.Spacing.m)
                    .background(
                        RoundedRectangle(cornerRadius: KingDesignTokens.Radius.m)
                            .fill(KingDesignTokens.Colors.accent)
                    )
            }
        }
        .padding(KingDesignTokens.Spacing.xxl)
    }
    
    // MARK: - Bottom Action Button
    
    private var bottomActionButton: some View {
        Button(action: handleNextAction) {
            HStack {
                Text(actionButtonTitle)
                    .font(KingDesignTokens.Typography.heading)
                
                if viewStore.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(KingDesignTokens.Colors.onPrimary)
                }
            }
            .foregroundColor(KingDesignTokens.Colors.onPrimary)
            .frame(maxWidth: .infinity)
            .padding(KingDesignTokens.Spacing.m)
            .background(
                RoundedRectangle(cornerRadius: KingDesignTokens.Radius.m)
                    .fill(
                        isActionButtonEnabled
                            ? KingDesignTokens.Colors.accent
                            : KingDesignTokens.Colors.disabled
                    )
            )
        }
        .disabled(!isActionButtonEnabled || viewStore.isLoading)
    }
    
    private var actionButtonTitle: String {
        switch viewStore.currentStep {
        case .enterRecipient:
            return "다음"
        case .enterAmount:
            return "다음"
        case .selectGasFee:
            return "다음"
        case .confirmTransaction:
            return "송금하기"
        default:
            return ""
        }
    }
    
    private var isActionButtonEnabled: Bool {
        switch viewStore.currentStep {
        case .enterRecipient:
            return !viewStore.recipientAddress.isEmpty
        case .enterAmount:
            return !viewStore.amount.isEmpty
        case .selectGasFee:
            return true
        case .confirmTransaction:
            return viewStore.pendingTransaction != nil || true  // Allow proceeding for demo
        default:
            return false
        }
    }
    
    // MARK: - Actions
    
    private func handleNextAction() {
        switch viewStore.currentStep {
        case .enterRecipient:
            validateAddress()
        case .enterAmount:
            validateAmount()
        case .selectGasFee:
            estimateGas()
        case .confirmTransaction:
            prepareTransaction()
        default:
            break
        }
    }
    
    private func validateAddress() {
        Task {
            let request = SendScene.ValidateAddress.Request(address: viewStore.recipientAddress)
            await viewStore.interactor?.validateAddress(request: request)
        }
    }
    
    private func validateAmount() {
        Task {
            let request = SendScene.ValidateAmount.Request(
                amount: viewStore.amount,
                availableBalance: "10.0"  // Mock balance
            )
            await viewStore.interactor?.validateAmount(request: request)
        }
    }
    
    private func estimateGas() {
        Task {
            let request = SendScene.EstimateGas.Request(
                recipientAddress: viewStore.recipientAddress,
                amount: viewStore.amount,
                gasFeeLevel: viewStore.selectedGasPriority
            )
            await viewStore.interactor?.estimateGas(request: request)
        }
    }
    
    private func prepareTransaction() {
        Task {
            guard let selectedGasFee = getSelectedGasFee() else { return }
            
            let request = SendScene.PrepareTransaction.Request(
                recipientAddress: viewStore.recipientAddress,
                amount: viewStore.amount,
                selectedGasFee: selectedGasFee
            )
            await viewStore.interactor?.prepareTransaction(request: request)
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupVIP() {
        let interactor = SendInteractor()
        let presenter = SendPresenter()
        let router = SendRouter(coordinator: EmptyCoordinator())
        
        viewStore.interactor = interactor
        viewStore.router = router
        interactor.presenter = presenter
        presenter.viewController = viewStore
        router.viewController = viewStore
        router.dataStore = interactor
    }
    
    private func getGasFee(for priority: GasPriority) -> GasFee? {
        guard let options = viewStore.gasOptions else {
            // Return mock data for UI preview
            switch priority {
            case .slow:
                return GasFee(gasPrice: "10", estimatedTime: 600, feeInETH: 0.001, feeInUSD: 2.5)
            case .normal:
                return GasFee(gasPrice: "20", estimatedTime: 180, feeInETH: 0.002, feeInUSD: 5.0)
            case .fast:
                return GasFee(gasPrice: "30", estimatedTime: 60, feeInETH: 0.003, feeInUSD: 7.5)
            }
        }
        
        switch priority {
        case .slow: return options.slow
        case .normal: return options.normal
        case .fast: return options.fast
        }
    }
    
    private func getSelectedGasFee() -> GasFee? {
        return getGasFee(for: viewStore.selectedGasPriority)
    }
    
    private func calculateTotal() -> String {
        guard let amount = Decimal(string: viewStore.amount),
              let gasFee = getSelectedGasFee() else {
            return "계산 중..."
        }
        
        let total = amount + gasFee.feeInETH
        return String(format: "%.6f ETH", NSDecimalNumber(decimal: total).doubleValue)
    }
    
    private func formatAddress(_ address: String) -> String {
        guard address.count > 10 else { return address }
        let prefix = String(address.prefix(6))
        let suffix = String(address.suffix(4))
        return "\(prefix)...\(suffix)"
    }
    
    private func observeKeyboard() {
        // Keyboard observation logic
    }
}

// MARK: - Empty Coordinator (Temporary)

private final class EmptyCoordinator: SendCoordinatorProtocol {
    func navigateToSuccess(data: SendSuccessData) {}
    func presentQRScanner(completion: @escaping (String?) -> Void) {}
    func presentAddressBook(completion: @escaping (String?) -> Void) {}
    func presentBiometricAuth(for transaction: PendingTransaction, completion: @escaping (Bool) -> Void) {}
    func navigateToTransactionDetail(hash: String) {}
    func presentGasSettings(completion: @escaping (GasFee?) -> Void) {}
    func dismissCurrentView() {}
}

// MARK: - Send Step Extension

extension SendStep {
    var rawValue: Int {
        switch self {
        case .enterRecipient: return 0
        case .enterAmount: return 1
        case .selectGasFee: return 2
        case .confirmTransaction: return 3
        case .authenticating: return 4
        case .sending: return 5
        case .completed: return 6
        case .failed: return 7
        }
    }
}

// MARK: - Preview

struct SendView_Previews: PreviewProvider {
    static var previews: some View {
        SendView()
    }
}