import Foundation
import SwiftUI
import Entity
import Core

// MARK: - Routing Logic Protocol

@MainActor
protocol SendRoutingLogic: AnyObject {
    func routeToAddressBook()
    func routeToQRScanner()
    func routeToTransactionDetails(transactionHash: String)
    func routeToWalletHome()
    func routeToSettings()
    func routeToHistory()
    func routeBack()
}

// MARK: - Data Passing Protocol

@MainActor
protocol SendDataPassing: AnyObject {
    var dataStore: SendDataStore? { get set }
}

// MARK: - Send Router

@MainActor
final class SendRouter: SendRoutingLogic, SendDataPassing {
    weak var viewController: UIViewController?
    var dataStore: SendDataStore?
    
    // MARK: - Routing Methods
    
    func routeToAddressBook() {
        Logger.debug("🧭 [SendRouter] Routing to address book")
        
        // TODO: Implement address book navigation
        // This would typically present an address book modal or push to address book scene
        
        // For now, show a placeholder alert
        showComingSoonAlert(feature: "주소록")
    }
    
    func routeToQRScanner() {
        Logger.debug("🧭 [SendRouter] Routing to QR scanner")
        
        // TODO: Implement QR scanner navigation
        // This would present the QR code scanner
        
        // For now, show a placeholder alert
        showComingSoonAlert(feature: "QR 코드 스캐너")
    }
    
    func routeToTransactionDetails(transactionHash: String) {
        Logger.debug("🧭 [SendRouter] Routing to transaction details: \(transactionHash)")
        
        // Store transaction hash for the next scene
        dataStore?.transactionHash = transactionHash
        
        // TODO: Implement transaction details navigation
        // This would push to a transaction details scene or open in browser
        
        // For now, copy to clipboard and show alert
        UIPasteboard.general.string = transactionHash
        showTransactionHashCopiedAlert(hash: transactionHash)
    }
    
    func routeToWalletHome() {
        Logger.debug("🧭 [SendRouter] Routing to wallet home")
        
        // Dismiss the send modal and return to wallet home
        viewController?.dismiss(animated: true)
    }
    
    func routeToSettings() {
        Logger.debug("🧭 [SendRouter] Routing to settings")
        
        // TODO: Implement settings navigation
        // This would typically present settings or push to settings scene
        
        showComingSoonAlert(feature: "설정")
    }
    
    func routeToHistory() {
        Logger.debug("🧭 [SendRouter] Routing to history")
        
        // Dismiss current view and navigate to history tab
        viewController?.dismiss(animated: true) {
            // TODO: Switch to history tab
            // This would require access to the main tab controller
            NotificationCenter.default.post(name: .switchToHistoryTab, object: nil)
        }
    }
    
    func routeBack() {
        Logger.debug("🧭 [SendRouter] Routing back")
        
        // Handle back navigation
        if let navigationController = viewController?.navigationController {
            navigationController.popViewController(animated: true)
        } else {
            viewController?.dismiss(animated: true)
        }
    }
    
    // MARK: - Helper Methods
    
    private func showComingSoonAlert(feature: String) {
        guard let viewController = viewController else { return }
        
        let alert = UIAlertController(
            title: "준비 중",
            message: "\(feature) 기능은 곧 출시될 예정입니다.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        
        viewController.present(alert, animated: true)
    }
    
    private func showTransactionHashCopiedAlert(hash: String) {
        guard let viewController = viewController else { return }
        
        let shortHash = String(hash.prefix(10)) + "..." + String(hash.suffix(10))
        
        let alert = UIAlertController(
            title: "거래 완료",
            message: "거래 해시가 클립보드에 복사되었습니다.\n\(shortHash)",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        
        alert.addAction(UIAlertAction(title: "Etherscan에서 보기", style: .default) { [weak self] _ in
            self?.openEtherscan(transactionHash: hash)
        })
        
        viewController.present(alert, animated: true)
    }
    
    private func openEtherscan(transactionHash: String) {
        // Open transaction in Etherscan
        let etherscanURL = "https://etherscan.io/tx/\(transactionHash)"
        
        if let url = URL(string: etherscanURL) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Send Data Store

final class SendDataStore {
    // Transaction data
    var recipientAddress: String?
    var amount: Decimal?
    var selectedGasFee: GasFee?
    var pendingTransaction: PendingTransaction?
    var transactionHash: String?
    
    // User preferences
    var preferredCurrency: CurrencyType = .USD
    var preferredGasPriority: GasPriority = .normal
    
    // Navigation state
    var previousStep: SendStep?
    var canGoBack: Bool = true
    
    // Validation state
    var isAddressValidated: Bool = false
    var isAmountValidated: Bool = false
    var hasEstimatedGas: Bool = false
    
    // Session data
    var sessionStartTime: Date = Date()
    var attemptCount: Int = 0
    
    func reset() {
        recipientAddress = nil
        amount = nil
        selectedGasFee = nil
        pendingTransaction = nil
        transactionHash = nil
        previousStep = nil
        isAddressValidated = false
        isAmountValidated = false
        hasEstimatedGas = false
        sessionStartTime = Date()
        attemptCount = 0
    }
    
    func incrementAttempt() {
        attemptCount += 1
    }
    
    var sessionDuration: TimeInterval {
        return Date().timeIntervalSince(sessionStartTime)
    }
}

// MARK: - Navigation Extensions

extension Notification.Name {
    static let switchToHistoryTab = Notification.Name("switchToHistoryTab")
    static let switchToWalletTab = Notification.Name("switchToWalletTab")
    static let refreshWalletBalance = Notification.Name("refreshWalletBalance")
}

// MARK: - Send Router Factory

enum SendRouterFactory {
    @MainActor
    static func makeSendRouter() -> (SendRouter, SendDataStore) {
        let router = SendRouter()
        let dataStore = SendDataStore()
        
        router.dataStore = dataStore
        
        return (router, dataStore)
    }
}
