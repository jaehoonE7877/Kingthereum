import SwiftUI
import DesignSystem
import Entity
import Core
import Factory

/// Phase 2.4-1: 프리미엄 핀테크 SendView - VIP 아키텍처 완전 구현
/// Modern Minimalism + Premium Fintech + Glassmorphism 3요소 완전 적용

// MARK: - VIP Architecture Protocols

/// 송금 화면의 디스플레이 로직을 정의하는 프로토콜
@MainActor
protocol SendDisplayLogic: AnyObject {
    func displayAddressValidation(viewModel: SendScene.ValidateAddress.ViewModel)
    func displayAmountValidation(viewModel: SendScene.ValidateAmount.ViewModel)
    func displayGasEstimation(viewModel: SendScene.EstimateGas.ViewModel)
    func displayTransactionPreparation(viewModel: SendScene.PrepareTransaction.ViewModel)
    func displayTransactionResult(viewModel: SendScene.SendTransaction.ViewModel)
    func displayBiometricAuthResult(viewModel: SendScene.BiometricAuth.ViewModel)
    func displayQRScanner(viewModel: SendScene.QRScanner.ViewModel)
}

/// 송금 화면의 비즈니스 로직을 정의하는 프로토콜
protocol SendBusinessLogic {
    func validateAddress(request: SendScene.ValidateAddress.Request)
    func validateAmount(request: SendScene.ValidateAmount.Request)
    func estimateGas(request: SendScene.EstimateGas.Request)
    func prepareTransaction(request: SendScene.PrepareTransaction.Request)
    func sendTransaction(request: SendScene.SendTransaction.Request)
    func authenticateWithBiometrics(request: SendScene.BiometricAuth.Request)
    func scanQRCode(request: SendScene.QRScanner.Request)
}

/// 송금 화면의 데이터 전달을 정의하는 프로토콜
protocol SendDataPassing {
    var dataStore: SendDataStore? { get }
}

/// 송금 화면의 라우팅을 정의하는 프로토콜
protocol SendRoutingLogic {
    func routeToSuccess(transactionHash: String)
    func routeToQRScanner()
    func routeToAddressBook()
    func routeToBiometricAuth()
}

/// 송금 화면의 데이터 저장소
protocol SendDataStore {
    var recipientAddress: String { get set }
    var amount: String { get set }
    var selectedGasFee: GasFeeLevel { get set }
    var transactionHash: String? { get set }
    var wallet: Entity.Wallet? { get set }
}

// MARK: - Models

/// 가스비 옵션
enum GasFeeLevel: String, CaseIterable {
    case slow = "느림"
    case standard = "보통"  
    case fast = "빠름"
    
    var icon: String {
        switch self {
        case .slow: return "tortoise.fill"
        case .standard: return "hare.fill"
        case .fast: return "bolt.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .slow: return KingColors.success
        case .standard: return KingColors.info
        case .fast: return KingColors.warning
        }
    }
}

// MARK: - ViewStore

/// SwiftUI용 Send ViewStore (DisplayLogic 구현)
@MainActor
@Observable
final class SendViewStore: SendDisplayLogic {
    // UI State
    var recipientAddress = ""
    var amount = ""
    var selectedGasFee: GasFeeLevel = .standard
    var estimatedGas = ""
    var isLoading = false
    var errorMessage: String?
    var showQRScanner = false
    var showAddressBook = false
    var showBiometricAuth = false
    var showSuccessView = false
    var transactionHash: String?
    
    // Validation States  
    var isAddressValid = false
    var isAmountValid = false
    var addressValidationMessage = ""
    var amountValidationMessage = ""
    
    // Step Management
    var currentStep: SendStep = .address
    var canProceedToAmount: Bool { isAddressValid && !recipientAddress.isEmpty }
    var canProceedToConfirmation: Bool { canProceedToAmount && isAmountValid && !amount.isEmpty }
    
    enum SendStep: Int, CaseIterable {
        case address = 0
        case amount = 1  
        case confirmation = 2
        
        var title: String {
            switch self {
            case .address: return "주소"
            case .amount: return "금액"
            case .confirmation: return "확인"
            }
        }
    }
    
    // MARK: - DisplayLogic Implementation
    
