import Foundation

struct BatteryStats {
    let level: Double
    let isCharging: Bool
    let cycleCount: Int?
    let health: Int?
    let timestamp: Date

    var levelFormatted: String {
        "\(Int(level * 100))%"
    }
}
