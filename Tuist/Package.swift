// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Kingthereum",
    platforms: [.iOS(.v17)],
    products: [],
    dependencies: [
        // MARK: - Ethereum & Web3
        .package(url: "https://github.com/web3swift-team/web3swift", from: "3.2.0"),
        
        // MARK: - Security
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess", from: "4.2.2"),
        
        // MARK: - Dependency Injection
        .package(url: "https://github.com/hmlongco/Factory", from: "2.5.3"),
    ],
    targets: [],
    swiftLanguageVersions: [.v5]
)

#if TUIST
import ProjectDescription

let packageSettings = PackageSettings(
    productTypes: [
        "KeychainAccess": .framework,
        "Factory": .framework,
        "BigInt": .framework,
        "CryptoSwift": .framework
    ]
)
#endif
