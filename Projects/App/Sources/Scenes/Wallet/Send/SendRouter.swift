import SwiftUI
import Foundation
import Entity
import Core

/// 송금 화면의 네비게이션을 관리하는 Router
/// SwiftUI의 선언적 패러다임에 맞춘 새로운 Router 패턴 적용
@Observable
@MainActor
public final class SendRouter {
    
    // MARK: - Router Dependencies
    
    private let appRouter: AppRouter
    
    // MARK: - Initialization
    
    public init(appRouter: AppRouter = RouterCoordinator.shared) {
        self.appRouter = appRouter
    }
    
    // MARK: - Navigation Methods
    
    /// 송금 확인 화면으로 이동
    public func routeToSendConfirmation(transaction: SendTransaction) {
        print("💰 Navigating to send confirmation")
        // 임시로 거래 상세 화면 사용
        appRouter.navigate(to: .wallet(.transactionDetail(transactionID: transaction.id)))
    }
    
    /// 송금 완료 화면으로 이동
    public func routeToSendComplete(transactionHash: String) {
        print("💰 Send completed with hash: \(transactionHash)")
        appRouter.navigate(to: .wallet(.transactionDetail(transactionID: transactionHash)))
    }
    
    /// QR 코드 스캔 화면으로 이동
    public func routeToQRScanner() {
        print("💰 Opening QR scanner")
        // QR 스캐너는 모달로 표시
        showQRScannerModal()
    }
    
    /// 연락처에서 주소 선택 화면으로 이동
    public func routeToAddressBook() {
        print("💰 Opening address book")
        // 주소록도 모달로 표시
        showAddressBookModal()
    }
    
    /// 토큰 선택 화면으로 이동
    public func routeToTokenSelector() {
        print("💰 Opening token selector")
        showTokenSelectorModal()
    }
    
    /// 거래 내역 화면으로 이동
    public func routeToTransactionHistory() {
        print("💰 Navigating to transaction history")
        appRouter.navigate(to: .history(.transactionList))
    }
    
    // MARK: - Modal Presentations
    
    /// QR 코드 스캐너 모달 표시
    public func showQRScannerModal() {
        appRouter.presentModal(.alert(
            title: "QR 스캐너", 
            message: "QR 코드를 스캔하여 주소를 입력하세요."
        ))
    }
    
    /// 주소록 모달 표시
    public func showAddressBookModal() {
        appRouter.presentModal(.alert(
            title: "주소록", 
            message: "저장된 주소에서 선택하세요."
        ))
    }
    
    /// 토큰 선택 모달 표시
    public func showTokenSelectorModal() {
        appRouter.presentModal(.alert(
            title: "토큰 선택", 
            message: "송금할 토큰을 선택하세요."
        ))
    }
    
    /// 송금 확인 다이얼로그 표시
    public func showSendConfirmation(transaction: SendTransaction) {
        appRouter.showConfirmation(
            title: "송금 확인",
            message: "\(transaction.amount) \(transaction.token)를 \(transaction.toAddress)로 송금하시겠습니까?",
            action: "송금"
        )
    }
    
    /// 로딩 화면 표시
    public func showLoading(_ message: String = "송금 처리 중...") {
        appRouter.showLoading(message)
    }
    
    /// 로딩 화면 닫기
    public func hideLoading() {
        appRouter.dismissModal()
    }
    
    // MARK: - Error Handling
    
    /// 송금 오류 표시
    public func showSendError(_ message: String) {
        let error = AppError.walletError(message)
        appRouter.showError(error)
    }
    
    /// 네트워크 오류 표시
    public func showNetworkError(_ message: String) {
        let error = AppError.networkError(message)
        appRouter.showError(error)
    }
    
    /// 유효성 검증 오류 표시
    public func showValidationError(_ message: String) {
        let error = AppError.validationError(message)
        appRouter.showError(error)
    }
    
    // MARK: - Navigation State
    
    /// 뒤로 가기 가능 여부
    public var canGoBack: Bool {
        appRouter.canGoBack
    }
    
    /// 뒤로 가기
    public func goBack() {
        appRouter.goBack()
    }
    
    /// 송금 플로우 취소하고 지갑 메인으로
    public func cancelSendFlow() {
        appRouter.popTo(WalletRoute.self)
    }
}

// MARK: - Send Context Data

/// 송금 거래 정보
/// Sendable을 준수하여 Swift 6 Concurrency 안전성 보장
public struct SendTransaction: Sendable, Identifiable {
    public let id: String
    public let fromAddress: String
    public let toAddress: String
    public let amount: String
    public let token: String
    public let gasPrice: String?
    public let gasLimit: String?
    public let memo: String?
    
    public init(
        id: String = UUID().uuidString,
        fromAddress: String,
        toAddress: String,
        amount: String,
        token: String,
        gasPrice: String? = nil,
        gasLimit: String? = nil,
        memo: String? = nil
    ) {
        self.id = id
        self.fromAddress = fromAddress
        self.toAddress = toAddress
        self.amount = amount
        self.token = token
        self.gasPrice = gasPrice
        self.gasLimit = gasLimit
        self.memo = memo
    }
}

/// 지원되는 토큰 타입
public enum TokenType: String, CaseIterable, Sendable {
    case eth = "ETH"
    case usdc = "USDC"
    case usdt = "USDT"
    case dai = "DAI"
    case link = "LINK"
    
    public var displayName: String {
        switch self {
        case .eth: return "Ethereum"
        case .usdc: return "USD Coin"
        case .usdt: return "Tether"
        case .dai: return "Dai"
        case .link: return "Chainlink"
        }
    }
    
    public var symbol: String {
        return rawValue
    }
    
    public var decimals: Int {
        switch self {
        case .eth: return 18
        case .usdc: return 6
        case .usdt: return 6
        case .dai: return 18
        case .link: return 18
        }
    }
    
    public var iconName: String {
        switch self {
        case .eth: return "ethereum"
        case .usdc: return "dollarsign.circle.fill"
        case .usdt: return "dollarsign.square.fill"
        case .dai: return "d.circle.fill"
        case .link: return "link.circle.fill"
        }
    }
}

/// 송금 상태
public enum SendStatus: String, CaseIterable, Sendable {
    case preparing = "preparing"
    case pending = "pending"
    case confirming = "confirming"
    case confirmed = "confirmed"
    case failed = "failed"
    
    public var displayName: String {
        switch self {
        case .preparing: return "준비 중"
        case .pending: return "대기 중"
        case .confirming: return "확인 중"
        case .confirmed: return "완료"
        case .failed: return "실패"
        }
    }
    
    public var iconName: String {
        switch self {
        case .preparing: return "clock.fill"
        case .pending: return "hourglass"
        case .confirming: return "checkmark.circle"
        case .confirmed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        }
    }
    
    public var color: String {
        switch self {
        case .preparing: return "blue"
        case .pending: return "orange"
        case .confirming: return "blue"
        case .confirmed: return "green"
        case .failed: return "red"
        }
    }
}