import Foundation

/// 가스 추정 정보를 나타내는 모델
public struct GasEstimate: Codable, Sendable {
    /// 추정된 가스 한계
    public let gasLimit: String
    /// 가스 가격 (Wei 단위)
    public let gasPrice: String
    /// 최대 수수료 (EIP-1559, Wei 단위)
    public let maxFeePerGas: String?
    /// 최대 우선순위 수수료 (EIP-1559, Wei 단위)
    public let maxPriorityFeePerGas: String?
    /// 추정 시간 (초)
    public let estimatedTime: TimeInterval?
    
    public init(
        gasLimit: String,
        gasPrice: String,
        maxFeePerGas: String? = nil,
        maxPriorityFeePerGas: String? = nil,
        estimatedTime: TimeInterval? = nil
    ) {
        self.gasLimit = gasLimit
        self.gasPrice = gasPrice
        self.maxFeePerGas = maxFeePerGas
        self.maxPriorityFeePerGas = maxPriorityFeePerGas
        self.estimatedTime = estimatedTime
    }
}

/// 가스 트래커 응답 모델
public struct GasResponse: Codable {
    public let status: String
    public let message: String
    public let result: GasResult
    
    public init(status: String, message: String, result: GasResult) {
        self.status = status
        self.message = message
        self.result = result
    }
}

/// 가스 트래커 결과 모델
public struct GasResult: Codable {
    public let SafeGasPrice: String
    public let StandardGasPrice: String
    public let FastGasPrice: String
    
    public init(SafeGasPrice: String, StandardGasPrice: String, FastGasPrice: String) {
        self.SafeGasPrice = SafeGasPrice
        self.StandardGasPrice = StandardGasPrice
        self.FastGasPrice = FastGasPrice
    }
}