import Foundation
import BigInt
@preconcurrency import web3swift
@preconcurrency import Web3Core

import Core

// MARK: - Extensions
extension String {
    func stripHexPrefix() -> String {
        return hasPrefix("0x") ? String(dropFirst(2)) : self
    }
}

public protocol EthereumWorkerProtocol: Sendable {
    func getBalance(for address: String) async throws -> String
    func getBalanceInWei(for address: String) async throws -> String
    func sendTransaction(from: String, to: String, value: String, gasPrice: String?, gasLimit: String?) async throws -> String
    func estimateGas(from: String, to: String, value: String) async throws -> String
    func getCurrentGasPrice() async throws -> String
    func getBlockNumber() async throws -> String
    func getTransactionReceipt(transactionHash: String) async throws -> TransactionReceipt?
    func getProvider() async -> Web3HttpProvider?
}

public actor EthereumWorker: EthereumWorkerProtocol {
    
    private let rpcURL: String
    private var web3: Web3?
    // InfuraMonitor 제거됨
    
    public init(rpcURL: String) throws {
        guard let url = URL(string: rpcURL) else {
            throw EthereumError.invalidRpcUrl
        }
        
        self.rpcURL = rpcURL
        
        // web3swift의 최신 API 사용
        let provider = Web3HttpProvider(url: url, network: Networks.Mainnet)
        self.web3 = Web3(provider: provider)
        
        Logger.debug("✅ Web3 프로바이더 초기화 완료: \(rpcURL)")
    }
    
    public func getProvider() async -> Web3HttpProvider? {
        return web3?.provider as? Web3HttpProvider
    }
    
    public func getBalance(for address: String) async throws -> String {
        // URL Session을 사용한 직접 JSON-RPC 호출
        return try await fetchBalanceDirectly(address: address)
    }
    
    /// URLSession을 사용한 직접 JSON-RPC 호출
    private func fetchBalanceDirectly(address: String) async throws -> String {
        // InfuraMonitor 제거됨
        
        Logger.debug("🔄 주소 잔액 직접 조회 중: \(address)")
        
        guard let url = URL(string: rpcURL) else {
            throw EthereumError.invalidRpcUrl
        }
        
        // eth_getBalance JSON-RPC 요청 생성
        let requestBody: [String: Any] = [
            "jsonrpc": "2.0",
            "method": "eth_getBalance",
            "params": [address.lowercased(), "latest"],
            "id": 1
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw EthereumError.networkError("HTTP 오류: \(response)")
        }
        
        // JSON 응답 파싱
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let result = json["result"] as? String else {
            throw EthereumError.networkError("잘못된 JSON 응답")
        }
        
        Logger.debug("✅ 원시 잔액 (hex): \(result)")
        
        // Hex를 BigUInt로 변환
        guard let balanceWei = BigUInt(result.stripHexPrefix(), radix: 16) else {
            throw EthereumError.networkError("잘못된 잔액 형식")
        }
        
        Logger.debug("✅ Wei 단위 잔액: \(balanceWei)")
        
        // Wei를 ETH로 변환 (1 ETH = 10^18 Wei)
        let divisor = BigUInt(10).power(18)
        let ethWhole = balanceWei / divisor
        let ethFraction = balanceWei % divisor
        
        // 4자리 정밀도로 포맷팅
        let fractionString = String(ethFraction).padding(toLength: 18, withPad: "0", startingAt: 0)
        let significantFraction = String(fractionString.prefix(4))
        
        let ethBalance = "\(ethWhole).\(significantFraction)"
        Logger.debug("✅ ETH 단위 잔액: \(ethBalance)")
        
        return ethBalance
    }
    
    public func getBalanceInWei(for address: String) async throws -> String {
        guard let url = URL(string: rpcURL) else {
            throw EthereumError.networkError("잘못된 RPC URL")
        }
        
        Logger.debug("💰 Wei 잔액 조회 시작: \(address)")
        
        let requestBody: [String: Any] = [
            "jsonrpc": "2.0",
            "method": "eth_getBalance",
            "params": [address, "latest"],
            "id": 1
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw EthereumError.networkError("HTTP 오류: \(response)")
        }
        
        // JSON 응답 파싱
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let result = json["result"] as? String else {
            throw EthereumError.networkError("잘못된 JSON 응답")
        }
        
        Logger.debug("✅ Wei 단위 잔액 (hex): \(result)")
        
        // Hex를 BigUInt로 변환 후 문자열로 반환
        guard let balanceWei = BigUInt(result.stripHexPrefix(), radix: 16) else {
            throw EthereumError.networkError("잘못된 잔액 형식")
        }
        
        return String(balanceWei)
    }
    
    public func sendTransaction(
        from: String,
        to: String,
        value: String,
        gasPrice: String?,
        gasLimit: String?
    ) async throws -> String {
        guard let web3 = self.web3 else {
            throw EthereumError.networkError("Web3가 초기화되지 않음")
        }
        
        guard let fromAddress = EthereumAddress(from),
              let toAddress = EthereumAddress(to) else {
            throw EthereumError.invalidAddress
        }
        
        do {
            // Infura 요청 수 모니터링
            // InfuraMonitor 제거됨
            
            // 트랜잭션 생성
            var transaction = CodableTransaction(to: toAddress)
            transaction.from = fromAddress
            transaction.value = Utilities.parseToBigUInt(value, decimals: 18) ?? BigUInt(0)
            
            // 가스 가격 설정
            if let gasPriceStr = gasPrice,
               let gasPriceBigUInt = BigUInt(gasPriceStr) {
                transaction.gasPrice = gasPriceBigUInt
            } else {
                // 현재 네트워크의 가스 가격 사용
                let gasPriceResult = try await web3.eth.gasPrice()
                transaction.maxFeePerGas = gasPriceResult
                transaction.maxPriorityFeePerGas = BigUInt(1_000_000_000) // 1 Gwei
            }
            
            // 가스 한도 설정
            if let gasLimitStr = gasLimit,
               let gasLimitBigUInt = BigUInt(gasLimitStr) {
                transaction.gasLimit = gasLimitBigUInt
            } else {
                // 가스 한도 자동 추정
                let gasEstimate = try await web3.eth.estimateGas(for: transaction, onBlock: .latest)
                transaction.gasLimit = gasEstimate
            }
            
            // Nonce 설정
            transaction.nonce = try await web3.eth.getTransactionCount(for: fromAddress, onBlock: .latest)
            
            // 트랜잭션 전송을 위해서는 서명된 트랜잭션이 필요
            // 임시로 hash만 반환 (실제로는 keystore에서 서명 필요)
            return "0x" + String(repeating: "0", count: 64)
            
        } catch {
            Logger.debug("❌ 트랜잭션 실패: \(error)")
            throw EthereumError.transactionFailed("트랜잭션 전송 실패: \(error.localizedDescription)")
        }
    }
    
    public func estimateGas(from: String, to: String, value: String) async throws -> String {
        guard let web3 = self.web3 else {
            throw EthereumError.networkError("Web3가 초기화되지 않음")
        }
        
        guard let fromAddress = EthereumAddress(from),
              let toAddress = EthereumAddress(to) else {
            throw EthereumError.invalidAddress
        }
        
        do {
            // InfuraMonitor 제거됨
            
            var transaction = CodableTransaction(to: toAddress)
            transaction.from = fromAddress
            transaction.value = Utilities.parseToBigUInt(value, decimals: 18) ?? BigUInt(0)
            
            let gasEstimate = try await web3.eth.estimateGas(for: transaction, onBlock: .latest)
            return String(gasEstimate)
            
        } catch {
            Logger.debug("❌ 가스 추정 실패: \(error)")
            throw EthereumError.gasEstimationFailed("가스 추정 실패: \(error.localizedDescription)")
        }
    }
    
    public func getCurrentGasPrice() async throws -> String {
        guard let web3 = self.web3 else {
            throw EthereumError.networkError("Web3가 초기화되지 않음")
        }
        
        do {
            // InfuraMonitor 제거됨
            
            let gasPrice = try await web3.eth.gasPrice()
            return String(gasPrice)
            
        } catch {
            Logger.debug("❌ 가스 가격 조회 실패: \(error)")
            throw EthereumError.networkError("가스 가격 조회 실패: \(error.localizedDescription)")
        }
    }
    
    public func getBlockNumber() async throws -> String {
        guard let web3 = self.web3 else {
            throw EthereumError.networkError("Web3가 초기화되지 않음")
        }
        
        do {
            // InfuraMonitor 제거됨
            
            let blockNumber = try await web3.eth.blockNumber()
            return String(blockNumber)
            
        } catch {
            Logger.debug("❌ 블록 번호 조회 실패: \(error)")
            throw EthereumError.networkError("블록 번호 조회 실패: \(error.localizedDescription)")
        }
    }
    
    public func getTransactionReceipt(transactionHash: String) async throws -> TransactionReceipt? {
        guard let web3 = self.web3 else {
            throw EthereumError.networkError("Web3가 초기화되지 않음")
        }
        
        do {
            // InfuraMonitor 제거됨
            
            guard let transactionHashData = Data(hex: transactionHash) else {
                throw EthereumError.invalidAddress
            }
            
            let receipt = try await web3.eth.transactionReceipt(transactionHashData)
            
            return TransactionReceipt(
                transactionHash: receipt.transactionHash.toHexString(),
                blockNumber: String(receipt.blockNumber),
                blockHash: receipt.blockHash.toHexString(),
                gasUsed: String(receipt.gasUsed),
                status: receipt.status == .ok ? "1" : "0"
            )
            
        } catch {
            Logger.debug("❌ 트랜잭션 영수증 조회 실패: \(error)")
            return nil
        }
    }
}

