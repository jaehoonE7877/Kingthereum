import Foundation

/// 거래 정보를 나타내는 모델
/// 🔗 Production-Level Transaction Model
/// Ethereum 블록체인 거래 정보를 나타내는 완전한 모델
public struct Transaction: Codable, Identifiable, Equatable, Sendable, Hashable {
    public let id: UUID
    public let hash: String
    public let from: String
    public let to: String
    public let value: String
    public let gasUsed: String?
    public let gasPrice: String?
    public let status: TransactionStatus
    public let timestamp: Date
    public let blockNumber: Int
    public let tokenAddress: String?
    public let tokenSymbol: String?
    public let tokenName: String?
    public let tokenDecimals: Int?
    public let nonce: String?
    public let input: String?
    public let gasLimit: String?
    public let transactionIndex: String?
    public let confirmations: Int?
    
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
        blockNumber: Int,
        tokenAddress: String? = nil,
        tokenSymbol: String? = nil,
        tokenName: String? = nil,
        tokenDecimals: Int? = nil,
        nonce: String? = nil,
        input: String? = nil,
        gasLimit: String? = nil,
        transactionIndex: String? = nil,
        confirmations: Int? = nil
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
        self.tokenName = tokenName
        self.tokenDecimals = tokenDecimals
        self.nonce = nonce
        self.input = input
        self.gasLimit = gasLimit
        self.transactionIndex = transactionIndex
        self.confirmations = confirmations
    }
    
    /// 포맷된 날짜 문자열 반환
    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: timestamp)
    }
    
    /// 거래 카테고리 추론 (ETH vs Token)
    public var category: TransactionCategory {
        if tokenSymbol != nil || tokenAddress != nil {
            return .token
        } else {
            return .ethereum
        }
    }
    
    /// 거래 방향 확인 (보낸 거래 vs 받은 거래)
    public func isOutgoing(for address: String) -> Bool {
        return from.lowercased() == address.lowercased()
    }
    
    /// 상대방 주소 반환
    public func counterpartyAddress(for userAddress: String) -> String {
        return isOutgoing(for: userAddress) ? to : from
    }
    
    /// 가스비 계산 (ETH 단위)
    public var gasFeeInEther: Decimal? {
        guard let gasUsed = gasUsed,
              let gasPrice = gasPrice,
              let gasUsedDecimal = Decimal(string: gasUsed),
              let gasPriceDecimal = Decimal(string: gasPrice) else {
            return nil
        }
        
        let gasFeeInWei = gasUsedDecimal * gasPriceDecimal
        return gasFeeInWei / pow(10, 18) // Wei to ETH conversion
    }
    
    /// 거래 금액 (토큰 단위로 변환)
    public var amountInTokenUnit: Decimal? {
        guard let valueDecimal = Decimal(string: value) else { return nil }
        
        let decimals = tokenDecimals ?? 18 // ETH default decimals
        return valueDecimal / pow(10, decimals)
    }
    
    /// 사람이 읽기 쉬운 거래 상태
    public var statusDisplayName: String {
        switch status {
        case .pending:
            return "처리 중"
        case .confirmed:
            return "완료"
        case .failed:
            return "실패"
        }
    }
    
    /// 거래 해시 축약 표시
    public var shortHash: String {
        guard hash.count > 10 else { return hash }
        return "\(hash.prefix(6))...\(hash.suffix(4))"
    }
    
    /// 주소 축약 표시
    public func shortAddress(_ address: String) -> String {
        guard address.count > 10 else { return address }
        return "\(address.prefix(6))...\(address.suffix(4))"
    }
}

/// 거래 카테고리 분류 (TransactionType 프로토콜과 충돌 방지)
public enum TransactionCategory: String, Codable, CaseIterable, Sendable {
    case ethereum = "ethereum"
    case token = "token"
    
    public var displayName: String {
        switch self {
        case .ethereum: return "이더리움"
        case .token: return "토큰"
        }
    }
}

