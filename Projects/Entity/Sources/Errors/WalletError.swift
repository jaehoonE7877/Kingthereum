import Foundation

/// 암호화폐 지갑 작업에서 발생할 수 있는 모든 오류 상황을 정의한 열거형
/// 
/// 지갑 생성, 키 관리, 트랜잭션 처리, 보안 등 지갑의 핵심 기능에서
/// 발생할 수 있는 다양한 오류들을 체계적으로 분류합니다.
/// 
/// ## 오류 카테고리:
/// ### 지갑 생성 및 복구
/// - `walletCreationFailed`: 새 지갑 생성 실패
/// - `invalidMnemonic`: 잘못된 시드 문구
/// - `noWalletFound`: 지갑 없음
/// 
/// ### 키 및 주소 관리
/// - `privateKeyExtractionFailed`: 개인키 추출 실패
/// - `invalidPrivateKey`: 잘못된 개인키 형식
/// - `invalidAddress`: 잘못된 지갑 주소 형식
/// 
/// ### 트랜잭션 및 잔액
/// - `insufficientFunds`: 잔액 부족
/// - `transactionFailed`: 트랜잭션 실패
/// 
/// ### 시스템 및 보안
/// - `keychainError`: 키체인 접근 실패
/// - `networkError`: 네트워크 연결 문제
/// 
/// ## 사용 예시:
/// ```swift
/// do {
///     let wallet = try walletManager.createWallet()
/// } catch WalletError.insufficientFunds {
///     showAlert("ETH를 충전해주세요")
/// } catch WalletError.keychainError {
///     showAlert("생체인증을 확인해주세요")
/// } catch {
///     showAlert("지갑 오류가 발생했습니다")
/// }
/// ```
public enum WalletError: LocalizedError, Sendable {
    /// 새 지갑 생성 프로세스 실패
    ///
    /// 발생 상황:
    /// - 엔트로피 생성 실패
    /// - 시드 문구 생성 오류
    /// - 개인키/공개키 쌍 생성 실패
    /// - 키체인 저장 실패
    case walletCreationFailed
    
    /// 기존 지갑에서 개인키 추출 실패
    ///
    /// 발생 상황:
    /// - 키체인에서 키 읽기 실패
    /// - 암호화된 키 복호화 실패
    /// - 손상된 키 데이터
    /// - 생체인증/패스코드 실패
    case privateKeyExtractionFailed
    
    /// 유효하지 않은 개인키 형식 또는 값
    ///
    /// 발생 상황:
    /// - 잘못된 개인키 길이 (64자 hex가 아님)
    /// - 유효하지 않은 hex 문자
    /// - 0 또는 곡선 범위 밖 값
    /// - 손상된 키 데이터
    case invalidPrivateKey
    
    /// 유효하지 않은 이더리움 주소 형식
    ///
    /// 발생 상황:
    /// - 잘못된 주소 길이 (42자가 아님)
    /// - 0x prefix 누락
    /// - 유효하지 않은 hex 문자
    /// - 체크섬 불일치
    case invalidAddress
    
    /// 유효하지 않은 BIP39 니모닉 시드 문구
    ///
    /// 발생 상황:
    /// - 단어 개수 오류 (12/15/18/21/24개가 아님)
    /// - BIP39 단어 목록에 없는 단어
    /// - 체크섬 검증 실패
    /// - 잘못된 단어 순서
    case invalidMnemonic
    
    /// 유효하지 않은 금액 또는 잔액 형식
    ///
    /// 발생 상황:
    /// - 음수 금액
    /// - 소수점 자릿수 초과 (18자리 초과)
    /// - 0 또는 공백 금액
    /// - 수치로 변환할 수 없는 형식
    case invalidAmount
    
    /// 트랜잭션 실행에 필요한 자금 부족
    ///
    /// 발생 상황:
    /// - ETH 잔액 < (전송액 + 가스비)
    /// - 토큰 잔액 < 전송액
    /// - 승인된 토큰 한도 부족
    /// - 가스 한계 초과
    case insufficientFunds
    
    /// 트랜잭션 전송 또는 실행 실패
    ///
    /// 발생 상황:
    /// - 트랜잭션 서명 실패
    /// - 네트워크 전송 실패
    /// - 노드에서 트랜잭션 거부
    /// - 가스 부족 또는 한도 초과
    /// - 스마트 컨트랙트 실행 오류
    case transactionFailed
    
    /// 블록체인 네트워크 연결 문제
    ///
    /// 발생 상황:
    /// - RPC 노드 연결 실패
    /// - 네트워크 타임아웃
    /// - 잘못된 체인 ID
    /// - 노드 동기화 문제
    case networkError
    
    /// iOS 키체인 접근 또는 저장 오류
    ///
    /// 발생 상황:
    /// - 생체인증 (Touch ID/Face ID) 실패
    /// - 패스코드 입력 실패 또는 취소
    /// - 키체인 저장 공간 부족
    /// - 시스템 키체인 서비스 오류
    case keychainError
    
    /// 앱에 등록된 지갑이 없음
    ///
    /// 발생 상황:
    /// - 최초 실행 시 지갑 미생성
    /// - 지갑 삭제 후 복구 안됨
    /// - 키체인에서 지갑 데이터 누락
    /// - 앱 재설치 후 복구 실패
    case noWalletFound
    
