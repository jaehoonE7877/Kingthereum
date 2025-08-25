#!/usr/bin/env swift

import Foundation

// MARK: - Configurable VIP Generator

struct ConfigurableVIPGenerator {
    let config: VIPSceneConfig
    let outputPath: String
    
    init(config: VIPSceneConfig, outputPath: String) {
        self.config = config
        self.outputPath = outputPath
    }
    
    func generate() throws {
        print("🚀 Generating VIP Scene: \(config.sceneName)")
        print("📋 Use Cases: \(config.useCases.map(\.name).joined(separator: ", "))")
        
        try generateFromConfig()
        
        print("✅ VIP Scene '\(config.sceneName)' generated successfully!")
        printGeneratedFiles()
    }
    
    private func generateFromConfig() throws {
        if config.generateSceneModels {
            try generateSceneModels()
        }
        
        if config.generateInteractor {
            try generateInteractor()
        }
        
        if config.generatePresenter {
            try generatePresenter()
        }
        
        if config.generateWorker {
            try generateWorker()
        }
        
        if config.generateRouter {
            try generateRouter()
        }
        
        if config.generateView {
            try generateView()
        }
        
        if config.generateTests {
            try generateTests()
        }
    }
    
    private func generateSceneModels() throws {
        let template = ConfigurableSceneModelsTemplate(config: config)
        let content = template.generate()
        let filePath = "\(outputPath)/Projects/Entity/Sources/Scenes/\(config.sceneName)Scene.swift"
        
        try createDirectoryIfNeeded(filePath: filePath)
        try content.write(toFile: filePath, atomically: true, encoding: .utf8)
    }
    
    private func generateInteractor() throws {
        let template = ConfigurableInteractorTemplate(config: config)
        let content = template.generate()
        let filePath = "\(outputPath)/Projects/App/Sources/Scenes/\(config.sceneName)/\(config.sceneName)Interactor.swift"
        
        try createDirectoryIfNeeded(filePath: filePath)
        try content.write(toFile: filePath, atomically: true, encoding: .utf8)
    }
    
    private func generatePresenter() throws {
        let template = ConfigurablePresenterTemplate(config: config)
        let content = template.generate()
        let filePath = "\(outputPath)/Projects/App/Sources/Scenes/\(config.sceneName)/\(config.sceneName)Presenter.swift"
        
        try createDirectoryIfNeeded(filePath: filePath)
        try content.write(toFile: filePath, atomically: true, encoding: .utf8)
    }
    
    private func generateWorker() throws {
        let template = ConfigurableWorkerTemplate(config: config)
        let content = template.generate()
        let filePath = "\(outputPath)/Projects/App/Sources/Scenes/\(config.sceneName)/\(config.sceneName)Worker.swift"
        
        try createDirectoryIfNeeded(filePath: filePath)
        try content.write(toFile: filePath, atomically: true, encoding: .utf8)
    }
    
    private func generateRouter() throws {
        let template = ConfigurableRouterTemplate(config: config)
        let content = template.generate()
        let filePath = "\(outputPath)/Projects/App/Sources/Scenes/\(config.sceneName)/\(config.sceneName)Router.swift"
        
        try createDirectoryIfNeeded(filePath: filePath)
        try content.write(toFile: filePath, atomically: true, encoding: .utf8)
    }
    
    private func generateView() throws {
        let template = ConfigurableViewTemplate(config: config)
        let content = template.generate()
        let filePath = "\(outputPath)/Projects/App/Sources/Scenes/\(config.sceneName)/\(config.sceneName)View.swift"
        
        try createDirectoryIfNeeded(filePath: filePath)
        try content.write(toFile: filePath, atomically: true, encoding: .utf8)
    }
    
    private func generateTests() throws {
        let template = TestTemplate(config: config)
        let content = template.generate()
        let filePath = "\(outputPath)/Projects/App/Tests/Scenes/\(config.sceneName)/\(config.sceneName)Tests.swift"
        
        try createDirectoryIfNeeded(filePath: filePath)
        try content.write(toFile: filePath, atomically: true, encoding: .utf8)
    }
    
    private func createDirectoryIfNeeded(filePath: String) throws {
        let directoryPath = (filePath as NSString).deletingLastPathComponent
        try FileManager.default.createDirectory(atPath: directoryPath, withIntermediateDirectories: true)
    }
    
