# CLAUDE.md

# 프로젝트 개발 원칙 및 가이드라인

## 🏗️ 아키텍처 원칙

### Clean Swift Architecture (VIP Pattern)
이 프로젝트는 Clean Swift 아키텍처를 엄격히 따릅니다:
- **View**: UI 표시 및 사용자 입력 처리
- **Interactor**: 비즈니스 로직 처리 (UseCase)
- **Presenter**: 데이터 포맷팅 및 표시 로직
- **Router**: 화면 전환 및 네비게이션
- **Worker**: 외부 서비스와의 통신 (Repository)
- **Models**: Request, Response, ViewModel 데이터 구조

### SOLID 원칙 준수
모든 코드는 SOLID 원칙을 엄격히 따릅니다:

#### 단일 책임 원칙 (SRP)
```swift
// ❌ Bad: 여러 책임을 가진 클래스
class UserManager {
    func validateEmail(_ email: String) -> Bool { }
    func saveToDatabase(_ user: User) { }
    func sendWelcomeEmail(_ email: String) { }
}

// ✅ Good: 단일 책임
class EmailValidator {
    func validate(_ email: String) -> Bool { }
}

class UserRepository {
    func save(_ user: User) { }
}

class EmailService {
    func sendWelcome(_ email: String) { }
}
```

개방-폐쇄 원칙 (OCP)
```swift
// ❌ Bad: 수정에 열려있는 코드
class PaymentProcessor {
    func process(type: String, amount: Double) {
        if type == "credit" {
            // credit card logic
        } else if type == "paypal" {
            // paypal logic
        }
    }
}

// ✅ Good: 확장에 열려있고 수정에 닫혀있는 코드
protocol PaymentMethod {
    func process(amount: Double)
}

class CreditCardPayment: PaymentMethod {
    func process(amount: Double) { }
}

class PayPalPayment: PaymentMethod {
    func process(amount: Double) { }
}
```

리스코프 치환 원칙 (LSP)

```swift
// ✅ Good: 하위 타입이 상위 타입을 완전히 대체
protocol Shape {
    func area() -> Double
}

class Rectangle: Shape {
    func area() -> Double { return width * height }
}

class Square: Shape {
    func area() -> Double { return side * side }
}
```

인터페이스 분리 원칙 (ISP)

```swift
// ❌ Bad: 거대한 인터페이스
protocol Worker {
    func work()
    func eat()
    func sleep()
}

// ✅ Good: 분리된 인터페이스
protocol Workable {
    func work()
}

protocol Feedable {
    func eat()
}

protocol Sleepable {
    func sleep()
}
```

의존성 역전 원칙 (DIP)

```swift
// ❌ Bad: 구체 클래스에 의존
class LoginViewModel {
    private let api = APIService() // 구체 클래스에 직접 의존
}

// ✅ Good: 추상화에 의존
protocol AuthRepository {
    func login(email: String, password: String) async -> Result<User, Error>
}

class LoginViewModel {
    private let repository: AuthRepository // 프로토콜에 의존
    
    init(repository: AuthRepository) {
        self.repository = repository
    }
}
```

## 🧪 TDD (Test-Driven Development)

### 📝 테스트 프레임워크 설정

**XCode 16+ Testing Framework 사용** (XCTest 사용 금지)

```swift
import Testing
import Foundation
@testable import YourModule
```

🎯 VIP 패턴 테스트 템플릿
Interactor 테스트 템플릿

