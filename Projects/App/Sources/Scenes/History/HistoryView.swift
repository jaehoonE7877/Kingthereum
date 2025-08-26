import SwiftUI
import Core
import DesignSystem
import Entity

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
    
    // MARK: - VIP Architecture Components
    private let interactor: HistoryBusinessLogic
    private let presenter: HistoryPresenter
    private let router: HistoryRouter
    
    init(showTabBar: Binding<Bool>) {
        self._showTabBar = showTabBar
        
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
                if viewStore.isLoading && viewStore.transactionViewModels.isEmpty {
                    // 초기 로딩
                    LoadingView(style: .spinner, size: .medium)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewStore.transactionViewModels.isEmpty && !viewStore.isLoading {
                    // 빈 상태
                    EmptyHistoryView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // 거래 목록
                    transactionListView
                }
            }
            .refreshable {
                refreshTransactions()
            }
            .navigationTitle("거래 내역")
            .navigationBarTitleDisplayMode(.large)
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
                // 필터 요약 (활성 필터가 있을 때만 표시)
                if viewStore.selectedFilter != .all {
                    filterSummaryView
                }
                
                // 거래 목록
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
                
                // 더 많은 거래 로딩 인디케이터
                if viewStore.hasMoreTransactions && viewStore.isLoadingMore {
                    LoadingView(style: .spinner, size: .small)
                        .padding()
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
                    .foregroundColor(.systemBlue)
                Text(viewStore.selectedFilter.rawValue)
                    .font(Typography.Body.small)
                    .fontWeight(.medium)
                if let resultCount = viewStore.filterResultCount {
                    Text("(\(resultCount))")
                        .font(Typography.Caption.small)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.systemBlue.opacity(0.1))
            .cornerRadius(DesignTokens.CornerRadius.lg)
            
            Spacer()
            
            Button("전체") {
                clearFilter()
            }
            .font(Typography.Body.small)
            .foregroundColor(.systemBlue)
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
    }
    
    private var filterButton: some View {
        Button {
            viewStore.showFilterOptions = true
        } label: {
            Image(systemName: "line.horizontal.3.decrease.circle")
                .foregroundColor(.systemBlue)
        }
    }
    
    private var exportButton: some View {
        Button {
            viewStore.showExportOptions = true
        } label: {
            Image(systemName: "square.and.arrow.up")
                .foregroundColor(.systemBlue)
        }
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

/// TransactionViewModel을 기반으로 한 거래 행 뷰
struct TransactionRowView: View {
    let viewModel: TransactionViewModel
    
    private var statusColor: Color {
        switch viewModel.statusColor {
        case "systemGreen": return .systemGreen
        case "systemRed": return .systemRed
        case "systemOrange": return .systemOrange
        default: return .systemBlue
        }
    }
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // 상태 아이콘
            Image(systemName: viewModel.statusIcon)
                .font(.title2)
                .foregroundColor(statusColor)
                .frame(width: 40, height: 40)
            
            // 거래 정보
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(viewModel.title)
                    .font(Typography.Body.medium)
                    .fontWeight(.medium)
                
                Text(viewModel.subtitle)
                    .font(Typography.Caption.medium)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // 금액 및 날짜
            VStack(alignment: .trailing, spacing: DesignTokens.Spacing.xs) {
                Text(viewModel.amount)
                    .font(Typography.Body.medium)
                    .fontWeight(.semibold)
                    .foregroundColor(statusColor)
                
                Text(viewModel.formattedDate)
                    .font(Typography.Caption.medium)
                    .foregroundColor(.secondary)
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .glassCard()
    }
}

/// 거래 내역이 없을 때 표시되는 빈 상태 뷰
struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 64))
                .foregroundColor(.systemGray3)
            
            VStack(spacing: DesignTokens.Spacing.sm) {
                Text("거래 내역이 없습니다")
                    .font(Typography.Heading.h4)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("첫 번째 거래를 시작해보세요")
                    .font(Typography.Body.medium)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(DesignTokens.Spacing.xxl)
    }
}

/// 필터 옵션을 선택하는 모달 뷰
struct FilterOptionsView: View {
    @Binding var selectedFilter: TransactionFilterType
    let onFilterApplied: (TransactionFilterType) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(TransactionFilterType.allCases, id: \.self) { filterType in
                    HStack {
                        Image(systemName: filterType.systemIcon)
                            .foregroundColor(.systemBlue)
                            .frame(width: 24)
                        
                        Text(filterType.rawValue)
                            .font(Typography.Body.medium)
                        
                        Spacer()
                        
                        if selectedFilter == filterType {
                            Image(systemName: "checkmark")
                                .foregroundColor(.systemBlue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedFilter = filterType
                        onFilterApplied(filterType)
                        dismiss()
                    }
                }
            }
            .navigationTitle("필터")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// 내보내기 옵션을 선택하는 모달 뷰
struct ExportOptionsView: View {
    let transactions: [Entity.Transaction]
    let onExport: (ExportFormat) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("내보내기 형식") {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        HStack {
                            Image(systemName: iconForFormat(format))
                                .foregroundColor(.systemBlue)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(format.rawValue)
                                    .font(Typography.Body.medium)
                                
                                Text(descriptionForFormat(format))
                                    .font(Typography.Caption.medium)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.systemGray3)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onExport(format)
                            dismiss()
                        }
                    }
                }
                
                Section {
                    Text("\(transactions.count)개의 거래를 내보냅니다")
                        .font(Typography.Caption.medium)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("내보내기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("취소") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func iconForFormat(_ format: ExportFormat) -> String {
        switch format {
        case .csv: return "doc.text"
        case .json: return "doc.badge.gearshape"
        case .pdf: return "doc.richtext"
        case .xlsx: return "doc.spreadsheet"
        }
    }
    
    private func descriptionForFormat(_ format: ExportFormat) -> String {
        switch format {
        case .csv: return "스프레드시트에서 열기"
        case .json: return "개발자용 데이터 형식"
        case .pdf: return "문서 형태로 저장"
        case .xlsx: return "엑셀 파일로 저장"
        }
    }
}
