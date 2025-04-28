package org.reclaimprotocol.inapp_flutter_sdk

import android.util.Log
import io.flutter.plugin.common.BasicMessageChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.launch
import org.reclaimprotocol.inapp_flutter_sdk.rpc.RpcClient
import org.reclaimprotocol.inapp_flutter_sdk.rpc.RpcMessage


public class PlatformRpcClient(private val channel: BasicMessageChannel<RpcMessage?>) : RpcClient(),
    BasicMessageChannel.MessageHandler<RpcMessage?> {
    companion object {
        const val TAG = "PlatformRpcClient"
    }

    private val _messageStream = MutableSharedFlow<RpcMessage>()
    override val messageStream: SharedFlow<RpcMessage> = _messageStream

    init {
        channel.setMessageHandler(this)
    }

    override fun send(message: RpcMessage) {
        Log.d(TAG, "send: $message")
        channel.send(message) {
            it?.let {
                CoroutineScope(Dispatchers.Main).launch {
                    _messageStream.emit(it)
                }
            }
        }
    }

    override fun onMessage(
        message: RpcMessage?,
        reply: BasicMessageChannel.Reply<RpcMessage?>
    ) {
        Log.d(TAG, "onMessage: $message")
        reply.reply(null)
        if (message == null) return
        CoroutineScope(Dispatchers.Main).launch {
            _messageStream.emit(message)
        }
    }

    override fun close() {
        channel.setMessageHandler(null)
        // No explicit close needed for MutableSharedFlow in this case
    }
}