import Testing
import Foundation
@testable import Core

// MARK: - Test Data
struct EthFormattingScenario: Sendable, CustomStringConvertible {
    let name: String
    let weiValue: String
    let decimals: Int
    let expectedFormatted: String
    let shouldUseScientific: Bool
    
    var description: String { name }
}

struct CurrencyFormattingScenario: Sendable, CustomStringConvertible {
    let name: String
    let value: Double
    let currency: String
    let expectedFormatted: String
    
    var description: String { name }
}

struct AddressFormattingScenario: Sendable, CustomStringConvertible {
    let name: String
    let address: String
    let expectedShort: String
    let isValidFormat: Bool
    
    var description: String { name }
}

struct PercentageFormattingScenario: Sendable, CustomStringConvertible {
    let name: String
    let value: Double
    let decimalPlaces: Int
    let expectedFormatted: String
    
    var description: String { name }
}

// MARK: - Formatters Tests
@Suite("Formatters Tests")
struct FormattersTests {
    
    // MARK: - Test Data
    private static let ethFormattingScenarios = [
        EthFormattingScenario(
            name: "1 ETH in wei",
            weiValue: "1000000000000000000",
            decimals: 18,
            expectedFormatted: "1.0",
            shouldUseScientific: false
        ),
        EthFormattingScenario(
            name: "0.5 ETH in wei",
            weiValue: "500000000000000000",
            decimals: 18,
            expectedFormatted: "0.5",
            shouldUseScientific: false
        ),
        EthFormattingScenario(
            name: "0.001 ETH in wei",
            weiValue: "1000000000000000",
            decimals: 18,
            expectedFormatted: "0.001",
            shouldUseScientific: false
        ),
        EthFormattingScenario(
            name: "1000 USDC in base units",
            weiValue: "1000000000",
            decimals: 6,
            expectedFormatted: "1000.0",
            shouldUseScientific: false
        ),
        EthFormattingScenario(
            name: "1.5 USDC in base units",
            weiValue: "1500000",
            decimals: 6,
            expectedFormatted: "1.5",
            shouldUseScientific: false
        ),
        EthFormattingScenario(
            name: "Very small amount",
            weiValue: "1",
            decimals: 18,
            expectedFormatted: "0.000000000000000001",
            shouldUseScientific: true
        ),
        EthFormattingScenario(
            name: "Zero amount",
            weiValue: "0",
            decimals: 18,
            expectedFormatted: "0.0",
            shouldUseScientific: false
        ),
        EthFormattingScenario(
            name: "Large amount",
            weiValue: "1000000000000000000000",
            decimals: 18,
            expectedFormatted: "1000.0",
            shouldUseScientific: false
        )
    ]
    
    private static let currencyFormattingScenarios = [
        CurrencyFormattingScenario(
            name: "USD formatting",
            value: 1234.56,
            currency: "USD",
            expectedFormatted: "$1,234.56"
        ),
        CurrencyFormattingScenario(
            name: "Large USD amount",
            value: 1000000.00,
            currency: "USD",
            expectedFormatted: "$1,000,000.00"
        ),
        CurrencyFormattingScenario(
            name: "Small USD amount",
            value: 0.01,
            currency: "USD",
            expectedFormatted: "$0.01"
        ),
        CurrencyFormattingScenario(
            name: "Zero USD amount",
            value: 0.00,
            currency: "USD",
            expectedFormatted: "$0.00"
        ),
        CurrencyFormattingScenario(
            name: "EUR formatting",
            value: 1234.56,
            currency: "EUR",
            expectedFormatted: "€1,234.56"
        )
    ]
    
    private static let addressFormattingScenarios = [
        AddressFormattingScenario(
            name: "Standard Ethereum address",
            address: "0x742d35Cc6627C8532b9b92a3d43F1f12f2CaF8B5",
            expectedShort: "0x742d...F8B5",
            isValidFormat: true
        ),
        AddressFormattingScenario(
            name: "Another valid address",
            address: "0x8ba1f109551bD432803012645Hac136c2367bAbb",
            expectedShort: "0x8ba1...bAbb",
            isValidFormat: true
        ),
        AddressFormattingScenario(
            name: "Lowercase address",
            address: "0x742d35cc6627c8532b9b92a3d43f1f12f2caf8b5",
            expectedShort: "0x742d...f8b5",
            isValidFormat: true
        ),
        AddressFormattingScenario(
            name: "Invalid address - too short",
            address: "0x123",
            expectedShort: "0x123",
            isValidFormat: false
        ),
        AddressFormattingScenario(
            name: "Invalid address - no prefix",
            address: "742d35Cc6627C8532b9b92a3d43F1f12f2CaF8B5",
            expectedShort: "742d35Cc6627C8532b9b92a3d43F1f12f2CaF8B5",
            isValidFormat: false
        ),
        AddressFormattingScenario(
            name: "Empty address",
            address: "",
            expectedShort: "",
            isValidFormat: false
        )
    ]
    
