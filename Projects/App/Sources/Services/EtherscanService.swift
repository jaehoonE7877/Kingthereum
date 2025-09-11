import Foundation
import Entity
import Core
import os.log

/// 🔗 Etherscan API 서비스 - Production Level
/// Revolut/N26 수준의 안정적인 블록체인 데이터 통합
@MainActor
public final class EtherscanService {
    
    // MARK: - Configuration
    
    private struct Config {
        static let baseURL = "https://api.etherscan.io/api"
        static let apiKey = "YourEtherscanAPIKey" // TODO: 실제 API 키로 교체 필요
        static let requestTimeout: TimeInterval = 15.0
        static let maxRetries = 3
        static let rateLimitDelay: TimeInterval = 0.2 // 5 requests/second
    }
    
    // MARK: - Core Properties
    
    private let session: URLSession
    private let logger = Logger(subsystem: "com.kingthereum.etherscan", category: "service")
    private var lastRequestTime: Date = .distantPast
    
    // MARK: - Rate Limiting
    
    private let requestQueue = DispatchQueue(label: "etherscan.requests", qos: .userInitiated)
    private var requestCount = 0
    private var requestWindow = Date()
    
    // MARK: - Initialization
    
    public init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = Config.requestTimeout
        configuration.timeoutIntervalForResource = Config.requestTimeout * 2
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = URLCache(memoryCapacity: 10 * 1024 * 1024, diskCapacity: 50 * 1024 * 1024)
        
        self.session = URLSession(configuration: configuration)
        
