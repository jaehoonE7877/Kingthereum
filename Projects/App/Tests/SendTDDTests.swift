import Testing
import Foundation
@testable import Kingthereum
@testable import DesignSystem

/// 진정한 TDD 방식으로 구현하는 송금 기능 테스트
@Suite("Send TDD Tests - Address and Balance Validation")
struct SendTDDTests {
    
    // MARK: - Address Validation Test Cases
    
    /// 주소 검증 테스트 시나리오 구조체
    struct AddressValidationScenario: Sendable, CustomStringConvertible {
        let address: String
        let isValid: Bool
        let description: String
        
        var description: String { description }
    }
    
    /// 주소 검증 테스트 케이스들
    static let addressValidationScenarios: [AddressValidationScenario] = [
        AddressValidationScenario(
            address: "0x742B15EcB8E3F6F7e7D58C4f9Ad2dBcEF8A5E9C3",
            isValid: true,
            description: "Valid Ethereum address"
        ),
        AddressValidationScenario(
            address: "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed",
            isValid: true,
            description: "Another valid Ethereum address"
        ),
        AddressValidationScenario(
            address: "invalid_address",
            isValid: false,
            description: "Invalid address format"
        ),
        AddressValidationScenario(
            address: "",
            isValid: false,
            description: "Empty address string"
        ),
        AddressValidationScenario(
            address: "0x123",
            isValid: false,
            description: "Short address (too short)"
        )
    ]
    
    /// 파라미터화된 주소 검증 테스트
    @Test("Address Validation", arguments: addressValidationScenarios)
    func validateAddress(scenario: AddressValidationScenario) {
        // Given - TDD RED 단계에서 구현될 AddressValidator
        let validator = AddressValidator()
        
        // When - 주소 검증 실행
        let result = validator.isValid(address: scenario.address)
        
        // Then - 예상 결과와 일치하는지 검증
        #expect(result == scenario.isValid, "Address validation failed for: \(scenario.description)")
    }
    
    // MARK: - Balance Validation Test Cases
    
    /// 잔액 검증 테스트 시나리오 구조체
    struct BalanceValidationScenario: Sendable, CustomStringConvertible {
        let currentBalance: Decimal
        let sendAmount: Decimal
        let gasFee: Decimal
        let isSufficient: Bool
        let description: String
        
        var description: String { description }
    }
    
    /// 잔액 검증 테스트 케이스들
    static let balanceValidationScenarios: [BalanceValidationScenario] = [
        BalanceValidationScenario(
            currentBalance: Decimal(2.0),
            sendAmount: Decimal(1.0),
            gasFee: Decimal(0.003),
            isSufficient: true,
            description: "Sufficient balance"
        ),
        BalanceValidationScenario(
            currentBalance: Decimal(1.0),
            sendAmount: Decimal(1.5),
            gasFee: Decimal(0.003),
            isSufficient: false,
            description: "Insufficient balance"
        ),
        BalanceValidationScenario(
            currentBalance: Decimal(1.003),
            sendAmount: Decimal(1.0),
            gasFee: Decimal(0.003),
            isSufficient: true,
            description: "Exact balance needed"
        )
    ]
    
    /// 파라미터화된 잔액 검증 테스트
    @Test("Balance Validation", arguments: balanceValidationScenarios)
    func validateBalance(scenario: BalanceValidationScenario) {
        // Given - 잔액 검증기 생성
        let validator = BalanceValidator(currentBalance: scenario.currentBalance)
        
        // When - 잔액 충족 여부 검사
        let result = validator.isSufficient(amount: scenario.sendAmount, gasFee: scenario.gasFee)
        
        // Then - 예상 결과와 일치하는지 검증
        #expect(result == scenario.isSufficient, "Balance validation failed for: \(scenario.description)")
    }
}

// MARK: - TDD 구현체 (최소한의 인터페이스 정의)

/// 주소 검증을 위한 최소한의 인터페이스 (TDD GREEN 단계에서 구현)
class AddressValidator {
    func isValid(address: String) -> Bool {
        // REFACTOR 단계: 실제 이더리움 주소 검증 로직 구현
        return isValidEthereumAddress(address)
    }
    
    private func isValidEthereumAddress(_ address: String) -> Bool {
        // 기본 검증: 빈 문자열 체크
        guard !address.isEmpty else { return false }
        
        // 0x 접두사 체크
        guard address.hasPrefix("0x") else { return false }
        
        // 길이 체크 (0x + 40자 = 42자)
        guard address.count == 42 else { return false }
        
        // 16진수 문자만 포함하는지 체크
        let hexPart = String(address.dropFirst(2)) // 0x 제거
        let hexCharacterSet = CharacterSet(charactersIn: "0123456789abcdefABCDEF")
        return hexPart.unicodeScalars.allSatisfy { hexCharacterSet.contains($0) }
    }
}

/// 잔액 검증을 위한 최소한의 인터페이스 (TDD GREEN 단계에서 구현)
class BalanceValidator {
    private let currentBalance: Decimal
    
    init(currentBalance: Decimal) {
        self.currentBalance = currentBalance
    }
    
    func isSufficient(amount: Decimal, gasFee: Decimal) -> Bool {
        let totalRequired = amount + gasFee
        return currentBalance >= totalRequired
    }
}