import Foundation

/// 암호화폐 지갑의 메타데이터를 표현하는 도메인 모델
/// 
/// 사용자의 블록체인 지갑에 대한 식별 정보와 상태를 관리합니다.
/// 실제 암호화 키는 보안상 별도의 키체인에 저장되며, 이 모델은 UI 표시와
/// 지갑 관리에 필요한 메타데이터만을 포함합니다.
/// 
/// ## 주요 특징:
/// - 불변 구조체로 설계되어 데이터 무결성 보장
/// - Sendable 준수로 동시성 환경에서 안전 사용
/// - 백업 상태 추적으로 사용자 자산 보안 지원
/// - 고유 ID를 통한 정확한 지갑 식별
/// 
/// ## 사용 예시:
/// ```swift
/// let wallet = Wallet(
///     name: "메인 지갑",
///     address: "0x742d35Cc6734C0532925a3b8D94Ca1b8C6c2B83A"
/// )
/// 
/// // 백업 완료 후 상태 업데이트
/// let backedUpWallet = wallet.withBackup(true)
/// ```
/// 
/// ## 보안 고려사항:
/// - 개인키나 니모닉은 절대 이 모델에 저장하지 않음
/// - 지갑 주소만 저장하여 읽기 전용 정보 제공
/// - 백업 상태를 통해 사용자에게 보안 알림 제공
public struct Wallet: Codable, Identifiable, Equatable, Sendable {
    
    // MARK: - Core Properties
    
    /// 지갑의 고유 식별자
    /// 
    /// 앱 내에서 지갑을 고유하게 식별하는 UUID입니다.
    /// 데이터베이스 저장, UI 목록 표시, 지갑 선택 등에 사용됩니다.
    public let id: UUID
    
    /// 사용자가 설정한 지갑 이름
    /// 
    /// 지갑을 구분하기 위한 사용자 친화적인 이름입니다.
    /// 예: "메인 지갑", "거래용 지갑", "저축 지갑" 등
    public let name: String
    
    /// 블록체인 지갑 주소 (0x로 시작하는 이더리움 주소)
    /// 
    /// EIP-55 체크섬이 적용된 이더리움 주소 형식입니다.
    /// 이 주소로 거래 내역 조회, 잔액 확인 등이 가능합니다.
    /// 
    /// ## 주소 형식:
    /// - 길이: 42자 (0x + 40자리 16진수)
    /// - 예시: "0x742d35Cc6734C0532925a3b8D94Ca1b8C6c2B83A"
    public let address: String
    
    /// 지갑 생성 일시
    /// 
    /// 지갑이 처음 생성되거나 가져온 시점을 기록합니다.
    /// 지갑 목록 정렬, 사용 기간 계산 등에 활용됩니다.
    public let createdAt: Date
    
    /// 지갑 백업 완료 여부
    /// 
    /// 니모닉 구문 또는 개인키 백업이 완료되었는지 추적합니다.
    /// false인 경우 사용자에게 백업 알림을 표시해야 합니다.
    /// 
    /// ## 백업 중요성:
    /// - 기기 분실 시 지갑 복구 가능
    /// - 앱 재설치 후 자산 접근 가능
    /// - 보안 사고 시 자산 이전 가능
    public let isBackedUp: Bool
    
    // MARK: - Initialization
    
    /// 새로운 지갑 인스턴스 생성
    /// 
    /// - Parameters:
    ///   - id: 고유 식별자 (기본값: 새로운 UUID 자동 생성)
    ///   - name: 사용자가 지정한 지갑 이름
    ///   - address: 이더리움 지갑 주소 (0x 접두사 포함)
    ///   - createdAt: 생성 일시 (기본값: 현재 시간)
    ///   - isBackedUp: 백업 완료 여부 (기본값: false - 백업 필요)
    /// 
    /// ## 사용 예시:
    /// ```swift
    /// // 새 지갑 생성
    /// let newWallet = Wallet(
    ///     name: "메인 지갑",
    ///     address: "0x742d35Cc6734C0532925a3b8D94Ca1b8C6c2B83A"
    /// )
    /// 
    /// // 기존 지갑 복원 (백업 완료 상태)
    /// let restoredWallet = Wallet(
    ///     name: "복원된 지갑",
    ///     address: "0x123...",
    ///     isBackedUp: true
    /// )
    /// ```
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
    
