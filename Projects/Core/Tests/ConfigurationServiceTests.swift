import Testing
import Foundation
import Darwin
@testable import Core

private let configurationTestEnvironment: [String: String] = [
    "INFURA_PROJECT_ID": "test-infura-project-id",
    "INFURA_PROJECT_SECRET": "test-infura-secret",
    "ETHERSCAN_API_KEY": "test-etherscan-api-key"
]

@discardableResult
private func withConfigurationEnvironment<T>(
    _ execute: () async throws -> T
) async rethrows -> T {
    var previousValues: [String: String?] = [:]
    for (key, value) in configurationTestEnvironment {
        if let existing = getenv(key) {
            previousValues[key] = String(cString: existing)
        } else {
            previousValues[key] = nil
        }
        setenv(key, value, 1)
    }
    defer {
        for (key, oldValue) in previousValues {
            if let old = oldValue {
                setenv(key, old, 1)
            } else {
                unsetenv(key)
            }
        }
    }
    return try await execute()
}

@discardableResult
private func withConfigurationService<T>(
    _ execute: (ConfigurationService) async throws -> T
) async rethrows -> T {
    return try await withConfigurationEnvironment {
        let service = ConfigurationService()
        return try await execute(service)
    }
}

/// ConfigurationService 단위 테스트
/// 설정 서비스의 환경별 구성 및 API 키 관리 기능을 테스트
@Suite("ConfigurationService Tests")
struct ConfigurationServiceTests {
    
    // MARK: - Test Environment Configuration
    
    @Test("Configuration service initialization")
    func testConfigurationServiceInitialization() {
        // Given & When
        let configService = ConfigurationService()
        
        // Then
        #expect(configService.currentEnvironment == .development, "Should default to development environment")
        #expect(configService.isDebugMode == true, "Should be in debug mode for development")
    }
    
    @Test("Environment configuration properties")
    func testEnvironmentConfigurationProperties() {
        // Given
        let configService = ConfigurationService()
        
        // When & Then - Development environment
        #expect(configService.currentEnvironment == .development)
        #expect(configService.isDebugMode == true)
    }
    
    // MARK: - API Configuration Tests
    
    @Test("Infura project ID configuration")
    func testInfuraProjectIDConfiguration() async throws {
        // Given
        try await withConfigurationService { configService in
            let projectID = try configService.infuraProjectID()
            #expect(!projectID.isEmpty, "Infura project ID should not be empty")
            #expect(projectID.contains("test") || projectID.contains("dev"), "Should contain test or dev identifier for development")
        }
    }
    
    @Test("Infura project secret configuration")
    func testInfuraProjectSecretConfiguration() async {
        // Given
        await withConfigurationService { configService in
            let projectSecret = configService.infuraProjectSecret()
            #expect(projectSecret != nil, "Infura project secret should be available")
            if let secret = projectSecret {
                #expect(!secret.isEmpty, "Infura project secret should not be empty")
            }
        }
    }
    
    @Test("Etherscan API key configuration")
    func testEtherscanAPIKeyConfiguration() async throws {
        // Given
        try await withConfigurationService { configService in
            let apiKey = try configService.etherscanAPIKey()
            #expect(!apiKey.isEmpty, "Etherscan API key should not be empty")
            #expect(apiKey.contains("test") || apiKey.contains("dev"), "Should contain test or dev identifier for development")
        }
    }
    
    @Test("Etherscan base URL configuration")
    func testEtherscanBaseURLConfiguration() async {
        // Given
        await withConfigurationService { configService in
            let baseURL = configService.etherscanBaseURL()
            #expect(!baseURL.isEmpty, "Etherscan base URL should not be empty")
            #expect(baseURL.hasPrefix("https://"), "Should use HTTPS protocol")
            #expect(baseURL.contains("etherscan"), "Should contain etherscan domain")
        }
    }
    
    // MARK: - Network URL Configuration Tests
    
    @Test("Ethereum mainnet RPC URL configuration")
    func testEthereumMainnetRPCURL() async throws {
        // Given
        try await withConfigurationService { configService in
            let rpcURL = try configService.getRPCURL(for: .mainnet)
            #expect(!rpcURL.isEmpty, "RPC URL should not be empty")
            #expect(rpcURL.hasPrefix("https://"), "Should use HTTPS protocol")
            #expect(rpcURL.contains("mainnet"), "Should contain mainnet identifier")
            #expect(rpcURL.contains("infura"), "Should use Infura provider")
        }
    }
    
