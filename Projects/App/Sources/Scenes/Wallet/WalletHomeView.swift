import SwiftUI
import DesignSystem
import Core

// MARK: - PreferenceKey
struct ScrollOffsetKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct WalletHomeView: View {
    @Binding var showTabBar: Bool
    @Binding var showReceiveView: Bool
    @State private var showSendView = false
    @State private var lastScrollOffset: CGFloat = 0
    @State private var isScrollingDown = false
    @State private var navigationPath = NavigationPath()
    @State private var glassTheme: GlassTheme = .vibrant
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: 20) {
                    // 초경량 SwiftUI Glass 잔액 카드
                    UltraLightweightBalanceCard(
                        balance: "2.5",
                        symbol: "ETH",
                        usdValue: "$4,250.00"
                    )
                    .scaleEffect(isScrollingDown ? 0.95 : 1.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isScrollingDown)
                    
                    // 초경량 SwiftUI Glass 액션 버튼들
                    HStack(spacing: 16) {
                        UltraLightweightSwiftUIButton(
                            icon: "arrow.up.circle.fill",
                            title: "보내기",
                            style: .crypto
                        ) {
                            navigationPath.append(SendDestination.selectRecipient)
                        }
                        .accessibilityLabel("이더리움 보내기")
                        .accessibilityHint("탭하여 이더리움을 다른 주소로 전송합니다")
                        
                        UltraLightweightSwiftUIButton(
                            icon: "arrow.down.circle.fill",
                            title: "받기",
                            style: .success
                        ) {
                            showReceiveView = true
                        }
                        .accessibilityLabel("이더리움 받기")
                        .accessibilityHint("탭하여 내 지갑 주소와 QR 코드를 확인합니다")
                    }
                    .padding(.horizontal, 8)
                    
                    // 초경량 SwiftUI Glass 최근 거래
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("최근 거래")
                                .kingStyle(.headlinePrimary)
                            Spacer()
                            UltraLightweightSwiftUIButton(
                                icon: "arrow.right"
                            ) {
                                // 모든 거래 내역으로 이동
                            }
                        }
                        .padding(.horizontal)
                        
                        ForEach(0..<3, id: \.self) { index in
                            UltraLightweightTransactionCard(
                                type: index % 2 == 0 ? .receive : .send,
                                amount: index == 0 ? "0.5" : index == 1 ? "1.2" : "0.8",
                                symbol: "ETH",
                                timestamp: index == 0 ? "5분 전" : index == 1 ? "1시간 전" : "3시간 전",
                                status: index == 1 ? .pending : .confirmed
                            )
                            .padding(.horizontal, 4)
                        }
                    }
                    
                    // 추가 스크롤 여백
                    Color.clear.frame(height: DesignTokens.Spacing.scrollBottomPadding)
                }
                .padding()
                .background(
                    GeometryReader { geometry in
                        Color.clear.preference(
                            key: ScrollOffsetKey.self,
                            value: geometry.frame(in: .named("scroll")).origin.y
                        )
                    }
                )
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetKey.self) { value in
                let delta = value - lastScrollOffset
                
                if abs(delta) > 5 {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isScrollingDown = delta < 0
                        showTabBar = delta > 0 || value >= 0
                    }
                }
                
                lastScrollOffset = value
            }
            .navigationTitle("지갑")
            .environment(\.glassTheme, glassTheme)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    // 테마 변경 메뉴
                    Menu {
                        Button("시스템 테마") {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                glassTheme = .system
                            }
                        }
                        Button("밝은 테마") {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                glassTheme = .light
                            }
                        }
                        Button("어두운 테마") {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                glassTheme = .dark
                            }
                        }
                        Button("생동감 테마") {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                glassTheme = .vibrant
                            }
                        }
                    } label: {
                        Image(systemName: "sparkles")
                            .foregroundColor(.primary)
                    }
                }
            }
            .navigationDestination(for: SendDestination.self) { destination in
                switch destination {
                case .selectRecipient:
                    SendRecipientNavigationView(navigationPath: $navigationPath)
                case .enterAmount(let recipientData):
                    SendAmountNavigationView(
                        recipientData: recipientData,
                        navigationPath: $navigationPath
                    )
                case .confirmTransaction(let transactionData):
                    SendConfirmNavigationView(
                        transactionData: transactionData,
                        navigationPath: $navigationPath
                    )
                }
            }
        }
    }
}

