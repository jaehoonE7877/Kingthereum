import SwiftUI
import Core
import DesignSystem
import Entity
import os.log
import Factory

/// Premium History View - 거래 내역 뷰 (VIP Architecture)
/// 프리미엄 피나테크 디자인 + Clean Swift Architecture 적용

// MARK: - Display Protocol

@MainActor
protocol HistoryDisplayLogic: AnyObject {
    func displayTransactionHistory(viewModel: HistoryScene.LoadTransactionHistory.ViewModel)
    func displayMoreTransactions(viewModel: HistoryScene.LoadMoreTransactions.ViewModel)
    func displayRefreshedHistory(viewModel: HistoryScene.RefreshTransactionHistory.ViewModel)
    func displayFilteredTransactions(viewModel: HistoryScene.FilterTransactions.ViewModel)
    func displaySearchResults(viewModel: HistoryScene.SearchTransactions.ViewModel)
    func displayExportResult(viewModel: HistoryScene.ExportTransactions.ViewModel)
}

// MARK: - ViewStore (SwiftUI Observable)

@MainActor
@Observable
final class OptimizedHistoryViewStore: HistoryDisplayLogic {
    var transactions: [TransactionViewModel] = []
    var isInitialLoading = false  // false로 변경하여 초기 로드 허용
    var isLoadingMore = false
    var hasMoreTransactions = false
    var selectedFilter: TransactionFilterType = .all
    var alertMessage: String?
    
    func displayTransactionHistory(viewModel: HistoryScene.LoadTransactionHistory.ViewModel) {
        isInitialLoading = false
        if let errorMessage = viewModel.errorMessage { alertMessage = errorMessage; return }
        self.transactions = viewModel.transactionViewModels
        self.hasMoreTransactions = viewModel.hasMoreTransactions
    }
    
    func displayMoreTransactions(viewModel: HistoryScene.LoadMoreTransactions.ViewModel) {
        isLoadingMore = false
        if let errorMessage = viewModel.errorMessage { alertMessage = errorMessage; return }
        self.transactions.append(contentsOf: viewModel.newTransactionViewModels)
        self.hasMoreTransactions = viewModel.hasMoreTransactions
    }
    
    func displayRefreshedHistory(viewModel: HistoryScene.RefreshTransactionHistory.ViewModel) {
        if let errorMessage = viewModel.errorMessage { alertMessage = errorMessage; return }
        self.transactions = viewModel.transactionViewModels
        self.hasMoreTransactions = viewModel.hasMore
    }
    
    func displayFilteredTransactions(viewModel: HistoryScene.FilterTransactions.ViewModel) {}
    func displaySearchResults(viewModel: HistoryScene.SearchTransactions.ViewModel) {}
    func displayExportResult(viewModel: HistoryScene.ExportTransactions.ViewModel) {
        if let errorMessage = viewModel.errorMessage { alertMessage = errorMessage; return }
        if let successMessage = viewModel.successMessage { alertMessage = successMessage }
    }
    
    func clearAlert() {
        alertMessage = nil
    }
}

// MARK: - Main View

@MainActor
struct HistoryView: View {
    @State private var viewStore = OptimizedHistoryViewStore()
    @Binding var showTabBar: Bool
    @Binding var selectedTab: AppTab
    
    @State private var scrollPosition: CGPoint = .zero
    @State private var prefetchTrigger: Double = 0
    
    // MARK: - VIP Architecture Components
    private let interactor: HistoryInteractor
    private let presenter: HistoryPresenter
    private let router: HistoryRouter
    
