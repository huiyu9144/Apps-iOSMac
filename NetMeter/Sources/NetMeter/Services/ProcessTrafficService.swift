import Foundation
import Darwin

struct ProcessTrafficInfo: Identifiable {
    let id: String
    let name: String
    let pid: Int
    let downloadSpeed: Double
    let uploadSpeed: Double

    var hasTraffic: Bool { uploadSpeed > 0 || downloadSpeed > 0 }
}

@MainActor
class ProcessTrafficService {
    private var timer: Timer?
    @Published var processes: [ProcessTrafficInfo] = []

    private var previousBytes: [pid_t: (inBytes: UInt64, outBytes: UInt64)] = [:]
    private var lastUpdateTime: Date?

    func startMonitoring(interval: TimeInterval = 3.0) {
        Task { await update() }
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { [weak self] in
                await self?.update()
            }
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        previousBytes = [:]
        lastUpdateTime = nil
    }

    private func update() async {
        let snapshot = await Self.scanAllProcesses()
        guard !snapshot.isEmpty else { return }
        let now = Date()

        var result: [ProcessTrafficInfo] = []

        for entry in snapshot {
            let prev = previousBytes[entry.pid]

            let deltaIn: UInt64
            let deltaOut: UInt64
            if let prev = prev {
                deltaIn = entry.bytesIn >= prev.inBytes ? entry.bytesIn - prev.inBytes : 0
                deltaOut = entry.bytesOut >= prev.outBytes ? entry.bytesOut - prev.outBytes : 0
            } else {
                deltaIn = 0
                deltaOut = 0
            }

            previousBytes[entry.pid] = (entry.bytesIn, entry.bytesOut)

            let elapsed = lastUpdateTime.map { now.timeIntervalSince($0) } ?? 3.0
            let dSpeed = elapsed > 0 ? Double(deltaIn) / elapsed : 0
            let uSpeed = elapsed > 0 ? Double(deltaOut) / elapsed : 0

            if dSpeed > 0 || uSpeed > 0 {
                result.append(ProcessTrafficInfo(
                    id: "\(entry.pid)_\(entry.name)",
                    name: entry.name,
                    pid: Int(entry.pid),
                    downloadSpeed: dSpeed,
                    uploadSpeed: uSpeed
                ))
            }
        }

        lastUpdateTime = now
        result.sort { ($0.downloadSpeed + $0.uploadSpeed) > ($1.downloadSpeed + $1.uploadSpeed) }
        processes = result
    }

    private static func scanAllProcesses() async -> [(pid: pid_t, name: String, bytesIn: UInt64, bytesOut: UInt64)] {
        await Task.detached(priority: .utility) {
            let capacity = 4096
            let pidList = UnsafeMutablePointer<pid_t>.allocate(capacity: capacity)
            defer { pidList.deallocate() }

            let count = proc_listallpids(pidList, Int32(MemoryLayout<pid_t>.stride * capacity))
            guard count > 0 else { return [] }

            let pidBuf = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(PROC_PIDPATHINFO_MAXSIZE))
            defer { pidBuf.deallocate() }

            var nameCache: [pid_t: String] = [:]
            var result: [(pid_t, String, UInt64, UInt64)] = []

            for i in 0..<Int(count) {
                let pid = pidList[i]
                guard pid > 0 else { continue }

                let traffic = readProcNetworkBytes(pid)
                guard traffic.0 > 0 || traffic.1 > 0 else { continue }

                let name: String
                if let cached = nameCache[pid] {
                    name = cached
                } else {
                    let pathSize = proc_pidpath(pid, pidBuf, UInt32(PROC_PIDPATHINFO_MAXSIZE))
                    if pathSize > 0 {
                        let path = String(cString: pidBuf)
                        name = URL(fileURLWithPath: path).lastPathComponent
                        nameCache[pid] = name
                    } else {
                        continue
                    }
                }

                result.append((pid, name, traffic.0, traffic.1))
            }

            return result
        }.value
    }
}

private func readProcNetworkBytes(_ pid: pid_t) -> (UInt64, UInt64) {
    var info = proc_taskinfo()
    let size = proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &info, Int32(MemoryLayout<proc_taskinfo>.stride))
    guard size == MemoryLayout<proc_taskinfo>.stride else { return (0, 0) }
    return (info.pti_total_bytes_in, info.pti_total_bytes_out)
}
