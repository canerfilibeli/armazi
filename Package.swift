// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Armazi",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "Armazi",
            dependencies: ["ArmaziCore"],
            path: "Sources/Armazi",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .target(
            name: "ArmaziCore",
            dependencies: ["Yams"],
            path: "Sources/ArmaziCore",
            resources: [.copy("Benchmarks")],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "ArmaziTests",
            dependencies: ["ArmaziCore"],
            path: "Tests/ArmaziTests"
        )
    ]
)
