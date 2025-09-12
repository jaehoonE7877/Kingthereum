import Foundation

import Entity

// MARK: - Convenience Extensions

public extension CoinPrice {
    
    /// USD 가격을 포맷된 문자열로 반환
    var formattedUSDPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: currentPrice as NSDecimalNumber) ?? "$0.00"
    }
    
    /// 24시간 변동률을 포맷된 문자열로 반환
    var formatted24hChange: String? {
        guard let change = priceChangePercentage24h else { return nil }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 2
        formatter.positivePrefix = "+"
        
        let changeValue = change / 100 // 퍼센트를 소수로 변환
        return formatter.string(from: changeValue as NSDecimalNumber)
    }
    
    /// 가격 상승/하락 여부
    var isPriceUp: Bool {
        guard let change = priceChangePercentage24h else { return false }
        return change > 0
    }
}