```swift
import Testing
import Foundation
@testable import Scenes

// MARK: - [Scene명]Interactor 테스트

@Suite("[Scene명]Interactor 테스트")
struct [Scene명]InteractorTests {
    
    // MARK: - Spy Classes
    
    class PresentationLogicSpy: [Scene명]PresentationLogic {
        var presentSomethingCalled = false
        var presentSomethingResponse: [Scene명].Something.Response?
        
        func presentSomething(response: [Scene명].Something.Response) {
            presentSomethingCalled = true
            presentSomethingResponse = response
        }
        
        var presentErrorCalled = false
        var presentErrorResponse: [Scene명].Error.Response?
        
        func presentError(response: [Scene명].Error.Response) {
            presentErrorCalled = true
            presentErrorResponse = response
        }
    }
    
    class WorkerSpy: [Scene명]WorkerProtocol {
        var fetchDataCalled = false
        var fetchDataResult: Result<Entity, Error> = .success(Entity())
        
        func fetchData(request: RequestModel) async -> Result<Entity, Error> {
            fetchDataCalled = true
            return fetchDataResult
        }
    }
    
    // MARK: - 비즈니스 로직 테스트
    
    @Suite("데이터 조회")
    struct FetchData {
        
        @Test("성공 케이스 - 유효한 데이터 반환")
        func testFetchDataSuccess() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            let expectedData = Entity(id: "123", name: "Test")
            workerSpy.fetchDataResult = .success(expectedData)
            
            let sut = [Scene명]Interactor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            let request = [Scene명].Something.Request(id: "123")
            
            // When
            await sut.fetchSomething(request: request)
            
            // Then
            #expect(workerSpy.fetchDataCalled == true, "Worker가 호출되어야 함")
            #expect(presenterSpy.presentSomethingCalled == true, "Presenter가 호출되어야 함")
            #expect(
                presenterSpy.presentSomethingResponse?.data == expectedData,
                "올바른 데이터가 Presenter로 전달되어야 함"
            )
        }
        
        @Test("실패 케이스 - 네트워크 오류")
        func testFetchDataNetworkError() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            let networkError = NetworkError.noConnection
            workerSpy.fetchDataResult = .failure(networkError)
            
            let sut = [Scene명]Interactor(
                presenter: presenterSpy,
                worker: workerSpy
            )
            
            let request = [Scene명].Something.Request(id: "123")
            
            // When
            await sut.fetchSomething(request: request)
            
            // Then
            #expect(workerSpy.fetchDataCalled == true, "Worker가 호출되어야 함")
            #expect(presenterSpy.presentErrorCalled == true, "에러 Presenter가 호출되어야 함")
            #expect(
                presenterSpy.presentErrorResponse?.error == networkError,
                "네트워크 오류가 Presenter로 전달되어야 함"
            )
        }
    }
    
    @Suite("유효성 검증")
    struct Validation {
        
        @Test("이메일 유효성 검증 - 성공")
        func testValidateEmailSuccess() {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let sut = [Scene명]Interactor(presenter: presenterSpy)
            let request = [Scene명].ValidateEmail.Request(email: "test@example.com")
            
            // When
            sut.validateEmail(request: request)
            
            // Then
            #expect(
                presenterSpy.presentEmailValidationResponse?.isValid == true,
                "유효한 이메일은 성공으로 처리되어야 함"
            )
        }
        
        @Test("이메일 유효성 검증 - 실패")
        func testValidateEmailFailure() {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let sut = [Scene명]Interactor(presenter: presenterSpy)
            let request = [Scene명].ValidateEmail.Request(email: "invalid-email")
            
            // When
            sut.validateEmail(request: request)
            
            // Then
            #expect(
                presenterSpy.presentEmailValidationResponse?.isValid == false,
                "유효하지 않은 이메일은 실패로 처리되어야 함"
            )
        }
    }
}
```

Presenter 테스트 템플릿

```swift
import Testing
import Foundation
@testable import Scenes

// MARK: - [Scene명]Presenter 테스트

@MainActor @Suite("[Scene명]Presenter 테스트")
struct [Scene명]PresenterTests {
    
    // MARK: - Spy Classes
    
    class DisplayLogicSpy: [Scene명]DisplayLogic {
        var displaySomethingCalled = false
        var displaySomethingViewModel: [Scene명].Something.ViewModel?
        
        func displaySomething(viewModel: [Scene명].Something.ViewModel) {
            displaySomethingCalled = true
            displaySomethingViewModel = viewModel
        }
        
        var displayErrorCalled = false
        var displayErrorViewModel: [Scene명].Error.ViewModel?
        
        func displayError(viewModel: [Scene명].Error.ViewModel) {
            displayErrorCalled = true
            displayErrorViewModel = viewModel
        }
    }
    
    // MARK: - 포맷팅 테스트
    
    @Suite("데이터 포맷팅")
    struct DataFormatting {
        
        @Test("날짜 포맷팅")
        func testFormatDate() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = [Scene명]Presenter(viewController: displayLogicSpy)
            
            let date = Date(timeIntervalSince1970: 1234567890)
            let response = [Scene명].ShowDate.Response(date: date)
            
            // When
            sut.presentDate(response: response)
            
            // Then
            #expect(displayLogicSpy.displaySomethingCalled == true, "Display 메서드가 호출되어야 함")
            #expect(
                displayLogicSpy.displaySomethingViewModel?.dateString == "2009년 2월 14일",
                "날짜가 올바른 형식으로 포맷되어야 함"
            )
        }
        
        @Test("금액 포맷팅")
        func testFormatCurrency() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = [Scene명]Presenter(viewController: displayLogicSpy)
            
            let response = [Scene명].ShowPrice.Response(amount: 1234567)
            
            // When
            sut.presentPrice(response: response)
            
            // Then
            #expect(
                displayLogicSpy.displayPriceViewModel?.priceString == "₩1,234,567",
                "금액이 올바른 형식으로 포맷되어야 함"
            )
        }
    }
    
    @Suite("에러 메시지 처리")
    struct ErrorHandling {
        
        @Test("네트워크 에러 메시지")
        func testPresentNetworkError() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = [Scene명]Presenter(viewController: displayLogicSpy)
            
            let response = [Scene명].Error.Response(
                error: NetworkError.noConnection
            )
            
            // When
            sut.presentError(response: response)
            
            // Then
            #expect(displayLogicSpy.displayErrorCalled == true, "에러 표시 메서드가 호출되어야 함")
            #expect(
                displayLogicSpy.displayErrorViewModel?.message == "네트워크 연결을 확인해주세요",
                "사용자 친화적인 에러 메시지로 변환되어야 함"
            )
        }
        
        @Test("유효성 검증 에러 메시지")
        func testPresentValidationError() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = [Scene명]Presenter(viewController: displayLogicSpy)
            
            let response = [Scene명].Validation.Response(
                isValid: false,
                field: "email",
                errorCode: "INVALID_FORMAT"
            )
            
            // When
            sut.presentValidation(response: response)
            
            // Then
            #expect(
                displayLogicSpy.displayValidationViewModel?.errorMessage == "올바른 이메일 형식이 아닙니다",
                "유효성 검증 에러가 적절한 메시지로 변환되어야 함"
            )
        }
    }
}
```

