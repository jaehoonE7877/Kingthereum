import Testing
import Foundation
@testable import SecurityKit
@testable import Core

// MARK: - Mock Keychain
final class MockKeychain: @unchecked Sendable {
    private var storage: [String: String] = [:]
    private var shouldFailOperations = false
    private var failureError: Error = MockKeychainError.operationFailed
    
    func reset() {
        storage.removeAll()
        shouldFailOperations = false
        failureError = MockKeychainError.operationFailed
    }
    
    func setFailureMode(_ shouldFail: Bool, error: Error = MockKeychainError.operationFailed) {
        shouldFailOperations = shouldFail
        failureError = error
    }
    
    func set(_ value: String, key: String) throws {
        guard !shouldFailOperations else {
            throw failureError
        }
        storage[key] = value
    }
    
    func get(_ key: String) throws -> String? {
        guard !shouldFailOperations else {
            throw failureError
        }
        return storage[key]
    }
    
    func remove(_ key: String) throws {
        guard !shouldFailOperations else {
            throw failureError
        }
        storage.removeValue(forKey: key)
    }
    
    func removeAll() throws {
        guard !shouldFailOperations else {
            throw failureError
        }
        storage.removeAll()
    }
    
    func getAllKeys() -> [String] {
        return Array(storage.keys)
    }
    
    func getAllValues() -> [String: String] {
        return storage
    }
}

enum MockKeychainError: Error, LocalizedError {
    case operationFailed
    case accessDenied
    case itemNotFound
    case duplicateItem
    
    var errorDescription: String? {
        switch self {
        case .operationFailed:
            return "Keychain operation failed"
        case .accessDenied:
            return "Access denied"
        case .itemNotFound:
            return "Item not found"
        case .duplicateItem:
            return "Duplicate item"
        }
    }
}

// MARK: - Mock KeychainManager
final class MockKeychainManager: KeychainManagerProtocol, @unchecked Sendable {
    private let mockKeychain: MockKeychain
    
    init(mockKeychain: MockKeychain = MockKeychain()) {
        self.mockKeychain = mockKeychain
    }
    
    func store(key: String, value: String) throws {
        try mockKeychain.set(value, key: key)
    }
    
    func retrieve(key: String) throws -> String? {
        return try mockKeychain.get(key)
    }
    
    func delete(key: String) throws {
        try mockKeychain.remove(key)
    }
    
    func deleteAll() throws {
        try mockKeychain.removeAll()
    }
    
    // MARK: - Wallet Methods
    func storePrivateKey(_ privateKey: String) async throws {
        try store(key: "private_key", value: privateKey)
    }
    
    func retrievePrivateKey() async throws -> String? {
        return try retrieve(key: "private_key")
    }
    
    func deletePrivateKey() async throws {
        try delete(key: "private_key")
    }
    
    func storeWalletAddress(_ address: String) async throws {
        try store(key: "wallet_address", value: address)
    }
    
    func retrieveWalletAddress() async throws -> String? {
        return try retrieve(key: "wallet_address")
    }
    
    func deleteWalletAddress() async throws {
        try delete(key: "wallet_address")
    }
    
    func storePIN(_ pin: String) async throws {
        try store(key: "pin", value: pin)
    }
    
    func retrievePIN() async throws -> String? {
        return try retrieve(key: "pin")
    }
    
    func deletePIN() async throws {
        try delete(key: "pin")
    }
}

// MARK: - Test Data
struct KeychainTestScenario: Sendable, CustomStringConvertible {
    let name: String
    let key: String
    let value: String
    
    var description: String { name }
}

struct WalletSecurityScenario: Sendable, CustomStringConvertible {
    let name: String
    let privateKey: String
    let mnemonic: String
    let pin: String
    
    var description: String { name }
}

struct KeychainErrorScenario: Sendable, CustomStringConvertible {
    let name: String
    let error: MockKeychainError
    let operation: String
    
    var description: String { name }
}

// MARK: - KeychainManager Tests
@Suite("KeychainManager Tests")
struct KeychainManagerTests {
    
