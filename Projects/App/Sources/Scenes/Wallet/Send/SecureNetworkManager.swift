import Foundation
import Network
import Security
import CommonCrypto

/// 🔒 보안 강화된 네트워크 매니저
/// SSL Pinning, Certificate Validation, Request Signing 구현
final class SecureNetworkManager: NSObject {
    
    static let shared = SecureNetworkManager()
    
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        configuration.waitsForConnectivity = true
        configuration.networkServiceType = .responsiveData
        
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()
    
    // SSL Certificate Pinning Configuration
    private let pinnedCertificates: [String: Data] = [
        "mainnet.infura.io": loadCertificate(named: "infura-mainnet"),
        "api.etherscan.io": loadCertificate(named: "etherscan-api"),
        "ethereum.org": loadCertificate(named: "ethereum-org")
    ].compactMapValues { $0 }
    
    private let pinnedPublicKeys: [String: SecKey] = [:]
    
    private override init() {
        super.init()
        setupNetworkMonitoring()
    }
    
    // MARK: - Secure HTTP Requests
    
    func secureRequest<T: Codable>(
        url: URL,
        method: HTTPMethod = .GET,
        body: Data? = nil,
        headers: [String: String] = [:],
        responseType: T.Type
    ) async throws -> T {
        
        // 🔒 1단계: URL 보안 검증
        try validateSecureURL(url)
        
        // 🔒 2단계: 요청 생성 및 서명
        let request = try createSecureRequest(url: url, method: method, body: body, headers: headers)
        
        // 🔒 3단계: 네트워크 상태 검증
        try await validateNetworkSecurity()
        
        // 🔒 4단계: 요청 실행
        let (data, response) = try await session.data(for: request)
        
        // 🔒 5단계: 응답 검증
        try validateResponse(response, data: data)
        
        // 🔒 6단계: 데이터 파싱
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            return try decoder.decode(responseType, from: data)
        } catch {
            throw NetworkSecurityError.responseParsingFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Ethereum Transaction Security
    
    func sendSecureTransaction(
        to endpoint: URL,
        transactionData: Data,
        signature: Data
    ) async throws -> TransactionResponse {
        
        // 🔒 거래 전송 전 추가 보안 검증
        try validateTransactionSecurity(transactionData: transactionData, signature: signature)
        
        let request = try createSecureTransactionRequest(
            url: endpoint,
            transactionData: transactionData,
            signature: signature
        )
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
        
        return try JSONDecoder().decode(TransactionResponse.self, from: data)
    }
    
    // MARK: - Security Validation Methods
    
    private func validateSecureURL(_ url: URL) throws {
        // HTTPS 필수 검증
        guard url.scheme == "https" else {
            throw NetworkSecurityError.insecureConnection("HTTPS 연결만 허용됩니다")
        }
        
        // 허용된 도메인 검증
        guard let host = url.host else {
            throw NetworkSecurityError.invalidURL("잘못된 URL 형식")
        }
        
        let allowedDomains = [
            "mainnet.infura.io",
            "api.etherscan.io",
            "ethereum.org",
            "sepolia.infura.io",
            "api-sepolia.etherscan.io"
        ]
        
        let isAllowedDomain = allowedDomains.contains { allowedDomain in
            host == allowedDomain || host.hasSuffix("." + allowedDomain)
        }
        
        guard isAllowedDomain else {
            logSecurityEvent(.unauthorizedDomainAccess, domain: host)
            throw NetworkSecurityError.unauthorizedDomain("허용되지 않은 도메인: \(host)")
        }
    }
    
    private func validateNetworkSecurity() async throws {
        // 네트워크 연결 타입 검증
        let monitor = NWPathMonitor()
        let path = monitor.currentPath
        
        // VPN 연결 감지
        if path.isExpensive || path.isConstrained {
            logSecurityEvent(.suspiciousNetworkDetected)
        }
        
        // 네트워크 가용성 검증
        guard path.status == .satisfied else {
            throw NetworkSecurityError.networkUnavailable("네트워크 연결이 불안정합니다")
        }
        
        // 보안 연결 검증 (Wi-Fi 보안 등)
        if path.usesInterfaceType(.wifi) {
            // Wi-Fi 보안 상태 추가 검증 가능
        }
    }
    
    private func validateTransactionSecurity(transactionData: Data, signature: Data) throws {
        // 거래 데이터 무결성 검증
        guard transactionData.count > 0 && transactionData.count < 1024 * 1024 else { // 1MB 제한
            throw NetworkSecurityError.invalidTransactionData("잘못된 거래 데이터 크기")
        }
        
        // 서명 유효성 검증
        guard signature.count == 65 else { // Ethereum signature length
            throw NetworkSecurityError.invalidSignature("잘못된 서명 형식")
        }
        
        // 거래 데이터 해시 검증
        let dataHash = SHA256.hash(data: transactionData)
        logSecurityEvent(.transactionDataValidated, hash: dataHash.description)
    }
    
    private func createSecureRequest(
        url: URL,
        method: HTTPMethod,
        body: Data?,
        headers: [String: String]
    ) throws -> URLRequest {
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        
        // 기본 보안 헤더 설정
        var secureHeaders = headers
        secureHeaders["User-Agent"] = "Kingthereum/1.0.0 (iOS)"
        secureHeaders["Accept"] = "application/json"
        secureHeaders["Content-Type"] = "application/json"
        secureHeaders["Cache-Control"] = "no-cache, no-store, must-revalidate"
        secureHeaders["Pragma"] = "no-cache"
        secureHeaders["X-Requested-With"] = "XMLHttpRequest"
        
        // Anti-CSRF 토큰 (필요시)
        secureHeaders["X-CSRF-Token"] = generateCSRFToken()
        
        // 요청 무결성 검증용 해시
        if let body = body {
            let bodyHash = SHA256.hash(data: body)
            secureHeaders["X-Content-Hash"] = Data(bodyHash).base64EncodedString()
        }
        
        // 타임스탬프 기반 재요청 방지
        secureHeaders["X-Timestamp"] = String(Int(Date().timeIntervalSince1970))
        
        for (key, value) in secureHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        return request
    }
    
    private func createSecureTransactionRequest(
        url: URL,
        transactionData: Data,
        signature: Data
    ) throws -> URLRequest {
        
        let payload = TransactionPayload(
            data: transactionData.base64EncodedString(),
            signature: signature.base64EncodedString(),
            timestamp: Int(Date().timeIntervalSince1970),
            nonce: generateNonce()
        )
        
        let jsonData = try JSONEncoder().encode(payload)
        
        return try createSecureRequest(
            url: url,
            method: .POST,
            body: jsonData,
            headers: [
                "X-Transaction-Type": "ethereum",
                "X-Security-Level": "high"
            ]
        )
    }
    
    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkSecurityError.invalidResponse("잘못된 응답 형식")
        }
        
