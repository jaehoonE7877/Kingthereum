import Foundation
import BigInt

/// Send Scene 관련 Entity 모델 정의
/// 실제 이더리움 네트워크와 상호작용하는 송금 기능
public enum SendScene {
    
    // MARK: - Shared Models
    
    /// 가스비 정보 (실제 네트워크에서 추정)
    public struct GasFeeInfo: Sendable, Equatable {
        public let gasPrice: BigUInt        // Wei 단위 가스 가격
        public let gasLimit: BigUInt        // 가스 제한
        public let maxFeePerGas: BigUInt   // EIP-1559 최대 가스비
        public let maxPriorityFeePerGas: BigUInt // EIP-1559 우선순위 수수료
        public let estimatedFee: BigUInt   // 예상 총 가스비 (Wei)
        public let feeType: FeeType        // 가스비 유형
        
        public enum FeeType: String, CaseIterable, Sendable {
            case slow = "느림"      // 저렴하지만 느림
            case standard = "표준"  // 권장 속도
            case fast = "빠름"      // 빠르지만 비쌈
        }
        
        /// 가스비를 ETH 단위로 변환
        public var formattedFee: String {
            let ethValue = Double(estimatedFee) / 1e18
            return String(format: "%.6f ETH (%.2f원)", ethValue, ethValue * 3500000) // 임시 환율
        }
        
        /// 가스비 상세 정보
        public var detailDescription: String {
            return "가스 가격: \(gasPrice) wei\n가스 한계: \(gasLimit)\n예상 수수료: \(formattedFee)"
        }
        
        public init(
            gasPrice: BigUInt,
            gasLimit: BigUInt,
            maxFeePerGas: BigUInt,
            maxPriorityFeePerGas: BigUInt,
            estimatedFee: BigUInt,
            feeType: FeeType
        ) {
            self.gasPrice = gasPrice
            self.gasLimit = gasLimit
            self.maxFeePerGas = maxFeePerGas
            self.maxPriorityFeePerGas = maxPriorityFeePerGas
            self.estimatedFee = estimatedFee
            self.feeType = feeType
        }
    }
    
    /// 거래 상태 (실시간 추적)
    public enum TransactionStatus: String, CaseIterable, Sendable {
        case preparing = "거래 준비중"    // 거래 생성 중
        case signing = "서명 처리중"      // 개인키로 서명 중
        case broadcasting = "네트워크 전송중" // 네트워크로 전송 중
        case pending = "대기 중"         // 메모리풀에서 대기
        case confirming = "확인 중"      // 블록에 포함되어 확인 중
        case confirmed = "완료"          // 충분한 확인 완료
        case failed = "실패"             // 거래 실패
        case timeout = "시간 초과"       // 거래 시간 초과
        
        /// 진행률 (0.0 ~ 1.0)
        public var progress: Double {
            switch self {
            case .preparing: return 0.1
            case .signing: return 0.2
            case .broadcasting: return 0.4
            case .pending: return 0.6
            case .confirming: return 0.8
            case .confirmed: return 1.0
            case .failed, .timeout: return 0.0
            }
        }
        
        /// 완료 여부
        public var isCompleted: Bool {
            switch self {
            case .confirmed, .failed, .timeout: return true
            default: return false
            }
        }
    }
    
    /// 거래 정보 (실제 블록체인 데이터)
    public struct TransactionInfo: Sendable, Equatable {
        public let hash: String                    // 거래 해시
        public let from: String                    // 송신자 주소
        public let to: String                      // 수신자 주소
        public let amount: BigUInt                 // 전송 금액 (Wei)
        public let gasUsed: BigUInt?               // 실제 사용된 가스
        public let gasPrice: BigUInt               // 가스 가격 (Wei)
        public let blockNumber: BigUInt?           // 포함된 블록 번호
        public let blockHash: String?              // 포함된 블록 해시
        public let transactionIndex: BigUInt?      // 블록 내 거래 인덱스
        public let timestamp: Date?                // 거래 시간
        public let confirmations: Int              // 확인 수
        public let status: TransactionStatus       // 거래 상태
        public let nonce: BigUInt                  // 거래 nonce
        public let networkID: BigUInt              // 네트워크 ID (1: 메인넷, 11155111: Sepolia)
        
        /// 전송 금액을 ETH 단위로 변환
        public var amountInETH: String {
            let ethValue = Double(amount) / 1e18
            return String(format: "%.6f ETH", ethValue)
        }
        
