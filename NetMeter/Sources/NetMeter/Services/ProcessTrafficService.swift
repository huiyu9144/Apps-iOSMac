import Foundation

struct ProcessTrafficInfo: Identifiable {
    let id: String
    let name: String
    let pid: Int
    let downloadSpeed: Double
    let uploadSpeed: Double
    let totalBytesIn: UInt64
    let totalBytesOut: UInt64

    var hasTraffic: Bool { uploadSpeed > 0 || downloadSpeed > 0 }
}

@MainActor
class ProcessTrafficService {
    @Published var processes: [ProcessTrafficInfo] = []
    @Published var isRefreshing = false

    private var previousBytes: [pid_t: (inBytes: UInt64, outBytes: UInt64)] = [:]
    private var lastUpdateTime: Date?

    func refresh() {
        guard !isRefreshing else { return }
        Task { await update() }
    }

    func stopMonitoring() {
        previousBytes = [:]
        lastUpdateTime = nil
    }

    private func update() async {
        isRefreshing = true

        var rawEntries: [(pid_t, String, UInt64, UInt64)]?

        let helperResult = await HelperManager.shared.requestRefresh()
        if let entries = helperResult, !entries.isEmpty {
            rawEntries = entries.map { ($0.pid, $0.name, $0.bytesIn, $0.bytesOut) }
        } else {
            rawEntries = await Task.detached(priority: .utility) {
                runNettopSnapshot()
            }.value
        }

        guard let snapshot = rawEntries, !snapshot.isEmpty else {
            isRefreshing = false
            return
        }

        let now = Date()

        var result: [ProcessTrafficInfo] = []

        for entry in snapshot {
            let prev = previousBytes[entry.0]

            let deltaIn: UInt64
            let deltaOut: UInt64
            if let prev = prev {
                deltaIn = entry.2 >= prev.inBytes ? entry.2 - prev.inBytes : 0
                deltaOut = entry.3 >= prev.outBytes ? entry.3 - prev.outBytes : 0
            } else {
                deltaIn = 0
                deltaOut = 0
            }

            previousBytes[entry.0] = (entry.2, entry.3)

            let elapsed = lastUpdateTime.map { now.timeIntervalSince($0) } ?? 3.0
            let dSpeed = elapsed > 0 ? Double(deltaIn) / elapsed : 0
            let uSpeed = elapsed > 0 ? Double(deltaOut) / elapsed : 0

            if dSpeed > 0 || uSpeed > 0 {
                result.append(ProcessTrafficInfo(
                    id: "\(entry.0)_\(entry.1)",
                    name: entry.1,
                    pid: Int(entry.0),
                    downloadSpeed: dSpeed,
                    uploadSpeed: uSpeed,
                    totalBytesIn: entry.2,
                    totalBytesOut: entry.3
                ))
            }
        }

        lastUpdateTime = now
        result.sort { ($0.downloadSpeed + $0.uploadSpeed) > ($1.downloadSpeed + $1.uploadSpeed) }
        processes = result
        isRefreshing = false
    }
}

private func runNettopSnapshot() -> [(pid_t, String, UInt64, UInt64)] {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/script")
    task.arguments = ["-q", "/dev/null", "/usr/bin/nettop", "-P", "-x", "-n", "-s", "1", "-l", "1", "-L", "1"]

    let outPipe = Pipe()
    task.standardOutput = outPipe
    task.standardError = Pipe()
    task.standardInput = FileHandle.nullDevice

    do {
        try task.run()
        task.waitUntilExit()
    } catch {
        return []
    }

    let data = outPipe.fileHandleForReading.readDataToEndOfFile()
    guard let text = String(data: data, encoding: .utf8) else { return [] }

    var result: [pid_t: (String, UInt64, UInt64)] = [:]
    let lines = text.components(separatedBy: .newlines)

    for line in lines {
        let cleaned = line.replacingOccurrences(of: "\u{0004}", with: "")
                             .replacingOccurrences(of: "\u{0008}", with: "")
        guard cleaned.contains(",") else { continue }

        let cols = cleaned.components(separatedBy: ",")
        guard cols.count >= 6 else { continue }
        if cols[1].hasPrefix("time") || cols[1] == "interface" { continue }

        let namePid = cols[1].trimmingCharacters(in: .whitespaces)
        guard !namePid.isEmpty, namePid.contains(".") else { continue }

        let bytesInStr = cols[4].trimmingCharacters(in: .whitespaces)
        let bytesOutStr = cols[5].trimmingCharacters(in: .whitespaces)
        guard let bytesIn = UInt64(bytesInStr), let bytesOut = UInt64(bytesOutStr) else { continue }

        guard let dotIndex = namePid.lastIndex(of: ".") else { continue }
        let pidStr = namePid[namePid.index(after: dotIndex)...]
        let procName = String(namePid[..<dotIndex]).trimmingCharacters(in: .whitespaces)
        guard let pid = pid_t(pidStr), pid > 0 else { continue }
        guard result[pid] == nil else { continue }

        result[pid] = (procName, bytesIn, bytesOut)
    }

    return result.map { ($0.key, $0.value.0, $0.value.1, $0.value.2) }
}
