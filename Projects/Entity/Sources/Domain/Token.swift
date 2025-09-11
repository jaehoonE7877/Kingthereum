import Foundation

// MARK: - Token Entity

/// ERC-20 토큰의 메타데이터와 설정을 관리하는 도메인 모델
/// 
/// 이더리움 생태계의 ERC-20 표준 토큰 정보를 표현합니다.
/// 토큰의 기본 속성(이름, 심볼, 주소)부터 UI 표시에 필요한 정보까지
/// 포괄적으로 관리하여 일관된 토큰 경험을 제공합니다.
/// 
/// ## 주요 기능:
/// - ERC-20 토큰 표준 준수 메타데이터 관리
/// - 사용자별 토큰 활성화/비활성화 설정
/// - 토큰 아이콘 및 UI 표시 정보 지원
/// - 소수점 자릿수 관리로 정확한 금액 표시
/// 
/// ## 사용 예시:
/// ```swift
/// let usdc = Token(
///     name: "USD Coin",
///     symbol: "USDC",
///     contractAddress: "0xA0b86a33E6441946cBDC8F6D37c8a0C4d41F8E64",
///     decimals: 6
/// )
/// 
/// let activeUsdc = usdc.withActiveState(true)
/// print(activeUsdc.displayInfo) // 토큰 상세 정보
/// ```
public struct Token: Codable, Identifiable, Equatable, Sendable {
    
    // MARK: - Core Properties
    
    /// 앱 내 토큰 고유 식별자
    /// 
    /// 로컬 데이터베이스와 UI에서 토큰을 구분하는 데 사용됩니다.
    /// 동일한 컨트랙트 주소라도 다른 네트워크에서는 다른 ID를 가집니다.
    public let id: UUID
    
    /// 토큰의 공식 명칭
    /// 
    /// ERC-20 표준의 name() 함수에서 반환되는 값입니다.
    /// 예: "USD Coin", "Chainlink", "Uniswap"
    public let name: String
    
    /// 토큰 심볼 (축약명)
    /// 
    /// ERC-20 표준의 symbol() 함수에서 반환되는 값입니다.
    /// UI에서 잔액 표시나 거래 내역에 주로 사용됩니다.
    /// 예: "USDC", "LINK", "UNI"
    public let symbol: String
    
    /// 토큰 스마트 컨트랙트 주소
    /// 
    /// 이더리움 네트워크에서 이 토큰을 관리하는 스마트 컨트랙트의 주소입니다.
    /// 토큰 전송, 잔액 조회, 메타데이터 조회 등 모든 토큰 연산의 기준이 됩니다.
    public let contractAddress: String
    
    /// 토큰의 소수점 자릿수
    /// 
    /// ERC-20 표준의 decimals() 함수에서 반환되는 값입니다.
    /// 최소 단위를 사람이 읽기 쉬운 형태로 변환할 때 사용됩니다.
    /// 예: ETH는 18, USDC는 6, WBTC는 8
    public let decimals: Int
    
    /// 토큰 아이콘 이미지 URL
    /// 
    /// UI에서 토큰을 시각적으로 표현하기 위한 아이콘 이미지 URL입니다.
    /// 토큰 목록, 잔액 화면, 거래 내역 등에서 사용됩니다.
    public let iconURL: String?
    
    /// 사용자의 토큰 활성화 설정
    /// 
    /// 사용자가 이 토큰을 자신의 지갑에 표시할지 여부를 결정합니다.
    /// false인 경우 토큰 목록에서 숨겨지지만, 실제 잔액은 유지됩니다.
    public let isActive: Bool
    
    /// 토큰 정보가 앱에 추가된 시점
    /// 
    /// 사용자가 커스텀 토큰을 추가하거나 토큰이 처음 발견된 시점을 기록합니다.
    public let createdAt: Date
    
    // MARK: - Initialization
    
    /// 새로운 토큰 인스턴스 생성
    /// 
    /// - Parameters:
    ///   - id: 고유 식별자 (기본값: 새로운 UUID 자동 생성)
    ///   - name: 토큰의 공식 명칭
    ///   - symbol: 토큰 심볼 (축약명)
    ///   - contractAddress: 스마트 컨트랙트 주소
    ///   - decimals: 소수점 자릿수
    ///   - iconURL: 아이콘 이미지 URL (선택사항)
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
    
    // MARK: - State Modification
    
    /// 활성화 상태가 변경된 새로운 토큰 인스턴스 생성
    /// 
    /// 불변 구조체의 특성에 따라 기존 인스턴스를 수정하는 대신
    /// 활성화 상태만 변경된 새로운 인스턴스를 반환합니다.
    /// 
    /// - Parameter isActive: 새로운 활성화 상태
    /// - Returns: 활성화 상태가 업데이트된 새로운 Token 인스턴스
    public func withActiveState(_ isActive: Bool) -> Token {
        return Token(
            id: self.id,
            name: self.name,
            symbol: self.symbol,
            contractAddress: self.contractAddress,
            decimals: self.decimals,
            iconURL: self.iconURL,
            isActive: isActive,
            createdAt: self.createdAt
        )
    }
    
