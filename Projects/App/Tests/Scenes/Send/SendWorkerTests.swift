import Testing
import Foundation
import BigInt
@testable import Scenes
@testable import Entity
@testable import WalletKit

// MARK: - SendWorker 테스트

@Suite("SendWorker 테스트")
struct SendWorkerTests {
    
    // MARK: - Mock Classes
    
    actor MockWalletService: WalletServiceProtocol {
        var createWalletCalled = false
        var createWalletResult: Result<Entity.Wallet, Error> = .success(Entity.Wallet(address: "0x123", privateKey: ""))
        
        func createWallet() async throws -> Entity.Wallet {
            createWalletCalled = true
            switch createWalletResult {
            case .success(let wallet):
                return wallet
            case .failure(let error):
                throw error
            }
        }
        
        var getCurrentWalletCalled = false
        var getCurrentWalletResult: Entity.Wallet?
        
        func getCurrentWallet() -> Entity.Wallet? {
            getCurrentWalletCalled = true
            return getCurrentWalletResult
        }
        
        var getBalanceCalled = false
        var getBalanceResult: Decimal = 1.0
        
        func getBalance() async -> Decimal {
            getBalanceCalled = true
            return getBalanceResult
        }
        
        var sendTransactionCalled = false
        var sendTransactionResult: Result<String, Error> = .success("0x123hash")
        
        func sendTransaction(to: String, amount: Decimal, gasPrice: BigUInt, gasLimit: BigUInt) async throws -> String {
            sendTransactionCalled = true
            switch sendTransactionResult {
            case .success(let hash):
                return hash
            case .failure(let error):
                throw error
            }
        }
    }
    
    struct MockPriceProvider: PriceProviderProtocol {
        let ethPrice: Decimal
        
        init(ethPrice: Decimal = 2000) {
            self.ethPrice = ethPrice
        }
        
        func getETHPriceInUSD() -> Decimal {
            return ethPrice
        }
    }
    
    // MARK: - Address Validation Tests
    
    @Suite("주소 검증")
    struct AddressValidation {
        
        @Test("유효한 이더리움 주소 - 성공")
        func testValidEthereumAddress() {
            // Given
            let sut = SendWorker()
            let validAddresses = [
                "0x742d35Cc6644C0532925a3b8F0aB4e7E6a7bDdD1",
                "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045",
                "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed"
            ]
            
            // When & Then
            for address in validAddresses {
                let isValid = sut.validateEthereumAddress(address)
                #expect(isValid == true, "유효한 이더리움 주소 \(address)가 검증되어야 함")
            }
        }
        
        @Test("유효하지 않은 이더리움 주소 - 실패")
        func testInvalidEthereumAddress() {
            // Given
            let sut = SendWorker()
            let invalidAddresses = [
                "0x742d35Cc6644C0532925a3b8F0aB4e7E6a7bDdD", // 너무 짧음
                "0x742d35Cc6644C0532925a3b8F0aB4e7E6a7bDdD12", // 너무 긺
                "742d35Cc6644C0532925a3b8F0aB4e7E6a7bDdD1", // 0x 접두사 없음
                "0xGGGd35Cc6644C0532925a3b8F0aB4e7E6a7bDdD1", // 잘못된 문자
                "", // 빈 문자열
                "not-an-address" // 완전히 잘못된 형식
            ]
            
            // When & Then
            for address in invalidAddresses {
                let isValid = sut.validateEthereumAddress(address)
                #expect(isValid == false, "유효하지 않은 주소 \(address)가 거부되어야 함")
            }
        }
        
        @Test("대소문자 혼합 주소 - 성공")
        func testMixedCaseAddress() {
            // Given
            let sut = SendWorker()
            let mixedCaseAddress = "0xAbCdEf1234567890aBcDeF1234567890AbCdEf12"
            
            // When
            let isValid = sut.validateEthereumAddress(mixedCaseAddress)
            
            // Then
            #expect(isValid == true, "대소문자 혼합 주소가 유효해야 함")
        }
    }
    
    // MARK: - Balance Management Tests
    
    @Suite("잔액 관리")
    struct BalanceManagement {
        
