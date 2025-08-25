import SwiftUI
import Core

/// 설정 행을 위한 재사용 가능한 컴포넌트
/// 아이콘, 제목, 값, 액션을 포함하는 설정 항목 표시용
public struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String?
    let action: () -> Void
    
    @State private var isPressed = false
    
    public init(
        icon: String,
        iconColor: Color,
        title: String,
        value: String? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.value = value
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // 아이콘
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(iconColor)
                    .frame(width: 32, height: 32)
                
                // 타이틀
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // 값
                if let value = value {
                    Text(value)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                // 화살표
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(isPressed ? 0.1 : 0))
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(SettingsRowButtonStyle(isPressed: $isPressed))
    }
}

struct SettingsRowButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, newValue in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = newValue
                }
            }
    }
}

#Preview {
    VStack {
        SettingsRow(
            icon: "moon.circle.fill",
            iconColor: .purple,
            title: "화면 모드",
            value: "시스템"
        ) {
            print("Settings row tapped")
        }
        
        SettingsRow(
            icon: "bell.circle.fill",
            iconColor: .orange,
            title: "알림"
        ) {
            print("Notification settings tapped")
        }
    }
    .padding()
}