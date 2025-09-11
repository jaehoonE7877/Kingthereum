import Foundation

/// 이더리움 가스 추정 정보 모델
/// 
/// 트랜잭션 실행에 필요한 가스 정보를 포함합니다.
/// Legacy 가스 모델과 EIP-1559 (London Fork) 가스 모델을 모두 지원합니다.
/// 
/// ## 가스 시스템 개요:
/// - **Gas Limit**: 트랜잭션이 사용할 수 있는 최대 가스 단위
/// - **Gas Price**: Legacy 모델에서 가스 단위당 가격 (Wei)
/// - **Base Fee**: EIP-1559에서 네트워크가 정한 기본 수수료
/// - **Priority Fee**: EIP-1559에서 마이너에게 주는 팁
/// - **Max Fee**: EIP-1559에서 지불할 의향이 있는 최대 수수료
/// 
/// ## EIP-1559 vs Legacy:
/// ```
/// Legacy: Total Cost = Gas Limit × Gas Price
/// EIP-1559: Total Cost = Gas Limit × (Base Fee + Priority Fee)
/// ```
/// 
/// ## 사용 예시:
/// ```swift
/// let estimate = GasEstimate(
///     gasLimit: "21000",           // 기본 이더 전송
///     gasPrice: "20000000000",     // 20 Gwei (Legacy)
///     maxFeePerGas: "30000000000", // 30 Gwei 최대
///     maxPriorityFeePerGas: "2000000000" // 2 Gwei 팁
/// )
/// 
/// let totalCostWei = estimate.calculateMaxCost()
/// ```
public struct GasEstimate: Codable, Sendable {
    /// 트랜잭션 실행에 필요한 최대 가스 단위
    /// 
    /// 일반적인 가스 한계 예시:
    /// - ETH 전송: 21,000
    /// - ERC-20 토큰 전송: ~65,000
    /// - 복잡한 스마트 컨트랙트 호출: 100,000+
    public let gasLimit: String
    
    /// Legacy 가스 모델에서의 가스 단위당 가격 (Wei)
    /// 
    /// EIP-1559 이전 네트워크에서 사용되거나
    /// 사용자가 Legacy 트랜잭션을 선택할 때 사용
    public let gasPrice: String
    
    /// EIP-1559에서 지불할 의향이 있는 가스 단위당 최대 수수료 (Wei)
    /// 
    /// Base Fee + Priority Fee의 합이 이 값을 초과할 수 없음
    /// 실제로는 더 적은 금액이 차감될 수 있음
    public let maxFeePerGas: String?
    
    /// EIP-1559에서 마이너에게 지불할 우선순위 수수료 (Wei)
    /// 
    /// 트랜잭션이 더 빨리 처리되도록 하는 '팁'
    /// 높을수록 빠른 처리, 일반적으로 1-5 Gwei
    public let maxPriorityFeePerGas: String?
    
    /// 트랜잭션이 블록에 포함될 것으로 예상되는 시간 (초)
    /// 
    /// 가스 가격과 네트워크 상황에 따라 달라짐
    /// nil일 경우 추정 불가능한 상태
    public let estimatedTime: TimeInterval?
    
    /// GasEstimate 초기화
    /// 
    /// - Parameters:
    ///   - gasLimit: 가스 한계 (hex 문자열)
    ///   - gasPrice: Legacy 가스 가격 (Wei, hex 문자열)
    ///   - maxFeePerGas: EIP-1559 최대 수수료 (Wei, hex 문자열)
    ///   - maxPriorityFeePerGas: EIP-1559 우선순위 수수료 (Wei, hex 문자열)
    ///   - estimatedTime: 예상 소요 시간 (초)
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

/// 외부 가스 트래커 API 응답 모델
/// 
/// Etherscan, GasNow 등의 가스 트래커 서비스에서 제공하는
/// 실시간 가스 가격 정보를 파싱하기 위한 모델입니다.
/// 
/// ## API 응답 구조:
/// ```json
/// {
///   "status": "1",
///   "message": "OK",
///   "result": {
///     "SafeGasPrice": "13",
///     "StandardGasPrice": "14", 
///     "FastGasPrice": "15"
///   }
/// }
/// ```
/// 
/// ## 가스 가격 옵션:
/// - **Safe**: 저렴하지만 느림 (~10분 이상)
/// - **Standard**: 일반적인 속도 (~3-5분)
/// - **Fast**: 빠름 (~1분 이내)
/// 
/// ## 사용 예시:
/// ```swift
/// let response = try JSONDecoder().decode(GasResponse.self, from: data)
/// if response.isSuccess {
///     let gasPrice = response.result.StandardGasPrice
///     print("Current gas price: \(gasPrice) Gwei")
/// }
/// ```
public struct GasResponse: Codable {
    /// API 호출 성공 여부 ("1": 성공, "0": 실패)
    public let status: String
    
