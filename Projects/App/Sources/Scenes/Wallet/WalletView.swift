import SwiftUI

import Core
import DesignSystem
import Entity
import PriceKit
import WalletKit

import Factory

// MARK: - WalletViewStore

@MainActor
final class WalletViewStore: ObservableObject {
    // UI 상태 관리
    struct UIState {
        var showSendView = false
        var isScrollingDown = false
        var isLoading = false
        var errorMessage: String?
        var isRefreshing = false
    }
    
    // 스크롤 상태 관리
    struct ScrollState {
        var lastOffset: CGFloat = 0
        var isScrollingDown = false
    }
    
    // 지갑 데이터 관리
    struct WalletData {
        var balance = "0.0"
        var usdValue = "$0.00"
        var symbol = "ETH"
        var walletAddress: String?
    }
    
    @Published var uiState = UIState()
    @Published var scrollState = ScrollState()
    @Published var walletData = WalletData()
    
    // 거래 내역
    @Published var transactions: [Entity.Transaction] = []
    
    @Injected(\.walletService) private var walletService: WalletServiceProtocol
    @Injected(\.etherscanService) private var etherscanService: EtherscanService
    @Injected(\.priceService) private var priceService: PriceServiceProtocol
    
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
    func loadWalletData() async {
        uiState.isLoading = true
        uiState.errorMessage = nil
        
        do {
            // 현재 지갑 주소 조회
            let address = try await walletService.getCurrentWalletAddress()
            
            // 잔액 조회
            let balanceInEth = try await walletService.getBalance(for: address)
            
            // 거래 내역 조회
            let etherscanResponse = try await etherscanService.getTransactionHistory(address: address)
            let transactionHistory = etherscanResponse.result.map { $0.toTransaction() }
            
            walletData.walletAddress = address
            walletData.balance = balanceInEth
            walletData.symbol = "ETH"
            
            // USD 환율 조회
            do {
                let ethPriceUSD = try await priceService.getETHPriceInUSD()
                let balanceDecimal = Decimal(string: balanceInEth) ?? 0
                let usdValueDecimal = balanceDecimal * ethPriceUSD
                
                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                formatter.currencyCode = "USD"
                formatter.maximumFractionDigits = 2
                
                walletData.usdValue = formatter.string(from: usdValueDecimal as NSDecimalNumber) ?? "$0.00"
            } catch {
                walletData.usdValue = "$0.00"
            }
            
            // 거래 내역 업데이트
            transactions = transactionHistory
            
        } catch {
            uiState.errorMessage = "지갑 데이터를 불러오는데 실패했습니다: \(error.localizedDescription)"
        }
        
        uiState.isLoading = false
    }
    
    func showSendView() {
        uiState.showSendView = true
    }
    
    func hideSendView() {
        uiState.showSendView = false
    }
}

// MARK: - WalletView

struct WalletView: View {
    @Binding var showTabBar: Bool
    @Binding var showReceiveView: Bool
    
    @StateObject private var viewStore = WalletViewStore()
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    LazyVStack(spacing: KingDesignTokens.Spacing.xl) {
                        // 지갑 잔액 카드
                        WalletBalanceCard(
                            balance: viewStore.walletData.balance,
                            symbol: viewStore.walletData.symbol,
                            usdValue: viewStore.walletData.usdValue,
                            isLoading: viewStore.uiState.isLoading,
                            isScrollingDown: viewStore.scrollState.isScrollingDown
                        )
                        .padding(.horizontal, KingDesignTokens.Spacing.lg)
                        .padding(.top, KingDesignTokens.Spacing.m)
                        
                        // 지갑 액션 버튼들
                        WalletActionButtons(
                            onSendTapped: { viewStore.showSendView() },
                            onReceiveTapped: { showReceiveView = true }
                        )
                        .padding(.horizontal, KingDesignTokens.Spacing.lg)
                        
                        // 지갑 관리 옵션
                        WalletManagementSection()
                            .padding(.horizontal, KingDesignTokens.Spacing.lg)
                        
                        // 거래 내역
                        TransactionHistorySection(transactions: viewStore.transactions)
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
                    await viewStore.loadWalletData()
                }
                .accessibilityLabel("지갑 화면")
                .accessibilityHint("스크롤하여 지갑 정보와 거래 내역을 확인하거나 새로고침하세요")
            }
            .background(KingDesignTokens.Gradients.background)
            .navigationTitle("지갑")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(KingDesignTokens.Colors.background.opacity(0.95), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onChange(of: viewStore.shouldHideTabBar) { _, shouldHide in
                withAnimation(KingDesignTokens.Animation.normal) {
                    showTabBar = !shouldHide
                }
            }
            .task {
                await viewStore.loadWalletData()
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
        .sheet(isPresented: Binding(
            get: { viewStore.uiState.showSendView },
            set: { _ in viewStore.hideSendView() }
        )) {
            SendView()
        }
    }
}

