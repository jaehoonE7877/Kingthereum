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

// MARK: - iOS-specific UI Extensions
#if os(iOS)
public extension View {
    
    /// 햅틱 피드백을 제공하는 뷰 수정자
    /// 
    /// 사용자의 터치에 대한 촉각적 피드백을 제공하여 앱의 반응성을 향상시킵니다.
    /// 시뮬레이터에서는 동작하지 않으며, iPhone에서만 실제 햅틱이 발생합니다.
    /// 
    /// - Parameter style: 햅틱 피드백의 강도 (.light, .medium, .heavy, .soft, .rigid)
    /// - Returns: 햅틱 피드백이 적용된 뷰
    /// 
    /// ## 사용 예시:
    /// ```swift
    /// Button("확인") { }
    ///     .hapticFeedback(.medium)
    /// ```
    func hapticFeedbackOnTap(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> some View {
        self.onTapGesture {
            guard UIDevice.current.userInterfaceIdiom == .phone else { return }
            
            #if targetEnvironment(simulator)
            // 시뮬레이터에서는 햅틱 피드백 비활성화
            return
            #else
            let impactFeedback = UIImpactFeedbackGenerator(style: style)
            impactFeedback.prepare()
            impactFeedback.impactOccurred()
            #endif
        }
    }
    
    /// 키보드 숨기기 제스처
    func dismissKeyboardOnTap() -> some View {
        onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder), 
                to: nil, 
                from: nil, 
                for: nil
            )
        }
    }
}
#endif

// MARK: - Enhanced Glass Morphism Effects

public extension View {
    
    /// 프리미엄 글래스모피즘 효과 (KingDesignTokens 사용)
    /// 
    /// 반투명 배경과 블러 효과, 미세한 테두리를 조합하여 유리 같은 질감을 연출합니다.
    /// 모던한 UI 디자인에서 카드나 오버레이 요소에 주로 사용됩니다.
    /// 
    /// - Parameter cornerRadius: 모서리 둥글기 (기본값: 12)
    /// - Returns: 글래스모피즘 스타일이 적용된 뷰
    /// 
    /// ## 디자인 특성:
    /// - 반투명 배경 (.ultraThinMaterial)
    /// - 일관된 둥근 모서리
    /// - KingDesignTokens 기반 테두리
    /// - 부드러운 그림자 효과
    func premiumGlassMorphism(cornerRadius: CGFloat = KingDesignTokens.Radius.md) -> some View {
        self
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(KingDesignTokens.Colors.outline, lineWidth: KingDesignTokens.BorderWidth.hairline)
            )
            .shadow(
                color: KingDesignTokens.Colors.shadow,
                radius: 12,
                x: 0,
                y: 4
            )
    }
    
    /// 인터랙티브 카드 효과
    /// 
    /// 터치와 호버 상태에 반응하는 인터랙티브한 카드 스타일을 적용합니다.
    /// 
    /// - Parameter isPressed: 눌림 상태
    /// - Returns: 인터랙티브 효과가 적용된 뷰
    func interactiveCard(isPressed: Bool = false) -> some View {
        self
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(KingDesignTokens.Animation.fast, value: isPressed)
            .background(
                RoundedRectangle(cornerRadius: KingDesignTokens.Radius.md)
                    .fill(isPressed ? KingDesignTokens.Colors.pressed : KingDesignTokens.Colors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: KingDesignTokens.Radius.md)
                    .stroke(
                        isPressed ? KingDesignTokens.Colors.primary : KingDesignTokens.Colors.border,
                        lineWidth: KingDesignTokens.BorderWidth.thin
                    )
            )
    }
}

// MARK: - Enhanced Error Handling

public extension View {
    
    /// KingToast를 사용한 에러 표시
    /// 
    /// - Parameters:
    ///   - error: 표시할 에러 메시지
    ///   - isPresented: 에러 표시 상태
    /// - Returns: 토스트 에러 표시가 가능한 뷰
    func errorToast(error: String?, isPresented: Binding<Bool>) -> some View {
        self.onChange(of: error) { _, newError in
            if let error = newError, !error.isEmpty {
                KingToastManager.shared.showError("오류", message: error)
                isPresented.wrappedValue = true
            }
        }
    }
    
    /// 통합 로딩 오버레이 (KingLoadingView 사용)
    /// 
    /// - Parameters:
    ///   - isLoading: 로딩 상태
    ///   - message: 로딩 메시지 (선택사항)
    /// - Returns: 통합 로딩 오버레이가 적용된 뷰
    func unifiedLoadingOverlay(isLoading: Bool, message: String? = nil) -> some View {
        self.overlay {
            if isLoading {
                KingLoadingView(
                    style: .fullScreen,
                    message: message ?? "로딩 중..."
                )
                .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(KingDesignTokens.Animation.normal, value: isLoading)
    }
}