        /// 실제 수수료 계산
        public var actualFee: BigUInt? {
            guard let gasUsed = gasUsed else { return nil }
            return gasUsed * gasPrice
        }
        
        /// 실제 수수료를 ETH 단위로 변환
        public var actualFeeInETH: String? {
            guard let fee = actualFee else { return nil }
            let ethValue = Double(fee) / 1e18
            return String(format: "%.6f ETH", ethValue)
        }
        
        /// 블록 탐색기 URL
        public var blockExplorerURL: String? {
            switch networkID {
            case 1: // 메인넷
                return "https://etherscan.io/tx/\(hash)"
            case 11155111: // Sepolia 테스트넷
                return "https://sepolia.etherscan.io/tx/\(hash)"
            default:
                return nil
            }
        }
        
        public init(
            hash: String,
            from: String,
            to: String,
            amount: BigUInt,
            gasUsed: BigUInt?,
            gasPrice: BigUInt,
            blockNumber: BigUInt?,
            blockHash: String?,
            transactionIndex: BigUInt?,
            timestamp: Date?,
            confirmations: Int,
            status: TransactionStatus,
            nonce: BigUInt,
            networkID: BigUInt
        ) {
            self.hash = hash
            self.from = from
            self.to = to
            self.amount = amount
            self.gasUsed = gasUsed
            self.gasPrice = gasPrice
            self.blockNumber = blockNumber
            self.blockHash = blockHash
            self.transactionIndex = transactionIndex
            self.timestamp = timestamp
            self.confirmations = confirmations
            self.status = status
            self.nonce = nonce
            self.networkID = networkID
        }
    }
    
    // MARK: - Use Cases
    
    /// 주소 유효성 검증
    public enum ValidateAddress {
        public struct Request: Sendable {
            public let recipientAddress: String    // 수신자 이더리움 주소
            public let amount: String             // 전송할 ETH 양 (문자열)
            public let gasSettings: GasSettings?  // 사용자 지정 가스 설정
            
            /// 사용자 지정 가스 설정
            public struct GasSettings: Sendable {
                public let gasPrice: BigUInt?
                public let gasLimit: BigUInt?
                public let maxFeePerGas: BigUInt?
                public let maxPriorityFeePerGas: BigUInt?
                
                public init(
                    gasPrice: BigUInt? = nil,
                    gasLimit: BigUInt? = nil,
                    maxFeePerGas: BigUInt? = nil,
                    maxPriorityFeePerGas: BigUInt? = nil
                ) {
                    self.gasPrice = gasPrice
                    self.gasLimit = gasLimit
                    self.maxFeePerGas = maxFeePerGas
                    self.maxPriorityFeePerGas = maxPriorityFeePerGas
                }
            }
            
            public init(
                recipientAddress: String,
                amount: String,
                gasSettings: GasSettings? = nil
            ) {
                self.recipientAddress = recipientAddress
                self.amount = amount
                self.gasSettings = gasSettings
            }
        }
        
        public struct Response: Sendable {
            public let isValid: Bool                  // 주소 유효성
            public let normalizedAddress: String?     // 체크섬이 적용된 정규화 주소
            public let addressType: AddressType?      // 주소 유형
            public let errorMessage: String?          // 오류 메시지
            
            public enum AddressType: String, Sendable {
                case eoa = "일반 계정"             // Externally Owned Account
                case contract = "컨트랙트"         // Smart Contract
                case multiSig = "다중 서명"        // MultiSig Wallet
                case unknown = "알 수 없음"
            }
            
            public init(
                isValid: Bool,
                normalizedAddress: String? = nil,
                addressType: AddressType? = nil,
                errorMessage: String? = nil
            ) {
                self.isValid = isValid
                self.normalizedAddress = normalizedAddress
                self.addressType = addressType
                self.errorMessage = errorMessage
            }
        }
        
        public struct ViewModel: Sendable {
            public let isValid: Bool                  // 유효성 결과
            public let address: String                // 표시할 주소
            public let addressTypeDescription: String? // 주소 유형 설명
            public let errorMessage: String?          // 사용자 친화적 오류 메시지
            public let showWarning: Bool              // 경고 표시 여부
            public let warningMessage: String?        // 경고 메시지 (컨트랙트 주소 등)
            
