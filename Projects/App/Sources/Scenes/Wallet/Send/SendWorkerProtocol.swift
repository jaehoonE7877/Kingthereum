import Foundation
import Core
import Entity
import BigInt

// MARK: - SendWorkerProtocol 정의

/// SendWorker가 구현해야 하는 프로토콜
/// 이더리움 네트워크와의 상호작용을 담당하는 메서드들을 정의
public protocol SendWorkerProtocol: Actor {
    // 기본 작업들
    func fetchWalletBalance(address: String) async -> Result<BigUInt, SendErrors.WalletError>
    func calculateTransactionFee(from: String, to: String, amount: BigUInt, gasPrice: BigUInt?) async -> Result<SendModels.TransactionFee, SendErrors.FeeError>
    func sendTransaction(from: String, to: String, amount: BigUInt, gasPrice: BigUInt?, gasLimit: BigUInt?, password: String) async -> Result<String, SendErrors.TransactionError>
    func fetchGasPrice() async -> Result<BigUInt, SendErrors.NetworkError>
    func getTransactionStatus(transactionHash: String) async -> Result<SendModels.TransactionStatus, SendErrors.NetworkError>
    func validateAddress(_ address: String) async -> Bool
    func fetchTransactionHistory(address: String, limit: Int) async -> Result<[SendModels.Transaction], SendErrors.NetworkError>
    func checkNetworkConnection() async -> Bool
    
    // ERC20 토큰 관련
    func fetchTokenBalance(tokenAddress: String, walletAddress: String) async -> Result<BigUInt, SendErrors.TokenError>
    func sendToken(tokenAddress: String, from: String, to: String, amount: BigUInt, gasPrice: BigUInt?, gasLimit: BigUInt?) async -> Result<String, SendErrors.TokenError>
}

// MARK: - Send Scene Models

/// Send 화면에서 사용하는 모델들
public enum SendModels {
    /// 거래 수수료 정보
    public struct TransactionFee: Sendable {
        public let gasLimit: BigUInt
        public let gasPrice: BigUInt
        public let totalFee: BigUInt
        
        public init(gasLimit: BigUInt, gasPrice: BigUInt, totalFee: BigUInt) {
            self.gasLimit = gasLimit
            self.gasPrice = gasPrice
            self.totalFee = totalFee
        }
    }
    
    /// 거래 상태 정보
    public struct TransactionStatus: Sendable {
        public let hash: String
        public let isPending: Bool
        public let isSuccessful: Bool
        public let blockNumber: Int?
        public let confirmations: Int
        public let gasUsed: BigUInt?
        public let effectiveGasPrice: BigUInt?
        public let from: String
        public let to: String
        public let value: BigUInt
        
        public init(
            hash: String,
            isPending: Bool,
            isSuccessful: Bool,
            blockNumber: Int? = nil,
            confirmations: Int,
            gasUsed: BigUInt? = nil,
            effectiveGasPrice: BigUInt? = nil,
            from: String,
            to: String,
            value: BigUInt
        ) {
            self.hash = hash
            self.isPending = isPending
            self.isSuccessful = isSuccessful
            self.blockNumber = blockNumber
            self.confirmations = confirmations
            self.gasUsed = gasUsed
            self.effectiveGasPrice = effectiveGasPrice
            self.from = from
            self.to = to
            self.value = value
        }
    }
    
    /// 거래 정보
    public struct Transaction: Sendable {
        public enum Status: Sendable {
            case pending
            case success
            case failed
        }
        
        public let hash: String
        public let from: String
        public let to: String
        public let value: BigUInt
        public let timestamp: Date
        public let status: Status
        public let gasUsed: BigUInt?
        public let gasPrice: BigUInt?
        
        public init(
            hash: String,
            from: String,
            to: String,
            value: BigUInt,
            timestamp: Date,
            status: Status,
            gasUsed: BigUInt? = nil,
            gasPrice: BigUInt? = nil
        ) {
            self.hash = hash
            self.from = from
            self.to = to
            self.value = value
            self.timestamp = timestamp
            self.status = status
            self.gasUsed = gasUsed
            self.gasPrice = gasPrice
        }
    }
}

// MARK: - Send Errors

