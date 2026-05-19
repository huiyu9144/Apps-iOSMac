import Foundation
import Network
import IOSurface
import CoreVideo
import CoreMedia

enum TCPServerError: Error, LocalizedError {
    case invalidPort
    case listenerCreationFailed(Error)
    case sendFailed(Error)
    case alreadyRunning
    case notRunning

    var errorDescription: String? {
        switch self {
        case .invalidPort:
            return "Invalid port number."
        case .listenerCreationFailed(let error):
            return "Failed to create listener: \(error.localizedDescription)"
        case .sendFailed(let error):
            return "Failed to send data: \(error.localizedDescription)"
        case .alreadyRunning:
            return "TCP server is already running."
        case .notRunning:
            return "TCP server is not running."
        }
    }
}

protocol TCPServerDelegate: AnyObject {
    func tcpServerDidAcceptClient(_ server: TCPServer, host: String)
    func tcpServerDidDisconnectClient(_ server: TCPServer)
    func tcpServer(_ server: TCPServer, didReceiveCommand type: JiaProtocol.CommandType, payload: Data)
}

extension TCPServerDelegate {
    func tcpServerDidAcceptClient(_ server: TCPServer, host: String) {}
    func tcpServerDidDisconnectClient(_ server: TCPServer) {}
    func tcpServer(_ server: TCPServer, didReceiveCommand type: JiaProtocol.CommandType, payload: Data) {}
}

final class TCPServer {

    private enum ChannelTag: Int {
        case frame = 0
        case command = 1
    }

    weak var delegate: TCPServerDelegate?
    weak var captureEngine: CaptureEngine?

    private var listener: NWListener?
    private var frameConnection: NWConnection?
    private var commandConnection: NWConnection?

    private let serverQueue = DispatchQueue(label: "com.jiaremote.tcp.server", qos: .userInitiated)
    private let frameSendQueue = DispatchQueue(label: "com.jiaremote.tcp.frame", qos: .userInteractive)
    private let commandQueue = DispatchQueue(label: "com.jiaremote.tcp.command", qos: .userInitiated)
    private let stateLock = DispatchQueue(label: "com.jiaremote.tcp.state")
    private let frameBufferLock = DispatchQueue(label: "com.jiaremote.tcp.framebuffer")

    private let maxFrameBufferSize = 3
    private var frameRingBuffer: [Data] = []
    private var isSendingFrame = false

    private var activePort: UInt16 = JiaProtocol.ProtocolConstants.defaultPort

    private(set) var isRunning: Bool = false
    private(set) var connectedClientHost: String?

    private var isFrameConnected: Bool = false
    private var isCommandConnected: Bool = false

    private var shouldAutoReconnect: Bool = false
    private var reconnectAttempts: Int = 0
    private let maxReconnectAttempts: Int = 10
    private let reconnectDelay: TimeInterval = 2.0

    private var bonjourService: NetService?
    private var commandBuffer = Data()

    deinit {
        stop()
        stopBonjour()
    }

    var isClientConnected: Bool {
        stateLock.sync { isFrameConnected && isCommandConnected }
    }

    var autoReconnectEnabled: Bool {
        get { stateLock.sync { shouldAutoReconnect } }
        set { stateLock.sync { shouldAutoReconnect = newValue } }
    }

    var listeningPort: UInt16? {
        stateLock.sync { isRunning ? activePort : nil }
    }

