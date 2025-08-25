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
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: 20) {
                    // 잔액 카드
                    BalanceCard(
                        balance: "2.5",
                        symbol: "ETH",
                        usdValue: "$4,250.00"
                    )
                    
                    // 액션 버튼들
                    HStack(spacing: 12) {
                        ActionButton(
                            title: "보내기",
                            icon: "arrow.up.circle.fill",
                            gradient: LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        ) {
                            navigationPath.append(SendDestination.selectRecipient)
                        }
                        
                        ActionButton(
                            title: "받기",
                            icon: "arrow.down.circle.fill",
                            gradient: LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        ) {
                            showReceiveView = true
                        }
                    }
                    
                    // 최근 거래
                    VStack(alignment: .leading, spacing: 12) {
                        Text("최근 거래")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(0..<3) { _ in
                            TransactionCard(
                                type: .receive,
                                amount: "0.5",
                                symbol: "ETH",
                                timestamp: "5분 전",
                                status: .confirmed
                            )
                        }
                    }
                    
                    // 추가 스크롤 여백
                    Color.clear.frame(height: 120)
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
                        .font(.headline)
                        .foregroundColor(.primary)
                    
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
//                        .onChange(of: recipientAddress) { newValue in
//                            validateAddress(newValue)
//                        }
                        
                        Button {
                            // QR 스캔
                        } label: {
                            Image(systemName: "qrcode.viewfinder")
                                .font(.title2)
                                .foregroundStyle(LinearGradient.primaryGradient)
                                .frame(width: 48, height: 48)
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
                        }
                    }
                    
                    if !recipientAddress.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: isAddressValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.caption)
                            Text(isAddressValid ? "유효한 주소입니다" : "올바른 주소 형식이 아닙니다")
                                .font(.caption)
                        }
                        .foregroundColor(isAddressValid ? .green : .red)
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
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundColor(.kingBlue)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            if let name = recipientData.name {
                                Text(name)
                                    .font(.body)
                                    .fontWeight(.medium)
                            }
                            Text(formatAddress(recipientData.address))
                                .font(.caption)
                                .foregroundColor(.secondary)
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
                            .font(.headline)
                        
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
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // 잔액 정보
                    HStack {
                        Text("사용 가능")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(balance) ETH")
                            .font(.caption)
                            .fontWeight(.medium)
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
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(transactionData.amount) ETH")
                        .font(.largeTitle)
                        .fontWeight(.bold)
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
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(LinearGradient.primaryGradient)
                    .cornerRadius(16)
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
            .frame(height: 80)
            .background(gradient)
            .cornerRadius(16)
        }
    }
}