        logger.info("🔗 EtherscanService initialized")
    }
    
    // MARK: - Public API
    
    /// 지갑 주소의 거래 내역 조회 (페이지네이션 지원)
    func getTransactionHistory(
        address: String, 
        startBlock: Int? = nil, 
        endBlock: Int? = nil,
        page: Int = 1,
        offset: Int = 20
    ) async throws -> EtherscanTransactionListResponse {
        logger.info("📊 Fetching transaction history for address: \(address.prefix(6))...***")
        
        await applyRateLimit()
        
        let parameters: [String: String] = [
            "module": "account",
            "action": "txlist",
            "address": address,
            "startblock": startBlock.map(String.init) ?? "0",
            "endblock": endBlock.map(String.init) ?? "99999999",
            "page": String(page),
            "offset": String(offset),
            "sort": "desc",
            "apikey": Config.apiKey
        ]
        
        return try await performRequest(parameters: parameters, responseType: EtherscanTransactionListResponse.self)
    }
    
    /// ERC-20 토큰 전송 내역 조회
    func getTokenTransferHistory(
        address: String,
        contractAddress: String? = nil,
        page: Int = 1,
        offset: Int = 20
    ) async throws -> EtherscanTokenTransferResponse {
        logger.info("🪙 Fetching token transfers for address: \(address.prefix(6))...***")
        
        await applyRateLimit()
        
        var parameters: [String: String] = [
            "module": "account",
            "action": "tokentx",
            "address": address,
            "page": String(page),
            "offset": String(offset),
            "sort": "desc",
            "apikey": Config.apiKey
        ]
        
        if let contractAddress = contractAddress {
            parameters["contractaddress"] = contractAddress
        }
        
        return try await performRequest(parameters: parameters, responseType: EtherscanTokenTransferResponse.self)
    }
    
    /// 이더리움 잔액 조회
    func getEtherBalance(address: String) async throws -> EtherscanBalanceResponse {
        logger.info("💰 Fetching ETH balance for address: \(address.prefix(6))...***")
        
        await applyRateLimit()
        
        let parameters: [String: String] = [
            "module": "account",
            "action": "balance",
            "address": address,
            "tag": "latest",
            "apikey": Config.apiKey
        ]
        
        return try await performRequest(parameters: parameters, responseType: EtherscanBalanceResponse.self)
    }
    
    /// 단일 거래 상세 정보 조회
    func getTransactionDetails(txHash: String) async throws -> EtherscanTransactionResponse {
        logger.info("🔍 Fetching transaction details for hash: \(txHash.prefix(6))...***")
        
        await applyRateLimit()
        
        let parameters: [String: String] = [
            "module": "proxy",
            "action": "eth_getTransactionByHash",
            "txhash": txHash,
            "apikey": Config.apiKey
        ]
        
        return try await performRequest(parameters: parameters, responseType: EtherscanTransactionResponse.self)
    }
    
    /// 현재 가스 가격 조회
    func getCurrentGasPrice() async throws -> EtherscanGasPriceResponse {
        logger.info("⛽ Fetching current gas price")
        
        await applyRateLimit()
        
        let parameters: [String: String] = [
            "module": "proxy",
            "action": "eth_gasPrice",
            "apikey": Config.apiKey
        ]
        
        return try await performRequest(parameters: parameters, responseType: EtherscanGasPriceResponse.self)
    }
    
    // MARK: - Private Methods
    
    private func performRequest<T: Decodable>(
        parameters: [String: String],
        responseType: T.Type
    ) async throws -> T {
        let url = try buildURL(parameters: parameters)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Kingthereum-iOS/1.0", forHTTPHeaderField: "User-Agent")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw EtherscanError.invalidResponse
        }
        
        logger.debug("📡 API Response: \(httpResponse.statusCode)")
        
        switch httpResponse.statusCode {
        case 200:
            do {
                let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                return decodedResponse
            } catch {
                logger.error("❌ JSON Decoding failed: \(error)")
                throw EtherscanError.decodingFailed(error)
            }
            
        case 429:
            logger.warning("⚠️ Rate limit exceeded, retrying...")
            try await Task.sleep(for: .seconds(1))
            return try await performRequest(parameters: parameters, responseType: responseType)
            
        case 400...499:
            throw EtherscanError.clientError(httpResponse.statusCode)
            
        case 500...599:
            throw EtherscanError.serverError(httpResponse.statusCode)
            
        default:
            throw EtherscanError.unknownError(httpResponse.statusCode)
        }
    }
    
    private func buildURL(parameters: [String: String]) throws -> URL {
        guard var components = URLComponents(string: Config.baseURL) else {
            throw EtherscanError.invalidURL
        }
        
        components.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        
        guard let url = components.url else {
            throw EtherscanError.invalidURL
        }
        
        return url
    }
    
    private func applyRateLimit() async {
        let now = Date()
        let timeSinceLastRequest = now.timeIntervalSince(lastRequestTime)
        
        if timeSinceLastRequest < Config.rateLimitDelay {
            let sleepTime = Config.rateLimitDelay - timeSinceLastRequest
            try? await Task.sleep(for: .seconds(sleepTime))
        }
        
        lastRequestTime = Date()
    }
}

// MARK: - Response Models

/// Etherscan 거래 목록 응답
struct EtherscanTransactionListResponse: Codable {
    let status: String
    let message: String
    let result: [EtherscanTransaction]
    
    var isSuccess: Bool {
        return status == "1"
    }
}

/// Etherscan 토큰 전송 응답
struct EtherscanTokenTransferResponse: Codable {
    let status: String
    let message: String
    let result: [EtherscanTokenTransfer]
    
    var isSuccess: Bool {
        return status == "1"
    }
}

/// Etherscan 잔액 응답
struct EtherscanBalanceResponse: Codable {
    let status: String
    let message: String
    let result: String
    
    var isSuccess: Bool {
        return status == "1"
    }
    
    var balanceInEther: Decimal {
        guard let wei = Decimal(string: result) else { return 0 }
        return wei / pow(10, 18)
    }
}

/// Etherscan 거래 상세 응답
struct EtherscanTransactionResponse: Codable {
    let jsonrpc: String?
    let result: EtherscanTransactionDetail?
    let error: EtherscanAPIError?
}

/// Etherscan 가스 가격 응답
struct EtherscanGasPriceResponse: Codable {
    let jsonrpc: String?
    let result: String?
    let error: EtherscanAPIError?
    
    var gasPriceInGwei: Decimal {
        guard let result = result,
              let wei = Decimal(string: result.hasPrefix("0x") ? String(result.dropFirst(2)) : result) else {
            return 0
        }
        return wei / pow(10, 9)
    }
}

