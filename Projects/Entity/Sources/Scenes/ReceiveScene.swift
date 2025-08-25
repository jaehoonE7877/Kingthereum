import Foundation

/// 수신 Scene의 VIP 모델들
public enum ReceiveScene {
    
    // MARK: - Use cases
    
    public enum LoadWalletAddress {
        public struct Request {
            public init() {}
        }
        
        public struct Response {
            public let walletAddress: String
            public let formattedAddress: String
            
            public init(walletAddress: String, formattedAddress: String) {
                self.walletAddress = walletAddress
                self.formattedAddress = formattedAddress
            }
        }
        
        public struct ViewModel {
            public let walletAddress: String
            public let formattedAddress: String
            public let qrCodeData: Data?
            
            public init(walletAddress: String, formattedAddress: String, qrCodeData: Data? = nil) {
                self.walletAddress = walletAddress
                self.formattedAddress = formattedAddress
                self.qrCodeData = qrCodeData
            }
        }
    }
    
    public enum CopyAddress {
        public struct Request {
            public let address: String
            
            public init(address: String) {
                self.address = address
            }
        }
        
        public struct Response {
            public let success: Bool
            
            public init(success: Bool) {
                self.success = success
            }
        }
        
        public struct ViewModel {
            public let showCopyAlert: Bool
            
            public init(showCopyAlert: Bool) {
                self.showCopyAlert = showCopyAlert
            }
        }
    }
    
    public enum ShareAddress {
        public struct Request {
            public let address: String
            
            public init(address: String) {
                self.address = address
            }
        }
        
        public struct Response {
            public let shareItems: [Any]
            
            public init(shareItems: [Any]) {
                self.shareItems = shareItems
            }
        }
        
        public struct ViewModel {
            public let shareItems: [Any]
            public let showShareSheet: Bool
            
            public init(shareItems: [Any], showShareSheet: Bool) {
                self.shareItems = shareItems
                self.showShareSheet = showShareSheet
            }
        }
    }
    
    public enum GenerateQRCode {
        public struct Request {
            public let address: String
            
            public init(address: String) {
                self.address = address
            }
        }
        
        public struct Response {
            public let qrCodeData: Data?
            public let isRefresh: Bool // 새로고침인지 구분
            
            public init(qrCodeData: Data? = nil, isRefresh: Bool) {
                self.qrCodeData = qrCodeData
                self.isRefresh = isRefresh
            }
        }
        
        public struct ViewModel {
            public let qrCodeData: Data?
            public let isRefresh: Bool
            public let showSuccessAnimation: Bool
            
            public init(qrCodeData: Data? = nil, isRefresh: Bool, showSuccessAnimation: Bool) {
                self.qrCodeData = qrCodeData
                self.isRefresh = isRefresh
                self.showSuccessAnimation = showSuccessAnimation
            }
        }
    }
}

// MARK: - Supporting Models

/// 수신 표시용 아이템
public struct ReceiveDisplayItem {
    public let walletAddress: String
    public let formattedAddress: String
    public let qrCodeData: Data?
    public let networkName: String
    public let networkIcon: String
    public let warningMessage: String
    
    public init(
        walletAddress: String,
        formattedAddress: String,
        qrCodeData: Data? = nil,
        networkName: String,
        networkIcon: String,
        warningMessage: String
    ) {
        self.walletAddress = walletAddress
        self.formattedAddress = formattedAddress
        self.qrCodeData = qrCodeData
        self.networkName = networkName
        self.networkIcon = networkIcon
        self.warningMessage = warningMessage
    }
}