import Foundation
import Core
import Entity

@MainActor
protocol SplashBusinessLogic: AnyObject {
    func handleAppear(request: SplashScene.Appear.Request)
    func completeSplash(request: SplashScene.Complete.Request)
}

@MainActor
final class SplashInteractor: SplashBusinessLogic {
    var presenter: SplashPresentationLogic?
    private let worker: SplashWorkerProtocol
    
    init(worker: SplashWorkerProtocol = SplashWorker()) {
        self.worker = worker
    }
    
    func handleAppear(request: SplashScene.Appear.Request) {
        Logger.debug("⚡️ [SplashInteractor] handleAppear reduceMotion=\(request.reduceMotion)")
        let animationStyle = worker.determineAnimationStyle(reduceMotionEnabled: request.reduceMotion)
        let response = SplashScene.Appear.Response(animationStyle: animationStyle)
        presenter?.presentInitialAnimations(response: response)
    }
    
    func completeSplash(request: SplashScene.Complete.Request) {
        Logger.debug("✅ [SplashInteractor] completeSplash")
        let response = SplashScene.Complete.Response(shouldFadeOut: true)
        presenter?.presentCompletion(response: response)
    }
}
