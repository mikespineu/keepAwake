// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KeepAwake",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "KeepAwake",
            path: "Sources/KeepAwake"
        ),
        .testTarget(
            name: "KeepAwakeTests",
            dependencies: ["KeepAwake"],
            path: "Tests/KeepAwakeTests"
        ),
    ]
)
