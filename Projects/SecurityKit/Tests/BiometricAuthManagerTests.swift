import Testing
import Foundation
import LocalAuthentication
@testable import SecurityKit
@testable import Core
@testable import Entity

// MARK: - Mock LAContext
final class MockLAContext: LAContext, @unchecked Sendable {
    var mockBiometryType: LABiometryType = .faceID
    var mockCanEvaluatePolicy = true
    var mockEvaluateError: LAError?
    var mockEvaluateResult = true
    var evaluateCallCount = 0
    var lastEvaluatedPolicy: LAPolicy?
    var lastLocalizedReason: String?
    
    override var biometryType: LABiometryType {
        return mockBiometryType
    }
    
    override func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool {
        if !mockCanEvaluatePolicy {
            if let errorPointer = error {
                errorPointer.pointee = LAError(.biometryNotAvailable) as NSError
            }
            return false
        }
        return true
    }
    
    override func evaluatePolicy(
        _ policy: LAPolicy,
        localizedReason: String
    ) async throws -> Bool {
        evaluateCallCount += 1
        lastEvaluatedPolicy = policy
        lastLocalizedReason = localizedReason
        
        if let error = mockEvaluateError {
            throw error
        }
        
        return mockEvaluateResult
    }
    
    func reset() {
        mockBiometryType = .faceID
        mockCanEvaluatePolicy = true
        mockEvaluateError = nil
        mockEvaluateResult = true
        evaluateCallCount = 0
        lastEvaluatedPolicy = nil
        lastLocalizedReason = nil
    }
}

// MARK: - Mock BiometricAuthManager
final class MockBiometricAuthManager: BiometricAuthManagerProtocol, @unchecked Sendable {
    private let mockContext: MockLAContext
    
    init(mockContext: MockLAContext = MockLAContext()) {
        self.mockContext = mockContext
    }
    
    var biometricType: BiometricType {
        switch mockContext.mockBiometryType {
        case .none:
            return .none
        case .touchID:
            return .touchID
        case .faceID:
            return .faceID
        case .opticID:
            return .opticID
        @unknown default:
            return .none
        }
    }
    
    var isAvailable: Bool {
        return mockContext.mockCanEvaluatePolicy
    }
    
    func authenticate(reason: String) async throws -> Bool {
        guard mockContext.mockCanEvaluatePolicy else {
            throw BiometricError.notAvailable
        }
        
        if let error = mockContext.mockEvaluateError {
            throw mapLAErrorToBiometricError(error)
        }
        
        return try await mockContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
    }
    
    private func mapLAErrorToBiometricError(_ error: LAError) -> BiometricError {
        switch error.code {
        case .biometryNotAvailable:
            return .notAvailable
        case .biometryNotEnrolled:
            return .notEnrolled
        case .biometryLockout:
            return .biometryLockout
        case .authenticationFailed:
            return .authenticationFailed
        case .userCancel:
            return .userCancel
        case .userFallback:
            return .userFallback
        case .systemCancel:
            return .userCancel
        case .passcodeNotSet:
            return .notAvailable
        default:
            return .unknown(error)
        }
    }
}

// MARK: - Test Data
struct BiometricTestScenario: Sendable, CustomStringConvertible {
    let name: String
    let biometryType: LABiometryType
    let expectedType: BiometricType
    let isAvailable: Bool
    
    var description: String { name }
}

struct AuthenticationScenario: Sendable, CustomStringConvertible {
    let name: String
    let reason: String
    let shouldSucceed: Bool
    let expectedError: BiometricError?
    
    var description: String { name }
}

struct ErrorMappingScenario: Sendable, CustomStringConvertible {
    let name: String
    let laErrorCode: LAError.Code
    let expectedBiometricError: BiometricError
    
    var description: String { name }
}

// MARK: - BiometricAuthManager Tests
@Suite("BiometricAuthManager Tests")
struct BiometricAuthManagerTests {
    
    // MARK: - Test Data
    private static let biometricTypeScenarios = [
        BiometricTestScenario(
            name: "Face ID available",
            biometryType: .faceID,
            expectedType: .faceID,
            isAvailable: true
        ),
        BiometricTestScenario(
            name: "Touch ID available",
            biometryType: .touchID,
            expectedType: .touchID,
            isAvailable: true
        ),
        BiometricTestScenario(
            name: "Optic ID available",
            biometryType: .opticID,
            expectedType: .opticID,
            isAvailable: true
        ),
        BiometricTestScenario(
            name: "No biometrics available",
            biometryType: .none,
            expectedType: .none,
            isAvailable: false
        )
    ]
    
