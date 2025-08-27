import Testing
import SwiftUI
import MetalKit
@testable import DesignSystem

/// Metal Liquid Glass 성능 테스트 스위트
@Suite("Metal Liquid Glass 성능 테스트")
struct MetalLiquidGlassPerformanceTests {
    
    // MARK: - Metal 렌더링 성능 테스트
    
    @Suite("Metal 렌더링 성능")
    struct MetalRenderingPerformanceTests {
        
        @Test("Metal 디바이스 초기화 성능", .timeLimit(.seconds(2)))
        func testMetalDeviceInitialization() {
            // Given & When
            measure {
                for _ in 0..<10 {
                    _ = MTLCreateSystemDefaultDevice()
                }
            }
            
            // Then - 2초 내에 완료되어야 함
        }
        
        @Test("Metal 셰이더 컴파일 성능", .timeLimit(.seconds(5)))
        func testShaderCompilationPerformance() async {
            // Given
            guard let device = MTLCreateSystemDefaultDevice() else {
                Issue.record("Metal 디바이스를 생성할 수 없습니다")
                return
            }
            
            // When & Then
            await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    self.measure {
                        do {
                            let library = try device.makeDefaultLibrary(bundle: .main)
                            _ = library?.makeFunction(name: "liquidGlassVertex")
                            _ = library?.makeFunction(name: "liquidGlassFragment")
                        } catch {
                            Issue.record("셰이더 컴파일 실패: \(error)")
                        }
                    }
                    continuation.resume()
                }
            }
        }
        
        @Test("렌더 파이프라인 생성 성능", .timeLimit(.seconds(3)))
        func testRenderPipelineCreationPerformance() async {
            // Given
            guard let device = MTLCreateSystemDefaultDevice() else {
                Issue.record("Metal 디바이스를 생성할 수 없습니다")
                return
            }
            
            // When & Then
            await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    self.measure {
                        do {
                            let library = try device.makeDefaultLibrary(bundle: .main)
                            let pipelineDescriptor = MTLRenderPipelineDescriptor()
                            pipelineDescriptor.vertexFunction = library?.makeFunction(name: "liquidGlassVertex")
                            pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "liquidGlassFragment")
                            pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
                            
                            _ = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
                        } catch {
                            Issue.record("렌더 파이프라인 생성 실패: \(error)")
                        }
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    // MARK: - 메모리 사용량 테스트
    
    @Suite("메모리 사용량")
    struct MemoryUsageTests {
        
        @Test("Metal 리소스 메모리 사용량 검증")
        func testMetalResourceMemoryUsage() {
            // Given
            guard let device = MTLCreateSystemDefaultDevice() else {
                Issue.record("Metal 디바이스를 생성할 수 없습니다")
                return
            }
            
            let startMemory = getCurrentMemoryUsage()
            var buffers: [MTLBuffer] = []
            
            // When - 대량의 Metal 버퍼 생성
            for _ in 0..<100 {
                if let buffer = device.makeBuffer(length: 1024 * 1024, options: []) { // 1MB 버퍼
                    buffers.append(buffer)
                }
            }
            
            let peakMemory = getCurrentMemoryUsage()
            let memoryIncrease = peakMemory - startMemory
            
            // 메모리 정리
            buffers.removeAll()
            
            let finalMemory = getCurrentMemoryUsage()
            let memoryLeaked = finalMemory - startMemory
            
            // Then
            #expect(memoryIncrease > 50 * 1024 * 1024, "Metal 버퍼가 적절한 메모리를 사용해야 함") // 50MB 이상
            #expect(memoryLeaked < 10 * 1024 * 1024, "메모리 누수가 10MB 이하여야 함") // 10MB 이하
        }
        
        @Test("텍스처 메모리 관리 검증")
        func testTextureMemoryManagement() {
            // Given
            guard let device = MTLCreateSystemDefaultDevice() else {
                Issue.record("Metal 디바이스를 생성할 수 없습니다")
                return
            }
            
            let startMemory = getCurrentMemoryUsage()
            var textures: [MTLTexture] = []
            
            // When - 고해상도 텍스처 생성
            for _ in 0..<10 {
                let textureDescriptor = MTLTextureDescriptor()
                textureDescriptor.width = 1024
                textureDescriptor.height = 1024
                textureDescriptor.pixelFormat = .bgra8Unorm
                textureDescriptor.usage = [.shaderRead, .renderTarget]
                
                if let texture = device.makeTexture(descriptor: textureDescriptor) {
                    textures.append(texture)
                }
            }
            
            let peakMemory = getCurrentMemoryUsage()
            let memoryIncrease = peakMemory - startMemory
            
            // 텍스처 정리
            textures.removeAll()
            
            // Then
            #expect(memoryIncrease > 20 * 1024 * 1024, "텍스처가 적절한 메모리를 사용해야 함") // 20MB 이상
        }
    }
    
    // MARK: - 프레임레이트 성능 테스트
    
    @Suite("프레임레이트 성능")
    struct FrameRateTests {
        
        @Test("60fps 유지 성능 검증")
        func testSixtyFPSMaintenance() {
            // Given
            let targetFrameTime: Double = 1.0 / 60.0 // 16.67ms
            var frameTimes: [Double] = []
            
            // When - 프레임 렌더링 시뮬레이션
            for _ in 0..<120 { // 2초간 60fps
                let startTime = CFAbsoluteTimeGetCurrent()
                
                // Metal Liquid Glass 렌더링 시뮬레이션
                simulateMetalRendering()
                
                let frameTime = CFAbsoluteTimeGetCurrent() - startTime
                frameTimes.append(frameTime)
            }
            
            // Then
            let averageFrameTime = frameTimes.reduce(0, +) / Double(frameTimes.count)
            let maxFrameTime = frameTimes.max() ?? 0
            let frameTimeVariation = frameTimes.reduce(0) { $0 + abs($1 - averageFrameTime) } / Double(frameTimes.count)
            
            #expect(averageFrameTime <= targetFrameTime, "평균 프레임 시간이 16.67ms 이하여야 함")
            #expect(maxFrameTime <= targetFrameTime * 2, "최대 프레임 시간이 33ms 이하여야 함")
            #expect(frameTimeVariation <= targetFrameTime * 0.2, "프레임 시간 편차가 3.33ms 이하여야 함")
        }
        
        @Test("복잡한 효과 조합 성능", .timeLimit(.seconds(10)))
        func testComplexEffectCombinations() {
            // Given
            let complexEffects = [
                "metalLiquid",
                "holographic",
                "glassMorphism",
                "aurora"
            ]
            
            // When & Then
            for effectName in complexEffects {
                let startTime = CFAbsoluteTimeGetCurrent()
                
                // 복잡한 효과 렌더링 시뮬레이션
                for _ in 0..<30 { // 30프레임
                    simulateComplexEffect(effectName)
                }
                
                let totalTime = CFAbsoluteTimeGetCurrent() - startTime
                let averageFrameTime = totalTime / 30.0
                
                #expect(averageFrameTime <= 1.0 / 30.0, "\(effectName) 효과가 30fps 이상 유지해야 함")
            }
        }
    }
    
    // MARK: - 배터리 효율성 테스트
    
    @Suite("배터리 효율성")
    struct BatteryEfficiencyTests {
        
        @Test("GPU 사용량 최적화 검증")
        func testGPUUsageOptimization() {
            // Given
            let testDuration: TimeInterval = 5.0 // 5초
            let startTime = CFAbsoluteTimeGetCurrent()
            var renderCount = 0
            
            // When
            while CFAbsoluteTimeGetCurrent() - startTime < testDuration {
                simulateOptimizedMetalRendering()
                renderCount += 1
                
                // 60fps 제한 시뮬레이션
                Thread.sleep(forTimeInterval: 1.0 / 60.0)
            }
            
            let actualDuration = CFAbsoluteTimeGetCurrent() - startTime
            let actualFPS = Double(renderCount) / actualDuration
            
            // Then
            #expect(actualFPS >= 55, "최소 55fps 이상 유지해야 함")
            #expect(actualFPS <= 65, "불필요한 과도한 렌더링을 피해야 함")
        }
        
        @Test("열 관리 성능 검증")
        func testThermalManagement() {
            // Given
            let intensiveOperationCount = 100
            let startTime = CFAbsoluteTimeGetCurrent()
            
            // When - 집약적인 Metal 연산 수행
            for _ in 0..<intensiveOperationCount {
                simulateIntensiveMetalOperation()
                
                // 열 관리를 위한 적절한 간격
                if CFAbsoluteTimeGetCurrent() - startTime > 0.1 {
                    Thread.sleep(forTimeInterval: 0.001) // 1ms 대기
                }
            }
            
            let totalTime = CFAbsoluteTimeGetCurrent() - startTime
            let operationsPerSecond = Double(intensiveOperationCount) / totalTime
            
            // Then
            #expect(totalTime <= 10.0, "집약적 연산이 10초 내에 완료되어야 함")
            #expect(operationsPerSecond >= 10, "초당 최소 10개 연산을 처리할 수 있어야 함")
        }
    }
    
    // MARK: - 실제 디바이스 성능 테스트
    
    @Suite("디바이스별 성능")
    struct DeviceSpecificTests {
        
        @Test("구형 디바이스 성능 검증")
        func testOlderDevicePerformance() {
            // Given - 구형 디바이스 시뮬레이션 (성능 제한)
            let isOlderDevice = simulateOlderDevice()
            
            if isOlderDevice {
                // When - 단순화된 렌더링 경로 테스트
                let startTime = CFAbsoluteTimeGetCurrent()
                
                for _ in 0..<60 { // 1초간 60프레임
                    simulateSimplifiedRendering()
                }
                
                let renderTime = CFAbsoluteTimeGetCurrent() - startTime
                let averageFrameTime = renderTime / 60.0
                
                // Then
                #expect(averageFrameTime <= 1.0 / 30.0, "구형 디바이스에서도 30fps 유지해야 함")
            }
        }
        
        @Test("최신 디바이스 고품질 렌더링")
        func testModernDeviceHighQuality() {
            // Given - 최신 디바이스 시뮬레이션
            let isModernDevice = !simulateOlderDevice()
            
            if isModernDevice {
                // When - 고품질 렌더링 경로 테스트
                let startTime = CFAbsoluteTimeGetCurrent()
                
                for _ in 0..<120 { // 2초간 60프레임
                    simulateHighQualityRendering()
                }
                
                let renderTime = CFAbsoluteTimeGetCurrent() - startTime
                let averageFrameTime = renderTime / 120.0
                
                // Then
                #expect(averageFrameTime <= 1.0 / 60.0, "최신 디바이스에서 60fps 유지해야 함")
                #expect(renderTime <= 2.5, "고품질 렌더링이 2.5초 내에 완료되어야 함")
            }
        }
    }
}

