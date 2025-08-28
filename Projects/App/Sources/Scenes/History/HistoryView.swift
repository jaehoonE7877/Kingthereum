import SwiftUI
import Core
import DesignSystem
import Entity

/// Phase 2.4-2: HistoryView King 디자인 시스템 완전 적용
/// VIP Architecture + King Design System (Colors, Typography, Gradients)
/// Modern Minimalism + Premium Fintech + Glassmorphism 완전 통합

/// 거래 내역 화면의 디스플레이 로직을 정의하는 프로토콜
/// VIP 아키텍처에서 Presenter가 View에게 데이터를 전달하기 위한 인터페이스
@MainActor
protocol HistoryDisplayLogic: AnyObject {
    func displayTransactionHistory(viewModel: HistoryScene.LoadTransactionHistory.ViewModel)
    func displayRefreshResult(viewModel: HistoryScene.RefreshTransactions.ViewModel)
    func displayFilteredTransactions(viewModel: HistoryScene.FilterTransactions.ViewModel)
    func displayExportResult(viewModel: HistoryScene.ExportTransactions.ViewModel)
}

/// SwiftUI용 History ViewStore (DisplayLogic 구현)
@MainActor
@Observable
final class HistoryViewStore: HistoryDisplayLogic {
    var transactionViewModels: [TransactionViewModel] = []
    var isLoading = false
    var isLoadingMore = false
    var hasMoreTransactions = false
    var selectedFilter: TransactionFilterType = .all
    var filterResultCount: String?
    var showFilterOptions = false
    var showExportOptions = false
    var alertMessage: String?
    
    var currentTransactions: [Entity.Transaction] = []
    
    // MARK: - Display Logic
    
    func displayTransactionHistory(viewModel: HistoryScene.LoadTransactionHistory.ViewModel) {
        isLoading = false
        isLoadingMore = false
        
        if let errorMessage = viewModel.errorMessage {
            alertMessage = errorMessage
            return
        }
        
        transactionViewModels = viewModel.transactionViewModels
        hasMoreTransactions = viewModel.hasMoreTransactions
    }
    
    func displayRefreshResult(viewModel: HistoryScene.RefreshTransactions.ViewModel) {
        if let errorMessage = viewModel.errorMessage {
            alertMessage = errorMessage
            return
        }
        
        transactionViewModels = viewModel.transactionViewModels
    }
    
    func displayFilteredTransactions(viewModel: HistoryScene.FilterTransactions.ViewModel) {
        transactionViewModels = viewModel.transactionViewModels
        filterResultCount = viewModel.resultCount
    }
    
    func displayExportResult(viewModel: HistoryScene.ExportTransactions.ViewModel) {
        if let errorMessage = viewModel.errorMessage {
            alertMessage = errorMessage
            return
        }
        
        if let successMessage = viewModel.successMessage {
            alertMessage = successMessage
        }
    }
    
    func clearAlert() {
        alertMessage = nil
    }
}

/// 거래 내역을 표시하는 VIP 패턴 기반 화면
struct HistoryView: View {
    @State private var viewStore = HistoryViewStore()
    @Binding var showTabBar: Bool
    @Binding var selectedTab: AppTab
    
    // MARK: - VIP Architecture Components
    private let interactor: HistoryBusinessLogic
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
                // King 디자인 시스템 배경 적용
                KingGradients.minimalistBackground
                    .ignoresSafeArea()
                