// MARK: - Ethereum Error Types
public enum EthereumError: LocalizedError, Equatable {
    case invalidRpcUrl
    case networkError(String)
    case invalidAddress
    case transactionFailed(String)
    case gasEstimationFailed(String)
    case insufficientFunds
    case unknownError
    
    public var errorDescription: String? {
        switch self {
        case .invalidRpcUrl:
            return "잘못된 RPC URL"
        case .networkError(let message):
            return "네트워크 오류: \(message)"
        case .invalidAddress:
            return "잘못된 이더리움 주소"
        case .transactionFailed(let message):
            return "트랜잭션 실패: \(message)"
        case .gasEstimationFailed(let message):
            return "가스 추정 실패: \(message)"
        case .insufficientFunds:
            return "잔액 부족"
        case .unknownError:
            return "알 수 없는 오류가 발생했습니다"
        }
    }
}

// MARK: - Supporting Types
public struct TransactionReceipt: Sendable {
    public let transactionHash: String
    public let blockNumber: String
    public let blockHash: String
    public let gasUsed: String
    public let status: String
    
    public init(transactionHash: String, blockNumber: String, blockHash: String, gasUsed: String, status: String) {
        self.transactionHash = transactionHash
        self.blockNumber = blockNumber
        self.blockHash = blockHash
        self.gasUsed = gasUsed
        self.status = status
    }
}
