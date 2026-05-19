import Foundation
import MachO

final class CPUService {
    private var previousLoadInfo: host_cpu_load_info?
    private let maxHistoryCount = 180

    private(set) var history: [CPUHistoryEntry] = []

    func readCPUUsage() -> Double {
        var size = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)
        var cpuLoadInfo = host_cpu_load_info()

        let result = withUnsafeMutablePointer(to: &cpuLoadInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO,
                               $0, &size)
            }
        }

        guard result == KERN_SUCCESS else { return 0 }

        let user = Double(cpuLoadInfo.cpu_ticks.0)
        let system = Double(cpuLoadInfo.cpu_ticks.1)
        let idle = Double(cpuLoadInfo.cpu_ticks.2)
        let nice = Double(cpuLoadInfo.cpu_ticks.3)

        let total = user + system + idle + nice

        if let previous = previousLoadInfo {
            let prevUser = Double(previous.cpu_ticks.0)
            let prevSystem = Double(previous.cpu_ticks.1)
            let prevIdle = Double(previous.cpu_ticks.2)
            let prevNice = Double(previous.cpu_ticks.3)
            let prevTotal = prevUser + prevSystem + prevIdle + prevNice

            let totalDelta = total - prevTotal
            let idleDelta = idle - prevIdle

            if totalDelta > 0 {
                let usage = (totalDelta - idleDelta) / totalDelta * 100
                previousLoadInfo = cpuLoadInfo
                return min(max(usage, 0), 100)
            }
        }

        previousLoadInfo = cpuLoadInfo
        return 0
    }

    func recordHistory(usage: Double) {
        let entry = CPUHistoryEntry(usage: usage, timestamp: Date())
        history.append(entry)
        if history.count > maxHistoryCount {
            history = Array(history.suffix(maxHistoryCount))
        }
    }

    func clearHistory() {
        history.removeAll()
    }
}