    /// API 응답 메시지 ("OK", "NOTOK" 등)
    public let message: String
    
    /// 실제 가스 가격 데이터
    public let result: GasResult
    
    /// GasResponse 초기화
    /// 
    /// - Parameters:
    ///   - status: API 호출 상태
    ///   - message: 응답 메시지
    ///   - result: 가스 가격 결과
    public init(status: String, message: String, result: GasResult) {
        self.status = status
        self.message = message
        self.result = result
    }
}

/// 가스 트래커 결과 데이터 모델
/// 
/// 다양한 속도 옵션별 가스 가격을 Gwei 단위로 제공합니다.
/// 사용자가 트랜잭션 우선순위에 따라 적절한 가스 가격을 선택할 수 있도록 합니다.
/// 
/// ## 가격 레벨별 특성:
/// ### Safe (안전)
/// - **속도**: 느림 (10+ 분)
/// - **비용**: 가장 저렴
/// - **적합한 경우**: 급하지 않은 트랜잭션, 비용 절약 우선
/// 
/// ### Standard (표준)
/// - **속도**: 보통 (3-5 분)
/// - **비용**: 중간
/// - **적합한 경우**: 일반적인 트랜잭션, 균형 잡힌 선택
/// 
/// ### Fast (빠름)
/// - **속도**: 빠름 (1-2 분)
/// - **비용**: 비쌈
/// - **적합한 경우**: 긴급한 트랜잭션, DEX 거래, 아비트리지
/// 
/// ## 단위 변환:
/// ```swift
/// let gwei = gasResult.StandardGasPrice // "20" (Gwei)
/// let wei = gasResult.standardGasPriceInWei // "20000000000" (Wei)
/// ```
public struct GasResult: Codable {
    /// 안전한 가스 가격 (Gwei 단위)
    /// 네트워크 혼잡 시에도 10분 내 처리 보장
    public let SafeGasPrice: String
    
    /// 표준 가스 가격 (Gwei 단위) 
    /// 일반적인 상황에서 3-5분 내 처리 예상
    public let StandardGasPrice: String
    
    /// 빠른 가스 가격 (Gwei 단위)
    /// 높은 우선순위로 1-2분 내 빠른 처리
    public let FastGasPrice: String
    
    /// GasResult 초기화
    /// 
    /// - Parameters:
    ///   - SafeGasPrice: 안전 가격 (Gwei 문자열)
    ///   - StandardGasPrice: 표준 가격 (Gwei 문자열)
    ///   - FastGasPrice: 빠른 가격 (Gwei 문자열)
    public init(SafeGasPrice: String, StandardGasPrice: String, FastGasPrice: String) {
        self.SafeGasPrice = SafeGasPrice
        self.StandardGasPrice = StandardGasPrice
        self.FastGasPrice = FastGasPrice
    }
}

// MARK: - GasEstimate Extensions

public extension GasEstimate {
    /// EIP-1559 트랜잭션인지 확인
    var isEIP1559: Bool {
        return maxFeePerGas != nil && maxPriorityFeePerGas != nil
    }
    
    /// Legacy 트랜잭션인지 확인
    var isLegacy: Bool {
        return !isEIP1559
    }
    
    /// 가스 한계를 정수로 변환
    var gasLimitInt: UInt64? {
        let cleanHex = gasLimit.hasPrefix("0x") ? String(gasLimit.dropFirst(2)) : gasLimit
        return UInt64(cleanHex, radix: 16)
    }
    
    /// Legacy 가스 가격을 Wei 단위 정수로 변환
    var gasPriceWei: UInt64? {
        let cleanHex = gasPrice.hasPrefix("0x") ? String(gasPrice.dropFirst(2)) : gasPrice
        return UInt64(cleanHex, radix: 16)
    }
    
    /// 최대 수수료를 Wei 단위 정수로 변환
    var maxFeeWei: UInt64? {
        guard let maxFee = maxFeePerGas else { return nil }
        let cleanHex = maxFee.hasPrefix("0x") ? String(maxFee.dropFirst(2)) : maxFee
        return UInt64(cleanHex, radix: 16)
    }
    
    /// 우선순위 수수료를 Wei 단위 정수로 변환
    var priorityFeeWei: UInt64? {
        guard let priorityFee = maxPriorityFeePerGas else { return nil }
        let cleanHex = priorityFee.hasPrefix("0x") ? String(priorityFee.dropFirst(2)) : priorityFee
        return UInt64(cleanHex, radix: 16)
    }
    
    /// Legacy 트랜잭션의 최대 비용 계산 (Wei)
    var legacyMaxCost: UInt64? {
        guard let limit = gasLimitInt, let price = gasPriceWei else { return nil }
        return limit * price
    }
    
