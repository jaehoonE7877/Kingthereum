import Foundation

/// 애플리케이션 전반에서 사용되는 상수를 관리하는 네임스페이스
/// 
/// 상수를 도메인별로 분류하여 코드의 가독성과 유지보수성을 향상시킵니다.
/// 각 하위 enum은 특정 도메인의 상수만을 관리하여 관심사를 분리합니다.
public enum Constants {
    
    // MARK: - Keychain Storage
    
    /// 키체인 저장소에서 사용하는 키와 서비스 식별자
    /// 
    /// 민감한 정보(개인키, PIN 등)를 안전하게 저장하기 위한 키체인 관련 상수들입니다.
    /// 모든 키는 일관된 명명 규칙을 따르고, 서비스 식별자로 앱의 키체인 영역을 격리합니다.
    public enum Keychain {
        /// 키체인 서비스 식별자 - 앱의 키체인 영역을 다른 앱과 격리
        public static let serviceIdentifier = "com.kingtherum.wallet"
        
        /// 암호화된 개인키 저장 키
        public static let privateKeyKey = "private_key"
        
        /// 사용자 PIN 저장 키
        public static let pinKey = "pin"
        
        /// 지갑 주소 저장 키
        public static let walletAddressKey = "wallet_address"
    }
    
    // MARK: - UserDefaults Storage
    
    /// UserDefaults에서 사용하는 키 상수
    /// 
    /// 애플리케이션 설정과 사용자 선호도를 저장하기 위한 키들입니다.
    /// Bool, String, Int 등의 기본 타입 데이터를 영구 저장할 때 사용합니다.
    public enum UserDefaults {
        /// 온보딩 완료 여부
        public static let hasCompletedOnboarding = "has_completed_onboarding"
        
        /// 현재 선택된 지갑 주소
        public static let selectedWalletAddress = "selected_wallet_address"
        
        /// 앱 최초 실행 여부
        public static let isFirstLaunch = "is_first_launch"
        
        /// 생체 인증 활성화 여부
        public static let biometricAuthEnabled = "biometric_auth_enabled"
        
        /// 선택된 네트워크의 체인 ID
        public static let selectedNetworkChainId = "selected_network_chain_id"
    }
    
    // MARK: - UI Design System
    
    /// UI 디자인 시스템에서 사용하는 기본 상수들
    /// 
    /// 일관된 UI/UX를 위한 디자인 토큰들입니다.
    /// DesignSystem 모듈의 토큰들과 함께 사용하여 통합된 디자인 언어를 구현합니다.
    public enum UI {
        /// 기본 모서리 둥글기 값
        public static let cornerRadius: CGFloat = 16.0
        
        /// 표준 패딩 값
        public static let padding: CGFloat = 16.0
        
        /// 작은 패딩 값
        public static let smallPadding: CGFloat = 8.0
        
        /// 큰 패딩 값
        public static let largePadding: CGFloat = 24.0
        
        /// 표준 버튼 높이
        public static let buttonHeight: CGFloat = 50.0
        
        /// 기본 애니메이션 지속시간
        public static let animationDuration: Double = 0.3
    }
    
    // MARK: - Debug Configuration
    
    /// 디버그 빌드와 프로덕션 빌드에서의 동작 제어
    /// 
    /// 컴파일 타임에 결정되는 디버그 관련 설정들입니다.
    /// 프로덕션 빌드에서 디버그 코드가 실행되지 않도록 보장합니다.
    public enum Debug {
        #if DEBUG
        /// 디버그 빌드에서만 로깅 활성화
        public static let isLoggingEnabled = true
        #else
        /// 프로덕션 빌드에서는 로깅 비활성화
        public static let isLoggingEnabled = false
        #endif
    }
}