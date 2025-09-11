import Foundation

/// 이더리움 블록체인 거래 정보를 표현하는 완전한 도메인 모델
/// 
/// 이더리움 네트워크에서 발생하는 모든 거래 정보를 포괄적으로 표현합니다.
/// ETH 전송, ERC-20 토큰 전송, 스마트 컨트랙트 상호작용을 모두 지원하며,
/// 거래의 전체 생명주기(대기 → 확인 → 완료/실패)를 추적합니다.
/// 
/// ## 주요 기능:
/// - 완전한 이더리움 거래 메타데이터 지원
/// - 토큰 전송과 ETH 전송 통합 처리
/// - 가스비 계산 및 분석
/// - 사용자 친화적인 표시 형식 제공
/// - 거래 상태 실시간 추적
/// 
/// ## 지원하는 거래 유형:
/// - ETH 직접 전송
/// - ERC-20 토큰 전송
/// - 스마트 컨트랙트 호출
/// - 멀티시그 지갑 거래
/// 
/// ## 사용 예시:
/// ```swift
/// let transaction = Transaction(
///     hash: "0xabc123...",
///     from: "0x742d35...",
///     to: "0x123def...",
///     value: "1000000000000000000", // 1 ETH in Wei
///     status: .confirmed,
///     blockNumber: 18500000
/// )
/// 
/// print(transaction.shortHash) // "0xabc1...3def"
/// print(transaction.amountInTokenUnit) // 1.0 ETH
/// ```
public struct Transaction: Codable, Identifiable, Equatable, Sendable, Hashable {
    
    // MARK: - Core Identity
    
    /// 앱 내 고유 식별자
    /// 
    /// 로컬 데이터베이스와 UI에서 거래를 식별하는 데 사용됩니다.
    /// 블록체인의 거래 해시와는 별개의 앱 내부 식별자입니다.
    public let id: UUID
    
    /// 블록체인 거래 해시 (트랜잭션 ID)
    /// 
    /// 이더리움 네트워크에서 거래를 고유하게 식별하는 해시값입니다.
    /// 블록 익스플로러에서 거래 상세 정보를 조회할 때 사용됩니다.
    /// 
    /// 형식: "0x" + 64자리 16진수
    public let hash: String
    
    // MARK: - Transaction Participants
    
    /// 송신자 지갑 주소
    /// 
    /// 거래를 시작한 이더리움 주소입니다.
    /// EOA(외부 소유 계정) 또는 스마트 컨트랙트 주소일 수 있습니다.
    public let from: String
    
    /// 수신자 지갑 주소
    /// 
    /// 거래의 대상이 되는 이더리움 주소입니다.
    /// 일반 지갑 주소 또는 스마트 컨트랙트 주소일 수 있습니다.
    public let to: String
    
    // MARK: - Transaction Value
    
    /// 전송된 값 (Wei 단위 문자열)
    /// 
    /// ETH의 경우 전송된 이더 량을, 토큰의 경우 토큰의 최소 단위량을 나타냅니다.
    /// 정밀도 손실 방지를 위해 문자열 형태로 저장됩니다.
    /// 
    /// 예시:
    /// - "1000000000000000000" = 1 ETH
    /// - "500000000000000000" = 0.5 ETH
    public let value: String
    
    // MARK: - Gas Information
    
    /// 실제 사용된 가스량
    /// 
    /// 거래 실행에 실제로 소모된 가스 단위입니다.
    /// 거래 완료 후에만 확정되며, gasLimit보다 작거나 같습니다.
    public let gasUsed: String?
    
    /// 가스 가격 (Wei 단위)
    /// 
    /// 가스 1단위당 지불한 Wei 금액입니다.
    /// 네트워크 혼잡도에 따라 동적으로 결정됩니다.
    public let gasPrice: String?
    
    /// 가스 한도
    /// 
    /// 거래 실행을 위해 설정된 최대 가스량입니다.
    /// 실제 사용량이 이 값을 초과하면 거래가 실패합니다.
    public let gasLimit: String?
    
    // MARK: - Transaction Status & Timing
    
    /// 거래 상태
    /// 
    /// 거래의 현재 처리 상태를 나타냅니다.
    /// UI에서 사용자에게 거래 진행 상황을 표시하는 데 사용됩니다.
    public let status: TransactionStatus
    
