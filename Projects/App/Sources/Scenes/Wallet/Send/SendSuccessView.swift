import SwiftUI
import DesignSystem

struct SendSuccessView: View {
    let transactionHash: String?
    @Environment(\.dismiss) private var dismiss
    @State private var showCheckmark = false
    @State private var showContent = false
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient.enhancedBackgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Success Animation
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(LinearGradient.primaryGradient, lineWidth: 3)
                        .frame(width: 120, height: 120)
                        .scaleEffect(showContent ? 1.0 : 0.8)
                        .opacity(showContent ? 1.0 : 0.0)
                    
                    // Inner circle
                    Circle()
                        .fill(LinearGradient.primaryGradient)
                        .frame(width: 100, height: 100)
                        .scaleEffect(showCheckmark ? 1.0 : 0.5)
                        .opacity(showCheckmark ? 1.0 : 0.0)
                    
                    // Checkmark
                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(showCheckmark ? 1.0 : 0.3)
                        .opacity(showCheckmark ? 1.0 : 0.0)
                }
                .onAppear {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0)) {
                        showCheckmark = true
                    }
                    
                    withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                        showContent = true
                    }
                }
                
                VStack(spacing: 16) {
                    Text("송금 완료!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(LinearGradient.primaryGradient)
                        .scaleEffect(showContent ? 1.0 : 0.8)
                        .opacity(showContent ? 1.0 : 0.0)
                    
                    Text("이더리움 거래가 성공적으로 전송되었습니다")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .scaleEffect(showContent ? 1.0 : 0.8)
                        .opacity(showContent ? 1.0 : 0.0)
                }
                
                if showContent {
                    VStack(spacing: 16) {
                        if let hash = transactionHash {
                            transactionHashSection(hash)
                        }
                        
                        actionButtons
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .gesture(
            DragGesture()
                .onEnded { gesture in
                    if gesture.translation.height > 100 && abs(gesture.translation.width) < 100 {
                        dismiss()
                    }
                }
        )
    }
    
    private func transactionHashSection(_ hash: String) -> some View {
        VStack(spacing: 12) {
            Text("거래 해시")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                Text(formatTransactionHash(hash))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                
                Button {
                    copyTransactionHash(hash)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                        Text("복사")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .glassCard(style: .default)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                openEtherscan()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "link")
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("Etherscan에서 보기")
                        .font(.system(size: 16, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(.ultraThinMaterial)
                .foregroundStyle(LinearGradient.primaryGradient)
                .cornerRadius(12)
                .glassCard(style: .subtle)
            }
            
            Button {
                dismiss()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("완료")
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(LinearGradient.primaryGradient)
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: .kingBlue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
    }
    
    private func formatTransactionHash(_ hash: String) -> String {
        guard hash.count > 10 else { return hash }
        let start = String(hash.prefix(8))
        let end = String(hash.suffix(8))
        return "\(start)...\(end)"
    }
    
    private func copyTransactionHash(_ hash: String) {
        UIPasteboard.general.string = hash
        
        // 햅틱 피드백
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // 토스트 알림 (실제 구현에서는 별도의 토스트 시스템 사용)
        print("거래 해시가 클립보드에 복사되었습니다")
    }
    
    private func openEtherscan() {
        guard let hash = transactionHash,
              let url = URL(string: "https://etherscan.io/tx/\(hash)") else {
            return
        }
        
        UIApplication.shared.open(url)
    }
}

#Preview {
    SendSuccessView(transactionHash: "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef")
}