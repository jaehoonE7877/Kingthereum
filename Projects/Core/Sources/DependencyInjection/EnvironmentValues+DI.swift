import SwiftUI
import Factory

// MARK: - Factory SwiftUI Integration

/// Factory와 SwiftUI의 통합을 위한 유틸리티
/// Swift Concurrency 환경에서 안전한 의존성 관리 제공
public struct FactorySwiftUI {
    
    /// 테스트용 의존성 리셋
    /// 테스트 시작 시 호출하여 깨끗한 상태로 초기화
    /// - Note: 테스트 격리를 위해 각 테스트마다 호출 권장
    public static func resetForTesting() {
        Container.shared.reset()
    }
    
    // Network 서비스 해결 제거 (더이상 사용되지 않음)
    
    // HTTP 서비스 해결 제거 (더이상 사용되지 않음)
    
    // RPC 서비스 해결 제거 (더이상 사용되지 않음)
    
    /// async 환경에서 안전한 Configuration 서비스 접근
    public static func resolveConfigurationService() -> ConfigurationServiceProtocol {
        return Container.shared.resolveConfigurationService()
    }
}

// MARK: - Usage Examples & Documentation

/*
 
 === Factory DI 사용법 (Swift Concurrency 지원) ===
 
 1. 앱 시작 시 설정:
 ```swift
 @main
 struct KingtherumApp: App {
     
     init() {
         // Factory는 lazy 등록이므로 별도 초기화 불필요
         // 모든 서비스가 Sendable을 준수하여 Actor 간 안전한 전달 보장
     }
     
     var body: some Scene {
         WindowGroup {
             ContentView()
         }
     }
 }
 ```
 
 2. SwiftUI 뷰에서 의존성 사용:
 ```swift
 struct SomeView: View {
     @Injected(\.configurationService) private var configService
     @Injected(\.networkService) private var networkService
     
     var body: some View {
         // 뷰 구현 - 모든 주입된 서비스는 Sendable 준수
         VStack {
             Text("Network Service Ready")
         }
         .task {
             // async 컨텍스트에서도 안전하게 사용 가능
             do {
                 let data = try await networkService.performGETRequest(url: someURL)
                 // Handle data
             } catch {
                 // Handle error
             }
         }
     }
 }
 ```
 
 3. Clean Swift VIP에서 의존성 사용 (Actor 환경):
 ```swift
 // Interactor (Actor 기반)
 actor SomeInteractor: SomeBusinessLogic {
     private let networkService: NetworkServiceProtocol
     private let presenter: SomePresentationLogic
     
     init() {
         // Sendable 서비스들은 Actor 간 안전하게 전달 가능
         self.networkService = Container.shared.resolveNetworkService()
         self.presenter = Container.shared.resolvePresenterService()
     }
     
     func performSomeAction(request: SomeRequest) async {
         do {
             let result = try await networkService.performGETRequest(url: request.url)
             let response = SomeResponse(data: result)
             await presenter.presentResult(response: response)
         } catch {
             await presenter.presentError(error: error)
         }
     }
 }
 ```
 
 4. 일반 클래스에서 async 메서드 사용:
 ```swift
 final class SomeWorker: Sendable {
     private let httpService: HTTPServiceProtocol
     
     init() {
         // Sendable 보장으로 안전한 참조
         self.httpService = Container.shared.resolveHTTPService()
     }
     
     func fetchData() async throws -> Data {
         let url = URL(string: "https://api.example.com/data")!
         return try await httpService.performGETRequest(url: url)
     }
 }
 ```
 
 5. 테스트에서 Mock 의존성 사용:
 ```swift
 final class SomeTests: XCTestCase {
     override func setUp() {
         super.setUp()
         FactorySwiftUI.resetForTesting()
         
         // Mock 등록 (Sendable Mock 사용)
         Container.shared.networkService.register {
             MockNetworkService() // Sendable을 준수하는 Mock
         }
     }
     
     @Test("Network request success")
     func testNetworkRequest() async throws {
         let service = FactorySwiftUI.resolveNetworkService()
         let result = try await service.performGETRequest(url: testURL)
         #expect(result.isEmpty == false, "Data should not be empty")
     }
 }
 ```
 
 === Swift Concurrency 주요 특징 ===
 
 ✅ 모든 서비스가 Sendable 준수
 ✅ Actor 환경에서 안전한 의존성 주입
 ✅ async/await와 완벽 호환
 ✅ RequestCounter는 Actor로 구현되어 동시성 안전성 보장
 ✅ Factory 컨테이너의 thread-safe한 singleton 관리
 
 */
