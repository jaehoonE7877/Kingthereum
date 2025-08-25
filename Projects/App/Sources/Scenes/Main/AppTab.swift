import SwiftUI

/// 앱의 메인 탭
public enum AppTab: String, CaseIterable, Identifiable, Hashable {
    case home = "home"
    case wallet = "wallet"
    case history = "history"
    case settings = "settings"
    
    public var id: String { self.rawValue }
    
    public var title: String {
        switch self {
        case .home: return "홈"
        case .wallet: return "지갑"
        case .history: return "내역"
        case .settings: return "설정"
        }
    }
    
    public var icon: String {
        switch self {
        case .home: return "house.fill"
        case .wallet: return "creditcard.fill"
        case .history: return "clock.fill"
        case .settings: return "gearshape.fill"
        }
    }
}