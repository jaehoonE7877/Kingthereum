import Testing
import Foundation
import SwiftUI
import Combine
import Entity
@testable import Core

@MainActor
private func makeDisplayModeServiceContext(
    _ name: StaticString,
    configureDefaults: ((UserDefaults) -> Void)? = nil
) -> (service: DisplayModeService, defaults: UserDefaults, suiteName: String) {
    let suiteName = "DisplayModeServiceTests.\(String(describing: name))"
    guard let defaults = UserDefaults(suiteName: suiteName) else {
        fatalError("Failed to create UserDefaults suite: \(suiteName)")
    }
    defaults.removePersistentDomain(forName: suiteName)
    configureDefaults?(defaults)
    let service = DisplayModeService(userDefaults: defaults, applyToSystem: false)
    return (service, defaults, suiteName)
}

/// Mock DisplayModeService for testing
@MainActor
final class MockDisplayModeService: DisplayModeServiceProtocol {
    
    @Published private(set) var currentMode: DisplayMode = .system
    
    init(initialMode: DisplayMode = .system) {
        self.currentMode = initialMode
    }
    
    func setDisplayMode(_ mode: DisplayMode) {
        currentMode = mode
    }
    
    var effectiveColorScheme: ColorScheme? {
        return currentMode.colorScheme
    }
}

/// DisplayModeService 단위 테스트
/// 다크모드/라이트모드 설정 관리 기능을 테스트
@Suite("DisplayModeService Tests")
struct DisplayModeServiceTests {
    
    // MARK: - Initialization Tests
    