    func start(port: UInt16 = JiaProtocol.ProtocolConstants.defaultPort) throws {
        guard !isRunning else {
            throw TCPServerError.alreadyRunning
        }

        activePort = port

        let parameters = NWParameters.tcp
        parameters.allowLocalEndpointReuse = true

        let tcpOptions = NWProtocolTCP.Options()
        tcpOptions.noDelay = true
        tcpOptions.enableKeepalive = true
        tcpOptions.keepaliveCount = 5
        tcpOptions.keepaliveIdle = 10
        tcpOptions.keepaliveInterval = 5
        parameters.defaultProtocolStack.transportProtocol = tcpOptions

        guard let nwPort = NWEndpoint.Port(rawValue: port) else {
            throw TCPServerError.invalidPort
        }

        do {
            listener = try NWListener(using: parameters, on: nwPort)
        } catch {
            throw TCPServerError.listenerCreationFailed(error)
        }

        listener?.stateUpdateHandler = { [weak self] state in
            guard let self else { return }

            switch state {
            case .setup:
                break

            case .waiting(let error):
                print("[TCPServer] Listener waiting: \(error)")

            case .ready:
                print("[TCPServer] Listener ready on port \(self.activePort)")
                self.stateLock.sync { self.isRunning = true }

            case .failed(let error):
                print("[TCPServer] Listener failed: \(error)")
                self.stateLock.sync { self.isRunning = false }
                self.stop()

            case .cancelled:
                print("[TCPServer] Listener cancelled")
                self.stateLock.sync { self.isRunning = false }

            @unknown default:
                break
            }
        }

        listener?.newConnectionHandler = { [weak self] connection in
            guard let self else {
                connection.cancel()
                return
            }
            self.handleNewConnection(connection)
        }

        listener?.start(queue: serverQueue)
    }

    func stop() {
        stateLock.sync {
            isRunning = false
            shouldAutoReconnect = false
        }

        listener?.stateUpdateHandler = nil
        listener?.newConnectionHandler = nil
        listener?.cancel()
        listener = nil

        disconnectFrameChannel()
        disconnectCommandChannel()

        frameBufferLock.sync {
            frameRingBuffer.removeAll()
        }

        stateLock.sync {
            connectedClientHost = nil
        }
    }

    func startBonjour() {
        stopBonjour()

        bonjourService = NetService(
            domain: "local.",
            type: "_jiaremote._tcp.",
            name: Host.current().localizedName ?? "JiaRemote",
            port: Int32(activePort)
        )

        bonjourService?.includesPeerToPeer = true
        bonjourService?.publish()
    }

    func stopBonjour() {
        bonjourService?.stop()
        bonjourService = nil
    }

    func sendCommandResponse(type: JiaProtocol.CommandType, payload: Data) {
        guard let connection = commandConnection else { return }

        let header = JiaProtocol.MessageHeader(commandType: type, payloadLength: UInt64(payload.count))
        var sendData = Data(capacity: JiaProtocol.MessageHeader.headerSize + payload.count)
        sendData.append(header.encode())
        sendData.append(payload)

        connection.send(content: sendData, completion: .contentProcessed({ error in
            if let error {
                print("[TCPServer] Command response send error: \(error)")
            }
        }))
    }

    func sendCommandResponse<T: Encodable>(type: JiaProtocol.CommandType, payload: T) {
        guard let payloadData = try? JSONEncoder().encode(payload) else { return }
        sendCommandResponse(type: type, payload: payloadData)
    }

    private func handleNewConnection(_ connection: NWConnection) {
        print("[TCPServer] 📥 New incoming connection from \(connection.endpoint)")

        connection.stateUpdateHandler = { [weak self, weak connection] state in
            guard let self, let connection else { return }

            switch state {
            case .setup:
                break

            case .waiting(let error):
                print("[TCPServer] Connection waiting: \(error)")

            case .preparing:
                break

            case .ready:
                print("[TCPServer] Connection ready: \(connection.endpoint) → starting handshake")
                self.classifyConnection(connection)

            case .failed(let error):
                print("[TCPServer] Connection failed: \(error)")
                connection.cancel()

            case .cancelled:
                break

            @unknown default:
                break
            }
        }

        connection.start(queue: serverQueue)
    }

    private func classifyConnection(_ connection: NWConnection) {
        let initialMessage = "JR_READY\r\n".data(using: .utf8)!

        connection.send(content: initialMessage, completion: .contentProcessed({ [weak self, weak connection] error in
            guard let self, let connection else { return }

            if let error {
                print("[TCPServer] Failed to send ready message: \(error)")
                connection.cancel()
                return
            }

            print("[TCPServer] Sent JR_READY to \(connection.endpoint), waiting for channel ID...")
            self.receiveChannelIdentification(from: connection)
        }))
    }

