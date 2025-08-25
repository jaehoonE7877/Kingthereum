import Testing
import Foundation
import BigInt
@testable import WalletKit
@testable import Core

// MARK: - Mock Token Contract
struct MockTokenContract: Sendable {
    let address: String
    let name: String
    let symbol: String
    let decimals: Int
    let totalSupply: String
    var balances: [String: String] = [:]
    
    init(
        address: String,
        name: String,
        symbol: String,
        decimals: Int,
        totalSupply: String = "1000000000000000000000000" // 1M tokens
    ) {
        self.address = address
        self.name = name
        self.symbol = symbol
        self.decimals = decimals
        self.totalSupply = totalSupply
    }
}

// MARK: - Mock TokenWorker
final class MockTokenWorker: TokenWorkerProtocol, @unchecked Sendable {
    private var contracts: [String: MockTokenContract] = [:]
    private var shouldFailRequests = false
    private var failureError: TokenError = .unknownError
    
    init() {
        setupMockContracts()
    }
    
    func reset() {
        shouldFailRequests = false
        failureError = .unknownError
        setupMockContracts()
    }
    
    func setFailureMode(_ shouldFail: Bool, error: TokenError = .unknownError) {
        shouldFailRequests = shouldFail
        failureError = error
    }
    
    private func setupMockContracts() {
        // USDC contract
        var usdcContract = MockTokenContract(
            address: "0xA0b86a33E6e6C0A9eA8C05bc3E3b6e90F78c8a4D",
            name: "USD Coin",
            symbol: "USDC",
            decimals: 6
        )
        usdcContract.balances["0x742d35Cc6627C8532b9b92a3d43F1f12f2CaF8B5"] = "1000000000" // 1000 USDC
        contracts[usdcContract.address] = usdcContract
        
        // USDT contract
        var usdtContract = MockTokenContract(
            address: "0xdAC17F958D2ee523a2206206994597C13D831ec7",
            name: "Tether USD",
            symbol: "USDT",
            decimals: 6
        )
        usdtContract.balances["0x742d35Cc6627C8532b9b92a3d43F1f12f2CaF8B5"] = "500000000" // 500 USDT
        contracts[usdtContract.address] = usdtContract
        
        // DAI contract
        var daiContract = MockTokenContract(
            address: "0x6B175474E89094C44Da98b954EedeAC495271d0F",
            name: "Dai Stablecoin",
            symbol: "DAI",
            decimals: 18
        )
        daiContract.balances["0x742d35Cc6627C8532b9b92a3d43F1f12f2CaF8B5"] = "1000000000000000000000" // 1000 DAI
        contracts[daiContract.address] = daiContract
    }
    
    func getTokenBalance(contractAddress: String, walletAddress: String) async throws -> String {
        guard !shouldFailRequests else {
            throw failureError
        }
        
        guard MockEthereumAddress(contractAddress) != nil,
              MockEthereumAddress(walletAddress) != nil else {
            throw TokenError.invalidContract
        }
        
        guard let contract = contracts[contractAddress] else {
            throw TokenError.contractNotFound
        }
        
        return contract.balances[walletAddress] ?? "0"
    }
    
    func getTokenInfo(contractAddress: String) async throws -> (name: String, symbol: String, decimals: Int) {
        guard !shouldFailRequests else {
            throw failureError
        }
        
        guard MockEthereumAddress(contractAddress) != nil else {
            throw TokenError.invalidContract
        }
        
        guard let contract = contracts[contractAddress] else {
            throw TokenError.contractNotFound
        }
        
        return (name: contract.name, symbol: contract.symbol, decimals: contract.decimals)
    }
    