// MARK: - Navigation Destinations
enum SendDestination: Hashable {
    case selectRecipient
    case enterAmount(RecipientData)
    case confirmTransaction(TransactionData)
}

struct RecipientData: Hashable {
    let address: String
    let name: String?
}

struct TransactionData: Hashable {
    let recipient: RecipientData
    let amount: String
    let estimatedGasFee: String
}

// MARK: - Send Navigation Views
struct SendRecipientNavigationView: View {
    @Binding var navigationPath: NavigationPath
    @State private var recipientAddress = ""
    @State private var recipientName: String? = nil
    @State private var isAddressValid = false
    @FocusState private var isAddressFocused: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 주소 입력 섹션
                VStack(alignment: .leading, spacing: 12) {
                    Text("받는 사람")
                        .kingStyle(.headlinePrimary)
                    
                    HStack {
                        GlassTextField(
                            text: $recipientAddress,
                            placeholder: "0x... 형식의 이더리움 주소",
                            style: .default,
                            isSecure: true,
                            keyboardType: .default,
                            submitLabel: .next
                        )
                        .focused($isAddressFocused)
                        .onChange(of: recipientAddress) { _, newValue in
                            validateAddress(newValue)
                        }
                        
                        Button {
                            // QR 스캔
                        } label: {
                            Image(systemName: "qrcode.viewfinder")
                                .font(.title2)
                                .foregroundStyle(KingthereumGradients.accent)
                                .frame(width: 48, height: 48)
                                .background(.ultraThinMaterial)
                                .cornerRadius(DesignTokens.CornerRadius.md)
                        }
                    }
                    
                    if !recipientAddress.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: isAddressValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.caption)
                            Text(isAddressValid ? "유효한 주소입니다" : "올바른 주소 형식이 아닙니다")
                                .kingStyle(KingthereumTextStyle(
                                    font: KingthereumTypography.caption,
                                    color: isAddressValid ? KingthereumColors.success : KingthereumColors.error
                                ))
                        }
                        .foregroundColor(isAddressValid ? KingthereumColors.success : KingthereumColors.error)
                    }
                }
                .padding()
                .glassCard()
                
                Spacer(minLength: 100)
            }
            .padding()
        }
        .navigationTitle("이더리움 전송")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("다음") {
                    let recipientData = RecipientData(
                        address: recipientAddress,
                        name: recipientName
                    )
                    navigationPath.append(SendDestination.enterAmount(recipientData))
                }
                .disabled(!isAddressValid)
            }
        }
        .onAppear {
            isAddressFocused = true
        }
    }
    
    private func validateAddress(_ address: String) {
        isAddressValid = address.hasPrefix("0x") && address.count == 42
    }
}

struct SendAmountNavigationView: View {
    let recipientData: RecipientData
    @Binding var navigationPath: NavigationPath
    @State private var amount = ""
    @State private var isAmountValid = false
    @FocusState private var isAmountFocused: Bool
    
    private let balance = "2.5"
    private let estimatedGasFee = "0.0021"
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 받는 사람 정보
                VStack(alignment: .leading, spacing: 8) {
                    Text("받는 사람")
                        .kingStyle(.captionPrimary)
                    
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundColor(KingthereumColors.accent)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            if let name = recipientData.name {
                                Text(name)
                                    .kingStyle(.bodyPrimary)
                            }
                            Text(formatAddress(recipientData.address))
                                .kingStyle(.captionPrimary)
                        }
                        
