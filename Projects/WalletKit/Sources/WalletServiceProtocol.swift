import Foundation
import Entity

/// 지갑 관리를 위한 핵심 서비스 프로토콜
/// 주소 생성, 잔액 조회, 거래 전송 등의 핵심 기능을 정의
public protocol WalletServiceProtocol: Sendable {
    
    // MARK: - Wallet Management
    
    /// 현재 지갑 주소 반환
    /// - Returns: 지갑 주소 (0x 형식)
    func getCurrentWalletAddress() async throws -> String
    
    /// 지갑 잔액 조회
    /// - Parameter address: 조회할 지갑 주소
    /// - Returns: ETH 잔액 (String 형태의 Ether 단위)
    /// - Throws: 네트워크 또는 RPC 에러
    func getBalance(for address: String) async throws -> String
    
    /// 지갑 잔액 조회 (Wei 단위)
    /// - Parameter address: 조회할 지갑 주소
    /// - Returns: Wei 단위 잔액
    /// - Throws: 네트워크 또는 RPC 에러
    func getBalanceInWei(for address: String) async throws -> String
    
    // MARK: - Transaction Management
    
    /// 거래 전송
    /// - Parameters:
    ///   - to: 수신자 주소
    ///   - amount: 전송할 ETH 금액 (Ether 단위)
    ///   - gasPrice: 가스 가격 (Wei 단위, nil이면 자동 설정)
    ///   - gasLimit: 가스 한도 (nil이면 자동 설정)
    /// - Returns: 거래 해시
    /// - Throws: 거래 전송 에러
    func sendTransaction(
        to: String,
        amount: String,
        gasPrice: String?,
        gasLimit: String?
    ) async throws -> String
    
    /// 가스 요금 추정
    /// - Parameters:
    ///   - to: 수신자 주소
    ///   - amount: 전송할 ETH 금액
    /// - Returns: 추정 가스 요금 정보
    /// - Throws: 가스 추정 에러
    func estimateGas(to: String, amount: String) async throws -> GasEstimate
    
    /// 거래 상태 확인
    /// - Parameter transactionHash: 거래 해시
    /// - Returns: 거래 정보
    /// - Throws: 거래 조회 에러
    func getTransactionStatus(transactionHash: String) async throws -> TransactionStatus
    
    // MARK: - Address Validation
    
    /// 이더리움 주소 유효성 검증
    /// - Parameter address: 검증할 주소
    /// - Returns: 유효성 여부
    func isValidEthereumAddress(_ address: String) -> Bool
    
    /// 주소 체크섬 형식으로 변환
    /// - Parameter address: 변환할 주소
    /// - Returns: 체크섬 형식 주소
    /// - Throws: 주소 형식 에러
    func toChecksumAddress(_ address: String) throws -> String
}

/// QR 코드 생성을 위한 프로토콜
public protocol QRCodeGeneratorProtocol: Sendable {
    
    /// QR 코드 생성
    /// - Parameter text: QR 코드에 인코딩할 텍스트
    /// - Returns: QR 코드 이미지 데이터
    func generateQRCode(from text: String) -> Data?
    
    /// 이더리움 주소용 QR 코드 생성 (ethereum: URI 형식)
    /// - Parameter address: 이더리움 주소
    /// - Returns: QR 코드 이미지 데이터
    func generateEthereumQRCode(for address: String) -> Data?
}
