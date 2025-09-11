import Foundation
import Factory
import Entity
// MARK: - SecurityKit Services Factory Registration

/// SecurityKit 모듈의 보안 서비스들을 Factory 방식으로 등록
/// 
/// 프로덕션 수준의 보안 서비스들을 의존성 주입 패턴으로 관리합니다.
/// Swift Concurrency 환경에서 안전하게 작동하며, 보안 서비스 간의 의존 관계를 적절히 처리합니다.
/// 
/// ## 등록된 서비스:
/// - BiometricAuthManager: Face ID, Touch ID, Optic ID 생체 인증 관리
/// - PINManager: PBKDF2 기반 PIN 암호화/검증 관리 (은행급 보안)
/// - KeychainManager: AES-256-GCM 키체인 암호화 관리 (다중 계층 보안)
/// - SecurityService: 통합 보안 서비스 (인증, 암호화, 보안 검증)
/// 
/// ## 보안 설계 원칙:
/// - 방어 깊이: 다중 계층 보안 (생체인증 + PIN + 암호화)
/// - 최소 권한: 필요한 권한만 부여
/// - 실패 시 안전: 보안 실패 시 안전한 상태로 복구
/// - 감사 로깅: 모든 보안 이벤트 추적
public extension Container {
    
    // MARK: - Core Security Components
    
    /// 생체 인증 관리자 (Face ID, Touch ID, Optic ID)
    /// 
    /// ## 주요 기능:
    /// - 생체 인증 가용성 검사
    /// - 안전한 생체 인증 수행
    /// - 생체 인증 타입 식별
    /// - 생체 인증 실패 처리
    /// 
    /// - Returns: BiometricAuthManagerProtocol을 준수하는 서비스 인스턴스
    var biometricAuthManager: Factory<any BiometricAuthManagerProtocol> {
        self { BiometricAuthManager() as any BiometricAuthManagerProtocol }
            .singleton
    }
    
    /// PIN 관리자 (PBKDF2 기반 암호화)
    /// 
    /// ## 보안 특징:
    /// - PBKDF2-HMAC-SHA256 (100,000 iterations)
    /// - 고유 Salt 생성 (256-bit)
    /// - 타이밍 공격 방지 (constant-time comparison)
    /// - 무차별 대입 공격 방지 (rate limiting)
    /// - 취약한 PIN 패턴 검사
    /// 
    /// - Returns: PINManagerProtocol을 준수하는 서비스 인스턴스
    var pinManager: Factory<any PINManagerProtocol> {
        self { PINManager() as any PINManagerProtocol }
            .singleton
    }
    
    /// 키체인 관리자 (AES-256-GCM 암호화)
    /// 
    /// ## 보안 특징:
    /// - AES-256-GCM 암호화 (NIST 승인)
    /// - HMAC-SHA256 무결성 검증
    /// - 다중 키체인 아키텍처 (데이터 분리)
    /// - 키 유도 함수 (HKDF-SHA256)
    /// - 접근 추적 및 보안 로깅
    /// 
    /// - Returns: KeychainManagerProtocol을 준수하는 서비스 인스턴스
    var keychainManager: Factory<any KeychainManagerProtocol> {
        self { KeychainManager() as any KeychainManagerProtocol }
            .singleton
    }
    
    // MARK: - Integrated Security Service
    
    /// 통합 보안 서비스 (메인 보안 인터페이스)
    /// 
    /// 모든 보안 구성 요소를 통합하여 일관된 보안 인터페이스를 제공합니다.
    /// 생체 인증, PIN 관리, 키체인 보안을 포괄합니다.
    /// 
    /// ## 기본 기능:
    /// - 생체 인증 (Face ID, Touch ID, Optic ID)
    /// - PIN 관리 (설정, 검증, 변경)
    /// - 키체인 보안 (개인키, 지갑 주소 저장)
    /// - Rate limiting
    /// 
    /// - Returns: SecurityServiceProtocol을 준수하는 통합 서비스 인스턴스
    var securityService: Factory<any SecurityServiceProtocol> {
        self {
            SecurityService(
                biometricManager: self.biometricAuthManager(),
                pinManager: self.pinManager(),
                keychainManager: self.keychainManager()
            ) as any SecurityServiceProtocol
        }
        .singleton
    }
}

// MARK: - Swift Concurrency Support

/// Swift Concurrency 환경에서의 안전한 보안 서비스 접근
/// 
/// async/await 컨텍스트에서 보안 서비스들을 안전하게 사용할 수 있도록
/// 명시적인 해결(resolution) 메서드들을 제공합니다.
/// 
/// ## Actor 격리 보장:
/// - 각 서비스는 적절한 actor에서 실행
/// - Sendable 규칙 준수
/// - 데이터 경합 상태 방지
public extension Container {
    
