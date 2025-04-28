package org.reclaimprotocol.inapp_flutter_sdk.rpc

import android.util.Log
import io.flutter.plugin.common.MessageCodec
import org.json.JSONObject
import java.nio.ByteBuffer
import java.nio.charset.StandardCharsets

class JsonRpcMessageCodec : MessageCodec<RpcMessage?> {
    override fun encodeMessage(message: RpcMessage?): ByteBuffer? {
        if (message == null) return null
        val jsonString = message.toJson().toString()
        val bytes = jsonString.toByteArray(StandardCharsets.UTF_8)
        Log.d("JsonRpcMessageCodec", String(bytes, StandardCharsets.UTF_8))
        val buffer = ByteBuffer.allocateDirect(bytes.size)
        buffer.put(bytes)
        buffer.flip()
        // TODO: Fix it because without this, empty bytes are sent to host
        buffer.get(ByteArray(buffer.remaining()))
        return buffer
    }

    override fun decodeMessage(message: ByteBuffer?): RpcMessage? {
        if (message == null) return null
        val bytes = ByteArray(message.remaining())
        message.get(bytes)
        val jsonString = String(bytes, StandardCharsets.UTF_8)
        val jsonObject = JSONObject(jsonString)
        return RpcMessage.Companion.fromJson(jsonObject)
    }
}