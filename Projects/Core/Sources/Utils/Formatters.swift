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
    
    // MARK: - Number Formatters
    
    /// 통화 표시용 포맷터 (USD 기준)
    /// 
    /// 암호화폐의 법정화폐 환산 가치를 표시할 때 사용합니다.
    /// 소수점 둘째 자리까지 표시하며, 통화 기호($)를 포함합니다.
    /// 
    /// ## 출력 예시: $1,234.56
    public static let currency: NumberFormatter = {
        let formatter = NumberFormatter()
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
        guard let doubleValue = Double(value) else { return "0" }
        let divisor = pow(10.0, Double(decimals))
        let ethValue = doubleValue / divisor
        
        // 값의 크기에 따른 동적 정밀도 적용
        if ethValue < 0.001 {
            return String(format: "%.6f", ethValue)
        } else if ethValue < 1 {
            return String(format: "%.4f", ethValue)
        } else {
            return String(format: "%.2f", ethValue)
        }
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
        guard address.count > length * 2 else { return address }
        let start = String(address.prefix(length))
        let end = String(address.suffix(length))
        return "\(start)...\(end)"
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
        guard hash.count > length else { return hash }
        return String(hash.prefix(length)) + "..."
    }
}