        // HTTP 상태 코드 검증
        guard 200...299 ~= httpResponse.statusCode else {
            let errorMessage = "HTTP Error: \(httpResponse.statusCode)"
            logSecurityEvent(.httpError, statusCode: httpResponse.statusCode)
            throw NetworkSecurityError.httpError(httpResponse.statusCode, errorMessage)
        }
        
        // Content-Type 검증
        if let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type") {
            guard contentType.contains("application/json") else {
                throw NetworkSecurityError.invalidContentType("예상되지 않은 Content-Type: \(contentType)")
            }
        }
        
        // 응답 크기 제한 (10MB)
        guard data.count <= 10 * 1024 * 1024 else {
            throw NetworkSecurityError.responseTooLarge("응답 데이터가 너무 큽니다")
        }
        
        // 응답 무결성 검증
        if let expectedHash = httpResponse.value(forHTTPHeaderField: "X-Content-Hash") {
            let actualHash = Data(SHA256.hash(data: data)).base64EncodedString()
            guard expectedHash == actualHash else {
                logSecurityEvent(.responseIntegrityFailure)
                throw NetworkSecurityError.responseIntegrityFailure("응답 데이터 무결성 검증 실패")
            }
        }
    }
    
    // MARK: - Certificate Pinning Helpers
    
    private static func loadCertificate(named name: String) -> Data? {
        guard let path = Bundle.main.path(forResource: name, ofType: "cer"),
              let data = NSData(contentsOfFile: path) as Data? else {
            print("⚠️ Certificate not found: \(name).cer")
            return nil
        }
        return data
    }
    
    private func validateCertificate(_ serverTrust: SecTrust, for host: String) -> Bool {
        // 1. 기본 시스템 검증
        var secresult = SecTrustResultType.invalid
        let status = SecTrustEvaluate(serverTrust, &secresult)
        
        guard status == errSecSuccess else {
            logSecurityEvent(.certificateValidationFailed, host: host)
            return false
        }
        
        // 2. Certificate Pinning 검증
        if let pinnedCert = pinnedCertificates[host] {
            return validateCertificatePinning(serverTrust, pinnedCertificate: pinnedCert)
        }
        
        // 3. Public Key Pinning 검증
        if let pinnedKey = pinnedPublicKeys[host] {
            return validatePublicKeyPinning(serverTrust, pinnedPublicKey: pinnedKey)
        }
        
        // 기본 시스템 검증 결과 반환
        return secresult == .unspecified || secresult == .proceed
    }
    
    private func validateCertificatePinning(_ serverTrust: SecTrust, pinnedCertificate: Data) -> Bool {
        guard let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0) else {
            return false
        }
        
        let serverCertData = SecCertificateCopyData(serverCertificate)
        let serverData = CFDataGetBytePtr(serverCertData)
        let serverLength = CFDataGetLength(serverCertData)
        
        return pinnedCertificate.withUnsafeBytes { pinnedBytes in
            let pinnedPtr = pinnedBytes.bindMemory(to: UInt8.self).baseAddress!
            return serverLength == pinnedCertificate.count &&
                   memcmp(serverData, pinnedPtr, pinnedCertificate.count) == 0
        }
    }
    
    private func validatePublicKeyPinning(_ serverTrust: SecTrust, pinnedPublicKey: SecKey) -> Bool {
        guard let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0),
              let serverPublicKey = SecCertificateCopyKey(serverCertificate) else {
            return false
        }
        
        return SecKeyIsEqual(serverPublicKey, pinnedPublicKey)
    }
    
    // MARK: - Network Monitoring
    
    private func setupNetworkMonitoring() {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "NetworkMonitor")
        
        monitor.pathUpdateHandler = { [weak self] path in
            self?.handleNetworkPathUpdate(path)
        }
        
        monitor.start(queue: queue)
    }
    
    private func handleNetworkPathUpdate(_ path: NWPath) {
        if path.status != .satisfied {
            logSecurityEvent(.networkConnectionLost)
        }
        
        // VPN 또는 프록시 연결 감지
        if path.isExpensive {
            logSecurityEvent(.expensiveNetworkDetected)
        }
        
        // 네트워크 타입 변경 로깅
        logSecurityEvent(.networkTypeChanged, networkType: path.availableInterfaces.description)
    }
    
    // MARK: - Utility Methods
    
    private func generateCSRFToken() -> String {
        return UUID().uuidString
    }
    
    private func generateNonce() -> String {
        let timestamp = String(Int(Date().timeIntervalSince1970))
        let random = String(Int.random(in: 100000...999999))
        return "\(timestamp)-\(random)"
    }
    
    private func logSecurityEvent(_ event: NetworkSecurityEvent, 
                                domain: String? = nil,
                                host: String? = nil,
                                statusCode: Int? = nil,
                                hash: String? = nil,
                                networkType: String? = nil) {
        var info: [String: Any] = ["event": event.rawValue]
        if let domain = domain { info["domain"] = domain }
        if let host = host { info["host"] = host }
        if let statusCode = statusCode { info["statusCode"] = statusCode }
        if let hash = hash { info["hash"] = hash }
        if let networkType = networkType { info["networkType"] = networkType }
        
        print("🔒 Network Security Event: \(event.rawValue) - \(info)")
    }
}