    // MARK: - Test Data
    private static let basicKeychainScenarios = [
        KeychainTestScenario(
            name: "Simple key-value storage",
            key: "test_key",
            value: "test_value"
        ),
        KeychainTestScenario(
            name: "Long key storage",
            key: String(repeating: "key", count: 50),
            value: "long_key_value"
        ),
        KeychainTestScenario(
            name: "Long value storage",
            key: "long_value_key",
            value: String(repeating: "value", count: 1000)
        ),
        KeychainTestScenario(
            name: "Special characters in key",
            key: "test.key-with_special@chars",
            value: "special_key_value"
        ),
        KeychainTestScenario(
            name: "Special characters in value",
            key: "special_value_key",
            value: "value with spaces and symbols: !@#$%^&*()"
        ),
        KeychainTestScenario(
            name: "Unicode value storage",
            key: "unicode_key",
            value: "Unicode value: 🔐🛡️💰 안전한 지갑"
        )
    ]
    
    private static let walletSecurityScenarios = [
        WalletSecurityScenario(
            name: "Ethereum wallet credentials",
            privateKey: "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12",
            mnemonic: "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about",
            pin: "123456"
        ),
        WalletSecurityScenario(
            name: "Production-like credentials",
            privateKey: "0xa1b2c3d4e5f6789012345678901234567890123456789012345678901234567890",
            mnemonic: "legal winner thank year wave sausage worth useful legal winner thank yellow",
            pin: "987654"
        )
    ]
    
    private static let errorScenarios = [
        KeychainErrorScenario(
            name: "Operation failed error",
            error: .operationFailed,
            operation: "store"
        ),
        KeychainErrorScenario(
            name: "Access denied error",
            error: .accessDenied,
            operation: "retrieve"
        ),
        KeychainErrorScenario(
            name: "Item not found error",
            error: .itemNotFound,
            operation: "retrieve"
        )
    ]
    
    // MARK: - Setup
    private var mockKeychain: MockKeychain!
    private var manager: MockKeychainManager!
    
    init() {
        mockKeychain = MockKeychain()
        manager = MockKeychainManager(mockKeychain: mockKeychain)
    }
    
    // MARK: - Basic Operations Tests
    @Test("Store and retrieve basic key-value pairs", arguments: basicKeychainScenarios)
    func testBasicKeyValueOperations(_ scenario: KeychainTestScenario) throws {
        // Given
        mockKeychain.reset()
        
        // When - Store value
        try manager.store(key: scenario.key, value: scenario.value)
        
        // Then - Verify storage
        let storedValue = try manager.retrieve(key: scenario.key)
        #expect(storedValue == scenario.value, "Retrieved value should match stored value")
        
        // When - Delete value
        try manager.delete(key: scenario.key)
        
        // Then - Verify deletion
        let deletedValue = try manager.retrieve(key: scenario.key)
        #expect(deletedValue == nil, "Value should be nil after deletion")
    }
    
    @Test("Store multiple key-value pairs")
    func testMultipleKeyValuePairs() throws {
        // Given
        mockKeychain.reset()
        let testData = [
            "key1": "value1",
            "key2": "value2",
            "key3": "value3"
        ]
        
        // When - Store multiple values
        for (key, value) in testData {
            try manager.store(key: key, value: value)
        }
        
        // Then - Verify all values
        for (key, expectedValue) in testData {
            let retrievedValue = try manager.retrieve(key: key)
            #expect(retrievedValue == expectedValue, "Value for key \(key) should match")
        }
        
        // Verify keychain contains all keys
        let allKeys = mockKeychain.getAllKeys()
        #expect(allKeys.count == testData.count, "Should have correct number of keys")
        
        for key in testData.keys {
            #expect(allKeys.contains(key), "Should contain key \(key)")
        }
    }
    
    @Test("Retrieve non-existent key returns nil")
    func testRetrieveNonExistentKey() throws {
        // Given
        mockKeychain.reset()
        let nonExistentKey = "non_existent_key"
        
        // When
        let value = try manager.retrieve(key: nonExistentKey)
        
        // Then
        #expect(value == nil, "Non-existent key should return nil")
    }
    
    @Test("Update existing key-value pair")
    func testUpdateExistingKeyValue() throws {
        // Given
        mockKeychain.reset()
        let key = "update_test_key"
        let originalValue = "original_value"
        let updatedValue = "updated_value"
        
        // When - Store original value
        try manager.store(key: key, value: originalValue)
        let firstRetrieval = try manager.retrieve(key: key)
        
        // Then
        #expect(firstRetrieval == originalValue, "Should retrieve original value")
        
        // When - Update value
        try manager.store(key: key, value: updatedValue)
        let secondRetrieval = try manager.retrieve(key: key)
        
        // Then
        #expect(secondRetrieval == updatedValue, "Should retrieve updated value")
    }
    
