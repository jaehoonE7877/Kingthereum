import Metal
import MetalKit
import simd
import UIKit

/// Metal을 사용한 Liquid Glass 렌더러
public class MetalGlassRenderer: NSObject {
    
    // MARK: - Properties
    
    /// Metal 디바이스
    private let device: MTLDevice
    
    /// Metal 명령 큐
    private let commandQueue: MTLCommandQueue
    
    /// 렌더 파이프라인 상태
    private var liquidGlassPipelineState: MTLRenderPipelineState?
    
    /// 버텍스 버퍼
    private var vertexBuffer: MTLBuffer?
    
    /// 인덱스 버퍼  
    private var indexBuffer: MTLBuffer?
    
    /// 유니폼 버퍼
    private var uniformBuffer: MTLBuffer?
    
    /// 백그라운드 텍스처
    private var backgroundTexture: MTLTexture?
    
    /// 노이즈 텍스처
    private var noiseTexture: MTLTexture?
    
    /// 현재 렌더링 설정
    public var glassSettings = LiquidGlassSettings()
    
    /// 애니메이션 시간
    private var animationTime: Float = 0.0
    
    /// 디스플레이 링크
    private var displayLink: CADisplayLink?
    
    // MARK: - Initialization
    
    public init?(device: MTLDevice? = nil) {
        // Metal 디바이스 초기화
        if let device = device {
            self.device = device
        } else {
            guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
                print("Metal is not available on this device")
                return nil
            }
            self.device = defaultDevice
        }
        
        // 명령 큐 생성
        guard let commandQueue = self.device.makeCommandQueue() else {
            print("Failed to create Metal command queue")
            return nil
        }
        self.commandQueue = commandQueue
        
        super.init()
        
