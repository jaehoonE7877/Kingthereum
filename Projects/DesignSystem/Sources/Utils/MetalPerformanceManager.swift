import Metal
import UIKit
import os.log
import Core

/// Metal 렌더링 성능을 관리하고 최적화하는 매니저
/// 디바이스 성능에 따라 자동으로 품질 설정을 조정하여 60fps 유지
@MainActor
public final class MetalPerformanceManager: ObservableObject {
    
    // MARK: - Singleton
    
    public static let shared = MetalPerformanceManager()
    
    // MARK: - Types
    
    /// 디바이스 성능 등급
    public enum DevicePerformanceTier: String, CaseIterable, Sendable {
        case high = "high"       // A15 이상, 최신 iPad Pro
        case medium = "medium"   // A12-A14, iPad Air
        case low = "low"         // A10-A11, 오래된 iPhone
        case minimal = "minimal" // Metal 미지원 또는 매우 낮은 성능
        
        public var displayName: String {
            switch self {
            case .high: return "높음"
            case .medium: return "보통"
            case .low: return "낮음"
            case .minimal: return "최소"
            }
        }
    }
    
    /// 렌더링 품질 설정
    public struct QualitySettings: Sendable {
        public let noiseOctaves: Int          // 노이즈 옥타브 수
        public let refractionSamples: Int     // 굴절 샘플링 수
        public let reflectionQuality: Float   // 반사 품질 (0.0-1.0)
        public let distortionComplexity: Float // 왜곡 복잡도
        public let animationSmoothing: Float  // 애니메이션 부드러움
        public let renderScale: Float         // 렌더 스케일 (해상도)
        public let enableChromaticAberration: Bool // 색수차 활성화
        public let enableAdvancedReflection: Bool  // 고급 반사 효과
        
        public static let high = QualitySettings(
            noiseOctaves: 4,
            refractionSamples: 8,
            reflectionQuality: 1.0,
            distortionComplexity: 1.0,
            animationSmoothing: 1.0,
            renderScale: 1.0,
            enableChromaticAberration: true,
            enableAdvancedReflection: true
        )
        
        public static let medium = QualitySettings(
            noiseOctaves: 3,
            refractionSamples: 4,
            reflectionQuality: 0.8,
            distortionComplexity: 0.8,
            animationSmoothing: 0.8,
            renderScale: 0.85,
            enableChromaticAberration: true,
            enableAdvancedReflection: false
        )
        
        public static let low = QualitySettings(
            noiseOctaves: 2,
            refractionSamples: 2,
            reflectionQuality: 0.6,
            distortionComplexity: 0.6,
            animationSmoothing: 0.6,
            renderScale: 0.75,
            enableChromaticAberration: false,
            enableAdvancedReflection: false
        )
        
        public static let minimal = QualitySettings(
            noiseOctaves: 1,
            refractionSamples: 1,
            reflectionQuality: 0.4,
            distortionComplexity: 0.4,
            animationSmoothing: 0.4,
            renderScale: 0.6,
            enableChromaticAberration: false,
            enableAdvancedReflection: false
        )
    }
    
    // MARK: - Properties
    
    @Published public private(set) var deviceTier: DevicePerformanceTier = .minimal
    @Published public private(set) var currentQuality: QualitySettings = .minimal
    @Published public private(set) var isPerformanceMonitoringEnabled: Bool = true
    @Published public private(set) var averageFrameTime: Double = 0.0
    @Published public private(set) var thermalState: ProcessInfo.ThermalState = .nominal
    
    private let metalDevice: MTLDevice?
    private let performanceLogger = OSLog(subsystem: "com.kingthereum.design", category: "MetalPerformance")
    
    // 성능 모니터링
    private var frameTimeBuffer: [Double] = []
    private var lastFrameTime: CFTimeInterval = 0
    private var performanceCheckTimer: Timer?
    private let maxFrameTimeBufferSize = 60 // 1초간 프레임 타임 추적
    
    // MARK: - Initialization
    
    private init() {
        self.metalDevice = MTLCreateSystemDefaultDevice()
        detectDeviceCapabilities()
        startPerformanceMonitoring()
        observeThermalState()
    }
    
    deinit {
        stopPerformanceMonitoring()
    }
    
    // MARK: - Device Detection
    
