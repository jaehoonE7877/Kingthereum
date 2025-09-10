import Foundation
import Entity
import Core

@MainActor
protocol HistoryPresentationLogic: AnyObject {
    func presentTransactionHistory(response: HistoryScene.LoadTransactionHistory.Response)
    func presentMoreTransactions(response: HistoryScene.LoadMoreTransactions.Response) // NEW
    func presentRefreshedHistory(response: HistoryScene.RefreshTransactionHistory.Response) // NEW
    func presentFilteredTransactions(response: HistoryScene.FilterTransactions.Response)
    func presentSearchResults(response: HistoryScene.SearchTransactions.Response) // NEW
    func presentExportResult(response: HistoryScene.ExportTransactions.Response)
}

@MainActor
final class HistoryPresenter: HistoryPresentationLogic {
    weak var viewController: HistoryDisplayLogic?
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()
    
    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 8
        formatter.minimumFractionDigits = 0
        return formatter
    }()
    
    func presentTransactionHistory(response: HistoryScene.LoadTransactionHistory.Response) {
        if let error = response.error {
            let viewModel = HistoryScene.LoadTransactionHistory.ViewModel(
                transactionViewModels: [],
                hasMoreTransactions: false,
                isEmpty: true,
                errorMessage: formatErrorMessage(error),
                isRealTimeEnabled: false
            )
            viewController?.displayTransactionHistory(viewModel: viewModel)
            return
        }
        
        let transactionViewModels = response.transactions.map { createTransactionViewModel(from: $0) }
        
        let viewModel = HistoryScene.LoadTransactionHistory.ViewModel(
            transactionViewModels: transactionViewModels,
            hasMoreTransactions: response.hasMore,
            isEmpty: response.transactions.isEmpty,
            errorMessage: nil,
            isRealTimeEnabled: response.isRealTimeEnabled
        )
        
        viewController?.displayTransactionHistory(viewModel: viewModel)
    }

    func presentMoreTransactions(response: HistoryScene.LoadMoreTransactions.Response) {
        if let error = response.error {
            let viewModel = HistoryScene.LoadMoreTransactions.ViewModel(
                newTransactionViewModels: [],
                hasMoreTransactions: false,
                errorMessage: formatErrorMessage(error)
            )
            viewController?.displayMoreTransactions(viewModel: viewModel)
            return
        }

        let newViewModels = response.newTransactions.map { createTransactionViewModel(from: $0) }
        let viewModel = HistoryScene.LoadMoreTransactions.ViewModel(
            newTransactionViewModels: newViewModels,
            hasMoreTransactions: response.hasMore,
            errorMessage: nil
        )
        viewController?.displayMoreTransactions(viewModel: viewModel)
    }

    func presentRefreshedHistory(response: HistoryScene.RefreshTransactionHistory.Response) {
        if let error = response.error {
            let viewModel = HistoryScene.RefreshTransactionHistory.ViewModel(
                transactionViewModels: [],
                hasMore: false,
                errorMessage: formatErrorMessage(error)
            )
            viewController?.displayRefreshedHistory(viewModel: viewModel)
            return
        }

        let viewModels = response.transactions.map { createTransactionViewModel(from: $0) }
        let viewModel = HistoryScene.RefreshTransactionHistory.ViewModel(
            transactionViewModels: viewModels,
            hasMore: response.hasMore,
            errorMessage: nil
        )
        viewController?.displayRefreshedHistory(viewModel: viewModel)
    }
    
    func presentFilteredTransactions(response: HistoryScene.FilterTransactions.Response) {
        let transactionViewModels = response.filteredTransactions.map { createTransactionViewModel(from: $0) }
        
        let filterTitle = response.filterType.rawValue
        let resultCount = "\(response.filteredTransactions.count) / \(response.totalCount)"
        
        let viewModel = HistoryScene.FilterTransactions.ViewModel(
            transactionViewModels: transactionViewModels,
            filterTitle: filterTitle,
            resultCount: resultCount,
            isEmpty: response.filteredTransactions.isEmpty
        )
        
        viewController?.displayFilteredTransactions(viewModel: viewModel)
    }

    func presentSearchResults(response: HistoryScene.SearchTransactions.Response) {
        if let error = response.error {
            let viewModel = HistoryScene.SearchTransactions.ViewModel(
                transactionViewModels: [],
                query: response.query,
                errorMessage: formatErrorMessage(error)
            )
            viewController?.displaySearchResults(viewModel: viewModel)
            return
        }

        let viewModels = response.results.map { createTransactionViewModel(from: $0) }
        let viewModel = HistoryScene.SearchTransactions.ViewModel(
            transactionViewModels: viewModels,
            query: response.query,
            errorMessage: nil
        )
        viewController?.displaySearchResults(viewModel: viewModel)
    }
    
    func presentExportResult(response: HistoryScene.ExportTransactions.Response) {
        if let error = response.error {
            let viewModel = HistoryScene.ExportTransactions.ViewModel(
                shareItems: [],
                successMessage: nil,
                errorMessage: formatErrorMessage(error)
            )
            viewController?.displayExportResult(viewModel: viewModel)
            return
        }
        
        guard let exportURL = response.exportURL else {
            let viewModel = HistoryScene.ExportTransactions.ViewModel(
                shareItems: [],
                successMessage: nil,
                errorMessage: "내보내기 데이터를 생성할 수 없습니다"
            )
            viewController?.displayExportResult(viewModel: viewModel)
            return
        }
        
        let shareItems: [Any] = [exportURL]
        let successMessage = "\(response.format.rawValue) 파일이 생성되었습니다"
        
        let viewModel = HistoryScene.ExportTransactions.ViewModel(
            shareItems: shareItems,
            successMessage: successMessage,
            errorMessage: nil
        )
        
        viewController?.displayExportResult(viewModel: viewModel)
    }
    
    // MARK: - Private Methods
    
    private func createTransactionViewModel(from transaction: Transaction) -> TransactionViewModel {
        let title: String
        let subtitle: String
        var statusIcon: String
        var statusColor: String
        
        let currentAddress = getCurrentWalletAddress()
        let isIncoming = transaction.to.lowercased() == currentAddress.lowercased()
        if isIncoming {
            title = "받음"
            subtitle = "From: \(formatAddress(transaction.from))"
            statusIcon = "arrow.down.circle.fill"
            statusColor = "systemGreen"
        } else {
            title = "보냄"
            subtitle = "To: \(formatAddress(transaction.to))"
            statusIcon = "arrow.up.circle.fill"
            statusColor = "systemRed"
        }
        
        // 상태에 따른 아이콘 오버라이드
        switch transaction.status {
        case .pending:
            statusIcon = "clock.circle.fill"
            statusColor = "systemOrange"
        case .failed:
            statusIcon = "exclamationmark.circle.fill"
            statusColor = "systemRed"
        default:
            break
        }
        
        let amount = Decimal(string: transaction.value) ?? 0
        let amountString = formatAmount(amount, symbol: transaction.tokenSymbol ?? "ETH")
        let formattedDate = dateFormatter.string(from: transaction.timestamp)
        
        return TransactionViewModel(
            id: transaction.hash,
            title: title,
            subtitle: subtitle,
            amount: amountString,
            formattedDate: formattedDate,
            statusIcon: statusIcon,
            statusColor: statusColor,
            isIncoming: isIncoming
        )
    }
    
    private func formatAddress(_ address: String) -> String {
        if address.count > 10 {
            let start = String(address.prefix(6))
            let end = String(address.suffix(4))
            return "\(start)...\(end)"
        }
        return address
    }
    
    private func formatAmount(_ amount: Decimal, symbol: String) -> String {
        let formatted = currencyFormatter.string(from: amount as NSDecimalNumber) ?? "0"
        return "\(formatted) \(symbol)"
    }
    
    private func formatErrorMessage(_ error: Error) -> String {
        if let networkError = error as? NetworkError {
            return networkError.errorDescription ?? error.localizedDescription
        }
        
        return error.localizedDescription
    }
    
    private func getCurrentWalletAddress() -> String {
        return UserDefaults.standard.string(forKey: Constants.UserDefaults.selectedWalletAddress) ?? ""
    }
}