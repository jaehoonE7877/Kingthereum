import Foundation

/// 토큰 정보를 나타내는 모델
public struct Token: Codable, Identifiable, Equatable, Sendable {
    /// 토큰의 고유 식별자
    public let id: UUID
    /// 토큰 이름
    public let name: String
    /// 토큰 심볼
    public let symbol: String
    /// 토큰 컨트랙트 주소
    public let contractAddress: String
    /// 토큰 소수점 자리수
    public let decimals: Int
    /// 토큰 아이콘 URL
    public let iconURL: String?
    /// 토큰이 활성화되어 있는지 여부
    public let isActive: Bool
    /// 토큰 생성 일시
    public let createdAt: Date
    
    /// 토큰 초기화
    /// - Parameters:
    ///   - id: 고유 식별자 (기본값: 새로운 UUID)
    ///   - name: 토큰 이름
    ///   - symbol: 토큰 심볼
    ///   - contractAddress: 컨트랙트 주소
    ///   - decimals: 소수점 자리수
    ///   - iconURL: 아이콘 URL (기본값: nil)
    ///   - isActive: 활성화 여부 (기본값: true)
    ///   - createdAt: 생성 일시 (기본값: 현재 시간)
    public init(
        id: UUID = UUID(),
        name: String,
        symbol: String,
        contractAddress: String,
        decimals: Int,
        iconURL: String? = nil,
        isActive: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.contractAddress = contractAddress
        self.decimals = decimals
        self.iconURL = iconURL
        self.isActive = isActive
        self.createdAt = createdAt
    }
    
    /// 토큰의 활성화 상태를 변경한 새로운 인스턴스를 생성
    /// - Parameter isActive: 새로운 활성화 상태
    /// - Returns: 활성화 상태가 업데이트된 토큰 인스턴스
    public func withActiveState(_ isActive: Bool) -> Token {
        return Token(
            id: id,
            name: name,
            symbol: symbol,
            contractAddress: contractAddress,
            decimals: decimals,
            iconURL: iconURL,
            isActive: isActive,
            createdAt: createdAt
        )
    }
}

/// 토큰 잔액 정보를 나타내는 모델
public struct TokenBalance: Codable, Identifiable, Equatable, Sendable {
    /// 토큰 잔액의 고유 식별자
    public let id: UUID
    /// 연관된 토큰 ID
    public let tokenId: UUID
    /// 지갑 주소
    public let walletAddress: String
    /// 잔액 (Wei 단위의 문자열)
    public let balance: String
    /// USD 환산 가격
    public let usdValue: Double?
    /// 마지막 업데이트 시간
    public let lastUpdated: Date
    
    /// 토큰 잔액 초기화
    /// - Parameters:
    ///   - id: 고유 식별자 (기본값: 새로운 UUID)
    ///   - tokenId: 연관된 토큰 ID
    ///   - walletAddress: 지갑 주소
    ///   - balance: 잔액
    ///   - usdValue: USD 환산 가격 (기본값: nil)
    ///   - lastUpdated: 마지막 업데이트 시간 (기본값: 현재 시간)
    public init(
        id: UUID = UUID(),
        tokenId: UUID,
        walletAddress: String,
        balance: String,
        usdValue: Double? = nil,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.tokenId = tokenId
        self.walletAddress = walletAddress
        self.balance = balance
        self.usdValue = usdValue
        self.lastUpdated = lastUpdated
    }
    
    /// 잔액 정보를 업데이트한 새로운 인스턴스를 생성
    /// - Parameters:
    ///   - balance: 새로운 잔액
    ///   - usdValue: 새로운 USD 환산 가격
    /// - Returns: 잔액 정보가 업데이트된 토큰 잔액 인스턴스
    public func withUpdatedBalance(_ balance: String, usdValue: Double? = nil) -> TokenBalance {
        return TokenBalance(
            id: id,
            tokenId: tokenId,
            walletAddress: walletAddress,
            balance: balance,
            usdValue: usdValue ?? self.usdValue,
            lastUpdated: Date()
        )
    }
}