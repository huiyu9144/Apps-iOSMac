import Foundation
import IOKit.ps

final class BatteryService {
    func readBatteryStats() -> BatteryStats? {
        let blob = IOPSCopyPowerSourcesInfo()
        guard let blobRef = blob?.takeRetainedValue() else { return nil }

        let sources = IOPSCopyPowerSourcesList(blobRef)
        guard let sourcesList = sources?.takeRetainedValue() as? [Any] else { return nil }

        guard sourcesList.count > 0 else { return nil }

        if let firstSource = sourcesList.first as? [String: Any] {
            let level = firstSource[kIOPSCurrentCapacityKey as String] as? Double ?? 0
            let maxLevel = firstSource[kIOPSMaxCapacityKey as String] as? Double ?? 100
            let isCharging = firstSource[kIOPSIsChargingKey as String] as? Bool ?? false
            let cycleCount = firstSource["Cycle Count" as String] as? Int
            let health = firstSource["Max Capacity" as String] as? Int

            return BatteryStats(
                level: maxLevel > 0 ? level / maxLevel : 0,
                isCharging: isCharging,
                cycleCount: cycleCount,
                health: health,
                timestamp: Date()
            )
        }

        return nil
    }

    func hasBattery() -> Bool {
        let blob = IOPSCopyPowerSourcesInfo()
        guard let blobRef = blob?.takeRetainedValue() else { return false }
        let sources = IOPSCopyPowerSourcesList(blobRef)
        guard let sourcesList = sources?.takeRetainedValue() as? [Any] else { return false }
        return sourcesList.count > 0
    }
}
