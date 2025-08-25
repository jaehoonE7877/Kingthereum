import Testing
import Foundation
@testable import Core

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
    func testInfuraProjectIDConfiguration() async {
        // Given
        let configService = ConfigurationService()
        
        // When
        let projectID = await configService.infuraProjectID
        
        // Then
        #expect(!projectID.isEmpty, "Infura project ID should not be empty")
        #expect(projectID.contains("test") || projectID.contains("dev"), "Should contain test or dev identifier for development")
    }
    
    @Test("Infura project secret configuration")
    func testInfuraProjectSecretConfiguration() async {
        // Given
        let configService = ConfigurationService()
        
        // When
        let projectSecret = await configService.infuraProjectSecret
        
        // Then
        #expect(projectSecret != nil, "Infura project secret should be available")
        if let secret = projectSecret {
            #expect(!secret.isEmpty, "Infura project secret should not be empty")
        }
    }
    
    @Test("Etherscan API key configuration")
    func testEtherscanAPIKeyConfiguration() async {
        // Given
        let configService = ConfigurationService()
        
        // When
        let apiKey = await configService.etherscanAPIKey
        
        // Then
        #expect(!apiKey.isEmpty, "Etherscan API key should not be empty")
        #expect(apiKey.contains("test") || apiKey.contains("dev"), "Should contain test or dev identifier for development")
    }
    
    @Test("Etherscan base URL configuration")
    func testEtherscanBaseURLConfiguration() async {
        // Given
        let configService = ConfigurationService()
        
        // When
        let baseURL = await configService.etherscanBaseURL
        
        // Then
        #expect(!baseURL.isEmpty, "Etherscan base URL should not be empty")
        #expect(baseURL.hasPrefix("https://"), "Should use HTTPS protocol")
        #expect(baseURL.contains("etherscan"), "Should contain etherscan domain")
    }
    
    // MARK: - Network URL Configuration Tests
    
    @Test("Ethereum mainnet RPC URL configuration")
    func testEthereumMainnetRPCURL() async {
        // Given
        let configService = ConfigurationService()
        
        // When
        let rpcURL = await configService.getRPCURL(for: .mainnet)
        
        // Then
        #expect(!rpcURL.isEmpty, "RPC URL should not be empty")
        #expect(rpcURL.hasPrefix("https://"), "Should use HTTPS protocol")
        #expect(rpcURL.contains("mainnet"), "Should contain mainnet identifier")
        #expect(rpcURL.contains("infura"), "Should use Infura provider")
    }
    
    @Test("Sepolia testnet RPC URL configuration")
    func testSepoliaTestnetRPCURL() async {
        // Given
        let configService = ConfigurationService()
        
        // When
        let rpcURL = await configService.getRPCURL(for: .sepolia)
        
        // Then
        #expect(!rpcURL.isEmpty, "RPC URL should not be empty")
        #expect(rpcURL.hasPrefix("https://"), "Should use HTTPS protocol")
        #expect(rpcURL.contains("sepolia"), "Should contain sepolia identifier")
        #expect(rpcURL.contains("infura"), "Should use Infura provider")
    }
    
    
    // MARK: - URL Validation Tests
    
    @Test("RPC URL format validation")
    func testRPCURLFormatValidation() async {
        // Given
        let configService = ConfigurationService()
        let networks: [NetworkType] = [.mainnet, .sepolia]
        
        for network in networks {
            // When
            let rpcURL = await configService.getRPCURL(for: network)
            
            // Then
            let url = URL(string: rpcURL)
            #expect(url != nil, "RPC URL should be a valid URL for \(network)")
            #expect(url?.scheme == "https", "RPC URL should use HTTPS for \(network)")
            #expect(url?.host != nil, "RPC URL should have a valid host for \(network)")
        }
    }
    
    
    // MARK: - API Key Security Tests
    
    @Test("API keys should not be hardcoded")
    func testAPIKeysNotHardcoded() async {
        // Given
        let configService = ConfigurationService()
        
        // When
        let infuraProjectID = await configService.infuraProjectID
        let etherscanAPIKey = await configService.etherscanAPIKey
        
        // Then - API keys should not contain common hardcoded patterns
        #expect(!infuraProjectID.contains("YOUR_PROJECT_ID"), "Infura project ID should not be placeholder")
        #expect(!infuraProjectID.contains("REPLACE_ME"), "Infura project ID should not be placeholder")
        #expect(!etherscanAPIKey.contains("YOUR_API_KEY"), "Etherscan API key should not be placeholder")
        #expect(!etherscanAPIKey.contains("REPLACE_ME"), "Etherscan API key should not be placeholder")
    }
    
    @Test("API keys should have minimum length")
    func testAPIKeysMinimumLength() async {
        // Given
        let configService = ConfigurationService()
        
        // When
        let infuraProjectID = await configService.infuraProjectID
        let etherscanAPIKey = await configService.etherscanAPIKey
        
        // Then - API keys should have reasonable minimum lengths
        #expect(infuraProjectID.count >= 10, "Infura project ID should have minimum length")
        #expect(etherscanAPIKey.count >= 10, "Etherscan API key should have minimum length")
    }
    
    // MARK: - Performance Tests
    
    @Test("Configuration access performance")
    func testConfigurationAccessPerformance() async {
        // Given
        let configService = ConfigurationService()
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // When - Access multiple configuration values
        async let infuraProjectID = configService.infuraProjectID
        async let etherscanAPIKey = configService.etherscanAPIKey
        async let rpcURL = configService.getRPCURL(for: .mainnet)
        
        let _ = await (infuraProjectID, etherscanAPIKey, rpcURL)
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Then - Should be fast (under 100ms)
        #expect(timeElapsed < 0.1, "Configuration access should be fast")
    }
    
    // MARK: - Concurrent Access Tests
    
    @Test("Concurrent configuration access")
    func testConcurrentConfigurationAccess() async {
        // Given
        let configService = ConfigurationService()
        
        // When - Multiple concurrent requests
        await withTaskGroup(of: String.self) { group in
            for i in 0..<10 {
                group.addTask {
                    if i % 2 == 0 {
                        return await configService.getRPCURL(for: .mainnet)
                    } else {
                        return await configService.getRPCURL(for: .sepolia)
                    }
                }
            }
            
            var results: [String] = []
            for await result in group {
                results.append(result)
            }
            
            // Then - All requests should complete successfully
            #expect(results.count == 10, "All concurrent requests should complete")
            #expect(results.allSatisfy { !$0.isEmpty }, "All results should be non-empty")
        }
    }
    
    // MARK: - Environment Switching Tests
    
    @Test("Configuration consistency across network types")
    func testConfigurationConsistencyAcrossNetworks() async {
        // Given
        let configService = ConfigurationService()
        let networks: [NetworkType] = [.mainnet, .sepolia]
        
        // When & Then - Verify consistent patterns across networks
        for network in networks {
            let rpcURL = await configService.getRPCURL(for: network)
            
            // RPC URL should use the same project ID
            let projectID = await configService.infuraProjectID
            #expect(rpcURL.contains(projectID), "RPC URL should contain project ID for \(network)")
            
            // RPC URL should use Infura
            #expect(rpcURL.contains("infura.io"), "RPC URL should use Infura for \(network)")
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
    
    var infuraProjectID: String {
        get async { mockInfuraProjectID }
    }
    
    var infuraProjectSecret: String? {
        get async { mockInfuraProjectSecret }
    }
    
    var etherscanAPIKey: String {
        get async { mockEtherscanAPIKey }
    }
    
    var etherscanBaseURL: String {
        get async {
            switch mockEnvironment {
            case .development, .staging:
                return "https://api-sepolia.etherscan.io"
            case .production:
                return "https://api.etherscan.io"
            }
        }
    }
    
    var ethereumRPCURL: String {
        let network: NetworkType = mockEnvironment == .production ? .mainnet : .sepolia
        return "https://\(network.subdomain).infura.io/v3/\(mockInfuraProjectID)"
    }
    
    func getRPCURL(for network: NetworkType) async -> String {
        return "https://\(network.subdomain).infura.io/v3/\(mockInfuraProjectID)"
    }
}

/// ConfigurationService Mock을 이용한 테스트
@Suite("ConfigurationService Mock Integration Tests")
struct ConfigurationServiceMockIntegrationTests {
    
    @Test("MockConfigurationService basic functionality")  
    func testMockConfigurationServiceBasicFunctionality() async {
        // Given
        let mockConfigService = MockConfigurationService(environment: .development)
        
        // When & Then
        #expect(mockConfigService.currentEnvironment == .development, "Should use development environment")
        #expect(mockConfigService.isDebugMode == true, "Should be in debug mode")
        #expect(await mockConfigService.infuraProjectID == "test-infura-project-id-mock", "Should return mock project ID")
        #expect(await mockConfigService.etherscanAPIKey == "test-etherscan-api-key-mock", "Should return mock API key")
    }
    
    @Test("MockConfigurationService custom values")
    func testMockConfigurationServiceCustomValues() async {
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
        #expect(await mockConfigService.infuraProjectID == customProjectID, "Should return custom project ID")
        #expect(await mockConfigService.etherscanAPIKey == customAPIKey, "Should return custom API key")
    }
    
    @Test("MockConfigurationService RPC URL generation")
    func testMockConfigurationServiceRPCURLGeneration() async {
        // Given
        let mockConfigService = MockConfigurationService()
        
        // When
        let mainnetURL = await mockConfigService.getRPCURL(for: .mainnet)
        let sepoliaURL = await mockConfigService.getRPCURL(for: .sepolia)
        
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
        let devEtherscanURL = await devMockService.etherscanBaseURL
        let prodEtherscanURL = await prodMockService.etherscanBaseURL
        
        // Then
        #expect(devEtherscanURL.contains("sepolia"), "Development should use Sepolia Etherscan")
        #expect(prodEtherscanURL.contains("api.etherscan.io"), "Production should use main Etherscan")
        #expect(!prodEtherscanURL.contains("sepolia"), "Production should not use Sepolia")
    }
}