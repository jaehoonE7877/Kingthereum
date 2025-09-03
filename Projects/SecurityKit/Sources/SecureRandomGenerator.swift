import Foundation
import Security
import CryptoKit

/// Cryptographically secure random data generator
/// Uses SecRandomCopyBytes and CryptoKit for secure random generation
public actor SecureRandomGenerator {
    
    /// Generate cryptographically secure random bytes
    /// - Parameter length: Number of bytes to generate
    /// - Returns: Secure random data
    /// - Throws: SecureRandomError if generation fails
    public static func generateSecureRandomBytes(length: Int) throws -> Data {
        var bytes = Data(count: length)
        let result = bytes.withUnsafeMutableBytes { pointer in
            SecRandomCopyBytes(kSecRandomDefault, length, pointer.bindMemory(to: UInt8.self).baseAddress!)
        }
        
        guard result == errSecSuccess else {
            Logger.error("🔴 SecRandomCopyBytes failed with status: \(result)")
            throw SecureRandomError.randomGenerationFailed
        }
        
        return bytes
    }
    
    /// Generate a cryptographically secure random string
    /// - Parameter length: Length of the string (default: 32)
    /// - Returns: Secure random hex string
    /// - Throws: SecureRandomError if generation fails
    public static func generateSecureRandomString(length: Int = 32) throws -> String {
        let randomData = try generateSecureRandomBytes(length: length)
        return randomData.map { String(format: "%02x", $0) }.joined()
    }
    
    /// Generate a secure password for keystore encryption
    /// Uses 256 bits (32 bytes) of entropy for maximum security
    /// - Returns: Secure password string
    /// - Throws: SecureRandomError if generation fails
    public static func generateSecurePassword() throws -> String {
        // Generate 256 bits (32 bytes) of cryptographically secure random data
        let randomData = try generateSecureRandomBytes(length: 32)
        
        // Convert to base64 for safe string representation
        let password = randomData.base64EncodedString()
        
        Logger.debug("✅ Generated secure password with 256-bit entropy")
        return password
    }
    
    /// Generate secure salt for additional encryption
    /// - Returns: 128-bit secure salt
    /// - Throws: SecureRandomError if generation fails
    public static func generateSalt() throws -> Data {
        return try generateSecureRandomBytes(length: 16) // 128 bits
    }
}

/// Errors related to secure random generation
public enum SecureRandomError: LocalizedError, Sendable {
    case randomGenerationFailed
    case insufficientEntropy
    case secureEnclaveNotAvailable
    
    public var errorDescription: String? {
        switch self {
        case .randomGenerationFailed:
            return "Secure random generation failed"
        case .insufficientEntropy:
            return "Insufficient entropy for secure random generation"
        case .secureEnclaveNotAvailable:
            return "Secure Enclave is not available on this device"
        }
    }
}