import SwiftUI
import Foundation
import Entity
import Core

/// 수신 화면의 네비게이션을 관리하는 Router
/// SwiftUI의 선언적 패러다임에 맞춘 새로운 Router 패턴 적용
@Observable
@MainActor
public final class ReceiveRouter {
    
    // MARK: - Router Dependencies
    
    private let appRouter: AppRouter
    
    // MARK: - Initialization
    
    public init(appRouter: AppRouter = RouterCoordinator.shared) {
        self.appRouter = appRouter
    }
    
    // MARK: - Navigation Methods
    
    /// QR 코드 공유 화면으로 이동
    public func routeToQRShare(address: String) {
        print("📥 Opening QR share for address: \(address)")
        showQRShareModal(address: address)
    }
    
    /// 주소 공유 화면으로 이동
    public func routeToAddressShare(address: String) {
        print("📥 Opening address share for: \(address)")
        showAddressShareModal(address: address)
    }
    
    /// 요청 금액 설정 화면으로 이동
    public func routeToRequestAmount() {
        print("📥 Opening amount request")
        showAmountRequestModal()
    }
    
    /// 결제 링크 생성 화면으로 이동
    public func routeToPaymentLink() {
        print("📥 Opening payment link generator")
        showPaymentLinkModal()
    }
    
    /// 거래 내역 화면으로 이동
    public func routeToTransactionHistory() {
        print("📥 Navigating to transaction history")
        appRouter.navigate(to: .history(.transactionList))
    }
    
    /// 토큰 선택 화면으로 이동
    public func routeToTokenSelector() {
        print("📥 Opening token selector")
        showTokenSelectorModal()
    }
    
    // MARK: - Modal Presentations
    
    /// QR 코드 공유 모달 표시
    public func showQRShareModal(address: String) {
        appRouter.presentModal(.alert(
            title: "QR 코드", 
            message: "지갑 주소의 QR 코드입니다.\n\n\(address)"
        ))
    }
    
    /// 주소 공유 모달 표시
    public func showAddressShareModal(address: String) {
        appRouter.presentModal(.alert(
            title: "주소 공유", 
            message: "지갑 주소를 복사하거나 공유하세요.\n\n\(address)"
        ))
    }
    
    /// 금액 요청 모달 표시
    public func showAmountRequestModal() {
        appRouter.presentModal(.alert(
            title: "금액 요청", 
            message: "요청할 금액과 토큰을 선택하세요."
        ))
    }
    
    /// 결제 링크 모달 표시
    public func showPaymentLinkModal() {
        appRouter.presentModal(.alert(
            title: "결제 링크", 
            message: "결제 링크를 생성하여 공유하세요."
        ))
    }
    
    /// 토큰 선택 모달 표시
    public func showTokenSelectorModal() {
        appRouter.presentModal(.alert(
            title: "토큰 선택", 
            message: "수신할 토큰을 선택하세요."
        ))
    }
    
    /// 주소 복사 완료 알림
    public func showAddressCopied() {
        appRouter.presentModal(.alert(
            title: "복사 완료", 
            message: "주소가 클립보드에 복사되었습니다."
        ))
    }
    
    /// 로딩 화면 표시
    public func showLoading(_ message: String = "처리 중...") {
        appRouter.showLoading(message)
    }
    
    /// 로딩 화면 닫기
    public func hideLoading() {
        appRouter.dismissModal()
    }
    
    // MARK: - Error Handling
    
    /// 수신 오류 표시
    public func showReceiveError(_ message: String) {
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
    
    /// 수신 플로우 취소하고 지갑 메인으로
    public func cancelReceiveFlow() {
        appRouter.popTo(WalletRoute.self)
    }
}

// MARK: - Receive Context Data

/// 수신 요청 정보
/// Sendable을 준수하여 Swift 6 Concurrency 안전성 보장
public struct ReceiveRequest: Sendable, Identifiable {
    public let id: String
    public let walletAddress: String
    public let amount: String?
    public let token: String?
    public let memo: String?
    public let expiresAt: Date?
    public let paymentLink: String?
    
    public init(
        id: String = UUID().uuidString,
        walletAddress: String,
        amount: String? = nil,
        token: String? = nil,
        memo: String? = nil,
        expiresAt: Date? = nil,
        paymentLink: String? = nil
    ) {
        self.id = id
        self.walletAddress = walletAddress
        self.amount = amount
        self.token = token
        self.memo = memo
        self.expiresAt = expiresAt
        self.paymentLink = paymentLink
    }
}

/// 결제 링크 타입
public enum PaymentLinkType: String, CaseIterable, Sendable {
    case simple = "simple"
    case withAmount = "with_amount"
    case recurring = "recurring"
    case oneTime = "one_time"
    
    public var displayName: String {
        switch self {
        case .simple: return "단순 링크"
        case .withAmount: return "금액 포함"
        case .recurring: return "정기 결제"
        case .oneTime: return "일회성"
        }
    }
    
    public var description: String {
        switch self {
        case .simple: return "지갑 주소만 포함된 링크"
        case .withAmount: return "요청 금액이 포함된 링크"
        case .recurring: return "정기적으로 결제를 요청하는 링크"
        case .oneTime: return "한 번만 사용 가능한 링크"
        }
    }
    
    public var iconName: String {
        switch self {
        case .simple: return "link"
        case .withAmount: return "dollarsign.circle"
        case .recurring: return "repeat"
        case .oneTime: return "1.circle"
        }
    }
}

/// QR 코드 설정
public struct QRCodeSettings: Sendable {
    public let size: Int
    public let errorCorrection: QRCodeErrorCorrection
    public let includeLabel: Bool
    public let customLabel: String?
    
    public init(
        size: Int = 300,
        errorCorrection: QRCodeErrorCorrection = .medium,
        includeLabel: Bool = true,
        customLabel: String? = nil
    ) {
        self.size = size
        self.errorCorrection = errorCorrection
        self.includeLabel = includeLabel
        self.customLabel = customLabel
    }
}

/// QR 코드 오류 정정 레벨
public enum QRCodeErrorCorrection: String, CaseIterable, Sendable {
    case low = "L"
    case medium = "M"
    case quartile = "Q"
    case high = "H"
    
    public var displayName: String {
        switch self {
        case .low: return "낮음 (7%)"
        case .medium: return "중간 (15%)"
        case .quartile: return "높음 (25%)"
        case .high: return "최고 (30%)"
        }
    }
    
    public var description: String {
        switch self {
        case .low: return "가장 작은 크기, 최소 오류 정정"
        case .medium: return "일반적인 사용에 적합"
        case .quartile: return "더 나은 오류 정정"
        case .high: return "최고 오류 정정, 큰 크기"
        }
    }
}