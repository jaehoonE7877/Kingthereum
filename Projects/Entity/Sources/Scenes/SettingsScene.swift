import Foundation

public enum SettingsScene {
    
    // MARK: - Load Settings
    
    public enum LoadSettings {
        public struct Request {
            public let userId: String
            
            public init(userId: String) {
                self.userId = userId
            }
        }
        
        public struct Response {
            public let settings: UserSettings
            public let error: Error?
            
            public init(settings: UserSettings, error: Error? = nil) {
                self.settings = settings
                self.error = error
            }
        }
        
        public struct ViewModel {
            public let displayMode: String
            public let fontSize: String
            public let notificationEnabled: Bool
            public let securityMode: String
            public let network: String
            public let currency: String
            public let language: String
            public let profileData: ProfileData
            public let errorMessage: String?
            
            public init(
                displayMode: String,
                fontSize: String,
                notificationEnabled: Bool,
                securityMode: String,
                network: String,
                currency: String,
                language: String,
                profileData: ProfileData,
                errorMessage: String? = nil
            ) {
                self.displayMode = displayMode
                self.fontSize = fontSize
                self.notificationEnabled = notificationEnabled
                self.securityMode = securityMode
                self.network = network
                self.currency = currency
                self.language = language
                self.profileData = profileData
                self.errorMessage = errorMessage
            }
        }
    }
    
    // MARK: - Update Display Mode
    
    public enum UpdateDisplayMode {
        public struct Request {
            public let displayMode: DisplayModeType
            
            public init(displayMode: DisplayModeType) {
                self.displayMode = displayMode
            }
        }
        
        public struct Response {
            public let success: Bool
            public let displayMode: DisplayModeType
            public let error: Error?
            
            public init(success: Bool, displayMode: DisplayModeType, error: Error? = nil) {
                self.success = success
                self.displayMode = displayMode
                self.error = error
            }
        }
        
        public struct ViewModel {
            public let displayMode: String
            public let successMessage: String?
            public let errorMessage: String?
            
            public init(
                displayMode: String,
                successMessage: String? = nil,
                errorMessage: String? = nil
            ) {
                self.displayMode = displayMode
                self.successMessage = successMessage
                self.errorMessage = errorMessage
            }
        }
    }
    
    // MARK: - Update Notification
    
    public enum UpdateNotification {
        public struct Request {
            public let enabled: Bool
            
            public init(enabled: Bool) {
                self.enabled = enabled
            }
        }
        
        public struct Response {
            public let success: Bool
            public let enabled: Bool
            public let error: Error?
            
            public init(success: Bool, enabled: Bool, error: Error? = nil) {
                self.success = success
                self.enabled = enabled
                self.error = error
            }
        }
        
        public struct ViewModel {
            public let enabled: Bool
            public let statusText: String
            public let successMessage: String?
            public let errorMessage: String?
            
            public init(
                enabled: Bool,
                statusText: String,
                successMessage: String? = nil,
                errorMessage: String? = nil
            ) {
                self.enabled = enabled
                self.statusText = statusText
                self.successMessage = successMessage
                self.errorMessage = errorMessage
            }
        }
    }
    
    // MARK: - Update Security
    
    public enum UpdateSecurity {
        public struct Request {
            public let securityType: SecurityType
            
            public init(securityType: SecurityType) {
                self.securityType = securityType
            }
        }
        
        public struct Response {
            public let success: Bool
            public let securityType: SecurityType
            public let error: Error?
            
            public init(success: Bool, securityType: SecurityType, error: Error? = nil) {
                self.success = success
                self.securityType = securityType
                self.error = error
            }
        }
        
        public struct ViewModel {
            public let securityMode: String
            public let successMessage: String?
            public let errorMessage: String?
            
            public init(
                securityMode: String,
                successMessage: String? = nil,
                errorMessage: String? = nil
            ) {
                self.securityMode = securityMode
                self.successMessage = successMessage
                self.errorMessage = errorMessage
            }
        }
    }
    
    // MARK: - Update Network
    
    public enum UpdateNetwork {
        public struct Request {
            public let networkType: NetworkType
            
            public init(networkType: NetworkType) {
                self.networkType = networkType
            }
        }
        
        public struct Response {
            public let success: Bool
            public let networkType: NetworkType
            public let error: Error?
            