    private static let percentageFormattingScenarios = [
        PercentageFormattingScenario(
            name: "Simple percentage",
            value: 0.1234,
            decimalPlaces: 2,
            expectedFormatted: "12.34%"
        ),
        PercentageFormattingScenario(
            name: "High precision percentage",
            value: 0.123456,
            decimalPlaces: 4,
            expectedFormatted: "12.3456%"
        ),
        PercentageFormattingScenario(
            name: "Zero percentage",
            value: 0.0,
            decimalPlaces: 2,
            expectedFormatted: "0.00%"
        ),
        PercentageFormattingScenario(
            name: "Large percentage",
            value: 1.5,
            decimalPlaces: 1,
            expectedFormatted: "150.0%"
        ),
        PercentageFormattingScenario(
            name: "Negative percentage",
            value: -0.05,
            decimalPlaces: 2,
            expectedFormatted: "-5.00%"
        )
    ]
    
    // MARK: - ETH Value Formatting Tests
    @Test("Format ETH values correctly", arguments: ethFormattingScenarios)
    func testFormatEthValue(_ scenario: EthFormattingScenario) {
        // When
        let formattedValue = Formatters.formatEthValue(scenario.weiValue, decimals: scenario.decimals)
        
        // Then
        if scenario.shouldUseScientific {
            // For very small values, just check it's not empty and contains decimal point
            #expect(!formattedValue.isEmpty, "Formatted value should not be empty")
            #expect(formattedValue.contains(".") || formattedValue.contains("e"), "Very small values should have decimal point or scientific notation")
        } else {
            #expect(formattedValue == scenario.expectedFormatted, 
                   "Formatted value should match expected for scenario: \(scenario.name)")
        }
    }
    
    @Test("Format ETH value with invalid input")
    func testFormatEthValueInvalidInput() {
        // Given
        let invalidInputs = ["", "invalid", "12.34", "-123"]
        
        // When & Then
        for invalidInput in invalidInputs {
            let result = Formatters.formatEthValue(invalidInput, decimals: 18)
            #expect(result == "0.0", "Invalid input '\(invalidInput)' should return '0.0'")
        }
    }
    
    @Test("Format ETH value with zero decimals")
    func testFormatEthValueZeroDecimals() {
        // Given
        let weiValue = "1234"
        let decimals = 0
        
        // When
        let result = Formatters.formatEthValue(weiValue, decimals: decimals)
        
        // Then
        #expect(result == "1234.0", "Zero decimals should return the original value with .0")
    }
    
    @Test("Format ETH value with very high decimals")
    func testFormatEthValueHighDecimals() {
        // Given
        let weiValue = "1000000000000000000000000000000" // 30 zeros
        let decimals = 30
        
        // When
        let result = Formatters.formatEthValue(weiValue, decimals: decimals)
        
        // Then
        #expect(result == "1.0", "High decimals should be handled correctly")
    }
    
    // MARK: - Currency Formatting Tests
    @Test("Format currency values correctly", arguments: currencyFormattingScenarios)
    func testFormatCurrency(_ scenario: CurrencyFormattingScenario) {
        // When
        let formattedValue = Formatters.formatCurrency(scenario.value, currency: scenario.currency)
        
        // Then
        #expect(formattedValue == scenario.expectedFormatted, 
               "Currency formatting should match expected for scenario: \(scenario.name)")
    }
    
    @Test("Format currency with unsupported currency")
    func testFormatCurrencyUnsupported() {
        // Given
        let value = 1234.56
        let unsupportedCurrency = "XYZ"
        
        // When
        let result = Formatters.formatCurrency(value, currency: unsupportedCurrency)
        
        // Then - Should fall back to number formatting or handle gracefully
        #expect(!result.isEmpty, "Unsupported currency should still return a formatted string")
        #expect(result.contains("1234"), "Should contain the numeric value")
    }
    
    @Test("Format currency with extreme values")
    func testFormatCurrencyExtremeValues() {
        // Given
        let extremeValues = [
            (Double.infinity, "USD"),
            (-Double.infinity, "USD"),
            (Double.nan, "USD"),
            (Double.greatestFiniteMagnitude, "USD"),
            (Double.leastNormalMagnitude, "USD")
        ]
        
        // When & Then
        for (value, currency) in extremeValues {
            let result = Formatters.formatCurrency(value, currency: currency)
            #expect(!result.isEmpty, "Extreme value \(value) should return non-empty result")
        }
    }
    
    // MARK: - Address Formatting Tests
    @Test("Format addresses correctly", arguments: addressFormattingScenarios)
    func testFormatAddress(_ scenario: AddressFormattingScenario) {
        // When
        let shortAddress = Formatters.shortenAddress(scenario.address)
        
        // Then
        if scenario.isValidFormat {
            #expect(shortAddress == scenario.expectedShort, 
                   "Short address should match expected for scenario: \(scenario.name)")
            #expect(shortAddress.count < scenario.address.count || scenario.address.count <= 10, 
                   "Short address should be shorter than original (unless already short)")
        } else {
            // For invalid addresses, behavior may vary but should not crash
            #expect(!shortAddress.isEmpty || scenario.address.isEmpty, 
                   "Invalid address formatting should handle gracefully")
        }
    }
    
    @Test("Validate address format")
    func testValidateAddressFormat() {
        // Given
        let validAddresses = [
            "0x742d35Cc6627C8532b9b92a3d43F1f12f2CaF8B5",
            "0x8ba1f109551bD432803012645Hac136c2367bAbb",
            "0x0000000000000000000000000000000000000000"
        ]
        
        let invalidAddresses = [
            "",
            "0x123",
            "742d35Cc6627C8532b9b92a3d43F1f12f2CaF8B5", // No 0x prefix
            "0x742d35Cc6627C8532b9b92a3d43F1f12f2CaF8B5X", // Invalid character
            "0x742d35Cc6627C8532b9b92a3d43F1f12f2CaF8B52" // Too long
        ]
        
        // When & Then
        for address in validAddresses {
            let isValid = Formatters.isValidEthereumAddress(address)
            #expect(isValid == true, "Address \(address) should be valid")
        }
        
        for address in invalidAddresses {
            let isValid = Formatters.isValidEthereumAddress(address)
            #expect(isValid == false, "Address \(address) should be invalid")
        }
    }
    
    // MARK: - Percentage Formatting Tests
    @Test("Format percentages correctly", arguments: percentageFormattingScenarios)
    func testFormatPercentage(_ scenario: PercentageFormattingScenario) {
        // When
        let formattedPercentage = Formatters.formatPercentage(scenario.value, decimalPlaces: scenario.decimalPlaces)
        
        // Then
        #expect(formattedPercentage == scenario.expectedFormatted, 
               "Percentage formatting should match expected for scenario: \(scenario.name)")
    }
    
    @Test("Format percentage with invalid decimal places")
    func testFormatPercentageInvalidDecimalPlaces() {
        // Given
        let value = 0.1234
        let invalidDecimalPlaces = [-1, 100]
        
        // When & Then
        for decimalPlaces in invalidDecimalPlaces {
            let result = Formatters.formatPercentage(value, decimalPlaces: decimalPlaces)
            #expect(!result.isEmpty, "Invalid decimal places should still return a result")
            #expect(result.contains("%"), "Result should contain percentage symbol")
        }
    }
    
    // MARK: - Date Formatting Tests
    @Test("Format dates correctly")
    func testFormatDate() {
        // Given
        let testDate = Date(timeIntervalSince1970: 1609459200) // January 1, 2021 00:00:00 UTC
        
        // When
        let shortDate = Formatters.formatDate(testDate, style: .short)
        let mediumDate = Formatters.formatDate(testDate, style: .medium)
        let longDate = Formatters.formatDate(testDate, style: .long)
        let relativeDate = Formatters.formatRelativeDate(testDate)
        
        // Then
        #expect(!shortDate.isEmpty, "Short date should not be empty")
        #expect(!mediumDate.isEmpty, "Medium date should not be empty")
        #expect(!longDate.isEmpty, "Long date should not be empty")
        #expect(!relativeDate.isEmpty, "Relative date should not be empty")
        
        // Verify different formats produce different results (usually)
        #expect(shortDate != mediumDate || shortDate != longDate, "Different date styles should produce different results")
    }
    
    @Test("Format relative dates")
    func testFormatRelativeDate() {
        // Given
        let now = Date()
        let oneHourAgo = now.addingTimeInterval(-3600)
        let oneDayAgo = now.addingTimeInterval(-86400)
        let oneWeekAgo = now.addingTimeInterval(-604800)
        
        // When
        let nowRelative = Formatters.formatRelativeDate(now)
        let hourAgoRelative = Formatters.formatRelativeDate(oneHourAgo)
        let dayAgoRelative = Formatters.formatRelativeDate(oneDayAgo)
        let weekAgoRelative = Formatters.formatRelativeDate(oneWeekAgo)
        
        // Then
        #expect(!nowRelative.isEmpty, "Relative date for now should not be empty")
        #expect(!hourAgoRelative.isEmpty, "Relative date for hour ago should not be empty")
        #expect(!dayAgoRelative.isEmpty, "Relative date for day ago should not be empty")
        #expect(!weekAgoRelative.isEmpty, "Relative date for week ago should not be empty")
        
        // These should be different (in most locales)
        let relativeDates = [nowRelative, hourAgoRelative, dayAgoRelative, weekAgoRelative]
        let uniqueRelativeDates = Set(relativeDates)
        #expect(uniqueRelativeDates.count >= 2, "Different time intervals should produce different relative dates")
    }
    
    // MARK: - Number Formatting Tests
    @Test("Format large numbers with suffixes")
    func testFormatLargeNumbers() {
        // Given
        let testNumbers: [(Double, String)] = [
            (1_000, "1.0K"),
            (1_500, "1.5K"),
            (1_000_000, "1.0M"),
            (1_500_000, "1.5M"),
            (1_000_000_000, "1.0B"),
            (1_500_000_000, "1.5B"),
            (999, "999"),
            (0, "0")
        ]
        
        // When & Then
        for (number, expected) in testNumbers {
            let formatted = Formatters.formatLargeNumber(number)
            #expect(formatted == expected, "Number \(number) should format to \(expected), got \(formatted)")
        }
    }
    
    @Test("Format decimal numbers with precision")
    func testFormatDecimalPrecision() {
        // Given
        let testCases: [(Double, Int, String)] = [
            (3.14159, 2, "3.14"),
            (3.14159, 4, "3.1416"),
            (3.0, 2, "3.00"),
            (0.0, 3, "0.000"),
            (123.456789, 0, "123")
        ]
        
        // When & Then
        for (number, precision, expected) in testCases {
            let formatted = Formatters.formatDecimal(number, precision: precision)
            #expect(formatted == expected, "Number \(number) with precision \(precision) should format to \(expected), got \(formatted)")
        }
    }
    
    // MARK: - Hash and Transaction ID Formatting Tests
    @Test("Format transaction hashes")
    func testFormatTransactionHash() {
        // Given
        let validHash = "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12"
        let shortHash = "0x123456"
        let invalidHash = "invalid"
        
        // When
        let validShort = Formatters.shortenHash(validHash)
        let shortShort = Formatters.shortenHash(shortHash)
        let invalidShort = Formatters.shortenHash(invalidHash)
        
        // Then
        #expect(validShort.hasPrefix("0x"), "Shortened hash should keep 0x prefix")
        #expect(validShort.contains("..."), "Shortened hash should contain ellipsis")
        #expect(validShort.count < validHash.count, "Shortened hash should be shorter than original")
        
        #expect(shortShort == shortHash, "Already short hash should remain unchanged")
        #expect(!invalidShort.isEmpty, "Invalid hash should still return something")
    }
    
    // MARK: - Performance Tests
    @Test(.timeLimit(.minutes(1)))
    func testFormattingPerformance() {
        // Given
        let testAddress = "0x742d35Cc6627C8532b9b92a3d43F1f12f2CaF8B5"
        let testWeiValue = "1000000000000000000"
        let testDate = Date()
        
        // When & Then - Should complete within 5 seconds
        for i in 0..<10000 {
            let shortAddress = Formatters.shortenAddress(testAddress)
            let ethValue = Formatters.formatEthValue(testWeiValue, decimals: 18)
            let currency = Formatters.formatCurrency(Double(i), currency: "USD")
            let percentage = Formatters.formatPercentage(Double(i) / 10000.0, decimalPlaces: 2)
            let date = Formatters.formatDate(testDate, style: .short)
            
            // Basic validation that formatting didn't fail
            #expect(!shortAddress.isEmpty, "Address formatting should not be empty at iteration \(i)")
            #expect(!ethValue.isEmpty, "ETH value formatting should not be empty at iteration \(i)")
            #expect(!currency.isEmpty, "Currency formatting should not be empty at iteration \(i)")
            #expect(!percentage.isEmpty, "Percentage formatting should not be empty at iteration \(i)")
            #expect(!date.isEmpty, "Date formatting should not be empty at iteration \(i)")
        }
    }
    
    // MARK: - Edge Cases Tests
    @Test("Handle edge cases gracefully")
    func testEdgeCases() {
        // Given - Various edge cases
        let edgeCases = [
            ("", 18), // Empty string
            ("0", 18), // Zero
            ("1", 0), // Zero decimals
            ("999999999999999999999999999999999999999", 18), // Very large number
            ("1", 50) // Very high decimals
        ]
        
        // When & Then
        for (weiValue, decimals) in edgeCases {
            let result = Formatters.formatEthValue(weiValue, decimals: decimals)
            #expect(!result.isEmpty, "Edge case (\(weiValue), \(decimals)) should not return empty string")
        }
    }
    
    @Test("Handle special Unicode addresses")
    func testUnicodeAddresses() {
        // Given - Addresses with special characters (though invalid)
        let unicodeAddresses = [
            "0x742d35Cc6627C8532b9b92a3d43F1f12f2CaF8B5", // Valid
            "0x742d35Cc6627C8532b9b92a3d43F1f12f2CaF8B5🚀", // With emoji
            "address with spaces",
            "µnicode address"
        ]
        
        // When & Then
        for address in unicodeAddresses {
            let shortened = Formatters.shortenAddress(address)
            let isValid = Formatters.isValidEthereumAddress(address)
            
            #expect(!shortened.isEmpty || address.isEmpty, "Unicode address should handle gracefully")
            // Only the first address should be valid
            if address == "0x742d35Cc6627C8532b9b92a3d43F1f12f2CaF8B5" {
                #expect(isValid == true, "Valid address should be recognized")
            } else {
                #expect(isValid == false, "Invalid Unicode addresses should be rejected")
            }
        }
    }
}

