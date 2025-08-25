import Foundation

/// 거래 정보를 나타내는 모델
public struct Transaction: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public let hash: String
    public let from: String
    public let to: String
    public let value: String
    public let gasUsed: String?
    public let gasPrice: String?
    public let status: TransactionStatus
    public let timestamp: Date
    public let blockNumber: Int?
    public let tokenAddress: String?
    public let tokenSymbol: String?
    public let tokenDecimals: Int?
    
    public init(
        id: UUID = UUID(),
        hash: String,
        from: String,
        to: String,
        value: String,
        gasUsed: String? = nil,
        gasPrice: String? = nil,
        status: TransactionStatus,
        timestamp: Date = Date(),
        blockNumber: Int? = nil,
        tokenAddress: String? = nil,
        tokenSymbol: String? = nil,
        tokenDecimals: Int? = nil
    ) {
        self.id = id
        self.hash = hash
        self.from = from
        self.to = to
        self.value = value
        self.gasUsed = gasUsed
        self.gasPrice = gasPrice
        self.status = status
        self.timestamp = timestamp
        self.blockNumber = blockNumber
        self.tokenAddress = tokenAddress
        self.tokenSymbol = tokenSymbol
        self.tokenDecimals = tokenDecimals
    }
    
    /// 포맷된 날짜 문자열 반환
    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}

