import Foundation
import Entity
import Core
import BigInt

// MARK: - SendInteractor Stub Implementation

/// SendInteractor의 Stub 구현
/// TODO: 실제 Web3 구현이 완료되면 complex 버전으로 교체
@MainActor
public final class SendInteractor: SendBusinessLogic {
    // MARK: - Properties
    
    public weak var presenter: SendPresentationLogic?
    private let worker: SendWorkerProtocol
    
    // MARK: - 초기화
    
    public init(
        presenter: SendPresentationLogic,
        worker: SendWorkerProtocol
    ) {
        self.presenter = presenter
        self.worker = worker
    }
    
    // MARK: - SendBusinessLogic Stub 구현
    
    public func validateAddress(request: SendScene.ValidateAddress.Request) {
        Logger.debug("📧 주소 검증 시작: \(request.recipientAddress)")
        
        // 간단한 이더리움 주소 형식 검증
        let isValid = request.recipientAddress.hasPrefix("0x") && request.recipientAddress.count == 42
        
        let response = SendScene.ValidateAddress.Response(
            isValid: isValid,
            normalizedAddress: isValid ? request.recipientAddress : nil,
            addressType: isValid ? .eoa : nil,
            errorMessage: isValid ? nil : "유효하지 않은 주소 형식입니다"
        )
        
        presenter?.presentAddressValidation(response: response)
        Logger.info("✅ 주소 검증 완료: \(isValid)")
    }
    
    public func estimateGasFee(request: SendScene.EstimateGasFee.Request) {
        Logger.debug("⛽ 가스 수수료 추정 시작")
        
        Task { @MainActor in
            // 임시로 고정 주소 사용
            let fromAddress = "0x1234567890123456789012345678901234567890"
            
            guard let amountBigUInt = BigUInt(request.amount) else {
                let response = SendScene.EstimateGasFee.Response(
                    gasFeeInfo: [],
                    recommendedFee: createDefaultGasFee(),
                    canAfford: false,
                    currentBalance: BigUInt(0),
                    totalCost: BigUInt(0),
                    networkStatus: .normal
                )
                presenter?.presentGasFeeEstimation(response: response)
                return
            }
            
            let result = await worker.calculateTransactionFee(
                from: fromAddress,
                to: request.recipientAddress,
                amount: amountBigUInt,
                gasPrice: nil
            )
            
            switch result {
            case .success(let fee):
                // 다양한 우선순위 가스비 생성
                let slowFee = SendScene.GasFeeInfo(
                    gasPrice: fee.gasPrice,
                    gasLimit: fee.gasLimit,
                    maxFeePerGas: fee.gasPrice,
                    maxPriorityFeePerGas: BigUInt(1_000_000_000), // 1 Gwei
                    estimatedFee: fee.totalFee,
                    feeType: .slow
                )
                
                let standardFee = SendScene.GasFeeInfo(
                    gasPrice: fee.gasPrice,
                    gasLimit: fee.gasLimit,
                    maxFeePerGas: fee.gasPrice,
                    maxPriorityFeePerGas: BigUInt(2_000_000_000), // 2 Gwei
                    estimatedFee: fee.totalFee,
                    feeType: .standard
                )
                
                let fastFee = SendScene.GasFeeInfo(
                    gasPrice: fee.gasPrice * 2,
                    gasLimit: fee.gasLimit,
                    maxFeePerGas: fee.gasPrice * 2,
                    maxPriorityFeePerGas: BigUInt(3_000_000_000), // 3 Gwei
                    estimatedFee: fee.totalFee * 2,
                    feeType: .fast
                )
                
                let response = SendScene.EstimateGasFee.Response(
                    gasFeeInfo: [slowFee, standardFee, fastFee],
                    recommendedFee: standardFee,
                    canAfford: true, // 임시로 true
                    currentBalance: BigUInt(10).power(18), // 1 ETH
                    totalCost: amountBigUInt + fee.totalFee,
                    networkStatus: .normal
                )
                presenter?.presentGasFeeEstimation(response: response)
                Logger.info("✅ 가스 수수료 추정 완료")
                
            case .failure(let error):
                let response = SendScene.EstimateGasFee.Response(
                    gasFeeInfo: [],
                    recommendedFee: createDefaultGasFee(),
                    canAfford: false,
                    currentBalance: BigUInt(0),
                    totalCost: BigUInt(0),
                    networkStatus: .normal
                )
                presenter?.presentGasFeeEstimation(response: response)
                Logger.error("❌ 가스 수수료 추정 실패: \(error)")
            }
        }
    }
    
    private func createDefaultGasFee() -> SendScene.GasFeeInfo {
        return SendScene.GasFeeInfo(
            gasPrice: BigUInt(20_000_000_000), // 20 Gwei
            gasLimit: BigUInt(21_000),
            maxFeePerGas: BigUInt(20_000_000_000),
            maxPriorityFeePerGas: BigUInt(2_000_000_000),
            estimatedFee: BigUInt(420_000_000_000_000), // 0.00042 ETH
            feeType: .standard
        )
    }
    
