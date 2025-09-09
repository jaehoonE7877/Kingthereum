import SwiftUI
import DesignSystem
import Core

// MARK: - MainTabViewStore (성능 최적화된 상태 관리)
@Observable
class MainTabViewStore {
    var selectedTab: AppTab = .home
    var showTabBar = true
    var showReceiveView = false
    var columnVisibility: NavigationSplitViewVisibility = .automatic
}

/// iOS 18 스타일 커스텀 Tab Bar를 메인으로 사용하는 앱의 루트 뷰
struct MainTabView: View {
    // 🚀 성능 최적화: @State 4개 → ViewStore 1개로 통합 (75% 감소)
    @State private var viewStore = MainTabViewStore()
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                // iPad/Mac - NavigationSplitView 사용
                iPadNavigationSplitView
            } else {
                // iPhone - 커스텀 Tab Bar 사용
                iPhoneCustomTabView
            }
        }
        .sheet(isPresented: Binding(
            get: { viewStore.showReceiveView },
            set: { viewStore.showReceiveView = $0 }
        )) {
            ReceiveView()
        }
    }
    
    // MARK: - iPad/Mac용 NavigationSplitView
    private var iPadNavigationSplitView: some View {
        NavigationSplitView(columnVisibility: Binding(
            get: { viewStore.columnVisibility },
            set: { viewStore.columnVisibility = $0 }
        )) {
            // Sidebar
            List {
                ForEach(AppTab.allCases) { tab in
                    Button {
                        viewStore.selectedTab = tab
                    } label: {
                        Label {
                            Text(tab.title)
                        } icon: {
                            Image(systemName: tab.icon)
                                .foregroundStyle(viewStore.selectedTab == tab ? Color.kingBlue : Color.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .listRowBackground(
                        viewStore.selectedTab == tab ? Color.kingBlue.opacity(0.1) : Color.clear
                    )
                }
            }
            .navigationTitle("Kingthereum")
            .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
        } detail: {
            // Detail View
            NavigationStack {
                destinationView(for: viewStore.selectedTab)
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
    
    // MARK: - Destination View Helper
    @ViewBuilder
    private func destinationView(for tab: AppTab) -> some View {
        switch tab {
        case .home:
            WalletHomeView(
                showTabBar: .constant(true),
                showReceiveView: Binding(
                    get: { viewStore.showReceiveView },
                    set: { viewStore.showReceiveView = $0 }
                )
            )
        case .wallet:
            WalletHomeView(
                showTabBar: .constant(true),
                showReceiveView: Binding(
                    get: { viewStore.showReceiveView },
                    set: { viewStore.showReceiveView = $0 }
                )
            )
        case .history:
            HistoryView(showTabBar: .constant(true), selectedTab: Binding(
                get: { viewStore.selectedTab },
                set: { viewStore.selectedTab = $0 }
            ))
        case .settings:
            SettingsView(showTabBar: .constant(true))
        }
    }
    
    // MARK: - iPhone용 커스텀 Tab Bar View
    private var iPhoneCustomTabView: some View {
        ZStack(alignment: .bottom) {
            // 컨텐츠 영역
            Group {
                switch viewStore.selectedTab {
                case .home:
                    WalletHomeView(
                        showTabBar: Binding(
                            get: { viewStore.showTabBar },
                            set: { viewStore.showTabBar = $0 }
                        ),
                        showReceiveView: Binding(
                    get: { viewStore.showReceiveView },
                    set: { viewStore.showReceiveView = $0 }
                )
                    )
                case .wallet:
                    WalletHomeView(
                        showTabBar: Binding(
                            get: { viewStore.showTabBar },
                            set: { viewStore.showTabBar = $0 }
                        ),
                        showReceiveView: Binding(
                    get: { viewStore.showReceiveView },
                    set: { viewStore.showReceiveView = $0 }
                )
                    )
                case .history:
                    HistoryView(showTabBar: Binding(
                        get: { viewStore.showTabBar },
                        set: { viewStore.showTabBar = $0 }
                    ), selectedTab: Binding(
                        get: { viewStore.selectedTab },
                        set: { viewStore.selectedTab = $0 }
                    ))
                case .settings:
                    SettingsView(showTabBar: Binding(
                        get: { viewStore.showTabBar },
                        set: { viewStore.showTabBar = $0 }
                    ))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // 커스텀 Tab Bar
            if viewStore.showTabBar {
                CustomTabBar(selectedTab: Binding(
                    get: { viewStore.selectedTab },
                    set: { viewStore.selectedTab = $0 }
                ))
                    .frame(height: DesignTokens.Size.TabBar.height) // Tab bar 높이
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .ignoresSafeArea(.keyboard)
    }
}