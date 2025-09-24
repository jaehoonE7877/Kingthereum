import SwiftUI
import DesignSystem
import Entity

/// 🔐 Premium Fintech Welcome - Minimalist Design
struct PremiumWelcomeView: View {
    @Bindable var viewStore: AuthenticationViewStore

    private let highlightItems = [
        ("shield.checkerboard", "자산 보호", "하드웨어 수준의 보안으로 개인키 안전보관"),
        ("bolt.horizontal.fill", "즉시 연결", "메인넷 · 커스텀 RPC 즉시 연결 지원"),
        ("chart.line.uptrend.xyaxis", "실시간 인사이트", "포트폴리오와 가스 수수료를 한눈에")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: KingDesignTokens.Spacing.xl) {
                heroCard

                VStack(spacing: KingDesignTokens.Spacing.md) {
                    ForEach(highlightItems, id: \.0) { item in
                        AuthenticationGlassCard {
                            HStack(alignment: .top, spacing: KingDesignTokens.Spacing.md) {
                                Image(systemName: item.0)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(KingDesignTokens.Colors.accent)
                                    .frame(width: 40, height: 40)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(KingDesignTokens.Colors.accent.opacity(0.12))
                                    )

                                VStack(alignment: .leading, spacing: KingDesignTokens.Spacing.xs) {
                                    Text(item.1)
                                        .font(KingDesignTokens.Typography.body)
                                        .fontWeight(.semibold)
                                        .foregroundColor(KingDesignTokens.Colors.primaryText)

                                    Text(item.2)
                                        .font(KingDesignTokens.Typography.caption)
                                        .foregroundColor(KingDesignTokens.Colors.secondaryText)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, KingDesignTokens.Spacing.lg)
            .padding(.bottom, 160)
        }
        .safeAreaInset(edge: .bottom) {
            AuthenticationCTAContainer {
                Button {
                    viewStore.requestFlow(.showMethodSelection)
                } label: {
                    Text("새 지갑 만들기")
                        .font(KingDesignTokens.Typography.body)
                        .fontWeight(.semibold)
                        .foregroundColor(KingDesignTokens.Colors.systemWhite)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(KingDesignTokens.Colors.accent)
                        .cornerRadius(KingDesignTokens.Radius.lg)
                }
                .disabled(viewStore.isLoading)

                Button {
                    viewStore.requestFlow(.showWalletImport)
                } label: {
                    Text("복구 구문으로 로그인")
                        .font(KingDesignTokens.Typography.body)
                        .foregroundColor(KingDesignTokens.Colors.secondaryText)
                        .frame(maxWidth: .infinity)
                }
                .disabled(viewStore.isLoading)
            }
        }
        .overlay(alignment: .center) {
            if viewStore.isLoading {
                LoadingOverlay()
            }
        }
    }

    private var heroCard: some View {
        AuthenticationGlassCard {
            VStack(alignment: .leading, spacing: KingDesignTokens.Spacing.md) {
                Text("Premium Ethereum Wallet")
                    .font(KingDesignTokens.Typography.caption)
                    .foregroundColor(KingDesignTokens.Colors.accent)
                    .textCase(.uppercase)

                Text("완벽한 온보딩 경험")
                    .font(KingDesignTokens.Typography.displayM)
                    .foregroundColor(KingDesignTokens.Colors.primaryText)

                Text("Kingthereum은 글로벌 커버리지와 프라이빗 보안을 결합한 하이엔드 코인 지갑입니다.")
                    .font(KingDesignTokens.Typography.caption)
                    .foregroundColor(KingDesignTokens.Colors.secondaryText)
            }
            .overlay(alignment: .topTrailing) {
                LinearGradient(colors: [
                    KingDesignTokens.Colors.accent.opacity(0.35),
                    KingDesignTokens.Colors.surface.opacity(0.05)
                ], startPoint: .topLeading, endPoint: .bottomTrailing)
                .frame(width: 140, height: 140)
                .clipShape(Circle())
                .offset(x: 40, y: -60)
            }
        }
    }
}

// MARK: - Supporting Views

/// Professional loading overlay
private struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            KingDesignTokens.Colors.background.opacity(0.9)
                .ignoresSafeArea(.all)
            
            VStack(spacing: KingDesignTokens.Spacing.md) {
                ProgressView()
                    .tint(KingDesignTokens.Colors.accent)
                
                Text("Creating wallet...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(KingDesignTokens.Colors.secondaryText)
            }
        }
    }
}
