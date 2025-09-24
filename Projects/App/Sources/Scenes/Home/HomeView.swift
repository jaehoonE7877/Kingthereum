import SwiftUI

import Core
import DesignSystem
import Entity
import PriceKit
import WalletKit

import Factory

// MARK: - HomeViewStore

final class HomeViewStore {
    // UI 상태 관리
    struct UIState {
        var isLoading = false
        var isRefreshing = false
        var errorMessage: String?
        var isScrollingDown = false
    }
    
    // 스크롤 상태 관리
    struct ScrollState {
        var lastOffset: CGFloat = 0
        var isScrollingDown = false
    }
    
    // 가격 데이터 관리
    struct PriceData {
        var ethPrice: CoinPrice?
        var cryptoPrices: [CoinPrice] = []
        var portfolioValue = "$0.00"
    }
    
    // 지갑 기본 정보
    struct WalletData {
        var balance = "0.0"
        var symbol = "ETH"
        var walletAddress: String?
    }
    
    var uiState = UIState()
    var scrollState = ScrollState()
    var priceData = PriceData()
    var walletData = WalletData()
    
    @Injected(\.priceService) private var priceService: PriceServiceProtocol
    @Injected(\.walletService) private var walletService: WalletServiceProtocol
    
    // 캐시 관리
    private var lastRefreshTime: Date?
    private let cacheValidDuration: TimeInterval = 300 // 5분
    
    var shouldHideTabBar: Bool {
        scrollState.isScrollingDown
    }
    
    init() {}
    
    // MARK: - Actions
    
    func handleScrollOffset(_ offset: CGFloat) {
        let currentOffset = -offset
        let threshold: CGFloat = 100
        let scrollThreshold: CGFloat = 10
        
        guard abs(currentOffset - scrollState.lastOffset) > scrollThreshold else {
            return
        }
        
        scrollState.isScrollingDown = currentOffset > scrollState.lastOffset && currentOffset > threshold
        scrollState.lastOffset = currentOffset
    }
    
    @MainActor
    func loadData() async {
        uiState.isLoading = true
        uiState.errorMessage = nil
        
        do {
            // 순차적으로 데이터 로드
            try await loadWalletData()
            try await loadPriceData()
            calculatePortfolioValue()
        } catch {
            uiState.errorMessage = "데이터를 불러오는데 실패했습니다: \(error.localizedDescription)"
        }
        
        uiState.isLoading = false
    }
    
    @MainActor
    private func loadWalletData() async throws {
        let address = try await walletService.getCurrentWalletAddress()
        let balanceInEth = try await walletService.getBalance(for: address)
        
        walletData.walletAddress = address
        walletData.balance = balanceInEth
        walletData.symbol = "ETH"
    }
    
    @MainActor
    private func loadPriceData() async throws {
        // ETH 가격 조회
        priceData.ethPrice = try await priceService.getCurrentPrice(for: "ETH")
        
        // 주요 암호화폐 가격 조회
        let cryptoSymbols = ["BTC", "ADA", "DOT", "LINK"]
        priceData.cryptoPrices = try await priceService.getCurrentPrices(for: cryptoSymbols)
    }
    
    private func calculatePortfolioValue() {
        guard let ethPrice = priceData.ethPrice,
              let balanceDecimal = Decimal(string: walletData.balance) else {
            priceData.portfolioValue = "$0.00"
            return
        }
        
        let portfolioValueDecimal = balanceDecimal * ethPrice.currentPrice
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        
        priceData.portfolioValue = formatter.string(from: portfolioValueDecimal as NSDecimalNumber) ?? "$0.00"
    }
}

// MARK: - HomeView

struct HomeView: View {
    @Binding var showTabBar: Bool
    
