import Testing
import SwiftUI
import Foundation
@testable import Kingthereum

@Suite("Saving Insights Models Tests")
struct SavingInsightsModelsTests {
    
    // MARK: - SavingInsight Generation Tests
    
    @Test("Should generate excellent saving condition")
    func excellentSavingCondition() {
        // Given - Low gas price and low congestion
        let baseFee = 8.0
        let networkCongestion = 0.2
        
        // When
        let insight = SavingInsight.generate(baseFee: baseFee, networkCongestion: networkCongestion)
        
        // Then
        switch insight {
        case .excellent(let message):
            #expect(insight.title == "최적의 거래 시간!")
            #expect(insight.icon == "checkmark.circle.fill")
            #expect(insight.color == .green)
            #expect(message.contains("30%"))
            #expect(message.contains("저렴"))
        default:
            Issue.record("Expected excellent insight for low gas price and congestion")
        }
    }
    
    @Test("Should generate good saving condition")
    func goodSavingCondition() {
        // Given - Moderate gas price and congestion
        let baseFee = 13.0 // Total: 13 + 2 = 15
        let networkCongestion = 0.4
        
        // When
        let insight = SavingInsight.generate(baseFee: baseFee, networkCongestion: networkCongestion)
        
        // Then
        switch insight {
        case .good(let message):
            #expect(insight.title == "괜찮은 시간이에요")
            #expect(insight.icon == "clock.circle.fill")
            #expect(insight.color == .orange)
            #expect(message.contains("평균적인"))
        default:
            Issue.record("Expected good insight for moderate conditions")
        }
    }
    
    @Test("Should generate wait recommendation")
    func waitRecommendation() {
        // Given - High gas price and congestion
        let baseFee = 25.0 // Total: 25 + 2 = 27
        let networkCongestion = 0.8
        
        // When
        let insight = SavingInsight.generate(baseFee: baseFee, networkCongestion: networkCongestion)
        
        // Then
        switch insight {
        case .wait(let message):
            #expect(insight.title == "잠시만 기다려보세요")
            #expect(insight.icon == "exclamationmark.circle.fill")
            #expect(insight.color == .red)
            #expect(message.contains("절약"))
            #expect(message.contains("%"))
        default:
            Issue.record("Expected wait insight for high gas price and congestion")
        }
    }
    
    @Test("Should handle borderline conditions")
    func borderlineConditions() {
        // Given - Exactly at the boundary
        let baseFee = 8.0 // Total: 8 + 2 = 10 (exactly at boundary)
        let networkCongestion = 0.3 // Exactly at boundary
        
        // When
        let insight = SavingInsight.generate(baseFee: baseFee, networkCongestion: networkCongestion)
        
        // Then - Should not be excellent since it's at boundary, not below
        switch insight {
        case .excellent:
            Issue.record("Should not be excellent at exact boundary")
        case .good, .wait:
            #expect(true) // Either is acceptable at boundary
        }
    }
    
    // MARK: - NetworkStatus Tests
    
    @Test("Should handle low congestion network status")
    func lowCongestionNetworkStatus() {
        // Given
        let lowCongestion = 0.2
        
        // When
        let status = NetworkStatus(congestionLevel: lowCongestion)
        
        // Then
        #expect(status.congestionLevel == lowCongestion)
        #expect(status.description == "원활")
        #expect(status.color == .green)
        #expect(status.estimatedWaitTime == "30초 이내")
    }
    
    @Test("Should handle moderate congestion network status")
    func moderateCongestionNetworkStatus() {
        // Given
        let moderateCongestion = 0.5
        
        // When
        let status = NetworkStatus(congestionLevel: moderateCongestion)
        
        // Then
        #expect(status.congestionLevel == moderateCongestion)
        #expect(status.description == "보통")
        #expect(status.color == .orange)
        #expect(status.estimatedWaitTime == "1-2분")
    }
    
    @Test("Should handle high congestion network status")
    func highCongestionNetworkStatus() {
        // Given
        let highCongestion = 0.8
        
        // When
        let status = NetworkStatus(congestionLevel: highCongestion)
        
        // Then
        #expect(status.congestionLevel == highCongestion)
        #expect(status.description == "혼잡")
        #expect(status.color == .red)
        #expect(status.estimatedWaitTime == "5분 이상")
    }
    
    // MARK: - CostComparison Tests
    
