// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AlwaysGreen",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "AlwaysGreenApp", targets: ["AlwaysGreenApp"]),
        .executable(name: "alwaysgreen", targets: ["alwaysgreen"])
    ],
    targets: [
        .target(name: "AlwaysGreenCore"),
        .executableTarget(
            name: "AlwaysGreenApp",
            dependencies: ["AlwaysGreenCore"]
        ),
        .executableTarget(
            name: "alwaysgreen",
            dependencies: ["AlwaysGreenCore"]
        ),
        .testTarget(
            name: "AlwaysGreenCoreTests",
            dependencies: ["AlwaysGreenCore"]
        )
    ],
    swiftLanguageModes: [.v5]
)
