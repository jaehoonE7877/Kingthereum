import Foundation

import Entity
import SecurityKit

@MainActor
protocol AuthenticationPresentationLogic {
    func presentPINSetupResult(response: AuthenticationScene.SetupPIN.Response)
    func presentBiometricAuthenticationResult(response: AuthenticationScene.AuthenticateWithBiometrics.Response)
    func presentPINAuthenticationResult(response: AuthenticationScene.AuthenticateWithPIN.Response)
    func presentBiometricAvailability(response: AuthenticationScene.CheckBiometricAvailability.Response)
    func presentWalletCreationResult(response: AuthenticationScene.CreateWallet.Response)
    func presentWalletImportResult(response: AuthenticationScene.ImportWallet.Response)
}

@MainActor
final class AuthenticationPresenter: AuthenticationPresentationLogic {
    weak var viewController: AuthenticationDisplayLogic?
    
    func presentPINSetupResult(response: AuthenticationScene.SetupPIN.Response) {
        let displayModel = AuthenticationScene.SetupPIN.ViewModel(
            success: response.success,
            errorMessage: response.error?.localizedDescription
        )
        viewController?.displayPINSetupResult(viewModel: displayModel)
    }
    
    func presentBiometricAuthenticationResult(response: AuthenticationScene.AuthenticateWithBiometrics.Response) {
        let displayModel = AuthenticationScene.AuthenticateWithBiometrics.ViewModel(
            success: response.success,
            biometricTypeDescription: response.biometricType.description,
            errorMessage: response.error?.localizedDescription
        )
        viewController?.displayBiometricAuthenticationResult(viewModel: displayModel)
    }
    
    func presentPINAuthenticationResult(response: AuthenticationScene.AuthenticateWithPIN.Response) {
        let displayModel = AuthenticationScene.AuthenticateWithPIN.ViewModel(
            success: response.success,
            errorMessage: response.error?.localizedDescription
        )
        viewController?.displayPINAuthenticationResult(viewModel: displayModel)
    }
    
    func presentBiometricAvailability(response: AuthenticationScene.CheckBiometricAvailability.Response) {
        let biometricIcon: String
        switch response.biometricType {
        case .none:
            biometricIcon = "lock"
        case .touchID:
            biometricIcon = "touchid"
        case .faceID:
            biometricIcon = "faceid"
        case .opticID:
            biometricIcon = "opticid"
        }
        
        let displayModel = AuthenticationScene.CheckBiometricAvailability.ViewModel(
            isAvailable: response.isAvailable,
            biometricTypeDescription: response.biometricType.description,
            biometricIcon: biometricIcon
        )
        viewController?.displayBiometricAvailability(viewModel: displayModel)
    }
    
    func presentWalletCreationResult(response: AuthenticationScene.CreateWallet.Response) {
        let displayModel = AuthenticationScene.CreateWallet.ViewModel(
            success: response.success,
            walletAddress: response.walletAddress,
            mnemonic: response.mnemonic,
            errorMessage: response.error?.localizedDescription
        )
        viewController?.displayWalletCreationResult(viewModel: displayModel)
    }
    
    func presentWalletImportResult(response: AuthenticationScene.ImportWallet.Response) {
        let displayModel = AuthenticationScene.ImportWallet.ViewModel(
            success: response.success,
            walletAddress: response.walletAddress,
            errorMessage: response.error?.localizedDescription
        )
        viewController?.displayWalletImportResult(viewModel: displayModel)
    }
}
