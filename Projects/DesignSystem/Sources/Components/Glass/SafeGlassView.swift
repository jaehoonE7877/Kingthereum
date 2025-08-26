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
        withAnimation {
            isAnimating = true
            animationOffset = CGSize(width: 200, height: 200)
        }
    }
}

/// Metal Glass 실패 시 안전한 fallback을 제공하는 View Extension
public extension View {
    /// Safe Metal Liquid Glass 효과 적용
    /// Metal이 실패하면 자동으로 SwiftUI 네이티브 효과로 대체
    func safeMetalLiquidGlass(settings: Binding<LiquidGlassSettings>) -> AnyView {
        // Metal 지원 여부 확인
        if MetalDeviceChecker.isMetalSupported {
            // Metal 지원: 원래 Metal Glass 사용
            return AnyView(self.metalLiquidGlass(settings: settings))
        } else {
            // Metal 미지원: Fallback Glass 사용
            return AnyView(
                SafeGlassView(glassSettings: settings.wrappedValue) {
                    self
                }
            )
        }
    }
}

/// Metal 디바이스 지원 여부를 확인하는 유틸리티
public enum MetalDeviceChecker {
    
    /// 현재 디바이스에서 Metal을 지원하는지 확인
    public static var isMetalSupported: Bool {
        #if targetEnvironment(simulator)
        // 시뮬레이터에서는 Metal이 제한적이므로 fallback 사용
        return false
        #else
        // 실제 디바이스에서 Metal 지원 여부 확인
        guard let _ = MTLCreateSystemDefaultDevice() else {
            print("⚠️ [MetalDeviceChecker] Metal is not available on this device")
            return false
        }
        return true
        #endif
    }
    
    /// Metal 라이브러리가 정상적으로 로드될 수 있는지 확인
    public static func canLoadMetalLibrary() -> Bool {
        guard let device = MTLCreateSystemDefaultDevice() else {
            return false
        }
        
        // 기본 라이브러리 로드 시도
        guard let _ = device.makeDefaultLibrary() else {
            print("⚠️ [MetalDeviceChecker] Cannot load default Metal library")
            return false
        }
        
        return true
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
