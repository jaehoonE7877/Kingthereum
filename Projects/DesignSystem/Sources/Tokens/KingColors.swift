import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Kingthereum 프리미엄 디자인 시스템 2024
/// 모던 미니멀리즘 + 프리미엄 피나테크 + 글래스모피즘 핵심 키워드 기반
public struct KingColors {
    
    // MARK: - 모던 미니멀리즘 Core Colors
    
    /// 극도로 깊은 네이비 - 모던 미니멀리즘의 핵심
    public static let minimalistNavy = Color.kingAdaptive(
        light: Color(hex: "#0A0F1C"),  // 더욱 깊고 절제된 네이비
        dark: Color(hex: "#000000")    // 순수 블랙
    )
    
    /// 프리미엄 피나테크 신뢰 퍼플
    public static let trustPurple = Color.kingAdaptive(
        light: Color(hex: "#5B21B6"),  // 신뢰감 있는 딥 퍼플
        dark: Color(hex: "#7C3AED")
    )
    
    /// 골드 액센트 - 오직 중요한 요소에만 사용
    public static let exclusiveGold = Color.kingAdaptive(
        light: Color(hex: "#B7791F"),  // 차분하고 고급스러운 골드
        dark: Color(hex: "#D97706")    // 약간 더 밝은 골드
    )
    
    /// 순수 화이트 - 미니멀리즘의 기본
    public static let pureWhite = Color.kingAdaptive(
        light: Color(hex: "#FFFFFF"),
        dark: Color(hex: "#0F0F0F")
    )
    
    /// 서브틀 그레이 - 뉴트럴 톤
    public static let subtleGray = Color.kingAdaptive(
        light: Color(hex: "#F8FAFC"),
        dark: Color(hex: "#1A1A1A")
    )
    
    // MARK: - Legacy Colors (호환성을 위해 유지하되 새로운 색상으로 매핑)
    
    /// 메인 브랜드 색상 → minimalistNavy로 매핑
    public static let primaryDark = minimalistNavy
    
    /// 라이트 브랜드 색상 → subtleGray로 매핑
    public static let primaryLight = subtleGray
    
    /// 메인 액센트 색상 → trustPurple로 매핑
    public static let accent = trustPurple
    
    /// 세컨더리 액센트 → exclusiveGold로 매핑
    public static let accentSecondary = exclusiveGold
    
    // MARK: - 미니멀리즘 Background Hierarchy
    
    /// 메인 배경색 - 순수하고 깔끔한 베이스
    public static let backgroundPrimary = pureWhite
    
    /// 세컨더리 배경색 - 극도로 서브틀한 그레이
    public static let backgroundSecondary = Color.kingAdaptive(
        light: Color(hex: "#FAFBFC"),  // 거의 화이트에 가까운 서브틀함
        dark: Color(hex: "#0A0A0A")
    )
    
    /// 터셔리 배경색 - 미니멀 그룹 배경
    public static let backgroundTertiary = Color.kingAdaptive(
        light: Color(hex: "#F5F6F8"),  // 아주 연한 그레이
        dark: Color(hex: "#151515")
    )
    
    /// 서피스 배경색 - 글래스모피즘 베이스
    public static let surface = Color.kingAdaptive(
        light: Color(hex: "#FFFFFF").opacity(0.9),  // 반투명 화이트
        dark: Color(hex: "#1A1A1A").opacity(0.9)    // 반투명 다크
    )
    
    // MARK: - 글래스모피즘 Card & Surface Colors
    
    /// 미니멀 글래스 카드 배경 - 극도로 서브틀한 반투명
    public static let glassCardBackground = Color.kingAdaptive(
        light: Color.white.opacity(0.65),  // 더 서브틀하게
        dark: Color(hex: "#1A1A1A").opacity(0.75)
    )
    
    /// 글래스 보더 - 극도로 연한 톤 (미니멀리즘)
    public static let glassBorder = Color.kingAdaptive(
        light: Color.white.opacity(0.2),  // 더 연하게
        dark: Color.white.opacity(0.1)
    )
    
    /// 글래스 섀도우 - 미니멀한 깊이감
    public static let glassShadow = Color.kingAdaptive(
        light: Color.black.opacity(0.05),  // 극도로 연하게
        dark: Color.black.opacity(0.2)
    )
    
    /// 프리미엄 엘리베이티드 카드 - 중요한 요소용
    public static let premiumElevated = Color.kingAdaptive(
        light: Color.white.opacity(0.9),
        dark: Color(hex: "#1F1F1F").opacity(0.9)
    )
    
    // MARK: - Legacy Card Colors (호환성을 위해 유지)
    
    /// 카드 배경색 → glassCardBackground로 매핑
    public static let cardBackground = glassCardBackground
    
    /// 카드 보더색 → glassBorder로 매핑
    public static let cardBorder = glassBorder
    
    /// 카드 섀도우색 → glassShadow로 매핑
    public static let cardShadow = glassShadow
    
    /// 엘리베이티드 카드 배경 → premiumElevated로 매핑
    public static let cardElevated = premiumElevated
    
    // MARK: - 미니멀리즘 Text Hierarchy
    
    /// 메인 텍스트 색상 - 강렬한 대비
    public static let textPrimary = Color.kingAdaptive(
        light: minimalistNavy,
        dark: pureWhite
    )
    