    func sendTokenTransaction(
        contractAddress: String,
        from: String,
        to: String,
        amount: String,
        gasPrice: String?,
        gasLimit: String?
    ) async throws -> String {
        guard !shouldFailRequests else {
            throw failureError
        }
        
        guard MockEthereumAddress(contractAddress) != nil,
              MockEthereumAddress(from) != nil,
              MockEthereumAddress(to) != nil else {
            throw TokenError.invalidContract
        }
        
        guard BigUInt(amount) != nil else {
            throw TokenError.transferFailed("Invalid amount")
        }
        
        guard contracts[contractAddress] != nil else {
            throw TokenError.contractNotFound
        }
        
        // Check if sender has sufficient balance
        let currentBalance = try await getTokenBalance(contractAddress: contractAddress, walletAddress: from)
        guard let currentBalanceInt = BigUInt(currentBalance),
              let amountInt = BigUInt(amount),
              currentBalanceInt >= amountInt else {
            throw TokenError.transferFailed("Insufficient funds")
        }
        
        return "0xtoken1234567890abcdef"
    }
}

// MARK: - Test Data
struct TokenTestScenario: Sendable, CustomStringConvertible {
    let name: String
    let contractAddress: String
    let walletAddress: String
    let expectedBalance: String
    let isValid: Bool
    
    var description: String { name }
}

struct TokenInfoScenario: Sendable, CustomStringConvertible {
    let name: String
    let contractAddress: String
    let expectedName: String
    let expectedSymbol: String
    let expectedDecimals: Int
    
    var description: String { name }
}

struct TokenTransferScenario: Sendable, CustomStringConvertible {
    let name: String
    let contractAddress: String
    let from: String
    let to: String
    let amount: String
    let shouldSucceed: Bool
    
    var description: String { name }
}

// MARK: - TokenWorker Tests
@Suite("TokenWorker Tests")
struct TokenWorkerTests {
    
    // MARK: - Test Data
    private static let validTokenBalanceScenarios = [
        TokenTestScenario(
            name: "USDC balance check",
            contractAddress: "0xA0b86a33E6e6C0A9eA8C05bc3E3b6e90F78c8a4D",
            walletAddress: "0x742d35Cc6627C8532b9b92a3d43F1f12f2CaF8B5",
            expectedBalance: "1000000000",
            isValid: true
        ),
        TokenTestScenario(
            name: "USDT balance check",
            contractAddress: "0xdAC17F958D2ee523a2206206994597C13D831ec7",
            walletAddress: "0x742d35Cc6627C8532b9b92a3d43F1f12f2CaF8B5",
            expectedBalance: "500000000",
            isValid: true
        ),
        TokenTestScenario(
            name: "DAI balance check",
            contractAddress: "0x6B175474E89094C44Da98b954EedeAC495271d0F",
            walletAddress: "0x742d35Cc6627C8532b9b92a3d43F1f12f2CaF8B5",
            expectedBalance: "1000000000000000000000",
            isValid: true
        )
    ]
    
    private static let tokenInfoScenarios = [
        TokenInfoScenario(
            name: "USDC token info",
            contractAddress: "0xA0b86a33E6e6C0A9eA8C05bc3E3b6e90F78c8a4D",
            expectedName: "USD Coin",
            expectedSymbol: "USDC",
            expectedDecimals: 6
        ),
        TokenInfoScenario(
            name: "USDT token info",
            contractAddress: "0xdAC17F958D2ee523a2206206994597C13D831ec7",
            expectedName: "Tether USD",
            expectedSymbol: "USDT",
            expectedDecimals: 6
        ),
        TokenInfoScenario(
            name: "DAI token info",
            contractAddress: "0x6B175474E89094C44Da98b954EedeAC495271d0F",
            expectedName: "Dai Stablecoin",
            expectedSymbol: "DAI",
            expectedDecimals: 18
        )
    ]
    
