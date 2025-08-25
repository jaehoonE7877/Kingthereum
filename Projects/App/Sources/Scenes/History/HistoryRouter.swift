import SwiftUI
import Foundation
import Entity
import Core

// MARK: - Type Aliases for Entity Module Types

/// Entity 모듈의 WalletTransactionType 사용을 명시
public typealias TransactionType = Entity.WalletTransactionType

/// 거래 내역 화면의 네비게이션을 관리하는 Router
/// SwiftUI의 선언적 패러다임에 맞춘 새로운 Router 패턴 적용
@Observable
@MainActor
public final class HistoryRouter {
    
    // MARK: - Router Dependencies
    
    private let appRouter: AppRouter
    
    // MARK: - Initialization
    
    public init(appRouter: AppRouter = RouterCoordinator.shared) {
        self.appRouter = appRouter
    }
    
    // MARK: - Navigation Methods
    
    /// 거래 상세 화면으로 이동
    public func routeToTransactionDetail(transactionHash: String) {
        print("📊 Navigating to transaction detail: \(transactionHash)")
        appRouter.navigate(to: .wallet(.transactionDetail(transactionID: transactionHash)))
    }
    
    /// 내보내기 옵션 화면으로 이동
    public func routeToExportOptions() {
        print("📊 Navigating to export options")
        appRouter.navigate(to: .history(.export))
    }
    
    /// 필터 설정 화면으로 이동
    public func routeToFilterSettings() {
        print("📊 Navigating to filter settings")
        appRouter.navigate(to: .history(.filter))
    }
    
    /// 거래 검색 화면으로 이동
    public func routeToTransactionSearch() {
        print("📊 Opening transaction search")
        showSearchModal()
    }
    
    /// 통계 화면으로 이동
    public func routeToStatistics() {
        print("📊 Opening statistics")
        showStatisticsModal()
    }
    
    // MARK: - Modal Presentations
    
    /// 거래 검색 모달 표시
    public func showSearchModal() {
        appRouter.presentModal(.alert(
            title: "거래 검색", 
            message: "거래 해시, 주소 또는 금액으로 검색하세요."
        ))
    }
    
    /// 통계 모달 표시
    public func showStatisticsModal() {
        appRouter.presentModal(.alert(
            title: "거래 통계", 
            message: "거래 내역을 분석한 통계를 확인하세요."
        ))
    }
    
    /// 내보내기 확인 다이얼로그 표시
    public func showExportConfirmation(format: ExportFormat, period: String) {
        appRouter.showConfirmation(
            title: "내보내기 확인",
            message: "\(period) 기간의 거래 내역을 \(format.displayName) 형식으로 내보내시겠습니까?",
            action: "내보내기"
        )
    }
    
    /// 필터 적용 확인 다이얼로그 표시
    public func showFilterConfirmation(filter: TransactionFilter) {
        appRouter.showConfirmation(
            title: "필터 적용",
            message: "선택한 필터 조건을 적용하시겠습니까?",
            action: "적용"
        )
    }
    
    /// 로딩 화면 표시
    public func showLoading(_ message: String = "거래 내역 로딩 중...") {
        appRouter.showLoading(message)
    }
    
    /// 로딩 화면 닫기
    public func hideLoading() {
        appRouter.dismissModal()
    }
    
    // MARK: - Error Handling
    
    /// 거래 내역 로딩 오류 표시
    public func showHistoryError(_ message: String) {
        let error = AppError.networkError(message)
        appRouter.showError(error)
    }
    
    /// 내보내기 오류 표시
    public func showExportError(_ message: String) {
        let error = AppError.validationError(message)
        appRouter.showError(error)
    }
    
    /// 검색 오류 표시
    public func showSearchError(_ message: String) {
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
    
    /// 거래 내역 메인으로 돌아가기
    public func goToHistoryRoot() {
        appRouter.popTo(HistoryRoute.self)
    }
}

// MARK: - History Context Data

/// 거래 필터 정보
/// Sendable을 준수하여 Swift 6 Concurrency 안전성 보장
public struct TransactionFilter: Sendable {
    public let dateRange: DateRange?
    public let transactionType: TransactionType?
    public let tokenType: String?
    public let minAmount: Double?
    public let maxAmount: Double?
    public let status: TransactionStatus?
    public let address: String?
    
    public init(
        dateRange: DateRange? = nil,
        transactionType: TransactionType? = nil,
        tokenType: String? = nil,
        minAmount: Double? = nil,
        maxAmount: Double? = nil,
        status: TransactionStatus? = nil,
        address: String? = nil
    ) {
        self.dateRange = dateRange
        self.transactionType = transactionType
        self.tokenType = tokenType
        self.minAmount = minAmount
        self.maxAmount = maxAmount
        self.status = status
        self.address = address
    }
}

/// 날짜 범위
public struct DateRange: Sendable {
    public let startDate: Date
    public let endDate: Date
    
    public init(startDate: Date, endDate: Date) {
        self.startDate = startDate
        self.endDate = endDate
    }
    
    public static var today: DateRange {
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? now
        return DateRange(startDate: startOfDay, endDate: endOfDay)
    }
    
    public static var thisWeek: DateRange {
        let now = Date()
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let endOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.end ?? now
        return DateRange(startDate: startOfWeek, endDate: endOfWeek)
    }
    
    public static var thisMonth: DateRange {
        let now = Date()
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let endOfMonth = calendar.dateInterval(of: .month, for: now)?.end ?? now
        return DateRange(startDate: startOfMonth, endDate: endOfMonth)
    }
}


/// 거래 상태
public enum TransactionStatus: String, CaseIterable, Sendable {
    case pending = "pending"
    case confirmed = "confirmed"
    case failed = "failed"
    case dropped = "dropped"
    
    public var displayName: String {
        switch self {
        case .pending: return "대기 중"
        case .confirmed: return "확인됨"
        case .failed: return "실패"
        case .dropped: return "취소됨"
        }
    }
    
    public var iconName: String {
        switch self {
        case .pending: return "clock.fill"
        case .confirmed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .dropped: return "minus.circle.fill"
        }
    }
    
    public var color: String {
        switch self {
        case .pending: return "orange"
        case .confirmed: return "green"
        case .failed: return "red"
        case .dropped: return "gray"
        }
    }
}

/// 내보내기 형식
public enum ExportFormat: String, CaseIterable, Sendable {
    case csv = "csv"
    case json = "json"
    case pdf = "pdf"
    case xlsx = "xlsx"
    
    public var displayName: String {
        switch self {
        case .csv: return "CSV"
        case .json: return "JSON"
        case .pdf: return "PDF"
        case .xlsx: return "Excel"
        }
    }
    
    public var fileExtension: String {
        return rawValue
    }
    
    public var mimeType: String {
        switch self {
        case .csv: return "text/csv"
        case .json: return "application/json"
        case .pdf: return "application/pdf"
        case .xlsx: return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        }
    }
    
    public var iconName: String {
        switch self {
        case .csv: return "tablecells"
        case .json: return "curlybraces"
        case .pdf: return "doc.richtext"
        case .xlsx: return "tablecells.badge.ellipsis"
        }
    }
}