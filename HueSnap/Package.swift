// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HueSnap",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "HueSnap",
            path: ".",
            exclude: [
                "Package.swift",
                "Assets.xcassets",
                "Info.plist",
                "HueSnap.entitlements"
            ],
            sources: [
                "App/HueSnapApp.swift",
                "App/AppDelegate.swift",
                "MenuBar/MenuBarPopoverView.swift",
                "Views/SettingsView.swift",
                "ViewModels/HueSnapViewModel.swift",
                "Services/ColorPickerService.swift",
                "Services/TailwindService.swift",
                "Utils/Localized.swift",
                "Utils/KeyboardShortcutManager.swift"
            ],
            swiftSettings: [
                .define("APP_STORE"),
                .unsafeFlags(["-Xfrontend", "-enable-actor-data-race-checks"])
            ],
            linkerSettings: [
                .unsafeFlags(["-Xlinker", "-sdk_version", "-Xlinker", "14.0"])
            ]
        )
    ]
)
