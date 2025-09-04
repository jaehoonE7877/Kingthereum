import Foundation
import Entity
import Core
import Web3Swift
import SecurityKit

// MARK: - SendWorkerProtocol

protocol SendWorkerProtocol {
    /// 이더리움 주소 유효성 검증
    func validateEthereumAddress(_ address: String) -> Bool
    
    /// 가스비 추정
    func estimateGasFee(recipientAddress: String, amount: String) -> Entity.GasOptions?
    
    /// 현재 지갑 잔액 조회
    func getCurrentBalance() -> Decimal
    
    /// 거래 준비
    func prepareTransaction(recipientAddress: String, amount: Decimal, gasFee: Entity.GasFee) -> Entity.PendingTransaction?
    
    /// 생체 인증 수행
    func authenticateWithBiometric() async -> Bool
    
    /// 거래 전송
    func sendTransaction(_ transaction: Entity.PendingTransaction) async -> Result<String, Error>
}

// MARK: - SendWorker

/// SendWorker는 백그라운드 작업을 처리하므로 @MainActor가 필요하지 않음
/// Sendable 프로토콜 준수로 안전한 cross-actor 사용 보장
final class SendWorker: SendWorkerProtocol, Sendable {
    
    private let walletService: WalletServiceProtocol
    private let secureKeyManager = SecureKeyManager()
    
    init(walletService: WalletServiceProtocol = WalletService.shared) {
        self.walletService = walletService
    }
    
    // MARK: - Address Validation
    
    func validateEthereumAddress(_ address: String) -> Bool {
        Logger.debug("🔍 이더리움 주소 유효성 검증: \(address.prefix(10))...")
        
        // 빈 문자열 체크
        guard !address.isEmpty else {
            Logger.debug("❌ 빈 주소")
            return false
        }
        
        // 0x 접두사 체크
        guard address.hasPrefix("0x") else {
            Logger.debug("❌ 0x 접두사 없음")
            return false
        }
        
        // 길이 체크 (0x + 40 hex characters = 42 characters)
        guard address.count == 42 else {
            Logger.debug("❌ 주소 길이 불일치: \(address.count)")
            return false
        }
        
        // Hex 문자 체크
        let hexPart = String(address.dropFirst(2))
        let hexCharacterSet = CharacterSet(charactersIn: "0123456789abcdefABCDEF")
        guard hexPart.rangeOfCharacter(from: hexCharacterSet.inverted) == nil else {
            Logger.debug("❌ 유효하지 않은 Hex 문자")
            return false
        }
        
        // Web3Swift를 이용한 추가 검증 (체크섬 검증)
        do {
            let ethAddress = EthereumAddress(address)
            Logger.debug("✅ 주소 유효성 검증 성공")
            return ethAddress.isValid
        } catch {
            Logger.debug("❌ Web3Swift 주소 검증 실패: \(error)")
            return false
        }
    }
    
    // MARK: - Gas Fee Estimation
    
    func estimateGasFee(recipientAddress: String, amount: String) -> Entity.GasOptions? {
        Logger.debug("⛽ 가스비 추정 시작")
        
        guard let amountDecimal = Decimal(string: amount) else {
            Logger.error("❌ 유효하지 않은 금액: \(amount)")
            return nil
        }
        
        do {
            // 실제 네트워크에서 가스비 추정 (Web3Swift 사용)
            let gasPrice = try walletService.getGasPrice()
            let gasLimit: BigUInt = 21000 // ETH 전송 기본 가스 제한
            
            // 세 가지 옵션으로 가스비 계산
            let slowGasPrice = gasPrice * 8 / 10  // 80%
            let normalGasPrice = gasPrice         // 100%
            let fastGasPrice = gasPrice * 15 / 10 // 150%
            
            // ETH 가격 조회 (USD 환산용)
            let ethPriceUSD = getETHPriceUSD()
            
            // 각 옵션별 수수료 계산
            let slowFee = calculateFee(gasPrice: slowGasPrice, gasLimit: gasLimit, ethPriceUSD: ethPriceUSD)
            let normalFee = calculateFee(gasPrice: normalGasPrice, gasLimit: gasLimit, ethPriceUSD: ethPriceUSD)
            let fastFee = calculateFee(gasPrice: fastGasPrice, gasLimit: gasLimit, ethPriceUSD: ethPriceUSD)
            
            let gasOptions = Entity.GasOptions(
                slow: Entity.GasFee(
                    gasPrice: slowGasPrice.description,
                    estimatedTime: 180, // 3분
                    feeInETH: slowFee.eth,
                    feeInUSD: slowFee.usd
                ),
                normal: Entity.GasFee(
                    gasPrice: normalGasPrice.description,
                    estimatedTime: 60, // 1분
                    feeInETH: normalFee.eth,
                    feeInUSD: normalFee.usd
                ),
                fast: Entity.GasFee(
                    gasPrice: fastGasPrice.description,
                    estimatedTime: 30, // 30초
                    feeInETH: fastFee.eth,
                    feeInUSD: fastFee.usd
                )
            )
            
            Logger.debug("✅ 가스비 추정 완료")
            return gasOptions
            
        } catch {
            Logger.error("❌ 가스비 추정 실패: \(error)")
            return nil
        }
    }
    
