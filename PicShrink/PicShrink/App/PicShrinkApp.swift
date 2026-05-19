import SwiftUI

@main
struct PicShrinkApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("appearance") private var appearance: String = "system"

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

extension PicShrinkApp {
    func applyAppearance() {
        switch appearance {
        case "light":
            NSApp.appearance = NSAppearance(named: .aqua)
        case "dark":
            NSApp.appearance = NSAppearance(named: .darkAqua)
        default:
            NSApp.appearance = nil
        }
        NSApp.windows.forEach { $0.appearance = NSApp.appearance }
    }
}
