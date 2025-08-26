import SwiftUI
import Core
import DesignSystem
import UIKit
import Factory

@main
struct KingthereumApp: App {
    @StateObject private var appCoordinator = AppCoordinator()
    @StateObject private var displayModeService = DisplayModeService()
    
    init() {
        // Factory는 lazy loading이므로 별도 초기화 불필요
        configureNavigationBar()
        
        // DisplayModeService는 Factory @Injected로 자동 주입
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appCoordinator)
                .preferredColorScheme(displayModeService.effectiveColorScheme)
        }
    }
    
    private func configureNavigationBar() {
        // 네비게이션 바 투명 스타일 설정
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.8)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        
        // 탭바 스타일 설정
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithTransparentBackground()
        tabBarAppearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.8)
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
}

struct ContentView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    
    var body: some View {
        Group {
            switch appCoordinator.currentFlow {
            case .splash:
                SplashView()
            case .authentication:
                AuthenticationView()
            case .main:
                MainTabView()
            }
        }
        .background(LinearGradient.enhancedBackgroundGradient.ignoresSafeArea())
        .onAppear {
            appCoordinator.start()
        }
    }
}