    private func receiveChannelIdentification(from connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 256) { [weak self, weak connection] data, _, isComplete, error in
            guard let self, let connection else { return }

            if let error {
                print("[TCPServer] Channel identification error: \(error)")
                connection.cancel()
                return
            }

            if isComplete {
                print("[TCPServer] Channel ID recv: connection completed before identification")
                connection.cancel()
                return
            }

            guard let data,
                  let identifier = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) else {
                self.receiveChannelIdentification(from: connection)
                return
            }

            print("[TCPServer] Received channel identifier: '\(identifier)' from \(connection.endpoint)")

            if identifier.hasPrefix(JiaProtocol.ProtocolConstants.frameChannelPrefix) {
                print("[TCPServer] → Classified as FRAME channel")
                self.acceptFrameChannel(connection)
            } else if identifier.hasPrefix(JiaProtocol.ProtocolConstants.commandChannelPrefix) {
                print("[TCPServer] → Classified as COMMAND channel")
                self.acceptCommandChannel(connection)
            } else if identifier == "JR_SCAN" {
                let hostname = Host.current().localizedName ?? "JiaRemote"
                let response = "JR_HOST:\(hostname)|v1.0"
                connection.send(content: response.data(using: .utf8), completion: .contentProcessed({ _ in
                    connection.cancel()
                }))
            } else {
                print("[TCPServer] → Unknown identifier '\(identifier)', closing in 0.5s")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak connection] in
                    connection?.cancel()
                }
            }
        }
    }

    private func acceptFrameChannel(_ connection: NWConnection) {
        disconnectFrameChannel()

        frameConnection = connection
        stateLock.sync { isFrameConnected = true }
        print("[TCPServer] ✅ Frame channel established (\(connection.endpoint))")

        connection.stateUpdateHandler = { [weak self] state in
            guard let self else { return }

            switch state {
            case .failed(let error):
                print("[TCPServer] Frame connection failed: \(error)")
                self.handleFrameDisconnection()
            case .cancelled:
                self.handleFrameDisconnection()
            default:
                break
            }
        }

        checkFullConnection()
        subscribeToCaptureEngine()
    }

    private func disconnectFrameChannel() {
        frameConnection?.stateUpdateHandler = nil
        frameConnection?.cancel()
        frameConnection = nil
        stateLock.sync { isFrameConnected = false }
        unsubscribeFromCaptureEngine()

        frameBufferLock.sync {
            frameRingBuffer.removeAll()
        }
    }

    private func handleFrameDisconnection() {
        frameConnection?.stateUpdateHandler = nil
        frameConnection = nil
        stateLock.sync { isFrameConnected = false }
        unsubscribeFromCaptureEngine()

        frameBufferLock.sync {
            frameRingBuffer.removeAll()
        }

        checkClientDisconnection()
    }

    private func acceptCommandChannel(_ connection: NWConnection) {
        disconnectCommandChannel()

        commandConnection = connection
        commandBuffer.removeAll(keepingCapacity: true)
        stateLock.sync { isCommandConnected = true }
        print("[TCPServer] ✅ Command channel established (\(connection.endpoint))")

        connection.stateUpdateHandler = { [weak self] state in
            guard let self else { return }

            switch state {
            case .failed(let error):
                print("[TCPServer] Command connection failed: \(error)")
                self.handleCommandDisconnection()
            case .cancelled:
                self.handleCommandDisconnection()
            default:
                break
            }
        }

        checkFullConnection()
        beginReceivingCommands()
    }

    private func disconnectCommandChannel() {
        commandConnection?.stateUpdateHandler = nil
        commandConnection?.cancel()
        commandConnection = nil
        commandBuffer.removeAll(keepingCapacity: true)
        stateLock.sync { isCommandConnected = false }
    }

    private func handleCommandDisconnection() {
        commandConnection?.stateUpdateHandler = nil
        commandConnection = nil
        commandBuffer.removeAll(keepingCapacity: true)
        stateLock.sync { isCommandConnected = false }

        checkClientDisconnection()
    }

    private func beginReceivingCommands() {
        guard let connection = commandConnection else { return }
        receiveCommandData(connection)
    }

    private func receiveCommandData(_ connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self, weak connection] data, _, isComplete, error in
            guard let self, let connection else { return }

            if isComplete {
                self.handleCommandDisconnection()
                return
            }

            if let error {
                print("[TCPServer] Command receive error: \(error)")
                self.handleCommandDisconnection()
                return
            }

            if let data {
                self.processCommandData(data)
            }

            if self.stateLock.sync(execute: { self.isCommandConnected }) {
                self.receiveCommandData(connection)
            }
        }
    }

    private func processCommandData(_ data: Data) {
        commandQueue.async { [weak self] in
            guard let self else { return }

            self.commandBuffer.append(data)
            self.parseCommandMessages()
        }
    }

    private func parseCommandMessages() {
        let headerSize = JiaProtocol.MessageHeader.headerSize
        let magic = JiaProtocol.MessageHeader.magicBytes

        while commandBuffer.count >= headerSize {
            if commandBuffer.count >= 4,
               commandBuffer[0] == magic[0],
               commandBuffer[1] == magic[1],
               commandBuffer[2] == magic[2],
               commandBuffer[3] == magic[3] {

                guard let header = JiaProtocol.MessageHeader.decode(from: commandBuffer) else {
                    if commandBuffer.count >= headerSize {
                        commandBuffer.removeFirst(1)
                    } else {
                        break
                    }
                    continue
                }

                let totalMessageSize = headerSize + Int(header.payloadLength)

                guard commandBuffer.count >= totalMessageSize else { break }

                let startIndex = commandBuffer.index(commandBuffer.startIndex, offsetBy: headerSize)
                let endIndex = commandBuffer.index(startIndex, offsetBy: Int(header.payloadLength))
                let payload = Data(commandBuffer[startIndex..<endIndex])

                let commandType = header.commandType
                let payloadData = payload

                commandBuffer.removeSubrange(commandBuffer.startIndex..<endIndex)

                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.delegate?.tcpServer(self, didReceiveCommand: commandType, payload: payloadData)
                }

            } else {
                commandBuffer.removeFirst(1)
            }
        }
    }

    private func subscribeToCaptureEngine() {
        captureEngine?.delegate = self
    }

    private func unsubscribeFromCaptureEngine() {
        captureEngine?.delegate = nil
    }

    private func checkFullConnection() {
        let isFull = stateLock.sync { isFrameConnected && isCommandConnected }
        print("[TCPServer] checkFullConnection: frame=\(stateLock.sync { isFrameConnected }), cmd=\(stateLock.sync { isCommandConnected }) → \(isFull ? "FULLY CONNECTED!" : "waiting...")")

        guard isFull else { return }

        stateLock.sync {
            reconnectAttempts = 0
        }

        guard let frameConn = frameConnection,
              let remoteEndpoint = frameConn.currentPath?.remoteEndpoint else { return }

        if case .hostPort(let host, _) = remoteEndpoint {
            let hostStr = "\(host)"
            stateLock.sync { connectedClientHost = hostStr }
            print("[TCPServer] 🎉 Client fully connected: \(hostStr)")
            delegate?.tcpServerDidAcceptClient(self, host: hostStr)
        }
    }

    private func checkClientDisconnection() {
        let isAnyConnected = stateLock.sync { isFrameConnected || isCommandConnected }

        if !isAnyConnected {
            let previousHost = stateLock.sync { connectedClientHost }
            stateLock.sync { connectedClientHost = nil }

            if previousHost != nil {
                delegate?.tcpServerDidDisconnectClient(self)
            }

            if stateLock.sync(execute: { shouldAutoReconnect && isRunning }) {
                attemptReconnect()
            }
        }
    }

    private func attemptReconnect() {
        guard stateLock.sync(execute: { shouldAutoReconnect && isRunning && reconnectAttempts < maxReconnectAttempts }) else {
            return
        }

        stateLock.sync { reconnectAttempts += 1 }
        let attempt = reconnectAttempts
        let port = activePort

        print("[TCPServer] Auto-reconnect attempt \(attempt)/\(maxReconnectAttempts)")

        DispatchQueue.global().asyncAfter(deadline: .now() + reconnectDelay) { [weak self] in
            guard let self else { return }
            guard self.stateLock.sync(execute: { self.isRunning }) else { return }

            self.stop()

            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self else { return }
                do {
                    try self.start(port: port)
                    self.autoReconnectEnabled = true
                } catch {
                    print("[TCPServer] Reconnect attempt \(attempt) failed: \(error)")
                    self.stateLock.sync { self.reconnectAttempts = attempt }
                    self.checkClientDisconnection()
                }
            }
        }
    }
}

