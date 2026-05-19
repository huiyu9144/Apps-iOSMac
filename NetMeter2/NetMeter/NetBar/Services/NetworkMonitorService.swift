import Foundation
import Network
import Combine

@MainActor
class NetworkMonitorService {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.netmeter.networkmonitor", qos: .utility)

    @Published var isConnected = true
    @Published var interfaceType: String = "Wi-Fi"
    @Published var ipAddress: String = ""

    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.updatePath(path)
            }
        }
        monitor.start(queue: queue)
        updateIPAddress()
    }

    func stopMonitoring() {
        monitor.cancel()
    }

    private func updatePath(_ path: NWPath) {
        isConnected = path.status == .satisfied
        if path.usesInterfaceType(.wifi) {
            interfaceType = "Wi-Fi"
        } else if path.usesInterfaceType(.wiredEthernet) {
            interfaceType = "Ethernet"
        } else if path.usesInterfaceType(.cellular) {
            interfaceType = "Cellular"
        } else {
            interfaceType = "Unknown"
        }
        if isConnected {
            updateIPAddress()
        } else {
            ipAddress = ""
        }
    }

    private func updateIPAddress() {
        Task.detached(priority: .utility) {
            let ip = getLocalIPAddress()
            await MainActor.run { [weak self] in
                self?.ipAddress = ip
            }
        }
    }
}

private func getLocalIPAddress() -> String {
    var address = ""
    var ifaddr: UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return "" }
    defer { freeifaddrs(ifaddr) }

    for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
        let interface = ptr.pointee
        let addrFamily = interface.ifa_addr.pointee.sa_family
        guard addrFamily == UInt8(AF_INET) else { continue }
        let name = String(cString: interface.ifa_name)
        guard name == "en0" || name == "en1" else { continue }
        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        getnameinfo(
            interface.ifa_addr,
            socklen_t(interface.ifa_addr.pointee.sa_len),
            &hostname,
            socklen_t(hostname.count),
            nil,
            socklen_t(0),
            NI_NUMERICHOST
        )
        address = String(cString: hostname)
        if !address.isEmpty { break }
    }
    return address
}
