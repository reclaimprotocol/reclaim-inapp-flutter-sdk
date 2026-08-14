import Flutter
import Foundation

/// Flutter plugin for native network handling
///
/// This plugin provides method channel communication between Dart and
/// the NativeNetworkHandler Swift class.
public class NativeNetworkPlugin: NSObject, FlutterPlugin {

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "org.reclaimprotocol.reclaim_tee_operator_flutter.native_network",
      binaryMessenger: registrar.messenger()
    )
    let instance = NativeNetworkPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "connect":
      handleConnect(call, result: result)
    case "read":
      handleRead(call, result: result)
    case "write":
      handleWrite(call, result: result)
    case "close":
      handleClose(call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleConnect(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
      let connType = args["connType"] as? Int32,
      let url = args["url"] as? String,
      let timeoutMs = args["timeoutMs"] as? Int32
    else {
      result(
        FlutterError(
          code: "INVALID_ARGS",
          message: "Missing required arguments for connect",
          details: nil
        ))
      return
    }

    print(
      "NativeNetworkPlugin connect requested: connType=\(connType) url=\"\(url)\" timeoutMs=\(timeoutMs)"
    )

    // Run connection on background queue to not block UI
    DispatchQueue.global(qos: .userInitiated).async {
      let connResult = NativeNetworkHandler.shared.connect(
        connType: connType,
        url: url,
        timeoutMs: timeoutMs
      )

      DispatchQueue.main.async {
        result([
          "handle": connResult.handle,
          "errorCode": connResult.errorCode,
          "errorMessage": connResult.errorMessage as Any,
        ])
      }
    }
  }

  private func handleRead(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
      let handle = args["handle"] as? Int,
      let maxBytes = args["maxBytes"] as? Int32,
      let timeoutMs = args["timeoutMs"] as? Int32
    else {
      result(
        FlutterError(
          code: "INVALID_ARGS",
          message: "Missing required arguments for read",
          details: nil
        ))
      return
    }

    DispatchQueue.global(qos: .userInitiated).async {
      let readResult = NativeNetworkHandler.shared.read(
        handle: handle,
        maxBytes: maxBytes,
        timeoutMs: timeoutMs
      )

      DispatchQueue.main.async {
        var response: [String: Any] = [
          "errorCode": readResult.errorCode,
          "errorMessage": readResult.errorMessage as Any,
        ]
        if let data = readResult.data {
          response["data"] = FlutterStandardTypedData(bytes: data)
        }
        result(response)
      }
    }
  }

  private func handleWrite(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
      let handle = args["handle"] as? Int,
      let data = args["data"] as? FlutterStandardTypedData
    else {
      result(
        FlutterError(
          code: "INVALID_ARGS",
          message: "Missing required arguments for write",
          details: nil
        ))
      return
    }

    DispatchQueue.global(qos: .userInitiated).async {
      let writeResult = NativeNetworkHandler.shared.write(
        handle: handle,
        data: data.data
      )

      DispatchQueue.main.async {
        result(writeResult)
      }
    }
  }

  private func handleClose(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
      let handle = args["handle"] as? Int
    else {
      result(
        FlutterError(
          code: "INVALID_ARGS",
          message: "Missing required arguments for close",
          details: nil
        ))
      return
    }

    NativeNetworkHandler.shared.close(handle: handle)
    result(nil)
  }
}
