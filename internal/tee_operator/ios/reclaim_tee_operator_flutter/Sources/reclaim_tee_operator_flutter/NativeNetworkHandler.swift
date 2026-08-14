import Foundation
import Network
import Security

/// Connection types matching Go's connection_type_t
enum ConnectionType: Int32 {
  case websocket = 1
  case tcp = 2
}

/// Error codes matching Go's native_net_error_t
enum NativeNetError: Int32 {
  case success = 0
  case unknown = -1
  case timeout = -2
  case eof = -3
  case closed = -4
  case connectFailed = -5
}

/// Represents an active native connection
class NativeConnection {
  let id: Int
  let type: ConnectionType
  let connection: NWConnection

  private var readBuffer: Data = Data()
  private let bufferLock = NSLock()
  private var _isClosed = false
  private let closedLock = NSLock()

  /// Semaphore to signal when data is available in the buffer
  let dataAvailable = DispatchSemaphore(value: 0)

  init(id: Int, type: ConnectionType, connection: NWConnection) {
    self.id = id
    self.type = type
    self.connection = connection
  }

  func appendToBuffer(_ data: Data) {
    bufferLock.lock()
    defer { bufferLock.unlock() }
    readBuffer.append(data)
    dataAvailable.signal()
  }

  func readFromBuffer(maxBytes: Int) -> Data? {
    bufferLock.lock()
    defer { bufferLock.unlock() }

    if readBuffer.isEmpty {
      return nil
    }

    let count = min(maxBytes, readBuffer.count)
    let data = readBuffer.prefix(count)
    readBuffer.removeFirst(count)
    return Data(data)
  }

  func markClosed() {
    closedLock.lock()
    defer { closedLock.unlock() }
    _isClosed = true
    dataAvailable.signal()  // Wake up any waiting readers
  }

  var closed: Bool {
    closedLock.lock()
    defer { closedLock.unlock() }
    return _isClosed
  }
}

/// Manages native network connections for iOS VPN compatibility
///
/// This class uses Network.framework (NWConnection) which properly
/// respects iOS VPN tunnels, unlike raw POSIX sockets used by Go.
@objc public class NativeNetworkHandler: NSObject {

  @objc public static let shared = NativeNetworkHandler()

  private var connections: [Int: NativeConnection] = [:]
  private var nextConnectionId = 1
  private let lock = NSLock()

  private let queue = DispatchQueue(label: "com.reclaim.native-network", qos: .userInitiated)

  private override init() {
    super.init()
  }

  // MARK: - Public API

