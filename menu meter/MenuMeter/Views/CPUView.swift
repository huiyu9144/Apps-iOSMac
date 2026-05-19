import SwiftUI

struct CPUView: View {
    @EnvironmentObject var monitorService: SystemMonitorService
    @AppStorage(SettingsKeys.temperatureUnit) private var tempUnit: String = TemperatureUnit.celsius.rawValue
    @State private var showChart = false

    private var unit: TemperatureUnit {
        TemperatureUnit(rawValue: tempUnit) ?? .celsius
    }

    var body: some View {
        SectionBox {
            HStack(spacing: 6) {
                SecLabel(icon: "cpu", text: "CPU")
                Spacer()
                if let t = monitorService.cpuStats.temperature {
                    Text(TemperatureFormatter.format(celsius: t, unit: unit))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondaryLabel)
                }
            }

            HStack(spacing: 8) {
                ThinBar(value: monitorService.cpuStats.usage / 100,
                        color: Color.usageColor(monitorService.cpuStats.usage))

                Mono(text: PercentageFormatter.format(monitorService.cpuStats.usage),
                     color: Color.usageColor(monitorService.cpuStats.usage))
                .frame(width: 48, alignment: .trailing)
            }

            if !monitorService.cpuHistory.isEmpty {
                CollapsibleDetails(label: "Trend", expanded: $showChart) {
                    TrendChartView(
                        entries: monitorService.cpuHistory,
                        color: Color.accent
                    )
                    .frame(height: 40)
                }
            }
        }
    }
}
