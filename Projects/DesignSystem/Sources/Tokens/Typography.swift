import SwiftUI
import Core

// MARK: - App-Specific Font Extensions
// Avoiding conflicts with SwiftUI Core by using unique naming
@MainActor
public extension Font {
    
    // MARK: - App Typography Styles
    // Custom styles that maintain iOS aesthetic while avoiding SwiftUI conflicts
    static let appLargeTitle = Font.largeTitle.weight(.bold)
    static let appTitle = Font.title.weight(.semibold)
    static let appTitle2 = Font.title2.weight(.semibold)
    static let appTitle3 = Font.title3.weight(.medium)
    static let appHeadline = Font.headline.weight(.semibold)
    static let appSubheadline = Font.subheadline.weight(.medium)
    static let appBody = Font.body.weight(.regular)
    static let appBodyEmphasized = Font.body.weight(.semibold)
    static let appCallout = Font.callout.weight(.regular)
    static let appFootnote = Font.footnote.weight(.regular)
    static let appCaption = Font.caption.weight(.regular)
    static let appCaption2 = Font.caption2.weight(.regular)
    
    // MARK: - Ethereum/Crypto Specific
    static let ethereumAddress = Font.system(.body, design: .monospaced).weight(.medium)
    static let transactionHash = Font.system(.footnote, design: .monospaced).weight(.regular)
    static let cryptoBalance = Font.system(.largeTitle, design: .default).weight(.semibold)
    static let cryptoBalanceSmall = Font.system(.title2, design: .default).weight(.medium)
    
    // MARK: - UI Elements (Native iOS Style)
    static let buttonLabel = Font.headline.weight(.semibold)
    static let navigationTitle = Font.headline.weight(.bold)
    static let listRowTitle = Font.body.weight(.regular)
    static let listRowSubtitle = Font.subheadline.weight(.regular)
    
    // MARK: - Numerical Values
    static let currencyValue = Font.system(.title, design: .default).weight(.medium)
    static let currencyLarge = Font.system(.largeTitle, design: .default).weight(.semibold)
    static let percentageValue = Font.callout.weight(.medium)
    
    // MARK: - Legacy Support for Phase 2.4
    static let cryptoBalanceLarge = Font.system(.largeTitle, design: .default).weight(.semibold)
}

// MARK: - Phase 2.6: Kingthereum Minimal Typography
// 극도 미니멀리즘에 최적화된 타이포그래피 시스템
public struct KingTypography {
    private init() {}
    
    // MARK: - Modern Minimalism Typography
    
    /// Clean Display - 극도로 미니멀한 대형 텍스트 (헤더용)
    public static let cleanDisplay = Font.system(.largeTitle, design: .default, weight: .ultraLight)
    
    /// Trust Headline - 신뢰감 있는 제목 (섹션 제목용)
    public static let trustHeadline = Font.system(.title3, design: .default, weight: .medium)
    
    /// Minimalist Body - 미니멀한 본문 텍스트
    public static let minimalistBody = Font.system(.callout, design: .default, weight: .regular)
    
    /// Subtle Caption - 서브틀한 캡션 (부가 정보용)
    public static let subtleCaption = Font.system(.caption, design: .default, weight: .light)
    
    // MARK: - Legacy Support (기존 호환성)
    
    /// 기존 호환성을 위한 타이포그래피들
    public static let displaySmall = Font.system(.title, design: .default, weight: .bold)
    public static let headlineSmall = Font.system(.headline, design: .default, weight: .bold)
    public static let bodyMedium = Font.system(.body, design: .default, weight: .medium)
    public static let bodySmall = Font.system(.callout, design: .default, weight: .regular)
    public static let labelLarge = Font.system(.callout, design: .default, weight: .semibold)
    public static let labelMedium = Font.system(.footnote, design: .default, weight: .medium)
    public static let caption = Font.system(.caption, design: .default, weight: .regular)
    
    /// 버튼용 타이포그래피
    public static let buttonPrimary = Font.system(.callout, design: .default, weight: .semibold)
    public static let buttonSecondary = Font.system(.footnote, design: .default, weight: .medium)
    
    /// 암호화폐 관련
    public static let cryptoBalanceLarge = Font.system(.largeTitle, design: .default, weight: .semibold)
}

// MARK: - Native iOS Text Styles
@MainActor
public struct NativeTextStyle: Sendable {
    public let font: Font
    public let color: Color
    public let lineLimit: Int?
    public let multilineTextAlignment: TextAlignment
    
    public init(
        font: Font,
        color: Color = .primary,
        lineLimit: Int? = nil,
        multilineTextAlignment: TextAlignment = .leading
    ) {
        self.font = font
        self.color = color
        self.lineLimit = lineLimit
        self.multilineTextAlignment = multilineTextAlignment
    }
    
