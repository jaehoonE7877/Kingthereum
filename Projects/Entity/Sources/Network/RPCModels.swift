import Foundation

/// RPC 응답을 나타내는 모델
public struct RPCResponse: Codable, Sendable {
    public let jsonrpc: String
    public let id: Int
    public let result: RPCResult?
    public let error: RPCError?
    
    public init(jsonrpc: String, id: Int, result: RPCResult? = nil, error: RPCError? = nil) {
        self.jsonrpc = jsonrpc
        self.id = id
        self.result = result
        self.error = error
    }
}

/// RPC 결과를 나타내는 열거형
public enum RPCResult: Codable, Sendable {
    case string(String)
    case number(Double)
    case object([String: String])
    case array([String])
    case bool(Bool)
    case null
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self = .null
        } else if let boolValue = try? container.decode(Bool.self) {
            self = .bool(boolValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let numberValue = try? container.decode(Double.self) {
            self = .number(numberValue)
        } else if let arrayValue = try? container.decode([String].self) {
            self = .array(arrayValue)
        } else if let objectValue = try? container.decode([String: String].self) {
            self = .object(objectValue)
        } else {
            throw DecodingError.typeMismatch(
                RPCResult.self,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid RPCResult type")
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .string(let value):
            try container.encode(value)
        case .number(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }
}

/// RPC 오류를 나타내는 모델
public struct RPCError: Codable, Error, Sendable {
    public let code: Int
    public let message: String
    public let data: String?
    
    public init(code: Int, message: String, data: String? = nil) {
        self.code = code
        self.message = message
        self.data = data
    }
}