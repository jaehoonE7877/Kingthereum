import ProjectDescription

extension TargetDependency {
    
    // MARK: - Internal Modules
    public static let entity = TargetDependency.project(target: "Entity", path: "../Entity")
    public static let core = TargetDependency.project(target: "Core", path: "../Core")
    public static let walletKit = TargetDependency.project(target: "WalletKit", path: "../WalletKit")
    public static let securityKit = TargetDependency.project(target: "SecurityKit", path: "../SecurityKit")
    public static let designSystem = TargetDependency.project(target: "DesignSystem", path: "../DesignSystem")
    
    // MARK: - External Dependencies - Ethereum & Web3
    public static let web3swift = TargetDependency.external(name: "web3swift")
    
    // MARK: - External Dependencies - Security
    public static let keychainAccess = TargetDependency.external(name: "KeychainAccess")
    
    // MARK: - External Dependencies - Dependency Injection
    public static let factory = TargetDependency.external(name: "Factory")
}
