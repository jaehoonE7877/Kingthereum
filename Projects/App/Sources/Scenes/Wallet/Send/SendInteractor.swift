import Foundation
import UIKit

import Entity

@MainActor
protocol SendBusinessLogic: Sendable {
    func validateAddress(request: SendScene.ValidateAddress.Request)
    func validateAmount(request: SendScene.ValidateAmount.Request)
    func estimateGasFee(request: SendScene.EstimateGas.Request)
    func prepareTransaction(request: SendScene.PrepareTransaction.Request)
    func sendTransaction(request: SendScene.SendTransaction.Request)
}

@MainActor
protocol SendDataStore: Sendable {
    var currentRecipientAddress: String? { get set }
    var currentAmount: Decimal? { get set }
    var currentGasFee: GasFee? { get set }
    var currentTransaction: PendingTransaction? { get set }
}

@MainActor
final class SendInteractor: SendBusinessLogic, SendDataStore {
    var presenter: SendPresentationLogic?
    var worker: SendWorkerProtocol?
    
    // MARK: - Data Store
    var currentRecipientAddress: String?
    var currentAmount: Decimal?
    var currentGasFee: GasFee?
    var currentTransaction: PendingTransaction?
    
    // MARK: - Business Logic
    
    func validateAddress(request: SendScene.ValidateAddress.Request) {
        let worker = self.worker ?? SendWorker()
        
        let address = request.address.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if address.isEmpty {
            let response = SendScene.ValidateAddress.Response(
                isValid: false,
                errorMessage: "주소를 입력해주세요"
            )
            presenter?.presentAddressValidation(response: response)
            return
        }
        
        let isValid = worker.validateEthereumAddress(address)
        
        if isValid {
            currentRecipientAddress = address
            let response = SendScene.ValidateAddress.Response(isValid: true, errorMessage: nil)
            presenter?.presentAddressValidation(response: response)
        } else {
            let response = SendScene.ValidateAddress.Response(
                isValid: false,
                errorMessage: "올바른 이더리움 주소를 입력해주세요"
            )
            presenter?.presentAddressValidation(response: response)
        }
    }
    
    func validateAmount(request: SendScene.ValidateAmount.Request) {
        let worker = self.worker ?? SendWorker()
        
        let amountString = request.amount.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if amountString.isEmpty {
            let response = SendScene.ValidateAmount.Response(
                isValid: false,
                errorMessage: "금액을 입력해주세요",
                parsedAmount: nil
            )
            presenter?.presentAmountValidation(response: response)
            return
        }
        
        guard let amount = Decimal(string: amountString), amount > 0 else {
            let response = SendScene.ValidateAmount.Response(
                isValid: false,
                errorMessage: "유효한 금액을 입력해주세요",
                parsedAmount: nil
            )
            presenter?.presentAmountValidation(response: response)
            return
        }
        
        let currentBalance = worker.getCurrentBalance()
        
        if amount > currentBalance {
            let response = SendScene.ValidateAmount.Response(
                isValid: false,
                errorMessage: "잔액이 부족합니다",
                parsedAmount: amount
            )
            presenter?.presentAmountValidation(response: response)
            return
        }
        
        currentAmount = amount
        let response = SendScene.ValidateAmount.Response(
            isValid: true,
            errorMessage: nil,
            parsedAmount: amount
        )
        presenter?.presentAmountValidation(response: response)
    }
    
    func estimateGasFee(request: SendScene.EstimateGas.Request) {
        let worker = self.worker ?? SendWorker()
        
        guard let gasOptions = worker.estimateGasFee(
            recipientAddress: request.recipientAddress,
            amount: request.amount
        ) else {
            let response = SendScene.EstimateGas.Response(
                gasOptions: nil,
                error: "가스비를 계산할 수 없습니다. 네트워크 상태를 확인해주세요."
            )
            presenter?.presentGasEstimation(response: response)
            return
        }
        
        let response = SendScene.EstimateGas.Response(gasOptions: gasOptions, error: nil)
        presenter?.presentGasEstimation(response: response)
    }
    
    func prepareTransaction(request: SendScene.PrepareTransaction.Request) {
        let worker = self.worker ?? SendWorker()
        
        // 주소 재검증
        guard worker.validateEthereumAddress(request.recipientAddress) else {
            let response = SendScene.PrepareTransaction.Response(
                transaction: nil,
                isReadyToSend: false,
                errorMessage: "잘못된 수신자 주소입니다"
            )
            presenter?.presentTransactionPreparation(response: response)
            return
        }
        
        // 금액 재검증
        guard let amount = Decimal(string: request.amount), amount > 0 else {
            let response = SendScene.PrepareTransaction.Response(
                transaction: nil,
                isReadyToSend: false,
                errorMessage: "잘못된 금액입니다"
            )
            presenter?.presentTransactionPreparation(response: response)
            return
        }
        
        // 잔액 확인 (가스비 포함)
        guard worker.isBalanceSufficient(amount: amount, includingGasFee: request.selectedGasFee.feeInETH) else {
            let response = SendScene.PrepareTransaction.Response(
                transaction: nil,
                isReadyToSend: false,
                errorMessage: "잔액이 부족합니다 (가스비 포함)"
            )
            presenter?.presentTransactionPreparation(response: response)
            return
        }
        
        // 거래 준비
        guard let transaction = worker.prepareTransaction(
            recipientAddress: request.recipientAddress,
            amount: amount,
            gasFee: request.selectedGasFee
        ) else {
            let response = SendScene.PrepareTransaction.Response(
                transaction: nil,
                isReadyToSend: false,
                errorMessage: "거래 준비 중 오류가 발생했습니다"
            )
            presenter?.presentTransactionPreparation(response: response)
            return
        }
        
        currentTransaction = transaction
        currentRecipientAddress = request.recipientAddress
        currentAmount = amount
        currentGasFee = request.selectedGasFee
        
        let response = SendScene.PrepareTransaction.Response(
            transaction: transaction,
            isReadyToSend: true,
            errorMessage: nil
        )
        presenter?.presentTransactionPreparation(response: response)
    }
    
    func sendTransaction(request: SendScene.SendTransaction.Request) {
        let worker = self.worker ?? SendWorker()
        
        Task {
            // 생체 인증
            let biometricResult = await worker.authenticateWithBiometric()
            
            guard biometricResult else {
                let response = SendScene.SendTransaction.Response(
                    success: false,
                    transactionHash: nil,
                    errorMessage: "생체 인증에 실패했습니다"
                )
                presenter?.presentTransactionResult(response: response)
                return
            }
            
            // 거래 전송
            let result = await worker.sendTransaction(request.transaction)
            
            switch result {
            case .success(let transactionHash):
                let response = SendScene.SendTransaction.Response(
                    success: true,
                    transactionHash: transactionHash,
                    errorMessage: nil
                )
                presenter?.presentTransactionResult(response: response)
                
            case .failure(let error):
                let response = SendScene.SendTransaction.Response(
                    success: false,
                    transactionHash: nil,
                    errorMessage: error.localizedDescription
                )
                presenter?.presentTransactionResult(response: response)
            }
        }
    }
}
