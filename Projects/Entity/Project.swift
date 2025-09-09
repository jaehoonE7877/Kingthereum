import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.makeModule(
    name: "Entity",
    hasResources: false,
    dependencies: [
        // BigInt: 이더리움 값(Wei, 가스비 등) 정확한 표현을 위한 필수 도메인 타입
        // 순수한 수학적 계산 라이브러리로 Clean Architecture 원칙에 부합
        .external(name: "BigInt")
    ],
    hasTests: true
)