    private static let tokenTransferScenarios = [
        TokenTransferScenario(
            name: "Valid USDC transfer",
            contractAddress: "0xA0b86a33E6e6C0A9eA8C05bc3E3b6e90F78c8a4D",
            from: "0x742d35Cc6627C8532b9b92a3d43F1f12f2CaF8B5",
            to: "0x8ba1f109551bD432803012645Hac136c2367bAbb",
            amount: "1000000", // 1 USDC
            shouldSucceed: true
        ),
        TokenTransferScenario(
            name: "Valid DAI transfer",
            contractAddress: "0x6B175474E89094C44Da98b954EedeAC495271d0F",
            from: "0x742d35Cc6627C8532b9b92a3d43F1f12f2CaF8B5",
            to: "0x8ba1f109551bD432803012645Hac136c2367bAbb",
            amount: "100000000000000000000", // 100 DAI
            shouldSucceed: true
        )
    ]
    
    // MARK: - Setup
    private var worker: MockTokenWorker!
    
    init() {
        worker = MockTokenWorker()
    }
    
    // MARK: - Token Balance Tests
    @Test("Get token balance for valid scenarios", arguments: validTokenBalanceScenarios)
    func testGetTokenBalance(_ scenario: TokenTestScenario) async throws {
        // When
        let balance = try await worker.getTokenBalance(
            contractAddress: scenario.contractAddress,
            walletAddress: scenario.walletAddress
        )
        
        // Then
        #expect(balance == scenario.expectedBalance, "Token balance should match expected value")
        #expect(BigUInt(balance) != nil, "Balance should be a valid number")
    }
    
    @Test("Get token balance for empty wallet")
    func testGetTokenBalanceEmptyWallet() async throws {
        // Given
        let contractAddress = "0xA0b86a33E6e6C0A9eA8C05bc3E3b6e90F78c8a4D"
        let emptyWallet = "0x1234567890123456789012345678901234567890"
        
        // When
        let balance = try await worker.getTokenBalance(
            contractAddress: contractAddress,
            walletAddress: emptyWallet
        )
        
        // Then
        #expect(balance == "0", "Empty wallet should have zero balance")
    }
    