    @Test("Delete non-existent key does not throw")
    func testDeleteNonExistentKey() throws {
        // Given
        mockKeychain.reset()
        let nonExistentKey = "non_existent_key"
        
        // When & Then - Should not throw
        try manager.delete(key: nonExistentKey)
    }
    
    @Test("Delete all keys")
    func testDeleteAllKeys() throws {
        // Given
        mockKeychain.reset()
        let testData = [
            "key1": "value1",
            "key2": "value2",
            "key3": "value3"
        ]
        
        // When - Store multiple values
        for (key, value) in testData {
            try manager.store(key: key, value: value)
        }
        
        // Verify they exist
        for (key, expectedValue) in testData {
            let value = try manager.retrieve(key: key)
            #expect(value == expectedValue, "Value should exist before deletion")
        }
        
        // When - Delete all
        try manager.deleteAll()
        
        // Then - Verify all are deleted
        for key in testData.keys {
            let value = try manager.retrieve(key: key)
            #expect(value == nil, "Value should be nil after deleteAll")
        }
        
        let allKeys = mockKeychain.getAllKeys()
        #expect(allKeys.isEmpty, "Should have no keys after deleteAll")
    }
    
    // MARK: - Wallet-Specific Tests
    @Test("Store and retrieve wallet credentials", arguments: walletSecurityScenarios)
    func testWalletCredentials(_ scenario: WalletSecurityScenario) throws {
        // Given
        mockKeychain.reset()
        let managerWithExtensions = MockKeychainManagerWithExtensions(mockKeychain: mockKeychain)
        
        // When - Store wallet credentials
        try managerWithExtensions.storePrivateKey(scenario.privateKey)
        // 니모닉은 더 이상 키체인에 저장하지 않음 - 테스트 건너뜀
        try managerWithExtensions.storePIN(scenario.pin)
        
        // Then - Verify retrieval
        let retrievedPrivateKey = try managerWithExtensions.retrievePrivateKey()
        // let retrievedMnemonic = nil // 니모닉은 저장되지 않음
        let retrievedPIN = try managerWithExtensions.retrievePIN()
        
        #expect(retrievedPrivateKey == scenario.privateKey, "Private key should match")
        #expect(retrievedMnemonic == scenario.mnemonic, "Mnemonic should match")
        #expect(retrievedPIN == scenario.pin, "PIN should match")
    }
    
    @Test("Delete wallet credentials individually")
    func testDeleteWalletCredentialsIndividually() throws {
        // Given
        mockKeychain.reset()
        let managerWithExtensions = MockKeychainManagerWithExtensions(mockKeychain: mockKeychain)
        
        let privateKey = "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12"
        let mnemonic = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
        let pin = "123456"
        
        // Store all credentials
        try managerWithExtensions.storePrivateKey(privateKey)
        // 니모닉은 더 이상 키체인에 저장하지 않음 - 테스트 건너뜀
        try managerWithExtensions.storePIN(pin)
        
        // When - Delete private key only
        try managerWithExtensions.deletePrivateKey()
        
        // Then - Verify private key is deleted, others remain
        let retrievedPrivateKey = try managerWithExtensions.retrievePrivateKey()
        // let retrievedMnemonic = nil // 니모닉은 저장되지 않음
        let retrievedPIN = try managerWithExtensions.retrievePIN()
        
        #expect(retrievedPrivateKey == nil, "Private key should be deleted")
        #expect(retrievedMnemonic == mnemonic, "Mnemonic should remain")
        #expect(retrievedPIN == pin, "PIN should remain")
        
        // When - Delete mnemonic
        // 니모닉 삭제 테스트 건너뜀 - 더 이상 저장하지 않음
        
        // Then - Verify mnemonic is deleted, PIN remains
        // let retrievedMnemonic2 = nil // 니모닉은 저장되지 않음
        let retrievedPIN2 = try managerWithExtensions.retrievePIN()
        
        #expect(retrievedMnemonic2 == nil, "Mnemonic should be deleted")
        #expect(retrievedPIN2 == pin, "PIN should remain")
        
        // When - Delete PIN
        try managerWithExtensions.deletePIN()
        
        // Then - Verify PIN is deleted
        let retrievedPIN3 = try managerWithExtensions.retrievePIN()
        #expect(retrievedPIN3 == nil, "PIN should be deleted")
    }
    
