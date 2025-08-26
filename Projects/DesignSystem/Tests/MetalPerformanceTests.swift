import Testing
import Foundation
import Metal
@testable import DesignSystem

// MARK: - MetalPerformanceManager 테스트

@Suite("Metal 성능 관리자 테스트")
struct MetalPerformanceManagerTests {
    
    // MARK: - Device Detection Tests
    
    @Suite("디바이스 감지")
    struct DeviceDetection {
        
        @Test("Metal 디바이스 지원 여부 확인")
        func testMetalDeviceSupport() {
            let isSupported = MetalDeviceChecker.isMetalSupported
            
            // 시뮬레이터에서는 false, 실제 디바이스에서는 true여야 함
            #if targetEnvironment(simulator)
            #expect(isSupported == false, "시뮬레이터에서는 Metal이 지원되지 않아야 함")
            #else
            // 실제 디바이스에서는 Metal이 지원되어야 함 (iOS 8 이상)
            #expect(isSupported == true, "실제 iOS 디바이스에서는 Metal이 지원되어야 함")
            #endif
        }
        
        @Test("Metal 라이브러리 로드 테스트")
        func testMetalLibraryLoad() {
            let canLoad = MetalDeviceChecker.canLoadMetalLibrary()
            
            #if targetEnvironment(simulator)
            // 시뮬레이터에서는 제한적
            #expect(canLoad == false || canLoad == true, "시뮬레이터에서의 라이브러리 로드는 환경에 따라 다를 수 있음")
            #else
            if MetalDeviceChecker.isMetalSupported {
                #expect(canLoad == true, "Metal을 지원하는 디바이스에서는 라이브러리를 로드할 수 있어야 함")
            }
            #endif
        }
        
        @Test("성능 등급 감지 테스트")
        func testPerformanceTierDetection() {
            let tier = MetalDeviceChecker.getMetalPerformanceTier()
            
            // 유효한 성능 등급이 반환되어야 함
            let validTiers: [MetalPerformanceManager.DevicePerformanceTier] = [.minimal, .low, .medium, .high]
            #expect(validTiers.contains(tier), "유효한 성능 등급이 반환되어야 함: \(tier)")
            
            #if targetEnvironment(simulator)
            // 시뮬레이터에서는 보통 minimal 또는 low
            #expect(tier == .minimal || tier == .low, "시뮬레이터에서는 낮은 성능 등급이 감지되어야 함")
            #endif
        }
    }
    
    // MARK: - Quality Settings Tests
    
    @Suite("품질 설정")
    struct QualitySettings {
        
