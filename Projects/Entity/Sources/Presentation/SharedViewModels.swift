import Foundation

/// 공통으로 사용되는 ViewModel들
public struct SharedViewModels {
    
    /// 니모닉 모드
    public enum MnemonicMode {
        case create
        case display
        case verify
        
        public var title: String {
            switch self {
            case .create:
                return "니모닉 생성"
            case .display:
                return "니모닉 확인"
            case .verify:
                return "니모닉 검증"
            }
        }
        
        public var instruction: String {
            switch self {
            case .create:
                return "새로운 니모닉 문구가 생성되었습니다"
            case .display:
                return "니모닉 문구를 안전한 곳에 저장하세요"
            case .verify:
                return "니모닉 문구를 올바른 순서로 입력하세요"
            }
        }
    }
    
    /// 송금 목적지
    public enum SendDestination: Hashable {
        case address(String)
        case contact(String, String) // name, address
        
        public var displayAddress: String {
            switch self {
            case .address(let addr):
                return addr
            case .contact(_, let addr):
                return addr
            }
        }
        
        public var displayName: String? {
            switch self {
            case .address:
                return nil
            case .contact(let name, _):
                return name
            }
        }
    }
}

/// 거래 데이터 (공통)
public struct TransactionData: Hashable {
    public let hash: String
    public let amount: String
    public let timestamp: Date
    public let isIncoming: Bool
    
    public init(hash: String, amount: String, timestamp: Date, isIncoming: Bool) {
        self.hash = hash
        self.amount = amount
        self.timestamp = timestamp
        self.isIncoming = isIncoming
    }
    
    public var formattedAmount: String {
        let prefix = isIncoming ? "+" : "-"
        return "\(prefix)\(amount) ETH"
    }
    
    public var directionIcon: String {
        return isIncoming ? "arrow.down.circle.fill" : "arrow.up.circle.fill"
    }
    
    public var statusColor: String {
        return isIncoming ? "green" : "blue"
    }
}