extension TCPServer: CaptureEngineDelegate {

    func captureEngine(_ engine: CaptureEngine, didOutput frame: CaptureFrame) {
        guard stateLock.sync(execute: { isFrameConnected }) else { return }

        let pixelBuffer = frame.pixelBuffer

        guard let ioSurface = frame.ioSurface else { return }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = IOSurfaceGetBytesPerRow(ioSurface)
        let pixelFormatType = CVPixelBufferGetPixelFormatType(pixelBuffer)
        let dataSize = bytesPerRow * height

        guard dataSize > 0, dataSize <= JiaProtocol.ProtocolConstants.maxFrameSize else { return }

        let timestampValue = frame.displayTime.timescale > 0
            ? UInt64(frame.displayTime.value) * 1000 / UInt64(frame.displayTime.timescale)
            : UInt64(0)

        let header = JiaProtocol.FrameHeader(
            width: UInt32(width),
            height: UInt32(height),
            bytesPerRow: UInt32(bytesPerRow),
            pixelFormat: pixelFormatType,
            timestamp: timestampValue,
            dataLength: UInt64(dataSize)
        )

        IOSurfaceLock(ioSurface, .readOnly, nil)
        defer { IOSurfaceUnlock(ioSurface, .readOnly, nil) }

        let baseAddress = IOSurfaceGetBaseAddress(ioSurface)

        let pixelData = Data(bytes: baseAddress, count: dataSize)
        let fullFrame = header.encodeFrame(pixelData: pixelData)

        enqueueFrame(fullFrame)
    }

