import SwiftUI

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
    func loadingOverlay(isLoading: Bool, style: LoadingStyle = .spinner) -> some View {
        overlay {
            if isLoading {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    LoadingView(style: style, size: .medium)
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
    
    /// 키보드 높이에 따른 패딩 자동 조정
    func keyboardAdaptive() -> some View {
        modifier(KeyboardAdaptiveModifier())
    }
    
    /// 장치별 조건부 뷰
    @ViewBuilder
    func iPhone<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        if UIDevice.current.userInterfaceIdiom == .phone {
            content()
        } else {
            self
        }
    }
    
    @ViewBuilder
    func iPad<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            content()
        } else {
            self
        }
    }
    
    /// 햅틱 피드백 추가
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> some View {
        onTapGesture {
            let impactFeedback = UIImpactFeedbackGenerator(style: style)
            impactFeedback.impactOccurred()
        }
    }
    
    /// 커스텀 테두리
    func customBorder(
        color: Color = .gray.opacity(0.3),
        width: CGFloat = 1,
        cornerRadius: CGFloat = 8
    ) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(color, lineWidth: width)
        )
    }
    
    /// 섀도우 프리셋
    func shadowPreset(_ preset: ShadowPreset) -> some View {
        shadow(
            color: preset.color,
            radius: preset.radius,
            x: preset.offset.x,
            y: preset.offset.y
        )
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

// MARK: - Keyboard Adaptive Modifier

private struct KeyboardAdaptiveModifier: ViewModifier {
    @State private var keyboardHeight: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboardHeight)
            .animation(.easeInOut(duration: 0.3), value: keyboardHeight)
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                    keyboardHeight = keyboardFrame.cgRectValue.height
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                keyboardHeight = 0
            }
    }
}

// MARK: - Safe Area Extensions

public extension View {
    /// 안전 영역 여백 적용
    func safeAreaPadding(_ edges: Edge.Set = .all, _ length: CGFloat? = nil) -> some View {
        padding(edges, length)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 0)
            }
    }
}

// MARK: - Navigation Extensions

//public extension View {
//    /// 네비게이션 타이틀 스타일 설정
//    func navigationTitle(_ title: String, displayMode: NavigationBarItem.TitleDisplayMode = .automatic) -> some View {
//        navigationTitle(title)
//            .navigationBarTitleDisplayMode(displayMode)
//    }
//    
//    /// 네비게이션 바 숨기기/보이기
//    func navigationBarHidden(_ hidden: Bool = true) -> some View {
//        navigationBarHidden(hidden)
//    }
//}