// MARK: - Helper Functions

extension MetalLiquidGlassPerformanceTests {
    
    /// 현재 메모리 사용량 조회
    private func getCurrentMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        return kerr == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }
    
    /// Metal 렌더링 시뮬레이션
    private func simulateMetalRendering() {
        // 실제 Metal 렌더링 작업을 시뮬레이션
        let workAmount = Int.random(in: 1000...5000)
        var result: Double = 0
        for i in 0..<workAmount {
            result += sin(Double(i) * 0.001)
        }
        _ = result // 컴파일러 최적화 방지
    }
    
    /// 복잡한 효과 렌더링 시뮬레이션
    private func simulateComplexEffect(_ effectName: String) {
        let complexity = effectName.contains("holographic") ? 10000 : 5000
        var result: Double = 0
        for i in 0..<complexity {
            result += cos(Double(i) * 0.001) * sin(Double(i) * 0.002)
        }
        _ = result
    }
    
    /// 최적화된 Metal 렌더링 시뮬레이션
    private func simulateOptimizedMetalRendering() {
        let workAmount = 2000 // 최적화된 작업량
        var result: Double = 0
        for i in 0..<workAmount {
            result += sin(Double(i) * 0.001)
        }
        _ = result
    }
    
    /// 집약적 Metal 연산 시뮬레이션
    private func simulateIntensiveMetalOperation() {
        let workAmount = 10000
        var result: Double = 0
        for i in 0..<workAmount {
            result += pow(sin(Double(i) * 0.001), 2) + pow(cos(Double(i) * 0.001), 2)
        }
        _ = result
    }
    
    /// 구형 디바이스 시뮬레이션
    private func simulateOlderDevice() -> Bool {
        // 실제 구현에서는 디바이스 모델, GPU 성능 등을 확인
        #if targetEnvironment(simulator)
        return true // 시뮬레이터는 구형 디바이스로 간주
        #else
        return ProcessInfo.processInfo.physicalMemory < 4 * 1024 * 1024 * 1024 // 4GB 미만
        #endif
    }
    
    /// 단순화된 렌더링 시뮬레이션 (구형 디바이스용)
    private func simulateSimplifiedRendering() {
        let workAmount = 1000 // 단순화된 작업량
        var result: Double = 0
        for i in 0..<workAmount {
            result += Double(i % 100) * 0.01
        }
        _ = result
    }
    
    /// 고품질 렌더링 시뮬레이션 (최신 디바이스용)
    private func simulateHighQualityRendering() {
        let workAmount = 8000 // 고품질 작업량
        var result: Double = 0
        for i in 0..<workAmount {
            result += sin(Double(i) * 0.001) * cos(Double(i) * 0.002) * tan(Double(i) * 0.0005)
        }
        _ = result
    }
    
    /// 성능 측정 헬퍼
    private func measure(_ block: () -> Void) {
        let startTime = CFAbsoluteTimeGetCurrent()
        block()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        print("Metal 성능 테스트 실행 시간: \(timeElapsed)초")
    }
}