    func captureEngine(_ engine: CaptureEngine, didEncounterError error: Error) {
        print("[TCPServer] Capture error: \(error)")
    }

    func captureEngineDidStop(_ engine: CaptureEngine) {
        frameBufferLock.sync {
            frameRingBuffer.removeAll()
        }
    }

    private func enqueueFrame(_ frameData: Data) {
        frameBufferLock.sync {
            if frameRingBuffer.count >= maxFrameBufferSize {
                frameRingBuffer.removeFirst()
            }
            frameRingBuffer.append(frameData)
        }
        sendNextFrame()
    }

    private func sendNextFrame() {
        frameSendQueue.async { [weak self] in
            guard let self else { return }
            guard !self.isSendingFrame else { return }

            var frameData: Data?
            self.frameBufferLock.sync {
                if !self.frameRingBuffer.isEmpty {
                    frameData = self.frameRingBuffer.removeFirst()
                }
            }

            guard let data = frameData,
                  let connection = self.frameConnection else { return }

            self.isSendingFrame = true

            connection.send(content: data, completion: .contentProcessed({ [weak self] error in
                guard let self else { return }
                self.isSendingFrame = false

                if let error {
                    print("[TCPServer] Frame send error: \(error)")
                }

                self.sendNextFrame()
            }))
        }
    }
}
