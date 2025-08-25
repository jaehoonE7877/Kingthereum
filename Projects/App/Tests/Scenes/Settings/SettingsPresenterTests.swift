import Testing
import Foundation
@testable import App
@testable import Entity
@testable import Core

@MainActor @Suite("SettingsPresenter 테스트")
struct SettingsPresenterTests {
    
    // MARK: - Spy Classes
    
    class DisplayLogicSpy: SettingsDisplayLogic {
        var displaySettingsCalled = false
        var displaySettingsViewModel: SettingsScene.LoadSettings.ViewModel?
        
        func displaySettings(viewModel: SettingsScene.LoadSettings.ViewModel) {
            displaySettingsCalled = true
            displaySettingsViewModel = viewModel
        }
        
        var displaySettingUpdateResultCalled = false
        var displaySettingUpdateResultViewModel: SettingsScene.UpdateSetting.ViewModel?
        
        func displaySettingUpdateResult(viewModel: SettingsScene.UpdateSetting.ViewModel) {
            displaySettingUpdateResultCalled = true
            displaySettingUpdateResultViewModel = viewModel
        }
        
        var displaySecuritySettingsCalled = false
        var displaySecuritySettingsViewModel: SettingsScene.LoadSecuritySettings.ViewModel?
        
        func displaySecuritySettings(viewModel: SettingsScene.LoadSecuritySettings.ViewModel) {
            displaySecuritySettingsCalled = true
            displaySecuritySettingsViewModel = viewModel
        }
        
        var displayAppInfoCalled = false
        var displayAppInfoViewModel: SettingsScene.LoadAppInfo.ViewModel?
        
        func displayAppInfo(viewModel: SettingsScene.LoadAppInfo.ViewModel) {
            displayAppInfoCalled = true
            displayAppInfoViewModel = viewModel
        }
        
        var displayErrorCalled = false
        var displayErrorViewModel: SettingsScene.Error.ViewModel?
        
        func displayError(viewModel: SettingsScene.Error.ViewModel) {
            displayErrorCalled = true
            displayErrorViewModel = viewModel
        }
        
        var displayLoadingCalled = false
        var displayLoadingIsLoading: Bool?
        
        func displayLoading(isLoading: Bool) {
            displayLoadingCalled = true
            displayLoadingIsLoading = isLoading
        }
    }
    
    // MARK: - 설정 로드 테스트
    
    @Suite("설정 표시")
    struct DisplaySettings {
        
        @Test("일반 설정 표시 - 모든 설정이 활성화된 경우")
        func testPresentSettingsAllEnabled() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = SettingsPresenter(viewController: displayLogicSpy)
            
            let response = SettingsScene.LoadSettings.Response(
                settings: AppSettings(
                    biometricAuthEnabled: true,
                    pushNotificationsEnabled: true,
                    darkModeEnabled: true,
                    autoLockEnabled: true,
                    autoLockTimeout: 300,
                    currency: .USD,
                    language: "ko",
                    analyticsEnabled: false
                )
            )
            
            // When
            sut.presentSettings(response: response)
            
            // Then
            #expect(displayLogicSpy.displaySettingsCalled == true, "설정 표시 메서드가 호출되어야 함")
            
            guard let viewModel = displayLogicSpy.displaySettingsViewModel else {
                Issue.record("ViewModel이 생성되어야 함")
                return
            }
            
            #expect(viewModel.biometricAuthTitle == "생체 인증", "생체 인증 제목이 올바르게 표시되어야 함")
            #expect(viewModel.biometricAuthEnabled == true, "생체 인증이 활성화되어야 함")
            #expect(viewModel.biometricAuthDescription == "Face ID 또는 Touch ID로 앱을 잠금 해제합니다", "생체 인증 설명이 표시되어야 함")
            
            #expect(viewModel.pushNotificationsTitle == "푸시 알림", "푸시 알림 제목이 올바르게 표시되어야 함")
            #expect(viewModel.pushNotificationsEnabled == true, "푸시 알림이 활성화되어야 함")
            
