import Foundation
import Entity
import Core

@MainActor
protocol SettingsPresentationLogic {
    func presentSettings(response: SettingsScene.LoadSettings.Response)
    func presentDisplayModeUpdate(response: SettingsScene.UpdateDisplayMode.Response)
    func presentNotificationUpdate(response: SettingsScene.UpdateNotification.Response)
    func presentSecurityUpdate(response: SettingsScene.UpdateSecurity.Response)
    func presentNetworkUpdate(response: SettingsScene.UpdateNetwork.Response)
    func presentProfile(response: SettingsScene.LoadProfile.Response)
}

@MainActor
final class SettingsPresenter: SettingsPresentationLogic {
    weak var viewController: SettingsDisplayLogic?
    
    func presentSettings(response: SettingsScene.LoadSettings.Response) {
        if let error = response.error {
            let displayModel = SettingsScene.LoadSettings.ViewModel(
                displayMode: response.settings.displayMode.displayName,
                fontSize: response.settings.fontSize.displayName,
                notificationEnabled: response.settings.notificationEnabled,
                securityMode: response.settings.securityType.displayName,
                network: response.settings.networkType.displayName,
                currency: response.settings.currency.displayName,
                language: response.settings.language.displayName,
                profileData: ProfileData(
                    displayName: "Kingthereum Wallet",
                    formattedAddress: "주소를 불러올 수 없습니다",
                    avatarInitials: "K"
                ),
                errorMessage: formatErrorMessage(error)
            )
            viewController?.displaySettings(viewModel: displayModel)
            return
        }
        
        let profileData = createProfileData(from: WalletProfile(
            name: "Kingthereum Wallet",
            address: getCurrentWalletAddress(),
            balance: 0.0
        ))
        
        let displayModel = SettingsScene.LoadSettings.ViewModel(
            displayMode: response.settings.displayMode.displayName,
            fontSize: response.settings.fontSize.displayName,
            notificationEnabled: response.settings.notificationEnabled,
            securityMode: response.settings.securityType.displayName,
            network: response.settings.networkType.displayName,
            currency: response.settings.currency.displayName,
            language: response.settings.language.displayName,
            profileData: profileData,
            errorMessage: nil
        )
        
        viewController?.displaySettings(viewModel: displayModel)
    }
    
    func presentDisplayModeUpdate(response: SettingsScene.UpdateDisplayMode.Response) {
        if let error = response.error {
            let displayModel = SettingsScene.UpdateDisplayMode.ViewModel(
                displayMode: response.displayMode.displayName,
                successMessage: nil,
                errorMessage: formatErrorMessage(error)
            )
            viewController?.displayDisplayModeUpdate(viewModel: displayModel)
            return
        }
        
        let displayModel = SettingsScene.UpdateDisplayMode.ViewModel(
            displayMode: response.displayMode.displayName,
            successMessage: "화면 모드가 변경되었습니다",
            errorMessage: nil
        )
        
        viewController?.displayDisplayModeUpdate(viewModel: displayModel)
    }
    
    func presentNotificationUpdate(response: SettingsScene.UpdateNotification.Response) {
        if let error = response.error {
            let displayModel = SettingsScene.UpdateNotification.ViewModel(
                enabled: response.enabled,
                statusText: response.enabled ? "켜짐" : "꺼짐",
                successMessage: nil,
                errorMessage: formatErrorMessage(error)
            )
            viewController?.displayNotificationUpdate(viewModel: displayModel)
            return
        }
        
        let statusText = response.enabled ? "켜짐" : "꺼짐"
        let successMessage = response.enabled ? "알림이 활성화되었습니다" : "알림이 비활성화되었습니다"
        
        let displayModel = SettingsScene.UpdateNotification.ViewModel(
            enabled: response.enabled,
            statusText: statusText,
            successMessage: successMessage,
            errorMessage: nil
        )
        
        viewController?.displayNotificationUpdate(viewModel: displayModel)
    }
    
