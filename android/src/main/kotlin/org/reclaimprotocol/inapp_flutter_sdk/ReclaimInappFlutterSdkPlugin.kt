package org.reclaimprotocol.inapp_flutter_sdk

import android.os.Build
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BasicMessageChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.json.JSONObject
import org.reclaimprotocol.inapp_flutter_sdk.rpc.JsonRpcMessageCodec
import org.reclaimprotocol.inapp_flutter_sdk.rpc.RpcError
import org.reclaimprotocol.inapp_flutter_sdk.rpc.RpcErrorInformation
import org.reclaimprotocol.inapp_flutter_sdk.rpc.RpcMessage
import org.reclaimprotocol.inapp_flutter_sdk.rpc.RpcRequest
import org.reclaimprotocol.inapp_flutter_sdk.rpc.RpcResult

/** ReclaimInappFlutterSdkPlugin */
class ReclaimInappFlutterSdkPlugin : FlutterPlugin {
    companion object {
        const val TAG = "InappFlutterSdkPlugin"
    }

    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: BasicMessageChannel<RpcMessage?>
    private lateinit var client: PlatformRpcClient
    private val api: InAppApi = InAppApi()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = BasicMessageChannel(
            flutterPluginBinding.binaryMessenger, "org.reclaimprotocol.inapp_sdk.rpc",
            JsonRpcMessageCodec()
        )
        api.setContext(flutterPluginBinding.applicationContext)
        client = PlatformRpcClient(channel)
        CoroutineScope(Dispatchers.Main).launch {
            client.messageStream.collect {
                onMessage(it)
            }
        }
    }

    fun onMessage(message: RpcMessage): Unit {
        Log.d(TAG, "listen.onMessage: $message")
        when (message) {
            is RpcRequest -> {
                return when (message.method) {
                    "ping" -> {
                        client.send(
                            RpcResult(
                                id = message.id,
                                result = "pong"
                            )
                        )
                    }
                    "startVerification" -> {
                        api.startVerification(
                            request = (message.params as JSONObject).getJSONObject("request"),
                            handler = object : ApiResultHandler {
                                override fun onResponse(response: JSONObject) {
                                    client.send(RpcResult(id = message.id, result = response))
                                }
                                override fun onError(error: InAppApiError) {
                                    client.send(RpcError(id = message.id, error = error.getRpcErrorInformation()))
                                }
                            }
                        )
                    }
                    else -> {
                        client.send(
                            RpcError(
                                id = message.id,
                                error = RpcErrorInformation.methodNotFound(data = "Method ${message.method} not found")
                            )
                        )
                    }
                }
            }
            else -> {
                Log.d(TAG, "Message is a response: $message")
                return
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        // We call `channel.setMessageHandler(null)` inside `PlatformRpcClient.close`
        client.close()
    }
}
