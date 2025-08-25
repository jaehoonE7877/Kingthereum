# Kingthereum iOS Testing Guide

## Overview

Kingthereum iOS 앱은 **Swift Testing framework** (iOS 17+, Xcode 16+)를 사용하여 포괄적인 단위 테스트를 구현했습니다. 이 문서는 테스트 아키텍처, 실행 방법, 그리고 주요 기능에 대한 가이드를 제공합니다.

## Testing Architecture

### 📁 Project Structure

```
Kingthereum/
├── Projects/
│   ├── Core/
│   │   ├── Sources/
│   │   └── Tests/
│   │       ├── ModelTests.swift
│   │       └── FormatterTests.swift
│   ├── SecurityKit/
│   │   ├── Sources/
│   │   └── Tests/
│   │       ├── BiometricAuthManagerTests.swift
│   │       └── KeychainManagerTests.swift
│   ├── WalletKit/
│   │   ├── Sources/
│   │   └── Tests/
│   │       ├── EthereumWorkerTests.swift
│   │       ├── TokenWorkerTests.swift
│   │       └── WalletServiceTests.swift
│   └── DesignSystem/
├── Scripts/
│   └── run_tests.sh
└── TESTING.md
```

### 🏗️ Test Modules

| Module | Purpose | Test Coverage |
|--------|---------|---------------|
| **Core** | 기본 모델 및 유틸리티 | Models, Formatters, Extensions |
| **SecurityKit** | 보안 기능 | Biometric Auth, Keychain Management |
| **WalletKit** | 블록체인 인터페이스 | Ethereum, Tokens, Wallet Service |

## Swift Testing Features

### 🎯 Parameterized Testing

```swift
@Test("Email validation", arguments: [
    ("valid@email.com", true),
    ("invalid", false),
    ("@domain.com", false)
])
func testEmailValidation(email: String, isValid: Bool) {
    #expect(validateEmail(email) == isValid)
}
```

### ⏱️ Performance Testing

```swift
@Test(.timeLimit(.seconds(5)))
func testWalletServicePerformance() async throws {
    // 5초 내에 완료되어야 하는 성능 테스트
    for _ in 0..<1000 {
        let balance = try await service.getWalletBalance(address: address)
        #expect(!balance.isEmpty)
    }
}
```

### 🔄 Async/Await Testing

```swift
@Test("Async wallet balance retrieval")
func testGetWalletBalance() async throws {
    // Given
    let address = "0x742d35Cc6627C8532b9b92a3d43F1f12f2CaF8B5"
    
    // When
    let balance = try await ethereumWorker.getBalance(for: address)
    
    // Then
    #expect(!balance.isEmpty)
    #expect(BigUInt(balance) != nil)
}
```

### 🏷️ Test Organization

```swift
@Suite("EthereumWorker Tests")
struct EthereumWorkerTests {
    
    @Test("Balance retrieval tests", arguments: validAddresses)
    func testGetBalance(_ scenario: AddressTestScenario) async throws {
        // Test implementation
    }
}
```

## Module-Specific Testing

### 🔒 SecurityKit Tests

#### BiometricAuthManager Tests
- **기능**: Face ID, Touch ID, Optic ID 인증
- **테스트 범위**:
  - 생체인증 타입 감지
  - 인증 성공/실패 시나리오
  - 에러 매핑 (LAError → BiometricError)
  - 장치 상태 변화 시뮬레이션

```swift
@Test("Biometric authentication success")
func testSuccessfulAuthentication() async throws {
    // Given
    mockContext.mockCanEvaluatePolicy = true
    mockContext.mockEvaluateResult = true
    
    // When
    let result = try await manager.authenticate(reason: "Access wallet")
    
    // Then
    #expect(result == true)
}
```

#### KeychainManager Tests
- **기능**: 안전한 키체인 저장/조회
- **테스트 범위**:
  - 기본 CRUD 작업
  - 지갑별 확장 기능 (Private Key, Mnemonic, PIN)
  - 에러 처리 및 복구
  - 동시성 테스트

### 💰 WalletKit Tests