            #expect(viewModel.darkModeTitle == "다크 모드", "다크 모드 제목이 올바르게 표시되어야 함")
            #expect(viewModel.darkModeEnabled == true, "다크 모드가 활성화되어야 함")
            
            #expect(viewModel.autoLockTitle == "자동 잠금", "자동 잠금 제목이 올바르게 표시되어야 함")
            #expect(viewModel.autoLockEnabled == true, "자동 잠금이 활성화되어야 함")
            #expect(viewModel.autoLockTimeoutDisplay == "5분", "자동 잠금 시간이 올바르게 표시되어야 함")
            
            #expect(viewModel.currencyTitle == "기본 통화", "통화 제목이 올바르게 표시되어야 함")
            #expect(viewModel.selectedCurrency == "USD", "선택된 통화가 표시되어야 함")
            #expect(viewModel.currencySymbol == "$", "통화 기호가 표시되어야 함")
            
            #expect(viewModel.languageTitle == "언어", "언어 제목이 올바르게 표시되어야 함")
            #expect(viewModel.selectedLanguage == "한국어", "선택된 언어가 표시되어야 함")
            
            #expect(viewModel.analyticsTitle == "분석 데이터", "분석 데이터 제목이 올바르게 표시되어야 함")
            #expect(viewModel.analyticsEnabled == false, "분석 데이터가 비활성화되어야 함")
        }
        
        @Test("일반 설정 표시 - 모든 설정이 비활성화된 경우")
        func testPresentSettingsAllDisabled() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = SettingsPresenter(viewController: displayLogicSpy)
            
            let response = SettingsScene.LoadSettings.Response(
                settings: AppSettings(
                    biometricAuthEnabled: false,
                    pushNotificationsEnabled: false,
                    darkModeEnabled: false,
                    autoLockEnabled: false,
                    autoLockTimeout: 0,
                    currency: .KRW,
                    language: "en",
                    analyticsEnabled: true
                )
            )
            
            // When
            sut.presentSettings(response: response)
            
            // Then
            guard let viewModel = displayLogicSpy.displaySettingsViewModel else {
                Issue.record("ViewModel이 생성되어야 함")
                return
            }
            
