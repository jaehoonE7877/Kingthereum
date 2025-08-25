import Testing
import Foundation
import SwiftUI
import Combine
import Entity
@testable import Core

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
        let displayModeService = DisplayModeService()
        
        // Then
        #expect(displayModeService.currentMode == .system, "Should default to system mode")
    }
    
    // MARK: - Display Mode Setting Tests
    
    @MainActor @Test("Set display mode to light")
    func testSetDisplayModeToLight() async {
        // Given
        let displayModeService = DisplayModeService()
        
        // When
        displayModeService.setDisplayMode(.light)
        
        // Then
        #expect(displayModeService.currentMode == .light, "Display mode should be set to light")
    }
    
    @MainActor @Test("Set display mode to dark")
    func testSetDisplayModeToDark() async {
        // Given
        let displayModeService = DisplayModeService()
        
        // When
        displayModeService.setDisplayMode(.dark)
        
        // Then
        #expect(displayModeService.currentMode == .dark, "Display mode should be set to dark")
    }
    
    @MainActor @Test("Set display mode to system")
    func testSetDisplayModeToSystem() async {
        // Given
        let displayModeService = DisplayModeService()
        displayModeService.setDisplayMode(.light) // Change from default
        
        // When
        displayModeService.setDisplayMode(.system)
        
        // Then
        #expect(displayModeService.currentMode == .system, "Display mode should be set to system")
    }
    
    // MARK: - Effective Color Scheme Tests
    
    @MainActor @Test("Effective color scheme for light mode")
    func testEffectiveColorSchemeForLightMode() async {
        // Given
        let displayModeService = DisplayModeService()
        
        // When
        displayModeService.setDisplayMode(.light)
        
        // Then
        #expect(displayModeService.effectiveColorScheme == .light, "Effective color scheme should be light")
    }
    
    @MainActor @Test("Effective color scheme for dark mode")
    func testEffectiveColorSchemeForDarkMode() async {
        // Given
        let displayModeService = DisplayModeService()
        
        // When
        displayModeService.setDisplayMode(.dark)
        
        // Then
        #expect(displayModeService.effectiveColorScheme == .dark, "Effective color scheme should be dark")
    }
    
    @MainActor @Test("Effective color scheme for system mode")
    func testEffectiveColorSchemeForSystemMode() async {
        // Given
        let displayModeService = DisplayModeService()
        
        // When
        displayModeService.setDisplayMode(.system)
        
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
            #expect(mode.name == expectedName, "Display name for \(mode) should be \(expectedName)")
        }
    }
    
    @Test("Display mode descriptions")
    func testDisplayModeDescriptions() {
        let modeDescriptions: [(DisplayMode, String)] = [
            (.light, "Light mode"),
            (.dark, "Dark mode"),
            (.system, "Follow system setting")
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
            (.system, "gear")
        ]
        
        for (mode, expectedIcon) in modeIcons {
            #expect(mode.systemIcon == expectedIcon, "System icon for \(mode) should be \(expectedIcon)")
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
        let userDefaults = UserDefaults()
        let key = "DisplayMode"
        
        // Clean up any existing value
        userDefaults.removeObject(forKey: key)
        
        let displayModeService = DisplayModeService()
        
        // When - Set a specific mode
        displayModeService.setDisplayMode(.dark)
        
        // Then - Should persist the setting
        let savedMode = userDefaults.string(forKey: key)
        #expect(savedMode == "dark", "Display mode should be persisted to UserDefaults")
        
        // Cleanup
        userDefaults.removeObject(forKey: key)
    }
    
    @MainActor @Test("Display mode restoration from persistence")
    func testDisplayModeRestorationFromPersistence() async {
        // Given
        let userDefaults = UserDefaults()
        let key = "DisplayMode"
        
        // Set up a persisted value
        userDefaults.set("light", forKey: key)
        
        // When - Create new service instance
        let displayModeService = DisplayModeService()
        
        // Then - Should restore the persisted mode
        #expect(displayModeService.currentMode == .light, "Display mode should be restored from UserDefaults")
        
        // Cleanup
        userDefaults.removeObject(forKey: key)
    }
    
    @MainActor @Test("Display mode invalid persistence value")
    func testDisplayModeInvalidPersistenceValue() async {
        // Given
        let userDefaults = UserDefaults()
        let key = "DisplayMode"
        
        // Set up an invalid persisted value
        userDefaults.set("invalid_mode", forKey: key)
        
        // When - Create new service instance
        let displayModeService = DisplayModeService()
        
        // Then - Should fall back to default system mode
        #expect(displayModeService.currentMode == .system, "Should fall back to system mode for invalid persisted value")
        
        // Cleanup
        userDefaults.removeObject(forKey: key)
    }
    
    // MARK: - Publisher Tests
    
    @MainActor @Test("Display mode publisher emission")
    func testDisplayModePublisherEmission() async {
        // Given
        let displayModeService = DisplayModeService()
        var receivedModes: [DisplayMode] = []
        let expectation = expectation(description: "Display mode changes received")
        
        // When - Subscribe to publisher
        let cancellable = displayModeService.$currentMode
            .sink { mode in
                receivedModes.append(mode)
                if receivedModes.count == 3 { // Initial + 2 changes
                    expectation.fulfill()
                }
            }
        
        // Change modes
        displayModeService.setDisplayMode(.light)
        displayModeService.setDisplayMode(.dark)
        
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // Then
        #expect(receivedModes.count == 3, "Should receive initial mode plus 2 changes")
        #expect(receivedModes[0] == .system, "First emission should be initial system mode")
        #expect(receivedModes[1] == .light, "Second emission should be light mode")
        #expect(receivedModes[2] == .dark, "Third emission should be dark mode")
        
        cancellable.cancel()
    }
    
    @MainActor @Test("Display mode publisher distinct values")
    func testDisplayModePublisherDistinctValues() async {
        // Given
        let displayModeService = DisplayModeService()
        var receivedModes: [DisplayMode] = []
        let expectation = expectation(description: "Display mode distinct changes received")
        
        // When - Subscribe to publisher
        let cancellable = displayModeService.$currentMode
            .removeDuplicates()
            .sink { mode in
                receivedModes.append(mode)
                if receivedModes.count == 3 { // Initial + 2 distinct changes
                    expectation.fulfill()
                }
            }
        
        // Change modes (including duplicate)
        displayModeService.setDisplayMode(.light)
        displayModeService.setDisplayMode(.light) // Duplicate
        displayModeService.setDisplayMode(.dark)
        
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // Then
        #expect(receivedModes.count == 3, "Should receive only distinct mode changes")
        #expect(receivedModes[0] == .system, "First emission should be initial system mode")
        #expect(receivedModes[1] == .light, "Second emission should be light mode")
        #expect(receivedModes[2] == .dark, "Third emission should be dark mode")
        
        cancellable.cancel()
    }
    
    // MARK: - Performance Tests
    
    @MainActor @Test("Display mode setting performance")
    func testDisplayModeSettingPerformance() async {
        // Given
        let displayModeService = DisplayModeService()
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // When - Perform multiple mode changes
        for i in 0..<1000 {
            let mode: DisplayMode = i % 3 == 0 ? .system : (i % 3 == 1 ? .light : .dark)
            displayModeService.setDisplayMode(mode)
        }
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Then - Should be fast (under 100ms)
        #expect(timeElapsed < 0.1, "Display mode setting should be fast")
    }
    
    // MARK: - Thread Safety Tests
    
    @MainActor @Test("Display mode concurrent access")
    func testDisplayModeConcurrentAccess() async {
        // Given
        let displayModeService = DisplayModeService()
        
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
        let expectation = expectation(description: "Mock mode changes received")
        
        // When - Subscribe to mock publisher
        let cancellable = mockDisplayModeService.$currentMode
            .sink { mode in
                receivedModes.append(mode)
                if receivedModes.count == 2 { // Initial + 1 change
                    expectation.fulfill()
                }
            }
        
        mockDisplayModeService.setDisplayMode(.dark)
        
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // Then
        #expect(receivedModes.count == 2, "Should receive initial mode plus change")
        #expect(receivedModes[0] == DisplayMode.system, "First emission should be initial system mode")
        #expect(receivedModes[1] == DisplayMode.dark, "Second emission should be dark mode")
        
        cancellable.cancel()
    }
}

// MARK: - Test Helpers

extension DisplayModeServiceTests {
    
    /// Helper function to create expectation for async testing
    private func expectation(description: String) -> XCTestExpectation {
        return XCTestExpectation(description: description)
    }
}

extension DisplayModeServiceMockIntegrationTests {
    
    /// Helper function to create expectation for async testing
    private func expectation(description: String) -> XCTestExpectation {
        return XCTestExpectation(description: description)
    }
}

/// XCTestExpectation replacement for Testing framework
private final class XCTestExpectation: @unchecked Sendable {
    private let description: String
    private var isFulfilled = false
    private let lock = NSLock()
    
    init(description: String) {
        self.description = description
    }
    
    func fulfill() {
        lock.lock()
        defer { lock.unlock() }
        isFulfilled = true
    }
    
    var fulfilled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return isFulfilled
    }
}

/// Helper function for async expectation fulfillment
private func fulfillment(of expectations: [XCTestExpectation], timeout: TimeInterval) async {
    let startTime = Date()
    
    while !expectations.allSatisfy({ $0.fulfilled }) {
        if Date().timeIntervalSince(startTime) > timeout {
            break
        }
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
    }
}