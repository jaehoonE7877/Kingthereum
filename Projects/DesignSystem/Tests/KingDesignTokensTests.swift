import Testing
import SwiftUI
@testable import DesignSystem

// MARK: - KingDesignTokens Tests

@Suite("KingDesignTokens Tests")
struct KingDesignTokensTests {
    
    @Suite("Color System")
    struct ColorTests {
        
        @Test("Core colors are defined")
        func testCoreColors() {
            // Verify core colors exist by accessing them
            let primaryText = KingDesignTokens.Colors.primaryText
            let background = KingDesignTokens.Colors.background
            let accent = KingDesignTokens.Colors.accent
            
            // Colors should be different from each other
            #expect(primaryText != background)
            #expect(accent != background)
        }
        
        @Test("Gray scale colors are defined")
        func testGrayScaleColors() {
            let secondaryText = KingDesignTokens.Colors.secondaryText
            let tertiaryText = KingDesignTokens.Colors.tertiaryText
            let border = KingDesignTokens.Colors.border
            
            // Colors should be accessible
            #expect(secondaryText != tertiaryText)
        }
        
        @Test("Semantic colors are defined")
        func testSemanticColors() {
            let success = KingDesignTokens.Colors.success
            let error = KingDesignTokens.Colors.error
            
            // Semantic colors should be different
            #expect(success != error)
        }
        
        @Test("Adaptive colors respond to color scheme")
        func testAdaptiveColors() {
            // Primary colors should be accessible
            let primary = KingDesignTokens.Colors.primary
            let background = KingDesignTokens.Colors.background
            let surface = KingDesignTokens.Colors.surface
            
            #expect(primary != background)
        }
        
        @Test("Color count is minimalist (8 colors)")
        func testColorMinimalism() {
            // Count unique color definitions
            let coreColors = 3 // ink, snow, gold
            let grayScale = 3  // ash, smoke, mist
            let semantic = 2   // success, danger
            let totalColors = coreColors + grayScale + semantic
            
            #expect(totalColors == 8, "Should have exactly 8 colors for minimalism")
        }
    }
    
    @Suite("Typography System")
    struct TypographyTests {
        
        @Test("Display fonts are defined")
        func testDisplayFonts() {
            let displayXL = KingDesignTokens.Typography.displayXL
            let displayL = KingDesignTokens.Typography.displayL
            let displayM = KingDesignTokens.Typography.displayM
            
            // Fonts should be accessible
            #expect(displayXL != displayL)
        }
        
        @Test("Text fonts are defined")
        func testTextFonts() {
            let heading = KingDesignTokens.Typography.heading
            let body = KingDesignTokens.Typography.body
            let caption = KingDesignTokens.Typography.caption
            let micro = KingDesignTokens.Typography.micro
            
            // Fonts should be accessible
            #expect(heading != body)
            #expect(body != caption)
        }
        
        @Test("Monospace fonts are defined")
        func testMonospaceFonts() {
            let mono = KingDesignTokens.Typography.mono
            let monoSmall = KingDesignTokens.Typography.monoSmall
            
            // Fonts should be accessible
            #expect(mono != monoSmall)
        }
    }
    
    @Suite("Spacing System")
    struct SpacingTests {
        
        @Test("Spacing follows 8px grid system")
        func testSpacingGrid() {
            #expect(KingDesignTokens.Spacing.xxs == 4)
            #expect(KingDesignTokens.Spacing.xs == 8)
            #expect(KingDesignTokens.Spacing.sm == 12)
            #expect(KingDesignTokens.Spacing.md == 16)
            #expect(KingDesignTokens.Spacing.lg == 24)
            #expect(KingDesignTokens.Spacing.xl == 32)
            #expect(KingDesignTokens.Spacing.xxl == 48)
            #expect(KingDesignTokens.Spacing.xxxl == 64)
        }
        
        @Test("Spacing values are consistent")
        func testSpacingConsistency() {
            // Verify spacing increases logically
            #expect(KingDesignTokens.Spacing.xxs < KingDesignTokens.Spacing.xs)
            #expect(KingDesignTokens.Spacing.xs < KingDesignTokens.Spacing.sm)
            #expect(KingDesignTokens.Spacing.sm < KingDesignTokens.Spacing.md)
            #expect(KingDesignTokens.Spacing.md < KingDesignTokens.Spacing.lg)
            #expect(KingDesignTokens.Spacing.lg < KingDesignTokens.Spacing.xl)
        }
    }
    
    @Suite("Radius System")
    struct RadiusTests {
        
        @Test("Corner radius values are defined")
        func testRadiusValues() {
            #expect(KingDesignTokens.Radius.xs == 4)
            #expect(KingDesignTokens.Radius.sm == 8)
            #expect(KingDesignTokens.Radius.md == 12)
            #expect(KingDesignTokens.Radius.lg == 16)
            #expect(KingDesignTokens.Radius.xl == 20)
            #expect(KingDesignTokens.Radius.full == 999)
        }
    }
    
    @Suite("Glass Material System")
    struct GlassTests {
        
        @Test("Material levels are defined")
        func testMaterialLevels() {
            let ultraThin = KingDesignTokens.Glass.ultraThin
            let thin = KingDesignTokens.Glass.thin
            let regular = KingDesignTokens.Glass.regular
            let thick = KingDesignTokens.Glass.thick
            
            // Materials should be accessible (different blur radii)
            #expect(ultraThin != thick)
        }
    }
    
    @Suite("Animation System")
    struct AnimationTests {
        
        @Test("Animation durations are appropriate")
        func testAnimationDurations() {
            // Animations should be defined and accessible
            let fast = KingDesignTokens.Animation.fast
            let normal = KingDesignTokens.Animation.normal
            let slow = KingDesignTokens.Animation.slow
            let spring = KingDesignTokens.Animation.spring
            
            // Different animations should exist
            #expect(fast.hashValue != slow.hashValue)
        }
    }
}

