import SwiftUI
import UIKit

/// SwiftUI에서 MetalGlassView를 사용하기 위한 UIViewRepresentable 래퍼
public struct MetalLiquidGlassView: UIViewRepresentable {
    
    // MARK: - Properties
    
    /// Glass 설정
    @Binding var glassSettings: LiquidGlassSettings
    
    /// 백그라운드 이미지
    private let backgroundImage: UIImage?
    
    /// 자동 백그라운드 업데이트 여부
    private let autoUpdateBackground: Bool
    
    /// 터치 이벤트 핸들러
    private let onTouchGesture: ((CGPoint) -> Void)?
    
    // MARK: - Initializers
    
    /// 기본 초기화
    public init(
        glassSettings: Binding<LiquidGlassSettings> = .constant(LiquidGlassSettings()),
        autoUpdateBackground: Bool = true,
        onTouchGesture: ((CGPoint) -> Void)? = nil
    ) {
        self._glassSettings = glassSettings
        self.backgroundImage = nil
        self.autoUpdateBackground = autoUpdateBackground
        self.onTouchGesture = onTouchGesture
    }
    
    /// 정적 이미지를 백그라운드로 사용
    public init(
        glassSettings: Binding<LiquidGlassSettings> = .constant(LiquidGlassSettings()),
        backgroundImage: UIImage,
        onTouchGesture: ((CGPoint) -> Void)? = nil
    ) {
        self._glassSettings = glassSettings
        self.backgroundImage = backgroundImage
        self.autoUpdateBackground = false
        self.onTouchGesture = onTouchGesture
    }
    
    // MARK: - UIViewRepresentable
    
    public func makeUIView(context: Context) -> MetalGlassView {
        let metalGlassView = MetalGlassView()
        
        // 초기 설정
        metalGlassView.glassSettings = glassSettings
        metalGlassView.autoUpdateBackground = autoUpdateBackground
        
        // 백그라운드 설정
        if let backgroundImage = backgroundImage {
            metalGlassView.setBackgroundImage(backgroundImage)
        }
        
        // 터치 제스처 설정
        if let onTouchGesture = onTouchGesture {
            let tapGesture = UITapGestureRecognizer { gesture in
                let location = gesture.location(in: metalGlassView)
                onTouchGesture(location)
                metalGlassView.addTouchRippleEffect(at: location)
            }
            metalGlassView.addGestureRecognizer(tapGesture)
        }
        
        return metalGlassView
    }
    
    public func updateUIView(_ uiView: MetalGlassView, context: Context) {
        // Glass 설정 업데이트
        uiView.glassSettings = glassSettings
        
        if let backgroundImage = backgroundImage {
            uiView.setBackgroundImage(backgroundImage)
        }
        
        uiView.autoUpdateBackground = autoUpdateBackground
    }
}

// MARK: - SwiftUI View Extensions

public extension View {
    
    /// 뷰에 Metal Liquid Glass 효과 적용
    func metalLiquidGlass(
        settings: Binding<LiquidGlassSettings> = .constant(LiquidGlassSettings()),
        autoUpdate: Bool = true
    ) -> some View {
        self
            .background(
                MetalLiquidGlassView(
                    glassSettings: settings,
                    autoUpdateBackground: autoUpdate
                )
            )
    }
    
    /// 특정 프리셋으로 Glass 효과 적용
    func metalLiquidGlass(
        preset: MetalGlassView.GlassPreset,
        autoUpdate: Bool = true
    ) -> some View {
        self
            .background(
                MetalLiquidGlassView(
                    glassSettings: .constant(preset.settings),
                    autoUpdateBackground: autoUpdate
                )
            )
    }
    
    /// 터치 인터랙션이 있는 Glass 효과
    func interactiveLiquidGlass(
        settings: Binding<LiquidGlassSettings> = .constant(LiquidGlassSettings()),
        onTouch: @escaping (CGPoint) -> Void
    ) -> some View {
        self
            .background(
                MetalLiquidGlassView(
                    glassSettings: settings,
                    onTouchGesture: onTouch
                )
            )
    }
}

// MARK: - Supporting Extensions

private extension UITapGestureRecognizer {
    convenience init(action: @escaping (UITapGestureRecognizer) -> Void) {
        self.init()
        addTarget(TapGestureTarget(action: action), action: #selector(TapGestureTarget.invoke))
    }
}

private class TapGestureTarget: NSObject {
    private let action: (UITapGestureRecognizer) -> Void
    
    init(action: @escaping (UITapGestureRecognizer) -> Void) {
        self.action = action
    }
    
    @objc func invoke(gesture: UITapGestureRecognizer) {
        action(gesture)
    }
}