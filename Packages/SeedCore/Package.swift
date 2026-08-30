// swift-tools-version: 5.9
import PackageDescription

// SeedCore builds on Apple's platforms against CryptoKit and simd, and off them
// against swift-crypto and the small compatibility layer in `Compatibility/`.
// The second path exists so continuous integration can run the whole suite on
// Linux — the derivation and the geometry are the parts that must not drift,
// and they are exactly the parts that need no UI to test.
let package = Package(
    name: "SeedCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SeedCore", targets: ["SeedCore"])
    ],
    dependencies: [
        // Resolved everywhere, linked only where CryptoKit is absent.
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0")
    ],
    targets: [
        .target(
            name: "SeedCore",
            dependencies: [
                .product(
                    name: "Crypto",
                    package: "swift-crypto",
                    condition: .when(platforms: [.linux, .windows, .android])
                )
            ],
            path: "Sources/SeedCore"
        ),
        .testTarget(name: "SeedCoreTests", dependencies: ["SeedCore"], path: "Tests/SeedCoreTests")
    ]
)
