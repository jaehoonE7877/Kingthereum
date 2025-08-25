import Foundation
import Entity
import Core
import SecurityKit


protocol SettingsWorkerProtocol: Sendable {
    func loadUserSettings(userId: String) async throws -> UserSettings
    func updateDisplayMode(mode: DisplayModeType) async throws
    func updateNotificationSetting(enabled: Bool) async throws
    func updateSecuritySetting(securityType: SecurityType) async throws
    func updateNetworkSetting(networkType: Entity.NetworkType) async throws
    func loadWalletProfile(address: String?) async throws -> WalletProfile
}

actor SettingsWorker: SettingsWorkerProtocol {
    private let userDefaults: UserDefaults
    private let keychain: KeychainManagerProtocol
    
    init(userDefaults: UserDefaults = UserDefaults.standard, keychain: KeychainManagerProtocol = KeychainManager()) {
        self.userDefaults = userDefaults
        self.keychain = keychain
    }
    
    func loadUserSettings(userId: String) async throws -> UserSettings {
        // UserDefaults에서 설정 값들 로드
        let displayModeRaw = userDefaults.string(forKey: "displayMode") ?? DisplayModeType.system.rawValue
        let displayMode = DisplayModeType(rawValue: displayModeRaw) ?? .system
        
        let fontSizeRaw = userDefaults.string(forKey: "fontSize") ?? FontSizeType.medium.rawValue
        let fontSize = FontSizeType(rawValue: fontSizeRaw) ?? .medium
        
        let notificationEnabled = userDefaults.bool(forKey: "notificationEnabled")
        
        let securityTypeRaw = userDefaults.string(forKey: "securityType") ?? SecurityType.none.rawValue
        let securityType = SecurityType(rawValue: securityTypeRaw) ?? .none
        
        let networkTypeRaw = userDefaults.string(forKey: "networkType") ?? Entity.NetworkType.mainnet.rawValue
        let networkType = Entity.NetworkType(rawValue: networkTypeRaw) ?? .mainnet
        
        let currencyRaw = userDefaults.string(forKey: "currency") ?? Entity.CurrencyType.usd.rawValue
        let currency = Entity.CurrencyType(rawValue: currencyRaw) ?? .usd
        
        let languageRaw = userDefaults.string(forKey: "language") ?? Entity.LanguageType.korean.rawValue
        let language = Entity.LanguageType(rawValue: languageRaw) ?? .korean
        
        return UserSettings(
            displayMode: displayMode,
            fontSize: fontSize,
            notificationEnabled: notificationEnabled,
            securityType: securityType,
            networkType: networkType,
            currency: currency,
            language: language
        )
    }
    
    func updateDisplayMode(mode: DisplayModeType) async throws {
        userDefaults.set(mode.rawValue, forKey: "displayMode")
        
        // 시스템에 변경 사항 반영
        await MainActor.run {
            NotificationCenter.default.post(
                name: NSNotification.Name("DisplayModeChanged"),
                object: mode
            )
        }
        
        Logger.info("Display mode updated to: \(mode.displayName)")
    }
    
    func updateNotificationSetting(enabled: Bool) async throws {
        userDefaults.set(enabled, forKey: "notificationEnabled")
        
        if enabled {
            // 알림 권한 요청
            await requestNotificationPermission()
        } else {
            // 알림 비활성화 처리
            await disableNotifications()
        }
        
        Logger.info("Notification setting updated to: \(enabled)")
    }
    
    func updateSecuritySetting(securityType: SecurityType) async throws {
        // 현재 보안 설정 검증
        if securityType == .faceID {
            let isAvailable = await isFaceIDAvailable()
            if !isAvailable {
                throw SettingsError.faceIDNotAvailable
            }
        }
        
        if securityType == .touchID {
            let isAvailable = await isTouchIDAvailable()
            if !isAvailable {
                throw SettingsError.touchIDNotAvailable
            }
        }
        
        // 보안 설정 저장
        userDefaults.set(securityType.rawValue, forKey: "securityType")
        
        // Keychain에 보안 타입 저장
        try await keychain.store(key: "securityType", value: securityType.rawValue)
        
        Logger.info("Security setting updated to: \(securityType.displayName)")
    }
    
    func updateNetworkSetting(networkType: Entity.NetworkType) async throws {
        userDefaults.set(networkType.rawValue, forKey: "networkType")
        
        // 네트워크 변경 알림
        await MainActor.run {
            NotificationCenter.default.post(
                name: NSNotification.Name("NetworkChanged"),
                object: networkType
            )
        }
        
        Logger.info("Network setting updated to: \(networkType.displayName)")
    }
    
    func loadWalletProfile(address: String? = nil) async throws -> WalletProfile {
        let walletAddress = address ?? userDefaults.string(forKey: Constants.UserDefaults.selectedWalletAddress) ?? ""
        
        guard !walletAddress.isEmpty else {
            throw SettingsError.walletAddressNotFound
        }
        
        // 지갑 이름 로드 (UserDefaults 또는 Keychain에서)
        let walletName = userDefaults.string(forKey: "walletName") ?? "Kingthereum Wallet"
        
        // 잔고 정보는 실제 구현에서 Web3 서비스에서 가져와야 함
        let balance: Decimal = 0.0
        
        return WalletProfile(
            name: walletName,
            address: walletAddress,
            balance: balance,
            avatarURL: nil
        )
    }
    
    // MARK: - Private Methods
    
    private func requestNotificationPermission() async {
        // UNUserNotificationCenter를 통한 알림 권한 요청
        // 실제 구현에서는 UNUserNotificationCenter 사용
        Logger.info("Requesting notification permission")
    }
    
    private func disableNotifications() async {
        // 알림 비활성화 처리
        Logger.info("Disabling notifications")
    }
    
    private func isFaceIDAvailable() async -> Bool {
        // LAContext를 사용하여 Face ID 사용 가능 여부 확인
        // 실제 구현에서는 LocalAuthentication 프레임워크 사용
        return true
    }
    
    private func isTouchIDAvailable() async -> Bool {
        // LAContext를 사용하여 Touch ID 사용 가능 여부 확인
        // 실제 구현에서는 LocalAuthentication 프레임워크 사용
        return true
    }
}

// MARK: - Settings Errors

enum SettingsError: LocalizedError {
    case walletAddressNotFound
    case faceIDNotAvailable
    case touchIDNotAvailable
    case networkConnectionFailed
    case invalidSettings
    
    var errorDescription: String? {
        switch self {
        case .walletAddressNotFound:
            return "지갑 주소를 찾을 수 없습니다"
        case .faceIDNotAvailable:
            return "Face ID를 사용할 수 없습니다"
        case .touchIDNotAvailable:
            return "Touch ID를 사용할 수 없습니다"
        case .networkConnectionFailed:
            return "네트워크 연결에 실패했습니다"
        case .invalidSettings:
            return "잘못된 설정 값입니다"
        }
    }
}