import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.makeModule(
    name: "WalletKit",
    hasResources: false,
    dependencies: [
        .core,
        .entity,
        .securityKit,
        .web3swift,
        .bigInt,
        .cryptoSwift
    ],
    hasTests: true
)
