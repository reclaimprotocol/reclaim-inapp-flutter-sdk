import Foundation
import Flutter

class JsonRpcMessageCodec: NSObject, FlutterMessageCodec {
    static let shared = JsonRpcMessageCodec()

    static func sharedInstance() -> Self {
        return shared as! Self
    }

    func encode(_ message: Any?) -> Data? {
        assert(message is RpcMessageProtocol || message == nil, "Message must conform to RpcMessageProtocol? but it was \(String(describing: message))")
        guard let message = message as? RpcMessageProtocol else {
            print("message to encode was null")
            return nil
        }
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: message.toJson(), options: [
                JSONSerialization.WritingOptions.sortedKeys,
                JSONSerialization.WritingOptions.fragmentsAllowed
            ])
            return jsonData
        } catch {
            print("Error encoding message: \(error)")
            return nil
        }
    }

    func decode(_ message: Data?) -> Any? {
        if let message {
            print("Data is \(String(describing: String.init(data: message, encoding: .utf8)))")
        } else {
            print("Data is null")
        }

        guard let messageData = message else {
            return nil
        }
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: messageData, options: [
                JSONSerialization.ReadingOptions.fragmentsAllowed,
            ])
            
            if let json = jsonObject as? [AnyHashable: Any?] {
                print("codable")
                return RpcMessage.fromJsonToRpcMessageProtocol(json)
            }
            print("unknpwn \(String(describing: jsonObject)) \(type(of: jsonObject))")
            return nil
        } catch {
            print("Error decoding message: \(error)")
            return nil
        }
    }
}
