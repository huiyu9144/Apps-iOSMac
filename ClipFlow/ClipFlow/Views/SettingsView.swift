import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @State private var launchAtLogin = LoginItemsService.shared.isLoginItem
    @State private var historyLimit: Int = UserDefaults.standard.integer(forKey: "historyLimit") != 0
        ? UserDefaults.standard.integer(forKey: "historyLimit")
        : 200
    
    var body: some View {
        TabView {
            generalView
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
            
            shortcutsView
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }
            
            aboutView
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 420, height: 350)
        .padding()
    }
    
    private var generalView: some View {
        Form {
            Toggle("Launch at login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, newValue in
                    if newValue {
                        LoginItemsService.shared.addLoginItem()
                    } else {
                        LoginItemsService.shared.removeLoginItem()
                    }
                    UserDefaults.standard.set(newValue, forKey: "launchAtLogin")
                }
            
            Picker("History limit", selection: $historyLimit) {
                Text("50 items").tag(50)
                Text("100 items").tag(100)
                Text("200 items").tag(200)
            }
            .onChange(of: historyLimit) { _, newValue in
                UserDefaults.standard.set(newValue, forKey: "historyLimit")
            }
            
            Divider()
            
            Text("PasteLite runs in your menu bar. Use ⌘⇧V to open history panel.")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
    }
    
    private var shortcutsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Default Shortcut")
                .font(.headline)
            
            HStack {
                Text("Show History Panel")
                Spacer()
                Text("⌘⇧V")
                    .font(.system(.body, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(4)
            }
            
            Divider()
            
            Text("Custom shortcut configuration coming soon.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    private var aboutView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)
            
            Text("PasteLite")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Version 1.0")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Smart Clipboard Manager for Mac Menu Bar")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Divider()
            
            Text("One-time purchase. No subscriptions.\nYour data stays on your Mac.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
