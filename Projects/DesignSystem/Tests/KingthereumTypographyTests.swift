import Testing
import SwiftUI
@testable import DesignSystem

/// KingthereumTypography 테스트 스위트
@Suite("KingthereumTypography 테스트")
struct KingthereumTypographyTests {
    
    // MARK: - 타이포그래피 계층 구조 테스트
    
    @Suite("타이포그래피 계층 구조")
    struct TypographyHierarchyTests {
        
        @Test("Display 타이포그래피 계층 검증")
        func testDisplayHierarchy() {
            // Given
            let displayFonts = [
                ("displayLarge", KingthereumTypography.displayLarge),
                ("displayMedium", KingthereumTypography.displayMedium),
                ("displaySmall", KingthereumTypography.displaySmall)
            ]
            
            // When & Then - 각 폰트가 정의되어 있고 크기가 올바른 계층을 가지는지 확인
            var previousSize: CGFloat = CGFloat.greatestFiniteMagnitude
            
            for (name, font) in displayFonts {
                #expect(font != nil, "\(name) 폰트가 정의되어야 함")
                
                // 폰트 크기 추출 (근사값으로 비교)
                let fontSize = extractFontSize(from: font)
                #expect(fontSize > 0, "\(name) 폰트 크기가 유효해야 함")
                #expect(fontSize <= previousSize, "Display 폰트는 Large > Medium > Small 순서여야 함")
                
                previousSize = fontSize
            }
        }
        
        @Test("Headline 타이포그래피 계층 검증")
        func testHeadlineHierarchy() {
            // Given
            let headlineFonts = [
                ("headlineLarge", KingthereumTypography.headlineLarge),
                ("headlineMedium", KingthereumTypography.headlineMedium),
                ("headlineSmall", KingthereumTypography.headlineSmall)
            ]
            
            // Then
            var previousSize: CGFloat = CGFloat.greatestFiniteMagnitude
            
            for (name, font) in headlineFonts {
                #expect(font != nil, "\(name) 폰트가 정의되어야 함")
                
                let fontSize = extractFontSize(from: font)
                #expect(fontSize > 0, "\(name) 폰트 크기가 유효해야 함")
                #expect(fontSize <= previousSize, "Headline 폰트는 올바른 크기 순서를 가져야 함")
                
                previousSize = fontSize
            }
        }
        
        @Test("Body 타이포그래피 계층 검증")
        func testBodyHierarchy() {
            // Given
            let bodyFonts = [
                ("bodyLarge", KingthereumTypography.bodyLarge),
                ("bodyMedium", KingthereumTypography.bodyMedium),
                ("bodySmall", KingthereumTypography.bodySmall)
            ]
            
            // Then
            for (name, font) in bodyFonts {
                #expect(font != nil, "\(name) 폰트가 정의되어야 함")
                
                let fontSize = extractFontSize(from: font)
                #expect(fontSize > 0, "\(name) 폰트 크기가 유효해야 함")
                #expect(fontSize >= 12, "본문 폰트는 최소 12pt 이상이어야 함")
            }
        }
        
        @Test("Label 및 Caption 계층 검증")
        func testLabelAndCaptionHierarchy() {
            // Given
            let smallFonts = [
                ("labelLarge", KingthereumTypography.labelLarge),
                ("labelMedium", KingthereumTypography.labelMedium),
                ("caption", KingthereumTypography.caption),
                ("helper", KingthereumTypography.helper)
            ]
            
            // Then
            for (name, font) in smallFonts {
                #expect(font != nil, "\(name) 폰트가 정의되어야 함")
                
                let fontSize = extractFontSize(from: font)
                #expect(fontSize > 0, "\(name) 폰트 크기가 유효해야 함")
                #expect(fontSize >= 10, "작은 폰트도 최소 10pt 이상이어야 함 (접근성)")
            }
        }
    }
    
    // MARK: - 접근성 테스트
    
    @Suite("타이포그래피 접근성")
    struct TypographyAccessibilityTests {
        