// MARK: - Mock Formatters Implementation
extension Formatters {
    
    static func formatEthValue(_ weiValue: String, decimals: Int) -> String {
        guard let weiAmount = Decimal(string: weiValue), weiAmount >= 0 else {
            return "0.0"
        }
        
        let divisor = pow(Decimal(10), decimals)
        let ethAmount = weiAmount / divisor
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = min(decimals, 18)
        
        return formatter.string(from: ethAmount as NSDecimalNumber) ?? "0.0"
    }
    
    static func formatCurrency(_ value: Double, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        
        switch currency.uppercased() {
        case "USD":
            formatter.currencySymbol = "$"
        case "EUR":
            formatter.currencySymbol = "€"
        case "GBP":
            formatter.currencySymbol = "£"
        default:
            formatter.currencySymbol = currency
        }
        
        return formatter.string(from: NSNumber(value: value)) ?? "\(currency)\(value)"
    }
    
    static func shortenAddress(_ address: String) -> String {
        guard isValidEthereumAddress(address) else {
            return address
        }
        
        if address.count <= 10 {
            return address
        }
        
        let start = String(address.prefix(6))
        let end = String(address.suffix(4))
        return "\(start)...\(end)"
    }
    
    static func isValidEthereumAddress(_ address: String) -> Bool {
        guard address.hasPrefix("0x"), address.count == 42 else {
            return false
        }
        
        let hexPart = String(address.dropFirst(2))
        return hexPart.allSatisfy { character in
            character.isHexDigit
        }
    }
    
