// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "NetMeter",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "NetMeter", targets: ["NetMeter"]),
        .executable(name: "NetMeterHelper", targets: ["NetMeterHelper"]),
    ],
    targets: [
        .executableTarget(
            name: "NetMeter",
            resources: [
                .process("Assets.xcassets"),
                .process("Resources"),
            ]
        ),
        .executableTarget(
            name: "NetMeterHelper"
        ),
    ]
)
