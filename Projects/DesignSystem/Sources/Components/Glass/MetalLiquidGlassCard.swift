import SwiftUI
import Core

/// Metal 기반 Liquid Glass 효과를 사용하는 개선된 카드
public struct MetalLiquidGlassCard<Content: View>: View {
    
    // MARK: - Properties
    
    let content: Content
    let style: MetalGlassCardStyle
    
    @State private var glassSettings: LiquidGlassSettings
    @Environment(\.glassTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Initialization
    
    public init(
        style: MetalGlassCardStyle = .default,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.style = style
        self._glassSettings = State(initialValue: style.baseGlassSettings)
    }
    
    // MARK: - Body
    
    public var body: some View {
        content
            .metalLiquidGlass(settings: $glassSettings)
            .overlay(
                RoundedRectangle(cornerRadius: style.cornerRadius)
                    .stroke(style.borderColor, lineWidth: style.borderWidth)
            )
            .clipShape(RoundedRectangle(cornerRadius: style.cornerRadius))
            .onTapGesture { location in
                handleTouchInteraction(at: location)
            }
            .onAppear {
                setupThemeAdaptiveGlass()
            }
            .onChange(of: theme) { _, _ in
                setupThemeAdaptiveGlass()
            }
    }
    
    // MARK: - Interaction Handlers
    
    private func handleTouchInteraction(at point: CGPoint) {
        // 터치 지점 기반 파급 효과
        let originalDistortion = glassSettings.distortionStrength
        let originalReflection = glassSettings.reflectionStrength
        
        withAnimation(.easeOut(duration: 0.4)) {
            glassSettings.distortionStrength = min(1.0, originalDistortion * 1.8)
            glassSettings.reflectionStrength = min(1.0, originalReflection * 1.5)
        }
        
        Task { @MainActor in
            try await Task.sleep(nanoseconds: 400_000_000) // 0.4초
            withAnimation(.easeInOut(duration: 0.6)) {
                glassSettings.distortionStrength = originalDistortion
                glassSettings.reflectionStrength = originalReflection
            }
        }
    }
    
    private func setupThemeAdaptiveGlass() {
        var adaptedSettings = style.baseGlassSettings
        
        switch theme {
        case .system:
            // 기본 설정 유지
            break
        case .light:
            adaptedSettings.thickness *= 0.8
            adaptedSettings.opacity *= 0.9
            adaptedSettings.tintColor = (0.98, 0.99, 1.0)
        case .dark:
            adaptedSettings.thickness *= 1.2
            adaptedSettings.reflectionStrength *= 1.3
            adaptedSettings.tintColor = (0.85, 0.9, 0.95)
        case .vibrant:
            adaptedSettings.thickness *= 1.1
            adaptedSettings.reflectionStrength *= 1.4
            adaptedSettings.chromaticAberration *= 1.5
            adaptedSettings.tintColor = colorScheme == .dark ? (0.8, 0.9, 1.0) : (0.9, 0.95, 1.0)
        }
        
        withAnimation(.easeInOut(duration: 0.5)) {
            glassSettings = adaptedSettings
        }
    }
}

// MARK: - MetalGlassCardStyle

public struct MetalGlassCardStyle: Sendable {
    let cornerRadius: CGFloat
    let borderColor: Color
    let borderWidth: CGFloat
    let baseGlassSettings: LiquidGlassSettings
    
    public init(
        cornerRadius: CGFloat = Constants.UI.cornerRadius,
        borderColor: Color = .glassBorderSecondary,
        borderWidth: CGFloat = 1,
        baseGlassSettings: LiquidGlassSettings
    ) {
        self.cornerRadius = cornerRadius
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.baseGlassSettings = baseGlassSettings
    }
    
    // MARK: - Predefined Styles
    
    /// 기본 카드 스타일
    public static let `default` = MetalGlassCardStyle(
        cornerRadius: Constants.UI.cornerRadius,
        borderColor: .glassBorderSecondary,
        borderWidth: 1,
        baseGlassSettings: {
            var settings = LiquidGlassSettings()
            settings.thickness = 0.4
            settings.refractionStrength = 0.2
            settings.reflectionStrength = 0.15
            settings.opacity = 0.75
            settings.tintColor = (0.95, 0.98, 1.0)
            settings.edgeFade = 0.1
            return settings
        }()
    )
    
    /// 은은한 카드 스타일
    public static let subtle = MetalGlassCardStyle(
        cornerRadius: Constants.UI.cornerRadius,
        borderColor: .glassBorderSecondary,
        borderWidth: 0.7,
        baseGlassSettings: {
            var settings = LiquidGlassSettings()
            settings.thickness = 0.25
            settings.refractionStrength = 0.1
            settings.reflectionStrength = 0.08
            settings.opacity = 0.65
            settings.tintColor = (0.98, 0.99, 1.0)
            return settings
        }()
    )
    
    /// 지갑 카드 스타일
    public static let wallet = MetalGlassCardStyle(
        cornerRadius: Constants.UI.cornerRadius + 4,
        borderColor: .glassBorderAccent,
        borderWidth: 1.1,
        baseGlassSettings: {
            var settings = LiquidGlassSettings()
            settings.thickness = 0.8
            settings.refractionStrength = 0.5
            settings.reflectionStrength = 0.4
            settings.distortionStrength = 0.2
            settings.opacity = 0.9
            settings.tintColor = (0.85, 0.9, 1.0)
            settings.chromaticAberration = 0.15
            settings.edgeFade = 0.25
            return settings
        }()
    )
    
    /// 거래 내역 카드 스타일
    public static let transaction = MetalGlassCardStyle(
        cornerRadius: Constants.UI.cornerRadius - 2,
        borderColor: .glassBorderSecondary,
        borderWidth: 0.6,
        baseGlassSettings: {
            var settings = LiquidGlassSettings()
            settings.thickness = 0.3
            settings.refractionStrength = 0.15
            settings.reflectionStrength = 0.12
            settings.opacity = 0.7
            settings.tintColor = (0.96, 0.98, 1.0)
            return settings
        }()
    )
}

// MARK: - View Extension

public extension View {
    /// Metal Liquid Glass Card 효과 적용
    func metalLiquidGlassCard(style: MetalGlassCardStyle = .default) -> some View {
        MetalLiquidGlassCard(style: style) {
            self
        }
    }
}

// MARK: - Specialized Metal Glass Cards

/// Metal 기반 잔액 표시 카드
public struct MetalBalanceCard: View {
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
        .metalLiquidGlassCard(style: .wallet)
    }
}

/// Metal 기반 거래 내역 카드
public struct MetalTransactionCard: View {
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
        .metalLiquidGlassCard(style: .transaction)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        MetalBalanceCard(balance: "2.5", symbol: "ETH", usdValue: "$4,250.00")
        
        MetalTransactionCard(
            type: .receive,
            amount: "0.5",
            symbol: "ETH",
            timestamp: "5분 전",
            status: .confirmed
        )
    }
    .padding()
    .background(
        LinearGradient(
            colors: [.systemBlue, .systemPurple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
    .environment(\.glassTheme, .vibrant)
}
