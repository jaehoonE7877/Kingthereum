import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// King 앱 전용 모던 색상 시스템
/// 라이트/다크 모드에 자연스럽게 어울리는 일관된 색상 팔레트
public struct KingColors {
    
    // MARK: - Primary Brand Colors
    
    /// 메인 브랜드 색상 - 딥 네이비
    public static let primaryDark = Color.kingAdaptive(
        light: Color(hex: "#1A1B23"),
        dark: Color(hex: "#0F0F0F")
    )
    
    /// 라이트 브랜드 색상
    public static let primaryLight = Color.kingAdaptive(
        light: Color(hex: "#2A2D39"),
        dark: Color(hex: "#1A1A1A")
    )
    
    /// 메인 액센트 색상 - 세련된 블루
    public static let accent = Color.kingAdaptive(
        light: Color(hex: "#4C6EF5"),
        dark: Color(hex: "#5C7CFA")
    )
    
    /// 세컨더리 액센트 - 퍼플
    public static let accentSecondary = Color.kingAdaptive(
        light: Color(hex: "#7C3AED"),
        dark: Color(hex: "#8B5CF6")
    )
    
    // MARK: - Background Hierarchy
    
    /// 메인 배경색
    public static let backgroundPrimary = Color.kingAdaptive(
        light: Color(hex: "#FFFFFF"),
        dark: Color(hex: "#000000")
    )
    
    /// 세컨더리 배경색 - 카드 등
    public static let backgroundSecondary = Color.kingAdaptive(
        light: Color(hex: "#F8F9FA"),
        dark: Color(hex: "#111111")
    )
    
    /// 터셔리 배경색 - 그룹된 컨텐츠
    public static let backgroundTertiary = Color.kingAdaptive(
        light: Color(hex: "#E9ECEF"),
        dark: Color(hex: "#1F1F1F")
    )
    
    /// 서피스 배경색 - 엘리베이티드 컨텐츠
    public static let surface = Color.kingAdaptive(
        light: Color(hex: "#FFFFFF"),
        dark: Color(hex: "#161616")
    )
    
    // MARK: - Card & Surface Colors
    
    /// 카드 배경색
    public static let cardBackground = Color.kingAdaptive(
        light: Color(hex: "#FFFFFF"),
        dark: Color(hex: "#1A1A1A")
    )
    
    /// 카드 보더색
    public static let cardBorder = Color.kingAdaptive(
        light: Color(hex: "#E5E7EB"),
        dark: Color(hex: "#374151")
    )
    
    /// 카드 섀도우색
    public static let cardShadow = Color.kingAdaptive(
        light: Color(hex: "#000000").opacity(0.04),
        dark: Color(hex: "#000000").opacity(0.2)
    )
    
    /// 엘리베이티드 카드 배경
    public static let cardElevated = Color.kingAdaptive(
        light: Color(hex: "#FFFFFF"),
        dark: Color(hex: "#262626")
    )
    
    // MARK: - Text Hierarchy
    
    /// 메인 텍스트 색상
    public static let textPrimary = Color.kingAdaptive(
        light: Color(hex: "#111827"),
        dark: Color(hex: "#F9FAFB")
    )
    
    /// 세컨더리 텍스트 색상
    public static let textSecondary = Color.kingAdaptive(
        light: Color(hex: "#6B7280"),
        dark: Color(hex: "#D1D5DB")
    )
    
    /// 터셔리 텍스트 색상 - 서브틀한 내용
    public static let textTertiary = Color.kingAdaptive(
        light: Color(hex: "#9CA3AF"),
        dark: Color(hex: "#9CA3AF")
    )
    
    /// 플레이스홀더 텍스트 색상
    public static let textPlaceholder = Color.kingAdaptive(
        light: Color(hex: "#D1D5DB"),
        dark: Color(hex: "#6B7280")
    )
    
    /// 인버스 텍스트 색상 (어두운 배경 위)
    public static let textInverse = Color.kingAdaptive(
        light: Color(hex: "#FFFFFF"),
        dark: Color(hex: "#111827")
    )
    
    // MARK: - Interactive Element Colors
    
    /// 버튼 배경색
    public static let buttonPrimary = accent
    
    /// 세컨더리 버튼 색상
    public static let buttonSecondary = Color.kingAdaptive(
        light: Color(hex: "#F3F4F6"),
        dark: Color(hex: "#374151")
    )
    
    /// 비활성화된 버튼 색상
    public static let buttonDisabled = Color.kingAdaptive(
        light: Color(hex: "#E5E7EB"),
        dark: Color(hex: "#4B5563")
    )
    
    /// 링크 색상
    public static let link = accent
    
    /// 포커스 색상
    public static let focus = Color.kingAdaptive(
        light: Color(hex: "#3B82F6"),
        dark: Color(hex: "#60A5FA")
    )
    
    // MARK: - Semantic Colors
    
    /// 성공 색상
    public static let success = Color.kingAdaptive(
        light: Color(hex: "#10B981"),
        dark: Color(hex: "#34D399")
    )
    
    /// 경고 색상
    public static let warning = Color.kingAdaptive(
        light: Color(hex: "#F59E0B"),
        dark: Color(hex: "#FBBF24")
    )
    
    /// 에러 색상
    public static let error = Color.kingAdaptive(
        light: Color(hex: "#EF4444"),
        dark: Color(hex: "#F87171")
    )
    
    /// 정보 색상
    public static let info = Color.kingAdaptive(
        light: Color(hex: "#3B82F6"),
        dark: Color(hex: "#60A5FA")
    )
    
    // MARK: - Border & Separator Colors
    
