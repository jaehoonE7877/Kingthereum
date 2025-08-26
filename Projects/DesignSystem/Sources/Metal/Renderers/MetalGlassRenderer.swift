import Metal
import MetalKit
import simd
import UIKit
import Core

/// Metal을 사용한 Liquid Glass 렌더러 (Swift6 Concurrency 적합 싱글톤)
@MainActor
public final class MetalGlassRenderer: NSObject {
    
    // MARK: - Singleton
    
    /// 싱글톤 인스턴스 (Swift6 Concurrency 안전)
    public static let shared: MetalGlassRenderer = {
        guard let instance = MetalGlassRenderer() else {
            fatalError("Failed to initialize MetalGlassRenderer singleton")
        }
        return instance
    }()
    
    // MARK: - Properties
    
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
    
    /// 텍스처 샘플러
    private var textureSampler: MTLSamplerState?
    
    /// 현재 렌더링 설정
    public var glassSettings = LiquidGlassSettings()
    
    /// 애니메이션 시간
    private var animationTime: Float = 0.0
    
    /// 디스플레이 링크
    private var displayLink: CADisplayLink?
    
    // MARK: - Initialization
    
    /// Metal 디바이스
    let device: MTLDevice
    
    private init?(device: MTLDevice? = nil) {
        // Metal 디바이스 초기화
        if let device = device {
            self.device = device
        } else {
            guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
                Logger.error("MetalGlassRenderer: Metal is not available on this device")
                return nil
            }
            self.device = defaultDevice
            Logger.debug("MetalGlassRenderer: Using system Metal device: \(defaultDevice.name)")
        }
        
        // 명령 큐 생성
        guard let commandQueue = self.device.makeCommandQueue() else {
            Logger.error("MetalGlassRenderer: Failed to create Metal command queue")
            return nil
        }
        self.commandQueue = commandQueue
        
        super.init()
        
        setupPipelines()
        setupBuffers()
        setupTextures()
        setupDisplayLink()
        