    func displayAddressValidation(viewModel: SendScene.ValidateAddress.ViewModel) {
        isAddressValid = viewModel.isValid
        addressValidationMessage = viewModel.message ?? ""
    }
    
    func displayAmountValidation(viewModel: SendScene.ValidateAmount.ViewModel) {
        isAmountValid = viewModel.isValid
        amountValidationMessage = viewModel.message ?? ""
    }
    
    func displayGasEstimation(viewModel: SendScene.EstimateGas.ViewModel) {
        estimatedGas = viewModel.estimatedGas
    }
    
    func displayTransactionPreparation(viewModel: SendScene.PrepareTransaction.ViewModel) {
        isLoading = viewModel.isLoading
        if !viewModel.isLoading && viewModel.isReady {
            currentStep = .confirmation
        }
    }
    
    func displayTransactionResult(viewModel: SendScene.SendTransaction.ViewModel) {
        isLoading = false
        if viewModel.success {
            transactionHash = viewModel.transactionHash
            showSuccessView = true
        } else {
            errorMessage = viewModel.errorMessage
        }
    }
    
    func displayBiometricAuthResult(viewModel: SendScene.BiometricAuth.ViewModel) {
        if viewModel.success {
            // 생체인증 성공 시 거래 진행
        } else {
            errorMessage = viewModel.errorMessage
        }
    }
    
    func displayQRScanner(viewModel: SendScene.QRScanner.ViewModel) {
        showQRScanner = viewModel.shouldShow
        if let scannedAddress = viewModel.scannedAddress {
            recipientAddress = scannedAddress
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
}

/// 프리미엄 핀테크 송금 화면
/// VIP 아키텍처 + Modern Minimalism + Premium Fintech + Glassmorphism
struct SendView: View {
    @State private var viewStore = SendViewStore()
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - VIP Architecture Components
    private let interactor: SendBusinessLogic
    private let presenter: SendPresenter
    private let router: SendRouter
    
    init() {
        let interactor = SendInteractor()
        let presenter = SendPresenter()
        let router = SendRouter()
        
        self.interactor = interactor
        self.presenter = presenter
        self.router = router
    }
    
    var body: some View {
        ZStack {
            // 프리미엄 배경 그라데이션
            KingGradients.minimalistBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // 프리미엄 헤더
                    premiumHeader
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                    
                    // 단계별 플로우
                    VStack(spacing: 24) {
                        switch viewStore.currentStep {
                        case .address:
                            addressInputSection
                        case .amount:
                            amountInputSection  
                        case .confirmation:
                            confirmationSection
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer(minLength: 120)
                }
            }
            
            // 하단 액션 버튼 영역
            bottomActionArea
        }
        .gesture(
            DragGesture()
                .onEnded { gesture in
                    if gesture.translation.height > 100 && abs(gesture.translation.width) < 50 {
                        dismiss()
                    }
                }
        )
        .onAppear {
            presenter.viewController = viewStore
            loadInitialData()
        }
        .alert("오류", isPresented: Binding<Bool>(
            get: { viewStore.errorMessage != nil },
            set: { _ in viewStore.clearError() }
        )) {
            Button("확인", role: .cancel) {
                viewStore.clearError()
            }
        } message: {
            if let errorMessage = viewStore.errorMessage {
                Text(errorMessage)
                    .font(KingTypography.bodyMedium)
                    .foregroundColor(KingColors.textSecondary)
            }
        }
        .sheet(isPresented: $viewStore.showSuccessView) {
            // 성공 화면은 추후 구현
            EmptyView()
        }
        .sheet(isPresented: $viewStore.showQRScanner) {
            // QR 스캐너는 추후 구현  
            EmptyView()
        }
    }
    
    // MARK: - Premium Components
    
    @ViewBuilder
    private var premiumHeader: some View {
        VStack(spacing: 20) {
            // 닫기 제스처 힌트
            RoundedRectangle(cornerRadius: 2.5)
                .fill(KingColors.textTertiary.opacity(0.4))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
            
            // 프리미엄 아이콘
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                KingColors.trustPurple.opacity(0.3),
                                KingColors.trustPurple.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 40
                        )
                    )
                    .frame(width: 80, height: 80)
                
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .background(
                            Circle()
                                .fill(KingColors.trustPurple.opacity(0.15))
                        )
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: "arrow.up.right.circle.fill")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    KingColors.trustPurple,
                                    KingColors.exclusiveGold.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .shadow(color: KingColors.trustPurple.opacity(0.3), radius: 12, x: 0, y: 6)
            }
            
