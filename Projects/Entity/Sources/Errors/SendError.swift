import Foundation

/// 암호화폐 송금 프로세스에서 발생할 수 있는 모든 오류를 정의한 열거형
/// 
/// 이더리움 및 ERC-20 토큰 전송 과정에서 발생할 수 있는 다양한 오류들을
/// 체계적으로 분류하여 사용자에게 명확한 피드백을 제공합니다.
/// 
/// ## 송금 오류 카테고리:
/// ### 입력 검증 오류
/// - `invalidAddress`: 잘못된 수신자 주소 형식
/// - `invalidAmount`: 잘못된 전송 금액
/// 
/// ### 잔액 및 수수료 오류
/// - `insufficientBalance`: 토큰 잔액 부족
/// - `insufficientGasFunds`: 가스비 (ETH) 부족
/// - `gasEstimationFailed`: 가스비 계산 실패
/// 
/// ### 트랜잭션 처리 오류
/// - `transactionFailed`: 블록체인 트랜잭션 실행 실패
/// - `networkError`: 네트워크 연결 문제
/// 
/// ### 사용자 및 보안 오류
/// - `userCancelled`: 사용자 취소
/// - `authenticationFailed`: 인증 실패
/// - `unknown`: 분류되지 않은 오류
/// 
/// ## 일반적인 송금 프로세스:
/// ```
/// 1. 주소 검증 → invalidAddress
/// 2. 금액 검증 → invalidAmount  
/// 3. 잔액 확인 → insufficientBalance
/// 4. 가스 추정 → gasEstimationFailed, insufficientGasFunds
/// 5. 사용자 인증 → authenticationFailed
/// 6. 트랜잭션 생성 및 서명 → transactionFailed
/// 7. 네트워크 전송 → networkError
/// ```
/// 
/// ## 사용 예시:
/// ```swift
/// do {
///     try await walletService.sendTransaction(to: address, amount: amount)
/// } catch SendError.insufficientBalance {
///     showAlert("잔액 부족", "전송할 토큰이 부족합니다")
/// } catch SendError.insufficientGasFunds {
///     showAlert("가스비 부족", "ETH를 충전해주세요")
/// } catch SendError.invalidAddress {
///     showAlert("주소 오류", "올바른 주소를 입력해주세요")
/// }
/// ```
public enum SendError: LocalizedError {
    /// 수신자 주소 형식이 올바르지 않음
    /// 
    /// 발생 상황:
    /// - 42자가 아닌 주소 길이
    /// - 0x prefix 누락 또는 잘못됨
    /// - 유효하지 않은 hex 문자 포함
    /// - EIP-55 체크섬 실패
    /// - 제로 주소 (0x0000...0000) 입력
    case invalidAddress
    
    /// 전송 금액이 유효하지 않음
    /// 
    /// 발생 상황:
    /// - 0 또는 음수 금액
    /// - 토큰 최소 단위보다 작은 금액
    /// - 숫자가 아닌 문자 포함
    /// - 지나치게 큰 금액 (오버플로우)
    /// - 소수점 자릿수 초과
    case invalidAmount
    
    /// 전송하려는 토큰의 잔액 부족
    /// 
    /// 발생 상황:
    /// - 지갑 잔액 < 전송 금액
    /// - ERC-20 토큰 잔액 부족
    /// - 토큰 승인 한도 부족 (allowance)
    /// - 스테이킹 또는 락업으로 인한 사용 불가 잔액
    case insufficientBalance
    
    /// 트랜잭션 수수료 지불을 위한 ETH 부족
    /// 
    /// 발생 상황:
    /// - ETH 잔액 < 예상 가스비
    /// - 가스 가격 상승으로 인한 수수료 증가
    /// - 복잡한 스마트 컨트랙트 호출의 높은 가스비
    /// - 네트워크 혼잡으로 인한 가스비 상승
    case insufficientGasFunds
    
    /// 트랜잭션 가스비 계산 실패
    /// 
    /// 발생 상황:
    /// - 스마트 컨트랙트 시뮬레이션 실패
    /// - 노드의 eth_estimateGas 호출 오류
    /// - 컨트랙트 실행 중 revert 발생
    /// - 가스 한계 초과 또는 네트워크 오류
    case gasEstimationFailed
    
