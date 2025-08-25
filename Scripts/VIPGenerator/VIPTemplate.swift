#!/usr/bin/env swift

import Foundation

// MARK: - VIP Scene Generator

struct VIPSceneGenerator {
    let sceneName: String
    let useCases: [UseCase]
    let outputPath: String
    
    func generate() throws {
        print("🚀 Generating VIP Scene: \(sceneName)")
        
        try generateSceneModels()
        try generateInteractor()
        try generatePresenter()
        try generateWorker()
        try generateRouter()
        try generateView()
        
        print("✅ VIP Scene '\(sceneName)' generated successfully!")
        print("📁 Generated files:")
        print("   - Entity/Sources/Scenes/\(sceneName)Scene.swift")
        print("   - App/Sources/Scenes/\(sceneName)/\(sceneName)Interactor.swift")
        print("   - App/Sources/Scenes/\(sceneName)/\(sceneName)Presenter.swift")
        print("   - App/Sources/Scenes/\(sceneName)/\(sceneName)Worker.swift")
        print("   - App/Sources/Scenes/\(sceneName)/\(sceneName)Router.swift")
        print("   - App/Sources/Scenes/\(sceneName)/\(sceneName)View.swift")
    }
    
    private func generateSceneModels() throws {
        let template = SceneModelsTemplate(sceneName: sceneName, useCases: useCases)
        let content = template.generate()
        let filePath = "\(outputPath)/Projects/Entity/Sources/Scenes/\(sceneName)Scene.swift"
        
        try createDirectoryIfNeeded(filePath: filePath)
        try content.write(toFile: filePath, atomically: true, encoding: .utf8)
    }
    
    private func generateInteractor() throws {
        let template = InteractorTemplate(sceneName: sceneName, useCases: useCases)
        let content = template.generate()
        let filePath = "\(outputPath)/Projects/App/Sources/Scenes/\(sceneName)/\(sceneName)Interactor.swift"
        
        try createDirectoryIfNeeded(filePath: filePath)
        try content.write(toFile: filePath, atomically: true, encoding: .utf8)
    }
    
    private func generatePresenter() throws {
        let template = PresenterTemplate(sceneName: sceneName, useCases: useCases)
        let content = template.generate()
        let filePath = "\(outputPath)/Projects/App/Sources/Scenes/\(sceneName)/\(sceneName)Presenter.swift"
        
        try createDirectoryIfNeeded(filePath: filePath)
        try content.write(toFile: filePath, atomically: true, encoding: .utf8)
    }
    
    private func generateWorker() throws {
        let template = WorkerTemplate(sceneName: sceneName, useCases: useCases)
        let content = template.generate()
        let filePath = "\(outputPath)/Projects/App/Sources/Scenes/\(sceneName)/\(sceneName)Worker.swift"
        
        try createDirectoryIfNeeded(filePath: filePath)
        try content.write(toFile: filePath, atomically: true, encoding: .utf8)
    }
    
    private func generateRouter() throws {
        let template = RouterTemplate(sceneName: sceneName, useCases: useCases)
        let content = template.generate()
        let filePath = "\(outputPath)/Projects/App/Sources/Scenes/\(sceneName)/\(sceneName)Router.swift"
        
        try createDirectoryIfNeeded(filePath: filePath)
        try content.write(toFile: filePath, atomically: true, encoding: .utf8)
    }
    
    private func generateView() throws {
        let template = ViewTemplate(sceneName: sceneName, useCases: useCases)
        let content = template.generate()
        let filePath = "\(outputPath)/Projects/App/Sources/Scenes/\(sceneName)/\(sceneName)View.swift"
        
        try createDirectoryIfNeeded(filePath: filePath)
        try content.write(toFile: filePath, atomically: true, encoding: .utf8)
    }
    
    private func createDirectoryIfNeeded(filePath: String) throws {
        let directoryPath = (filePath as NSString).deletingLastPathComponent
        try FileManager.default.createDirectory(atPath: directoryPath, withIntermediateDirectories: true)
    }
}

// MARK: - Use Case Model

