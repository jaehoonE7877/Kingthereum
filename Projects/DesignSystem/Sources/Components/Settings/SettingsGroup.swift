import SwiftUI
import Core

/// 설정 그룹을 위한 재사용 가능한 컴포넌트
/// 설정 화면에서 관련 항목들을 그룹화하여 표시할 때 사용
public struct SettingsGroup<Content: View>: View {
    let title: String
    let content: Content
    
    public init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal, 4)
            
            content
        }
    }
}