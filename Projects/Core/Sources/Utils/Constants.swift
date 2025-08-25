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
    
    /// Web3 및 블록체인 관련 상수
    public enum Web3 {
        public static let defaultGasLimit = "21000"
        public static let defaultGasPrice = "20000000000" // 20 Gwei
        public static let ethDecimals = 18
    }
    
    /// 에러 메시지 관련 상수
    public enum Errors {
        public static let unknownError = "알 수 없는 오류가 발생했습니다"
        public static let networkError = "네트워크 연결 오류"
        public static let invalidAddress = "잘못된 이더리움 주소"
        public static let insufficientFunds = "잔액이 부족합니다"
        public static let transactionFailed = "거래가 실패했습니다"
        public static let biometricNotAvailable = "생체인증을 사용할 수 없습니다"
        public static let biometricNotEnrolled = "등록된 생체 데이터가 없습니다"
        public static let authenticationFailed = "인증에 실패했습니다"
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