#### EthereumWorker Tests
- **기능**: 이더리움 블록체인 상호작용
- **테스트 범위**:
  - 잔액 조회
  - 트랜잭션 전송
  - 가스 추정
  - 트랜잭션 영수증 조회
  - 네트워크 에러 처리

#### TokenWorker Tests
- **기능**: ERC-20 토큰 관리
- **테스트 범위**:
  - 토큰 잔액 조회
  - 토큰 정보 (name, symbol, decimals)
  - 토큰 전송
  - 병렬 토큰 작업

#### WalletService Tests
- **기능**: 지갑 서비스 통합
- **테스트 범위**:
  - 지갑 생성/가져오기
  - 포트폴리오 관리
  - 트랜잭션 히스토리
  - 통합 워크플로우

### 📊 Core Tests

#### Model Tests
- **Wallet, Transaction, Token, Network 모델**
- **테스트 범위**:
  - 모델 초기화 및 속성
  - Equatable 및 Codable 준수
  - 엣지 케이스 처리
  - 통합 시나리오

#### Formatter Tests
- **다양한 포맷터 유틸리티**
- **테스트 범위**:
  - ETH 값 포맷팅
  - 통화 포맷팅
  - 주소 단축
  - 날짜/시간 포맷팅
  - 성능 테스트

## Mock Objects & Test Doubles

### 🎭 Mocking Strategy

각 모듈은 외부 의존성을 격리하기 위해 포괄적인 Mock 객체를 사용합니다:

#### EthereumWorker Mock
```swift
final class MockEthereumWorker: EthereumWorkerProtocol {
    private var mockBalance = "1000000000000000000"
    private var shouldFailRequests = false
    
    func getBalance(for address: String) async throws -> String {
        guard !shouldFailRequests else {
            throw WalletError.networkError("Mock network error")
        }
        return mockBalance
    }
}
```

#### BiometricAuth Mock
```swift
final class MockLAContext: LAContext {
    var mockBiometryType: LABiometryType = .faceID
    var mockCanEvaluatePolicy = true
    var mockEvaluateError: LAError?
    
    override func evaluatePolicy(_ policy: LAPolicy, localizedReason: String) async throws -> Bool {
        if let error = mockEvaluateError { throw error }
        return true
    }
}
```

## Running Tests

### 🚀 Quick Start

```bash
# 모든 테스트 실행
./Scripts/run_tests.sh

# 특정 모듈 테스트
xcodebuild test -workspace Kingthereum.xcworkspace -scheme CoreTests
xcodebuild test -workspace Kingthereum.xcworkspace -scheme SecurityKitTests
xcodebuild test -workspace Kingthereum.xcworkspace -scheme WalletKitTests
```

### 📋 Prerequisites

- **Xcode 16+** (Swift Testing 지원)
- **iOS 17+ Simulator**
- **Tuist** (프로젝트 생성)

### 🔧 Test Configuration

테스트는 다음 설정으로 실행됩니다:

```swift
// Tuist Project Settings
let testSettings: SettingsDictionary = [
    "ENABLE_TESTING_SEARCH_PATHS": "YES",
    "SWIFT_TESTING": "YES",
    "ENABLE_SWIFT_TESTING": "YES"
]
```

## Test Patterns & Best Practices

### 📝 Given-When-Then Pattern

모든 테스트는 명확한 3단계 구조를 따릅니다:

```swift
@Test("Wallet creation succeeds")
func testCreateWallet() async throws {
    // Given - 테스트 전제조건 설정
    let walletName = "Test Wallet"
    
    // When - 테스트할 동작 실행
    let wallet = try await service.createWallet(name: walletName)
    
    // Then - 결과 검증
    #expect(wallet.name == walletName)
    #expect(!wallet.address.isEmpty)
}
```

### 🔄 Async Testing

```swift
@Test("Concurrent operations")
func testConcurrentOperations() async throws {
    async let balance = service.getBalance(address: address)
    async let gasPrice = service.getCurrentGasPrice()
    async let history = service.getTransactionHistory(address: address)
    
    let results = try await (balance, gasPrice, history)
    
    #expect(!results.0.isEmpty)
    #expect(!results.1.isEmpty)
    #expect(results.2.count >= 0)
}
```

