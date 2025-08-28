import SwiftUI
import DesignSystem
import Entity
import Core
import Factory

/// Phase 2.6: 신뢰감 있는 미니멀 송금 - 극도 미니멀리즘 완성
/// 각 단계를 하나의 클린한 글래스 카드로 통합, 골드는 최종 Send만

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
            // 극도 미니멀 배경
            KingColors.primaryDark
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // 미니멀 헤더
                    minimalHeader
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                    
                    // 통합 송금 카드 (모든 단계 하나로)
                    unifiedSendCard
                        .padding(.horizontal, 20)
                    
                    Spacer(minLength: 140)
                }
            }
            
            // 단순한 하단 액션 영역
            minimalBottomAction
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
    
    // MARK: - Minimal Trust Components
    
    @ViewBuilder
    private var minimalHeader: some View {
        VStack(spacing: 24) {
            // 닫기 제스처 힌트 - 더 서브틀하게
            RoundedRectangle(cornerRadius: 2)
                .fill(KingColors.textSecondary.opacity(0.3))
                .frame(width: 32, height: 4)
            
            // 극도로 미니멀한 아이콘
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .background(
                        Circle()
                            .fill(KingColors.buttonTrust.opacity(0.08))
                    )
                    .frame(width: 56, height: 56)
                
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(KingColors.textInverse.opacity(0.9))
            }
            
            // 미니멀 타이틀
            VStack(spacing: 6) {
                Text("송금")
                    .font(KingTypography.cleanDisplay)
                    .foregroundColor(KingColors.textInverse)
                
                Text("신뢰할 수 있는 ETH 전송")
                    .font(KingTypography.minimalistBody)
                    .foregroundColor(KingColors.textSecondary)
            }
        }
    }
    
    // 단계 표시기 완전 제거 - 미니멀리즘에 집중
    
    // MARK: - Unified Send Card (All Steps in One)
    
    @ViewBuilder
    private var unifiedSendCard: some View {
        VStack(spacing: 28) {
            // 주소 입력 - 항상 표시
            trustAddressSection
            
            // 금액 입력 - 주소 입력 후 표시
            if viewStore.canProceedToAmount {
                Divider()
                    .background(KingColors.glassBorder)
                    .padding(.horizontal, 8)
                
                trustAmountSection
                
                // 가스비 - 미니멀하게
                if viewStore.canProceedToConfirmation {
                    trustGasSection
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(KingColors.textInverse.opacity(0.05))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(KingColors.textInverse.opacity(0.08), lineWidth: 1)
        )
        .shadow(
            color: Color.black.opacity(0.3), 
            radius: 20, 
            x: 0, 
            y: 8
        )
    }
    
    @ViewBuilder
    private var trustAddressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("받는 주소")
                .font(KingTypography.trustHeadline)
                .foregroundColor(KingColors.textInverse.opacity(0.9))
            
            HStack(spacing: 16) {
                TextField("0x...", text: $viewStore.recipientAddress)
                    .font(KingTypography.minimalistBody)
                    .foregroundColor(KingColors.textInverse)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(KingColors.backgroundSecondary.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                viewStore.isAddressValid && !viewStore.recipientAddress.isEmpty 
                                ? KingColors.buttonPrimary.opacity(0.4) 
                                : KingColors.glassBorder, 
                                lineWidth: 1
                            )
                    )
                    .onChange(of: viewStore.recipientAddress) { _, _ in
                        validateAddress()
                    }
                
                // QR 스캔 버튼 - 미니멀
                Button(action: scanQRCode) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(KingColors.textSecondary)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(KingColors.backgroundSecondary.opacity(0.2))
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // 유효성 메시지 - 서브틀
            if !viewStore.addressValidationMessage.isEmpty {
                Text(viewStore.addressValidationMessage)
                    .font(KingTypography.subtleCaption)
                    .foregroundColor(
                        viewStore.isAddressValid 
                        ? KingColors.buttonPrimary.opacity(0.8) 
                        : KingColors.textSecondary
                    )
            }
        }
    }
    
    @ViewBuilder
    private var trustAmountSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("금액")
                .font(KingTypography.trustHeadline)
                .foregroundColor(KingColors.textInverse.opacity(0.9))
            
            HStack {
                TextField("0.0", text: $viewStore.amount)
                    .font(KingTypography.cleanDisplay)
                    .foregroundColor(KingColors.textInverse)
                    .keyboardType(.decimalPad)
                    .onChange(of: viewStore.amount) { _, _ in
                        validateAmount()
                    }
                
                Text("ETH")
                    .font(KingTypography.trustHeadline)
                    .foregroundColor(KingColors.textSecondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(KingColors.backgroundSecondary.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        viewStore.isAmountValid && !viewStore.amount.isEmpty 
                        ? KingColors.buttonPrimary.opacity(0.4) 
                        : KingColors.glassBorder, 
                        lineWidth: 1
                    )
            )
            
            if !viewStore.amountValidationMessage.isEmpty {
                Text(viewStore.amountValidationMessage)
                    .font(KingTypography.subtleCaption)
                    .foregroundColor(
                        viewStore.isAmountValid 
                        ? KingColors.buttonPrimary.opacity(0.8) 
                        : KingColors.textSecondary
                    )
            }
        }
    }
    
    @ViewBuilder
    private var trustGasSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("네트워크 수수료")
                    .font(KingTypography.minimalistBody)
                    .foregroundColor(KingColors.textSecondary)
                
                Spacer()
                
                if !viewStore.estimatedGas.isEmpty {
                    Text(viewStore.estimatedGas)
                        .font(KingTypography.subtleCaption)
                        .foregroundColor(KingColors.textTertiary)
                }
            }
            
            // 미니멀 가스 선택
            HStack(spacing: 8) {
                ForEach(GasFeeLevel.allCases, id: \.self) { fee in
                    Button {
                        viewStore.selectedGasFee = fee
                        estimateGas()
                    } label: {
                        Text(fee.rawValue)
                            .font(KingTypography.subtleCaption)
                            .foregroundColor(
                                viewStore.selectedGasFee == fee 
                                ? KingColors.buttonPrimary 
                                : KingColors.textSecondary
                            )
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        viewStore.selectedGasFee == fee 
                                        ? KingColors.buttonPrimary.opacity(0.15) 
                                        : Color.clear
                                    )
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    @ViewBuilder
    private var minimalBottomAction: some View {
        VStack {
            Spacer()
            
            // 미니멀 송금 버튼 - 골드는 오직 여기에만
            if viewStore.canProceedToConfirmation {
                Button(action: sendTransaction) {
                    HStack(spacing: 12) {
                        if viewStore.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: KingColors.primaryDark))
                                .scaleEffect(0.9)
                        } else {
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(KingColors.primaryDark)
                        }
                        
                        Text("송금")
                            .font(KingTypography.trustHeadline)
                            .fontWeight(.bold)
                            .foregroundColor(KingColors.primaryDark)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(KingColors.buttonPrimary)
                    )
                    .shadow(
                        color: KingColors.buttonPrimary.opacity(0.4),
                        radius: 12,
                        x: 0,
                        y: 6
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(viewStore.isLoading)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewStore.canProceedToConfirmation)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
        .background(
            LinearGradient(
                colors: [
                    Color.clear,
                    KingColors.primaryDark.opacity(0.8),
                    KingColors.primaryDark
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
    
    // 단계별 네비게이션 제거 - 모든 입력을 하나의 카드에서 처리
    
    private func sendTransaction() {
        let request = SendScene.SendTransaction.Request(
            recipient: viewStore.recipientAddress,
            amount: viewStore.amount,
            gasFee: viewStore.selectedGasFee
        )
        interactor.sendTransaction(request: request)
    }
}

// MARK: - Minimal Trust Components (Simplified)

// 모든 프리미엄 컴포넌트 제거 - 미니멀리즘에 집중
// 주소, 금액, 가스비 모두 하나의 카드에서 처리
// 골드는 최종 송금 버튼에만 사용

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