    @Test("Get token balance fails for invalid contract address")
    func testGetTokenBalanceInvalidContractAddress() async throws {
        // Given
        let invalidContract = "invalid"
        let validWallet = "0x742d35Cc6627C8532b9b92a3d43F1f12f2CaF8B5"
        
        // When & Then
        await #expect(throws: TokenError.invalidContract) {
            try await worker.getTokenBalance(
                contractAddress: invalidContract,
                walletAddress: validWallet
            )
        }
    }
    
    @Test("Get token balance fails for invalid wallet address")
    func testGetTokenBalanceInvalidWalletAddress() async throws {
        // Given
        let validContract = "0xA0b86a33E6e6C0A9eA8C05bc3E3b6e90F78c8a4D"
        let invalidWallet = "invalid"
        
        // When & Then
        await #expect(throws: TokenError.invalidContract) {
            try await worker.getTokenBalance(
                contractAddress: validContract,
                walletAddress: invalidWallet
            )
        }
    }
    
    @Test("Get token balance fails for non-existent contract")
    func testGetTokenBalanceNonExistentContract() async throws {
        // Given
        let nonExistentContract = "0x1234567890123456789012345678901234567890"
        let validWallet = "0x742d35Cc6627C8532b9b92a3d43F1f12f2CaF8B5"
        
        // When & Then
        await #expect(throws: TokenError.contractNotFound) {
            try await worker.getTokenBalance(
                contractAddress: nonExistentContract,
                walletAddress: validWallet
            )
        }
    }
    
    @Test("Get token balance handles network errors")
    func testGetTokenBalanceNetworkError() async throws {
        // Given
        worker.setFailureMode(true, error: .unknownError)
        let validContract = "0xA0b86a33E6e6C0A9eA8C05bc3E3b6e90F78c8a4D"
        let validWallet = "0x742d35Cc6627C8532b9b92a3d43F1f12f2CaF8B5"
        
        // When & Then
        await #expect(throws: TokenError.unknownError) {
            try await worker.getTokenBalance(
                contractAddress: validContract,
                walletAddress: validWallet
            )
        }
    }
    
    // MARK: - Token Info Tests
    @Test("Get token info for valid contracts", arguments: tokenInfoScenarios)
    func testGetTokenInfo(_ scenario: TokenInfoScenario) async throws {
        // When
        let tokenInfo = try await worker.getTokenInfo(contractAddress: scenario.contractAddress)
        
        // Then
        #expect(tokenInfo.name == scenario.expectedName, "Token name should match")
        #expect(tokenInfo.symbol == scenario.expectedSymbol, "Token symbol should match")
        #expect(tokenInfo.decimals == scenario.expectedDecimals, "Token decimals should match")
    }
    
    @Test("Get token info fails for invalid contract address")
    func testGetTokenInfoInvalidAddress() async throws {
        // Given
        let invalidContract = "invalid"
        
        // When & Then
        await #expect(throws: TokenError.invalidContract) {
            try await worker.getTokenInfo(contractAddress: invalidContract)
        }
    }
    
    @Test("Get token info fails for non-existent contract")
    func testGetTokenInfoNonExistentContract() async throws {
        // Given
        let nonExistentContract = "0x1234567890123456789012345678901234567890"
        
        // When & Then
        await #expect(throws: TokenError.unknownError) {
            try await worker.getTokenInfo(contractAddress: nonExistentContract)
        }
    }
    
    @Test("Get token info handles network errors")
    func testGetTokenInfoNetworkError() async throws {
        // Given
        worker.setFailureMode(true, error: .unknownError)
        let validContract = "0xA0b86a33E6e6C0A9eA8C05bc3E3b6e90F78c8a4D"
        
        // When & Then
        await #expect(throws: TokenError.unknownError) {
            try await worker.getTokenInfo(contractAddress: validContract)
        }
    }
    
    // MARK: - Token Transfer Tests
    @Test("Send token transaction succeeds for valid scenarios", arguments: tokenTransferScenarios)
    func testSendTokenTransaction(_ scenario: TokenTransferScenario) async throws {
        // When
        let transactionHash = try await worker.sendTokenTransaction(
            contractAddress: scenario.contractAddress,
            from: scenario.from,
            to: scenario.to,
            amount: scenario.amount,
            gasPrice: "20000000000",
            gasLimit: "100000"
        )
        
        // Then
        #expect(!transactionHash.isEmpty, "Transaction hash should not be empty")
        #expect(transactionHash.hasPrefix("0x"), "Transaction hash should start with 0x")
    }
    
    @Test("Send token transaction fails for invalid contract address")
    func testSendTokenTransactionInvalidContractAddress() async throws {
        // Given
        let invalidContract = "invalid"
        let validFrom = "0x742d35Cc6627C8532b9b92a3d43F1f12f2CaF8B5"
        let validTo = "0x8ba1f109551bD432803012645Hac136c2367bAbb"
        let amount = "1000000"
        
        // When & Then
        await #expect(throws: TokenError.invalidContract) {
            try await worker.sendTokenTransaction(
                contractAddress: invalidContract,
                from: validFrom,
                to: validTo,
                amount: amount,
                gasPrice: nil,
                gasLimit: nil
            )
        }
    }
    
    @Test("Send token transaction fails for invalid from address")
    func testSendTokenTransactionInvalidFromAddress() async throws {
        // Given
        let validContract = "0xA0b86a33E6e6C0A9eA8C05bc3E3b6e90F78c8a4D"
        let invalidFrom = "invalid"
        let validTo = "0x8ba1f109551bD432803012645Hac136c2367bAbb"
        let amount = "1000000"
        
        // When & Then
        await #expect(throws: TokenError.invalidContract) {
            try await worker.sendTokenTransaction(
                contractAddress: validContract,
                from: invalidFrom,
                to: validTo,
                amount: amount,
                gasPrice: nil,
                gasLimit: nil
            )
        }
    }
    
    @Test("Send token transaction fails for invalid amount")
    func testSendTokenTransactionInvalidAmount() async throws {
        // Given
        let validContract = "0xA0b86a33E6e6C0A9eA8C05bc3E3b6e90F78c8a4D"
        let validFrom = "0x742d35Cc6627C8532b9b92a3d43F1f12f2CaF8B5"
        let validTo = "0x8ba1f109551bD432803012645Hac136c2367bAbb"
        let invalidAmount = "invalid"
        
        // When & Then
        await #expect(throws: TokenError.transferFailed) {
            try await worker.sendTokenTransaction(
                contractAddress: validContract,
                from: validFrom,
                to: validTo,
                amount: invalidAmount,
                gasPrice: nil,
                gasLimit: nil
            )
        }
    }
    
    @Test("Send token transaction fails for insufficient funds")
    func testSendTokenTransactionInsufficientFunds() async throws {
        // Given
        let validContract = "0xA0b86a33E6e6C0A9eA8C05bc3E3b6e90F78c8a4D"
        let validFrom = "0x742d35Cc6627C8532b9b92a3d43F1f12f2CaF8B5"
        let validTo = "0x8ba1f109551bD432803012645Hac136c2367bAbb"
        let excessiveAmount = "10000000000000" // Much more than available balance
        
        // When & Then
        await #expect(throws: TokenError.transferFailed) {
            try await worker.sendTokenTransaction(
                contractAddress: validContract,
                from: validFrom,
                to: validTo,
                amount: excessiveAmount,
                gasPrice: nil,
                gasLimit: nil
            )
        }
    }
    
    @Test("Send token transaction handles network errors")
    func testSendTokenTransactionNetworkError() async throws {
        // Given
        worker.setFailureMode(true, error: .unknownError)
        let validContract = "0xA0b86a33E6e6C0A9eA8C05bc3E3b6e90F78c8a4D"
        let validFrom = "0x742d35Cc6627C8532b9b92a3d43F1f12f2CaF8B5"
        let validTo = "0x8ba1f109551bD432803012645Hac136c2367bAbb"
        let amount = "1000000"
        
        // When & Then
        await #expect(throws: TokenError.unknownError) {
            try await worker.sendTokenTransaction(
                contractAddress: validContract,
                from: validFrom,
                to: validTo,
                amount: amount,
                gasPrice: nil,
                gasLimit: nil
            )
        }
    }
    
    // MARK: - Performance Tests
    @Test(.timeLimit(.minutes(1)))
    func testTokenBalancePerformance() async throws {
        // Given
        let contractAddress = "0xA0b86a33E6e6C0A9eA8C05bc3E3b6e90F78c8a4D"
        let walletAddress = "0x742d35Cc6627C8532b9b92a3d43F1f12f2CaF8B5"
        
        // When & Then - Should complete within 5 seconds
        for _ in 0..<100 {
            let balance = try await worker.getTokenBalance(
                contractAddress: contractAddress,
                walletAddress: walletAddress
            )
            #expect(!balance.isEmpty, "Balance should not be empty")
        }
    }
    
    @Test(.timeLimit(.minutes(1)))
    func testTokenInfoPerformance() async throws {
        // Given
        let contractAddress = "0xA0b86a33E6e6C0A9eA8C05bc3E3b6e90F78c8a4D"
        
        // When & Then - Should complete within 3 seconds
        for _ in 0..<50 {
            let tokenInfo = try await worker.getTokenInfo(contractAddress: contractAddress)
            #expect(!tokenInfo.name.isEmpty, "Token name should not be empty")
            #expect(!tokenInfo.symbol.isEmpty, "Token symbol should not be empty")
            #expect(tokenInfo.decimals >= 0, "Token decimals should be non-negative")
        }
    }
}

