import Foundation
import Entity

// MARK: - Price Service Protocol

/// 암호화폐 가격 정보 서비스 프로토콜
/// 암호화폐 가격 정보 서비스 프로토콜
public protocol PriceServiceProtocol: Sendable {
    
    /// 특정 코인의 현재 가격 조회
    /// - Parameter coinSymbol: 코인 심볼 (예: "ETH", "BTC")
    /// - Returns: 코인 가격 정보
    func getCurrentPrice(for coinSymbol: String) async throws -> CoinPrice
    
    /// 여러 코인의 가격을 동시에 조회
    /// - Parameter coinSymbols: 코인 심볼 배열
    /// - Returns: 코인 가격 정보 배열
    func getCurrentPrices(for coinSymbols: [String]) async throws -> [CoinPrice]
    
    /// ETH 가격을 USD로 조회 (편의 메서드)
    /// - Returns: ETH/USD 가격
    func getETHPriceInUSD() async throws -> Decimal
    
    /// 캐시된 가격 정보 조회
    /// - Parameter coinSymbol: 코인 심볼
    /// - Returns: 캐시된 가격 정보 (없으면 nil)
    func getCachedPrice(for coinSymbol: String) -> CoinPrice?
    
    /// 캐시 무효화
    func invalidateCache()
}

// MARK: - Price Cache Protocol

public protocol PriceCacheProtocol: Sendable {
    func getPrice(for coinSymbol: String) async -> CoinPrice?
    func setPrice(_ price: CoinPrice, for coinSymbol: String) async
    func removePrice(for coinSymbol: String) async
    func removeAll() async
    func isExpired(for coinSymbol: String, duration: TimeInterval) async -> Bool
}

// MARK: - Price Network Protocol

public protocol PriceNetworkProtocol: Sendable {
    func fetchPrice(for coinSymbol: String) async throws -> CoinPrice
    func fetchPrices(for coinSymbols: [String]) async throws -> [CoinPrice]
}
