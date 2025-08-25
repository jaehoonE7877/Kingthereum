import Foundation
import KeychainAccess
import Core

/// 키체인 저장소 관리를 위한 프로토콜
/// 암호화된 데이터의 안전한 저장과 검색을 제공
public protocol KeychainManagerProtocol: Sendable {
    /// 키체인에 값을 저장
    /// - Parameters:
    ///   - key: 저장할 키
    ///   - value: 저장할 값
    /// - Throws: 키체인 저장 오류
    func store(key: String, value: String) async throws
    
    /// 키체인에서 값을 검색
    /// - Parameter key: 검색할 키
    /// - Returns: 저장된 값 (없으면 nil)
    /// - Throws: 키체인 검색 오류
    func retrieve(key: String) async throws -> String?
    
    /// 키체인에서 특정 키를 삭제
    /// - Parameter key: 삭제할 키
    /// - Throws: 키체인 삭제 오류
    func delete(key: String) async throws
    
    /// 키체인의 모든 데이터를 삭제
    /// - Throws: 키체인 삭제 오류
    func deleteAll() async throws
    
    // 지갑 전용 메서드들
    /// 개인키를 키체인에 저장
    /// - Parameter privateKey: 저장할 개인키
    /// - Throws: 키체인 저장 오류
    func storePrivateKey(_ privateKey: String) async throws
    
    /// 키체인에서 개인키를 검색
    /// - Returns: 저장된 개인키 (없으면 nil)
    /// - Throws: 키체인 검색 오류
    func retrievePrivateKey() async throws -> String?
    
    /// 키체인에서 개인키를 삭제
    /// - Throws: 키체인 삭제 오류
    func deletePrivateKey() async throws
    
    
    /// 지갑 주소를 키체인에 저장
    /// - Parameter address: 저장할 지갑 주소
    /// - Throws: 키체인 저장 오류
    func storeWalletAddress(_ address: String) async throws
    
    /// 키체인에서 지갑 주소를 검색
    /// - Returns: 저장된 지갑 주소 (없으면 nil)
    /// - Throws: 키체인 검색 오류
    func retrieveWalletAddress() async throws -> String?
    
    /// 키체인에서 지갑 주소를 삭제
    /// - Throws: 키체인 삭제 오류
    func deleteWalletAddress() async throws
    
    /// PIN을 키체인에 저장
    /// - Parameter pin: 저장할 PIN
    /// - Throws: 키체인 저장 오류
    func storePIN(_ pin: String) async throws
    
    /// 키체인에서 PIN을 검색
    /// - Returns: 저장된 PIN (없으면 nil)
    /// - Throws: 키체인 검색 오류
    func retrievePIN() async throws -> String?
    
    /// 키체인에서 PIN을 삭제
    /// - Throws: 키체인 삭제 오류
    func deletePIN() async throws
}

/// KeychainAccess 라이브러리를 사용한 키체인 관리자
/// 암호화된 데이터의 안전한 저장과 검색을 제공
/// Actor로 구현하여 동시 접근 시 데이터 무결성을 보장
public actor KeychainManager: KeychainManagerProtocol {
    
    private let keychain: Keychain
    
    /// KeychainManager 초기화
    /// 기기가 잠금 해제된 상태에서만 접근 가능하도록 설정
    public init() {
        self.keychain = Keychain(service: Constants.Keychain.serviceIdentifier)
            .accessibility(.whenUnlockedThisDeviceOnly)
    }
    
    /// 키체인에 값을 저장
    public func store(key: String, value: String) async throws {
        try keychain.set(value, key: key)
    }
    
    /// 키체인에서 값을 검색
    public func retrieve(key: String) async throws -> String? {
        return try keychain.get(key)
    }
    
    /// 키체인에서 특정 키를 삭제
    public func delete(key: String) async throws {
        try keychain.remove(key)
    }
    
    /// 키체인의 모든 데이터를 삭제
    public func deleteAll() async throws {
        try keychain.removeAll()
    }
}

// MARK: - 지갑 전용 메서드들
public extension KeychainManager {
    
    /// 개인키를 키체인에 저장
    func storePrivateKey(_ privateKey: String) async throws {
        try await store(key: Constants.Keychain.privateKeyKey, value: privateKey)
    }
    
    /// 개인키를 키체인에 저장 (Data 형태)
    func savePrivateKey(_ privateKeyData: Data, for address: String) async throws {
        let hexString = privateKeyData.toHexString()
        try keychain.set(hexString, key: "\(Constants.Keychain.privateKeyKey)_\(address)")
    }
    
    /// 특정 주소의 개인키를 키체인에서 검색 (Data 형태)
    func getPrivateKey(for address: String) async throws -> Data? {
        guard let hexString = try keychain.get("\(Constants.Keychain.privateKeyKey)_\(address)") else {
            return nil
        }
        return Data(hex: hexString)
    }
    
    /// 키체인에서 개인키를 검색
    func retrievePrivateKey() async throws -> String? {
        return try await retrieve(key: Constants.Keychain.privateKeyKey)
    }
    
    /// 키체인에서 개인키를 삭제
    func deletePrivateKey() async throws {
        try await delete(key: Constants.Keychain.privateKeyKey)
    }
    
    
    /// PIN을 키체인에 저장
    func storePIN(_ pin: String) async throws {
        try await store(key: Constants.Keychain.pinKey, value: pin)
    }
    
    /// 키체인에서 PIN을 검색
    func retrievePIN() async throws -> String? {
        return try await retrieve(key: Constants.Keychain.pinKey)
    }
    
    /// 키체인에서 PIN을 삭제
    func deletePIN() async throws {
        try await delete(key: Constants.Keychain.pinKey)
    }
    
    /// 지갑 주소를 키체인에 저장
    func storeWalletAddress(_ address: String) async throws {
        try await store(key: Constants.Keychain.walletAddressKey, value: address)
    }
    
    /// 키체인에서 지갑 주소를 검색
    func retrieveWalletAddress() async throws -> String? {
        return try await retrieve(key: Constants.Keychain.walletAddressKey)
    }
    
    /// 키체인에서 지갑 주소를 삭제
    func deleteWalletAddress() async throws {
        try await delete(key: Constants.Keychain.walletAddressKey)
    }
}
