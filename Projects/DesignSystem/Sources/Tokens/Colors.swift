import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Native Apple Color System with App-Specific Extensions
/// Based on Apple Human Interface Guidelines color specifications
public extension Color {
    
    // MARK: - Apple System Colors (iOS 13+)
    // These colors automatically adapt to light/dark mode and accessibility settings
    
    /// Primary system label color - adapts to user's appearance settings
    static let systemLabel = Color(.label)
    /// Secondary system label color - for less prominent text
    static let systemSecondaryLabel = Color(.secondaryLabel)
    /// Tertiary system label color - for placeholder text and subtle content
    static let systemTertiaryLabel = Color(.tertiaryLabel)
    /// Quaternary system label color - for watermarks and subtle details
    static let systemQuaternaryLabel = Color(.quaternaryLabel)
    
    // MARK: - System Background Colors
    /// Primary system background - main app background
    static let systemBackground = Color(.systemBackground)
    /// Secondary system background - elevated content background
    static let systemSecondaryBackground = Color(.secondarySystemBackground)
    /// Tertiary system background - for grouped content
    static let systemTertiaryBackground = Color(.tertiarySystemBackground)
    
    // MARK: - Grouped Background Colors (for lists and grouped content)
    /// Primary grouped background
    static let systemGroupedBackground = Color(.systemGroupedBackground)
    /// Secondary grouped background
    static let systemSecondaryGroupedBackground = Color(.secondarySystemGroupedBackground)
    /// Tertiary grouped background
    static let systemTertiaryGroupedBackground = Color(.tertiarySystemGroupedBackground)
    
    // MARK: - System Fill Colors
    /// Primary fill color for thin and small shapes
    static let systemFill = Color(.systemFill)
    /// Secondary fill color
    static let systemSecondaryFill = Color(.secondarySystemFill)
    /// Tertiary fill color
    static let systemTertiaryFill = Color(.tertiarySystemFill)
    /// Quaternary fill color
    static let systemQuaternaryFill = Color(.quaternarySystemFill)
    
    // MARK: - System Separator Colors
    /// Standard separator color
    static let systemSeparator = Color(.separator)
    /// Opaque separator color
    static let systemOpaqueSeparator = Color(.opaqueSeparator)
    
    // MARK: - Standard System Colors
    static let systemRed = Color(.systemRed)
    static let systemOrange = Color(.systemOrange)
    static let systemYellow = Color(.systemYellow)
    static let systemGreen = Color(.systemGreen)
    static let systemMint = Color(.systemMint)
    static let systemTeal = Color(.systemTeal)
    static let systemCyan = Color(.systemCyan)
    static let systemBlue = Color(.systemBlue)
    static let systemIndigo = Color(.systemIndigo)
    static let systemPurple = Color(.systemPurple)
    static let systemPink = Color(.systemPink)
    static let systemBrown = Color(.systemBrown)
    
    // MARK: - System Gray Colors
    static let systemGray = Color(.systemGray)
    static let systemGray2 = Color(.systemGray2)
    static let systemGray3 = Color(.systemGray3)
    static let systemGray4 = Color(.systemGray4)
    static let systemGray5 = Color(.systemGray5)
    static let systemGray6 = Color(.systemGray6)
    
    // MARK: - App Branding Colors
    // Custom colors for Kingthereum while maintaining system compatibility
    
    /// Kingthereum의 상징적인 파란색 - system blue based
    static let kingBlue = Color(.systemBlue)
    /// Kingthereum의 상징적인 보라색 - system purple based  
    static let kingPurple = Color(.systemPurple)
    /// Kingthereum의 상징적인 금색 - system orange based for gold effect
    static let kingGold = Color(.systemOrange)
    
    // MARK: - Ethereum Brand Colors
    /// Ethereum brand blue with system compatibility
    static let ethereumBlue = Color(.systemBlue)
    /// Ethereum secondary color
    static let ethereumGray = Color(.systemGray)
    
