// swift-tools-version: 6.0
import PackageDescription

// SeedCore for the browser: one module that grows a plant from its seed and
// hands the page the same vertex buffers `PlantSceneBuilder` gets on the phone.
//
// Build it with the swift.org toolchain and its WebAssembly SDK (Xcode's Swift
// cannot target wasm); `build.sh` has the command.
let package = Package(
    name: "PlantWasm",
    dependencies: [
        .package(path: "../../Packages/SeedCore")
    ],
    targets: [
        .executableTarget(
            name: "PlantWasm",
            dependencies: [.product(name: "SeedCore", package: "SeedCore")],
            swiftSettings: [.swiftLanguageMode(.v6)],
            // A reactor stays loaded after it starts, so the page can call it
            // again for each plant. A command would run `main` and exit.
            linkerSettings: [
                .unsafeFlags(["-Xclang-linker", "-mexec-model=reactor"])
            ]
        )
    ]
)
