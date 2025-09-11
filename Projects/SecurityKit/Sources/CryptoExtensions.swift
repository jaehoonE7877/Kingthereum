import Foundation
import CryptoSwift

// MARK: - CryptoSwift Extensions for Production Security

extension Data: @unchecked Sendable {
    /// 16진수 문자열에서 Data 생성
    init?(hex: String) {
        let cleanHex = hex.hasPrefix("0x") ? String(hex.dropFirst(2)) : hex
        guard cleanHex.count % 2 == 0 else { return nil }
        
        var data = Data()
        var index = cleanHex.startIndex
        
        while index < cleanHex.endIndex {
            let nextIndex = cleanHex.index(index, offsetBy: 2)
            let byteString = String(cleanHex[index..<nextIndex])
            
            guard let byte = UInt8(byteString, radix: 16) else { return nil }
            data.append(byte)
            index = nextIndex
        }
        
        self = data
    }
}

extension Array: @unchecked Sendable where Element == UInt8 {
    /// UInt8 배열을 16진수 문자열로 변환
    func toHexString() -> String {
        return self.map { String(format: "%02x", $0) }.joined()
    }
}

extension Character {
    /// 16진수 문자인지 확인
    var isHexDigit: Bool {
        return self.isASCII && (self.isNumber || ("a"..."f").contains(self.lowercased().first!))
    }
}

// MARK: - Advanced Cryptographic Operations

/// 프로덕션급 암호화 유틸리티
public struct ProductionCrypto: Sendable {
    
    // MARK: - PBKDF2 Key Derivation
    
    /// PBKDF2를 사용한 키 유도 (PIN 해싱용)
    /// - Parameters:
    ///   - password: 원본 비밀번호
    ///   - salt: 솔트 데이터
    ///   - iterations: 반복 횟수 (최소 100,000 권장)
    ///   - keyLength: 결과 키 길이
    /// - Returns: 유도된 키
    public static func pbkdf2(password: String, salt: Data, iterations: Int = 100_000, keyLength: Int = 32) throws -> Data {
        guard let passwordData = password.data(using: .utf8) else {
            throw CryptoError.invalidInput
        }
        
        let derivedKey = try PKCS5.PBKDF2(
            password: Array(passwordData),
            salt: Array(salt),
            iterations: iterations,
            keyLength: keyLength,
            variant: .sha2(.sha256)
        ).calculate()
        
        return Data(derivedKey)
    }
    
    // MARK: - AES-GCM Encryption
    
    /// AES-256-GCM 암호화
    /// - Parameters:
    ///   - data: 암호화할 데이터
    ///   - key: 256비트 암호화 키
    ///   - additionalData: 추가 인증 데이터 (선택사항)
    /// - Returns: 암호화된 데이터와 인증 태그
    public static func encryptAESGCM(data: Data, key: Data, additionalData: Data? = nil) throws -> EncryptedData {
        guard key.count == 32 else { // 256비트
            throw CryptoError.invalidKeySize
        }
        
        // 랜덤 IV 생성 (96비트)
        let iv = secureRandomBytes(count: 12)
        
        let additionalBytes = additionalData != nil ? Array(additionalData!) : nil
        let gcm = GCM(iv: iv, additionalAuthenticatedData: additionalBytes)
        let aes = try AES(key: Array(key), blockMode: gcm, padding: .noPadding)
        let encrypted = try aes.encrypt(Array(data))
        
        // GCM 모드에서 인증 태그 추출
        guard let authTag = gcm.authenticationTag else {
            throw CryptoError.encryptionFailed
        }
        
        return EncryptedData(
            ciphertext: Data(encrypted),
            iv: Data(iv),
            authTag: Data(authTag)
        )
    }
    
    /// AES-256-GCM 복호화
    /// - Parameters:
    ///   - encryptedData: 암호화된 데이터 또는 결합된 데이터
    ///   - key: 256비트 복호화 키
    ///   - additionalData: 추가 인증 데이터 (선택사항)
    /// - Returns: 복호화된 원본 데이터
    public static func decryptAESGCM(encryptedData: Data, key: Data, additionalData: Data? = nil) throws -> Data {
        guard key.count == 32 else {
            throw CryptoError.invalidKeySize
        }
        
        // 결합된 데이터에서 EncryptedData 구조 추출
        guard let structuredData = EncryptedData(combined: encryptedData) else {
            throw CryptoError.decryptionFailed
        }
        
        let gcm = GCM(
            iv: Array(structuredData.iv),
            authenticationTag: Array(structuredData.authTag),
            additionalAuthenticatedData: additionalData != nil ? Array(additionalData!) : nil
        )
        let aes = try AES(key: Array(key), blockMode: gcm, padding: .noPadding)
        
        let decrypted = try aes.decrypt(Array(structuredData.ciphertext))
        return Data(decrypted)
    }
    
    // MARK: - HMAC
    
    /// HMAC-SHA256 생성
    /// - Parameters:
    ///   - data: 해시할 데이터
    ///   - key: HMAC 키
    /// - Returns: HMAC 결과
    public static func generateHMAC(data: Data, key: Data) throws -> Data {
        let hmac = try HMAC(key: Array(key), variant: .sha2(.sha256)).authenticate(Array(data))
        return Data(hmac)
    }
    
    // MARK: - Secure Random Generation
    
