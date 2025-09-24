import Foundation
import Entity

protocol SplashWorkerProtocol {
    func determineAnimationStyle(reduceMotionEnabled: Bool) -> SplashScene.AnimationStyle
}

struct SplashWorker: SplashWorkerProtocol {
    func determineAnimationStyle(reduceMotionEnabled: Bool) -> SplashScene.AnimationStyle {
        reduceMotionEnabled ? .reduced : .full
    }
}