            VStack(spacing: 8) {
                Text("이더리움 송금")
                    .font(KingTypography.displaySmall)
                    .fontWeight(.bold)
                    .foregroundColor(KingColors.textPrimary)
                    .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 0.5)
                
                Text("안전하게 ETH를 전송하세요")
                    .font(KingTypography.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(KingColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .shadow(color: Color.black.opacity(0.15), radius: 0.5, x: 0, y: 0.25)
            }
            
            // 단계 표시기
            stepIndicator
        }
    }
    
    @ViewBuilder
    private var stepIndicator: some View {
        HStack(spacing: 12) {
            ForEach(Array(SendViewStore.SendStep.allCases.enumerated()), id: \.offset) { index, step in
                HStack(spacing: 8) {
                    // 원형 인디케이터
                    ZStack {
                        Circle()
                            .fill(
                                step.rawValue <= viewStore.currentStep.rawValue 
                                ? KingColors.trustPurple.opacity(0.2)
                                : KingColors.textTertiary.opacity(0.1)
                            )
                            .frame(width: 24, height: 24)
                        
                        if step.rawValue < viewStore.currentStep.rawValue {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(KingColors.trustPurple)
                        } else {
                            Text("\(index + 1)")
                                .font(KingTypography.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(
                                    step == viewStore.currentStep 
                                    ? KingColors.trustPurple
                                    : KingColors.textTertiary
                                )
                        }
                    }
                    
                    if index < 2 {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(
                                step.rawValue < viewStore.currentStep.rawValue
                                ? KingColors.trustPurple.opacity(0.3)
                                : KingColors.textTertiary.opacity(0.2)
                            )
                            .frame(width: 20, height: 2)
                    }
                }
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Step Sections
    
    @ViewBuilder
    private var addressInputSection: some View {
        VStack(spacing: 20) {
            PremiumSectionHeader(
                title: "받는 사람 주소",
                subtitle: "이더리움 주소를 입력하거나 스캔하세요"
            )
            
            PremiumAddressField(
                address: $viewStore.recipientAddress,
                isValid: viewStore.isAddressValid,
                validationMessage: viewStore.addressValidationMessage,
                onQRScan: scanQRCode,
                onAddressBook: showAddressBook,
                onValidation: validateAddress
            )
        }
    }
    
    @ViewBuilder
    private var amountInputSection: some View {
        VStack(spacing: 20) {
            PremiumSectionHeader(
                title: "송금 금액",
                subtitle: "전송할 ETH 금액을 입력하세요"
            )
            
            PremiumAmountField(
                amount: $viewStore.amount,
                isValid: viewStore.isAmountValid,
                validationMessage: viewStore.amountValidationMessage,
                onValidation: validateAmount
            )
            
            // 가스비 선택
            PremiumGasFeeSelector(
                selectedFee: $viewStore.selectedGasFee,
                estimatedGas: viewStore.estimatedGas,
                onEstimateGas: estimateGas
            )
        }
    }
    
    @ViewBuilder
    private var confirmationSection: some View {
        VStack(spacing: 20) {
            PremiumSectionHeader(
                title: "거래 확인",
                subtitle: "송금 정보를 확인하세요"
            )
            
            PremiumTransactionSummary(
                recipientAddress: viewStore.recipientAddress,
                amount: viewStore.amount,
                gasFee: viewStore.selectedGasFee,
                estimatedGas: viewStore.estimatedGas
            )
        }
    }
    
    @ViewBuilder
    private var bottomActionArea: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 16) {
                switch viewStore.currentStep {
                case .address:
                    PremiumActionButton(
                        title: "다음",
                        isEnabled: viewStore.canProceedToAmount,
                        isLoading: viewStore.isLoading,
                        action: proceedToAmount
                    )
                    
                case .amount:
                    HStack(spacing: 12) {
                        PremiumSecondaryButton(
                            title: "이전",
                            action: goBackToAddress
                        )
                        
                        PremiumActionButton(
                            title: "다음",
                            isEnabled: viewStore.canProceedToConfirmation,
                            isLoading: viewStore.isLoading,
                            action: proceedToConfirmation
                        )
                    }
                    
                case .confirmation:
                    HStack(spacing: 12) {
                        PremiumSecondaryButton(
                            title: "이전",
                            action: goBackToAmount
                        )
                        
                        PremiumActionButton(
                            title: "송금하기",
                            isEnabled: true,
                            isLoading: viewStore.isLoading,
                            action: sendTransaction
                        )
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(
            LinearGradient(
                colors: [
                    Color.clear,
                    KingColors.backgroundPrimary.opacity(0.8),
                    KingColors.backgroundPrimary
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        )
    }
    
    // MARK: - Actions
    
    private func loadInitialData() {
        // 초기 데이터 로드
    }
    
    private func validateAddress() {
        let request = SendScene.ValidateAddress.Request(address: viewStore.recipientAddress)
        interactor.validateAddress(request: request)
    }
    
    private func validateAmount() {
        let request = SendScene.ValidateAmount.Request(amount: viewStore.amount)
        interactor.validateAmount(request: request)
    }
    
    private func estimateGas() {
        let request = SendScene.EstimateGas.Request(
            recipient: viewStore.recipientAddress,
            amount: viewStore.amount,
            gasFeeLevel: viewStore.selectedGasFee
        )
        interactor.estimateGas(request: request)
    }
    
    private func scanQRCode() {
        let request = SendScene.QRScanner.Request()
        interactor.scanQRCode(request: request)
    }
    
    private func showAddressBook() {
        // 주소록 표시
        viewStore.showAddressBook = true
    }
    
    private func proceedToAmount() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            viewStore.currentStep = .amount
        }
        estimateGas()
    }
    
    private func proceedToConfirmation() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            viewStore.currentStep = .confirmation
        }
    }
    
    private func goBackToAddress() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            viewStore.currentStep = .address
        }
    }
    
    private func goBackToAmount() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            viewStore.currentStep = .amount
        }
    }
    
    private func sendTransaction() {
        let request = SendScene.SendTransaction.Request(
            recipient: viewStore.recipientAddress,
            amount: viewStore.amount,
            gasFee: viewStore.selectedGasFee
        )
        interactor.sendTransaction(request: request)
    }
}