    /// 메인 보더 색상
    public static let border = Color.kingAdaptive(
        light: Color(hex: "#E5E7EB"),
        dark: Color(hex: "#374151")
    )
    
    /// 서브틀 보더 색상
    public static let borderSubtle = Color.kingAdaptive(
        light: Color(hex: "#F3F4F6"),
        dark: Color(hex: "#1F2937")
    )
    
    /// 강조 보더 색상
    public static let borderAccent = accent.opacity(0.3)
    
    /// 구분선 색상
    public static let separator = Color.kingAdaptive(
        light: Color(hex: "#E5E7EB"),
        dark: Color(hex: "#374151")
    )
    
    // MARK: - Status & Transaction Colors
    
    /// 송금 트랜잭션 색상
    public static let transactionSend = error
    
    /// 수신 트랜잭션 색상
    public static let transactionReceive = success
    
    /// 대기중 트랜잭션 색상
    public static let transactionPending = warning
    
    /// 확인됨 트랜잭션 색상
    public static let transactionConfirmed = success
    
    /// 실패한 트랜잭션 색상
    public static let transactionFailed = error
    
    // MARK: - Ethereum & Crypto Specific Colors
    
    /// 이더리움 브랜드 색상
    public static let ethereum = Color.kingAdaptive(
        light: Color(hex: "#627EEA"),
        dark: Color(hex: "#7B93F4")
    )
    
    /// Bitcoin 색상
    public static let bitcoin = Color.kingAdaptive(
        light: Color(hex: "#F7931A"),
        dark: Color(hex: "#FFB74D")
    )
    
    // MARK: - Glass Morphism Colors
    
    /// Glass 테두리 색상
    public static let glassBorder = Color.kingAdaptive(
        light: Color.white.opacity(0.3),
        dark: Color.white.opacity(0.2)
    )
    
    /// Glass 그림자 색상
    public static let glassShadow = Color.kingAdaptive(
        light: Color.black.opacity(0.1),
        dark: Color.black.opacity(0.3)
    )
    
    // MARK: - Enhanced Glass Morphism Colors (2024 최적화)
    
    /// 접근성을 고려한 Glass 테두리 색상 (WCAG AAA 기준)
    public static let glassAccessibleBorder = Color.kingAdaptive(
        light: Color.white.opacity(0.6),
        dark: Color.white.opacity(0.45)
    )
    
    /// 고대비 Glass 그림자 색상
    public static let glassAccessibleShadow = Color.kingAdaptive(
        light: Color.black.opacity(0.25),
        dark: Color.black.opacity(0.5)
    )
    
    /// Vibrancy 효과용 Glass 하이라이트 색상
    public static let glassVibrancy = Color.kingAdaptive(
        light: Color.white.opacity(0.25),
        dark: Color.white.opacity(0.15)
    )
    
    /// Apple Vision Pro 스타일 Glass 테두리
    public static let glassVisionProBorder = Color.kingAdaptive(
        light: Color.white.opacity(0.8),
        dark: Color.white.opacity(0.6)
    )
}

// MARK: - Color Extensions for Hex Support
public extension Color {
    /// Hex 코드로 색상 생성
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    /// 라이트/다크 모드 적응 색상 생성 (Kingthereum 전용)
    static func kingAdaptive(light: Color, dark: Color) -> Color {
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
}

// MARK: - Preview Support
#Preview("Kingthereum Colors") {
    ScrollView {
        VStack(spacing: 24) {
            // Brand Colors
            ColorSection(
                title: "Brand Colors",
                colors: [
                    ("Primary Dark", KingColors.primaryDark),
                    ("Primary Light", KingColors.primaryLight),
                    ("Accent", KingColors.accent),
                    ("Accent Secondary", KingColors.accentSecondary)
                ]
            )
            
            // Background Colors
            ColorSection(
                title: "Background Colors",
                colors: [
                    ("Background Primary", KingColors.backgroundPrimary),
                    ("Background Secondary", KingColors.backgroundSecondary),
                    ("Background Tertiary", KingColors.backgroundTertiary),
                    ("Surface", KingColors.surface)
                ]
            )
            
            // Text Colors
            ColorSection(
                title: "Text Colors",
                colors: [
                    ("Text Primary", KingColors.textPrimary),
                    ("Text Secondary", KingColors.textSecondary),
                    ("Text Tertiary", KingColors.textTertiary),
                    ("Text Placeholder", KingColors.textPlaceholder)
                ]
            )
            
            // Semantic Colors
            ColorSection(
                title: "Semantic Colors",
                colors: [
                    ("Success", KingColors.success),
                    ("Warning", KingColors.warning),
                    ("Error", KingColors.error),
                    ("Info", KingColors.info)
                ]
            )
            
            // Transaction Colors
            ColorSection(
                title: "Transaction Colors",
                colors: [
                    ("Send", KingColors.transactionSend),
                    ("Receive", KingColors.transactionReceive),
                    ("Pending", KingColors.transactionPending),
                    ("Confirmed", KingColors.transactionConfirmed)
                ]
            )
        }
        .padding()
    }
    .background(KingColors.backgroundPrimary)
}

// MARK: - Helper Views for Preview
private struct ColorSection: View {
    let title: String
    let colors: [(String, Color)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(KingColors.textPrimary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(colors, id: \.0) { name, color in
                    HStack {
                        Circle()
                            .fill(color)
                            .frame(width: 20, height: 20)
                        
                        Text(name)
                            .font(.caption)
                            .foregroundColor(KingColors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(KingColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(KingColors.cardBorder, lineWidth: 1)
        )
    }
}