    /// 블록체인 네트워크에서 트랜잭션 처리 실패
    /// 
    /// 발생 상황:
    /// - 트랜잭션 서명 오류
    /// - 낮은 가스비로 인한 처리 지연
    /// - 네트워크 혼잡으로 트랜잭션 드롭
    /// - 논스(nonce) 값 충돌
    /// - 스마트 컨트랙트 실행 실패 (revert)
    case transactionFailed
    
    /// 블록체인 네트워크 연결 문제
    /// 
    /// 발생 상황:
    /// - 인터넷 연결 끊김
    /// - RPC 노드 서버 다운
    /// - 네트워크 타임아웃
    /// - 잘못된 체인 ID 또는 노드 설정
    case networkError
    
    /// 사용자가 송금 프로세스를 취소함
    /// 
    /// 발생 상황:
    /// - 확인 화면에서 취소 버튼 클릭
    /// - 생체인증 취소
    /// - 백 제스처로 화면 이탈
    /// - 앱 백그라운드 전환으로 세션 만료
    case userCancelled
    
    /// 송금을 위한 사용자 인증 실패
    /// 
    /// 발생 상황:
    /// - Face ID/Touch ID 실패
    /// - PIN 번호 오입력
    /// - 키체인 접근 거부
    /// - 생체인증 잠금 상태
    /// - 인증 시간 초과
    case authenticationFailed
    
    /// 분류되지 않은 예상치 못한 오류
    /// 
    /// - Parameter underlyingError: 원본 오류 객체
    case unknown(Error)
    
    /// 사용자에게 표시할 현지화된 오류 메시지
    public var errorDescription: String? {
        switch self {
        case .invalidAddress:
            return "잘못된 주소입니다"
        case .invalidAmount:
            return "잘못된 금액입니다"
        case .insufficientBalance:
            return "잔액이 부족합니다"
        case .insufficientGasFunds:
            return "가스비가 부족합니다"
        case .gasEstimationFailed:
            return "가스 추정에 실패했습니다"
        case .transactionFailed:
            return "거래 전송에 실패했습니다"
        case .networkError:
            return "네트워크 오류가 발생했습니다"
        case .userCancelled:
            return "사용자가 거래를 취소했습니다"
        case .authenticationFailed:
            return "인증에 실패했습니다"
        case .unknown(let error):
            return "알 수 없는 오류: \(error.localizedDescription)"
        }
    }
    
    /// 개발자를 위한 상세한 디버깅 정보
    public var debugDescription: String {
        switch self {
        case .invalidAddress:
            return "Invalid Ethereum address format - must be 42-char hex with 0x prefix and valid checksum"
        case .invalidAmount:
            return "Invalid amount - must be positive number with valid decimal precision"
        case .insufficientBalance:
            return "Insufficient token balance - balance < send amount"
        case .insufficientGasFunds:
            return "Insufficient ETH for gas fees - ETH balance < estimated gas cost"
        case .gasEstimationFailed:
            return "Gas estimation failed - contract simulation or RPC call error"
        case .transactionFailed:
            return "Transaction failed - signing error, network rejection, or contract revert"
        case .networkError:
            return "Network connection failed - RPC node unreachable or timeout"
        case .userCancelled:
            return "User cancelled transaction - UI cancellation or authentication timeout"
        case .authenticationFailed:
            return "Authentication failed - biometric, PIN, or keychain access denied"
        case .unknown(let error):
            return "Unknown send error: \(error)"
        }
    }
    
    /// 사용자에게 제안할 해결 방법
    public var recoverySuggestion: String? {
        switch self {
        case .invalidAddress:
            return "올바른 이더리움 주소를 입력해주세요. QR코드를 스캔하거나 주소를 복사해서 붙여넣으세요."
        case .invalidAmount:
            return "0보다 큰 유효한 금액을 입력해주세요. 잔액을 확인하고 적절한 금액을 설정하세요."
        case .insufficientBalance:
            return "전송할 토큰을 충전하거나 전송 금액을 줄여주세요."
        case .insufficientGasFunds:
            return "가스비 지불을 위해 ETH를 충전해주세요. 최소 0.001 ETH 이상 보유를 권장합니다."
        case .gasEstimationFailed:
            return "네트워크 상태를 확인하고 잠시 후 다시 시도해주세요. 수신 주소가 올바른지도 확인해보세요."
        case .transactionFailed:
            return "가스비를 높이거나 네트워크 상태가 개선된 후 다시 시도해주세요."
        case .networkError:
            return "인터넷 연결을 확인하고 잠시 후 다시 시도해주세요."
        case .userCancelled:
            return "다시 송금을 시도하려면 송금 버튼을 눌러주세요."
        case .authenticationFailed:
            return "생체인증 또는 PIN을 다시 시도해주세요. 설정에서 인증 방법을 확인할 수 있습니다."
        case .unknown:
            return "앱을 재시작하고 다시 시도해주세요. 문제가 계속되면 지원팀에 문의하세요."
        }
    }
    
