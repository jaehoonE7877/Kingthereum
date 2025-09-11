import Foundation

/// 지갑 Scene의 VIP (View-Interactor-Presenter) 아키텍처 모델 정의
/// 
/// 이 파일은 Clean Architecture의 VIP 패턴을 따라 지갑 화면의 모든 사용 사례(Use Case)를
/// Request-Response-ViewModel 구조로 정의합니다.
/// 
/// ## VIP 아키텍처 개요:
/// - **View**: UI 이벤트를 Interactor에 전달하고 ViewModel을 받아 화면 업데이트
/// - **Interactor**: 비즈니스 로직 처리 및 데이터 레이어와 통신
/// - **Presenter**: Response를 UI에 적합한 ViewModel로 변환
/// 
/// ## 데이터 흐름:
/// ```
/// View → Request → Interactor → Response → Presenter → ViewModel → View
/// ```
/// 
/// ## 지갑 Scene 주요 기능:
/// - 잔액 조회 및 USD 가치 표시
/// - 트랜잭션 전송 및 상태 관리
/// - 트랜잭션 히스토리 로드
/// - 주소 복사 및 공유
/// - 실시간 잔액 업데이트
/// 
/// ## 사용 예시:
/// ```swift
/// // Interactor에서 잔액 요청 처리
/// func getBalance(request: WalletScene.GetBalance.Request) {
///     // 블록체인에서 잔액 조회
///     let response = WalletScene.GetBalance.Response(...)
///     presenter?.presentBalance(response: response)
/// }
/// ```
public enum WalletScene {
    
    // MARK: - Get Balance Use Case
    
    /// 지갑 잔액 조회 사용 사례
    /// 
    /// 사용자의 ETH 및 ERC-20 토큰 잔액을 조회하고
    /// 실시간 환율을 적용하여 USD 가치를 함께 표시합니다.
    public enum GetBalance {
        /// 잔액 조회 요청
        /// 
        /// View에서 Interactor로 전달되는 잔액 조회 요청 데이터
        public struct Request {
            /// 조회할 지갑 주소 (0x로 시작하는 42자리 hex)
            public let walletAddress: String
            
            /// 강제 새로고침 여부 (캐시 무시)
            public let forceRefresh: Bool
            
            /// 조회할 토큰 컨트랙트 주소들 (nil이면 ETH만 조회)
            public let tokenAddresses: [String]?
            
            /// Request 초기화
            /// 
            /// - Parameters:
            ///   - walletAddress: 지갑 주소
            ///   - forceRefresh: 캐시 무시 여부 (기본값: false)
            ///   - tokenAddresses: 토큰 주소 배열 (기본값: nil)
            public init(walletAddress: String, forceRefresh: Bool = false, tokenAddresses: [String]? = nil) {
                self.walletAddress = walletAddress
                self.forceRefresh = forceRefresh
                self.tokenAddresses = tokenAddresses
            }
        }
        
        /// 잔액 조회 응답
        /// 
        /// Interactor에서 Presenter로 전달되는 원시 데이터
        public struct Response {
            /// ETH 잔액 (Wei 단위를 ETH로 변환한 문자열)
            public let balance: String
            
            /// USD 환산 가치 (nil이면 환율 조회 실패)
            public let usdValue: String?
            
            /// 토큰 잔액 목록
            public let tokenBalances: [TokenBalanceInfo]
            
            /// 마지막 업데이트 시간
            public let lastUpdated: Date
            
            /// 조회 중 발생한 오류
            public let error: Error?
            
            /// Response 초기화
            /// 
            /// - Parameters:
            ///   - balance: ETH 잔액
            ///   - usdValue: USD 가치
            ///   - tokenBalances: 토큰 잔액 배열
            ///   - lastUpdated: 업데이트 시간
            ///   - error: 오류 정보
            public init(
                balance: String, 
                usdValue: String? = nil, 
                tokenBalances: [TokenBalanceInfo] = [],
                lastUpdated: Date = Date(),
                error: Error? = nil
            ) {
                self.balance = balance
                self.usdValue = usdValue
                self.tokenBalances = tokenBalances
                self.lastUpdated = lastUpdated
                self.error = error
            }
        }
        
        /// 잔액 표시용 뷰 모델
        /// 
        /// Presenter에서 View로 전달되는 UI 표시용 데이터
        public struct ViewModel {
            /// 표시용 ETH 잔액 (포맷팅된 문자열)
            public let balance: String
            
