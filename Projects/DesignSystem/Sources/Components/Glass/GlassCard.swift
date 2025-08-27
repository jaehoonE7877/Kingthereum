import SwiftUI
import Core

// GlassTokens는 같은 모듈 내에 있으므로 별도 import 불필요

/// 4단계 GlassMorphism 효과를 지원하는 Glass Card 컴포넌트
/// 효과 레벨과 테마에 따라 동적으로 스타일이 적용됨
public struct GlassCard<Content: View>: View {
    let content: Content
    let effectLevel: GlassTokens.EffectLevel
    let context: GlassTokens.Context
    let customCornerRadius: CGFloat?
    
    @Environment(\.glassTheme) private var theme
    @Environment(\.glassEffectLevel) private var environmentEffectLevel
    @Environment(\.colorScheme) private var colorScheme
    
    // 2024 접근성 지원을 위한 기본 설정
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    /// 효과 레벨을 명시적으로 지정하여 초기화
    public init(
        level: GlassTokens.EffectLevel,
        context: GlassTokens.Context = .card,
        cornerRadius: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.effectLevel = level
        self.context = context
        self.customCornerRadius = cornerRadius
    }
    
    /// 환경에서 효과 레벨을 상속받아 초기화
    public init(
        context: GlassTokens.Context = .card,
        cornerRadius: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.effectLevel = context.defaultEffectLevel
        self.context = context
        self.customCornerRadius = cornerRadius
    }
    
    public var body: some View {
        content
            .background(
                effectiveMaterial,
                in: RoundedRectangle(cornerRadius: effectiveCornerRadius)
            )
            .overlay(
                RoundedRectangle(cornerRadius: effectiveCornerRadius)
                    .stroke(effectiveBorderColor, lineWidth: effectiveBorderWidth)
            )
            .shadow(
                color: effectiveShadowColor,
                radius: effectiveShadowRadius,
                x: 0,
                y: effectiveShadowOffset
            )
    }
    
    // MARK: - Dynamic Properties
    
    /// 테마와 효과 레벨에 따른 Material 결정 (2024 최적화)
    private var effectiveMaterial: Material {
        // 기본 Material 효과
        let baseMaterial = effectLevel.material
        
        // 테마별 로직
        switch theme {
        case .system:
            return baseMaterial
        case .light:
            return baseMaterial
        case .dark:
            return .thickMaterial
        case .vibrant:
            return colorScheme == .dark ? .ultraThickMaterial : .thinMaterial
        }
    }
    
    /// 효과적인 코너 반경
    private var effectiveCornerRadius: CGFloat {
        customCornerRadius ?? context.defaultCornerRadius
    }
    
    /// 테마와 효과 레벨에 따른 테두리 색상 (2024 최적화)
    private var effectiveBorderColor: Color {
        let adaptation = GlassTokens.ColorAdaptation.border
        let baseColor = KingColors.glassBorder
        
        switch theme {
        case .system:
            return baseColor.opacity(effectLevel.opacity * 0.5)
        case .light:
            return baseColor.opacity(adaptation.light)
        case .dark:
            return baseColor.opacity(adaptation.dark)
        case .vibrant:
            return baseColor.opacity(adaptation.vibrant)
        }
    }
    
    /// 효과 레벨에 따른 테두리 두께
    private var effectiveBorderWidth: CGFloat {
        effectLevel.borderWidth
    }
    
    /// 테마와 효과 레벨에 따른 그림자 색상 (2024 최적화)
    private var effectiveShadowColor: Color {
        let adaptation = GlassTokens.ColorAdaptation.shadow
        let baseColor = KingColors.glassShadow
        
        // 모션 감소 설정 시 그림자 효과 최소화
        let motionMultiplier = reduceMotion ? 0.5 : 1.0
        
        switch theme {
        case .system:
            return baseColor.opacity(effectLevel.opacity * 0.3 * motionMultiplier)
        case .light:
            return baseColor.opacity(adaptation.light * motionMultiplier)
        case .dark:
            return Color.black.opacity(adaptation.dark * motionMultiplier)
        case .vibrant:
            return baseColor.opacity(adaptation.vibrant * motionMultiplier)
        }
    }
    
