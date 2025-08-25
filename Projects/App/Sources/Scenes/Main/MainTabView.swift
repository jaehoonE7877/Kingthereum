import SwiftUI
import DesignSystem
import Core

/// iOS 18 스타일 커스텀 Tab Bar를 메인으로 사용하는 앱의 루트 뷰
struct MainTabView: View {
    @State private var selectedTab: AppTab = .home
    @State private var showTabBar = true
    @State private var showReceiveView = false
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                // iPad/Mac - 기존 TabView 사용
                iPadTabView
            } else {
                // iPhone - 커스텀 Tab Bar 사용
                iPhoneCustomTabView
            }
        }
        .sheet(isPresented: $showReceiveView) {
            ReceiveView()
        }
    }
    
    // MARK: - iPad/Mac용 TabView
    private var iPadTabView: some View {
        TabView(selection: $selectedTab) {
            WalletHomeView(
                showTabBar: .constant(true),
                showReceiveView: $showReceiveView
            )
            .tabItem {
                Label(AppTab.home.title, systemImage: AppTab.home.icon)
            }
            .tag(AppTab.home)
            
            WalletHomeView(
                showTabBar: .constant(true),
                showReceiveView: $showReceiveView
            )
            .tabItem {
                Label(AppTab.wallet.title, systemImage: AppTab.wallet.icon)
            }
            .tag(AppTab.wallet)
            
            HistoryView(showTabBar: .constant(true))
                .tabItem {
                    Label(AppTab.history.title, systemImage: AppTab.history.icon)
                }
                .tag(AppTab.history)
            
            SettingsView(showTabBar: .constant(true))
                .tabItem {
                    Label(AppTab.settings.title, systemImage: AppTab.settings.icon)
                }
                .tag(AppTab.settings)
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