import Foundation
import Entity
import Core
import BigInt

// MARK: - SendPresenter Stub Implementation

/// SendPresenter의 Stub 구현
/// TODO: 실제 UI 요구사항이 명확해지면 complex 버전으로 교체
@MainActor
public final class SendPresenter: SendPresentationLogic {
    // MARK: - Properties
    
    public var viewController: (any SendDisplayLogic)?
    
    // MARK: - 초기화
    
    public init(viewController: SendDisplayLogic? = nil) {
        self.viewController = viewController
        Logger.info("SendPresenter Stub 초기화 완료")
    }
    
    // MARK: - SendPresentationLogic Stub 구현
    
    public func presentAddressValidation(response: SendScene.ValidateAddress.Response) {
        Logger.debug("📧 주소 검증 결과 표시 (Stub): \(response.isValid)")
        
        let viewModel = SendScene.ValidateAddress.ViewModel(
            isValid: response.isValid,
            address: response.normalizedAddress ?? "",
            addressTypeDescription: response.addressType?.rawValue,
            errorMessage: response.errorMessage,
            showWarning: !response.isValid,
            warningMessage: response.isValid ? nil : response.errorMessage
        )
        
        viewController?.displayAddressValidation(viewModel: viewModel)
    }
    
    public func presentGasFeeEstimation(response: SendScene.EstimateGasFee.Response) {
        Logger.debug("⛽ 가스 수수료 표시 (Stub)")
        
        // Convert GasFeeInfo to FeeOptionViewModel
        let feeOptions = response.gasFeeInfo.map { feeInfo in
            SendScene.EstimateGasFee.FeeOptionViewModel(
                type: feeInfo.feeType,
                feeText: "\(feeInfo.estimatedFee) Wei",
                timeEstimate: "약 2분",
                isRecommended: feeInfo.feeType == .standard
            )
        }
        
        let viewModel = SendScene.EstimateGasFee.ViewModel(
            feeOptions: feeOptions,
            selectedFeeIndex: 0,
            canProceed: response.canAfford,
            warningMessage: response.canAfford ? nil : "잔액이 부족합니다",
            networkStatusText: "🟢 \(response.networkStatus.rawValue)",
            balanceText: "잔액: \(response.currentBalance) Wei",
            totalCostText: "총 비용: \(response.totalCost) Wei"
        )
        
        viewController?.displayGasFeeEstimation(viewModel: viewModel)
    }
    
    public func presentTransactionResult(response: SendScene.SendTransaction.Response) {
        Logger.info("💸 거래 결과 표시 (Stub): \(response.success)")
        
        let viewModel = SendScene.SendTransaction.ViewModel(
            success: response.success,
            title: response.success ? "송금 성공" : "송금 실패",
            message: response.success ? "이더리움 전송이 완료되었습니다." : (response.error?.localizedDescription ?? "거래 처리 중 문제가 발생했습니다."),
            transactionHash: response.transactionHash,
            blockExplorerURL: nil,
            showRetryButton: !response.success,
            showShareButton: response.success,
            estimatedTime: response.success ? "5-10분" : nil
        )
        
        viewController?.displayTransactionResult(viewModel: viewModel)
    }
    
    public func presentTransactionTracking(response: SendScene.TrackTransaction.Response) {
        Logger.debug("🔍 거래 추적 결과 표시 (Stub)")
        
        let transactionInfo = response.transactionInfo
        let status = transactionInfo.status
        
        let viewModel = SendScene.TrackTransaction.ViewModel(
            status: status,
            progressText: "거래 처리 중...",
            progressValue: status == .confirmed ? 1.0 : 0.6,
            transactionInfo: transactionInfo,
            showProgressBar: status != .confirmed,
            statusIcon: status == .confirmed ? "checkmark.circle" : "clock",
            actionButtonText: nil,
            canCancel: false
        )
        
        viewController?.displayTransactionTracking(viewModel: viewModel)
    }
}

// MARK: - SendDisplayLogic Protocol

@MainActor
public protocol SendDisplayLogic: AnyObject {
    func displayAddressValidation(viewModel: SendScene.ValidateAddress.ViewModel)
    func displayGasFeeEstimation(viewModel: SendScene.EstimateGasFee.ViewModel)
    func displayTransactionResult(viewModel: SendScene.SendTransaction.ViewModel)
    func displayTransactionTracking(viewModel: SendScene.TrackTransaction.ViewModel)
}
