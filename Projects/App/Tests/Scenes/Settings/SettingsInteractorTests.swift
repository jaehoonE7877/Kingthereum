import Testing
import Foundation
@testable import App
@testable import Entity
@testable import Core

// MARK: - SettingsInteractor Tests

@Suite("SettingsInteractor 테스트")
struct SettingsInteractorTests {
    
    // MARK: - Spy Classes
    
    @MainActor
    class PresentationLogicSpy: SettingsPresentationLogic {
        var presentSettingsCalled = false
        var presentSettingsResponse: SettingsScene.LoadSettings.Response?
        
        var presentDisplayModeUpdateCalled = false
        var presentDisplayModeUpdateResponse: SettingsScene.UpdateDisplayMode.Response?
        
        var presentNotificationUpdateCalled = false
        var presentNotificationUpdateResponse: SettingsScene.UpdateNotification.Response?
        
        var presentSecurityUpdateCalled = false
        var presentSecurityUpdateResponse: SettingsScene.UpdateSecurity.Response?
        
        var presentNetworkUpdateCalled = false
        var presentNetworkUpdateResponse: SettingsScene.UpdateNetwork.Response?
        
        var presentProfileCalled = false
        var presentProfileResponse: SettingsScene.LoadProfile.Response?
        
        func presentSettings(response: SettingsScene.LoadSettings.Response) {
            presentSettingsCalled = true
            presentSettingsResponse = response
        }
        
        func presentDisplayModeUpdate(response: SettingsScene.UpdateDisplayMode.Response) {
            presentDisplayModeUpdateCalled = true
            presentDisplayModeUpdateResponse = response
        }
        
        func presentNotificationUpdate(response: SettingsScene.UpdateNotification.Response) {
            presentNotificationUpdateCalled = true
            presentNotificationUpdateResponse = response
        }
        
        func presentSecurityUpdate(response: SettingsScene.UpdateSecurity.Response) {
            presentSecurityUpdateCalled = true
            presentSecurityUpdateResponse = response
        }
        
        func presentNetworkUpdate(response: SettingsScene.UpdateNetwork.Response) {
            presentNetworkUpdateCalled = true
            presentNetworkUpdateResponse = response
        }
        
        func presentProfile(response: SettingsScene.LoadProfile.Response) {
            presentProfileCalled = true
            presentProfileResponse = response
        }
    }
    