    @State private var viewStore = HomeViewStore()
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    LazyVStack(spacing: KingDesignTokens.Spacing.xl) {
                        // 포트폴리오 개요 카드
                        PortfolioOverviewCard(
                            balance: viewStore.walletData.balance,
                            symbol: viewStore.walletData.symbol,
                            portfolioValue: viewStore.priceData.portfolioValue,
                            ethPrice: viewStore.priceData.ethPrice,
                            isLoading: viewStore.uiState.isLoading
                        )
                        .padding(.horizontal, KingDesignTokens.Spacing.lg)
                        .padding(.top, KingDesignTokens.Spacing.m)
                        
                        // 시장 개요 섹션
                        MarketOverviewSection(
                            cryptoPrices: viewStore.priceData.cryptoPrices,
                            isLoading: viewStore.uiState.isLoading
                        )
                        .padding(.horizontal, KingDesignTokens.Spacing.lg)
                        
                        // 가격 알림 및 뉴스 섹션 (추후 확장)
                        QuickActionsSection()
                            .padding(.horizontal, KingDesignTokens.Spacing.lg)
                        
                        Spacer(minLength: 120)
                    }
                }
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentOffset.y
                } action: { oldValue, newValue in
                    viewStore.handleScrollOffset(newValue)
                }
                .refreshable {
                    await viewStore.loadData()
                }
                .accessibilityLabel("홈 화면")
                .accessibilityHint("스크롤하여 포트폴리오와 시장 정보를 확인하거나 새로고침하세요")
            }
            .background(KingDesignTokens.Gradients.background)
            .navigationTitle("홈")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(KingDesignTokens.Colors.background.opacity(0.95), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onChange(of: viewStore.shouldHideTabBar) { _, shouldHide in
                withAnimation(KingDesignTokens.Animation.normal) {
                    showTabBar = !shouldHide
                }
            }
            .task {
                await viewStore.loadData()
            }
            .alert("오류", isPresented: Binding(
                get: { viewStore.uiState.errorMessage != nil },
                set: { _ in viewStore.uiState.errorMessage = nil }
            )) {
                Button("확인", role: .cancel) {
                    viewStore.uiState.errorMessage = nil
                }
            } message: {
                Text(viewStore.uiState.errorMessage ?? "")
            }
        }
    }
}

// MARK: - Portfolio Overview Card

struct PortfolioOverviewCard: View {
    let balance: String
    let symbol: String
    let portfolioValue: String
    let ethPrice: CoinPrice?
    let isLoading: Bool
    
    @State private var animationPhase: CGFloat = 0.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    private var glowIntensity: Double {
        0.3 + (animationPhase * 0.5)
    }
    
    private var pulseScale: CGFloat {
        1.0 + (animationPhase * 0.08)
    }
    
    var body: some View {
        VStack(spacing: KingDesignTokens.Spacing.lg) {
            // 헤더
            HStack {
                VStack(alignment: .leading, spacing: KingDesignTokens.Spacing.xs) {
                    Text("포트폴리오")
                        .font(KingDesignTokens.Typography.bodyLarge)
                        .foregroundColor(KingDesignTokens.Colors.secondaryText)
                        .accessibilityAddTraits(.isHeader)
                    
                    Text("총 자산 가치")
                        .font(KingDesignTokens.Typography.bodyMedium)
                        .foregroundColor(KingDesignTokens.Colors.tertiaryText)
                }
                
                Spacer()
                
                // ETH 가격 정보
                if let ethPrice = ethPrice {
                    VStack(alignment: .trailing, spacing: KingDesignTokens.Spacing.xxs) {
                        HStack {
                            Text("ETH")
                                .font(KingDesignTokens.Typography.labelMedium)
                                .foregroundColor(KingDesignTokens.Colors.secondaryText)
                            
                            Text("$\(ethPrice.currentPrice as NSDecimalNumber, formatter: priceFormatter)")
                                .font(KingDesignTokens.Typography.labelMedium)
                                .foregroundColor(KingDesignTokens.Colors.success)
                        }
                        
                        if let change = ethPrice.priceChange24h {
                            Text("\(change > 0 ? "+" : "")\(change as NSDecimalNumber, formatter: percentFormatter)%")
                                .font(KingDesignTokens.Typography.caption)
                                .foregroundColor(change >= 0 ? KingDesignTokens.Colors.success : KingDesignTokens.Colors.error)
                        }
                    }
                }
            }
            
            // 메인 포트폴리오 값 표시
            VStack(spacing: KingDesignTokens.Spacing.sm) {
                if isLoading {
                    KingLoadingView(style: .skeleton, size: .medium)
                        .frame(height: 80)
                        .accessibilityLabel("포트폴리오 로딩 중")
                } else {
                    Text(portfolioValue)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    KingDesignTokens.Colors.accent,
                                    KingDesignTokens.Colors.accent.opacity(0.8),
                                    KingDesignTokens.Colors.primary.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(
                            color: KingDesignTokens.Colors.accent.opacity(0.3),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .accessibilityLabel("총 포트폴리오 가치 \(portfolioValue)")
                    
                    // 보유 ETH 표시
                    HStack {
                        Text(balance)
                            .font(KingDesignTokens.Typography.headlineLarge)
                            .foregroundColor(KingDesignTokens.Colors.primaryText)
                        
                        Text(symbol)
                            .font(KingDesignTokens.Typography.bodyMedium)
                            .foregroundColor(KingDesignTokens.Colors.secondaryText)
                    }
                    .accessibilityLabel("\(balance) \(symbol) 보유")
                }
            }
        }
        .padding(KingDesignTokens.Spacing.xxxl)
        .frame(maxWidth: .infinity)
        .background(
            KingCard(style: .glass, size: .expanded) {
                EmptyView()
            }
        )
        .onAppear {
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                    animationPhase = 1.0
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("포트폴리오 카드. 총 가치 \(portfolioValue), \(balance) \(symbol) 보유")
    }
    
    private var priceFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter
    }
    
    private var percentFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }
}

