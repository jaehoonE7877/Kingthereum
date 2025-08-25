import Foundation

/// 지갑 정보를 나타내는 모델
/// 지갑의 고유 식별자, 이름, 주소, 생성일시, 백업 여부 등의 정보를 포함
public struct Wallet: Codable, Identifiable, Equatable, Sendable {
    /// 지갑의 고유 식별자
    public let id: UUID
    /// 지갑 이름
    public let name: String
    /// 지갑 주소
    public let address: String
    /// 지갑 생성 일시
    public let createdAt: Date
    /// 지갑 백업 완료 여부
    public let isBackedUp: Bool
    
    /// 지갑 초기화
    /// - Parameters:
    ///   - id: 고유 식별자 (기본값: 새로운 UUID)
    ///   - name: 지갑 이름
    ///   - address: 지갑 주소
    ///   - createdAt: 생성 일시 (기본값: 현재 시간)
    ///   - isBackedUp: 백업 여부 (기본값: false)
    public init(
        id: UUID = UUID(),
        name: String,
        address: String,
        createdAt: Date = Date(),
        isBackedUp: Bool = false
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.createdAt = createdAt
        self.isBackedUp = isBackedUp
    }
    
    /// 백업 상태를 변경한 새로운 지갑 인스턴스를 생성
    /// - Parameter isBackedUp: 새로운 백업 상태
    /// - Returns: 백업 상태가 업데이트된 지갑 인스턴스
    public func withBackup(_ isBackedUp: Bool) -> Wallet {
        return Wallet(
            id: id,
            name: name,
            address: address,
            createdAt: createdAt,
            isBackedUp: isBackedUp
        )
    }
}