                if viewStore.isLoading && viewStore.transactionViewModels.isEmpty {
                    // 초기 로딩 - King 스타일
                    LoadingView(style: .spinner, size: .medium)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewStore.transactionViewModels.isEmpty && !viewStore.isLoading {
                    // 빈 상태 - King 스타일
                    EmptyHistoryView(onNavigateToHome: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTab = .home
                        }
                    })
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // 거래 목록 - King 스타일
                    transactionListView
                }
            }
            .refreshable {
                refreshTransactions()
            }
            .navigationTitle("거래 내역")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(KingGradients.minimalistBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    filterButton
                    exportButton
                }
            }
            .sheet(isPresented: $viewStore.showFilterOptions) {
                FilterOptionsView(
                    selectedFilter: $viewStore.selectedFilter,
                    onFilterApplied: { filterType in
                        applyFilter(filterType)
                    }
                )
            }
            .sheet(isPresented: $viewStore.showExportOptions) {
                ExportOptionsView(
                    transactions: viewStore.currentTransactions,
                    onExport: { format in
                        exportTransactions(format: format)
                    }
                )
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
                        .kingStyle(.bodySecondary)
                }
            }
        }
        .onAppear {
            // Connect presenter to viewStore after view initialization
            presenter.viewController = viewStore
            loadInitialTransactions()
        }
    }
    
    // MARK: - Subviews
    
    private var transactionListView: some View {
        ScrollView {
            LazyVStack(spacing: DesignTokens.Spacing.md) {
                // 필터 요약 (활성 필터가 있을 때만 표시) - King 스타일
                if viewStore.selectedFilter != .all {
                    filterSummaryView
                }
                
                // 거래 목록 - King 스타일 적용
                ForEach(viewStore.transactionViewModels, id: \.id) { transactionVM in
                    TransactionRowView(viewModel: transactionVM)
                        .padding(.horizontal, DesignTokens.Spacing.lg)
                        .onTapGesture {
                            selectTransaction(transactionVM.id)
                        }
                        .onAppear {
                            if transactionVM.id == viewStore.transactionViewModels.last?.id {
                                loadMoreTransactionsIfNeeded()
                            }
                        }
                }
                
                // 더 많은 거래 로딩 인디케이터 - King 스타일
                if viewStore.hasMoreTransactions && viewStore.isLoadingMore {
                    VStack(spacing: 12) {
                        LoadingView(style: .spinner, size: .small)
                        Text("더 많은 거래를 불러오는 중...")
                            .kingStyle(.captionPrimary)
                    }
                    .padding()
                    .premiumFinTechGlass(level: .subtle)
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                }
                
                // 추가 스크롤 여백
                Color.clear.frame(height: DesignTokens.Spacing.scrollBottomPadding)
            }
            .padding(.top, DesignTokens.Spacing.lg)
        }
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y
        } action: { _, newValue in
            let threshold: CGFloat = 50
            withAnimation(.easeInOut(duration: 0.3)) {
                showTabBar = newValue < threshold
            }
        }
    }
    
    private var filterSummaryView: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: viewStore.selectedFilter.systemIcon)
                    .font(KingTypography.caption)
                    .foregroundColor(KingColors.trustPurple)
                
                Text(viewStore.selectedFilter.rawValue)
                    .kingStyle(.bodyPrimary)
                
                if let resultCount = viewStore.filterResultCount {
                    Text("(\(resultCount))")
                        .kingStyle(.captionPrimary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                    .fill(KingColors.trustPurple.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                            .stroke(KingColors.trustPurple.opacity(0.2), lineWidth: 0.5)
                    )
            )
            
            Spacer()
            
            Button("전체") {
                clearFilter()
            }
            .font(KingTypography.labelMedium)
            .foregroundColor(KingColors.trustPurple)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.1))
            .cornerRadius(DesignTokens.CornerRadius.md)
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
    }
    
    private var filterButton: some View {
        Button {
            viewStore.showFilterOptions = true
        } label: {
            Image(systemName: "line.horizontal.3.decrease.circle")
                .font(KingTypography.labelLarge)
                .foregroundColor(KingColors.exclusiveGold)
                .padding(8)
                .background(Color.white.opacity(0.1))
                .clipShape(Circle())
        }
        .scaleEffect(viewStore.showFilterOptions ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: viewStore.showFilterOptions)
    }
    
    private var exportButton: some View {
        Button {
            viewStore.showExportOptions = true
        } label: {
            Image(systemName: "square.and.arrow.up")
                .font(KingTypography.labelLarge)
                .foregroundColor(KingColors.exclusiveGold)
                .padding(8)
                .background(Color.white.opacity(0.1))
                .clipShape(Circle())
        }
        .scaleEffect(viewStore.showExportOptions ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: viewStore.showExportOptions)
    }
    
    // MARK: - Business Logic Methods
    
    private func loadInitialTransactions() {
        guard let walletAddress = getCurrentWalletAddress() else {
            viewStore.alertMessage = "지갑 주소를 찾을 수 없습니다"
            return
        }
        
        viewStore.isLoading = true
        let request = HistoryScene.LoadTransactionHistory.Request(
            walletAddress: walletAddress,
            limit: 20,
            offset: 0
        )
        interactor.loadTransactionHistory(request: request)
    }
    
    private func refreshTransactions() {
        guard let walletAddress = getCurrentWalletAddress() else { return }
        let request = HistoryScene.RefreshTransactions.Request(walletAddress: walletAddress)
        interactor.refreshTransactions(request: request)
    }
    
    private func loadMoreTransactionsIfNeeded() {
        guard viewStore.hasMoreTransactions && !viewStore.isLoadingMore else { return }
        guard let walletAddress = getCurrentWalletAddress() else { return }
        
        viewStore.isLoadingMore = true
        let request = HistoryScene.LoadTransactionHistory.Request(
            walletAddress: walletAddress,
            limit: 20,
            offset: viewStore.transactionViewModels.count
        )
        interactor.loadTransactionHistory(request: request)
    }
    
    private func applyFilter(_ filterType: TransactionFilterType) {
        viewStore.selectedFilter = filterType
        let request = HistoryScene.FilterTransactions.Request(filterType: filterType)
        interactor.filterTransactions(request: request)
    }
    
    private func clearFilter() {
        viewStore.selectedFilter = .all
        viewStore.filterResultCount = nil
        applyFilter(.all)
    }
    
    private func exportTransactions(format: ExportFormat) {
        // Convert from app ExportFormat to entity ExportFormat
        let entityFormat = Entity.ExportFormat(rawValue: format.rawValue.uppercased()) ?? .csv
        let request = HistoryScene.ExportTransactions.Request(
            transactions: viewStore.currentTransactions,
            format: entityFormat
        )
        interactor.exportTransactions(request: request)
    }
    
    private func selectTransaction(_ transactionId: String) {
        router.routeToTransactionDetail(transactionHash: transactionId)
    }
    
    private func getCurrentWalletAddress() -> String? {
        return UserDefaults.standard.string(forKey: Constants.UserDefaults.selectedWalletAddress)
    }
}

