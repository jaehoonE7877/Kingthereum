import SwiftUI
import Core

/// King 앱 전용 모던 타이포그래피 시스템
/// KingColors와 완벽하게 통합된 텍스트 스타일링
public struct KingTypography {
    
    // MARK: - Display Fonts (Large Headings)
    
    /// 대형 디스플레이 폰트 - 메인 화면 타이틀용
    public static let displayLarge = Font.system(size: 32, weight: .bold, design: .rounded)
    
    /// 중형 디스플레이 폰트 - 섹션 헤더용
    public static let displayMedium = Font.system(size: 28, weight: .semibold, design: .rounded)
    
    /// 소형 디스플레이 폰트 - 카드 타이틀용
    public static let displaySmall = Font.system(size: 24, weight: .semibold, design: .default)
    
    // MARK: - Headline Fonts
    
    /// 대형 헤드라인
    public static let headlineLarge = Font.system(size: 24, weight: .semibold, design: .default)
    
    /// 중형 헤드라인
    public static let headlineMedium = Font.system(size: 20, weight: .semibold, design: .default)
    
    /// 소형 헤드라인
    public static let headlineSmall = Font.system(size: 18, weight: .medium, design: .default)
    
    // MARK: - Body Text Fonts
    
    /// 대형 본문
    public static let bodyLarge = Font.system(size: 16, weight: .regular, design: .default)
    
    /// 중형 본문 (기본)
    public static let bodyMedium = Font.system(size: 14, weight: .regular, design: .default)
    
    /// 소형 본문
    public static let bodySmall = Font.system(size: 12, weight: .regular, design: .default)
    
    /// 강조된 본문
    public static let bodyEmphasized = Font.system(size: 16, weight: .semibold, design: .default)
    
    // MARK: - Label Fonts
    
    /// 대형 라벨 - 버튼, 중요한 라벨
    public static let labelLarge = Font.system(size: 14, weight: .medium, design: .default)
    
    /// 중형 라벨 - 일반 라벨
    public static let labelMedium = Font.system(size: 12, weight: .medium, design: .default)
    
    /// 소형 라벨 - 서브틀한 라벨
    public static let labelSmall = Font.system(size: 10, weight: .medium, design: .default)
    
    // MARK: - Caption & Helper Text
    
    /// 캡션 텍스트
    public static let caption = Font.system(size: 11, weight: .regular, design: .default)
    
    /// 헬퍼 텍스트
    public static let helper = Font.system(size: 10, weight: .regular, design: .default)
    
    // MARK: - Crypto & Web3 Specific
    
    /// 이더리움 주소용 모노스페이스
    public static let ethereumAddress = Font.system(size: 14, weight: .medium, design: .monospaced)
    
    /// 트랜잭션 해시용 모노스페이스
    public static let transactionHash = Font.system(size: 12, weight: .regular, design: .monospaced)
    
    /// 크립토 잔고 - 대형
    public static let cryptoBalanceLarge = Font.system(size: 32, weight: .semibold, design: .default)
    
    /// 크립토 잔고 - 중형
    public static let cryptoBalanceMedium = Font.system(size: 20, weight: .medium, design: .default)
    
    /// 크립토 잔고 - 소형
    public static let cryptoBalanceSmall = Font.system(size: 16, weight: .medium, design: .default)
    
    // MARK: - Interactive Elements
    
    /// 버튼 라벨
    public static let buttonPrimary = Font.system(size: 16, weight: .semibold, design: .default)
    
    /// 세컨더리 버튼 라벨
    public static let buttonSecondary = Font.system(size: 14, weight: .medium, design: .default)
    
    /// 네비게이션 타이틀
    public static let navigationTitle = Font.system(size: 18, weight: .semibold, design: .default)
    
    /// 탭 바 라벨
    public static let tabBar = Font.system(size: 10, weight: .medium, design: .default)
    
    // MARK: - Status & Alert Text
    
    /// 알럿 타이틀
    public static let alertTitle = Font.system(size: 17, weight: .semibold, design: .default)
    
    /// 알럿 메시지
    public static let alertMessage = Font.system(size: 13, weight: .regular, design: .default)
    
    /// 상태 텍스트
    public static let status = Font.system(size: 12, weight: .medium, design: .default)
}

// MARK: - Text Style Definitions
/// 색상과 폰트가 결합된 완전한 텍스트 스타일 정의
public struct KingTextStyle: Sendable {
    public let font: Font
    public let color: Color
    public let lineLimit: Int?
    public let alignment: TextAlignment
    
