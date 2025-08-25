import Foundation
import Entity
import Core
import Factory

@MainActor
protocol SettingsBusinessLogic {
    func loadSettings(request: SettingsScene.LoadSettings.Request)
    func updateDisplayMode(request: SettingsScene.UpdateDisplayMode.Request)
    func updateNotification(request: SettingsScene.UpdateNotification.Request)
    func updateSecurity(request: SettingsScene.UpdateSecurity.Request)
    func updateNetwork(request: SettingsScene.UpdateNetwork.Request)
    func loadProfile(request: SettingsScene.LoadProfile.Request)
}

@MainActor
protocol SettingsDataStore {
    var currentSettings: UserSettings? { get set }
    var currentProfile: WalletProfile? { get set }
    var isLoading: Bool { get set }
}

@MainActor
final class SettingsInteractor: SettingsBusinessLogic, SettingsDataStore {
    var presenter: SettingsPresentationLogic?
    private let worker: SettingsWorkerProtocol
    
    @Injected(\.displayModeService) private var displayModeService
    
    // MARK: - Data Store
    var currentSettings: UserSettings?
    var currentProfile: WalletProfile?
    var isLoading = false
    
    init(worker: SettingsWorkerProtocol? = nil) {
        self.worker = worker ?? SettingsWorker()
        loadDefaultSettings()
    }
    
    // MARK: - Business Logic
    
