import SwiftUI
import Foundation
import Entity
import Core

// MARK: - Routing Logic Protocol

@MainActor
protocol SendRoutingLogic {
    func routeToSuccess(transactionHash: String)
    func routeToQRScanner()
    func routeToAddressBook()
    func routeToBiometricAuth()
    func routeToTransactionDetail(transactionHash: String)
    func routeToGasSettings()
    func routeBack()
}

// MARK: - Data Passing Protocol

@MainActor
protocol SendDataPassing {
    var dataStore: SendDataStore? { get }
}

// MARK: - Send Router

@MainActor
final class SendRouter: SendRoutingLogic, SendDataPassing {
    
    // MARK: - VIP References
    weak var viewController: SendDisplayLogic?
    var dataStore: SendDataStore?
    
    // MARK: - Dependencies
    private weak var navigationController: UINavigationController?
    private let coordinator: SendCoordinatorProtocol
    
    // MARK: - Initialization
    
    init(coordinator: SendCoordinatorProtocol) {
        self.coordinator = coordinator
    }
    
    // MARK: - Routing Logic Implementation
    
    func routeToSuccess(transactionHash: String) {
        guard let dataStore = dataStore else { return }
        
        // 성공 화면으로 데이터 전달
        let successData = SendSuccessData(
            transactionHash: transactionHash,
            recipientAddress: dataStore.recipientAddress,
            amount: dataStore.amount,
            gasFee: dataStore.selectedGasFee,
            timestamp: Date()
        )
        
        coordinator.navigateToSuccess(data: successData)
    }
    
    func routeToQRScanner() {
        coordinator.presentQRScanner { [weak self] scannedAddress in
            self?.handleQRScanResult(address: scannedAddress)
        }
    }
    
    func routeToAddressBook() {
        coordinator.presentAddressBook { [weak self] selectedAddress in
            self?.handleAddressSelection(address: selectedAddress)
        }
    }
    
    func routeToBiometricAuth() {
        guard let transaction = dataStore?.pendingTransaction else { return }
        
        coordinator.presentBiometricAuth(for: transaction) { [weak self] success in
            self?.handleBiometricAuthResult(success: success)
        }
    }
    
    func routeToTransactionDetail(transactionHash: String) {
        coordinator.navigateToTransactionDetail(hash: transactionHash)
    }
    
    func routeToGasSettings() {
        coordinator.presentGasSettings { [weak self] selectedGasFee in
            self?.handleGasFeeSelection(gasFee: selectedGasFee)
        }
    }
    
    func routeBack() {
        coordinator.dismissCurrentView()
    }
}

// MARK: - Private Handlers

private extension SendRouter {
    
    /// QR 스캔 결과 처리
    func handleQRScanResult(address: String?) {
        guard let address = address else { return }
        
        // 스캔된 주소를 ViewStore에 전달
        if let viewController = viewController as? SendViewStore {
            viewController.recipientAddress = address
            
            // 주소 유효성 검증 트리거
            let _ = SendScene.ValidateAddress.Request(address: address)
            // Interactor에 검증 요청 (실제 구현에서는 proper delegation 필요)
        }
    }
    
    /// 주소록에서 주소 선택 처리
    func handleAddressSelection(address: String?) {
        guard let address = address else { return }
        
        // 선택된 주소를 ViewStore에 전달
        if let viewController = viewController as? SendViewStore {
            viewController.recipientAddress = address
        }
    }
    
    /// 생체 인증 결과 처리
    func handleBiometricAuthResult(success: Bool) {
        if success {
            // 인증 성공 시 거래 진행
            guard let transaction = dataStore?.pendingTransaction else { return }
            
            _ = SendScene.SendTransaction.Request(transaction: transaction)
            // Interactor에 거래 전송 요청 (실제 구현에서는 proper delegation 필요)
            
        } else {
            // 인증 실패 처리
            if let viewController = viewController as? SendViewStore {
                viewController.errorMessage = "생체 인증에 실패했습니다"
            }
        }
    }
    
    /// 가스비 선택 처리
    func handleGasFeeSelection(gasFee: GasFee?) {
        guard let gasFee = gasFee else { return }
        
        // 선택된 가스비를 데이터 스토어에 저장
        dataStore?.selectedGasFee = gasFee
        
        // ViewStore 업데이트
        if let _ = viewController as? SendViewStore {
            // 가스비에 따른 UI 업데이트 (formattedFeeETH는 Entity.GasFee에 없으므로 임시로 주석)
            // viewController.estimatedGas = gasFee.formattedFeeETH
        }
    }
}