### 🎯 Error Testing

```swift
@Test("Network error handling")
func testNetworkError() async throws {
    // Given
    mockWorker.setFailureMode(true, error: .networkError("Connection timeout"))
    
    // When & Then
    await #expect(throws: WalletError.networkError) {
        try await worker.getBalance(for: address)
    }
}
```

### 📊 Performance Testing

```swift
@Test(.timeLimit(.seconds(5)))
func testPerformance() async throws {
    for i in 0..<1000 {
        let result = try await heavyOperation(input: i)
        #expect(!result.isEmpty)
    }
}
```

## Test Data Management

### 🗂️ Test Scenarios

구조화된 테스트 데이터를 사용하여 다양한 시나리오를 테스트합니다:

```swift
struct WalletTestScenario: Sendable, CustomStringConvertible {
    let name: String
    let walletName: String
    let address: String
    let shouldSucceed: Bool
    
    var description: String { name }
}

private static let walletScenarios = [
    WalletTestScenario(
        name: "Valid wallet creation",
        walletName: "My Wallet",
        address: "0x742d35Cc6627C8532b9b92a3d43F1f12f2CaF8B5",
        shouldSucceed: true
    ),
    // More scenarios...
]
```

## Coverage & Reporting

### 📈 Test Coverage

- **Core Module**: 모델 및 유틸리티 완전 커버리지
- **SecurityKit**: 보안 기능 포괄적 테스트
- **WalletKit**: 블록체인 상호작용 핵심 기능

### 📊 Reports

테스트 실행 후 다음 리포트가 생성됩니다:

```
TestResults/
├── CoreTests.xcresult
├── SecurityKitTests.xcresult
├── WalletKitTests.xcresult
├── test_report.md
└── coverage_report.json
```

## Integration Testing

### 🔗 End-to-End Workflows

```swift
@Test("Complete wallet workflow")
func testCompleteWalletWorkflow() async throws {
    // 1. Create wallet
    let wallet = try await service.createWallet(name: "Integration Test")
    
    // 2. Get balance
    let balance = try await service.getWalletBalance(address: wallet.address)
    
    // 3. Get token balances
    let tokens = try await service.getTokenBalances(address: wallet.address, tokenAddresses: contracts)
    
    // 4. Verify complete portfolio
    #expect(!balance.isEmpty)
    #expect(tokens.count > 0)
}
```

## Continuous Integration

### 🔄 CI/CD Integration

```yaml
# GitHub Actions example
- name: Run Swift Tests
  run: |
    ./Scripts/run_tests.sh
    
- name: Upload Test Results
  uses: actions/upload-artifact@v3
  with:
    name: test-results
    path: TestResults/
```

## Troubleshooting

### 🔧 Common Issues

1. **Xcode Version**: Swift Testing requires Xcode 16+
2. **Simulator**: Ensure iOS 17+ simulator is available
3. **Dependencies**: Run `tuist generate` if workspace is missing
4. **Permissions**: Ensure test script is executable

### 🆘 Debug Commands

```bash
# Check Xcode version
xcodebuild -version

# List available simulators
xcrun simctl list devices

# Clean build
xcodebuild clean -workspace Kingthereum.xcworkspace

# Regenerate project
tuist clean && tuist generate
```

## Future Enhancements

### 🚀 Roadmap

- [ ] UI Testing with XCUITest
- [ ] Snapshot Testing for SwiftUI views
- [ ] Network Integration Testing
- [ ] Performance Benchmarking
- [ ] Automated Test Generation

## Contributing

### 📝 Guidelines

1. **Test Naming**: 명확하고 설명적인 테스트 이름 사용
2. **Mock Objects**: 외부 의존성은 항상 Mock 사용
3. **Edge Cases**: 정상 케이스와 에러 케이스 모두 테스트
4. **Documentation**: 복잡한 테스트 로직은 주석으로 설명
5. **Performance**: 성능에 민감한 테스트는 시간 제한 설정

---

## 📞 Support

테스트 관련 문의사항이나 이슈가 있으시면 프로젝트 이슈 트래커를 통해 문의해주세요.

**Happy Testing! 🧪✅**