    public init(
        font: Font,
        color: Color,
        lineLimit: Int? = nil,
        alignment: TextAlignment = .leading
    ) {
        self.font = font
        self.color = color
        self.lineLimit = lineLimit
        self.alignment = alignment
    }
}

// MARK: - Predefined Text Styles
public extension KingTextStyle {
    
    // MARK: - Primary Styles
    
    /// 메인 디스플레이 스타일
    static let displayPrimary = KingTextStyle(
        font: KingTypography.displayLarge,
        color: KingColors.textPrimary
    )
    
    /// 헤드라인 스타일
    static let headlinePrimary = KingTextStyle(
        font: KingTypography.headlineLarge,
        color: KingColors.textPrimary
    )
    
    /// 기본 본문 스타일
    static let bodyPrimary = KingTextStyle(
        font: KingTypography.bodyMedium,
        color: KingColors.textPrimary
    )
    
    /// 세컨더리 본문 스타일
    static let bodySecondary = KingTextStyle(
        font: KingTypography.bodyMedium,
        color: KingColors.textSecondary
    )
    
    /// 캡션 스타일
    static let captionPrimary = KingTextStyle(
        font: KingTypography.caption,
        color: KingColors.textTertiary
    )
    
    // MARK: - Button Styles
    
    /// 프라이머리 버튼 스타일
    static let buttonPrimary = KingTextStyle(
        font: KingTypography.buttonPrimary,
        color: KingColors.textInverse,
        alignment: .center
    )
    
    /// 세컨더리 버튼 스타일
    static let buttonSecondary = KingTextStyle(
        font: KingTypography.buttonSecondary,
        color: KingColors.accent,
        alignment: .center
    )
    
    /// 링크 스타일
    static let link = KingTextStyle(
        font: KingTypography.bodyMedium,
        color: KingColors.link
    )
    
    // MARK: - Crypto Specific Styles
    
    /// 크립토 잔고 대형 스타일
    static let cryptoBalanceLarge = KingTextStyle(
        font: KingTypography.cryptoBalanceLarge,
        color: KingColors.textPrimary,
        alignment: .trailing
    )
    
    /// 크립토 잔고 중형 스타일
    static let cryptoBalanceMedium = KingTextStyle(
        font: KingTypography.cryptoBalanceMedium,
        color: KingColors.textPrimary,
        alignment: .trailing
    )
    
    /// 이더리움 주소 스타일
    static let ethereumAddress = KingTextStyle(
        font: KingTypography.ethereumAddress,
        color: KingColors.textSecondary,
        lineLimit: 1
    )
    
    /// 트랜잭션 해시 스타일
    static let transactionHash = KingTextStyle(
        font: KingTypography.transactionHash,
        color: KingColors.textTertiary,
        lineLimit: 1
    )
    
    // MARK: - Semantic Styles
    
    /// 성공 메시지 스타일
    static let success = KingTextStyle(
        font: KingTypography.status,
        color: KingColors.success
    )
    
    /// 경고 메시지 스타일
    static let warning = KingTextStyle(
        font: KingTypography.status,
        color: KingColors.warning
    )
    
    /// 에러 메시지 스타일
    static let error = KingTextStyle(
        font: KingTypography.status,
        color: KingColors.error
    )
    
    /// 정보 메시지 스타일
    static let info = KingTextStyle(
        font: KingTypography.status,
        color: KingColors.info
    )
    
    // MARK: - Navigation & Interface Styles
    
    /// 네비게이션 타이틀 스타일
    static let navigationTitle = KingTextStyle(
        font: KingTypography.navigationTitle,
        color: KingColors.textPrimary,
        alignment: .center
    )
    
    /// 탭 바 라벨 스타일
    static let tabBarLabel = KingTextStyle(
        font: KingTypography.tabBar,
        color: KingColors.textSecondary,
        alignment: .center
    )
    
    /// 탭 바 선택된 라벨 스타일
    static let tabBarLabelSelected = KingTextStyle(
        font: KingTypography.tabBar,
        color: KingColors.accent,
        alignment: .center
    )
    
    // MARK: - Card & List Styles
    
    /// 카드 타이틀 스타일
    static let cardTitle = KingTextStyle(
        font: KingTypography.headlineSmall,
        color: KingColors.textPrimary
    )
    
    /// 카드 서브타이틀 스타일
    static let cardSubtitle = KingTextStyle(
        font: KingTypography.bodySmall,
        color: KingColors.textSecondary
    )
    
    /// 리스트 아이템 타이틀 스타일
    static let listTitle = KingTextStyle(
        font: KingTypography.bodyLarge,
        color: KingColors.textPrimary
    )
    
