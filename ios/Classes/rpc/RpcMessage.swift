import Foundation

// MARK: - RpcMessage

public protocol RpcMessageProtocol: NSObject {
    var id: String { get }
    func toJson() -> [String: Any]
}

enum RpcMessageType {
    case request
    case response
    case error
    case result
}

class RpcMessage: NSObject, RpcMessageProtocol {
    let id: String
    
    init(id: String) {
        self.id = id
    }
    
    func toJson() -> [String : Any] {
        return ["id": id]
    }
    
    static func fromJsonToRpcMessageProtocol(_ json: [AnyHashable: Any?]) -> RpcMessageProtocol? {
        if json.keys.contains("method") {
            return RpcRequest.fromJsonToRpcRequest(json)
        } else {
            return RpcResponse.fromJsonToRpcResponse(json)
        }
    }
}

// MARK: - RpcRequest

class RpcRequest: RpcMessage {
    let method: String
    let params: Any?

    init(method: String, params: Any?, id: String) {
        self.method = method
        self.params = params
        super.init(id: id)
    }

    convenience init(method: String, params: Any?) {
        self.init(method: method, params: params, id: UUID().uuidString)
    }
    
    override func toJson() -> [String: Any] {
        var json = super.toJson()
        json["method"] = method
        json["params"] = params
        return json
    }

    static func fromJsonToRpcRequest(_ json: [AnyHashable: Any?]) -> RpcRequest? {
        guard let method = json["method"] as? String,
              let id = json["id"] as? String else {
            return nil
        }
        let params: Any? = if let x = json["params"] {
            x
        } else {
            nil
        }
        
        return RpcRequest(method: method, params: params, id: id)
    }
}

// MARK: - RpcResponse

class RpcResponse: RpcMessage {
    static func fromJsonToRpcResponse(_ json: [AnyHashable: Any?]) -> RpcResponse? {
        if json.keys.contains("error") {
            return RpcError.fromJsonToRpcError(json)
        } else if json.keys.contains("result") {
            return RpcResult.fromJsonToRpcResult(json)
        }
        return nil
    }
}

// MARK: - RpcResult

class RpcResult: RpcResponse {
    let result: Any?

    init(id: String, result: Any?) {
        self.result = result
        super.init(id: id)
    }

    override func toJson() -> [String: Any] {
        var json = super.toJson()
        json["result"] = result
        return json
    }

    static func fromJsonToRpcResult(_ json: [AnyHashable: Any?]) -> RpcResult? {
        guard let id = json["id"] as? String else {
            return nil
        }
        let result: Any? = if let it = json["result"] {
            it
        } else {
            nil
        }
        
        return RpcResult(id: id, result: result)
    }
}

// MARK: - RpcErrorCode

struct RpcErrorCode: Equatable, Codable {
    let code: Int

    init(_ code: Int) {
        self.code = code
    }

    func toJson() -> Int {
        return code
    }

    static func fromJson(_ code: Int) -> RpcErrorCode {
        if let value = values.first(where: { $0.code == code }) {
            return value
        }
        return RpcErrorCode(code)
    }

    var isServerError: Bool {
        return code >= -32099 && code <= -32000
    }

    static let parseError = RpcErrorCode(-32700)
    static let invalidRequest = RpcErrorCode(-32600)
    static let methodNotFound = RpcErrorCode(-32601)
    static let invalidParams = RpcErrorCode(-32602)
    static let internalError = RpcErrorCode(-32603)

    static let values: [RpcErrorCode] = [
        parseError,
        invalidRequest,
        methodNotFound,
        invalidParams,
        internalError,
    ]
}

// MARK: - RpcErrorInformation

struct RpcErrorInformation {
    let code: RpcErrorCode
    let message: String
    let data: (any Codable)?

    init(code: RpcErrorCode, message: String, data: (any Codable)? = nil) {
        self.code = code
        self.message = message
        self.data = data
    }

    func toJson() -> [String: Any] {
        var json: [String: Any] = ["code": code.toJson(), "message": message]
        if let data = data {
            json["data"] = data
        }
        return json
    }

    static func fromJson(_ json: [String: (any Codable)?]) -> RpcErrorInformation? {
        guard let codeInt = json["code"] as? Int,
              let message = json["message"] as? String else {
            return nil
        }
        let code = RpcErrorCode.fromJson(codeInt)
        let data: (any Codable)? = if let it = json["data"] {
            it
        } else {
            nil
        }
        return RpcErrorInformation(code: code, message: message, data: data)
    }

    static func parseError(data: (any Codable)? = nil) -> RpcErrorInformation {
        return RpcErrorInformation(code: .parseError, message: "Parse error", data: data)
    }

    static func invalidRequest(data: (any Codable)? = nil) -> RpcErrorInformation {
        return RpcErrorInformation(code: .invalidRequest, message: "Invalid request", data: data)
    }

    static func methodNotFound(data: (any Codable)? = nil) -> RpcErrorInformation {
        return RpcErrorInformation(code: .methodNotFound, message: "Method not found", data: data)
    }

    static func invalidParams(data: (any Codable)? = nil) -> RpcErrorInformation {
        return RpcErrorInformation(code: .invalidParams, message: "Invalid params", data: data)
    }

    static func internalError(data: (any Codable)? = nil) -> RpcErrorInformation {
        return RpcErrorInformation(code: .internalError, message: "Internal error", data: data)
    }

    static func serverError(code: Int, data: (any Codable)? = nil) -> RpcErrorInformation {
        assert(code >= -32099 && code <= -32000)
        return RpcErrorInformation(code: RpcErrorCode.fromJson(code), message: "Server error", data: data)
    }
}

// MARK: - RpcError

class RpcError: RpcResponse {
    let error: RpcErrorInformation

    init(error: RpcErrorInformation, id: String) {
        self.error = error
        super.init(id: id)
    }

    override func toJson() -> [String: Any] {
        var json = super.toJson()
        json["error"] = error.toJson()
        return json
    }

    static func fromJsonToRpcError(_ json: [AnyHashable: Any?]) -> RpcError? {
        guard let errorJson = json["error"] as? [String: (any Codable)?],
              let id = json["id"] as? String,
              let errorInfo = RpcErrorInformation.fromJson(errorJson) else {
            return nil
        }
        return RpcError(error: errorInfo, id: id)
    }
}