    @Test("Should handle cost comparison lower than average")
    func costComparisonLowerThanAverage() {
        // Given
        let currentCost = 10.0
        let averageCost = 15.0
        
        // When
        let comparison = CostComparison(currentCost: currentCost, averageCost: averageCost)
        
        // Then
        #expect(comparison.currentCost == currentCost)
        #expect(comparison.averageCost == averageCost)
        #expect(abs(comparison.percentageDifference - (-33.33)) < 0.1)
        #expect(comparison.savingsAmount == 5.0)
        #expect(comparison.isCurrentCostLower)
        #expect(comparison.formattedComparison.contains("33% 저렴"))
        #expect(comparison.formattedComparison.contains("$5.00 절약"))
    }
    
    @Test("Should handle cost comparison higher than average")
    func costComparisonHigherThanAverage() {
        // Given
        let currentCost = 20.0
        let averageCost = 15.0
        
        // When
        let comparison = CostComparison(currentCost: currentCost, averageCost: averageCost)
        
        // Then
        #expect(comparison.currentCost == currentCost)
        #expect(comparison.averageCost == averageCost)
        #expect(abs(comparison.percentageDifference - 33.33) < 0.1)
        #expect(comparison.savingsAmount == -5.0)
        #expect(comparison.isCurrentCostLower == false)
        #expect(comparison.formattedComparison.contains("33% 비쌈"))
    }
    
    @Test("Should use default average in cost comparison")
    func costComparisonDefaultAverage() {
        // Given
        let currentCost = 12.0
        
        // When
        let comparison = CostComparison(currentCost: currentCost) // Uses default average of 15.0
        
        // Then
        #expect(comparison.averageCost == 15.0)
        #expect(comparison.isCurrentCostLower)
    }
    
    // MARK: - InsightGenerator Component Tests
    
    @Test("Should analyze network congestion correctly")
    func networkAnalyzer() {
        // Given
        let analyzer = SavingInsights.InsightGenerator.DefaultNetworkAnalyzer()
        let gasUsedRatio = [0.8, 0.6, 0.9, 0.4, 0.3]
        
        // When
        let congestion = analyzer.analyzeCongestion(gasUsedRatio)
        
        // Then
        #expect(abs(congestion - 0.6) < 0.01) // (0.8+0.6+0.9+0.4+0.3)/5 = 3.0/5 = 0.6
    }
    
    @Test("Should handle empty array in network analyzer")
    func networkAnalyzerEmptyArray() {
        // Given
        let analyzer = SavingInsights.InsightGenerator.DefaultNetworkAnalyzer()
        let emptyGasUsedRatio: [Double] = []
        
        // When
        let congestion = analyzer.analyzeCongestion(emptyGasUsedRatio)
        
        // Then
        #expect(congestion == 0.0)
    }
    
    @Test("Should analyze cost correctly")
    func costAnalyzer() {
        // Given
        let analyzer = SavingInsights.InsightGenerator.DefaultCostAnalyzer()
        let baseFee = 12.5
        let priorityFee = 2.5
        
        // When
        let totalCost = analyzer.analyzeCost(baseFee, priorityFee)
        
        // Then
        #expect(totalCost == 15.0)
    }
    
    @Test("Should generate appropriate recommendations")
    func recommendationEngine() {
        // Given
        let engine = SavingInsights.InsightGenerator.DefaultRecommendationEngine()
        
        // When & Then - Optimal conditions
        let optimalRecommendation = engine.generateRecommendation(8.0, 0.2)
        #expect(optimalRecommendation.contains("지금 거래하세요"))
        
        // When & Then - Poor conditions
        let poorRecommendation = engine.generateRecommendation(30.0, 0.9)
        #expect(poorRecommendation.contains("1-2시간 후"))
        
        // When & Then - Moderate conditions
        let moderateRecommendation = engine.generateRecommendation(15.0, 0.5)
        #expect(moderateRecommendation.contains("괜찮은"))
    }
    
    // MARK: - Integration Tests
    
    @Test("Should generate complete insight")
    func completeInsightGeneration() {
        // Given - Real-world scenario
        let baseFee = 12.0
        let networkCongestion = 0.45
        
        // When
        let insight = SavingInsight.generate(baseFee: baseFee, networkCongestion: networkCongestion)
        let networkStatus = NetworkStatus(congestionLevel: networkCongestion)
        let costComparison = CostComparison(currentCost: baseFee + 2.0)
        
        // Then
        #expect(insight.title != nil)
        #expect(insight.message != nil)
        #expect(insight.icon != nil)
        
        #expect(networkStatus.description == "보통")
        #expect(costComparison.isCurrentCostLower)
    }
}