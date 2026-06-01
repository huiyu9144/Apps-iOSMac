import Foundation

enum JiaProtocol {

    struct FrameHeader {
        let width: UInt32
        let height: UInt32
        let bytesPerRow: UInt32
        let pixelFormat: UInt32
        let timestamp: UInt64
        let dataLength: UInt64

        static let magicBytes: [UInt8] = [0x4A, 0x52, 0x4D, 0x43]
        static let headerSize = 36

        var headerData: Data {
            var data = Data(capacity: FrameHeader.headerSize)
            data.append(contentsOf: FrameHeader.magicBytes)
            data.append(packUInt32(width))
            data.append(packUInt32(height))
            data.append(packUInt32(bytesPerRow))
            data.append(packUInt32(pixelFormat))
            data.append(packUInt64(timestamp))
            data.append(packUInt64(dataLength))
            return data
        }

        var totalFrameSize: Int {
            FrameHeader.headerSize + Int(dataLength)
        }

        static func decode(from data: Data) -> FrameHeader? {
            guard data.count >= headerSize else { return nil }
            guard data[0] == magicBytes[0],
                  data[1] == magicBytes[1],
                  data[2] == magicBytes[2],
                  data[3] == magicBytes[3] else { return nil }

            var offset = 4
            let width = unpackUInt32(data, offset: offset); offset += 4
            let height = unpackUInt32(data, offset: offset); offset += 4
            let bytesPerRow = unpackUInt32(data, offset: offset); offset += 4
            let pixelFormat = unpackUInt32(data, offset: offset); offset += 4
            let timestamp = unpackUInt64(data, offset: offset); offset += 8
            let dataLength = unpackUInt64(data, offset: offset)

            return FrameHeader(
                width: width,
                height: height,
                bytesPerRow: bytesPerRow,
                pixelFormat: pixelFormat,
                timestamp: timestamp,
                dataLength: dataLength
            )
        }

        func encodeFrame(pixelData: Data) -> Data {
            var frame = Data(capacity: totalFrameSize)
            frame.append(headerData)
            frame.append(pixelData)
            return frame
        }
    }

    enum CommandType: UInt32 {
        case mouseMove = 1
        case mouseDown = 2
        case mouseUp = 3
        case mouseScroll = 4
        case mouseDblClick = 5

        case keyDown = 10
        case keyUp = 11
        case keyCombo = 12

        case systemCommand = 20

        case clipboardPush = 30
        case clipboardPull = 31

        case windowListRequest = 40
        case windowListResponse = 41
        case windowFocus = 42
        case windowClose = 43

        case displayInfoRequest = 50
        case displayInfoResponse = 51

        case ping = 100
        case pong = 101
    }

    struct MessageHeader {
        let commandType: CommandType
        let payloadLength: UInt64

        static let magicBytes: [UInt8] = [0x4A, 0x52, 0x43, 0x4D]
        static let headerSize = 16

        func encode() -> Data {
            var data = Data(capacity: MessageHeader.headerSize)
            data.append(contentsOf: MessageHeader.magicBytes)
            data.append(packUInt32(commandType.rawValue))
            data.append(packUInt64(payloadLength))
            return data
        }

        static func decode(from data: Data) -> MessageHeader? {
            guard data.count >= headerSize else { return nil }
            guard data[0] == magicBytes[0],
                  data[1] == magicBytes[1],
                  data[2] == magicBytes[2],
                  data[3] == magicBytes[3] else { return nil }

            let rawType = unpackUInt32(data, offset: 4)
            let payloadLength = unpackUInt64(data, offset: 8)

            guard let commandType = CommandType(rawValue: rawType) else { return nil }

            return MessageHeader(commandType: commandType, payloadLength: payloadLength)
        }
    }

    struct MousePoint: Codable {
        let x: Float
        let y: Float
    }

    struct MouseButtonEvent: Codable {
        let button: Int
        let point: MousePoint
    }

    struct MouseScrollEvent: Codable {
        let deltaY: Float
        let deltaX: Float
        let point: MousePoint
    }

    struct KeyEvent: Codable {
        let keyCode: UInt16
        let flags: UInt64
    }

    struct KeyComboEvent: Codable {
        let keyCodes: [UInt16]
        let flags: UInt64
    }

    enum SystemCommandType: String, Codable {
        case sleep
        case restart
        case shutdown
        case lockScreen
        case volumeUp
        case volumeDown
        case mute
        case brightnessUp
        case brightnessDown
        case launchpad
        case missionControl
        case wake
    }

    struct SystemCommandEvent: Codable {
        let commandType: String
        let value: Float?
    }

    struct ClipboardData: Codable {
        let text: String
    }

    struct RemoteWindowInfo: Codable {
        let id: UInt32
        let title: String
        let appName: String
        let isOnScreen: Bool
    }

    struct RemoteDisplayInfo: Codable {
        let id: UInt32
        let width: UInt16
        let height: UInt16
        let refreshRate: UInt16
    }

    enum ProtocolConstants {
        static let defaultPort: UInt16 = 9527
        static let frameChannelPrefix = "JR_FRAME"
        static let commandChannelPrefix = "JR_CMD"
        static let maxFrameSize = 256 * 1024 * 1024
        static let compressionFlag: UInt32 = 0x80000000
    }

    static func encodeCommand(type: CommandType, payload: some Encodable) -> Data? {
        guard let payloadData = try? JSONEncoder().encode(payload) else { return nil }

        let header = MessageHeader(commandType: type, payloadLength: UInt64(payloadData.count))
        var command = Data(capacity: MessageHeader.headerSize + payloadData.count)
        command.append(header.encode())
        command.append(payloadData)
        return command
    }

    static func decodeCommandPayload<T: Decodable>(_ type: T.Type, from payload: Data) -> T? {
        try? JSONDecoder().decode(type, from: payload)
    }
}

private func packUInt32(_ value: UInt32) -> Data {
    var v = value.littleEndian
    return Data(bytes: &v, count: 4)
}

private func packUInt64(_ value: UInt64) -> Data {
    var v = value.littleEndian
    return Data(bytes: &v, count: 8)
}

private func unpackUInt32(_ data: Data, offset: Int) -> UInt32 {
    var value: UInt32 = 0
    _ = withUnsafeMutableBytes(of: &value) { ptr in
        data.copyBytes(to: ptr, from: offset ..< offset + 4)
    }
    return UInt32(littleEndian: value)
}

private func unpackUInt64(_ data: Data, offset: Int) -> UInt64 {
    var value: UInt64 = 0
    _ = withUnsafeMutableBytes(of: &value) { ptr in
        data.copyBytes(to: ptr, from: offset ..< offset + 8)
    }
    return UInt64(littleEndian: value)
}