    func presentSecurityUpdate(response: SettingsScene.UpdateSecurity.Response) {
        if let error = response.error {
            let displayModel = SettingsScene.UpdateSecurity.ViewModel(
                securityMode: response.securityType.displayName,
                successMessage: nil,
                errorMessage: formatErrorMessage(error)
            )
            viewController?.displaySecurityUpdate(viewModel: displayModel)
            return
        }
        
        let successMessage: String
        switch response.securityType {
        case .none:
            successMessage = "보안 설정이 해제되었습니다"
        case .pin:
            successMessage = "PIN 보안이 설정되었습니다"
        case .faceID:
            successMessage = "Face ID 보안이 설정되었습니다"
        case .touchID:
            successMessage = "Touch ID 보안이 설정되었습니다"
        }
        
        let displayModel = SettingsScene.UpdateSecurity.ViewModel(
            securityMode: response.securityType.displayName,
            successMessage: successMessage,
            errorMessage: nil
        )
        
        viewController?.displaySecurityUpdate(viewModel: displayModel)
    }
    
    func presentNetworkUpdate(response: SettingsScene.UpdateNetwork.Response) {
        if let error = response.error {
            let displayModel = SettingsScene.UpdateNetwork.ViewModel(
                network: response.networkType.displayName,
                successMessage: nil,
                errorMessage: formatErrorMessage(error)
            )
            viewController?.displayNetworkUpdate(viewModel: displayModel)
            return
        }
        
        let successMessage = "네트워크가 \(response.networkType.displayName)로 변경되었습니다"
        
        let displayModel = SettingsScene.UpdateNetwork.ViewModel(
            network: response.networkType.displayName,
            successMessage: successMessage,
            errorMessage: nil
        )
        
        viewController?.displayNetworkUpdate(viewModel: displayModel)
    }
    
    func presentProfile(response: SettingsScene.LoadProfile.Response) {
        if let error = response.error {
            let profileData = ProfileData(
                displayName: "Kingthereum Wallet",
                formattedAddress: "주소를 불러올 수 없습니다",
                avatarInitials: "K"
            )
            
            let displayModel = SettingsScene.LoadProfile.ViewModel(
                profileData: profileData,
                errorMessage: formatErrorMessage(error)
            )
            viewController?.displayProfile(viewModel: displayModel)
            return
        }
        
        let profileData = createProfileData(from: response.profile)
        
        let displayModel = SettingsScene.LoadProfile.ViewModel(
            profileData: profileData,
            errorMessage: nil
        )
        
        viewController?.displayProfile(viewModel: displayModel)
    }
    
    // MARK: - Private Methods
    
    private func createProfileData(from profile: WalletProfile) -> ProfileData {
        let formattedAddress = formatWalletAddress(profile.address)
        let avatarInitials = createAvatarInitials(from: profile.name)
        
        return ProfileData(
            displayName: profile.name,
            formattedAddress: formattedAddress,
            avatarInitials: avatarInitials
        )
    }
    
    private func formatWalletAddress(_ address: String) -> String {
        guard address.count > 10 else { return address }
        
        let start = String(address.prefix(6))
        let end = String(address.suffix(4))
        return "\(start)...\(end)"
    }
    
    private func createAvatarInitials(from name: String) -> String {
        let components = name.split(separator: " ")
        
        if components.count >= 2 {
            return String(components[0].prefix(1)) + String(components[1].prefix(1))
        } else if let firstComponent = components.first {
            return String(firstComponent.prefix(1))
        } else {
            return "K"
        }
    }
    
    private func getCurrentWalletAddress() -> String {
        return UserDefaults.standard.string(forKey: Constants.UserDefaults.selectedWalletAddress) ?? ""
    }
    
    private func formatErrorMessage(_ error: Error) -> String {
        if let networkError = error as? Core.NetworkError {
            switch networkError {
            case .invalidResponse:
                return "유효하지 않은 응답입니다"
            case .clientError(let code):
                return "클라이언트 오류 (HTTP \(code))"
            case .serverError(let code):
                return "서버 오류 (HTTP \(code))"
            case .unexpectedStatusCode(let code):
                return "예상하지 못한 상태 코드 (HTTP \(code))"
            case .unsupportedHTTPMethod(let method):
                return "지원하지 않는 HTTP 메서드: \(method)"
            }
        }
        
        return error.localizedDescription
    }
}