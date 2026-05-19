import Foundation

struct CPUStats {
    let usage: Double
    let temperature: Double?
    let timestamp: Date
}

struct CPUHistoryEntry: Identifiable {
    let id = UUID()
    let usage: Double
    let timestamp: Date
}
