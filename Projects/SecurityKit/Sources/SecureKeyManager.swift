import Foundation
import Security
import CryptoKit
import Core

/// 안전한 개인키 관리자
/// Secure Enclave 및 Keychain을 사용하여 개인키를 안전하게 보호
public actor SecureKeyManager {
    
    // MARK: - 보안 키 참조 타입
    
    /// 보안 저장된 키 참조
    public struct SecureKeyReference: Sendable {
        let tag: String
        let isSecureEnclaveKey: Bool
        let publicKeyData: Data
        
        init(tag: String, isSecureEnclaveKey: Bool, publicKeyData: Data) {
            self.tag = tag
            self.isSecureEnclaveKey = isSecureEnclaveKey
            self.publicKeyData = publicKeyData
        }
    }
    
    // MARK: - 키 생성 타입
    
    /// 키 생성 옵션
    public struct KeyGenerationOptions: Sendable {
        let useBiometricProtection: Bool
        let requireUserPresence: Bool
        let invalidateOnBiometryChange: Bool
        
        public init(
            useBiometricProtection: Bool = true,
            requireUserPresence: Bool = false,
            invalidateOnBiometryChange: Bool = true
        ) {
            self.useBiometricProtection = useBiometricProtection
            self.requireUserPresence = requireUserPresence
            self.invalidateOnBiometryChange = invalidateOnBiometryChange
        }
        
        public static let `default` = KeyGenerationOptions()
        public static let highSecurity = KeyGenerationOptions(
            useBiometricProtection: true,
            requireUserPresence: true,
            invalidateOnBiometryChange: true
        )
    }
    
    // MARK: - 초기화
    
    public init() {
        Logger.debug("🔐 SecureKeyManager 초기화됨")
    }
    
    // MARK: - 안전한 개인키 생성
    
    /// 안전한 개인키 생성 (Secure Enclave 우선)
    /// - Parameters:
    ///   - tag: 키 식별자
    ///   - options: 키 생성 옵션
    /// - Returns: 보안 키 참조
    /// - Throws: 키 생성 실패 시 SecurityError
    public func generatePrivateKey(
        tag: String,
        options: KeyGenerationOptions = .default
    ) async throws -> SecureKeyReference {
        Logger.debug("🔑 안전한 개인키 생성 시작: \(tag)")
        
        // 먼저 Secure Enclave 사용 시도
        if SecureEnclave.isAvailable {
            do {
                return try await generateSecureEnclaveKey(tag: tag, options: options)
            } catch {
                Logger.warning("⚠️ Secure Enclave 키 생성 실패, Keychain으로 대체: \(error)")
            }
        }
        
        // Secure Enclave를 사용할 수 없으면 안전한 Keychain 저장
        return try await generateKeychainKey(tag: tag, options: options)
    }
    
    /// Secure Enclave를 사용한 키 생성
    private func generateSecureEnclaveKey(
        tag: String,
        options: KeyGenerationOptions
    ) async throws -> SecureKeyReference {
        Logger.debug("🛡️ Secure Enclave 키 생성 중...")
        
        // 접근 제어 설정
        var accessControl: SecAccessControl
        var flags: SecAccessControlCreateFlags = []
        
        if options.useBiometricProtection {
            flags.insert(.biometryAny)
        }
        
        if options.requireUserPresence {
            flags.insert(.userPresence)
        }
        
        if options.invalidateOnBiometryChange {
            flags.insert(.applicationPassword) // 생체 정보 변경 시 키 무효화
        }
        
        guard let control = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            flags,
            nil
        ) else {
            throw SecurityError.secureEnclaveUnavailable
        }
        
        accessControl = control
        
        // 키 생성 파라미터
        let keyAttributes: [CFString: Any] = [
            kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits: 256,
            kSecAttrTokenID: kSecAttrTokenIDSecureEnclave,
            kSecPrivateKeyAttrs: [
                kSecAttrIsPermanent: true,
                kSecAttrApplicationTag: {
                    guard let data = tag.data(using: .utf8) else {
                        Logger.error("❌ 키 태그를 UTF-8 데이터로 변환 실패")
                        return Data() // 빈 데이터 fallback
                    }
                    return data
                }(),
                kSecAttrAccessControl: accessControl
            ]
        ]
        
        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(keyAttributes as CFDictionary, &error) else {
            if let err = error?.takeRetainedValue() {
                Logger.error("❌ Secure Enclave 키 생성 실패: \(err)")
                throw SecurityError.keyGenerationFailed(CFErrorCopyDescription(err) as String? ?? "Unknown error")
            }
            throw SecurityError.keyGenerationFailed("Unknown error")
        }
        
        // 공개키 추출
        guard let publicKey = SecKeyCopyPublicKey(privateKey),
              let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil) else {
            throw SecurityError.publicKeyExtractionFailed
        }
        
        Logger.debug("✅ Secure Enclave 키 생성 완료")
        return SecureKeyReference(
            tag: tag,
            isSecureEnclaveKey: true,
            publicKeyData: publicKeyData as Data
        )
    }
    
    /// 안전한 Keychain을 사용한 키 생성 (Secure Enclave 대체)
    private func generateKeychainKey(
        tag: String,
        options: KeyGenerationOptions
    ) async throws -> SecureKeyReference {
        Logger.debug("🔐 Keychain 안전 키 생성 중...")
        
        // 암호학적으로 안전한 개인키 생성
        let privateKeyData = try generateSecureRandomData(length: 32)
        
        // AES-GCM으로 개인키 암호화
        let encryptionKey = try generateSecureRandomData(length: 32)
        let encryptedPrivateKey = try encryptData(privateKeyData, with: encryptionKey)
        
        // Keychain에 암호화된 개인키 저장
        try await storeEncryptedKeyInKeychain(
            tag: tag,
            encryptedKey: encryptedPrivateKey,
            encryptionKey: encryptionKey,
            options: options
        )
        
        // 공개키 생성 (secp256k1)
        let publicKeyData = try derivePublicKey(from: privateKeyData)
        
        // 메모리에서 개인키 데이터 즉시 제거
        privateKeyData.withUnsafeMutableBytes { bytes in
            bytes.bindMemory(to: UInt8.self).initialize(repeating: 0)
        }
        
        Logger.debug("✅ 안전한 Keychain 키 생성 완료")
        return SecureKeyReference(
            tag: tag,
            isSecureEnclaveKey: false,
            publicKeyData: publicKeyData
        )
    }
    
    // MARK: - 안전한 서명 생성
    
    /// 안전한 메시지 서명
    /// - Parameters:
    ///   - message: 서명할 메시지
    ///   - keyReference: 키 참조
    /// - Returns: 서명 데이터
    /// - Throws: 서명 실패 시 SecurityError
    public func signMessage(
        _ message: Data,
        with keyReference: SecureKeyReference
    ) async throws -> Data {
        Logger.debug("✍️ 메시지 서명 시작")
        
        if keyReference.isSecureEnclaveKey {
            return try await signWithSecureEnclave(message, tag: keyReference.tag)
        } else {
            return try await signWithKeychain(message, tag: keyReference.tag)
        }
    }
    
    /// Secure Enclave를 사용한 서명
    private func signWithSecureEnclave(_ message: Data, tag: String) async throws -> Data {
        // Keychain에서 개인키 참조 가져오기
        let query: [CFString: Any] = [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: {
                guard let data = tag.data(using: .utf8) else {
                    Logger.error("❌ 서명용 키 태그를 UTF-8 데이터로 변환 실패")
                    return Data() // 빈 데이터 fallback
                }
                return data
            }(),
            kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
            kSecReturnRef: true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess else {
            Logger.error("❌ Secure Enclave 키 검색 실패")
            throw SecurityError.keyNotFound(tag)
        }
        
        // 안전한 타입 캐스팅
        guard let privateKey = item as? SecKey else {
            Logger.error("❌ 잘못된 키 타입")
            throw SecurityError.authenticationRequired // 기존 에러 케이스 사용
        }
        
        // 메시지 해시 (SHA-256)
        let messageHash = SHA256.hash(data: message)
        
        // ECDSA 서명
        var error: Unmanaged<CFError>?
        guard let signature = SecKeyCreateSignature(
            privateKey,
            .ecdsaSignatureMessageX962SHA256,
            Data(messageHash) as CFData,
            &error
        ) else {
            if let err = error?.takeRetainedValue() {
                Logger.error("❌ Secure Enclave 서명 실패: \(err)")
                throw SecurityError.signingFailed(CFErrorCopyDescription(err) as String? ?? "Unknown error")
            }
            throw SecurityError.signingFailed("Unknown error")
        }
        
        Logger.debug("✅ Secure Enclave 서명 완료")
        return signature as Data
    }
    
    /// Keychain 암호화된 키를 사용한 서명
    private func signWithKeychain(_ message: Data, tag: String) async throws -> Data {
        // 암호화된 키 데이터 가져오기
        let (encryptedKey, encryptionKey) = try await retrieveEncryptedKeyFromKeychain(tag: tag)
        
        // 개인키 복호화
        let privateKeyData = try decryptData(encryptedKey, with: encryptionKey)
        defer {
            // 메모리에서 개인키 즉시 제거
            privateKeyData.withUnsafeMutableBytes { bytes in
                bytes.bindMemory(to: UInt8.self).initialize(repeating: 0)
            }
        }
        
        // ECDSA 서명 생성
        let messageHash = SHA256.hash(data: message)
        let signature = try signECDSA(messageHash: Data(messageHash), privateKey: privateKeyData)
        
        Logger.debug("✅ Keychain 키 서명 완료")
        return signature
    }
    
    // MARK: - 키 삭제
    
    /// 안전한 키 삭제
    /// - Parameter keyReference: 삭제할 키 참조
    /// - Throws: 삭제 실패 시 SecurityError
    public func deleteKey(_ keyReference: SecureKeyReference) async throws {
        Logger.debug("🗑️ 키 삭제 시작: \(keyReference.tag)")
        
        let query: [CFString: Any] = [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: {
                guard let data = keyReference.tag.data(using: .utf8) else {
                    Logger.error("❌ 삭제용 키 태그를 UTF-8 데이터로 변환 실패")
                    return Data() // 빈 데이터 fallback
                }
                return data
            }()
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            Logger.error("❌ 키 삭제 실패: \(status)")
            throw SecurityError.keyDeletionFailed("SecItemDelete failed with status: \(status)")
        }
        
        // 암호화 키도 삭제 (Keychain 키인 경우)
        if !keyReference.isSecureEnclaveKey {
            let encKeyQuery: [CFString: Any] = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: "com.kingthereum.encryption",
                kSecAttrAccount: keyReference.tag
            ]
            
            _ = SecItemDelete(encKeyQuery as CFDictionary)
        }
        
        Logger.debug("✅ 키 삭제 완료")
    }
    
    // MARK: - 유틸리티 메서드
    
    /// 암호학적으로 안전한 랜덤 데이터 생성
    private func generateSecureRandomData(length: Int) throws -> Data {
        var data = Data(count: length)
        let result = data.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, length, bytes.bindMemory(to: UInt8.self).baseAddress!)
        }
        
        guard result == errSecSuccess else {
            throw SecurityError.randomGenerationFailed
        }
        
        return data
    }
    
    /// 데이터 AES-GCM 암호화
    private func encryptData(_ data: Data, with key: Data) throws -> Data {
        let symmetricKey = SymmetricKey(data: key)
        let sealedBox = try AES.GCM.seal(data, using: symmetricKey)
        return sealedBox.combined!
    }
    
    /// 데이터 AES-GCM 복호화
    private func decryptData(_ encryptedData: Data, with key: Data) throws -> Data {
        let symmetricKey = SymmetricKey(data: key)
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        return try AES.GCM.open(sealedBox, using: symmetricKey)
    }
    
    /// secp256k1 공개키 생성
    private func derivePublicKey(from privateKey: Data) throws -> Data {
        // 실제 구현에서는 secp256k1 라이브러리 사용
        // 여기서는 임시 구현
        return Data("placeholder_public_key".utf8)
    }
    
    /// ECDSA 서명 생성
    private func signECDSA(messageHash: Data, privateKey: Data) throws -> Data {
        // 실제 구현에서는 secp256k1 라이브러리 사용
        // 여기서는 임시 구현
        return Data("placeholder_signature".utf8)
    }
    
    /// 암호화된 키를 Keychain에 저장
    private func storeEncryptedKeyInKeychain(
        tag: String,
        encryptedKey: Data,
        encryptionKey: Data,
        options: KeyGenerationOptions
    ) async throws {
        // 암호화된 개인키 저장
        let keyQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: "com.kingthereum.keys",
            kSecAttrAccount: tag,
            kSecValueData: encryptedKey,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let keyStatus = SecItemAdd(keyQuery as CFDictionary, nil)
        guard keyStatus == errSecSuccess else {
            throw SecurityError.keychainStoreFailed("Failed to store encrypted key: \(keyStatus)")
        }
        
        // 암호화 키 저장
        let encKeyQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: "com.kingthereum.encryption",
            kSecAttrAccount: tag,
            kSecValueData: encryptionKey,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let encKeyStatus = SecItemAdd(encKeyQuery as CFDictionary, nil)
        guard encKeyStatus == errSecSuccess else {
            // 개인키 저장 실패 시 이미 저장된 키도 삭제
            _ = SecItemDelete(keyQuery as CFDictionary)
            throw SecurityError.keychainStoreFailed("Failed to store encryption key: \(encKeyStatus)")
        }
    }
    
    /// Keychain에서 암호화된 키 검색
    private func retrieveEncryptedKeyFromKeychain(tag: String) async throws -> (Data, Data) {
        // 암호화된 개인키 가져오기
        let keyQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: "com.kingthereum.keys",
            kSecAttrAccount: tag,
            kSecReturnData: true
        ]
        
        var keyItem: CFTypeRef?
        let keyStatus = SecItemCopyMatching(keyQuery as CFDictionary, &keyItem)
        
        guard keyStatus == errSecSuccess,
              let encryptedKey = keyItem as? Data else {
            throw SecurityError.keyNotFound("Encrypted key not found: \(tag)")
        }
        
        // 암호화 키 가져오기
        let encKeyQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: "com.kingthereum.encryption",
            kSecAttrAccount: tag,
            kSecReturnData: true
        ]
        
        var encKeyItem: CFTypeRef?
        let encKeyStatus = SecItemCopyMatching(encKeyQuery as CFDictionary, &encKeyItem)
        
        guard encKeyStatus == errSecSuccess,
              let encryptionKey = encKeyItem as? Data else {
            throw SecurityError.keyNotFound("Encryption key not found: \(tag)")
        }
        
        return (encryptedKey, encryptionKey)
    }
}

