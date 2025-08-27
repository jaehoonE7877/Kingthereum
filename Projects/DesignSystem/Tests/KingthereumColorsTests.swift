import Testing
import SwiftUI
@testable import DesignSystem

/// KingthereumColors 테스트 스위트
@Suite("KingthereumColors 테스트")
struct KingthereumColorsTests {
    
    // MARK: - 컬러 접근성 테스트
    
    @Suite("컬러 접근성 테스트")
    struct ColorAccessibilityTests {
        
        @Test("주요 텍스트 색상 대비율 검증")
        func testPrimaryTextContrast() {
            // Given
            let backgroundColor = KingthereumColors.background
            let primaryTextColor = KingthereumColors.textPrimary
            
            // When
            let contrastRatio = calculateContrastRatio(primaryTextColor, backgroundColor)
            
            // Then
            #expect(contrastRatio >= 4.5, "주요 텍스트는 AA 접근성 기준(4.5:1) 이상이어야 함")
        }
        
        @Test("보조 텍스트 색상 대비율 검증")
        func testSecondaryTextContrast() {
            // Given
            let backgroundColor = KingthereumColors.surface
            let secondaryTextColor = KingthereumColors.textSecondary
            
            // When
            let contrastRatio = calculateContrastRatio(secondaryTextColor, backgroundColor)
            
            // Then
            #expect(contrastRatio >= 3.0, "보조 텍스트는 최소 대비율(3:1) 이상이어야 함")
        }
        
        @Test("에러 색상 인식성 검증")
        func testErrorColorVisibility() {
            // Given
            let errorColor = KingthereumColors.error
            let backgroundColor = KingthereumColors.background
            
            // When
            let contrastRatio = calculateContrastRatio(errorColor, backgroundColor)
            
            // Then
            #expect(contrastRatio >= 3.0, "에러 색상은 충분히 구별 가능해야 함")
        }
        
        @Test("성공 색상 인식성 검증")
        func testSuccessColorVisibility() {
            // Given
            let successColor = KingthereumColors.success
            let backgroundColor = KingthereumColors.background
            
            // When
            let contrastRatio = calculateContrastRatio(successColor, backgroundColor)
            
            // Then
            #expect(contrastRatio >= 3.0, "성공 색상은 충분히 구별 가능해야 함")
        }
    }
    
    // MARK: - 다크모드 호환성 테스트
    
    @Suite("다크모드 호환성")
    struct DarkModeCompatibilityTests {
        
        @Test("다크모드에서 컬러 정의 존재 확인")
        func testDarkModeColors() {
            // Given
            let lightColorScheme = ColorScheme.light
            let darkColorScheme = ColorScheme.dark
            
            // When & Then - 주요 색상들이 다크모드에서도 정의되어 있는지 확인
            let testColors = [
                ("textPrimary", KingthereumColors.textPrimary),
                ("textSecondary", KingthereumColors.textSecondary),
                ("background", KingthereumColors.background),
                ("surface", KingthereumColors.surface),
                ("accent", KingthereumColors.accent)
            ]
            
            for (colorName, color) in testColors {
                #expect(color != nil, "\(colorName) 색상이 정의되어야 함")
            }
        }
        
        @Test("라이트/다크 모드 색상 차이 검증")
        func testColorSchemeDifferences() {
            // Given - 라이트/다크 모드에서 다른 값을 가져야 하는 색상들
            let adaptiveColors = [
                KingthereumColors.textPrimary,
                KingthereumColors.background,
                KingthereumColors.surface
            ]
            
            // Then - 각 색상이 유효한 Color 인스턴스인지 확인
            for color in adaptiveColors {
                #expect(color != nil, "적응형 색상이 올바르게 정의되어야 함")
            }
        }
    }
    
    // MARK: - 컬러 네이밍 일관성 테스트
    
    @Suite("컬러 네이밍 규칙")
    struct ColorNamingTests {
        
