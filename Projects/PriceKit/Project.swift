import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.makeModule(
    name: "PriceKit",
    hasResources: false,
    dependencies: [
        .core
    ],
    hasTests: true
)