// MARK: - Legacy ViewModel removed - now using VIP + @Observable pattern

// MARK: - Supporting Views

/// TransactionViewModel을 기반으로 한 거래 행 뷰 - King 디자인 완전 적용
struct TransactionRowView: View {
    let viewModel: TransactionViewModel
    
    private var statusColor: Color {
        switch viewModel.statusColor {
        case "systemGreen": return KingColors.success
        case "systemRed": return KingColors.error
        case "systemOrange": return KingColors.warning
        default: return KingColors.trustPurple
        }
    }
    
    private var statusGradient: LinearGradient {
        switch viewModel.statusColor {
        case "systemGreen": return KingGradients.subtleSuccess
        case "systemRed": return KingGradients.subtleDanger
        case "systemOrange": return KingGradients.minimalistSecondary
        default: return KingGradients.trustGradient
        }
    }
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // 프리미엄 상태 아이콘
            ZStack {
                Circle()
                    .fill(statusGradient)
                    .frame(width: 44, height: 44)
                
                Image(systemName: viewModel.statusIcon)
                    .font(KingTypography.labelLarge)
                    .foregroundColor(statusColor)
                    .fontWeight(.medium)
            }
            
            // 거래 정보 - King Typography 적용
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(viewModel.title)
                    .kingStyle(.bodyPrimary)
                
                Text(viewModel.subtitle)
                    .kingStyle(.bodySecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // 금액 및 날짜 - King Typography 적용
            VStack(alignment: .trailing, spacing: DesignTokens.Spacing.xs) {
                Text(viewModel.amount)
                    .kingStyle(KingTextStyle(
                        font: KingTypography.bodyMedium,
                        color: statusColor
                    ))
                    .fontWeight(.semibold)
                
                Text(viewModel.formattedDate)
                    .kingStyle(.captionPrimary)
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .premiumFinTechGlass(level: .standard)
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                .stroke(
                    LinearGradient(
                        colors: [
                            statusColor.opacity(0.3),
                            statusColor.opacity(0.1),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        )
        .shadow(
            color: statusColor.opacity(0.1),
            radius: 4,
            x: 0,
            y: 2
        )
    }
}

/// 빈 상태 뷰 - King 디자인 시스템 완전 적용
struct EmptyHistoryView: View {
    @State private var isAnimating = false
    @State private var pulseAnimation = false
    @State private var floatingOffset: CGFloat = 0
    
    // HomeTab으로 이동하기 위한 클로저
    let onNavigateToHome: (() -> Void)?
    
    init(onNavigateToHome: (() -> Void)? = nil) {
        self.onNavigateToHome = onNavigateToHome
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 60)
                    
                    // 메인 콘텐츠 카드
                    VStack(spacing: 32) {
                        // 프리미엄 헤더 아이콘 섹션
                        headerIconSection
                        
                        // 메인 메시지 섹션
                        mainMessageSection
                        
                        // CTA 버튼 섹션
                        ctaButtonSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 40)
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(.ultraThinMaterial)
                            .background(
                                RoundedRectangle(cornerRadius: 28)
                                    .fill(KingGradients.surface.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 28)
                                    .stroke(KingGradients.trustGradient.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .shadow(
                        color: KingColors.backgroundSecondary.opacity(0.1),
                        radius: 20,
                        x: 0,
                        y: 8
                    )
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 60)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
                pulseAnimation = true
            }
            
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                floatingOffset = -10
            }
        }
    }
    