    private func printGeneratedFiles() {
        print("📁 Generated files:")
        
        if config.generateSceneModels {
            print("   ✓ Entity/Sources/Scenes/\(config.sceneName)Scene.swift")
        }
        if config.generateInteractor {
            print("   ✓ App/Sources/Scenes/\(config.sceneName)/\(config.sceneName)Interactor.swift")
        }
        if config.generatePresenter {
            print("   ✓ App/Sources/Scenes/\(config.sceneName)/\(config.sceneName)Presenter.swift")
        }
        if config.generateWorker {
            print("   ✓ App/Sources/Scenes/\(config.sceneName)/\(config.sceneName)Worker.swift")
        }
        if config.generateRouter {
            print("   ✓ App/Sources/Scenes/\(config.sceneName)/\(config.sceneName)Router.swift")
        }
        if config.generateView {
            print("   ✓ App/Sources/Scenes/\(config.sceneName)/\(config.sceneName)View.swift")
        }
        if config.generateTests {
            print("   ✓ App/Tests/Scenes/\(config.sceneName)/\(config.sceneName)Tests.swift")
        }
    }
}

// MARK: - VIP Scene Configuration

struct VIPSceneConfig: Codable {
    let sceneName: String
    let useCases: [ConfigurableUseCase]
    let options: GenerationOptions
    let imports: [String]
    let dataStoreProperties: [DataStoreProperty]
    let routingMethods: [RoutingMethod]
    
    var generateSceneModels: Bool { options.generateSceneModels }
    var generateInteractor: Bool { options.generateInteractor }
    var generatePresenter: Bool { options.generatePresenter }
    var generateWorker: Bool { options.generateWorker }
    var generateRouter: Bool { options.generateRouter }
    var generateView: Bool { options.generateView }
    var generateTests: Bool { options.generateTests }
    
    init(
        sceneName: String,
        useCases: [ConfigurableUseCase] = [],
        options: GenerationOptions = GenerationOptions(),
        imports: [String] = ["Foundation", "Entity", "Core"],
        dataStoreProperties: [DataStoreProperty] = [],
        routingMethods: [RoutingMethod] = []
    ) {
        self.sceneName = sceneName
        self.useCases = useCases
        self.options = options
        self.imports = imports
        self.dataStoreProperties = dataStoreProperties
        self.routingMethods = routingMethods
    }
}

struct GenerationOptions: Codable {
    let generateSceneModels: Bool
    let generateInteractor: Bool
    let generatePresenter: Bool
    let generateWorker: Bool
    let generateRouter: Bool
    let generateView: Bool
    let generateTests: Bool
    let useSwiftUI: Bool
    let includeFormatters: Bool
    let includeLogging: Bool
    
    init(
        generateSceneModels: Bool = true,
        generateInteractor: Bool = true,
        generatePresenter: Bool = true,
        generateWorker: Bool = true,
        generateRouter: Bool = true,
        generateView: Bool = true,
        generateTests: Bool = true,
        useSwiftUI: Bool = true,
        includeFormatters: Bool = true,
        includeLogging: Bool = true
    ) {
        self.generateSceneModels = generateSceneModels
        self.generateInteractor = generateInteractor
        self.generatePresenter = generatePresenter
        self.generateWorker = generateWorker
        self.generateRouter = generateRouter
        self.generateView = generateView
        self.generateTests = generateTests
        self.useSwiftUI = useSwiftUI
        self.includeFormatters = includeFormatters
        self.includeLogging = includeLogging
    }
}

struct ConfigurableUseCase: Codable {
    let name: String
    let requestFields: [ConfigurableField]
    let responseFields: [ConfigurableField]
    let viewModelFields: [ConfigurableField]
    let isAsyncOperation: Bool
    let requiresNetwork: Bool
    let requiresDatabase: Bool
    
    init(
        name: String,
        requestFields: [ConfigurableField] = [],
        responseFields: [ConfigurableField] = [],
        viewModelFields: [ConfigurableField] = [],
        isAsyncOperation: Bool = true,
        requiresNetwork: Bool = false,
        requiresDatabase: Bool = false
    ) {
        self.name = name
        self.requestFields = requestFields
        self.responseFields = responseFields
        self.viewModelFields = viewModelFields
        self.isAsyncOperation = isAsyncOperation
        self.requiresNetwork = requiresNetwork
        self.requiresDatabase = requiresDatabase
    }
}

