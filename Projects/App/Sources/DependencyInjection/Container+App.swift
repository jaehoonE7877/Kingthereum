import Foundation

import Core
import Entity
import SecurityKit
import WalletKit
import PriceKit

import Factory

// MARK: - App Module Services Factory Registration

/// App 모듈의 서비스들을 Factory 방식으로 등록
/// Swift 6.0 strict concurrency 규칙 준수
public extension Container {
    
    /// DisplayModeService 구현체 (MainActor 격리)
    /// 다크모드/라이트모드 관리 서비스
    var displayModeService: Factory<DisplayModeService> {
        self {
            // MainActor에서 안전하게 DisplayModeService 생성
            // assumeIsolated는 현재 컨텍스트가 MainActor임을 가정
            return MainActor.assumeIsolated {
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
    
    // SecurityService는 이제 SecurityKit/Container+SecurityKit.swift에서 관리됨
    /// HistoryService 구현체 (네이밍 통일)
    /// Etherscan API를 통한 블록체인 거래 내역 처리
    var historyService: Factory<HistoryService> {
        self {
            return HistoryService()
        }
        .singleton
    }
    
    /// EtherscanService 구현체
    /// Ethereum 블록체인 데이터 API 서비스
    var etherscanService: Factory<EtherscanService> {
        self {
            MainActor.assumeIsolated {
                EtherscanService()
            }
        }
        .singleton
    }
    
    /// PriceService 구현체
    /// 암호화폐 가격 정보 서비스 (CoinGecko API 연동)
    var priceService: Factory<PriceServiceProtocol> {
        self {
            return PriceService(
                networkService: self.priceNetworkService(),
                cacheService: self.priceCacheService(),
                configuration: self.priceConfiguration
            )
        }
        .singleton
    }
    
    // MARK: - Internal Price Services
    
    /// Price Network Service
    var priceNetworkService: Factory<PriceNetworkProtocol> {
        self { CoinGeckoPriceNetwork(configuration: self.priceConfiguration) }
        .singleton
    }
    
    /// Price Cache Service  
    var priceCacheService: Factory<PriceCacheProtocol> {
        self { InMemoryPriceCache() }
        .singleton
    }
    
    /// PriceConfiguration (xcconfig API 키 사용)
    internal var priceConfiguration: PriceConfiguration {
        let apiKey = Bundle.main.object(forInfoDictionaryKey: "COINGECKO_API_KEY") as? String
        
        return PriceConfiguration(
            apiKey: apiKey,
            cacheDuration: 300, // 5분 캐시
            requestTimeout: 10   // 10초 타임아웃
        )
    }
    
}

// MARK: - Thread-Safe Container Access

/// Thread-safe Container 접근을 위한 헬퍼
/// Swift 6.0 동시성 안전성 보장
actor ContainerManager {
    
    private let container: Container
    
    init(container: Container = Container.shared) {
        self.container = container
    }
    
    /// WalletService 안전한 해결
    func resolveWalletService() -> WalletService {
        container.walletService()
    }
    
    
    /// DisplayModeService 안전한 해결 (MainActor)
    @MainActor
    func resolveDisplayModeService() -> DisplayModeService {
        container.displayModeService()
    }
    
    /// SecurityService 안전한 해결 (SecurityKit에서 제공)
    func resolveSecurityService() async -> any SecurityServiceProtocol {
        await container.resolveSecurityService()
    }
    
    /// HistoryService 안전한 해결
    func resolveHistoryService() -> HistoryService {
        container.historyService()
    }
    
    /// EtherscanService 안전한 해결
    func resolveEtherscanService() -> EtherscanService {
        container.etherscanService()
    }
    
    /// PriceService 안전한 해결
    func resolvePriceService() -> PriceServiceProtocol {
        container.priceService()
    }
}

// MARK: - Service Protocol Extensions for Sendable

/// DisplayModeService가 Sendable을 준수하도록 확장
extension DisplayModeService: @unchecked Sendable {
    // DisplayModeService는 @MainActor로 격리되어 있어 thread-safe함
}
