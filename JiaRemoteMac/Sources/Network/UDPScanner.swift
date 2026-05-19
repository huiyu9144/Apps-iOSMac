import Foundation
import Network

final class UDPScanner {

    private var listener: NWListener?
    private let queue = DispatchQueue(label: "com.jiaremote.udp.scanner", qos: .userInitiated)
    private var isRunning = false
    private var listeningPort: UInt16 = 0

    func start(port: UInt16) {
        guard !isRunning else { return }
        listeningPort = port

        do {
            let params = NWParameters.udp
            params.allowLocalEndpointReuse = true

            guard let nwPort = NWEndpoint.Port(rawValue: port) else {
                print("[UDPScanner] Invalid port: \(port)")
                return
            }

            listener = try NWListener(using: params, on: nwPort)

            listener?.stateUpdateHandler = { [weak self] state in
                switch state {
                case .ready:
                    self?.isRunning = true
                    print("[UDPScanner] Listening on UDP port \(self?.listeningPort ?? 0)")
                case .failed(let error):
                    print("[UDPScanner] Listener failed: \(error)")
                    self?.restart()
                case .cancelled:
                    self?.isRunning = false
                    print("[UDPScanner] Stopped")
                default:
                    break
                }
            }

            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleIncoming(connection)
            }

            listener?.start(queue: queue)
        } catch {
            print("[UDPScanner] Failed to create listener: \(error)")
        }
    }

    func stop() {
        listener?.stateUpdateHandler = nil
        listener?.newConnectionHandler = nil
        listener?.cancel()
        listener = nil
        isRunning = false
    }

    private func handleIncoming(_ connection: NWConnection) {
        connection.stateUpdateHandler = { [weak conn = connection] state in
            if state == .ready, let c = conn {
                self.receiveProbe(on: c)
            } else if case .failed(let err) = state, let c = conn {
                print("[UDPScanner] Connection error: \(err)")
                c.cancel()
            } else if state == .cancelled {
            }
        }
        connection.start(queue: queue)
    }

    private func receiveProbe(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 512) { [weak self] data, _, isComplete, error in
            defer { connection.cancel() }

            if let error {
                print("[UDPScanner] Receive error: \(error)")
                return
            }

            if isComplete { return }

            if let data, let message = String(data: data, encoding: .utf8) {
                let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed == "JR_SCAN" {
                    self?.sendResponse(on: connection)
                }
            }
        }
    }

    private func sendResponse(on connection: NWConnection) {
        let hostname = Host.current().localizedName ?? "JiaRemote"
        let localIP = getLocalIPAddress() ?? "0.0.0.0"
        let response = "JR_HOST:\(hostname)|\(localIP)"

        connection.send(content: response.data(using: .utf8), completion: .contentProcessed({ error in
            if let error {
                print("[UDPScanner] Send response error: \(error)")
            } else {
                print("[UDPScanner] Responded to JR_SCAN probe from \(connection.endpoint)")
            }
        }))
    }

    private func restart() {
        stop()
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self, !self.isRunning else { return }
            self.start(port: self.listeningPort)
        }
    }

    private func getLocalIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return nil }
        defer { freeifaddrs(ifaddr) }

        var current = firstAddr
        while true {
            let addr = current.pointee
            if addr.ifa_addr.pointee.sa_family == UInt8(AF_INET) {
                let name = String(cString: addr.ifa_name)
                if name.hasPrefix("en") || name == "en0" {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(addr.ifa_addr, socklen_t(addr.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST)
                    address = String(cString: hostname)
                    if address != "127.0.0.1" { break }
                }
            }
            guard let next = current.pointee.ifa_next else { break }
            current = next
        }
        return address
    }
}