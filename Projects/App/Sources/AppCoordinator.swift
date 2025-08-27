import SwiftUI
import Core
import Entity
import SecurityKit
import WalletKit

public enum AppFlow {
    case splash
    case authentication
    case main
}

@MainActor
public final class AppCoordinator: ObservableObject {
    @Published var currentFlow: AppFlow = .splash
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let securityService: SecurityServiceProtocol
    private var walletService: WalletService?
    
    public init(securityService: SecurityServiceProtocol = SecurityService()) {
        self.securityService = securityService
        setupWalletService()
    }
    
    public func start() {
        Task {
            await checkInitialState()
        }
    }
    
    private func checkInitialState() async {
        await MainActor.run {
            isLoading = true
        }
        
        try? await Task.sleep(nanoseconds: 3_600_000_000) // 3.6 second splash with smooth transition
        
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Constants.UserDefaults.hasCompletedOnboarding)
        let isSecuritySetup = await securityService.isSecuritySetup()
        
        await MainActor.run {
            if hasCompletedOnboarding {
                if isSecuritySetup {
                    currentFlow = .authentication
                } else {
                    currentFlow = .main
                }
            } else {
                currentFlow = .authentication
            }
            isLoading = false
        }
    }
    
    public func completeAuthentication() {
        // 인증 완료 후 기존 지갑 복원 시도
        Task {
            await restoreWalletIfAvailable()
            await MainActor.run {
                currentFlow = .main
            }
        }
    }
    
    /// 기존 지갑이 있다면 복원
    private func restoreWalletIfAvailable() async {
        guard UserDefaults.standard.bool(forKey: Constants.UserDefaults.hasCompletedOnboarding) else {
            Logger.debug("⚠️ 온보딩이 완료되지 않아 지갑 복원을 건너뜁니다")
            return
        }
        
        Logger.debug("🔄 기존 지갑 복원을 시도합니다...")
        
        // 저장된 지갑 주소 확인
        if let savedAddress = UserDefaults.standard.string(forKey: Constants.UserDefaults.selectedWalletAddress) {
            Logger.debug("📱 UserDefaults에 저장된 지갑 주소: \(savedAddress)")
        } else {
            Logger.debug("⚠️ UserDefaults에 지갑 주소가 없습니다")
        }
        
        do {
            let authWorker = AuthenticationWorker()
            if let restoredWallet = try await authWorker.restoreExistingWallet() {
                Logger.debug("✅ 지갑 복원 성공: \(restoredWallet.address)")
                
                // 지갑 주소가 UserDefaults에 정확히 저장되었는지 재확인
                let currentSavedAddress = UserDefaults.standard.string(forKey: Constants.UserDefaults.selectedWalletAddress)
                if currentSavedAddress != restoredWallet.address {
                    Logger.debug("🔧 지갑 주소 불일치 발견, 업데이트합니다: \(currentSavedAddress ?? "nil") -> \(restoredWallet.address)")
                    UserDefaults.standard.set(restoredWallet.address, forKey: Constants.UserDefaults.selectedWalletAddress)
                }
            } else {
                Logger.debug("⚠️ 복원할 지갑이 없습니다")
            }
        } catch {
            Logger.debug("❌ 지갑 복원 실패: \(error)")
            await MainActor.run {
                showError("지갑을 불러오는데 실패했습니다. 다시 로그인해주세요.")
            }
        }
    }
    
    public func logout() {
        Task { [weak self] in
            guard let self = self else { return }
            do {
                try await self.securityService.deleteWalletData()
                UserDefaults.standard.removeObject(forKey: Constants.UserDefaults.hasCompletedOnboarding)
                UserDefaults.standard.removeObject(forKey: Constants.UserDefaults.selectedWalletAddress)
                
                await MainActor.run {
                    self.currentFlow = .authentication
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    public func showError(_ message: String) {
        errorMessage = message
    }
    
    public func clearError() {
        errorMessage = nil
    }
    
    private func setupWalletService() {
        Task {
            do {
                let rpcURL = Network.ethereum.rpcURL
                let service = try WalletService.initialize(rpcURL: rpcURL)
                await MainActor.run {
                    self.walletService = service
                }
            } catch {
                Logger.debug("Failed to setup wallet service: \(error)")
            }
        }
    }
}
