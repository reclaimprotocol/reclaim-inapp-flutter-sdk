package org.reclaimprotocol.inapp_flutter_sdk.rpc

import org.json.JSONObject
import java.util.UUID

sealed class RpcMessage(open val id: String) {
    abstract fun toJson(): JSONObject

    companion object {
        @JvmStatic
        fun fromJson(json: JSONObject): RpcMessage {
            return if (json.has("method")) {
                RpcRequest.fromJson(json)
            } else {
                RpcResponse.fromJson(json)
            }
        }
    }
}

data class RpcRequest(
    val method: String,
    val params: Any?,
    override val id: String
) : RpcMessage(id) {
    constructor(method: String, params: Any?) : this(method, params, UUID.randomUUID().toString())

    override fun toJson(): JSONObject {
        val json = JSONObject()
        json.put("id", id)
        json.put("method", method)
        json.put("params", params)
        return json
    }

    companion object {
        @JvmStatic
        fun fromJson(json: JSONObject): RpcRequest {
            return RpcRequest(
                method = json.getString("method"),
                params = json.opt("params"),
                id = json.getString("id")
            )
        }
    }
}

sealed class RpcResponse(id: String) : RpcMessage(id) {
    companion object {
        @JvmStatic
        fun fromJson(json: JSONObject): RpcResponse {
            return if (json.has("error")) {
                RpcError.fromJson(json)
            } else {
                RpcResult.fromJson(json)
            }
        }
    }
}

data class RpcResult(
    val result: Any?,
    override val id: String
) : RpcResponse(id) {
    override fun toJson(): JSONObject {
        val json = JSONObject()
        json.put("id", id)
        json.put("result", result)
        return json
    }

    companion object {
        @JvmStatic
        fun fromJson(json: JSONObject): RpcResult {
            return RpcResult(
                result = json.opt("result"),
                id = json.getString("id")
            )
        }
    }
}

data class RpcErrorCode(val code: Int) {
    fun toJson(): Int {
        return code
    }

    companion object {
        @JvmStatic
        fun fromJson(code: Int): RpcErrorCode {
            return values.find { it.code == code } ?: RpcErrorCode(code)
        }

        val parseError = RpcErrorCode(-32700)
        val invalidRequest = RpcErrorCode(-32600)
        val methodNotFound = RpcErrorCode(-32601)
        val invalidParams = RpcErrorCode(-32602)
        val internalError = RpcErrorCode(-32603)

        val values = listOf(
            parseError,
            invalidRequest,
            methodNotFound,
            invalidParams,
            internalError
        )
    }

    public val isServerError: Boolean
        get() = code in -32099..-32000
}

data class RpcErrorInformation(
    val code: RpcErrorCode,
    val message: String,
    val data: Any? = null
) {
    fun toJson(): JSONObject {
        val json = JSONObject()
        json.put("code", code.toJson())
        json.put("message", message)
        json.put("data", data)
        return json
    }

    companion object {
        @JvmStatic
        fun fromJson(json: JSONObject): RpcErrorInformation {
            return RpcErrorInformation(
                code = RpcErrorCode.fromJson(json.getInt("code")),
                message = json.getString("message"),
                data = json.opt("data")
            )
        }

        @JvmStatic
        fun parseError(data: Any? = null): RpcErrorInformation {
            return RpcErrorInformation(
                code = RpcErrorCode.parseError,
                message = "Parse error",
                data = data
            )
        }

        @JvmStatic
        fun invalidRequest(data: Any? = null): RpcErrorInformation {
            return RpcErrorInformation(
                code = RpcErrorCode.invalidRequest,
                message = "Invalid request",
                data = data
            )
        }

        @JvmStatic
        fun methodNotFound(data: Any? = null): RpcErrorInformation {
            return RpcErrorInformation(
                code = RpcErrorCode.methodNotFound,
                message = "Method not found",
                data = data
            )
        }

        @JvmStatic
        fun invalidParams(data: Any? = null): RpcErrorInformation {
            return RpcErrorInformation(
                code = RpcErrorCode.invalidParams,
                message = "Invalid params",
                data = data
            )
        }

        @JvmStatic
        fun internalError(data: Any? = null): RpcErrorInformation {
            return RpcErrorInformation(
                code = RpcErrorCode.internalError,
                message = "Internal error",
                data = data
            )
        }

        @JvmStatic
        fun serverError(code: Int, data: Any? = null): RpcErrorInformation {
            assert(code in -32099..-32000)
            return RpcErrorInformation(
                code = RpcErrorCode.fromJson(code),
                message = "Server error",
                data = data
            )
        }
    }
}

data class RpcError(
    val error: RpcErrorInformation,
    override val id: String
) : RpcResponse(id) {
    override fun toJson(): JSONObject {
        val json = JSONObject()
        json.put("id", id)
        json.put("error", error.toJson())
        return json
    }

    companion object {
        @JvmStatic
        fun fromJson(json: JSONObject): RpcError {
            return RpcError(
                error = RpcErrorInformation.fromJson(json.getJSONObject("error")),
                id = json.getString("id")
            )
        }
    }
}