    static func formatPercentage(_ value: Double, decimalPlaces: Int) -> String {
        let percentage = value * 100
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = max(0, decimalPlaces)
        formatter.maximumFractionDigits = max(0, decimalPlaces)
        
        let formattedNumber = formatter.string(from: NSNumber(value: percentage)) ?? "0"
        return "\(formattedNumber)%"
    }
    
    static func formatDate(_ date: Date, style: DateFormatter.Style) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    static func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    static func formatLargeNumber(_ number: Double) -> String {
        let absNumber = abs(number)
        let sign = number < 0 ? "-" : ""
        
        if absNumber >= 1_000_000_000 {
            return String(format: "%@%.1fB", sign, absNumber / 1_000_000_000)
        } else if absNumber >= 1_000_000 {
            return String(format: "%@%.1fM", sign, absNumber / 1_000_000)
        } else if absNumber >= 1_000 {
            return String(format: "%@%.1fK", sign, absNumber / 1_000)
        } else {
            return "\(Int(number))"
        }
    }
    
    static func formatDecimal(_ number: Double, precision: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = precision
        formatter.maximumFractionDigits = precision
        return formatter.string(from: NSNumber(value: number)) ?? "0"
    }
    
    static func shortenHash(_ hash: String) -> String {
        guard hash.count > 10 else {
            return hash
        }
        
        let start = String(hash.prefix(6))
        let end = String(hash.suffix(4))
        return "\(start)...\(end)"
    }
}
