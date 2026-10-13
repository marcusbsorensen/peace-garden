// swift-tools-version: 6.0
import PackageDescription

// The population test's generator and verifier. It links SeedCore by path, so
// every cross, every trait and every area it writes is SeedCore's own — the
// same code the app runs — and every check of what the service accepted is
// made by SeedCore rather than by the PHP port it is checking.
let package = Package(
    name: "popgen",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(path: "../../../Packages/SeedCore")
    ],
    targets: [
        .executableTarget(
            name: "popgen",
            dependencies: [.product(name: "SeedCore", package: "SeedCore")],
            path: "Sources/popgen"
        )
    ]
)
