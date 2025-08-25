import SwiftUI
import Core

public struct GlassCard<Content: View>: View {
    let content: Content
    let style: GlassCardStyle
    
    public init(
        style: GlassCardStyle = .default,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.style = style
    }
    
    public var body: some View {
        content
            .background(style.material, in: RoundedRectangle(cornerRadius: style.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: style.cornerRadius)
                    .stroke(style.borderColor, lineWidth: style.borderWidth)
            )
            .shadow(
                color: style.shadowColor,
                radius: style.shadowRadius,
                x: 0,
                y: style.shadowOffset
            )
    }
}

@MainActor
public struct GlassCardStyle {
    public static let `default` = GlassCardStyle(
        material: .ultraThinMaterial,
        cornerRadius: Constants.UI.cornerRadius,
        borderColor: .glassBorderSecondary,
        borderWidth: 1,
        shadowColor: .glassShadowLight,
        shadowRadius: 8,
        shadowOffset: 4
    )
    
    public static let prominent = GlassCardStyle(
        material: .thickMaterial,
        cornerRadius: Constants.UI.cornerRadius,
        borderColor: .glassBorderPrimary,
        borderWidth: 1.2,
        shadowColor: .glassShadowMedium,
        shadowRadius: 16,
        shadowOffset: 8
    )
    
    public static let subtle = GlassCardStyle(
        material: .ultraThinMaterial,
        cornerRadius: Constants.UI.cornerRadius,
        borderColor: .glassBorderSecondary,
        borderWidth: 0.7,
        shadowColor: .glassShadowLight,
        shadowRadius: 6,
        shadowOffset: 3
    )
    
    public static let wallet = GlassCardStyle(
        material: .regularMaterial,
        cornerRadius: Constants.UI.cornerRadius + 4,
        borderColor: .glassBorderAccent,
        borderWidth: 1.1,
        shadowColor: .glassShadowMedium,
        shadowRadius: 14,
        shadowOffset: 7
    )
    
    public static let transaction = GlassCardStyle(
        material: .thinMaterial,
        cornerRadius: Constants.UI.cornerRadius - 2,
        borderColor: .glassBorderSecondary,
        borderWidth: 0.6,
        shadowColor: .glassShadowLight,
        shadowRadius: 6,
        shadowOffset: 3
    )
    
    let material: Material
    let cornerRadius: CGFloat
    let borderColor: Color
    let borderWidth: CGFloat
    let shadowColor: Color
    let shadowRadius: CGFloat
    let shadowOffset: CGFloat
    
    public init(
        material: Material,
        cornerRadius: CGFloat, 
        borderColor: Color,
        borderWidth: CGFloat,
        shadowColor: Color,
        shadowRadius: CGFloat,
        shadowOffset: CGFloat
    ) {
        self.material = material
        self.cornerRadius = cornerRadius
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.shadowColor = shadowColor
        self.shadowRadius = shadowRadius
        self.shadowOffset = shadowOffset
    }
}

public extension View {
    func glassCard(style: GlassCardStyle = .default) -> some View {
        GlassCard(style: style) {
            self
        }
    }
}

// MARK: - Specialized Glass Cards

/// 잔액 표시 전용 카드
public struct BalanceCard: View {
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
        .glassCard(style: .wallet)
    }
}

/// 거래 내역 전용 카드
public struct TransactionCard: View {
    let type: TransactionType
    let amount: String
    let symbol: String
    let timestamp: String
    let status: TransactionStatus
    
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
            case .send: return .systemRed
            case .receive: return .systemGreen
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
            case .pending: return .systemOrange
            case .confirmed: return .systemGreen
            case .failed: return .systemRed
            }
        }
    }
    
    public init(type: TransactionType, amount: String, symbol: String, timestamp: String, status: TransactionStatus) {
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
        .glassCard(style: .transaction)
    }
}

/// 액션 버튼 그룹 카드
public struct ActionCard: View {
    let title: String
    let actions: [ActionItem]
    
    public struct ActionItem {
        let icon: String
        let title: String
        let action: () -> Void
        
        public init(icon: String, title: String, action: @escaping () -> Void) {
            self.icon = icon
            self.title = title
            self.action = action
        }
    }
    
    public init(title: String, actions: [ActionItem]) {
        self.title = title
        self.actions = actions
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: min(actions.count, 3)), spacing: 12) {
                ForEach(actions.indices, id: \.self) { index in
                    let action = actions[index]
                    Button(action: action.action) {
                        VStack(spacing: 8) {
                            Image(systemName: action.icon)
                                .font(.title2)
                                .foregroundStyle(LinearGradient.primaryGradient)
                            Text(action.title)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(20)
        .glassCard(style: .default)
    }
}

/// 정보 표시 카드
public struct InfoCard: View {
    let icon: String
    let title: String
    let subtitle: String?
    let value: String
    let style: InfoCardStyle
    
    public enum InfoCardStyle {
        case `default`, success, warning, error
        
        var iconColor: Color {
            switch self {
            case .default: return .kingBlue
            case .success: return .systemGreen
            case .warning: return .systemOrange
            case .error: return .systemRed
            }
        }
    }
    
    public init(icon: String, title: String, subtitle: String? = nil, value: String, style: InfoCardStyle = .default) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.style = style
    }
    
    public var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(style.iconColor)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(16)
        .glassCard(style: .subtle)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            BalanceCard(balance: "2.5", symbol: "ETH", usdValue: "$4,250.00")
            
            TransactionCard(
                type: .receive,
                amount: "0.5",
                symbol: "ETH",
                timestamp: "5분 전",
                status: .confirmed
            )
            
            ActionCard(title: "빠른 액션", actions: [
                .init(icon: "arrow.up.circle.fill", title: "송금") { },
                .init(icon: "arrow.down.circle.fill", title: "수신") { },
                .init(icon: "qrcode", title: "QR코드") { }
            ])
            
            InfoCard(
                icon: "network",
                title: "네트워크",
                subtitle: "이더리움 메인넷",
                value: "ETH",
                style: .default
            )
        }
        .padding()
    }
    .background(
        LinearGradient(
            colors: [.systemBlue, .systemPurple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