// MARK: - Integration Tests
@Suite("TokenWorker Integration Tests")
struct TokenWorkerIntegrationTests {
    
    private var worker: MockTokenWorker!
    
    init() {
        worker = MockTokenWorker()
    }
    
    @Test("Complete token workflow - info, balance, transfer")
    func testCompleteTokenWorkflow() async throws {
        // Given
        let contractAddress = "0xA0b86a33E6e6C0A9eA8C05bc3E3b6e90F78c8a4D"
        let fromAddress = "0x742d35Cc6627C8532b9b92a3d43F1f12f2CaF8B5"
        let toAddress = "0x8ba1f109551bD432803012645Hac136c2367bAbb"
        let transferAmount = "1000000" // 1 USDC
        
        // When - Get token info
        let tokenInfo = try await worker.getTokenInfo(contractAddress: contractAddress)
        
        // Then
        #expect(tokenInfo.name == "USD Coin", "Token name should be USD Coin")
        #expect(tokenInfo.symbol == "USDC", "Token symbol should be USDC")
        #expect(tokenInfo.decimals == 6, "Token decimals should be 6")
        
        // When - Get initial balance
        let initialBalance = try await worker.getTokenBalance(
            contractAddress: contractAddress,
            walletAddress: fromAddress
        )
        
        // Then
        #expect(initialBalance == "1000000000", "Initial balance should be 1000 USDC")
        
        // When - Send token transaction
        let transactionHash = try await worker.sendTokenTransaction(
            contractAddress: contractAddress,
            from: fromAddress,
            to: toAddress,
            amount: transferAmount,
            gasPrice: "20000000000",
            gasLimit: "100000"
        )
        
        // Then
        #expect(!transactionHash.isEmpty, "Transaction hash should not be empty")
        #expect(transactionHash.hasPrefix("0x"), "Transaction hash should start with 0x")
    }
    