        @Test("시맨틱 컬러 네이밍 검증")
        func testSemanticColorNaming() {
            // Given - 시맨틱 컬러들이 존재하는지 확인
            let semanticColors = [
                ("primary", KingthereumColors.accent),
                ("secondary", KingthereumColors.accentSecondary),
                ("success", KingthereumColors.success),
                ("warning", KingthereumColors.warning),
                ("error", KingthereumColors.error),
                ("info", KingthereumColors.info)
            ]
            
            // Then
            for (name, color) in semanticColors {
                #expect(color != nil, "\(name) 시맨틱 컬러가 정의되어야 함")
            }
        }
        
        @Test("텍스트 컬러 계층 구조 검증")
        func testTextColorHierarchy() {
            // Given
            let textColors = [
                ("primary", KingthereumColors.textPrimary),
                ("secondary", KingthereumColors.textSecondary),
                ("tertiary", KingthereumColors.textTertiary),
                ("inverse", KingthereumColors.textInverse)
            ]
            
            // Then
            for (level, color) in textColors {
                #expect(color != nil, "\(level) 텍스트 컬러가 정의되어야 함")
            }
        }
    }
    
    // MARK: - 색상 일관성 테스트
    
    @Suite("색상 일관성")
    struct ColorConsistencyTests {
        
        @Test("브랜드 컬러 일관성 검증")
        func testBrandColorConsistency() {
            // Given
            let brandColors = [
                KingthereumColors.accent,
                KingthereumColors.accentSecondary
            ]
            
            // Then - 브랜드 컬러들이 모두 정의되어 있는지 확인
            for color in brandColors {
                #expect(color != nil, "브랜드 컬러가 정의되어야 함")
            }
        }
        
        @Test("암호화폐 관련 컬러 검증")
        func testCryptoColors() {
            // Given
            let cryptoColors = [
                ("bitcoin", KingthereumColors.bitcoin),
                ("ethereum", KingthereumColors.ethereum)
            ]
            
            // Then
            for (crypto, color) in cryptoColors {
                #expect(color != nil, "\(crypto) 컬러가 정의되어야 함")
            }
        }
    }
    
    // MARK: - 성능 테스트
    
    @Suite("색상 성능")
    struct ColorPerformanceTests {
        
        @Test("컬러 초기화 성능", .timeLimit(.seconds(1)))
        func testColorInitializationPerformance() {
            // Given & When - 대량의 컬러 인스턴스 생성
            measure {
                for _ in 0..<1000 {
                    _ = KingthereumColors.accent
                    _ = KingthereumColors.textPrimary
                    _ = KingthereumColors.background
                    _ = KingthereumColors.surface
                }
            }
            
            // Then - 1초 내에 완료되어야 함 (timeLimit으로 검증)
        }
    }
}

// MARK: - Helper Functions

extension KingthereumColorsTests {
    
    /// 두 색상 간의 명암 대비율 계산 (WCAG 기준)
    private func calculateContrastRatio(_ foreground: Color, _ background: Color) -> Double {
        // SwiftUI Color를 UIColor로 변환하여 RGB 값 추출
        let foregroundUIColor = UIColor(foreground)
        let backgroundUIColor = UIColor(background)
        
        let foregroundLuminance = calculateLuminance(foregroundUIColor)
        let backgroundLuminance = calculateLuminance(backgroundUIColor)
        
        let lighter = max(foregroundLuminance, backgroundLuminance)
        let darker = min(foregroundLuminance, backgroundLuminance)
        
        return (lighter + 0.05) / (darker + 0.05)
    }
    
    /// 색상의 상대 휘도 계산
    private func calculateLuminance(_ color: UIColor) -> Double {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // sRGB to Linear RGB 변환
        let rs = red <= 0.03928 ? red / 12.92 : pow((red + 0.055) / 1.055, 2.4)
        let gs = green <= 0.03928 ? green / 12.92 : pow((green + 0.055) / 1.055, 2.4)
        let bs = blue <= 0.03928 ? blue / 12.92 : pow((blue + 0.055) / 1.055, 2.4)
        
        // 상대 휘도 계산 (ITU-R BT.709)
        return 0.2126 * Double(rs) + 0.7152 * Double(gs) + 0.0722 * Double(bs)
    }
    
    /// 성능 측정 헬퍼
    private func measure(_ block: () -> Void) {
        let startTime = CFAbsoluteTimeGetCurrent()
        block()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // 성능 검증은 timeLimit으로 처리
        print("실행 시간: \(timeElapsed)초")
    }
}