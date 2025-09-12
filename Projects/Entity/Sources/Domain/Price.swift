import Foundation

// MARK: - Price Domain Models

/// 암호화폐 가격 정보
public struct CoinPrice: Sendable {
    public let coinId: String
    public let symbol: String
    public let name: String
    public let currentPrice: Decimal
    public let marketCap: Decimal?
    public let priceChange24h: Decimal?
    public let priceChangePercentage24h: Decimal?
    public let imageURL: String?  // Added for coin symbol images
    public let lastUpdated: Date
    
    public init(
        coinId: String,
        symbol: String,
        name: String,
        currentPrice: Decimal,
        marketCap: Decimal? = nil,
        priceChange24h: Decimal? = nil,
        priceChangePercentage24h: Decimal? = nil,
        imageURL: String? = nil,
        lastUpdated: Date = Date()
    ) {
        self.coinId = coinId
        self.symbol = symbol
        self.name = name
        self.currentPrice = currentPrice
        self.marketCap = marketCap
        self.priceChange24h = priceChange24h
        self.priceChangePercentage24h = priceChangePercentage24h
        self.imageURL = imageURL
        self.lastUpdated = lastUpdated
    }
}
