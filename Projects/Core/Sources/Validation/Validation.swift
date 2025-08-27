import Foundation

/// 폼 필드 검증 결과를 나타내는 구조체
public struct Validation {
    public let isValid: Bool
    public let message: String?
    
    public init(isValid: Bool, message: String? = nil) {
        self.isValid = isValid
        self.message = message
    }
    
    /// 성공 케이스
    public static let valid = Validation(isValid: true)
    
    /// 실패 케이스 생성
    public static func invalid(_ message: String) -> Validation {
        Validation(isValid: false, message: message)
    }
}

/// 검증 규칙을 정의하는 프로토콜
public protocol ValidationRule {
    func validate(_ value: String) -> Validation
}

/// 이더리움 주소 검증 규칙
public struct EthereumAddressValidationRule: ValidationRule {
    public init() {}
    
    public func validate(_ value: String) -> Validation {
        guard !value.isEmpty else {
            return .invalid("주소를 입력해주세요")
        }
        
        guard value.hasPrefix("0x") else {
            return .invalid("주소는 0x로 시작해야 합니다")
        }
        
        guard value.count == 42 else {
            return .invalid("주소는 42자여야 합니다")
        }
        
        let hexPattern = "^0x[a-fA-F0-9]{40}$"
        let regex = try? NSRegularExpression(pattern: hexPattern)
        let range = NSRange(location: 0, length: value.count)
        
        guard regex?.firstMatch(in: value, options: [], range: range) != nil else {
            return .invalid("올바른 주소 형식이 아닙니다")
        }
        
        return .valid
    }
}

/// 금액 검증 규칙
public struct AmountValidationRule: ValidationRule {
    private let balance: Double
    private let minimumAmount: Double
    
    public init(balance: Double, minimumAmount: Double = 0.0001) {
        self.balance = balance
        self.minimumAmount = minimumAmount
    }
    
    public func validate(_ value: String) -> Validation {
        guard !value.isEmpty else {
            return .invalid("금액을 입력해주세요")
        }
        
        guard let amount = Double(value) else {
            return .invalid("올바른 숫자를 입력해주세요")
        }
        
        guard amount > 0 else {
            return .invalid("0보다 큰 금액을 입력해주세요")
        }
        
        guard amount >= minimumAmount else {
            return .invalid("최소 금액은 \(minimumAmount) ETH입니다")
        }
        
        guard amount <= balance else {
            return .invalid("잔액이 부족합니다")
        }
        
        return .valid
    }
}

/// PIN 검증 규칙
public struct PINValidationRule: ValidationRule {
    public init() {}
    
    public func validate(_ value: String) -> Validation {
        guard !value.isEmpty else {
            return .invalid("PIN을 입력해주세요")
        }
        
        guard value.count == 6 else {
            return .invalid("PIN은 6자리여야 합니다")
        }
        
        guard value.allSatisfy({ $0.isNumber }) else {
            return .invalid("PIN은 숫자만 입력 가능합니다")
        }
        
        return .valid
    }
}

/// 여러 규칙을 조합하는 검증기
public struct FormValidator {
    private let rules: [ValidationRule]
    
    public init(rules: [ValidationRule]) {
        self.rules = rules
    }
    
    public func validate(_ value: String) -> Validation {
        for rule in rules {
            let result = rule.validate(value)
            if !result.isValid {
                return result
            }
        }
        return .valid
    }
}

// MARK: - String Extensions
public extension String {
    /// 이더리움 주소 유효성 검증
    var isValidEthereumAddress: Bool {
        EthereumAddressValidationRule().validate(self).isValid
    }
    
    /// PIN 유효성 검증
    var isValidPIN: Bool {
        PINValidationRule().validate(self).isValid
    }
    
    /// 금액 유효성 검증
    func isValidAmount(balance: Double) -> Bool {
        AmountValidationRule(balance: balance).validate(self).isValid
    }
}