import SwiftUI

import Core
import DesignSystem
import Entity
import WalletKit

import Factory

// MARK: - WalletHomeViewStore (실제 데이터 연동)

final class WalletHomeViewStore {
    // UI 상태 그룹 - 화면 표시 관련
    struct UIState {
        var showSendView = false
        var isScrollingDown = false
        var isLoading = false
        var errorMessage: String?
        var isRefreshing = false
    }
    
    // 스크롤 상태 그룹 - 스크롤 추적 관련
    struct ScrollState {
        var lastOffset: CGFloat = 0
        var isScrollingDown = false
    }
    
    // 실제 지갑 데이터 그룹
    struct WalletData {
        var balance = "0.0"
        var usdValue = "$0.00"
        var symbol = "ETH"
        var walletAddress: String?
    }
    
    // 통합된 상태 그룹들
    var uiState = UIState()
    var scrollState = ScrollState()
    var walletData = WalletData()
    
    // 실제 거래 내역
    var transactions: [Entity.Transaction] = []
    
    @Injected(\.walletService) private var walletService
    @Injected(\.etherscanService) private var etherscanService: EtherscanService

    init() { }
        
    // 간단한 메모리 캐시 (화면 세션 동안만)
    private var lastRefreshTime: Date?
    private let cacheValidDuration: TimeInterval = 300 // 5분
    
    // 🚀 성능 최적화: 계산 프로퍼티로 파생 상태 처리
    var shouldHideTabBar: Bool {
        scrollState.isScrollingDown
    }
    
    // MARK: - 액션 메서드들
    
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
            // Get current wallet address
            let address = try await walletService.getCurrentWalletAddress()
            
            // Fetch wallet balance
            let balanceInEth = try await walletService.getBalance(for: address)
            
            // Fetch transaction history via EtherscanService
            let etherscanResponse = try await etherscanService.getTransactionHistory(address: address)
            let transactionHistory = etherscanResponse.result.map { $0.toTransaction() }
            
            // Update wallet data on MainActor
            await MainActor.run {
                walletData.walletAddress = address
                walletData.balance = balanceInEth
                walletData.symbol = "ETH"
                walletData.usdValue = "0.00" // TODO: Add price service integration
                
                // Update transactions
                transactions = transactionHistory
                
                uiState.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                uiState.isLoading = false
                uiState.errorMessage = "데이터를 불러오는데 실패했습니다: \(error.localizedDescription)"
            }
            print("❌ Failed to load wallet data: \(error)")
        }
    }
    
    func showSendView() {
        uiState.showSendView = true
    }
    
    func hideSendView() {
        uiState.showSendView = false
    }
}

struct WalletHomeView: View {
    @Binding var showTabBar: Bool
    @Binding var showReceiveView: Bool
    