    init(showTabBar: Binding<Bool>, selectedTab: Binding<AppTab>) {
        self._showTabBar = showTabBar
        self._selectedTab = selectedTab
        
        let interactor = HistoryInteractor()
        let presenter = HistoryPresenter()
        let router = HistoryRouter()
        
        interactor.presenter = presenter
        
        self.interactor = interactor
        self.presenter = presenter
        self.router = router
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 프리미엄 피나테크 배경
                LinearGradient(
                    colors: [
                        KingDesignTokens.Colors.background,
                        KingDesignTokens.Colors.surfaceVariant.opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if viewStore.isInitialLoading && viewStore.transactions.isEmpty {
                    premiumLoadingView
                } else if viewStore.transactions.isEmpty && !viewStore.isInitialLoading {
                    premiumEmptyView
                } else {
                    transactionListView
                }
            }
            .navigationTitle("거래 내역")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    premiumToolbarButton(icon: "line.3.horizontal.decrease.circle", action: filterTransactions)
                    premiumToolbarButton(icon: "square.and.arrow.up", action: exportTransactions)
                }
            }
            .alert("알림", isPresented: Binding<Bool>(
                get: { viewStore.alertMessage != nil },
                set: { _ in viewStore.clearAlert() }
            )) {
                Button("확인") {
                    viewStore.clearAlert()
                }
            } message: {
                if let message = viewStore.alertMessage {
                    Text(message)
                        .font(KingDesignTokens.Typography.body)
                        .foregroundColor(KingDesignTokens.Colors.secondaryText)
                }
            }
        }
        .onAppear {
            print("🔍 [DEBUG] HistoryView appeared")
            print("🔍 [DEBUG] Transactions count: \(viewStore.transactions.count)")
            print("🔍 [DEBUG] Is initial loading: \(viewStore.isInitialLoading)")
            
            setupVIPComponents()
            
            // 백업 로직: 항상 초기 로드 시도
            if viewStore.transactions.isEmpty {
                print("🔍 [DEBUG] Backup load triggered from onAppear")
                Task { await loadInitialTransactions() }
            } else {
                print("🔍 [DEBUG] Skipping onAppear load - data exists")
            }
        }
        .onChange(of: selectedTab) { oldTab, newTab in
            // 디버그 로그 추가
            print("🔍 [DEBUG] Tab changed: \(oldTab) → \(newTab)")
            
            // 내역 탭으로 전환될 때만 로드
            if newTab == .history {
                print("🔍 [DEBUG] History tab selected")
                print("🔍 [DEBUG] Transactions count: \(viewStore.transactions.count)")
                print("🔍 [DEBUG] Is initial loading: \(viewStore.isInitialLoading)")
                
                // 데이터가 없으면 로드
                if viewStore.transactions.isEmpty {
                    print("🔍 [DEBUG] Starting transaction load from onChange...")
                    Task { await loadInitialTransactions() }
                } else {
                    print("🔍 [DEBUG] Skipping onChange load - data already exists")
                }
            }
        }
        .onChange(of: prefetchTrigger) { _, _ in 
            Task { await loadMoreTransactions() }
        }
    }
    
    // MARK: - Premium Subviews
    
    private var transactionListView: some View {
        ScrollView {
            LazyVStack(spacing: KingDesignTokens.Spacing.md) {
                // Filter Summary View
                FilterSummaryView(
                    selectedFilter: viewStore.selectedFilter,
                    transactionCount: viewStore.transactions.count,
                    onClearFilter: {
                        viewStore.selectedFilter = .all
                        // TODO: 필터 클리어 시 데이터 다시 로드
                    }
                )
                .padding(.horizontal, KingDesignTokens.Spacing.lg)
                
                ForEach(viewStore.transactions) { transaction in
                    PremiumTransactionRow(viewModel: transaction)
                        .onTapGesture { selectTransaction(transaction.id) }
                        .onAppear {
                            if transaction.id == viewStore.transactions.last?.id {
                                prefetchTrigger = Date().timeIntervalSinceReferenceDate
                            }
                        }
                }
                
                if viewStore.isLoadingMore { premiumLoadingMoreView.padding() }
                
                Color.clear.frame(height: KingDesignTokens.Spacing.xxxl)
            }
            .padding(.horizontal, KingDesignTokens.Spacing.lg)
            .padding(.top, KingDesignTokens.Spacing.lg)
        }
        .refreshable { await refreshTransactionHistory() }
        .onScrollGeometryChange(for: CGPoint.self) { $0.contentOffset } action: { self.scrollPosition = $1; optimizeScrollHandling(newOffset: $1.y) }
    }
    
    private var premiumLoadingView: some View {
        VStack(spacing: KingDesignTokens.Spacing.md) {
            ProgressView().tint(KingDesignTokens.Colors.accent)
            Text("거래 내역을 불러오는 중...")
                .font(KingDesignTokens.Typography.body)
                .foregroundColor(KingDesignTokens.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var premiumEmptyView: some View {
        VStack(spacing: KingDesignTokens.Spacing.xl) {
            ZStack {
                Circle().fill(KingDesignTokens.Colors.surface).frame(width: 120, height: 120)
                    .shadow(color: KingDesignTokens.Colors.shadow.opacity(0.15), radius: 4)
                Image(systemName: "tray.fill")
                    .font(.system(size: 50, weight: .light))
                    .foregroundColor(KingDesignTokens.Colors.tertiaryText)
            }
            
            VStack(spacing: KingDesignTokens.Spacing.xs) {
                Text("거래 내역이 없습니다")
                    .font(KingDesignTokens.Typography.heading)
                    .foregroundColor(KingDesignTokens.Colors.primaryText)
                Text("첫 거래를 시작하여 자산을 관리해보세요.")
                    .font(KingDesignTokens.Typography.body)
                    .foregroundColor(KingDesignTokens.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Button("이더리움 보내기") { selectedTab = .home } // Assuming .home is send tab
                .buttonStyle(KingPrimaryButtonStyle())
                .padding(.top, KingDesignTokens.Spacing.sm)
        }
        .padding(KingDesignTokens.Spacing.xl)
    }
    
    private var premiumLoadingMoreView: some View {
        HStack(spacing: KingDesignTokens.Spacing.sm) {
            ProgressView().scaleEffect(0.8).tint(KingDesignTokens.Colors.accent)
            Text("더 많은 거래를 불러오는 중...")
                .font(KingDesignTokens.Typography.caption)
                .foregroundColor(KingDesignTokens.Colors.secondaryText)
        }
        .padding(.vertical, KingDesignTokens.Spacing.md)
    }
    
    private func premiumToolbarButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(KingDesignTokens.Colors.primaryText)
                .frame(width: 40, height: 40)
                .background(KingDesignTokens.Colors.surface)
                .clipShape(Circle())
                .shadow(color: KingDesignTokens.Colors.shadow.opacity(0.1), radius: 2)
        }
    }
    
    // MARK: - VIP Setup
    
    private func setupVIPComponents() {
        presenter.viewController = viewStore
        router.viewController = viewStore
        router.dataStore = interactor
    }
    
    // MARK: - Business Logic Methods
    
    private func loadInitialTransactions() async {
        print("🔍 [DEBUG] loadInitialTransactions called")
        
        guard let walletAddress = getCurrentWalletAddress() else { 
            print("❌ [ERROR] No wallet address found")
            return 
        }
        
        print("🔍 [DEBUG] Wallet address: \(walletAddress.prefix(6))...***")
        let request = HistoryScene.LoadTransactionHistory.Request(walletAddress: walletAddress, limit: 50)
        interactor.loadTransactionHistory(request: request)
    }
    
    private func refreshTransactionHistory() async {
        guard let walletAddress = getCurrentWalletAddress() else { return }
        let request = HistoryScene.RefreshTransactionHistory.Request(walletAddress: walletAddress)
        interactor.refreshTransactionHistory(request: request)
    }
    
    private func loadMoreTransactions() async {
        guard let walletAddress = getCurrentWalletAddress() else { return }
        let request = HistoryScene.LoadMoreTransactions.Request(walletAddress: walletAddress)
        interactor.loadMoreTransactions(request: request)
    }
    
    // MARK: - Routing Actions
    
    private func selectTransaction(_ transactionId: String) {
        router.routeToTransactionDetail(transactionHash: transactionId)
    }
    
    private func filterTransactions() {
        router.routeToFilterSettings()
    }
    
    private func exportTransactions() {
        router.routeToExportOptions()
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentWalletAddress() -> String? {
        return UserDefaults.standard.string(forKey: Constants.UserDefaults.selectedWalletAddress)
    }
    
    private func optimizeScrollHandling(newOffset: CGFloat) {
        withAnimation(KingDesignTokens.Animation.normal) { 
            showTabBar = newOffset < 50 
        }
    }
}

// MARK: - Premium UI Components

/// 프리미엄 거래 행 컴포넌트 - 피나테크 스타일
struct PremiumTransactionRow: View {
    let viewModel: TransactionViewModel
    
    private var statusColor: Color {
        switch viewModel.statusColor {
        case "systemGreen": return KingDesignTokens.Colors.success
        case "systemRed": return KingDesignTokens.Colors.error
        case "systemOrange": return KingDesignTokens.Colors.warning
        default: return KingDesignTokens.Colors.secondaryText
        }
    }
    
    var body: some View {
        HStack(spacing: KingDesignTokens.Spacing.md) {
            // 프리미엄 상태 아이콘
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                statusColor.opacity(0.15),
                                statusColor.opacity(0.05)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 22
                        )
                    )
                    .frame(width: 44, height: 44)
                
                Image(systemName: viewModel.statusIcon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(statusColor)
            }
            
            // 거래 세부 정보
            VStack(alignment: .leading, spacing: KingDesignTokens.Spacing.xxs) {
                Text(viewModel.title)
                    .font(KingDesignTokens.Typography.body)
                    .fontWeight(.semibold)
                    .foregroundColor(KingDesignTokens.Colors.primaryText)
                
                Text(viewModel.subtitle)
                    .font(KingDesignTokens.Typography.monoSmall)
                    .foregroundColor(KingDesignTokens.Colors.secondaryText)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // 금액 및 날짜
            VStack(alignment: .trailing, spacing: KingDesignTokens.Spacing.xxs) {
                Text(viewModel.amount)
                    .font(KingDesignTokens.Typography.mono)
                    .fontWeight(.semibold)
                    .foregroundColor(
                        viewModel.isIncoming 
                        ? KingDesignTokens.Colors.success 
                        : KingDesignTokens.Colors.primaryText
                    )
                
                Text(viewModel.formattedDate)
                    .font(KingDesignTokens.Typography.caption)
                    .foregroundColor(KingDesignTokens.Colors.tertiaryText)
            }
        }
        .padding(KingDesignTokens.Spacing.md)
        .glass(material: .ultraThin, cornerRadius: KingDesignTokens.Radius.xl)
        .overlay(
            RoundedRectangle(cornerRadius: KingDesignTokens.Radius.xl)
                .stroke(KingDesignTokens.Colors.outline.opacity(0.08), lineWidth: 0.5)
        )
        .shadow(KingDesignTokens.Shadow.sm)
    }
}

// MARK: - Supporting Components

/// 필터 요약 뷰 - 현재 적용된 필터 상태 표시
struct FilterSummaryView: View {
    let selectedFilter: TransactionFilterType
    let transactionCount: Int
    let onClearFilter: () -> Void
    
    var body: some View {
        if selectedFilter != .all {
            HStack(spacing: KingDesignTokens.Spacing.md) {
                // 필터 아이콘
                Image(systemName: selectedFilter.systemIcon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(KingDesignTokens.Colors.accent)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(KingDesignTokens.Colors.accent.opacity(0.1))
                    )
                
                // 필터 정보
                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedFilter.rawValue)
                        .font(KingDesignTokens.Typography.body)
                        .fontWeight(.semibold)
                        .foregroundColor(KingDesignTokens.Colors.primaryText)
                    
                    Text("\(transactionCount)개 거래")
                        .font(KingDesignTokens.Typography.caption)
                        .foregroundColor(KingDesignTokens.Colors.secondaryText)
                }
                
                Spacer()
                
                // 필터 클리어 버튼
                Button(action: onClearFilter) {
                    HStack(spacing: KingDesignTokens.Spacing.xs) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .medium))
                        Text("전체 보기")
                            .font(KingDesignTokens.Typography.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(KingDesignTokens.Colors.accent)
                    .padding(.horizontal, KingDesignTokens.Spacing.sm)
                    .padding(.vertical, KingDesignTokens.Spacing.xs)
                    .background(
                        Capsule()
                            .fill(KingDesignTokens.Colors.accent.opacity(0.1))
                    )
                }
            }
            .padding(KingDesignTokens.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: KingDesignTokens.Radius.lg)
                    .fill(KingDesignTokens.Colors.surface)
                    .shadow(KingDesignTokens.Shadow.sm)
            )
            .overlay(
                RoundedRectangle(cornerRadius: KingDesignTokens.Radius.lg)
                    .stroke(KingDesignTokens.Colors.outline.opacity(0.08), lineWidth: 0.5)
            )
        }
    }
}

/// 킹 프라이머리 버튼 스타일
struct KingPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(KingDesignTokens.Typography.body)
            .fontWeight(.bold)
            .foregroundColor(KingDesignTokens.Colors.onPrimary)
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [
                        KingDesignTokens.Colors.primary,
                        KingDesignTokens.Colors.primary.opacity(0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(KingDesignTokens.Radius.md)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(KingDesignTokens.Animation.fast, value: configuration.isPressed)
            .shadow(
                color: KingDesignTokens.Colors.primary.opacity(0.3),
                radius: configuration.isPressed ? 2 : 4,
                x: 0,
                y: configuration.isPressed ? 1 : 2
            )
    }
}
