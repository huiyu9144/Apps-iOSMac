import SwiftUI

struct MemoryView: View {
    @EnvironmentObject var monitorService: SystemMonitorService
    @State private var showProcesses = false
    @State private var showChart = false

    var body: some View {
        SectionBox {
            SecLabel(icon: "memorychip", text: "Memory")

            HStack(spacing: 8) {
                ThinBar(value: monitorService.memoryStats.usagePercentage / 100,
                        color: Color.usageColor(monitorService.memoryStats.usagePercentage))

                Mono(text: PercentageFormatter.format(monitorService.memoryStats.usagePercentage),
                     color: Color.usageColor(monitorService.memoryStats.usagePercentage))
            }

            if !monitorService.topProcesses.isEmpty {
                CollapsibleDetails(label: "Top Processes", expanded: $showProcesses) {
                    VStack(spacing: 2) {
                        ForEach(monitorService.topProcesses.prefix(5)) { process in
                            HStack(spacing: 0) {
                                Text(process.name)
                                    .font(.system(size: 11))
                                    .foregroundColor(.label)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                Spacer(minLength: 6)
                                Text(process.memoryFormatted)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.tertiaryLabel)
                            }
                            .padding(.vertical, 1)
                        }
                    }
                }
            }

            if !monitorService.memoryHistory.isEmpty {
                CollapsibleDetails(label: "Trend", expanded: $showChart) {
                    TrendChartView(entries: monitorService.memoryHistory, color: Color.accent)
                        .frame(height: 40)
                }
            }
        }
    }
}
