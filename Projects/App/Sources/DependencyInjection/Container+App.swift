import Foundation
import Core
import WalletKit
import SecurityKit
import Factory
import Entity
import os.log

// MARK: - App Module Services Factory Registration

/// App 모듈의 서비스들을 Factory 방식으로 등록
/// Swift 6.0 strict concurrency 규칙 준수
public extension Container {
    
    /// DisplayModeService 구현체 (MainActor 격리)
    /// 다크모드/라이트모드 관리 서비스
    var displayModeService: Factory<DisplayModeService> {
        self {
            MainActor.assumeIsolated {
                DisplayModeService()
            }
        }
        .singleton
    }
    
    /// WalletService 구현체
    /// 지갑 관련 핵심 비즈니스 로직 처리
    var walletService: Factory<WalletService> {
        self {
            // 안전한 Container 접근을 위한 Task 사용
            let configService = Container.shared.configurationService()
            let rpcURL = configService.ethereumRPCURL
            
            // WalletService.shared를 사용하거나 새로 초기화
            do {
                let service = try WalletService.initialize(rpcURL: rpcURL)
                return service
            } catch {
                // 더 나은 에러 핸들링
                fatalError("Critical service initialization failed: \(error.localizedDescription)")
            }
        }
        .singleton
    }
    
    /// SecurityService 구현체
    /// 생체 인식, PIN 인증 등 보안 기능 담당
    var securityService: Factory<SecurityService> {
        self { SecurityService() }
            .singleton
    }
    /// HistoryService 구현체 (네이밍 통일)
    /// Etherscan API를 통한 블록체인 거래 내역 처리
    var historyService: Factory<HistoryServiceProtocol> {
        self {
            let etherscanService = EtherscanService()
            return HistoryService(etherscanService: etherscanService)
        }
        .singleton
    }
    
    /// EtherscanService 구현체
    /// Ethereum 블록체인 데이터 API 서비스
    var etherscanService: Factory<EtherscanService> {
        self { EtherscanService() }
            .singleton
    }
    
}

// MARK: - Thread-Safe Container Access

/// Thread-safe Container 접근을 위한 헬퍼
/// Swift 6.0 동시성 안전성 보장
public actor ContainerManager {
    private let container: Container
    
    public init(container: Container = Container.shared) {
        self.container = container
    }
    
    /// WalletService 안전한 해결
    public func resolveWalletService() -> WalletService {
        container.walletService()
    }
    
    
    /// DisplayModeService 안전한 해결 (MainActor)
    @MainActor
    public func resolveDisplayModeService() -> DisplayModeService {
        container.displayModeService()
    }
    
    /// SecurityService 안전한 해결
    public func resolveSecurityService() -> SecurityService {
        container.securityService()
    }
    
    /// HistoryService 안전한 해결
    public func resolveHistoryService() -> HistoryServiceProtocol {
        container.historyService()
    }
    
    /// EtherscanService 안전한 해결
    public func resolveEtherscanService() -> EtherscanService {
        container.etherscanService()
    }
}

// MARK: - Service Protocol Extensions for Sendable

/// DisplayModeService가 Sendable을 준수하도록 확장
extension DisplayModeService: @unchecked Sendable {
    // DisplayModeService는 @MainActor로 격리되어 있어 thread-safe함
}