    /// 거래 발생 시점
    /// 
    /// 거래가 블록체인에 포함된 시간입니다.
    /// 대기 중인 거래의 경우 생성 시간을 사용할 수 있습니다.
    public let timestamp: Date
    
    /// 블록 번호
    /// 
    /// 거래가 포함된 이더리움 블록의 번호입니다.
    /// 블록 번호를 통해 거래의 확정성을 판단할 수 있습니다.
    public let blockNumber: Int
    
    /// 거래 논스 (순서 번호)
    /// 
    /// 송신자 주소에서 발생한 거래의 순차적 번호입니다.
    /// 동일 주소의 거래 순서를 보장하는 데 사용됩니다.
    public let nonce: String?
    
    // MARK: - Token Information
    
    /// ERC-20 토큰 컨트랙트 주소 (토큰 거래인 경우)
    /// 
    /// 토큰 전송 거래인 경우 해당 토큰의 스마트 컨트랙트 주소입니다.
    /// ETH 직접 전송인 경우 nil입니다.
    public let tokenAddress: String?
    
    /// 토큰 심볼 (예: "USDC", "DAI")
    /// 
    /// 토큰의 축약된 이름입니다. UI 표시에 주로 사용됩니다.
    public let tokenSymbol: String?
    
    /// 토큰 전체 이름 (예: "USD Coin", "Dai Stablecoin")
    /// 
    /// 토큰의 공식 명칭입니다. 상세 정보 표시에 사용됩니다.
    public let tokenName: String?
    
    /// 토큰 소수점 자릿수
    /// 
    /// 토큰의 최소 단위를 사람이 읽기 쉬운 형태로 변환할 때 사용됩니다.
    /// ETH의 경우 18, USDC의 경우 6이 일반적입니다.
    public let tokenDecimals: Int?
    
    // MARK: - Additional Metadata
    
    /// 거래 입력 데이터 (스마트 컨트랙트 호출 데이터)
    /// 
    /// 스마트 컨트랙트 함수 호출 시 전달되는 인코딩된 데이터입니다.
    /// 일반 ETH 전송의 경우 "0x" 또는 nil입니다.
    public let input: String?
    
    /// 블록 내 거래 인덱스
    /// 
    /// 해당 블록에서 이 거래의 순서를 나타내는 인덱스입니다.
    public let transactionIndex: String?
    
    /// 거래 확인 수
    /// 
    /// 이 거래가 포함된 블록 이후 생성된 블록의 수입니다.
    /// 확인 수가 많을수록 거래의 확정성이 높아집니다.
    public let confirmations: Int?
    
    // MARK: - Initialization
    
    /// 새로운 거래 인스턴스 생성
    /// 
    /// 모든 거래 정보를 포함하는 완전한 생성자입니다.
    /// API 응답이나 블록체인 데이터로부터 거래 객체를 생성할 때 사용됩니다.
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
    
    // MARK: - Display Formatting
    
