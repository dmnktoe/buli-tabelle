// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "BuLiTabelle",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.4"),
        .package(url: "https://github.com/TelemetryDeck/SwiftSDK", from: "2.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "BuLiTabelle",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle"),
                .product(name: "TelemetryDeck", package: "SwiftSDK"),
            ],
            path: "Sources/BuLiTabelle"
        ),
        .testTarget(
            name: "BuLiTabelleTests",
            dependencies: ["BuLiTabelle"],
            path: "Tests/BuLiTabelleTests"
        ),
    ]
)
