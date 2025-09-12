import Foundation
import Core
import Entity

// MARK: - Price Service Implementation

public final class PriceService: PriceServiceProtocol, @unchecked Sendable {
    
    private let networkService: PriceNetworkProtocol
    private let cacheService: PriceCacheProtocol
    private let configuration: PriceConfiguration
    
    // 간단하게 구독 기능은 제거하고 기본 기능만 구현
    // private var subscribers: [String: AsyncStream<CoinPrice>.Continuation] = [:]
    
    public init(
        networkService: PriceNetworkProtocol,
        cacheService: PriceCacheProtocol,
        configuration: PriceConfiguration
    ) {
        self.networkService = networkService
        self.cacheService = cacheService
        self.configuration = configuration
    }
    
    // MARK: - PriceServiceProtocol Implementation
    
    public func getCurrentPrice(for coinSymbol: String) async throws -> CoinPrice {
        let upperSymbol = coinSymbol.uppercased()
        
        // 1. 캐시 확인
        if let cachedPrice = await getCachedPriceAsync(for: upperSymbol) {
            return cachedPrice
        }
        
        // 2. 네트워크에서 가져오기
        do {
            let price = try await networkService.fetchPrice(for: upperSymbol)
            await cacheService.setPrice(price, for: upperSymbol)
            
            return price
        } catch {
            Logger.error("Failed to fetch price for \(upperSymbol): \(error)")
            throw error
        }
    }
    
    public func getCurrentPrices(for coinSymbols: [String]) async throws -> [CoinPrice] {
        let upperSymbols = coinSymbols.map { $0.uppercased() }
        var prices: [CoinPrice] = []
        var symbolsToFetch: [String] = []
        
        // 1. 캐시에서 가능한 것들 먼저 수집
        for symbol in upperSymbols {
            if let cachedPrice = await getCachedPriceAsync(for: symbol) {
                prices.append(cachedPrice)
            } else {
                symbolsToFetch.append(symbol)
            }
        }
        
        // 2. 캐시에 없는 것들만 네트워크에서 가져오기
        if !symbolsToFetch.isEmpty {
            do {
                let fetchedPrices = try await networkService.fetchPrices(for: symbolsToFetch)
                
                // 3. 캐시에 저장하고 결과에 추가
                for price in fetchedPrices {
                    await cacheService.setPrice(price, for: price.symbol.uppercased())
                    prices.append(price)
                }
            } catch {
                Logger.error("Failed to fetch prices for \(symbolsToFetch): \(error)")
                throw error
            }
        }
        
        return prices
    }
    
    public func getETHPriceInUSD() async throws -> Decimal {
        let ethPrice = try await getCurrentPrice(for: "ETH")
        return ethPrice.currentPrice
    }
    
    public func getCachedPrice(for coinSymbol: String) -> CoinPrice? {
        // 동기 API를 위한 간단한 구현 - 만료된 캐시는 nil 반환
        let upperSymbol = coinSymbol.uppercased()
        var result: CoinPrice?
        let group = DispatchGroup()
        
        group.enter()
        Task {
            result = await getCachedPriceAsync(for: upperSymbol)
            group.leave()
        }
        
        group.wait()
        return result
    }
    
    private func getCachedPriceAsync(for coinSymbol: String) async -> CoinPrice? {
        let upperSymbol = coinSymbol.uppercased()
        
        guard let cachedPrice = await cacheService.getPrice(for: upperSymbol) else {
            return nil
        }
        
        // 캐시 만료 확인
        if await cacheService.isExpired(for: upperSymbol, duration: configuration.cacheDuration) {
            await cacheService.removePrice(for: upperSymbol)
            return nil
        }
        
        return cachedPrice
    }
    
    public func invalidateCache() {
        let group = DispatchGroup()
        group.enter()
        
        Task {
            await cacheService.removeAll()
            group.leave()
        }
        
        group.wait()
    }
}

// MARK: - In-Memory Cache Implementation

public actor InMemoryPriceCache: PriceCacheProtocol {
    
    private struct CachedPrice: Sendable {
        let price: CoinPrice
        let timestamp: Date
    }
    
    private var cache: [String: CachedPrice] = [:]
    
    public init() {}
    
    public func getPrice(for coinSymbol: String) -> CoinPrice? {
        return cache[coinSymbol.uppercased()]?.price
    }
    
    public func setPrice(_ price: CoinPrice, for coinSymbol: String) {
        cache[coinSymbol.uppercased()] = CachedPrice(
            price: price,
            timestamp: Date()
        )
    }
    
    public func removePrice(for coinSymbol: String) {
        cache.removeValue(forKey: coinSymbol.uppercased())
    }
    
    public func removeAll() {
        cache.removeAll()
    }
    
    public func isExpired(for coinSymbol: String, duration: TimeInterval) -> Bool {
        guard let cachedPrice = cache[coinSymbol.uppercased()] else {
            return true
        }
        return Date().timeIntervalSince(cachedPrice.timestamp) > duration
    }
}