    // MARK: - Error Handling Tests
    @Test("Handle keychain operation errors", arguments: errorScenarios)
    func testKeychainOperationErrors(_ scenario: KeychainErrorScenario) throws {
        // Given
        mockKeychain.reset()
        mockKeychain.setFailureMode(true, error: scenario.error)
        
        // When & Then
        switch scenario.operation {
        case "store":
            #expect(throws: MockKeychainError.self) {
                try manager.store(key: "test_key", value: "test_value")
            }
        case "retrieve":
            #expect(throws: MockKeychainError.self) {
                try manager.retrieve(key: "test_key")
            }
        case "delete":
            #expect(throws: MockKeychainError.self) {
                try manager.delete(key: "test_key")
            }
        case "deleteAll":
            #expect(throws: MockKeychainError.self) {
                try manager.deleteAll()
            }
        default:
            Issue.record("Unknown operation: \(scenario.operation)")
        }
    }
    
    @Test("Error recovery after failed operations")
    func testErrorRecovery() throws {
        // Given
        mockKeychain.reset()
        let testKey = "recovery_test_key"
        let testValue = "recovery_test_value"
        
        // When - Simulate failure
        mockKeychain.setFailureMode(true, error: MockKeychainError.operationFailed)
        
        // Then - Operation should fail
        #expect(throws: MockKeychainError.self) {
            try manager.store(key: testKey, value: testValue)
        }
        
        // When - Restore normal operation
        mockKeychain.setFailureMode(false)
        
        // Then - Operation should succeed
        try manager.store(key: testKey, value: testValue)
        let retrievedValue = try manager.retrieve(key: testKey)
        #expect(retrievedValue == testValue, "Should work after error recovery")
    }
    
    // MARK: - Edge Cases Tests
    @Test("Store empty string value")
    func testStoreEmptyStringValue() throws {
        // Given
        mockKeychain.reset()
        let key = "empty_value_key"
        let emptyValue = ""
        
        // When
        try manager.store(key: key, value: emptyValue)
        
        // Then
        let retrievedValue = try manager.retrieve(key: key)
        #expect(retrievedValue == emptyValue, "Should handle empty string values")
    }
    
    @Test("Store very long value")
    func testStoreVeryLongValue() throws {
        // Given
        mockKeychain.reset()
        let key = "long_value_key"
        let longValue = String(repeating: "a", count: 10000) // 10KB string
        
        // When
        try manager.store(key: key, value: longValue)
        
        // Then
        let retrievedValue = try manager.retrieve(key: key)
        #expect(retrievedValue == longValue, "Should handle very long values")
    }
    
    @Test("Store binary-like data as string")
    func testStoreBinaryLikeData() throws {
        // Given
        mockKeychain.reset()
        let key = "binary_data_key"
        let binaryValue = Data([0x00, 0x01, 0x02, 0xFF, 0xFE, 0xFD]).base64EncodedString()
        
        // When
        try manager.store(key: key, value: binaryValue)
        
        // Then
        let retrievedValue = try manager.retrieve(key: key)
        #expect(retrievedValue == binaryValue, "Should handle binary-encoded data")
    }
    
    // MARK: - Performance Tests
    @Test(.timeLimit(.minutes(1)))
    func testStoragePerformance() throws {
        // Given
        mockKeychain.reset()
        
        // When & Then - Should complete within 1 minute
        for i in 0..<1000 {
            let key = "perf_key_\(i)"
            let value = "perf_value_\(i)_\(String(repeating: "x", count: 100))"
            
            try manager.store(key: key, value: value)
            let retrievedValue = try manager.retrieve(key: key)
            #expect(retrievedValue == value, "Performance test item \(i) should match")
        }
    }
    
    @Test(.timeLimit(.minutes(1)))
    func testRetrievalPerformance() throws {
        // Given
        mockKeychain.reset()
        let testData = (0..<100).map { i in
            ("key_\(i)", "value_\(i)")
        }
        
        // Store test data
        for (key, value) in testData {
            try manager.store(key: key, value: value)
        }
        
        // When & Then - Should complete within 1 minute
        for _ in 0..<1000 {
            for (key, expectedValue) in testData {
                let value = try manager.retrieve(key: key)
                #expect(value == expectedValue, "Performance retrieval should match")
            }
        }
    }
    
    // MARK: - Concurrent Access Tests
    @Test("Concurrent store operations")
    func testConcurrentStoreOperations() async throws {
        // Given
        mockKeychain.reset()
        
        // When - Perform concurrent store operations
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    do {
                        try manager.store(key: "concurrent_key_\(i)", value: "concurrent_value_\(i)")
                    } catch {
                        Issue.record("Concurrent store failed for key \(i): \(error)")
                    }
                }
            }
        }
        
        // Then - Verify all values were stored
        for i in 0..<10 {
            let value = try manager.retrieve(key: "concurrent_key_\(i)")
            #expect(value == "concurrent_value_\(i)", "Concurrent store \(i) should succeed")
        }
    }
    
    @Test("Concurrent retrieve operations")
    func testConcurrentRetrieveOperations() async throws {
        // Given
        mockKeychain.reset()
        let testKey = "concurrent_retrieve_key"
        let testValue = "concurrent_retrieve_value"
        try manager.store(key: testKey, value: testValue)
        
        // When - Perform concurrent retrieve operations
        let results = await withTaskGroup(of: String?.self, returning: [String?].self) { group in
            var results: [String?] = []
            
            for _ in 0..<10 {
                group.addTask {
                    do {
                        return try manager.retrieve(key: testKey)
                    } catch {
                        Issue.record("Concurrent retrieve failed: \(error)")
                        return nil
                    }
                }
            }
            
            for await result in group {
                results.append(result)
            }
            
            return results
        }
        
        // Then - All retrievals should succeed
        #expect(results.count == 10, "Should have 10 results")
        for result in results {
            #expect(result == testValue, "All concurrent retrievals should return correct value")
        }
    }
}