struct ConfigurableField: Codable {
    let name: String
    let type: String
    let isOptional: Bool
    let defaultValue: String?
    let isPublic: Bool
    let comment: String?
    
    init(
        name: String,
        type: String,
        isOptional: Bool = false,
        defaultValue: String? = nil,
        isPublic: Bool = true,
        comment: String? = nil
    ) {
        self.name = name
        self.type = type
        self.isOptional = isOptional
        self.defaultValue = defaultValue
        self.isPublic = isPublic
        self.comment = comment
    }
    
    var declaration: String {
        let accessLevel = isPublic ? "public " : ""
        let optionalMark = isOptional ? "?" : ""
        let commentLine = comment.map { "            /// \($0)\n" } ?? ""
        return "\(commentLine)\(accessLevel)let \(name): \(type)\(optionalMark)"
    }
}

struct DataStoreProperty: Codable {
    let name: String
    let type: String
    let initialValue: String?
    let isPublished: Bool
    
    init(name: String, type: String, initialValue: String? = nil, isPublished: Bool = false) {
        self.name = name
        self.type = type
        self.initialValue = initialValue
        self.isPublished = isPublished
    }
}

struct RoutingMethod: Codable {
    let name: String
    let destination: String
    let parameters: [String]
    
    init(name: String, destination: String, parameters: [String] = []) {
        self.name = name
        self.destination = destination
        self.parameters = parameters
    }
}

// MARK: - Configurable Templates

struct ConfigurableSceneModelsTemplate {
    let config: VIPSceneConfig
    
    func generate() -> String {
        let imports = config.imports.map { "import \($0)" }.joined(separator: "\n")
        
        return """
\(imports)

public enum \(config.sceneName)Scene {
    
\(config.useCases.map { generateUseCase($0) }.joined(separator: "\n\n"))
}
"""
    }
    
    private func generateUseCase(_ useCase: ConfigurableUseCase) -> String {
        return """
    // MARK: - \(useCase.name)
    
    public enum \(useCase.name) {
        public struct Request {
\(useCase.requestFields.map { "            \($0.declaration)" }.joined(separator: "\n"))
            
            public init(
\(useCase.requestFields.map { generateInitParameter($0) }.joined(separator: ",\n"))
            ) {
\(useCase.requestFields.map { "                self.\($0.name) = \($0.name)" }.joined(separator: "\n"))
            }
        }
        
        public struct Response {
\(useCase.responseFields.map { "            \($0.declaration)" }.joined(separator: "\n"))
            
            public init(
\(useCase.responseFields.map { generateInitParameter($0) }.joined(separator: ",\n"))
            ) {
\(useCase.responseFields.map { "                self.\($0.name) = \($0.name)" }.joined(separator: "\n"))
            }
        }
        
        public struct ViewModel {
\(useCase.viewModelFields.map { "            \($0.declaration)" }.joined(separator: "\n"))
            
            public init(
\(useCase.viewModelFields.map { generateInitParameter($0) }.joined(separator: ",\n"))
            ) {
\(useCase.viewModelFields.map { "                self.\($0.name) = \($0.name)" }.joined(separator: "\n"))
            }
        }
    }"""
    }
    
    private func generateInitParameter(_ field: ConfigurableField) -> String {
        let optionalMark = field.isOptional ? "?" : ""
        if let defaultValue = field.defaultValue {
            return "                \(field.name): \(field.type)\(optionalMark) = \(defaultValue)"
        }
        return "                \(field.name): \(field.type)\(optionalMark)"
    }
}

struct ConfigurableInteractorTemplate {
    let config: VIPSceneConfig
    
