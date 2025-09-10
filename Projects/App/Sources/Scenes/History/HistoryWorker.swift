import Foundation
import Entity
import WalletKit
import Core
import os.log
import Factory

/// 🚀 High-Performance History Worker (Cleaned)
/// 🚀 Production-Level History Service with Etherscan API Integration
/// Revolut/N26 수준의 프리미엄 핀테크 블록체인 데이터 통합
actor HistoryService: HistoryServiceProtocol {
    
    // MARK: - Core Dependencies
    
    private let etherscanService: EtherscanService
    private let logger = Logger(subsystem: "com.kingthereum.history", category: "worker")
    
    // MARK: - Multi-Level Caching System
    
    private let memoryCache = NSCache<NSString, CachedTransactionData>()
    private let diskCacheManager = HistoryDiskCacheManager()
    private var realTimeCache: [String: [Transaction]] = [:]
    
    // MARK: - Performance Optimization State
    
    private var pendingRequests: Set<String> = []
    private var lastRequestTime: Date = .distantPast
    private let requestThrottleInterval: TimeInterval = 0.2 // 200ms between requests for Etherscan
    
    // MARK: - Background Processing
    
    private let backgroundQueue = DispatchQueue(label: "history.etherscan.background", qos: .utility)
    private var prefetchTask: Task<Void, Never>?
    
    // MARK: - Cache Configuration
    
    private struct CacheConfig {
        static let memoryTTL: TimeInterval = 300 // 5 minutes
        static let diskTTL: TimeInterval = 1800 // 30 minutes (shorter for blockchain data)
        static let realTimeTTL: TimeInterval = 30 // 30 seconds (blockchain updates frequently)
        static let maxMemoryItems = 2000
        static let maxDiskSize = 100 * 1024 * 1024 // 100MB for blockchain data
    }
    
    init(etherscanService: EtherscanService? = nil) {
        self.etherscanService = etherscanService ?? EtherscanService()
        
        configureCache()
        startBackgroundTasks()
        
        logger.info("🚀 HistoryService initialized with Etherscan API integration")
    }
    
    // MARK: - Cache Configuration
    
    private func configureCache() {
        memoryCache.countLimit = CacheConfig.maxMemoryItems
        memoryCache.totalCostLimit = CacheConfig.maxDiskSize
        
        // 주기적 캐시 정리 (블록체인 데이터는 더 자주 업데이트)
        Timer.scheduledTimer(withTimeInterval: 180, repeats: true) { [weak self] _ in
            Task { [weak self] in await self?.cleanupExpiredCache() }
        }
    }
    
    private func startBackgroundTasks() {
        prefetchTask = Task {
            await backgroundPrefetchLoop()
        }
    }
    
    // MARK: - HistoryServiceProtocol Implementation
    
    func fetchTransactionHistory(walletAddress: String, limit: Int, offset: Int) async throws -> ([Transaction], Bool) {
        let cacheKey = "\(walletAddress)_\(limit)_\(offset)"
        logger.info("🔗 Fetching blockchain transaction history via Etherscan: address=\(walletAddress.prefix(6))...*** limit=\(limit) offset=\(offset)")
        
        await applyRequestThrottle()
        
        // 캐시 우선 확인
        if let cachedResult = await getCachedTransactionHistory(cacheKey: cacheKey) {
            logger.info("✅ Cache hit for key: \(cacheKey)")
            return cachedResult
        }
        
        // 중복 요청 방지
        if pendingRequests.contains(cacheKey) {
            try? await Task.sleep(for: .milliseconds(100))
            return try await fetchTransactionHistory(walletAddress: walletAddress, limit: limit, offset: offset)
        }
        
        pendingRequests.insert(cacheKey)
        defer { pendingRequests.remove(cacheKey) }
        
        do {
            let result = try await withTimeout(seconds: 15) {
                try await performEtherscanRequest(walletAddress: walletAddress, limit: limit, offset: offset)
            }
            await cacheTransactionHistory(cacheKey: cacheKey, result: result)
            logger.info("✅ Etherscan fetch completed for key: \(cacheKey) - \(result.0.count) transactions")
            
            // 지능형 프리페치 트리거
            triggerPrefetch(walletAddress: walletAddress, currentOffset: offset + limit)
            
            return result
        } catch {
            logger.error("❌ Etherscan fetch failed for key \(cacheKey): \(error)")
            throw error
        }
    }
    
    func searchTransactions(walletAddress: String, query: String) async throws -> [Transaction] {
        logger.info("🔍 Searching blockchain transactions for query: \(query.prefix(10))...")

        var searchResults: [Transaction] = []
        var currentPage = 1
        let pageSize = 100 // Etherscan 페이지 크기
        var hasMorePages = true
        let lowercasedQuery = query.lowercased()

        while hasMorePages && currentPage <= 10 { // 최대 10페이지 검색 (1000개 거래)
            do {
                // Etherscan API는 페이지 기반 pagination 사용
                let response = try await etherscanService.getTransactionHistory(
                    address: walletAddress,
                    page: currentPage,
                    offset: pageSize
                )
                
                guard response.isSuccess else {
                    logger.warning("⚠️ Etherscan search failed: \(response.message)")
                    break
                }
                
                let transactions = response.result.map { $0.toTransaction() }
                
                // 쿼리로 필터링
                let filteredBatch = transactions.filter { transaction in
                    transaction.hash.lowercased().contains(lowercasedQuery) ||
                    transaction.from.lowercased().contains(lowercasedQuery) ||
                    transaction.to.lowercased().contains(lowercasedQuery) ||
                    transaction.value.contains(lowercasedQuery)
                }
                
                searchResults.append(contentsOf: filteredBatch)
                
                // 더 이상 결과가 없으면 중단
                hasMorePages = transactions.count == pageSize
                currentPage += 1
                
                // Rate limiting
                try? await Task.sleep(for: .milliseconds(200))
                
            } catch {
                logger.error("❌ Search failed at page \(currentPage): \(error)")
                throw error
            }
        }
        
        logger.info("✅ Blockchain search completed. Found \(searchResults.count) results.")
        return searchResults
    }
    
    func exportTransactions(transactions: [Transaction], format: ExportFormat) async throws -> (Data, String) {
        logger.info("📤 Exporting \(transactions.count) blockchain transactions in \(format.rawValue) format")
        
        return try await withCheckedThrowingContinuation { continuation in
            backgroundQueue.async {
                do {
                    let result = try self.performBlockchainExport(transactions: transactions, format: format)
                    self.logger.info("✅ Blockchain export completed")
                    continuation.resume(returning: result)
                } catch {
                    self.logger.error("❌ Blockchain export failed: \(error)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Etherscan API Integration
    
    private func performEtherscanRequest(walletAddress: String, limit: Int, offset: Int) async throws -> ([Transaction], Bool) {
        // Etherscan은 페이지 기반이므로 offset을 page로 변환
        let page = (offset / limit) + 1
        
        // 일반 ETH 거래와 토큰 거래를 동시에 가져옴
        async let ethTransactions = etherscanService.getTransactionHistory(
            address: walletAddress,
            page: page,
            offset: limit
        )
        
        async let tokenTransactions = etherscanService.getTokenTransferHistory(
            address: walletAddress,
            page: page,
            offset: limit
        )
        
        let (ethResponse, tokenResponse) = try await (ethTransactions, tokenTransactions)
        
        guard ethResponse.isSuccess else {
            throw EtherscanError.serverError(400)
        }
        
        var allTransactions: [Transaction] = []
        
        // ETH 거래 추가
        allTransactions.append(contentsOf: ethResponse.result.map { $0.toTransaction() })
        
        // 토큰 거래 추가 (실패해도 ETH 거래는 반환)
        if tokenResponse.isSuccess {
            allTransactions.append(contentsOf: tokenResponse.result.map { $0.toTransaction() })
        }
        
        // 타임스탬프로 정렬 (최신순)
        allTransactions.sort { $0.timestamp > $1.timestamp }
        
        // 요청한 limit만큼만 반환
        let limitedTransactions = Array(allTransactions.prefix(limit))
        let hasMore = allTransactions.count >= limit
        
        return (limitedTransactions, hasMore)
    }
    
    // MARK: - Caching & Network
    
    private func getCachedTransactionHistory(cacheKey: String) async -> ([Transaction], Bool)? {
        // 메모리 캐시 확인
        if let cachedData = memoryCache.object(forKey: cacheKey as NSString), !cachedData.isExpired {
            logger.debug("💾 Memory cache hit for blockchain data: \(cacheKey)")
            return (cachedData.transactions, cachedData.hasMore)
        }
        
        // 디스크 캐시 확인
        if let diskData = await diskCacheManager.getCachedData(for: cacheKey), !diskData.isExpired {
            logger.debug("💽 Disk cache hit for blockchain data: \(cacheKey)")
            memoryCache.setObject(diskData, forKey: cacheKey as NSString)
            return (diskData.transactions, diskData.hasMore)
        }
        
        return nil
    }
    
    private func cacheTransactionHistory(cacheKey: String, result: ([Transaction], Bool)) async {
        let cachedData = CachedTransactionData(
            transactions: result.0, 
            hasMore: result.1, 
            timestamp: Date()
        )
        
        memoryCache.setObject(cachedData, forKey: cacheKey as NSString)
        
        // 백그라운드로 디스크 캐시 저장
        Task { await diskCacheManager.setCachedData(cachedData, for: cacheKey) }
        
        logger.debug("💾 Cached \(result.0.count) blockchain transactions for key: \(cacheKey)")
    }
    
    private func applyRequestThrottle() async {
        let timeSinceLastRequest = Date().timeIntervalSince(lastRequestTime)
        if timeSinceLastRequest < requestThrottleInterval {
            let sleepTime = requestThrottleInterval - timeSinceLastRequest
            try? await Task.sleep(for: .seconds(sleepTime))
        }
        lastRequestTime = Date()
    }
    
    // MARK: - Intelligent Prefetching for Blockchain Data
    
    private func triggerPrefetch(walletAddress: String, currentOffset: Int) {
        Task {
            await performIntelligentBlockchainPrefetch(
                walletAddress: walletAddress, 
                fromOffset: currentOffset
            )
        }
    }
    
    private func performIntelligentBlockchainPrefetch(walletAddress: String, fromOffset: Int) async {
        let prefetchBatches = 2 // 블록체인 데이터는 2배치만 프리페치
        let batchSize = 50
        
        for batch in 1...prefetchBatches {
            let offset = fromOffset + (batch - 1) * batchSize
            let cacheKey = "\(walletAddress)_\(batchSize)_\(offset)"
            
            // 이미 캐시된 데이터는 건너뛰기
            if await getCachedTransactionHistory(cacheKey: cacheKey) != nil {
                continue
            }
            
            do {
                let result = try await performEtherscanRequest(
                    walletAddress: walletAddress,
                    limit: batchSize,
                    offset: offset
                )
                
                await cacheTransactionHistory(cacheKey: cacheKey, result: result)
                logger.debug("🔮 Prefetched blockchain batch \(batch) with \(result.0.count) transactions")
                
                if !result.1 { break } // 더 이상 데이터가 없음
                
                // Etherscan rate limit 고려
                try? await Task.sleep(for: .milliseconds(300))
                
            } catch {
                logger.warning("⚠️ Blockchain prefetch failed for batch \(batch): \(error)")
                break
            }
        }
    }
    
    private func backgroundPrefetchLoop() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(60)) // 블록체인 데이터는 1분마다 정리
            await cleanupExpiredCache()
            await diskCacheManager.optimizeStorageUsage()
            logger.debug("🧹 Background blockchain cache optimization completed")
        }
    }
    
    // MARK: - Cache Management
    
    private func cleanupExpiredCache() async {
        let now = Date()
        
        // 실시간 캐시 정리 (블록체인 데이터는 30초 TTL)
        realTimeCache = realTimeCache.filter { key, _ in
            guard let timestamp = getCacheTimestamp(for: key) else { return false }
            return now.timeIntervalSince(timestamp) < CacheConfig.realTimeTTL
        }
        
        await diskCacheManager.cleanupExpiredEntries()
        logger.debug("🧹 Blockchain cache cleanup completed")
    }
    
    private func invalidateRelatedCaches(walletAddress: String) async {
        let keysToInvalidate = realTimeCache.keys.filter { $0.contains(walletAddress) }
        
        for key in keysToInvalidate {
            realTimeCache.removeValue(forKey: key)
            memoryCache.removeObject(forKey: key as NSString)
            await diskCacheManager.invalidateCache(for: key)
        }
        
        logger.debug("🗑️ Invalidated \(keysToInvalidate.count) blockchain cache entries for address")
    }
    
    // MARK: - Export with Blockchain-Specific Data
    
    private func performBlockchainExport(transactions: [Transaction], format: ExportFormat) throws -> (Data, String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let fileName = "kingthereum_blockchain_transactions_\(timestamp).\(format.fileExtension)"
        
        let data: Data
        switch format {
        case .csv:
            data = try generateBlockchainCSV(from: transactions)
        case .json:
            data = try generateBlockchainJSON(from: transactions)
        case .pdf:
            data = try generateBlockchainPDF(from: transactions)
        case .xlsx:
            data = try generateBlockchainCSV(from: transactions) // XLSX fallback
        }
        
        return (data, fileName)
    }
    
    private func generateBlockchainCSV(from transactions: [Transaction]) throws -> Data {
        var csvLines: [String] = [
            "Date,Transaction Hash,From Address,To Address,Amount,Symbol,Status,Gas Used,Gas Price,Block Number,Token Contract"
        ]
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        for transaction in transactions {
            let line = [
                formatter.string(from: transaction.timestamp),
                transaction.hash,
                transaction.from,
                transaction.to,
                transaction.value,
                transaction.tokenSymbol ?? "ETH",
                transaction.status.rawValue,
                transaction.gasUsed ?? "0",
                transaction.gasPrice ?? "0",
                String(transaction.blockNumber),
                transaction.tokenName ?? ""
            ].joined(separator: ",")
            csvLines.append(line)
        }
        
        guard let data = csvLines.joined(separator: "\n").data(using: .utf8) else {
            throw ExportError.dataConversionFailed
        }
        
        return data
    }
    
    private func generateBlockchainJSON(from transactions: [Transaction]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let exportData = BlockchainExportData(
            exportDate: Date(),
            totalTransactions: transactions.count,
            transactions: transactions
        )
        
        return try encoder.encode(exportData)
    }
    
    private func generateBlockchainPDF(from transactions: [Transaction]) throws -> Data {
        var content = "KINGTHEREUM BLOCKCHAIN TRANSACTION HISTORY\n"
        content += "Export Date: \(ISO8601DateFormatter().string(from: Date()))\n"
        content += "Total Transactions: \(transactions.count)\n\n"
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        for (index, transaction) in transactions.prefix(1000).enumerated() { // PDF 성능 고려하여 1000개 제한
            content += "═══ Transaction #\(index + 1) ═══\n"
            content += "Date: \(formatter.string(from: transaction.timestamp))\n"
            content += "Hash: \(transaction.hash)\n"
            content += "From: \(transaction.from)\n"
            content += "To: \(transaction.to)\n"
            content += "Amount: \(transaction.value) \(transaction.tokenSymbol ?? "ETH")\n"
            content += "Status: \(transaction.status.rawValue)\n"
            content += "Block: #\(transaction.blockNumber)\n"
            
            if let gasUsed = transaction.gasUsed, let gasPrice = transaction.gasPrice {
                content += "Gas: \(gasUsed) @ \(gasPrice) wei\n"
            }
            
            if let tokenName = transaction.tokenName {
                content += "Token: \(tokenName)\n"
            }
            
            content += "\n"
        }
        
        if transactions.count > 1000 {
            content += "\n... and \(transactions.count - 1000) more transactions"
        }
        
        guard let data = content.data(using: .utf8) else {
            throw ExportError.dataConversionFailed
        }
        
        return data
    }
    
    // MARK: - Utility Methods
    
    private func getCacheTimestamp(for key: String) -> Date? {
        // 실제 구현에서는 별도의 타임스탬프 저장소 사용
        return Date()
    }
    
    private func setCacheTimestamp(for key: String, timestamp: Date) {
        // 실제 구현에서는 별도의 타임스탬프 저장소 사용
    }
    
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(for: .seconds(seconds))
                throw TimeoutError.operationTimeout
            }
            
            guard let result = try await group.next() else {
                throw TimeoutError.operationTimeout
            }
            
            group.cancelAll()
            return result
        }
    }
}