// MARK: - Supporting Models

/// 성공 화면에 전달할 데이터
struct SendSuccessData {
    let transactionHash: String
    let recipientAddress: String
    let amount: String
    let gasFee: GasFee?
    let timestamp: Date
}

// MARK: - Send Coordinator Protocol

@MainActor
protocol SendCoordinatorProtocol: AnyObject {
    func navigateToSuccess(data: SendSuccessData)
    func presentQRScanner(completion: @escaping (String?) -> Void)
    func presentAddressBook(completion: @escaping (String?) -> Void)
    func presentBiometricAuth(for transaction: PendingTransaction, completion: @escaping (Bool) -> Void)
    func navigateToTransactionDetail(hash: String)
    func presentGasSettings(completion: @escaping (GasFee?) -> Void)
    func dismissCurrentView()
}

// MARK: - Default Send Coordinator Implementation

@MainActor
final class DefaultSendCoordinator: SendCoordinatorProtocol {
    
    private weak var presentingViewController: UIViewController?
    
    init(presentingViewController: UIViewController) {
        self.presentingViewController = presentingViewController
    }
    
    func navigateToSuccess(data: SendSuccessData) {
        // SendSuccessView로 네비게이션
        let successView = SendSuccessView(transactionHash: data.transactionHash)
        let hostingController = UIHostingController(rootView: successView)
        
        presentingViewController?.navigationController?.pushViewController(
            hostingController,
            animated: true
        )
    }
    
    func presentQRScanner(completion: @escaping (String?) -> Void) {
        // QR 스캐너 모달 표시
        let qrScanner = QRScannerView { address in
            completion(address)
        }
        let hostingController = UIHostingController(rootView: qrScanner)
        
        presentingViewController?.present(hostingController, animated: true)
    }
    
    func presentAddressBook(completion: @escaping (String?) -> Void) {
        // 주소록 모달 표시
        let addressBook = AddressBookView { address in
            completion(address)
        }
        let hostingController = UIHostingController(rootView: addressBook)
        
        presentingViewController?.present(hostingController, animated: true)
    }
    
    func presentBiometricAuth(for transaction: PendingTransaction, completion: @escaping (Bool) -> Void) {
        // 생체 인증 모달 표시
        let biometricAuth = BiometricAuthView(transaction: transaction) { success in
            completion(success)
        }
        let hostingController = UIHostingController(rootView: biometricAuth)
        
        presentingViewController?.present(hostingController, animated: true)
    }
    
    func navigateToTransactionDetail(hash: String) {
        // 거래 상세 화면으로 네비게이션
        let detailView = TransactionDetailView(transactionHash: hash)
        let hostingController = UIHostingController(rootView: detailView)
        
        presentingViewController?.navigationController?.pushViewController(
            hostingController,
            animated: true
        )
    }
    
    func presentGasSettings(completion: @escaping (GasFee?) -> Void) {
        // 가스 설정 모달 표시
        let gasSettings = GasSettingsView { gasFee in
            completion(gasFee)
        }
        let hostingController = UIHostingController(rootView: gasSettings)
        
        presentingViewController?.present(hostingController, animated: true)
    }
    
    func dismissCurrentView() {
        if presentingViewController?.navigationController?.viewControllers.count ?? 0 > 1 {
            presentingViewController?.navigationController?.popViewController(animated: true)
        } else {
            presentingViewController?.dismiss(animated: true)
        }
    }
}

// MARK: - Placeholder Views (실제 구현 시 별도 파일로 분리)

struct QRScannerView: View {
    let completion: (String?) -> Void
    
    var body: some View {
        Text("QR Scanner")
            .onTapGesture {
                completion("0x742d35ccE4C9CE80cb23E23A808a43dc9aE37C5E")
            }
    }
}

struct AddressBookView: View {
    let completion: (String?) -> Void
    
    var body: some View {
        Text("Address Book")
            .onTapGesture {
                completion("0x742d35ccE4C9CE80cb23E23A808a43dc9aE37C5E")
            }
    }
}

struct BiometricAuthView: View {
    let transaction: PendingTransaction
    let completion: (Bool) -> Void
    
    var body: some View {
        Text("Biometric Auth")
            .onTapGesture {
                completion(true)
            }
    }
}

struct TransactionDetailView: View {
    let transactionHash: String
    
    var body: some View {
        Text("Transaction Detail: \(transactionHash)")
    }
}

struct GasSettingsView: View {
    let completion: (GasFee?) -> Void
    
    var body: some View {
        Text("Gas Settings")
    }
}