            #expect(viewModel.biometricAuthEnabled == false, "생체 인증이 비활성화되어야 함")
            #expect(viewModel.pushNotificationsEnabled == false, "푸시 알림이 비활성화되어야 함")
            #expect(viewModel.darkModeEnabled == false, "다크 모드가 비활성화되어야 함")
            #expect(viewModel.autoLockEnabled == false, "자동 잠금이 비활성화되어야 함")
            #expect(viewModel.autoLockTimeoutDisplay == "비활성화", "자동 잠금이 비활성화로 표시되어야 함")
            #expect(viewModel.selectedCurrency == "KRW", "원화가 선택되어야 함")
            #expect(viewModel.currencySymbol == "₩", "원 기호가 표시되어야 함")
            #expect(viewModel.selectedLanguage == "English", "영어가 선택되어야 함")
            #expect(viewModel.analyticsEnabled == true, "분석 데이터가 활성화되어야 함")
        }
        
        @Test("다양한 자동 잠금 시간 표시")
        func testPresentAutoLockTimeouts() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = SettingsPresenter(viewController: displayLogicSpy)
            
            let testCases = [
                (timeout: 60, expected: "1분"),
                (timeout: 300, expected: "5분"),
                (timeout: 600, expected: "10분"),
                (timeout: 1800, expected: "30분"),
                (timeout: 3600, expected: "1시간"),
                (timeout: 0, expected: "비활성화")
            ]
            
            for testCase in testCases {
                let response = SettingsScene.LoadSettings.Response(
                    settings: AppSettings(
                        biometricAuthEnabled: true,
                        pushNotificationsEnabled: true,
                        darkModeEnabled: true,
                        autoLockEnabled: testCase.timeout > 0,
                        autoLockTimeout: testCase.timeout,
                        currency: .USD,
                        language: "ko",
                        analyticsEnabled: false
                    )
                )
                
                // When
                sut.presentSettings(response: response)
                
                // Then
                guard let viewModel = displayLogicSpy.displaySettingsViewModel else {
                    Issue.record("ViewModel이 생성되어야 함")
                    continue
                }
                
                #expect(
                    viewModel.autoLockTimeoutDisplay == testCase.expected,
                    "자동 잠금 시간이 \(testCase.expected)로 표시되어야 함 (입력: \(testCase.timeout))"
                )
            }
        }
        
        @Test("다양한 통화 표시")
        func testPresentDifferentCurrencies() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = SettingsPresenter(viewController: displayLogicSpy)
            
            let testCases: [(currency: Currency, expectedCode: String, expectedSymbol: String)] = [
                (.USD, "USD", "$"),
                (.KRW, "KRW", "₩"),
                (.EUR, "EUR", "€"),
                (.JPY, "JPY", "¥"),
                (.BTC, "BTC", "₿"),
                (.ETH, "ETH", "Ξ")
            ]
            
            for testCase in testCases {
                let response = SettingsScene.LoadSettings.Response(
                    settings: AppSettings(
                        biometricAuthEnabled: true,
                        pushNotificationsEnabled: true,
                        darkModeEnabled: true,
                        autoLockEnabled: true,
                        autoLockTimeout: 300,
                        currency: testCase.currency,
                        language: "ko",
                        analyticsEnabled: false
                    )
                )
                
                // When
                sut.presentSettings(response: response)
                
                // Then
                guard let viewModel = displayLogicSpy.displaySettingsViewModel else {
                    Issue.record("ViewModel이 생성되어야 함")
                    continue
                }
                
                #expect(
                    viewModel.selectedCurrency == testCase.expectedCode,
                    "\(testCase.currency) 통화 코드가 \(testCase.expectedCode)로 표시되어야 함"
                )
                #expect(
                    viewModel.currencySymbol == testCase.expectedSymbol,
                    "\(testCase.currency) 통화 기호가 \(testCase.expectedSymbol)로 표시되어야 함"
                )
            }
        }
        
        @Test("언어 설정 표시")
        func testPresentLanguageSettings() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = SettingsPresenter(viewController: displayLogicSpy)
            
            let testCases = [
                (languageCode: "ko", expectedDisplay: "한국어"),
                (languageCode: "en", expectedDisplay: "English"),
                (languageCode: "ja", expectedDisplay: "日本語"),
                (languageCode: "zh", expectedDisplay: "中文"),
                (languageCode: "unknown", expectedDisplay: "Unknown")
            ]
            
            for testCase in testCases {
                let response = SettingsScene.LoadSettings.Response(
                    settings: AppSettings(
                        biometricAuthEnabled: true,
                        pushNotificationsEnabled: true,
                        darkModeEnabled: true,
                        autoLockEnabled: true,
                        autoLockTimeout: 300,
                        currency: .USD,
                        language: testCase.languageCode,
                        analyticsEnabled: false
                    )
                )
                
                // When
                sut.presentSettings(response: response)
                
                // Then
                guard let viewModel = displayLogicSpy.displaySettingsViewModel else {
                    Issue.record("ViewModel이 생성되어야 함")
                    continue
                }
                
                #expect(
                    viewModel.selectedLanguage == testCase.expectedDisplay,
                    "\(testCase.languageCode) 언어가 \(testCase.expectedDisplay)로 표시되어야 함"
                )
            }
        }
    }
    
    // MARK: - 설정 업데이트 결과 테스트
    
    @Suite("설정 업데이트 결과")
    struct DisplayUpdateResult {
        
        @Test("설정 업데이트 성공")
        func testPresentSettingUpdateSuccess() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = SettingsPresenter(viewController: displayLogicSpy)
            
            let response = SettingsScene.UpdateSetting.Response(
                success: true,
                settingKey: "biometricAuth",
                newValue: true,
                error: nil
            )
            
            // When
            sut.presentSettingUpdateResult(response: response)
            
            // Then
            #expect(displayLogicSpy.displaySettingUpdateResultCalled == true, "업데이트 결과 표시가 호출되어야 함")
            
            guard let viewModel = displayLogicSpy.displaySettingUpdateResultViewModel else {
                Issue.record("업데이트 결과 ViewModel이 생성되어야 함")
                return
            }
            
            #expect(viewModel.success == true, "성공 상태가 표시되어야 함")
            #expect(viewModel.message == "설정이 성공적으로 업데이트되었습니다", "성공 메시지가 표시되어야 함")
            #expect(viewModel.showAlert == false, "성공 시 알림을 표시하지 않아야 함")
            #expect(viewModel.settingKey == "biometricAuth", "설정 키가 전달되어야 함")
        }
        
        @Test("설정 업데이트 실패 - 권한 오류")
        func testPresentSettingUpdatePermissionError() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = SettingsPresenter(viewController: displayLogicSpy)
            
            let response = SettingsScene.UpdateSetting.Response(
                success: false,
                settingKey: "pushNotifications",
                newValue: true,
                error: SettingsError.permissionDenied
            )
            
            // When
            sut.presentSettingUpdateResult(response: response)
            
            // Then
            guard let viewModel = displayLogicSpy.displaySettingUpdateResultViewModel else {
                Issue.record("업데이트 결과 ViewModel이 생성되어야 함")
                return
            }
            
            #expect(viewModel.success == false, "실패 상태가 표시되어야 함")
            #expect(viewModel.message == "설정을 변경할 권한이 없습니다. 시스템 설정에서 권한을 확인해주세요.", "권한 오류 메시지가 표시되어야 함")
            #expect(viewModel.showAlert == true, "실패 시 알림을 표시해야 함")
            #expect(viewModel.alertTitle == "설정 변경 실패", "알림 제목이 설정되어야 함")
        }
        
        @Test("설정 업데이트 실패 - 네트워크 오류")
        func testPresentSettingUpdateNetworkError() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = SettingsPresenter(viewController: displayLogicSpy)
            
            let response = SettingsScene.UpdateSetting.Response(
                success: false,
                settingKey: "analyticsEnabled",
                newValue: false,
                error: SettingsError.networkError
            )
            
            // When
            sut.presentSettingUpdateResult(response: response)
            
            // Then
            guard let viewModel = displayLogicSpy.displaySettingUpdateResultViewModel else {
                Issue.record("업데이트 결과 ViewModel이 생성되어야 함")
                return
            }
            
            #expect(viewModel.success == false, "실패 상태가 표시되어야 함")
            #expect(viewModel.message == "네트워크 연결을 확인하고 다시 시도해주세요.", "네트워크 오류 메시지가 표시되어야 함")
            #expect(viewModel.showAlert == true, "실패 시 알림을 표시해야 함")
            #expect(viewModel.alertTitle == "설정 변경 실패", "알림 제목이 설정되어야 함")
        }
        
        @Test("다양한 설정 타입별 업데이트 성공 메시지")
        func testPresentDifferentSettingUpdateSuccess() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = SettingsPresenter(viewController: displayLogicSpy)
            
            let testCases = [
                (settingKey: "biometricAuth", expectedMessage: "생체 인증 설정이 변경되었습니다"),
                (settingKey: "pushNotifications", expectedMessage: "푸시 알림 설정이 변경되었습니다"),
                (settingKey: "darkMode", expectedMessage: "다크 모드 설정이 변경되었습니다"),
                (settingKey: "autoLock", expectedMessage: "자동 잠금 설정이 변경되었습니다"),
                (settingKey: "currency", expectedMessage: "통화 설정이 변경되었습니다"),
                (settingKey: "language", expectedMessage: "언어 설정이 변경되었습니다"),
                (settingKey: "analytics", expectedMessage: "분석 데이터 설정이 변경되었습니다"),
                (settingKey: "unknown", expectedMessage: "설정이 성공적으로 업데이트되었습니다")
            ]
            
            for testCase in testCases {
                let response = SettingsScene.UpdateSetting.Response(
                    success: true,
                    settingKey: testCase.settingKey,
                    newValue: true,
                    error: nil
                )
                
                // When
                sut.presentSettingUpdateResult(response: response)
                
                // Then
                guard let viewModel = displayLogicSpy.displaySettingUpdateResultViewModel else {
                    Issue.record("업데이트 결과 ViewModel이 생성되어야 함")
                    continue
                }
                
                #expect(
                    viewModel.message == testCase.expectedMessage,
                    "\(testCase.settingKey) 설정의 성공 메시지가 \(testCase.expectedMessage)로 표시되어야 함"
                )
            }
        }
    }
    
    // MARK: - 보안 설정 테스트
    
    @Suite("보안 설정")
    struct DisplaySecuritySettings {
        
        @Test("보안 설정 표시 - 모든 보안 기능 활성화")
        func testPresentSecuritySettingsAllEnabled() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = SettingsPresenter(viewController: displayLogicSpy)
            
            let response = SettingsScene.LoadSecuritySettings.Response(
                biometricAuthAvailable: true,
                biometricAuthType: .faceID,
                biometricAuthEnabled: true,
                pinEnabled: true,
                autoLockEnabled: true,
                autoLockTimeout: 300,
                screenCaptureBlocked: true,
                copyProtectionEnabled: true
            )
            
            // When
            sut.presentSecuritySettings(response: response)
            
            // Then
            #expect(displayLogicSpy.displaySecuritySettingsCalled == true, "보안 설정 표시가 호출되어야 함")
            
            guard let viewModel = displayLogicSpy.displaySecuritySettingsViewModel else {
                Issue.record("보안 설정 ViewModel이 생성되어야 함")
                return
            }
            
            #expect(viewModel.biometricAuthTitle == "Face ID", "Face ID 제목이 표시되어야 함")
            #expect(viewModel.biometricAuthAvailable == true, "생체 인증이 사용 가능해야 함")
            #expect(viewModel.biometricAuthEnabled == true, "생체 인증이 활성화되어야 함")
            #expect(viewModel.biometricAuthDescription == "Face ID를 사용하여 앱을 잠금 해제합니다", "Face ID 설명이 표시되어야 함")
            #expect(viewModel.biometricAuthIcon == "faceid", "Face ID 아이콘이 설정되어야 함")
            
            #expect(viewModel.pinTitle == "PIN 코드", "PIN 제목이 표시되어야 함")
            #expect(viewModel.pinEnabled == true, "PIN이 활성화되어야 함")
            #expect(viewModel.pinDescription == "6자리 PIN 코드로 앱을 보호합니다", "PIN 설명이 표시되어야 함")
            
            #expect(viewModel.autoLockTitle == "자동 잠금", "자동 잠금 제목이 표시되어야 함")
            #expect(viewModel.autoLockEnabled == true, "자동 잠금이 활성화되어야 함")
            #expect(viewModel.autoLockTimeoutDisplay == "5분", "자동 잠금 시간이 표시되어야 함")
            
            #expect(viewModel.screenCaptureTitle == "화면 캡처 차단", "화면 캡처 차단 제목이 표시되어야 함")
            #expect(viewModel.screenCaptureBlocked == true, "화면 캡처가 차단되어야 함")
            
            #expect(viewModel.copyProtectionTitle == "복사 보호", "복사 보호 제목이 표시되어야 함")
            #expect(viewModel.copyProtectionEnabled == true, "복사 보호가 활성화되어야 함")
        }
        
        @Test("보안 설정 표시 - Touch ID 사용")
        func testPresentSecuritySettingsTouchID() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = SettingsPresenter(viewController: displayLogicSpy)
            
            let response = SettingsScene.LoadSecuritySettings.Response(
                biometricAuthAvailable: true,
                biometricAuthType: .touchID,
                biometricAuthEnabled: true,
                pinEnabled: false,
                autoLockEnabled: false,
                autoLockTimeout: 0,
                screenCaptureBlocked: false,
                copyProtectionEnabled: false
            )
            
            // When
            sut.presentSecuritySettings(response: response)
            
            // Then
            guard let viewModel = displayLogicSpy.displaySecuritySettingsViewModel else {
                Issue.record("보안 설정 ViewModel이 생성되어야 함")
                return
            }
            
            #expect(viewModel.biometricAuthTitle == "Touch ID", "Touch ID 제목이 표시되어야 함")
            #expect(viewModel.biometricAuthDescription == "Touch ID를 사용하여 앱을 잠금 해제합니다", "Touch ID 설명이 표시되어야 함")
            #expect(viewModel.biometricAuthIcon == "touchid", "Touch ID 아이콘이 설정되어야 함")
        }
        
        @Test("보안 설정 표시 - 생체 인증 사용 불가")
        func testPresentSecuritySettingsBiometricUnavailable() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = SettingsPresenter(viewController: displayLogicSpy)
            
            let response = SettingsScene.LoadSecuritySettings.Response(
                biometricAuthAvailable: false,
                biometricAuthType: .none,
                biometricAuthEnabled: false,
                pinEnabled: true,
                autoLockEnabled: true,
                autoLockTimeout: 300,
                screenCaptureBlocked: true,
                copyProtectionEnabled: true
            )
            
            // When
            sut.presentSecuritySettings(response: response)
            
            // Then
            guard let viewModel = displayLogicSpy.displaySecuritySettingsViewModel else {
                Issue.record("보안 설정 ViewModel이 생성되어야 함")
                return
            }
            
            #expect(viewModel.biometricAuthTitle == "생체 인증", "기본 생체 인증 제목이 표시되어야 함")
            #expect(viewModel.biometricAuthAvailable == false, "생체 인증이 사용 불가해야 함")
            #expect(viewModel.biometricAuthEnabled == false, "생체 인증이 비활성화되어야 함")
            #expect(viewModel.biometricAuthDescription == "이 기기에서는 생체 인증을 사용할 수 없습니다", "사용 불가 설명이 표시되어야 함")
            #expect(viewModel.biometricAuthIcon == "exclamationmark.shield", "경고 아이콘이 설정되어야 함")
        }
    }
    
    // MARK: - 앱 정보 테스트
    
    @Suite("앱 정보")
    struct DisplayAppInfo {
        
        @Test("앱 정보 표시")
        func testPresentAppInfo() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = SettingsPresenter(viewController: displayLogicSpy)
            
            let response = SettingsScene.LoadAppInfo.Response(
                appName: "Kingtherum",
                appVersion: "1.2.3",
                buildNumber: "123",
                developer: "Kingtherum Team",
                supportEmail: "support@kingtherum.io",
                privacyPolicyURL: "https://kingtherum.io/privacy",
                termsOfServiceURL: "https://kingtherum.io/terms",
                openSourceLicenses: [
                    OpenSourceLicense(name: "Web3Swift", version: "3.2.0", license: "Apache 2.0"),
                    OpenSourceLicense(name: "KeychainAccess", version: "4.2.2", license: "MIT")
                ]
            )
            
            // When
            sut.presentAppInfo(response: response)
            
            // Then
            #expect(displayLogicSpy.displayAppInfoCalled == true, "앱 정보 표시가 호출되어야 함")
            
            guard let viewModel = displayLogicSpy.displayAppInfoViewModel else {
                Issue.record("앱 정보 ViewModel이 생성되어야 함")
                return
            }
            
            #expect(viewModel.appTitle == "Kingtherum", "앱 이름이 표시되어야 함")
            #expect(viewModel.versionText == "버전 1.2.3 (123)", "버전 정보가 표시되어야 함")
            #expect(viewModel.developerText == "개발자: Kingtherum Team", "개발자 정보가 표시되어야 함")
            #expect(viewModel.supportEmailText == "지원: support@kingtherum.io", "지원 이메일이 표시되어야 함")
            #expect(viewModel.privacyPolicyURL == "https://kingtherum.io/privacy", "개인정보처리방침 URL이 설정되어야 함")
            #expect(viewModel.termsOfServiceURL == "https://kingtherum.io/terms", "서비스 약관 URL이 설정되어야 함")
            #expect(viewModel.openSourceLicenses.count == 2, "오픈소스 라이선스 2개가 표시되어야 함")
            
            // 오픈소스 라이선스 검증
            let firstLicense = viewModel.openSourceLicenses[0]
            #expect(firstLicense.displayName == "Web3Swift", "첫 번째 라이브러리 이름이 표시되어야 함")
            #expect(firstLicense.displayVersion == "3.2.0", "첫 번째 라이브러리 버전이 표시되어야 함")
            #expect(firstLicense.displayLicense == "Apache 2.0", "첫 번째 라이브러리 라이선스가 표시되어야 함")
            #expect(firstLicense.displayText == "Web3Swift 3.2.0 (Apache 2.0)", "첫 번째 라이브러리 전체 텍스트가 표시되어야 함")
            
            let secondLicense = viewModel.openSourceLicenses[1]
            #expect(secondLicense.displayName == "KeychainAccess", "두 번째 라이브러리 이름이 표시되어야 함")
            #expect(secondLicense.displayVersion == "4.2.2", "두 번째 라이브러리 버전이 표시되어야 함")
            #expect(secondLicense.displayLicense == "MIT", "두 번째 라이브러리 라이선스가 표시되어야 함")
            #expect(secondLicense.displayText == "KeychainAccess 4.2.2 (MIT)", "두 번째 라이브러리 전체 텍스트가 표시되어야 함")
        }
        
        @Test("최소한의 앱 정보 표시")
        func testPresentMinimalAppInfo() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = SettingsPresenter(viewController: displayLogicSpy)
            
            let response = SettingsScene.LoadAppInfo.Response(
                appName: "TestApp",
                appVersion: "1.0.0",
                buildNumber: "1",
                developer: "",
                supportEmail: "",
                privacyPolicyURL: "",
                termsOfServiceURL: "",
                openSourceLicenses: []
            )
            
            // When
            sut.presentAppInfo(response: response)
            
            // Then
            guard let viewModel = displayLogicSpy.displayAppInfoViewModel else {
                Issue.record("앱 정보 ViewModel이 생성되어야 함")
                return
            }
            
            #expect(viewModel.appTitle == "TestApp", "앱 이름이 표시되어야 함")
            #expect(viewModel.versionText == "버전 1.0.0 (1)", "버전 정보가 표시되어야 함")
            #expect(viewModel.developerText == "", "개발자 정보가 비어있어야 함")
            #expect(viewModel.supportEmailText == "", "지원 이메일이 비어있어야 함")
            #expect(viewModel.openSourceLicenses.isEmpty == true, "오픈소스 라이선스가 비어있어야 함")
        }
    }
    
    // MARK: - 에러 처리 테스트
    
    @Suite("에러 처리")
    struct ErrorHandling {
        
        @Test("일반 오류 표시")
        func testPresentGeneralError() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = SettingsPresenter(viewController: displayLogicSpy)
            
            let response = SettingsScene.Error.Response(
                error: SettingsError.generalError("알 수 없는 오류가 발생했습니다")
            )
            
            // When
            sut.presentError(response: response)
            
            // Then
            #expect(displayLogicSpy.displayErrorCalled == true, "에러 표시가 호출되어야 함")
            
            guard let viewModel = displayLogicSpy.displayErrorViewModel else {
                Issue.record("에러 ViewModel이 생성되어야 함")
                return
            }
            
            #expect(viewModel.title == "오류", "에러 제목이 설정되어야 함")
            #expect(viewModel.message == "알 수 없는 오류가 발생했습니다", "에러 메시지가 표시되어야 함")
            #expect(viewModel.primaryButtonTitle == "확인", "확인 버튼 제목이 설정되어야 함")
            #expect(viewModel.secondaryButtonTitle == nil, "보조 버튼이 없어야 함")
            #expect(viewModel.errorType == .general, "일반 에러 타입이 설정되어야 함")
        }
        
        @Test("권한 거부 오류 표시")
        func testPresentPermissionDeniedError() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = SettingsPresenter(viewController: displayLogicSpy)
            
            let response = SettingsScene.Error.Response(
                error: SettingsError.permissionDenied
            )
            
            // When
            sut.presentError(response: response)
            
            // Then
            guard let viewModel = displayLogicSpy.displayErrorViewModel else {
                Issue.record("에러 ViewModel이 생성되어야 함")
                return
            }
            
            #expect(viewModel.title == "권한 필요", "권한 제목이 설정되어야 함")
            #expect(viewModel.message == "설정을 변경할 권한이 없습니다. 시스템 설정에서 권한을 확인해주세요.", "권한 에러 메시지가 표시되어야 함")
            #expect(viewModel.primaryButtonTitle == "설정으로 이동", "설정 이동 버튼이 표시되어야 함")
            #expect(viewModel.secondaryButtonTitle == "취소", "취소 버튼이 표시되어야 함")
            #expect(viewModel.errorType == .permission, "권한 에러 타입이 설정되어야 함")
        }
        
        @Test("네트워크 오류 표시")
        func testPresentNetworkError() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = SettingsPresenter(viewController: displayLogicSpy)
            
            let response = SettingsScene.Error.Response(
                error: SettingsError.networkError
            )
            
            // When
            sut.presentError(response: response)
            
            // Then
            guard let viewModel = displayLogicSpy.displayErrorViewModel else {
                Issue.record("에러 ViewModel이 생성되어야 함")
                return
            }
            
            #expect(viewModel.title == "네트워크 오류", "네트워크 오류 제목이 설정되어야 함")
            #expect(viewModel.message == "네트워크 연결을 확인하고 다시 시도해주세요.", "네트워크 에러 메시지가 표시되어야 함")
            #expect(viewModel.primaryButtonTitle == "다시 시도", "다시 시도 버튼이 표시되어야 함")
            #expect(viewModel.secondaryButtonTitle == "취소", "취소 버튼이 표시되어야 함")
            #expect(viewModel.errorType == .network, "네트워크 에러 타입이 설정되어야 함")
        }
        
        @Test("생체 인증 사용 불가 오류 표시")
        func testPresentBiometricUnavailableError() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = SettingsPresenter(viewController: displayLogicSpy)
            
            let response = SettingsScene.Error.Response(
                error: SettingsError.biometricUnavailable
            )
            
            // When
            sut.presentError(response: response)
            
            // Then
            guard let viewModel = displayLogicSpy.displayErrorViewModel else {
                Issue.record("에러 ViewModel이 생성되어야 함")
                return
            }
            
            #expect(viewModel.title == "생체 인증 사용 불가", "생체 인증 사용 불가 제목이 설정되어야 함")
            #expect(viewModel.message == "이 기기에서는 생체 인증을 사용할 수 없습니다. 시스템 설정에서 Face ID 또는 Touch ID를 활성화해주세요.", "생체 인증 사용 불가 메시지가 표시되어야 함")
            #expect(viewModel.primaryButtonTitle == "확인", "확인 버튼이 표시되어야 함")
            #expect(viewModel.secondaryButtonTitle == nil, "보조 버튼이 없어야 함")
            #expect(viewModel.errorType == .biometric, "생체 인증 에러 타입이 설정되어야 함")
        }
    }
    
    // MARK: - 로딩 상태 테스트
    
    @Suite("로딩 상태")
    struct LoadingState {
        
        @Test("로딩 시작")
        func testPresentLoadingStart() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = SettingsPresenter(viewController: displayLogicSpy)
            
            // When
            sut.presentLoading(isLoading: true)
            
            // Then
            #expect(displayLogicSpy.displayLoadingCalled == true, "로딩 표시가 호출되어야 함")
            #expect(displayLogicSpy.displayLoadingIsLoading == true, "로딩 상태가 true여야 함")
        }
        
        @Test("로딩 종료")
        func testPresentLoadingEnd() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = SettingsPresenter(viewController: displayLogicSpy)
            
            // When
            sut.presentLoading(isLoading: false)
            
            // Then
            #expect(displayLogicSpy.displayLoadingCalled == true, "로딩 표시가 호출되어야 함")
            #expect(displayLogicSpy.displayLoadingIsLoading == false, "로딩 상태가 false여야 함")
        }
    }
}