        setupPipelines()
        setupBuffers()
        setupTextures()
        setupDisplayLink()
    }
    
    deinit {
        displayLink?.invalidate()
    }
    
    // MARK: - Setup Methods
    
    private func setupPipelines() {
        guard let library = device.makeDefaultLibrary() else {
            print("Failed to create Metal library")
            return
        }
        
        // 버텍스 함수
        guard let vertexFunction = library.makeFunction(name: "liquidGlassVertex") else {
            print("Failed to find vertex function")
            return
        }
        
        // 프래그먼트 함수
        guard let fragmentFunction = library.makeFunction(name: "liquidGlassFragment") else {
            print("Failed to find fragment function")
            return
        }
        
        // 렌더 파이프라인 디스크립터
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        do {
            liquidGlassPipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            print("Failed to create pipeline state: \\(error)")
        }
    }
    
    private func setupBuffers() {
        // 쿼드 버텍스 (전체 화면을 덮는 사각형)
        let vertices: [Vertex] = [
            Vertex(position: [-1.0, -1.0], texCoord: [0.0, 1.0]),
            Vertex(position: [1.0, -1.0], texCoord: [1.0, 1.0]),
            Vertex(position: [1.0, 1.0], texCoord: [1.0, 0.0]),
            Vertex(position: [-1.0, 1.0], texCoord: [0.0, 0.0])
        ]
        
        let indices: [UInt16] = [0, 1, 2, 0, 2, 3]
        
        // 버텍스 버퍼 생성
        vertexBuffer = device.makeBuffer(
            bytes: vertices,
            length: vertices.count * MemoryLayout<Vertex>.stride,
            options: []
        )
        
        // 인덱스 버퍼 생성
        indexBuffer = device.makeBuffer(
            bytes: indices,
            length: indices.count * MemoryLayout<UInt16>.stride,
            options: []
        )
        
        // 유니폼 버퍼 생성
        uniformBuffer = device.makeBuffer(
            length: MemoryLayout<LiquidGlassUniforms>.stride,
            options: [.storageModeShared]
        )
    }
    
    private func setupTextures() {
        createNoiseTexture()
    }
    
    private func setupDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateAnimation))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func updateAnimation() {
        animationTime += 1.0 / 60.0 // 60 FPS 기준
    }
    
    // MARK: - Public Methods
    
    /// 렌더링 수행
    public func render(in view: MTKView, backgroundImage: UIImage? = nil) {
        guard let drawable = view.currentDrawable else { return }
        
        // 백그라운드 텍스처 업데이트
        if let backgroundImage = backgroundImage {
            updateBackgroundTexture(with: backgroundImage)
        }
        
        // 유니폼 업데이트
        updateUniforms(viewSize: view.bounds.size)
        
        // 명령 버퍼 생성
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        
        // 렌더 패스 디스크립터
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        
        // 렌더 명령 인코더
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        
        guard let pipeline = liquidGlassPipelineState else {
            renderEncoder.endEncoding()
            return
        }
        
        // 렌더링 상태 설정
        renderEncoder.setRenderPipelineState(pipeline)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
        renderEncoder.setFragmentBuffer(uniformBuffer, offset: 0, index: 0)
        
        // 텍스처 바인딩
        if let backgroundTexture = backgroundTexture {
            renderEncoder.setFragmentTexture(backgroundTexture, index: 0)
        }
        if let noiseTexture = noiseTexture {
            renderEncoder.setFragmentTexture(noiseTexture, index: 1)
        }
        
        // 드로우 콜
        renderEncoder.drawIndexedPrimitives(
            type: .triangle,
            indexCount: 6,
            indexType: .uint16,
            indexBuffer: indexBuffer!,
            indexBufferOffset: 0
        )
        
        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    // MARK: - Private Methods
    
    private func updateUniforms(viewSize: CGSize) {
        guard let uniformBuffer = uniformBuffer else { return }
        
        let uniforms = uniformBuffer.contents().bindMemory(to: LiquidGlassUniforms.self, capacity: 1)
        
        // MVP 매트릭스
        let aspectRatio = Float(viewSize.width / viewSize.height)
        let projection = simd_float4x4(
            [1.0, 0.0, 0.0, 0.0],
            [0.0, aspectRatio, 0.0, 0.0],
            [0.0, 0.0, 1.0, 0.0],
            [0.0, 0.0, 0.0, 1.0]
        )
        
        uniforms.pointee = LiquidGlassUniforms(
            modelViewProjection: projection,
            time: animationTime,
            glassThickness: glassSettings.thickness,
            refractionStrength: glassSettings.refractionStrength,
            reflectionStrength: glassSettings.reflectionStrength,
            distortionStrength: glassSettings.distortionStrength,
            noiseScale: glassSettings.noiseScale,
            opacity: glassSettings.opacity,
            edgeFade: glassSettings.edgeFade,
            screenSize: simd_float2(Float(viewSize.width), Float(viewSize.height)),
            tintColor: simd_float3(glassSettings.tintColor.0, glassSettings.tintColor.1, glassSettings.tintColor.2),
            aberrationStrength: glassSettings.chromaticAberration
        )
    }
    
    private func updateBackgroundTexture(with image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        
        let textureLoader = MTKTextureLoader(device: device)
        do {
            backgroundTexture = try textureLoader.newTexture(cgImage: cgImage, options: [
                .textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
                .textureStorageMode: NSNumber(value: MTLStorageMode.private.rawValue)
            ])
        } catch {
            print("Failed to load background texture: \\(error)")
        }
    }
    
    private func createNoiseTexture() {
        let width = 256
        let height = 256
        var noiseData = [UInt8](repeating: 0, count: width * height * 4)
        
        // 간단한 노이즈 생성
        for y in 0..<height {
            for x in 0..<width {
                let index = (y * width + x) * 4
                let noise = Float.random(in: 0...1)
                let value = UInt8(noise * 255)
                
                noiseData[index] = value     // R
                noiseData[index + 1] = value // G
                noiseData[index + 2] = value // B
                noiseData[index + 3] = 255   // A
            }
        }
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: width,
            height: height,
            mipmapped: false
        )
        textureDescriptor.usage = [.shaderRead]
        
        noiseTexture = device.makeTexture(descriptor: textureDescriptor)
        noiseTexture?.replace(
            region: MTLRegionMake2D(0, 0, width, height),
            mipmapLevel: 0,
            withBytes: noiseData,
            bytesPerRow: width * 4
        )
    }
}

// MARK: - Supporting Structures

/// 버텍스 구조체
struct Vertex {
    let position: simd_float2
    let texCoord: simd_float2
}

/// Metal 유니폼 구조체 (셰이더와 매칭)
struct LiquidGlassUniforms {
    var modelViewProjection: simd_float4x4
    var time: Float
    var glassThickness: Float
    var refractionStrength: Float
    var reflectionStrength: Float
    var distortionStrength: Float
    var noiseScale: Float
    var opacity: Float
    var edgeFade: Float
    var screenSize: simd_float2
    var tintColor: simd_float3
    var aberrationStrength: Float
}

/// Liquid Glass 설정
public struct LiquidGlassSettings {
    public var renderingMode: RenderingMode = .liquidGlass
    public var thickness: Float = 0.5
    public var refractionStrength: Float = 0.3
    public var reflectionStrength: Float = 0.2
    public var distortionStrength: Float = 0.1
    public var noiseScale: Float = 1.0
    public var opacity: Float = 0.8
    public var edgeFade: Float = 0.1
    public var tintColor: (Float, Float, Float) = (0.9, 0.95, 1.0)
    public var chromaticAberration: Float = 0.1
    
    public enum RenderingMode {
        case liquidGlass
        case distortion
        case blur
    }
    
    public init() {}
}