// MARK: - Wallet Balance Card

struct WalletBalanceCard: View {
    let balance: String
    let symbol: String
    let usdValue: String
    let isLoading: Bool
    let isScrollingDown: Bool
    
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
            // 헤더: 잔액
            HStack {
                VStack(alignment: .leading, spacing: KingDesignTokens.Spacing.xs) {
                    Text("현재 잔액")
                        .font(KingDesignTokens.Typography.bodyLarge)
                        .foregroundColor(KingDesignTokens.Colors.secondaryText)
                        .accessibilityAddTraits(.isHeader)
                    
                    Text("이더리움 메인넷")
                        .font(KingDesignTokens.Typography.bodyMedium)
                        .foregroundColor(KingDesignTokens.Colors.tertiaryText)
                }
                
                Spacer()
                
                // 이더리움 심볼
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    KingDesignTokens.Colors.accent.opacity(0.3),
                                    KingDesignTokens.Colors.accent.opacity(0.1)
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: 25
                            )
                        )
                        .frame(width: 50, height: 50)
                        .shadow(
                            color: KingDesignTokens.Colors.accent.opacity(glowIntensity),
                            radius: 16,
                            x: 0,
                            y: 0
                        )
                        .scaleEffect(pulseScale)
                    
                    Text("Ξ")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    KingDesignTokens.Colors.accent,
                                    KingDesignTokens.Colors.accent.opacity(0.8)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .accessibilityLabel("이더리움")
            }
            
            // 메인 잔액 표시
            VStack(spacing: KingDesignTokens.Spacing.sm) {
                if isLoading {
                    KingLoadingView(style: .skeleton, size: .medium)
                        .frame(height: 80)
                        .accessibilityLabel("잔액 로딩 중")
                } else {
                    // 대형 잔액 수치
                    HStack(alignment: .firstTextBaseline, spacing: KingDesignTokens.Spacing.sm) {
                        Text(balance)
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
                            .accessibilityLabel("잔액 \(balance)")
                        
                        Text(symbol)
                            .font(KingDesignTokens.Typography.headlineLarge)
                            .foregroundColor(KingDesignTokens.Colors.secondaryText)
                            .padding(.bottom, 4)
                            .accessibilityLabel("\(symbol) 단위")
                    }
                    
                    // USD 값
                    Text(usdValue)
                        .font(KingDesignTokens.Typography.bodyLarge)
                        .foregroundColor(KingDesignTokens.Colors.tertiaryText)
                        .accessibilityLabel("USD 환산 \(usdValue)")
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
        .scaleEffect(isScrollingDown ? 0.96 : 1.0)
        .animation(KingDesignTokens.Animation.spring, value: isScrollingDown)
        .onAppear {
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                    animationPhase = 1.0
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("지갑 잔액 카드. 현재 \(balance) \(symbol), USD 환산 \(usdValue)")
    }
}

// MARK: - Wallet Action Buttons

struct WalletActionButtons: View {
    let onSendTapped: () -> Void
    let onReceiveTapped: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            // Send Button
            WalletActionButton(
                icon: "arrow.up.right",
                title: "보내기",
                style: .send,
                action: onSendTapped
            )
            
            // Receive Button
            WalletActionButton(
                icon: "arrow.down.left",
                title: "받기",
                style: .receive,
                action: onReceiveTapped
            )
        }
    }
}

// MARK: - Wallet Action Button

struct WalletActionButton: View {
    let icon: String
    let title: String
    let style: ButtonStyle
    let action: () -> Void
    
    enum ButtonStyle {
        case send
        case receive
    }
    
