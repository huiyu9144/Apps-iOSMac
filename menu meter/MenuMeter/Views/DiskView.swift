import SwiftUI

struct DiskView: View {
    @EnvironmentObject var monitorService: SystemMonitorService
    @State private var showDetails = false

    var body: some View {
        SectionBox {
            SecLabel(icon: "internaldrive", text: "Disk")

            HStack(spacing: 8) {
                ThinBar(value: monitorService.diskStats.usagePercentage / 100,
                        color: Color.usageColor(monitorService.diskStats.usagePercentage))

                Mono(text: PercentageFormatter.format(monitorService.diskStats.usagePercentage),
                     color: Color.usageColor(monitorService.diskStats.usagePercentage))
            }

            CollapsibleDetails(label: "Details", expanded: $showDetails) {
                HStack(spacing: 16) {
                    Text(monitorService.diskStats.usedFormatted)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondaryLabel)
                    Text(monitorService.diskStats.totalFormatted)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.tertiaryLabel)
                }
            }
        }
    }
}