// MARK: - Mock KeychainManager with Extensions
final class MockKeychainManagerWithExtensions: KeychainManagerProtocol, @unchecked Sendable {
    private let mockKeychain: MockKeychain
    
    init(mockKeychain: MockKeychain) {
        self.mockKeychain = mockKeychain
    }
    
    func store(key: String, value: String) throws {
        try mockKeychain.set(value, key: key)
    }
    
    func retrieve(key: String) throws -> String? {
        return try mockKeychain.get(key)
    }
    
    func delete(key: String) throws {
        try mockKeychain.remove(key)
    }
    
    func deleteAll() throws {
        try mockKeychain.removeAll()
    }
    
    // MARK: - Wallet Methods
    func storePrivateKey(_ privateKey: String) async throws {
        try store(key: "private_key", value: privateKey)
    }
    
    func retrievePrivateKey() async throws -> String? {
        return try retrieve(key: "private_key")
    }
    
    func deletePrivateKey() async throws {
        try delete(key: "private_key")
    }
    
    func storeWalletAddress(_ address: String) async throws {
        try store(key: "wallet_address", value: address)
    }
    
    func retrieveWalletAddress() async throws -> String? {
        return try retrieve(key: "wallet_address")
    }
    
    func deleteWalletAddress() async throws {
        try delete(key: "wallet_address")
    }
    
    func storePIN(_ pin: String) async throws {
        try store(key: "pin", value: pin)
    }
    
    func retrievePIN() async throws -> String? {
        return try retrieve(key: "pin")
    }
    
    func deletePIN() async throws {
        try delete(key: "pin")
    }
}


// MARK: - Integration Tests
@Suite("KeychainManager Integration Tests")
struct KeychainManagerIntegrationTests {
    
    private var mockKeychain: MockKeychain!
    private var manager: MockKeychainManagerWithExtensions!
    
    init() {
        mockKeychain = MockKeychain()
        manager = MockKeychainManagerWithExtensions(mockKeychain: mockKeychain)
    }
    
