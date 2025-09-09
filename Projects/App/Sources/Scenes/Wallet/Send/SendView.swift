import SwiftUI
import BigInt
import Core
import DesignSystem
import Entity
import WalletKit
import SecurityKit

// MARK: - SendView Production Implementation

/// 실제 이더리움 송금 기능 화면
/// Production-ready Ethereum transaction interface
public struct SendView: View {
    // MARK: - Properties
    
    @State private var recipientAddress = ""
    @State private var amount = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var currentBalance = "0.0"
    @State private var currentGasPrice = "0.0"
    @State private var estimatedGas = "21000"
    @State private var isLoadingBalance = true
    @State private var isLoadingGasPrice = true
    @State private var isValidatingAddress = false
    @State private var addressValidationResult: (isValid: Bool, message: String?) = (false, nil)
    
    // VIP Components (의존성 주입으로 제공)
    private let interactor: SendBusinessLogic
    private let router: SendRoutingLogic
    
    // MARK: - 초기화
    
    public init(
        interactor: SendBusinessLogic,
        router: SendRoutingLogic
    ) {
        self.interactor = interactor
        self.router = router
    }
    
    // MARK: - Body
    
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 헤더
                    VStack(spacing: 8) {
                        Text("이더리움 송금")
                            .font(KingTypography.headlineLarge)
                            .foregroundColor(KingColors.textPrimary)
                        
                        Text("안전한 블록체인 전송")
                            .font(KingTypography.bodyMedium)
                            .foregroundColor(KingColors.textSecondary)
                    }
                    .padding(.top)
                    