    /// 세컨더리 텍스트 색상 - 서브틀한 정보
    public static let textSecondary = Color.kingAdaptive(
        light: Color(hex: "#64748B"),  // 미디엄 그레이
        dark: Color(hex: "#CBD5E1")   // 연한 그레이
    )
    
    /// 터셔리 텍스트 색상 - 극도로 서브틀
    public static let textTertiary = Color.kingAdaptive(
        light: Color(hex: "#94A3B8"),  // 라이트 그레이
        dark: Color(hex: "#64748B")   // 미디엄 그레이
    )
    
    /// 플레이스홀더 텍스트 색상 - 거의 보이지 않을 정도로 서브틀
    public static let textPlaceholder = Color.kingAdaptive(
        light: Color(hex: "#CBD5E1"),
        dark: Color(hex: "#475569")
    )
    
    /// 골드 텍스트 - 오직 중요한 수치/액션에만
    public static let textGold = exclusiveGold
    
    /// 퍼플 텍스트 - 신뢰성 요소
    public static let textTrust = trustPurple
    
    /// 인버스 텍스트 색상
    public static let textInverse = Color.kingAdaptive(
        light: pureWhite,
        dark: minimalistNavy
    )
    
    // MARK: - 미니멀리즘 Interactive Element Colors
    
    /// 프리미엄 버튼 - 골드 액센트 (중요한 액션에만)
    public static let buttonPrimary = exclusiveGold
    
    /// 신뢰 버튼 - 퍼플 (보안 및 중요 기능)
    public static let buttonTrust = trustPurple
    
    /// 세컨더리 버튼 - 극도로 서브틀
    public static let buttonSecondary = Color.kingAdaptive(
        light: Color(hex: "#F8FAFC"),  // 거의 투명한 그레이
        dark: Color(hex: "#1F2937")
    )
    
    /// 비활성화된 버튼 - 아주 연한 그레이
    public static let buttonDisabled = Color.kingAdaptive(
        light: Color(hex: "#F1F5F9"),
        dark: Color(hex: "#334155")
    )
    
    /// 미니멀 링크 - 골드로 전환
    public static let link = exclusiveGold
    
    /// 포커스 색상 - 골드로 통일
    public static let focus = exclusiveGold
    
    // MARK: - Legacy Interactive Colors (호환성을 위해 유지)
    
    /// 기존 accent → trustPurple로 매핑
    public static let accent = trustPurple
    
    // MARK: - 미니멀리즘 Semantic Colors
    
    /// 성공 색상 - 서브틀한 그린
    public static let success = Color.kingAdaptive(
        light: Color(hex: "#059669"),  // 더 진한 그린
        dark: Color(hex: "#10B981")
    )
    
    /// 경고 색상 - 서브틀한 오렌지
    public static let warning = Color.kingAdaptive(
        light: Color(hex: "#D97706"),  // 진한 오렌지
        dark: Color(hex: "#F59E0B")
    )
    
    /// 에러 색상 - 서브틀한 레드
    public static let error = Color.kingAdaptive(
        light: Color(hex: "#DC2626"),  // 더 진한 레드
        dark: Color(hex: "#EF4444")
    )
    
    /// 정보 색상 - 퍼플로 통일
    public static let info = trustPurple
    
    // MARK: - 미니멀리즘 Border & Separator Colors
    
    /// 극도로 서브틀한 보더 색상
    public static let border = Color.kingAdaptive(
        light: Color(hex: "#F1F5F9"),  // 거의 보이지 않는 연한 그레이
        dark: Color(hex: "#1E293B")
    )
    
    /// 극히 서브틀한 보더 색상
    public static let borderSubtle = Color.kingAdaptive(
        light: Color(hex: "#F8FAFC"),  // 거의 투명
        dark: Color(hex: "#0F172A")
    )
    
    /// 골드 강조 보더 색상 - 중요한 요소에만
    public static let borderAccent = exclusiveGold.opacity(0.4)
    
    /// 미니멀 구분선 색상
    public static let separator = Color.kingAdaptive(
        light: Color(hex: "#F1F5F9"),
        dark: Color(hex: "#1E293B")
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
    
    // MARK: - 프리미엄 피나테크 Crypto Colors
    
    /// 이더리움 색상 - trustPurple로 통일
    public static let ethereum = trustPurple
    
    /// Bitcoin 색상 - 골드로 통일
    public static let bitcoin = exclusiveGold
    
    /// 암호화폐 성공 색상
    public static let cryptoPositive = success
    
    /// 암호화폐 손실 색상
    public static let cryptoNegative = error
    
    // MARK: - 프리미엄 글래스모피즘 2024 (중복 제거 및 통합)
    
    /// 프리미엄 글래스 하이라이트 - 골드 액센트
    public static let glassGoldHighlight = Color.kingAdaptive(
        light: exclusiveGold.opacity(0.2),
        dark: exclusiveGold.opacity(0.3)
    )
    
    /// 프리미엄 글래스 퍼플 하이라이트 - 신뢰성 액센트
    public static let glassTrustHighlight = Color.kingAdaptive(
        light: trustPurple.opacity(0.15),
        dark: trustPurple.opacity(0.25)
    )
    
    /// 미니멀 글래스 베이스 - 완전 투명에 가까운
    public static let glassMinimalBase = Color.kingAdaptive(
        light: Color.white.opacity(0.1),
        dark: Color.black.opacity(0.1)
    )
    
    // MARK: - Legacy Glass Colors (호환성을 위해 유지)
    /// 기존 glassBorder들은 이미 위에서 새로 정의됨
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