import Foundation
import Core

/// 공통 포맷팅 유틸리티
/// 다양한 데이터 타입을 사용자 친화적인 형태로 변환
public enum FormatUtils {
    
    // MARK: - Currency Formatting
    
    /// ETH 금액 포맷팅
    /// - Parameters:
    ///   - amount: ETH 금액 (String)
    ///   - precision: 소수점 자릿수 (기본값: 4)
    /// - Returns: 포맷된 ETH 문자열
    public static func formatETH(_ amount: String, precision: Int = 4) -> String {
        guard let doubleAmount = Double(amount) else { return "0.0000 ETH" }
        return formatETH(doubleAmount, precision: precision)
    }
    
    /// ETH 금액 포맷팅 (Double)
    public static func formatETH(_ amount: Double, precision: Int = 4) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = min(precision, 4)
        formatter.maximumFractionDigits = precision
        formatter.groupingSeparator = ","
        
        guard let formattedNumber = formatter.string(from: NSNumber(value: amount)) else {
            return "0.0000 ETH"
        }
        
        return "\(formattedNumber) ETH"
    }
    
    /// USD 금액 포맷팅
    public static func formatUSD(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.currencySymbol = "$"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    /// 원화 포맷팅
    public static func formatKRW(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "KRW"
        formatter.currencySymbol = "₩"
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = ","
        
        return formatter.string(from: NSNumber(value: amount)) ?? "₩0"
    }
    
    /// 가스비 포맷팅 (Gwei)
    public static func formatGwei(_ amount: Double, precision: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = precision
        formatter.groupingSeparator = ","
        
        guard let formattedNumber = formatter.string(from: NSNumber(value: amount)) else {
            return "0 Gwei"
        }
        
        return "\(formattedNumber) Gwei"
    }
    
    // MARK: - Address Formatting
    
    /// 이더리움 주소 축약 포맷팅
    /// - Parameters:
    ///   - address: 전체 주소
    ///   - prefixLength: 앞부분 길이 (기본값: 6)
    ///   - suffixLength: 뒷부분 길이 (기본값: 4)
    /// - Returns: 축약된 주소 (예: 0x1234...5678)
    public static func formatAddress(
        _ address: String,
        prefixLength: Int = 6,
        suffixLength: Int = 4
    ) -> String {
        guard address.count > prefixLength + suffixLength else {
            return address
        }
        
        let start = String(address.prefix(prefixLength))
        let end = String(address.suffix(suffixLength))
        return "\(start)...\(end)"
    }
    
    /// 트랜잭션 해시 포맷팅
    public static func formatTransactionHash(_ hash: String) -> String {
        return formatAddress(hash, prefixLength: 8, suffixLength: 6)
    }
    
    // MARK: - Date/Time Formatting
    
    /// 상대적 시간 표시 (예: 2분 전, 1시간 전)
    public static func formatRelativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        formatter.locale = Locale(identifier: "ko_KR")
        
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    /// 트랜잭션 시간 포맷팅
    public static func formatTransactionTime(_ date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        if timeInterval < 60 {
            return "방금 전"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)분 전"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)시간 전"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd HH:mm"
            formatter.locale = Locale(identifier: "ko_KR")
            return formatter.string(from: date)
        }
    }
    
    /// 절대 시간 포맷팅
    public static func formatAbsoluteTime(_ date: Date, style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = style
        formatter.locale = Locale(identifier: "ko_KR")
        
        return formatter.string(from: date)
    }
    
    // MARK: - Number Formatting
    
    /// 큰 숫자 축약 (예: 1.2K, 3.4M)
    public static func formatLargeNumber(_ number: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        
        switch number {
        case 1_000_000_000...:
            return "\(formatter.string(from: NSNumber(value: number / 1_000_000_000)) ?? "0")B"
        case 1_000_000...:
            return "\(formatter.string(from: NSNumber(value: number / 1_000_000)) ?? "0")M"
        case 1_000...:
            return "\(formatter.string(from: NSNumber(value: number / 1_000)) ?? "0")K"
        default:
            formatter.maximumFractionDigits = 0
            return formatter.string(from: NSNumber(value: number)) ?? "0"
        }
    }
    
    /// 퍼센트 포맷팅
    public static func formatPercentage(_ value: Double, precision: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = precision
        
        return formatter.string(from: NSNumber(value: value)) ?? "0%"
    }
    
    // MARK: - Wei Conversion
    
    /// Wei를 ETH로 변환
    public static func weiToEth(_ wei: String) -> String {
        guard let weiDouble = Double(wei) else { return "0" }
        let eth = weiDouble / 1_000_000_000_000_000_000 // 10^18
        return String(eth)
    }
    
    /// ETH를 Wei로 변환
    public static func ethToWei(_ eth: String) -> String {
        guard let ethDouble = Double(eth) else { return "0" }
        let wei = ethDouble * 1_000_000_000_000_000_000 // 10^18
        return String(format: "%.0f", wei)
    }
    
    // MARK: - Validation Helpers
    
    /// 유효한 ETH 금액인지 확인
    public static func isValidETHAmount(_ amount: String) -> Bool {
        guard let doubleAmount = Double(amount) else { return false }
        return doubleAmount > 0 && doubleAmount <= 1_000_000 // 현실적인 상한선
    }
    
    /// 소수점 자릿수 제한
    public static func limitDecimalPlaces(_ amount: String, to places: Int) -> String {
        let components = amount.split(separator: ".")
        guard components.count == 2 else { return amount }
        
        let integerPart = String(components[0])
        let decimalPart = String(components[1])
        let limitedDecimalPart = String(decimalPart.prefix(places))
        
        return places > 0 ? "\(integerPart).\(limitedDecimalPart)" : integerPart
    }
}

// MARK: - String Extensions for Formatting

public extension String {
    /// ETH 포맷팅 적용
    func formatAsETH(precision: Int = 4) -> String {
        return FormatUtils.formatETH(self, precision: precision)
    }
    
    /// 주소 축약 적용
    func formatAsAddress() -> String {
        return FormatUtils.formatAddress(self)
    }
    
    /// 트랜잭션 해시 포맷팅 적용
    func formatAsTransactionHash() -> String {
        return FormatUtils.formatTransactionHash(self)
    }
}

public extension Double {
    /// USD 포맷팅 적용
    func formatAsUSD() -> String {
        return FormatUtils.formatUSD(self)
    }
    
    /// KRW 포맷팅 적용
    func formatAsKRW() -> String {
        return FormatUtils.formatKRW(self)
    }
    
    /// Gwei 포맷팅 적용
    func formatAsGwei(precision: Int = 2) -> String {
        return FormatUtils.formatGwei(self, precision: precision)
    }
    
    /// 퍼센트 포맷팅 적용
    func formatAsPercentage(precision: Int = 2) -> String {
        return FormatUtils.formatPercentage(self, precision: precision)
    }
}