import SwiftUI
import DesignSystem
import Core

// MARK: - Premium Fintech Dashboard

struct WalletHomeView: View {
    @Binding var showTabBar: Bool
    @Binding var showReceiveView: Bool
    @State private var showSendView = false
    @State private var lastScrollOffset: CGFloat = 0
    @State private var isScrollingDown = false
    
    // MARK: - Mock Data
    @State private var balance = "2.5"
    @State private var usdValue = "$4,250.00"
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    LazyVStack(spacing: 32) {
                        // 대형 미니멀 잔액 카드
                        PremiumBalanceCard(
                            balance: balance,
                            symbol: "ETH",
                            usdValue: usdValue,
                            isLoading: isLoading,
                            isScrollingDown: isScrollingDown
                        )
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        
                        // 2개 액션 버튼 (Send/Receive)
                        MinimalActionButtons(
                            onSendTapped: { showSendView = true },
                            onReceiveTapped: { showReceiveView = true }
                        )
                        .padding(.horizontal, 24)
                        
                        // 극도로 심플한 거래 리스트
                        MinimalTransactionsList()
                            .padding(.horizontal, 24)
                        
                        Spacer(minLength: 120)
                    }
                    .background(
                        GeometryReader { scrollGeometry in
                            Color.clear.preference(
                                key: ScrollOffsetKey.self,
                                value: scrollGeometry.frame(in: .named("scroll")).minY
                            )
                        }
                    )
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetKey.self) { value in
                    handleScrollOffset(value)
                }
            }
            .background(KingGradients.minimalistBackground)
            .navigationTitle("지갑")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(KingGradients.minimalistBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onChange(of: isScrollingDown) { _, newValue in
                withAnimation(.easeInOut(duration: 0.2)) {
                    showTabBar = !newValue
                }
            }
            .task {
                loadWalletData()
            }
        }
        .sheet(isPresented: $showSendView) {
            SendView()
        }
    }
    
    // MARK: - Actions
    
    private func handleScrollOffset(_ offset: CGFloat) {
        let currentOffset = -offset
        let threshold: CGFloat = 100
        
        withAnimation(.easeInOut(duration: 0.2)) {
            isScrollingDown = currentOffset > lastScrollOffset && currentOffset > threshold
        }
        
        lastScrollOffset = currentOffset
    }
    
    private func loadWalletData() {
        // Mock loading simulation
        withAnimation(.easeInOut(duration: 0.3)) {
            isLoading = false
        }
    }
}

// MARK: - Premium Balance Card

struct PremiumBalanceCard: View {
    let balance: String
    let symbol: String
    let usdValue: String
    let isLoading: Bool
    let isScrollingDown: Bool
    
    @State private var pulseAnimation = false
    @State private var glowIntensity: Double = 0.3
    
    var body: some View {
        VStack(spacing: 28) {
            // 헤더: 총 잔액
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("총 잔액")
                        .font(KingTypography.bodyLarge)
                        .foregroundColor(KingColors.textSecondary)
                    
                    Text("이더리움 지갑")
                        .font(KingTypography.bodyMedium)
                        .foregroundColor(KingColors.textTertiary)
                }
                
                Spacer()
                
                // Ethereum Symbol with Golden Glow
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    KingColors.exclusiveGold.opacity(0.3),
                                    KingColors.exclusiveGold.opacity(0.1)
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: 25
                            )
                        )
                        .frame(width: 50, height: 50)
                        .shadow(
                            color: KingColors.exclusiveGold.opacity(glowIntensity),
                            radius: 16,
                            x: 0,
                            y: 0
                        )
                        .scaleEffect(pulseAnimation ? 1.08 : 1.0)
                    
                    Text("Ξ")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    KingColors.exclusiveGold,
                                    KingColors.exclusiveGold.opacity(0.8)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            }
            
            // 메인 잔액 표시
            VStack(spacing: 12) {
                if isLoading {
                    BalanceLoadingSkeleton()
                } else {
                    // 대형 골드 수치
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(balance)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        KingColors.exclusiveGold,
                                        KingColors.exclusiveGold.opacity(0.8),
                                        KingColors.trustPurple.opacity(0.8)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(
                                color: KingColors.exclusiveGold.opacity(0.3),
                                radius: 8,
                                x: 0,
                                y: 4
                            )
                        
                        Text(symbol)
                            .font(KingTypography.headlineLarge)
                            .foregroundColor(KingColors.textSecondary)
                            .padding(.bottom, 4)
                    }
                    
                    // USD 값
                    Text(usdValue)
                        .font(KingTypography.bodyLarge)
                        .foregroundColor(KingColors.textTertiary)
                }
            }
        }
        .padding(32)
        .background(
            ZStack {
                // 미니멀 글래스 배경
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThinMaterial)
                
                // 서브틀 골드 보더
                RoundedRectangle(cornerRadius: 28)
                    .stroke(
                        LinearGradient(
                            colors: [
                                KingColors.exclusiveGold.opacity(0.3),
                                KingColors.exclusiveGold.opacity(0.8).opacity(0.2),
                                KingColors.trustPurple.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
        )
        .scaleEffect(isScrollingDown ? 0.96 : 1.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isScrollingDown)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                glowIntensity = 0.8
            }
            withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
    }
}

// MARK: - Minimal Action Buttons