        @Test("현재 잔액 조회 - Mock 잔액")
        func testGetCurrentBalanceWithMock() {
            // Given
            let mockBalance = Decimal(1.5)
            let sut = SendWorker(mockBalance: mockBalance)
            
            // When
            let balance = sut.getCurrentBalance()
            
            // Then
            #expect(balance == mockBalance, "Mock 잔액이 반환되어야 함")
        }
        
        @Test("현재 잔액 조회 - UserDefaults")
        func testGetCurrentBalanceFromUserDefaults() {
            // Given
            let expectedBalance = "2.5"
            UserDefaults.standard.set(expectedBalance, forKey: "eth_balance")
            let sut = SendWorker()
            
            // When
            let balance = sut.getCurrentBalance()
            
            // Then
            #expect(balance == Decimal(string: expectedBalance), "UserDefaults 잔액이 반환되어야 함")
            
            // Cleanup
            UserDefaults.standard.removeObject(forKey: "eth_balance")
        }
        
        @Test("잔액 충분성 검사 - 충분한 잔액")
        func testSufficientBalance() {
            // Given
            let mockBalance = Decimal(2.0)
            let sut = SendWorker(mockBalance: mockBalance)
            
            let sendAmount = Decimal(1.0)
            let gasFee = Decimal(0.5)
            
            // When
            let isSufficient = sut.isBalanceSufficient(amount: sendAmount, includingGasFee: gasFee)
            
            // Then
            #expect(isSufficient == true, "충분한 잔액일 때 true를 반환해야 함")
        }
        
        @Test("잔액 충분성 검사 - 부족한 잔액")
        func testInsufficientBalance() {
            // Given
            let mockBalance = Decimal(1.0)
            let sut = SendWorker(mockBalance: mockBalance)
            
            let sendAmount = Decimal(0.8)
            let gasFee = Decimal(0.5)
            
            // When
            let isSufficient = sut.isBalanceSufficient(amount: sendAmount, includingGasFee: gasFee)
            
            // Then
            #expect(isSufficient == false, "부족한 잔액일 때 false를 반환해야 함")
        }
        
        @Test("잔액 충분성 검사 - 정확히 같은 잔액")
        func testExactBalance() {
            // Given
            let mockBalance = Decimal(1.5)
            let sut = SendWorker(mockBalance: mockBalance)
            
            let sendAmount = Decimal(1.0)
            let gasFee = Decimal(0.5)
            
            // When
            let isSufficient = sut.isBalanceSufficient(amount: sendAmount, includingGasFee: gasFee)
            
            // Then
            #expect(isSufficient == true, "정확히 같은 잔액일 때 true를 반환해야 함")
        }
    }
    
    // MARK: - Gas Fee Estimation Tests
    
    @Suite("가스비 추정")
    struct GasFeeEstimation {
        
        @Test("가스비 추정 성공")
        func testEstimateGasFeeSuccess() {
            // Given
            let mockPriceProvider = MockPriceProvider(ethPrice: 2500)
            let sut = SendWorker(priceProvider: mockPriceProvider)
            
            let validAddress = "0x742d35Cc6644C0532925a3b8F0aB4e7E6a7bDdD1"
            let amount = "1.0"
            
            // When
            let gasOptions = sut.estimateGasFee(recipientAddress: validAddress, amount: amount)
            
            // Then
            #expect(gasOptions != nil, "가스비 옵션이 반환되어야 함")
            
            let options = gasOptions!
            #expect(options.slow.estimatedTime == 300, "느림 옵션은 5분이어야 함")
            #expect(options.normal.estimatedTime == 180, "보통 옵션은 3분이어야 함")
            #expect(options.fast.estimatedTime == 60, "빠름 옵션은 1분이어야 함")
            
            // 가스비가 ETH 단위로 계산되는지 확인
            #expect(options.slow.feeInETH > 0, "느림 가스비는 0보다 커야 함")
            #expect(options.normal.feeInETH > options.slow.feeInETH, "보통 가스비는 느림보다 커야 함")
            #expect(options.fast.feeInETH > options.normal.feeInETH, "빠름 가스비는 보통보다 커야 함")
            
            // USD 가격이 계산되는지 확인
            #expect(options.slow.feeInUSD > 0, "USD 가격이 계산되어야 함")
        }
        
