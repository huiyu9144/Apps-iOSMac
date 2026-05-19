import SwiftUI

@main
struct FindDupApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, minHeight: 500)
        }
        .windowResizability(.contentSize)
    }
}
