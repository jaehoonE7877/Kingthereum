import Foundation

// MARK: - String Extensions

/// String 타입에 블록체인 관련 검증 및 변환 기능을 추가
public extension String {
    
    /// 이더리움 주소 유효성 검증
    /// 
    /// 표준 이더리움 주소 형식(0x로 시작하는 42자리 16진수)인지 확인합니다.
    /// EIP-55 체크섬 검증은 별도로 수행해야 합니다.
    /// 
    /// - Returns: 유효한 이더리움 주소 형식이면 true
    var isValidEthereumAddress: Bool {
        return self.hasPrefix("0x") 
            && self.count == 42 
            && self.dropFirst(2).allSatisfy { $0.isHexDigit }
    }
    
    /// 이더리움 개인키 유효성 검증
    /// 
    /// 표준 이더리움 개인키 형식(64자리 16진수)인지 확인합니다.
    /// 실제 키의 수학적 유효성은 별도로 검증해야 합니다.
    /// 
    /// - Returns: 유효한 개인키 형식이면 true
    var isValidPrivateKey: Bool {
        return self.count == 64 && self.allSatisfy { $0.isHexDigit }
    }
    
    /// EIP-55 체크섬 주소로 변환
    /// 
    /// 현재는 단순히 소문자로 변환하지만, 향후 실제 EIP-55 체크섬 로직으로 개선 필요
    /// 
    /// - Returns: 체크섬이 적용된 주소 (현재는 lowercase)
    /// - Note: 실제 체크섬 계산을 위해서는 Keccak-256 해시 함수 필요
    func toChecksumAddress() -> String {
        // TODO: 실제 EIP-55 체크섬 로직 구현
        return self.lowercased()
    }
}

// MARK: - Character Extensions

/// Character 타입에 16진수 검증 기능을 추가
public extension Character {
    
    /// 16진수 문자인지 검증
    /// 
    /// 0-9, a-f, A-F 범위의 문자인지 확인합니다.
    /// 블록체인 주소와 해시값 검증에 사용됩니다.
    /// 
    /// - Returns: 유효한 16진수 문자이면 true
    var isHexDigit: Bool {
        return self.isNumber 
            || ("a"..."f").contains(self) 
            || ("A"..."F").contains(self)
    }
}

// MARK: - Double Extensions

/// Double 타입에 정밀한 반올림 기능을 추가
public extension Double {
    
    /// 지정된 소수점 자릿수로 반올림
    /// 
    /// 암호화폐 가격이나 잔액 표시에서 정확한 소수점 처리를 위해 사용합니다.
    /// IEEE 754 부동소수점의 한계로 인한 미세한 오차를 방지합니다.
    /// 
    /// - Parameter places: 반올림할 소수점 자릿수 (0 이상)
    /// - Returns: 지정된 자릿수로 반올림된 값
    /// 
    /// ## 사용 예시:
    /// ```swift
    /// let price = 1234.56789
    /// let rounded = price.rounded(toPlaces: 2) // 1234.57
    /// ```
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}


// MARK: - Data Extensions

/// Data 타입에 16진수 문자열 변환 기능을 추가
/// 블록체인과 암호화 작업에서 바이너리 데이터와 문자열 간 변환에 사용
public extension Data {
    
    /// 16진수 문자열로부터 Data 객체를 생성하는 실패 가능한 이니셜라이저
    /// 
    /// 블록체인 트랜잭션 해시, 개인키, 공개키 등의 16진수 문자열을 
    /// 바이너리 데이터로 변환할 때 사용합니다.
    /// 
    /// - Parameter hex: 16진수 문자열 ("0x" 접두사는 선택사항)
    /// 
    /// ## 지원 형식:
    /// - "deadbeef"
    /// - "0xdeadbeef" 
    /// - "DEADBEEF"
    /// - "0xDEADBEEF"
    /// 
    /// ## 실패 조건:
    /// - 홀수 길이의 문자열
    /// - 16진수가 아닌 문자 포함
    /// 
    /// ## 사용 예시:
    /// ```swift
    /// let data = Data(hex: "0x48656c6c6f") // "Hello"의 16진수 표현
    /// ```
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
    
    /// Data를 16진수 문자열로 변환
    /// 
    /// 바이너리 데이터를 사람이 읽을 수 있는 16진수 문자열로 변환합니다.
    /// 블록체인 데이터를 UI에 표시하거나 API 요청에 사용할 때 활용됩니다.
    /// 
    /// - Parameter prefix: "0x" 접두사 포함 여부 (기본값: false)
    /// - Returns: 소문자 16진수 문자열
    /// 
    /// ## 사용 예시:
    /// ```swift
    /// let data = "Hello".data(using: .utf8)!
    /// let hex = data.toHexString() // "48656c6c6f"
    /// let hexWithPrefix = data.toHexString(prefix: true) // "0x48656c6c6f"
    /// ```
    func toHexString(prefix: Bool = false) -> String {
        let hexString = map { String(format: "%02hhx", $0) }.joined()
        return prefix ? "0x\(hexString)" : hexString
    }
}

// MARK: - URL Extensions

/// URL 타입에 이더스캔 링크 생성 기능을 추가
/// 블록체인 익스플로러 연결을 위한 편의 메서드들
public extension URL {
    
    /// 이더스캔 트랜잭션 페이지 URL 생성
    /// 
    /// 트랜잭션 해시를 이용하여 이더스캔에서 트랜잭션 상세 정보를 
    /// 확인할 수 있는 URL을 생성합니다.
    /// 
    /// - Parameters:
    ///   - hash: 트랜잭션 해시 (0x 접두사 포함/미포함 모두 가능)
    ///   - isMainnet: 메인넷 여부 (기본값: true, false면 Sepolia 테스트넷)
    /// - Returns: 이더스캔 트랜잭션 URL, 생성 실패 시 nil
    /// 
    /// ## 사용 예시:
    /// ```swift
    /// let url = URL.etherscanTransaction(hash: "0xabc123...", isMainnet: true)
    /// // https://etherscan.io/tx/0xabc123...
    /// ```
    static func etherscanTransaction(hash: String, isMainnet: Bool = true) -> URL? {
        let baseURL = isMainnet ? "https://etherscan.io" : "https://sepolia.etherscan.io"
        return URL(string: "\(baseURL)/tx/\(hash)")
    }
    
    /// 이더스캔 주소 페이지 URL 생성
    /// 
    /// 지갑 주소나 컨트랙트 주소를 이용하여 이더스캔에서 
    /// 주소 상세 정보를 확인할 수 있는 URL을 생성합니다.
    /// 
    /// - Parameters:
    ///   - address: 이더리움 주소 (0x 접두사 포함)
    ///   - isMainnet: 메인넷 여부 (기본값: true, false면 Sepolia 테스트넷)
    /// - Returns: 이더스캔 주소 URL, 생성 실패 시 nil
    /// 
    /// ## 사용 예시:
    /// ```swift
    /// let url = URL.etherscanAddress(address: "0x123abc...", isMainnet: false)
    /// // https://sepolia.etherscan.io/address/0x123abc...
    /// ```
    static func etherscanAddress(address: String, isMainnet: Bool = true) -> URL? {
        let baseURL = isMainnet ? "https://etherscan.io" : "https://sepolia.etherscan.io"
        return URL(string: "\(baseURL)/address/\(address)")
    }
}