            /// 표시용 USD 가치 (포맷팅된 문자열)
            public let usdValue: String
            
            /// 토큰 잔액 표시 정보
            public let tokenBalances: [TokenBalanceDisplayInfo]
            
            /// 총 USD 가치 (ETH + 토큰)
            public let totalUsdValue: String
            
            /// 로딩 상태 여부
            public let isLoading: Bool
            
            /// 사용자에게 표시할 오류 메시지
            public let errorMessage: String?
            
            /// 마지막 업데이트 시간 표시 문자열
            public let lastUpdatedText: String
            
            /// 새로고침 가능 여부
            public let canRefresh: Bool
            
            /// ViewModel 초기화
            /// 
            /// - Parameters:
            ///   - balance: 포맷팅된 잔액
            ///   - usdValue: 포맷팅된 USD 가치
            ///   - tokenBalances: 토큰 잔액 표시 정보
            ///   - totalUsdValue: 총 USD 가치
            ///   - isLoading: 로딩 상태
            ///   - errorMessage: 오류 메시지
            ///   - lastUpdatedText: 업데이트 시간 텍스트
            ///   - canRefresh: 새로고침 가능 여부
            public init(
                balance: String, 
                usdValue: String, 
                tokenBalances: [TokenBalanceDisplayInfo] = [],
                totalUsdValue: String = "$0.00",
                isLoading: Bool, 
                errorMessage: String? = nil,
                lastUpdatedText: String = "",
                canRefresh: Bool = true
            ) {
                self.balance = balance
                self.usdValue = usdValue
                self.tokenBalances = tokenBalances
                self.totalUsdValue = totalUsdValue
                self.isLoading = isLoading
                self.errorMessage = errorMessage
                self.lastUpdatedText = lastUpdatedText
                self.canRefresh = canRefresh
            }
        }
    }
    
    // MARK: - Send Transaction Use Case
    
    /// 트랜잭션 전송 사용 사례
    /// 
    /// ETH 또는 ERC-20 토큰을 다른 주소로 전송하는 기능을 처리합니다.
    /// 가스비 계산, 트랜잭션 서명, 브로드캐스팅 등의 전체 프로세스를 포함합니다.
    public enum SendTransaction {
        /// 트랜잭션 전송 요청
        /// 
        /// View에서 사용자가 입력한 전송 정보
        public struct Request {
            /// 수신자 주소 (0x로 시작하는 42자리 hex)
            public let toAddress: String
            
            /// 전송할 금액 (ETH 단위 또는 토큰 단위)
            public let amount: String
            
            /// 전송할 토큰 컨트랙트 주소 (nil이면 ETH 전송)
            public let tokenAddress: String?
            
            /// 사용자가 지정한 가스 가격 (Wei 단위, nil이면 자동 계산)
            public let gasPrice: String?
            
            /// 사용자가 지정한 가스 한계 (nil이면 자동 추정)
            public let gasLimit: String?
            
            /// 트랜잭션 우선순위 (낮음/보통/높음)
            public let priority: TransactionPriority
            
            /// 메모 또는 데이터 (선택사항)
            public let memo: String?
            
            /// Request 초기화
            /// 
            /// - Parameters:
            ///   - toAddress: 수신자 주소
            ///   - amount: 전송 금액
            ///   - tokenAddress: 토큰 컨트랙트 주소
            ///   - gasPrice: 가스 가격
            ///   - gasLimit: 가스 한계
            ///   - priority: 트랜잭션 우선순위
            ///   - memo: 메모
            public init(
                toAddress: String, 
                amount: String, 
                tokenAddress: String? = nil,
                gasPrice: String? = nil, 
                gasLimit: String? = nil,
                priority: TransactionPriority = .standard,
                memo: String? = nil
            ) {
                self.toAddress = toAddress
                self.amount = amount
                self.tokenAddress = tokenAddress
                self.gasPrice = gasPrice
                self.gasLimit = gasLimit
                self.priority = priority
                self.memo = memo
            }
        }
        
        /// 트랜잭션 전송 응답
        /// 
        /// Interactor에서 처리 결과를 Presenter에 전달
        public struct Response {
            /// 전송 성공 여부
            public let success: Bool
            