    /// 암호학적으로 안전한 랜덤 바이트 생성
    /// - Parameter count: 생성할 바이트 수
    /// - Returns: 랜덤 바이트 배열
    private static func secureRandomBytes(count: Int) -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: count)
        let status = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
        
        guard status == errSecSuccess else {
            // Fallback to CryptoSwift random
            return AES.randomIV(count)
        }
        
        return bytes
    }
    
    /// 암호학적으로 안전한 랜덤 데이터 생성
    /// - Parameter length: 생성할 데이터 길이
    /// - Returns: 랜덤 데이터
    public static func secureRandomData(length: Int) -> Data {
        return Data(secureRandomBytes(count: length))
    }
    
    // MARK: - Constant Time Comparison
    
    /// 타이밍 공격 방지를 위한 상수 시간 비교
    /// - Parameters:
    ///   - lhs: 첫 번째 데이터
    ///   - rhs: 두 번째 데이터
    /// - Returns: 데이터가 같으면 true
    public static func constantTimeCompare(_ lhs: Data, _ rhs: Data) -> Bool {
        guard lhs.count == rhs.count else { return false }
        
        var result: UInt8 = 0
        for i in 0..<lhs.count {
            result |= lhs[i] ^ rhs[i]
        }
        
        return result == 0
    }
    
    /// 문자열에 대한 상수 시간 비교
    /// - Parameters:
    ///   - lhs: 첫 번째 문자열
    ///   - rhs: 두 번째 문자열
    /// - Returns: 문자열이 같으면 true
    public static func constantTimeCompare(_ lhs: String, _ rhs: String) -> Bool {
        guard let lhsData = lhs.data(using: .utf8),
              let rhsData = rhs.data(using: .utf8) else {
            return false
        }
        
        return constantTimeCompare(lhsData, rhsData)
    }
    
    // MARK: - Hash Functions
    
    /// SHA-256 해시
    public static func sha256(_ data: Data) -> Data {
        return Data(SHA2(variant: .sha256).calculate(for: Array(data)))
    }
    
    /// SHA-3 (Keccak-256) 해시 - 이더리움 호환
    public static func keccak256(_ data: Data) -> Data {
        return Data(SHA3(variant: .keccak256).calculate(for: Array(data)))
    }
    
    /// HMAC-SHA256 (별칭)
    public static func hmacSHA256(data: Data, key: Data) throws -> Data {
        return try generateHMAC(data: data, key: key)
    }
}

// MARK: - Supporting Types

/// 암호화된 데이터 구조체
public struct EncryptedData: Codable, Sendable {
    public let ciphertext: Data
    public let iv: Data
    public let authTag: Data
    
    public init(ciphertext: Data, iv: Data, authTag: Data) {
        self.ciphertext = ciphertext
        self.iv = iv
        self.authTag = authTag
    }
    
    /// 전체 암호화 데이터를 하나의 Data로 결합
    public var combined: Data {
        var result = Data()
        result.append(UInt32(iv.count).bigEndian.data) // IV 길이 (4바이트)
        result.append(iv)
        result.append(UInt32(authTag.count).bigEndian.data) // 인증 태그 길이 (4바이트)
        result.append(authTag)
        result.append(ciphertext)
        return result
    }
    
    /// 결합된 Data에서 EncryptedData 생성
    public init?(combined: Data) {
        guard combined.count >= 8 else { return nil } // 최소 길이 확인
        
        var offset = 0
        
        // IV 길이 읽기
        let ivLengthData = combined.subdata(in: offset..<offset+4)
        let ivLength = Int(UInt32(bigEndian: ivLengthData.withUnsafeBytes { $0.load(as: UInt32.self) }))
        offset += 4
        
        guard combined.count >= offset + ivLength + 4 else { return nil }
        
        // IV 읽기
        let iv = combined.subdata(in: offset..<offset+ivLength)
        offset += ivLength
        
        // 인증 태그 길이 읽기
        let authTagLengthData = combined.subdata(in: offset..<offset+4)
        let authTagLength = Int(UInt32(bigEndian: authTagLengthData.withUnsafeBytes { $0.load(as: UInt32.self) }))
        offset += 4
        
        guard combined.count >= offset + authTagLength else { return nil }
        
        // 인증 태그 읽기
        let authTag = combined.subdata(in: offset..<offset+authTagLength)
        offset += authTagLength
        
        // 암호문 읽기
        let ciphertext = combined.subdata(in: offset..<combined.count)
        
        self.init(ciphertext: ciphertext, iv: iv, authTag: authTag)
    }
}

/// 암호화 관련 오류
public enum CryptoError: LocalizedError, Sendable {
    case invalidInput
    case invalidKeySize
    case encryptionFailed
    case decryptionFailed
    case keyDerivationFailed
    case randomGenerationFailed
    
    public var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "잘못된 입력 데이터입니다"
        case .invalidKeySize:
            return "키 크기가 올바르지 않습니다"
        case .encryptionFailed:
            return "암호화에 실패했습니다"
        case .decryptionFailed:
            return "복호화에 실패했습니다"
        case .keyDerivationFailed:
            return "키 유도에 실패했습니다"
        case .randomGenerationFailed:
            return "랜덤 데이터 생성에 실패했습니다"
        }
    }
}

// MARK: - Extensions

extension UInt32: @unchecked Sendable {
    var data: Data {
        var value = self
        return Data(bytes: &value, count: MemoryLayout<UInt32>.size)
    }
}

extension Data {
    var uint32: UInt32 {
        return self.withUnsafeBytes { $0.load(as: UInt32.self) }
    }
}
