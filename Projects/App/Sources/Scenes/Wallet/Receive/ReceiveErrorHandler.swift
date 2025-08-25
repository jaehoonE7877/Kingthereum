import Foundation
import Entity
import DesignSystem

// MARK: - 수신 기능 에러 타입 정의

enum ReceiveError: LocalizedError, Equatable {
    case invalidWalletAddress(String)
    case qrCodeGenerationFailed
    case clipboardAccessDenied
    case shareSheetUnavailable
    case networkError(String)
    case securityViolation(String)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidWalletAddress(let address):
            return "유효하지 않은 지갑 주소입니다: \(address)"
        case .qrCodeGenerationFailed:
            return "QR 코드 생성에 실패했습니다. 다시 시도해주세요."
        case .clipboardAccessDenied:
            return "클립보드 접근이 거부되었습니다."
        case .shareSheetUnavailable:
            return "공유 기능을 사용할 수 없습니다."
        case .networkError(let message):
            return "네트워크 오류: \(message)"
        case .securityViolation(let reason):
            return "보안 위반 감지: \(reason)"
        case .unknown(let message):
            return "알 수 없는 오류: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidWalletAddress:
            return "올바른 이더리움 지갑 주소를 확인하고 다시 시도해주세요."
        case .qrCodeGenerationFailed:
            return "잠시 후 다시 시도하거나 앱을 재시작해주세요."
        case .clipboardAccessDenied:
            return "설정에서 클립보드 접근 권한을 허용해주세요."
        case .shareSheetUnavailable:
            return "주소를 수동으로 복사하여 공유해주세요."
        case .networkError:
            return "인터넷 연결을 확인하고 다시 시도해주세요."
        case .securityViolation:
            return "보안을 위해 앱을 재시작하고 다시 시도해주세요."
        case .unknown:
            return "문제가 지속되면 고객센터에 문의해주세요."
        }
    }
}

// MARK: - 에러 핸들러

final class ReceiveErrorHandler {
    
    // 에러 로깅 및 분석을 위한 delegate
    weak var analyticsDelegate: ReceiveAnalyticsDelegate?
    
    /// 에러를 사용자 친화적인 메시지로 변환
    func handleError(_ error: Error) -> (title: String, message: String, suggestion: String?) {
        let receiveError: ReceiveError
        
        // 다양한 에러 타입을 ReceiveError로 변환
        if let receiverError = error as? ReceiveError {
            receiveError = receiverError
        } else {
            let nsError = error as NSError
            switch nsError.domain {
            case "NSCocoaErrorDomain":
                receiveError = .clipboardAccessDenied
            case "NSURLErrorDomain":
                receiveError = .networkError(nsError.localizedDescription)
            default:
                receiveError = .unknown(nsError.localizedDescription)
            }
        }
        
        // 분석을 위한 에러 로깅
        logError(receiveError)
        
        return (
            title: getErrorTitle(for: receiveError),
            message: receiveError.errorDescription ?? "알 수 없는 오류가 발생했습니다.",
            suggestion: receiveError.recoverySuggestion
        )
    }
    
    /// QR 코드 생성 실패 처리
    func handleQRGenerationFailure(for address: String) -> ReceiveError {
        if address.isEmpty {
            return .invalidWalletAddress("빈 주소")
        }
        
        // 이더리움 주소 패턴 직접 검증
        let pattern = "^0x[a-fA-F0-9]{40}$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: address.count)
        if regex?.firstMatch(in: address, range: range) == nil {
            return .invalidWalletAddress(address)
        }
        
        return .qrCodeGenerationFailed
    }
    
    /// 클립보드 작업 실패 처리
    func handleClipboardError(_ error: Error?) -> ReceiveError {
        guard let error = error else {
            return .clipboardAccessDenied
        }
        
        return .unknown(error.localizedDescription)
    }
    
    // MARK: - Private Methods
    
    private func getErrorTitle(for error: ReceiveError) -> String {
        switch error {
        case .invalidWalletAddress:
            return "주소 오류"
        case .qrCodeGenerationFailed:
            return "QR 코드 생성 실패"
        case .clipboardAccessDenied:
            return "클립보드 오류"
        case .shareSheetUnavailable:
            return "공유 오류"
        case .networkError:
            return "네트워크 오류"
        case .securityViolation:
            return "보안 경고"
        case .unknown:
            return "오류 발생"
        }
    }
    
    private func logError(_ error: ReceiveError) {
        let errorInfo = [
            "error_type": "\(error)",
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "description": error.errorDescription ?? "No description"
        ]
        
        #if DEBUG
        print("🚨 ReceiveError: \(errorInfo)")
        #endif
        
        // 실제 운영 환경에서는 Firebase Crashlytics, Sentry 등에 로그 전송
        analyticsDelegate?.logError(errorInfo)
    }
}

// MARK: - Analytics Delegate

protocol ReceiveAnalyticsDelegate: AnyObject {
    func logError(_ errorInfo: [String: String])
    func logUserAction(_ action: String, parameters: [String: Any]?)
}

// MARK: - Result Type 확장

extension Result where Failure == ReceiveError {
    /// 에러 메시지 조회를 위한 편의 메서드
    var receiveErrorMessage: String {
        switch self {
        case .success:
            return "성공"
        case .failure(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - Async/Await 지원

extension ReceiveErrorHandler {
    /// 비동기 작업에서 에러를 처리하고 Result 반환
    func handleAsyncOperation<T>(
        operation: @escaping () async throws -> T
    ) async -> Result<T, ReceiveError> {
        do {
            let result = try await operation()
            return .success(result)
        } catch {
            let mappedError = mapToReceiveError(error)
            logError(mappedError)
            return .failure(mappedError)
        }
    }
    
    private func mapToReceiveError(_ error: Error) -> ReceiveError {
        if let receiveError = error as? ReceiveError {
            return receiveError
        }
        return .unknown(error.localizedDescription)
    }
}