// MARK: - Premium Components

/// 프리미엄 섹션 헤더
struct PremiumSectionHeader: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(KingTypography.headlineSmall)
                .fontWeight(.bold)
                .foregroundColor(KingColors.textPrimary)
                .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 0.5)
            
            Text(subtitle)
                .font(KingTypography.bodySmall)
                .fontWeight(.medium)
                .foregroundColor(KingColors.textSecondary)
                .multilineTextAlignment(.center)
                .shadow(color: Color.black.opacity(0.15), radius: 0.5, x: 0, y: 0.25)
        }
    }
}

/// 프리미엄 주소 입력 필드
struct PremiumAddressField: View {
    @Binding var address: String
    let isValid: Bool
    let validationMessage: String
    let onQRScan: () -> Void
    let onAddressBook: () -> Void
    let onValidation: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // 메인 입력 필드
            VStack(spacing: 12) {
                TextField("0x1234...abcd", text: $address)
                    .font(KingTypography.bodyMedium)
                    .foregroundColor(KingColors.textPrimary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(KingColors.glassMinimalBase)
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isValid && !address.isEmpty ? KingColors.success.opacity(0.5) : 
                                !validationMessage.isEmpty ? KingColors.error.opacity(0.5) :
                                KingColors.glassBorder,
                                lineWidth: 1
                            )
                    )
                    .onChange(of: address) { oldValue, newValue in
                        onValidation()
                    }
                
                // 유효성 검증 메시지
                if !validationMessage.isEmpty {
                    Text(validationMessage)
                        .font(KingTypography.caption)
                        .foregroundColor(isValid ? KingColors.success : KingColors.error)
                        .shadow(color: Color.black.opacity(0.1), radius: 0.5, x: 0, y: 0.25)
                }
            }
            
            // 액션 버튼들
            HStack(spacing: 12) {
                PremiumIconButton(
                    icon: "qrcode.viewfinder",
                    title: "QR 스캔",
                    color: KingColors.info,
                    action: onQRScan
                )
                
                PremiumIconButton(
                    icon: "person.2.fill",
                    title: "주소록",
                    color: KingColors.trustPurple,
                    action: onAddressBook
                )
            }
        }
        .trustGlassCard(level: .subtle, cornerRadius: 20)
        .padding(.horizontal, 4)
    }
}

