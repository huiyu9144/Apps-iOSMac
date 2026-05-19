import Foundation
import MachO

final class MemoryService {
    func readMemoryStats() -> (used: UInt64, total: UInt64) {
        var size = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        var vmStats = vm_statistics64()

        let result = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64,
                                 $0, &size)
            }
        }

        guard result == KERN_SUCCESS else { return (0, 0) }

        let pageSize = UInt64(vm_kernel_page_size)
        let used = UInt64(vmStats.active_count + vmStats.wire_count + vmStats.inactive_count) * pageSize
        let total = ProcessInfo.processInfo.physicalMemory

        return (used, total)
    }

    func readTopProcesses(limit: Int = 5) -> [MemoryTopProcess] {
        var processes: [MemoryTopProcess] = []
        var name: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_ALL]
        var length = 0

        sysctl(&name, UInt32(name.count), nil, &length, nil, 0)
        guard length > 0 else { return [] }

        var procData = UnsafeMutablePointer<kinfo_proc>.allocate(capacity: length / MemoryLayout<kinfo_proc>.stride)
        defer { procData.deallocate() }

        var count = length
        let result = sysctl(&name, UInt32(name.count), procData, &count, nil, 0)
        guard result == 0 else { return [] }

        let procCount = count / MemoryLayout<kinfo_proc>.stride

        var processInfos: [(name: String, memory: UInt64)] = []

        for i in 0..<procCount {
            let proc = procData[i]
            let pid = proc.kp_proc.p_pid
            if pid == 0 { continue }

            var taskName = proc.kp_proc.p_comm
            let appName = withUnsafePointer(to: &taskName.0) { ptr -> String in
                let raw = UnsafeRawPointer(ptr)
                var bytes: [UInt8] = []
                for i in 0..<16 {
                    let byte = raw.load(fromByteOffset: i, as: UInt8.self)
                    if byte == 0 { break }
                    bytes.append(byte)
                }
                return String(decoding: bytes, as: UTF8.self)
            }

            var taskInfo = task_vm_info()
            var taskSize = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size / MemoryLayout<natural_t>.size)
            var taskPort: task_t = 0
            let taskResult = task_for_pid(mach_task_self_, pid, &taskPort)
            guard taskResult == KERN_SUCCESS else { continue }

            defer { mach_port_deallocate(mach_task_self_, taskPort) }

            let infoResult = withUnsafeMutablePointer(to: &taskInfo) {
                $0.withMemoryRebound(to: integer_t.self, capacity: Int(taskSize)) {
                    task_info(taskPort, task_flavor_t(TASK_VM_INFO),
                             $0, &taskSize)
                }
            }

            if infoResult == KERN_SUCCESS {
                let memory = UInt64(taskInfo.phys_footprint)
                processInfos.append((appName, memory))
            }
        }

        processInfos.sort { $0.memory > $1.memory }
        let topProcesses = processInfos.prefix(limit)

        for p in topProcesses {
            processes.append(MemoryTopProcess(name: p.name, memoryUsage: p.memory))
        }

        return processes
    }
}
