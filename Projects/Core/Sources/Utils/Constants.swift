import Foundation

/// 전역에서 사용되는 상수들을 정의한 열거형
public enum Constants {
    
    /// 키체인 저장소 관련 상수
    public enum Keychain {
        public static let serviceIdentifier = "com.kingtherum.wallet"
        public static let privateKeyKey = "private_key"
        public static let pinKey = "pin"
        public static let walletAddressKey = "wallet_address"
    }
    
    /// UserDefaults 저장소 관련 상수
    public enum UserDefaults {
        public static let hasCompletedOnboarding = "has_completed_onboarding"
        public static let selectedWalletAddress = "selected_wallet_address"
        public static let isFirstLaunch = "is_first_launch"
        public static let biometricAuthEnabled = "biometric_auth_enabled"
        public static let selectedNetworkChainId = "selected_network_chain_id"
    }
    
    /// UI 디자인 관련 상수
    public enum UI {
        public static let cornerRadius: CGFloat = 16.0
        public static let padding: CGFloat = 16.0
        public static let smallPadding: CGFloat = 8.0
        public static let largePadding: CGFloat = 24.0
        public static let buttonHeight: CGFloat = 50.0
        public static let animationDuration: Double = 0.3
    }
    
    
    /// 디버그 및 로깅 관련 상수
    public enum Debug {
        #if DEBUG
        public static let isLoggingEnabled = true
        #else
        public static let isLoggingEnabled = false
        #endif
    }
}