    /// 디바이스 성능 등급을 감지하고 설정
    private func detectDeviceCapabilities() {
        guard let device = metalDevice else {
            deviceTier = .minimal
            currentQuality = .minimal
            return
        }
        
        // GPU 패밀리로 성능 등급 판단
        if device.supportsFamily(.apple7) || device.supportsFamily(.apple8) || device.supportsFamily(.apple9) {
            // A15, A16, A17 이상
            deviceTier = .high
            currentQuality = .high
        } else if device.supportsFamily(.apple5) || device.supportsFamily(.apple6) {
            // A12, A13, A14
            deviceTier = .medium
            currentQuality = .medium
        } else if device.supportsFamily(.apple3) || device.supportsFamily(.apple4) {
            // A10, A11
            deviceTier = .low
            currentQuality = .low
        } else {
            // 그 이하 또는 Metal 미지원
            deviceTier = .minimal
            currentQuality = .minimal
        }
        
        os_log("디바이스 성능 등급 감지: %{public}@, Metal GPU Family 지원됨", 
               log: performanceLogger, type: .info, deviceTier.displayName)
        
        // 메모리 상태에 따른 추가 조정
        adjustForMemoryConstraints()
    }
    
    /// 메모리 제약에 따른 품질 조정
    private func adjustForMemoryConstraints() {
        let physicalMemory = ProcessInfo.processInfo.physicalMemory
        let memoryInGB = Double(physicalMemory) / (1024 * 1024 * 1024)
        
        // 메모리가 3GB 미만인 경우 품질 하향 조정
        if memoryInGB < 3.0 && deviceTier == .high {
            deviceTier = .medium
            currentQuality = .medium
            os_log("메모리 제약으로 인한 성능 등급 조정: %.1fGB RAM", 
                   log: performanceLogger, type: .info, memoryInGB)
        }
        
        // 메모리가 2GB 미만인 경우 추가 하향 조정
        if memoryInGB < 2.0 && deviceTier == .medium {
            deviceTier = .low
            currentQuality = .low
        }
    }
    
    // MARK: - Performance Monitoring
    
