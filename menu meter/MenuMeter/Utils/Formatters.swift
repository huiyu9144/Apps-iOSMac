import Foundation

struct ByteFormatter {
    static func format(bytes: UInt64) -> String {
        let units = ["B", "KB", "MB", "GB", "TB"]
        var value = Double(bytes)
        var unitIndex = 0

        while value >= 1024 && unitIndex < units.count - 1 {
            value /= 1024
            unitIndex += 1
        }

        if unitIndex == 0 {
            return "\(Int(value)) \(units[unitIndex])"
        } else if value >= 100 {
            return String(format: "%.1f %@", value, units[unitIndex])
        } else {
            return String(format: "%.2f %@", value, units[unitIndex])
        }
    }

    static func formatSpeed(bytesPerSecond: Double) -> String {
        let absSpeed = abs(bytesPerSecond)
        if absSpeed < 1024 {
            return String(format: "%.1f B/s", absSpeed)
        } else if absSpeed < 1024 * 1024 {
            return String(format: "%.1f KB/s", absSpeed / 1024)
        } else {
            return String(format: "%.1f MB/s", absSpeed / (1024 * 1024))
        }
    }
}

struct PercentageFormatter {
    static func format(_ value: Double) -> String {
        String(format: "%.0f%%", min(max(value, 0), 100))
    }
}

struct TemperatureFormatter {
    static func format(celsius: Double?, unit: TemperatureUnit) -> String {
        guard let celsius else { return "--" }
        switch unit {
        case .celsius:
            return String(format: "%.0f°C", celsius)
        case .fahrenheit:
            let fahrenheit = celsius * 9 / 5 + 32
            return String(format: "%.0f°F", fahrenheit)
        }
    }
}

enum TemperatureUnit: String, CaseIterable {
    case celsius
    case fahrenheit
}
