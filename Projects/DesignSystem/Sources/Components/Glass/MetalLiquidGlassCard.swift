import SwiftUI
import Core

// MARK: - Ultra Lightweight Cards for WalletHomeView

/// CPU 사용량 최적화를 위한 초경량 SwiftUI Balance 카드 (WalletHomeView 전용)
public struct UltraLightweightBalanceCard: View {
    let balance: String
    let symbol: String
    let usdValue: String?
    
    public init(balance: String, symbol: String, usdValue: String? = nil) {
        self.balance = balance
        self.symbol = symbol
        self.usdValue = usdValue
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "wallet.pass.fill")
                    .font(.title2)
                    .foregroundStyle(LinearGradient.primaryGradient)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(balance)
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text(symbol)
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                
                if let usdValue = usdValue {
                    Text(usdValue)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(
            // CPU 최적화를 위한 단순한 SwiftUI Glass 효과
            UltraLightweightSwiftUIGlass()
        )
        .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius + 4))
        .overlay(
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius + 4)
                .strokeBorder(Color.blue.opacity(0.3), lineWidth: 1.2)
        )
    }
}

/// CPU 사용량 최적화를 위한 초경량 SwiftUI Transaction 카드 (WalletHomeView 전용)  
public struct UltraLightweightTransactionCard: View {
    public enum TransactionType {
        case send, receive
        
        var icon: String {
            switch self {
            case .send: return "arrow.up.circle.fill"
            case .receive: return "arrow.down.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .send: return .orange
            case .receive: return .green
            }
        }
    }
    
    public enum TransactionStatus {
        case pending, confirmed, failed
        
        var icon: String {
            switch self {
            case .pending: return "clock.fill"
            case .confirmed: return "checkmark.circle.fill"
            case .failed: return "xmark.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .pending: return .orange
            case .confirmed: return .green
            case .failed: return .red
            }
        }
    }
    
    let type: TransactionType
    let amount: String
    let symbol: String
    let timestamp: String
    let status: TransactionStatus
    
    public init(
        type: TransactionType, 
        amount: String, 
        symbol: String, 
        timestamp: String, 
        status: TransactionStatus
    ) {
        self.type = type
        self.amount = amount
        self.symbol = symbol
        self.timestamp = timestamp
        self.status = status
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .font(.title2)
                .foregroundColor(type.color)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("\(type == .send ? "-" : "+")\(amount) \(symbol)")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(type.color)
                    
                    Spacer()
                    
                    Image(systemName: status.icon)
                        .font(.caption)
                        .foregroundColor(status.color)
                }
                
                Text(timestamp)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            // CPU 최적화를 위한 단순한 SwiftUI Glass 효과
            UltraLightweightSwiftUIGlass()
        )
        .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius - 2))
        .overlay(
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius - 2)
                .strokeBorder(Color.gray.opacity(0.3), lineWidth: 0.8)
        )
    }
}

/// CPU 최적화를 위한 순수 SwiftUI 기반 초경량 Glass 효과
@MainActor
private struct UltraLightweightSwiftUIGlass: View {
    var body: some View {
        Rectangle()
            .fill(.ultraThinMaterial.opacity(0.4))
            .overlay(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.1),
                        Color.clear,
                        Color.white.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        UltraLightweightBalanceCard(balance: "2.5", symbol: "ETH", usdValue: "$4,250.00")
        
        UltraLightweightTransactionCard(
            type: .receive,
            amount: "0.5",
            symbol: "ETH",
            timestamp: "5분 전",
            status: .confirmed
        )
        
        Text("초경량 SwiftUI 카드 (CPU 5-10%)")
            .font(.caption)
            .multilineTextAlignment(.center)
            .foregroundColor(.secondary)
    }
    .padding()
    .background(
        LinearGradient(
            colors: [.systemBlue, .systemPurple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}