import Foundation

/// 블록체인 네트워크 설정 정보를 관리하는 도메인 모델
/// 
/// 이더리움 생태계의 다양한 블록체인 네트워크(메인넷, 테스트넷, L2 솔루션 등)
/// 정보를 통합 관리합니다. 각 네트워크의 연결 정보, 메타데이터, 설정을
/// 포괄적으로 제공하여 멀티체인 지갑 경험을 구현합니다.
/// 
/// ## 지원 네트워크:
/// - 이더리움 메인넷 및 테스트넷
/// - Layer 2 솔루션 (Polygon, Arbitrum, Optimism)
/// - 사이드체인 (BSC 등)
/// - 커스텀 네트워크 추가 지원
/// 
/// ## 주요 기능:
/// - RPC 엔드포인트 관리
/// - 블록 익스플로러 연동
/// - 네트워크별 가스 토큰 정보
/// - 테스트넷/메인넷 구분
/// 
/// ## 사용 예시:
/// ```swift
/// let ethereum = Network.ethereum
/// let customNetwork = Network(
///     name: "My Custom Network",
///     chainId: 1337,
///     rpcURL: "http://localhost:8545",
///     nativeTokenSymbol: "ETH"
/// )
/// ```
public struct Network: Codable, Identifiable, Equatable, Sendable, Hashable {
    
    // MARK: - Core Properties
    
    /// 앱 내 네트워크 고유 식별자
    /// 
    /// 로컬 데이터베이스와 UI에서 네트워크를 구분하는 데 사용됩니다.
    /// 체인 ID와는 별개의 앱 내부 식별자입니다.
    public let id: UUID
    
    /// 네트워크 표시 이름
    /// 
    /// 사용자에게 표시되는 네트워크의 친화적인 이름입니다.
    /// 예: "Ethereum", "Polygon", "Arbitrum One"
    public let name: String
    
    /// EIP-155 체인 ID
    /// 
    /// 블록체인에서 네트워크를 고유하게 식별하는 번호입니다.
    /// 거래 서명과 네트워크 구분에 사용됩니다.
    /// 
    /// 주요 체인 ID:
    /// - 1: 이더리움 메인넷
    /// - 137: Polygon 메인넷
    /// - 42161: Arbitrum One
    /// - 10: Optimism
    public let chainId: Int
    
    /// RPC (Remote Procedure Call) 엔드포인트 URL
    /// 
    /// 블록체인과 통신하기 위한 JSON-RPC API 엔드포인트입니다.
    /// 거래 전송, 잔액 조회, 스마트 컨트랙트 호출 등에 사용됩니다.
    public let rpcURL: String
    
    /// 네이티브 가스 토큰 심볼
    /// 
    /// 이 네트워크에서 거래 수수료 지불에 사용되는 토큰의 심볼입니다.
    /// 예: "ETH", "MATIC", "BNB"
    public let nativeTokenSymbol: String
    
    /// 블록 익스플로러 베이스 URL
    /// 
    /// 거래 내역과 주소 정보를 확인할 수 있는 블록 익스플로러 사이트입니다.
    /// 거래 해시나 주소와 조합하여 상세 정보 링크를 생성할 수 있습니다.
    public let blockExplorerURL: String?
    
    /// 테스트넷 여부
    /// 
    /// 개발과 테스트를 위한 네트워크인지 실제 가치가 있는 메인넷인지 구분합니다.
    /// UI에서 테스트넷 경고 표시나 기능 제한에 활용됩니다.
    public let isTestnet: Bool
    
    /// 네트워크 활성화 상태
    /// 
    /// 사용자가 이 네트워크를 자신의 지갑에서 사용할지 여부를 결정합니다.
    /// 비활성화된 네트워크는 선택 목록에서 숨겨집니다.
    public let isActive: Bool
    
    /// 네트워크 정보가 앱에 추가된 시점
    /// 
    /// 커스텀 네트워크 추가 시점이나 업데이트 추적에 사용됩니다.
    public let createdAt: Date
    
    // MARK: - Initialization
    