    func generate() -> String {
        let imports = config.imports.map { "import \($0)" }.joined(separator: "\n")
        
        return """
\(imports)
import Factory

@MainActor
protocol \(config.sceneName)BusinessLogic {
\(config.useCases.map { "    func \(camelCase($0.name))(request: \(config.sceneName)Scene.\($0.name).Request)" }.joined(separator: "\n"))
}

@MainActor
protocol \(config.sceneName)DataStore {
    var isLoading: Bool { get set }
\(config.dataStoreProperties.map { generateDataStoreProperty($0) }.joined(separator: "\n"))
}

@MainActor
final class \(config.sceneName)Interactor: \(config.sceneName)BusinessLogic, \(config.sceneName)DataStore {
    var presenter: \(config.sceneName)PresentationLogic?
    private let worker: \(config.sceneName)WorkerProtocol
    
    // MARK: - Data Store
    var isLoading = false
\(config.dataStoreProperties.map { generateDataStoreImplementation($0) }.joined(separator: "\n"))
    
    init(worker: \(config.sceneName)WorkerProtocol? = nil) {
        self.worker = worker ?? \(config.sceneName)Worker()
    }
    
    // MARK: - Business Logic
    
\(config.useCases.map { generateBusinessLogicMethod($0) }.joined(separator: "\n\n"))
}
"""
    }
    
    private func generateDataStoreProperty(_ property: DataStoreProperty) -> String {
        return "    var \(property.name): \(property.type) { get set }"
    }
    
    private func generateDataStoreImplementation(_ property: DataStoreProperty) -> String {
        if let initialValue = property.initialValue {
            return "    var \(property.name): \(property.type) = \(initialValue)"
        }
        return "    var \(property.name): \(property.type)"
    }
    
    private func generateBusinessLogicMethod(_ useCase: ConfigurableUseCase) -> String {
        if useCase.isAsyncOperation {
            return generateAsyncBusinessLogicMethod(useCase)
        } else {
            return generateSyncBusinessLogicMethod(useCase)
        }
    }
    
    private func generateAsyncBusinessLogicMethod(_ useCase: ConfigurableUseCase) -> String {
        return """
    func \(camelCase(useCase.name))(request: \(config.sceneName)Scene.\(useCase.name).Request) {
        guard !isLoading else { return }
        
        isLoading = true
        
        Task { [weak self] in
            do {\(config.options.includeLogging ? "\n                Logger.debug(\"Starting \(useCase.name) with request: \\(request)\")" : "")
                
                let result = try await self?.worker.perform\(useCase.name)(request)
                
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    
                    self.isLoading = false
                    
                    let response = \(config.sceneName)Scene.\(useCase.name).Response(
                        // TODO: Map worker result to response
                    )
                    self.presenter?.present\(useCase.name)(response: response)
                }
            } catch {
                await MainActor.run { [weak self] in
                    guard let self = self else { return }\(config.options.includeLogging ? "\n                    Logger.error(\"Failed \(useCase.name): \\(error)\")" : "")
                    
                    self.isLoading = false
                    
                    let response = \(config.sceneName)Scene.\(useCase.name).Response(
                        // TODO: Handle error response
                    )
                    self.presenter?.present\(useCase.name)(response: response)
                }
            }
        }
    }"""
    }
    
    private func generateSyncBusinessLogicMethod(_ useCase: ConfigurableUseCase) -> String {
        return """
    func \(camelCase(useCase.name))(request: \(config.sceneName)Scene.\(useCase.name).Request) {\(config.options.includeLogging ? "\n        Logger.debug(\"Processing \(useCase.name) with request: \\(request)\")" : "")
        
        // TODO: Implement synchronous business logic
        
        let response = \(config.sceneName)Scene.\(useCase.name).Response(
            // TODO: Create response
        )
        presenter?.present\(useCase.name)(response: response)
    }"""
    }
    
    private func camelCase(_ string: String) -> String {
        return string.prefix(1).lowercased() + string.dropFirst()
    }
}

struct ConfigurablePresenterTemplate {
    let config: VIPSceneConfig
    
