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
        static let apiKey: String = {
            // 환경 변수에서 API 키 읽기 (개발/운영 분리)
            if let apiKey = Bundle.main.object(forInfoDictionaryKey: "ETHERSCAN_API_KEY") as? String,
               !apiKey.isEmpty && apiKey != "$(ETHERSCAN_API_KEY)" {
                return apiKey
            }
            // Info.plist에 없으면 UserDefaults에서 확인
            if let savedKey = UserDefaults.standard.string(forKey: "etherscan_api_key"),
               !savedKey.isEmpty {
                return savedKey
            }
            // 기본값 (테스트용 - 실제로는 공식 키 필요)
            return "YourEtherscanAPIKey"
        }()
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
        
        logger.info("🔗 EtherscanService shared instance initialized")
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
                // 디버그용 로그 (개발 환경에서만)
#if DEBUG
                if let jsonString = String(data: data, encoding: .utf8) {
                    logger.debug("📦 Response Data: \(String(jsonString.prefix(500)))...")
                }
#endif
                
                let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                return decodedResponse
            } catch {
                logger.error("❌ JSON Decoding failed: \(error)")
                
                // 더 구체적인 디코딩 에러 정보 제공
                if let decodingError = error as? DecodingError {
                    logger.error("📋 Decoding Error Details: \(decodingError.localizedDescription)")
                    
                    // 개발 환경에서 원본 데이터 로그
#if DEBUG
                    if let jsonString = String(data: data, encoding: .utf8) {
                        logger.error("📦 Failed to decode data: \(jsonString)")
                    }
#endif
                }
                
                throw EtherscanError.decodingFailed(error)
            }
            
        case 429:
            logger.warning("⚠️ Rate limit exceeded, retrying...")
            try await Task.sleep(for: .seconds(1))
            return try await performRequest(parameters: parameters, responseType: responseType)
            
        case 400...499:
            logger.error("❌ Client error: \(httpResponse.statusCode)")
            if let errorData = String(data: data, encoding: .utf8) {
                logger.error("📋 Error details: \(errorData)")
            }
            throw EtherscanError.clientError(httpResponse.statusCode)
        case 500...599:
            logger.error("❌ Server error: \(httpResponse.statusCode)")
            if let errorData = String(data: data, encoding: .utf8) {
                logger.error("📋 Error details: \(errorData)")
            }
            throw EtherscanError.serverError(httpResponse.statusCode)
        default:
            logger.error("❌ Unknown error: \(httpResponse.statusCode)")
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

// MARK: - API 키 설정 헬퍼

extension EtherscanService {
    /// API 키 설정 상태 확인
    static var isAPIKeyConfigured: Bool {
        return Config.apiKey != "YourEtherscanAPIKey" && !Config.apiKey.isEmpty
    }
    
    /// API 키 런타임 설정 (테스트용)
    static func setAPIKey(_ apiKey: String) {
        UserDefaults.standard.set(apiKey, forKey: "etherscan_api_key")
    }
    
    /// API 키 설정 가이드 메시지
    static var apiKeySetupGuide: String {
        return """
        🔑 Etherscan API 키 설정 필요:
        
        1. https://etherscan.io/register 에서 계정 생성
        2. https://etherscan.io/apis 에서 무료 API 키 발급
        3. Info.plist에 ETHERSCAN_API_KEY 추가:
           <key>ETHERSCAN_API_KEY</key>
           <string>YOUR_API_KEY_HERE</string>
        
        또는 런타임에서:
        EtherscanService.setAPIKey("YOUR_API_KEY_HERE")
        """
    }
}

// MARK: - 안전한 API 응답 검증

extension EtherscanTransactionListResponse {
    /// 응답 유효성 검사
    var isValidResponse: Bool {
        guard isSuccess else { return false }
        
        // "No transactions found" 메시지도 유효한 응답으로 처리
        if message.lowercased().contains("no transactions found") {
            return true
        }
        
        // 실제 결과가 있는 경우 검증
        return !result.isEmpty && result.allSatisfy { !$0.hash.isEmpty }
    }
    
    /// 안전한 거래 목록 반환
    var safeResult: [EtherscanTransaction] {
        return result.filter { !$0.hash.isEmpty && !$0.from.isEmpty }
    }
}

extension EtherscanTokenTransferResponse {
    /// 응답 유효성 검사
    var isValidResponse: Bool {
        guard isSuccess else { return false }
        
        if message.lowercased().contains("no transactions found") {
            return true
        }
        
        return !result.isEmpty && result.allSatisfy { !$0.hash.isEmpty }
    }
    