    /// 성능 모니터링 시작
    private func startPerformanceMonitoring() {
        guard isPerformanceMonitoringEnabled else { return }
        
        performanceCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkPerformanceAndAdjust()
            }
        }
    }
    
    /// 성능 모니터링 중지
    private func stopPerformanceMonitoring() {
        performanceCheckTimer?.invalidate()
        performanceCheckTimer = nil
    }
    
    /// 프레임 렌더링 시작 시 호출
    public func frameRenderingStarted() {
        lastFrameTime = CACurrentMediaTime()
    }
    
    /// 프레임 렌더링 완료 시 호출
    public func frameRenderingCompleted() {
        let currentTime = CACurrentMediaTime()
        let frameTime = currentTime - lastFrameTime
        
        // 프레임 타임 버퍼에 추가
        frameTimeBuffer.append(frameTime)
        if frameTimeBuffer.count > maxFrameTimeBufferSize {
            frameTimeBuffer.removeFirst()
        }
        
        // 평균 프레임 타임 계산
        if !frameTimeBuffer.isEmpty {
            averageFrameTime = frameTimeBuffer.reduce(0, +) / Double(frameTimeBuffer.count)
        }
    }
    
    /// 성능 체크 및 품질 자동 조정
    private func checkPerformanceAndAdjust() {
        guard !frameTimeBuffer.isEmpty else { return }
        
        let targetFrameTime = 1.0 / 60.0 // 60fps 목표
        let performanceThreshold = targetFrameTime * 1.2 // 20% 여유
        
        // 성능이 목표에 못 미치는 경우 품질 하향 조정
        if averageFrameTime > performanceThreshold {
            adjustQualityDown()
        }
        // 성능에 여유가 있는 경우 품질 상향 조정 (신중하게)
        else if averageFrameTime < targetFrameTime * 0.8 {
            adjustQualityUp()
        }
    }
    
    /// 품질 하향 조정
    private func adjustQualityDown() {
        let newQuality: QualitySettings
        
        switch deviceTier {
        case .high:
            deviceTier = .medium
            newQuality = .medium
        case .medium:
            deviceTier = .low
            newQuality = .low
        case .low:
            deviceTier = .minimal
            newQuality = .minimal
        case .minimal:
            return // 더 이상 낮출 수 없음
        }
        
        currentQuality = newQuality
        
        os_log("성능 부족으로 품질 조정: %{public}@ → 평균 프레임 타임: %.3fms", 
               log: performanceLogger, type: .info, 
               deviceTier.displayName, averageFrameTime * 1000)
    }
    
    /// 품질 상향 조정 (매우 신중하게)
    private func adjustQualityUp() {
        // 온도 상태가 좋지 않으면 품질 상향 조정 금지
        guard thermalState == .nominal || thermalState == .fair else { return }
        
        let newQuality: QualitySettings
        let newTier: DevicePerformanceTier
        
        switch deviceTier {
        case .minimal:
            newTier = .low
            newQuality = .low
        case .low:
            newTier = .medium
            newQuality = .medium
        case .medium:
            newTier = .high
            newQuality = .high
        case .high:
            return // 이미 최고 품질
        }
        
        // 매우 안정적인 성능일 때만 품질 향상
        if frameTimeBuffer.count >= maxFrameTimeBufferSize {
            let stablePerformance = frameTimeBuffer.allSatisfy { $0 < 1.0/60.0 * 0.8 }
            if stablePerformance {
                deviceTier = newTier
                currentQuality = newQuality
                
                os_log("성능 향상으로 품질 상향 조정: %{public}@", 
                       log: performanceLogger, type: .info, deviceTier.displayName)
            }
        }
    }
    
    // MARK: - Thermal State Monitoring
    
    /// 열 상태 모니터링 시작
    private func observeThermalState() {
        thermalState = ProcessInfo.processInfo.thermalState
        
        NotificationCenter.default.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleThermalStateChange()
        }
    }
    
    /// 열 상태 변경 처리
    private func handleThermalStateChange() {
        let newThermalState = ProcessInfo.processInfo.thermalState
        let oldThermalState = thermalState
        thermalState = newThermalState
        
        // 과열 상태에서는 품질 강제 하향 조정
        switch newThermalState {
        case .serious, .critical:
            if deviceTier != .minimal {
                deviceTier = .minimal
                currentQuality = .minimal
                os_log("과열로 인한 품질 강제 하향 조정: %{public}@", 
                       log: performanceLogger, type: .error, thermalState.description)
            }
        case .fair:
            if deviceTier == .high {
                deviceTier = .medium
                currentQuality = .medium
            }
        case .nominal:
            // 온도가 정상으로 돌아오면 점진적 회복 (자동 조정에 맡김)
            break
        @unknown default:
            break
        }
        
        if oldThermalState != newThermalState {
            os_log("열 상태 변경: %{public}@ → %{public}@", 
                   log: performanceLogger, type: .info, 
                   oldThermalState.description, newThermalState.description)
        }
    }
    
    // MARK: - Public Interface
    
    /// 수동으로 품질 설정 변경 (사용자 설정)
    public func setQuality(_ quality: QualitySettings, tier: DevicePerformanceTier) {
        currentQuality = quality
        deviceTier = tier
        
        os_log("수동 품질 설정 변경: %{public}@", 
               log: performanceLogger, type: .info, tier.displayName)
    }
    
    /// 현재 성능 정보 반환
    public func getCurrentPerformanceInfo() -> (tier: DevicePerformanceTier, 
                                              quality: QualitySettings, 
                                              frameRate: Double,
                                              thermal: ProcessInfo.ThermalState) {
        let fps = averageFrameTime > 0 ? 1.0 / averageFrameTime : 0
        return (deviceTier, currentQuality, fps, thermalState)
    }
    
    /// Metal 디바이스 반환
    public var device: MTLDevice? {
        return metalDevice
    }
    
    /// 성능 모니터링 활성화/비활성화
    public func setPerformanceMonitoring(enabled: Bool) {
        isPerformanceMonitoringEnabled = enabled
        
        if enabled {
            startPerformanceMonitoring()
        } else {
            stopPerformanceMonitoring()
        }
    }
}

// MARK: - ProcessInfo.ThermalState Extension

private extension ProcessInfo.ThermalState {
    var description: String {
        switch self {
        case .nominal: return "정상"
        case .fair: return "보통"
        case .serious: return "심각"
        case .critical: return "위험"
        @unknown default: return "알 수 없음"
        }
    }
}