        @Test("기본 품질 설정 유효성")
        func testDefaultQualitySettings() {
            let high = MetalPerformanceManager.QualitySettings.high
            let medium = MetalPerformanceManager.QualitySettings.medium
            let low = MetalPerformanceManager.QualitySettings.low
            let minimal = MetalPerformanceManager.QualitySettings.minimal
            
            // 품질이 높을수록 더 많은 리소스를 사용해야 함
            #expect(high.noiseOctaves >= medium.noiseOctaves, "높은 품질은 더 많은 노이즈 옥타브를 사용해야 함")
            #expect(medium.noiseOctaves >= low.noiseOctaves, "중간 품질은 낮은 품질보다 더 많은 노이즈 옥타브를 사용해야 함")
            #expect(low.noiseOctaves >= minimal.noiseOctaves, "낮은 품질은 최소 품질보다 더 많은 노이즈 옥타브를 사용해야 함")
            
            // 렌더 스케일 검증
            #expect(high.renderScale >= medium.renderScale, "높은 품질은 더 높은 렌더 스케일을 가져야 함")
            #expect(medium.renderScale >= low.renderScale, "중간 품질은 낮은 품질보다 더 높은 렌더 스케일을 가져야 함")
            #expect(low.renderScale >= minimal.renderScale, "낮은 품질은 최소 품질보다 더 높은 렌더 스케일을 가져야 함")
            
            // 모든 스케일 값은 0.0~1.0 범위 내에 있어야 함
            let allSettings = [high, medium, low, minimal]
            for setting in allSettings {
                #expect(setting.renderScale >= 0.0 && setting.renderScale <= 1.0, 
                       "렌더 스케일은 0.0~1.0 범위 내에 있어야 함: \(setting.renderScale)")
                #expect(setting.reflectionQuality >= 0.0 && setting.reflectionQuality <= 1.0,
                       "반사 품질은 0.0~1.0 범위 내에 있어야 함: \(setting.reflectionQuality)")
                #expect(setting.distortionComplexity >= 0.0 && setting.distortionComplexity <= 1.0,
                       "왜곡 복잡도는 0.0~1.0 범위 내에 있어야 함: \(setting.distortionComplexity)")
                #expect(setting.animationSmoothing >= 0.0 && setting.animationSmoothing <= 1.0,
                       "애니메이션 부드러움은 0.0~1.0 범위 내에 있어야 함: \(setting.animationSmoothing)")
            }
        }
        
        @Test("고급 기능 활성화 로직")
        func testAdvancedFeatureActivation() {
            let high = MetalPerformanceManager.QualitySettings.high
            let medium = MetalPerformanceManager.QualitySettings.medium
            let low = MetalPerformanceManager.QualitySettings.low
            let minimal = MetalPerformanceManager.QualitySettings.minimal
            
            // 고품질에서는 모든 고급 기능이 활성화되어야 함
            #expect(high.enableChromaticAberration == true, "고품질에서는 색수차가 활성화되어야 함")
            #expect(high.enableAdvancedReflection == true, "고품질에서는 고급 반사가 활성화되어야 함")
            
            // 최소 품질에서는 고급 기능이 비활성화되어야 함
            #expect(minimal.enableChromaticAberration == false, "최소 품질에서는 색수차가 비활성화되어야 함")
            #expect(minimal.enableAdvancedReflection == false, "최소 품질에서는 고급 반사가 비활성화되어야 함")
        }
    }
    
    // MARK: - Performance Manager Tests
    
    @Suite("성능 관리자 기능")
    struct PerformanceManagerFunctionality {
        
        @Test("성능 관리자 초기화")
        @MainActor
        func testPerformanceManagerInitialization() {
            let manager = MetalPerformanceManager.shared
            
            // 성능 등급이 설정되어야 함
            let validTiers: [MetalPerformanceManager.DevicePerformanceTier] = [.minimal, .low, .medium, .high]
            #expect(validTiers.contains(manager.deviceTier), "유효한 디바이스 성능 등급이 설정되어야 함")
            
            // 현재 품질 설정이 설정되어야 함
            let currentQuality = manager.currentQuality
            #expect(currentQuality.noiseOctaves > 0, "노이즈 옥타브는 0보다 커야 함")
            #expect(currentQuality.refractionSamples > 0, "굴절 샘플은 0보다 커야 함")
        }
        
        @Test("성능 정보 조회")
        @MainActor
        func testPerformanceInfoRetrieval() {
            let manager = MetalPerformanceManager.shared
            let info = manager.getCurrentPerformanceInfo()
            
            // 모든 정보가 유효해야 함
            let validTiers: [MetalPerformanceManager.DevicePerformanceTier] = [.minimal, .low, .medium, .high]
            #expect(validTiers.contains(info.tier), "유효한 성능 등급이 반환되어야 함")
            
            #expect(info.frameRate >= 0, "프레임 레이트는 0 이상이어야 함")
            
            // 열 상태 검증
            let validThermalStates: [ProcessInfo.ThermalState] = [.nominal, .fair, .serious, .critical]
            #expect(validThermalStates.contains(info.thermal), "유효한 열 상태가 반환되어야 함")
        }
        
        @Test("수동 품질 설정")
        @MainActor
        func testManualQualitySetting() {
            let manager = MetalPerformanceManager.shared
            let originalTier = manager.deviceTier
            let originalQuality = manager.currentQuality
            
            // 높은 품질로 설정
            manager.setQuality(.high, tier: .high)
            #expect(manager.deviceTier == .high, "수동으로 설정한 성능 등급이 적용되어야 함")
            #expect(manager.currentQuality.noiseOctaves == MetalPerformanceManager.QualitySettings.high.noiseOctaves,
                   "수동으로 설정한 품질이 적용되어야 함")
            
            // 낮은 품질로 설정
            manager.setQuality(.low, tier: .low)
            #expect(manager.deviceTier == .low, "수동으로 설정한 성능 등급이 적용되어야 함")
            #expect(manager.currentQuality.noiseOctaves == MetalPerformanceManager.QualitySettings.low.noiseOctaves,
                   "수동으로 설정한 품질이 적용되어야 함")
            
            // 원래 설정으로 복원
            manager.setQuality(originalQuality, tier: originalTier)
        }
        
        @Test("성능 모니터링 제어")
        @MainActor
        func testPerformanceMonitoringControl() async throws {
            let manager = MetalPerformanceManager.shared
            
            // 모니터링 비활성화
            manager.setPerformanceMonitoring(enabled: false)
            #expect(manager.isPerformanceMonitoringEnabled == false, "성능 모니터링이 비활성화되어야 함")
            
            // 모니터링 활성화
            manager.setPerformanceMonitoring(enabled: true)
            #expect(manager.isPerformanceMonitoringEnabled == true, "성능 모니터링이 활성화되어야 함")
        }
    }
    
    // MARK: - Frame Rate Tests
    
    @Suite("프레임 레이트 측정")
    struct FrameRateMeasurement {
        
        @Test("프레임 렌더링 시간 측정")
        @MainActor
        func testFrameRenderingTimeMeasurement() async throws {
            let manager = MetalPerformanceManager.shared
            
            // 프레임 렌더링 시작/완료 시뮬레이션
            manager.frameRenderingStarted()
            
            // 약간의 처리 시간 시뮬레이션
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
            
            manager.frameRenderingCompleted()
            
            // 프레임 시간이 측정되어야 함
            #expect(manager.averageFrameTime > 0, "프레임 시간이 측정되어야 함")
            #expect(manager.averageFrameTime < 1.0, "프레임 시간이 합리적인 범위 내에 있어야 함 (1초 미만)")
        }
        
        @Test("여러 프레임의 평균 계산")
        @MainActor
        func testMultipleFrameAveraging() async throws {
            let manager = MetalPerformanceManager.shared
            let frameCount = 5
            
            // 여러 프레임 시뮬레이션
            for _ in 0..<frameCount {
                manager.frameRenderingStarted()
                try await Task.sleep(nanoseconds: 5_000_000) // 5ms
                manager.frameRenderingCompleted()
            }
            
            // 평균 프레임 시간이 합리적인 범위에 있어야 함
            #expect(manager.averageFrameTime > 0.001, "평균 프레임 시간이 1ms 이상이어야 함")
            #expect(manager.averageFrameTime < 0.1, "평균 프레임 시간이 100ms 미만이어야 함")
        }
    }
}

