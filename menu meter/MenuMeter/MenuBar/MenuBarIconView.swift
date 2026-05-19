import SwiftUI

struct MenuBarIconView: View {
    @EnvironmentObject var monitorService: SystemMonitorService
    @AppStorage(SettingsKeys.menuBarDisplay) private var display: String = MenuBarDisplay.cpu.rawValue

    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(Color.accent).frame(width: 5, height: 5)

            switch MenuBarDisplay(rawValue: display) ?? .cpu {
            case .cpu:
                Mono(text: PercentageFormatter.format(monitorService.cpuStats.usage),
                     color: Color.usageColor(monitorService.cpuStats.usage),
                     size: 11)
            case .temperature:
                if let t = monitorService.cpuStats.temperature {
                    Mono(text: TemperatureFormatter.format(celsius: t, unit: .celsius), size: 10)
                }
            case .memory:
                Mono(text: monitorService.memoryStats.usedFormatted, size: 10)
            case .network:
                HStack(spacing: 1) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 6, weight: .heavy))
                        .foregroundColor(.accent)
                    Mono(text: ByteFormatter.formatSpeed(bytesPerSecond: monitorService.networkStats.downloadSpeed), size: 9)
                }
            }
        }
        .padding(.horizontal, 4)
    }
}

enum MenuBarDisplay: String, CaseIterable {
    case cpu, temperature, memory, network
}

struct SettingsKeys {
    static let menuBarDisplay = "menuBarDisplay"
    static let refreshInterval = "refreshInterval"
    static let showCPU = "showCPU"
    static let showMemory = "showMemory"
    static let showNetwork = "showNetwork"
    static let showDisk = "showDisk"
    static let showBattery = "showBattery"
    static let temperatureUnit = "temperatureUnit"
    static let launchAtLogin = "launchAtLogin"
}