  /// Connect to the given URL using native iOS networking
  @objc public func connect(
    connType: Int32,
    url: String,
    timeoutMs: Int32
  ) -> NativeConnectionResult {
    guard let type = ConnectionType(rawValue: connType) else {
      return NativeConnectionResult(
        handle: 0,
        errorCode: NativeNetError.unknown.rawValue,
        errorMessage: "Invalid connection type"
      )
    }

    // Parse URL to get host and port
    guard let (host, port, useTLS) = parseURL(url, type: type) else {
      return NativeConnectionResult(
        handle: 0,
        errorCode: NativeNetError.connectFailed.rawValue,
        errorMessage: "Failed to parse URL: \(url)"
      )
    }

    print(
      "NativeNetworkHandler connect: type=\(type) url=\"\(url)\" -> host=\"\(host)\" port=\(port) useTLS=\(useTLS) timeoutMs=\(timeoutMs)"
    )

    // Create NWConnection with appropriate parameters
    let parameters: NWParameters
    if useTLS {
      // TEE nodes (CN=tee_k) present self-signed certificates. Trust is NOT
      // established by the standard CA/hostname chain here — it is established by
      // the TEE attestation handshake performed at the application layer inside
      // the Go libreclaim client over this channel. The default `.tls` parameters
      // would reject the self-signed cert (and the IP/hostname mismatch), so we
      // install a verify block that accepts the transport certificate. This mirrors
      // Android, where the Go client dials directly and likewise does not perform
      // CA-based verification for the TEE transport.
      let tlsOptions = NWProtocolTLS.Options()
      sec_protocol_options_set_verify_block(
        tlsOptions.securityProtocolOptions,
        { _, _, complete in
          complete(true)
        },
        queue
      )
      parameters = NWParameters(tls: tlsOptions)
    } else {
      parameters = .tcp
    }

    // For WebSocket, we need to handle the upgrade ourselves or use URLSessionWebSocketTask
    // For simplicity in this example, we use raw TCP/TLS connections
    // The WebSocket upgrade is handled by the Go gorilla/websocket library

    guard let nwPort = NWEndpoint.Port(rawValue: port) else {
      return NativeConnectionResult(
        handle: 0,
        errorCode: NativeNetError.connectFailed.rawValue,
        errorMessage: "Invalid port number: \(port)"
      )
    }

    let endpoint = NWEndpoint.hostPort(
      host: NWEndpoint.Host(host),
      port: nwPort
    )

    let connection = NWConnection(to: endpoint, using: parameters)

    let connectionId = assignConnectionId()
    let nativeConn = NativeConnection(id: connectionId, type: type, connection: connection)

    // Store connection BEFORE setting up state handler to prevent race condition
    // where data arrives before connection is in the map
    lock.lock()
    connections[connectionId] = nativeConn
    print("Connection added for handle: \(connectionId). Current connections: \(connections.keys)")
    lock.unlock()

    // Set up state handler
    let semaphore = DispatchSemaphore(value: 0)
    var connectError: Error?

    var wasCancelled = false

    connection.stateUpdateHandler = { [weak nativeConn] state in
      switch state {
      case .ready:
        semaphore.signal()
        // Start receiving data
        self.startReceiving(nativeConn)
      case .failed(let error):
        connectError = error
        nativeConn?.markClosed()
        semaphore.signal()
      case .cancelled:
        wasCancelled = true
        nativeConn?.markClosed()
        semaphore.signal()
      default:
        break
      }
    }

    // Start the connection
    connection.start(queue: queue)

    // Wait for connection with timeout
    let timeout = DispatchTime.now() + .milliseconds(Int(timeoutMs))
    let result = semaphore.wait(timeout: timeout)

    // On failure, remove from map and return error
    if result == .timedOut {
      connection.cancel()
      lock.lock()
      connections.removeValue(forKey: connectionId)
      lock.unlock()
      return NativeConnectionResult(
        handle: 0,
        errorCode: NativeNetError.timeout.rawValue,
        errorMessage: "Connection timeout"
      )
    }

    if let error = connectError {
      lock.lock()
      connections.removeValue(forKey: connectionId)
      lock.unlock()
      return NativeConnectionResult(
        handle: 0,
        errorCode: NativeNetError.connectFailed.rawValue,
        errorMessage: error.localizedDescription
      )
    }

    if wasCancelled {
      lock.lock()
      connections.removeValue(forKey: connectionId)
      lock.unlock()
      return NativeConnectionResult(
        handle: 0,
        errorCode: NativeNetError.closed.rawValue,
        errorMessage: "Connection was cancelled"
      )
    }

    return NativeConnectionResult(
      handle: connectionId,
      errorCode: NativeNetError.success.rawValue,
      errorMessage: nil
    )
  }

  /// Read data from the connection
  ///
  /// This method reads from the internal buffer populated by startReceiving().
  /// It waits for data to become available using the connection's semaphore.
  @objc public func read(
    handle: Int,
    maxBytes: Int32,
    timeoutMs: Int32
  ) -> NativeReadResult {
    guard let conn = getConnection(handle) else {
      print("Connection not found for handle: \(handle). Current connections: \(connections.keys)")
      return NativeReadResult(
        data: nil,
        errorCode: NativeNetError.closed.rawValue,
        errorMessage:
          "Connection not found for handle: \(handle). Current connections: \(connections.keys)"
      )
    }

    let timeoutTime = DispatchTime.now() + .milliseconds(Int(timeoutMs))

    while true {
      // Try to read from buffer first
      if let data = conn.readFromBuffer(maxBytes: Int(maxBytes)) {
        return NativeReadResult(data: data, errorCode: NativeNetError.success.rawValue)
      }

      // Check if connection is closed after checking buffer
      // to ensure we always drain the buffer before reporting EOF
      if conn.closed {
        return NativeReadResult(data: nil, errorCode: NativeNetError.eof.rawValue)
      }

      // Wait for data to be available in the buffer
      let waitResult = conn.dataAvailable.wait(timeout: timeoutTime)

      // If we timed out, report it.
      // If we didn't time out, we loop back up to check buffer.
      // This safely consumes any spurious/unaligned semaphore signals.
      if waitResult == .timedOut {
        return NativeReadResult(data: nil, errorCode: NativeNetError.timeout.rawValue)
      }
    }
  }

  /// Write data to the connection
  @objc public func write(
    handle: Int,
    data: Data
  ) -> Int32 {
    guard let conn = getConnection(handle) else {
      print("Connection not found for handle: \(handle). Current connections: \(connections.keys)")
      return NativeNetError.closed.rawValue
    }

    if conn.closed {
      return NativeNetError.closed.rawValue
    }

    let semaphore = DispatchSemaphore(value: 0)
    var writeError: NWError?

    conn.connection.send(
      content: data,
      completion: .contentProcessed { error in
        writeError = error
        semaphore.signal()
      })

    // Wait for write to complete (with reasonable timeout)
    let result = semaphore.wait(timeout: .now() + .seconds(30))

    if result == .timedOut {
      return NativeNetError.timeout.rawValue
    }

    if writeError != nil {
      return NativeNetError.unknown.rawValue
    }

    return Int32(data.count)
  }

