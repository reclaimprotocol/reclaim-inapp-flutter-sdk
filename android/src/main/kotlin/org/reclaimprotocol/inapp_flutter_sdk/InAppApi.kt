package org.reclaimprotocol.inapp_flutter_sdk

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import org.reclaimprotocol.inapp_flutter_sdk.rpc.RpcError
import org.reclaimprotocol.inapp_flutter_sdk.rpc.RpcErrorCode
import org.reclaimprotocol.inapp_flutter_sdk.rpc.RpcErrorInformation
import org.reclaimprotocol.inapp_sdk.ReclaimVerification

public interface ApiResultHandler {
    public fun onResponse(response: JSONObject)
    public fun onError(error: InAppApiError)
}

public sealed interface InAppApiError {
   fun getRpcErrorInformation(): RpcErrorInformation

    public enum class ErrorCodes(val code: RpcErrorCode) {
        Verification(RpcErrorCode(1));
    }

    public data class VerificationInAppApiError (val exception: ReclaimVerification.ReclaimVerificationException): InAppApiError {
        override fun getRpcErrorInformation(): RpcErrorInformation {
            val data = JSONObject()
            data.put("message", exception.message)
            data.put("sessionId", exception.sessionId)
            data.put("reason", exception.reason)
            val type = when (exception) {
                is ReclaimVerification.ReclaimVerificationException.Cancelled -> "cancelled"
                is ReclaimVerification.ReclaimVerificationException.Dismissed -> "dismissed"
                is ReclaimVerification.ReclaimVerificationException.Failed -> "failed"
                is ReclaimVerification.ReclaimVerificationException.SessionExpired -> "sessionExpired"
            }
            data.put("type", type)

            return RpcErrorInformation(
                code = ErrorCodes.Verification.code,
                message = "verification error",
                data = data
            )
        }
    }
}



public class InAppApi {
    lateinit var context: Context

    fun setContext(context: Context) {
        this.context = context
    }

    fun startVerification(
        request: JSONObject,
        handler: ApiResultHandler
    ) {
        ReclaimVerification.startVerification(
            context = context.applicationContext,
            request = ReclaimVerification.Request(
                appId = request.optString("appId"),
                secret = request.optString("secret"),
                providerId = request.optString("providerId")
            ),
            handler = object :  ReclaimVerification.ResultHandler {
                override fun onException(exception: ReclaimVerification.ReclaimVerificationException) {
                    handler.onError(InAppApiError.VerificationInAppApiError(exception))
                }

                override fun onResponse(response: ReclaimVerification.Response) {
                    val data = JSONObject()
                    data.put("sessionId", response.sessionId)
                    data.put("proofs", JSONArray(response.proofs))
                    handler.onResponse(data)
                }
            }
        )
    }
}