    // MARK: - State Modification
    
    /// 백업 상태가 변경된 새로운 지갑 인스턴스 생성
    /// 
    /// 불변 구조체의 특성에 따라 기존 인스턴스를 수정하는 대신
    /// 백업 상태만 변경된 새로운 인스턴스를 반환합니다.
    /// 
    /// - Parameter isBackedUp: 새로운 백업 상태
    /// - Returns: 백업 상태가 업데이트된 새로운 Wallet 인스턴스
    /// 
    /// ## 사용 예시:
    /// ```swift
    /// let wallet = Wallet(name: "테스트", address: "0x...")
    /// print(wallet.isBackedUp) // false
    /// 
    /// let backedUpWallet = wallet.withBackup(true)
    /// print(backedUpWallet.isBackedUp) // true
    /// print(wallet.isBackedUp) // 원본은 여전히 false (불변)
    /// ```
    public func withBackup(_ isBackedUp: Bool) -> Wallet {
        return Wallet(
            id: self.id,
            name: self.name,
            address: self.address,
            createdAt: self.createdAt,
            isBackedUp: isBackedUp
        )
    }
    
    /// 지갑 이름이 변경된 새로운 인스턴스 생성
    /// 
    /// - Parameter name: 새로운 지갑 이름
    /// - Returns: 이름이 업데이트된 새로운 Wallet 인스턴스
    public func withName(_ name: String) -> Wallet {
        return Wallet(
            id: self.id,
            name: name,
            address: self.address,
            createdAt: self.createdAt,
            isBackedUp: self.isBackedUp
        )
    }
    
    // MARK: - Computed Properties
    
    /// 축약된 지갑 주소 (UI 표시용)
    /// 
    /// 긴 주소를 앞 6자리와 뒤 4자리로 축약하여 표시합니다.
    /// 지갑 목록, 거래 내역 등 공간이 제한된 UI에서 사용합니다.
    /// 
    /// - Returns: "0x742d...B83A" 형식의 축약된 주소
    public var shortAddress: String {
        guard address.count > 10 else { return address }
        return "\(address.prefix(6))...\(address.suffix(4))"
    }
    
    /// 지갑 생성으로부터 경과된 일수
    /// 
    /// 지갑 사용 기간을 계산하여 통계나 사용자 경험 개선에 활용합니다.
    /// 
    /// - Returns: 생성일부터 현재까지의 경과 일수
    public var daysSinceCreation: Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
        return max(0, days)
    }
    
    /// 백업 필요 여부
    /// 
    /// UI에서 백업 알림 표시 여부를 결정할 때 사용합니다.
    /// 
    /// - Returns: 백업이 필요하면 true, 이미 완료되었으면 false
    public var needsBackup: Bool {
        return !isBackedUp
    }
    
    /// 지갑 주소 유효성 확인
    /// 
    /// 저장된 주소가 올바른 이더리움 주소 형식인지 확인합니다.
    /// 
    /// - Returns: 유효한 이더리움 주소 형식이면 true
    public var hasValidAddress: Bool {
        return address.hasPrefix("0x") && 
               address.count == 42 && 
               address.dropFirst(2).allSatisfy { $0.isHexDigit }
    }
    
    // MARK: - Display Helpers
    
    /// 지갑 정보 요약 문자열
    /// 
    /// 디버깅이나 로그에서 지갑을 간단히 식별할 때 사용합니다.
    /// 
    /// - Returns: "지갑이름 (0x742d...B83A)" 형식의 요약 문자열
    public var displaySummary: String {
        return "\(name) (\(shortAddress))"
    }
    
    /// 상세 정보 딕셔너리
    /// 
    /// 디버깅이나 분석 목적으로 지갑의 모든 정보를 구조화하여 제공합니다.
    /// 
    /// - Returns: 지갑의 모든 속성을 포함하는 딕셔너리
    public var debugInfo: [String: Any] {
        return [
            "id": id.uuidString,
            "name": name,
            "address": address,
            "shortAddress": shortAddress,
            "createdAt": createdAt,
            "isBackedUp": isBackedUp,
            "daysSinceCreation": daysSinceCreation,
            "hasValidAddress": hasValidAddress
        ]
    }
    
    /// 백업 상태를 변경한 새로운 지갑 인스턴스를 생성
    /// - Parameter isBackedUp: 새로운 백업 상태
}
