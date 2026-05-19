// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MenuMeter",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "MenuMeter",
            dependencies: [],
            path: ".",
            exclude: ["Resources/Info.plist"],
            resources: [.process("Resources")]
        )
    ]
)