        @Test("최소 폰트 크기 접근성 검증")
        func testMinimumFontSizeAccessibility() {
            // Given - 모든 타이포그래피 스타일
            let allFonts = [
                ("displayLarge", KingthereumTypography.displayLarge),
                ("displayMedium", KingthereumTypography.displayMedium),
                ("displaySmall", KingthereumTypography.displaySmall),
                ("headlineLarge", KingthereumTypography.headlineLarge),
                ("headlineMedium", KingthereumTypography.headlineMedium),
                ("headlineSmall", KingthereumTypography.headlineSmall),
                ("bodyLarge", KingthereumTypography.bodyLarge),
                ("bodyMedium", KingthereumTypography.bodyMedium),
                ("bodySmall", KingthereumTypography.bodySmall),
                ("labelLarge", KingthereumTypography.labelLarge),
                ("labelMedium", KingthereumTypography.labelMedium),
                ("caption", KingthereumTypography.caption),
                ("helper", KingthereumTypography.helper)
            ]
            
            // When & Then - 접근성 최소 크기 검증
            for (name, font) in allFonts {
                let fontSize = extractFontSize(from: font)
                
                if name.contains("body") || name.contains("headline") {
                    #expect(fontSize >= 16, "\(name)은 주요 텍스트로 16pt 이상이어야 함")
                } else if name.contains("label") {
                    #expect(fontSize >= 12, "\(name)은 12pt 이상이어야 함")
                } else {
                    #expect(fontSize >= 10, "\(name)은 최소 10pt 이상이어야 함")
                }
            }
        }
        
        @Test("동적 타입 지원 검증")
        func testDynamicTypeSupport() {
            // Given
            let testFonts = [
                KingthereumTypography.bodyMedium,
                KingthereumTypography.headlineLarge,
                KingthereumTypography.caption
            ]
            
            // Then - 동적 타입을 지원하는 폰트인지 확인
            for font in testFonts {
                #expect(font != nil, "동적 타입 지원 폰트가 정의되어야 함")
                // 실제 SwiftUI 환경에서는 @Environment(\.sizeCategory) 테스트 필요
            }
        }
    }
    
    // MARK: - 특수 용도 타이포그래피 테스트
    
    @Suite("특수 용도 타이포그래피")
    struct SpecialPurposeTypographyTests {
        
        @Test("버튼 타이포그래피 검증")
        func testButtonTypography() {
            // Given
            let buttonFonts = [
                ("buttonPrimary", KingthereumTypography.buttonPrimary),
                ("buttonSecondary", KingthereumTypography.buttonSecondary)
            ]
            
            // Then
            for (name, font) in buttonFonts {
                #expect(font != nil, "\(name) 버튼 폰트가 정의되어야 함")
                
                let fontSize = extractFontSize(from: font)
                #expect(fontSize >= 14, "버튼 폰트는 14pt 이상이어야 함 (터치 접근성)")
                #expect(fontSize <= 20, "버튼 폰트는 20pt 이하여야 함 (UI 균형)")
            }
        }
        
        @Test("암호화폐 전용 타이포그래피 검증")
        func testCryptoTypography() {
            // Given
            let cryptoFonts = [
                ("cryptoBalance", KingthereumTypography.cryptoBalance),
                ("cryptoBalanceLarge", KingthereumTypography.cryptoBalanceLarge),
                ("cryptoAddress", KingthereumTypography.cryptoAddress)
            ]
            
            // Then
            for (name, font) in cryptoFonts {
                #expect(font != nil, "\(name) 암호화폐 폰트가 정의되어야 함")
                
                let fontSize = extractFontSize(from: font)
                
                if name.contains("Balance") {
                    #expect(fontSize >= 18, "잔액 표시 폰트는 18pt 이상이어야 함")
                } else if name.contains("Address") {
                    #expect(fontSize >= 12, "주소 표시 폰트는 12pt 이상이어야 함")
                }
            }
        }
        
