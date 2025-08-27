import SwiftUI
import Core
import DesignSystem
import UIKit
import Factory

@main
struct KingthereumApp: App {
    @StateObject private var appCoordinator = AppCoordinator()
    @StateObject private var displayModeService = Container.shared.displayModeService()
    
    init() {
        configureNavigationBar()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appCoordinator)
                .environmentObject(displayModeService) // 환경 객체로도 전달
                .preferredColorScheme(displayModeService.effectiveColorScheme)
                .animation(.easeInOut(duration: 0.3), value: displayModeService.effectiveColorScheme)
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
    @State private var showTransition = false
    
    var body: some View {
        ZStack {
            // 배경 그라데이션
            LinearGradient.enhancedBackgroundGradient
                .ignoresSafeArea()
            
            // 메인 콘텐츠
            Group {
                switch appCoordinator.currentFlow {
                case .splash:
                    SplashView()
                        .transition(.identity)
                case .authentication:
                    AuthenticationView()
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95)).combined(with: .move(edge: .bottom)),
                            removal: .opacity.combined(with: .scale(scale: 1.05)).combined(with: .move(edge: .top))
                        ))
                case .main:
                    MainTabView()
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95)).combined(with: .move(edge: .bottom)),
                            removal: .opacity.combined(with: .scale(scale: 1.05)).combined(with: .move(edge: .top))
                        ))
                }
            }
            .animation(.easeInOut(duration: 1.2), value: appCoordinator.currentFlow)
        }
        .onAppear {
            appCoordinator.start()
        }
    }
}