    // MARK: - Semantic Colors (iOS Native)
    /// Success color using system green
    static let successGreen = Color(.systemGreen)
    /// Warning color using system orange
    static let warningOrange = Color(.systemOrange)
    /// Error color using system red
    static let errorRed = Color(.systemRed)
    /// Info color using system blue
    static let infoBlue = Color(.systemBlue)
    
    // MARK: - Transaction State Colors
    /// Send transaction color (system red)
    static let sendRed = Color(.systemRed)
    /// Receive transaction color (system green)
    static let receiveGreen = Color(.systemGreen)
    /// Pending transaction color (system yellow)
    static let pendingYellow = Color(.systemYellow)
    /// Confirmed transaction color (system green)
    static let confirmedGreen = Color(.systemGreen)
    /// Failed transaction color (system red)
    static let failedRed = Color(.systemRed)
    
    // MARK: - Accessibility Support
    /// High contrast colors for accessibility
    static var accessiblePrimary: Color {
        Color(.label)
    }
    
    static var accessibleSecondary: Color {
        Color(.secondaryLabel)
    }
    
    // MARK: - Card and Surface Colors
    /// Card background using system grouped background
    static let cardBackground = Color(.systemGroupedBackground)
    /// Elevated card background
    static let elevatedCardBackground = Color(.secondarySystemBackground)
    /// Surface background
    static let surfaceBackground = Color(.systemBackground)
    
    // MARK: - Link and Interactive Colors
    /// System link color
    static let linkColor = Color(.link)
    /// Tint color (follows system accent color)
    static let systemAccent = Color.accentColor
}