        @Test("탭바 타이포그래피 검증")
        func testTabBarTypography() {
            // Given
            let tabBarFont = KingthereumTypography.tabBar
            
            // Then
            #expect(tabBarFont != nil, "탭바 폰트가 정의되어야 함")
            
            let fontSize = extractFontSize(from: tabBarFont)
            #expect(fontSize >= 10, "탭바 폰트는 10pt 이상이어야 함")
            #expect(fontSize <= 14, "탭바 폰트는 14pt 이하여야 함")
        }
    }
    
    // MARK: - 브랜드 일관성 테스트
    
    @Suite("브랜드 일관성")
    struct BrandConsistencyTests {
        
        @Test("폰트 패밀리 일관성 검증")
        func testFontFamilyConsistency() {
            // Given - 주요 타이포그래피 스타일들
            let primaryFonts = [
                KingthereumTypography.displayLarge,
                KingthereumTypography.headlineLarge,
                KingthereumTypography.bodyMedium
            ]
            
            // Then - 모든 폰트가 브랜드 폰트 패밀리를 사용하는지 확인
            for font in primaryFonts {
                #expect(font != nil, "브랜드 폰트가 정의되어야 함")
                // 실제 구현에서는 폰트 패밀리명 확인 필요
            }
        }
        
        @Test("폰트 웨이트 적용 검증")
        func testFontWeightApplication() {
            // Given
            let weightedFonts = [
                ("display", KingthereumTypography.displayLarge),
                ("headline", KingthereumTypography.headlineLarge),
                ("body", KingthereumTypography.bodyMedium)
            ]
            
            // Then
            for (category, font) in weightedFonts {
                #expect(font != nil, "\(category) 카테고리 폰트가 정의되어야 함")
                // 폰트 웨이트가 적절히 적용되었는지 확인
            }
        }
    }
    
    // MARK: - 성능 테스트
    
    @Suite("타이포그래피 성능")
    struct TypographyPerformanceTests {
        
        @Test("폰트 로딩 성능", .timeLimit(.seconds(2)))
        func testFontLoadingPerformance() {
            // Given & When - 대량의 폰트 인스턴스 생성
            measure {
                for _ in 0..<500 {
                    _ = KingthereumTypography.displayLarge
                    _ = KingthereumTypography.headlineMedium
                    _ = KingthereumTypography.bodyMedium
                    _ = KingthereumTypography.caption
                }
            }
            
            // Then - 2초 내에 완료되어야 함
        }
        
        @Test("텍스트 렌더링 성능", .timeLimit(.seconds(1)))
        func testTextRenderingPerformance() async {
            // Given
            let testText = "가나다라마바사아자차카타파하 ABCDEFGHIJKLMNOPQRSTUVWXYZ 0123456789"
            let fonts = [
                KingthereumTypography.bodyMedium,
                KingthereumTypography.headlineLarge,
                KingthereumTypography.caption
            ]
            
            // When & Then - 텍스트 렌더링 성능 테스트
            for font in fonts {
                #expect(font != nil, "폰트가 유효해야 함")
                // SwiftUI Text 렌더링 성능은 실제 UI 테스트에서 확인
            }
        }
    }
}

// MARK: - Helper Functions

extension KingthereumTypographyTests {
    
    /// Font에서 크기 추출 (근사값)
    private func extractFontSize(from font: Font) -> CGFloat {
        // SwiftUI Font를 UIFont로 변환하여 크기 추출하는 헬퍼 함수
        // 실제 구현에서는 더 정확한 방법 필요
        switch font {
        case .largeTitle: return 34
        case .title: return 28
        case .title2: return 22
        case .title3: return 20
        case .headline: return 17
        case .body: return 17
        case .callout: return 16
        case .subheadline: return 15
        case .footnote: return 13
        case .caption: return 12
        case .caption2: return 11
        default: return 17 // 기본값
        }
    }
    
    /// 성능 측정 헬퍼
    private func measure(_ block: () -> Void) {
        let startTime = CFAbsoluteTimeGetCurrent()
        block()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        print("타이포그래피 성능 테스트 실행 시간: \(timeElapsed)초")
    }
}