// MARK: - Blockchain Export Data Model

private struct BlockchainExportData: Codable {
    let exportDate: Date
    let totalTransactions: Int
    let blockchainNetwork: String = "Ethereum Mainnet"
    let exportedBy: String = "Kingthereum iOS App"
    let transactions: [Transaction]
}

// MARK: - Supporting Types

final class CachedTransactionData: NSObject {
    let transactions: [Transaction]; let hasMore: Bool; let timestamp: Date
    init(transactions: [Transaction], hasMore: Bool, timestamp: Date) { self.transactions = transactions; self.hasMore = hasMore; self.timestamp = timestamp }
    var isExpired: Bool { Date().timeIntervalSince(timestamp) > 300 }
}

actor HistoryDiskCacheManager {
    private let cacheDirectory: URL
    private let fileManager = FileManager.default
    private let logger = Logger(subsystem: "com.kingthereum.history", category: "disk-cache")
    
    init() {
        let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.cacheDirectory = cacheDir.appendingPathComponent("HistoryCache", isDirectory: true)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func getCachedData(for key: String) async -> CachedTransactionData? {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).cache")
        do {
            let data = try Data(contentsOf: fileURL)
            let cachedData = try JSONDecoder().decode(CachedTransactionDataStorage.self, from: data)
            let result = CachedTransactionData(transactions: cachedData.transactions, hasMore: cachedData.hasMore, timestamp: cachedData.timestamp)
            if !result.isExpired { logger.debug("💽 Disk cache hit for: \(key)"); return result }
            else { try? fileManager.removeItem(at: fileURL); return nil }
        } catch { return nil }
    }
    
    func setCachedData(_ data: CachedTransactionData, for key: String) async {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).cache")
        do {
            let storageData = CachedTransactionDataStorage(transactions: data.transactions, hasMore: data.hasMore, timestamp: data.timestamp)
            let encodedData = try JSONEncoder().encode(storageData)
            try encodedData.write(to: fileURL)
            logger.debug("💽 Cached to disk: \(key)")
        } catch { logger.error("❌ Failed to cache to disk: \(error)") }
    }
    
    func invalidateCache(for key: String) async { let fileURL = cacheDirectory.appendingPathComponent("\(key).cache"); try? fileManager.removeItem(at: fileURL) }
    
    func cleanupExpiredEntries() async {
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.creationDateKey])
            for file in files {
                if let creationDate = try? file.resourceValues(forKeys: [.creationDateKey]).creationDate, Date().timeIntervalSince(creationDate) > 3600 { try? fileManager.removeItem(at: file) }
            }
        } catch { logger.error("❌ Failed to cleanup disk cache: \(error)") }
    }
    
    func optimizeStorageUsage() async {
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey, .creationDateKey])
            let sortedFiles = files.sorted { (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate ?? .distantPast)! < (try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate ?? .distantPast)! }
            let maxSize = 50 * 1024 * 1024; var currentSize = 0
            for file in files { if let fileSize = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize { currentSize += fileSize } }
            if currentSize > maxSize {
                for file in sortedFiles {
                    try? fileManager.removeItem(at: file)
                    if let fileSize = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize { currentSize -= fileSize; if currentSize <= maxSize * 3/4 { break } }
                }
            }
        } catch { logger.error("❌ Failed to optimize storage: \(error)") }
    }
}

private struct CachedTransactionDataStorage: Codable { let transactions: [Transaction]; let hasMore: Bool; let timestamp: Date }
enum TimeoutError: Error { case operationTimeout }
private class MockWalletService: WalletService { override func getTransactionHistory(address: String) async throws -> [Transaction] { return [] } }
enum ExportError: LocalizedError {
    case dataConversionFailed, jsonEncodingFailed(Error), pdfGenerationFailed(Error)
    var errorDescription: String? {
        switch self {
        case .dataConversionFailed: return "데이터 변환에 실패했습니다"
        case .jsonEncodingFailed(let e): return "JSON 인코딩 실패: \(e.localizedDescription)"
        case .pdfGenerationFailed(let e): return "PDF 생성 실패: \(e.localizedDescription)"
        }
    }
}