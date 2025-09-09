import Foundation
import Security
import Core
import Entity

/// 지갑 주소 안전 관리자
/// UserDefaults 대신 Keychain을 사용하여 지갑 주소를 안전하게 저장
public actor WalletAddressManager {
    
    // MARK: - 키체인 서비스 식별자
    
    private enum KeychainService {
        static let walletAddresses = "com.kingthereum.wallet.addresses"
        static let selectedWallet = "com.kingthereum.wallet.selected"
    }
    
    // MARK: - 키체인 계정 키
    
    private enum KeychainAccount {
        static let selectedWalletAddress = "selected_wallet_address"
        static let walletList = "wallet_list"
    }
    
    // MARK: - 초기화
    
    public init() {
        Logger.debug("📱 WalletAddressManager 초기화됨")
    }
    
    // MARK: - 선택된 지갑 주소 관리
    
    /// 현재 선택된 지갑 주소 저장
    /// - Parameter address: 저장할 지갑 주소
    /// - Throws: 키체인 저장 실패 시 SecurityError
    public func setSelectedWalletAddress(_ address: String) async throws {
        Logger.debug("💾 선택된 지갑 주소 저장: \(address.prefix(6))...")
        
        try await storeStringInKeychain(
            service: KeychainService.selectedWallet,
            account: KeychainAccount.selectedWalletAddress,
            value: address
        )
        
        Logger.debug("✅ 선택된 지갑 주소 저장 완료")
    }
    
    /// 현재 선택된 지갑 주소 조회
    /// - Returns: 선택된 지갑 주소 (없으면 nil)
    /// - Throws: 키체인 접근 실패 시 SecurityError
    public func getSelectedWalletAddress() async throws -> String? {
        Logger.debug("📥 선택된 지갑 주소 조회 중...")
        
        let address = try await retrieveStringFromKeychain(
            service: KeychainService.selectedWallet,
            account: KeychainAccount.selectedWalletAddress
        )
        
        if let address = address {
            Logger.debug("✅ 선택된 지갑 주소 조회 완료: \(address.prefix(6))...")
        } else {
            Logger.debug("ℹ️ 선택된 지갑 주소가 없음")
        }
        
        return address
    }
    
    /// 선택된 지갑 주소 삭제
    /// - Throws: 키체인 삭제 실패 시 SecurityError
    public func removeSelectedWalletAddress() async throws {
        Logger.debug("🗑️ 선택된 지갑 주소 삭제 중...")
        
        try await deleteFromKeychain(
            service: KeychainService.selectedWallet,
            account: KeychainAccount.selectedWalletAddress
        )
        
        Logger.debug("✅ 선택된 지갑 주소 삭제 완료")
    }
    
    // MARK: - 지갑 목록 관리
    
    /// 지갑 주소 목록 저장
    /// - Parameter addresses: 저장할 지갑 주소 목록
    /// - Throws: 키체인 저장 실패 시 SecurityError
    public func setWalletAddressList(_ addresses: [String]) async throws {
        Logger.debug("📋 지갑 주소 목록 저장 중: \(addresses.count)개")
        
        // JSON으로 인코딩
        let jsonData = try JSONEncoder().encode(addresses)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw Entity.SecurityError.encryptionFailed
        }
        
        try await storeStringInKeychain(
            service: KeychainService.walletAddresses,
            account: KeychainAccount.walletList,
            value: jsonString
        )
        
        Logger.debug("✅ 지갑 주소 목록 저장 완료")
    }
    
    /// 지갑 주소 목록 조회
    /// - Returns: 저장된 지갑 주소 목록
    /// - Throws: 키체인 접근 실패 시 SecurityError
    public func getWalletAddressList() async throws -> [String] {
        Logger.debug("📋 지갑 주소 목록 조회 중...")
        
        guard let jsonString = try await retrieveStringFromKeychain(
            service: KeychainService.walletAddresses,
            account: KeychainAccount.walletList
        ) else {
            Logger.debug("ℹ️ 저장된 지갑 주소 목록이 없음")
            return []
        }
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw Entity.SecurityError.decryptionFailed
        }
        
        let addresses = try JSONDecoder().decode([String].self, from: jsonData)
        Logger.debug("✅ 지갑 주소 목록 조회 완료: \(addresses.count)개")
        
        return addresses
    }
    
    /// 지갑 주소를 목록에 추가
    /// - Parameter address: 추가할 지갑 주소
    /// - Throws: 키체인 작업 실패 시 SecurityError
    public func addWalletAddress(_ address: String) async throws {
        Logger.debug("➕ 지갑 주소 목록에 추가: \(address.prefix(6))...")
        
        var addresses = try await getWalletAddressList()
        
        // 중복 방지
        if !addresses.contains(address) {
            addresses.append(address)
            try await setWalletAddressList(addresses)
            Logger.debug("✅ 지갑 주소 추가 완료")
        } else {
            Logger.debug("ℹ️ 이미 존재하는 지갑 주소")
        }
    }
    
    /// 지갑 주소를 목록에서 제거
    /// - Parameter address: 제거할 지갑 주소
    /// - Throws: 키체인 작업 실패 시 SecurityError
    public func removeWalletAddress(_ address: String) async throws {
        Logger.debug("➖ 지갑 주소 목록에서 제거: \(address.prefix(6))...")
        
        var addresses = try await getWalletAddressList()
        addresses.removeAll { $0 == address }
        
        try await setWalletAddressList(addresses)
        
        // 제거된 주소가 현재 선택된 주소라면 선택도 해제
        if let selectedAddress = try await getSelectedWalletAddress(),
           selectedAddress == address {
            try await removeSelectedWalletAddress()
            Logger.debug("ℹ️ 선택된 지갑도 함께 해제됨")
        }
        
        Logger.debug("✅ 지갑 주소 제거 완료")
    }
    
    // MARK: - 편의 메서드
    
    /// 현재 선택된 지갑이 있는지 확인
    /// - Returns: 선택된 지갑 존재 여부
    public func hasSelectedWallet() async -> Bool {
        do {
            let address = try await getSelectedWalletAddress()
            return address != nil
        } catch {
            Logger.error("❌ 선택된 지갑 확인 중 오류: \(error)")
            return false
        }
    }
    
    /// 저장된 지갑이 있는지 확인
    /// - Returns: 저장된 지갑 존재 여부
    public func hasStoredWallets() async -> Bool {
        do {
            let addresses = try await getWalletAddressList()
            return !addresses.isEmpty
        } catch {
            Logger.error("❌ 저장된 지갑 확인 중 오류: \(error)")
            return false
        }
    }
    
    /// 모든 지갑 데이터 삭제 (초기화)
    /// - Throws: 키체인 삭제 실패 시 SecurityError
    public func clearAllWalletData() async throws {
        Logger.debug("🧹 모든 지갑 데이터 삭제 중...")
        
        // 선택된 지갑 주소 삭제
        do {
            try await removeSelectedWalletAddress()
        } catch {
            // 선택된 지갑이 없는 경우는 정상
            Logger.debug("ℹ️ 선택된 지갑 주소가 없음")
        }
        
        // 지갑 목록 삭제
        try await deleteFromKeychain(
            service: KeychainService.walletAddresses,
            account: KeychainAccount.walletList
        )
        
        Logger.debug("✅ 모든 지갑 데이터 삭제 완료")
    }
    
    // MARK: - 키체인 유틸리티 메서드
    
    /// 키체인에 문자열 저장
    private func storeStringInKeychain(
        service: String,
        account: String,
        value: String
    ) async throws {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecValueData: {
                guard let data = value.data(using: .utf8) else {
                    Logger.error("❌ 문자열을 UTF-8 데이터로 변환 실패")
                    return Data() // 빈 데이터 반환
                }
                return data
            }(),
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // 기존 항목 삭제 후 새로 추가
        _ = SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            Logger.error("❌ 키체인 저장 실패: \(status)")
            throw Entity.SecurityError.keychainAccessFailed
        }
    }
    
    /// 키체인에서 문자열 조회
    private func retrieveStringFromKeychain(
        service: String,
        account: String
    ) async throws -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil // 항목이 없는 것은 정상
            }
            Logger.error("❌ 키체인 조회 실패: \(status)")
            throw Entity.SecurityError.keychainAccessFailed
        }
        
        guard let data = item as? Data,
              let string = String(data: data, encoding: .utf8) else {
            throw Entity.SecurityError.decryptionFailed
        }
        
        return string
    }
    
    /// 키체인에서 항목 삭제
    private func deleteFromKeychain(
        service: String,
        account: String
    ) async throws {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            Logger.error("❌ 키체인 삭제 실패: \(status)")
            throw Entity.SecurityError.keychainAccessFailed
        }
    }
}