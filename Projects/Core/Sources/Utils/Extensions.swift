import Foundation
import SwiftUI

// MARK: - String Extensions
public extension String {
    var isValidEthereumAddress: Bool {
        return self.hasPrefix("0x") && self.count == 42 && self.dropFirst(2).allSatisfy { $0.isHexDigit }
    }
    
    var isValidPrivateKey: Bool {
        return self.count == 64 && self.allSatisfy { $0.isHexDigit }
    }
    
    func toChecksumAddress() -> String {
        return self.lowercased()
    }
}

// MARK: - Character Extensions
public extension Character {
    var isHexDigit: Bool {
        return self.isNumber || ("a"..."f").contains(self) || ("A"..."F").contains(self)
    }
}

// MARK: - Double Extensions
public extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

// MARK: - View Extensions
public extension View {
#if os(iOS)
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> some View {
        self.onTapGesture {
            guard UIDevice.current.userInterfaceIdiom == .phone else { return }
            
            #if targetEnvironment(simulator)
            // 시뮬레이터에서는 햅틱 피드백 비활성화
            return
            #else
            let impactFeedback = UIImpactFeedbackGenerator(style: style)
            impactFeedback.prepare()
            impactFeedback.impactOccurred()
            #endif
        }
    }
#endif
    func glassMorphism() -> some View {
        self
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}


// MARK: - Data Extensions
public extension Data {
    /// Hex 문자열로부터 Data를 생성하는 이니셜라이저
    /// - Parameter hex: hex 문자열 (0x 접두사 있어도 됨)
    init?(hex: String) {
        let string = hex.lowercased().hasPrefix("0x") ? String(hex.dropFirst(2)) : hex
        guard string.count % 2 == 0 else { return nil }
        
        var data = Data(capacity: string.count / 2)
        var index = string.startIndex
        
        for _ in 0..<string.count/2 {
            let nextIndex = string.index(index, offsetBy: 2)
            let byteString = String(string[index..<nextIndex])
            
            guard let byte = UInt8(byteString, radix: 16) else {
                return nil
            }
            
            data.append(byte)
            index = nextIndex
        }
        
        self = data
    }
    
    /// Data를 hex 문자열로 변환
    /// - Parameter prefix: 0x 접두사 포함 여부 (기본값: false)
    /// - Returns: hex 문자열
    func toHexString(prefix: Bool = false) -> String {
        let hexString = map { String(format: "%02hhx", $0) }.joined()
        return prefix ? "0x\(hexString)" : hexString
    }
}

// MARK: - URL Extensions
public extension URL {
    static func etherscanTransaction(hash: String, isMainnet: Bool = true) -> URL? {
        let baseURL = isMainnet ? "https://etherscan.io" : "https://sepolia.etherscan.io"
        return URL(string: "\(baseURL)/tx/\(hash)")
    }
    
    static func etherscanAddress(address: String, isMainnet: Bool = true) -> URL? {
        let baseURL = isMainnet ? "https://etherscan.io" : "https://sepolia.etherscan.io"
        return URL(string: "\(baseURL)/address/\(address)")
    }
}