/// 프리미엄 금액 입력 필드  
struct PremiumAmountField: View {
    @Binding var amount: String
    let isValid: Bool
    let validationMessage: String
    let onValidation: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                HStack {
                    TextField("0.0", text: $amount)
                        .font(KingTypography.cryptoBalanceLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(KingColors.textPrimary)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                    
                    Text("ETH")
                        .font(KingTypography.labelLarge)
                        .fontWeight(.bold)
                        .foregroundColor(KingColors.exclusiveGold)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                
                if !validationMessage.isEmpty {
                    Text(validationMessage)
                        .font(KingTypography.caption)
                        .foregroundColor(isValid ? KingColors.success : KingColors.error)
                        .shadow(color: Color.black.opacity(0.1), radius: 0.5, x: 0, y: 0.25)
                }
            }
            .onChange(of: amount) { oldValue, newValue in
                onValidation()
            }
        }
        .premiumFinTechGlass(level: .standard)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isValid && !amount.isEmpty ? KingColors.success.opacity(0.3) :
                    !validationMessage.isEmpty ? KingColors.error.opacity(0.3) :
                    Color.clear,
                    lineWidth: 1
                )
        )
    }
}

/// 프리미엄 가스비 선택기
struct PremiumGasFeeSelector: View {
    @Binding var selectedFee: GasFeeLevel
    let estimatedGas: String
    let onEstimateGas: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("네트워크 수수료")
                    .font(KingTypography.labelLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(KingColors.textPrimary)
                
                Spacer()
                
                if !estimatedGas.isEmpty {
                    Text(estimatedGas)
                        .font(KingTypography.bodySmall)
                        .fontWeight(.medium)
                        .foregroundColor(KingColors.textSecondary)
                }
            }
            
            HStack(spacing: 12) {
                ForEach(GasFeeLevel.allCases, id: \.self) { fee in
                    Button {
                        selectedFee = fee
                        onEstimateGas()
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: fee.icon)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(fee.color)
                            
                            Text(fee.rawValue)
                                .font(KingTypography.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(
                                    selectedFee == fee ? KingColors.textPrimary : KingColors.textSecondary
                                )
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                selectedFee == fee ? 
                                fee.color.opacity(0.1) : 
                                Color.clear
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                selectedFee == fee ? 
                                fee.color.opacity(0.4) : 
                                KingColors.glassBorder,
                                lineWidth: selectedFee == fee ? 1.5 : 0.5
                            )
                    )
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedFee)
                }
            }
        }
        .ultraMinimalGlass(level: .subtle)
        .padding(.horizontal, 4)
    }
}

/// 프리미엄 거래 요약
struct PremiumTransactionSummary: View {
    let recipientAddress: String
    let amount: String
    let gasFee: GasFeeLevel
    let estimatedGas: String
    
    var body: some View {
        VStack(spacing: 20) {
            // 받는 사람
            PremiumInfoRow(
                title: "받는 사람",
                value: recipientAddress,
                icon: "person.circle.fill",
                iconColor: KingColors.info
            )
            
            // 송금 금액
            PremiumInfoRow(
                title: "송금 금액",
                value: "\(amount) ETH",
                icon: "bitcoinsign.circle.fill",
                iconColor: KingColors.exclusiveGold
            )
            
            // 네트워크 수수료
            PremiumInfoRow(
                title: "네트워크 수수료",
                value: estimatedGas,
                icon: gasFee.icon,
                iconColor: gasFee.color
            )
            
            Divider()
                .background(KingColors.glassBorder)
            
            // 총 금액
            PremiumInfoRow(
                title: "총 금액",
                value: "계산 중...",
                icon: "sum",
                iconColor: KingColors.trustPurple,
                isHighlighted: true
            )
        }
        .trustGlassCard(level: .prominent)
        .padding(.horizontal, 4)
    }
}

/// 프리미엄 정보 행
struct PremiumInfoRow: View {
    let title: String
    let value: String
    let icon: String
    let iconColor: Color
    var isHighlighted: Bool = false
    