    @Test("Complete wallet security setup")
    func testCompleteWalletSecuritySetup() throws {
        // Given
        mockKeychain.reset()
        let privateKey = "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12"
        let mnemonic = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
        let pin = "123456"
        
        // When - Setup complete wallet security
        try manager.storePrivateKey(privateKey)
        // try manager.storeMnemonic(mnemonic) // 니모닉은 더 이상 저장하지 않음
        try manager.storePIN(pin)
        
        // Then - Verify all credentials are stored
        let storedPrivateKey = try manager.retrievePrivateKey()
        // let storedMnemonic = nil // 니모닉은 저장되지 않음
        let storedPIN = try manager.retrievePIN()
        
        #expect(storedPrivateKey == privateKey, "Private key should be stored correctly")
        #expect(storedMnemonic == mnemonic, "Mnemonic should be stored correctly")
        #expect(storedPIN == pin, "PIN should be stored correctly")
        
        // Verify keychain contains all expected keys
        let allKeys = mockKeychain.getAllKeys()
        #expect(allKeys.contains("private_key"), "Should contain private key")
        #expect(allKeys.contains("mnemonic"), "Should contain mnemonic")
        #expect(allKeys.contains("pin"), "Should contain PIN")
    }
    
    @Test("Wallet reset scenario")
    func testWalletResetScenario() throws {
        // Given - Setup wallet with full credentials
        mockKeychain.reset()
        try manager.storePrivateKey("0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12")
        try manager.storeMnemonic("abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about")
        try manager.storePIN("123456")
        
        // Verify setup
        #expect(try manager.retrievePrivateKey() != nil, "Private key should exist before reset")
        // #expect(try manager.retrieveMnemonic() != nil, "Mnemonic should exist before reset") // 니모닉은 저장되지 않음
        #expect(try manager.retrievePIN() != nil, "PIN should exist before reset")
        
        // When - Reset wallet (delete all)
        try manager.deleteAll()
        
        // Then - Verify all credentials are removed
        #expect(try manager.retrievePrivateKey() == nil, "Private key should be removed after reset")
        // #expect(try manager.retrieveMnemonic() == nil, "Mnemonic should be removed after reset") // 니모닉은 애초에 저장되지 않음
        #expect(try manager.retrievePIN() == nil, "PIN should be removed after reset")
        
        let allKeys = mockKeychain.getAllKeys()
        #expect(allKeys.isEmpty, "Should have no keys after reset")
    }
    
    @Test("Wallet backup and restore simulation")
    func testWalletBackupAndRestoreSimulation() throws {
        // Given - Original wallet setup
        mockKeychain.reset()
        let originalPrivateKey = "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12"
        let originalMnemonic = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
        let originalPIN = "123456"
        
        try manager.storePrivateKey(originalPrivateKey)
        try manager.storeMnemonic(originalMnemonic)
        try manager.storePIN(originalPIN)
        
        // When - Simulate backup (get all values)
        let backupPrivateKey = try manager.retrievePrivateKey()
        // let backupMnemonic = nil // 니모닉은 저장되지 않음
        let backupPIN = try manager.retrievePIN()
        
        // When - Simulate device loss (clear keychain)
        try manager.deleteAll()
        
        // Verify loss
        #expect(try manager.retrievePrivateKey() == nil, "Should be empty after loss")
        // #expect(try manager.retrieveMnemonic() == nil, "Should be empty after loss") // 니모닉은 애초에 저장되지 않음
        #expect(try manager.retrievePIN() == nil, "Should be empty after loss")
        
        // When - Simulate restore from backup
        guard let backupPrivateKey = backupPrivateKey,
              let backupMnemonic = backupMnemonic,
              let backupPIN = backupPIN else {
            Issue.record("Backup values should not be nil")
            return
        }
        
        try manager.storePrivateKey(backupPrivateKey)
        // try manager.storeMnemonic(backupMnemonic) // 니모닉은 저장하지 않음
        try manager.storePIN(backupPIN)
        
        // Then - Verify restore
        let restoredPrivateKey = try manager.retrievePrivateKey()
        // let restoredMnemonic = nil // 니모닉은 저장되지 않음
        let restoredPIN = try manager.retrievePIN()
        
        #expect(restoredPrivateKey == originalPrivateKey, "Restored private key should match original")
        #expect(restoredMnemonic == originalMnemonic, "Restored mnemonic should match original")
        #expect(restoredPIN == originalPIN, "Restored PIN should match original")
    }
}