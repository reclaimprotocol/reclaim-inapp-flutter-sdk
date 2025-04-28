protocol RpcClientProtocol {
    func send(message: RpcMessageProtocol) async throws
    func sendRequest(method: String, params: (any Codable)?) async throws -> RpcMessageProtocol
    var messageStream: AsyncStream<RpcMessageProtocol> { get }
    func close()
}