Worker 테스트 템플릿

```swift
import Testing
import Foundation
@testable import Scenes
@testable import NetworkKit

// MARK: - [Scene명]Worker 테스트

@Suite("[Scene명]Worker 테스트")
struct [Scene명]WorkerTests {
    
    // MARK: - Mock Classes
    
    actor MockAPIClient: APIClientProtocol {
        var requestCalled = false
        var requestResult: Result<Data, Error> = .success(Data())
        
        func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
            requestCalled = true
            switch requestResult {
            case .success(let data):
                return try JSONDecoder().decode(T.self, from: data)
            case .failure(let error):
                throw error
            }
        }
    }
    
    // MARK: - API 통신 테스트
    
    @Suite("API 호출")
    struct APITests {
        
        @Test("데이터 조회 성공")
        func testFetchDataSuccess() async {
            // Given
            let mockAPIClient = MockAPIClient()
            let expectedData = UserEntity(id: "123", name: "홍길동")
            let jsonData = try! JSONEncoder().encode(expectedData)
            await mockAPIClient.requestResult = .success(jsonData)
            
            let sut = [Scene명]Worker(apiClient: mockAPIClient)
            
            // When
            let result = await sut.fetchUser(id: "123")
            
            // Then
            switch result {
            case .success(let user):
                #expect(user.id == "123", "사용자 ID가 일치해야 함")
                #expect(user.name == "홍길동", "사용자 이름이 일치해야 함")
                #expect(await mockAPIClient.requestCalled == true, "API가 호출되어야 함")
            case .failure:
                Issue.record("데이터 조회가 성공해야 함")
            }
        }
        
        @Test("네트워크 타임아웃")
        func testNetworkTimeout() async {
            // Given
            let mockAPIClient = MockAPIClient()
            await mockAPIClient.requestResult = .failure(NetworkError.timeout)
            
            let sut = [Scene명]Worker(apiClient: mockAPIClient)
            
            // When
            let result = await sut.fetchUser(id: "123")
            
            // Then
            switch result {
            case .success:
                Issue.record("타임아웃 에러가 발생해야 함")
            case .failure(let error):
                #expect(
                    error as? NetworkError == NetworkError.timeout,
                    "타임아웃 에러가 반환되어야 함"
                )
            }
        }
    }
    
    @Suite("데이터 변환")
    struct DataTransformation {
        
        @Test("JSON 파싱 성공")
        func testParseJSONSuccess() {
            // Given
            let sut = [Scene명]Worker()
            let jsonString = """
            {
                "id": "123",
                "name": "테스트",
                "email": "test@example.com"
            }
            """
            let jsonData = jsonString.data(using: .utf8)!
            
            // When
            let result = sut.parseUserData(jsonData)
            
            // Then
            switch result {
            case .success(let user):
                #expect(user.id == "123", "ID가 올바르게 파싱되어야 함")
                #expect(user.name == "테스트", "이름이 올바르게 파싱되어야 함")
                #expect(user.email == "test@example.com", "이메일이 올바르게 파싱되어야 함")
            case .failure:
                Issue.record("JSON 파싱이 성공해야 함")
            }
        }
        
        @Test("잘못된 JSON 형식")
        func testParseInvalidJSON() {
            // Given
            let sut = [Scene명]Worker()
            let invalidJSON = "not a json".data(using: .utf8)!
            
            // When
            let result = sut.parseUserData(invalidJSON)
            
            // Then
            switch result {
            case .success:
                Issue.record("잘못된 JSON은 파싱 실패해야 함")
            case .failure(let error):
                #expect(error is DecodingError, "디코딩 에러가 발생해야 함")
            }
        }
    }
}
```

📐 VIP 데이터 모델 템플릿

```swift
// MARK: - [Scene명] Models

enum [Scene명] {
    
    // MARK: Use case 1 - Fetch Something
    
    enum FetchSomething {
        struct Request {
            let id: String
        }
        
        struct Response {
            let data: Entity
        }
        
        struct ViewModel {
            let displayedData: DisplayedData
        }
    }
    
    // MARK: Use case 2 - Validate Something
    
    enum ValidateSomething {
        struct Request {
            let field: String
            let value: String
        }
        
        struct Response {
            let isValid: Bool
            let errorCode: String?
        }
        
        struct ViewModel {
            let fieldState: FieldState
            let errorMessage: String?
        }
    }
}
```

📋 코드 리뷰 체크리스트
🔐 보안 검증

 API Key, Secret, Token이 하드코딩되지 않았는가?
 민감한 정보가 UserDefaults/Keychain에 암호화되어 저장되는가?
 네트워크 통신 시 SSL Pinning이 적용되었는가?
 로그에 민감한 정보가 노출되지 않는가?
 입력값 검증과 sanitization이 적용되었는가?