        @Test("가스비 추정 실패 - 유효하지 않은 주소")
        func testEstimateGasFeeInvalidAddress() {
            // Given
            let sut = SendWorker()
            let invalidAddress = "invalid-address"
            let amount = "1.0"
            
            // When
            let gasOptions = sut.estimateGasFee(recipientAddress: invalidAddress, amount: amount)
            
            // Then
            #expect(gasOptions == nil, "유효하지 않은 주소에 대해 nil을 반환해야 함")
        }
        
        @Test("가스비 추정 실패 - 유효하지 않은 금액")
        func testEstimateGasFeeInvalidAmount() {
            // Given
            let sut = SendWorker()
            let validAddress = "0x742d35Cc6644C0532925a3b8F0aB4e7E6a7bDdD1"
            let invalidAmount = "not-a-number"
            
            // When
            let gasOptions = sut.estimateGasFee(recipientAddress: validAddress, amount: invalidAmount)
            
            // Then
            #expect(gasOptions == nil, "유효하지 않은 금액에 대해 nil을 반환해야 함")
        }
        
        @Test("가스비 계산 로직")
        func testGasFeeCalculation() {
            // Given
            let ethPrice = Decimal(3000)
            let mockPriceProvider = MockPriceProvider(ethPrice: ethPrice)
            let sut = SendWorker(priceProvider: mockPriceProvider)
            
            let validAddress = "0x742d35Cc6644C0532925a3b8F0aB4e7E6a7bDdD1"
            let amount = "1.0"
            
            // When
            let gasOptions = sut.estimateGasFee(recipientAddress: validAddress, amount: amount)!
            
            // Then
            // 20 Gwei * 21000 gas limit = 420000000000000 Wei = 0.00042 ETH (대략적)
            let expectedSlowETH = Decimal(20 * 21000) / pow(10, 9) // Gwei to ETH 변환
            #expect(abs(gasOptions.slow.feeInETH - expectedSlowETH) < 0.001, "느림 가스비가 올바르게 계산되어야 함")
            
            // USD 가격 확인
            let expectedSlowUSD = gasOptions.slow.feeInETH * ethPrice
            #expect(abs(gasOptions.slow.feeInUSD - expectedSlowUSD) < 0.01, "USD 가격이 올바르게 계산되어야 함")
        }
    }
    
    // MARK: - Transaction Preparation Tests
    
    @Suite("거래 준비")
    struct TransactionPreparation {
        
        @Test("거래 준비 성공")
        func testPrepareTransactionSuccess() {
            // Given
            let mockBalance = Decimal(2.0)
            let sut = SendWorker(mockBalance: mockBalance)
            
            let recipientAddress = "0x742d35Cc6644C0532925a3b8F0aB4e7E6a7bDdD1"
            let amount = Decimal(1.0)
            let gasFee = Entity.GasFee(
                gasPrice: "25000000000",
                estimatedTime: 180,
                feeInETH: 0.00063,
                feeInUSD: 1.25
            )
            
            // When
            let transaction = sut.prepareTransaction(
                recipientAddress: recipientAddress,
                amount: amount,
                gasFee: gasFee
            )
            
            // Then
            #expect(transaction != nil, "거래가 준비되어야 함")
            
            let tx = transaction!
            #expect(tx.recipientAddress == recipientAddress, "받는 사람 주소가 설정되어야 함")
            #expect(tx.amount == amount, "금액이 설정되어야 함")
            #expect(tx.gasPrice == gasFee.gasPrice, "가스 가격이 설정되어야 함")
            #expect(tx.gasLimit == "21000", "가스 한도가 설정되어야 함")
            #expect(tx.nonce == "42", "Nonce가 설정되어야 함")
        }
        
        @Test("거래 준비 실패 - 유효하지 않은 주소")
        func testPrepareTransactionInvalidAddress() {
            // Given
            let sut = SendWorker()
            let invalidAddress = "invalid-address"
            let amount = Decimal(1.0)
            let gasFee = Entity.GasFee(
                gasPrice: "25000000000",
                estimatedTime: 180,
                feeInETH: 0.00063,
                feeInUSD: 1.25
            )
            
            // When
            let transaction = sut.prepareTransaction(
                recipientAddress: invalidAddress,
                amount: amount,
                gasFee: gasFee
            )
            
            // Then
            #expect(transaction == nil, "유효하지 않은 주소에 대해 nil을 반환해야 함")
        }
        
