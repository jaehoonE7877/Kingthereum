import SwiftUI
import Metal
import MetalKit
import os.log
import Core

/// 성능 최적화된 Metal Glass 렌더러
/// 디바이스 성능에 따라 자동으로 품질 조정하여 60fps 유지
@MainActor
public final class OptimizedMetalGlassRenderer: NSObject, ObservableObject {
    
    // MARK: - Properties
    
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let library: MTLLibrary
    private var renderPipelineState: MTLRenderPipelineState?
    private var minimalPipelineState: MTLRenderPipelineState?
    
    private let performanceManager = MetalPerformanceManager.shared
    private let logger = OSLog(subsystem: "com.kingthereum.design", category: "MetalGlassRenderer")
    
    // 렌더링 상태
    @Published public private(set) var isRenderingEnabled: Bool = true
    @Published public private(set) var currentFrameRate: Double = 60.0
    @Published public private(set) var renderTime: Double = 0.0
    
    // 최적화 옵션
    private var enableFrameRateLimit: Bool = true
    private var targetFrameRate: Double = 60.0
    private var lastRenderTime: CFTimeInterval = 0
    
    // 리소스 관리
    private var vertexBuffer: MTLBuffer?
    private var uniformBuffer: MTLBuffer?
    private let maxBuffersInFlight = 3
    private var bufferIndex = 0
    
    // MARK: - Initialization
    
    public init?(device: MTLDevice? = nil) {
        let metalDevice = device ?? MTLCreateSystemDefaultDevice()
        guard let metalDevice = metalDevice else {
            os_log("Metal 디바이스를 생성할 수 없습니다", type: .error)
            return nil
        }
        
        self.device = metalDevice
        
        guard let commandQueue = metalDevice.makeCommandQueue() else {
            os_log("Metal 명령 큐를 생성할 수 없습니다", type: .error)
            return nil
        }
        self.commandQueue = commandQueue
        
        guard let library = metalDevice.makeDefaultLibrary() else {
            os_log("Metal 라이브러리를 로드할 수 없습니다", type: .error)
            return nil
        }
        self.library = library
        
        super.init()
        
        setupRenderPipeline()
        setupBuffers()
        
        os_log("Metal Glass 렌더러 초기화 완료", log: logger, type: .info)
    }
    
    // MARK: - Setup
    
    private func setupRenderPipeline() {
        do {
            // 표준 품질 파이프라인 설정
            renderPipelineState = try createPipelineState(
                vertexFunction: "optimizedLiquidGlassVertex",
                fragmentFunction: "optimizedLiquidGlassFragment"
            )
            
            // 최소 품질 파이프라인 설정
            minimalPipelineState = try createPipelineState(
                vertexFunction: "optimizedLiquidGlassVertex", 
                fragmentFunction: "minimalLiquidGlassFragment"
            )
            
            os_log("Metal 렌더 파이프라인 설정 완료", log: logger, type: .info)
        } catch {
            os_log("렌더 파이프라인 설정 실패: %{public}@", log: logger, type: .error, error.localizedDescription)
            isRenderingEnabled = false
        }
    }
    