    @Test("Sepolia testnet RPC URL configuration")
    func testSepoliaTestnetRPCURL() async throws {
        // Given
        try await withConfigurationService { configService in
            let rpcURL = try configService.getRPCURL(for: .sepolia)
            #expect(!rpcURL.isEmpty, "RPC URL should not be empty")
            #expect(rpcURL.hasPrefix("https://"), "Should use HTTPS protocol")
            #expect(rpcURL.contains("sepolia"), "Should contain sepolia identifier")
            #expect(rpcURL.contains("infura"), "Should use Infura provider")
        }
    }
    
    
    // MARK: - URL Validation Tests
    
    @Test("RPC URL format validation")
    func testRPCURLFormatValidation() async throws {
        // Given
        try await withConfigurationService { configService in
            let networks: [NetworkType] = [.mainnet, .sepolia]
            for network in networks {
                let rpcURL = try configService.getRPCURL(for: network)
                let url = URL(string: rpcURL)
                #expect(url != nil, "RPC URL should be a valid URL for \(network)")
                #expect(url?.scheme == "https", "RPC URL should use HTTPS for \(network)")
                #expect(url?.host != nil, "RPC URL should have a valid host for \(network)")
            }
        }
    }
    
    
    // MARK: - API Key Security Tests
    
    @Test("API keys should not be hardcoded")
    func testAPIKeysNotHardcoded() async throws {
        // Given
        try await withConfigurationService { configService in
            let infuraProjectID = try configService.infuraProjectID()
            let etherscanAPIKey = try configService.etherscanAPIKey()
            #expect(!infuraProjectID.contains("YOUR_PROJECT_ID"), "Infura project ID should not be placeholder")
            #expect(!infuraProjectID.contains("REPLACE_ME"), "Infura project ID should not be placeholder")
            #expect(!etherscanAPIKey.contains("YOUR_API_KEY"), "Etherscan API key should not be placeholder")
            #expect(!etherscanAPIKey.contains("REPLACE_ME"), "Etherscan API key should not be placeholder")
        }
    }
    
    @Test("API keys should have minimum length")
    func testAPIKeysMinimumLength() async throws {
        // Given
        try await withConfigurationService { configService in
            let infuraProjectID = try configService.infuraProjectID()
            let etherscanAPIKey = try configService.etherscanAPIKey()
            #expect(infuraProjectID.count >= 10, "Infura project ID should have minimum length")
            #expect(etherscanAPIKey.count >= 10, "Etherscan API key should have minimum length")
        }
    }
    
    // MARK: - Performance Tests
    
    @Test("Configuration access performance")
    func testConfigurationAccessPerformance() async throws {
        // Given
        try await withConfigurationService { configService in
            let startTime = CFAbsoluteTimeGetCurrent()
            _ = try configService.infuraProjectID()
            _ = try configService.etherscanAPIKey()
            _ = try configService.getRPCURL(for: .mainnet)
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime

            #expect(timeElapsed < 0.1, "Configuration access should be fast")
        }
    }
    
    // MARK: - Concurrent Access Tests
    
    @Test("Concurrent configuration access")
    func testConcurrentConfigurationAccess() async throws {
        // Given
        // When - Multiple concurrent requests
        try await withConfigurationService { configService in
            try await withThrowingTaskGroup(of: String.self) { group in
                for i in 0..<10 {
                    group.addTask {
                        if i % 2 == 0 {
                            return try configService.getRPCURL(for: .mainnet)
                        } else {
                            return try configService.getRPCURL(for: .sepolia)
                        }
                    }
                }
                
                var results: [String] = []
                for try await result in group {
                    results.append(result)
                }
                #expect(results.count == 10, "All concurrent requests should complete")
                #expect(results.allSatisfy { !$0.isEmpty }, "All results should be non-empty")
            }
        }
    }
    
    // MARK: - Environment Switching Tests
    
    @Test("Configuration consistency across network types")
    func testConfigurationConsistencyAcrossNetworks() async throws {
        // Given
        try await withConfigurationService { configService in
            let networks: [NetworkType] = [.mainnet, .sepolia]
            let projectID = try configService.infuraProjectID()
            for network in networks {
                let rpcURL = try configService.getRPCURL(for: network)
                #expect(rpcURL.contains(projectID), "RPC URL should contain project ID for \(network)")
                #expect(rpcURL.contains("infura.io"), "RPC URL should use Infura for \(network)")
            }
        }
    }
}

// MARK: - Mock Configuration Service

/// Mock implementation of ConfigurationServiceProtocol for testing
final class MockConfigurationService: ConfigurationServiceProtocol {
    private let mockEnvironment: AppEnvironment
    private let mockInfuraProjectID: String
    private let mockInfuraProjectSecret: String?
    private let mockEtherscanAPIKey: String
    
