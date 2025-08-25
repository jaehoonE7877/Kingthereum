import Testing
import Foundation
@testable import Kingthereum

@Suite("Gas Calculator Models Tests")
struct GasCalculatorModelsTests {
    
    // MARK: - TransactionCost Tests
    
    @Test("Should calculate transaction cost correctly")
    func transactionCostCalculation() {
        // Given
        let gasLimit = 21000
        let baseFee = 10.0
        let priorityFee = 2.0
        let ethPrice = 2000.0
        
        // When
        let cost = TransactionCost(
            gasLimit: gasLimit,
            baseFee: baseFee,
            priorityFee: priorityFee,
            ethPrice: ethPrice
        )
        
        // Then
        #expect(cost.totalGwei == 252000.0) // (10 + 2) * 21000
        #expect(cost.gasLimit == gasLimit)
        #expect(cost.baseFee == baseFee)
        #expect(cost.priorityFee == priorityFee)
        #expect(cost.ethPrice == ethPrice)
    }
    
    @Test("Should convert to ETH correctly")
    func ethConversion() {
        // Given
        let cost = TransactionCost(
            gasLimit: 21000,
            baseFee: 10.0,
            priorityFee: 2.0,
            ethPrice: 2000.0
        )
        
        // When & Then
        #expect(abs(cost.totalETH - 0.000252) < 0.000001)
    }
    
    @Test("Should convert to USD correctly")
    func usdConversion() {
        // Given
        let cost = TransactionCost(
            gasLimit: 21000,
            baseFee: 10.0,
            priorityFee: 2.0,
            ethPrice: 2000.0
        )
        
        // When & Then
        #expect(abs(cost.totalUSD - 0.504) < 0.001) // 0.000252 * 2000
    }
    
    @Test("Should format strings correctly")
    func formattedStrings() {
        // Given
        let cost = TransactionCost(
            gasLimit: 21000,
            baseFee: 10.5,
            priorityFee: 2.3,
            ethPrice: 2150.75
        )
        
        // When & Then
        #expect(cost.formattedETH == "0.000269 ETH")
        #expect(cost.formattedUSD == "$0.58")
        #expect(cost.formattedGwei == "268800 Gwei")
    }
    
    // MARK: - TransactionType Tests
    
    @Test("ETH Transfer type should have correct properties")
    func ethTransferType() {
        // Given
        let ethTransfer = ETHTransfer()
        
        // When & Then
        #expect(ethTransfer.gasLimit == 21000)
        #expect(ethTransfer.name == "ETH 송금")
        #expect(ethTransfer.icon == "arrow.up.circle")
    }
    
    @Test("Token Transfer type should have correct properties")
    func tokenTransferType() {
        // Given
        let tokenTransfer = TokenTransfer()
        
        // When & Then
        #expect(tokenTransfer.gasLimit == 65000)
        #expect(tokenTransfer.name == "토큰 전송")
        #expect(tokenTransfer.icon == "dollarsign.circle")
    }
    
    @Test("Uniswap Swap type should have correct properties")
    func uniswapSwapType() {
        // Given
        let uniswapSwap = UniswapSwap()
        
        // When & Then
        #expect(uniswapSwap.gasLimit == 150000)
        #expect(uniswapSwap.name == "Uniswap 스왑")
        #expect(uniswapSwap.icon == "arrow.triangle.2.circlepath")
    }
    
    @Test("NFT Minting type should have correct properties")
    func nftMintingType() {
        // Given
        let nftMinting = NFTMinting()
        
        // When & Then
        #expect(nftMinting.gasLimit == 200000)
        #expect(nftMinting.name == "NFT 민팅")
        #expect(nftMinting.icon == "photo.artframe")
    }
    
    @Test("Custom Transaction type should have correct properties")
    func customTransactionType() {
        // Given
        let customGasLimit = 500000
        let customTransaction = CustomTransaction(gasLimit: customGasLimit)
        
        // When & Then
        #expect(customTransaction.gasLimit == customGasLimit)
        #expect(customTransaction.name == "커스텀")
        #expect(customTransaction.icon == "slider.horizontal.3")
    }
    
    // MARK: - TransactionTypeFactory Tests
    
    @Test("Should provide all available transaction types")
    func availableTransactionTypes() {
        // Given & When
        let availableTypes = TransactionTypeFactory.availableTypes
        
        // Then
        #expect(availableTypes.count == 4)
        #expect(availableTypes.contains { $0.name == "ETH 송금" })
        #expect(availableTypes.contains { $0.name == "토큰 전송" })
        #expect(availableTypes.contains { $0.name == "Uniswap 스왑" })
        #expect(availableTypes.contains { $0.name == "NFT 민팅" })
    }
    
    @Test("Should create custom transaction type")
    func createCustomTransactionType() {
        // Given
        let customGasLimit = 750000
        
        // When
        let customType = TransactionTypeFactory.createCustom(gasLimit: customGasLimit)
        
        // Then
        #expect(customType.gasLimit == customGasLimit)
        #expect(customType.name == "커스텀")
    }
    
    // MARK: - Edge Cases Tests
    
    @Test("Should handle zero gas limit")
    func zeroGasLimit() {
        // Given
        let cost = TransactionCost(
            gasLimit: 0,
            baseFee: 10.0,
            priorityFee: 2.0,
            ethPrice: 2000.0
        )
        
        // When & Then
        #expect(cost.totalGwei == 0.0)
        #expect(cost.totalETH == 0.0)
        #expect(cost.totalUSD == 0.0)
    }
    
    @Test("Should handle high gas prices")
    func highGasPrice() {
        // Given - Network congestion scenario
        let cost = TransactionCost(
            gasLimit: 21000,
            baseFee: 100.0, // Very high base fee
            priorityFee: 50.0, // Very high priority fee
            ethPrice: 3000.0
        )
        
        // When & Then
        #expect(cost.totalGwei == 3150000.0) // (100 + 50) * 21000
        #expect(abs(cost.totalETH - 0.00315) < 0.00001)
        #expect(abs(cost.totalUSD - 9.45) < 0.01)
    }
    
    @Test("Should handle very small amounts")
    func verySmallAmounts() {
        // Given - Low network activity
        let cost = TransactionCost(
            gasLimit: 21000,
            baseFee: 0.1,
            priorityFee: 0.05,
            ethPrice: 2000.0
        )
        
        // When & Then
        #expect(cost.totalGwei == 3150.0) // (0.1 + 0.05) * 21000
        #expect(abs(cost.totalETH - 0.00000315) < 0.00000001)
        #expect(abs(cost.totalUSD - 0.0063) < 0.0001)
    }
}