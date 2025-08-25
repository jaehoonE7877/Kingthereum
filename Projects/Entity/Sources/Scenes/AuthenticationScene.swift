import Foundation

/// 인증 Scene의 VIP 모델들
public enum AuthenticationScene {
    
    // MARK: - Use Cases
    public enum SetupPIN {
        public struct Request {
            public let pin: String
            
            public init(pin: String) {
                self.pin = pin
            }
        }
        
        public struct Response: Sendable {
            public let success: Bool
            public let error: Error?
            
            public init(success: Bool, error: Error? = nil) {
                self.success = success
                self.error = error
            }
        }
        
        public struct ViewModel {
            public let success: Bool
            public let errorMessage: String?
            
            public init(success: Bool, errorMessage: String? = nil) {
                self.success = success
                self.errorMessage = errorMessage
            }
        }
    }
    
    public enum AuthenticateWithBiometrics {
        public struct Request {
            public let reason: String
            
            public init(reason: String) {
                self.reason = reason
            }
        }
        
        public struct Response: Sendable {
            public let success: Bool
            public let biometricType: BiometricType
            public let error: Error?
            
            public init(success: Bool, biometricType: BiometricType, error: Error? = nil) {
                self.success = success
                self.biometricType = biometricType
                self.error = error
            }
        }
        
        public struct ViewModel {
            public let success: Bool
            public let biometricTypeDescription: String
            public let errorMessage: String?
            
            public init(success: Bool, biometricTypeDescription: String, errorMessage: String? = nil) {
                self.success = success
                self.biometricTypeDescription = biometricTypeDescription
                self.errorMessage = errorMessage
            }
        }
    }
    
    public enum AuthenticateWithPIN {
        public struct Request {
            public let pin: String
            
            public init(pin: String) {
                self.pin = pin
            }
        }
        
        public struct Response: Sendable {
            public let success: Bool
            public let error: Error?
            
            public init(success: Bool, error: Error? = nil) {
                self.success = success
                self.error = error
            }
        }
        
        public struct ViewModel {
            public let success: Bool
            public let errorMessage: String?
            
            public init(success: Bool, errorMessage: String? = nil) {
                self.success = success
                self.errorMessage = errorMessage
            }
        }
    }
    
    public enum CheckBiometricAvailability {
        public struct Request {
            public init() {}
        }
        
        public struct Response: Sendable {
            public let isAvailable: Bool
            public let biometricType: BiometricType
            
            public init(isAvailable: Bool, biometricType: BiometricType) {
                self.isAvailable = isAvailable
                self.biometricType = biometricType
            }
        }
        
        public struct ViewModel {
            public let isAvailable: Bool
            public let biometricTypeDescription: String
            public let biometricIcon: String
            
            public init(isAvailable: Bool, biometricTypeDescription: String, biometricIcon: String) {
                self.isAvailable = isAvailable
                self.biometricTypeDescription = biometricTypeDescription
                self.biometricIcon = biometricIcon
            }
        }
    }
    
    public enum CreateWallet {
        public struct Request {
            public let walletName: String
            
            public init(walletName: String) {
                self.walletName = walletName
            }
        }
        
        public struct Response: Sendable {
            public let success: Bool
            public let walletAddress: String?
            public let mnemonic: String?
            public let error: Error?
            
            public init(success: Bool, walletAddress: String? = nil, mnemonic: String? = nil, error: Error? = nil) {
                self.success = success
                self.walletAddress = walletAddress
                self.mnemonic = mnemonic
                self.error = error
            }
        }
        
        public struct ViewModel {
            public let success: Bool
            public let walletAddress: String?
            public let mnemonic: String?
            public let errorMessage: String?
            
            public init(success: Bool, walletAddress: String? = nil, mnemonic: String? = nil, errorMessage: String? = nil) {
                self.success = success
                self.walletAddress = walletAddress
                self.mnemonic = mnemonic
                self.errorMessage = errorMessage
            }
        }
    }
    
    public enum ImportWallet {
        public struct Request {
            public let walletName: String
            public let mnemonic: String
            public let pin: String
            
            public init(walletName: String, mnemonic: String, pin: String) {
                self.walletName = walletName
                self.mnemonic = mnemonic
                self.pin = pin
            }
        }
        
        public struct Response: Sendable {
            public let success: Bool
            public let walletAddress: String?
            public let error: Error?
            
            public init(success: Bool, walletAddress: String? = nil, error: Error? = nil) {
                self.success = success
                self.walletAddress = walletAddress
                self.error = error
            }
        }
        
        public struct ViewModel {
            public let success: Bool
            public let walletAddress: String?
            public let errorMessage: String?
            
            public init(success: Bool, walletAddress: String? = nil, errorMessage: String? = nil) {
                self.success = success
                self.walletAddress = walletAddress
                self.errorMessage = errorMessage
            }
        }
    }
}

// MARK: - Import BiometricType from SecurityError.swift
// BiometricType는 이미 Entity/Sources/Errors/SecurityError.swift에 정의되어 있음