import SwiftUI
import Foundation
import Entity

/// Router와 SwiftUI NavigationStack을 연결하는 코디네이터
/// 앱의 네비게이션을 중앙에서 관리
@MainActor
public struct RouterCoordinator {
    
    // MARK: - Shared Router Instance
    
    /// 앱의 메인 Router 인스턴스
    public static let shared = AppRouter()
    
    // MARK: - NavigationStack Integration
    
    /// NavigationStack과 Router를 통합하는 ViewBuilder
    public struct NavigationContainer<Content: View>: View {
        let router: AppRouter
        let content: () -> Content
        
        public init(router: AppRouter = RouterCoordinator.shared, @ViewBuilder content: @escaping () -> Content) {
            self.router = router
            self.content = content
        }
        
        public var body: some View {
            @Bindable var bindableRouter = router
            NavigationStack(path: $bindableRouter.navigationPath) {
                content()
                    .navigationDestination(for: AppRoute.self) { route in
                        destinationView(for: route)
                    }
            }
            .sheet(isPresented: $bindableRouter.isModalPresented) {
                if let modal = router.presentedModal {
                    modalView(for: modal)
                }
            }
            .environment(router)
        }
        
        /// 라우트에 따른 목적지 뷰 생성
        @ViewBuilder
        private func destinationView(for route: AppRoute) -> some View {
            switch route {
            case .authentication(let authRoute):
                authenticationView(for: authRoute)
                
            case .wallet(let walletRoute):
                walletView(for: walletRoute)
                
            case .settings(let settingsRoute):
                settingsView(for: settingsRoute)
                
            case .history(let historyRoute):
                historyView(for: historyRoute)
                
            case .modal:
                EmptyView() // 모달은 별도 처리
            }
        }
        
        /// 인증 관련 뷰
        @ViewBuilder
        private func authenticationView(for route: AuthenticationRoute) -> some View {
            switch route {
            case .welcome:
                // AuthenticationWelcomeView()
                Text("Welcome View")
                    .navigationTitle("환영합니다")
                
            case .pinSetup(let isFirstTime):
                // PINSetupView(isFirstTime: isFirstTime)
                Text("PIN Setup: \(isFirstTime ? "처음" : "재설정")")
                    .navigationTitle("PIN 설정")
                
            case .biometricSetup:
                // BiometricSetupView()
                Text("Biometric Setup View")
                    .navigationTitle("생체 인증 설정")
                
            case .walletCreation:
                // WalletCreationView()
                Text("Wallet Creation View")
                    .navigationTitle("지갑 생성")
                
            case .walletImport(let method):
                // WalletImportView(method: method)
                Text("Wallet Import: \(method.displayName)")
                    .navigationTitle("지갑 가져오기")
                
            case .securityOptions:
                // SecurityOptionsView()
                Text("Security Options View")
                    .navigationTitle("보안 옵션")
                
            case .backup:
                // WalletBackupView()
                Text("Wallet Backup View")
                    .navigationTitle("지갑 백업")
            }
        }
        
        /// 지갑 관련 뷰
        @ViewBuilder
        private func walletView(for route: WalletRoute) -> some View {
            switch route {
            case .send(let address):
                // SendView(walletAddress: address)
                Text("Send View: \(address)")
                    .navigationTitle("송금")
                
            case .receive(let address):
                // ReceiveView(walletAddress: address)
                Text("Receive View: \(address)")
                    .navigationTitle("수신")
                
            case .transactionDetail(let id):
                // TransactionDetailView(transactionID: id)
                Text("Transaction Detail: \(id)")
                    .navigationTitle("거래 상세")
                
            case .tokenDetail(let token):
                // TokenDetailView(token: token)
                Text("Token Detail: \(token)")
                    .navigationTitle("토큰 상세")
            }
        }
        
        /// 설정 관련 뷰
        @ViewBuilder
        private func settingsView(for route: SettingsRoute) -> some View {
            switch route {
            case .displayMode:
                // DisplayModeSettingsView()
                Text("Display Mode Settings")
                    .navigationTitle("화면 모드")
                
            case .notifications:
                // NotificationSettingsView()
                Text("Notification Settings")
                    .navigationTitle("알림 설정")
                
            case .security:
                // SecuritySettingsView()
                Text("Security Settings")
                    .navigationTitle("보안 설정")
                
            case .network:
                // NetworkSettingsView()
                Text("Network Settings")
                    .navigationTitle("네트워크 설정")
                
            case .currency:
                // CurrencySettingsView()
                Text("Currency Settings")
                    .navigationTitle("통화 설정")
                
            case .language:
                // LanguageSettingsView()
                Text("Language Settings")
                    .navigationTitle("언어 설정")
                
            case .profile:
                // ProfileView()
                Text("Profile View")
                    .navigationTitle("프로필")
                
            case .help:
                // HelpView()
                Text("Help View")
                    .navigationTitle("도움말")
                
            case .termsOfService:
                // TermsOfServiceView()
                Text("Terms of Service")
                    .navigationTitle("서비스 약관")
                
            case .privacyPolicy:
                // PrivacyPolicyView()
                Text("Privacy Policy")
                    .navigationTitle("개인정보 정책")
            }
        }
        
