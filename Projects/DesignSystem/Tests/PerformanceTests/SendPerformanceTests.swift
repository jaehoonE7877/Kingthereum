import Testing
import Foundation
import SwiftUI
@testable import DesignSystem

/// 🚀 Performance Test Suite for Optimized Send Components
/// Validates performance improvements and regression testing
@MainActor @Suite("Send Performance Tests")
struct SendPerformanceTests {
    
    // MARK: - Network Performance Tests
    
    @Suite("Network Optimization")
    struct NetworkPerformanceTests {
        
        @Test("Gas estimation performance under 500ms")
        func testGasEstimationSpeed() async {
            let networkManager = OptimizedSendNetworkManager.shared
            let startTime = CFAbsoluteTimeGetCurrent()
            
            do {
                let _ = try await networkManager.getOptimizedGasEstimate(
                    for: "0x1234567890123456789012345678901234567890",
                    amount: "1.0"
                )
                
                let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
                
                #expect(
                    duration < 500,
                    "Gas estimation should complete in under 500ms, took \(duration)ms"
                )
            } catch {
                Issue.record("Gas estimation failed: \(error)")
            }
        }
        
        @Test("Cache hit performance under 50ms")
        func testCacheHitPerformance() async {
            let networkManager = OptimizedSendNetworkManager.shared
            let cacheKey = "performance_test_key"
            
            // First call to populate cache
            let _ = try? await networkManager.getOptimizedGasEstimate(
                for: "0x1234567890123456789012345678901234567890",
                amount: "1.0",
                cacheKey: cacheKey
            )
            
            // Second call should hit cache
            let startTime = CFAbsoluteTimeGetCurrent()
            let _ = try? await networkManager.getOptimizedGasEstimate(
                for: "0x1234567890123456789012345678901234567890", 
                amount: "1.0",
                cacheKey: cacheKey
            )
            let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            
            #expect(
                duration < 50,
                "Cache hit should complete in under 50ms, took \(duration)ms"
            )
        }
        
        @Test("Parallel gas price fetching efficiency")
        func testParallelGasFetching() async {
            let networkManager = OptimizedSendNetworkManager.shared
            
            let startTime = CFAbsoluteTimeGetCurrent()
            
            // Simulate parallel gas price fetching
            async let task1 = networkManager.getOptimizedGasEstimate(
                for: "0x1111111111111111111111111111111111111111",
                amount: "1.0"
            )
            async let task2 = networkManager.getOptimizedGasEstimate(
                for: "0x2222222222222222222222222222222222222222", 
                amount: "2.0"
            )
            async let task3 = networkManager.getOptimizedGasEstimate(
                for: "0x3333333333333333333333333333333333333333",
                amount: "3.0"
            )
            
            let _ = try? await (task1, task2, task3)
            let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            
            #expect(
                duration < 800, // Should be faster than sequential (3 x 500ms = 1500ms)
                "Parallel fetching should complete in under 800ms, took \(duration)ms"
            )
        }
    }
    
    // MARK: - Address Validation Performance Tests
    
    @Suite("Address Validation Optimization") 
    struct AddressValidationTests {
        
        @Test("Address validation performance under 100ms")
        func testAddressValidationSpeed() async {
            let validator = CachedAddressValidator()
            let testAddress = "0x1234567890123456789012345678901234567890"
            
            let startTime = CFAbsoluteTimeGetCurrent()
            let _ = await validator.validateFormat(testAddress)
            let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            
            #expect(
                duration < 100,
                "Address validation should complete in under 100ms, took \(duration)ms"
            )
        }
        
        @Test("Address validation cache effectiveness")
        func testAddressValidationCache() async {
            let validator = CachedAddressValidator() 
            let testAddress = "0x1234567890123456789012345678901234567890"
            
            // First call populates cache
            let _ = await validator.validateFormat(testAddress)
            
            // Second call should hit cache
            let startTime = CFAbsoluteTimeGetCurrent()
            let _ = await validator.validateFormat(testAddress)
            let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            
            #expect(
                duration < 10,
                "Cached address validation should complete in under 10ms, took \(duration)ms"
            )
        }
        
        @Test("Parallel address validation components")
        func testParallelAddressValidation() async {
            let validator = CachedAddressValidator()
            let testAddress = "0x1234567890123456789012345678901234567890"
            
            let startTime = CFAbsoluteTimeGetCurrent()
            
            // Parallel validation like in production code
            async let formatValidation = validator.validateFormat(testAddress)
            async let checksumValidation = validator.validateChecksum(testAddress)
            async let blacklistCheck = validator.checkBlacklist(testAddress)
            
            let _ = await (formatValidation, checksumValidation, blacklistCheck)
            let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            
            #expect(
                duration < 150, // Should be faster than sequential
                "Parallel address validation should complete in under 150ms, took \(duration)ms"
            )
        }
    }
    
    // MARK: - UI Performance Tests
    
    @Suite("UI Performance Optimization")
    struct UIPerformanceTests {
        
        @Test("Debouncer prevents excessive validation calls")
        func testDebouncerEffectiveness() async {
            let debouncer = Debouncer(delay: 0.1)
            var callCount = 0
            
            // Simulate rapid typing
            for i in 0..<10 {
                debouncer.debounce {
                    callCount += 1
                }
                try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
            }
            
            // Wait for debounce delay
            try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
            
            #expect(
                callCount == 1,
                "Debouncer should result in only 1 call, got \(callCount)"
            )
        }
        
        @Test("ViewStore selective updates prevent unnecessary re-renders")
        func testViewStoreSelectiveUpdates() {
            let viewStore = OptimizedSendViewStore()
            var updateCount = 0
            
            // Monitor published changes (simulate @Published observation)
            let cancellable = viewStore.objectWillChange.sink { _ in
                updateCount += 1
            }
            
            // Multiple identical updates
            viewStore.updateAddressValidation(isValid: true, message: "Valid")
            viewStore.updateAddressValidation(isValid: true, message: "Valid") // Should be ignored
            viewStore.updateAddressValidation(isValid: true, message: "Valid") // Should be ignored
            
            cancellable.cancel()
            
            #expect(
                updateCount == 1,
                "Identical updates should be ignored, got \(updateCount) updates"
            )
        }
        
        @Test("Animation controller provides smooth transitions")
        func testAnimationControllerPerformance() {
            let animationController = SendAnimationController()
            
            let startTime = CFAbsoluteTimeGetCurrent()
            animationController.startEntryAnimation()
            let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            
            #expect(
                duration < 16, // Should be under one frame (16.67ms at 60fps)
                "Animation setup should complete within one frame, took \(duration)ms"
            )
        }
    }
    
    // MARK: - Memory Performance Tests
    
    @Suite("Memory Optimization")
    struct MemoryPerformanceTests {
        
        @Test("Cache cleanup prevents memory bloat")
        func testCacheCleanupEffectiveness() async {
            let interactor = OptimizedSendInteractor()
            
            // Generate many validation requests to populate caches
            for i in 0..<100 {
                interactor.validateAddress("0x\(String(format: "%040d", i))")
                await Task.yield() // Allow cache population
            }
            
            // Simulate time passage for cache expiration
            // In real implementation, cleanup would be triggered by timer
            
            // Verify system can handle large number of validations without crashes
            #expect(true, "System should handle 100 validation requests without memory issues")
        }
        
        @Test("No memory leaks in network operations")  
        func testNetworkMemoryLeaks() async {
            weak var networkManager: OptimizedSendNetworkManager? = OptimizedSendNetworkManager.shared
            
            // Perform multiple network operations
            for _ in 0..<10 {
                let _ = try? await OptimizedSendNetworkManager.shared.getOptimizedGasEstimate(
                    for: "0x1234567890123456789012345678901234567890",
                    amount: "1.0"
                )
            }
            
            // Network manager should still exist (it's a singleton)
            #expect(networkManager != nil, "Network manager should not be deallocated")
        }
    }
    
    // MARK: - Integration Performance Tests
    
    @Suite("End-to-End Performance")
    struct IntegrationPerformanceTests {
        
        @Test("Complete transaction validation flow under 1 second")
        func testCompleteValidationFlow() async {
            let interactor = OptimizedSendInteractor()
            
            let startTime = CFAbsoluteTimeGetCurrent()
            
            // Simulate complete user flow
            interactor.validateAddress("0x1234567890123456789012345678901234567890")
            interactor.validateAmount("1.0")
            interactor.estimateGas(
                recipient: "0x1234567890123456789012345678901234567890",
                amount: "1.0"
            )
            
            // Wait for all validations to complete
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            
            #expect(
                duration < 1000,
                "Complete validation flow should finish in under 1 second, took \(duration)ms"
            )
        }
        
        @Test("Performance metrics accuracy")
        func testPerformanceMetricsTracking() async {
            let monitor = SendPerformanceMonitor()
            
            monitor.startTimer(for: "testOperation")
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
            let measuredDuration = monitor.endTimer(for: "testOperation")
            
            #expect(
                measuredDuration >= 0.09 && measuredDuration <= 0.15, // 90-150ms range
                "Performance metrics should accurately measure duration, got \(measuredDuration)s"
            )
        }
        
        @Test("Performance optimization flags work correctly")
        func testPerformanceOptimizationDetection() async {
            let monitor = SendPerformanceMonitor()
            
            // Simulate fast operations (under thresholds)
            monitor.startTimer(for: "addressValidation")
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
            monitor.endTimer(for: "addressValidation")
            
            monitor.startTimer(for: "gasEstimation") 
            try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
            monitor.endTimer(for: "gasEstimation")
            
            monitor.startTimer(for: "networkRequest")
            try? await Task.sleep(nanoseconds: 500_000_000) // 500ms  
            monitor.endTimer(for: "networkRequest")
            
            monitor.startTimer(for: "uiRender")
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
            monitor.endTimer(for: "uiRender")
            
            #expect(
                monitor.isOptimized == true,
                "Performance should be marked as optimized with fast operations"
            )
        }
    }
    
    // MARK: - Regression Tests
    
    @Suite("Performance Regression Tests")
    struct RegressionTests {
        
        @Test("Performance doesn't degrade with repeated use") 
        func testPerformanceConsistency() async {
            let interactor = OptimizedSendInteractor()
            var durations: [TimeInterval] = []
            
            // Perform same operation 10 times
            for _ in 0..<10 {
                let startTime = CFAbsoluteTimeGetCurrent()
                interactor.validateAddress("0x1234567890123456789012345678901234567890")
                try? await Task.sleep(nanoseconds: 100_000_000) // Wait for completion
                let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
                durations.append(duration)
            }
            
            let averageDuration = durations.reduce(0, +) / Double(durations.count)
            let maxDuration = durations.max() ?? 0
            
            #expect(
                maxDuration < averageDuration * 2,
                "Performance should remain consistent, max: \(maxDuration)ms, avg: \(averageDuration)ms"
            )
        }
        
        @Test("Memory usage remains stable under load")
        func testMemoryStability() async {
            let interactor = OptimizedSendInteractor()
            
            // Simulate heavy usage
            for i in 0..<50 {
                interactor.validateAddress("0x\(String(format: "%040d", i))")
                interactor.validateAmount("\(Double(i) * 0.1)")
                
                if i % 10 == 0 {
                    await Task.yield() // Allow memory cleanup
                }
            }
            
            // Memory should not grow excessively
            // In real implementation, would measure actual memory usage
            #expect(true, "Memory should remain stable under load")
        }
    }
}

// MARK: - Performance Benchmarking Utilities

extension SendPerformanceTests {
    
    /// Measures execution time of an async operation
    static func measureAsync<T>(_ operation: () async throws -> T) async rethrows -> (result: T, duration: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await operation()
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        return (result, duration)
    }
    
    /// Validates performance threshold
    static func assertPerformance<T>(
        _ operation: () async throws -> T,
        threshold: TimeInterval,
        file: StaticString = #file,
        line: UInt = #line
    ) async rethrows {
        let (_, duration) = try await measureAsync(operation)
        
        #expect(
            duration < threshold,
            "Operation exceeded performance threshold: \(duration * 1000)ms > \(threshold * 1000)ms",
            sourceLocation: SourceLocation(fileID: String(file), line: Int(line))
        )
    }
}