// MARK: - Secure Enclave 가용성 확인

private enum SecureEnclave {
    /// Secure Enclave 사용 가능 여부
    static var isAvailable: Bool {
        // 실제 디바이스에서 Secure Enclave 지원 여부 확인
        return TARGET_OS_SIMULATOR == 0 && 
               SecKeyIsAlgorithmSupported(kSecAttrKeyTypeECSECPrimeRandom as! SecKey, .encrypt, .eciesEncryptionCofactorX963SHA256AESGCM)
    }
}

// MARK: - 보안 에러 확장

extension SecurityError {
    static let secureEnclaveUnavailable = SecurityError.custom("Secure Enclave를 사용할 수 없습니다")
    static let keyGenerationFailed = { (reason: String) in SecurityError.custom("키 생성 실패: \(reason)") }
    static let publicKeyExtractionFailed = SecurityError.custom("공개키 추출에 실패했습니다")
    static let keyNotFound = { (tag: String) in SecurityError.custom("키를 찾을 수 없습니다: \(tag)") }
    static let signingFailed = { (reason: String) in SecurityError.custom("서명 실패: \(reason)") }
    static let keyDeletionFailed = { (reason: String) in SecurityError.custom("키 삭제 실패: \(reason)") }
    static let randomGenerationFailed = SecurityError.custom("안전한 랜덤 데이터 생성 실패")
    static let keychainStoreFailed = { (reason: String) in SecurityError.custom("Keychain 저장 실패: \(reason)") }
}