            public init(
                isValid: Bool,
                address: String,
                addressTypeDescription: String? = nil,
                errorMessage: String? = nil,
                showWarning: Bool = false,
                warningMessage: String? = nil
            ) {
                self.isValid = isValid
                self.address = address
                self.addressTypeDescription = addressTypeDescription
                self.errorMessage = errorMessage
                self.showWarning = showWarning
                self.warningMessage = warningMessage
            }
        }
    }
    
    /// 가스비 추정
    public enum EstimateGasFee {
        public struct Request: Sendable {
            public let amount: String                 // 전송할 ETH 양
            public let recipientAddress: String       // 수신자 주소 (가스비 계산에 영향)
            public let priorityLevel: GasFeeInfo.FeeType // 우선순위 수준
            
            public init(
                amount: String,
                recipientAddress: String,
                priorityLevel: GasFeeInfo.FeeType = .standard
            ) {
                self.amount = amount
                self.recipientAddress = recipientAddress
                self.priorityLevel = priorityLevel
            }
        }
        
        public struct Response: Sendable {
            public let gasFeeInfo: [GasFeeInfo]       // 다양한 우선순위 수준의 가스비
            public let recommendedFee: GasFeeInfo     // 권장 가스비
            public let canAfford: Bool                // 잔액 충분 여부
            public let currentBalance: BigUInt        // 현재 ETH 잔액 (Wei)
            public let totalCost: BigUInt             // 전송 금액 + 가스비 (Wei)
            public let networkStatus: NetworkStatus   // 네트워크 상태
            
            public enum NetworkStatus: String, Sendable {
                case normal = "정상"           // 평상시
                case congested = "혼잡"        // 네트워크 혼잡
                case high = "매우 혼잡"        // 매우 혼잡 (높은 가스비)
            }
            
            public init(
                gasFeeInfo: [GasFeeInfo],
                recommendedFee: GasFeeInfo,
                canAfford: Bool,
                currentBalance: BigUInt,
                totalCost: BigUInt,
                networkStatus: NetworkStatus
            ) {
                self.gasFeeInfo = gasFeeInfo
                self.recommendedFee = recommendedFee
                self.canAfford = canAfford
                self.currentBalance = currentBalance
                self.totalCost = totalCost
                self.networkStatus = networkStatus
            }
        }
        
        public struct ViewModel: Sendable {
            public let feeOptions: [FeeOptionViewModel]  // 가스비 옵션들
            public let selectedFeeIndex: Int            // 선택된 옵션 인덱스
            public let canProceed: Bool                 // 진행 가능 여부
            public let warningMessage: String?          // 경고 메시지
            public let networkStatusText: String        // 네트워크 상태 텍스트
            public let balanceText: String             // 잔액 표시 텍스트
            public let totalCostText: String           // 총 비용 표시 텍스트
            
            public init(
                feeOptions: [FeeOptionViewModel],
                selectedFeeIndex: Int,
                canProceed: Bool,
                warningMessage: String? = nil,
                networkStatusText: String,
                balanceText: String,
                totalCostText: String
            ) {
                self.feeOptions = feeOptions
                self.selectedFeeIndex = selectedFeeIndex
                self.canProceed = canProceed
                self.warningMessage = warningMessage
                self.networkStatusText = networkStatusText
                self.balanceText = balanceText
                self.totalCostText = totalCostText
            }
        }
        
        public struct FeeOptionViewModel: Sendable, Identifiable {
            public let id = UUID()
            public let type: GasFeeInfo.FeeType
            public let feeText: String                 // "0.001234 ETH (₩4,321)"
            public let timeEstimate: String            // "약 2분"
            public let isRecommended: Bool            // 권장 여부
            
            public init(
                type: GasFeeInfo.FeeType,
                feeText: String,
                timeEstimate: String,
                isRecommended: Bool = false
            ) {
                self.type = type
                self.feeText = feeText
                self.timeEstimate = timeEstimate
                self.isRecommended = isRecommended
            }
        }
    }
    
    /// 실제 송금 실행
    public enum SendTransaction {
        public struct Request: Sendable {
            public let recipientAddress: String       // 수신자 이더리움 주소
            public let amount: String                 // 전송할 ETH 양 (사용자 입력 문자열)
            public let selectedGasFee: GasFeeInfo     // 사용자가 선택한 가스비 설정
            public let userConfirmation: Bool         // 사용자 최종 확인
            