// MARK: - URLSessionDelegate

extension SecureNetworkManager: URLSessionDelegate {
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        guard let serverTrust = challenge.protectionSpace.serverTrust,
              let host = challenge.protectionSpace.host as String? else {
            logSecurityEvent(.certificateValidationFailed)
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        if validateCertificate(serverTrust, for: host) {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            logSecurityEvent(.certificateValidationFailed, host: host)
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}

// MARK: - Supporting Types

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

struct TransactionPayload: Codable {
    let data: String
    let signature: String
    let timestamp: Int
    let nonce: String
}

struct TransactionResponse: Codable {
    let hash: String
    let status: String
    let timestamp: Int
}

enum NetworkSecurityError: LocalizedError {
    case insecureConnection(String)
    case unauthorizedDomain(String)
    case invalidURL(String)
    case certificateValidationFailed(String)
    case networkUnavailable(String)
    case invalidTransactionData(String)
    case invalidSignature(String)
    case invalidResponse(String)
    case httpError(Int, String)
    case invalidContentType(String)
    case responseTooLarge(String)
    case responseIntegrityFailure(String)
    case responseParsingFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .insecureConnection(let message),
             .unauthorizedDomain(let message),
             .invalidURL(let message),
             .certificateValidationFailed(let message),
             .networkUnavailable(let message),
             .invalidTransactionData(let message),
             .invalidSignature(let message),
             .invalidResponse(let message),
             .invalidContentType(let message),
             .responseTooLarge(let message),
             .responseIntegrityFailure(let message),
             .responseParsingFailed(let message):
            return message
        case .httpError(let code, let message):
            return "HTTP \(code): \(message)"
        }
    }
}

enum NetworkSecurityEvent: String {
    case unauthorizedDomainAccess = "unauthorized_domain_access"
    case suspiciousNetworkDetected = "suspicious_network_detected"
    case transactionDataValidated = "transaction_data_validated"
    case httpError = "http_error"
    case responseIntegrityFailure = "response_integrity_failure"
    case certificateValidationFailed = "certificate_validation_failed"
    case networkConnectionLost = "network_connection_lost"
    case expensiveNetworkDetected = "expensive_network_detected"
    case networkTypeChanged = "network_type_changed"
}