    /// 사용자 친화적인 날짜 표시 형식
    /// 
    /// 거래 목록이나 상세 화면에서 표시하는 한국어 날짜 형식입니다.
    /// 
    /// - Returns: "2024년 1월 15일 오후 2:30" 형식의 문자열
    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: timestamp)
    }
    
    /// 거래 해시 축약 표시
    /// 
    /// 긴 거래 해시를 UI에 표시하기 적합한 형태로 축약합니다.
    /// 
    /// - Returns: "0xabc123...def789" 형식의 축약된 해시
    public var shortHash: String {
        guard hash.count > 10 else { return hash }
        return "\(hash.prefix(6))...\(hash.suffix(4))"
    }
    
    /// 주소 축약 표시
    /// 
    /// 이더리움 주소를 UI 표시용으로 축약합니다.
    /// 
    /// - Parameter address: 축약할 이더리움 주소
    /// - Returns: "0x742d...B83A" 형식의 축약된 주소
    public func shortAddress(_ address: String) -> String {
        guard address.count > 10 else { return address }
        return "\(address.prefix(6))...\(address.suffix(4))"
    }
    
    /// 사람이 읽기 쉬운 거래 상태 표시
    /// 
    /// 기술적인 상태값을 사용자가 이해하기 쉬운 한국어로 변환합니다.
    /// 
    /// - Returns: 상태에 따른 한국어 표시명
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
    
    // MARK: - Transaction Analysis
    
    /// 거래 카테고리 자동 분류
    /// 
    /// 거래 데이터를 분석하여 ETH 전송인지 토큰 전송인지 자동으로 판별합니다.
    /// 
    /// - Returns: .ethereum (ETH 전송) 또는 .token (토큰 전송)
    public var category: TransactionCategory {
        if tokenSymbol != nil || tokenAddress != nil {
            return .token
        } else {
            return .ethereum
        }
    }
    
    /// 거래 방향 확인 (송금 vs 수신)
    /// 
    /// 주어진 사용자 주소를 기준으로 이 거래가 송금인지 수신인지 판별합니다.
    /// 
    /// - Parameter address: 판별 기준이 되는 사용자의 지갑 주소
    /// - Returns: 송금 거래면 true, 수신 거래면 false
    public func isOutgoing(for address: String) -> Bool {
        return from.lowercased() == address.lowercased()
    }
    
    /// 상대방 주소 반환
    /// 
    /// 사용자를 기준으로 거래의 상대방(송금 대상 또는 송금자) 주소를 반환합니다.
    /// 
    /// - Parameter userAddress: 사용자의 지갑 주소
    /// - Returns: 상대방의 지갑 주소
    public func counterpartyAddress(for userAddress: String) -> String {
        return isOutgoing(for: userAddress) ? to : from
    }
    
    /// 거래 확정 여부 확인
    /// 
    /// 일반적으로 12개 이상의 확인을 받으면 거래가 확정된 것으로 간주합니다.
    /// 
    /// - Returns: 충분한 확인을 받아 확정된 거래면 true
    public var isConfirmed: Bool {
        return (confirmations ?? 0) >= 12
    }
    
    // MARK: - Financial Calculations
    
    /// 거래 금액을 토큰 단위로 변환
    /// 
    /// Wei나 토큰 최소 단위로 저장된 값을 사람이 읽기 쉬운 단위로 변환합니다.
    /// 
    /// - Returns: 토큰 단위로 변환된 거래 금액 (예: 1.5 ETH, 100.0 USDC)
    public var amountInTokenUnit: Decimal? {
        guard let valueDecimal = Decimal(string: value) else { return nil }
        
        let decimals = tokenDecimals ?? 18 // ETH 기본값
        return valueDecimal / pow(10, decimals)
    }
    
    /// 가스비 계산 (ETH 단위)
    /// 
    /// 거래에 소요된 실제 가스비를 ETH 단위로 계산합니다.
    /// 
    /// - Returns: ETH 단위의 가스비 (예: 0.002 ETH)
    public var gasFeeInEther: Decimal? {
        guard let gasUsed = gasUsed,
              let gasPrice = gasPrice,
              let gasUsedDecimal = Decimal(string: gasUsed),
              let gasPriceDecimal = Decimal(string: gasPrice) else {
            return nil
        }
        
        let gasFeeInWei = gasUsedDecimal * gasPriceDecimal
        return gasFeeInWei / pow(10, 18) // Wei를 ETH로 변환
    }
    
    /// 최대 가스비 계산 (ETH 단위)
    /// 
    /// 거래 생성 시 설정한 최대 가스비를 ETH 단위로 계산합니다.
    /// 
    /// - Returns: ETH 단위의 최대 가스비
    public var maxGasFeeInEther: Decimal? {
        guard let gasLimit = gasLimit,
              let gasPrice = gasPrice,
              let gasLimitDecimal = Decimal(string: gasLimit),
              let gasPriceDecimal = Decimal(string: gasPrice) else {
            return nil
        }
        
        let maxGasFeeInWei = gasLimitDecimal * gasPriceDecimal
        return maxGasFeeInWei / pow(10, 18)
    }
    
    /// 가스 효율성 계산 (사용률)
    /// 
    /// 설정한 가스 한도 대비 실제 사용한 가스의 비율을 계산합니다.
    /// 
    /// - Returns: 가스 사용률 (0.0~1.0)
    public var gasEfficiency: Double? {
        guard let gasUsed = gasUsed,
              let gasLimit = gasLimit,
              let gasUsedDouble = Double(gasUsed),
              let gasLimitDouble = Double(gasLimit),
              gasLimitDouble > 0 else {
            return nil
        }
        
        return gasUsedDouble / gasLimitDouble
    }
    
    // MARK: - Smart Contract Analysis
    
    /// 스마트 컨트랙트 상호작용 여부
    /// 
    /// 이 거래가 단순한 ETH 전송이 아닌 스마트 컨트랙트 호출인지 판별합니다.
    /// 
    /// - Returns: 컨트랙트 호출이면 true, 일반 전송이면 false
    public var isContractInteraction: Bool {
        return input != nil && input != "0x" && !(input?.isEmpty ?? true)
    }
    
    /// 토큰 전송 거래 여부
    /// 
    /// ERC-20 토큰 전송 거래인지 확인합니다.
    /// 
    /// - Returns: 토큰 전송이면 true, ETH 전송이면 false
    public var isTokenTransfer: Bool {
        return tokenAddress != nil
    }
    
    // MARK: - Debugging & Analytics
    
    /// 상세 정보 딕셔너리
    /// 
    /// 디버깅이나 분석 목적으로 거래의 모든 정보를 구조화하여 제공합니다.
    /// 
    /// - Returns: 거래의 모든 속성을 포함하는 딕셔너리
    public var debugInfo: [String: Any] {
        var info: [String: Any] = [
            "id": id.uuidString,
            "hash": hash,
            "shortHash": shortHash,
            "from": from,
            "to": to,
            "value": value,
            "status": status.rawValue,
            "timestamp": timestamp,
            "blockNumber": blockNumber,
            "category": category.rawValue,
            "isContractInteraction": isContractInteraction,
            "isTokenTransfer": isTokenTransfer
        ]
        
        // Optional 값들 추가
        if let gasUsed = gasUsed { info["gasUsed"] = gasUsed }
        if let gasPrice = gasPrice { info["gasPrice"] = gasPrice }
        if let gasLimit = gasLimit { info["gasLimit"] = gasLimit }
        if let tokenSymbol = tokenSymbol { info["tokenSymbol"] = tokenSymbol }
        if let amountInTokenUnit = amountInTokenUnit { info["amountInTokenUnit"] = amountInTokenUnit }
        if let gasFeeInEther = gasFeeInEther { info["gasFeeInEther"] = gasFeeInEther }
        if let confirmations = confirmations { info["confirmations"] = confirmations }
        
        return info
    }
}