    // MARK: - Header Icon Section
    private var headerIconSection: some View {
        ZStack {
            // 배경 글로우 이펙트
            Circle()
                .fill(KingGradients.trustGradient.opacity(0.2))
                .frame(width: 140, height: 140)
                .blur(radius: 20)
                .scaleEffect(pulseAnimation ? 1.1 : 0.9)
                .animation(
                    .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                    value: pulseAnimation
                )
            
            // 메인 아이콘 배경
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            KingColors.trustPurple.opacity(0.1),
                            KingColors.exclusiveGold.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    KingColors.trustPurple.opacity(0.3),
                                    KingColors.exclusiveGold.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
            
            // 메인 아이콘
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 36, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            KingColors.trustPurple,
                            KingColors.exclusiveGold
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .offset(y: floatingOffset)
                .animation(
                    .easeInOut(duration: 2.5).repeatForever(autoreverses: true),
                    value: floatingOffset
                )
        }
    }
    
    // MARK: - Main Message Section
    private var mainMessageSection: some View {
        VStack(spacing: 16) {
            Text("거래 내역이 없습니다")
                .font(KingTypography.displaySmall)
                .foregroundColor(KingColors.textPrimary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 8) {
                Text("첫 번째 거래를 시작해보세요")
                    .font(KingTypography.bodyLarge)
                    .foregroundColor(KingColors.textSecondary)
                    .multilineTextAlignment(.center)
                
                Text("이더리움을 안전하게 전송하고 받을 수 있습니다")
                    .font(KingTypography.bodyMedium)
                    .foregroundColor(KingColors.textTertiary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - CTA Button Section
    private var ctaButtonSection: some View {
        Button(action: {
            onNavigateToHome?()
        }) {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20, weight: .medium))
                
                Text("거래 시작하기")
                    .font(KingTypography.buttonPrimary)
                    .fontWeight(.semibold)
            }
            .foregroundColor(KingColors.textInverse)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    // 배경 그라데이션 레이어
                    RoundedRectangle(cornerRadius: 16)
                        .fill(KingGradients.premiumGoldButton)
                    
                    // 오버레이 그라데이션
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    KingColors.trustPurple.opacity(0.8),
                                    KingColors.exclusiveGold.opacity(0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .blendMode(.overlay)
                }
                .shadow(
                    color: KingColors.trustPurple.opacity(0.4),
                    radius: 16,
                    x: 0,
                    y: 8
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [
                                KingColors.trustPurple.opacity(0.5),
                                KingColors.exclusiveGold.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PressedButtonStyle())
    }
}

// MARK: - Custom Button Style
struct PressedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// 필터 옵션 모달 뷰 - King 디자인 완전 적용
struct FilterOptionsView: View {
    @Binding var selectedFilter: TransactionFilterType
    let onFilterApplied: (TransactionFilterType) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                KingGradients.minimalistBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: DesignTokens.Spacing.sm) {
                        ForEach(TransactionFilterType.allCases, id: \.self) { filterType in
                            FilterOptionRow(
                                filterType: filterType,
                                isSelected: selectedFilter == filterType
                            ) {
                                selectedFilter = filterType
                                onFilterApplied(filterType)
                                dismiss()
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("필터")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(KingGradients.minimalistBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        dismiss()
                    }
                    .font(KingTypography.buttonPrimary)
                    .foregroundColor(KingColors.trustPurple)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

struct FilterOptionRow: View {
    let filterType: TransactionFilterType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.md) {
                // 아이콘
                ZStack {
                    Circle()
                        .fill(isSelected ? KingColors.trustPurple.opacity(0.15) : Color.clear)
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: filterType.systemIcon)
                        .font(KingTypography.labelLarge)
                        .foregroundColor(isSelected ? KingColors.trustPurple : KingColors.textSecondary)
                }
                
                // 텍스트
                Text(filterType.rawValue)
                    .font(KingTypography.bodyMedium)
                    .foregroundColor(isSelected ? KingColors.textPrimary : KingColors.textSecondary)
                
                Spacer()
                
                // 선택 표시
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(KingTypography.labelLarge)
                        .foregroundColor(KingColors.trustPurple)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(DesignTokens.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                    .fill(isSelected ? KingColors.trustPurple.opacity(0.08) : Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                            .stroke(
                                isSelected ? KingColors.trustPurple.opacity(0.3) : Color.clear,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
    }
}

/// 내보내기 옵션 모달 뷰 - King 디자인 완전 적용
struct ExportOptionsView: View {
    let transactions: [Entity.Transaction]
    let onExport: (ExportFormat) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                KingGradients.minimalistBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DesignTokens.Spacing.lg) {
                        // 헤더 섹션
                        VStack(spacing: DesignTokens.Spacing.md) {
                            ZStack {
                                Circle()
                                    .fill(KingGradients.premiumGold)
                                    .frame(width: 64, height: 64)
                                
                                Image(systemName: "square.and.arrow.up")
                                    .font(KingTypography.headlineMedium)
                                    .foregroundColor(KingColors.exclusiveGold)
                            }
                            
                            VStack(spacing: DesignTokens.Spacing.xs) {
                                Text("거래 내역 내보내기")
                                    .font(KingTypography.headlineLarge)
                                    .foregroundColor(KingColors.textPrimary)
                                
                                Text("\(transactions.count)개의 거래를 선택한 형식으로 내보냅니다")
                                    .font(KingTypography.bodyMedium)
                                    .foregroundColor(KingColors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.top)
                        
                        // 내보내기 형식 옵션들
                        LazyVStack(spacing: DesignTokens.Spacing.sm) {
                            ForEach(ExportFormat.allCases, id: \.self) { format in
                                ExportOptionRow(format: format) {
                                    onExport(format)
                                    dismiss()
                                }
                            }
                        }
                        
                        Spacer(minLength: 50)
                    }
                    .padding()
                }
            }
            .navigationTitle("내보내기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(KingGradients.minimalistBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("취소") {
                        dismiss()
                    }
                    .font(KingTypography.buttonPrimary)
                    .foregroundColor(KingColors.textSecondary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

struct ExportOptionRow: View {
    let format: ExportFormat
    let action: () -> Void
    
    private var formatIcon: String {
        switch format {
        case .csv: return "doc.text"
        case .json: return "doc.badge.gearshape"
        case .pdf: return "doc.richtext"
        case .xlsx: return "doc.spreadsheet"
        }
    }
    
    private var formatDescription: String {
        switch format {
        case .csv: return "스프레드시트에서 열기"
        case .json: return "개발자용 데이터 형식"
        case .pdf: return "문서 형태로 저장"
        case .xlsx: return "엑셀 파일로 저장"
        }
    }
    
    private var formatColor: Color {
        switch format {
        case .csv: return KingColors.success
        case .json: return KingColors.trustPurple
        case .pdf: return KingColors.error
        case .xlsx: return KingColors.exclusiveGold
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.md) {
                // 아이콘
                ZStack {
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                        .fill(formatColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: formatIcon)
                        .font(KingTypography.labelLarge)
                        .foregroundColor(formatColor)
                }
                
                // 텍스트 정보
                VStack(alignment: .leading, spacing: 2) {
                    Text(format.rawValue.uppercased())
                        .kingStyle(.bodyPrimary)
                        .fontWeight(.semibold)
                    
                    Text(formatDescription)
                        .kingStyle(.bodySecondary)
                }
                
                Spacer()
                
                // 화살표
                Image(systemName: "chevron.right")
                    .font(KingTypography.caption)
                    .foregroundColor(KingColors.textTertiary)
            }
            .padding(DesignTokens.Spacing.lg)
            .background(.ultraThinMaterial)
            .cornerRadius(DesignTokens.CornerRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                    .stroke(formatColor.opacity(0.2), lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(0.98)
        .animation(.easeInOut(duration: 0.1), value: false)
    }
}
