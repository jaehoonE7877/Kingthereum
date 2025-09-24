import Foundation

import Core
import Entity
import WalletKit

import Factory

/// 🚀 High-Performance History Worker (Cleaned)
/// 🚀 Production-Level History Service with Etherscan API Integration
/// Revolut/N26 수준의 프리미엄 핀테크 블록체인 데이터 통합
public actor HistoryService: HistoryServiceProtocol {
    
    // MARK: - Core Dependencies
    
    @Injected(\.etherscanService) private var etherscanService: EtherscanService
    
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
    
    public init() {
        Task {
            await self.initializeAsync()
        }
    }
    
    private func initializeAsync() async {
        configureCache()
        startBackgroundTasks()
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
        Logger.info("🔗 Fetching blockchain transaction history via Etherscan: address=\(walletAddress.prefix(6))...*** limit=\(limit) offset=\(offset)")
        
        await applyRequestThrottle()
        
        // 캐시 우선 확인
        if let cachedResult = await getCachedTransactionHistory(cacheKey: cacheKey) {
            Logger.info("✅ Cache hit for key: \(cacheKey)")
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
                try await self.performEtherscanRequest(walletAddress: walletAddress, limit: limit, offset: offset)
            }
            await cacheTransactionHistory(cacheKey: cacheKey, result: result)
            Logger.info("✅ Etherscan fetch completed for key: \(cacheKey) - \(result.0.count) transactions")
            
            // 지능형 프리페치 트리거
            triggerPrefetch(walletAddress: walletAddress, currentOffset: offset + limit)
            
            return result
        } catch {
            Logger.error("❌ Etherscan fetch failed for key \(cacheKey): \(error)")
            throw error
        }
    }
    
    func searchTransactions(walletAddress: String, query: String) async throws -> [Transaction] {
        Logger.info("🔍 Searching blockchain transactions for query: \(query.prefix(10))...")

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
                    Logger.warning("⚠️ Etherscan search failed: \(response.message)")
                    break
                }
                
                let transactions = response.result.map { $0.toTransaction() }
                
                // 쿼리로 필터링
                let filteredBatch = transactions.filter {
                    $0.hash.lowercased().contains(lowercasedQuery) ||
                    $0.from.lowercased().contains(lowercasedQuery) ||
                    $0.to.lowercased().contains(lowercasedQuery) ||
                    $0.value.contains(lowercasedQuery)
                }
                
                searchResults.append(contentsOf: filteredBatch)
                
                // 더 이상 결과가 없으면 중단
                hasMorePages = transactions.count == pageSize
                currentPage += 1
                
                // Rate limiting
                try? await Task.sleep(for: .milliseconds(200))
                
            } catch {
                Logger.error("❌ Search failed at page \(currentPage): \(error)")
                throw error
            }
        }
        
        Logger.info("✅ Blockchain search completed. Found \(searchResults.count) results.")
        return searchResults
    }
    
    func exportTransactions(transactions: [Transaction], format: ExportFormat) async throws -> (Data, String) {
        Logger.info("📤 Exporting \(transactions.count) blockchain transactions in \(format.rawValue) format")
        
        do {
            let result = try await Task.detached(priority: .utility) {
                try self.performBlockchainExport(transactions: transactions, format: format)
            }.value
            Logger.info("✅ Blockchain export completed")
            return result
        } catch {
            Logger.error("❌ Blockchain export failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Etherscan API Integration
    
    private func performEtherscanRequest(walletAddress: String, limit: Int, offset: Int) async throws -> ([Transaction], Bool) {
        // API 키 확인
        guard await EtherscanService.isAPIKeyConfigured else {
            Logger.error("❌ Etherscan API key not configured")
            throw EtherscanError.apiKeyInvalid
        }
        
        // Etherscan은 페이지 기반이므로 offset을 page로 변환
        let page = (offset / limit) + 1
        
        // 순차적으로 API 요청 (Rate limit 방지)
        let ethResponse = try await etherscanService.getTransactionHistory(
            address: walletAddress,
            page: page,
            offset: limit
        )
        
        // Rate limit 방지를 위한 딜레이 (2req/sec 제한 준수)
        try await Task.sleep(nanoseconds: 600_000_000) // 0.6초 대기
        
        let tokenResponse = try await etherscanService.getTokenTransferHistory(
            address: walletAddress,
            page: page,
            offset: limit
        )
        
        // 응답 유효성 검사 - "No transactions found"는 정상 응답
        if ethResponse.message.lowercased().contains("no transactions found") {
            Logger.info("ℹ️ No ETH transactions found for address (this is normal)")
            print("ℹ️ [INFO] No ETH transactions found for address (this is normal)")
        } else if !ethResponse.isSuccess {
            Logger.error("❌ ETH transaction API failed: \(ethResponse.message)")
            print("❌ [ERROR] ETH transaction API failed: \(ethResponse.message)")
            throw EtherscanError.serverError(400)
        }
        
        var allTransactions: [Transaction] = []
        
        // ETH 거래 추가 (안전한 결과만)
        allTransactions.append(contentsOf: ethResponse.safeResult.map { $0.toTransaction() })
        
        // 토큰 거래 추가 (실패해도 ETH 거래는 반환)
        if tokenResponse.message.lowercased().contains("no transactions found") {
            Logger.info("ℹ️ No token transactions found for address (this is normal)")
            print("ℹ️ [INFO] No token transactions found for address (this is normal)")
        } else if tokenResponse.isSuccess {
            allTransactions.append(contentsOf: tokenResponse.safeResult.map { $0.toTransaction() })
            Logger.info("✅ Loaded \(tokenResponse.safeResult.count) token transactions")
            print("✅ [INFO] Loaded \(tokenResponse.safeResult.count) token transactions")
        } else {
            Logger.warning("⚠️ Token transaction API failed: \(tokenResponse.message)")
            print("⚠️ [WARNING] Token transaction API failed: \(tokenResponse.message)")
        }
        
        // 타임스탬프로 정렬 (최신순)
        allTransactions.sort { $0.timestamp > $1.timestamp }
        
        // 중복 제거 (같은 해시의 거래)
        let uniqueTransactions = Dictionary(grouping: allTransactions, by: { $0.hash })
            .compactMapValues { $0.first }
            .values
            .sorted { $0.timestamp > $1.timestamp }
        
        // 요청한 limit만큼만 반환
        let limitedTransactions = Array(uniqueTransactions.prefix(limit))
        let hasMore = uniqueTransactions.count >= limit
        
        Logger.info("✅ Processed \(allTransactions.count) raw → \(uniqueTransactions.count) unique → \(limitedTransactions.count) final transactions")
        
        return (limitedTransactions, hasMore)
    }
    
    // MARK: - Caching & Network
    
    private func getCachedTransactionHistory(cacheKey: String) async -> ([Transaction], Bool)? {
        // 메모리 캐시 확인
        if let cachedData = memoryCache.object(forKey: cacheKey as NSString), !cachedData.isExpired {
            Logger.debug("💾 Memory cache hit for blockchain data: \(cacheKey)")
            return (cachedData.transactions, cachedData.hasMore)
        }
        
        // 디스크 캐시 확인
        if let diskData = await diskCacheManager.getCachedData(for: cacheKey), !diskData.isExpired {
            Logger.debug("💽 Disk cache hit for blockchain data: \(cacheKey)")
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
        
        Logger.debug("💾 Cached \(result.0.count) blockchain transactions for key: \(cacheKey)")
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
                Logger.debug("🔮 Prefetched blockchain batch \(batch) with \(result.0.count) transactions")
                
                if !result.1 { break } // 더 이상 데이터가 없음
                
                // Etherscan rate limit 고려
                try? await Task.sleep(for: .milliseconds(300))
                
            } catch {
                Logger.warning("⚠️ Blockchain prefetch failed for batch \(batch): \(error)")
                break
            }
        }
    }
    
    private func backgroundPrefetchLoop() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(60)) // 블록체인 데이터는 1분마다 정리
            await cleanupExpiredCache()
            await diskCacheManager.optimizeStorageUsage()
            Logger.debug("🧹 Background blockchain cache optimization completed")
        }
    }
    
    // MARK: - Cache Management
    
    private func cleanupExpiredCache() async {
        let now = Date()
        
        // 실시간 캐시 정리 (블록체인 데이터는 30초 TTL)
        realTimeCache = realTimeCache.filter {
            guard let timestamp = getCacheTimestamp(for: $0.key) else { return false }
            return now.timeIntervalSince(timestamp) < CacheConfig.realTimeTTL
        }
        
        await diskCacheManager.cleanupExpiredEntries()
        Logger.debug("🧹 Blockchain cache cleanup completed")
    }
    
    private func invalidateRelatedCaches(walletAddress: String) async {
        let keysToInvalidate = realTimeCache.keys.filter { $0.contains(walletAddress) }
        
        for key in keysToInvalidate {
            realTimeCache.removeValue(forKey: key)
            memoryCache.removeObject(forKey: key as NSString)
            await diskCacheManager.invalidateCache(for: key)
        }
        
        Logger.debug("🗑️ Invalidated \(keysToInvalidate.count) blockchain cache entries for address")
    }
    
    // MARK: - Export with Blockchain-Specific Data
    
    private nonisolated func performBlockchainExport(transactions: [Transaction], format: ExportFormat) throws -> (Data, String) {
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
    
    private nonisolated func generateBlockchainCSV(from transactions: [Transaction]) throws -> Data {
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
    
    private nonisolated func generateBlockchainJSON(from transactions: [Transaction]) throws -> Data {
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
    
    private nonisolated func generateBlockchainPDF(from transactions: [Transaction]) throws -> Data {
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
    
    private func withTimeout<T: Sendable>(seconds: TimeInterval, operation: @escaping @Sendable () async throws -> T) async throws -> T {
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

// MARK: - Mock Service (테스트용)

/// 테스트 및 개발용 Mock Etherscan Service
public actor MockHistoryService: HistoryServiceProtocol {
    
    private let sampleTransactions: [Transaction] = [
        Transaction(
            hash: "0x1234567890abcdef1234567890abcdef12345678",
            from: "0xabcdef1234567890abcdef1234567890abcdef12",
            to: "0x1234567890abcdef1234567890abcdef12345678",
            value: "1000000000000000000", // 1 ETH in wei
            gasUsed: "21000",
            gasPrice: "20000000000", // 20 Gwei
            status: .confirmed,
            timestamp: Date().addingTimeInterval(-3600), // 1시간 전
            blockNumber: 18500000,
            tokenSymbol: nil,
            tokenName: nil
        ),
        Transaction(
            hash: "0xabcdef1234567890abcdef1234567890abcdef12",
            from: "0x1234567890abcdef1234567890abcdef12345678",
            to: "0xabcdef1234567890abcdef1234567890abcdef12",
            value: "500000000000000000", // 0.5 ETH
            gasUsed: "21000",
            gasPrice: "25000000000", // 25 Gwei
            status: .confirmed,
            timestamp: Date().addingTimeInterval(-7200), // 2시간 전
            blockNumber: 18499950,
            tokenSymbol: nil,
            tokenName: nil
        ),
        Transaction(
            hash: "0x9876543210fedcba9876543210fedcba98765432",
            from: "0xabcdef1234567890abcdef1234567890abcdef12",
            to: "0x1234567890abcdef1234567890abcdef12345678",
            value: "1000000000000000000000", // 1000 USDT (가정)
            gasUsed: "65000",
            gasPrice: "30000000000", // 30 Gwei
            status: .confirmed,
            timestamp: Date().addingTimeInterval(-10800), // 3시간 전
            blockNumber: 18499900,
            tokenSymbol: "USDT",
            tokenName: "Tether USD"
        )
    ]
    
    public init() {}
    
    public func fetchTransactionHistory(walletAddress: String, limit: Int, offset: Int) async throws -> ([Transaction], Bool) {
        // 실제 네트워크 지연 시뮬레이션
        try await Task.sleep(for: .milliseconds(500))
        
        let startIndex = offset
        let endIndex = min(startIndex + limit, sampleTransactions.count)
        
        guard startIndex < sampleTransactions.count else {
            return ([], false)
        }
        
        let batch = Array(sampleTransactions[startIndex..<endIndex])
        let hasMore = endIndex < sampleTransactions.count
        
        Logger.info("🧪 Mock service returned \(batch.count) transactions (hasMore: \(hasMore))")
        return (batch, hasMore)
    }
    
    public func searchTransactions(walletAddress: String, query: String) async throws -> [Transaction] {
        try await Task.sleep(for: .milliseconds(300))
        
        let filtered = sampleTransactions.filter { transaction in
            transaction.hash.lowercased().contains(query.lowercased()) ||
            transaction.from.lowercased().contains(query.lowercased()) ||
            transaction.to.lowercased().contains(query.lowercased()) ||
            (transaction.tokenSymbol?.lowercased().contains(query.lowercased()) ?? false)
        }
        
        Logger.info("🔍 Mock search returned \(filtered.count) results for query: \(query)")
        return filtered
    }
    
    public func exportTransactions(transactions: [Transaction], format: ExportFormat) async throws -> (Data, String) {
        try await Task.sleep(for: .milliseconds(200))
        
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let fileName = "mock_transactions_\(timestamp).\(format.fileExtension)"
        let content = "Mock export data for \(transactions.count) transactions"
        
        guard let data = content.data(using: .utf8) else {
            throw ExportError.dataConversionFailed
        }
        
        Logger.info("📤 Mock export completed: \(fileName)")
        return (data, fileName)
    }
}

// MARK: - Blockchain Export Data Model

private struct BlockchainExportData: Encodable {
    let exportDate: Date
    let totalTransactions: Int
    let blockchainNetwork: String = "Ethereum Mainnet"
    let exportedBy: String = "Kingthereum iOS App"
    let transactions: [Transaction]
}

// MARK: - Supporting Types

final class CachedTransactionData: Sendable {
    let transactions: [Transaction]; let hasMore: Bool; let timestamp: Date
    init(transactions: [Transaction], hasMore: Bool, timestamp: Date) { self.transactions = transactions; self.hasMore = hasMore; self.timestamp = timestamp }
    var isExpired: Bool { Date().timeIntervalSince(timestamp) > 300 }
}

enum ExportError: Error {
    case dataConversionFailed
}

actor HistoryDiskCacheManager {
    private let cacheDirectory: URL
    private let fileManager = FileManager.default
    
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
            if !result.isExpired { Logger.debug("💽 Disk cache hit for: \(key)"); return result } 
            else { try? fileManager.removeItem(at: fileURL); return nil }
        } catch { return nil }
    }
    
    func setCachedData(_ data: CachedTransactionData, for key: String) async {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).cache")
        do {
            let storageData = CachedTransactionDataStorage(transactions: data.transactions, hasMore: data.hasMore, timestamp: data.timestamp)
            let encodedData = try JSONEncoder().encode(storageData)
            try encodedData.write(to: fileURL)
            Logger.debug("💽 Cached to disk: \(key)")
        } catch { Logger.error("❌ Failed to cache to disk: \(error)") }
    }
    
    func invalidateCache(for key: String) async { let fileURL = cacheDirectory.appendingPathComponent("\(key).cache"); try? fileManager.removeItem(at: fileURL) }
    
    func cleanupExpiredEntries() async {
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.creationDateKey])
            for file in files {
                if let creationDate = try? file.resourceValues(forKeys: [.creationDateKey]).creationDate, Date().timeIntervalSince(creationDate) > 3600 { try? fileManager.removeItem(at: file) }
            }
        } catch { Logger.error("❌ Failed to cleanup disk cache: \(error)") }
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
        } catch { Logger.error("❌ Failed to optimize storage: \(error)") }
    }
}

private struct CachedTransactionDataStorage: Codable {
    let transactions: [Transaction]
    let hasMore: Bool
    let timestamp: Date
}

enum TimeoutError: Error {
    case operationTimeout
}
