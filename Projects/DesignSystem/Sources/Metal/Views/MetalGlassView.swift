import UIKit
import Metal
import MetalKit
import QuartzCore

/// UIView 기반의 Metal Liquid Glass 효과 뷰
@MainActor
public final class MetalGlassView: UIView {
    
    // MARK: - Properties
    
    /// Metal 뷰
    private var metalView: MTKView!
    
    /// Metal 렌더러
    private var renderer: MetalGlassRenderer?
    
    /// 백그라운드 캡처를 위한 뷰
    public weak var backgroundView: UIView? {
        didSet {
            updateBackgroundSnapshot()
        }
    }
    
    /// Glass 설정
    public var glassSettings = LiquidGlassSettings() {
        didSet {
            renderer?.glassSettings = glassSettings
        }
    }
    
    /// 자동 백그라운드 업데이트 여부
    public var autoUpdateBackground: Bool = true
    
    /// 현재 백그라운드 이미지
    private var currentBackgroundImage: UIImage?
    
    // MARK: - Initialization
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupMetalView()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupMetalView()
    }
    
    deinit {
        // Cleanup handled automatically when view is deallocated
    }
    
    // MARK: - Setup
    
    private func setupMetalView() {
        // Metal 뷰 생성
        metalView = MTKView(frame: bounds)
        metalView.translatesAutoresizingMaskIntoConstraints = false
        metalView.backgroundColor = UIColor.clear
        metalView.isOpaque = false
        metalView.framebufferOnly = false
        
        // Metal 렌더러 설정
        renderer = MetalGlassRenderer.shared
        metalView.device = renderer?.device
        metalView.delegate = self
        
        // 뷰 계층에 추가
        addSubview(metalView)
        
        // 오토레이아웃 설정
        NSLayoutConstraint.activate([
            metalView.topAnchor.constraint(equalTo: topAnchor),
            metalView.leadingAnchor.constraint(equalTo: leadingAnchor),
            metalView.trailingAnchor.constraint(equalTo: trailingAnchor),
            metalView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // 초기 설정
        backgroundColor = UIColor.clear
    }
    
    // MARK: - Public Methods
    
    /// 백그라운드 뷰 스냅샷 업데이트
    @MainActor
    public func updateBackgroundSnapshot() {
        guard let backgroundView = backgroundView else { return }
        
        Task { @MainActor in
            // 백그라운드 뷰의 스냅샷 생성
            UIGraphicsBeginImageContextWithOptions(backgroundView.bounds.size, false, UIScreen.main.scale)
            defer { UIGraphicsEndImageContext() }
            
            guard let context = UIGraphicsGetCurrentContext() else { return }
            backgroundView.layer.render(in: context)
            
            let snapshot = UIGraphicsGetImageFromCurrentImageContext()
            self.currentBackgroundImage = snapshot
        }
    }
    
    /// 특정 이미지로 백그라운드 설정
    public func setBackgroundImage(_ image: UIImage) {
        currentBackgroundImage = image
    }
    
    /// 터치 인터랙션 효과
    public func addTouchRippleEffect(at point: CGPoint) {
        // 터치 지점 기반 파급 효과
        let originalRefraction = glassSettings.refractionStrength
        glassSettings.refractionStrength = min(1.0, originalRefraction * 1.5)
        
        // 0.5초 후 원래 상태로 복구
        Task { @MainActor in
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5초
            UIView.animate(withDuration: 0.3) {
                self.glassSettings.refractionStrength = originalRefraction
            }
        }
    }
    
    // MARK: - UIView Overrides
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        metalView.frame = bounds
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        if let touch = touches.first {
            let location = touch.location(in: self)
            addTouchRippleEffect(at: location)
        }
    }
}

// MARK: - MTKViewDelegate

extension MetalGlassView: MTKViewDelegate {
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // 화면 크기 변경 시 호출
    }
    
    public func draw(in view: MTKView) {
        // 렌더링 수행
        renderer?.render(in: view, backgroundImage: currentBackgroundImage)
    }
}

// MARK: - Glass Presets

public extension MetalGlassView {
    
    /// 다양한 Glass 스타일 프리셋
    enum GlassPreset {
        case subtle
        case medium
        case strong
        case ethereal
        case vibrant
        case crystal
        
        var settings: LiquidGlassSettings {
            var settings = LiquidGlassSettings()
            
            switch self {
            case .subtle:
                settings.thickness = 0.2
                settings.refractionStrength = 0.1
                settings.reflectionStrength = 0.1
                settings.opacity = 0.6
                settings.tintColor = LiquidGlassSettings.TintColor(r: 0.95, g: 0.98, b: 1.0)
                
            case .medium:
                settings.thickness = 0.5
                settings.refractionStrength = 0.3
                settings.reflectionStrength = 0.2
                settings.opacity = 0.8
                settings.tintColor = LiquidGlassSettings.TintColor(r: 0.9, g: 0.95, b: 1.0)
                
            case .strong:
                settings.thickness = 0.8
                settings.refractionStrength = 0.5
                settings.reflectionStrength = 0.4
                settings.opacity = 0.9
                settings.tintColor = LiquidGlassSettings.TintColor(r: 0.85, g: 0.9, b: 0.95)
                
            case .ethereal:
                settings.thickness = 0.3
                settings.refractionStrength = 0.4
                settings.reflectionStrength = 0.6
                settings.opacity = 0.7
                settings.tintColor = LiquidGlassSettings.TintColor(r: 0.9, g: 0.95, b: 1.0)
                settings.edgeFade = 0.3
                
            case .vibrant:
                settings.thickness = 0.6
                settings.refractionStrength = 0.4
                settings.reflectionStrength = 0.3
                settings.opacity = 0.85
                settings.tintColor = LiquidGlassSettings.TintColor(r: 0.8, g: 0.9, b: 1.0)
                settings.chromaticAberration = 0.2
                
            case .crystal:
                settings.thickness = 0.4
                settings.refractionStrength = 0.6
                settings.reflectionStrength = 0.5
                settings.opacity = 0.9
                settings.tintColor = LiquidGlassSettings.TintColor(r: 0.95, g: 0.98, b: 1.0)
                settings.distortionStrength = 0.2
            }
            
            return settings
        }
    }
    
    /// 프리셋으로 Glass 효과 설정
    func applyGlassPreset(_ preset: GlassPreset, animated: Bool = true) {
        let newSettings = preset.settings
        
        if animated {
            UIView.animate(withDuration: 0.5) {
                self.glassSettings = newSettings
            }
        } else {
            glassSettings = newSettings
        }
    }
    
    /// 색온도 기반 틴트 색상 설정
    func setColorTemperature(_ temperature: ColorTemperature) {
        switch temperature {
        case .cool:
            glassSettings.tintColor = LiquidGlassSettings.TintColor(r: 0.85, g: 0.9, b: 1.0)
        case .neutral:
            glassSettings.tintColor = LiquidGlassSettings.TintColor(r: 0.9, g: 0.95, b: 1.0)
        case .warm:
            glassSettings.tintColor = LiquidGlassSettings.TintColor(r: 1.0, g: 0.95, b: 0.85)
        }
    }
    
    enum ColorTemperature {
        case cool, neutral, warm
    }
}
