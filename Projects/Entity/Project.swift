import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.makeModule(
    name: "Entity",
    hasResources: false,
    dependencies: [
        // Entity는 순수 모델 모듈로, 다른 모듈에 의존하지 않음
    ],
    hasTests: true
)