struct UseCase {
    let name: String
    let requestFields: [Field]
    let responseFields: [Field]
    let viewModelFields: [Field]
    
    init(name: String, requestFields: [Field] = [], responseFields: [Field] = [], viewModelFields: [Field] = []) {
        self.name = name
        self.requestFields = requestFields
        self.responseFields = responseFields
        self.viewModelFields = viewModelFields
    }
}

struct Field {
    let name: String
    let type: String
    let isOptional: Bool
    let defaultValue: String?
    
    init(name: String, type: String, isOptional: Bool = false, defaultValue: String? = nil) {
        self.name = name
        self.type = type
        self.isOptional = isOptional
        self.defaultValue = defaultValue
    }
    
    var declaration: String {
        let optionalMark = isOptional ? "?" : ""
        return "public let \(name): \(type)\(optionalMark)"
    }
    
    var initParameter: String {
        let optionalMark = isOptional ? "?" : ""
        if let defaultValue = defaultValue {
            return "\(name): \(type)\(optionalMark) = \(defaultValue)"
        }
        return "\(name): \(type)\(optionalMark)"
    }
    
    var initAssignment: String {
        return "self.\(name) = \(name)"
    }
}

// MARK: - Scene Models Template

struct SceneModelsTemplate {
    let sceneName: String
    let useCases: [UseCase]
    
    func generate() -> String {
        return """
import Foundation

public enum \(sceneName)Scene {
    
\(useCases.map { generateUseCase($0) }.joined(separator: "\n\n"))
}
"""
    }
    
    private func generateUseCase(_ useCase: UseCase) -> String {
        return """
    // MARK: - \(useCase.name)
    
    public enum \(useCase.name) {
        public struct Request {
\(useCase.requestFields.map { "            \($0.declaration)" }.joined(separator: "\n"))
            
            public init(
\(useCase.requestFields.map { "                \($0.initParameter)" }.joined(separator: ",\n"))
            ) {
\(useCase.requestFields.map { "                \($0.initAssignment)" }.joined(separator: "\n"))
            }
        }
        
        public struct Response {
\(useCase.responseFields.map { "            \($0.declaration)" }.joined(separator: "\n"))
            
            public init(
\(useCase.responseFields.map { "                \($0.initParameter)" }.joined(separator: ",\n"))
            ) {
\(useCase.responseFields.map { "                \($0.initAssignment)" }.joined(separator: "\n"))
            }
        }
        
        public struct ViewModel {
\(useCase.viewModelFields.map { "            \($0.declaration)" }.joined(separator: "\n"))
            
            public init(
\(useCase.viewModelFields.map { "                \($0.initParameter)" }.joined(separator: ",\n"))
            ) {
\(useCase.viewModelFields.map { "                \($0.initAssignment)" }.joined(separator: "\n"))
            }
        }
    }"""
    }
}

// MARK: - Interactor Template

struct InteractorTemplate {
    let sceneName: String
    let useCases: [UseCase]
    
    func generate() -> String {
        return """
import Foundation
import Entity
import Core
import Factory

@MainActor
protocol \(sceneName)BusinessLogic {
\(useCases.map { "    func \(camelCase($0.name))(request: \(sceneName)Scene.\($0.name).Request)" }.joined(separator: "\n"))
}

@MainActor
protocol \(sceneName)DataStore {
    var isLoading: Bool { get set }
    // Add your data store properties here
}

@MainActor
final class \(sceneName)Interactor: \(sceneName)BusinessLogic, \(sceneName)DataStore {
    var presenter: \(sceneName)PresentationLogic?
    private let worker: \(sceneName)WorkerProtocol
    
    // MARK: - Data Store
    var isLoading = false
    
    init(worker: \(sceneName)WorkerProtocol? = nil) {
        self.worker = worker ?? \(sceneName)Worker()
    }
    
    // MARK: - Business Logic
    
\(useCases.map { generateBusinessLogicMethod($0) }.joined(separator: "\n\n"))
}
"""
    }
    
