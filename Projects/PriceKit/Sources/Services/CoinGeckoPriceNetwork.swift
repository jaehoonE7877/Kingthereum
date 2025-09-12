import Foundation
import Core
import Entity

// MARK: - CoinGecko Network Service

public final class CoinGeckoPriceNetwork: PriceNetworkProtocol {
    
    private let configuration: PriceConfiguration
    private let urlSession: URLSession
    
    // CoinGecko API 엔드포인트
    private static let baseURL = "https://api.coingecko.com/api/v3"
    
    // 코인 ID 매핑 (심볼 → CoinGecko ID)
    private let coinIdMapping: [String: String] = [
        "ETH": "ethereum",
        "BTC": "bitcoin",
        "ADA": "cardano",
        "DOT": "polkadot",
        "MATIC": "matic-network"
    ]
    
    public init(configuration: PriceConfiguration) {
        self.configuration = configuration
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = configuration.requestTimeout
        config.timeoutIntervalForResource = configuration.requestTimeout * 2
        
        self.urlSession = URLSession(configuration: config)
    }
    
    // MARK: - PriceNetworkProtocol Implementation
    
    public func fetchPrice(for coinSymbol: String) async throws -> CoinPrice {
        let prices = try await fetchPrices(for: [coinSymbol])
        
        guard let price = prices.first else {
            throw PriceError.coinNotFound(coinSymbol)
        }
        
        return price
    }
    
    public func fetchPrices(for coinSymbols: [String]) async throws -> [CoinPrice] {
        guard !coinSymbols.isEmpty else { return [] }
        
        // 심볼을 CoinGecko ID로 변환
        let coinIds = coinSymbols.compactMap { symbol in
            coinIdMapping[symbol.uppercased()]
        }
        
        guard !coinIds.isEmpty else {
            throw PriceError.configurationError("Unsupported coin symbols: \(coinSymbols)")
        }
        
        let url = try buildURL(for: coinIds)
        
        do {
            Logger.info("Fetching prices from CoinGecko: \(coinIds)")
            
            let (data, response) = try await urlSession.data(from: url)
            
            try validateResponse(response)
            
            let prices = try parsePriceResponse(data, for: coinSymbols)
            
            Logger.info("Successfully fetched \(prices.count) prices from CoinGecko")
            
            return prices
            
        } catch let error as PriceError {
            throw error
        } catch {
            Logger.error("CoinGecko API request failed: \(error)")
            throw PriceError.networkUnavailable
        }
    }
    
    // MARK: - Private Methods
    
    private func buildURL(for coinIds: [String]) throws -> URL {
        // /coins/markets 엔드포인트 사용 (이미지 포함)
        var components = URLComponents(string: "\(Self.baseURL)/coins/markets")!
        
        var queryItems = [
            URLQueryItem(name: "ids", value: coinIds.joined(separator: ",")),
            URLQueryItem(name: "vs_currency", value: "usd"),
            URLQueryItem(name: "order", value: "market_cap_desc"),
            URLQueryItem(name: "per_page", value: "\(coinIds.count)"),
            URLQueryItem(name: "page", value: "1"),
            URLQueryItem(name: "sparkline", value: "false"),
            URLQueryItem(name: "price_change_percentage", value: "24h")
        ]
        
        // API 키가 있으면 추가
        if let apiKey = configuration.apiKey {
            queryItems.append(URLQueryItem(name: "x_cg_demo_api_key", value: apiKey))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw PriceError.configurationError("Invalid URL components")
        }
        
        return url
    }
    
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PriceError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            break // Success
        case 429:
            throw PriceError.rateLimitExceeded
        case 400...499:
            throw PriceError.invalidResponse
        case 500...599:
            throw PriceError.networkUnavailable
        default:
            throw PriceError.invalidResponse
        }
    }
    
    private func parsePriceResponse(_ data: Data, for requestedSymbols: [String]) throws -> [CoinPrice] {
        do {
            // /coins/markets 엔드포인트는 배열을 반환
            guard let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                throw PriceError.invalidResponse
            }
            
            var prices: [CoinPrice] = []
            
            // 요청된 심볼과 매칭되는 코인 데이터 찾기
            for symbol in requestedSymbols {
                guard let coinId = coinIdMapping[symbol.uppercased()] else {
                    continue
                }
                
                // 해당 coinId와 일치하는 데이터 찾기
                guard let coinData = jsonArray.first(where: { ($0["id"] as? String) == coinId }) else {
                    continue
                }
                
                guard let currentPrice = coinData["current_price"] as? Double else {
                    continue
                }
                
                let name = coinData["name"] as? String ?? symbol.capitalized
                let marketCap = (coinData["market_cap"] as? Double).map { Decimal($0) }
                let priceChange24h = (coinData["price_change_24h"] as? Double).map { Decimal($0) }
                let priceChangePercentage24h = (coinData["price_change_percentage_24h"] as? Double).map { Decimal($0) }
                let imageURL = coinData["image"] as? String
                
                let coinPrice = CoinPrice(
                    coinId: coinId,
                    symbol: symbol.uppercased(),
                    name: name,
                    currentPrice: Decimal(currentPrice),
                    marketCap: marketCap,
                    priceChange24h: priceChange24h,
                    priceChangePercentage24h: priceChangePercentage24h,
                    imageURL: imageURL,
                    lastUpdated: Date()
                )
                
                prices.append(coinPrice)
            }
            
            return prices
            
        } catch {
            Logger.error("Failed to parse CoinGecko response: \(error)")
            throw PriceError.invalidResponse
        }
    }
}

// MARK: - Mock Network Service for Testing

#if DEBUG
internal final class MockPriceNetwork: PriceNetworkProtocol {
    
    private let mockPrices: [String: CoinPrice] = [
        "ETH": CoinPrice(
            coinId: "ethereum",
            symbol: "ETH",
            name: "Ethereum",
            currentPrice: 2500.00,
            marketCap: 300000000000,
            priceChange24h: 125.50,
            priceChangePercentage24h: 5.28,
            imageURL: "https://assets.coingecko.com/coins/images/279/large/ethereum.png"
        ),
        "BTC": CoinPrice(
            coinId: "bitcoin",
            symbol: "BTC",
            name: "Bitcoin",
            currentPrice: 45000.00,
            marketCap: 850000000000,
            priceChange24h: -850.00,
            priceChangePercentage24h: -1.85,
            imageURL: "https://assets.coingecko.com/coins/images/1/large/bitcoin.png"
        )
    ]
    
    func fetchPrice(for coinSymbol: String) async throws -> CoinPrice {
        // 네트워크 지연 시뮬레이션
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5초
        
        guard let price = mockPrices[coinSymbol.uppercased()] else {
            throw PriceError.coinNotFound(coinSymbol)
        }
        
        return price
    }
    
    func fetchPrices(for coinSymbols: [String]) async throws -> [CoinPrice] {
        // 네트워크 지연 시뮬레이션
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1초
        
        return coinSymbols.compactMap { symbol in
            mockPrices[symbol.uppercased()]
        }
    }
}
#endif