🏛️ Clean Swift 아키텍처 준수

 View, Interactor, Presenter가 명확히 분리되었는가?
 각 컴포넌트가 단일 책임을 가지는가?
 의존성 주입이 올바르게 구현되었는가?
 Protocol을 통한 추상화가 적용되었는가?
 데이터 흐름이 단방향인가? (View → Interactor → Presenter → View)

✅ 테스트 검증

 모든 새로운 기능에 대한 단위 테스트가 작성되었는가?
 비즈니스 로직 테스트 커버리지가 80% 이상인가?
 Given-When-Then 패턴을 따르는가?
 Edge Case와 Error Case가 테스트되었는가?
 Mock 객체가 적절히 사용되었는가?
 테스트가 독립적이고 반복 가능한가?

🔄 SOLID 원칙

 각 클래스가 단일 책임 원칙을 따르는가?
 확장에는 열려있고 수정에는 닫혀있는가?
 상속 관계가 리스코프 치환 원칙을 만족하는가?
 인터페이스가 적절히 분리되었는가?
 구체 클래스가 아닌 추상화에 의존하는가?

📊 코드 품질

 함수/메서드가 20줄 이내인가?
 순환 복잡도가 10 이하인가?
 중복 코드가 없는가?
 네이밍이 명확하고 일관성 있는가?
 주석 대신 자기 설명적 코드인가?

🎯 비즈니스 로직

 요구사항이 정확히 구현되었는가?
 예외 처리가 적절한가?
 성능 최적화가 필요한 부분이 처리되었는가?

⚠️ 개발 원칙
필수 준수 사항

테스트 없는 코드는 절대 머지하지 않습니다
보안 취약점이 있는 코드는 즉시 수정합니다
아키텍처 위반 사항은 리팩토링 후 진행합니다
코드 리뷰 없이 production 배포하지 않습니다

지속적 개선

매 스프린트마다 기술 부채 해결
정기적인 의존성 업데이트
테스트 커버리지 지속적 모니터링
성능 메트릭 추적 및 개선


이 CLAUDE.md 파일은 Claude Code가 Swift 프로젝트에서 TDD와 SOLID 원칙을 일관되게 적용할 수 있도록 구성되었습니다. 특히 XCode 16+의 Testing 프레임워크를 사용한 실제 테스트 템플릿과 Clean Swift 아키텍처를 준수하는 구체적인 가이드라인을 포함했습니다.

## 1. 기술 스택

### 언어 및 개발 환경
- **Swift**: 6.0 이상
- **Xcode**: 16.0 이상 (CI/CD에서는 Xcode 16.3 사용)
- **Tuist**: 4.48.1 버전
- **mise**: 버전 관리 도구 (Node.js, Tuist 등)
- **최소 지원 버전**: iOS 18.0

### 주요 기술
- **SwiftUI**: Code-based UI 구현 (Storyboard/XIB 미사용)
- **Swift Concurrency**: async/await, Task, Actor를 활용한 비동기 프로그래밍
- **URLSession**: 네트워크 통신 라이브러리
- **Swift Testing**: 단위 테스트 및 통합 테스트 (@Suite, @Test 어노테이션 사용)

### 외부 서비스 및 라이브러리
- **Web3Swift**: 3.2.0 - Web3 이더리움 지갑 연동 및 송금 등
- **KeychainAccess**: 4.2.2 - 암호화된 데이터의 안전한 저장과 검색을 제공

## 2. 프로젝트 구조

### 아키텍처
**Clean Swift** 기반으로 설계되었으며, 각 레이어 간의 의존성을 명확히 분리하여 유지보수성과 테스트 용이성을 확보합니다.

## 3. 코딩 컨벤션 및 패턴

