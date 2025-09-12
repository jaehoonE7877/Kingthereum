import SwiftUI

// MARK: - Toast Type
public enum KingToastType {
    case success
    case error
    case warning
    case info
    case custom(icon: String, color: Color)
    
    var icon: String {
        switch self {
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "xmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .info:
            return "info.circle.fill"
        case .custom(let icon, _):
            return icon
        }
    }
    
    var color: Color {
        switch self {
        case .success:
            return KingDesignTokens.Colors.success
        case .error:
            return KingDesignTokens.Colors.error
        case .warning:
            return KingDesignTokens.Colors.warning
        case .info:
            return KingDesignTokens.Colors.info
        case .custom(_, let color):
            return color
        }
    }
}

// MARK: - Toast Position
public enum KingToastPosition {
    case top
    case bottom
    case center
}

// MARK: - Toast Item
public struct KingToastItem: Identifiable, Equatable {
    public let id = UUID()
    public let type: KingToastType
    public let title: String
    public let message: String?
    public let duration: Double
    public let action: (() -> Void)?
    public let actionTitle: String?
    
    public init(
        type: KingToastType,
        title: String,
        message: String? = nil,
        duration: Double = 3.0,
        action: (() -> Void)? = nil,
        actionTitle: String? = nil
    ) {
        self.type = type
        self.title = title
        self.message = message
        self.duration = duration
        self.action = action
        self.actionTitle = actionTitle
    }
    
    public static func == (lhs: KingToastItem, rhs: KingToastItem) -> Bool {
        lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.message == rhs.message &&
        lhs.duration == rhs.duration &&
        lhs.actionTitle == rhs.actionTitle
    }
}

// MARK: - Toast View
public struct KingToast: View {
    let item: KingToastItem
    let onDismiss: () -> Void
    
    @State private var isShowing = false
    @State private var isDragging = false
    @State private var dragOffset: CGSize = .zero
    
    public init(
        item: KingToastItem,
        onDismiss: @escaping () -> Void
    ) {
        self.item = item
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        HStack(spacing: KingDesignTokens.Spacing.m) {
            // Icon
            Image(systemName: item.type.icon)
                .font(.system(size: KingDesignTokens.Sizing.iconMD))
                .foregroundColor(item.type.color)
                .frame(width: KingDesignTokens.Sizing.iconLG, height: KingDesignTokens.Sizing.iconLG)
                .background(item.type.color.opacity(0.1))
                .clipShape(Circle())
            
            // Content
            VStack(alignment: .leading, spacing: KingDesignTokens.Spacing.xxs) {
                Text(item.title)
                    .font(KingDesignTokens.Typography.labelLarge)
                    .foregroundColor(KingDesignTokens.Colors.primaryText)
                    .lineLimit(2)
                
                if let message = item.message {
                    Text(message)
                        .font(KingDesignTokens.Typography.caption)
                        .foregroundColor(KingDesignTokens.Colors.secondaryText)
                        .lineLimit(3)
                }
            }
            
            Spacer()
            
            // Action Button
            if let action = item.action, let actionTitle = item.actionTitle {
                Button(action: action) {
                    Text(actionTitle)
                        .font(KingDesignTokens.Typography.labelMedium)
                        .foregroundColor(item.type.color)
                }
                .buttonStyle(.plain)
            }
            
            // Close Button
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(KingDesignTokens.Colors.tertiaryText)
                    .frame(width: 24, height: 24)
                    .background(KingDesignTokens.Colors.surfaceVariant)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, KingDesignTokens.Spacing.m)
        .padding(.vertical, KingDesignTokens.Spacing.sm)
        .background(toastBackground)
        .clipShape(RoundedRectangle(cornerRadius: KingDesignTokens.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: KingDesignTokens.Radius.md)
                .stroke(KingDesignTokens.Colors.border.opacity(0.2), lineWidth: KingDesignTokens.BorderWidth.hairline)
        )
        .shadow(
            color: KingDesignTokens.Colors.shadow,
            radius: 12,
            x: 0,
            y: 4
        )
        .offset(y: dragOffset.height)
        .opacity(isShowing ? 1 : 0)
        .scaleEffect(isShowing ? 1 : 0.9)
        .animation(KingDesignTokens.Animation.spring, value: isShowing)
        .animation(KingDesignTokens.Animation.fast, value: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if abs(value.translation.height) < 100 {
                        dragOffset = value.translation
                    }
                }
                .onEnded { value in
                    if abs(value.translation.height) > 50 {
                        onDismiss()
                    } else {
                        withAnimation(KingDesignTokens.Animation.spring) {
                            dragOffset = .zero
                        }
                    }
                }
        )
        .onAppear {
            withAnimation {
                isShowing = true
            }
            
            if item.duration > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + item.duration) {
                    onDismiss()
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.type) 알림: \(item.title). \(item.message ?? "")")
        .accessibilityHint(item.actionTitle != nil ? "액션 가능" : "닫기 가능")
    }
    
    @ViewBuilder
    private var toastBackground: some View {
        ZStack {
            Rectangle()
                .fill(.clear)
                .background(KingDesignTokens.Glass.regular)
            KingDesignTokens.Colors.surface.opacity(0.95)
        }
    }
}

