import Foundation

/// Splash Scene의 VIP 모델
public enum SplashScene {
    /// 스플래시 애니메이션 스타일
    public enum AnimationStyle: Equatable {
        case full
        case reduced
    }
    
    // MARK: - 초기 진입
    
    public enum Appear {
        public struct Request {
            public let reduceMotion: Bool
            
            public init(reduceMotion: Bool) {
                self.reduceMotion = reduceMotion
            }
        }
        
        public struct Response {
            public let animationStyle: AnimationStyle
            
            public init(animationStyle: AnimationStyle) {
                self.animationStyle = animationStyle
            }
        }
        
        public struct ViewModel {
            public let animationStyle: AnimationStyle
            
            public init(animationStyle: AnimationStyle) {
                self.animationStyle = animationStyle
            }
        }
    }
    
    // MARK: - 완료 처리
    
    public enum Complete {
        public struct Request {
            public init() {}
        }
        
        public struct Response {
            public let shouldFadeOut: Bool
            
            public init(shouldFadeOut: Bool) {
                self.shouldFadeOut = shouldFadeOut
            }
        }
        
        public struct ViewModel {
            public let shouldFadeOut: Bool
            
            public init(shouldFadeOut: Bool) {
                self.shouldFadeOut = shouldFadeOut
            }
        }
    }
}
