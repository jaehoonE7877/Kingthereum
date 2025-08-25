import Foundation

/// 네트워크 정보를 나타내는 모델
public struct Network: Codable, Identifiable, Equatable, Sendable, Hashable {
    /// 네트워크의 고유 식별자
    public let id: UUID
    /// 네트워크 이름
    public let name: String
    /// 체인 ID
    public let chainId: Int
    /// RPC URL
    public let rpcURL: String
    /// 네이티브 토큰 심볼
    public let nativeTokenSymbol: String
    /// 블록 익스플로러 URL
    public let blockExplorerURL: String?
    /// 테스트넷 여부
    public let isTestnet: Bool
    /// 네트워크 활성화 여부
    public let isActive: Bool
    /// 네트워크 생성 일시
    public let createdAt: Date
    
    /// 네트워크 초기화
    /// - Parameters:
    ///   - id: 고유 식별자 (기본값: 새로운 UUID)
    ///   - name: 네트워크 이름
    ///   - chainId: 체인 ID
    ///   - rpcURL: RPC URL
    ///   - nativeTokenSymbol: 네이티브 토큰 심볼
    ///   - blockExplorerURL: 블록 익스플로러 URL (기본값: nil)
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
    
    /// 네트워크의 활성화 상태를 변경한 새로운 인스턴스를 생성
    /// - Parameter isActive: 새로운 활성화 상태
    /// - Returns: 활성화 상태가 업데이트된 네트워크 인스턴스
    public func withActiveState(_ isActive: Bool) -> Network {
        return Network(
            id: id,
            name: name,
            chainId: chainId,
            rpcURL: rpcURL,
            nativeTokenSymbol: nativeTokenSymbol,
            blockExplorerURL: blockExplorerURL,
            isTestnet: isTestnet,
            isActive: isActive,
            createdAt: createdAt
        )
    }
}

// MARK: - Predefined Networks

public extension Network {
    /// 이더리움 메인넷
    static let ethereum = Network(
        name: "Ethereum",
        chainId: 1,
        rpcURL: "https://mainnet.infura.io/v3/",
        nativeTokenSymbol: "ETH",
        blockExplorerURL: "https://etherscan.io",
        isTestnet: false
    )
    
    /// 폴리곤 메인넷
    static let polygon = Network(
        name: "Polygon",
        chainId: 137,
        rpcURL: "https://polygon-rpc.com",
        nativeTokenSymbol: "MATIC",
        blockExplorerURL: "https://polygonscan.com",
        isTestnet: false
    )
    
    /// 바이낸스 스마트 체인
    static let bsc = Network(
        name: "Binance Smart Chain",
        chainId: 56,
        rpcURL: "https://bsc-dataseed1.binance.org",
        nativeTokenSymbol: "BNB",
        blockExplorerURL: "https://bscscan.com",
        isTestnet: false
    )
    
    /// 세폴리아 테스트넷
    static let sepolia = Network(
        name: "Sepolia",
        chainId: 11155111,
        rpcURL: "https://sepolia.infura.io/v3/",
        nativeTokenSymbol: "SepoliaETH",
        blockExplorerURL: "https://sepolia.etherscan.io",
        isTestnet: true
    )
}