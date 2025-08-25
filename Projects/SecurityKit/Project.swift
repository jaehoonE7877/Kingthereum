import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.makeModule(
    name: "SecurityKit",
    hasResources: false,
    dependencies: [
        .core,
        .keychainAccess
    ],
    hasTests: true
)