    func loadSettings(request: SettingsScene.LoadSettings.Request) {
        guard !isLoading else { return }
        
        isLoading = true
        
        Task { [weak self] in
            do {
                let settings = try await self?.worker.loadUserSettings(userId: request.userId)
                let profile = try await self?.worker.loadWalletProfile(address: nil)
                
                guard let settings = settings, let profile = profile else { return }
                
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    
                    self.currentSettings = settings
                    self.currentProfile = profile
                    self.isLoading = false
                    
                    let response = SettingsScene.LoadSettings.Response(
                        settings: settings,
                        error: nil
                    )
                    self.presenter?.presentSettings(response: response)
                }
            } catch {
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    
                    self.isLoading = false
                    
                    let response = SettingsScene.LoadSettings.Response(
                        settings: self.getDefaultSettings(),
                        error: error
                    )
                    self.presenter?.presentSettings(response: response)
                }
            }
        }
    }
    
    func updateDisplayMode(request: SettingsScene.UpdateDisplayMode.Request) {
        Task { [weak self] in
            do {
                try await self?.worker.updateDisplayMode(mode: request.displayMode)
                
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    
                    // Update current settings
                    if var settings = self.currentSettings {
                        settings = UserSettings(
                            displayMode: request.displayMode,
                            fontSize: settings.fontSize,
                            notificationEnabled: settings.notificationEnabled,
                            securityType: settings.securityType,
                            networkType: settings.networkType,
                            currency: settings.currency,
                            language: settings.language
                        )
                        self.currentSettings = settings
                    }
                    
                    // Update display mode service
                    let displayMode = DisplayMode(rawValue: request.displayMode.rawValue) ?? .system
                    self.displayModeService.setDisplayMode(displayMode)
                    
                    let response = SettingsScene.UpdateDisplayMode.Response(
                        success: true,
                        displayMode: request.displayMode,
                        error: nil
                    )
                    self.presenter?.presentDisplayModeUpdate(response: response)
                }
            } catch {
                await MainActor.run { [weak self] in
                    let response = SettingsScene.UpdateDisplayMode.Response(
                        success: false,
                        displayMode: request.displayMode,
                        error: error
                    )
                    self?.presenter?.presentDisplayModeUpdate(response: response)
                }
            }
        }
    }
    
    func updateNotification(request: SettingsScene.UpdateNotification.Request) {
        Task { [weak self] in
            do {
                try await self?.worker.updateNotificationSetting(enabled: request.enabled)
                
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    
                    // Update current settings
                    if var settings = self.currentSettings {
                        settings = UserSettings(
                            displayMode: settings.displayMode,
                            fontSize: settings.fontSize,
                            notificationEnabled: request.enabled,
                            securityType: settings.securityType,
                            networkType: settings.networkType,
                            currency: settings.currency,
                            language: settings.language
                        )
                        self.currentSettings = settings
                    }
                    
                    let response = SettingsScene.UpdateNotification.Response(
                        success: true,
                        enabled: request.enabled,
                        error: nil
                    )
                    self.presenter?.presentNotificationUpdate(response: response)
                }
            } catch {
                await MainActor.run { [weak self] in
                    let response = SettingsScene.UpdateNotification.Response(
                        success: false,
                        enabled: request.enabled,
                        error: error
                    )
                    self?.presenter?.presentNotificationUpdate(response: response)
                }
            }
        }
    }
    
    func updateSecurity(request: SettingsScene.UpdateSecurity.Request) {
        Task { [weak self] in
            do {
                try await self?.worker.updateSecuritySetting(securityType: request.securityType)
                
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    
                    // Update current settings
                    if var settings = self.currentSettings {
                        settings = UserSettings(
                            displayMode: settings.displayMode,
                            fontSize: settings.fontSize,
                            notificationEnabled: settings.notificationEnabled,
                            securityType: request.securityType,
                            networkType: settings.networkType,
                            currency: settings.currency,
                            language: settings.language
                        )
                        self.currentSettings = settings
                    }
                    
                    let response = SettingsScene.UpdateSecurity.Response(
                        success: true,
                        securityType: request.securityType,
                        error: nil
                    )
                    self.presenter?.presentSecurityUpdate(response: response)
                }
            } catch {
                await MainActor.run { [weak self] in
                    let response = SettingsScene.UpdateSecurity.Response(
                        success: false,
                        securityType: request.securityType,
                        error: error
                    )
                    self?.presenter?.presentSecurityUpdate(response: response)
                }
            }
        }
    }
    
    func updateNetwork(request: SettingsScene.UpdateNetwork.Request) {
        Task { [weak self] in
            do {
                try await self?.worker.updateNetworkSetting(networkType: request.networkType)
                
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    
                    // Update current settings
                    if var settings = self.currentSettings {
                        settings = UserSettings(
                            displayMode: settings.displayMode,
                            fontSize: settings.fontSize,
                            notificationEnabled: settings.notificationEnabled,
                            securityType: settings.securityType,
                            networkType: request.networkType,
                            currency: settings.currency,
                            language: settings.language
                        )
                        self.currentSettings = settings
                    }
                    
                    let response = SettingsScene.UpdateNetwork.Response(
                        success: true,
                        networkType: request.networkType,
                        error: nil
                    )
                    self.presenter?.presentNetworkUpdate(response: response)
                }
            } catch {
                await MainActor.run { [weak self] in
                    let response = SettingsScene.UpdateNetwork.Response(
                        success: false,
                        networkType: request.networkType,
                        error: error
                    )
                    self?.presenter?.presentNetworkUpdate(response: response)
                }
            }
        }
    }
    
    func loadProfile(request: SettingsScene.LoadProfile.Request) {
        Task { [weak self] in
            do {
                let profile = try await self?.worker.loadWalletProfile(address: request.walletAddress)
                
                guard let profile = profile else { return }
                
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    
                    self.currentProfile = profile
                    
                    let response = SettingsScene.LoadProfile.Response(
                        profile: profile,
                        error: nil
                    )
                    self.presenter?.presentProfile(response: response)
                }
            } catch {
                await MainActor.run { [weak self] in
                    let response = SettingsScene.LoadProfile.Response(
                        profile: WalletProfile(name: "", address: "", balance: 0),
                        error: error
                    )
                    self?.presenter?.presentProfile(response: response)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func loadDefaultSettings() {
        currentSettings = getDefaultSettings()
        currentProfile = getDefaultProfile()
    }
    
    private func getDefaultSettings() -> UserSettings {
        return UserSettings(
            displayMode: .system,
            fontSize: .medium,
            notificationEnabled: true,
            securityType: .faceID,
            networkType: .mainnet,
            currency: .usd,
            language: .korean
        )
    }
    
    private func getDefaultProfile() -> WalletProfile {
        let address = UserDefaults.standard.string(forKey: Constants.UserDefaults.selectedWalletAddress) ?? ""
        return WalletProfile(
            name: "Kingthereum Wallet",
            address: address,
            balance: 0.0,
            avatarURL: nil
        )
    }
}