    private func generateBusinessLogicMethod(_ useCase: UseCase) -> String {
        return """
    func \(camelCase(useCase.name))(request: \(sceneName)Scene.\(useCase.name).Request) {
        guard !isLoading else { return }
        
        isLoading = true
        
        Task { [weak self] in
            do {
                // TODO: Implement business logic
                // let result = try await self?.worker.perform\(useCase.name)(request)
                
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    
                    self.isLoading = false
                    
                    let response = \(sceneName)Scene.\(useCase.name).Response(
                        // TODO: Map worker result to response
                    )
                    self.presenter?.present\(useCase.name)(response: response)
                }
            } catch {
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    
                    self.isLoading = false
                    
                    let response = \(sceneName)Scene.\(useCase.name).Response(
                        // TODO: Handle error response
                    )
                    self.presenter?.present\(useCase.name)(response: response)
                }
            }
        }
    }"""
    }
    
    private func camelCase(_ string: String) -> String {
        return string.prefix(1).lowercased() + string.dropFirst()
    }
}

// MARK: - Presenter Template

struct PresenterTemplate {
    let sceneName: String
    let useCases: [UseCase]
    
    func generate() -> String {
        return """
import Foundation
import Entity
import Core

@MainActor
protocol \(sceneName)PresentationLogic {
\(useCases.map { "    func present\($0.name)(response: \(sceneName)Scene.\($0.name).Response)" }.joined(separator: "\n"))
}

@MainActor
final class \(sceneName)Presenter: \(sceneName)PresentationLogic {
    weak var viewController: \(sceneName)DisplayLogic?
    
    // MARK: - Formatters
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()
    
    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 8
        formatter.minimumFractionDigits = 0
        return formatter
    }()
    
    // MARK: - Presentation Logic
    
\(useCases.map { generatePresentationMethod($0) }.joined(separator: "\n\n"))
    
    // MARK: - Private Methods
    
    private func formatErrorMessage(_ error: Error) -> String {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .noConnection:
                return "인터넷 연결을 확인해주세요"
            case .timeout:
                return "요청 시간이 초과되었습니다"
            case .serverError:
                return "서버 오류가 발생했습니다"
            default:
                return "네트워크 오류가 발생했습니다"
            }
        }
        
        return error.localizedDescription
    }
}
"""
    }
    
    private func generatePresentationMethod(_ useCase: UseCase) -> String {
        return """
    func present\(useCase.name)(response: \(sceneName)Scene.\(useCase.name).Response) {
        // TODO: Format response data for display
        
        let viewModel = \(sceneName)Scene.\(useCase.name).ViewModel(
            // TODO: Map response to view model
        )
        
        viewController?.display\(useCase.name)(viewModel: viewModel)
    }"""
    }
}

// MARK: - Worker Template

struct WorkerTemplate {
    let sceneName: String
    let useCases: [UseCase]
    
    func generate() -> String {
        return """
import Foundation
import Entity
import Core

protocol \(sceneName)WorkerProtocol: Sendable {
\(useCases.map { "    func perform\($0.name)(_ request: \(sceneName)Scene.\($0.name).Request) async throws" }.joined(separator: "\n"))
}

actor \(sceneName)Worker: \(sceneName)WorkerProtocol {
    
    init() {
        // Initialize dependencies
    }
    
    // MARK: - Worker Methods
    
\(useCases.map { generateWorkerMethod($0) }.joined(separator: "\n\n"))
}
"""
    }
    
    private func generateWorkerMethod(_ useCase: UseCase) -> String {
        return """
    func perform\(useCase.name)(_ request: \(sceneName)Scene.\(useCase.name).Request) async throws {
        // TODO: Implement \(useCase.name) logic
        // This might involve:
        // - Network requests
        // - Database operations
        // - File system operations
        // - External service calls
        
        Logger.debug("Performing \(useCase.name) with request: \\(request)")
        
        // Example implementation:
        // try await networkService.performRequest(...)
    }"""
    }
}

// MARK: - Router Template

struct RouterTemplate {
    let sceneName: String
    let useCases: [UseCase]
    