    /// async 컨텍스트에서 안전하게 SecurityService를 해결
    /// 
    /// - Returns: Sendable을 준수하는 SecurityServiceProtocol 인스턴스
    func resolveSecurityService() async -> any SecurityServiceProtocol {
        return securityService()
    }
    
    /// async 컨텍스트에서 안전하게 BiometricAuthManager를 해결
    /// 
    /// - Returns: Sendable을 준수하는 BiometricAuthManagerProtocol 인스턴스
    func resolveBiometricAuthManager() async -> any BiometricAuthManagerProtocol {
        return biometricAuthManager()
    }
    
    /// async 컨텍스트에서 안전하게 PINManager를 해결
    /// 
    /// - Returns: Sendable을 준수하는 PINManagerProtocol 인스턴스
    func resolvePINManager() async -> any PINManagerProtocol {
        return pinManager()
    }
    
    /// async 컨텍스트에서 안전하게 KeychainManager를 해결
    /// 
    /// - Returns: Sendable을 준수하는 KeychainManagerProtocol 인스턴스
    func resolveKeychainManager() async -> any KeychainManagerProtocol {
        return keychainManager()
    }
    
    /// 모든 SecurityKit 서비스를 한 번에 예열(warm-up)하는 유틸리티 메서드
    /// 
    /// 앱 시작 시 보안 서비스들을 미리 초기화하여:
    /// - 첫 번째 보안 작업 시의 지연을 방지
    /// - 보안 서비스 간 의존성 검증
    /// - 보안 구성 요소의 초기화 상태 확인
    /// 
    /// ## 사용 시점:
    /// - 앱 시작 시 (AppDelegate 또는 App 구조체)
    /// - 백그라운드에서 비동기적으로 실행 권장
    /// - 사용자 인증이 필요한 화면 진입 전
    func warmUpSecurityServices() async {
        // 1. 핵심 보안 구성 요소 예열
        _ = biometricAuthManager()
        _ = pinManager()
        _ = keychainManager()
        
        // 2. 통합 보안 서비스 예열 (의존성 검증)
        let securityService = self.securityService()
        
        // 3. 보안 서비스 상태 검증
        Task {
            // 비동기로 보안 상태 확인 (UI 차단 방지)
            let hasSetup = await securityService.isSecuritySetup()
            let biometricAvailable = securityService.isBiometricAvailable()
            
            print("🛡️ Security Services Warm-up Complete")
            print("   - Security Setup: \(hasSetup ? "✅" : "❌")")
            print("   - Biometric Available: \(biometricAvailable ? "✅" : "❌")")
            print("   - Biometric Type: \(securityService.getBiometricType())")
        }
    }
}

// MARK: - Security Service Validation

/// 보안 서비스 초기화 및 상태 검증을 위한 헬퍼
/// 
/// 앱 시작 시 보안 서비스들의 정상 작동 여부를 검증하고,
/// 필요한 경우 보안 설정 가이드를 제공합니다.
public struct SecurityServicesValidator {
    
    /// 보안 서비스 초기화 상태를 검증
    /// 
    /// - Parameter container: 검증할 Container 인스턴스
    /// - Returns: 검증 결과와 권장 사항을 포함한 ValidationResult
    public static func validateSecurityServices(container: Container = Container.shared) async -> ValidationResult {
        let securityService = container.securityService()
        
        // 1. 기본 보안 설정 상태 확인
        let hasSecuritySetup = await securityService.isSecuritySetup()
        let biometricAvailable = securityService.isBiometricAvailable()
        let biometricType = securityService.getBiometricType()
        
        // 2. 권장 사항 생성
        var recommendations: [String] = []
        
        if !hasSecuritySetup {
            recommendations.append("보안 설정이 필요합니다. PIN을 설정해주세요.")
        }
        
        if !biometricAvailable && biometricType != .none {
            recommendations.append("생체 인증을 설정하여 보안을 강화할 수 있습니다.")
        }
        
        // 3. 검증 결과 반환
        return ValidationResult(
            isValid: true,
            hasSecuritySetup: hasSecuritySetup,
            biometricAvailable: biometricAvailable,
            biometricType: biometricType,
            recommendations: recommendations
        )
    }
    
    /// 보안 서비스 검증 결과
    public struct ValidationResult {
        public let isValid: Bool
        public let hasSecuritySetup: Bool
        public let biometricAvailable: Bool
        public let biometricType: Entity.SecurityError.BiometricType
        public let recommendations: [String]
        
        /// 사용자에게 표시할 보안 상태 메시지
        public var userMessage: String {
            if !isValid {
                return "보안 서비스를 초기화할 수 없습니다."
            }
            
            if hasSecuritySetup && biometricAvailable {
                return "보안이 완전히 설정되었습니다."
            } else if hasSecuritySetup {
                return "기본 보안이 설정되었습니다."
            } else {
                return "보안 설정이 필요합니다."
            }
        }
    }
}
