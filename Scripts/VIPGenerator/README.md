# VIP Scene Generator

이 도구는 Clean Swift (VIP) 아키텍처 패턴을 따르는 iOS Scene을 자동으로 생성합니다.

## 🛠️ 제공하는 도구

### 1. VIPTemplate.swift - 기본 VIP 생성기
간단하고 빠른 VIP Scene 생성을 위한 기본 도구입니다.

### 2. ConfigurableVIPGenerator.swift - 고급 설정 가능한 생성기
JSON 설정 파일을 통해 상세한 커스터마이징이 가능한 고급 도구입니다.

## 🚀 사용법

### 기본 VIP 생성기 사용

```bash
# Scene 생성
swift VIPTemplate.swift generate ProfileManagement

# 특정 경로에 생성
swift VIPTemplate.swift generate UserSettings ~/Projects/MyApp

# 도움말 보기
swift VIPTemplate.swift help

# 예제 보기
swift VIPTemplate.swift examples
```

### 고급 설정 가능한 생성기 사용

```bash
# 1. 샘플 설정 파일 생성
swift ConfigurableVIPGenerator.swift config sample UserProfile

# 2. 설정 파일 편집 (userprofile-config.json)
vim userprofile-config.json

# 3. 설정 파일로부터 VIP Scene 생성
swift ConfigurableVIPGenerator.swift generate userprofile-config.json

# 4. 특정 출력 경로 지정
swift ConfigurableVIPGenerator.swift generate userprofile-config.json ~/Projects/MyApp
```

## 📁 생성되는 파일 구조

```
YourScene/
├── Entity/Sources/Scenes/
│   └── YourSceneScene.swift          # Request-Response-ViewModel 모델
├── App/Sources/Scenes/YourScene/
│   ├── YourSceneInteractor.swift     # 비즈니스 로직
│   ├── YourScenePresenter.swift      # 데이터 포맷팅
│   ├── YourSceneWorker.swift         # 외부 서비스 통신
│   ├── YourSceneRouter.swift         # 네비게이션
│   └── YourSceneView.swift           # SwiftUI 화면
└── App/Tests/Scenes/YourScene/
    └── YourSceneTests.swift          # 단위 테스트 (옵션)
```

## ⚙️ 설정 파일 구조

### 기본 설정 예제

```json
{
  "sceneName": "UserProfile",
  "useCases": [
    {
      "name": "LoadProfile",
      "requestFields": [
        {
          "name": "userId",
          "type": "String",
          "comment": "사용자의 고유 ID"
        }
      ],
      "responseFields": [
        {
          "name": "profile",
          "type": "UserProfile"
        },
        {
          "name": "error",
          "type": "Error",
          "isOptional": true
        }
      ],
      "viewModelFields": [
        {
          "name": "displayName",
          "type": "String"
        },
        {
          "name": "errorMessage",
          "type": "String",
          "isOptional": true
        }
      ],
      "isAsyncOperation": true,
      "requiresNetwork": true
    }
  ],
  "options": {
    "generateSceneModels": true,
    "generateInteractor": true,
    "generatePresenter": true,
    "generateWorker": true,
    "generateRouter": true,
    "generateView": true,
    "generateTests": true,
    "useSwiftUI": true,
    "includeFormatters": true,
    "includeLogging": true
  },
  "dataStoreProperties": [
    {
      "name": "currentProfile",
      "type": "UserProfile?",
      "isPublished": true
    },
    {
      "name": "isLoading",
      "type": "Bool",
      "initialValue": "false",
      "isPublished": true
    }
  ],
  "routingMethods": [
    {
      "name": "routeToEditProfile",
      "destination": "EditProfile"
    },
    {
      "name": "routeToSettings",
      "destination": "Settings"
    }
  ]
}
```

## 🎯 UseCase 설정

### 필드 타입
- `name`: 필드명
- `type`: Swift 타입 (String, Int, Bool, CustomType 등)
- `isOptional`: 옵셔널 여부 (기본값: false)
- `defaultValue`: 기본값 (옵션)
- `isPublic`: public 접근 제어자 여부 (기본값: true)
- `comment`: 주석 (옵션)

### UseCase 옵션
- `isAsyncOperation`: 비동기 작업 여부 (기본값: true)
- `requiresNetwork`: 네트워크 요청 필요 여부
- `requiresDatabase`: 데이터베이스 작업 필요 여부

## 🔧 생성 옵션

