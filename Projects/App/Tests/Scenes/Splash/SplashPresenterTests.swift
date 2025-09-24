import Testing
@testable import Scenes
@testable import Entity

@MainActor @Suite("SplashPresenter 테스트")
struct SplashPresenterTests {
    final class SplashDisplayLogicSpy: SplashDisplayLogic {
        var displayInitialAnimationsCalled = false
        var displayInitialAnimationsViewModel: SplashScene.Appear.ViewModel?
        
        func displayInitialAnimations(viewModel: SplashScene.Appear.ViewModel) {
            displayInitialAnimationsCalled = true
            displayInitialAnimationsViewModel = viewModel
        }
        
        var displayCompletionCalled = false
        var displayCompletionViewModel: SplashScene.Complete.ViewModel?
        
        func displayCompletion(viewModel: SplashScene.Complete.ViewModel) {
            displayCompletionCalled = true
            displayCompletionViewModel = viewModel
        }
    }
    
    @Test("InitialAnimations 응답을 ViewModel로 변환")
    func testPresentInitialAnimations() {
        let spy = SplashDisplayLogicSpy()
        let sut = SplashPresenter(viewController: spy)
        let response = SplashScene.Appear.Response(animationStyle: .full)
        
        sut.presentInitialAnimations(response: response)
        
        #expect(spy.displayInitialAnimationsCalled == true)
        #expect(spy.displayInitialAnimationsViewModel?.animationStyle == .full)
    }
    
    @Test("Splash 완료 이벤트를 fade-out 여부와 함께 전달")
    func testPresentCompletion() {
        let spy = SplashDisplayLogicSpy()
        let sut = SplashPresenter(viewController: spy)
        let response = SplashScene.Complete.Response(shouldFadeOut: true)
        
        sut.presentCompletion(response: response)
        
        #expect(spy.displayCompletionCalled == true)
        #expect(spy.displayCompletionViewModel?.shouldFadeOut == true)
    }
}
