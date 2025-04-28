import Flutter
import UIKit

public class ReclaimInappFlutterSdkPlugin: NSObject, FlutterPlugin {
    private var client: PlatformRpcClient
    
    init(client: PlatformRpcClient) {
        self.client = client
        super.init()
        Task { @MainActor in
            for await message in client.messageStream {
                onMessage(message)
            }
        }
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterBasicMessageChannel(name: "org.reclaimprotocol.inapp_sdk.rpc", binaryMessenger: registrar.messenger(), codec: JsonRpcMessageCodec())
        let instance = ReclaimInappFlutterSdkPlugin(client: PlatformRpcClient(channel: channel))
        registrar.addApplicationDelegate(instance)
    }
    
    public func onMessage(_ message: RpcMessageProtocol) {
        PlatformRpcClient.debugPrintMessage(message, "PluginOnMessage")
        if let message = message as? RpcRequest {
            Task { @MainActor in
                do {
                    try await self.client.send(message: RpcResult(id: message.id, result: "iOS " + UIDevice.current.systemVersion))
                } catch {
                    
                }
            }
        } else {
            print("Unexpected")
        }
    }
}
