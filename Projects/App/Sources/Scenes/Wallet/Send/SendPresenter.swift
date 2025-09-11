import Foundation
import Entity
import UIKit

// MARK: - Presentation Logic Protocol

@MainActor
protocol SendPresentationLogic: AnyObject {
    func presentAddressValidation(response: SendScene.ValidateAddress.Response)
    func presentAmountValidation(response: SendScene.ValidateAmount.Response)
    func presentGasEstimation(response: SendScene.EstimateGas.Response)
    func presentTransactionPreparation(response: SendScene.PrepareTransaction.Response)
    func presentTransactionResult(response: SendScene.SendTransaction.Response)
}

// MARK: - Send Presenter

@MainActor
final class SendPresenter: SendPresentationLogic {
    
    // MARK: - VIP Reference
    weak var viewController: SendDisplayLogic?
    
    // MARK: - Formatters
    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 6
        return formatter
    }()
    
    private let ethFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 18
        return formatter
    }()
    
    // MARK: - Presentation Logic Implementation
    
    func presentAddressValidation(response: SendScene.ValidateAddress.Response) {
        let viewModel = SendScene.ValidateAddress.ViewModel(
            isValid: response.isValid,
            errorMessage: response.errorMessage,
            showError: !response.isValid && response.errorMessage != nil
        )
        
        viewController?.displayAddressValidation(viewModel: viewModel)
    }
    
    func presentAmountValidation(response: SendScene.ValidateAmount.Response) {
        let formattedAmount = response.parsedAmount.flatMap { amount in
            ethFormatter.string(from: NSDecimalNumber(decimal: amount))
        }
        
        let viewModel = SendScene.ValidateAmount.ViewModel(
            isValid: response.isValid,
            errorMessage: response.errorMessage,
            showError: !response.isValid && response.errorMessage != nil,
            formattedAmount: formattedAmount
        )
        
        viewController?.displayAmountValidation(viewModel: viewModel)
    }
    
    func presentGasEstimation(response: SendScene.EstimateGas.Response) {
        let viewModel = SendScene.EstimateGas.ViewModel(
            gasOptions: response.gasOptions,
            errorMessage: response.error,
            showError: response.error != nil
        )
        
        viewController?.displayGasEstimation(viewModel: viewModel)
    }
    
    func presentTransactionPreparation(response: SendScene.PrepareTransaction.Response) {
        var totalAmount: String?
        var totalAmountUSD: String?
        
        if let transaction = response.transaction,
           let gasFee = getCurrentGasFee() {
            
            // ETH 총액 계산 (송금액 + 가스비)
            let total = transaction.amount + gasFee.feeInETH
            totalAmount = ethFormatter.string(from: NSDecimalNumber(decimal: total))
            
            // USD 총액 계산
            let totalUSD = (transaction.amount * getCurrentETHPrice()) + gasFee.feeInUSD
            totalAmountUSD = currencyFormatter.string(from: NSDecimalNumber(decimal: totalUSD))
        }
        
        let viewModel = SendScene.PrepareTransaction.ViewModel(
            transaction: response.transaction,
            isReadyToSend: response.isReadyToSend,
            errorMessage: response.errorMessage,
            showError: response.errorMessage != nil,
            totalAmount: totalAmount,
            totalAmountUSD: totalAmountUSD
        )
        
        viewController?.displayTransactionPreparation(viewModel: viewModel)
    }
    
    func presentTransactionResult(response: SendScene.SendTransaction.Response) {
        let viewModel = SendScene.SendTransaction.ViewModel(
            success: response.success,
            transactionHash: response.transactionHash,
            errorMessage: response.errorMessage,
            showSuccess: response.success && response.transactionHash != nil,
            showError: !response.success && response.errorMessage != nil
        )
        
        viewController?.displayTransactionResult(viewModel: viewModel)
    }
}

// MARK: - Public Helpers

extension SendPresenter {
    
    /// ETH 금액 포맷팅
    func formatETH(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 4
        formatter.maximumFractionDigits = 4
        formatter.locale = Locale(identifier: "ko_KR")
        
        if let formatted = formatter.string(from: amount as NSDecimalNumber) {
            return "\(formatted) ETH"
        }
        return "\(amount) ETH"
    }
    
    /// USD 금액 포맷팅
    func formatUSD(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        formatter.locale = Locale(identifier: "en_US")
        
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }
    
    /// 주소 축약 포맷팅
    func formatAddress(_ address: String) -> String {
        guard address.count > 10 else { return address }
        let prefix = String(address.prefix(6))
        let suffix = String(address.suffix(4))
        return "\(prefix)...\(suffix)"
    }
    
    /// 예상 시간 포맷팅
    func formatEstimatedTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds / 60)
        if minutes < 1 {
            return "< 1분"
        } else if minutes < 60 {
            return "~\(minutes)분"
        } else {
            let hours = minutes / 60
            return "~\(hours)시간"
        }
    }
    
    /// 에러 메시지 현지화
    func localizedErrorMessage(_ error: Error) -> String {
        // 기본 에러 메시지 처리
        if error.localizedDescription.contains("Network") || 
           error.localizedDescription.contains("connection") {
            return "네트워크 연결을 확인해주세요."
        } else if error.localizedDescription.contains("Transaction") {
            return "거래를 처리할 수 없습니다. 다시 시도해주세요."
        }
        return "오류가 발생했습니다. 다시 시도해주세요."
    }
}

// MARK: - Private Helpers

private extension SendPresenter {
    
    /// 현재 선택된 가스비 정보 반환
    func getCurrentGasFee() -> GasFee? {
        // 실제 구현에서는 DataStore에서 가져오거나
        // Interactor를 통해 현재 선택된 가스비를 반환
        return nil
    }
    
    /// 현재 ETH 가격 반환 (USD 계산용)
    func getCurrentETHPrice() -> Decimal {
        // 실제 구현에서는 가격 서비스에서 가져옴
        // 임시로 고정값 사용
        return 2500.0
    }
    
    /// 가스비 레벨에 따른 설명 텍스트
    func getGasLevelDescription(_ gasOptions: GasOptions?) -> [String] {
        guard let gasOptions = gasOptions else {
            return ["", "", ""]
        }
        
        return [
            "느림 • \(gasOptions.slow.formattedFeeETH) • \(formatEstimatedTime(gasOptions.slow.estimatedTime))",
            "보통 • \(gasOptions.normal.formattedFeeETH) • \(formatEstimatedTime(gasOptions.normal.estimatedTime))",
            "빠름 • \(gasOptions.fast.formattedFeeETH) • \(formatEstimatedTime(gasOptions.fast.estimatedTime))"
        ]
    }
}