    /// 사용자에게 표시할 현지화된 오류 메시지
    public var errorDescription: String? {
        switch self {
        case .walletCreationFailed:
            return "지갑 생성에 실패했습니다"
        case .privateKeyExtractionFailed:
            return "개인키 추출에 실패했습니다"
        case .invalidPrivateKey:
            return "잘못된 개인키입니다"
        case .invalidAddress:
            return "잘못된 주소입니다"
        case .invalidMnemonic:
            return "잘못된 니모닉 문구입니다"
        case .invalidAmount:
            return "잘못된 금액입니다"
        case .insufficientFunds:
            return "잔액이 부족합니다"
        case .transactionFailed:
            return "거래 전송에 실패했습니다"
        case .networkError:
            return "네트워크 연결에 실패했습니다"
        case .keychainError:
            return "키체인 접근에 실패했습니다"
        case .noWalletFound:
            return "지갑을 찾을 수 없습니다"
        }
    }
    
    /// 개발자를 위한 상세한 오류 정보
    public var debugDescription: String {
        switch self {
        case .walletCreationFailed:
            return "Failed to create new wallet - entropy generation or key derivation failed"
        case .privateKeyExtractionFailed:
            return "Failed to extract private key from secure storage"
        case .invalidPrivateKey:
            return "Private key format invalid - must be 64-character hex string"
        case .invalidAddress:
            return "Invalid Ethereum address format - must be 42-character hex with 0x prefix"
        case .invalidMnemonic:
            return "Invalid BIP39 mnemonic phrase - checksum or word validation failed"
        case .invalidAmount:
            return "Invalid amount format - must be positive number with max 18 decimal places"
        case .insufficientFunds:
            return "Insufficient balance for transaction including gas fees"
        case .transactionFailed:
            return "Transaction execution failed - signing, broadcasting, or mining error"
        case .networkError:
            return "Blockchain network connection failed"
        case .keychainError:
            return "iOS Keychain access failed - biometric or passcode authentication required"
        case .noWalletFound:
            return "No wallet found in secure storage"
        }
    }
    
    /// 사용자에게 제안할 해결 방법
    public var recoverySuggestion: String? {
        switch self {
        case .walletCreationFailed:
            return "앱을 다시 시작하고 재시도해주세요. 문제가 계속되면 기기를 재시작해보세요."
        case .privateKeyExtractionFailed, .keychainError:
            return "생체인증(Face ID/Touch ID) 또는 패스코드를 확인해주세요. 설정에서 생체인증을 다시 등록해보세요."
        case .invalidPrivateKey:
            return "올바른 개인키 형식을 입력해주세요 (64자리 16진수)."
        case .invalidAddress:
            return "이더리움 주소 형식을 확인해주세요 (0x로 시작하는 42자리)."
        case .invalidMnemonic:
            return "12개 또는 24개의 올바른 시드 단어를 입력해주세요. 순서와 철자를 확인해보세요."
        case .invalidAmount:
            return "양수 금액을 입력해주세요. 소수점은 최대 18자리까지 가능합니다."
        case .insufficientFunds:
            return "ETH를 충전하거나 전송 금액을 줄여주세요. 가스비도 함께 고려해야 합니다."
        case .transactionFailed:
            return "네트워크 상태를 확인하고 가스비를 늘려서 재시도해주세요."
        case .networkError:
            return "인터넷 연결을 확인하고 잠시 후 다시 시도해주세요."
        case .noWalletFound:
            return "새 지갑을 생성하거나 기존 지갑을 복원해주세요."
        }
    }
    
    /// 오류가 사용자 액션으로 인한 것인지 확인
    public var isUserError: Bool {
        switch self {
        case .invalidPrivateKey, .invalidAddress, .invalidMnemonic, .invalidAmount, .insufficientFunds:
            return true
        default:
            return false
        }
    }
    
    /// 시스템 또는 기술적 오류인지 확인
    public var isSystemError: Bool {
        switch self {
        case .walletCreationFailed, .privateKeyExtractionFailed, .keychainError, .networkError:
            return true
        default:
            return false
        }
    }
    
    /// 재시도 가능한 오류인지 확인
    public var isRetryable: Bool {
        switch self {
        case .networkError, .transactionFailed, .keychainError:
            return true
        case .walletCreationFailed:
            return true // 일시적 시스템 문제일 수 있음
        default:
            return false
        }
    }
    
    /// 오류 심각도 레벨 (문자열로 반환)
    public var severityLevel: String {
        switch self {
        case .noWalletFound:
            return "critical" // 앱 핵심 기능 불가
        case .keychainError, .privateKeyExtractionFailed:
            return "high" // 보안 관련 문제
        case .walletCreationFailed, .transactionFailed:
            return "high" // 주요 기능 실패
        case .insufficientFunds, .networkError:
            return "medium" // 사용자가 해결 가능
        case .invalidPrivateKey, .invalidAddress, .invalidMnemonic, .invalidAmount:
            return "low" // 입력 오류
        }
    }
    
    /// 오류 카테고리 (문자열로 반환)
    public var errorCategory: String {
        switch self {
        case .walletCreationFailed, .noWalletFound:
            return "wallet"
        case .privateKeyExtractionFailed, .invalidPrivateKey, .keychainError:
            return "security"
        case .invalidAddress, .invalidMnemonic, .invalidAmount:
            return "validation"
        case .insufficientFunds, .transactionFailed:
            return "transaction"
        case .networkError:
            return "network"
        }
    }
    
    /// 사용자에게 표시할 액션 버튼 텍스트
    public var actionTitle: String? {
        switch self {
        case .noWalletFound:
            return "지갑 생성"
        case .insufficientFunds:
            return "충전하기"
        case .keychainError:
            return "인증 재시도"
        case .networkError:
            return "다시 시도"
        case .transactionFailed:
            return "재전송"
        default:
            return nil
        }
    }
}
