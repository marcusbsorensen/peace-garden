// swift-tools-version: 6.0
import PackageDescription

// The replant's first half: reads a copy of the live garden, grows every
// stored seed again with SeedCore as it is now, replays every area's arrivals
// through the area's own rule, and writes the plan `Server/.api/replant.php`
// carries out on the server. See README.md.
//
//     swift run -c release --package-path tools/replant replant plan <copy> [--out plan.json]
//
// A tool, not a target of SeedCore, for the reason tools/coppice is one: it
// reads a database, and nothing in the SeedCore suite should.
let package = Package(
    name: "Replant",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(path: "../../Packages/SeedCore")
    ],
    targets: [
        .executableTarget(
            name: "replant",
            dependencies: [.product(name: "SeedCore", package: "SeedCore")],
            path: "Sources/Replant",
            swiftSettings: [.swiftLanguageMode(.v6)],
            linkerSettings: [.linkedLibrary("sqlite3")]
        )
    ]
)
