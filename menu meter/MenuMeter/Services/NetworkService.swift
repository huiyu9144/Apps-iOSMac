import Foundation

final class NetworkService {
    private var previousBytes: (rx: UInt64, tx: UInt64)?
    private var totalDownloadToday: UInt64 = 0
    private var totalUploadToday: UInt64 = 0
    private var lastResetDate: Date = Calendar.current.startOfDay(for: Date())

    func readNetworkStats() -> (downloadSpeed: Double, uploadSpeed: Double) {
        var interfaceAddresses: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&interfaceAddresses) == 0, let start = interfaceAddresses else {
            return (0, 0)
        }
        defer { freeifaddrs(interfaceAddresses) }

        var totalRx: UInt64 = 0
        var totalTx: UInt64 = 0

        var cursor = start
        while true {
            let interface = cursor.pointee
            let name = String(cString: interface.ifa_name)

            if name.hasPrefix("en") || name == "en0" {
                if let data = interface.ifa_data?.assumingMemoryBound(to: if_data.self).pointee {
                    totalRx += UInt64(data.ifi_ibytes)
                    totalTx += UInt64(data.ifi_obytes)
                }
            }

            guard let next = interface.ifa_next else { break }
            cursor = next
        }

        let now = Date()
        if !Calendar.current.isDate(now, inSameDayAs: lastResetDate) {
            totalDownloadToday = 0
            totalUploadToday = 0
            lastResetDate = Calendar.current.startOfDay(for: now)
        }

        var downloadSpeed: Double = 0
        var uploadSpeed: Double = 0

        if let prev = previousBytes {
            if totalRx >= prev.rx {
                downloadSpeed = Double(totalRx - prev.rx)
                totalDownloadToday += totalRx - prev.rx
            }
            if totalTx >= prev.tx {
                uploadSpeed = Double(totalTx - prev.tx)
                totalUploadToday += totalTx - prev.tx
            }
        }

        previousBytes = (totalRx, totalTx)
        return (downloadSpeed, uploadSpeed)
    }

    func getTodayTraffic() -> (download: UInt64, upload: UInt64) {
        (totalDownloadToday, totalUploadToday)
    }

    func reset() {
        previousBytes = nil
        totalDownloadToday = 0
        totalUploadToday = 0
    }
}
