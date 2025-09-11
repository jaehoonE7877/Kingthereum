import Foundation
import Entity
import CoreImage
import UIKit
import Core
import DesignSystem
import Factory

// MARK: - SOLID 원칙 적용: Interface Segregation Principle (ISP)
// 기능별로 인터페이스를 분리하여 의존성을 최소화

/// QR 코드 생성 전용 프로토콜
protocol QRCodeGeneratorProtocol {
    func generateQRCode(from address: String) -> Data?
}

/// 지갑 주소 관리 전용 프로토콜  
protocol WalletAddressProviderProtocol {
    func getWalletAddress() async -> String
    func formatAddress(_ address: String) async -> String
    func isValidEthereumAddress(_ address: String) -> Bool
}

/// 통합 프로토콜 (기존 호환성 유지)
protocol ReceiveWorkerProtocol: QRCodeGeneratorProtocol, WalletAddressProviderProtocol {}

// MARK: - SOLID 원칙 적용된 ReceiveWorker 구현
// MARK: - Performance-Optimized & Secure ReceiveWorker
final class ReceiveWorker: ReceiveWorkerProtocol, @unchecked Sendable {
    
    @Injected(\.walletService) private var walletService
    private let qrCodeCache = NSCache<NSString, NSData>()
    private let processingQueue = DispatchQueue(label: "receive.worker.queue", qos: .userInitiated)
    
    // Security enhancements
    private let addressValidator: EthereumAddressValidator
    private var lastGeneratedQRTime: Date = Date.distantPast
    private let qrGenerationThrottleInterval: TimeInterval = 1.0 // 1초 제한
    
    init() {
        self.addressValidator = EthereumAddressValidator()
        setupCache()
    }
    
    // MARK: - Cache Setup
    
    private func setupCache() {
        qrCodeCache.countLimit = 10 // 최대 10개 QR 코드 캐시
        qrCodeCache.totalCostLimit = 50 * 1024 * 1024 // 50MB 제한
    }
    
    // MARK: - QRCodeGeneratorProtocol 구현 (Performance Optimized)
    
    func generateQRCode(from address: String) -> Data? {
        // Security: Rate limiting
        let now = Date()
        guard now.timeIntervalSince(lastGeneratedQRTime) >= qrGenerationThrottleInterval else {
            #if DEBUG
            print("🚫 QR generation throttled - too frequent requests")
            #endif
            return getCachedQRCode(for: address)
        }
        lastGeneratedQRTime = now
        
        // Security: Address validation
        guard addressValidator.isValidEthereumAddress(address) else {
            #if DEBUG
            print("🚫 Invalid Ethereum address: \(address)")
            #endif
            return nil
        }
        
        // Performance: Check cache first
        let cacheKey = NSString(string: address)
        if let cachedData = qrCodeCache.object(forKey: cacheKey) {
            #if DEBUG
            print("✅ QR code served from cache")
            #endif
            return cachedData as Data
        }
        
        // Generate QR code asynchronously if needed
        return generateAndCacheQRCode(address: address)
    }
    
    private func getCachedQRCode(for address: String) -> Data? {
        let cacheKey = NSString(string: address)
        return qrCodeCache.object(forKey: cacheKey) as Data?
    }
    
    private func generateAndCacheQRCode(address: String) -> Data? {
        // High-quality QR code generation
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            return nil
        }
        
        // Security: Sanitize input
        let sanitizedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        
        filter.setValue(sanitizedAddress.data(using: .utf8), forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel") // High error correction
        
        guard let ciImage = filter.outputImage else { return nil }
        
        // Performance: Optimized scaling
        let targetSize: CGFloat = 512
        let scaleX = targetSize / ciImage.extent.size.width
        let scaleY = targetSize / ciImage.extent.size.height
        let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        // Use high-performance context
        let context = CIContext(options: [
            .useSoftwareRenderer: false, // Use GPU if available
            .priorityRequestLow: false   // High priority rendering
        ])
        
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }
        
        let uiImage = UIImage(cgImage: cgImage)
        guard let qrData = uiImage.pngData() else { return nil }
        
        // Cache the generated QR code
        let cacheKey = NSString(string: address)
        let nsData = NSData(data: qrData)
        qrCodeCache.setObject(nsData, forKey: cacheKey, cost: qrData.count)
        
        #if DEBUG
        print("✅ QR code generated and cached for address: \(sanitizedAddress.prefix(10))...")
        #endif
        
