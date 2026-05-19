import Foundation

struct SystemStats {
    let cpu: CPUStats
    let memory: MemoryStats
    let network: NetworkStats
    let disk: DiskStats
    let battery: BatteryStats?
    let timestamp: Date
}