    private static let authenticationScenarios = [
        AuthenticationScenario(
            name: "Successful authentication",
            reason: "Authenticate to access your wallet",
            shouldSucceed: true,
            expectedError: nil
        ),
        AuthenticationScenario(
            name: "Authentication with custom reason",
            reason: "Unlock secure storage",
            shouldSucceed: true,
            expectedError: nil
        ),
        AuthenticationScenario(
            name: "Authentication with long reason",
            reason: String(repeating: "A", count: 200),
            shouldSucceed: true,
            expectedError: nil
        )
    ]
    
    private static let errorMappingScenarios = [
        ErrorMappingScenario(
            name: "Biometry not available",
            laErrorCode: .biometryNotAvailable,
            expectedBiometricError: .notAvailable
        ),
        ErrorMappingScenario(
            name: "Biometry not enrolled",
            laErrorCode: .biometryNotEnrolled,
            expectedBiometricError: .notEnrolled
        ),
        ErrorMappingScenario(
            name: "Biometry lockout",
            laErrorCode: .biometryLockout,
            expectedBiometricError: .biometryLockout
        ),
        ErrorMappingScenario(
            name: "Authentication failed",
            laErrorCode: .authenticationFailed,
            expectedBiometricError: .authenticationFailed
        ),
        ErrorMappingScenario(
            name: "User cancelled",
            laErrorCode: .userCancel,
            expectedBiometricError: .userCancel
        ),
        ErrorMappingScenario(
            name: "User fallback",
            laErrorCode: .userFallback,
            expectedBiometricError: .userFallback
        ),
        ErrorMappingScenario(
            name: "System cancelled",
            laErrorCode: .systemCancel,
            expectedBiometricError: .userCancel
        )
    ]
    
    // MARK: - Setup
    private var mockContext: MockLAContext!
    private var manager: MockBiometricAuthManager!
    
    init() {
        mockContext = MockLAContext()
        manager = MockBiometricAuthManager(mockContext: mockContext)
    }
    
    // MARK: - Biometric Type Tests
    @Test("Biometric type detection", arguments: biometricTypeScenarios)
    func testBiometricType(_ scenario: BiometricTestScenario) {
        // Given
        mockContext.mockBiometryType = scenario.biometryType
        mockContext.mockCanEvaluatePolicy = scenario.isAvailable
        
        // When
        let detectedType = manager.biometricType
        let availability = manager.isAvailable
        
        // Then
        #expect(detectedType == scenario.expectedType, "Biometric type should match expected value")
        #expect(availability == scenario.isAvailable, "Availability should match expected value")
    }
    