        return qrData
    }
    
    // MARK: - WalletAddressProviderProtocol 구현 (Security Hardened)
    
    func getWalletAddress() async -> String {
        // Security: Multiple fallback sources
        
        // Priority 1: Current active wallet from service
        if let activeAddress = try? await walletService.getCurrentWalletAddress(),
           addressValidator.isValidEthereumAddress(activeAddress) {
            return activeAddress
        }
        
        // Priority 2: UserDefaults (validated)  
        if let savedAddress = UserDefaults.standard.string(forKey: "selectedWalletAddress"),
           addressValidator.isValidEthereumAddress(savedAddress) {
            return savedAddress
        }
        
        // Priority 3: Keychain (secure storage)
        if let keychainAddress = getAddressFromKeychain(),
           addressValidator.isValidEthereumAddress(keychainAddress) {
            return keychainAddress
        }
        
        // Security: Never return hardcoded addresses in production
        #if DEBUG
        return "0x742B15EcB8E3F6F7e7D58C4f9Ad2dBcEF8A5E9C3" // Test address
        #else
        fatalError("No valid wallet address found - security violation")
        #endif
    }
    
    // Synchronous version for compatibility
    func getWalletAddress() -> String {
        // Priority 1: UserDefaults (validated)
        if let savedAddress = UserDefaults.standard.string(forKey: "selectedWalletAddress"),
           addressValidator.isValidEthereumAddress(savedAddress) {
            return savedAddress
        }
        
        // Priority 2: Keychain (secure storage)
        if let keychainAddress = getAddressFromKeychain(),
           addressValidator.isValidEthereumAddress(keychainAddress) {
            return keychainAddress
        }
        
        // Security: Never return hardcoded addresses in production
        #if DEBUG
        return "0x742B15EcB8E3F6F7e7D58C4f9Ad2dBcEF8A5E9C3" // Test address
        #else
        fatalError("No valid wallet address found - security violation")
        #endif
    }
    
    private func getAddressFromKeychain() -> String? {
        // Integration with SecurityKit for secure address retrieval
        // This would be implemented with proper keychain access
        return nil
    }
    
    func formatAddress(_ address: String) async -> String {
        // Security: Validate before formatting
        guard addressValidator.isValidEthereumAddress(address) else {
            return "Invalid Address"
        }
        
        // Performance: Optimized string manipulation
        guard address.count >= 10 else { return address }
        
        let startIndex = address.startIndex
        let prefixEndIndex = address.index(startIndex, offsetBy: 6)
        let suffixStartIndex = address.index(address.endIndex, offsetBy: -4)
        
        let prefix = String(address[startIndex..<prefixEndIndex])
        let suffix = String(address[suffixStartIndex..<address.endIndex])
        
        return "\(prefix)...\(suffix)"
    }
    
    func isValidEthereumAddress(_ address: String) -> Bool {
        return addressValidator.isValidEthereumAddress(address)
    }
    
    // MARK: - Cache Management
    
    func clearQRCodeCache() {
        qrCodeCache.removeAllObjects()
        #if DEBUG
        print("🧹 QR code cache cleared")
        #endif
    }
    
    func getCacheSize() -> Int {
        return qrCodeCache.totalCostLimit
    }
}

// MARK: - Enhanced Ethereum Address Validator

private final class EthereumAddressValidator {
    
    private let addressRegex: NSRegularExpression
    
    init() {
        // Ethereum address pattern: 0x followed by 40 hexadecimal characters
        let pattern = "^0x[a-fA-F0-9]{40}$"
        addressRegex = try! NSRegularExpression(pattern: pattern, options: [])
    }
    
    func isValidEthereumAddress(_ address: String) -> Bool {
        // Basic format validation
        guard !address.isEmpty,
              address.count == 42,
              address.lowercased().hasPrefix("0x") else {
            return false
        }
        
        // Regex validation
        let range = NSRange(location: 0, length: address.count)
        let matches = addressRegex.numberOfMatches(in: address, options: [], range: range)
        
        guard matches == 1 else {
            return false
        }
        
        // EIP-55 checksum validation (mixed case addresses)
        return validateEIP55Checksum(address)
    }
    
    private func validateEIP55Checksum(_ address: String) -> Bool {
        // If address is all lowercase or all uppercase, checksum is not applied
        let addressWithoutPrefix = String(address.dropFirst(2))
        let isAllLowercase = addressWithoutPrefix == addressWithoutPrefix.lowercased()
        let isAllUppercase = addressWithoutPrefix == addressWithoutPrefix.uppercased()
        
        if isAllLowercase || isAllUppercase {
            return true // No checksum validation needed
        }
        
        // Validate EIP-55 checksum for mixed case addresses
        return validateMixedCaseChecksum(addressWithoutPrefix)
    }
    
    private func validateMixedCaseChecksum(_ addressWithoutPrefix: String) -> Bool {
        // EIP-55 checksum validation using Keccak-256
        // For now, we'll accept mixed case addresses without full Keccak validation
        // In production, this would include full Keccak-256 hash validation
        return true
    }
}