            /// 트랜잭션 해시 (성공 시 반환)
            public let transactionHash: String?
            
            /// 실제 사용된 가스비 (Wei 단위)
            public let actualGasFee: String?
            
            /// 트랜잭션 상태
            public let status: TransactionStatus
            
            /// 전송 완료 시점
            public let timestamp: Date?
            
            /// 발생한 오류
            public let error: Error?
            
            /// Response 초기화
            /// 
            /// - Parameters:
            ///   - success: 성공 여부
            ///   - transactionHash: 트랜잭션 해시
            ///   - actualGasFee: 실제 가스비
            ///   - status: 트랜잭션 상태
            ///   - timestamp: 완료 시점
            ///   - error: 오류 정보
            public init(
                success: Bool, 
                transactionHash: String? = nil, 
                actualGasFee: String? = nil,
                status: TransactionStatus = .pending,
                timestamp: Date? = nil,
                error: Error? = nil
            ) {
                self.success = success
                self.transactionHash = transactionHash
                self.actualGasFee = actualGasFee
                self.status = status
                self.timestamp = timestamp
                self.error = error
            }
        }
        
        /// 트랜잭션 전송 결과 뷰 모델
        /// 
        /// Presenter에서 View로 전달되는 UI 표시용 데이터
        public struct ViewModel {
            /// 전송 성공 여부
            public let success: Bool
            
            /// 표시용 트랜잭션 해시 (축약된 형태)
            public let transactionHash: String?
            
            /// 완전한 트랜잭션 해시 (복사/공유용)
            public let fullTransactionHash: String?
            
            /// 사용자에게 표시할 상태 메시지
            public let statusMessage: String
            
            /// 사용자에게 표시할 오류 메시지
            public let errorMessage: String?
            
            /// 블록체인 탐색기 URL
            public let explorerURL: String?
            
            /// 다음 액션 버튼 텍스트
            public let nextActionTitle: String?
            
            /// 결과 화면 표시 여부
            public let shouldShowResult: Bool
            
            /// ViewModel 초기화
            /// 
            /// - Parameters:
            ///   - success: 성공 여부
            ///   - transactionHash: 축약 트랜잭션 해시
            ///   - fullTransactionHash: 전체 트랜잭션 해시
            ///   - statusMessage: 상태 메시지
            ///   - errorMessage: 오류 메시지
            ///   - explorerURL: 탐색기 URL
            ///   - nextActionTitle: 다음 액션 제목
            ///   - shouldShowResult: 결과 표시 여부
            public init(
                success: Bool, 
                transactionHash: String? = nil,
                fullTransactionHash: String? = nil,
                statusMessage: String,
                errorMessage: String? = nil,
                explorerURL: String? = nil,
                nextActionTitle: String? = nil,
                shouldShowResult: Bool = true
            ) {
                self.success = success
                self.transactionHash = transactionHash
                self.fullTransactionHash = fullTransactionHash
                self.statusMessage = statusMessage
                self.errorMessage = errorMessage
                self.explorerURL = explorerURL
                self.nextActionTitle = nextActionTitle
                self.shouldShowResult = shouldShowResult
            }
        }
    }
    
    // MARK: - Load Transactions
    public enum LoadTransactions {
        public struct Request {
            public let walletAddress: String
            
            public init(walletAddress: String) {
                self.walletAddress = walletAddress
            }
        }
        
        public struct Response {
            public let transactions: [TransactionDisplayItem]
            public let error: Error?
            
            public init(transactions: [TransactionDisplayItem], error: Error? = nil) {
                self.transactions = transactions
                self.error = error
            }
        }
        
        public struct ViewModel {
            public let transactions: [TransactionDisplayItem]
            public let isLoading: Bool
            public let errorMessage: String?
            
            public init(transactions: [TransactionDisplayItem], isLoading: Bool, errorMessage: String? = nil) {
                self.transactions = transactions
                self.isLoading = isLoading
                self.errorMessage = errorMessage
            }
        }
    }
    
    // MARK: - Copy Address
    public enum CopyAddress {
        public struct Request {
            public let address: String
            
            public init(address: String) {
                self.address = address
            }
        }
        
        public struct Response {
            public let success: Bool
            
            public init(success: Bool) {
                self.success = success
            }
        }
        
        public struct ViewModel {
            public let message: String
            
            public init(message: String) {
                self.message = message
            }
        }
    }
}