        /// 거래 내역 관련 뷰
        @ViewBuilder
        private func historyView(for route: HistoryRoute) -> some View {
            switch route {
            case .transactionList:
                // TransactionListView()
                Text("Transaction List")
                    .navigationTitle("거래 내역")
                
            case .transactionDetail(let id):
                // TransactionDetailView(id: id)
                Text("Transaction Detail: \(id)")
                    .navigationTitle("거래 상세")
                
            case .filter:
                // TransactionFilterView()
                Text("Transaction Filter")
                    .navigationTitle("필터")
                
            case .export:
                // TransactionExportView()
                Text("Transaction Export")
                    .navigationTitle("내보내기")
            }
        }
        
        /// 모달 뷰
        @ViewBuilder
        private func modalView(for modal: ModalRoute) -> some View {
            switch modal {
            case .alert(let title, let message):
                // CustomAlertView(title: title, message: message)
                VStack(spacing: 20) {
                    Text(title)
                        .font(.headline)
                    Text(message)
                        .font(.body)
                    Button("확인") {
                        router.dismissModal()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .presentationDetents([.height(200)])
                
            case .confirmation(let title, let message, let action):
                // ConfirmationView(title: title, message: message, action: action)
                VStack(spacing: 20) {
                    Text(title)
                        .font(.headline)
                    Text(message)
                        .font(.body)
                    HStack {
                        Button("취소") {
                            router.dismissModal()
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action) {
                            router.dismissModal()
                            // 확인 액션 실행
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
                .presentationDetents([.height(250)])
                
            case .loading(let message):
                // LoadingView(message: message)
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text(message)
                        .font(.body)
                }
                .padding()
                .presentationDetents([.height(150)])
                .interactiveDismissDisabled()
                
            case .error(let message):
                // ErrorView(message: message)
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.largeTitle)
                    Text("오류")
                        .font(.headline)
                    Text(message)
                        .font(.body)
                        .multilineTextAlignment(.center)
                    Button("확인") {
                        router.dismissModal()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .presentationDetents([.height(300)])
            }
        }
    }
    
    // MARK: - Environment Integration
    
    /// Router를 환경에 주입하는 ViewModifier
    public struct RouterEnvironment: ViewModifier {
        let router: AppRouter
        
        public func body(content: Content) -> some View {
            content
                .environment(router)
        }
    }
}

// MARK: - SwiftUI Extensions

public extension View {
    
    /// Router를 환경에 주입
    func withRouter(_ router: AppRouter = RouterCoordinator.shared) -> some View {
        self.modifier(RouterCoordinator.RouterEnvironment(router: router))
    }
    
    /// NavigationContainer로 래핑
    func withNavigationContainer(router: AppRouter = RouterCoordinator.shared) -> some View {
        RouterCoordinator.NavigationContainer(router: router) {
            self
        }
    }
}

// MARK: - Deep Link Handling

public extension RouterCoordinator {
    
    /// 딥링크 처리
    static func handleDeepLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let host = components.host else {
            return
        }
        
        let pathComponents = components.path.components(separatedBy: "/").filter { !$0.isEmpty }
        let queryItems = components.queryItems
                
        switch host {
        case "send":
            if let walletAddress = queryItems?.first(where: { $0.name == "address" })?.value {
                shared.navigate(to: .wallet(.send(walletAddress: walletAddress)))
            }
            
        case "receive":
            if let walletAddress = queryItems?.first(where: { $0.name == "address" })?.value {
                shared.navigate(to: .wallet(.receive(walletAddress: walletAddress)))
            }
            
        case "transaction":
            if let transactionId = pathComponents.first {
                shared.navigate(to: .wallet(.transactionDetail(transactionID: transactionId)))
            }
            
        case "settings":
            if let settingType = pathComponents.first {
                switch settingType {
                case "display": shared.navigate(to: .settings(.displayMode))
                case "security": shared.navigate(to: .settings(.security))
                case "notifications": shared.navigate(to: .settings(.notifications))
                default: shared.navigate(to: .settings(.profile))
                }
            }
            
        case "auth":
            shared.startAuthenticationFlow()
            
        default:
            Logger.error("❌ Unhandled deep link host: \(host)")
        }
    }
}

// MARK: - Router Testing Utilities

#if DEBUG
public extension RouterCoordinator {
    
    /// 테스트용 Router 상태 출력
    static func printRouterStatus() {
        let history = shared.getNavigationHistory()
        print("🧭 Router Status:")
        print("  - Current depth: \(shared.currentDepth)")
        print("  - Can go back: \(shared.canGoBack)")
        print("  - Modal presented: \(shared.isModalPresented)")
        print("  - Navigation history count: \(history.count)")
        
        if !history.isEmpty {
            print("  - Recent navigation:")
            for event in history.suffix(5) {
                print("    \(event.action): \(event.route ?? "nil") (depth: \(event.depth))")
            }
        }
    }
    
    /// 테스트용 Router 리셋
    static func resetForTesting() {
        shared.goToRoot()
        shared.dismissModal()
        shared.clearNavigationHistory()
    }
}
#endif
