import SwiftUI

struct ContentView: View {
    @EnvironmentObject var monitorService: SystemMonitorService
    @State private var refreshing = false

    @AppStorage(SettingsKeys.showCPU) private var showCPU = true
    @AppStorage(SettingsKeys.showMemory) private var showMemory = true
    @AppStorage(SettingsKeys.showNetwork) private var showNetwork = true
    @AppStorage(SettingsKeys.showDisk) private var showDisk = true
    @AppStorage(SettingsKeys.showBattery) private var showBattery = true

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    if showCPU { CPUView() }
                    if showMemory { MemoryView() }
                    if showNetwork { NetworkView() }
                    if showDisk { DiskView() }
                    if showBattery, let b = monitorService.batteryStats {
                        BatteryView(battery: b)
                    }
                }
            }

            bottomBar
        }
        .frame(width: 340)
        .background(Color.windowBackground)
    }

    private var bottomBar: some View {
        HStack(spacing: 0) {
            Button(action: { (NSApp.delegate as? AppDelegate)?.openSettings() }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondaryLabel)
                    .frame(width: 32, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Settings")

            Spacer()

            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) { refreshing = true }
                monitorService.refreshNow()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeInOut(duration: 0.3)) { refreshing = false }
                }
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondaryLabel)
                    .rotationEffect(.degrees(refreshing ? 360 : 0))
                    .frame(width: 32, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Refresh")

            Spacer()

            Button(action: { (NSApp.delegate as? AppDelegate)?.quitApp() }) {
                Image(systemName: "power")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondaryLabel)
                    .frame(width: 32, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Quit")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

// MARK: - Battery
struct BatteryView: View {
    let battery: BatteryStats
    @State private var showDetails = false

    var body: some View {
        SectionBox {
            HStack(spacing: 6) {
                SecLabel(icon: "battery.100", text: "Battery")
                if battery.isCharging {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.accent)
                }
                Spacer()
            }

            HStack(spacing: 8) {
                ThinBar(value: battery.level, color: Color.batteryColor(battery.level))
                Mono(text: battery.levelFormatted, color: Color.batteryColor(battery.level))
                    .frame(width: 48, alignment: .trailing)
            }

            CollapsibleDetails(label: "Details", expanded: $showDetails) {
                HStack(spacing: 16) {
                    if let h = battery.health {
                        Text("\(h)%")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(h < 80 ? .orange : .label)
                    }
                    if let c = battery.cycleCount {
                        Text("\(c) cycles")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.label)
                    }
                }
            }
        }
    }
}