// MARK: - Supporting Types

/// 거래 처리 상태를 나타내는 열거형
/// 
/// 블록체인에서 거래의 처리 단계를 추적하는 데 사용됩니다.
/// UI에서 사용자에게 거래 진행 상황을 표시하는 데 활용됩니다.
public enum TransactionStatus: String, Codable, CaseIterable, Sendable {
    /// 대기 중 - 메모리풀에 있지만 아직 블록에 포함되지 않음
    case pending = "pending"
    
    /// 확인됨 - 블록에 포함되어 처리 완료
    case confirmed = "confirmed"
    
    /// 실패 - 실행 중 오류 발생으로 되돌려짐
    case failed = "failed"
    
    /// 사용자에게 표시할 상태명 (한국어)
    public var displayName: String {
        switch self {
        case .pending: return "처리 중"
        case .confirmed: return "완료"
        case .failed: return "실패"
        }
    }
    
    /// 상태에 따른 UI 색상 힌트
    public var colorHint: String {
        switch self {
        case .pending: return "orange"
        case .confirmed: return "green"
        case .failed: return "red"
        }
    }
}

/// 거래 카테고리 분류
/// 
/// 거래의 유형을 구분하여 UI 표시나 필터링에 사용합니다.
/// TransactionType 프로토콜과의 이름 충돌을 방지하기 위해 Category로 명명했습니다.
public enum TransactionCategory: String, Codable, CaseIterable, Sendable {
    /// 이더리움(ETH) 직접 전송
    case ethereum = "ethereum"
    
    /// ERC-20 토큰 전송
    case token = "token"
    
    /// 사용자에게 표시할 카테고리명 (한국어)
    public var displayName: String {
        switch self {
        case .ethereum: return "이더리움"
        case .token: return "토큰"
        }
    }
    
    /// 카테고리별 아이콘 이름 (SF Symbols)
    public var iconName: String {
        switch self {
        case .ethereum: return "e.circle.fill"
        case .token: return "t.circle.fill"
        }
    }
}