    /// 아이콘 URL이 업데이트된 새로운 토큰 인스턴스 생성
    /// 
    /// - Parameter iconURL: 새로운 아이콘 URL
    /// - Returns: 아이콘 URL이 업데이트된 새로운 Token 인스턴스
    public func withIcon(_ iconURL: String?) -> Token {
        return Token(
            id: self.id,
            name: self.name,
            symbol: self.symbol,
            contractAddress: self.contractAddress,
            decimals: self.decimals,
            iconURL: iconURL,
            isActive: self.isActive,
            createdAt: self.createdAt
        )
    }
    
    // MARK: - Computed Properties
    
    /// 축약된 컨트랙트 주소 (UI 표시용)
    /// 
    /// 긴 컨트랙트 주소를 UI 표시에 적합한 형태로 축약합니다.
    /// 
    /// - Returns: "0x742d...B83A" 형식의 축약된 주소
    public var shortAddress: String {
        guard contractAddress.count > 10 else { return contractAddress }
        return "\(contractAddress.prefix(6))...\(contractAddress.suffix(4))"
    }
    
    /// 컨트랙트 주소 유효성 확인
    /// 
    /// 저장된 주소가 올바른 이더리움 주소 형식인지 확인합니다.
    /// 
    /// - Returns: 유효한 이더리움 주소 형식이면 true
    public var hasValidAddress: Bool {
        return contractAddress.hasPrefix("0x") && 
               contractAddress.count == 42 && 
               contractAddress.dropFirst(2).allSatisfy { $0.isHexDigit }
    }
    
    /// 토큰 표시명 (심볼 우선)
    /// 
    /// UI에서 간결한 표시가 필요할 때 심볼을 우선하여 반환합니다.
    /// 
    /// - Returns: 심볼이 있으면 심볼, 없으면 이름
    public var displayName: String {
        return symbol.isEmpty ? name : symbol
    }
    
    /// 토큰 정보 요약
    /// 
    /// 디버깅이나 로그에서 토큰을 간단히 식별할 때 사용합니다.
    /// 
    /// - Returns: "USDC (USD Coin)" 형식의 요약 문자열
    public var displaySummary: String {
        return "\(symbol) (\(name))"
    }
    
    /// 최소 단위 값 (1 / 10^decimals)
    /// 
    /// 이 토큰의 최소 거래 단위를 Decimal로 반환합니다.
    /// 
    /// - Returns: 토큰의 최소 단위 값
    public var minimumUnit: Decimal {
        return 1 / pow(10, decimals)
    }
    
    // MARK: - Value Conversion
    
    /// Wei 단위 값을 토큰 단위로 변환
    /// 
    /// 블록체인에서 받은 최소 단위 값을 사람이 읽기 쉬운 형태로 변환합니다.
    /// 
    /// - Parameter weiValue: Wei 또는 토큰 최소 단위 값
    /// - Returns: 토큰 단위로 변환된 값
    public func convertFromWei(_ weiValue: String) -> Decimal? {
        guard let decimal = Decimal(string: weiValue) else { return nil }
        return decimal / pow(10, decimals)
    }
    
    /// 토큰 단위 값을 Wei 단위로 변환
    /// 
    /// 사용자 입력 값을 블록체인 거래에 사용할 수 있는 형태로 변환합니다.
    /// 
    /// - Parameter tokenValue: 토큰 단위 값
    /// - Returns: Wei 또는 토큰 최소 단위로 변환된 값
    public func convertToWei(_ tokenValue: Decimal) -> String {
        let weiValue = tokenValue * pow(10, decimals)
        return weiValue.description
    }
    
    // MARK: - Debugging & Analytics
    
    /// 상세 정보 딕셔너리
    /// 
    /// 디버깅이나 분석 목적으로 토큰의 모든 정보를 구조화하여 제공합니다.
    /// 
    /// - Returns: 토큰의 모든 속성을 포함하는 딕셔너리
    public var debugInfo: [String: Any] {
        return [
            "id": id.uuidString,
            "name": name,
            "symbol": symbol,
            "contractAddress": contractAddress,
            "shortAddress": shortAddress,
            "decimals": decimals,
            "iconURL": iconURL as Any,
            "isActive": isActive,
            "createdAt": createdAt,
            "hasValidAddress": hasValidAddress,
            "minimumUnit": minimumUnit.description
        ]
    }
}

// MARK: - Common Tokens

