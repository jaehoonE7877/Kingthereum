import Foundation

// MARK: - Price Service Configuration

public struct PriceConfiguration: Sendable {
    public let apiKey: String?
    public let cacheDuration: TimeInterval
    public let requestTimeout: TimeInterval
    
    public init(
        apiKey: String? = nil,
        cacheDuration: TimeInterval = 300, // 5분
        requestTimeout: TimeInterval = 10
    ) {
        self.apiKey = apiKey
        self.cacheDuration = cacheDuration
        self.requestTimeout = requestTimeout
    }
    
    public static let `default` = PriceConfiguration()
}