### Clean Swift (VIP) 패턴
 1. VIP 아키텍처 구성 요소

  View ←→ Interactor ←→ Presenter
   ↑                        ↑
   └── Router ←──────────────┘

  V (View)

  - UI 표시 담당
  - 사용자 입력을 Interactor로 전달
  - Presenter로부터 받은 ViewModel을 화면에 렌더링

  I (Interactor)

  - 비즈니스 로직 실행
  - Worker를 통해 데이터 처리
  - Response를 Presenter로 전달

  P (Presenter)

  - Response를 ViewModel로 변환
  - 화면 표시용 데이터 포맷팅
  - View에게 결과 전달

  2. 단방향 데이터 흐름 (Unidirectional Data Flow)

  // 1. View → Interactor (Request)
  func createWallet() {
      let request = Authentication.CreateWallet.Request(walletName: walletName)
      interactor?.createWallet(request: request)
  }

  // 2. Interactor → Presenter (Response)
  let response = Authentication.CreateWallet.Response(
      success: true,
      walletAddress: result.wallet.address,
      error: nil
  )
  presenter?.presentWalletCreationResult(response: response)

  // 3. Presenter → View (ViewModel)
  let viewModel = Authentication.CreateWallet.ViewModel(
      success: response.success,
      errorMessage: response.error?.localizedDescription
  )
  viewController?.displayWalletCreationResult(viewModel: viewModel)

  3. 핵심 설계 원칙

  3.1 관심사 분리 (Separation of Concerns)

  - View: UI 표시만 담당
  - Interactor: 비즈니스 로직만 처리
  - Presenter: 데이터 변환만 수행

  3.2 의존성 역전 (Dependency Inversion)

  // 프로토콜을 통한 의존성 주입
  protocol AuthenticationBusinessLogic {
      func createWallet(request: Authentication.CreateWallet.Request)
  }

  class AuthenticationView {
      private var interactor: AuthenticationBusinessLogic?
  }

  3.3 테스트 용이성 (Testability)

  // Mock 객체를 통한 단위 테스트
  class MockAuthenticationInteractor: AuthenticationBusinessLogic {
      func createWallet(request: Authentication.CreateWallet.Request) {
          // Test implementation
      }
  }

  4. Request-Response-ViewModel 패턴

  표준 Models 구조

  enum Authentication {
      enum CreateWallet {
          struct Request {
              let walletName: String
          }

          struct Response {
              let success: Bool
              let walletAddress: String?
              let error: Error?
          }

          struct ViewModel {
              let success: Bool
              let errorMessage: String?
          }
      }
  }

  5. Router와 DataStore 패턴

  Router (화면 전환)

  protocol AuthenticationRoutingLogic {
      func routeToMain()
  }

  protocol AuthenticationDataPassing {
      var dataStore: AuthenticationDataStore? { get }
  }

  DataStore (데이터 전달)

  protocol AuthenticationDataStore {
      var isSetupMode: Bool { get set }
      var hasExistingWallet: Bool { get set }
  }

  6. Worker 패턴 (선택적)

  // 네트워크, 데이터베이스 등 외부 서비스 처리
  class AuthenticationWorker {
      func setupPIN(_ pin: String) async throws { }
      func createWallet(name: String) async throws -> Wallet { }
  }

  7. 주요 장점

  7.1 예측 가능한 구조

  - 모든 Scene이 동일한 VIP 패턴 적용
  - 코드 위치 예측 가능

  7.2 높은 테스트 커버리지

  - 각 컴포넌트 독립적 테스트 가능
  - Mock 객체 쉽게 구성

  7.3 확장성과 유지보수성

  - 새로운 기능 추가 시 기존 코드 영향 최소화
  - 각 레이어 독립적 수정 가능

  7.4 팀 개발 효율성

  - 역할 분담 명확
  - 병렬 개발 가능

  8. Clean Architecture와의 차이점

  | 특징     | Clean Swift (VIP)              | Clean Architecture            |
  |--------|--------------------------------|-------------------------------|
  | 구조     | Scene 기반                       | Layer 기반                      |
  | 데이터 흐름 | Request → Response → ViewModel | Repository → UseCase → Entity |
  | 화면 전환  | Router                         | Coordinator                   |
  | 상태 관리  | Local ViewModel                | Centralized AppState          |

  9. SwiftUI와의 호환성

  // VIP + SwiftUI 조합
  struct AuthenticationView: View {
      @StateObject private var viewModel = AuthenticationViewModel()

      var body: some View {
          // SwiftUI View 구현
      }
  }

  // ViewModel이 DisplayLogic 프로토콜 구현
  extension AuthenticationViewModel: AuthenticationDisplayLogic {
      func displayWalletCreationResult(viewModel: Authentication.CreateWallet.ViewModel) {
          // UI 업데이트
      }
  }

## 4. 테스팅

### 테스트 프레임워크
- Swift Testing 프레임워크 사용 (`@Suite`, `@Test` 어노테이션)
- Mock 객체를 활용한 단위 테스트
- Actor 기반 Mock 구현으로 동시성 안전성 확보

## 5. iOS 코드 컨벤션