            public init(success: Bool, networkType: NetworkType, error: Error? = nil) {
                self.success = success
                self.networkType = networkType
                self.error = error
            }
        }
        
        public struct ViewModel {
            public let network: String
            public let successMessage: String?
            public let errorMessage: String?
            
            public init(
                network: String,
                successMessage: String? = nil,
                errorMessage: String? = nil
            ) {
                self.network = network
                self.successMessage = successMessage
                self.errorMessage = errorMessage
            }
        }
    }
    
    // MARK: - Load Profile
    
    public enum LoadProfile {
        public struct Request {
            public let walletAddress: String
            
            public init(walletAddress: String) {
                self.walletAddress = walletAddress
            }
        }
        
        public struct Response {
            public let profile: WalletProfile
            public let error: Error?
            
            public init(profile: WalletProfile, error: Error? = nil) {
                self.profile = profile
                self.error = error
            }
        }
        
        public struct ViewModel {
            public let profileData: ProfileData
            public let errorMessage: String?
            
            public init(profileData: ProfileData, errorMessage: String? = nil) {
                self.profileData = profileData
                self.errorMessage = errorMessage
            }
        }
    }
}

// MARK: - Supporting Types

public enum DisplayModeType: String, CaseIterable, Sendable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    public var displayName: String {
        switch self {
        case .system: return "시스템"
        case .light: return "라이트"
        case .dark: return "다크"
        }
    }
}

public enum SecurityType: String, CaseIterable, Sendable {
    case none = "none"
    case pin = "pin"
    case faceID = "faceID"
    case touchID = "touchID"
    
    public var displayName: String {
        switch self {
        case .none: return "없음"
        case .pin: return "PIN"
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        }
    }
}

public enum NetworkType: String, CaseIterable, Sendable {
    case mainnet = "mainnet"
    case sepolia = "sepolia"
    case goerli = "goerli"
    case localhost = "localhost"
    
    public var displayName: String {
        switch self {
        case .mainnet: return "메인넷"
        case .sepolia: return "세폴리아 테스트넷"
        case .goerli: return "괴를리 테스트넷"
        case .localhost: return "로컬호스트"
        }
    }
}

public enum FontSizeType: String, CaseIterable, Sendable {
    case small = "small"
    case medium = "medium"
    case large = "large"
    
    public var displayName: String {
        switch self {
        case .small: return "작게"
        case .medium: return "기본"
        case .large: return "크게"
        }
    }
}

public enum LanguageType: String, CaseIterable, Sendable {
    case korean = "ko"
    case english = "en"
    
    public var displayName: String {
        switch self {
        case .korean: return "한국어"
        case .english: return "English"
        }
    }
}

public enum CurrencyType: String, CaseIterable, Sendable {
    case usd = "USD"
    case krw = "KRW"
    case eur = "EUR"
    case jpy = "JPY"
    
    public var displayName: String {
        return rawValue
    }
}

public struct UserSettings: Sendable {
    public let displayMode: DisplayModeType
    public let fontSize: FontSizeType
    public let notificationEnabled: Bool
    public let securityType: SecurityType
    public let networkType: NetworkType
    public let currency: CurrencyType
    public let language: LanguageType
    
    public init(
        displayMode: DisplayModeType,
        fontSize: FontSizeType,
        notificationEnabled: Bool,
        securityType: SecurityType,
        networkType: NetworkType,
        currency: CurrencyType,
        language: LanguageType
    ) {
        self.displayMode = displayMode
        self.fontSize = fontSize
        self.notificationEnabled = notificationEnabled
        self.securityType = securityType
        self.networkType = networkType
        self.currency = currency
        self.language = language
    }
}

public struct WalletProfile: Sendable {
    public let name: String
    public let address: String
    public let balance: Decimal
    public let avatarURL: URL?
    
    public init(name: String, address: String, balance: Decimal, avatarURL: URL? = nil) {
        self.name = name
        self.address = address
        self.balance = balance
        self.avatarURL = avatarURL
    }
}

public struct ProfileData: Sendable {
    public let displayName: String
    public let formattedAddress: String
    public let avatarInitials: String
    
    public init(displayName: String, formattedAddress: String, avatarInitials: String) {
        self.displayName = displayName
        self.formattedAddress = formattedAddress
        self.avatarInitials = avatarInitials
    }
}