public extension Token {
    /// USDC (USD Coin) - 주요 스테이블코인
    static let usdc = Token(
        name: "USD Coin",
        symbol: "USDC",
        contractAddress: "0xA0b86a33E6441946cBDC8F6D37c8a0C4d41F8E64",
        decimals: 6
    )
    
    /// DAI - 탈중앙화 스테이블코인
    static let dai = Token(
        name: "Dai Stablecoin",
        symbol: "DAI",
        contractAddress: "0x6B175474E89094C44Da98b954EedeAC495271d0F",
        decimals: 18
    )
    
    /// USDT (Tether) - 주요 스테이블코인
    static let usdt = Token(
        name: "Tether USD",
        symbol: "USDT",
        contractAddress: "0xdAC17F958D2ee523a2206206994597C13D831ec7",
        decimals: 6
    )
}

// MARK: - Token Balance Entity

/// 특정 지갑의 토큰 잔액 정보를 관리하는 도메인 모델
/// 
/// 사용자의 지갑 주소와 특정 토큰의 실시간 잔액 정보를 추적합니다.
/// USD 환산 가격 정보도 함께 제공하여 포트폴리오 관리를 지원합니다.
/// 
/// ## 주요 기능:
/// - 실시간 토큰 잔액 추적
/// - USD 환산 가격 계산 및 저장
/// - 잔액 업데이트 시점 추적
/// - 지갑별 토큰 잔액 분리 관리
/// 
/// ## 사용 예시:
/// ```swift
/// let usdcBalance = TokenBalance(
///     tokenId: usdc.id,
///     walletAddress: "0x742d35...",
///     balance: "1000000000", // 1000 USDC in minimal units
///     usdValue: 1000.0
/// )
/// 
/// let formattedBalance = usdcBalance.formattedBalance(for: usdc)
/// ```
public struct TokenBalance: Codable, Identifiable, Equatable, Sendable {
    
    // MARK: - Core Properties
    
    /// 토큰 잔액 레코드의 고유 식별자
    /// 
    /// 동일한 토큰이라도 지갑별로 별도의 잔액 레코드를 가지므로
    /// 각 레코드를 고유하게 식별하는 ID가 필요합니다.
    public let id: UUID
    
    /// 연관된 토큰의 ID
    /// 
    /// Token 엔티티의 id와 연결되어 어떤 토큰의 잔액인지 식별합니다.
    /// 외래 키 역할을 하여 토큰 메타데이터와 잔액 정보를 연결합니다.
    public let tokenId: UUID
    
    /// 잔액을 소유한 지갑 주소
    /// 
    /// 이더리움 주소 형태로, 이 잔액이 어느 지갑에 속하는지 나타냅니다.
    /// 한 사용자가 여러 지갑을 가질 수 있으므로 정확한 주소 구분이 중요합니다.
    public let walletAddress: String
    
    /// 토큰 잔액 (최소 단위)
    /// 
    /// 토큰의 최소 단위로 표현된 잔액입니다.
    /// 정밀도 손실을 방지하기 위해 문자열로 저장됩니다.
    /// 예: USDC 6자리의 경우 "1000000"은 1 USDC
    public let balance: String
    
    /// USD 환산 가격
    /// 
    /// 현재 시장 가격을 기준으로 계산된 USD 환산 가치입니다.
    /// 포트폴리오 총액 계산이나 자산 분석에 활용됩니다.
    public let usdValue: Double?
    
    /// 마지막 업데이트 시점
    /// 
    /// 잔액 정보가 마지막으로 갱신된 시점을 기록합니다.
    /// 데이터 신선도 확인과 주기적 업데이트 스케줄링에 사용됩니다.
    public let lastUpdated: Date
    
    // MARK: - Initialization
    
    /// 새로운 토큰 잔액 인스턴스 생성
    /// 
    /// - Parameters:
    ///   - id: 고유 식별자 (기본값: 새로운 UUID 자동 생성)
    ///   - tokenId: 연관된 토큰 ID
    ///   - walletAddress: 지갑 주소
    ///   - balance: 토큰 잔액 (최소 단위)
    ///   - usdValue: USD 환산 가격 (선택사항)
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
    
    // MARK: - State Modification
    
    /// 잔액 정보가 업데이트된 새로운 인스턴스 생성
    /// 
    /// 새로운 잔액 정보로 업데이트하고 갱신 시점을 현재 시간으로 설정합니다.
    /// 
    /// - Parameters:
    ///   - balance: 새로운 토큰 잔액
    ///   - usdValue: 새로운 USD 환산 가격 (nil인 경우 기존 값 유지)
    /// - Returns: 잔액 정보가 업데이트된 새로운 TokenBalance 인스턴스
    public func withUpdatedBalance(_ balance: String, usdValue: Double? = nil) -> TokenBalance {
        return TokenBalance(
            id: self.id,
            tokenId: self.tokenId,
            walletAddress: self.walletAddress,
            balance: balance,
            usdValue: usdValue ?? self.usdValue,
            lastUpdated: Date()
        )
    }
    