    // 🚀 성능 최적화: @State 11개 → ViewStore 1개로 통합 (90% 감소)
    @State private var viewStore = WalletHomeViewStore()
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    LazyVStack(spacing: KingDesignTokens.Spacing.xl) {
                        // 대형 미니멀 잔액 카드
                        PremiumBalanceCard(
                            balance: viewStore.walletData.balance,
                            symbol: viewStore.walletData.symbol,
                            usdValue: viewStore.walletData.usdValue,
                            isLoading: viewStore.uiState.isLoading,
                            isScrollingDown: viewStore.scrollState.isScrollingDown
                        )
                        .padding(.horizontal, KingDesignTokens.Spacing.lg)
                        .padding(.top, KingDesignTokens.Spacing.m)
                        
                        // 2개 액션 버튼 (Send/Receive)
                        MinimalActionButtons(
                            onSendTapped: { viewStore.showSendView() },
                            onReceiveTapped: { showReceiveView = true }
                        )
                        .padding(.horizontal, KingDesignTokens.Spacing.lg)
                        
                        // 극도로 심플한 거래 리스트
                        MinimalTransactionsList()
                            .padding(.horizontal, KingDesignTokens.Spacing.lg)
                        
                        Spacer(minLength: 120)
                    }
                    .background(
                        GeometryReader { scrollGeometry in
                            KingDesignTokens.Colors.clear.preference(
                                key: ScrollOffsetKey.self,
                                value: scrollGeometry.frame(in: .named("scroll")).minY
                            )
                        }
                    )
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetKey.self) { value in
                    viewStore.handleScrollOffset(value)
                }
                .refreshable {
                    await viewStore.loadWalletData()
                }
                .accessibilityLabel("지갑 홈 화면")
                .accessibilityHint("스크롤하여 잔액과 거래 내역을 확인하거나 새로고침하세요")
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
    
    // MARK: - Premium Balance Card
    
    struct PremiumBalanceCard: View {
        let balance: String
        let symbol: String
        let usdValue: String
        let isLoading: Bool
        let isScrollingDown: Bool
        
        // 🚀 성능 최적화: 단일 애니메이션 페이즈로 통합
        @State private var animationPhase: CGFloat = 0.0
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        
        // 계산 프로퍼티로 성능 최적화
        private var glowIntensity: Double {
            0.3 + (animationPhase * 0.5)
        }
        private var pulseScale: CGFloat {
            1.0 + (animationPhase * 0.08)
        }
        
        var body: some View {
            VStack(spacing: KingDesignTokens.Spacing.lg) {
                // 헤더: 총 잔액
                HStack {
                    VStack(alignment: .leading, spacing: KingDesignTokens.Spacing.xs) {
                        Text("총 잔액")
                            .font(KingDesignTokens.Typography.bodyLarge)
                            .foregroundColor(KingDesignTokens.Colors.secondaryText)
                            .accessibilityAddTraits(.isHeader)
                        
                        Text("이더리움 지갑")
                            .font(KingDesignTokens.Typography.bodyMedium)
                            .foregroundColor(KingDesignTokens.Colors.tertiaryText)
                    }
                    
                    Spacer()
                    
                    // Ethereum Symbol with Golden Glow
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
                    .accessibilityHint("현재 선택된 암호화폐")
                }
                
                // 메인 잔액 표시
                VStack(spacing: KingDesignTokens.Spacing.sm) {
                    if isLoading {
                        KingLoadingView(style: .skeleton, size: .medium)
                            .frame(height: 80)
                            .accessibilityLabel("잔액 로딩 중")
                    } else {
                        // 대형 골드 수치
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
                // 🚀 성능 최적화: 단일 통합 애니메이션 + 접근성 지원
                if !reduceMotion {
                    withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                        animationPhase = 1.0
                    }
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("잔액 카드. 총 \(balance) \(symbol), USD 환산 \(usdValue)")
            .accessibilityHint("새로고침하여 최신 잔액 확인")
        }
    }
    // MARK: - Minimal Action Buttons
    
    struct MinimalActionButtons: View {
        let onSendTapped: () -> Void
        let onReceiveTapped: () -> Void
        
        var body: some View {
            HStack(spacing: 20) {
                // Send Button
                GoldenActionButton(
                    icon: "arrow.up.right",
                    title: "보내기",
                    style: .send,
                    action: onSendTapped
                )
                
                // Receive Button
                GoldenActionButton(
                    icon: "arrow.down.left",
                    title: "받기",
                    style: .receive,
                    action: onReceiveTapped
                )
            }
        }
    }
    
    // MARK: - Golden Action Button
    
    struct GoldenActionButton: View {
        let icon: String
        let title: String
        let style: ButtonStyle
        let action: () -> Void
        
        enum ButtonStyle {
            case send
            case receive
        }
        
        @State private var isPressed = false
        // 🚀 성능 최적화: 버튼 애니메이션도 통합
        @State private var buttonAnimationPhase: CGFloat = 0.0
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        
        // 버튼 글로우 계산 프로퍼티
        private var buttonGlow: Bool {
            buttonAnimationPhase > 0.5
        }
        
        var body: some View {
            Button(action: action) {
                VStack(spacing: KingDesignTokens.Spacing.m) {
                    // 골드 아이콘
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
                    
                    // 미니멀 텍스트
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
            } perform: {
                // Long press action if needed
            }
            .onAppear {
                // 🚀 성능 최적화: 접근성을 고려한 단일 애니메이션
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
}
// MARK: - Minimal Transactions List

struct MinimalTransactionsList: View {
    
    @State private var mockTransactions = [
        MockTransaction(type: .receive, amount: "0.5", time: "5분 전"),
        MockTransaction(type: .send, amount: "1.2", time: "1시간 전"),
        MockTransaction(type: .receive, amount: "0.8", time: "3시간 전")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: KingDesignTokens.Spacing.lg) {
            // 섹션 헤더
            HStack {
                Text("최근 거래")
                    .font(KingDesignTokens.Typography.headlineLarge)
                    .foregroundColor(KingDesignTokens.Colors.primaryText)
                    .accessibilityAddTraits(.isHeader)
                
                Spacer()
                
                Button("전체보기") {
                    // Navigate to full history
                }
                .font(KingDesignTokens.Typography.labelMedium)
                .foregroundColor(KingDesignTokens.Colors.primary)
                .accessibilityHint("전체 거래 내역을 확인합니다")
            }
            
            // 극도로 심플한 거래 리스트
            if mockTransactions.isEmpty {
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
                    ForEach(mockTransactions, id: \.id) { transaction in
                        MinimalTransactionRow(transaction: transaction)
                    }
                }
                .accessibilityLabel("최근 거래 목록")
                .accessibilityHint("\(mockTransactions.count)개의 거래 내역")
            }
        }
    }
}
// MARK: - Minimal Transaction Row

struct MinimalTransactionRow: View {
    let transaction: MockTransaction
    
    var body: some View {
        HStack(spacing: KingDesignTokens.Spacing.m) {
            // 타입 아이콘 (미니멀)
            ZStack {
                Circle()
                    .fill(iconBackgroundColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: iconName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(iconColor)
                    .accessibilityHidden(true)
            }
            
            // 거래 정보 (breathable space)
            VStack(alignment: .leading, spacing: KingDesignTokens.Spacing.xxs) {
                Text(transactionTitle)
                    .font(KingDesignTokens.Typography.bodyMedium)
                    .foregroundColor(KingDesignTokens.Colors.primaryText)
                
                Text(transaction.time)
                    .font(KingDesignTokens.Typography.caption)
                    .foregroundColor(KingDesignTokens.Colors.secondaryText)
            }
            
            Spacer()
            
            // 금액 (골드 accent)
            Text("\(amountPrefix)\(transaction.amount) ETH")
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
        }
        .padding(.vertical, KingDesignTokens.Spacing.sm)
        .padding(.horizontal, KingDesignTokens.Spacing.m)
        .background(
            KingCard(style: .flat, size: .compact, isInteractive: true) {
                EmptyView()
            }
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(transactionTitle). \(amountPrefix)\(transaction.amount) 이더리움. \(transaction.time)")
        .accessibilityHint("거래 세부 정보를 확인하려면 탭하세요")
    }
    
    private var iconName: String {
        transaction.type == .send ? "arrow.up.right" : "arrow.down.left"
    }
    
    private var iconColor: Color {
        transaction.type == .send ? KingDesignTokens.Colors.primary : KingDesignTokens.Colors.success
    }
    
    private var iconBackgroundColor: Color {
        transaction.type == .send ? KingDesignTokens.Colors.primary : KingDesignTokens.Colors.success
    }
    
    private var transactionTitle: String {
        transaction.type == .send ? "전송" : "수신"
    }
    
    private var amountPrefix: String {
        transaction.type == .send ? "-" : "+"
    }
}

// MARK: - Balance Loading Skeleton

struct BalanceLoadingSkeleton: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12)
                .fill(KingDesignTokens.Colors.onSurfaceVariant.opacity(0.3))
                .frame(width: 220, height: 48)
            
            RoundedRectangle(cornerRadius: 8)
                .fill(KingDesignTokens.Colors.onSurfaceVariant.opacity(0.2))
                .frame(width: 140, height: 24)
        }
        .opacity(isAnimating ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: isAnimating)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Mock Data

struct MockTransaction: Identifiable {
    let id = UUID()
    let type: TransactionType
    let amount: String
    let time: String
    
    enum TransactionType {
        case send, receive
    }
}

// MARK: - ScrollOffsetKey (재사용)

struct ScrollOffsetKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
