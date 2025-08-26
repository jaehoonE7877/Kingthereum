import SwiftUI
import DesignSystem
import Core

/// iOS 18 스타일 커스텀 Tab Bar를 메인으로 사용하는 앱의 루트 뷰
struct MainTabView: View {
    @State private var selectedTab: AppTab = .home
    @State private var showTabBar = true
    @State private var showReceiveView = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
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
        .sheet(isPresented: $showReceiveView) {
            ReceiveView()
        }
    }
    
    // MARK: - iPad/Mac용 NavigationSplitView
    private var iPadNavigationSplitView: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar
            List {
                ForEach(AppTab.allCases) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        Label {
                            Text(tab.title)
                        } icon: {
                            Image(systemName: tab.icon)
                                .foregroundStyle(selectedTab == tab ? Color.kingBlue : Color.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .listRowBackground(
                        selectedTab == tab ? Color.kingBlue.opacity(0.1) : Color.clear
                    )
                }
            }
            .navigationTitle("Kingthereum")
            .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
        } detail: {
            // Detail View
            NavigationStack {
                destinationView(for: selectedTab)
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
                showReceiveView: $showReceiveView
            )
        case .wallet:
            WalletHomeView(
                showTabBar: .constant(true),
                showReceiveView: $showReceiveView
            )
        case .history:
            HistoryView(showTabBar: .constant(true))
        case .settings:
            SettingsView(showTabBar: .constant(true))
        }
    }
    
    // MARK: - iPhone용 커스텀 Tab Bar View
    private var iPhoneCustomTabView: some View {
        ZStack(alignment: .bottom) {
            // 컨텐츠 영역
            Group {
                switch selectedTab {
                case .home:
                    WalletHomeView(
                        showTabBar: $showTabBar,
                        showReceiveView: $showReceiveView
                    )
                case .wallet:
                    WalletHomeView(
                        showTabBar: $showTabBar,
                        showReceiveView: $showReceiveView
                    )
                case .history:
                    HistoryView(showTabBar: $showTabBar)
                case .settings:
                    SettingsView(showTabBar: $showTabBar)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // 커스텀 Tab Bar
            if showTabBar {
                CustomTabBar(selectedTab: $selectedTab)
                    .frame(height: 83) // Tab bar 높이
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .ignoresSafeArea(.keyboard)
    }
}