    /// EIP-1559 트랜잭션의 최대 비용 계산 (Wei)
    var eip1559MaxCost: UInt64? {
        guard let limit = gasLimitInt, let maxFee = maxFeeWei else { return nil }
        return limit * maxFee
    }
    
    /// 트랜잭션 타입에 따른 최대 비용 계산
    func calculateMaxCost() -> UInt64? {
        if isEIP1559 {
            return eip1559MaxCost
        } else {
            return legacyMaxCost
        }
    }
    
    /// 예상 소요 시간을 분 단위로 반환
    var estimatedMinutes: Double? {
        guard let time = estimatedTime else { return nil }
        return time / 60.0
    }
    
    /// 사용자 친화적인 비용 설명
    func costDescription() -> String {
        guard let maxCost = calculateMaxCost() else {
            return "Cost calculation unavailable"
        }
        
        let eth = Double(maxCost) / 1_000_000_000_000_000_000.0 // Wei to ETH
        let costText = String(format: "%.6f ETH", eth)
        
        if let minutes = estimatedMinutes {
            return "\(costText) (~\(Int(minutes))min)"
        } else {
            return costText
        }
    }
}

// MARK: - GasResponse Extensions

public extension GasResponse {
    /// API 호출이 성공했는지 확인
    var isSuccess: Bool {
        return status == "1" && message.uppercased() == "OK"
    }
    
    /// API 호출이 실패했는지 확인
    var isFailure: Bool {
        return !isSuccess
    }
}

// MARK: - GasResult Extensions

public extension GasResult {
    /// Safe 가스 가격을 Wei 단위로 변환
    var safeGasPriceInWei: String {
        return gweiToWei(SafeGasPrice)
    }
    
    /// Standard 가스 가격을 Wei 단위로 변환
    var standardGasPriceInWei: String {
        return gweiToWei(StandardGasPrice)
    }
    
    /// Fast 가스 가격을 Wei 단위로 변환
    var fastGasPriceInWei: String {
        return gweiToWei(FastGasPrice)
    }
    
    /// 모든 가스 가격을 배열로 반환 (Gwei)
    var allPrices: [String] {
        return [SafeGasPrice, StandardGasPrice, FastGasPrice]
    }
    
    /// 가스 가격 옵션을 레이블과 함께 반환
    var priceOptions: [(label: String, price: String, description: String)] {
        return [
            (
                label: "Safe",
                price: SafeGasPrice,
                description: "Slow but cheap (~10+ min)"
            ),
            (
                label: "Standard", 
                price: StandardGasPrice,
                description: "Balanced speed and cost (~3-5 min)"
            ),
            (
                label: "Fast",
                price: FastGasPrice,
                description: "Quick but expensive (~1-2 min)"
            )
        ]
    }
    
    /// 가격 차이 분석
    var priceAnalysis: (cheapest: String, expensive: String, spread: Double) {
        let prices: [Double] = [
            Double(SafeGasPrice) ?? 0,
            Double(StandardGasPrice) ?? 0,
            Double(FastGasPrice) ?? 0
        ]
        
        let min = prices.min() ?? 0
        let max = prices.max() ?? 0
        let spread = max - min
        
        return (
            cheapest: String(format: "%.1f", min),
            expensive: String(format: "%.1f", max),
            spread: spread
        )
    }
    
    /// Gwei를 Wei로 변환하는 내부 함수
    private func gweiToWei(_ gwei: String) -> String {
        guard let gweiValue = Double(gwei) else { return "0" }
        let weiValue = gweiValue * 1_000_000_000 // 1 Gwei = 10^9 Wei
        return String(format: "%.0f", weiValue)
    }
    
    /// 16진수 형태로 Wei 값 반환
    func hexWeiValue(for level: GasLevel) -> String {
        let weiString: String
        switch level {
        case .safe:
            weiString = safeGasPriceInWei
        case .standard:
            weiString = standardGasPriceInWei
        case .fast:
            weiString = fastGasPriceInWei
        }
        
        guard let weiValue = UInt64(weiString) else { return "0x0" }
        return "0x" + String(weiValue, radix: 16)
    }
}

// MARK: - Supporting Types

/// 가스 가격 레벨 옵션
public enum GasLevel: String, CaseIterable {
    case safe = "safe"
    case standard = "standard" 
    case fast = "fast"
    
    /// 사용자 친화적인 이름
    public var displayName: String {
        switch self {
        case .safe: return "Safe"
        case .standard: return "Standard"
        case .fast: return "Fast"
        }
    }
    
    /// 예상 소요 시간 (분)
    public var estimatedMinutes: ClosedRange<Int> {
        switch self {
        case .safe: return 10...15
        case .standard: return 3...5
        case .fast: return 1...2
        }
    }
}
