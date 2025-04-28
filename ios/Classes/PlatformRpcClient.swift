import Flutter
import Foundation

class PlatformRpcClient: NSObject, RpcClientProtocol {
    private let channel: FlutterBasicMessageChannel
    private let messageStreamController: AsyncStream<RpcMessageProtocol>.Continuation
    let messageStream: AsyncStream<RpcMessageProtocol>
    
    init(channel: FlutterBasicMessageChannel) {
        self.channel = channel
        (self.messageStream, self.messageStreamController) = AsyncStream.makeStream()
        super.init()
        channel.setMessageHandler(self.onMessage)
    }
    
    static func debugPrintMessage(_ message: Any?, _ tag: String) {
#if DEBUG
        if let message = message as? RpcMessageProtocol {
            if let jsonString = String(data: JsonRpcMessageCodec.shared.encode(message) ?? Data(), encoding: .utf8) {
                print("[\(tag)] debugPrintMessage: \(jsonString)")
            }
        } else {
            print("[\(tag)] debugPrintMessage (none): \(String(describing: message))")
        }
#endif
    }
    
    func send(message: RpcMessageProtocol) async throws {
        PlatformRpcClient.debugPrintMessage(message, "send")
        let result = await channel.sendMessage(message)
        if let resultData = result as? RpcMessageProtocol {
            self.onMessage(message: resultData) {it in
                PlatformRpcClient.debugPrintMessage(it, "Unexpected reply")
            }
        }
    }
    
    private func onMessage(message: Any?, callback: @escaping FlutterReply) {
        PlatformRpcClient.debugPrintMessage(message, "onMessage")
        if let message = message as? RpcMessageProtocol {
            messageStreamController.yield(message)
        } else {
            return callback(nil)
        }
    }
    
    func sendRequest(method: String, params: (any Codable)?) async throws -> RpcMessageProtocol {
        let request = RpcRequest(method: method, params: params)
        try await send(message: request)
        return await messageStream.first { receivedMessage in
            return request.id == receivedMessage.id
        } ?? RpcError(error: RpcErrorInformation.internalError(data: "Client closed before a response was received"), id: request.id)
    }
    
    func close() {
        channel.setMessageHandler(nil)
        messageStreamController.finish()
    }
}
