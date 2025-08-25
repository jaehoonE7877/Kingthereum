import Testing
import Foundation
import BigInt
@preconcurrency import web3swift
@preconcurrency import Web3Core
@testable import WalletKit
@testable import Core
@testable import Entity

// MARK: - Mock Dependencies
@MainActor
final class MockWeb3Client: Sendable {
    var shouldFailRequests = false
    var mockBalance = "1000000000000000000" // 1 ETH in wei
    var mockGasPrice = "20000000000" // 20 Gwei
    var mockGasEstimate = "21000"
    var mockTransactionHash = "0x1234567890abcdef"
    var mockTransactionReceipt: MockTransactionReceipt?
    var mockBlockNumber = 18500000
    
    func reset() {
        shouldFailRequests = false
        mockBalance = "1000000000000000000"
        mockGasPrice = "20000000000"
        mockGasEstimate = "21000"
        mockTransactionHash = "0x1234567890abcdef"
        mockTransactionReceipt = nil
        mockBlockNumber = 18500000
    }
    
    func setShouldFailRequests(_ value: Bool) {
        shouldFailRequests = value
    }
    
    func setMockTransactionReceipt(_ receipt: MockTransactionReceipt?) {
        mockTransactionReceipt = receipt
    }
}

struct MockTransactionReceipt: Sendable {
    let from: String
    let to: String
    let gasUsed: String
    let status: Entity.TransactionStatus
    let blockNumber: Int
}

// MARK: - Mock EthereumWorker
actor MockEthereumWorker: EthereumWorkerProtocol {
    private let mockClient: MockWeb3Client
    
    init(mockClient: MockWeb3Client = MockWeb3Client()) {
        self.mockClient = mockClient
    }
    
    func getBalance(for address: String) async throws -> String {
        guard !await mockClient.shouldFailRequests else {
            throw EthereumError.networkError("Mock network error")
        }
        
        guard MockEthereumAddress(address) != nil else {
            throw EthereumError.invalidAddress
        }
        
        return await mockClient.mockBalance
    }
    
    func sendTransaction(
        from: String,
        to: String,
        value: String,
        gasPrice: String?,
        gasLimit: String?
    ) async throws -> String {
        guard !await mockClient.shouldFailRequests else {
            throw EthereumError.transactionFailed("Mock transaction failed")
        }
        
        guard MockEthereumAddress(from) != nil,
              MockEthereumAddress(to) != nil else {
            throw EthereumError.invalidAddress
        }
        
        guard BigUInt(value) != nil else {
            throw EthereumError.networkError("Invalid amount")
        }
        
        return await mockClient.mockTransactionHash
    }
    
    func estimateGas(from: String, to: String, value: String) async throws -> String {
        guard !await mockClient.shouldFailRequests else {
            throw EthereumError.gasEstimationFailed("Mock gas estimation failed")
        }
        
        guard MockEthereumAddress(from) != nil,
              MockEthereumAddress(to) != nil else {
            throw EthereumError.invalidAddress
        }
        
        return await mockClient.mockGasEstimate
    }
    
    func getCurrentGasPrice() async throws -> String {
        guard !await mockClient.shouldFailRequests else {
            throw EthereumError.networkError("Mock gas price error")
        }
        
        return await mockClient.mockGasPrice
    }
    
    func getTransactionReceipt(transactionHash: String) async throws -> WalletKit.TransactionReceipt? {
        guard !await mockClient.shouldFailRequests else {
            throw EthereumError.networkError("Mock receipt error")
        }
        
        guard let receipt = await mockClient.mockTransactionReceipt else {
            return nil
        }
        
        return WalletKit.TransactionReceipt(
            transactionHash: transactionHash,
            blockNumber: String(receipt.blockNumber),
            blockHash: "0x" + String(repeating: "0", count: 64),
            gasUsed: receipt.gasUsed,
            status: receipt.status == .confirmed ? "1" : "0"
        )
    }
    
    func getBlockNumber() async throws -> String {
        guard !await mockClient.shouldFailRequests else {
            throw EthereumError.networkError("Mock block number error")
        }
        
        return String(await mockClient.mockBlockNumber)
    }
    
    func getProvider() async -> web3swift.Web3HttpProvider? {
        return nil // Mock implementation
    }
}

