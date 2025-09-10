import SwiftUI
import Combine
import Foundation
import SecurityKit
import WalletKit
import Entity
import Core

// MARK: - Premium Send Coordinator

@MainActor
final class PremiumSendCoordinator: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var recipientAddress: String = ""
    @Published var amount: String = ""
    @Published var selectedGasFee: GasFeeLevel = .standard
    
    // Validation states
    @Published var addressValidation = AddressValidation()
    @Published var amountValidation = AmountValidation()
    @Published var securityValidation = SecurityValidation()
    
    // UI states
    @Published var isLoading: Bool = false
    @Published var isSending: Bool = false
    @Published var isEstimatingGas: Bool = false
    @Published var showTransactionPreview: Bool = false
    @Published var showQRScanner: Bool = false
    @Published var showAddressBook: Bool = false
    @Published var showTransactionSuccess: Bool = false
    
    // Security
    @Published var securityStatus: SecurityStatus = .secure
    @Published var securityAlerts: [SecurityAlert] = []
    
    // Gas estimates
    @Published var gasEstimates: [GasFeeLevel: GasEstimate] = [:]
    
    // Real-time data
    @Published var amountUSD: String = "$0.00"
    @Published var totalAmount: String = "0.0000 ETH"
    @Published var estimatedTransactionTime: String = "~2 min"
    
    // Address suggestions
    @Published var addressSuggestions: [AddressSuggestion] = []
    
    // Transaction result
    @Published var lastTransactionHash: String = ""
    
    // MARK: - Dependencies
    
    private let sendWorker: SendWorker
    private let securityManager: SendSecurityInteractor
    private let balanceService: BalanceService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        sendWorker: SendWorker = SendWorker(),
        securityManager: SendSecurityInteractor = SendSecurityInteractor(),
        balanceService: BalanceService = BalanceService()
    ) {
        self.sendWorker = sendWorker
        self.securityManager = securityManager
        self.balanceService = balanceService
        
        setupBindings()
        setupValidation()
    }
    
    // MARK: - Computed Properties
    
    var canSend: Bool {
        addressValidation.isValid &&
        amountValidation.isValid &&
        securityValidation.isAuthenticated &&
        !isSending &&
        !amount.isEmpty &&
        !recipientAddress.isEmpty
    }
    
    var sendButtonTitle: String {
        if isSending {
            return "송금 중..."
        } else if !securityValidation.isAuthenticated {
            return "인증 후 송금"
        } else {
            return "송금하기"
        }
    }
    
    var selectedGasEstimate: GasEstimate {
        gasEstimates[selectedGasFee] ?? GasEstimate.default
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Address validation
        $recipientAddress
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] address in
                Task { @MainActor in
                    await self?.validateAddress(address)
                }
            }
            .store(in: &cancellables)
        
        // Amount validation
        $amount
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] amount in
                Task { @MainActor in
                    await self?.validateAmount(amount)
                }
            }
            .store(in: &cancellables)
        
        // Security monitoring
        securityManager.$currentSecurityStatus
            .receive(on: DispatchQueue.main)
            .assign(to: &$securityStatus)
        
        securityManager.$activeAlerts
            .receive(on: DispatchQueue.main)
            .assign(to: &$securityAlerts)
        
        // Gas estimation trigger
        Publishers.CombineLatest3($recipientAddress, $amount, $selectedGasFee)
            .debounce(for: .milliseconds(800), scheduler: DispatchQueue.main)
            .sink { [weak self] address, amount, gasFee in
                if !address.isEmpty && !amount.isEmpty {
                    Task { @MainActor in
                        await self?.estimateGasFees()
                    }
                }
            }
            .store(in: &cancellables)
        
        // USD amount calculation
        $amount
            .combineLatest(balanceService.$ethereumPrice)
            .map { amount, price in
                guard let amountDouble = Double(amount), price > 0 else {
                    return "$0.00"
                }
                let usdValue = amountDouble * price
                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                formatter.currencyCode = "USD"
                return formatter.string(from: NSNumber(value: usdValue)) ?? "$0.00"
            }
            .assign(to: &$amountUSD)
        
        // Transaction preview visibility
        Publishers.CombineLatest($addressValidation, $amountValidation)
            .map { address, amount in
                address.isValid && amount.isValid
            }
            .assign(to: &$showTransactionPreview)
    }
    
    private func setupValidation() {
        // Initialize security validation
        Task {
            await performInitialSecurityCheck()
        }
    }
    
    // MARK: - Data Loading
    
    func loadInitialData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Load address book for suggestions
            let suggestions = await loadAddressSuggestions()
            addressSuggestions = suggestions
            
            // Initialize gas estimates
            await estimateGasFees()
            
        } catch {
            print("Failed to load initial data: \(error)")
        }
    }
    
    func refreshData() async {
        await loadInitialData()
        await balanceService.refreshBalance()
    }
    
    // MARK: - Address Validation
    
    private func validateAddress(_ address: String) async {
        guard !address.isEmpty else {
            addressValidation = AddressValidation()
            return
        }
        
        addressValidation.isValidating = true
        
        do {
            let validation = try await sendWorker.validateAddress(address)
            addressValidation = validation
            
            // Load suggestions if address is partial
            if address.count > 4 && !validation.isValid {
                let suggestions = await loadAddressSuggestions(matching: address)
                addressSuggestions = suggestions
                addressValidation.showSuggestions = !suggestions.isEmpty
            }
            
        } catch {
            addressValidation = AddressValidation(
                isValid: false,
                message: "주소 검증에 실패했습니다",
                isValidating: false
            )
        }
    }
    
    private func loadAddressSuggestions(matching prefix: String = "") async -> [AddressSuggestion] {
        // Mock implementation - replace with actual address book service
        let mockSuggestions = [
            AddressSuggestion(
                name: "내 다른 지갑",
                address: "0x742d35Cc6C834C6532C5C4b4c8C8D7C47dA84F4f",
                icon: "person.crop.circle.fill"
            ),
            AddressSuggestion(
                name: "거래소 지갑",
                address: "0xA0b86991c431e58e083c3C0E5a2A8F4A4c2b2F8c",
                icon: "building.2.fill"
            ),
            AddressSuggestion(
                name: "친구 지갑",
                address: "0xdAC17F958D2ee523a2206206994597C13D831ec7",
                icon: "person.2.fill"
            )
        ]
        
        if prefix.isEmpty {
            return mockSuggestions
        } else {
            return mockSuggestions.filter { suggestion in
                suggestion.name.localizedCaseInsensitiveContains(prefix) ||
                suggestion.address.localizedCaseInsensitiveContains(prefix)
            }
        }
    }
    
    // MARK: - Amount Validation
    
    private func validateAmount(_ amount: String) async {
        guard !amount.isEmpty else {
            amountValidation = AmountValidation()
            return
        }
        
        amountValidation.isValidating = true
        
        do {
            let validation = try await sendWorker.validateAmount(amount)
            amountValidation = validation
            
            // Calculate total amount with gas
            updateTotalAmount()
            
        } catch {
            amountValidation = AmountValidation(
                isValid: false,
                message: "금액 검증에 실패했습니다",
                isValidating: false
            )
        }
    }
    
    private func updateTotalAmount() {
        guard let amountDouble = Double(amount) else {
            totalAmount = "0.0000 ETH"
            return
        }
        
        let gasAmount = selectedGasEstimate.gasPrice * selectedGasEstimate.gasLimit / 1e18
        let total = amountDouble + gasAmount
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 4
        formatter.maximumFractionDigits = 6
        
        totalAmount = (formatter.string(from: NSNumber(value: total)) ?? "0.0000") + " ETH"
    }
    
    // MARK: - Gas Fee Estimation
    
    func estimateGasFees() async {
        guard !recipientAddress.isEmpty && !amount.isEmpty else { return }
        
        isEstimatingGas = true
        defer { isEstimatingGas = false }
        
        do {
            let estimates = try await sendWorker.estimateGasFees(
                recipient: recipientAddress,
                amount: amount
            )
            
            gasEstimates = estimates
            updateTotalAmount()
            updateEstimatedTime()
            
        } catch {
            print("Gas estimation failed: \(error)")
        }
    }
    
    private func updateEstimatedTime() {
        switch selectedGasFee {
        case .slow:
            estimatedTransactionTime = "~5-10 min"
        case .standard:
            estimatedTransactionTime = "~2-5 min"
        case .fast:
            estimatedTransactionTime = "~30 sec"
        }
    }
    
    // MARK: - Security Operations
    
    private func performInitialSecurityCheck() async {
        securityValidation.isRequired = true
        await securityManager.performSecurityCheck()
    }
    
    func performSecurityValidation() async {
        do {
            let result = try await securityManager.authenticateTransaction(
                recipient: recipientAddress,
                amount: amount
            )
            
            securityValidation.isAuthenticated = result.success
            securityValidation.isRequired = !result.success
            
            if !result.success {
                securityAlerts.append(
                    SecurityAlert(
                        type: .authenticationRequired,
                        message: result.message ?? "인증에 실패했습니다",
                        timestamp: Date(),
                        severity: .high
                    )
                )
            }
            
        } catch {
            securityValidation.isAuthenticated = false
            securityAlerts.append(
                SecurityAlert(
                    type: .authenticationRequired,
                    message: "보안 인증 중 오류가 발생했습니다",
                    timestamp: Date(),
                    severity: .critical
                )
            )
        }
    }
    
    // MARK: - Transaction Operations
    
    func initiateTransaction() async {
        guard canSend else { return }
        
        isSending = true
        defer { isSending = false }
        
        do {
            // Pre-transaction security validation
            await performSecurityValidation()
            
            guard securityValidation.isAuthenticated else {
                return
            }
            
            // Execute transaction
            let result = try await sendWorker.sendTransaction(
                recipient: recipientAddress,
                amount: amount,
                gasLevel: selectedGasFee
            )
            
            if result.success {
                lastTransactionHash = result.transactionHash ?? ""
                showTransactionSuccess = true
                
                // Log successful transaction
                await securityManager.logTransactionSuccess(
                    hash: lastTransactionHash,
                    recipient: recipientAddress,
                    amount: amount
                )
                
                // Reset form
                resetForm()
                
            } else {
                securityAlerts.append(
                    SecurityAlert(
                        type: .transactionFailed,
                        message: result.message ?? "거래 실행에 실패했습니다",
                        timestamp: Date(),
                        severity: .high
                    )
                )
            }
            
        } catch {
            securityAlerts.append(
                SecurityAlert(
                    type: .transactionFailed,
                    message: "거래 중 오류가 발생했습니다: \(error.localizedDescription)",
                    timestamp: Date(),
                    severity: .critical
                )
            )
        }
    }
    
    // MARK: - Helper Actions
    
    func selectAddress(_ address: String) {
        recipientAddress = address
        addressSuggestions.removeAll()
        addressValidation.showSuggestions = false
    }
    
    func pasteFromClipboard() {
        if let clipboardString = UIPasteboard.general.string {
            recipientAddress = clipboardString.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    func setMaxAmount() {
        // Get current balance minus gas fees
        let balance = balanceService.balance
        let gasAmount = selectedGasEstimate.gasPrice * selectedGasEstimate.gasLimit / 1e18
        let maxAmount = max(0, balance - gasAmount)
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 6
        
        amount = formatter.string(from: NSNumber(value: maxAmount)) ?? "0"
    }
    
    func setPercentageAmount(_ percentage: Double) {
        let balance = balanceService.balance
        let targetAmount = balance * percentage
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 6
        
        amount = formatter.string(from: NSNumber(value: targetAmount)) ?? "0"
    }
    
    func dismissSecurityAlert(_ alert: SecurityAlert) {
        securityAlerts.removeAll { $0.id == alert.id }
    }
    
    func dismissSecurityOverlay() {
        securityAlerts.removeAll()
    }
    
    private func resetForm() {
        recipientAddress = ""
        amount = ""
        selectedGasFee = .standard
        addressValidation = AddressValidation()
        amountValidation = AmountValidation()
        securityValidation = SecurityValidation()
        showTransactionPreview = false
    }
}

// MARK: - Supporting Types

struct AddressValidation {
    var isValid: Bool = false
    var message: String = ""
    var isValidating: Bool = false
    var showSuggestions: Bool = false
}

struct AmountValidation {
    var isValid: Bool = false
    var message: String = ""
    var isValidating: Bool = false
    var hasInsufficientFunds: Bool = false
}

struct SecurityValidation {
    var isRequired: Bool = false
    var isAuthenticated: Bool = false
    var biometricType: String = ""
    var lastAuthenticationTime: Date?
}

enum GasFeeLevel: String, CaseIterable {
    case slow = "느림"
    case standard = "보통"
    case fast = "빠름"
    
    var icon: String {
        switch self {
        case .slow: return "tortoise.fill"
        case .standard: return "hare.fill"
        case .fast: return "bolt.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .slow: return KingDesignTokens.Colors.success
        case .standard: return KingDesignTokens.Colors.primary
        case .fast: return KingDesignTokens.Colors.warning
        }
    }
    
    var priority: Double {
        switch self {
        case .slow: return 1.0
        case .standard: return 1.5
        case .fast: return 2.0
        }
    }
}

struct GasEstimate {
    let gasPrice: Double // in Gwei
    let gasLimit: Double // in gas units
    let estimatedCostETH: Double
    let estimatedCostUSD: Double
    let estimatedTime: String
    
    static let `default` = GasEstimate(
        gasPrice: 20.0,
        gasLimit: 21000,
        estimatedCostETH: 0.00042,
        estimatedCostUSD: 1.26,
        estimatedTime: "~2 min"
    )
}

enum SecurityStatus: String, CaseIterable {
    case secure = "secure"
    case warning = "warning"
    case danger = "danger"
    
    var displayName: String {
        switch self {
        case .secure: return "안전"
        case .warning: return "주의"
        case .danger: return "위험"
        }
    }
    
    var color: Color {
        switch self {
        case .secure: return KingDesignTokens.Colors.success
        case .warning: return KingDesignTokens.Colors.warning
        case .danger: return KingDesignTokens.Colors.error
        }
    }
    
    var icon: String {
        switch self {
        case .secure: return "shield.checkered"
        case .warning: return "shield.lefthalf.filled.trianglebadge.exclamationmark"
        case .danger: return "shield.slash"
        }
    }
}

struct SecurityAlert: Identifiable, Equatable {
    let id = UUID()
    let type: AlertType
    let message: String
    let timestamp: Date
    let severity: SecurityStatus
    
    enum AlertType: String, CaseIterable {
        case authenticationRequired = "authenticationRequired"
        case transactionFailed = "transactionFailed"
        case suspiciousActivity = "suspiciousActivity"
        case networkIssue = "networkIssue"
        
        var displayName: String {
            switch self {
            case .authenticationRequired: return "인증 필요"
            case .transactionFailed: return "거래 실패"
            case .suspiciousActivity: return "의심스러운 활동"
            case .networkIssue: return "네트워크 문제"
            }
        }
    }
}

// MARK: - Balance Service

@MainActor
final class BalanceService: ObservableObject {
    @Published var balance: Double = 0.0
    @Published var ethereumPrice: Double = 3000.0
    @Published var isUpdating: Bool = false
    
    func refreshBalance() async {
        isUpdating = true
        defer { isUpdating = false }
        
        // Mock implementation - replace with actual wallet service
        try? await Task.sleep(nanoseconds: 500_000_000)
        balance = Double.random(in: 1.0...10.0)
        ethereumPrice = Double.random(in: 2800...3200)
    }
}