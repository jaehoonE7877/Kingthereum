import Foundation

public enum Formatters {
    
    public static let currency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    public static let decimal: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 6
        formatter.minimumFractionDigits = 0
        return formatter
    }()
    
    public static let percentage: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    public static let dateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    public static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    public static func formatEthValue(_ value: String, decimals: Int = 18) -> String {
        guard let doubleValue = Double(value) else { return "0" }
        let divisor = pow(10.0, Double(decimals))
        let ethValue = doubleValue / divisor
        
        if ethValue < 0.001 {
            return String(format: "%.6f", ethValue)
        } else if ethValue < 1 {
            return String(format: "%.4f", ethValue)
        } else {
            return String(format: "%.2f", ethValue)
        }
    }
    
    public static func formatAddress(_ address: String, length: Int = 6) -> String {
        guard address.count > length * 2 else { return address }
        let start = String(address.prefix(length))
        let end = String(address.suffix(length))
        return "\(start)...\(end)"
    }
    
    public static func formatHash(_ hash: String, length: Int = 8) -> String {
        guard hash.count > length else { return hash }
        return String(hash.prefix(length)) + "..."
    }
}