### 5.1 기본 원칙
- 객체에는 **Upper Camel Case**, 그 외에는 **Lower Camel Case** 사용
- Apple의 [API Design Guide](https://www.swift.org/documentation/api-design-guidelines/) 준수

### 5.2 코드 포매팅

#### 임포트
- 알파벳 순으로 정렬
- 내장 프레임워크(First-Party) 먼저 임포트 후 빈줄로 구분
- 최소의 모듈만 임포트

```swift
// ✅ 좋은 예
import SwiftUI
import UIKit

import Alamofire
import Data
import Kingfisher
import Snapkit
```

#### 띄어쓰기
- 콜론(`:`) 사용 시 오른쪽만 띄어쓰기
- 삼항연산자의 경우 콜론 앞뒤로 띄어쓰기
- 연산 프로퍼티 접근 레벨 설정 시 붙여서 사용

```swift
// ✅ 좋은 예
let user: [String: String]
private(set) var phoneNumber: String
let isBlack: Bool = isBlack() == "YES" ? true : false
```

#### 들여쓰기
- Tab 사용 (Space 4번)

#### 줄바꿈
- 함수 정의가 최대 길이를 초과하는 경우 줄바꿈
- 파라미터에 클로저가 2개 이상 존재하는 경우 무조건 내려쓰기
- `if let`, `guard let` 구문이 길 경우 줄바꿈 후 한칸 들여쓰기

```swift
// ✅ 좋은 예
func collectionView(
  _ collectionView: UICollectionView,
  cellForItemAt indexPath: IndexPath
) -> UICollectionViewCell {
  // doSomething()
}

guard let user = self.veryLongFunctionName(),
      let name = user.name,
      user.gender == .female
else { return }
```

#### 빈 줄
- 모든 파일은 빈 줄로 끝나도록 함
- MARK 구문 위와 아래에 공백 설정

#### 최대 줄 길이
- 한 줄은 최대 100자로 설정

### 5.3 네이밍

#### 클래스 • 구조체 • 열거형
- Upper Camel Case 사용
- 클래스 이름에는 접두사를 붙이지 않음

```swift
// ✅ 좋은 예
class User { }
struct Human { }
enum NetworkError {
    case keyNotFound
    case serverError
}
```

#### 함수 • 메서드
- Lower Camel Case 사용
- 함수 이름 앞에 `get`을 붙이지 않음
- Action 함수의 네이밍은 '주어 + 동사 + 목적어' 형태
- `will~`: 특정 행위가 일어나기 직전
- `did~`: 특정 행위가 일어난 직후
- `should~`: Bool을 반환하는 함수에 사용

```swift
// ✅ 좋은 예
func name(for user: User) -> String?
func backButtonDidTap() { }
func shouldBackButtonDidTap() -> Bool { }
```

#### 변수 • 상수
- Lower Camel Case 사용
- NotificationName은 모든 철자 대문자 + Snake case 사용

```swift
// ✅ 좋은 예
let isBlackUser: Bool
let maximumNumberOfLines = 3
let NOTIFICATION_LOGOUT = NSNotification.Name(rawValue: "LOGOUT")
```

#### 프로토콜
- Upper Camel Case 사용
- 네이밍 시 ~able 사용 권장, 애매할 땐 ~Protocol 붙이기

```swift
// ✅ 좋은 예
protocol NetworkProtocol { }
class NetworkManager: NetworkProtocol { }
```

### 5.4 기타 규칙

#### 약어
- 약어로 시작하는 경우 소문자로 표기, 그 외에는 대문자

```swift
// ✅ 좋은 예
let userID: Int?
let html: String?
let websiteURL: URL?
let urlString: String?
```

#### 클로저
- 파라미터와 리턴 타입이 없는 Closure 정의 시 `() -> Void` 사용
- Closure 사용 시 타입 정의 생략
- 파라미터 이름 사용 권장 (고차함수는 제외)
- Closure 내 self 사용 시 weak self 패턴 적용

```swift
// ✅ 좋은 예
let completionHandler: (() -> Void)?

UIView.animate(withDuration: 0.5) {
  // doSomething()
}

login { token in
    send(token)
}

// Swift 5.8 이상
{ [weak self] value in
    guard let self else { return }
    self.viewModel
}
```

#### 타입
- `Array<T>`와 `Dictionary<T: U>` 보다는 `[T]`, `[T: U]` 사용
- 컴파일러가 타입 추론이 가능하면 타입 생략

```swift
// ✅ 좋은 예
var messages: [String]?
var names: [Int: String]?
let view = UIView(frame: .zero)
```

#### final
- 더 이상 상속이 발생하지 않는 클래스는 final 키워드로 선언

#### 프로토콜 extension
- 프로토콜 적용 시 extension으로 관련된 메서드를 모아둠

```swift
// ✅ 좋은 예
final class MyViewController: UIViewController {
  // ...
}

// MARK: - UITableViewDataSource
extension MyViewController: UITableViewDataSource {
  // ...
}
```

#### 주석
- `///`: 문서화에 사용되는 주석
- `//`: 한 줄 주석 처리
- `// MARK: -`: 연관된 코드 구분
- 주석 작성 시 한글 사용 가능

```swift
/// 나이 더하기
/// - Parameters:
///   - a: a의 나이
///   - b: b의 나이
/// - Returns: 둘 나이의 합
func add(a: Int, b: Int) -> Int {
    return a + b
}
```

#### 접근제어자
- internal은 사용하지 않음
- static 키워드 사용 시 접근제어자를 우선 작성
- 접근제어자가 다를 때마다 줄바꿈 사용

```swift
// ✅ 좋은 예
public static func create() { }

public var id: String?
public var password: String?

private var isValidID: Bool?
private var isValidPassword: Bool?
```

## 6. Git 에티켓

### 6.1 Branch 네이밍 규칙

#### 기본 규칙
- 무조건 **소문자**로 작성
- 띄어쓰기는 하이픈(`-`)으로 표기

#### Branch 유형별 네이밍
1. **신기능 추가**: `feature`로 시작
2. **버그 수정**: `fix`로 시작
3. **리팩토링**: `refactor`로 시작
4. **테스트 코드**: `test`로 시작

#### 예시
```bash
# 신기능 추가
feature-mypage-setting         # 마이페이지 > 설정화면 기능 및 UI 구현
feature-push-notification      # 푸시 알림 기능 구현

# 버그 수정
fix-api-token-refresh         # APIManager 토큰 갱신 로직 수정
fix-login-validation          # 로그인 유효성 검증 버그 수정

# 리팩토링
refactor-inapp-purchase       # 인앱 결제 리팩토링
refactor-network-layer        # 네트워크 레이어 구조 개선

# 테스트 코드
test-login-logic             # 로그인 로직 단위테스트
test-payment-integration     # 결제 통합 테스트
```

### 6.2 Commit 메시지 규칙

#### 기본 구조
```
type: subject

body

footer
```
- 각 파트는 **빈 줄**로 구분
- type과 subject는 **필수**, body와 footer는 **선택사항**

#### Commit Type
- 태그는 **영어**로 작성, 첫 문자는 **대문자**
- 콜론(`:`) 뒤에만 공백

| Type | 설명 |
|------|------|
| **Feat** | 새로운 기능 추가 |
| **Fix** | 버그 수정 |
| **Docs** | 문서 수정 |
| **Style** | 코드 포맷팅, 세미콜론 누락 등 (코드 변경 없음) |
| **Refactor** | 코드 리팩토링 |
| **Test** | 테스트 코드 추가 |
| **Chore** | 빌드 업무 수정, 패키지 매니저 수정 |

#### Subject 작성 규칙
- 최대 **50글자** 이내
- 마침표 및 특수기호 사용 금지
- **한국어**로 작성
- 개조식 구문으로 간결하게 작성

```bash
# ✅ 좋은 예
Feat: 사용자 인증 기능 추가
Fix: 토큰 갱신 이슈 해결
Refactor: 네트워크 에러 처리 개선

# ❌ 나쁜 예
Feat: 사용자 인증 기능을 추가했습니다.
Fix: 토큰 갱신 이슈를 해결함!
Refactor: 네트워크 에러 처리를 개선하였음
```

#### Body 작성 규칙
- 한 줄당 **72자** 이내
- **무엇을** 변경했는지, **왜** 변경했는지 설명
- 최대한 상세히 작성

```bash
Fix: 토큰 갱신 시 무한 루프 문제 해결

토큰 갱신 중 401 에러가 연속으로 발생할 경우
무한 루프에 빠지는 문제를 해결했습니다.

- RefreshToken이 만료된 경우를 체크하는 로직 추가
- 최대 재시도 횟수를 1회로 제한
- 재시도 실패 시 로그인 화면으로 이동
```

#### Footer 작성 규칙
- 이슈 트래커 ID 작성 (선택사항)
- `유형: #이슈번호` 형식
- 여러 이슈는 쉼표(`,`)로 구분

| 유형 | 사용 시점 |
|------|-----------|
| **Fixes** | 이슈 수정 중 (미해결) |
| **Resolves** | 이슈 해결 완료 |
| **Ref** | 참고할 이슈 |
| **Related to** | 관련된 이슈 (미해결) |

```bash
# Footer 예시
Fixes: #45
Resolves: #32
Ref: #12
Related to: #34, #23
```

#### Commit 메시지 전체 예시
```bash
Feat: 소셜 로그인 기능 추가

카카오톡과 애플 로그인 기능을 구현했습니다.

- KakaoSDK를 사용한 카카오톡 로그인 구현
- Sign in with Apple 구현
- 소셜 로그인 실패 시 에러 처리 로직 추가
- 기존 이메일 로그인과 통합

Resolves: #89
Related to: #78, #90
```

## 7. 프로젝트 실행 가이드

### 사전 요구사항
1. Xcode 16.0 이상 설치
2. mise 설치: `curl https://mise.run | sh`
3. Tuist 설치: `mise install tuist@4.48.1`

### 테스트 실행
```bash
# 단위 테스트만 실행
tuist test --skip-ui-tests

# 모든 테스트 실행
tuist test
```

## 8. 🎨 디자인 시스템 사용 가이드

### 필수 사용 규칙
모든 SwiftUI View를 생성할 때 반드시 다음 디자인 시스템을 활용해야 합니다:

#### 8.1 컬러 시스템
- **`KingthereumColors`** 사용 필수
- 하드코딩된 색상값 절대 금지
- 시스템 다크모드 자동 대응

```swift
// ✅ 좋은 예
Text("제목")
    .foregroundColor(KingthereumColors.primaryText)
    .background(KingthereumColors.surface)

Button("확인") { }
    .foregroundColor(KingthereumColors.onPrimary)
    .background(KingthereumColors.primary)

// ❌ 나쁜 예
Text("제목")
    .foregroundColor(.white)        // 하드코딩 금지
    .background(Color(hex: "#123")) // 직접 색상값 금지
```

#### 8.2 타이포그래피 시스템
- **`KingthereumTypography`** 사용 필수
- 폰트 크기, 굵기, 줄간격 일관성 보장
- 접근성 고려한 동적 타입 지원

```swift
// ✅ 좋은 예
Text("타이틀")
    .font(KingthereumTypography.headlineLarge)

Text("본문 내용")
    .font(KingthereumTypography.bodyMedium)

Text("캡션")
    .font(KingthereumTypography.captionSmall)

// ❌ 나쁜 예
Text("타이틀")
    .font(.system(size: 24, weight: .bold))  // 직접 폰트 설정 금지

Text("본문")
    .font(.title2)  // 시스템 기본 폰트 사용 금지
```

#### 8.3 그라데이션 시스템
- **`KingthereumGradients`** 사용 필수
- Metal Liquid Glass 브랜드 아이덴티티 유지
- 일관된 시각적 효과 제공

```swift
// ✅ 좋은 예
Rectangle()
    .fill(KingthereumGradients.metalLiquid)

Button("시작하기") { }
    .background(KingthereumGradients.primaryGlow)

VStack { }
    .background(KingthereumGradients.surfaceGradient)

// ❌ 나쁜 예
Rectangle()
    .fill(LinearGradient(
        colors: [.blue, .purple],  // 직접 그라데이션 생성 금지
        startPoint: .top,
        endPoint: .bottom
    ))
```

### 8.4 디자인 시스템 적용 템플릿

#### 기본 View 구조
```swift
struct MyCustomView: View {
    var body: some View {
        VStack(spacing: 16) {
            // Header
            Text("페이지 제목")
                .font(KingthereumTypography.headlineLarge)
                .foregroundColor(KingthereumColors.primaryText)
            
            // Content
            VStack(spacing: 12) {
                Text("설명 텍스트")
                    .font(KingthereumTypography.bodyMedium)
                    .foregroundColor(KingthereumColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(KingthereumColors.surface)
            .cornerRadius(16)
            
            // Action Button
            Button("액션 버튼") {
                // Action
            }
            .font(KingthereumTypography.labelLarge)
            .foregroundColor(KingthereumColors.onPrimary)
            .padding()
            .background(KingthereumGradients.primaryGlow)
            .cornerRadius(12)
        }
        .padding()
        .background(KingthereumColors.background)
    }
}
```

#### 카드 컴포넌트 템플릿
```swift
struct KingthereumCard<Content: View>: View {
    let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        VStack(spacing: 0) {
            content()
        }
        .padding()
        .background(KingthereumColors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(KingthereumGradients.borderGradient, lineWidth: 1)
        )
        .cornerRadius(16)
        .shadow(
            color: KingthereumColors.shadow.opacity(0.1),
            radius: 8,
            x: 0,
            y: 4
        )
    }
}
```

#### 입력 필드 템플릿
```swift
struct KingthereumTextField: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        TextField(placeholder, text: $text)
            .font(KingthereumTypography.bodyMedium)
            .foregroundColor(KingthereumColors.primaryText)
            .padding()
            .background(KingthereumColors.surfaceVariant)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(KingthereumColors.outline, lineWidth: 1)
            )
            .cornerRadius(12)
    }
}
```

### 8.5 디자인 시스템 검증 체크리스트

새로운 View 작성 시 반드시 확인:

#### 컬러 시스템 ✅
- [ ] 모든 색상이 `KingthereumColors`에서 가져왔는가?
- [ ] 하드코딩된 색상값이 없는가?
- [ ] 다크모드에서 적절한 대비를 가지는가?

#### 타이포그래피 ✅
- [ ] 모든 텍스트가 `KingthereumTypography`를 사용하는가?
- [ ] 텍스트 계층구조가 올바른가?
- [ ] 동적 타입을 고려했는가?

#### 그라데이션 ✅
- [ ] 그라데이션이 `KingthereumGradients`에서 가져왔는가?
- [ ] 브랜드 아이덴티티를 유지하는가?
- [ ] 성능에 영향을 주지 않는가?

#### 일관성 ✅
- [ ] 기존 컴포넌트와 시각적 일관성을 가지는가?
- [ ] 간격(spacing)이 디자인 토큰을 따르는가?
- [ ] 둥근 모서리(corner radius)가 일관된가?

### 8.6 금지 사항

#### 절대 사용하면 안 되는 것들
```swift
// ❌ 절대 금지
.foregroundColor(.red)           // 시스템 색상 직접 사용
.foregroundColor(Color.blue)     // 하드코딩된 색상
.font(.system(size: 16))         // 직접 폰트 크기 지정
.background(Color(red: 0.5, green: 0.5, blue: 0.5)) // RGB 직접 설정

// ✅ 반드시 이렇게
.foregroundColor(KingthereumColors.error)
.font(KingthereumTypography.bodyMedium)
.background(KingthereumGradients.errorGradient)
```

### 8.7 디자인 시스템 확장

새로운 디자인 토큰이 필요한 경우:
1. **디자이너와 협의** 후 추가
2. **네이밍 컨벤션** 준수
3. **다크모드 대응** 필수
4. **문서화** 업데이트

```swift
// 새로운 컬러 추가 예시
extension KingthereumColors {
    static let newSemanticColor = Color("NewSemanticColor")
}

// 새로운 타이포그래피 추가 예시
extension KingthereumTypography {
    static let newTextStyle = Font.custom("SpoqaHanSansNeo", size: 18)
        .weight(.medium)
}
```

이 디자인 시스템을 통해 일관된 사용자 경험과 브랜드 아이덴티티를 유지하며, 유지보수성과 확장성을 보장합니다.

