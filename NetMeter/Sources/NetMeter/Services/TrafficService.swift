import Foundation
import Darwin

struct TrafficSnapshot {
    let uploadSpeed: Double
    let downloadSpeed: Double
    let timestamp: Date
}

@MainActor
class TrafficService {
    private var lastBaseline: [(name: String, bytesIn: UInt64, bytesOut: UInt64)] = []
    private var lastTimestamp: Date?
    private var timer: Timer?
    private var sessionUploadTotal: UInt64 = 0
    private var sessionDownloadTotal: UInt64 = 0

    @Published var uploadSpeed: Double = 0
    @Published var downloadSpeed: Double = 0
    @Published var sessionUpload: UInt64 = 0
    @Published var sessionDownload: UInt64 = 0

    private let historyCapacity = 60
    @Published var speedHistory: [TrafficSnapshot] = []

    private let dailyCapacity = 7
    @Published var dailyTotals: [(date: Date, upload: UInt64, download: UInt64)] = []
    private var currentDayUpload: UInt64 = 0
    private var currentDayDownload: UInt64 = 0
    private var currentDayDate: Date = Calendar.current.startOfDay(for: Date())

    func startMonitoring(interval: TimeInterval = 1.0) {
        Task {
            lastBaseline = await Self.readInterfaceBytes()
            lastTimestamp = Date()
        }

        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { [weak self] in
                await self?.updateTraffic()
            }
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func updateTraffic() async {
        let current = await Self.readInterfaceBytes()
        guard !current.isEmpty else { return }
        let now = Date()

        var totalIn: UInt64 = 0
        var totalOut: UInt64 = 0

        for entry in current {
            if let baseline = lastBaseline.first(where: { $0.name == entry.name }) {
                let deltaIn = entry.bytesIn >= baseline.bytesIn
                    ? entry.bytesIn - baseline.bytesIn : entry.bytesIn
                let deltaOut = entry.bytesOut >= baseline.bytesOut
                    ? entry.bytesOut - baseline.bytesOut : entry.bytesOut
                totalIn += deltaIn
                totalOut += deltaOut
            }
        }

        lastBaseline = current

        if let last = lastTimestamp {
            let elapsed = now.timeIntervalSince(last)
            if elapsed > 0 {
                uploadSpeed = Double(totalOut) / elapsed
                downloadSpeed = Double(totalIn) / elapsed
            }
        }
        lastTimestamp = now

        sessionUploadTotal += totalOut
        sessionDownloadTotal += totalIn
        sessionUpload = sessionUploadTotal
        sessionDownload = sessionDownloadTotal

        currentDayUpload += totalOut
        currentDayDownload += totalIn

        speedHistory.append(TrafficSnapshot(
            uploadSpeed: uploadSpeed, downloadSpeed: downloadSpeed, timestamp: now
        ))
        if speedHistory.count > historyCapacity {
            speedHistory.removeFirst()
        }

        checkDayRollover()
    }

    private func checkDayRollover() {
        let today = Calendar.current.startOfDay(for: Date())
        if today != currentDayDate {
            if currentDayUpload > 0 || currentDayDownload > 0 {
                dailyTotals.append((currentDayDate, currentDayUpload, currentDayDownload))
                if dailyTotals.count > dailyCapacity {
                    dailyTotals.removeFirst()
                }
            }
            currentDayUpload = 0
            currentDayDownload = 0
            currentDayDate = today
        }
    }

    private static func readInterfaceBytes() async -> [(name: String, bytesIn: UInt64, bytesOut: UInt64)] {
        await Task.detached(priority: .utility) {
            getInterfaceTraffic()
        }.value
    }
}

private func getInterfaceTraffic() -> [(String, UInt64, UInt64)] {
    var ifaddr: UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return [] }
    defer { freeifaddrs(ifaddr) }

    var result: [(String, UInt64, UInt64)] = []
    var seen = Set<String>()

    var ptr = first
    while true {
        let interface = ptr.pointee
        let name = String(cString: interface.ifa_name)

        if name.hasPrefix("lo") {
            // skip loopback
        } else if interface.ifa_addr?.pointee.sa_family == AF_LINK,
                  let data = interface.ifa_data {
            let dataPtr = data.assumingMemoryBound(to: if_data.self)
            let bytesIn = dataPtr.pointee.ifi_ibytes
            let bytesOut = dataPtr.pointee.ifi_obytes

            if !seen.contains(name) {
                seen.insert(name)
                result.append((name, bytesIn, bytesOut))
            }
        }

        guard let next = interface.ifa_next else { break }
        ptr = next
    }

    return result
}
