import Foundation
import Entity

@MainActor
protocol SplashPresentationLogic: AnyObject {
    func presentInitialAnimations(response: SplashScene.Appear.Response)
    func presentCompletion(response: SplashScene.Complete.Response)
}

@MainActor
final class SplashPresenter: SplashPresentationLogic {
    weak var viewController: SplashDisplayLogic?
    
    init(viewController: SplashDisplayLogic? = nil) {
        self.viewController = viewController
    }
    
    func presentInitialAnimations(response: SplashScene.Appear.Response) {
        let viewModel = SplashScene.Appear.ViewModel(animationStyle: response.animationStyle)
        viewController?.displayInitialAnimations(viewModel: viewModel)
    }
    
    func presentCompletion(response: SplashScene.Complete.Response) {
        let viewModel = SplashScene.Complete.ViewModel(shouldFadeOut: response.shouldFadeOut)
        viewController?.displayCompletion(viewModel: viewModel)
    }
}