    /// 리스트 아이템 서브타이틀 스타일
    static let listSubtitle = KingTextStyle(
        font: KingTypography.bodySmall,
        color: KingColors.textSecondary
    )
}

// MARK: - Text View Extensions
public extension Text {
    
    /// KingTextStyle 적용
    func kingStyle(_ style: KingTextStyle) -> some View {
        self
            .font(style.font)
            .foregroundColor(style.color)
            .lineLimit(style.lineLimit)
            .multilineTextAlignment(style.alignment)
    }
}

// MARK: - Specialized Text Components
public struct KingText: View {
    let text: String
    let style: KingTextStyle
    
    public init(_ text: String, style: KingTextStyle) {
        self.text = text
        self.style = style
    }
    
    public var body: some View {
        Text(text)
            .kingStyle(style)
    }
}

public struct KingCryptoBalanceText: View {
    let balance: String
    let symbol: String
    let style: KingTextStyle
    
    public init(balance: String, symbol: String, style: KingTextStyle = .cryptoBalanceMedium) {
        self.balance = balance
        self.symbol = symbol
        self.style = style
    }
    
    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(balance)
                .kingStyle(style)
            
            Text(symbol)
                .kingStyle(KingTextStyle(
                    font: KingTypography.labelLarge,
                    color: style.color
                ))
        }
    }
}

public struct KingEthereumAddressText: View {
    let address: String
    let length: Int
    
    public init(_ address: String, length: Int = 6) {
        self.address = address
        self.length = length
    }
    
    public var body: some View {
        Text(formatAddress(address, length: length))
            .kingStyle(.ethereumAddress)
    }
    
    private func formatAddress(_ address: String, length: Int) -> String {
        guard address.count > length * 2 + 2 else { return address }
        let start = String(address.prefix(length + 2))
        let end = String(address.suffix(length))
        return "\(start)...\(end)"
    }
}

// MARK: - Preview Support
#Preview("Kingthereum Typography") {
    ScrollView {
        VStack(alignment: .leading, spacing: 24) {
            // Display Fonts
            VStack(alignment: .leading, spacing: 12) {
                KingText("Display Fonts", style: .headlinePrimary)
                
                VStack(alignment: .leading, spacing: 8) {
                    KingText("Large Display", style: .displayPrimary)
                    KingText("Medium Display", style: KingTextStyle(
                        font: KingTypography.displayMedium,
                        color: KingColors.textPrimary
                    ))
                    KingText("Small Display", style: KingTextStyle(
                        font: KingTypography.displaySmall,
                        color: KingColors.textPrimary
                    ))
                }
            }
            
            Divider()
            
            // Body Text
            VStack(alignment: .leading, spacing: 12) {
                KingText("Body Text", style: .headlinePrimary)
                
                VStack(alignment: .leading, spacing: 8) {
                    KingText("Primary body text example", style: .bodyPrimary)
                    KingText("Secondary body text example", style: .bodySecondary)
                    KingText("Caption text example", style: .captionPrimary)
                }
            }
            
            Divider()
            
            // Crypto Specific
            VStack(alignment: .leading, spacing: 12) {
                KingText("Crypto Elements", style: .headlinePrimary)
                
                VStack(alignment: .leading, spacing: 8) {
                    KingCryptoBalanceText(balance: "1.234567", symbol: "ETH")
                    KingEthereumAddressText("0x1234567890abcdef1234567890abcdef12345678")
                }
            }
            
            Divider()
            
            // Semantic Colors
            VStack(alignment: .leading, spacing: 12) {
                KingText("Semantic Messages", style: .headlinePrimary)
                
                VStack(alignment: .leading, spacing: 8) {
                    KingText("Success message", style: .success)
                    KingText("Warning message", style: .warning)
                    KingText("Error message", style: .error)
                    KingText("Info message", style: .info)
                }
            }
            
            Divider()
            
            // Buttons
            VStack(alignment: .leading, spacing: 12) {
                KingText("Button Styles", style: .headlinePrimary)
                
                VStack(spacing: 12) {
                    // Primary Button Preview
                    Rectangle()
                        .fill(KingGradients.buttonPrimary)
                        .frame(height: 48)
                        .overlay(
                            KingText("Primary Button", style: .buttonPrimary)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Secondary Button Preview
                    Rectangle()
                        .fill(KingGradients.buttonSecondary)
                        .frame(height: 48)
                        .overlay(
                            KingText("Secondary Button", style: .buttonSecondary)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(KingColors.accent, lineWidth: 1.5)
                        )
                }
            }
        }
        .padding()
    }
    .background(KingColors.backgroundPrimary)
}