// swift-tools-version: 6.0
import PackageDescription

// SeedCore builds on Apple's platforms against CryptoKit and simd, and off them
// against swift-crypto and the small compatibility layer in `Compatibility/`.
// The second path exists so continuous integration can run the whole suite on
// Linux — the derivation and the geometry are the parts that must not drift,
// and they are exactly the parts that need no UI to test.
//
// The browser build (WASI) takes the compatibility layer, imports
// `FoundationEssentials` rather than Foundation, and hashes with
// `PortableSHA256`. The whole of Foundation, which swift-crypto brings with it,
// is some 50 MB of WebAssembly, most of it ICU text data SeedCore never reads.
let package = Package(
    name: "SeedCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SeedCore", targets: ["SeedCore"])
    ],
    dependencies: [
        // Resolved everywhere, linked only on Linux, Windows and Android.
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
            path: "Sources/SeedCore",
            // The app builds at this bar too. The core is pure value types and
            // free functions, so it costs nothing here — which is the argument
            // for turning it on before anything in it needs shared state.
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(name: "SeedCoreTests", dependencies: ["SeedCore"], path: "Tests/SeedCoreTests")
    ]
)
