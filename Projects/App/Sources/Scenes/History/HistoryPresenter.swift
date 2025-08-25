import Foundation
import Entity
import Core

@MainActor
protocol HistoryPresentationLogic {
    func presentTransactionHistory(response: HistoryScene.LoadTransactionHistory.Response)
    func presentRefreshResult(response: HistoryScene.RefreshTransactions.Response)
    func presentFilteredTransactions(response: HistoryScene.FilterTransactions.Response)
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
            let displayModel = HistoryScene.LoadTransactionHistory.ViewModel(
                transactionViewModels: [],
                hasMoreTransactions: false,
                isEmpty: true,
                errorMessage: formatErrorMessage(error)
            )
            viewController?.displayTransactionHistory(viewModel: displayModel)
            return
        }
        
        let transactionViewModels = response.transactions.map { transaction in
            createTransactionViewModel(from: transaction)
        }
        
        let displayModel = HistoryScene.LoadTransactionHistory.ViewModel(
            transactionViewModels: transactionViewModels,
            hasMoreTransactions: response.hasMore,
            isEmpty: response.transactions.isEmpty,
            errorMessage: nil
        )
        
        viewController?.displayTransactionHistory(viewModel: displayModel)
    }
    
    func presentRefreshResult(response: HistoryScene.RefreshTransactions.Response) {
        if let error = response.error {
            let displayModel = HistoryScene.RefreshTransactions.ViewModel(
                transactionViewModels: [],
                refreshMessage: nil,
                errorMessage: formatErrorMessage(error)
            )
            viewController?.displayRefreshResult(viewModel: displayModel)
            return
        }
        
        let transactionViewModels = response.transactions.map { transaction in
            createTransactionViewModel(from: transaction)
        }
        
        let refreshMessage: String?
        if response.newTransactionsCount > 0 {
            refreshMessage = "\(response.newTransactionsCount)개의 새로운 거래가 있습니다"
        } else {
            refreshMessage = "최신 상태입니다"
        }
        
        let displayModel = HistoryScene.RefreshTransactions.ViewModel(
            transactionViewModels: transactionViewModels,
            refreshMessage: refreshMessage,
            errorMessage: nil
        )
        
        viewController?.displayRefreshResult(viewModel: displayModel)
    }
    
    func presentFilteredTransactions(response: HistoryScene.FilterTransactions.Response) {
        let transactionViewModels = response.filteredTransactions.map { transaction in
            createTransactionViewModel(from: transaction)
        }
        
        let filterTitle = response.filterType.rawValue
        let resultCount = "\(response.filteredTransactions.count) / \(response.totalCount)"
        
        let displayModel = HistoryScene.FilterTransactions.ViewModel(
            transactionViewModels: transactionViewModels,
            filterTitle: filterTitle,
            resultCount: resultCount,
            isEmpty: response.filteredTransactions.isEmpty
        )
        
        viewController?.displayFilteredTransactions(viewModel: displayModel)
    }
    
    func presentExportResult(response: HistoryScene.ExportTransactions.Response) {
        if let error = response.error {
            let displayModel = HistoryScene.ExportTransactions.ViewModel(
                shareItems: [],
                successMessage: nil,
                errorMessage: formatErrorMessage(error)
            )
            viewController?.displayExportResult(viewModel: displayModel)
            return
        }
        
        guard let exportData = response.exportData else {
            let displayModel = HistoryScene.ExportTransactions.ViewModel(
                shareItems: [],
                successMessage: nil,
                errorMessage: "내보내기 데이터를 생성할 수 없습니다"
            )
            viewController?.displayExportResult(viewModel: displayModel)
            return
        }
        
        // 임시 파일 생성
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(response.fileName)
        
        do {
            try exportData.write(to: fileURL)
            
            let shareItems: [Any] = [fileURL]
            let successMessage = "\(response.format.rawValue) 파일이 생성되었습니다"
            
            let displayModel = HistoryScene.ExportTransactions.ViewModel(
                shareItems: shareItems,
                successMessage: successMessage,
                errorMessage: nil
            )
            
            viewController?.displayExportResult(viewModel: displayModel)
        } catch {
            let displayModel = HistoryScene.ExportTransactions.ViewModel(
                shareItems: [],
                successMessage: nil,
                errorMessage: "파일 저장에 실패했습니다: \(error.localizedDescription)"
            )
            viewController?.displayExportResult(viewModel: displayModel)
        }
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
        if let networkError = error as? Core.NetworkError {
            switch networkError {
            case .invalidResponse:
                return "유효하지 않은 응답입니다"
            case .clientError(let code):
                return "클라이언트 오류 (HTTP \(code))"
            case .serverError(let code):
                return "서버 오류 (HTTP \(code))"
            case .unexpectedStatusCode(let code):
                return "예상하지 못한 상태 코드 (HTTP \(code))"
            case .unsupportedHTTPMethod(let method):
                return "지원하지 않는 HTTP 메서드: \(method)"
            }
        }
        
        return error.localizedDescription
    }
    
    private func getCurrentWalletAddress() -> String {
        return UserDefaults.standard.string(forKey: Constants.UserDefaults.selectedWalletAddress) ?? ""
    }
}