// MARK: - Dynamic Color Support
public extension Color {
    /// Creates a color that adapts to the current color scheme
    /// - Parameters:
    ///   - light: Color for light appearance
    ///   - dark: Color for dark appearance
    /// - Returns: Dynamic color that changes based on appearance
    static func adaptive(light: Color, dark: Color) -> Color {
        #if canImport(UIKit)
        Color(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
        #elseif canImport(AppKit)
        Color(NSColor(name: nil) { appearance in
            let effectiveAppearance = appearance.bestMatch(from: [.aqua, .darkAqua])
            if effectiveAppearance == .darkAqua {
                return NSColor(dark)
            } else {
                return NSColor(light)
            }
        })
        #else
        light
        #endif
    }
    
    /// App-specific adaptive background
    static let appBackground = Color(.systemBackground)
    
    /// App-specific adaptive surface 
    static let appSurface = Color(.secondarySystemBackground)
    
    /// App-specific adaptive border
    static let appBorder = Color(.separator)
}

// MARK: - Gradient Support with System Colors
public extension LinearGradient {
    /// Primary brand gradient using system colors
    static let primaryGradient = LinearGradient(
        colors: [Color.kingBlue, Color.kingPurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Gold gradient using system orange variations
    static let goldGradient = LinearGradient(
        colors: [Color.systemOrange, Color.systemYellow],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Ethereum gradient using system blues
    static let ethereumGradient = LinearGradient(
        colors: [Color.systemBlue, Color.systemTeal],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Subtle background gradient
    static let backgroundGradient = LinearGradient(
        colors: [
            Color.systemBackground,
            Color.systemSecondaryBackground.opacity(0.8)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Enhanced background gradient for better visibility
    static let enhancedBackgroundGradient = LinearGradient(
        colors: [
            Color.systemBackground,
            Color.adaptive(
                light: Color.systemSecondaryBackground.opacity(0.4),
                dark: Color.systemSecondaryBackground.opacity(0.6)
            )
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Subtle primary accent gradient for buttons and interactive elements
    static let accentGradient = LinearGradient(
        colors: [Color.kingBlue.opacity(0.8), Color.kingPurple.opacity(0.6)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Success gradient using green tones
    static let successGradient = LinearGradient(
        colors: [Color.systemGreen, Color.systemMint],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Warning gradient using orange tones
    static let warningGradient = LinearGradient(
        colors: [Color.systemOrange, Color.systemYellow],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Error gradient using red tones
    static let errorGradient = LinearGradient(
        colors: [Color.systemRed, Color.systemPink],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - UIKit/AppKit Integration
#if canImport(UIKit)
public extension UIColor {
    /// King Blue UIColor equivalent
    static let kingBlue = UIColor.systemBlue
    /// King Purple UIColor equivalent  
    static let kingPurple = UIColor.systemPurple
    /// King Gold UIColor equivalent
    static let kingGold = UIColor.systemOrange
}
#elseif canImport(AppKit)
public extension NSColor {
    /// King Blue NSColor equivalent
    static let kingBlue = NSColor.systemBlue
    /// King Purple NSColor equivalent  
    static let kingPurple = NSColor.systemPurple
    /// King Gold NSColor equivalent
    static let kingGold = NSColor.systemOrange
}
#endif

// MARK: - Liquid Glass Color System
public extension Color {
    
    // MARK: - Glass Surface Colors (라이트/다크 모드 자동 대응)
    /// 프라이머리 글래스 서피스 - 메인 컨텐츠용
    static let glassPrimary = Color.adaptive(
        light: Color.white.opacity(0.85),
        dark: Color.black.opacity(0.75)
    )
    
    /// 세컨더리 글래스 서피스 - 카드/패널용
    static let glassSecondary = Color.adaptive(
        light: Color.white.opacity(0.65),
        dark: Color.black.opacity(0.55)
    )
    
    /// 서틀 글래스 서피스 - 서브틀한 오버레이용
    static let glassSubtle = Color.adaptive(
        light: Color.white.opacity(0.45),
        dark: Color.black.opacity(0.35)
    )
    
    // MARK: - Glass Border Colors
    /// 프라이머리 글래스 보더
    static let glassBorderPrimary = Color.adaptive(
        light: Color.white.opacity(0.3),
        dark: Color.white.opacity(0.15)
    )
    
    /// 세컨더리 글래스 보더
    static let glassBorderSecondary = Color.adaptive(
        light: Color.white.opacity(0.2),
        dark: Color.white.opacity(0.1)
    )
    
    /// 액센트 글래스 보더
    static let glassBorderAccent = Color.adaptive(
        light: Color.kingBlue.opacity(0.4),
        dark: Color.kingBlue.opacity(0.6)
    )
    
    // MARK: - Glass Shadow Colors
    /// 라이트 글래스 섀도우
    static let glassShadowLight = Color.adaptive(
        light: Color.black.opacity(0.08),
        dark: Color.black.opacity(0.4)
    )
    
    /// 미디엄 글래스 섀도우
    static let glassShadowMedium = Color.adaptive(
        light: Color.black.opacity(0.12),
        dark: Color.black.opacity(0.5)
    )
    
    /// 스트롱 글래스 섀도우
    static let glassShadowStrong = Color.adaptive(
        light: Color.black.opacity(0.18),
        dark: Color.black.opacity(0.6)
    )
    
    // MARK: - Interactive Glass Colors
    /// 액티브 글래스 (선택된 상태)
    static let glassActive = Color.adaptive(
        light: Color.kingBlue.opacity(0.15),
        dark: Color.kingBlue.opacity(0.35)
    )
    
    /// 호버 글래스 (마우스오버/터치)
    static let glassHover = Color.adaptive(
        light: Color.white.opacity(0.7),
        dark: Color.white.opacity(0.08)
    )
    
    /// 프레스드 글래스 (눌린 상태)
    static let glassPressed = Color.adaptive(
        light: Color.black.opacity(0.08),
        dark: Color.white.opacity(0.08)
    )
    
    // MARK: - Semantic Glass Colors
    /// 성공 글래스
    static let glassSuccess = Color.adaptive(
        light: Color.systemGreen.opacity(0.2),
        dark: Color.systemGreen.opacity(0.3)
    )
    
    /// 경고 글래스
    static let glassWarning = Color.adaptive(
        light: Color.systemOrange.opacity(0.2),
        dark: Color.systemOrange.opacity(0.3)
    )
    
    /// 에러 글래스
    static let glassError = Color.adaptive(
        light: Color.systemRed.opacity(0.2),
        dark: Color.systemRed.opacity(0.3)
    )
    
    /// 정보 글래스
    static let glassInfo = Color.adaptive(
        light: Color.systemBlue.opacity(0.2),
        dark: Color.systemBlue.opacity(0.3)
    )
    
    // MARK: - Enhanced Dark Mode Colors
    /// 다크모드에서 더 강한 대비를 위한 enhanced 컬러들
    
    /// Enhanced 글래스 보더 (다크모드 최적화)
    static let glassEnhancedBorder = Color.adaptive(
        light: Color.white.opacity(0.25),
        dark: Color.white.opacity(0.2)
    )
    
    /// Enhanced 글래스 배경 (다크모드 최적화)
    static let glassEnhancedBackground = Color.adaptive(
        light: Color.white.opacity(0.8),
        dark: Color.black.opacity(0.85)
    )
    
    /// Enhanced 텍스트 대비 (다크모드 최적화)
    static let glassEnhancedText = Color.adaptive(
        light: Color.primary,
        dark: Color.primary.opacity(0.95)
    )
}

// MARK: - Material Design for Glass Effects
public extension Material {
    /// Ultra thin glass material for subtle effects
    static let glassUltraThin: Material = .ultraThinMaterial
    /// Thin glass material
    static let glassThin: Material = .thinMaterial
    /// Regular glass material 
    static let glassRegular: Material = .regularMaterial
    /// Thick glass material
    static let glassThick: Material = .thickMaterial
    /// Ultra thick glass material for strong effects
    static let glassUltraThick: Material = .ultraThickMaterial
}

// MARK: - Preview Support
#Preview {
    ScrollView {
        VStack(spacing: 20) {
            // System Colors Section
            GroupBox("System Colors") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                    ForEach([
                        ("Blue", Color.systemBlue),
                        ("Purple", Color.systemPurple), 
                        ("Orange", Color.systemOrange),
                        ("Green", Color.systemGreen),
                        ("Red", Color.systemRed),
                        ("Yellow", Color.systemYellow)
                    ], id: \.0) { name, color in
                        VStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(color)
                                .frame(height: 40)
                            Text(name)
                                .font(.caption)
                                .foregroundColor(.systemSecondaryLabel)
                        }
                    }
                }
                .padding()
            }
            
            // Background Colors Section
            GroupBox("Background Colors") {
                VStack(spacing: 8) {
                    HStack {
                        Text("Primary")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.systemBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.systemSeparator, lineWidth: 1)
                            )
                            .frame(width: 60, height: 30)
                    }
                    
                    HStack {
                        Text("Secondary") 
                            .frame(maxWidth: .infinity, alignment: .leading)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.systemSecondaryBackground)
                            .frame(width: 60, height: 30)
                    }
                    
                    HStack {
                        Text("Tertiary")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.systemTertiaryBackground)
                            .frame(width: 60, height: 30)
                    }
                }
                .padding()
            }
            
            // Label Colors Section
            GroupBox("Label Colors") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Primary Label")
                        .foregroundColor(.systemLabel)
                    Text("Secondary Label")
                        .foregroundColor(.systemSecondaryLabel)
                    Text("Tertiary Label")
                        .foregroundColor(.systemTertiaryLabel)
                    Text("Quaternary Label")
                        .foregroundColor(.systemQuaternaryLabel)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            
            // App Specific Colors
            GroupBox("Kingthereum Brand Colors") {
                HStack(spacing: 20) {
                    VStack {
                        Circle()
                            .fill(Color.kingBlue)
                            .frame(width: 50, height: 50)
                        Text("King Blue")
                            .font(.caption)
                    }
                    
                    VStack {
                        Circle()
                            .fill(Color.kingPurple)
                            .frame(width: 50, height: 50)
                        Text("King Purple")
                            .font(.caption)
                    }
                    
                    VStack {
                        Circle()
                            .fill(Color.kingGold)
                            .frame(width: 50, height: 50)
                        Text("King Gold")
                            .font(.caption)
                    }
                }
                .padding()
            }
        }
        .padding()
    }
    .background(Color.systemBackground)
}
