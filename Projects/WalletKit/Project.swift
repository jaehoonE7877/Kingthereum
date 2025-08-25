import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.makeModule(
    name: "WalletKit",
    hasResources: false,
    dependencies: [
        .core,
        .web3swift
    ],
    hasTests: true
)