// MARK: - Test Data
struct EthereumTestScenario: Sendable, CustomStringConvertible {
    let name: String
    let address: String
    let isValid: Bool
    
    var description: String { name }
}

struct TransactionTestScenario: Sendable, CustomStringConvertible {
    let name: String
    let from: String
    let to: String
    let amount: String
    let shouldSucceed: Bool
    
    var description: String { name }
}

struct GasEstimationScenario: Sendable, CustomStringConvertible {
    let name: String
    let from: String
    let to: String
    let amount: String
    let expectedGas: String
    
    var description: String { name }
}

// MARK: - EthereumWorker Tests
@Suite("EthereumWorker Tests")
@MainActor
struct EthereumWorkerTests {
    
    // MARK: - Test Data
    private static let validAddresses = [
        EthereumTestScenario(
            name: "Valid mainnet address",
            address: "0x742d35Cc6627C8532b9b92a3d43F1f12f2CaF8B5",
            isValid: true
        ),
        EthereumTestScenario(
            name: "Valid address with mixed case",
            address: "0x742d35Cc6627C8532b9b92a3d43F1f12f2CaF8B5",
            isValid: true
        )
    ]
    
    private static let invalidAddresses = [
        EthereumTestScenario(
            name: "Invalid address - too short",
            address: "0x123",
            isValid: false
        ),
        EthereumTestScenario(
            name: "Invalid address - no 0x prefix",
            address: "742d35Cc6627C8532b9b92a3d43F1f12f2CaF8B5",
            isValid: false
        ),
        EthereumTestScenario(
            name: "Invalid address - empty string",
            address: "",
            isValid: false
        ),
        EthereumTestScenario(
            name: "Invalid address - invalid characters",
            address: "0x742d35Cc6627C8532b9b92a3d43F1f12f2CaFXYZ",
            isValid: false
        )
    ]
    
    private static let transactionScenarios = [
        TransactionTestScenario(
            name: "Valid ETH transfer",
            from: "0x742d35Cc6627C8532b9b92a3d43F1f12f2CaF8B5",
            to: "0x8ba1f109551bD432803012645Hac136c2367b Abb",
            amount: "1000000000000000000", // 1 ETH
            shouldSucceed: true
        ),
        TransactionTestScenario(
            name: "Small amount transfer",
            from: "0x742d35Cc6627C8532b9b92a3d43F1f12f2CaF8B5",
            to: "0x8ba1f109551bD432803012645Hac136c2367b Abb",
            amount: "1000000000000000", // 0.001 ETH
            shouldSucceed: true
        )
    ]
    
    private static let gasEstimationScenarios = [
        GasEstimationScenario(
            name: "Standard ETH transfer",
            from: "0x742d35Cc6627C8532b9b92a3d43F1f12f2CaF8B5",
            to: "0x8ba1f109551bD432803012645Hac136c2367b Abb",
            amount: "1000000000000000000",
            expectedGas: "21000"
        )
    ]
    
    // MARK: - Setup
    private var mockClient: MockWeb3Client!
    private var worker: MockEthereumWorker!
    
    init() async {
        mockClient = MockWeb3Client()
        worker = MockEthereumWorker(mockClient: mockClient)
    }
    
    // MARK: - Balance Tests
    @Test("Get balance for valid addresses", arguments: validAddresses)
    func testGetBalanceForValidAddress(_ scenario: EthereumTestScenario) async throws {
        // Given
        let expectedBalance = await mockClient.mockBalance
        
        // When
        let balance = try await worker.getBalance(for: scenario.address)
        
        // Then
        #expect(balance == expectedBalance, "Balance should match expected value")
        #expect(!balance.isEmpty, "Balance should not be empty")
    }
    