    @State private var isPressed = false
    @State private var buttonAnimationPhase: CGFloat = 0.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    private var buttonGlow: Bool {
        buttonAnimationPhase > 0.5
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: KingDesignTokens.Spacing.m) {
                // 액션 아이콘
                ZStack {
                    Circle()
                        .fill(iconBackgroundGradient)
                        .frame(
                            width: KingDesignTokens.Sizing.iconXXL,
                            height: KingDesignTokens.Sizing.iconXXL
                        )
                        .shadow(
                            color: shadowColor.opacity(buttonGlow ? 0.6 : 0.3),
                            radius: buttonGlow ? 20 : 12,
                            x: 0,
                            y: 6
                        )
                        .scaleEffect(buttonGlow ? 1.05 : 1.0)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(KingDesignTokens.Colors.onPrimary)
                        .accessibilityHidden(true)
                }
                
                // 버튼 텍스트
                Text(title)
                    .font(KingDesignTokens.Typography.labelLarge)
                    .foregroundColor(KingDesignTokens.Colors.primaryText)
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: KingDesignTokens.Sizing.buttonXL * 2)
            .padding(.vertical, KingDesignTokens.Spacing.lg)
            .background(
                KingCard(style: .glass, size: .regular, isInteractive: true) {
                    EmptyView()
                }
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(KingDesignTokens.Animation.fast, value: isPressed)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) { pressing in
            isPressed = pressing
        } perform: {}
        .onAppear {
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                    buttonAnimationPhase = 1.0
                }
            }
        }
        .accessibilityElement()
        .accessibilityLabel(title)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(.isButton)
    }
    
    private var iconBackgroundGradient: LinearGradient {
        switch style {
        case .send:
            return LinearGradient(
                colors: [
                    KingDesignTokens.Colors.primary,
                    KingDesignTokens.Colors.primary.opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .receive:
            return KingDesignTokens.Gradients.primaryButton
        }
    }
    
    private var shadowColor: Color {
        switch style {
        case .send:
            return KingDesignTokens.Colors.primary
        case .receive:
            return KingDesignTokens.Colors.accent
        }
    }
    
    private var accessibilityHint: String {
        switch style {
        case .send:
            return "이더리움을 다른 지갑으로 전송합니다"
        case .receive:
            return "이더리움을 받을 수 있는 주소를 표시합니다"
        }
    }
}

// MARK: - Wallet Management Section

struct WalletManagementSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: KingDesignTokens.Spacing.lg) {
            Text("지갑 관리")
                .font(KingDesignTokens.Typography.headlineLarge)
                .foregroundColor(KingDesignTokens.Colors.primaryText)
                .accessibilityAddTraits(.isHeader)
            
            VStack(spacing: KingDesignTokens.Spacing.sm) {
                WalletManagementRow(
                    icon: "key",
                    title: "니모닉 백업",
                    subtitle: "복구 문구 확인 및 백업",
                    action: {
                        // Navigate to mnemonic backup
                    }
                )
                
                WalletManagementRow(
                    icon: "network",
                    title: "네트워크 설정",
                    subtitle: "메인넷/테스트넷 전환",
                    action: {
                        // Navigate to network settings
                    }
                )
                
                WalletManagementRow(
                    icon: "wallet.pass",
                    title: "지갑 정보",
                    subtitle: "주소, 공개키 확인",
                    action: {
                        // Navigate to wallet info
                    }
                )
            }
        }
    }
}

// MARK: - Wallet Management Row

