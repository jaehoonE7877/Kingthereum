import Testing
import Foundation

@Suite("Swift Testing Validation")
struct SwiftTestingValidationTest {
    
    @Test("Basic test should pass")
    func basicTest() {
        #expect(true)
    }
    
    @Test("Parameterized test", arguments: [1, 2, 3, 4, 5])
    func parameterizedTest(number: Int) {
        #expect(number > 0)
    }
    
    @Test("String comparison test")  
    func stringComparisonTest() {
        let expected = "Hello, World!"
        let actual = "Hello, World!"
        #expect(actual == expected)
    }
}