    /// USD 가격만 업데이트된 새로운 인스턴스 생성
    /// 
    /// 잔액은 그대로 두고 USD 환산 가격만 업데이트할 때 사용합니다.
    /// 
    /// - Parameter usdValue: 새로운 USD 환산 가격
    /// - Returns: USD 가격이 업데이트된 새로운 TokenBalance 인스턴스
    public func withUpdatedPrice(_ usdValue: Double) -> TokenBalance {
        return TokenBalance(
            id: self.id,
            tokenId: self.tokenId,
            walletAddress: self.walletAddress,
            balance: self.balance,
            usdValue: usdValue,
            lastUpdated: Date()
        )
    }
    
    // MARK: - Computed Properties
    
    /// 잔액이 0인지 확인
    /// 
    /// UI에서 빈 잔액을 특별히 처리할 때 사용합니다.
    /// 
    /// - Returns: 잔액이 0이면 true
    public var isEmpty: Bool {
        guard let decimal = Decimal(string: balance) else { return true }
        return decimal == 0
    }
    
    /// 잔액이 있는지 확인
    /// 
    /// 0보다 큰 잔액을 가지고 있는지 확인합니다.
    /// 
    /// - Returns: 0보다 큰 잔액이 있으면 true
    public var hasBalance: Bool {
        return !isEmpty
    }
    
    /// 데이터 신선도 확인 (분 단위)
    /// 
    /// 마지막 업데이트로부터 경과된 시간을 분 단위로 계산합니다.
    /// 
    /// - Returns: 마지막 업데이트로부터 경과된 분 수
    public var minutesSinceUpdate: Int {
        let interval = Date().timeIntervalSince(lastUpdated)
        return Int(interval / 60)
    }
    
    /// 축약된 지갑 주소 (UI 표시용)
    /// 
    /// - Returns: "0x742d...B83A" 형식의 축약된 주소
    public var shortAddress: String {
        guard walletAddress.count > 10 else { return walletAddress }
        return "\(walletAddress.prefix(6))...\(walletAddress.suffix(4))"
    }
    
    // MARK: - Display Helpers
    
    /// 토큰 단위로 변환된 잔액 (소수점 형태)
    /// 
    /// 토큰의 decimals 정보를 사용하여 사람이 읽기 쉬운 형태로 변환합니다.
    /// 
    /// - Parameter token: 연관된 Token 인스턴스
    /// - Returns: 토큰 단위로 변환된 잔액
    public func formattedBalance(for token: Token) -> Decimal? {
        return token.convertFromWei(balance)
    }
    
    /// 사용자 친화적인 잔액 표시 문자열
    /// 
    /// 토큰 심볼과 함께 적절히 포맷된 잔액을 반환합니다.
    /// 
    /// - Parameter token: 연관된 Token 인스턴스
    /// - Returns: "1,234.56 USDC" 형식의 표시 문자열
    public func displayString(for token: Token) -> String {
        guard let balance = formattedBalance(for: token) else {
            return "0 \(token.symbol)"
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = min(token.decimals, 6)
        formatter.minimumFractionDigits = 0
        
        let formattedNumber = formatter.string(from: balance as NSDecimalNumber) ?? "0"
        return "\(formattedNumber) \(token.symbol)"
    }
    
    /// USD 가치 표시 문자열
    /// 
    /// USD 환산 가격을 통화 형식으로 표시합니다.
    /// 
    /// - Returns: "$1,234.56" 형식의 USD 가격 문자열
    public var usdValueString: String? {
        guard let usdValue = usdValue else { return nil }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: NSNumber(value: usdValue))
    }
    
    // MARK: - Analytics
    
    /// 상세 정보 딕셔너리
    /// 
    /// - Returns: 토큰 잔액의 모든 속성을 포함하는 딕셔너리
    public var debugInfo: [String: Any] {
        return [
            "id": id.uuidString,
            "tokenId": tokenId.uuidString,
            "walletAddress": walletAddress,
            "shortAddress": shortAddress,
            "balance": balance,
            "usdValue": usdValue as Any,
            "lastUpdated": lastUpdated,
            "isEmpty": isEmpty,
            "hasBalance": hasBalance,
            "minutesSinceUpdate": minutesSinceUpdate
        ]
    }
    
    /// 잔액 정보를 업데이트한 새로운 인스턴스를 생성
    /// - Parameters:
    ///   - balance: 새로운 잔액
    ///   - usdValue: 새로운 USD 환산 가격
}