### GenerationOptions
- `generateSceneModels`: Scene 모델 생성 여부
- `generateInteractor`: Interactor 생성 여부
- `generatePresenter`: Presenter 생성 여부
- `generateWorker`: Worker 생성 여부
- `generateRouter`: Router 생성 여부
- `generateView`: View 생성 여부
- `generateTests`: 테스트 파일 생성 여부
- `useSwiftUI`: SwiftUI 사용 여부 (UIKit 지원 예정)
- `includeFormatters`: 날짜/통화 포맷터 포함 여부
- `includeLogging`: 로깅 코드 포함 여부

## 📊 DataStore 속성

DataStore에 추가할 속성들을 정의할 수 있습니다:

```json
{
  "dataStoreProperties": [
    {
      "name": "currentUser",
      "type": "User?",
      "initialValue": "nil",
      "isPublished": true
    }
  ]
}
```

## 🗺️ 라우팅 메서드

Scene에서 사용할 네비게이션 메서드들을 정의할 수 있습니다:

```json
{
  "routingMethods": [
    {
      "name": "routeToDetail",
      "destination": "UserDetail",
      "parameters": ["userId"]
    }
  ]
}
```

## 🧪 테스트 생성

`generateTests: true` 옵션을 사용하면 다음과 같은 테스트가 자동 생성됩니다:

- **Interactor 테스트**: 비즈니스 로직 단위 테스트
- **Presenter 테스트**: 데이터 포맷팅 테스트
- **Mock/Spy 객체**: 의존성 주입을 위한 테스트 더블

## 🚀 실제 사용 예제

### 1. 간단한 프로필 화면 생성

```bash
# 기본 생성기 사용
swift VIPTemplate.swift generate UserProfile
```

### 2. 복잡한 거래 관리 화면 생성

```bash
# 1. 설정 파일 생성
swift ConfigurableVIPGenerator.swift config sample TransactionManagement

# 2. 설정 파일 편집하여 다음 UseCase들 추가:
#    - LoadTransactions
#    - FilterTransactions
#    - ExportTransactions
#    - SendTransaction

# 3. VIP Scene 생성
swift ConfigurableVIPGenerator.swift generate transactionmanagement-config.json
```

### 3. 기존 프로젝트에 통합

```bash
# 프로젝트 루트 디렉토리에서 실행
cd ~/Projects/MyiOSApp
swift ~/Desktop/Kingtherum/Scripts/VIPGenerator/ConfigurableVIPGenerator.swift generate my-scene-config.json .
```

## 🔄 워크플로우 권장사항

1. **설정 파일 생성**: `config sample` 명령으로 기본 템플릿 생성
2. **요구사항 분석**: UseCase와 데이터 모델 정의
3. **설정 파일 편집**: JSON 파일에서 상세 설정 조정
4. **VIP Scene 생성**: `generate` 명령으로 코드 생성
5. **커스터마이징**: 생성된 TODO 주석 부분 구현
6. **테스트 작성**: 생성된 테스트 템플릿 완성

## 💡 팁과 권장사항

### UseCase 네이밍
- 동사로 시작: `LoadData`, `UpdateProfile`, `SendMessage`
- 명확하고 구체적으로: `LoadUserProfile` > `LoadData`

### 필드 타입 설정
- 원시 타입 사용: `String`, `Int`, `Bool`
- 커스텀 타입 사용 시 import 확인: `Entity` 모듈의 타입들

### 에러 처리
- 모든 Response에 `error: Error?` 필드 포함 권장
- ViewModel에 `errorMessage: String?` 필드 포함

### 비동기 작업
- 네트워크/DB 작업은 `isAsyncOperation: true` 설정
- Worker에서 적절한 에러 처리 구현

## 🛠️ 개발자 정보

이 도구는 Kingtherum 프로젝트의 Clean Swift 아키텍처 표준화를 위해 개발되었습니다.

### 지원되는 기능
- ✅ SwiftUI 기반 View 생성
- ✅ Clean Swift VIP 패턴 준수
- ✅ Swift Concurrency (async/await) 지원
- ✅ Factory 의존성 주입 통합
- ✅ StandardRouter 기반 네비게이션
- ✅ XCode 16+ Testing 프레임워크 지원
- ⏳ UIKit 지원 (예정)
- ⏳ Combine 지원 (예정)

### 기여하기
개선 사항이나 버그 발견 시 이슈를 등록해 주세요.