    /// 새로운 네트워크 인스턴스 생성
    /// 
    /// - Parameters:
    ///   - id: 고유 식별자 (기본값: 새로운 UUID 자동 생성)
    ///   - name: 네트워크 표시 이름
    ///   - chainId: EIP-155 체인 ID
    ///   - rpcURL: JSON-RPC 엔드포인트 URL
    ///   - nativeTokenSymbol: 네이티브 토큰 심볼
    ///   - blockExplorerURL: 블록 익스플로러 URL (선택사항)
    ///   - isTestnet: 테스트넷 여부 (기본값: false)
    ///   - isActive: 활성화 여부 (기본값: true)
    ///   - createdAt: 생성 일시 (기본값: 현재 시간)
    public init(
        id: UUID = UUID(),
        name: String,
        chainId: Int,
        rpcURL: String,
        nativeTokenSymbol: String,
        blockExplorerURL: String? = nil,
        isTestnet: Bool = false,
        isActive: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.chainId = chainId
        self.rpcURL = rpcURL
        self.nativeTokenSymbol = nativeTokenSymbol
        self.blockExplorerURL = blockExplorerURL
        self.isTestnet = isTestnet
        self.isActive = isActive
        self.createdAt = createdAt
    }
    
    // MARK: - State Modification
    
    /// 활성화 상태가 변경된 새로운 네트워크 인스턴스 생성
    /// 
    /// - Parameter isActive: 새로운 활성화 상태
    /// - Returns: 활성화 상태가 업데이트된 새로운 Network 인스턴스
    public func withActiveState(_ isActive: Bool) -> Network {
        return Network(
            id: self.id,
            name: self.name,
            chainId: self.chainId,
            rpcURL: self.rpcURL,
            nativeTokenSymbol: self.nativeTokenSymbol,
            blockExplorerURL: self.blockExplorerURL,
            isTestnet: self.isTestnet,
            isActive: isActive,
            createdAt: self.createdAt
        )
    }
    
    /// RPC URL이 업데이트된 새로운 인스턴스 생성
    /// 
    /// 네트워크 설정 변경이나 RPC 엔드포인트 교체 시 사용합니다.
    /// 
    /// - Parameter rpcURL: 새로운 RPC URL
    /// - Returns: RPC URL이 업데이트된 새로운 Network 인스턴스
    public func withRPCURL(_ rpcURL: String) -> Network {
        return Network(
            id: self.id,
            name: self.name,
            chainId: self.chainId,
            rpcURL: rpcURL,
            nativeTokenSymbol: self.nativeTokenSymbol,
            blockExplorerURL: self.blockExplorerURL,
            isTestnet: self.isTestnet,
            isActive: self.isActive,
            createdAt: self.createdAt
        )
    }
    
    // MARK: - Computed Properties
    
    /// 메인넷 여부 확인
    /// 
    /// 테스트넷이 아닌 실제 가치가 있는 네트워크인지 확인합니다.
    /// 
    /// - Returns: 메인넷이면 true, 테스트넷이면 false
    public var isMainnet: Bool {
        return !isTestnet
    }
    
    /// 네트워크 타입 표시 (메인넷/테스트넷)
    /// 
    /// UI에서 네트워크 구분을 명확히 표시할 때 사용합니다.
    /// 
    /// - Returns: "메인넷" 또는 "테스트넷"
    public var networkTypeDisplayName: String {
        return isTestnet ? "테스트넷" : "메인넷"
    }
    
    /// 네트워크 요약 정보
    /// 
    /// 디버깅이나 로그에서 네트워크를 간단히 식별할 때 사용합니다.
    /// 
    /// - Returns: "Ethereum (Chain 1)" 형식의 요약 문자열
    public var displaySummary: String {
        return "\(name) (Chain \(chainId))"
    }
    
    /// RPC URL 유효성 확인
    /// 
    /// 저장된 RPC URL이 올바른 HTTP/HTTPS URL 형식인지 확인합니다.
    /// 
    /// - Returns: 유효한 URL 형식이면 true
    public var hasValidRPCURL: Bool {
        guard let url = URL(string: rpcURL) else { return false }
        return url.scheme == "http" || url.scheme == "https"
    }
    
