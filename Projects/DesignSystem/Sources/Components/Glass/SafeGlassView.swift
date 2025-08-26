import SwiftUI
import Metal
import Core

/// Metal이 사용할 수 없는 환경에서 사용하는 Fallback Glass 효과
/// Metal Liquid Glass가 실패할 경우 SwiftUI 네이티브 효과로 대체
public struct SafeGlassView<Content: View>: View {
    
    // MARK: - Properties
    
    let content: Content
    let glassSettings: LiquidGlassSettings
    
    @State private var animationOffset: CGSize = .zero
    @State private var isAnimating: Bool = false
    
    // MARK: - Initialization
    
    public init(
        glassSettings: LiquidGlassSettings = LiquidGlassSettings(),
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.glassSettings = glassSettings
    }
    
    // MARK: - Body
    
    public var body: some View {
        content
            .background(fallbackGlassEffect)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .onAppear {
                startContinuousAnimation()
            }
    }
    
    // MARK: - Fallback Glass Effect
    
    @ViewBuilder
    private var fallbackGlassEffect: some View {
        ZStack {
            // 기본 블러 효과
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(Double(glassSettings.opacity))
            
            // 글로시 오버레이
            LinearGradient(
                colors: [
                    Color.white.opacity(0.3),
                    Color.white.opacity(0.1),
                    Color.white.opacity(0.05),
                    Color.white.opacity(0.1),
                    Color.white.opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(Double(glassSettings.reflectionStrength))
            
            // 애니메이팅 글레어 효과
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.15),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .rotationEffect(.degrees(45))
                .offset(animationOffset)
                .opacity(isAnimating ? 0.7 : 0.0)
                .animation(
                    .easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true),
                    value: isAnimating
                )
            
            // 틴트 색상 오버레이
            Rectangle()
                .fill(
                    Color(
                        red: Double(glassSettings.tintColor.r),
                        green: Double(glassSettings.tintColor.g),
                        blue: Double(glassSettings.tintColor.b)
                    )
                    .opacity(0.1)
                )
            
            // 가장자리 하이라이트
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            Color.clear,
                            Color.clear,
                            Color.white.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }
    
    // MARK: - Animation
    
    private func startContinuousAnimation() {
        // 성능 관리자의 품질 설정에 따라 애니메이션 강도 조정
        let performanceManager = MetalPerformanceManager.shared
        let animationIntensity = performanceManager.currentQuality.animationSmoothing
        
        withAnimation(
            .easeInOut(duration: 2.0 / Double(animationIntensity))
            .repeatForever(autoreverses: true)
        ) {
            isAnimating = true
            let offsetDistance = 200.0 * Double(animationIntensity)
            animationOffset = CGSize(width: offsetDistance, height: offsetDistance)
        }
    }
}

/// Metal Glass 실패 시 안전한 fallback을 제공하는 View Extension
public extension View {
    /// Safe Metal Liquid Glass 효과 적용
    /// Metal이 실패하면 자동으로 SwiftUI 네이티브 효과로 대체
    /// 성능 관리자를 통해 디바이스 성능에 맞는 품질 자동 조정
    func safeMetalLiquidGlass(settings: Binding<LiquidGlassSettings>) -> AnyView {
        let performanceManager = MetalPerformanceManager.shared
        
        // Metal 지원 여부 및 성능 상태 확인
        if MetalDeviceChecker.isMetalSupported && performanceManager.deviceTier != .minimal {
            // Metal 지원 + 성능 양호: 최적화된 Metal Glass 사용
            return AnyView(self.optimizedMetalLiquidGlass(settings: settings))
        } else {
            // Metal 미지원 또는 성능 부족: Fallback Glass 사용
            return AnyView(
                SafeGlassView(glassSettings: settings.wrappedValue) {
                    self
                }
            )
        }
    }
    
    /// 최적화된 Metal Liquid Glass 효과 (내부 사용)
    private func optimizedMetalLiquidGlass(settings: Binding<LiquidGlassSettings>) -> some View {
        // TODO: OptimizedMetalGlassView 구현 시 연결
        // 현재는 기본 Metal Glass로 폴백
        return self.metalLiquidGlass(settings: settings)
    }
}

/// Metal 디바이스 지원 여부를 확인하는 유틸리티
/// 성능 관리자와 연동하여 더 정교한 지원 여부 판단
public enum MetalDeviceChecker {
    
    /// 현재 디바이스에서 Metal을 지원하는지 확인
    public static var isMetalSupported: Bool {
        #if targetEnvironment(simulator)
        // 시뮬레이터에서는 Metal이 제한적이므로 fallback 사용
        return false
        #else
        // 실제 디바이스에서 Metal 지원 여부 확인
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("⚠️ [MetalDeviceChecker] Metal is not available on this device")
            return false
        }
        
        // 기본적인 Metal 기능 확인
        guard canLoadMetalLibrary() else {
            print("⚠️ [MetalDeviceChecker] Metal library cannot be loaded")
            return false
        }
        
        // GPU 성능 확인 (최소 Apple GPU 필요)
        let supportsBasicGPU = device.supportsFamily(.apple3) || 
                              device.supportsFamily(.mac1) ||
                              device.supportsFamily(.common1)
        
        return supportsBasicGPU
        #endif
    }
    
    /// Metal 라이브러리가 정상적으로 로드될 수 있는지 확인
    public static func canLoadMetalLibrary() -> Bool {
        guard let device = MTLCreateSystemDefaultDevice() else {
            return false
        }
        
        // 기본 라이브러리 로드 시도
        guard let library = device.makeDefaultLibrary() else {
            print("⚠️ [MetalDeviceChecker] Cannot load default Metal library")
            return false
        }
        
        // 셰이더 함수 로드 테스트
        let hasOptimizedShaders = library.makeFunction(name: "optimizedLiquidGlassVertex") != nil &&
                                  library.makeFunction(name: "optimizedLiquidGlassFragment") != nil
        
        let hasMinimalShaders = library.makeFunction(name: "minimalLiquidGlassFragment") != nil
        
        return hasOptimizedShaders || hasMinimalShaders
    }
    
    /// 현재 디바이스의 Metal 성능 등급을 반환
    public static func getMetalPerformanceTier() -> MetalPerformanceManager.DevicePerformanceTier {
        guard let device = MTLCreateSystemDefaultDevice() else {
            return .minimal
        }
        
        if device.supportsFamily(.apple7) || device.supportsFamily(.apple8) || device.supportsFamily(.apple9) {
            return .high
        } else if device.supportsFamily(.apple5) || device.supportsFamily(.apple6) {
            return .medium
        } else if device.supportsFamily(.apple3) || device.supportsFamily(.apple4) {
            return .low
        } else {
            return .minimal
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        SafeGlassView {
            VStack {
                Text("Safe Fallback Glass")
                    .font(.headline)
                Text("Metal이 지원되지 않는 환경에서 사용")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .frame(height: 100)
        
        Text("Metal 지원: \(MetalDeviceChecker.isMetalSupported ? "YES" : "NO")")
            .font(.caption)
            .padding()
            .safeMetalLiquidGlass(settings: .constant(LiquidGlassSettings()))
    }
    .padding()
}
