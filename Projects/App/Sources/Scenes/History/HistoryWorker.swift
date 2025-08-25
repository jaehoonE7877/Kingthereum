import Foundation
import Entity
import WalletKit
import Core

protocol HistoryWorkerProtocol: Sendable {
    func fetchTransactionHistory(walletAddress: String, limit: Int, offset: Int) async throws -> ([Transaction], Bool)
    func fetchLatestTransactions(walletAddress: String) async throws -> [Transaction]
    func exportTransactions(transactions: [Transaction], format: ExportFormat) async throws -> (Data, String)
}

actor HistoryWorker: HistoryWorkerProtocol {
    private let walletService: WalletService
    private let dateFormatter: ISO8601DateFormatter
    
    init(walletService: WalletService) {
        self.walletService = walletService
        self.dateFormatter = ISO8601DateFormatter()
    }
    
    func fetchTransactionHistory(walletAddress: String, limit: Int, offset: Int) async throws -> ([Transaction], Bool) {
        do {
            let transactions = try await walletService.getTransactionHistory(address: walletAddress)
            
            // 페이지네이션 적용
            let startIndex = offset
            let endIndex = min(startIndex + limit, transactions.count)
            
            guard startIndex < transactions.count else {
                return ([], false)
            }
            
            let pageTransactions = Array(transactions[startIndex..<endIndex])
            let hasMore = endIndex < transactions.count
            
            return (pageTransactions, hasMore)
        } catch {
            Logger.error("Failed to fetch transaction history: \(error)")
            throw error
        }
    }
    
    func fetchLatestTransactions(walletAddress: String) async throws -> [Transaction] {
        do {
            let transactions = try await walletService.getTransactionHistory(address: walletAddress)
            return transactions
        } catch {
            Logger.error("Failed to fetch latest transactions: \(error)")
            throw error
        }
    }
    
    func exportTransactions(transactions: [Transaction], format: ExportFormat) async throws -> (Data, String) {
        let timestamp = dateFormatter.string(from: Date())
        let fileName = "transactions_\(timestamp).\(format.fileExtension)"
        
        switch format {
        case .csv:
            let csvData = try generateCSVData(from: transactions)
            return (csvData, fileName)
            
        case .json:
            let jsonData = try generateJSONData(from: transactions)
            return (jsonData, fileName)
            
        case .pdf:
            let pdfData = try generatePDFData(from: transactions)
            return (pdfData, fileName)
            
        case .xlsx:
            // For now, fall back to CSV format for XLSX
            let csvData = try generateCSVData(from: transactions)
            return (csvData, fileName)
        }
    }
    
    // MARK: - Private Methods
    
    private func generateCSVData(from transactions: [Transaction]) throws -> Data {
        var csvContent = "Date,Hash,From,To,Amount,Symbol,Status,Gas Fee\n"
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        for transaction in transactions {
            let date = formatter.string(from: transaction.timestamp)
            let hash = transaction.hash
            let from = transaction.from
            let to = transaction.to
            let amount = transaction.value
            let symbol = transaction.tokenSymbol ?? "ETH"
            let status = transaction.status.rawValue
            let gasFee = calculateGasFee(transaction: transaction)
            
            let row = "\(date),\(hash),\(from),\(to),\(amount),\(symbol),\(status),\(gasFee)\n"
            csvContent += row
        }
        
        guard let data = csvContent.data(using: .utf8) else {
            throw ExportError.dataConversionFailed
        }
        
        return data
    }
    
    private func calculateGasFee(transaction: Transaction) -> String {
        if let gasUsed = transaction.gasUsed,
           let gasPrice = transaction.gasPrice,
           let gasUsedDecimal = Double(gasUsed),
           let gasPriceDecimal = Double(gasPrice) {
            let gasFee = gasUsedDecimal * gasPriceDecimal / 1_000_000_000_000_000_000 // Convert from wei to ETH
            return String(format: "%.6f", gasFee)
        }
        return "0"
    }
    
    private func generateJSONData(from transactions: [Transaction]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        do {
            return try encoder.encode(transactions)
        } catch {
            throw ExportError.jsonEncodingFailed(error)
        }
    }
    
    private func generatePDFData(from transactions: [Transaction]) throws -> Data {
        // PDF 생성은 복잡하므로 간단한 텍스트 기반 PDF로 구현
        // 실제 프로덕션에서는 PDFKit을 사용하여 더 정교하게 구현
        
        var pdfContent = "TRANSACTION HISTORY\n\n"
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        for (index, transaction) in transactions.enumerated() {
            pdfContent += "Transaction #\(index + 1)\n"
            pdfContent += "Date: \(formatter.string(from: transaction.timestamp))\n"
            pdfContent += "Hash: \(transaction.hash)\n"
            pdfContent += "From: \(transaction.from)\n"
            pdfContent += "To: \(transaction.to)\n"
            pdfContent += "Amount: \(transaction.value) \(transaction.tokenSymbol ?? "ETH")\n"
            pdfContent += "Status: \(transaction.status.rawValue)\n"
            let gasFee = calculateGasFee(transaction: transaction)
            pdfContent += "Gas Fee: \(gasFee) ETH\n"
            pdfContent += "\n---\n\n"
        }
        
        guard let data = pdfContent.data(using: .utf8) else {
            throw ExportError.dataConversionFailed
        }
        
        return data
    }
}

// MARK: - Export Errors

enum ExportError: LocalizedError {
    case dataConversionFailed
    case jsonEncodingFailed(Error)
    case pdfGenerationFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .dataConversionFailed:
            return "데이터 변환에 실패했습니다"
        case .jsonEncodingFailed(let error):
            return "JSON 인코딩에 실패했습니다: \(error.localizedDescription)"
        case .pdfGenerationFailed(let error):
            return "PDF 생성에 실패했습니다: \(error.localizedDescription)"
        }
    }
}