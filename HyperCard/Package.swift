// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "HyperCard",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "HyperCardCore", targets: ["HyperCardCore"]),
        .executable(name: "HyperCardApp", targets: ["HyperCardApp"])
    ],
    targets: [
        .executableTarget(
            name: "HyperCardApp",
            dependencies: ["HyperCardCore"]
        ),
        .target(name: "HyperCardCore"),
        .testTarget(
            name: "HyperCardCoreTests",
            dependencies: ["HyperCardCore"]
        )
    ]
)