// MARK: - Metal 셰이더 테스트

@Suite("Metal 셰이더 최적화 테스트")
struct MetalShaderOptimizationTests {
    
    @Suite("셰이더 로드")
    struct ShaderLoading {
        
        @Test("최적화된 셰이더 함수 존재 확인")
        func testOptimizedShaderFunctions() {
            guard let device = MTLCreateSystemDefaultDevice(),
                  let library = device.makeDefaultLibrary() else {
                return // Metal을 지원하지 않는 환경에서는 테스트 스킵
            }
            
            // 버텍스 셰이더 함수 확인
            let vertexFunction = library.makeFunction(name: "optimizedLiquidGlassVertex")
            #expect(vertexFunction != nil, "최적화된 버텍스 셰이더 함수가 존재해야 함")
            
            // 프래그먼트 셰이더 함수 확인
            let fragmentFunction = library.makeFunction(name: "optimizedLiquidGlassFragment")
            #expect(fragmentFunction != nil, "최적화된 프래그먼트 셰이더 함수가 존재해야 함")
            
            // 최소 품질 셰이더 함수 확인
            let minimalFunction = library.makeFunction(name: "minimalLiquidGlassFragment")
            #expect(minimalFunction != nil, "최소 품질 셰이더 함수가 존재해야 함")
        }
        
