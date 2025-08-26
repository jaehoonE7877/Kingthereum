import SwiftUI
import Core

/// Metal 성능 디버깅 및 모니터링 뷰
/// 개발 및 테스트 환경에서 Metal Glass 성능을 실시간으로 모니터링
public struct MetalPerformanceDebugView: View {
    
    @StateObject private var performanceManager = MetalPerformanceManager.shared
    @State private var showDetails: Bool = false
    @State private var isMonitoringEnabled: Bool = true
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            headerSection
            
            if showDetails {
                detailsSection
                    .transition(.opacity.combined(with: .scale))
            }
            
            controlsSection
        }
        .padding(DesignTokens.Spacing.lg)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                .stroke(performanceStatusColor.opacity(0.3), lineWidth: 1)
        )
        .onAppear {
            performanceManager.setPerformanceMonitoring(enabled: isMonitoringEnabled)
        }
    }
    
    // MARK: - Header Section
    
    @ViewBuilder
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text("Metal 성능 모니터")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(performanceManager.deviceTier.displayName)
                    .font(.subheadline)
                    .foregroundColor(performanceStatusColor)
                    .fontWeight(.medium)
            }
            
            Spacer()
            
            // 성능 상태 인디케이터
            HStack(spacing: DesignTokens.Spacing.sm) {
                thermalIndicator
                fpsIndicator
            }
            
            Button {
                withAnimation(.spring()) {
                    showDetails.toggle()
                }
            } label: {
                Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
    }
    
    // MARK: - Performance Indicators
    
    @ViewBuilder
    private var thermalIndicator: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            Image(systemName: thermalIconName)
                .foregroundColor(thermalColor)
                .font(.caption)
            
            Text(thermalStateText)
                .font(.caption2)
                .foregroundColor(thermalColor)
        }
        .padding(.horizontal, DesignTokens.Spacing.xs)
        .padding(.vertical, 2)
        .background(thermalColor.opacity(0.1), in: RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.sm))
    }
    
    @ViewBuilder
    private var fpsIndicator: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            Text("\(Int(1.0 / max(performanceManager.averageFrameTime, 0.001)))fps")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(fpsColor)
                .monospacedDigit()
        }
        .padding(.horizontal, DesignTokens.Spacing.xs)
        .padding(.vertical, 2)
        .background(fpsColor.opacity(0.1), in: RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.sm))
    }
    
    // MARK: - Details Section
    
    @ViewBuilder
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Divider()
            
            // 성능 메트릭스
            performanceMetricsSection
            
            Divider()
            
            // 품질 설정
            qualitySettingsSection
        }
    }
    
    @ViewBuilder
    private var performanceMetricsSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text("성능 메트릭스")
                .font(.subheadline)
                .fontWeight(.medium)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: DesignTokens.Spacing.sm) {
                metricCard("프레임 타임", "\(String(format: "%.2f", performanceManager.averageFrameTime * 1000))ms")
                metricCard("FPS", "\(Int(1.0 / max(performanceManager.averageFrameTime, 0.001)))")
                metricCard("열 상태", thermalStateText)
                metricCard("모니터링", isMonitoringEnabled ? "활성" : "비활성")
            }
        }
    }
    
    @ViewBuilder
    private var qualitySettingsSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text("품질 설정")
                .font(.subheadline)
                .fontWeight(.medium)
            
            let quality = performanceManager.currentQuality
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: DesignTokens.Spacing.sm) {
                metricCard("노이즈 옥타브", "\(quality.noiseOctaves)")
                metricCard("굴절 샘플", "\(quality.refractionSamples)")
                metricCard("반사 품질", "\(Int(quality.reflectionQuality * 100))%")
                metricCard("렌더 스케일", "\(Int(quality.renderScale * 100))%")
                metricCard("색수차", quality.enableChromaticAberration ? "활성" : "비활성")
                metricCard("고급 반사", quality.enableAdvancedReflection ? "활성" : "비활성")
            }
        }
    }
    
    @ViewBuilder
    private func metricCard(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignTokens.Spacing.xs)
        .background(Color.secondary.opacity(0.05), in: RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xs))
    }
    
    // MARK: - Controls Section
    
    @ViewBuilder
    private var controlsSection: some View {
        if showDetails {
            Divider()
            
            HStack {
                // 성능 모니터링 토글
                Toggle("성능 모니터링", isOn: $isMonitoringEnabled)
                    .toggleStyle(.switch)
                    .onChange(of: isMonitoringEnabled) { _, newValue in
                        performanceManager.setPerformanceMonitoring(enabled: newValue)
                    }
                
                Spacer()
                
                // 수동 품질 조정 버튼들
                qualityControlButtons
            }
            .font(.caption)
        }
    }
    
    @ViewBuilder
    private var qualityControlButtons: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            ForEach([
                ("최소", MetalPerformanceManager.QualitySettings.minimal, MetalPerformanceManager.DevicePerformanceTier.minimal),
                ("낮음", MetalPerformanceManager.QualitySettings.low, MetalPerformanceManager.DevicePerformanceTier.low),
                ("보통", MetalPerformanceManager.QualitySettings.medium, MetalPerformanceManager.DevicePerformanceTier.medium),
                ("높음", MetalPerformanceManager.QualitySettings.high, MetalPerformanceManager.DevicePerformanceTier.high)
            ], id: \.0) { title, quality, tier in
                Button(title) {
                    performanceManager.setQuality(quality, tier: tier)
                }
                .font(.caption2)
                .padding(.horizontal, DesignTokens.Spacing.xs)
                .padding(.vertical, 2)
                .background(
                    performanceManager.deviceTier == tier ? 
                    Color.accentColor.opacity(0.2) : 
                    Color.secondary.opacity(0.1),
                    in: RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xs)
                )
                .foregroundColor(
                    performanceManager.deviceTier == tier ? 
                    .accentColor : 
                    .secondary
                )
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var performanceStatusColor: Color {
        switch performanceManager.deviceTier {
        case .high: return .green
        case .medium: return .orange
        case .low: return .red
        case .minimal: return .gray
        }
    }
    
    private var thermalColor: Color {
        switch performanceManager.thermalState {
        case .nominal: return .green
        case .fair: return .yellow
        case .serious: return .orange
        case .critical: return .red
        @unknown default: return .gray
        }
    }
    
    private var thermalIconName: String {
        switch performanceManager.thermalState {
        case .nominal: return "thermometer"
        case .fair: return "thermometer"
        case .serious: return "thermometer.high"
        case .critical: return "exclamationmark.triangle.fill"
        @unknown default: return "questionmark"
        }
    }
    
    private var thermalStateText: String {
        switch performanceManager.thermalState {
        case .nominal: return "정상"
        case .fair: return "보통"
        case .serious: return "높음"
        case .critical: return "위험"
        @unknown default: return "알 수 없음"
        }
    }
    
    private var fpsColor: Color {
        let fps = 1.0 / max(performanceManager.averageFrameTime, 0.001)
        if fps >= 55 { return .green }
        else if fps >= 40 { return .orange }
        else { return .red }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            MetalPerformanceDebugView()
            
            // Glass 효과 테스트
            VStack {
                Text("Metal Glass 효과 테스트")
                    .font(.headline)
                    .padding()
            }
            .frame(height: 100)
            .safeMetalLiquidGlass(settings: .constant(LiquidGlassSettings()))
        }
        .padding()
    }
    .background(
        LinearGradient(
            colors: [.blue, .purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}