// MARK: - Market Overview Section

struct MarketOverviewSection: View {
    let cryptoPrices: [CoinPrice]
    let isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: KingDesignTokens.Spacing.lg) {
            // 섹션 헤더
            HStack {
                Text("시장 현황")
                    .font(KingDesignTokens.Typography.headlineLarge)
                    .foregroundColor(KingDesignTokens.Colors.primaryText)
                    .accessibilityAddTraits(.isHeader)
                
                Spacer()
                
                Button("전체보기") {
                    // Navigate to full market view
                }
                .font(KingDesignTokens.Typography.labelMedium)
                .foregroundColor(KingDesignTokens.Colors.primary)
                .accessibilityHint("전체 시장 정보를 확인합니다")
            }
            
            // 가격 리스트
            if isLoading {
                VStack(spacing: KingDesignTokens.Spacing.sm) {
                    ForEach(0..<4, id: \.self) { _ in
                        CoinPriceRowSkeleton()
                    }
                }
            } else if cryptoPrices.isEmpty {
                KingCard(style: .outlined) {
                    VStack(spacing: KingDesignTokens.Spacing.m) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: KingDesignTokens.Sizing.iconLG))
                            .foregroundColor(KingDesignTokens.Colors.tertiaryText)
                        
                        Text("시장 정보를 불러올 수 없습니다")
                            .font(KingDesignTokens.Typography.body)
                            .foregroundColor(KingDesignTokens.Colors.secondaryText)
                    }
                    .padding(.vertical, KingDesignTokens.Spacing.lg)
                }
            } else {
                LazyVStack(spacing: KingDesignTokens.Spacing.sm) {
                    ForEach(cryptoPrices, id: \.symbol) { price in
                        CoinPriceRow(coinPrice: price)
                    }
                }
            }
        }
    }
}

// MARK: - Coin Price Row

struct CoinPriceRow: View {
    let coinPrice: CoinPrice
    