    /// 블록 익스플로러 사용 가능 여부
    /// 
    /// 블록 익스플로러 URL이 설정되어 있고 유효한지 확인합니다.
    /// 
    /// - Returns: 사용 가능하면 true
    public var hasBlockExplorer: Bool {
        guard let explorerURL = blockExplorerURL else { return false }
        return URL(string: explorerURL) != nil
    }
    
    // MARK: - URL Generation
    
    /// 거래 해시를 위한 블록 익스플로러 URL 생성
    /// 
    /// - Parameter transactionHash: 조회할 거래 해시
    /// - Returns: 거래 상세 페이지 URL (블록 익스플로러가 없으면 nil)
    public func explorerURL(for transactionHash: String) -> URL? {
        guard let baseURL = blockExplorerURL else { return nil }
        return URL(string: "\(baseURL)/tx/\(transactionHash)")
    }
    
    /// 지갑 주소를 위한 블록 익스플로러 URL 생성
    /// 
    /// - Parameter address: 조회할 지갑 주소
    /// - Returns: 주소 상세 페이지 URL (블록 익스플로러가 없으면 nil)
    public func explorerAddressURL(for address: String) -> URL? {
        guard let baseURL = blockExplorerURL else { return nil }
        return URL(string: "\(baseURL)/address/\(address)")
    }
    
    /// 토큰 컨트랙트를 위한 블록 익스플로러 URL 생성
    /// 
    /// - Parameter tokenAddress: 조회할 토큰 컨트랙트 주소
    /// - Returns: 토큰 상세 페이지 URL (블록 익스플로러가 없으면 nil)
    public func explorerTokenURL(for tokenAddress: String) -> URL? {
        guard let baseURL = blockExplorerURL else { return nil }
        return URL(string: "\(baseURL)/token/\(tokenAddress)")
    }
    
    // MARK: - Network Classification
    
    /// Layer 2 네트워크 여부 확인
    /// 
    /// 이더리움의 Layer 2 솔루션인지 확인합니다.
    /// 
    /// - Returns: L2 네트워크면 true
    public var isLayer2: Bool {
        let layer2ChainIds: Set<Int> = [137, 42161, 10, 8453, 324] // Polygon, Arbitrum, Optimism, Base, zkSync Era
        return layer2ChainIds.contains(chainId)
    }
    
    /// EVM 호환 여부 확인
    /// 
    /// 이더리움 가상 머신과 호환되는 네트워크인지 확인합니다.
    /// 현재는 모든 지원 네트워크가 EVM 호환이므로 true를 반환합니다.
    /// 
    /// - Returns: EVM 호환이면 true (현재 모든 네트워크가 호환)
    public var isEVMCompatible: Bool {
        return true // 현재 지원하는 모든 네트워크가 EVM 호환
    }
    
    // MARK: - Debugging & Analytics
    
    /// 상세 정보 딕셔너리
    /// 
    /// 디버깅이나 분석 목적으로 네트워크의 모든 정보를 구조화하여 제공합니다.
    /// 
    /// - Returns: 네트워크의 모든 속성을 포함하는 딕셔너리
    public var debugInfo: [String: Any] {
        return [
            "id": id.uuidString,
            "name": name,
            "chainId": chainId,
            "rpcURL": rpcURL,
            "nativeTokenSymbol": nativeTokenSymbol,
            "blockExplorerURL": blockExplorerURL as Any,
            "isTestnet": isTestnet,
            "isMainnet": isMainnet,
            "isActive": isActive,
            "isLayer2": isLayer2,
            "isEVMCompatible": isEVMCompatible,
            "hasValidRPCURL": hasValidRPCURL,
            "hasBlockExplorer": hasBlockExplorer,
            "createdAt": createdAt
        ]
    }
}

// MARK: - Predefined Networks

/// 자주 사용되는 주요 네트워크들의 사전 정의된 인스턴스
public extension Network {
    
    // MARK: - Ethereum Networks
    
    /// 이더리움 메인넷
    /// 
    /// 이더리움의 메인 네트워크로, 실제 가치가 있는 ETH와 토큰이 거래됩니다.
    /// 가장 높은 보안과 탈중앙화를 제공하지만 가스비가 상대적으로 높습니다.
    static let ethereum = Network(
        name: "Ethereum",
        chainId: 1,
        rpcURL: "https://mainnet.infura.io/v3/",
        nativeTokenSymbol: "ETH",
        blockExplorerURL: "https://etherscan.io",
        isTestnet: false
    )
    