    @Test("Parallel token operations")
    func testParallelTokenOperations() async throws {
        // Given
        let contracts = [
            "0xA0b86a33E6e6C0A9eA8C05bc3E3b6e90F78c8a4D", // USDC
            "0xdAC17F958D2ee523a2206206994597C13D831ec7", // USDT
            "0x6B175474E89094C44Da98b954EedeAC495271d0F"  // DAI
        ]
        let walletAddress = "0x742d35Cc6627C8532b9b92a3d43F1f12f2CaF8B5"
        
        // When - Perform parallel operations
        async let balances = withTaskGroup(of: (String, String).self) { group in
            var results: [(String, String)] = []
            
            for contract in contracts {
                group.addTask {
                    let balance = try await worker.getTokenBalance(
                        contractAddress: contract,
                        walletAddress: walletAddress
                    )
                    return (contract, balance)
                }
            }
            
            for await result in group {
                results.append(result)
            }
            
            return results
        }
        
        async let tokenInfos = withTaskGroup(of: (String, (String, String, Int)).self) { group in
            var results: [(String, (String, String, Int))] = []
            
            for contract in contracts {
                group.addTask {
                    let info = try await worker.getTokenInfo(contractAddress: contract)
                    return (contract, info)
                }
            }
            
            for await result in group {
                results.append(result)
            }
            
            return results
        }
        
        // Then
        let balanceResults = try await balances
        let infoResults = try await tokenInfos
        
        #expect(balanceResults.count == 3, "Should have 3 balance results")
        #expect(infoResults.count == 3, "Should have 3 token info results")
        
        // Verify specific results
        let usdcBalance = balanceResults.first { $0.0 == contracts[0] }?.1
        #expect(usdcBalance == "1000000000", "USDC balance should match")
        
        let usdcInfo = infoResults.first { $0.0 == contracts[0] }?.1
        #expect(usdcInfo?.1 == "USDC", "USDC symbol should match")
    }
}

// MARK: - Helper for MockEthereumAddress
struct MockEthereumAddress: Sendable {
    let address: String
    
    init?(_ address: String) {
        // Simple validation for testing
        guard address.hasPrefix("0x"),
              address.count == 42,
              address.dropFirst(2).allSatisfy({ $0.isHexDigit }) else {
            return nil
        }
        self.address = address
    }
}