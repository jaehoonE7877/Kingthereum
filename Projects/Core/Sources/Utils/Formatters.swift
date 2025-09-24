import Foundation

/// 일관된 데이터 표시를 위한 포맷터 유틸리티
/// 
/// 앱 전반에서 사용하는 다양한 데이터 타입의 표시 형식을 통일합니다.
/// 모든 포맷터는 지연 초기화되며, 스레드 안전하게 사용할 수 있습니다.
/// 
/// ## 포맷터 종류:
/// - 숫자: 통화, 소수, 백분율
/// - 날짜: 짧은 형식, 상세 형식
/// - 블록체인: 이더 값, 주소, 해시
public enum Formatters {
    
    // MARK: - Shared Formatters
    
    private static let posixLocale = Locale(identifier: "en_US_POSIX")
    private static let currencyLocale = Locale(identifier: "en_US")
private static let smallEthThreshold: Decimal = Decimal(string: "0.000001") ?? Decimal(sign: .plus, exponent: -6, significand: 1)
private static let mediumEthThreshold: Decimal = Decimal(string: "0.001") ?? Decimal(sign: .plus, exponent: -3, significand: 1)
    
    /// 통화 표시용 포맷터 (USD 기준)
    /// 
    /// 암호화폐의 법정화폐 환산 가치를 표시할 때 사용합니다.
    /// 소수점 둘째 자리까지 표시하며, 통화 기호($)를 포함합니다.
    /// 
    /// ## 출력 예시: $1,234.56
    public static let currency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = posixLocale
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()
    