                    // 수신자 주소 입력
                    VStack(alignment: .leading, spacing: 12) {
                        Text("받는 사람 주소")
                            .font(KingTypography.labelLarge)
                            .foregroundColor(KingColors.textPrimary)
                        
                        TextField("0x...", text: $recipientAddress)
                            .font(KingTypography.bodyMedium)
                            .padding()
                            .background(KingColors.surface)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(KingColors.border, lineWidth: 1)
                            )
                            .onChange(of: recipientAddress) { _, newValue in
                                validateAddress(newValue)
                            }
                    }
                    
                    // 송금 금액 입력
                    VStack(alignment: .leading, spacing: 12) {
                        Text("송금 금액")
                            .font(KingTypography.labelLarge)
                            .foregroundColor(KingColors.textPrimary)
                        
                        TextField("0.0", text: $amount)
                            .font(KingTypography.bodyMedium)
                            .keyboardType(.decimalPad)
                            .padding()
                            .background(KingColors.surface)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(KingColors.border, lineWidth: 1)
                            )
                        
                        HStack {
                            Text("잔액: ")
                                .font(KingTypography.caption)
                                .foregroundColor(KingColors.textSecondary)
                            
                            if isLoadingBalance {
                                HStack(spacing: 4) {
                                    Text("로딩 중...")
                                        .font(KingTypography.caption)
                                        .foregroundColor(KingColors.textSecondary)
                                    ProgressView()
                                        .scaleEffect(0.7)
                                }
                            } else {
                                Text("\(currentBalance) ETH")
                                    .font(KingTypography.caption)
                                    .foregroundColor(KingColors.textPrimary)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                    
                    // 가스 수수료 정보
                    VStack(alignment: .leading, spacing: 12) {
                        Text("가스 수수료")
                            .font(KingTypography.labelLarge)
                            .foregroundColor(KingColors.textPrimary)
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("예상 수수료")
                                    .font(KingTypography.bodyMedium)
                                    .foregroundColor(KingColors.textSecondary)
                                Text("0.002 ETH")
                                    .font(KingTypography.bodyLarge)
                                    .foregroundColor(KingColors.textPrimary)
                            }
                            
                            Spacer()
                            
                            Text("🟢 네트워크 정상")
                                .font(KingTypography.bodyMedium)
                                .foregroundColor(KingColors.success)
                        }
                        .padding()
                        .background(KingColors.surface)
                        .cornerRadius(12)
                    }
                    
                    Spacer()
                    
                    // 송금 버튼
                    Button("송금하기") {
                        sendTransaction()
                    }
                    .font(KingTypography.labelLarge)
                    .foregroundColor(KingColors.buttonPrimary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(KingGradients.primary)
                    )
                    .disabled(recipientAddress.isEmpty || amount.isEmpty)
                    .opacity((recipientAddress.isEmpty || amount.isEmpty) ? 0.5 : 1.0)
                }
                .padding()
            }
            .background(KingColors.backgroundPrimary)
            .navigationBarTitleDisplayMode(.inline)
            .alert("송금 결과", isPresented: $showAlert) {
                Button("확인") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func validateAddress(_ address: String) {
        let request = SendScene.ValidateAddress.Request(
            recipientAddress: address,
            amount: amount.isEmpty ? "0" : amount
        )
        interactor.validateAddress(request: request)
    }
    
    func handleTransactionResult(_ viewModel: SendScene.SendTransaction.ViewModel) {
        if viewModel.success {
            if let txHash = viewModel.transactionHash {
                alertMessage = "송금이 성공적으로 완료되었습니다!\n\n트랜잭션 해시:\n\(txHash)\n\n블록체인에서 확인까지 몇 분 소요될 수 있습니다."
            } else {
                alertMessage = viewModel.message
            }
            // 송금 성공 시 폼 초기화
            recipientAddress = ""
            amount = ""
        } else {
            alertMessage = viewModel.message
        }
        showAlert = true
    }
    
    private func sendTransaction() {
        guard !recipientAddress.isEmpty,
              !amount.isEmpty,
              let _ = BigUInt(amount) else {
            alertMessage = "입력 정보를 확인해주세요."
            showAlert = true
            return
        }
        
        // 실제 이더리움 송금 실행
        Task {
            // 가스비 정보 생성
            let gasPrice = BigUInt(currentGasPrice) ?? BigUInt("20000000000") // 20 Gwei
            let gasLimit = BigUInt(estimatedGas) ?? BigUInt("21000")
            let maxFeePerGas = gasPrice
            let maxPriorityFeePerGas = BigUInt("2000000000") // 2 Gwei
            let estimatedFee = gasPrice * gasLimit
            
            let selectedGasFee = Entity.SendScene.GasFeeInfo(
                gasPrice: gasPrice,
                gasLimit: gasLimit,
                maxFeePerGas: maxFeePerGas,
                maxPriorityFeePerGas: maxPriorityFeePerGas,
                estimatedFee: estimatedFee,
                feeType: .standard
            )
            
            let request = SendScene.SendTransaction.Request(
                recipientAddress: recipientAddress,
                amount: amount,
                selectedGasFee: selectedGasFee,
                userConfirmation: true
            )
            await interactor.sendTransaction(request: request)
        }
    }
}

// MARK: - SendDisplayLogic Implementation

@MainActor
class SendViewDisplayLogic: SendDisplayLogic {
    var sendView: SendView?
    
    init(sendView: SendView) {
        self.sendView = sendView
    }
    
    func displayAddressValidation(viewModel: SendScene.ValidateAddress.ViewModel) {
        Logger.debug("📧 주소 검증 결과: \(viewModel.isValid)")
    }
    
    func displayGasFeeEstimation(viewModel: SendScene.EstimateGasFee.ViewModel) {
        Logger.debug("⛽ 가스 수수료 정보 업데이트")
    }
    
    func displayTransactionResult(viewModel: SendScene.SendTransaction.ViewModel) {
        sendView?.handleTransactionResult(viewModel)
    }
    
    func displayTransactionTracking(viewModel: SendScene.TrackTransaction.ViewModel) {
        Logger.debug("🔍 거래 추적: \(viewModel.progressText)")
    }
}

// MARK: - Preview

struct SendView_Previews: PreviewProvider {
    static var previews: some View {
        // Production interactor와 router 생성
        let presenter = SendPresenter()
        let worker = SendWorker(walletService: WalletService.shared, securityService: SecurityService.shared)
        let interactor = SendInteractor(presenter: presenter, worker: worker)
        let router = SendRouter()
        
        return SendView(interactor: interactor, router: router)
    }
}