    /// 오류가 사용자 입력으로 인한 것인지 확인
    public var isUserInputError: Bool {
        switch self {
        case .invalidAddress, .invalidAmount, .userCancelled:
            return true
        default:
            return false
        }
    }
    
    /// 잔액 부족으로 인한 오류인지 확인
    public var isInsufficientFundsError: Bool {
        switch self {
        case .insufficientBalance, .insufficientGasFunds:
            return true
        default:
            return false
        }
    }
    
    /// 네트워크 관련 오류인지 확인
    public var isNetworkError: Bool {
        switch self {
        case .networkError, .gasEstimationFailed, .transactionFailed:
            return true
        default:
            return false
        }
    }
    
    /// 재시도 가능한 오류인지 확인
    public var isRetryable: Bool {
        switch self {
        case .networkError, .gasEstimationFailed, .transactionFailed, .authenticationFailed:
            return true
        case .userCancelled:
            return true // 사용자가 다시 시도할 수 있음
        default:
            return false
        }
    }
    
    /// 오류 심각도 레벨
    public var severity: SendErrorSeverity {
        switch self {
        case .userCancelled:
            return .info // 정상적인 사용자 액션
        case .invalidAddress, .invalidAmount:
            return .low // 사용자 입력 오류
        case .insufficientBalance, .insufficientGasFunds:
            return .medium // 잔액 문제
        case .gasEstimationFailed, .networkError, .authenticationFailed:
            return .medium // 일시적 문제
        case .transactionFailed:
            return .high // 트랜잭션 실패
        case .unknown:
            return .high // 분석 필요
        }
    }
    
    /// 송금 오류 카테고리
    public var category: SendErrorCategory {
        switch self {
        case .invalidAddress, .invalidAmount:
            return .validation
        case .insufficientBalance, .insufficientGasFunds:
            return .funds
        case .gasEstimationFailed:
            return .gasEstimation
        case .transactionFailed:
            return .transaction
        case .networkError:
            return .network
        case .userCancelled:
            return .userAction
        case .authenticationFailed:
            return .authentication
        case .unknown:
            return .system
        }
    }
    
    /// 사용자 액션 버튼 텍스트
    public var actionTitle: String? {
        switch self {
        case .invalidAddress:
            return "주소 수정"
        case .invalidAmount:
            return "금액 수정"
        case .insufficientBalance:
            return "충전하기"
        case .insufficientGasFunds:
            return "ETH 충전"
        case .gasEstimationFailed, .networkError, .transactionFailed:
            return "다시 시도"
        case .userCancelled:
            return "다시 송금"
        case .authenticationFailed:
            return "다시 인증"
        case .unknown:
            return "재시도"
        }
    }
    
