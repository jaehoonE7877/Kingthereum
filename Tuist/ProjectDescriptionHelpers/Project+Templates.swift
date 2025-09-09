import Foundation
import ProjectDescription

public extension Project {
    
    static func makeModule(
        name: String,
        hasResources: Bool = false,
        dependencies: [TargetDependency] = [],
        hasTests: Bool = true
    ) -> Project {
        
        let deploymentTarget = Environment.deploymentTarget
        let destination = Environment.destination
        let organizationName = Environment.bundlePrefix
        
        // 기본 공통 설정
        let baseSettings: SettingsDictionary = .baseSettings
            .merging(["SWIFT_VERSION": .string("6")])
            .automaticCodeSigning(devTeam: "RFHV927M8S")
        
        // 디버그 모드 설정
        let debugSettings: SettingsDictionary = baseSettings
            .merging(["SWIFT_OPTIMIZATION_LEVEL": "-Onone"])
            .merging(["SWIFT_COMPILATION_MODE": "singlefile"])
            
        // 릴리스 모드 설정
        let releaseSettings: SettingsDictionary = baseSettings
            .merging(["SWIFT_OPTIMIZATION_LEVEL": "-O"])
            .merging(["SWIFT_COMPILATION_MODE": "wholemodule"])
            .merging(["GCC_OPTIMIZATION_LEVEL": "s"])
        
        // Configuration 설정
        let debugConfiguration = Configuration.debug(
            name: "Debug",
            settings: debugSettings,
            xcconfig: .relativeToRoot("Config/Development-Local.xcconfig")
        )
        let releaseConfiguration = Configuration.release(
            name: "Release",
            settings: releaseSettings,
            xcconfig: .relativeToRoot("Config/Production-Local.xcconfig")
        )
        
        let configurations: [Configuration] = [
            debugConfiguration,
            releaseConfiguration
        ]
        
        var projectTargets: [Target] = []
        
        // MARK: - Framework Target
        var buildableFolders: [BuildableFolder] = [.folder("Sources"), .folder("Derived")]
        if hasResources {
            buildableFolders.append(.folder("Resources"))
        }
        
        let frameworkTarget = Target.target(
            name: name,
            destinations: destination,
            product: .framework,
            bundleId: "\(organizationName).\(name)",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: buildableFolders,
            dependencies: dependencies,
            settings: .settings(
                base: baseSettings
                    .merging(["ENABLE_PREVIEWS": "YES"])
                    .merging(["SWIFT_EMIT_LOC_STRINGS": "YES"])
                    .merging(["ENABLE_TESTING_SEARCH_PATHS": "YES"]),
                configurations: configurations
            )
        )
        projectTargets.append(frameworkTarget)
        
        // MARK: - Test Target
        if hasTests {
            // Swift Testing을 위한 테스트 설정
            let testSettings: SettingsDictionary = debugSettings
                .merging(["ENABLE_TESTING_SEARCH_PATHS": "YES"])
                .merging(["SWIFT_TESTING": "YES"])
                .merging(["ENABLE_SWIFT_TESTING": "YES"])
            
            let testTarget = Target.target(
                name: "\(name)Tests",
                destinations: destination,
                product: .unitTests,
                bundleId: "\(organizationName).\(name)Tests",
                deploymentTargets: deploymentTarget,
                infoPlist: .default,
                buildableFolders: [.folder("Tests")],
                dependencies: [.target(name: name)],
                settings: .settings(base: testSettings, configurations: [debugConfiguration])
            )
            projectTargets.append(testTarget)
        }
        
        var schemes: [Scheme] = [
            Scheme.scheme(
                name: name,
                shared: true,
                buildAction: .buildAction(targets: ["\(name)"]),
                testAction: hasTests ? .targets(["\(name)Tests"]) : nil
            )
        ]
        
        // 테스트 전용 스키마 추가
        if hasTests {
            schemes.append(
                Scheme.scheme(
                    name: "\(name)Tests",
                    shared: true,
                    buildAction: .buildAction(targets: ["\(name)", "\(name)Tests"]),
                    testAction: .targets(["\(name)Tests"])
                )
            )
        }

        return Project(
            name: name,
            organizationName: organizationName,
            options: .options(defaultKnownRegions: ["ko"], developmentRegion: "ko"),
            settings: .settings(base: baseSettings, configurations: configurations),
            targets: projectTargets,
            schemes: schemes
        )
    }
    