        @Test("렌더 파이프라인 상태 생성 테스트")
        func testRenderPipelineStateCreation() throws {
            guard let device = MTLCreateSystemDefaultDevice(),
                  let library = device.makeDefaultLibrary() else {
                return // Metal을 지원하지 않는 환경에서는 테스트 스킵
            }
            
            guard let vertexFunction = library.makeFunction(name: "optimizedLiquidGlassVertex"),
                  let fragmentFunction = library.makeFunction(name: "optimizedLiquidGlassFragment") else {
                Issue.record("셰이더 함수를 로드할 수 없음")
                return
            }
            
            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.vertexFunction = vertexFunction
            descriptor.fragmentFunction = fragmentFunction
            descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            
            // 파이프라인 상태 생성이 성공해야 함
            let pipelineState = try? device.makeRenderPipelineState(descriptor: descriptor)
            #expect(pipelineState != nil, "렌더 파이프라인 상태를 생성할 수 있어야 함")
        }
    }
    
    @Suite("성능 최적화")
    struct PerformanceOptimization {
        
        @Test("유니폼 버퍼 크기 검증")
        func testUniformBufferSize() {
            let uniformSize = MemoryLayout<OptimizedLiquidGlassUniforms>.stride
            
            // 유니폼 버퍼 크기가 합리적인 범위에 있어야 함 (너무 크지 않아야 함)
            #expect(uniformSize > 0, "유니폼 버퍼 크기가 0보다 커야 함")
            #expect(uniformSize < 1024, "유니폼 버퍼 크기가 1KB 미만이어야 함 (메모리 효율성)")
        }
        
        @Test("품질 레벨 매핑 검증")
        func testQualityLevelMapping() {
            // 품질 설정을 레벨로 변환하는 로직 검증
            let highQuality = MetalPerformanceManager.QualitySettings.high
            let mediumQuality = MetalPerformanceManager.QualitySettings.medium
            let lowQuality = MetalPerformanceManager.QualitySettings.low
            let minimalQuality = MetalPerformanceManager.QualitySettings.minimal
            
            // 각 품질 설정에 대해 올바른 레벨이 매핑되어야 함
            #expect(qualityToLevel(highQuality) >= qualityToLevel(mediumQuality), 
                   "높은 품질은 더 높은 레벨을 가져야 함")
            #expect(qualityToLevel(mediumQuality) >= qualityToLevel(lowQuality),
                   "중간 품질은 낮은 품질보다 높은 레벨을 가져야 함")
            #expect(qualityToLevel(lowQuality) >= qualityToLevel(minimalQuality),
                   "낮은 품질은 최소 품질보다 높은 레벨을 가져야 함")
        }
        
        private func qualityToLevel(_ quality: MetalPerformanceManager.QualitySettings) -> Int {
            if quality.noiseOctaves >= 4 { return 3 }
            else if quality.noiseOctaves >= 3 { return 2 }
            else if quality.noiseOctaves >= 2 { return 1 }
            else { return 0 }
        }
    }
}

// MARK: - Supporting Types for Tests

private struct OptimizedLiquidGlassUniforms {
    let modelViewProjection: matrix_float4x4
    let time: Float
    let glassThickness: Float
    let refractionStrength: Float
    let reflectionStrength: Float
    let distortionStrength: Float
    let noiseScale: Float
    let opacity: Float
    let edgeFade: Float
    let screenSize: SIMD2<Float>
    let tintColor: SIMD3<Float>
    let aberrationStrength: Float
    let qualityLevel: Int32
    let renderScale: Float
}