struct MinimalActionButtons: View {
    let onSendTapped: () -> Void
    let onReceiveTapped: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            // Send Button
            GoldenActionButton(
                icon: "arrow.up.right",
                title: "보내기",
                style: .send,
                action: onSendTapped
            )
            
            // Receive Button  
            GoldenActionButton(
                icon: "arrow.down.left",
                title: "받기",
                style: .receive,
                action: onReceiveTapped
            )
        }
    }
}

// MARK: - Golden Action Button

struct GoldenActionButton: View {
    let icon: String
    let title: String
    let style: ButtonStyle
    let action: () -> Void
    
    enum ButtonStyle {
        case send
        case receive
    }
    
    @State private var isPressed = false
    @State private var buttonGlow = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                // 골드 아이콘
                ZStack {
                    Circle()
                        .fill(iconBackgroundGradient)
                        .frame(width: 64, height: 64)
                        .shadow(
                            color: shadowColor.opacity(buttonGlow ? 0.6 : 0.3),
                            radius: buttonGlow ? 20 : 12,
                            x: 0,
                            y: 6
                        )
                        .scaleEffect(buttonGlow ? 1.05 : 1.0)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.white)
                }
                
                // 미니멀 텍스트
                Text(title)
                    .font(KingTypography.buttonPrimary)
                    .foregroundColor(KingColors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        KingColors.exclusiveGold.opacity(0.2),
                                        KingColors.trustPurple.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) { pressing in
            isPressed = pressing
        } perform: {
            // Long press action if needed
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                buttonGlow = true
            }
        }
    }
    
    private var iconBackgroundGradient: LinearGradient {
        switch style {
        case .send:
            return LinearGradient(
                colors: [
                    KingColors.trustPurple,
                    KingColors.trustPurple.opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .receive:
            return KingGradients.premiumGoldButton
        }
    }
    
    private var shadowColor: Color {
        switch style {
        case .send:
            return KingColors.trustPurple
        case .receive:
            return KingColors.exclusiveGold
        }
    }
}

// MARK: - Minimal Transactions List

struct MinimalTransactionsList: View {
    
    @State private var mockTransactions = [
        MockTransaction(type: .receive, amount: "0.5", time: "5분 전"),
        MockTransaction(type: .send, amount: "1.2", time: "1시간 전"),
        MockTransaction(type: .receive, amount: "0.8", time: "3시간 전")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 섹션 헤더
            HStack {
                Text("최근 거래")
                    .font(KingTypography.headlineLarge)
                    .foregroundColor(KingColors.textPrimary)
                
                Spacer()
                
                Button("전체보기") {
                    // Navigate to full history
                }
                .font(KingTypography.buttonSecondary)
                .foregroundColor(KingColors.exclusiveGold)
            }
            
            // 극도로 심플한 거래 리스트
            VStack(spacing: 12) {
                ForEach(mockTransactions, id: \.id) { transaction in
                    MinimalTransactionRow(transaction: transaction)
                }
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Minimal Transaction Row

struct MinimalTransactionRow: View {
    let transaction: MockTransaction
    
    var body: some View {
        HStack(spacing: 16) {
            // 타입 아이콘 (미니멀)
            ZStack {
                Circle()
                    .fill(iconBackgroundColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: iconName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(iconColor)
            }
            
            // 거래 정보 (breathable space)
            VStack(alignment: .leading, spacing: 4) {
                Text(transactionTitle)
                    .font(KingTypography.bodyMedium)
                    .foregroundColor(KingColors.textPrimary)
                
                Text(transaction.time)
                    .font(KingTypography.caption)
                    .foregroundColor(KingColors.textTertiary)
            }
            
            Spacer()
            
            // 금액 (골드 accent)
            Text("\(amountPrefix)\(transaction.amount) ETH")
                .font(KingTypography.bodyMedium)
                .fontWeight(.semibold)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            KingColors.exclusiveGold,
                            KingColors.exclusiveGold.opacity(0.8)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            KingColors.textTertiary.opacity(0.1),
                            lineWidth: 0.5
                        )
                )
        )
    }
    
    private var iconName: String {
        transaction.type == .send ? "arrow.up.right" : "arrow.down.left"
    }
    
    private var iconColor: Color {
        transaction.type == .send ? KingColors.trustPurple : KingColors.exclusiveGold
    }
    
    private var iconBackgroundColor: Color {
        transaction.type == .send ? KingColors.trustPurple : KingColors.exclusiveGold
    }
    
    private var transactionTitle: String {
        transaction.type == .send ? "전송" : "수신"
    }
    
    private var amountPrefix: String {
        transaction.type == .send ? "-" : "+"
    }
}

// MARK: - Balance Loading Skeleton

struct BalanceLoadingSkeleton: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12)
                .fill(KingColors.textTertiary.opacity(0.3))
                .frame(width: 220, height: 48)
            
            RoundedRectangle(cornerRadius: 8)
                .fill(KingColors.textTertiary.opacity(0.2))
                .frame(width: 140, height: 24)
        }
        .opacity(isAnimating ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: isAnimating)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Mock Data

struct MockTransaction: Identifiable {
    let id = UUID()
    let type: TransactionType
    let amount: String
    let time: String
    
    enum TransactionType {
        case send, receive
    }
}

// MARK: - ScrollOffsetKey (재사용)

struct ScrollOffsetKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}