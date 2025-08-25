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
    
    // Backward compatibility with existing kingStyle
    func kingStyle(_ style: NativeTextStyle) -> some View {
        self.nativeStyle(style)
    }
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
