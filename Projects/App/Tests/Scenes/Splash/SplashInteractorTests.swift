import Testing
@testable import Scenes
@testable import Entity

@MainActor @Suite("SplashInteractor 테스트")
struct SplashInteractorTests {
    final class SplashPresenterSpy: SplashPresentationLogic {
        var presentInitialAnimationsCalled = false
        var lastAppearResponse: SplashScene.Appear.Response?
        
        func presentInitialAnimations(response: SplashScene.Appear.Response) {
            presentInitialAnimationsCalled = true
            lastAppearResponse = response
        }
        
        var presentCompletionCalled = false
        var lastCompletionResponse: SplashScene.Complete.Response?
        
        func presentCompletion(response: SplashScene.Complete.Response) {
            presentCompletionCalled = true
            lastCompletionResponse = response
        }
    }
    
    final class SplashWorkerSpy: SplashWorkerProtocol {
        var receivedReduceMotion: Bool?
        var animationStyleToReturn: SplashScene.AnimationStyle
        
        init(animationStyleToReturn: SplashScene.AnimationStyle) {
            self.animationStyleToReturn = animationStyleToReturn
        }
        
        func determineAnimationStyle(reduceMotionEnabled: Bool) -> SplashScene.AnimationStyle {
            receivedReduceMotion = reduceMotionEnabled
            return animationStyleToReturn
        }
    }
    
    @Test("화면 진입 시 Worker 결과를 Presenter에 전달")
    func testHandleAppearForwardsWorkerResult() {
        let workerSpy = SplashWorkerSpy(animationStyleToReturn: .reduced)
        let presenterSpy = SplashPresenterSpy()
        let sut = SplashInteractor(worker: workerSpy)
        sut.presenter = presenterSpy
        
        sut.handleAppear(request: SplashScene.Appear.Request(reduceMotion: true))
        
        #expect(workerSpy.receivedReduceMotion == true)
        #expect(presenterSpy.presentInitialAnimationsCalled == true)
        #expect(presenterSpy.lastAppearResponse?.animationStyle == .reduced)
    }
    
    @Test("Splash 완료 시 fade-out 지시")
    func testCompleteSplashTriggersFadeOut() {
        let workerSpy = SplashWorkerSpy(animationStyleToReturn: .full)
        let presenterSpy = SplashPresenterSpy()
        let sut = SplashInteractor(worker: workerSpy)
        sut.presenter = presenterSpy
        
        sut.completeSplash(request: SplashScene.Complete.Request())
        
        #expect(presenterSpy.presentCompletionCalled == true)
        #expect(presenterSpy.lastCompletionResponse?.shouldFadeOut == true)
    }
}