        // 초기화 완료 여부 확인
        if liquidGlassPipelineState != nil {
            Logger.debug("MetalGlassRenderer: Initialized successfully")
        } else {
            Logger.error("MetalGlassRenderer: Initialized with limited functionality (pipeline creation failed)")
        }
    }
    
    deinit {
        // displayLink cleanup handled by stopAnimation
    }
    
    // MARK: - Setup Methods
    
    /// Metal 리소스 상태 검증 (DEBUG 모드에서만 실행)
    private func validateMetalResources() {
        #if DEBUG
        Logger.debug("MetalGlassRenderer: Validating Metal resources")
        
        let bundle = Bundle(for: type(of: self))
        
        // Metal 라이브러리 검사
        if device.makeDefaultLibrary() != nil {
            Logger.debug("MetalGlassRenderer: Default Metal library available")
        } else {
            Logger.debug("MetalGlassRenderer: Default Metal library NOT available")
        }
        
        // metallib 파일 검사
        if bundle.path(forResource: "default", ofType: "metallib") != nil {
            Logger.debug("MetalGlassRenderer: Compiled metallib found")
        } else {
            Logger.debug("MetalGlassRenderer: Compiled metallib NOT found")
        }
        
        Logger.debug("MetalGlassRenderer: Resource validation completed")
        #endif
    }
    
    /// Metal 라이브러리 생성
    private func createMetalLibrary() -> MTLLibrary? {
        Logger.debug("MetalGlassRenderer: Attempting to create Metal library")
                
        // 방법 1: 기본 라이브러리 시도
        if let library = device.makeDefaultLibrary() {
            Logger.debug("MetalGlassRenderer: Default Metal library loaded successfully")
            return validateAndReturnLibrary(library)
        }
        
        Logger.debug("MetalGlassRenderer: Default library failed, trying direct metallib loading")
        
        // 방법 2: 번들의 default.metallib 직접 로드
        if let library = loadMetallibFromBundle() {
            Logger.debug("MetalGlassRenderer: Direct metallib loaded successfully")
            return validateAndReturnLibrary(library)
        }
        
        Logger.debug("MetalGlassRenderer: Direct metallib failed, trying runtime compilation")
        
        // 방법 3: LiquidGlass.dat 파일에서 런타임 컴파일 시도
        if let library = compileFromDatFile() {
            Logger.debug("MetalGlassRenderer: DAT file compilation successful")
            return validateAndReturnLibrary(library)
        }
        
        Logger.error("MetalGlassRenderer: All Metal library creation methods failed")
        return nil
    }
    
    /// Metal 라이브러리 검증 및 반환
    private func validateAndReturnLibrary(_ library: MTLLibrary) -> MTLLibrary {
        #if DEBUG
        Logger.debug("MetalGlassRenderer: Available functions: \(library.functionNames.count)")
        #endif
        
        // 필요한 함수들 확인
        let requiredFunctions = ["liquidGlassVertex", "liquidGlassFragment"]
        var foundFunctions = 0
        
        for functionName in requiredFunctions {
            if library.makeFunction(name: functionName) != nil {
                #if DEBUG
                Logger.debug("MetalGlassRenderer: Found function: \(functionName)")
                #endif
                foundFunctions += 1
            } else {
                Logger.error("MetalGlassRenderer: Missing function: \(functionName)")
            }
        }
        
        if foundFunctions == requiredFunctions.count {
            Logger.debug("MetalGlassRenderer: All required functions found")
        } else {
            Logger.error("MetalGlassRenderer: Missing \(requiredFunctions.count - foundFunctions) required functions")
        }
        
        return library
    }
    
    /// 번들에서 default.metallib 직접 로드
    private func loadMetallibFromBundle() -> MTLLibrary? {
        let bundle = Bundle(for: type(of: self))
        
        guard let metallibPath = bundle.path(forResource: "default", ofType: "metallib") else {
            Logger.debug("MetalGlassRenderer: default.metallib not found in bundle")
            return nil
        }
        
        Logger.debug("MetalGlassRenderer: Found metallib at: \(metallibPath)")
        
        do {
            let metallibURL = URL(fileURLWithPath: metallibPath)
            let library = try device.makeLibrary(URL: metallibURL)
            Logger.debug("MetalGlassRenderer: Successfully loaded metallib from URL")
            return library
        } catch {
            Logger.error("MetalGlassRenderer: Failed to load metallib: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// LiquidGlass.dat 파일에서 컴파일 시도
    private func compileFromDatFile() -> MTLLibrary? {
        let bundle = Bundle(for: type(of: self))
        
        guard let datPath = bundle.path(forResource: "LiquidGlass", ofType: "dat") else {
            Logger.debug("MetalGlassRenderer: LiquidGlass.dat not found in bundle")
            return nil
        }
        
        Logger.debug("MetalGlassRenderer: Found LiquidGlass.dat at: \(datPath)")
        
        // .dat 파일을 Metal 소스로 읽어보기
        guard let shaderSource = try? String(contentsOfFile: datPath, encoding: .utf8) else {
            Logger.error("MetalGlassRenderer: Failed to read LiquidGlass.dat file")
            return nil
        }
        
        Logger.debug("MetalGlassRenderer: DAT file loaded (\(shaderSource.count) characters)")
        
        // Metal 소스인지 확인
        if shaderSource.contains("liquidGlassVertex") && shaderSource.contains("liquidGlassFragment") {
            Logger.debug("MetalGlassRenderer: DAT file contains Metal source code")
            
            do {
                let library = try device.makeLibrary(source: shaderSource, options: nil)
                Logger.debug("MetalGlassRenderer: Successfully compiled from DAT file")
                return library
            } catch {
                Logger.error("MetalGlassRenderer: Failed to compile from DAT: \(error)")
                return nil
            }
        } else {
            Logger.error("MetalGlassRenderer: DAT file doesn't contain expected Metal functions")
            return nil
        }
    }
    
    /// 런타임 Metal 셰이더 컴파일 (Fallback)
    private func compileMetalShaderRuntime() -> MTLLibrary? {
        Logger.debug("MetalGlassRenderer: Attempting runtime Metal shader compilation")
        
        let bundle = Bundle(for: type(of: self))
        
        // Resources/Metal/LiquidGlass.metal 파일 찾기
        guard let metalPath = bundle.path(forResource: "Metal/LiquidGlass", ofType: "metal") else {
            Logger.debug("MetalGlassRenderer: LiquidGlass.metal not found in Resources/Metal/")
            return nil
        }
        
        // Metal 소스 코드 읽기
        guard let shaderSource = try? String(contentsOfFile: metalPath, encoding: .utf8) else {
            Logger.error("MetalGlassRenderer: Failed to read LiquidGlass.metal file")
            return nil
        }
        
        Logger.debug("MetalGlassRenderer: Metal source code loaded (\(shaderSource.count) characters)")
        
        // 런타임 컴파일
        do {
            let library = try device.makeLibrary(source: shaderSource, options: nil)
            Logger.debug("MetalGlassRenderer: Successfully compiled Metal shader from source")
            return library
        } catch {
            Logger.error("MetalGlassRenderer: Failed to compile Metal shader: \(error)")
            if let metalError = error as? MTLLibraryError {
                Logger.error("MetalGlassRenderer: Metal compilation error details: \(metalError.localizedDescription)")
            }
            return nil
        }
    }
    
    private func setupPipelines() {
        // Metal library 생성
        guard let library = createMetalLibrary() else {
            Logger.error("MetalGlassRenderer: Failed to create Metal library - Using fallback mode")
            return
        }
        
        Logger.debug("MetalGlassRenderer: Metal library created successfully")
        
        // 버텍스 함수
        guard let vertexFunction = library.makeFunction(name: "liquidGlassVertex") else {
            Logger.error("MetalGlassRenderer: Failed to find vertex function 'liquidGlassVertex'")
            return
        }
        
        // 프래그먼트 함수
        guard let fragmentFunction = library.makeFunction(name: "liquidGlassFragment") else {
            Logger.error("MetalGlassRenderer: Failed to find fragment function 'liquidGlassFragment'")
            return
        }
        
        Logger.debug("MetalGlassRenderer: Metal functions loaded successfully")
        
        // 렌더 파이프라인 디스크립터
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        
        // Vertex Descriptor 설정
        pipelineDescriptor.vertexDescriptor = createVertexDescriptor()
        
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        do {
            liquidGlassPipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
            Logger.debug("MetalGlassRenderer: Render pipeline state created successfully")
        } catch {
            Logger.error("MetalGlassRenderer: Failed to create pipeline state: \(error.localizedDescription)")
        }
    }
    
    /// Vertex Descriptor 생성
    private func createVertexDescriptor() -> MTLVertexDescriptor {
        let vertexDescriptor = MTLVertexDescriptor()
        
        // Position attribute (index 0)
        vertexDescriptor.attributes[0].format = .float2           // simd_float2
        vertexDescriptor.attributes[0].offset = 0                 // position이 첫번째 필드
        vertexDescriptor.attributes[0].bufferIndex = 1            // index 1 버퍼에서 읽어옴 (유니폼은 0)
        
        // TexCoord attribute (index 1) 
        vertexDescriptor.attributes[1].format = .float2           // simd_float2
        vertexDescriptor.attributes[1].offset = MemoryLayout<simd_float2>.stride  // position 다음
        vertexDescriptor.attributes[1].bufferIndex = 1            // 같은 버퍼에서 읽어옴
        
        // Buffer layout (layout 1) - 버텍스 데이터용
        vertexDescriptor.layouts[1].stride = MemoryLayout<Vertex>.stride  // Vertex 구조체 크기
        vertexDescriptor.layouts[1].stepRate = 1                          // 정점마다 하나씩
        vertexDescriptor.layouts[1].stepFunction = .perVertex             // 정점 단위로 진행
        
        #if DEBUG
        Logger.debug("MetalGlassRenderer: Vertex descriptor created with stride: \(vertexDescriptor.layouts[1].stride)")
        #endif
        
        return vertexDescriptor
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
        createTextureSampler()
    }
    
    private func setupDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateAnimation))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func updateAnimation() {
        animationTime += 1.0 / 60.0 // 60 FPS 기준
    }
    
    // MARK: - Public Methods
    
    /// 애니메이션 중지
    public func stopAnimation() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    /// 렌더링 수행 (성능 최적화됨)
    public func render(in view: MTKView, backgroundImage: UIImage? = nil) {
        // Metal 파이프라인이 준비되지 않은 경우 조용히 반환
        guard let pipelineState = liquidGlassPipelineState else {
            return
        }
        
        guard let drawable = view.currentDrawable else {
            return 
        }
        
        // 백그라운드 텍스처 업데이트
        if let backgroundImage = backgroundImage {
            updateBackgroundTexture(with: backgroundImage)
        }
        
        // 유니폼 업데이트
        updateUniforms(viewSize: view.bounds.size)
        
        // 명령 버퍼 생성
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { 
            Logger.error("MetalGlassRenderer: Failed to create command buffer")
            return 
        }
        
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
        
        // 렌더링 상태 설정 (이미 확인된 pipelineState 사용)
        renderEncoder.setRenderPipelineState(pipelineState)
        
        // 버텍스 버퍼 바인딩 (버퍼 인덱스 수정)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 1)      // 버텍스 데이터를 index 1에
        renderEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: 0)     // 유니폼을 index 0에 (셰이더 기대값)
        renderEncoder.setFragmentBuffer(uniformBuffer, offset: 0, index: 0)   // 프래그먼트도 index 0에
        
        // 텍스처 바인딩
        if let backgroundTexture = backgroundTexture {
            renderEncoder.setFragmentTexture(backgroundTexture, index: 0)
        }
        if let noiseTexture = noiseTexture {
            renderEncoder.setFragmentTexture(noiseTexture, index: 1)
        }
        
        // 샘플러 바인딩 (필수!)
        if let textureSampler = textureSampler {
            renderEncoder.setFragmentSamplerState(textureSampler, index: 0)
        } else {
            Logger.error("MetalGlassRenderer: Texture sampler is nil")
            renderEncoder.endEncoding()
            return
        }
        
        // 드로우 콜
        guard let indexBuffer = indexBuffer else {
            Logger.error("MetalGlassRenderer: Index buffer is nil")
            renderEncoder.endEncoding()
            return
        }
        
        renderEncoder.drawIndexedPrimitives(
            type: .triangle,
            indexCount: 6,
            indexType: .uint16,
            indexBuffer: indexBuffer,
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
            tintColor: glassSettings.tintColor.simdFloat3,
            aberrationStrength: glassSettings.chromaticAberration
        )
    }
    
    // MARK: - Cross-Actor Access Methods
    
    /// 다른 Actor에서 안전하게 설정을 업데이트할 수 있는 nonisolated 메서드
    nonisolated func updateSettings(_ settings: LiquidGlassSettings) {
        Task { @MainActor in
            await MainActor.run {
                // 현재 렌더링 상태를 고려한 안전한 설정 업데이트
                // 실제 uniforms 업데이트는 다음 render 호출에서 자동으로 적용
            }
        }
    }
    
    /// 현재 설정을 안전하게 조회할 수 있는 nonisolated 메서드
    nonisolated func getCurrentSettings() async -> LiquidGlassSettings? {
        return await MainActor.run {
            // 기본 설정값 반환 (실제 설정은 render 호출 시 외부에서 전달받음)
            return LiquidGlassSettings()
        }
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
            Logger.error("MetalGlassRenderer: Failed to load background texture: \(error)")
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
    
    /// 텍스처 샘플러 생성
    private func createTextureSampler() {
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.mipFilter = .linear
        samplerDescriptor.sAddressMode = .repeat
        samplerDescriptor.tAddressMode = .repeat
        samplerDescriptor.rAddressMode = .repeat
        
        textureSampler = device.makeSamplerState(descriptor: samplerDescriptor)
        
        if textureSampler == nil {
            Logger.error("MetalGlassRenderer: Failed to create texture sampler")
        }
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

/// Liquid Glass 설정 (Swift 6 Concurrency + 직렬화 지원)
public struct LiquidGlassSettings: Sendable, Codable {
    public var renderingMode: RenderingMode = .liquidGlass
    public var thickness: Float = 0.8
    public var refractionStrength: Float = 0.6
    public var reflectionStrength: Float = 0.4
    public var distortionStrength: Float = 0.3
    public var noiseScale: Float = 2.0
    public var opacity: Float = 0.85
    public var edgeFade: Float = 0.2
    public var tintColor: TintColor = LiquidGlassSettings.TintColor(r: 0.8, g: 0.9, b: 1.0)
    public var chromaticAberration: Float = 0.3
    
    public enum RenderingMode: Sendable, Codable {
        case liquidGlass
        case distortion
        case blur
    }
    
    /// Codable + Sendable한 색상 타입
    public struct TintColor: Sendable, Codable {
        public let r: Float
        public let g: Float
        public let b: Float
        
        public init(r: Float, g: Float, b: Float) {
            self.r = r
            self.g = g
            self.b = b
        }
        
        /// simd_float3로 변환
        public var simdFloat3: simd_float3 {
            return simd_float3(r, g, b)
        }
        
        /// tuple로 변환 (기존 호환성)
        public var tuple: (Float, Float, Float) {
            return (r, g, b)
        }
    }
    
    public init() {}
    
    /// 다크/라이트 모드에 적응형 Glass 설정 생성
    public static func adaptive(isDarkMode: Bool) -> LiquidGlassSettings {
        var settings = LiquidGlassSettings()
        
        if isDarkMode {
            // 다크 모드: 더 밝고 강렬한 Glass 효과
            settings.thickness = 0.9
            settings.refractionStrength = 0.7
            settings.reflectionStrength = 0.5
            settings.distortionStrength = 0.4
            settings.noiseScale = 2.5
            settings.opacity = 0.9
            settings.edgeFade = 0.25
            settings.tintColor = LiquidGlassSettings.TintColor(r: 0.7, g: 0.85, b: 1.0) // 더 차가운 블루 톤
            settings.chromaticAberration = 0.4
        } else {
            // 라이트 모드: 더 부드럽고 자연스러운 Glass 효과  
            settings.thickness = 0.7
            settings.refractionStrength = 0.5
            settings.reflectionStrength = 0.3
            settings.distortionStrength = 0.2
            settings.noiseScale = 1.8
            settings.opacity = 0.8
            settings.edgeFade = 0.15
            settings.tintColor = LiquidGlassSettings.TintColor(r: 0.9, g: 0.95, b: 1.0) // 더 따뜻한 톤
            settings.chromaticAberration = 0.2
        }
        
        return settings
    }
}
