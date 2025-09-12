import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.app(
    name: "Kingthereum",
    dependencies: [
        .walletKit,
        .securityKit,
        .designSystem,
        .priceKit
    ],
    hasTests: true
)
