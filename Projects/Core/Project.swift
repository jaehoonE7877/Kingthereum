import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.makeModule(
    name: "Core",
    hasResources: false,
    dependencies: [
        .factory,
        .entity
    ],
    hasTests: true
)