    /// 일반 소수 표시용 포맷터
    /// 
    /// 암호화폐 수량이나 기술적 수치를 표시할 때 사용합니다.
    /// 최대 6자리까지 소수점을 표시하며, 불필요한 0은 생략합니다.
    /// 
    /// ## 출력 예시: 1,234.123456
    public static let decimal: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = posixLocale
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 6
        formatter.minimumFractionDigits = 0
        formatter.usesGroupingSeparator = true
        return formatter
    }()
    
    /// 백분율 표시용 포맷터
    /// 
    /// 가격 변동률이나 진행률을 표시할 때 사용합니다.
    /// 소수점 둘째 자리까지 표시하며, % 기호를 포함합니다.
    /// 
    /// ## 출력 예시: 12.34%
    public static let percentage: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = posixLocale
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter
    }()
    
    // MARK: - Date Formatters
    
    /// 날짜와 시간을 모두 포함하는 포맷터
    /// 
    /// 트랜잭션 시간이나 이벤트 발생 시점을 상세히 표시할 때 사용합니다.
    /// 사용자의 로케일에 따라 적절한 형식으로 표시됩니다.
    /// 
    /// ## 출력 예시: 2024년 1월 15일 오후 2:30
    public static let dateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    /// 날짜만 표시하는 간단한 포맷터
    /// 
    /// 리스트나 요약 화면에서 공간을 절약하며 날짜를 표시할 때 사용합니다.
    /// 
    /// ## 출력 예시: 2024. 1. 15.
    public static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    // MARK: - Blockchain-Specific Formatters
    
    /// 이더 값을 사용자 친화적으로 포맷팅
    /// 
    /// Wei 단위의 큰 숫자를 Ether 단위로 변환하고 적절한 정밀도로 표시합니다.
    /// 값의 크기에 따라 동적으로 소수점 자릿수를 조정합니다.
    /// 
    /// - Parameters:
    ///   - value: Wei 단위의 문자열 값
    ///   - decimals: 토큰의 소수점 자릿수 (기본값: 18, 이더리움 표준)
    /// - Returns: 포맷팅된 이더 값 문자열
    /// 
    /// ## 포맷팅 규칙:
    /// - 0.001 미만: 6자리 소수점 (0.000123)
    /// - 0.001 ~ 1: 4자리 소수점 (0.1234)
    /// - 1 이상: 2자리 소수점 (12.34)
    /// 
    /// ## 사용 예시:
    /// ```swift
    /// let formatted = Formatters.formatEthValue("1234567890123456789") // "1.23"
    /// ```
    public static func formatEthValue(_ value: String, decimals: Int = 18) -> String {
        guard !value.isEmpty,
              value.unicodeScalars.allSatisfy({ CharacterSet.decimalDigits.contains($0) })
        else { return "0.0" }
        guard let weiAmount = Decimal(string: value), weiAmount >= 0 else { return "0.0" }
        let normalizedDecimals = max(0, decimals)
        let divisor = decimalPower(of: normalizedDecimals)
        guard divisor != 0 else { return "0.0" }
        let ethAmount = weiAmount / divisor
        if ethAmount == 0 { return "0.0" }
        let absEth = ethAmount.magnitude

        let numberFormatter = NumberFormatter()
        numberFormatter.locale = posixLocale
        numberFormatter.numberStyle = .decimal
        numberFormatter.usesGroupingSeparator = false
        let decimalNumber = NSDecimalNumber(decimal: ethAmount)

        if absEth < smallEthThreshold {
            let scientificFormatter = NumberFormatter()
            scientificFormatter.locale = posixLocale
            scientificFormatter.numberStyle = .scientific
            scientificFormatter.exponentSymbol = "e"
            scientificFormatter.minimumSignificantDigits = 1
            scientificFormatter.maximumSignificantDigits = min(max(normalizedDecimals, 6), 18)
            let scientific = scientificFormatter.string(from: decimalNumber) ?? decimalNumber.stringValue
            return scientific.replacingOccurrences(of: "E", with: "e")
        } else if absEth < mediumEthThreshold {
            let maxFractionDigits = min(max(normalizedDecimals, 6), 18)
            numberFormatter.minimumFractionDigits = 1
            numberFormatter.maximumFractionDigits = maxFractionDigits
        } else if absEth < 1 {
            numberFormatter.minimumFractionDigits = 1
            numberFormatter.maximumFractionDigits = 4
        } else {
            numberFormatter.minimumFractionDigits = 1
            numberFormatter.maximumFractionDigits = 2
        }

        if let formatted = numberFormatter.string(from: decimalNumber) {
            return trimTrailingZeros(formatted)
        }
        return decimalNumber.stringValue
    }

    /// 법정화폐 금액을 통화 코드에 맞춰 포맷팅합니다.
    public static func formatCurrency(_ value: Double, currency: String) -> String {
        guard value.isFinite else { return "\(currency.uppercased()) --" }
        let uppercaseCurrency = currency.uppercased()
        let decimalFormatter = NumberFormatter()
        decimalFormatter.locale = currencyLocale
        decimalFormatter.numberStyle = .decimal
        decimalFormatter.minimumFractionDigits = 2
        decimalFormatter.maximumFractionDigits = 2
        let numeric = decimalFormatter.string(from: NSNumber(value: value))
            ?? String(format: "%.2f", locale: posixLocale, value)
        let groupingSeparator = decimalFormatter.groupingSeparator ?? ","
        let sanitizedNumeric = (uppercaseCurrency == "USD" || uppercaseCurrency == "EUR" || uppercaseCurrency == "GBP")
            ? numeric
            : numeric.replacingOccurrences(of: groupingSeparator, with: "")

        switch uppercaseCurrency {
        case "USD":
            return "$\(numeric)"
        case "EUR":
            return "€\(numeric)"
        case "GBP":
            return "£\(numeric)"
        default:
            return "\(uppercaseCurrency) \(sanitizedNumeric)"
        }
    }

    /// 백분율 값을 문자열로 변환합니다.
    public static func formatPercentage(_ value: Double, decimalPlaces: Int) -> String {
        guard value.isFinite else { return "--%" }
        let clamped = max(0, min(decimalPlaces, 6))
        let formatter = NumberFormatter()
        formatter.locale = posixLocale
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = clamped
        formatter.maximumFractionDigits = clamped
        let formatted = formatter.string(from: NSNumber(value: value * 100)) ?? "0"
        return "\(formatted)%"
    }

    /// 이더리움 주소를 축약형으로 포맷팅합니다.
    public static func shortenAddress(_ address: String, prefixLength: Int = 6, suffixLength: Int = 4) -> String {
        guard address.count > prefixLength + suffixLength else { return address }
        let start = address.prefix(prefixLength)
        let end = address.suffix(suffixLength)
        return "\(start)...\(end)"
    }

    /// 주소 유효성을 검증합니다.
    public static func isValidEthereumAddress(_ address: String) -> Bool {
        guard address.hasPrefix("0x"), address.count == 42 else { return false }
        let hexPart = address.dropFirst(2)
        guard !hexPart.isEmpty else { return false }
        let hexSet = CharacterSet(charactersIn: "0123456789abcdefABCDEF")
        if hexPart.unicodeScalars.allSatisfy({ hexSet.contains($0) }) {
            return true
        }
        return hexPart.unicodeScalars.allSatisfy { CharacterSet.alphanumerics.contains($0) }
    }

    /// 날짜를 지정된 스타일로 포맷팅합니다.
    public static func formatDate(_ date: Date, style: DateFormatter.Style) -> String {
        let formatter = DateFormatter()
        formatter.locale = posixLocale
        formatter.dateStyle = style
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    /// 상대 시간을 인간 친화적 표현으로 변환합니다.
    public static func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = posixLocale
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    /// 큰 숫자를 K/M/B 접미사를 사용한 문자열로 변환합니다.
    public static func formatLargeNumber(_ number: Double) -> String {
        let absNumber = abs(number)
        let sign = number < 0 ? "-" : ""
        switch absNumber {
        case let value where value >= 1_000_000_000:
            let formatted = String(format: "%.1f", locale: posixLocale, value / 1_000_000_000)
            return "\(sign)\(formatted)B"
        case let value where value >= 1_000_000:
            let formatted = String(format: "%.1f", locale: posixLocale, value / 1_000_000)
            return "\(sign)\(formatted)M"
        case let value where value >= 1_000:
            let formatted = String(format: "%.1f", locale: posixLocale, value / 1_000)
            return "\(sign)\(formatted)K"
        default:
            let formatted = String(format: "%.0f", locale: posixLocale, absNumber)
            return "\(sign)\(formatted)"
        }
    }

    /// 주어진 정밀도로 소수를 포맷팅합니다.
    public static func formatDecimal(_ number: Double, precision: Int) -> String {
        guard number.isFinite else { return "0" }
        let clampedPrecision = max(0, min(precision, 10))
        let formatter = NumberFormatter()
        formatter.locale = posixLocale
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = clampedPrecision
        formatter.maximumFractionDigits = clampedPrecision
        if let formatted = formatter.string(from: NSNumber(value: number)) {
            return formatted
        }
        return String(format: "%.*f", locale: posixLocale, clampedPrecision, number)
    }

    /// 해시 값을 축약형으로 포맷팅합니다.
    public static func shortenHash(_ hash: String, prefixLength: Int = 6, suffixLength: Int = 4) -> String {
        guard hash.count > prefixLength + suffixLength else { return hash }
        let prefix = hash.prefix(prefixLength)
        let suffix = hash.suffix(suffixLength)
        return "\(prefix)...\(suffix)"
    }
    
    /// 이더리움 주소를 축약된 형태로 포맷팅
    /// 
    /// 긴 주소를 UI에 표시할 때 가독성을 위해 중간 부분을 생략합니다.
    /// 앞뒤의 일정 길이만 표시하여 주소를 식별 가능하게 유지합니다.
    /// 
    /// - Parameters:
    ///   - address: 원본 이더리움 주소
    ///   - length: 앞뒤에 표시할 문자 개수 (기본값: 6)
    /// - Returns: 축약된 주소 문자열
    /// 
    /// ## 사용 예시:
    /// ```swift
    /// let short = Formatters.formatAddress("0x1234567890abcdef...") // "0x1234...cdef"
    /// ```
    public static func formatAddress(_ address: String, length: Int = 6) -> String {
        return shortenAddress(address, prefixLength: length, suffixLength: length)
    }
    
    /// 트랜잭션 해시를 축약된 형태로 포맷팅
    /// 
    /// 긴 해시값을 UI에 표시할 때 공간을 절약하며 식별 가능하게 표시합니다.
    /// 주로 트랜잭션 목록이나 상태 표시에서 사용됩니다.
    /// 
    /// - Parameters:
    ///   - hash: 원본 해시값
    ///   - length: 표시할 앞부분 문자 개수 (기본값: 8)
    /// - Returns: 축약된 해시 문자열
    /// 
    /// ## 사용 예시:
    /// ```swift
    /// let short = Formatters.formatHash("0xabcdef123456...") // "0xabcdef..."
    /// ```
    public static func formatHash(_ hash: String, length: Int = 8) -> String {
        return shortenHash(hash, prefixLength: length, suffixLength: length)
    }

    // MARK: - Helpers
    private static func decimalPower(of exponent: Int) -> Decimal {
        guard exponent > 0 else { return 1 }
        var result: Decimal = 1
        for _ in 0..<exponent {
            result *= 10
        }
        return result
    }

    private static func trimTrailingZeros(_ value: String) -> String {
        guard value.contains(".") else { return value }
        var trimmed = value
        while trimmed.last == "0" {
            trimmed.removeLast()
        }
        if trimmed.last == "." {
            trimmed.append("0")
        }
        return trimmed
    }
}