    var body: some View {
        HStack(spacing: KingDesignTokens.Spacing.m) {
            // 코인 아이콘 및 정보
            HStack(spacing: KingDesignTokens.Spacing.m) {
                // 코인 아이콘
                ZStack {
                    Circle()
                        .fill(KingDesignTokens.Colors.surfaceVariant)
                        .frame(width: 40, height: 40)
                    
                    Text(coinPrice.symbol.prefix(1))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(KingDesignTokens.Colors.primary)
                }
                
                VStack(alignment: .leading, spacing: KingDesignTokens.Spacing.xxs) {
                    Text(coinPrice.symbol)
                        .font(KingDesignTokens.Typography.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(KingDesignTokens.Colors.primaryText)
                    
                    Text(coinPrice.name)
                        .font(KingDesignTokens.Typography.caption)
                        .foregroundColor(KingDesignTokens.Colors.secondaryText)
                }
            }
            
            Spacer()
            
            // 가격 정보
            VStack(alignment: .trailing, spacing: KingDesignTokens.Spacing.xxs) {
                Text("$\(coinPrice.currentPrice as NSDecimalNumber, formatter: priceFormatter)")
                    .font(KingDesignTokens.Typography.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(KingDesignTokens.Colors.primaryText)
                
                if let change = coinPrice.priceChange24h {
                    Text("\(change > 0 ? "+" : "")\(change as NSDecimalNumber, formatter: percentFormatter)%")
                        .font(KingDesignTokens.Typography.caption)
                        .foregroundColor(change >= 0 ? KingDesignTokens.Colors.success : KingDesignTokens.Colors.error)
                }
            }
        }
        .padding(.vertical, KingDesignTokens.Spacing.sm)
        .padding(.horizontal, KingDesignTokens.Spacing.m)
        .background(
            KingCard(style: .flat, size: .compact, isInteractive: true) {
                EmptyView()
            }
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(coinPrice.name) \(coinPrice.symbol). 현재 가격 $\(coinPrice.currentPrice as NSDecimalNumber, formatter: priceFormatter)")
    }
    
    private var priceFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter
    }
    
    private var percentFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }
}

// MARK: - Coin Price Row Skeleton

struct CoinPriceRowSkeleton: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: KingDesignTokens.Spacing.m) {
            // 아이콘 스켈레톤
            Circle()
                .fill(KingDesignTokens.Colors.onSurfaceVariant.opacity(0.3))
                .frame(width: 40, height: 40)
            
            // 텍스트 스켈레톤
            VStack(alignment: .leading, spacing: KingDesignTokens.Spacing.xs) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(KingDesignTokens.Colors.onSurfaceVariant.opacity(0.3))
                    .frame(width: 60, height: 16)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(KingDesignTokens.Colors.onSurfaceVariant.opacity(0.2))
                    .frame(width: 80, height: 12)
            }
            
            Spacer()
            
            // 가격 스켈레톤
            VStack(alignment: .trailing, spacing: KingDesignTokens.Spacing.xs) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(KingDesignTokens.Colors.onSurfaceVariant.opacity(0.3))
                    .frame(width: 70, height: 16)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(KingDesignTokens.Colors.onSurfaceVariant.opacity(0.2))
                    .frame(width: 50, height: 12)
            }
        }
        .padding(.vertical, KingDesignTokens.Spacing.sm)
        .padding(.horizontal, KingDesignTokens.Spacing.m)
        .background(
            KingCard(style: .flat, size: .compact) {
                EmptyView()
            }
        )
        .opacity(isAnimating ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: isAnimating)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Quick Actions Section

struct QuickActionsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: KingDesignTokens.Spacing.lg) {
            Text("빠른 액세스")
                .font(KingDesignTokens.Typography.headlineLarge)
                .foregroundColor(KingDesignTokens.Colors.primaryText)
                .accessibilityAddTraits(.isHeader)
            
            HStack(spacing: KingDesignTokens.Spacing.m) {
                QuickActionButton(
                    icon: "bell",
                    title: "가격 알림",
                    action: {
                        // Navigate to price alerts
                    }
                )
                
                QuickActionButton(
                    icon: "newspaper",
                    title: "뉴스",
                    action: {
                        // Navigate to crypto news
                    }
                )
                
                QuickActionButton(
                    icon: "chart.bar",
                    title: "분석",
                    action: {
                        // Navigate to market analysis
                    }
                )
            }
        }
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: KingDesignTokens.Spacing.sm) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(KingDesignTokens.Colors.primary)
                    .accessibilityHidden(true)
                
                Text(title)
                    .font(KingDesignTokens.Typography.labelMedium)
                    .foregroundColor(KingDesignTokens.Colors.primaryText)
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, KingDesignTokens.Spacing.lg)
            .background(
                KingCard(style: .outlined, size: .regular, isInteractive: true) {
                    EmptyView()
                }
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement()
        .accessibilityLabel(title)
        .accessibilityHint("\(title) 화면으로 이동합니다")
        .accessibilityAddTraits(.isButton)
    }
}

