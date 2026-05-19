import SwiftUI

struct NetworkView: View {
    @EnvironmentObject var monitorService: SystemMonitorService
    @State private var showToday = false

    var body: some View {
        SectionBox {
            SecLabel(icon: "network", text: "Network")

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(ByteFormatter.formatSpeed(bytesPerSecond: monitorService.networkStats.downloadSpeed))
                        .font(.system(size: 15, weight: .semibold, design: .monospaced))
                        .foregroundColor(.accent)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(ByteFormatter.formatSpeed(bytesPerSecond: monitorService.networkStats.uploadSpeed))
                        .font(.system(size: 15, weight: .semibold, design: .monospaced))
                        .foregroundColor(.orange)
                }
            }
            .padding(.vertical, 2)

            CollapsibleDetails(label: "Today", expanded: $showToday) {
                HStack(spacing: 0) {
                    Text("↓ \(ByteFormatter.format(bytes: monitorService.networkStats.totalDownloadToday))")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.accent)
                    Text("  ↑ \(ByteFormatter.format(bytes: monitorService.networkStats.totalUploadToday))")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.orange)
                }
            }
        }
    }
}