    /// Sepolia 테스트넷
    /// 
    /// 이더리움의 공식 테스트 네트워크로, 개발과 테스트를 위해 사용됩니다.
    /// 무료 테스트 ETH를 받아서 dApp 개발과 테스트를 진행할 수 있습니다.
    static let sepolia = Network(
        name: "Sepolia",
        chainId: 11155111,
        rpcURL: "https://sepolia.infura.io/v3/",
        nativeTokenSymbol: "SepoliaETH",
        blockExplorerURL: "https://sepolia.etherscan.io",
        isTestnet: true
    )
    
    // MARK: - Layer 2 Networks
    
    /// Polygon 메인넷
    /// 
    /// 이더리움의 대표적인 Layer 2 솔루션입니다.
    /// 빠른 거래 속도와 낮은 수수료를 제공하며, 많은 DeFi 프로토콜이 지원합니다.
    static let polygon = Network(
        name: "Polygon",
        chainId: 137,
        rpcURL: "https://polygon-rpc.com",
        nativeTokenSymbol: "MATIC",
        blockExplorerURL: "https://polygonscan.com",
        isTestnet: false
    )
    
    /// Arbitrum One
    /// 
    /// 이더리움의 Optimistic Rollup 기반 Layer 2 솔루션입니다.
    /// 이더리움과 높은 호환성을 유지하면서 빠르고 저렴한 거래를 제공합니다.
    static let arbitrum = Network(
        name: "Arbitrum One",
        chainId: 42161,
        rpcURL: "https://arb1.arbitrum.io/rpc",
        nativeTokenSymbol: "ETH",
        blockExplorerURL: "https://arbiscan.io",
        isTestnet: false
    )
    
    /// Optimism 메인넷
    /// 
    /// 또 다른 Optimistic Rollup 기반 Layer 2 솔루션입니다.
    /// 이더리움 생태계와 완전한 호환성을 제공하며 저렴한 거래 수수료를 지원합니다.
    static let optimism = Network(
        name: "Optimism",
        chainId: 10,
        rpcURL: "https://mainnet.optimism.io",
        nativeTokenSymbol: "ETH",
        blockExplorerURL: "https://optimistic.etherscan.io",
        isTestnet: false
    )
    
    // MARK: - Other Networks
    
    /// Binance Smart Chain (BSC)
    /// 
    /// 바이낸스에서 개발한 EVM 호환 블록체인입니다.
    /// 빠른 거래 속도와 낮은 수수료를 제공하며, PancakeSwap 등의 DeFi 생태계를 보유합니다.
    static let bsc = Network(
        name: "BNB Smart Chain",
        chainId: 56,
        rpcURL: "https://bsc-dataseed1.binance.org",
        nativeTokenSymbol: "BNB",
        blockExplorerURL: "https://bscscan.com",
        isTestnet: false
    )
    
    /// Base 메인넷
    /// 
    /// Coinbase에서 개발한 Layer 2 솔루션입니다.
    /// Optimism 기술을 기반으로 하며, 사용자 친화적인 온보딩에 중점을 둡니다.
    static let base = Network(
        name: "Base",
        chainId: 8453,
        rpcURL: "https://mainnet.base.org",
        nativeTokenSymbol: "ETH",
        blockExplorerURL: "https://basescan.org",
        isTestnet: false
    )
    
    // MARK: - Network Collections
    
    /// 모든 메인넷 목록
    static let allMainnets: [Network] = [
        ethereum, polygon, arbitrum, optimism, bsc, base
    ]
    
    /// 모든 테스트넷 목록
    static let allTestnets: [Network] = [
        sepolia
    ]
    
    /// 모든 네트워크 목록 (메인넷 + 테스트넷)
    static let allNetworks: [Network] = allMainnets + allTestnets
    
    /// Layer 2 네트워크 목록
    static let layer2Networks: [Network] = [
        polygon, arbitrum, optimism, base
    ]
    
    /// 기본 활성화 네트워크 목록 (새 사용자용)
    static let defaultActiveNetworks: [Network] = [
        ethereum, polygon
    ]
}