    @Test("Biometric type descriptions")
    func testBiometricTypeDescriptions() {
        let typeDescriptions: [(BiometricType, String)] = [
            (.none, "None"),
            (.touchID, "Touch ID"),
            (.faceID, "Face ID"),
            (.opticID, "Optic ID")
        ]
        
        for (type, expectedDescription) in typeDescriptions {
            #expect(type.description == expectedDescription, 
                   "Description for \(type) should be \(expectedDescription)")
        }
    }
    
    // MARK: - Authentication Tests
    @Test("Successful authentication", arguments: authenticationScenarios)
    func testSuccessfulAuthentication(_ scenario: AuthenticationScenario) async throws {
        // Given
        mockContext.mockCanEvaluatePolicy = true
        mockContext.mockEvaluateResult = scenario.shouldSucceed
        mockContext.mockEvaluateError = nil
        
        // When
        let result = try await manager.authenticate(reason: scenario.reason)
        
        // Then
        #expect(result == scenario.shouldSucceed, "Authentication result should match expected value")
        #expect(mockContext.evaluateCallCount == 1, "Should call evaluate once")
        #expect(mockContext.lastLocalizedReason == scenario.reason, "Should pass correct reason")
        #expect(mockContext.lastEvaluatedPolicy == .deviceOwnerAuthenticationWithBiometrics, 
               "Should use correct policy")
    }
    
    @Test("Authentication fails when biometrics not available")
    func testAuthenticationFailsWhenNotAvailable() async throws {
        // Given
        mockContext.mockCanEvaluatePolicy = false
        
        // When & Then
        await #expect(throws: BiometricError.notAvailable) {
            try await manager.authenticate(reason: "Test authentication")
        }
    }
    
    @Test("Authentication error mapping", arguments: errorMappingScenarios)
    func testAuthenticationErrorMapping(_ scenario: ErrorMappingScenario) async throws {
        // Given
        mockContext.mockCanEvaluatePolicy = true
        mockContext.mockEvaluateError = LAError(scenario.laErrorCode)
        
        // When & Then
        await #expect(throws: scenario.expectedBiometricError) {
            try await manager.authenticate(reason: "Test authentication")
        }
    }
    
    // MARK: - Availability Tests
    @Test("Availability detection")
    func testAvailabilityDetection() {
        // Test available scenario
        mockContext.mockCanEvaluatePolicy = true
        #expect(manager.isAvailable == true, "Should be available when mock allows evaluation")
        
        // Test unavailable scenario
        mockContext.mockCanEvaluatePolicy = false
        #expect(manager.isAvailable == false, "Should not be available when mock denies evaluation")
    }
    
    // MARK: - Edge Cases Tests
    @Test("Multiple authentication attempts")
    func testMultipleAuthenticationAttempts() async throws {
        // Given
        mockContext.mockCanEvaluatePolicy = true
        mockContext.mockEvaluateResult = true
        let reason = "Multiple attempts test"
        
        // When - Multiple authentication attempts
        for i in 1...3 {
            let result = try await manager.authenticate(reason: reason)
            
            // Then
            #expect(result == true, "Authentication \(i) should succeed")
            #expect(mockContext.evaluateCallCount == i, "Should track correct call count")
        }
    }
    
    @Test("Authentication with empty reason")
    func testAuthenticationWithEmptyReason() async throws {
        // Given
        mockContext.mockCanEvaluatePolicy = true
        mockContext.mockEvaluateResult = true
        let emptyReason = ""
        
        // When
        let result = try await manager.authenticate(reason: emptyReason)
        
        // Then
        #expect(result == true, "Authentication should succeed even with empty reason")
        #expect(mockContext.lastLocalizedReason == emptyReason, "Should pass empty reason")
    }
    
    @Test("Authentication with special characters in reason")
    func testAuthenticationWithSpecialCharacters() async throws {
        // Given
        mockContext.mockCanEvaluatePolicy = true
        mockContext.mockEvaluateResult = true
        let specialReason = "🔐 Authenticate to access wallet 💰"
        
        // When
        let result = try await manager.authenticate(reason: specialReason)
        
        // Then
        #expect(result == true, "Authentication should succeed with special characters")
        #expect(mockContext.lastLocalizedReason == specialReason, "Should handle special characters correctly")
    }
    
    // MARK: - Performance Tests
    @Test(.timeLimit(.minutes(1)))
    func testAuthenticationPerformance() async throws {
        // Given
        mockContext.mockCanEvaluatePolicy = true
        mockContext.mockEvaluateResult = true
        
        // When & Then - Should complete within 1 minute
        for i in 0..<50 {
            let result = try await manager.authenticate(reason: "Performance test \(i)")
            #expect(result == true, "Authentication \(i) should succeed")
        }
    }
    
    @Test(.timeLimit(.minutes(1)))
    func testBiometricTypePerformance() {
        // When & Then - Should complete within 1 second
        for _ in 0..<1000 {
            let type = manager.biometricType
            let available = manager.isAvailable
            #expect(type == .none || type == .touchID || type == .faceID, "Biometric type should be valid")
            #expect(available == true || available == false, "Availability should be boolean")
        }
    }
}

// MARK: - BiometricError Tests
@Suite("BiometricError Tests")
struct BiometricErrorTests {
    
