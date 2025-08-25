import Foundation

/// 지갑 관련 오류를 나타내는 열거형
public enum WalletError: LocalizedError, Sendable {
    case walletCreationFailed
    case privateKeyExtractionFailed
    case invalidPrivateKey
    case invalidAddress
    case invalidMnemonic
    case insufficientFunds
    case transactionFailed
    case networkError
    case keychainError
    case noWalletFound
    
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
}