/// 거래 타입 (포괄적 정의)
public enum WalletTransactionType: String, CaseIterable, Sendable {
    case send = "send"
    case receive = "receive"
    case swap = "swap"
    case approval = "approval"
    case contract = "contract"
    
    public var displayName: String {
        switch self {
        case .send: return "송금"
        case .receive: return "수신"
        case .swap: return "스왑"
        case .approval: return "승인"
        case .contract: return "컨트랙트"
        }
    }
    
    public var iconName: String {
        switch self {
        case .send: return "arrow.up.circle.fill"
        case .receive: return "arrow.down.circle.fill"
        case .swap: return "arrow.triangle.2.circlepath"
        case .approval: return "checkmark.circle.fill"
        case .contract: return "doc.text.fill"
        }
    }
    
    public var color: String {
        switch self {
        case .send: return "red"
        case .receive: return "green"
        case .swap: return "blue"
        case .approval: return "orange"
        case .contract: return "purple"
        }
    }
    
    public var symbol: String {
        switch self {
        case .send: return "↗"
        case .receive: return "↙"
        case .swap: return "⇄"
        case .approval: return "✓"
        case .contract: return "📄"
        }
    }
}


/// 거래 표시용 아이템
public struct TransactionDisplayItem: Identifiable {
    public let id = UUID()
    public let hash: String
    public let type: WalletTransactionType
    public let amount: String
    public let address: String
    public let date: String
    public let status: TransactionStatus
    
    public init(hash: String, type: WalletTransactionType, amount: String, address: String, date: String, status: TransactionStatus) {
        self.hash = hash
        self.type = type
        self.amount = amount
        self.address = address
        self.date = date
        self.status = status
    }
}

// MARK: - Supporting Types

/// 토큰 잔액 정보 (내부 데이터)
public struct TokenBalanceInfo {
    /// 토큰 컨트랙트 주소
    public let address: String
    /// 토큰 심볼 (예: "USDC", "DAI")
    public let symbol: String
    /// 토큰 이름 (예: "USD Coin")
    public let name: String
    /// 잔액 (토큰 단위)
    public let balance: String
    /// 소수점 자릿수
    public let decimals: Int
    /// USD 가치
    public let usdValue: String?
    
    public init(address: String, symbol: String, name: String, balance: String, decimals: Int, usdValue: String? = nil) {
        self.address = address
        self.symbol = symbol
        self.name = name
        self.balance = balance
        self.decimals = decimals
        self.usdValue = usdValue
    }
}

/// 토큰 잔액 표시 정보 (UI 표시용)
public struct TokenBalanceDisplayInfo: Identifiable {
    public let id = UUID()
    /// 토큰 심볼
    public let symbol: String
    /// 포맷팅된 잔액
    public let formattedBalance: String
    /// 포맷팅된 USD 가치
    public let formattedUsdValue: String
    /// 토큰 아이콘 URL
    public let iconURL: String?
    /// 변화율 (24시간)
    public let changePercentage: String?
    /// 변화율이 양수인지 여부
    public let isPositiveChange: Bool
    
    public init(symbol: String, formattedBalance: String, formattedUsdValue: String, iconURL: String? = nil, changePercentage: String? = nil, isPositiveChange: Bool = true) {
        self.symbol = symbol
        self.formattedBalance = formattedBalance
        self.formattedUsdValue = formattedUsdValue
        self.iconURL = iconURL
        self.changePercentage = changePercentage
        self.isPositiveChange = isPositiveChange
    }
}

/// 트랜잭션 우선순위
public enum TransactionPriority: String, CaseIterable {
    case slow = "slow"
    case standard = "standard"
    case fast = "fast"
    
    public var displayName: String {
        switch self {
        case .slow: return "느림"
        case .standard: return "보통" 
        case .fast: return "빠름"
        }
    }
    
    public var description: String {
        switch self {
        case .slow: return "낮은 가스비, 느린 처리 (~10분)"
        case .standard: return "적정 가스비, 보통 처리 (~3분)"
        case .fast: return "높은 가스비, 빠른 처리 (~1분)"
        }
    }
    
    /// 우선순위에 따른 가스비 승수
    public var gasMultiplier: Double {
        switch self {
        case .slow: return 0.8
        case .standard: return 1.0
        case .fast: return 1.5
        }
    }
}