    actor WorkerSpy: SettingsWorkerProtocol {
        var loadUserSettingsCalled = false
        var loadUserSettingsResult: Result<UserSettings, Error> = .success(createDefaultUserSettings())
        
        var updateDisplayModeCalled = false
        var updateDisplayModeResult: Result<Void, Error> = .success(())
        var lastDisplayMode: DisplayModeType?
        
        var updateNotificationSettingCalled = false
        var updateNotificationSettingResult: Result<Void, Error> = .success(())
        var lastNotificationEnabled: Bool?
        
        var updateSecuritySettingCalled = false
        var updateSecuritySettingResult: Result<Void, Error> = .success(())
        var lastSecurityType: SecurityType?
        
        var updateNetworkSettingCalled = false
        var updateNetworkSettingResult: Result<Void, Error> = .success(())
        var lastNetworkType: NetworkType?
        
        var loadWalletProfileCalled = false
        var loadWalletProfileResult: Result<WalletProfile, Error> = .success(createDefaultWalletProfile())
        
        func loadUserSettings(userId: String) async throws -> UserSettings {
            loadUserSettingsCalled = true
            switch loadUserSettingsResult {
            case .success(let settings):
                return settings
            case .failure(let error):
                throw error
            }
        }
        
        func updateDisplayMode(mode: DisplayModeType) async throws {
            updateDisplayModeCalled = true
            lastDisplayMode = mode
            switch updateDisplayModeResult {
            case .success:
                break
            case .failure(let error):
                throw error
            }
        }
        
        func updateNotificationSetting(enabled: Bool) async throws {
            updateNotificationSettingCalled = true
            lastNotificationEnabled = enabled
            switch updateNotificationSettingResult {
            case .success:
                break
            case .failure(let error):
                throw error
            }
        }
        
        func updateSecuritySetting(securityType: SecurityType) async throws {
            updateSecuritySettingCalled = true
            lastSecurityType = securityType
            switch updateSecuritySettingResult {
            case .success:
                break
            case .failure(let error):
                throw error
            }
        }
        
        func updateNetworkSetting(networkType: NetworkType) async throws {
            updateNetworkSettingCalled = true
            lastNetworkType = networkType
            switch updateNetworkSettingResult {
            case .success:
                break
            case .failure(let error):
                throw error
            }
        }
        
        func loadWalletProfile(address: String?) async throws -> WalletProfile {
            loadWalletProfileCalled = true
            switch loadWalletProfileResult {
            case .success(let profile):
                return profile
            case .failure(let error):
                throw error
            }
        }
        
        static func createDefaultUserSettings() -> UserSettings {
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
        
        static func createDefaultWalletProfile() -> WalletProfile {
            return WalletProfile(
                name: "Test Wallet",
                address: "0x742d35Cc6634C0Dcc6b9C2b48b9bC4C8b9d9aE3",
                balance: Decimal(2.5),
                avatarURL: nil
            )
        }
    }
    
    // MARK: - 설정 로드 테스트
    
    @Suite("설정 로드")
    struct LoadSettings {
        
        @Test("성공 케이스 - 설정 로드")
        func testLoadSettingsSuccess() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let mockSettings = UserSettings(
                displayMode: .dark,
                fontSize: .large,
                notificationEnabled: false,
                securityType: .pin,
                networkType: .sepolia,
                currency: .krw,
                language: .english
            )
            
            await workerSpy.setLoadUserSettingsResult(.success(mockSettings))
            
            let sut = SettingsInteractor(worker: workerSpy)
            sut.presenter = presenterSpy
            
            let request = SettingsScene.LoadSettings.Request(userId: "test-user-123")
            
            // When
            sut.loadSettings(request: request)
            
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            // Then
            #expect(await workerSpy.loadUserSettingsCalled == true, "Worker의 설정 로드가 호출되어야 함")
            #expect(presenterSpy.presentSettingsCalled == true, "Presenter가 호출되어야 함")
            
            let response = presenterSpy.presentSettingsResponse
            #expect(response != nil, "Response가 전달되어야 함")
            #expect(response?.settings.displayMode == .dark, "다크 모드가 설정되어야 함")
            #expect(response?.settings.fontSize == .large, "큰 글씨가 설정되어야 함")
            #expect(response?.settings.notificationEnabled == false, "알림이 비활성화되어야 함")
            #expect(response?.settings.securityType == .pin, "PIN 보안이 설정되어야 함")
            #expect(response?.settings.networkType == .sepolia, "Sepolia 네트워크가 설정되어야 함")
            #expect(response?.error == nil, "에러가 없어야 함")
            
            // DataStore 상태 확인
            #expect(sut.currentSettings?.displayMode == .dark, "DataStore에 설정이 저장되어야 함")
            #expect(sut.isLoading == false, "로딩 상태가 해제되어야 함")
        }
        
        @Test("실패 케이스 - 설정 로드 에러")
        func testLoadSettingsError() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let settingsError = SettingsError.networkConnectionFailed
            await workerSpy.setLoadUserSettingsResult(.failure(settingsError))
            
            let sut = SettingsInteractor(worker: workerSpy)
            sut.presenter = presenterSpy
            
            let request = SettingsScene.LoadSettings.Request(userId: "test-user-123")
            
            // When
            sut.loadSettings(request: request)
            
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            // Then
            #expect(await workerSpy.loadUserSettingsCalled == true, "Worker가 호출되어야 함")
            #expect(presenterSpy.presentSettingsCalled == true, "Presenter가 호출되어야 함")
            
            let response = presenterSpy.presentSettingsResponse
            #expect(response?.error != nil, "에러가 전달되어야 함")
            #expect(sut.isLoading == false, "로딩 상태가 해제되어야 함")
        }
        
