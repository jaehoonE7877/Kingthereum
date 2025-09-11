import SwiftUI
import UIKit

// MARK: - View Extensions for Common UI Patterns

public extension View {
    
    /// 조건부 뷰 모디파이어 적용
    /// - Parameters:
    ///   - condition: 적용 조건
    ///   - transform: 적용할 변형
    /// - Returns: 조건에 따라 변형된 뷰
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// 옵셔널 값에 따른 조건부 뷰 모디파이어
    @ViewBuilder
    func ifLet<T, Content: View>(_ value: T?, transform: (Self, T) -> Content) -> some View {
        if let value = value {
            transform(self, value)
        } else {
            self
        }
    }
    
    /// 로딩 오버레이 추가
    func loadingOverlay(isLoading: Bool) -> some View {
        overlay {
            if isLoading {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .tint(KingDesignTokens.Colors.accent)
                        .scaleEffect(1.5)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                                .frame(width: 100, height: 100)
                        )
                }
            }
        }
    }
    
    /// 에러 얼럿 표시 (간단한 문자열 기반)
    func errorAlert(
        title: String = "오류",
        message: String,
        isPresented: Binding<Bool>,
        retryAction: (() -> Void)? = nil
    ) -> some View {
        alert(
            title,
            isPresented: isPresented
        ) {
            if let retryAction = retryAction {
                Button("다시 시도") {
                    retryAction()
                }
            }
            Button("확인", role: .cancel) {}
        } message: {
            Text(message)
        }
    }
    
    /// 키보드 숨기기 제스처 추가
    func hideKeyboardOnTap() -> some View {
        onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    // MARK: - Glass Morphism Effects
    
    /// 신뢰성 글래스 카드 효과
    func trustGlassCard(level: GlassLevel, cornerRadius: CGFloat = 16) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(level.borderColor, lineWidth: level.borderWidth)
                )
        )
    }
    
    /// 울트라 미니멀 글래스 효과
    func ultraMinimalGlass(level: GlassLevel) -> some View {
        background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(level.borderColor.opacity(0.3), lineWidth: 0.5)
                )
        )
    }
    
    // MARK: - Additional View Modifiers
    
    /// 햅틱 피드백 추가
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> some View {
        self.onTapGesture {
            let impactFeedback = UIImpactFeedbackGenerator(style: style)
            impactFeedback.impactOccurred()
        }
    }
    
    /// 커스텀 테두리
    func customBorder(
        color: Color = Color.gray.opacity(0.3),
        width: CGFloat = 1,
        cornerRadius: CGFloat = 8
    ) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(color, lineWidth: width)
        )
    }
    
    /// 섀도우 프리셋
    func shadowPreset(_ preset: ShadowPreset) -> some View {
        self.shadow(
            color: preset.color,
            radius: preset.radius,
            x: preset.offset.x,
            y: preset.offset.y
        )
    }
}

// MARK: - Glass Level Enum
public enum GlassLevel {
    case standard
    case prominent
    case subtle
    
    var borderColor: Color {
        switch self {
        case .standard:
            return KingDesignTokens.Colors.border
        case .prominent:
            return KingDesignTokens.Colors.accent.opacity(0.5)
        case .subtle:
            return KingDesignTokens.Colors.tertiaryText.opacity(0.3)
        }
    }
    
    var borderWidth: CGFloat {
        switch self {
        case .standard:
            return 0.5
        case .prominent:
            return 1.0
        case .subtle:
            return 0.3
        }
    }
}

// MARK: - Shadow Presets

public enum ShadowPreset {
    case none
    case subtle
    case medium
    case strong
    case card
    
    var color: Color {
        switch self {
        case .none: return .clear
        case .subtle, .medium, .strong, .card: return .black.opacity(0.1)
        }
    }
    
    var radius: CGFloat {
        switch self {
        case .none: return 0
        case .subtle: return 2
        case .medium: return 4
        case .strong: return 8
        case .card: return 6
        }
    }
    
    var offset: CGPoint {
        switch self {
        case .none: return .zero
        case .subtle: return CGPoint(x: 0, y: 1)
        case .medium: return CGPoint(x: 0, y: 2)
        case .strong: return CGPoint(x: 0, y: 4)
        case .card: return CGPoint(x: 0, y: 3)
        }
    }
}