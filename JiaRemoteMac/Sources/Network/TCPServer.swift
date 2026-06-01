import Foundation
import Cocoa
import Network
import IOSurface
import CoreVideo
import CoreMedia
import VideoToolbox

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
    private let commandQueue = DispatchQueue(label: "com.jiaremote.tcp.command", qos: .userInitiated)
    private let stateLock = DispatchQueue(label: "com.jiaremote.tcp.state")
    private let vtEncodeQueue = DispatchQueue(label: "com.jiaremote.vtencode", qos: .userInteractive)
    private var vtSession: VTCompressionSession?

    private let latestFrameLock = DispatchQueue(label: "com.jiaremote.latestframe")
    private var frameTimer: DispatchSourceTimer?
    private var latestPixelBuffer: CVPixelBuffer?
    private var latestFormat: UInt32 = 0
    private var latestTimestamp: UInt64 = 0
    private var frameSendCount: Int = 0

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
                JiaLog("[TCPServer] Listener waiting: \(error)")

            case .ready:
                JiaLog("[TCPServer] Listener ready on port \(self.activePort)")
                self.stateLock.sync { self.isRunning = true }

            case .failed(let error):
                JiaLog("[TCPServer] Listener failed: \(error)")
                self.stateLock.sync { self.isRunning = false }
                self.stop()

            case .cancelled:
                JiaLog("[TCPServer] Listener cancelled")
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

        stateLock.sync {
            connectedClientHost = nil
        }

        latestFrameLock.sync {
            latestPixelBuffer = nil
        }
        stopFrameTimer()
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
                JiaLog("[TCPServer] Command response send error: \(error)")
            }
        }))
    }

    func sendCommandResponse<T: Encodable>(type: JiaProtocol.CommandType, payload: T) {
        guard let payloadData = try? JSONEncoder().encode(payload) else { return }
        sendCommandResponse(type: type, payload: payloadData)
    }

    private func handleNewConnection(_ connection: NWConnection) {
        JiaLog("[TCPServer] 📥 New incoming connection from \(connection.endpoint)")

        connection.stateUpdateHandler = { [weak self, weak connection] state in
            guard let self, let connection else { return }

            switch state {
            case .setup:
                break

            case .waiting(let error):
                JiaLog("[TCPServer] Connection waiting: \(error)")

            case .preparing:
                break

            case .ready:
                JiaLog("[TCPServer] Connection ready: \(connection.endpoint) → starting handshake")
                self.classifyConnection(connection)

            case .failed(let error):
                JiaLog("[TCPServer] Connection failed: \(error)")
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
                JiaLog("[TCPServer] Failed to send ready message: \(error)")
                connection.cancel()
                return
            }

            JiaLog("[TCPServer] Sent JR_READY to \(connection.endpoint), waiting for channel ID...")
            self.receiveChannelIdentification(from: connection)
        }))
    }

    private func receiveChannelIdentification(from connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 256) { [weak self, weak connection] data, _, isComplete, error in
            guard let self, let connection else { return }

            if let error {
                JiaLog("[TCPServer] Channel identification error: \(error)")
                connection.cancel()
                return
            }

            if isComplete {
                JiaLog("[TCPServer] Channel ID recv: connection completed before identification")
                connection.cancel()
                return
            }

            guard let data,
                  let identifier = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) else {
                self.receiveChannelIdentification(from: connection)
                return
            }

            JiaLog("[TCPServer] Received channel identifier: '\(identifier)' from \(connection.endpoint)")

            if identifier.hasPrefix(JiaProtocol.ProtocolConstants.frameChannelPrefix) {
                JiaLog("[TCPServer] → Classified as FRAME channel")
                self.acceptFrameChannel(connection)
            } else if identifier.hasPrefix(JiaProtocol.ProtocolConstants.commandChannelPrefix) {
                JiaLog("[TCPServer] → Classified as COMMAND channel")
                self.acceptCommandChannel(connection)
            } else if identifier == "JR_SCAN" {
                let hostname = Host.current().localizedName ?? "JiaRemote"
                let response = "JR_HOST:\(hostname)|v1.0"
                connection.send(content: response.data(using: .utf8), completion: .contentProcessed({ _ in
                    connection.cancel()
                }))
            } else {
                JiaLog("[TCPServer] → Unknown identifier '\(identifier)', closing in 0.5s")
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
        JiaLog("[TCPServer] ✅ Frame channel established (\(connection.endpoint))")

        connection.stateUpdateHandler = { [weak self] state in
            guard let self else { return }

            switch state {
            case .failed(let error):
                JiaLog("[TCPServer] Frame connection failed: \(error)")
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
        frameConnection?.cancel()
        frameConnection = nil
        stateLock.sync { isFrameConnected = false }
        unsubscribeFromCaptureEngine()
    }

    private func handleFrameDisconnection() {
        frameConnection?.stateUpdateHandler = nil
        frameConnection = nil
        stateLock.sync { isFrameConnected = false }
        unsubscribeFromCaptureEngine()

        checkClientDisconnection()
    }

    private func acceptCommandChannel(_ connection: NWConnection) {
        disconnectCommandChannel()

        commandConnection = connection
        commandBuffer.removeAll(keepingCapacity: true)
        stateLock.sync { isCommandConnected = true }
        JiaLog("[TCPServer] ✅ Command channel established (\(connection.endpoint))")

        connection.stateUpdateHandler = { [weak self] state in
            guard let self else { return }

            switch state {
            case .failed(let error):
                JiaLog("[TCPServer] Command connection failed: \(error)")
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
                JiaLog("[TCPServer] Command receive error: \(error)")
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
        JiaLog("[TCPServer] checkFullConnection: frame=\(stateLock.sync { isFrameConnected }), cmd=\(stateLock.sync { isCommandConnected }) → \(isFull ? "FULLY CONNECTED!" : "waiting...")")

        guard isFull else { return }

        stateLock.sync {
            reconnectAttempts = 0
        }

        guard let frameConn = frameConnection,
              let remoteEndpoint = frameConn.currentPath?.remoteEndpoint else { return }

        if case .hostPort(let host, _) = remoteEndpoint {
            let hostStr = "\(host)"
            stateLock.sync { connectedClientHost = hostStr }
            JiaLog("[TCPServer] 🎉 Client fully connected: \(hostStr)")
            delegate?.tcpServerDidAcceptClient(self, host: hostStr)
        }

        startFrameTimer()
    }

    private func checkClientDisconnection() {
        let isAnyConnected = stateLock.sync { isFrameConnected || isCommandConnected }

        if !isAnyConnected {
            stopFrameTimer()
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

        JiaLog("[TCPServer] Auto-reconnect attempt \(attempt)/\(maxReconnectAttempts)")

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
                    JiaLog("[TCPServer] Reconnect attempt \(attempt) failed: \(error)")
                    self.stateLock.sync { self.reconnectAttempts = attempt }
                    self.checkClientDisconnection()
                }
            }
        }
    }
}

extension TCPServer: CaptureEngineDelegate {

    private func ensureVTSession(width: Int, height: Int) -> VTCompressionSession? {
        if let session = vtSession { return session }
        var session: VTCompressionSession?
        let status = VTCompressionSessionCreate(
            allocator: kCFAllocatorDefault,
            width: Int32(width), height: Int32(height),
            codecType: kCMVideoCodecType_JPEG,
            encoderSpecification: nil,
            imageBufferAttributes: nil,
            compressedDataAllocator: kCFAllocatorDefault,
            outputCallback: nil,
            refcon: nil,
            compressionSessionOut: &session
        )
        guard status == noErr, let session else {
            JiaLog("[TCPServer] VTCompressionSessionCreate failed: \(status)")
            return nil
        }
        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_Quality, value: NSNumber(value: 0.4))
        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_RealTime, value: kCFBooleanTrue)
        vtSession = session
        return session
    }

    private func encodeJPEG(pixelBuffer: CVPixelBuffer) -> Data? {
        guard let session = ensureVTSession(
            width: CVPixelBufferGetWidth(pixelBuffer),
            height: CVPixelBufferGetHeight(pixelBuffer)
        ) else { return nil }

        var resultData: Data?
        let sema = DispatchSemaphore(value: 0)
        var infoFlags = VTEncodeInfoFlags()

        let status = VTCompressionSessionEncodeFrame(
            session,
            imageBuffer: pixelBuffer,
            presentationTimeStamp: CMTime.zero,
            duration: CMTime.invalid,
            frameProperties: nil,
            infoFlagsOut: &infoFlags
        ) { status, _, sampleBuffer in
            defer { sema.signal() }
            guard status == noErr, let sampleBuffer else { return }
            guard let dataBuffer = sampleBuffer.dataBuffer else { return }
            var length: Int = 0
            var ptr: UnsafeMutablePointer<Int8>?
            if CMBlockBufferGetDataPointer(dataBuffer, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &length, dataPointerOut: &ptr) == noErr, let ptr {
                resultData = Data(bytes: ptr, count: length)
            }
        }

        if status != noErr { return nil }
        _ = sema.wait(timeout: .now() + .seconds(1))
        return resultData
    }

    func captureEngine(_ engine: CaptureEngine, didOutput frame: CaptureFrame) {
        let pb = frame.pixelBuffer
        let fmt = CVPixelBufferGetPixelFormatType(pb)
        let ts = frame.displayTime.timescale > 0
            ? UInt64(frame.displayTime.value) * 1000 / UInt64(frame.displayTime.timescale)
            : UInt64(0)

        CVPixelBufferLockBaseAddress(pb, .readOnly)
        let base = CVPixelBufferGetBaseAddress(pb)
        CVPixelBufferUnlockBaseAddress(pb, .readOnly)
        guard base != nil else { return }

        latestFrameLock.sync {
            latestPixelBuffer = pb
            latestFormat = fmt
            latestTimestamp = ts
        }
    }

    func captureEngine(_ engine: CaptureEngine, didEncounterError error: Error) {
        JiaLog("[TCPServer] ❌ Capture error: \(error)")
    }

    func captureEngineDidStop(_ engine: CaptureEngine) {
        JiaLog("[TCPServer] ⏹ Capture stopped")
        if let session = vtSession {
            VTCompressionSessionInvalidate(session)
            vtSession = nil
        }
    }

    func startFrameTimer() {
        stopFrameTimer()
        let timer = DispatchSource.makeTimerSource(queue: vtEncodeQueue)
        timer.schedule(deadline: .now(), repeating: .nanoseconds(8_333_333), leeway: .nanoseconds(500_000))
        timer.setEventHandler { [weak self] in self?.onFrameTick() }
        timer.activate()
        frameTimer = timer
        JiaLog("[TCPServer] ▶️ 120Hz frame timer started")
    }

    func stopFrameTimer() {
        frameTimer?.cancel()
        frameTimer = nil
    }

    private func onFrameTick() {
        guard stateLock.sync(execute: { isFrameConnected }) else { return }

        var pb: CVPixelBuffer?
        var fmt: UInt32 = 0
        var ts: UInt64 = 0
        latestFrameLock.sync {
            pb = latestPixelBuffer
            fmt = latestFormat
            ts = latestTimestamp
        }
        guard let pixelBuffer = pb else { return }

        guard let jpegData = encodeJPEG(pixelBuffer: pixelBuffer) else { return }

        let w = CVPixelBufferGetWidth(pixelBuffer)
        let h = CVPixelBufferGetHeight(pixelBuffer)
        let formatWithFlag = fmt | JiaProtocol.ProtocolConstants.compressionFlag
        let header = JiaProtocol.FrameHeader(
            width: UInt32(w), height: UInt32(h),
            bytesPerRow: UInt32(w * 4),
            pixelFormat: formatWithFlag,
            timestamp: ts,
            dataLength: UInt64(jpegData.count)
        )
        let frameData = header.encodeFrame(pixelData: jpegData)
        frameSendCount += 1

        guard let conn = frameConnection else { return }
        conn.send(content: frameData, completion: .contentProcessed({ _ in }))
    }
}