    var body: some View {
        HStack(spacing: 16) {
            // 아이콘
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(iconColor)
            }
            
            // 텍스트
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(KingTypography.bodySmall)
                    .fontWeight(.medium)
                    .foregroundColor(KingColors.textSecondary)
                
                Text(value)
                    .font(isHighlighted ? KingTypography.labelLarge : KingTypography.bodyMedium)
                    .fontWeight(isHighlighted ? .bold : .medium)
                    .foregroundColor(isHighlighted ? KingColors.trustPurple : KingColors.textPrimary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
    }
}

/// 프리미엄 아이콘 버튼
struct PremiumIconButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(KingTypography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(KingColors.textSecondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(maxWidth: .infinity)
    }
}

/// 프리미엄 액션 버튼
struct PremiumActionButton: View {
    let title: String
    let isEnabled: Bool
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: KingColors.textInverse))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(KingTypography.labelLarge)
                        .foregroundColor(KingColors.textInverse)
                }
                
                Text(title)
                    .font(KingTypography.buttonPrimary)
                    .fontWeight(.bold)
                    .foregroundColor(KingColors.textInverse)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [
                        KingColors.trustPurple,
                        KingColors.trustPurple.opacity(0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(
                color: KingColors.trustPurple.opacity(0.4),
                radius: 12,
                x: 0,
                y: 6
            )
            .opacity(isEnabled ? 1.0 : 0.6)
            .scaleEffect(isEnabled ? 1.0 : 0.98)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isEnabled || isLoading)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isEnabled)
    }
}

/// 프리미엄 보조 버튼
struct PremiumSecondaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.left.circle")
                    .font(KingTypography.labelMedium)
                    .foregroundColor(KingColors.trustPurple)
                
                Text(title)
                    .font(KingTypography.buttonSecondary)
                    .fontWeight(.semibold)
                    .foregroundColor(KingColors.trustPurple)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(KingColors.trustPurple.opacity(0.05))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(KingColors.trustPurple.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - VIP Components (Stubs for compilation)

class SendInteractor: SendBusinessLogic {
    func validateAddress(request: SendScene.ValidateAddress.Request) {}
    func validateAmount(request: SendScene.ValidateAmount.Request) {}
    func estimateGas(request: SendScene.EstimateGas.Request) {}
    func prepareTransaction(request: SendScene.PrepareTransaction.Request) {}
    func sendTransaction(request: SendScene.SendTransaction.Request) {}
    func authenticateWithBiometrics(request: SendScene.BiometricAuth.Request) {}
    func scanQRCode(request: SendScene.QRScanner.Request) {}
}

class SendPresenter {
    weak var viewController: SendDisplayLogic?
}

class SendRouter: SendRoutingLogic {
    func routeToSuccess(transactionHash: String) {}
    func routeToQRScanner() {}
    func routeToAddressBook() {}
    func routeToBiometricAuth() {}
}

// MARK: - SendScene Models (Stubs)

enum SendScene {
    enum ValidateAddress {
        struct Request { let address: String }
        struct ViewModel { let isValid: Bool; let message: String? }
    }
    
    enum ValidateAmount {
        struct Request { let amount: String }
        struct ViewModel { let isValid: Bool; let message: String? }
    }
    
    enum EstimateGas {
        struct Request { let recipient: String; let amount: String; let gasFeeLevel: GasFeeLevel }
        struct ViewModel { let estimatedGas: String }
    }
    
    enum PrepareTransaction {
        struct Request {}
        struct ViewModel { let isLoading: Bool; let isReady: Bool }
    }
    
    enum SendTransaction {
        struct Request { let recipient: String; let amount: String; let gasFee: GasFeeLevel }
        struct ViewModel { let success: Bool; let transactionHash: String?; let errorMessage: String? }
    }
    
    enum BiometricAuth {
        struct Request {}
        struct ViewModel { let success: Bool; let errorMessage: String? }
    }
    
    enum QRScanner {
        struct Request {}
        struct ViewModel { let shouldShow: Bool; let scannedAddress: String? }
    }
}

// MARK: - Preview

#Preview("Premium SendView") {
    SendView()
        .preferredColorScheme(.dark)
}

#Preview("Premium SendView - Light") {
    SendView()
        .preferredColorScheme(.light)
}