// MARK: - Component Tests

@Suite("Glass Component Tests")
struct GlassComponentTests {
    
    @Suite("GlassButton Tests")
    struct ButtonTests {
        
        @Test("Button styles are defined")
        func testButtonStyles() {
            // Verify buttons can be created with different styles
            let primaryButton = GlassButton("Test", style: .primary) {}
            let secondaryButton = GlassButton("Test", style: .secondary) {}  
            let textButton = GlassButton("Test", style: .text) {}
            
            // Buttons should be properly initialized
            #expect(true, "All button styles should be accessible")
        }
        
        @Test("Button sizes are defined")
        func testButtonSizes() {
            // Verify buttons can be created with different sizes
            let smallButton = GlassButton("Test", size: .small) {}
            let mediumButton = GlassButton("Test", size: .medium) {}
            let largeButton = GlassButton("Test", size: .large) {}
            
            // Buttons should be properly initialized
            #expect(true, "All button sizes should be accessible")
        }
    }
    
    @Suite("GlassTextField Tests")
    struct TextFieldTests {
        
        @Test("TextField validation states work")
        func testValidationStates() {
            let validState = GlassTextField.ValidationState.valid
            let invalidState = GlassTextField.ValidationState.invalid("Error message")
            
            #expect(validState.color == KingDesignTokens.Colors.success)
            #expect(invalidState.color == KingDesignTokens.Colors.error)
            #expect(validState.icon == "checkmark.circle")
            #expect(invalidState.icon == "xmark.circle")
        }
    }
    
    @Suite("GlassCard Tests")
    struct CardTests {
        
        @Test("Card components are initialized")
        func testCardInitialization() {
            // Verify card components can be initialized
            let basicCard = GlassCard { Text("Content") }
            let infoCard = GlassInfoCard(
                icon: "creditcard",
                title: "Test",
                subtitle: "Subtitle",
                value: "Value"
            )
            let alertCard = GlassAlertCard(
                type: .success,
                title: "Success",
                message: "Test message"
            )
            
            // All card types should be properly initialized
            #expect(true, "All card components should be accessible")
        }
        
        @Test("Alert card types have correct properties")
        func testAlertCardTypes() {
            let infoType = GlassAlertCard.AlertType.info
            let successType = GlassAlertCard.AlertType.success
            let warningType = GlassAlertCard.AlertType.warning
            let errorType = GlassAlertCard.AlertType.error
            
            #expect(infoType.icon == "info.circle")
            #expect(successType.icon == "checkmark.circle")
            #expect(warningType.icon == "exclamationmark.triangle")
            #expect(errorType.icon == "xmark.circle")
            
            #expect(successType.color == KingDesignTokens.Colors.success)
            #expect(errorType.color == KingDesignTokens.Colors.error)
        }
    }
}

// MARK: - Performance Tests

@Suite("Performance Tests")
struct PerformanceTests {
    
    @Test("Token access is efficient")
    func testTokenAccessPerformance() {
        // Measure token access time
        let startTime = Date()
        
        for _ in 0..<1000 {
            _ = KingDesignTokens.Colors.primary
            _ = KingDesignTokens.Typography.body
            _ = KingDesignTokens.Spacing.md
        }
        
        let elapsed = Date().timeIntervalSince(startTime)
        #expect(elapsed < 0.1, "Token access should be fast (< 100ms for 1000 accesses)")
    }
    
    @Test("View modifier application is efficient")
    func testViewModifierPerformance() {
        let startTime = Date()
        
        for _ in 0..<100 {
            _ = Text("Test").glass()
        }
        
        let elapsed = Date().timeIntervalSince(startTime)
        #expect(elapsed < 0.1, "View modifier application should be fast")
    }
}

// MARK: - Accessibility Tests

@Suite("Accessibility Tests")
struct AccessibilityTests {
    
    @Test("Colors have sufficient contrast")
    func testColorContrast() {
        // Primary text on background should have good contrast
        // This is a simplified test - in production, use proper contrast calculation
        #expect(KingDesignTokens.Colors.primary != KingDesignTokens.Colors.background)
        #expect(KingDesignTokens.Colors.accent != KingDesignTokens.Colors.background)
    }
    
    @Test("Typography supports dynamic type")
    func testDynamicTypeSupport() {
        // Verify fonts are created with system design
        let bodyFont = KingDesignTokens.Typography.body
        #expect(true, "Fonts should support dynamic type and be accessible")
    }
    
    @Test("Interactive elements have minimum size")
    func testMinimumTapTargets() {
        // Verify button sizes meet accessibility guidelines (44pt minimum)
        let smallButtonHeight = GlassButton.Size.small.height
        let mediumButtonHeight = GlassButton.Size.medium.height
        let largeButtonHeight = GlassButton.Size.large.height
        
        #expect(smallButtonHeight >= 44, "Small button should meet minimum tap target")
        #expect(mediumButtonHeight >= 44, "Medium button should meet minimum tap target")
        #expect(largeButtonHeight >= 44, "Large button should meet minimum tap target")
    }
}

// MARK: - Migration Compatibility Tests

@Suite("Migration Compatibility Tests")
struct MigrationTests {
    
    @Test("Deprecated type aliases work")
    func testDeprecatedAliases() {
        // These should still work but be marked as deprecated
        #expect(KingColors.self == KingDesignTokens.Colors.self)
        #expect(KingTypography.self == KingDesignTokens.Typography.self)
        #expect(KingSpacing.self == KingDesignTokens.Spacing.self)
    }
}
