package org.reclaimprotocol.inapp_flutter_sdk.rpc

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first

abstract class RpcClient {
    abstract fun send(message: RpcMessage)
    abstract val messageStream: Flow<RpcMessage>
    abstract fun close()

    suspend fun sendRequest(method: String, params: Any?): RpcResponse {
        val request = RpcRequest(method = method, params = params)
        send(request)
        return messageStream.first { it is RpcResponse && it.id == request.id } as RpcResponse
    }
}