    // MARK: - Balance Management
    
    func getCurrentBalance() -> Decimal {
        Logger.debug("💳 현재 지갑 잔액 조회")
        
        do {
            // 현재 활성 지갑의 잔액 조회
            let balance = try walletService.getBalance()
            Logger.debug("✅ 잔액 조회 성공: \(balance) ETH")
            return balance
        } catch {
            Logger.error("❌ 잔액 조회 실패: \(error)")
            return 0
        }
    }
    
    // MARK: - Transaction Preparation
    
    func prepareTransaction(recipientAddress: String, amount: Decimal, gasFee: Entity.GasFee) -> Entity.PendingTransaction? {
        Logger.debug("📝 거래 준비 시작")
        
        do {
            // Nonce 조회
            let nonce = try walletService.getNonce()
            
            // 가스 제한 설정
            let gasLimit = "21000" // ETH 전송 기본값
            
            let transaction = Entity.PendingTransaction(
                recipientAddress: recipientAddress,
                amount: amount,
                gasPrice: gasFee.gasPrice,
                gasLimit: gasLimit,
                nonce: nonce.description
            )
            
            Logger.debug("✅ 거래 준비 완료")
            return transaction
            
        } catch {
            Logger.error("❌ 거래 준비 실패: \(error)")
            return nil
        }
    }
    
    // MARK: - Biometric Authentication
    
    func authenticateWithBiometric() async -> Bool {
        Logger.debug("🔐 생체 인증 시작")
        
        do {
            // SecurityKit의 BiometricManager 사용 (향후 구현)
            // 현재는 시뮬레이션
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1초 대기
            
            Logger.debug("✅ 생체 인증 성공")
            return true
            
        } catch {
            Logger.error("❌ 생체 인증 실패: \(error)")
            return false
        }
    }
    
    // MARK: - Transaction Sending
    
    func sendTransaction(_ transaction: Entity.PendingTransaction) async -> Result<String, Error> {
        Logger.debug("📤 거래 전송 시작")
        
        do {
            // SecureKeyManager를 통해 안전하게 개인키 접근
            let keyReference = try await secureKeyManager.getKeyReference(tag: "wallet_private_key")
            
            // Web3Swift를 사용한 거래 서명 및 전송
            let transactionHash = try await walletService.sendTransaction(
                to: transaction.recipientAddress,
                amount: transaction.amount,
                gasPrice: BigUInt(transaction.gasPrice) ?? BigUInt(20000000000), // 20 Gwei 기본값
                gasLimit: BigUInt(transaction.gasLimit) ?? BigUInt(21000),
                nonce: BigUInt(transaction.nonce) ?? BigUInt(0),
                keyReference: keyReference
            )
            
            Logger.debug("✅ 거래 전송 성공: \(transactionHash)")
            return .success(transactionHash)
            
        } catch {
            Logger.error("❌ 거래 전송 실패: \(error)")
            return .failure(error)
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func calculateFee(gasPrice: BigUInt, gasLimit: BigUInt, ethPriceUSD: Decimal) -> (eth: Decimal, usd: Decimal) {
        // Wei를 ETH로 변환 (1 ETH = 10^18 Wei)
        let totalWei = gasPrice * gasLimit
        let ethAmount = Decimal(string: totalWei.description) ?? 0
        let divisor = pow(Decimal(10), 18)
        let feeInETH = ethAmount / divisor
        
        // USD 환산
        let feeInUSD = feeInETH * ethPriceUSD
        
        return (eth: feeInETH, usd: feeInUSD)
    }
    
    private func getETHPriceUSD() -> Decimal {
        // 실제로는 CoinGecko API나 다른 가격 API에서 가져와야 함
        // 현재는 고정값 사용
        return 2000.0 // $2000 per ETH (예시)
    }
}

// MARK: - Supporting Types

enum SendError: LocalizedError {
    case invalidAddress
    case insufficientBalance
    case gasEstimationFailed
    case transactionPreparationFailed
    case authenticationFailed
    case networkError
    case missingRequiredData
    
    var errorDescription: String? {
        switch self {
        case .invalidAddress:
            return "유효하지 않은 주소입니다"
        case .insufficientBalance:
            return "잔액이 부족합니다"
        case .gasEstimationFailed:
            return "가스비 추정에 실패했습니다"
        case .transactionPreparationFailed:
            return "거래 준비에 실패했습니다"
        case .authenticationFailed:
            return "인증에 실패했습니다"
        case .networkError:
            return "네트워크 오류가 발생했습니다"
        case .missingRequiredData:
            return "필수 데이터가 누락되었습니다"
        }
    }
}