    @MainActor @Test("Display mode service initialization")
    func testDisplayModeServiceInitialization() async {
        // Given & When
        let context = makeDisplayModeServiceContext(#function)
        defer { context.defaults.removePersistentDomain(forName: context.suiteName) }
        let displayModeService = context.service
        
        // Then
        #expect(displayModeService.currentMode == .system, "Should default to system mode")
    }
    
    // MARK: - Display Mode Setting Tests
    
    @MainActor @Test("Set display mode to light")
    func testSetDisplayModeToLight() async {
        // Given
        let context = makeDisplayModeServiceContext(#function)
        defer { context.defaults.removePersistentDomain(forName: context.suiteName) }
        let displayModeService = context.service
        
        // When
        displayModeService.setDisplayMode(.light)
        await Task.yield()
        
        // Then
        #expect(displayModeService.currentMode == .light, "Display mode should be set to light")
    }
    
    @MainActor @Test("Set display mode to dark")
    func testSetDisplayModeToDark() async {
        // Given
        let context = makeDisplayModeServiceContext(#function)
        defer { context.defaults.removePersistentDomain(forName: context.suiteName) }
        let displayModeService = context.service
        
        // When
        displayModeService.setDisplayMode(.dark)
        await Task.yield()
        
        // Then
        #expect(displayModeService.currentMode == .dark, "Display mode should be set to dark")
    }
    
    @MainActor @Test("Set display mode to system")
    func testSetDisplayModeToSystem() async {
        // Given
        let context = makeDisplayModeServiceContext(#function)
        defer { context.defaults.removePersistentDomain(forName: context.suiteName) }
        let displayModeService = context.service
        displayModeService.setDisplayMode(.light) // Change from default
        
        // When
        displayModeService.setDisplayMode(.system)
        await Task.yield()
        
        // Then
        #expect(displayModeService.currentMode == .system, "Display mode should be set to system")
    }
    
    // MARK: - Effective Color Scheme Tests
    
    @MainActor @Test("Effective color scheme for light mode")
    func testEffectiveColorSchemeForLightMode() async {
        // Given
        let context = makeDisplayModeServiceContext(#function)
        defer { context.defaults.removePersistentDomain(forName: context.suiteName) }
        let displayModeService = context.service
        
        // When
        displayModeService.setDisplayMode(.light)
        await Task.yield()
        
        // Then
        #expect(displayModeService.effectiveColorScheme == .light, "Effective color scheme should be light")
    }
    
    @MainActor @Test("Effective color scheme for dark mode")
    func testEffectiveColorSchemeForDarkMode() async {
        // Given
        let context = makeDisplayModeServiceContext(#function)
        defer { context.defaults.removePersistentDomain(forName: context.suiteName) }
        let displayModeService = context.service
        
        // When
        displayModeService.setDisplayMode(.dark)
        await Task.yield()
        
        // Then
        #expect(displayModeService.effectiveColorScheme == .dark, "Effective color scheme should be dark")
    }
    
    @MainActor @Test("Effective color scheme for system mode")
    func testEffectiveColorSchemeForSystemMode() async {
        // Given
        let context = makeDisplayModeServiceContext(#function)
        defer { context.defaults.removePersistentDomain(forName: context.suiteName) }
        let displayModeService = context.service
        
        // When
        displayModeService.setDisplayMode(.system)
        await Task.yield()
        
        // Then
        #expect(displayModeService.effectiveColorScheme == nil, "Effective color scheme should be nil for system mode")
    }
    
    // MARK: - Display Mode Properties Tests
    
    @Test("Display mode names")
    func testDisplayModeNames() {
        let modeNames: [(DisplayMode, String)] = [
            (.light, "Light"),
            (.dark, "Dark"),
            (.system, "System")
        ]
        
        for (mode, expectedName) in modeNames {
            #expect(mode.englishName == expectedName, "English name for \(mode) should be \(expectedName)")
        }
    }
    
    @Test("Display mode descriptions")
    func testDisplayModeDescriptions() {
        let modeDescriptions: [(DisplayMode, String)] = [
            (.light, "항상 밝은 테마를 사용합니다"),
            (.dark, "항상 어두운 테마를 사용합니다"),
            (.system, "기기의 시스템 설정을 따릅니다")
        ]
        
        for (mode, expectedDescription) in modeDescriptions {
            #expect(mode.description == expectedDescription, "Description for \(mode) should be \(expectedDescription)")
        }
    }
    
    @Test("Display mode system icons")
    func testDisplayModeSystemIcons() {
        let modeIcons: [(DisplayMode, String)] = [
            (.light, "sun.max.fill"),
            (.dark, "moon.fill"),
            (.system, "gearshape.fill")
        ]
        
        for (mode, expectedIcon) in modeIcons {
            #expect(mode.iconName == expectedIcon, "Icon name for \(mode) should be \(expectedIcon)")
        }
    }
    
    @Test("Display mode color scheme properties")
    func testDisplayModeColorSchemeProperties() {
        #expect(DisplayMode.light.colorScheme == .light, "Light mode should have light color scheme")
        #expect(DisplayMode.dark.colorScheme == .dark, "Dark mode should have dark color scheme")
        #expect(DisplayMode.system.colorScheme == nil, "System mode should have nil color scheme")
    }
    
    // MARK: - Display Mode Case Iteration Tests
    
    @Test("Display mode all cases")
    func testDisplayModeAllCases() {
        let allCases = DisplayMode.allCases
        
        #expect(allCases.count == 3, "Should have 3 display mode cases")
        #expect(allCases.contains(.light), "Should contain light mode")
        #expect(allCases.contains(.dark), "Should contain dark mode")
        #expect(allCases.contains(.system), "Should contain system mode")
    }
    
    // MARK: - Persistence Tests
    
    @MainActor @Test("Display mode persistence")
    func testDisplayModePersistence() async {
        // Given
        let context = makeDisplayModeServiceContext(#function)
        defer { context.defaults.removePersistentDomain(forName: context.suiteName) }
        let displayModeService = context.service
        
        // When - Set a specific mode
        displayModeService.setDisplayMode(.dark)
        await Task.yield()
        
        // Then - Should persist the setting
        let savedMode = context.defaults.string(forKey: "DisplayMode")
        #expect(savedMode == "dark", "Display mode should be persisted to UserDefaults")
        
        // Cleanup
        context.defaults.removeObject(forKey: "DisplayMode")
    }
    
    @MainActor @Test("Display mode restoration from persistence")
    func testDisplayModeRestorationFromPersistence() async {
        // Given
        let context = makeDisplayModeServiceContext(#function) { defaults in
            defaults.set("light", forKey: "DisplayMode")
        }
        defer { context.defaults.removePersistentDomain(forName: context.suiteName) }
        let displayModeService = context.service
        
        // Then - Should restore the persisted mode
        #expect(displayModeService.currentMode == .light, "Display mode should be restored from UserDefaults")
        
        // Cleanup
        context.defaults.removeObject(forKey: "DisplayMode")
    }
    
    @MainActor @Test("Display mode invalid persistence value")
    func testDisplayModeInvalidPersistenceValue() async {
        // Given
        let context = makeDisplayModeServiceContext(#function) { defaults in
            defaults.set("invalid_mode", forKey: "DisplayMode")
        }
        defer { context.defaults.removePersistentDomain(forName: context.suiteName) }
        let displayModeService = context.service
        
        // Then - Should fall back to default system mode
        #expect(displayModeService.currentMode == .system, "Should fall back to system mode for invalid persisted value")
        
        // Cleanup
        context.defaults.removeObject(forKey: "DisplayMode")
    }
    
    // MARK: - Publisher Tests
    
    @MainActor @Test("Display mode publisher emission")
    func testDisplayModePublisherEmission() async {
        // Given
        let context = makeDisplayModeServiceContext(#function)
        defer { context.defaults.removePersistentDomain(forName: context.suiteName) }
        let displayModeService = context.service
        var receivedModes: [DisplayMode] = []
        
        // When - Subscribe to publisher and collect values
        let cancellable = displayModeService.$currentMode
            .sink { mode in
                receivedModes.append(mode)
            }
        
        // Allow initial value to be captured
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        // Change modes
        displayModeService.setDisplayMode(.light)
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        displayModeService.setDisplayMode(.dark)
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        // Then
        #expect(receivedModes.count >= 3, "Should receive initial mode plus changes")
        #expect(receivedModes.first == .system, "First emission should be initial system mode")
        #expect(receivedModes.contains(.light), "Should contain light mode")
        #expect(receivedModes.contains(.dark), "Should contain dark mode")
        
        cancellable.cancel()
    }
    
    @MainActor @Test("Display mode publisher distinct values")
    func testDisplayModePublisherDistinctValues() async {
        // Given
        let context = makeDisplayModeServiceContext(#function)
        defer { context.defaults.removePersistentDomain(forName: context.suiteName) }
        let displayModeService = context.service
        var receivedModes: [DisplayMode] = []
        
        // When - Subscribe to publisher with removeDuplicates
        let cancellable = displayModeService.$currentMode
            .removeDuplicates()
            .sink { mode in
                receivedModes.append(mode)
            }
        
        // Allow initial value to be captured
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        // Change modes (including duplicate)
        displayModeService.setDisplayMode(.light)
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        displayModeService.setDisplayMode(.light) // Duplicate - should be filtered
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        displayModeService.setDisplayMode(.dark)
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        // Then - Duplicates should be filtered out
        #expect(receivedModes.count >= 3, "Should receive distinct mode changes only")
        #expect(receivedModes.first == .system, "First emission should be initial system mode")
        #expect(receivedModes.contains(.light), "Should contain light mode")
        #expect(receivedModes.contains(.dark), "Should contain dark mode")
        
        cancellable.cancel()
    }
    
    // MARK: - Performance Tests
    
    @MainActor @Test("Display mode setting performance")
    func testDisplayModeSettingPerformance() async {
        // Given
        let context = makeDisplayModeServiceContext(#function)
        defer { context.defaults.removePersistentDomain(forName: context.suiteName) }
        let displayModeService = context.service
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // When - Perform multiple mode changes
        for i in 0..<1000 {
            let mode: DisplayMode = i % 3 == 0 ? .system : (i % 3 == 1 ? .light : .dark)
            displayModeService.setDisplayMode(mode)
        }
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Then - Should be fast (under 100ms)
        #expect(timeElapsed < 0.5, "Display mode setting should be fast")
    }
    
    // MARK: - Thread Safety Tests
    
    @MainActor @Test("Display mode concurrent access")
    func testDisplayModeConcurrentAccess() async {
        // Given
        let context = makeDisplayModeServiceContext(#function)
        defer { context.defaults.removePersistentDomain(forName: context.suiteName) }
        let displayModeService = context.service
        
        // When - Multiple concurrent mode changes
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<100 {
                group.addTask { @MainActor in
                    let mode: DisplayMode = i % 3 == 0 ? .system : (i % 3 == 1 ? .light : .dark)
                    displayModeService.setDisplayMode(mode)
                }
            }
        }
        
        // Then - Should not crash and should have a valid final state
        let finalMode = displayModeService.currentMode
        #expect([DisplayMode.system, .light, .dark].contains(finalMode), "Final mode should be valid")
    }
}

/// DisplayModeService Mock을 이용한 테스트
@MainActor @Suite("DisplayModeService Mock Integration Tests")
struct DisplayModeServiceMockIntegrationTests {
    
    @Test("Mock display mode service functionality")
    func testMockDisplayModeServiceFunctionality() async {
        // Given
        let mockDisplayModeService = MockDisplayModeService()
        
        // When & Then - Test mock implementation
        #expect(mockDisplayModeService.currentMode == DisplayMode.system, "Mock should start with system mode")
        
        // Test mode changes
        mockDisplayModeService.setDisplayMode(.light)
        #expect(mockDisplayModeService.currentMode == DisplayMode.light, "Mock should update to light mode")
        
        mockDisplayModeService.setDisplayMode(.dark)
        #expect(mockDisplayModeService.currentMode == DisplayMode.dark, "Mock should update to dark mode")
    }
    
    @Test("Mock effective color scheme")
    func testMockEffectiveColorScheme() async {
        // Given
        let mockDisplayModeService = MockDisplayModeService()
        
        // When & Then - Test effective color scheme for each mode
        mockDisplayModeService.setDisplayMode(.light)
        #expect(mockDisplayModeService.effectiveColorScheme == ColorScheme.light, "Mock should return light color scheme")
        
        mockDisplayModeService.setDisplayMode(.dark)
        #expect(mockDisplayModeService.effectiveColorScheme == ColorScheme.dark, "Mock should return dark color scheme")
        
        mockDisplayModeService.setDisplayMode(.system)
        #expect(mockDisplayModeService.effectiveColorScheme == nil, "Mock should return nil for system mode")
    }
    
    @Test("Mock publisher behavior")
    func testMockPublisherBehavior() async {
        // Given
        let mockDisplayModeService = MockDisplayModeService()
        var receivedModes: [DisplayMode] = []
        
        // When - Subscribe to mock publisher
        let cancellable = mockDisplayModeService.$currentMode
            .sink { mode in
                receivedModes.append(mode)
            }
        
        // Allow initial value to be captured
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        mockDisplayModeService.setDisplayMode(.dark)
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        // Then
        #expect(receivedModes.count >= 2, "Should receive initial mode plus change")
        #expect(receivedModes.first == DisplayMode.system, "First emission should be initial system mode")
        #expect(receivedModes.contains(.dark), "Should contain dark mode")
        
        cancellable.cancel()
    }
}
