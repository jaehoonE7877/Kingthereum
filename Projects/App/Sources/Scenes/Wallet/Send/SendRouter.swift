import UIKit
import SwiftUI
import Entity
import Core

// MARK: - SendRouter Stub Implementation

/// SendRouter의 Stub 구현
/// TODO: 실제 네비게이션 요구사항이 명확해지면 complex 버전으로 교체
public final class SendRouter: SendRoutingLogic, SendDataPassing {
    // MARK: - Properties
    
    public weak var viewController: UIViewController?
    public var dataStore: SendDataStore?
    
    // MARK: - 초기화
    
    public init(viewController: UIViewController? = nil) {
        self.viewController = viewController
        Logger.info("SendRouter Stub 초기화 완료")
    }
    
    // MARK: - SendRoutingLogic Stub 구현
    
    public func routeToTransactionSuccess(transactionHash: String) {
        Logger.info("🎉 거래 성공 화면으로 이동 (Stub): \(transactionHash)")
        
        // Stub: 콘솔에만 로그 출력
        Logger.debug("TODO: SendSuccessView로 네비게이션 구현 필요")
    }
    
    public func routeToTransactionHistory() {
        Logger.info("📜 거래 이력 화면으로 이동 (Stub)")
        
        // Stub: 콘솔에만 로그 출력
        Logger.debug("TODO: HistoryView로 네비게이션 구현 필요")
    }
    
    public func routeToSettings() {
        Logger.info("⚙️ 설정 화면으로 이동 (Stub)")
        
        // Stub: 콘솔에만 로그 출력
        Logger.debug("TODO: SettingsView로 네비게이션 구현 필요")
    }
    
    public func dismissView() {
        Logger.info("❌ 화면 닫기 (Stub)")
        
        // Stub: 콘솔에만 로그 출력
        Logger.debug("TODO: dismiss 네비게이션 구현 필요")
    }
    
    public func showErrorAlert(message: String) {
        Logger.error("🚨 에러 알림 표시 (Stub): \(message)")
        
        // Stub: 콘솔에만 로그 출력
        Logger.debug("TODO: UIAlertController 구현 필요")
    }
    
    public func showSuccessToast(message: String) {
        Logger.info("✅ 성공 토스트 표시 (Stub): \(message)")
        
        // Stub: 콘솔에만 로그 출력
        Logger.debug("TODO: Toast UI 구현 필요")
    }
    
    public func routeToTransactionDetail(transactionHash: String) {
        Logger.info("🔍 거래 상세 화면으로 이동 (Stub): \(transactionHash)")
        
        // Stub: 콘솔에만 로그 출력
        Logger.debug("TODO: TransactionDetailView로 네비게이션 구현 필요")
    }
    
    public func routeBack() {
        Logger.info("⬅️ 이전 화면으로 돌아가기 (Stub)")
        
        // Stub: 콘솔에만 로그 출력
        Logger.debug("TODO: 네비게이션 팝 구현 필요")
    }
}

// MARK: - SendRoutingLogic Protocol

public protocol SendRoutingLogic {
    func routeToTransactionSuccess(transactionHash: String)
    func routeToTransactionHistory()
    func routeToSettings()
    func dismissView()
    func showErrorAlert(message: String)
    func showSuccessToast(message: String)
    func routeToTransactionDetail(transactionHash: String)
    func routeBack()
}

// MARK: - SendDataPassing Protocol

public protocol SendDataPassing {
    var dataStore: SendDataStore? { get }
}

// MARK: - SendDataStore

public class SendDataStore {
    // 기본적인 데이터 저장소
    public var currentTransaction: String?
    public var recipientAddress: String?
    public var sendAmount: String?
    
    public init() {
        Logger.debug("SendDataStore 초기화 완료")
    }
}