  /// Close the connection
  @objc public func close(handle: Int) {
    lock.lock()
    guard let conn = connections.removeValue(forKey: handle) else {
      lock.unlock()
      return
    }
    lock.unlock()

    conn.markClosed()
    conn.connection.cancel()
  }

  // MARK: - Private Helpers

  private func assignConnectionId() -> Int {
    lock.lock()
    defer { lock.unlock() }
    let id = nextConnectionId
    nextConnectionId += 1
    return id
  }

  private func getConnection(_ handle: Int) -> NativeConnection? {
    lock.lock()
    defer { lock.unlock() }
    return connections[handle]
  }

  private func parseURL(_ url: String, type: ConnectionType) -> (
    host: String, port: UInt16, useTLS: Bool
  )? {
    // Handle WebSocket URLs
    if type == .websocket {
      if url.hasPrefix("wss://") {
        let stripped = String(url.dropFirst(6))
        return parseHostPort(stripped, defaultPort: 443, useTLS: true)
      } else if url.hasPrefix("ws://") {
        let stripped = String(url.dropFirst(5))
        return parseHostPort(stripped, defaultPort: 80, useTLS: false)
      }
    }

    // Handle TCP addresses (host:port format)
    // TCP connections are plain by default; TLS is handled at application layer
    if type == .tcp {
      return parseHostPort(url, defaultPort: 443, useTLS: false)
    }

    // Try generic URL parsing
    if let parsed = URL(string: url) {
      let host = parsed.host ?? ""
      let port = UInt16(
        parsed.port ?? (parsed.scheme == "https" || parsed.scheme == "wss" ? 443 : 80))
      let useTLS = parsed.scheme == "https" || parsed.scheme == "wss"
      return (host, port, useTLS)
    }

    return nil
  }

  private func parseHostPort(_ str: String, defaultPort: UInt16, useTLS: Bool) -> (
    host: String, port: UInt16, useTLS: Bool
  )? {
    // Remove path component if present
    let hostPort = str.split(separator: "/").first.map(String.init) ?? str

    // Handle IPv6 addresses in brackets: [::1]:8080
    if hostPort.hasPrefix("[") {
      if let closeBracket = hostPort.firstIndex(of: "]") {
        let host = String(hostPort[hostPort.index(after: hostPort.startIndex)..<closeBracket])
        let afterBracket = hostPort.index(after: closeBracket)
        if afterBracket < hostPort.endIndex && hostPort[afterBracket] == ":" {
          let portStr = String(hostPort[hostPort.index(after: afterBracket)...])
          if let port = UInt16(portStr) {
            return (host, port, useTLS)
          }
        }
        return (host, defaultPort, useTLS)
      }
      return nil  // Malformed IPv6 address
    }

    // Parse host:port for IPv4/hostname (only use last colon to handle edge cases)
    if let colonIndex = hostPort.lastIndex(of: ":") {
      let host = String(hostPort[..<colonIndex])
      let portStr = String(hostPort[hostPort.index(after: colonIndex)...])
      if let port = UInt16(portStr) {
        return (host, port, useTLS)
      }
    }

    return (hostPort, defaultPort, useTLS)
  }

  private func startReceiving(_ conn: NativeConnection?) {
    guard let conn = conn, !conn.closed else { return }

    conn.connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) {
      [weak self, weak conn] data, _, isComplete, error in
      guard let self = self, let conn = conn else { return }

      if let data = data, !data.isEmpty {
        conn.appendToBuffer(data)
      }

      if isComplete || error != nil {
        conn.markClosed()
        // DO NOT remove closed connection from registry here.
        // We must keep it so `read()` can drain any remaining buffer
        // and correctly return EOF. Dart/Go will explicitly call `close()` to remove it.
      } else {
        // Continue receiving
        self.startReceiving(conn)
      }
    }
  }
}

// MARK: - Result Types

@objc public class NativeConnectionResult: NSObject {
  @objc public let handle: Int
  @objc public let errorCode: Int32
  @objc public let errorMessage: String?

  init(handle: Int, errorCode: Int32, errorMessage: String?) {
    self.handle = handle
    self.errorCode = errorCode
    self.errorMessage = errorMessage
  }
}

@objc public class NativeReadResult: NSObject {
  @objc public let data: Data?
  @objc public let errorCode: Int32
  @objc public let errorMessage: String?

  init(data: Data?, errorCode: Int32, errorMessage: String? = nil) {
    self.data = data
    self.errorCode = errorCode
    self.errorMessage = errorMessage
  }
}