    /// 효과 레벨에 따른 그림자 반경
    private var effectiveShadowRadius: CGFloat {
        let baseRadius = effectLevel.shadowRadius
        
        switch theme {
        case .system:
            return baseRadius
        case .light:
            return baseRadius * 0.7
        case .dark:
            return baseRadius * 1.2
        case .vibrant:
            return baseRadius * 1.5
        }
    }
    
    /// 효과 레벨에 따른 그림자 오프셋
    private var effectiveShadowOffset: CGFloat {
        effectLevel.shadowOffset
    }
}


// MARK: - Convenience Extensions

public extension View {
    /// 새로운 4단계 Glass Card 적용 (권장)
    func glassCard(
        level: GlassTokens.EffectLevel,
        context: GlassTokens.Context = .card,
        cornerRadius: CGFloat? = nil
    ) -> some View {
        GlassCard(level: level, context: context, cornerRadius: cornerRadius) {
            self
        }
    }
    
    
    /// 컨텍스트 기반 기본 Glass Card
    func glassCard(context: GlassTokens.Context = .card) -> some View {
        GlassCard(context: context) {
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
        .padding(DesignTokens.Spacing.lg)
        .glassCard(level: .prominent, context: .card)
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
                .frame(width: DesignTokens.Size.Icon.lg, height: DesignTokens.Size.Icon.lg)
            
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
        .padding(DesignTokens.Spacing.lg)
        .glassCard(level: .subtle, context: .card)
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
                        .padding(.vertical, DesignTokens.Spacing.md)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .glassCard(level: .standard, context: .card)
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
                .frame(width: DesignTokens.Size.Icon.lg, height: DesignTokens.Size.Icon.lg)
            
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
        .padding(DesignTokens.Spacing.lg)
        .glassCard(level: .subtle, context: .card)
    }
}

// MARK: - Advanced Glass Components (2024 최적화)

/// Vibrancy 효과가 있는 동적 Glass 카드
public struct VibrancyGlassCard<Content: View>: View {
    let content: Content
    let level: GlassTokens.EffectLevel
    
    @State private var animationPhase: CGFloat = 0
    @State private var isPressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    public init(
        level: GlassTokens.EffectLevel,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.level = level
    }
    
    public var body: some View {
        content
            .background(
                ZStack {
                    // 기본 Material
                    RoundedRectangle(cornerRadius: 16)
                        .fill(level.material)
                    
                    // 동적 Vibrancy 레이어 (모션 감소 설정 시 비활성화)
                    if !reduceMotion {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        KingColors.glassVibrancy.opacity(0.4 + animationPhase * 0.2),
                                        Color.clear,
                                        KingColors.glassVibrancy.opacity(0.2 + animationPhase * 0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .onAppear {
                if !reduceMotion {
                    withAnimation(.easeInOut(duration: 6.0).repeatForever(autoreverses: true)) {
                        animationPhase = 1.0
                    }
                }
            }
            .onTapGesture {
                if !reduceMotion {
                    withAnimation(.spring(duration: 0.2)) {
                        isPressed.toggle()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.spring(duration: 0.2)) {
                            isPressed = false
                        }
                    }
                }
            }
    }
}


// MARK: - Convenience Extensions for Vibrancy Glass

public extension View {
    /// Vibrancy 효과가 있는 Glass Card 적용
    func vibrancyGlassCard(level: GlassTokens.EffectLevel) -> some View {
        VibrancyGlassCard(level: level) {
            self
        }
    }
}

#Preview("Default Theme") {
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
    .environment(\.glassTheme, .system)
}

#Preview("Vibrant Theme") {
    ScrollView {
        VStack(spacing: 20) {
            BalanceCard(balance: "2.5", symbol: "ETH", usdValue: "$4,250.00")
            
            TransactionCard(
                type: .send,
                amount: "1.2",
                symbol: "ETH",
                timestamp: "방금 전",
                status: .pending
            )
            
            InfoCard(
                icon: "network",
                title: "네트워크",
                subtitle: "이더리움 메인넷",
                value: "ETH",
                style: .success
            )
        }
        .padding()
    }
    .background(
        LinearGradient(
            colors: [.systemPink, .systemOrange],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
    .environment(\.glassTheme, .vibrant)
}

#Preview("Dark Theme") {
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
        }
        .padding()
    }
    .background(Color.black)
    .preferredColorScheme(.dark)
    .environment(\.glassTheme, .dark)
}
