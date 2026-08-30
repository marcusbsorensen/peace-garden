// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SeedCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SeedCore", targets: ["SeedCore"])
    ],
    targets: [
        .target(name: "SeedCore", path: "Sources/SeedCore"),
        .testTarget(name: "SeedCoreTests", dependencies: ["SeedCore"], path: "Tests/SeedCoreTests")
    ]
)