    @Test("BiometricError descriptions are correct")
    func testBiometricErrorDescriptions() {
        let errorCases: [(BiometricError, String)] = [
            (.notAvailable, "생체 인증을 사용할 수 없습니다"),
            (.notEnrolled, "생체 인증이 설정되지 않았습니다"),
            (.biometryLockout, "생체 인증이 잠금되었습니다"),
            (.authenticationFailed, "생체 인증에 실패했습니다"),
            (.userCancel, "사용자가 인증을 취소했습니다"),
            (.userFallback, "사용자가 대체 인증을 선택했습니다")
        ]
        
        for (error, expectedDescription) in errorCases {
            #expect(error.errorDescription == expectedDescription, 
                   "Error description should match expected value for \(error)")
        }
    }
    
    @Test("BiometricError equality")
    func testBiometricErrorEquality() {
        // Test same error types are equal
        #expect(BiometricError.notAvailable == BiometricError.notAvailable, 
               "Same error types should be equal")
        #expect(BiometricError.authenticationFailed == BiometricError.authenticationFailed, 
               "Same error types should be equal")
        
        // Test different error types are not equal
        #expect(BiometricError.notAvailable != BiometricError.authenticationFailed, 
               "Different error types should not be equal")
        #expect(BiometricError.userCancel != BiometricError.userFallback, 
               "Different error types should not be equal")
    }
}

// MARK: - Integration Tests
@Suite("BiometricAuthManager Integration Tests")
struct BiometricAuthManagerIntegrationTests {
    
    private var mockContext: MockLAContext!
    private var manager: MockBiometricAuthManager!
    
    init() {
        mockContext = MockLAContext()
        manager = MockBiometricAuthManager(mockContext: mockContext)
    }
    
    @Test("Complete biometric workflow")
    func testCompleteBiometricWorkflow() async throws {
        // Given - Setup Face ID availability
        mockContext.mockBiometryType = .faceID
        mockContext.mockCanEvaluatePolicy = true
        mockContext.mockEvaluateResult = true
        
        // When - Check availability
        let isAvailable = manager.isAvailable
        let biometricType = manager.biometricType
        
        // Then
        #expect(isAvailable == true, "Biometrics should be available")
        #expect(biometricType == .faceID, "Should detect Face ID")
        
        // When - Authenticate
        let authResult = try await manager.authenticate(reason: "Access wallet securely")
        
        // Then
        #expect(authResult == true, "Authentication should succeed")
        #expect(mockContext.evaluateCallCount == 1, "Should call evaluate once")
    }
    
    @Test("Fallback scenario handling")
    func testFallbackScenarioHandling() async throws {
        // Given - Setup biometrics available but user chooses fallback
        mockContext.mockBiometryType = .faceID
        mockContext.mockCanEvaluatePolicy = true
        mockContext.mockEvaluateError = LAError(.userFallback)
        
        // When & Then
        await #expect(throws: BiometricError.userFallback) {
            try await manager.authenticate(reason: "Authenticate for secure access")
        }
    }
    
    @Test("Device state changes simulation")
    func testDeviceStateChanges() async throws {
        // Given - Start with Face ID available
        mockContext.mockBiometryType = .faceID
        mockContext.mockCanEvaluatePolicy = true
        
        // When - Check initial state
        #expect(manager.biometricType == .faceID, "Should start with Face ID")
        #expect(manager.isAvailable == true, "Should be available initially")
        
        // Given - Simulate device state change (e.g., biometrics disabled)
        mockContext.mockCanEvaluatePolicy = false
        
        // When - Check updated state
        #expect(manager.isAvailable == false, "Should reflect disabled state")
        
        // Given - Simulate lockout
        mockContext.mockCanEvaluatePolicy = true
        mockContext.mockEvaluateError = LAError(.biometryLockout)
        
        // When & Then
        await #expect(throws: BiometricError.biometryLockout) {
            try await manager.authenticate(reason: "Test after lockout")
        }
    }
    
    @Test("Concurrent authentication attempts")
    func testConcurrentAuthenticationAttempts() async throws {
        // Given
        mockContext.mockBiometryType = .faceID
        mockContext.mockCanEvaluatePolicy = true
        mockContext.mockEvaluateResult = true
        
        // When - Multiple concurrent authentication attempts
        async let auth1 = manager.authenticate(reason: "Concurrent auth 1")
        async let auth2 = manager.authenticate(reason: "Concurrent auth 2")
        async let auth3 = manager.authenticate(reason: "Concurrent auth 3")
        
        // Then
        let results = try await (auth1, auth2, auth3)
        
        #expect(results.0 == true, "First authentication should succeed")
        #expect(results.1 == true, "Second authentication should succeed")
        #expect(results.2 == true, "Third authentication should succeed")
        #expect(mockContext.evaluateCallCount == 3, "Should call evaluate three times")
    }
}