/// Etherscan 거래 정보
struct EtherscanTransaction: Codable {
    let blockNumber: String
    let timeStamp: String
    let hash: String
    let nonce: String
    let blockHash: String
    let transactionIndex: String
    let from: String
    let to: String
    let value: String
    let gas: String
    let gasPrice: String
    let isError: String
    let txreceipt_status: String
    let input: String
    let contractAddress: String
    let cumulativeGasUsed: String
    let gasUsed: String
    let confirmations: String
    let methodId: String?
    let functionName: String?
}

/// Etherscan 토큰 전송 정보
struct EtherscanTokenTransfer: Codable {
    let blockNumber: String
    let timeStamp: String
    let hash: String
    let nonce: String
    let blockHash: String
    let from: String
    let contractAddress: String
    let to: String
    let value: String
    let tokenName: String
    let tokenSymbol: String
    let tokenDecimal: String
    let transactionIndex: String
    let gas: String
    let gasPrice: String
    let gasUsed: String
    let cumulativeGasUsed: String
    let input: String
    let confirmations: String
}

/// Etherscan 거래 상세 정보
struct EtherscanTransactionDetail: Codable {
    let blockHash: String?
    let blockNumber: String?
    let from: String?
    let gas: String?
    let gasPrice: String?
    let hash: String?
    let input: String?
    let nonce: String?
    let to: String?
    let transactionIndex: String?
    let value: String?
    let type: String?
    let chainId: String?
    let v: String?
    let r: String?
    let s: String?
}

/// Etherscan API 에러
struct EtherscanAPIError: Codable {
    let code: Int
    let message: String
}

// MARK: - Error Types

enum EtherscanError: LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingFailed(Error)
    case clientError(Int)
    case serverError(Int)
    case unknownError(Int)
    case rateLimitExceeded
    case apiKeyInvalid
    case networkUnavailable
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "잘못된 URL입니다"
        case .invalidResponse:
            return "서버 응답이 올바르지 않습니다"
        case .decodingFailed(let error):
            return "데이터 파싱 실패: \(error.localizedDescription)"
        case .clientError(let code):
            return "클라이언트 오류 (코드: \(code))"
        case .serverError(let code):
            return "서버 오류 (코드: \(code))"
        case .unknownError(let code):
            return "알 수 없는 오류 (코드: \(code))"
        case .rateLimitExceeded:
            return "API 요청 한도를 초과했습니다"
        case .apiKeyInvalid:
            return "API 키가 유효하지 않습니다"
        case .networkUnavailable:
            return "네트워크에 연결할 수 없습니다"
        }
    }
}

// MARK: - Extensions

extension EtherscanTransaction {
    /// Entity.Transaction으로 변환
    func toTransaction() -> Transaction {
        let timestamp = Date(timeIntervalSince1970: TimeInterval(timeStamp) ?? 0)
        let status: TransactionStatus
        
        if isError == "1" || txreceipt_status == "0" {
            status = .failed
        } else if confirmations == "0" {
            status = .pending
        } else {
            status = .confirmed
        }
        
        return Transaction(
            hash: hash,
            from: from,
            to: to,
            value: value,
            gasUsed: gasUsed,
            gasPrice: gasPrice,
            status: status,
            timestamp: timestamp,
            blockNumber: Int(blockNumber) ?? 0,
            tokenSymbol: nil,
            tokenName: nil
        )
    }
}

extension EtherscanTokenTransfer {
    /// Entity.Transaction으로 변환 (토큰 전송)
    func toTransaction() -> Transaction {
        let timestamp = Date(timeIntervalSince1970: TimeInterval(timeStamp) ?? 0)
        let status: TransactionStatus = .confirmed // 토큰 전송은 이미 확정된 상태
        
        return Transaction(
            hash: hash,
            from: from,
            to: to,
            value: value,
            gasUsed: gasUsed,
            gasPrice: gasPrice,
            status: status,
            timestamp: timestamp,
            blockNumber: Int(blockNumber) ?? 0,
            tokenSymbol: tokenSymbol,
            tokenName: tokenName
        )
    }
}