    func generate() -> String {
        return """
import Foundation
import Entity
import Core

@MainActor
protocol \(sceneName)RoutingLogic {
    // TODO: Add routing methods
    func routeToHome()
    func routeToSettings()
}

@MainActor
protocol \(sceneName)DataPassing {
    var dataStore: \(sceneName)DataStore? { get }
}

@MainActor
final class \(sceneName)Router: StandardRouter<\(sceneName)DisplayLogic, \(sceneName)DataStore>, \(sceneName)RoutingLogic, \(sceneName)DataPassing {
    
    override init(sceneName: String? = nil) {
        super.init(sceneName: "\(sceneName)")
    }
    
    // MARK: - Routing Logic
    
    func routeToHome() {
        logNavigation(to: "Home")
        
        // TODO: Implement navigation to home
        NotificationCenter.default.post(
            name: NSNotification.Name("NavigateToHome"),
            object: nil
        )
    }
    
    func routeToSettings() {
        logNavigation(to: "Settings")
        
        // TODO: Implement navigation to settings
        // viewController?.navigateToSettings()
    }
}
"""
    }
}

// MARK: - View Template

struct ViewTemplate {
    let sceneName: String
    let useCases: [UseCase]
    
    func generate() -> String {
        return """
import SwiftUI
import DesignSystem
import Core
import Entity

protocol \(sceneName)DisplayLogic: AnyObject {
\(useCases.map { "    func display\($0.name)(viewModel: \(sceneName)Scene.\($0.name).ViewModel)" }.joined(separator: "\n"))
}

struct \(sceneName)View: View {
    @State private var viewStore = \(sceneName)ViewStore()
    @Binding var showTabBar: Bool
    
    init(showTabBar: Binding<Bool>) {
        self._showTabBar = showTabBar
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewStore.isLoading {
                    LoadingView(style: .spinner, size: .medium)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    contentView
                }
            }
            .navigationTitle("\(sceneName)")
            .navigationBarTitleDisplayMode(.large)
            .alert("알림", isPresented: Binding<Bool>(
                get: { viewStore.alertMessage != nil },
                set: { _ in viewStore.clearAlert() }
            )) {
                Button("확인") {
                    viewStore.clearAlert()
                }
            } message: {
                if let message = viewStore.alertMessage {
                    Text(message)
                }
            }
        }
        .onAppear {
            viewStore.setupVIP()
            viewStore.loadInitialData()
        }
    }
    
    private var contentView: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.xl) {
                // TODO: Add your UI components here
                
                Text("\\(sceneName) Scene")
                    .font(Typography.Heading.h2)
                    .foregroundColor(.primary)
                
                Button("Sample Action") {
                    viewStore.performSampleAction()
                }
                .buttonStyle(PrimaryButtonStyle())
                
                // 추가 스크롤 여백
                Color.clear.frame(height: 120)
            }
            .padding(DesignTokens.Spacing.lg)
        }
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y
        } action: { _, newValue in
            let threshold: CGFloat = 50
            withAnimation(.easeInOut(duration: 0.3)) {
                showTabBar = newValue < threshold
            }
        }
    }
}

// MARK: - ViewStore

@MainActor
@Observable
final class \(sceneName)ViewStore: \(sceneName)DisplayLogic {
    var isLoading = false
    var alertMessage: String?
    
    private var interactor: \(sceneName)BusinessLogic?
    private var router: \(sceneName)RoutingLogic?
    
    func setupVIP() {
        let interactor = \(sceneName)Interactor()
        let presenter = \(sceneName)Presenter()
        let router = \(sceneName)Router()
        
        interactor.presenter = presenter
        presenter.viewController = self
        router.viewController = self
        router.dataStore = interactor
        
        self.interactor = interactor
        self.router = router
    }
    
    func loadInitialData() {
        // TODO: Implement initial data loading
        // let request = \(sceneName)Scene.LoadData.Request()
        // interactor?.loadData(request: request)
    }
    
    func performSampleAction() {
        // TODO: Implement sample action
        alertMessage = "Sample action performed!"
    }
    
    func clearAlert() {
        alertMessage = nil
    }
    
    // MARK: - Display Logic
    
\(useCases.map { generateDisplayMethod($0) }.joined(separator: "\n\n"))
}
"""
    }
    