    func generate() -> String {
        let imports = config.imports.map { "import \($0)" }.joined(separator: "\n")
        let formatters = config.options.includeFormatters ? generateFormatters() : ""
        
        return """
\(imports)

@MainActor
protocol \(config.sceneName)PresentationLogic {
\(config.useCases.map { "    func present\($0.name)(response: \(config.sceneName)Scene.\($0.name).Response)" }.joined(separator: "\n"))
}

@MainActor
final class \(config.sceneName)Presenter: \(config.sceneName)PresentationLogic {
    weak var viewController: \(config.sceneName)DisplayLogic?
    
\(formatters)
    // MARK: - Presentation Logic
    
\(config.useCases.map { generatePresentationMethod($0) }.joined(separator: "\n\n"))
    
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
    
    private func generateFormatters() -> String {
        return """
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
    
"""
    }
    
    private func generatePresentationMethod(_ useCase: ConfigurableUseCase) -> String {
        return """
    func present\(useCase.name)(response: \(config.sceneName)Scene.\(useCase.name).Response) {
        // TODO: Format response data for display
        
        let viewModel = \(config.sceneName)Scene.\(useCase.name).ViewModel(
            // TODO: Map response to view model
        )
        
        viewController?.display\(useCase.name)(viewModel: viewModel)
    }"""
    }
}

struct ConfigurableWorkerTemplate {
    let config: VIPSceneConfig
    
    func generate() -> String {
        let imports = config.imports.map { "import \($0)" }.joined(separator: "\n")
        
        return """
\(imports)

protocol \(config.sceneName)WorkerProtocol: Sendable {
\(config.useCases.map { generateWorkerProtocolMethod($0) }.joined(separator: "\n"))
}

actor \(config.sceneName)Worker: \(config.sceneName)WorkerProtocol {
    
    init() {
        // Initialize dependencies
    }
    
    // MARK: - Worker Methods
    
\(config.useCases.map { generateWorkerMethod($0) }.joined(separator: "\n\n"))
}
"""
    }
    
    private func generateWorkerProtocolMethod(_ useCase: ConfigurableUseCase) -> String {
        if useCase.isAsyncOperation {
            return "    func perform\(useCase.name)(_ request: \(config.sceneName)Scene.\(useCase.name).Request) async throws"
        } else {
            return "    func perform\(useCase.name)(_ request: \(config.sceneName)Scene.\(useCase.name).Request) throws"
        }
    }
    
    private func generateWorkerMethod(_ useCase: ConfigurableUseCase) -> String {
        let asyncKeyword = useCase.isAsyncOperation ? "async " : ""
        let networkComment = useCase.requiresNetwork ? "\n        // Network request implementation needed" : ""
        let databaseComment = useCase.requiresDatabase ? "\n        // Database operation implementation needed" : ""
        
        return """
    func perform\(useCase.name)(_ request: \(config.sceneName)Scene.\(useCase.name).Request) \(asyncKeyword)throws {\(config.options.includeLogging ? "\n        Logger.debug(\"Performing \(useCase.name) with request: \\(request)\")" : "")\(networkComment)\(databaseComment)
        
        // TODO: Implement \(useCase.name) logic
        // This might involve:
        // - Network requests\(useCase.requiresNetwork ? " ✓" : "")
        // - Database operations\(useCase.requiresDatabase ? " ✓" : "")
        // - File system operations
        // - External service calls
        
        // Example implementation:
        // try await networkService.performRequest(...)
    }"""
    }
}

struct ConfigurableRouterTemplate {
    let config: VIPSceneConfig
    
    func generate() -> String {
        let imports = config.imports.map { "import \($0)" }.joined(separator: "\n")
        let routingMethods = config.routingMethods.isEmpty ? defaultRoutingMethods() : config.routingMethods
        
        return """
\(imports)

@MainActor
protocol \(config.sceneName)RoutingLogic {
\(routingMethods.map { "    func \($0.name)()" }.joined(separator: "\n"))
}

@MainActor
protocol \(config.sceneName)DataPassing {
    var dataStore: \(config.sceneName)DataStore? { get }
}

@MainActor
final class \(config.sceneName)Router: StandardRouter<\(config.sceneName)DisplayLogic, \(config.sceneName)DataStore>, \(config.sceneName)RoutingLogic, \(config.sceneName)DataPassing {
    
    override init(sceneName: String? = nil) {
        super.init(sceneName: "\(config.sceneName)")
    }
    
    // MARK: - Routing Logic
    
\(routingMethods.map { generateRoutingMethod($0) }.joined(separator: "\n\n"))
}
"""
    }
    
    private func defaultRoutingMethods() -> [RoutingMethod] {
        return [
            RoutingMethod(name: "routeToHome", destination: "Home"),
            RoutingMethod(name: "routeToSettings", destination: "Settings")
        ]
    }
    
    private func generateRoutingMethod(_ method: RoutingMethod) -> String {
        return """
    func \(method.name)() {
        logNavigation(to: "\(method.destination)")
        
        // TODO: Implement navigation to \(method.destination)
        // viewController?.navigateTo\(method.destination)()
    }"""
    }
}

struct ConfigurableViewTemplate {
    let config: VIPSceneConfig
    
    func generate() -> String {
        if config.options.useSwiftUI {
            return generateSwiftUIView()
        } else {
            return generateUIKitView()
        }
    }
    
    private func generateSwiftUIView() -> String {
        let imports = (config.imports + ["SwiftUI", "DesignSystem"]).map { "import \($0)" }.joined(separator: "\n")
        
        return """
\(imports)

protocol \(config.sceneName)DisplayLogic: AnyObject {
\(config.useCases.map { "    func display\($0.name)(viewModel: \(config.sceneName)Scene.\($0.name).ViewModel)" }.joined(separator: "\n"))
}

struct \(config.sceneName)View: View {
    @StateObject private var viewModel = \(config.sceneName)ViewModel()
    @Binding var showTabBar: Bool
    
    init(showTabBar: Binding<Bool>) {
        self._showTabBar = showTabBar
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    LoadingView(style: .spinner, size: .medium)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    contentView
                }
            }
            .navigationTitle("\(config.sceneName)")
            .navigationBarTitleDisplayMode(.large)
            .alert("알림", isPresented: Binding<Bool>(
                get: { viewModel.alertMessage != nil },
                set: { _ in viewModel.clearAlert() }
            )) {
                Button("확인") {
                    viewModel.clearAlert()
                }
            } message: {
                if let message = viewModel.alertMessage {
                    Text(message)
                }
            }
        }
        .onAppear {
            viewModel.setupVIP()
            viewModel.loadInitialData()
        }
    }
    
    private var contentView: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.xl) {
                // TODO: Add your UI components here
                
                Text("\\(config.sceneName) Scene")
                    .font(Typography.Heading.h2)
                    .foregroundColor(.primary)
                
                Button("Sample Action") {
                    viewModel.performSampleAction()
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

// MARK: - ViewModel

@MainActor
final class \(config.sceneName)ViewModel: ObservableObject, \(config.sceneName)DisplayLogic {
    @Published var isLoading = false
    @Published var alertMessage: String?
\(config.dataStoreProperties.filter(\.isPublished).map { generatePublishedProperty($0) }.joined(separator: "\n"))
    
    private var interactor: \(config.sceneName)BusinessLogic?
    private var router: \(config.sceneName)RoutingLogic?
    
    func setupVIP() {
        let interactor = \(config.sceneName)Interactor()
        let presenter = \(config.sceneName)Presenter()
        let router = \(config.sceneName)Router()
        
        interactor.presenter = presenter
        presenter.viewController = self
        router.viewController = self
        router.dataStore = interactor
        
        self.interactor = interactor
        self.router = router
    }
    
    func loadInitialData() {
        // TODO: Implement initial data loading
        // let request = \(config.sceneName)Scene.LoadData.Request()
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
    
\(config.useCases.map { generateDisplayMethod($0) }.joined(separator: "\n\n"))
}
"""
    }
    
    private func generateUIKitView() -> String {
        // UIKit implementation
        return "// UIKit implementation not yet supported"
    }
    
    private func generatePublishedProperty(_ property: DataStoreProperty) -> String {
        if let initialValue = property.initialValue {
            return "    @Published var \(property.name): \(property.type) = \(initialValue)"
        }
        return "    @Published var \(property.name): \(property.type)"
    }
    
    private func generateDisplayMethod(_ useCase: ConfigurableUseCase) -> String {
        return """
    func display\(useCase.name)(viewModel: \(config.sceneName)Scene.\(useCase.name).ViewModel) {
        // TODO: Update UI based on view model
        
        if let errorMessage = viewModel.errorMessage {
            alertMessage = errorMessage
        }
    }"""
    }
}

struct TestTemplate {
    let config: VIPSceneConfig
    
    func generate() -> String {
        let imports = (config.imports + ["Testing"]).map { "import \($0)" }.joined(separator: "\n")
        
        return """
\(imports)
@testable import Scenes

// MARK: - \(config.sceneName) Tests

@Suite("\(config.sceneName) VIP Tests")
struct \(config.sceneName)Tests {
    
    // MARK: - Spy Classes
    
    class PresentationLogicSpy: \(config.sceneName)PresentationLogic {
\(config.useCases.map { generateSpyProperty($0) }.joined(separator: "\n"))
        
\(config.useCases.map { generateSpyMethod($0) }.joined(separator: "\n\n"))
    }
    
    class WorkerSpy: \(config.sceneName)WorkerProtocol {
\(config.useCases.map { generateWorkerSpyProperty($0) }.joined(separator: "\n"))
        
\(config.useCases.map { generateWorkerSpyMethod($0) }.joined(separator: "\n\n"))
    }
    
    // MARK: - Interactor Tests
    
    @Suite("Interactor")
    struct InteractorTests {
        
\(config.useCases.map { generateInteractorTest($0) }.joined(separator: "\n\n"))
    }
    
    // MARK: - Presenter Tests
    
    @Suite("Presenter")
    struct PresenterTests {
        
\(config.useCases.map { generatePresenterTest($0) }.joined(separator: "\n\n"))
    }
}
"""
    }
    
    private func generateSpyProperty(_ useCase: ConfigurableUseCase) -> String {
        return """
        var present\(useCase.name)Called = false
        var present\(useCase.name)Response: \(config.sceneName)Scene.\(useCase.name).Response?"""
    }
    
    private func generateSpyMethod(_ useCase: ConfigurableUseCase) -> String {
        return """
        func present\(useCase.name)(response: \(config.sceneName)Scene.\(useCase.name).Response) {
            present\(useCase.name)Called = true
            present\(useCase.name)Response = response
        }"""
    }
    
    private func generateWorkerSpyProperty(_ useCase: ConfigurableUseCase) -> String {
        return "        var perform\(useCase.name)Called = false"
    }
    
    private func generateWorkerSpyMethod(_ useCase: ConfigurableUseCase) -> String {
        let asyncKeyword = useCase.isAsyncOperation ? "async " : ""
        return """
        func perform\(useCase.name)(_ request: \(config.sceneName)Scene.\(useCase.name).Request) \(asyncKeyword)throws {
            perform\(useCase.name)Called = true
        }"""
    }
    
    private func generateInteractorTest(_ useCase: ConfigurableUseCase) -> String {
        let testName = camelCase(useCase.name)
        return """
        @Test("\(useCase.name) - 성공 케이스")
        func test\(useCase.name)Success() async {
            // Given
            let presenterSpy = PresentationLogicSpy()
            let workerSpy = WorkerSpy()
            
            let sut = \(config.sceneName)Interactor(worker: workerSpy)
            sut.presenter = presenterSpy
            
            let request = \(config.sceneName)Scene.\(useCase.name).Request(
                // TODO: Add request parameters
            )
            
            // When
            \(useCase.isAsyncOperation ? "await " : "")sut.\(testName)(request: request)
            
            // Then
            #expect(workerSpy.perform\(useCase.name)Called == true, "Worker가 호출되어야 함")
            #expect(presenterSpy.present\(useCase.name)Called == true, "Presenter가 호출되어야 함")
        }"""
    }
    
    private func generatePresenterTest(_ useCase: ConfigurableUseCase) -> String {
        return """
        @Test("\(useCase.name) 표시 - 성공 케이스")
        func testPresent\(useCase.name)Success() {
            // Given
            let displayLogicSpy = DisplayLogicSpy()
            let sut = \(config.sceneName)Presenter()
            sut.viewController = displayLogicSpy
            
            let response = \(config.sceneName)Scene.\(useCase.name).Response(
                // TODO: Add response parameters
            )
            
            // When
            sut.present\(useCase.name)(response: response)
            
            // Then
            #expect(displayLogicSpy.display\(useCase.name)Called == true, "Display가 호출되어야 함")
        }"""
    }
    
    private func camelCase(_ string: String) -> String {
        return string.prefix(1).lowercased() + string.dropFirst()
    }
}

// MARK: - Configuration File Manager

struct VIPConfigManager {
    static func loadConfig(from path: String) throws -> VIPSceneConfig {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let decoder = JSONDecoder()
        return try decoder.decode(VIPSceneConfig.self, from: data)
    }
    
    static func saveConfig(_ config: VIPSceneConfig, to path: String) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(config)
        try data.write(to: URL(fileURLWithPath: path))
    }
    
    static func createSampleConfig(sceneName: String) -> VIPSceneConfig {
        return VIPSceneConfig(
            sceneName: sceneName,
            useCases: [
                ConfigurableUseCase(
                    name: "LoadData",
                    requestFields: [
                        ConfigurableField(name: "id", type: "String", comment: "Unique identifier for the data")
                    ],
                    responseFields: [
                        ConfigurableField(name: "data", type: "SomeDataType"),
                        ConfigurableField(name: "error", type: "Error", isOptional: true)
                    ],
                    viewModelFields: [
                        ConfigurableField(name: "displayData", type: "String"),
                        ConfigurableField(name: "errorMessage", type: "String", isOptional: true)
                    ],
                    requiresNetwork: true
                )
            ],
            dataStoreProperties: [
                DataStoreProperty(name: "currentData", type: "SomeDataType", isPublished: true),
                DataStoreProperty(name: "isRefreshing", type: "Bool", initialValue: "false", isPublished: true)
            ],
            routingMethods: [
                RoutingMethod(name: "routeToDetail", destination: "Detail"),
                RoutingMethod(name: "routeToSettings", destination: "Settings")
            ]
        )
    }
}

// MARK: - CLI Interface

struct ConfigurableVIPCLI {
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
        case "config":
            handleConfig(arguments: Array(arguments.dropFirst(2)))
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
            print("❌ Configuration file path is required")
            printUsage()
            return
        }
        
        let configPath = arguments[0]
        let outputPath = arguments.count >= 2 ? arguments[1] : FileManager.default.currentDirectoryPath
        
        do {
            let config = try VIPConfigManager.loadConfig(from: configPath)
            let generator = ConfigurableVIPGenerator(config: config, outputPath: outputPath)
            try generator.generate()
        } catch {
            print("❌ Failed to generate VIP scene: \(error)")
        }
    }
    
    private static func handleConfig(arguments: [String]) {
        guard arguments.count >= 2 else {
            print("❌ Usage: config <create|sample> <sceneName> [outputPath]")
            return
        }
        
        let subcommand = arguments[0]
        let sceneName = arguments[1]
        let outputPath = arguments.count >= 3 ? arguments[2] : "./\(sceneName.lowercased())-config.json"
        
        switch subcommand {
        case "create", "sample":
            do {
                let config = VIPConfigManager.createSampleConfig(sceneName: sceneName)
                try VIPConfigManager.saveConfig(config, to: outputPath)
                print("✅ Sample configuration created: \(outputPath)")
                print("💡 Edit the configuration file and run: swift ConfigurableVIPGenerator.swift generate \(outputPath)")
            } catch {
                print("❌ Failed to create configuration: \(error)")
            }
        default:
            print("❌ Unknown config subcommand: \(subcommand)")
        }
    }
    
    private static func printUsage() {
        print("""
        🏗️  Configurable VIP Generator
        
        USAGE:
            swift ConfigurableVIPGenerator.swift generate <ConfigPath> [OutputPath]
            swift ConfigurableVIPGenerator.swift config sample <SceneName> [ConfigPath]
            swift ConfigurableVIPGenerator.swift help
            swift ConfigurableVIPGenerator.swift examples
        
        COMMANDS:
            generate     Generate VIP scene from configuration file
            config       Create or manage configuration files
            help         Show this help message
            examples     Show usage examples
        
        EXAMPLES:
            swift ConfigurableVIPGenerator.swift config sample Profile
            swift ConfigurableVIPGenerator.swift generate profile-config.json ~/Projects/MyApp
        """)
    }
    
    private static func printExamples() {
        print("""
        📚 Configurable VIP Generator Examples:
        
        1. Create sample configuration:
           swift ConfigurableVIPGenerator.swift config sample UserProfile
           
        2. Edit the generated JSON configuration file to customize:
           - Use cases and their fields
           - Data store properties
           - Routing methods
           - Generation options
           
        3. Generate VIP scene from configuration:
           swift ConfigurableVIPGenerator.swift generate userprofile-config.json
           
        4. Example configuration structure:
           {
             "sceneName": "UserProfile",
             "useCases": [
               {
                 "name": "LoadProfile",
                 "requestFields": [...],
                 "responseFields": [...],
                 "viewModelFields": [...]
               }
             ],
             "options": {
               "generateTests": true,
               "useSwiftUI": true
             }
           }
        """)
    }
}

// MARK: - Main Entry Point

if CommandLine.argc > 0 {
    ConfigurableVIPCLI.main()
}