    init(
        environment: AppEnvironment = .development,
        infuraProjectID: String = "test-infura-project-id-mock",
        infuraProjectSecret: String? = "test-infura-secret-mock",
        etherscanAPIKey: String = "test-etherscan-api-key-mock"
    ) {
        self.mockEnvironment = environment
        self.mockInfuraProjectID = infuraProjectID
        self.mockInfuraProjectSecret = infuraProjectSecret
        self.mockEtherscanAPIKey = etherscanAPIKey
    }
    
    var currentEnvironment: AppEnvironment {
        mockEnvironment
    }
    
    var isDebugMode: Bool {
        mockEnvironment == .development
    }
    
    func infuraProjectID() throws -> String { mockInfuraProjectID }
    func infuraProjectSecret() -> String? { mockInfuraProjectSecret }
    func etherscanAPIKey() throws -> String { mockEtherscanAPIKey }
    func etherscanBaseURL() -> String {
        switch mockEnvironment {
        case .development, .staging:
            return "https://api-sepolia.etherscan.io"
        case .production:
            return "https://api.etherscan.io"
        }
    }
    
    func ethereumRPCURL() throws -> String {
        let network: NetworkType = mockEnvironment == .production ? .mainnet : .sepolia
        return try getRPCURL(for: network)
    }
    
    func getRPCURL(for network: NetworkType) throws -> String {
        return "https://\(network.subdomain).infura.io/v3/\(mockInfuraProjectID)"
    }
}

/// ConfigurationService Mock을 이용한 테스트
@Suite("ConfigurationService Mock Integration Tests")
struct ConfigurationServiceMockIntegrationTests {
    
    @Test("MockConfigurationService basic functionality")  
    func testMockConfigurationServiceBasicFunctionality() async throws {
        // Given
        let mockConfigService = MockConfigurationService(environment: .development)
        
        // When & Then
        #expect(mockConfigService.currentEnvironment == .development, "Should use development environment")
        #expect(mockConfigService.isDebugMode == true, "Should be in debug mode")
        #expect(try mockConfigService.infuraProjectID() == "test-infura-project-id-mock", "Should return mock project ID")
        #expect(try mockConfigService.etherscanAPIKey() == "test-etherscan-api-key-mock", "Should return mock API key")
    }
    
    @Test("MockConfigurationService custom values")
    func testMockConfigurationServiceCustomValues() async throws {
        // Given
        let customProjectID = "custom-test-project-id"
        let customAPIKey = "custom-test-api-key"
        let mockConfigService = MockConfigurationService(
            environment: .production,
            infuraProjectID: customProjectID,
            etherscanAPIKey: customAPIKey
        )
        
        // When & Then
        #expect(mockConfigService.currentEnvironment == .production, "Should use production environment")
        #expect(mockConfigService.isDebugMode == false, "Should not be in debug mode for production")
        #expect(try mockConfigService.infuraProjectID() == customProjectID, "Should return custom project ID")
        #expect(try mockConfigService.etherscanAPIKey() == customAPIKey, "Should return custom API key")
    }
    
    @Test("MockConfigurationService RPC URL generation")
    func testMockConfigurationServiceRPCURLGeneration() async throws {
        // Given
        let mockConfigService = MockConfigurationService()
        
        // When
        let mainnetURL = try mockConfigService.getRPCURL(for: .mainnet)
        let sepoliaURL = try mockConfigService.getRPCURL(for: .sepolia)
        
        // Then
        #expect(mainnetURL.contains("mainnet.infura.io"), "Should contain mainnet endpoint")
        #expect(sepoliaURL.contains("sepolia.infura.io"), "Should contain sepolia endpoint")
        #expect(mainnetURL.contains("test-infura-project-id-mock"), "Should contain mock project ID")
        #expect(sepoliaURL.contains("test-infura-project-id-mock"), "Should contain mock project ID")
    }
    
    @Test("MockConfigurationService environment-based URLs")
    func testMockConfigurationServiceEnvironmentBasedURLs() async {
        // Given - Development environment
        let devMockService = MockConfigurationService(environment: .development)
        let prodMockService = MockConfigurationService(environment: .production)
        
        // When
        let devEtherscanURL = devMockService.etherscanBaseURL()
        let prodEtherscanURL = prodMockService.etherscanBaseURL()
        
        // Then
        #expect(devEtherscanURL.contains("sepolia"), "Development should use Sepolia Etherscan")
        #expect(prodEtherscanURL.contains("api.etherscan.io"), "Production should use main Etherscan")
        #expect(!prodEtherscanURL.contains("sepolia"), "Production should not use Sepolia")
    }
}