    @Test("Get balance fails for invalid addresses", arguments: invalidAddresses)
    func testGetBalanceForInvalidAddress(_ scenario: EthereumTestScenario) async throws {
        // Given & When & Then
        await #expect(throws: EthereumError.invalidAddress) {
            try await worker.getBalance(for: scenario.address)
        }
    }
    
    @Test("Get balance handles network errors")
    func testGetBalanceNetworkError() async throws {
        // Given
        await mockClient.setShouldFailRequests(true)
        let validAddress = "0x742d35Cc6627C8532b9b92a3d43F1f12f2CaF8B5"
        
        // When & Then
        await #expect(throws: EthereumError.networkError) {
            try await worker.getBalance(for: validAddress)
        }
    }
    
    // MARK: - Gas Price Tests
    @Test("Get current gas price succeeds")
    func testGetCurrentGasPrice() async throws {
        // Given
        let expectedGasPrice = await mockClient.mockGasPrice
        
        // When
        let gasPrice = try await worker.getCurrentGasPrice()
        
        // Then
        #expect(gasPrice == expectedGasPrice, "Gas price should match expected value")
        #expect(BigUInt(gasPrice) != nil, "Gas price should be a valid number")
    }
    
    @Test("Get current gas price handles network errors")
    func testGetCurrentGasPriceNetworkError() async throws {
        // Given
        await mockClient.setShouldFailRequests(true)
        
        // When & Then
        await #expect(throws: EthereumError.networkError) {
            try await worker.getCurrentGasPrice()
        }
    }
    
    // MARK: - Gas Estimation Tests
    @Test("Estimate gas for valid transactions", arguments: gasEstimationScenarios)
    func testEstimateGas(_ scenario: GasEstimationScenario) async throws {
        // When
        let estimatedGas = try await worker.estimateGas(
            from: scenario.from,
            to: scenario.to,
            value: scenario.amount
        )
        
        // Then
        #expect(estimatedGas == scenario.expectedGas, "Estimated gas should match expected value")
        #expect(BigUInt(estimatedGas) != nil, "Estimated gas should be a valid number")
    }
    
    @Test("Estimate gas fails for invalid addresses")
    func testEstimateGasInvalidAddress() async throws {
        // Given
        let invalidFrom = "invalid"
        let validTo = "0x8ba1f109551bD432803012645Hac136c2367b Abb"
        let amount = "1000000000000000000"
        
        // When & Then
        await #expect(throws: EthereumError.invalidAddress) {
            try await worker.estimateGas(from: invalidFrom, to: validTo, value: amount)
        }
    }
    
    // MARK: - Transaction Tests
    @Test("Send transaction succeeds for valid parameters", arguments: transactionScenarios)
    func testSendTransaction(_ scenario: TransactionTestScenario) async throws {
        // Given
        let expectedHash = await mockClient.mockTransactionHash
        
        // When
        let transactionHash = try await worker.sendTransaction(
            from: scenario.from,
            to: scenario.to,
            value: scenario.amount,
            gasPrice: nil,
            gasLimit: nil
        )
        
        // Then
        #expect(transactionHash == expectedHash, "Transaction hash should match expected value")
        #expect(!transactionHash.isEmpty, "Transaction hash should not be empty")
        #expect(transactionHash.hasPrefix("0x"), "Transaction hash should start with 0x")
    }
    
    @Test("Send transaction fails for invalid addresses")
    func testSendTransactionInvalidAddress() async throws {
        // Given
        let invalidFrom = "invalid"
        let validTo = "0x8ba1f109551bD432803012645Hac136c2367b Abb"
        let amount = "1000000000000000000"
        
        // When & Then
        await #expect(throws: EthereumError.invalidAddress) {
            try await worker.sendTransaction(
                from: invalidFrom,
                to: validTo,
                value: amount,
                gasPrice: nil,
                gasLimit: nil
            )
        }
    }
    
    @Test("Send transaction fails for invalid amount")
    func testSendTransactionInvalidAmount() async throws {
        // Given
        let validFrom = "0x742d35Cc6627C8532b9b92a3d43F1f12f2CaF8B5"
        let validTo = "0x8ba1f109551bD432803012645Hac136c2367b Abb"
        let invalidAmount = "invalid"
        
        // When & Then
        await #expect(throws: EthereumError.networkError) {
            try await worker.sendTransaction(
                from: validFrom,
                to: validTo,
                value: invalidAmount,
                gasPrice: nil,
                gasLimit: nil
            )
        }
    }
    
    @Test("Send transaction handles network errors")
    func testSendTransactionNetworkError() async throws {
        // Given
        await mockClient.setShouldFailRequests(true)
        let validFrom = "0x742d35Cc6627C8532b9b92a3d43F1f12f2CaF8B5"
        let validTo = "0x8ba1f109551bD432803012645Hac136c2367b Abb"
        let amount = "1000000000000000000"
        
        // When & Then
        await #expect(throws: EthereumError.transactionFailed) {
            try await worker.sendTransaction(
                from: validFrom,
                to: validTo,
                value: amount,
                gasPrice: nil,
                gasLimit: nil
            )
        }
    }
    
    // MARK: - Transaction Receipt Tests
    @Test("Get transaction receipt succeeds")
    func testGetTransactionReceipt() async throws {
        // Given
        let transactionHash = "0x1234567890abcdef"
        let mockReceipt = MockTransactionReceipt(
            from: "0x742d35Cc6627C8532b9b92a3d43F1f12f2CaF8B5",
            to: "0x8ba1f109551bD432803012645Hac136c2367b Abb",
            gasUsed: "21000",
            status: .confirmed,
            blockNumber: 18500000
        )
        await mockClient.setMockTransactionReceipt(mockReceipt)
        
        // When
        let receipt = try await worker.getTransactionReceipt(transactionHash: transactionHash)
        
        // Then
        #expect(receipt != nil, "Receipt should not be nil")
        #expect(receipt?.transactionHash == transactionHash, "Transaction hash should match")
        #expect(receipt?.status == "1", "Transaction status should be confirmed")
    }
    
    @Test("Get transaction receipt returns nil for non-existent transaction")
    func testGetTransactionReceiptNotFound() async throws {
        // Given
        let transactionHash = "0x1234567890abcdef"
        await mockClient.setMockTransactionReceipt(nil)
        
        // When
        let receipt = try await worker.getTransactionReceipt(transactionHash: transactionHash)
        
        // Then
        #expect(receipt == nil, "Receipt should be nil for non-existent transaction")
    }
    
    // MARK: - Block Number Tests
    @Test("Get block number succeeds")
    func testGetBlockNumber() async throws {
        // Given
        let expectedBlockNumber = String(await mockClient.mockBlockNumber)
        
        // When
        let blockNumber = try await worker.getBlockNumber()
        
        // Then
        #expect(blockNumber == expectedBlockNumber, "Block number should match expected value")
        #expect(Int(blockNumber) ?? 0 > 0, "Block number should be positive")
    }
    
    @Test("Get block number handles network errors")
    func testGetBlockNumberNetworkError() async throws {
        // Given
        await mockClient.setShouldFailRequests(true)
        
        // When & Then
        await #expect(throws: EthereumError.networkError) {
            try await worker.getBlockNumber()
        }
    }
}

// MARK: - Helper for EthereumAddress Mock
struct EthereumAddress: Sendable {
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

// MARK: - EthereumError Tests
@Suite("EthereumError Tests")
struct EthereumErrorTests {
    
    @Test("EthereumError descriptions are correct")
    func testEthereumErrorDescriptions() {
        let errorCases: [(EthereumError, String)] = [
            (.invalidRpcUrl, "잘못된 RPC URL"),
            (.invalidAddress, "잘못된 이더리움 주소"),
            (.networkError("test"), "네트워크 오류: test"),
            (.transactionFailed("test"), "트랜잭션 실패: test"),
            (.gasEstimationFailed("test"), "가스 추정 실패: test"),
            (.insufficientFunds, "잔액 부족"),
            (.unknownError, "알 수 없는 오류가 발생했습니다")
        ]
        
        for (error, expectedDescription) in errorCases {
            #expect(error.errorDescription == expectedDescription, 
                   "Error description should match expected value for \(error)")
        }
    }
}