struct WalletManagementRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: KingDesignTokens.Spacing.m) {
                // 아이콘
                ZStack {
                    Circle()
                        .fill(KingDesignTokens.Colors.primary.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(KingDesignTokens.Colors.primary)
                        .accessibilityHidden(true)
                }
                
                // 텍스트 정보
                VStack(alignment: .leading, spacing: KingDesignTokens.Spacing.xxs) {
                    Text(title)
                        .font(KingDesignTokens.Typography.bodyMedium)
                        .foregroundColor(KingDesignTokens.Colors.primaryText)
                    
                    Text(subtitle)
                        .font(KingDesignTokens.Typography.caption)
                        .foregroundColor(KingDesignTokens.Colors.secondaryText)
                }
                
                Spacer()
                
                // 화살표
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(KingDesignTokens.Colors.tertiaryText)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, KingDesignTokens.Spacing.sm)
            .padding(.horizontal, KingDesignTokens.Spacing.m)
            .background(
                KingCard(style: .flat, size: .compact, isInteractive: true) {
                    EmptyView()
                }
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
        .accessibilityHint("탭하여 \(title) 화면으로 이동")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Transaction History Section

struct TransactionHistorySection: View {
    let transactions: [Entity.Transaction]
    
    var body: some View {
        VStack(alignment: .leading, spacing: KingDesignTokens.Spacing.lg) {
            // 섹션 헤더
            HStack {
                Text("거래 내역")
                    .font(KingDesignTokens.Typography.headlineLarge)
                    .foregroundColor(KingDesignTokens.Colors.primaryText)
                    .accessibilityAddTraits(.isHeader)
                
                Spacer()
                
                Button("전체보기") {
                    // Navigate to full transaction history
                }
                .font(KingDesignTokens.Typography.labelMedium)
                .foregroundColor(KingDesignTokens.Colors.primary)
                .accessibilityHint("전체 거래 내역을 확인합니다")
            }
            
            // 거래 내역 리스트
            if transactions.isEmpty {
                KingCard(style: .outlined) {
                    VStack(spacing: KingDesignTokens.Spacing.m) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: KingDesignTokens.Sizing.iconLG))
                            .foregroundColor(KingDesignTokens.Colors.tertiaryText)
                        
                        Text("거래 내역이 없습니다")
                            .font(KingDesignTokens.Typography.body)
                            .foregroundColor(KingDesignTokens.Colors.secondaryText)
                        
                        Text("첫 거래를 시작해보세요")
                            .font(KingDesignTokens.Typography.caption)
                            .foregroundColor(KingDesignTokens.Colors.tertiaryText)
                    }
                    .padding(.vertical, KingDesignTokens.Spacing.lg)
                }
                .accessibilityLabel("거래 내역이 없습니다. 첫 거래를 시작해보세요")
            } else {
                LazyVStack(spacing: KingDesignTokens.Spacing.sm) {
                    ForEach(transactions.prefix(5), id: \.id) { transaction in
                        TransactionRow(transaction: transaction)
                    }
                }
                .accessibilityLabel("최근 거래 목록")
                .accessibilityHint("\(min(transactions.count, 5))개의 거래 내역")
            }
        }
    }
}

// MARK: - Transaction Row

struct TransactionRow: View {
    let transaction: Entity.Transaction
    
    var body: some View {
        HStack(spacing: KingDesignTokens.Spacing.m) {
            // 거래 타입 아이콘
            ZStack {
                Circle()
                    .fill(iconBackgroundColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: iconName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(iconColor)
                    .accessibilityHidden(true)
            }
            
            // 거래 정보
            VStack(alignment: .leading, spacing: KingDesignTokens.Spacing.xxs) {
                Text(transactionTitle)
                    .font(KingDesignTokens.Typography.bodyMedium)
                    .foregroundColor(KingDesignTokens.Colors.primaryText)
                
                Text(formatDate(transaction.timestamp))
                    .font(KingDesignTokens.Typography.caption)
                    .foregroundColor(KingDesignTokens.Colors.secondaryText)
            }
            
            Spacer()
            
            // 금액
            VStack(alignment: .trailing, spacing: KingDesignTokens.Spacing.xxs) {
                Text("\(amountPrefix)\(transaction.amountInTokenUnit ?? 0) ETH")
                    .font(KingDesignTokens.Typography.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                KingDesignTokens.Colors.accent,
                                KingDesignTokens.Colors.accent.opacity(0.8)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text(transaction.status.displayName)
                    .font(KingDesignTokens.Typography.caption)
                    .foregroundColor(statusColor)
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
        .accessibilityLabel("\(transactionTitle). \(amountPrefix)\(transaction.amountInTokenUnit ?? 0) 이더리움. \(formatDate(transaction.timestamp))")
    }
    
    private var iconName: String {
        // Transaction이 outgoing인지 확인하려면 사용자 주소가 필요
        // 임시로 from address로 판단 (실제로는 현재 지갑 주소와 비교해야 함)
        return "arrow.up.right" // 일단 송금으로 가정
    }
    
    private var iconColor: Color {
        return KingDesignTokens.Colors.primary
    }
    
    private var iconBackgroundColor: Color {
        return KingDesignTokens.Colors.primary
    }
    
    private var transactionTitle: String {
        return "거래" // 일단 중립적 표현
    }
    
    private var amountPrefix: String {
        return "" // 일단 prefix 없이
    }
    
    private var statusColor: Color {
        switch transaction.status {
        case .confirmed:
            return KingDesignTokens.Colors.success
        case .pending:
            return KingDesignTokens.Colors.warning
        case .failed:
            return KingDesignTokens.Colors.error
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

