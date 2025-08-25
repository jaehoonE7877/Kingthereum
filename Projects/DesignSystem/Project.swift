import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.makeModule(
    name: "DesignSystem",
    hasResources: true,
    dependencies: [
        .core
    ]
)