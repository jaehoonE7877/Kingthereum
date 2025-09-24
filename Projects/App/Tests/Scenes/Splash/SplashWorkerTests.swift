import Testing
@testable import Scenes
@testable import Entity

@Suite("SplashWorker 동작 테스트")
struct SplashWorkerTests {
    private let sut = SplashWorker()
    
    @Test("감소된 모션 접근성 설정 시 reduced 스타일 반환")
    func testDetermineAnimationStyleWithReducedMotion() {
        let style = sut.determineAnimationStyle(reduceMotionEnabled: true)
        #expect(style == .reduced)
    }
    
    @Test("감소된 모션이 아닐 때 full 스타일 반환")
    func testDetermineAnimationStyleWithFullMotion() {
        let style = sut.determineAnimationStyle(reduceMotionEnabled: false)
        #expect(style == .full)
    }
}