    // MARK: - App Project
    static func app(
        name: String,
        dependencies: [TargetDependency] = [],
        hasTests: Bool = false
    ) -> Project {
        
        let deploymentTarget = Environment.deploymentTarget
        let destination = Environment.destination
        let organizationName = Environment.bundlePrefix
        
        let baseSettings: SettingsDictionary = .baseSettings
            .merging(["SWIFT_VERSION": .string("6")])
            .merging(["OTHER_LDFLAGS": ["-ObjC"]])
            .automaticCodeSigning(devTeam: "RFHV927M8S")
        
        let versionSetting: [String: SettingValue] = [
            "MARKETING_VERSION": SettingValue(stringLiteral: Environment.appVersion),
            "CURRENT_PROJECT_VERSION": "1"
        ]
        
        let debugSettings = baseSettings
            .merging(versionSetting)
            .merging(["SWIFT_OPTIMIZATION_LEVEL": "-Onone"])
            .merging(["SWIFT_COMPILATION_MODE": "singlefile"])
            
        let releaseSettings = baseSettings
            .merging(versionSetting)
            .merging(["SWIFT_OPTIMIZATION_LEVEL": "-O"])
            .merging(["SWIFT_COMPILATION_MODE": "wholemodule"])
            .merging(["GCC_OPTIMIZATION_LEVEL": "s"])
        
        let debugConfiguration = Configuration.debug(
            name: "Debug",
            settings: debugSettings,
            xcconfig: .relativeToRoot("Config/Development-Local.xcconfig")
        )
        let releaseConfiguration = Configuration.release(
            name: "Release",
            settings: releaseSettings,
            xcconfig: .relativeToRoot("Config/Production-Local.xcconfig")
        )
        
        let appTarget = Target.target(
            name: name,
            destinations: destination,
            product: .app,
            bundleId: organizationName,
            deploymentTargets: deploymentTarget,
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": [
                    "UIColorName": "",
                    "UIImageName": "",
                ],
                "NSFaceIDUsageDescription": "Use Face ID to secure your wallet",
                "CFBundleDisplayName": "Kingthereum",
                "UIUserInterfaceStyle": "Automatic",
                "MARKETING_VERSION": .string(Environment.appVersion),
                "CURRENT_PROJECT_VERSION": "1",
                "INFURA_PROJECT_ID": "$(INFURA_PROJECT_ID)",
                "INFURA_PROJECT_SECRET": "$(INFURA_PROJECT_SECRET)",
                "ETHERSCAN_API_KEY": "$(ETHERSCAN_API_KEY)"
            ]),
            buildableFolders: [.folder("Sources"), .folder("Resources"), .folder("Derived")],
            dependencies: dependencies,
            settings: .settings(
                base: baseSettings
                    .merging(versionSetting)
                    .merging(["ENABLE_PREVIEWS": "YES"])
                    .merging(["SWIFT_EMIT_LOC_STRINGS": "YES"])
                    .merging(["ENABLE_TESTING_SEARCH_PATHS": "YES"]),
                configurations: [debugConfiguration, releaseConfiguration]
            )
        )
        
        var projectTargets: [Target] = [appTarget]
        var schemes: [Scheme] = []
        
        // Test Target 추가
        if hasTests {
            let testTarget = Target.target(
                name: "\(name)Tests",
                destinations: destination,
                product: .unitTests,
                bundleId: "\(organizationName).\(name)Tests",
                deploymentTargets: deploymentTarget,
                infoPlist: .default,
                buildableFolders: [.folder("Tests")],
                dependencies: [.target(name: name)],
                settings: .settings(
                    base: debugSettings
                        .merging(["ENABLE_TESTING_SEARCH_PATHS": "YES"])
                        .merging(["SWIFT_TESTING": "YES"])
                        .merging(["ENABLE_SWIFT_TESTING": "YES"]),
                    configurations: [debugConfiguration]
                )
            )
            projectTargets.append(testTarget)
            
            schemes.append(
                Scheme.scheme(
                    name: name,
                    shared: true,
                    buildAction: .buildAction(targets: ["\(name)"]),
                    testAction: .targets(["\(name)Tests"]),
                    runAction: .runAction(executable: "\(name)")
                )
            )
            
            schemes.append(
                Scheme.scheme(
                    name: "\(name)Tests",
                    shared: true,
                    buildAction: .buildAction(targets: ["\(name)", "\(name)Tests"]),
                    testAction: .targets(["\(name)Tests"])
                )
            )
        } else {
            schemes.append(
                Scheme.scheme(
                    name: name,
                    shared: true,
                    buildAction: .buildAction(targets: ["\(name)"]),
                    runAction: .runAction(executable: "\(name)")
                )
            )
        }
        
        return Project(
            name: name,
            organizationName: organizationName,
            options: .options(defaultKnownRegions: ["ko"], developmentRegion: "ko"),
            settings: .settings(base: baseSettings, configurations: [debugConfiguration, releaseConfiguration]),
            targets: projectTargets,
            schemes: schemes
        )
    }
}