/// Send 기능에서 발생할 수 있는 에러들
public enum SendErrors {
    /// 지갑 관련 에러
    public enum WalletError: Error, LocalizedError, Sendable {
        case notFound
        case insufficientBalance
        case invalidAddress
        case locked
        
        public var errorDescription: String? {
            switch self {
            case .notFound: return "지갑을 찾을 수 없습니다"
            case .insufficientBalance: return "잔액이 부족합니다"
            case .invalidAddress: return "유효하지 않은 주소입니다"
            case .locked: return "지갑이 잠겨있습니다"
            }
        }
    }
    
    /// 수수료 관련 에러
    public enum FeeError: Error, LocalizedError, Sendable {
        case calculationFailed
        case gasPriceTooHigh
        case estimationFailed
        
        public var errorDescription: String? {
            switch self {
            case .calculationFailed: return "수수료 계산에 실패했습니다"
            case .gasPriceTooHigh: return "가스 가격이 너무 높습니다"
            case .estimationFailed: return "가스 추정에 실패했습니다"
            }
        }
    }
    
    /// 거래 관련 에러
    public enum TransactionError: Error, LocalizedError, Sendable {
        case failed(String)
        case rejected
        case timeout
        case invalidParameters
        
        public var errorDescription: String? {
            switch self {
            case .failed(let reason): return "거래 실패: \(reason)"
            case .rejected: return "거래가 거부되었습니다"
            case .timeout: return "거래 시간이 초과되었습니다"
            case .invalidParameters: return "잘못된 거래 매개변수입니다"
            }
        }
    }
    
    /// 네트워크 관련 에러
    public enum NetworkError: Error, LocalizedError, Sendable {
        case noConnection
        case serverError
        case invalidResponse
        case requestFailed
        
        public var errorDescription: String? {
            switch self {
            case .noConnection: return "네트워크 연결이 없습니다"
            case .serverError: return "서버 오류가 발생했습니다"
            case .invalidResponse: return "잘못된 응답을 받았습니다"
            case .requestFailed: return "요청이 실패했습니다"
            }
        }
    }
    
    /// 토큰 관련 에러
    public enum TokenError: Error, LocalizedError, Sendable {
        case notFound
        case invalidContract
        case transferFailed
        
        public var errorDescription: String? {
            switch self {
            case .notFound: return "토큰을 찾을 수 없습니다"
            case .invalidContract: return "유효하지 않은 컨트랙트입니다"
            case .transferFailed: return "토큰 전송에 실패했습니다"
            }
        }
    }
}

// MARK: - Supporting Types

/// 오류 정보를 담는 구조체
public struct SendErrorInfo: Sendable {
    public let title: String
    public let message: String
    public let severity: ErrorSeverity
    public let isRetryable: Bool
    public let recommendedAction: String?
    public let retryDelay: TimeInterval
    
    public init(
        title: String,
        message: String,
        severity: ErrorSeverity,
        isRetryable: Bool,
        recommendedAction: String?,
        retryDelay: TimeInterval
    ) {
        self.title = title
        self.message = message
        self.severity = severity
        self.isRetryable = isRetryable
        self.recommendedAction = recommendedAction
        self.retryDelay = retryDelay
    }
}

/// 가스비 변경 정보를 담는 구조체
public struct GasFeeChangeInfo: Sendable {
    public let selectedFeeType: SendScene.GasFeeInfo.FeeType
    public let feeText: String
    public let timeEstimate: String
    public let canAfford: Bool
    public let warningMessage: String?
    
    public init(
        selectedFeeType: SendScene.GasFeeInfo.FeeType,
        feeText: String,
        timeEstimate: String,
        canAfford: Bool,
        warningMessage: String?
    ) {
        self.selectedFeeType = selectedFeeType
        self.feeText = feeText
        self.timeEstimate = timeEstimate
        self.canAfford = canAfford
        self.warningMessage = warningMessage
    }
}

/// 최대 전송 금액 정보를 담는 구조체
public struct MaxSendAmountInfo: Sendable {
    public let maxAmount: String
    public let gasFeeCost: String
    public let explanation: String
    
    public init(
        maxAmount: String,
        gasFeeCost: String,
        explanation: String
    ) {
        self.maxAmount = maxAmount
        self.gasFeeCost = gasFeeCost
        self.explanation = explanation
    }
}