    // MARK: - Standard iOS Text Styles
    public static let largeTitle = NativeTextStyle(
        font: .largeTitle,
        color: .primary
    )
    
    public static let title = NativeTextStyle(
        font: .title,
        color: .primary
    )
    
    public static let title2 = NativeTextStyle(
        font: .title2,
        color: .primary
    )
    
    public static let title3 = NativeTextStyle(
        font: .title3,
        color: .primary
    )
    
    public static let headline = NativeTextStyle(
        font: .headline,
        color: .primary
    )
    
    public static let subheadline = NativeTextStyle(
        font: .subheadline,
        color: .secondary
    )
    
    public static let body = NativeTextStyle(
        font: .body,
        color: .primary
    )
    
    public static let callout = NativeTextStyle(
        font: .callout,
        color: .primary
    )
    
    public static let footnote = NativeTextStyle(
        font: .footnote,
        color: .secondary
    )
    
    public static let caption = NativeTextStyle(
        font: .caption,
        color: .secondary
    )
    
    public static let caption2 = NativeTextStyle(
        font: .caption2,
        color: .secondary
    )
    
    // MARK: - App Specific Styles
    public static let balance = NativeTextStyle(
        font: .cryptoBalance,
        color: .primary,
        multilineTextAlignment: .trailing
    )
    
    public static let address = NativeTextStyle(
        font: .ethereumAddress,
        color: .secondary,
        lineLimit: 1
    )
    
    public static let navigationTitle = NativeTextStyle(
        font: .navigationTitle,
        color: .primary
    )
    
    public static let buttonLabel = NativeTextStyle(
        font: .buttonLabel,
        color: .white
    )
    
    // MARK: - Semantic Styles
    public static let error = NativeTextStyle(
        font: .footnote,
        color: .red
    )
    
    public static let success = NativeTextStyle(
        font: .footnote,
        color: .green
    )
    
    public static let warning = NativeTextStyle(
        font: .footnote,
        color: .orange
    )
    
    public static let link = NativeTextStyle(
        font: .body,
        color: .blue
    )
}

// MARK: - Text View Extension for Native Styles
public extension Text {
    func nativeStyle(_ style: NativeTextStyle) -> some View {
        self
            .font(style.font)
            .foregroundColor(style.color)
            .lineLimit(style.lineLimit)
            .multilineTextAlignment(style.multilineTextAlignment)
    }
    
    // DEPRECATED: Use KingTypography.KingTextStyle instead
    // func kingStyle(_ style: NativeTextStyle) -> some View {
    //     self.nativeStyle(style)
    // }
}

// MARK: - Native Text Components
public struct NativeText: View {
    let text: String
    let style: NativeTextStyle
    
    public init(_ text: String, style: NativeTextStyle) {
        self.text = text
        self.style = style
    }
    
    public var body: some View {
        Text(text)
            .nativeStyle(style)
    }
}

public struct EthereumAddressText: View {
    let address: String
    let length: Int
    
    public init(_ address: String, length: Int = 6) {
        self.address = address
        self.length = length
    }
    
    public var body: some View {
        Text(Formatters.formatAddress(address, length: length))
            .nativeStyle(.address)
    }
}

public struct CryptoBalanceText: View {
    let balance: String
    let symbol: String
    let style: NativeTextStyle
    
    public init(balance: String, symbol: String, style: NativeTextStyle = .balance) {
        self.balance = balance
        self.symbol = symbol
        self.style = style
    }
    
    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(balance)
                .nativeStyle(style)
            
            Text(symbol)
                .nativeStyle(NativeTextStyle(
                    font: .body.weight(.medium),
                    color: style.color
                ))
        }
    }
}

#Preview {
    ScrollView {
        VStack(alignment: .leading, spacing: 16) {
            Group {
                NativeText("Large Title", style: .largeTitle)
                NativeText("Title", style: .title)
                NativeText("Title 2", style: .title2)
                NativeText("Title 3", style: .title3)
                NativeText("Headline", style: .headline)
            }
            
            Group {
                NativeText("Subheadline", style: .subheadline)
                NativeText("Body text with regular weight", style: .body)
                NativeText("Callout text", style: .callout)
                NativeText("Footnote text", style: .footnote)
                NativeText("Caption text", style: .caption)
            }
            
            Divider()
            
            Group {
                EthereumAddressText("0x1234567890abcdef1234567890abcdef12345678")
                CryptoBalanceText(balance: "1.234", symbol: "ETH")
                
                NativeText("Error Message", style: .error)
                NativeText("Success Message", style: .success) 
                NativeText("Warning Message", style: .warning)
                NativeText("Link Text", style: .link)
            }
        }
        .padding()
    }
    .background(Color(.systemBackground))
}