        @Test("중복 로딩 방지")
        func testLoadSettingsPreventDuplicateLoading() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let sut = SettingsInteractor(worker: workerSpy)
            sut.presenter = presenterSpy
            sut.isLoading = true // 이미 로딩 중
            
            let request = SettingsScene.LoadSettings.Request(userId: "test-user-123")
            
            // When
            sut.loadSettings(request: request)
            
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            // Then
            #expect(await workerSpy.loadUserSettingsCalled == false, "이미 로딩 중이므로 Worker가 호출되지 않아야 함")
            #expect(presenterSpy.presentSettingsCalled == false, "Presenter가 호출되지 않아야 함")
        }
    }
    
    // MARK: - 화면 모드 업데이트 테스트
    
    @Suite("화면 모드 업데이트")
    struct UpdateDisplayMode {
        
        @Test("성공 케이스 - 다크 모드로 변경")
        func testUpdateDisplayModeToDark() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let sut = SettingsInteractor(worker: workerSpy)
            sut.presenter = presenterSpy
            sut.currentSettings = WorkerSpy.createDefaultUserSettings()
            
            let request = SettingsScene.UpdateDisplayMode.Request(displayMode: .dark)
            
            // When
            sut.updateDisplayMode(request: request)
            
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            // Then
            #expect(await workerSpy.updateDisplayModeCalled == true, "Worker의 화면 모드 업데이트가 호출되어야 함")
            #expect(await workerSpy.lastDisplayMode == .dark, "다크 모드로 업데이트되어야 함")
            #expect(presenterSpy.presentDisplayModeUpdateCalled == true, "Presenter가 호출되어야 함")
            
            let response = presenterSpy.presentDisplayModeUpdateResponse
            #expect(response?.success == true, "성공 상태여야 함")
            #expect(response?.displayMode == .dark, "다크 모드가 반환되어야 함")
            #expect(response?.error == nil, "에러가 없어야 함")
            
            // DataStore 업데이트 확인
            #expect(sut.currentSettings?.displayMode == .dark, "DataStore의 화면 모드가 업데이트되어야 함")
        }
        
        @Test("실패 케이스 - 화면 모드 업데이트 에러")
        func testUpdateDisplayModeError() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let updateError = SettingsError.invalidSettings
            await workerSpy.setUpdateDisplayModeResult(.failure(updateError))
            
            let sut = SettingsInteractor(worker: workerSpy)
            sut.presenter = presenterSpy
            
            let request = SettingsScene.UpdateDisplayMode.Request(displayMode: .light)
            
            // When
            sut.updateDisplayMode(request: request)
            
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            // Then
            let response = presenterSpy.presentDisplayModeUpdateResponse
            #expect(response?.success == false, "실패 상태여야 함")
            #expect(response?.error != nil, "에러가 전달되어야 함")
        }
    }
    
    // MARK: - 알림 설정 업데이트 테스트
    
    @Suite("알림 설정 업데이트")
    struct UpdateNotification {
        
        @Test("성공 케이스 - 알림 활성화")
        func testUpdateNotificationEnable() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let initialSettings = UserSettings(
                displayMode: .system,
                fontSize: .medium,
                notificationEnabled: false, // 처음에는 비활성화
                securityType: .none,
                networkType: .mainnet,
                currency: .usd,
                language: .korean
            )
            
            let sut = SettingsInteractor(worker: workerSpy)
            sut.presenter = presenterSpy
            sut.currentSettings = initialSettings
            
            let request = SettingsScene.UpdateNotification.Request(enabled: true)
            
            // When
            sut.updateNotification(request: request)
            
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            // Then
            #expect(await workerSpy.updateNotificationSettingCalled == true, "Worker의 알림 설정 업데이트가 호출되어야 함")
            #expect(await workerSpy.lastNotificationEnabled == true, "알림이 활성화되어야 함")
            #expect(presenterSpy.presentNotificationUpdateCalled == true, "Presenter가 호출되어야 함")
            
            let response = presenterSpy.presentNotificationUpdateResponse
            #expect(response?.success == true, "성공 상태여야 함")
            #expect(response?.enabled == true, "알림이 활성화되어야 함")
            
            // DataStore 업데이트 확인
            #expect(sut.currentSettings?.notificationEnabled == true, "DataStore의 알림 설정이 업데이트되어야 함")
        }
        
        @Test("성공 케이스 - 알림 비활성화")
        func testUpdateNotificationDisable() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let sut = SettingsInteractor(worker: workerSpy)
            sut.presenter = presenterSpy
            sut.currentSettings = WorkerSpy.createDefaultUserSettings() // 알림이 활성화된 상태
            
            let request = SettingsScene.UpdateNotification.Request(enabled: false)
            
            // When
            sut.updateNotification(request: request)
            
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            // Then
            #expect(await workerSpy.lastNotificationEnabled == false, "알림이 비활성화되어야 함")
            #expect(sut.currentSettings?.notificationEnabled == false, "DataStore의 알림이 비활성화되어야 함")
        }
    }
    
    // MARK: - 보안 설정 업데이트 테스트
    
    @Suite("보안 설정 업데이트")
    struct UpdateSecurity {
        
        @Test("성공 케이스 - Face ID 설정")
        func testUpdateSecurityToFaceID() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let sut = SettingsInteractor(worker: workerSpy)
            sut.presenter = presenterSpy
            sut.currentSettings = WorkerSpy.createDefaultUserSettings()
            
            let request = SettingsScene.UpdateSecurity.Request(securityType: .faceID)
            
            // When
            sut.updateSecurity(request: request)
            
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            // Then
            #expect(await workerSpy.updateSecuritySettingCalled == true, "Worker의 보안 설정 업데이트가 호출되어야 함")
            #expect(await workerSpy.lastSecurityType == .faceID, "Face ID로 설정되어야 함")
            #expect(presenterSpy.presentSecurityUpdateCalled == true, "Presenter가 호출되어야 함")
            
            let response = presenterSpy.presentSecurityUpdateResponse
            #expect(response?.success == true, "성공 상태여야 함")
            #expect(response?.securityType == .faceID, "Face ID가 반환되어야 함")
            
            // DataStore 업데이트 확인
            #expect(sut.currentSettings?.securityType == .faceID, "DataStore의 보안 타입이 업데이트되어야 함")
        }
        
        @Test("실패 케이스 - Face ID 사용 불가")
        func testUpdateSecurityFaceIDUnavailable() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let faceIDError = SettingsError.faceIDNotAvailable
            await workerSpy.setUpdateSecuritySettingResult(.failure(faceIDError))
            
            let sut = SettingsInteractor(worker: workerSpy)
            sut.presenter = presenterSpy
            
            let request = SettingsScene.UpdateSecurity.Request(securityType: .faceID)
            
            // When
            sut.updateSecurity(request: request)
            
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            // Then
            let response = presenterSpy.presentSecurityUpdateResponse
            #expect(response?.success == false, "실패 상태여야 함")
            #expect(response?.error != nil, "에러가 전달되어야 함")
        }
    }
    
    // MARK: - 네트워크 설정 업데이트 테스트
    
    @Suite("네트워크 설정 업데이트")
    struct UpdateNetwork {
        
        @Test("성공 케이스 - 테스트넷으로 변경")
        func testUpdateNetworkToTestnet() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let sut = SettingsInteractor(worker: workerSpy)
            sut.presenter = presenterSpy
            sut.currentSettings = WorkerSpy.createDefaultUserSettings() // 메인넷으로 시작
            
            let request = SettingsScene.UpdateNetwork.Request(networkType: .sepolia)
            
            // When
            sut.updateNetwork(request: request)
            
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            // Then
            #expect(await workerSpy.updateNetworkSettingCalled == true, "Worker의 네트워크 설정 업데이트가 호출되어야 함")
            #expect(await workerSpy.lastNetworkType == .sepolia, "Sepolia로 설정되어야 함")
            #expect(presenterSpy.presentNetworkUpdateCalled == true, "Presenter가 호출되어야 함")
            
            let response = presenterSpy.presentNetworkUpdateResponse
            #expect(response?.success == true, "성공 상태여야 함")
            #expect(response?.networkType == .sepolia, "Sepolia가 반환되어야 함")
            
            // DataStore 업데이트 확인
            #expect(sut.currentSettings?.networkType == .sepolia, "DataStore의 네트워크가 업데이트되어야 함")
        }
        
        @Test("네트워크 변경 시 모든 네트워크 타입 테스트")
        func testUpdateNetworkAllTypes() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let sut = SettingsInteractor(worker: workerSpy)
            sut.presenter = presenterSpy
            sut.currentSettings = WorkerSpy.createDefaultUserSettings()
            
            let networkTypes: [NetworkType] = [.mainnet, .sepolia, .goerli, .localhost]
            
            for networkType in networkTypes {
                // When
                let request = SettingsScene.UpdateNetwork.Request(networkType: networkType)
                sut.updateNetwork(request: request)
                
                try? await Task.sleep(nanoseconds: 50_000_000)
                
                // Then
                #expect(await workerSpy.lastNetworkType == networkType, "\(networkType)으로 설정되어야 함")
                #expect(sut.currentSettings?.networkType == networkType, "DataStore가 \(networkType)으로 업데이트되어야 함")
            }
        }
    }
    
    // MARK: - 프로필 로드 테스트
    
    @Suite("프로필 로드")
    struct LoadProfile {
        
        @Test("성공 케이스 - 프로필 로드")
        func testLoadProfileSuccess() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let mockProfile = WalletProfile(
                name: "My Ethereum Wallet",
                address: "0x742d35Cc6634C0Dcc6b9C2b48b9bC4C8b9d9aE3",
                balance: Decimal(5.25),
                avatarURL: URL(string: "https://example.com/avatar.png")
            )
            
            await workerSpy.setLoadWalletProfileResult(.success(mockProfile))
            
            let sut = SettingsInteractor(worker: workerSpy)
            sut.presenter = presenterSpy
            
            let request = SettingsScene.LoadProfile.Request(
                walletAddress: "0x742d35Cc6634C0Dcc6b9C2b48b9bC4C8b9d9aE3"
            )
            
            // When
            sut.loadProfile(request: request)
            
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            // Then
            #expect(await workerSpy.loadWalletProfileCalled == true, "Worker의 프로필 로드가 호출되어야 함")
            #expect(presenterSpy.presentProfileCalled == true, "Presenter가 호출되어야 함")
            
            let response = presenterSpy.presentProfileResponse
            #expect(response != nil, "Response가 전달되어야 함")
            #expect(response?.profile.name == "My Ethereum Wallet", "지갑 이름이 일치해야 함")
            #expect(response?.profile.address == "0x742d35Cc6634C0Dcc6b9C2b48b9bC4C8b9d9aE3", "주소가 일치해야 함")
            #expect(response?.profile.balance == Decimal(5.25), "잔고가 일치해야 함")
            #expect(response?.error == nil, "에러가 없어야 함")
            
            // DataStore 업데이트 확인
            #expect(sut.currentProfile?.name == "My Ethereum Wallet", "DataStore에 프로필이 저장되어야 함")
            #expect(sut.currentProfile?.balance == Decimal(5.25), "DataStore에 잔고가 저장되어야 함")
        }
        
        @Test("실패 케이스 - 프로필 로드 에러")
        func testLoadProfileError() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let profileError = SettingsError.walletAddressNotFound
            await workerSpy.setLoadWalletProfileResult(.failure(profileError))
            
            let sut = SettingsInteractor(worker: workerSpy)
            sut.presenter = presenterSpy
            
            let request = SettingsScene.LoadProfile.Request(walletAddress: "invalid-address")
            
            // When
            sut.loadProfile(request: request)
            
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            // Then
            let response = presenterSpy.presentProfileResponse
            #expect(response?.error != nil, "에러가 전달되어야 함")
            #expect(response?.profile.name == "", "기본 프로필이 반환되어야 함")
        }
    }
    
    // MARK: - 복합 시나리오 테스트
    
    @Suite("복합 시나리오")
    struct ComplexScenarios {
        
        @Test("설정 로드 후 연속 업데이트")
        func testLoadSettingsThenMultipleUpdates() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let sut = SettingsInteractor(worker: workerSpy)
            sut.presenter = presenterSpy
            
            // 1. 초기 설정 로드
            let loadRequest = SettingsScene.LoadSettings.Request(userId: "test-user")
            sut.loadSettings(request: loadRequest)
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            #expect(sut.currentSettings != nil, "초기 설정이 로드되어야 함")
            
            // 2. 화면 모드 변경
            let displayModeRequest = SettingsScene.UpdateDisplayMode.Request(displayMode: .dark)
            sut.updateDisplayMode(request: displayModeRequest)
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            #expect(sut.currentSettings?.displayMode == .dark, "화면 모드가 업데이트되어야 함")
            
            // 3. 보안 설정 변경
            let securityRequest = SettingsScene.UpdateSecurity.Request(securityType: .pin)
            sut.updateSecurity(request: securityRequest)
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            #expect(sut.currentSettings?.securityType == .pin, "보안 설정이 업데이트되어야 함")
            
            // 4. 네트워크 변경
            let networkRequest = SettingsScene.UpdateNetwork.Request(networkType: .sepolia)
            sut.updateNetwork(request: networkRequest)
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            #expect(sut.currentSettings?.networkType == .sepolia, "네트워크가 업데이트되어야 함")
            
            // 최종 상태 확인
            let finalSettings = sut.currentSettings
            #expect(finalSettings?.displayMode == .dark, "최종 화면 모드가 다크여야 함")
            #expect(finalSettings?.securityType == .pin, "최종 보안이 PIN이어야 함")
            #expect(finalSettings?.networkType == .sepolia, "최종 네트워크가 Sepolia여야 함")
        }
    }
    
    // MARK: - Helper Methods
    
    private static func createUserSettings(
        displayMode: DisplayModeType = .system,
        fontSize: FontSizeType = .medium,
        notificationEnabled: Bool = true,
        securityType: SecurityType = .none,
        networkType: NetworkType = .mainnet,
        currency: CurrencyType = .usd,
        language: LanguageType = .korean
    ) -> UserSettings {
        return UserSettings(
            displayMode: displayMode,
            fontSize: fontSize,
            notificationEnabled: notificationEnabled,
            securityType: securityType,
            networkType: networkType,
            currency: currency,
            language: language
        )
    }
}

// MARK: - WorkerSpy Extensions

extension SettingsInteractorTests.WorkerSpy {
    func setLoadUserSettingsResult(_ result: Result<UserSettings, Error>) {
        loadUserSettingsResult = result
    }
    
    func setUpdateDisplayModeResult(_ result: Result<Void, Error>) {
        updateDisplayModeResult = result
    }
    
    func setUpdateNotificationSettingResult(_ result: Result<Void, Error>) {
        updateNotificationSettingResult = result
    }
    
    func setUpdateSecuritySettingResult(_ result: Result<Void, Error>) {
        updateSecuritySettingResult = result
    }
    
    func setUpdateNetworkSettingResult(_ result: Result<Void, Error>) {
        updateNetworkSettingResult = result
    }
    
    func setLoadWalletProfileResult(_ result: Result<WalletProfile, Error>) {
        loadWalletProfileResult = result
    }
}