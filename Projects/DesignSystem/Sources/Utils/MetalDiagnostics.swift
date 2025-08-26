import Metal
import Foundation
import Core

/// Metal 진단 및 디버깅을 위한 유틸리티
public enum MetalDiagnostics {
    
    /// Metal 지원 상태와 디바이스 정보를 출력 (간소화된 버전)
    public static func printSystemInfo() {
        Logger.debug("MetalDiagnostics: Metal System Information")
        
        // Metal 지원 여부
        guard let device = MTLCreateSystemDefaultDevice() else {
            Logger.error("MetalDiagnostics: Metal not supported on this device")
            return
        }
        
        Logger.debug("MetalDiagnostics: Metal supported - Device: \(device.name)")
        Logger.debug("MetalDiagnostics: Memory: \(device.hasUnifiedMemory ? "Unified" : "Discrete")")
        Logger.debug("MetalDiagnostics: Max Threads Per Group: \(device.maxThreadsPerThreadgroup)")
        
        // 라이브러리 로드 테스트
        if let library = device.makeDefaultLibrary() {
            Logger.debug("MetalDiagnostics: Default Library: Available (\(library.functionNames.count) functions)")
        } else {
            Logger.debug("MetalDiagnostics: Default Library: Not Available")
        }
    }
    
    /// Metal 라이브러리의 함수 목록을 출력 (디버깅용)
    public static func printAvailableFunctions() {
        guard let device = MTLCreateSystemDefaultDevice(),
              let library = device.makeDefaultLibrary() else {
            Logger.error("MetalDiagnostics: Cannot access Metal library")
            return
        }
        
        Logger.debug("MetalDiagnostics: Available Metal Functions (\(library.functionNames.count) total)")
        
        #if DEBUG
        let functionNames = library.functionNames.sorted()
        for (index, name) in functionNames.enumerated() {
            Logger.debug("\(index + 1). \(name)")
        }
        #endif
    }
    
    /// 특정 함수가 Metal 라이브러리에 존재하는지 확인
    public static func checkFunction(_ functionName: String) -> Bool {
        guard let device = MTLCreateSystemDefaultDevice(),
              let library = device.makeDefaultLibrary() else {
            Logger.error("MetalDiagnostics: Cannot access Metal library")
            return false
        }
        
        let exists = library.makeFunction(name: functionName) != nil
        Logger.debug("MetalDiagnostics: Function '\(functionName)': \(exists ? "Found" : "Not Found")")
        return exists
    }
    
    /// Metal Liquid Glass 관련 라이브러리 상태 확인 (간소화된 버전)
    /// 
    /// 참고: LiquidGlass 함수들은 컴파일된 metallib에 있으므로 
    /// 기본 라이브러리에서 검색하면 찾을 수 없습니다. 이는 정상적인 동작입니다.
    public static func checkMetalLibraryStatus() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            Logger.error("MetalDiagnostics: Metal is not supported on this device")
            return
        }
        
        Logger.debug("MetalDiagnostics: Metal device: \(device.name)")
        
        if let library = device.makeDefaultLibrary() {
            Logger.debug("MetalDiagnostics: Default library available with \(library.functionNames.count) functions")
        } else {
            Logger.debug("MetalDiagnostics: Default library not available (normal for custom shaders)")
        }
    }
}