    public func sendTransaction(request: SendScene.SendTransaction.Request) async {
        Logger.info("💸 거래 전송 시작 (Production)")
        
        // Entity의 새로운 Request 구조에 맞춰 변환
        guard let amountBigUInt = BigUInt(request.amount) else {
            let response = SendScene.SendTransaction.Response(
                success: false,
                transactionHash: nil,
                transactionInfo: nil,
                error: SendError.invalidAmount(reason: "유효하지 않은 금액입니다"),
                estimatedConfirmationTime: nil
            )
            presenter?.presentTransactionResult(response: response)
            return
        }
        
        // 임시로 고정 주소 사용 (실제 구현에서는 WalletService에서 가져옴)
        let fromAddress = "0x1234567890123456789012345678901234567890"
        
        let result = await worker.sendTransaction(
            from: fromAddress,
            to: request.recipientAddress,
            amount: amountBigUInt,
            gasPrice: request.selectedGasFee.gasPrice,
            gasLimit: request.selectedGasFee.gasLimit,
            password: "temp_password" // 실제로는 보안 모듈에서 처리
        )
        
        switch result {
        case .success(let txHash):
            let response = SendScene.SendTransaction.Response(
                success: true,
                transactionHash: txHash,
                transactionInfo: nil,
                error: nil,
                estimatedConfirmationTime: 300 // 5분
            )
            presenter?.presentTransactionResult(response: response)
            Logger.info("✅ 거래 전송 성공: \(txHash)")
            
        case .failure(let error):
            let sendError = SendError.transactionBroadcastFailed(reason: error.localizedDescription)
            let response = SendScene.SendTransaction.Response(
                success: false,
                transactionHash: nil,
                transactionInfo: nil,
                error: sendError,
                estimatedConfirmationTime: nil
            )
            presenter?.presentTransactionResult(response: response)
            Logger.error("❌ 거래 전송 실패: \(error)")
        }
    }
    
    public func trackTransaction(request: SendScene.TrackTransaction.Request) {
        Logger.debug("🔍 거래 추적 시작: \(request.transactionHash)")
        
        Task { @MainActor in
            let result = await worker.getTransactionStatus(transactionHash: request.transactionHash)
            
            switch result {
            case .success(let status):
                // SendModels.TransactionStatus를 SendScene.TransactionStatus로 변환
                let transactionStatus: SendScene.TransactionStatus
                if status.isSuccessful {
                    transactionStatus = .confirmed
                } else if status.isPending {
                    transactionStatus = .pending
                } else {
                    transactionStatus = .failed
                }
                
                // TransactionInfo 생성
                let transactionInfo = SendScene.TransactionInfo(
                    hash: status.hash,
                    from: status.from,
                    to: status.to,
                    amount: status.value,
                    gasUsed: status.gasUsed ?? BigUInt(21_000),
                    gasPrice: status.effectiveGasPrice ?? BigUInt("20000000000"), // 20 Gwei fallback
                    blockNumber: status.blockNumber != nil ? BigUInt(status.blockNumber!) : nil,
                    blockHash: nil,
                    transactionIndex: nil,
                    timestamp: Date(),
                    confirmations: status.confirmations,
                    status: transactionStatus,
                    nonce: BigUInt(0),
                    networkID: BigUInt(1)
                )
                
                let response = SendScene.TrackTransaction.Response(
                    transactionInfo: transactionInfo,
                    shouldContinuePolling: !transactionStatus.isCompleted
                )
                presenter?.presentTransactionTracking(response: response)
                Logger.info("✅ 거래 추적 완료")
                
            case .failure(let error):
                // 실패한 경우에도 TransactionInfo 생성 (최소한의 정보)
                let transactionInfo = SendScene.TransactionInfo(
                    hash: request.transactionHash,
                    from: "",
                    to: "",
                    amount: BigUInt(0),
                    gasUsed: nil,
                    gasPrice: BigUInt(0),
                    blockNumber: nil,
                    blockHash: nil,
                    transactionIndex: nil,
                    timestamp: Date(),
                    confirmations: 0,
                    status: .failed,
                    nonce: BigUInt(0),
                    networkID: BigUInt(1)
                )
                
                let response = SendScene.TrackTransaction.Response(
                    transactionInfo: transactionInfo,
                    shouldContinuePolling: false
                )
                presenter?.presentTransactionTracking(response: response)
                Logger.error("❌ 거래 추적 실패: \(error)")
            }
        }
    }
}

// MARK: - SendBusinessLogic Protocol

@MainActor
public protocol SendBusinessLogic: AnyObject {
    func validateAddress(request: SendScene.ValidateAddress.Request)
    func estimateGasFee(request: SendScene.EstimateGasFee.Request)
    func sendTransaction(request: SendScene.SendTransaction.Request) async
    func trackTransaction(request: SendScene.TrackTransaction.Request)
}

// MARK: - SendPresentationLogic Protocol

@MainActor
public protocol SendPresentationLogic: AnyObject {
    func presentAddressValidation(response: SendScene.ValidateAddress.Response)
    func presentGasFeeEstimation(response: SendScene.EstimateGasFee.Response)
    func presentTransactionResult(response: SendScene.SendTransaction.Response)
    func presentTransactionTracking(response: SendScene.TrackTransaction.Response)
}

// MARK: - SendScene Models
// Note: SendScene 모델들은 Entity 모듈에서 import 됩니다.