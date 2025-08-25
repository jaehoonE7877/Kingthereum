import ProjectDescription

public enum Environment {
    public static let appVersion: String = "1.0.0"
    public static let bundlePrefix: String = "com.kingtherum"
    public static let deploymentTarget: DeploymentTargets = .iOS("18.0")
    public static let destination: Destinations = [.iPhone, .iPad]
}

public extension SettingsDictionary {
    static var baseSettings: SettingsDictionary {
        return [
            "SWIFT_VERSION": "5.9",
            "IPHONEOS_DEPLOYMENT_TARGET": "18.0",
            "ENABLE_STRICT_OBJC_MSGSEND": "YES",
            "GCC_C_LANGUAGE_STANDARD": "gnu11",
            "GCC_TREAT_WARNINGS_AS_ERRORS": "YES",
            "SWIFT_TREAT_WARNINGS_AS_ERRORS": "YES",
            "CLANG_ENABLE_OBJC_ARC": "YES",
            "CLANG_WARN_OBJC_ROOT_CLASS": "YES_ERROR",
            "GCC_WARN_UNUSED_VARIABLE": "YES",
            "SWIFT_STRICT_CONCURRENCY": "complete",
            "DEFINES_MODULE": "YES",
            "DEAD_CODE_STRIPPING": "YES"
        ]
    }
    
    func automaticCodeSigning(devTeam: String) -> SettingsDictionary {
        return merging([
            "CODE_SIGN_STYLE": "Automatic",
            "DEVELOPMENT_TEAM": .string(devTeam)
        ])
    }
}