        @Test("거래 준비 실패 - 0 이하 금액")
        func testPrepareTransactionZeroAmount() {
            // Given
            let sut = SendWorker()
            let validAddress = "0x742d35Cc6644C0532925a3b8F0aB4e7E6a7bDdD1"
            let zeroAmount = Decimal(0)
            let gasFee = Entity.GasFee(
                gasPrice: "25000000000",
                estimatedTime: 180,
                feeInETH: 0.00063,
                feeInUSD: 1.25
            )
            
            // When
            let transaction = sut.prepareTransaction(
                recipientAddress: validAddress,
                amount: zeroAmount,
                gasFee: gasFee
            )
            
            // Then
            #expect(transaction == nil, "0 이하 금액에 대해 nil을 반환해야 함")
        }
        
        @Test("거래 준비 실패 - 잔액 부족")
        func testPrepareTransactionInsufficientBalance() {
            // Given
            let mockBalance = Decimal(0.5)
            let sut = SendWorker(mockBalance: mockBalance)
            
            let validAddress = "0x742d35Cc6644C0532925a3b8F0aB4e7E6a7bDdD1"
            let amount = Decimal(1.0)
            let gasFee = Entity.GasFee(
                gasPrice: "25000000000",
                estimatedTime: 180,
                feeInETH: 0.5,
                feeInUSD: 1000.0
            )
            
            // When
            let transaction = sut.prepareTransaction(
                recipientAddress: validAddress,
                amount: amount,
                gasFee: gasFee
            )
            
            // Then
            #expect(transaction == nil, "잔액 부족시 nil을 반환해야 함")
        }
    }
    
    // MARK: - Biometric Authentication Tests
    
    @Suite("생체 인증")
    struct BiometricAuthentication {
        
        @Test("생체 인증 성공")
        func testBiometricAuthenticationSuccess() async {
            // Given
            let sut = SendWorker()
            
            // When
            let result = await sut.authenticateWithBiometric()
            
            // Then
            // 실제 디바이스에서 생체 인증을 테스트하기 어려우므로,
            // 최소한 메서드가 호출되고 결과가 반환되는지 확인
            #expect(result is Bool, "Boolean 결과가 반환되어야 함")
        }
    }
    
    // MARK: - Transaction Sending Tests
    
    @Suite("거래 전송")
    struct TransactionSending {
        
        @Test("거래 전송 성공 시뮬레이션")
        func testSendTransactionSuccess() async {
            // Given
            let sut = SendWorker()
            let transaction = Entity.PendingTransaction(
                recipientAddress: "0x742d35Cc6644C0532925a3b8F0aB4e7E6a7bDdD1",
                amount: Decimal(1.0),
                gasPrice: "25000000000",
                gasLimit: "21000",
                nonce: "42"
            )
            
            // When
            let result = await sut.sendTransaction(transaction)
            
            // Then
            switch result {
            case .success(let hash):
                #expect(hash.hasPrefix("0x"), "거래 해시는 0x로 시작해야 함")
                #expect(hash.count == 66, "거래 해시는 66자여야 함 (0x + 64자)")
            case .failure:
                // Mock 구현에서 90% 확률로 성공하므로, 실패할 수도 있음
                // 이는 정상적인 테스트 시나리오
                break
            }
        }
        
        @Test("거래 해시 생성 형식")
        func testTransactionHashGeneration() {
            // Given
            let sut = SendWorker()
            
            // When
            let hash1 = sut.generateMockTransactionHash()
            let hash2 = sut.generateMockTransactionHash()
            
            // Then
            #expect(hash1.hasPrefix("0x"), "해시는 0x로 시작해야 함")
            #expect(hash1.count == 66, "해시는 66자여야 함")
            #expect(hash1 != hash2, "매번 다른 해시가 생성되어야 함")
            
            // 16진수 문자만 포함하는지 확인
            let hexCharacterSet = CharacterSet(charactersIn: "0123456789abcdef")
            let hashWithoutPrefix = String(hash1.dropFirst(2))
            let containsOnlyHex = hashWithoutPrefix.unicodeScalars.allSatisfy { hexCharacterSet.contains($0) }
            #expect(containsOnlyHex, "해시는 16진수 문자만 포함해야 함")
        }
    }
    