    /// 오류 해결을 위한 단계별 가이드
    public var troubleshootingSteps: [String] {
        switch self {
        case .invalidAddress:
            return [
                "주소 형식이 0x로 시작하는 42자리인지 확인",
                "QR코드를 다시 스캔하거나 주소를 복사해서 붙여넣기",
                "ENS 도메인을 사용하는 경우 올바른 형식인지 확인"
            ]
        case .invalidAmount:
            return [
                "0보다 큰 유효한 숫자인지 확인",
                "소수점 자릿수가 토큰 정밀도를 초과하지 않는지 확인",
                "전체 잔액보다 작은 금액인지 확인"
            ]
        case .insufficientBalance:
            return [
                "현재 토큰 잔액 확인",
                "토큰 충전 또는 전송 금액 조정",
                "ERC-20 토큰의 경우 승인(approve) 한도 확인"
            ]
        case .insufficientGasFunds:
            return [
                "현재 ETH 잔액 확인",
                "예상 가스비와 비교하여 부족한 ETH 충전",
                "가스 가격을 낮춰서 수수료 절약 고려"
            ]
        case .gasEstimationFailed:
            return [
                "네트워크 연결 상태 확인",
                "수신 주소가 올바른지 재확인",
                "잠시 후 다시 시도 (네트워크 혼잡 가능성)"
            ]
        case .transactionFailed:
            return [
                "가스 한계와 가스 가격 증가",
                "네트워크 혼잡도 확인 후 재시도",
                "논스(nonce) 충돌이 없는지 확인"
            ]
        case .networkError:
            return [
                "인터넷 연결 상태 확인",
                "WiFi 또는 모바일 데이터 연결 재시도",
                "다른 네트워크로 전환 후 테스트"
            ]
        case .authenticationFailed:
            return [
                "생체인증 (Face ID/Touch ID) 다시 시도",
                "PIN 번호 정확히 입력",
                "설정에서 인증 방법 재설정"
            ]
        case .userCancelled:
            return [
                "송금 버튼을 다시 눌러 재시도",
                "필요한 경우 송금 정보 다시 확인"
            ]
        case .unknown:
            return [
                "앱 완전 종료 후 재시작",
                "디바이스 재시작",
                "앱 업데이트 확인",
                "지원팀에 오류 상황 문의"
            ]
        }
    }
}

// MARK: - Supporting Types

/// 송금 오류 심각도 레벨
public enum SendErrorSeverity {
    /// 정보성 - 정상적인 사용자 액션
    case info
    /// 낮은 심각도 - 사용자 입력 수정으로 해결 가능
    case low
    /// 중간 심각도 - 사용자 액션이나 일시적 대기 필요
    case medium
    /// 높은 심각도 - 시스템 문제나 복잡한 해결 과정 필요
    case high
}

/// 송금 오류 카테고리
public enum SendErrorCategory {
    /// 입력 데이터 검증 오류
    case validation
    /// 잔액 및 자금 관련 오류
    case funds
    /// 가스 추정 관련 오류
    case gasEstimation
    /// 블록체인 트랜잭션 오류
    case transaction
    /// 네트워크 연결 오류
    case network
    /// 사용자 액션 관련
    case userAction
    /// 인증 관련 오류
    case authentication
    /// 시스템 및 분류되지 않은 오류
    case system
}

// MARK: - SendError Extensions

public extension SendError {
    /// 특정 오류 타입인지 확인하는 편의 메서드
    func isType(_ errorType: SendError) -> Bool {
        switch (self, errorType) {
        case (.invalidAddress, .invalidAddress),
             (.invalidAmount, .invalidAmount),
             (.insufficientBalance, .insufficientBalance),
             (.insufficientGasFunds, .insufficientGasFunds),
             (.gasEstimationFailed, .gasEstimationFailed),
             (.transactionFailed, .transactionFailed),
             (.networkError, .networkError),
             (.userCancelled, .userCancelled),
             (.authenticationFailed, .authenticationFailed):
            return true
        case (.unknown, .unknown):
            return true
        default:
            return false
        }
    }
    
    /// 오류 발생 단계 (송금 프로세스에서의 위치)
    var processStage: SendProcessStage {
        switch self {
        case .invalidAddress, .invalidAmount:
            return .validation
        case .insufficientBalance, .insufficientGasFunds:
            return .balanceCheck
        case .gasEstimationFailed:
            return .gasEstimation
        case .authenticationFailed:
            return .authentication
        case .transactionFailed, .networkError:
            return .execution
        case .userCancelled:
            return .userInteraction
        case .unknown:
            return .unknown
        }
    }
}

/// 송금 프로세스 단계
public enum SendProcessStage {
    /// 입력 데이터 검증 단계
    case validation
    /// 잔액 확인 단계
    case balanceCheck
    /// 가스비 추정 단계
    case gasEstimation
    /// 사용자 인증 단계
    case authentication
    /// 트랜잭션 실행 단계
    case execution
    /// 사용자 상호작용 단계
    case userInteraction
    /// 알 수 없는 단계
    case unknown
}