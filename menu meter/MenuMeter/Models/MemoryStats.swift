import Foundation

struct MemoryStats {
    let used: UInt64
    let total: UInt64
    let timestamp: Date

    var usagePercentage: Double {
        total > 0 ? Double(used) / Double(total) * 100 : 0
    }

    var usedFormatted: String {
        ByteFormatter.format(bytes: used)
    }

    var totalFormatted: String {
        ByteFormatter.format(bytes: total)
    }
}

struct MemoryTopProcess: Identifiable {
    let id = UUID()
    let name: String
    let memoryUsage: UInt64

    var memoryFormatted: String {
        ByteFormatter.format(bytes: memoryUsage)
    }
}
