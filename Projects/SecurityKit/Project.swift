import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.makeModule(
    name: "SecurityKit",
    hasResources: false,
    dependencies: [
        .core,
        .entity,
        .keychainAccess,
        .cryptoSwift
    ],
    hasTests: true
)