// MARK: - Toast Manager
@MainActor
public class KingToastManager: ObservableObject {
    @Published public var toasts: [KingToastItem] = []
    public var position: KingToastPosition = .top
    
    public static let shared = KingToastManager()
    
    private init() {}
    
    public func show(_ item: KingToastItem) {
        withAnimation {
            toasts.append(item)
        }
    }
    
    public func show(
        type: KingToastType,
        title: String,
        message: String? = nil,
        duration: Double = 3.0,
        action: (() -> Void)? = nil,
        actionTitle: String? = nil
    ) {
        let item = KingToastItem(
            type: type,
            title: title,
            message: message,
            duration: duration,
            action: action,
            actionTitle: actionTitle
        )
        show(item)
    }
    
    public func dismiss(_ item: KingToastItem) {
        withAnimation {
            toasts.removeAll { $0.id == item.id }
        }
    }
    
    public func dismissAll() {
        withAnimation {
            toasts.removeAll()
        }
    }
}

// MARK: - Toast Container View
public struct KingToastContainer: View {
    @ObservedObject private var manager = KingToastManager.shared
    let position: KingToastPosition
    
    public init(position: KingToastPosition = .top) {
        self.position = position
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(manager.toasts) { toast in
                    toastView(for: toast, in: geometry)
                }
            }
        }
        .allowsHitTesting(false)
    }
    
    @ViewBuilder
    private func toastView(for toast: KingToastItem, in geometry: GeometryProxy) -> some View {
        VStack {
            if position == .bottom || position == .center {
                Spacer()
            }
            
            KingToast(item: toast) {
                manager.dismiss(toast)
            }
            .padding(.horizontal)
            .transition(
                .asymmetric(
                    insertion: .move(edge: position == .bottom ? .bottom : .top)
                        .combined(with: .opacity),
                    removal: .move(edge: position == .bottom ? .bottom : .top)
                        .combined(with: .opacity)
                )
            )
            .zIndex(Double(manager.toasts.firstIndex(where: { $0.id == toast.id }) ?? 0))
            .offset(y: offsetY(for: toast))
            
            if position == .top || position == .center {
                Spacer()
            }
        }
        .allowsHitTesting(true)
    }
    
    private func offsetY(for toast: KingToastItem) -> CGFloat {
        guard let index = manager.toasts.firstIndex(where: { $0.id == toast.id }) else {
            return 0
        }
        
        let spacing: CGFloat = 70
        let offset = CGFloat(index) * spacing
        
        switch position {
        case .top:
            return offset
        case .bottom:
            return -offset
        case .center:
            return 0
        }
    }
}

// MARK: - View Extension
public extension View {
    /// Add toast container to any view
    func toastContainer(position: KingToastPosition = .top) -> some View {
        self.overlay(
            KingToastContainer(position: position)
                .animation(KingDesignTokens.Animation.normal, value: KingToastManager.shared.toasts)
        )
    }
}

// MARK: - Convenience Methods
public extension KingToastManager {
    func showSuccess(_ title: String, message: String? = nil) {
        show(type: .success, title: title, message: message)
    }
    
    func showError(_ title: String, message: String? = nil) {
        show(type: .error, title: title, message: message)
    }
    
    func showWarning(_ title: String, message: String? = nil) {
        show(type: .warning, title: title, message: message)
    }
    
    func showInfo(_ title: String, message: String? = nil) {
        show(type: .info, title: title, message: message)
    }
}

// MARK: - Preview
#Preview("KingToast Examples") {
    VStack(spacing: KingDesignTokens.Spacing.xl) {
        // Buttons to trigger toasts
        VStack(spacing: KingDesignTokens.Spacing.m) {
            KingButton("Show Success", style: .primary) {
                KingToastManager.shared.showSuccess(
                    "Transaction Sent!",
                    message: "0.5 ETH sent successfully to 0x742d...8923"
                )
            }
            
            KingButton("Show Error", style: .primary) {
                KingToastManager.shared.showError(
                    "Transaction Failed",
                    message: "Insufficient gas fee. Please try again."
                )
            }
            
            KingButton("Show Warning", style: .primary) {
                KingToastManager.shared.showWarning(
                    "Low Balance",
                    message: "Your ETH balance is below 0.01"
                )
            }
            
            KingButton("Show Info", style: .primary) {
                KingToastManager.shared.showInfo(
                    "Network Changed",
                    message: "Switched to Ethereum Mainnet"
                )
            }
            
            KingButton("Show with Action", style: .secondary) {
                KingToastManager.shared.show(
                    type: .info,
                    title: "New Update Available",
                    message: "Version 2.0 is now available",
                    action: {
                        print("Update tapped")
                    },
                    actionTitle: "Update"
                )
            }
        }
        .padding()
        
        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(KingDesignTokens.Colors.background)
    .toastContainer(position: .top)
}