    /// 안전한 토큰 전송 목록 반환
    var safeResult: [EtherscanTokenTransfer] {
        return result.filter { !$0.hash.isEmpty && !$0.from.isEmpty && !$0.to.isEmpty }
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
    let blockHash: String?
    let transactionIndex: String
    let from: String
    let to: String?
    let value: String
    let gas: String
    let gasPrice: String
    let isError: String
    let txreceipt_status: String?
    let input: String?
    let contractAddress: String?
    let cumulativeGasUsed: String
    let gasUsed: String
    let confirmations: String
    let methodId: String?
    let functionName: String?
    
    // 커스텀 디코딩으로 안정성 향상
    private enum CodingKeys: String, CodingKey {
        case blockNumber
        case timeStamp
        case hash
        case nonce
        case blockHash
        case transactionIndex
        case from
        case to
        case value
        case gas
        case gasPrice
        case isError
        case txreceipt_status
        case input
        case contractAddress
        case cumulativeGasUsed
        case gasUsed
        case confirmations
        case methodId
        case functionName
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        blockNumber = try container.decode(String.self, forKey: .blockNumber)
        timeStamp = try container.decode(String.self, forKey: .timeStamp)
        hash = try container.decode(String.self, forKey: .hash)
        nonce = try container.decode(String.self, forKey: .nonce)
        blockHash = try container.decodeIfPresent(String.self, forKey: .blockHash)
        transactionIndex = try container.decode(String.self, forKey: .transactionIndex)
        from = try container.decode(String.self, forKey: .from)
        to = try container.decodeIfPresent(String.self, forKey: .to)
        value = try container.decode(String.self, forKey: .value)
        gas = try container.decode(String.self, forKey: .gas)
        gasPrice = try container.decode(String.self, forKey: .gasPrice)
        isError = try container.decode(String.self, forKey: .isError)
        txreceipt_status = try container.decodeIfPresent(String.self, forKey: .txreceipt_status)
        input = try container.decodeIfPresent(String.self, forKey: .input)
        contractAddress = try container.decodeIfPresent(String.self, forKey: .contractAddress)
        cumulativeGasUsed = try container.decode(String.self, forKey: .cumulativeGasUsed)
        gasUsed = try container.decode(String.self, forKey: .gasUsed)
        confirmations = try container.decode(String.self, forKey: .confirmations)
        methodId = try container.decodeIfPresent(String.self, forKey: .methodId)
        functionName = try container.decodeIfPresent(String.self, forKey: .functionName)
    }
}

/// Etherscan 토큰 전송 정보
struct EtherscanTokenTransfer: Codable {
    let blockNumber: String
    let timeStamp: String
    let hash: String
    let nonce: String
    let blockHash: String?
    let from: String
    let contractAddress: String
    let to: String
    let value: String
    let tokenName: String?
    let tokenSymbol: String?
    let tokenDecimal: String?
    let transactionIndex: String
    let gas: String
    let gasPrice: String
    let gasUsed: String
    let cumulativeGasUsed: String
    let input: String?
    let confirmations: String
    
    // 커스텀 디코딩으로 안정성 향상
    private enum CodingKeys: String, CodingKey {
        case blockNumber
        case timeStamp
        case hash
        case nonce
        case blockHash
        case from
        case contractAddress
        case to
        case value
        case tokenName
        case tokenSymbol
        case tokenDecimal
        case transactionIndex
        case gas
        case gasPrice
        case gasUsed
        case cumulativeGasUsed
        case input
        case confirmations
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        blockNumber = try container.decode(String.self, forKey: .blockNumber)
        timeStamp = try container.decode(String.self, forKey: .timeStamp)
        hash = try container.decode(String.self, forKey: .hash)
        nonce = try container.decode(String.self, forKey: .nonce)
        blockHash = try container.decodeIfPresent(String.self, forKey: .blockHash)
        from = try container.decode(String.self, forKey: .from)
        contractAddress = try container.decode(String.self, forKey: .contractAddress)
        to = try container.decode(String.self, forKey: .to)
        value = try container.decode(String.self, forKey: .value)
        tokenName = try container.decodeIfPresent(String.self, forKey: .tokenName)
        tokenSymbol = try container.decodeIfPresent(String.self, forKey: .tokenSymbol)
        tokenDecimal = try container.decodeIfPresent(String.self, forKey: .tokenDecimal)
        transactionIndex = try container.decode(String.self, forKey: .transactionIndex)
        gas = try container.decode(String.self, forKey: .gas)
        gasPrice = try container.decode(String.self, forKey: .gasPrice)
        gasUsed = try container.decode(String.self, forKey: .gasUsed)
        cumulativeGasUsed = try container.decode(String.self, forKey: .cumulativeGasUsed)
        input = try container.decodeIfPresent(String.self, forKey: .input)
        confirmations = try container.decode(String.self, forKey: .confirmations)
    }
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
        
        // 안전한 변환으로 nil 값 처리
        let safeToAddress = to?.isEmpty == true ? nil : to
        
        return Transaction(
            hash: hash,
            from: from,
            to: safeToAddress ?? "", // 빈 문자열로 대체
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
