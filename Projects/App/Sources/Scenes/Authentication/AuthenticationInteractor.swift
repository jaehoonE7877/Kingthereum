import Foundation
import Core
import Entity

import SecurityKit
import WalletKit

@MainActor
protocol AuthenticationBusinessLogic {
    func setupPIN(request: AuthenticationScene.SetupPIN.Request)
    func authenticateWithBiometrics(request: AuthenticationScene.AuthenticateWithBiometrics.Request)
    func authenticateWithPIN(request: AuthenticationScene.AuthenticateWithPIN.Request)
    func checkBiometricAvailability(request: AuthenticationScene.CheckBiometricAvailability.Request)
    func createWallet(request: AuthenticationScene.CreateWallet.Request)
    func importWalletFromMnemonic(request: AuthenticationScene.ImportWallet.Request)
}

@MainActor
protocol AuthenticationDataStore {
    var isSetupMode: Bool { get set }
    var hasExistingWallet: Bool { get set }
}

@MainActor
final class AuthenticationInteractor: AuthenticationBusinessLogic, AuthenticationDataStore {
    var presenter: AuthenticationPresentationLogic?
    private let worker: AuthenticationWorker
    
    // MARK: - Data Store
    var isSetupMode = false
    var hasExistingWallet = false
    
    init() {
        self.worker = AuthenticationWorker()
        checkExistingWallet()
    }
    
    // MARK: - Business Logic
    func setupPIN(request: AuthenticationScene.SetupPIN.Request) {
        Task { [weak self] in
            do {
                try await self?.worker.setupPIN(request.pin)
                
                let response = AuthenticationScene.SetupPIN.Response(
                    success: true,
                    error: nil
                )
                await MainActor.run { [weak self] in
                    self?.presenter?.presentPINSetupResult(response: response)
                }
            } catch {
                let response = AuthenticationScene.SetupPIN.Response(
                    success: false,
                    error: error
                )
                await MainActor.run { [weak self] in
                    self?.presenter?.presentPINSetupResult(response: response)
                }
            }
        }
    }
    
    func authenticateWithBiometrics(request: AuthenticationScene.AuthenticateWithBiometrics.Request) {
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let success = try await self.worker.authenticateWithBiometrics(reason: request.reason)
                let biometricType = await self.worker.getBiometricType()
                
                let response = AuthenticationScene.AuthenticateWithBiometrics.Response(
                    success: success,
                    biometricType: biometricType,
                    error: nil
                )
                await MainActor.run {
                    self.presenter?.presentBiometricAuthenticationResult(response: response)
                }
            } catch {
                let biometricType = await self.worker.getBiometricType()
                let response = AuthenticationScene.AuthenticateWithBiometrics.Response(
                    success: false,
                    biometricType: biometricType,
                    error: error
                )
                await MainActor.run {
                    self.presenter?.presentBiometricAuthenticationResult(response: response)
                }
            }
        }
    }
    
    func authenticateWithPIN(request: AuthenticationScene.AuthenticateWithPIN.Request) {
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let success = try await self.worker.authenticateWithPIN(request.pin)
                
                let response = AuthenticationScene.AuthenticateWithPIN.Response(
                    success: success,
                    error: nil
                )
                await MainActor.run {
                    self.presenter?.presentPINAuthenticationResult(response: response)
                }
            } catch {
                let response = AuthenticationScene.AuthenticateWithPIN.Response(
                    success: false,
                    error: error
                )
                await MainActor.run {
                    self.presenter?.presentPINAuthenticationResult(response: response)
                }
            }
        }
    }
    
    func checkBiometricAvailability(request: AuthenticationScene.CheckBiometricAvailability.Request) {
        Task { [weak self] in
            guard let self = self else { return }
            let isAvailable = await self.worker.isBiometricAvailable()
            let biometricType = await self.worker.getBiometricType()
            
            let response = AuthenticationScene.CheckBiometricAvailability.Response(
                isAvailable: isAvailable,
                biometricType: biometricType
            )
            
            await MainActor.run {
                self.presenter?.presentBiometricAvailability(response: response)
            }
        }
    }
    
    func createWallet(request: AuthenticationScene.CreateWallet.Request) {
        Task { [weak self] in
            guard let self = self else { return }
            do {
                // 니모닉과 함께 지갑 생성
                let result = try await self.worker.createWalletWithMnemonic(name: request.walletName)
                
                let response = AuthenticationScene.CreateWallet.Response(
                    success: true,
                    walletAddress: result.wallet.address,
                    mnemonic: result.mnemonic,
                    error: nil
                )
                await MainActor.run {
                    self.presenter?.presentWalletCreationResult(response: response)
                }
            } catch {
                let response = AuthenticationScene.CreateWallet.Response(
                    success: false,
                    walletAddress: nil,
                    mnemonic: nil,
                    error: error
                )
                await MainActor.run {
                    self.presenter?.presentWalletCreationResult(response: response)
                }
            }
        }
    }
    
    func importWalletFromMnemonic(request: AuthenticationScene.ImportWallet.Request) {
        Task { [weak self] in
            guard let self = self else { return }
            do {
                // 먼저 PIN 설정
                try await self.worker.setupPIN(request.pin)
                
                // 니모닉으로 지갑 복원
                let wallet = try await self.worker.importWalletFromMnemonic(
                    name: request.walletName,
                    mnemonic: request.mnemonic
                )
                
                let response = AuthenticationScene.ImportWallet.Response(
                    success: true,
                    walletAddress: wallet.address,
                    error: nil
                )
                await MainActor.run {
                    self.presenter?.presentWalletImportResult(response: response)
                }
            } catch {
                let response = AuthenticationScene.ImportWallet.Response(
                    success: false,
                    walletAddress: nil,
                    error: error
                )
                await MainActor.run {
                    self.presenter?.presentWalletImportResult(response: response)
                }
            }
        }
    }
    
    private func checkExistingWallet() {
        hasExistingWallet = UserDefaults.standard.string(forKey: Constants.UserDefaults.selectedWalletAddress) != nil
        isSetupMode = !UserDefaults.standard.bool(forKey: Constants.UserDefaults.hasCompletedOnboarding)
    }
}
