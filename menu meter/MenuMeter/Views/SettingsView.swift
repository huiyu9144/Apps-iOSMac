import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @EnvironmentObject var monitorService: SystemMonitorService

    @AppStorage(SettingsKeys.showCPU) private var showCPU = true
    @AppStorage(SettingsKeys.showMemory) private var showMemory = true
    @AppStorage(SettingsKeys.showNetwork) private var showNetwork = true
    @AppStorage(SettingsKeys.showDisk) private var showDisk = true
    @AppStorage(SettingsKeys.showBattery) private var showBattery = true
    @AppStorage(SettingsKeys.refreshInterval) private var refreshInterval: Double = 2.0
    @AppStorage(SettingsKeys.menuBarDisplay) private var menuBarDisplay: String = MenuBarDisplay.cpu.rawValue
    @AppStorage(SettingsKeys.temperatureUnit) private var temperatureUnit: String = TemperatureUnit.celsius.rawValue
    @AppStorage(SettingsKeys.launchAtLogin) private var launchAtLogin = false

    var body: some View {
        TabView {
            Form {
                Section {
                    Picker("Menu Bar", selection: $menuBarDisplay) {
                        ForEach(MenuBarDisplay.allCases, id: \.rawValue) { o in
                            Text(optionName(o)).tag(o.rawValue)
                        }
                    }
                    Picker("Temperature", selection: $temperatureUnit) {
                        Text("°C").tag(TemperatureUnit.celsius.rawValue)
                        Text("°F").tag(TemperatureUnit.fahrenheit.rawValue)
                    }
                    Picker("Refresh", selection: $refreshInterval) {
                        Text("1s").tag(1.0); Text("2s").tag(2.0)
                        Text("5s").tag(5.0); Text("10s").tag(10.0)
                    }
                    .onChange(of: refreshInterval) { _, v in monitorService.updateInterval(v) }
                    Toggle("Launch at Login", isOn: $launchAtLogin)
                        .toggleStyle(.switch)
                        .onChange(of: launchAtLogin) { _, v in toggleLaunch(v) }
                }
            }
            .padding()
            .tabItem { Image(systemName: "gearshape"); Text("General") }

            Form {
                Section {
                    Toggle("CPU", isOn: $showCPU).toggleStyle(.switch)
                    Toggle("Memory", isOn: $showMemory).toggleStyle(.switch)
                    Toggle("Network", isOn: $showNetwork).toggleStyle(.switch)
                    Toggle("Disk", isOn: $showDisk).toggleStyle(.switch)
                    Toggle("Battery", isOn: $showBattery).toggleStyle(.switch)
                }
                Text("Changes apply immediately")
                    .font(.system(size: 10))
                    .foregroundColor(.tertiaryLabel)
            }
            .padding()
            .tabItem { Image(systemName: "switch.2"); Text("Modules") }
        }
        .frame(width: 360, height: 280)
    }

    private func optionName(_ o: MenuBarDisplay) -> String {
        switch o { case .cpu: return "CPU Usage"; case .temperature: return "Temperature"; case .memory: return "Memory"; case .network: return "Network Speed" }
    }

    private func toggleLaunch(_ v: Bool) {
        do { if v { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() } }
        catch { print("Launch toggle: \(error)") }
    }
}
