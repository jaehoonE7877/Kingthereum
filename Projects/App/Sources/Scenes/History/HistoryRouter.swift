import SwiftUI
import Foundation
import Entity
import Core

// MARK: - Protocols (VIP)

@MainActor
protocol HistoryRoutingLogic {
    func routeToTransactionDetail(transactionHash: String)
    func routeToExportOptions()
    func routeToFilterSettings()
}

// MARK: - Router

@Observable
@MainActor
final class HistoryRouter: HistoryRoutingLogic {
    
    // MARK: - VIP Properties
    
    weak var viewController: HistoryDisplayLogic?
    var dataStore: HistoryDataStore?

    // MARK: - Dependencies
    
    private let appRouter: AppRouter
    
    // MARK: - Initialization
    
    public init(appRouter: AppRouter = RouterCoordinator.shared) {
        self.appRouter = appRouter
    }
    
    // MARK: - Routing Logic
    
    func routeToTransactionDetail(transactionHash: String) {
        // Example of using DataStore to pass data
        appRouter.navigate(to: .wallet(.transactionDetail(transactionID: transactionHash)))
    }
    
    func routeToExportOptions() {
        appRouter.navigate(to: .history(.export))
    }
    
    func routeToFilterSettings() {
        appRouter.navigate(to: .history(.filter))
    }
    
    // MARK: - Modal Presentations & Other Methods
    
    public func showLoading(_ message: String = "로딩 중...") {
        appRouter.showLoading(message)
    }
    
    public func hideLoading() {
        appRouter.dismissModal()
    }
    
    public func showError(_ message: String) {
        let error = AppError.networkError(message)
        appRouter.showError(error)
    }
}