            public init(
                recipientAddress: String,
                amount: String,
                selectedGasFee: GasFeeInfo,
                userConfirmation: Bool
            ) {
                self.recipientAddress = recipientAddress
                self.amount = amount
                self.selectedGasFee = selectedGasFee
                self.userConfirmation = userConfirmation
            }
        }
        
        public struct Response: Sendable {
            public let success: Bool                  // 거래 성공 여부
            public let transactionHash: String?       // 거래 해시 (성공 시)
            public let transactionInfo: TransactionInfo? // 상세 거래 정보
            public let error: SendError?              // 오류 정보 (실패 시)
            public let estimatedConfirmationTime: TimeInterval? // 예상 확인 시간 (초)
            
            public init(
                success: Bool,
                transactionHash: String? = nil,
                transactionInfo: TransactionInfo? = nil,
                error: SendError? = nil,
                estimatedConfirmationTime: TimeInterval? = nil
            ) {
                self.success = success
                self.transactionHash = transactionHash
                self.transactionInfo = transactionInfo
                self.error = error
                self.estimatedConfirmationTime = estimatedConfirmationTime
            }
        }
        
        public struct ViewModel: Sendable {
            public let success: Bool                  // 거래 성공 여부
            public let title: String                  // 결과 제목
            public let message: String                // 결과 메시지
            public let transactionHash: String?       // 거래 해시
            public let blockExplorerURL: String?      // 블록 탐색기 URL
            public let showRetryButton: Bool          // 재시도 버튼 표시 여부
            public let showShareButton: Bool          // 공유 버튼 표시 여부
            public let estimatedTime: String?         // 예상 완료 시간
            
            public init(
                success: Bool,
                title: String,
                message: String,
                transactionHash: String? = nil,
                blockExplorerURL: String? = nil,
                showRetryButton: Bool = false,
                showShareButton: Bool = false,
                estimatedTime: String? = nil
            ) {
                self.success = success
                self.title = title
                self.message = message
                self.transactionHash = transactionHash
                self.blockExplorerURL = blockExplorerURL
                self.showRetryButton = showRetryButton
                self.showShareButton = showShareButton
                self.estimatedTime = estimatedTime
            }
        }
    }
    
    /// 거래 상태 추적
    public enum TrackTransaction {
        public struct Request: Sendable {
            public let transactionHash: String       // 추적할 거래 해시
            public let startPolling: Bool            // 폴링 시작 여부
            
            public init(
                transactionHash: String,
                startPolling: Bool = true
            ) {
                self.transactionHash = transactionHash
                self.startPolling = startPolling
            }
        }
        
        public struct Response: Sendable {
            public let transactionInfo: TransactionInfo  // 최신 거래 정보
            public let shouldContinuePolling: Bool      // 계속 폴링할지 여부
            public let pollingInterval: TimeInterval    // 다음 폴링까지 간격
            
            public init(
                transactionInfo: TransactionInfo,
                shouldContinuePolling: Bool,
                pollingInterval: TimeInterval = 10.0
            ) {
                self.transactionInfo = transactionInfo
                self.shouldContinuePolling = shouldContinuePolling
                self.pollingInterval = pollingInterval
            }
        }
        
        public struct ViewModel: Sendable {
            public let status: TransactionStatus      // 현재 상태
            public let progressText: String           // 진행 상황 텍스트
            public let progressValue: Double          // 진행률 (0.0~1.0)
            public let transactionInfo: TransactionInfo? // 거래 상세 정보
            public let showProgressBar: Bool          // 진행바 표시 여부
            public let statusIcon: String             // 상태 아이콘
            public let actionButtonText: String?      // 액션 버튼 텍스트
            public let canCancel: Bool               // 취소 가능 여부
            
            public init(
                status: TransactionStatus,
                progressText: String,
                progressValue: Double,
                transactionInfo: TransactionInfo? = nil,
                showProgressBar: Bool = true,
                statusIcon: String = "clock",
                actionButtonText: String? = nil,
                canCancel: Bool = false
            ) {
                self.status = status
                self.progressText = progressText
                self.progressValue = progressValue
                self.transactionInfo = transactionInfo
                self.showProgressBar = showProgressBar
                self.statusIcon = statusIcon
                self.actionButtonText = actionButtonText
                self.canCancel = canCancel
            }
        }
    }
}