    private func createPipelineState(vertexFunction: String, fragmentFunction: String) throws -> MTLRenderPipelineState {
        let descriptor = MTLRenderPipelineDescriptor()
        
        // 셰이더 함수 로드
        guard let vertexFunc = library.makeFunction(name: vertexFunction),
              let fragmentFunc = library.makeFunction(name: fragmentFunction) else {
            throw MetalError.shaderLoadFailed
        }
        
        descriptor.vertexFunction = vertexFunc
        descriptor.fragmentFunction = fragmentFunc
        
        // 컬러 어태치먼트 설정
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        descriptor.colorAttachments[0].alphaBlendOperation = .add
        
        // 버텍스 디스크립터 설정
        let vertexDescriptor = MTLVertexDescriptor()
        
        // Position (float2)
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        
        // Texture coordinate (float2)
        vertexDescriptor.attributes[1].format = .float2
        vertexDescriptor.attributes[1].offset = MemoryLayout<Float>.stride * 2
        vertexDescriptor.attributes[1].bufferIndex = 0
        
        vertexDescriptor.layouts[0].stride = MemoryLayout<Float>.stride * 4
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        
        descriptor.vertexDescriptor = vertexDescriptor
        
        return try device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    private func setupBuffers() {
        // 전체 화면 사각형을 위한 정점 데이터
        let vertices: [Float] = [
            // Position    TexCoord
            -1.0, -1.0,   0.0, 1.0,  // 좌하단
             1.0, -1.0,   1.0, 1.0,  // 우하단
            -1.0,  1.0,   0.0, 0.0,  // 좌상단
             1.0,  1.0,   1.0, 0.0   // 우상단
        ]
        
        vertexBuffer = device.makeBuffer(bytes: vertices, 
                                        length: vertices.count * MemoryLayout<Float>.stride,
                                        options: [])
        
        // 유니폼 버퍼 (다중 프레임 지원)
        let uniformBufferSize = MemoryLayout<OptimizedLiquidGlassUniforms>.stride * maxBuffersInFlight
        uniformBuffer = device.makeBuffer(length: uniformBufferSize, options: [])
        
        os_log("Metal 버퍼 설정 완료", log: logger, type: .info)
    }
    
    // MARK: - Rendering
    
    public func render(
        with settings: LiquidGlassSettings,
        size: CGSize,
        time: Float,
        in view: MTKView
    ) {
        guard isRenderingEnabled else { return }
        
        // 프레임 레이트 제한
        if enableFrameRateLimit {
            let currentTime = CACurrentMediaTime()
            let timeSinceLastRender = currentTime - lastRenderTime
            let minFrameTime = 1.0 / targetFrameRate
            
            if timeSinceLastRender < minFrameTime {
                return // 프레임 스킵
            }
            lastRenderTime = currentTime
        }
        
        // 성능 모니터링 시작
        let renderStartTime = CACurrentMediaTime()
        performanceManager.frameRenderingStarted()
        
        defer {
            // 성능 모니터링 완료
            performanceManager.frameRenderingCompleted()
            
            let renderEndTime = CACurrentMediaTime()
            renderTime = (renderEndTime - renderStartTime) * 1000 // ms 단위
            currentFrameRate = renderTime > 0 ? 1000.0 / renderTime : 0
        }
        
        guard let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor else {
            return
        }
        
        // 성능 등급에 따른 파이프라인 선택
        let performanceInfo = performanceManager.getCurrentPerformanceInfo()
        let pipelineState = performanceInfo.tier == .minimal ? minimalPipelineState : renderPipelineState
        
        guard let pipelineState = pipelineState else { return }
        
        // 유니폼 데이터 준비
        updateUniforms(with: settings, size: size, time: time, quality: performanceInfo.quality)
        
        // 렌더링 명령 인코딩
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        
        renderEncoder.setRenderPipelineState(pipelineState)
        
        // 버퍼 바인딩
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        let uniformBufferOffset = MemoryLayout<OptimizedLiquidGlassUniforms>.stride * bufferIndex
        renderEncoder.setVertexBuffer(uniformBuffer, offset: uniformBufferOffset, index: 1)
        renderEncoder.setFragmentBuffer(uniformBuffer, offset: uniformBufferOffset, index: 0)
        
        // 배경 텍스처 바인딩 (필요한 경우)
        // renderEncoder.setFragmentTexture(backgroundTexture, index: 0)
        
        // 드로우 콜
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
        
        // 다음 프레임을 위한 버퍼 인덱스 업데이트
        bufferIndex = (bufferIndex + 1) % maxBuffersInFlight
    }
    
    private func updateUniforms(
        with settings: LiquidGlassSettings,
        size: CGSize,
        time: Float,
        quality: MetalPerformanceManager.QualitySettings
    ) {
        let uniformBufferOffset = MemoryLayout<OptimizedLiquidGlassUniforms>.stride * bufferIndex
        let uniformPointer = uniformBuffer?.contents().advanced(by: uniformBufferOffset)
            .bindMemory(to: OptimizedLiquidGlassUniforms.self, capacity: 1)
        
        // MVP 매트릭스 (단위 행렬로 단순화)
        let mvp = matrix_float4x4(
            SIMD4<Float>(1, 0, 0, 0),
            SIMD4<Float>(0, 1, 0, 0),
            SIMD4<Float>(0, 0, 1, 0),
            SIMD4<Float>(0, 0, 0, 1)
        )
        
        uniformPointer?.pointee = OptimizedLiquidGlassUniforms(
            modelViewProjection: mvp,
            time: time,
            glassThickness: settings.thickness * quality.distortionComplexity,
            refractionStrength: settings.refractionStrength * quality.reflectionQuality,
            reflectionStrength: settings.reflectionStrength * quality.reflectionQuality,
            distortionStrength: settings.distortionStrength * quality.distortionComplexity,
            noiseScale: 10.0,
            opacity: settings.opacity,
            edgeFade: settings.edgeFade,
            screenSize: SIMD2<Float>(Float(size.width), Float(size.height)),
            tintColor: SIMD3<Float>(settings.tintColor.r, settings.tintColor.g, settings.tintColor.b),
            aberrationStrength: quality.enableChromaticAberration ? settings.chromaticAberration : 0.0,
            qualityLevel: Int32(qualityToLevel(quality)),
            renderScale: quality.renderScale
        )
    }
    
    private func qualityToLevel(_ quality: MetalPerformanceManager.QualitySettings) -> Int {
        if quality.noiseOctaves >= 4 { return 3 }
        else if quality.noiseOctaves >= 3 { return 2 }
        else if quality.noiseOctaves >= 2 { return 1 }
        else { return 0 }
    }
    
    // MARK: - Performance Controls
    
    public func setFrameRateLimit(enabled: Bool, targetFPS: Double = 60.0) {
        enableFrameRateLimit = enabled
        targetFrameRate = targetFPS
    }
    
    public func setRenderingEnabled(_ enabled: Bool) {
        isRenderingEnabled = enabled
    }
    
    public func getCurrentPerformanceMetrics() -> (frameRate: Double, renderTime: Double, tier: String) {
        let info = performanceManager.getCurrentPerformanceInfo()
        return (currentFrameRate, renderTime, info.tier.displayName)
    }
}

// MARK: - Supporting Types

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

private enum MetalError: Error {
    case shaderLoadFailed
    case deviceNotSupported
    case bufferCreationFailed
    
    var localizedDescription: String {
        switch self {
        case .shaderLoadFailed:
            return "셰이더를 로드할 수 없습니다"
        case .deviceNotSupported:
            return "Metal을 지원하지 않는 디바이스입니다"
        case .bufferCreationFailed:
            return "Metal 버퍼 생성에 실패했습니다"
        }
    }
}