    private func generateDisplayMethod(_ useCase: UseCase) -> String {
        return """
    func display\(useCase.name)(viewModel: \(sceneName)Scene.\(useCase.name).ViewModel) {
        // TODO: Update UI based on view model
        
        if let errorMessage = viewModel.errorMessage {
            alertMessage = errorMessage
        }
    }"""
    }
}

// MARK: - CLI Interface

struct VIPGeneratorCLI {
    static func main() {
        let arguments = CommandLine.arguments
        
        guard arguments.count >= 2 else {
            printUsage()
            return
        }
        
        let command = arguments[1]
        
        switch command {
        case "generate", "g":
            handleGenerate(arguments: Array(arguments.dropFirst(2)))
        case "help", "-h", "--help":
            printUsage()
        case "examples":
            printExamples()
        default:
            print("❌ Unknown command: \(command)")
            printUsage()
        }
    }
    
    private static func handleGenerate(arguments: [String]) {
        guard arguments.count >= 1 else {
            print("❌ Scene name is required")
            printUsage()
            return
        }
        
        let sceneName = arguments[0]
        let outputPath = arguments.count >= 2 ? arguments[1] : FileManager.default.currentDirectoryPath
        
        // Default use cases for demonstration
        let defaultUseCases = [
            UseCase(
                name: "LoadData",
                requestFields: [Field(name: "id", type: "String")],
                responseFields: [
                    Field(name: "data", type: "SomeDataType"),
                    Field(name: "error", type: "Error", isOptional: true)
                ],
                viewModelFields: [
                    Field(name: "displayData", type: "String"),
                    Field(name: "errorMessage", type: "String", isOptional: true)
                ]
            ),
            UseCase(
                name: "UpdateData",
                requestFields: [
                    Field(name: "id", type: "String"),
                    Field(name: "newValue", type: "String")
                ],
                responseFields: [
                    Field(name: "success", type: "Bool"),
                    Field(name: "error", type: "Error", isOptional: true)
                ],
                viewModelFields: [
                    Field(name: "success", type: "Bool"),
                    Field(name: "successMessage", type: "String", isOptional: true),
                    Field(name: "errorMessage", type: "String", isOptional: true)
                ]
            )
        ]
        
        let generator = VIPSceneGenerator(
            sceneName: sceneName,
            useCases: defaultUseCases,
            outputPath: outputPath
        )
        
        do {
            try generator.generate()
        } catch {
            print("❌ Failed to generate VIP scene: \(error)")
        }
    }
    
    private static func printUsage() {
        print("""
        🏗️  VIP Scene Generator
        
        USAGE:
            swift VIPTemplate.swift generate <SceneName> [OutputPath]
            swift VIPTemplate.swift examples
            swift VIPTemplate.swift help
        
        ARGUMENTS:
            SceneName    The name of the VIP scene to generate
            OutputPath   The output directory (default: current directory)
        
        EXAMPLES:
            swift VIPTemplate.swift generate Profile
            swift VIPTemplate.swift generate UserManagement ~/Projects/MyApp
        """)
    }
    
    private static func printExamples() {
        print("""
        📚 VIP Generator Examples:
        
        1. Generate a simple Profile scene:
           swift VIPTemplate.swift generate Profile
        
        2. Generate a UserManagement scene in specific directory:
           swift VIPTemplate.swift generate UserManagement ~/Projects/MyApp
        
        3. Generated structure:
           Profile/
           ├── ProfileInteractor.swift
           ├── ProfilePresenter.swift
           ├── ProfileRouter.swift
           ├── ProfileView.swift
           ├── ProfileWorker.swift
           └── ProfileScene.swift (in Entity module)
        
        4. Customize use cases by editing the VIPTemplate.swift file
        """)
    }
}

// MARK: - Main Entry Point

if CommandLine.argc > 0 {
    VIPGeneratorCLI.main()
}