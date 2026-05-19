import Foundation

struct DiskStats {
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

    var freeFormatted: String {
        ByteFormatter.format(bytes: total - used)
    }
}