                        Spacer()
                    }
                }
                .padding()
                .glassCard(style: .subtle)
                
                // 금액 입력
                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Text("보낼 금액")
                            .kingStyle(.headlinePrimary)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            TextField("0", text: $amount)
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)
                                .keyboardType(.decimalPad)
                                .focused($isAmountFocused)
                                .onChange(of: amount) { _, newValue in
                                    validateAmount(newValue)
                                }
                            
                            Text("ETH")
                                .kingStyle(.bodySecondary)
                        }
                    }
                    
                    // 잔액 정보
                    HStack {
                        Text("사용 가능")
                            .kingStyle(.captionPrimary)
                        Spacer()
                        Text("\(balance) ETH")
                            .kingStyle(KingthereumTextStyle(
                                font: KingthereumTypography.caption,
                                color: KingthereumColors.textPrimary
                            ))
                    }
                }
                .padding()
                .glassCard()
                
                Spacer(minLength: 100)
            }
            .padding()
        }
        .navigationTitle("금액 입력")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("다음") {
                    let transactionData = TransactionData(
                        recipient: recipientData,
                        amount: amount,
                        estimatedGasFee: estimatedGasFee
                    )
                    navigationPath.append(SendDestination.confirmTransaction(transactionData))
                }
                .disabled(!isAmountValid || amount.isEmpty)
            }
        }
        .onAppear {
            isAmountFocused = true
        }
    }
    
    private func formatAddress(_ address: String) -> String {
        guard address.count > 10 else { return address }
        let prefix = address.prefix(6)
        let suffix = address.suffix(4)
        return "\(prefix)...\(suffix)"
    }
    
    private func validateAmount(_ amount: String) {
        guard let amountValue = Double(amount),
              let balance = Double(balance),
              let gasFee = Double(estimatedGasFee) else {
            isAmountValid = false
            return
        }
        isAmountValid = amountValue > 0 && (amountValue + gasFee) <= balance
    }
}

struct SendConfirmNavigationView: View {
    let transactionData: TransactionData
    @Binding var navigationPath: NavigationPath
    @State private var isProcessing = false
    @State private var showSuccess = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 거래 요약
                VStack(spacing: 20) {
                    Text("거래 확인")
                        .kingStyle(.headlinePrimary)
                    
                    Text("\(transactionData.amount) ETH")
                        .kingStyle(KingthereumTextStyle(
                            font: KingthereumTypography.cryptoBalanceLarge,
                            color: KingthereumColors.textPrimary
                        ))
                }
                .padding()
                .frame(maxWidth: .infinity)
                .glassCard(style: .prominent)
                
                // 전송 버튼
                Button {
                    sendTransaction()
                } label: {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "paperplane.fill")
                            Text("전송하기")
                                .kingStyle(.buttonPrimary)
                        }
                    }
                    .font(.headline)
                    .foregroundColor(KingthereumColors.textInverse)
                    .frame(maxWidth: .infinity)
                    .frame(height: DesignTokens.Size.Button.lg)
                    .background(KingthereumGradients.buttonPrimary)
                    .cornerRadius(DesignTokens.CornerRadius.lg)
                }
                .disabled(isProcessing)
                
                Spacer(minLength: 50)
            }
            .padding()
        }
        .navigationTitle("거래 확인")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(isProcessing)
        .sheet(isPresented: $showSuccess) {
            SendSuccessView(
                transactionHash: "0x1234567890abcdef"
            )
        }
    }
    
    private func sendTransaction() {
        isProcessing = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isProcessing = false
            showSuccess = true
        }
    }
}

// MARK: - Helper Views
struct ActionButton: View {
    let title: String
    let icon: String
    let gradient: LinearGradient
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: DesignTokens.Size.Card.prominentHeight)
            .background(gradient)
            .cornerRadius(DesignTokens.CornerRadius.lg)
        }
    }
}

// MARK: - Previews
#Preview("WalletHomeView") {
    WalletHomeView(
        showTabBar: .constant(true),
        showReceiveView: .constant(false)
    )
}

#Preview("WalletHomeView - Dark Mode") {
    WalletHomeView(
        showTabBar: .constant(true),
        showReceiveView: .constant(false)
    )
    .preferredColorScheme(.dark)
}