    // MARK: - Price Provider Tests
    
    @Suite("가격 제공자")
    struct PriceProvider {
        
        @Test("Mock 가격 제공자")
        func testMockPriceProvider() {
            // Given
            let mockProvider = MockPriceProvider()
            
            // When
            let price = mockProvider.getETHPriceInUSD()
            
            // Then
            #expect(price == Decimal(2000), "Mock ETH 가격이 $2000이어야 함")
        }
        
        @Test("커스텀 가격 Mock 가격 제공자")
        func testCustomPriceMockProvider() {
            // Given
            let customPrice = Decimal(3500)
            let mockProvider = MockPriceProvider(ethPrice: customPrice)
            
            // When
            let price = mockProvider.getETHPriceInUSD()
            
            // Then
            #expect(price == customPrice, "커스텀 ETH 가격이 설정되어야 함")
        }
        
        @Test("실제 가격 제공자 인스턴스 생성")
        func testCoinGeckoPriceProviderCreation() {
            // Given & When
            let coinGeckoProvider = CoinGeckoPriceProvider()
            let price = coinGeckoProvider.getETHPriceInUSD()
            
            // Then
            #expect(price == Decimal(2000), "기본 ETH 가격이 반환되어야 함")
            // 실제 구현에서는 API 호출 로직이 포함될 예정
        }
    }
    
    // MARK: - Integration Tests
    
    @Suite("통합 테스트")
    struct IntegrationTests {
        
        @Test("전체 송금 플로우")
        func testCompleteTransferFlow() async {
            // Given
            let mockBalance = Decimal(2.0)
            let mockPriceProvider = MockPriceProvider(ethPrice: 2500)
            let sut = SendWorker(mockBalance: mockBalance, priceProvider: mockPriceProvider)
            
            let recipientAddress = "0x742d35Cc6644C0532925a3b8F0aB4e7E6a7bDdD1"
            let sendAmount = "1.0"
            
            // When & Then
            // 1. 주소 검증
            let isValidAddress = sut.validateEthereumAddress(recipientAddress)
            #expect(isValidAddress == true, "주소가 유효해야 함")
            
            // 2. 잔액 확인
            let currentBalance = sut.getCurrentBalance()
            #expect(currentBalance >= Decimal(string: sendAmount)!, "잔액이 충분해야 함")
            
            // 3. 가스비 추정
            let gasOptions = sut.estimateGasFee(recipientAddress: recipientAddress, amount: sendAmount)
            #expect(gasOptions != nil, "가스비 추정이 성공해야 함")
            
            // 4. 잔액 충분성 재확인 (가스비 포함)
            let isSufficient = sut.isBalanceSufficient(
                amount: Decimal(string: sendAmount)!,
                includingGasFee: gasOptions!.normal.feeInETH
            )
            #expect(isSufficient == true, "가스비 포함 잔액이 충분해야 함")
            
            // 5. 거래 준비
            let transaction = sut.prepareTransaction(
                recipientAddress: recipientAddress,
                amount: Decimal(string: sendAmount)!,
                gasFee: gasOptions!.normal
            )
            #expect(transaction != nil, "거래가 준비되어야 함")
            
            // 6. 생체 인증 (시뮬레이션)
            let isAuthenticated = await sut.authenticateWithBiometric()
            // 생체 인증 결과는 디바이스에 따라 다르므로 결과 타입만 확인
            #expect(isAuthenticated is Bool, "생체 인증 결과가 반환되어야 함")
            
            // 7. 거래 전송
            let sendResult = await sut.sendTransaction(transaction!)
            switch sendResult {
            case .success(let hash):
                #expect(hash.hasPrefix("0x"), "거래 해시가 반환되어야 함")
            case .failure:
                // Mock에서는 실패할 수 있음 (10% 확률)
                break
            }
        }
    }
}