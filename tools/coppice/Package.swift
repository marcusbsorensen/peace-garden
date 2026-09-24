// swift-tools-version: 6.0
import PackageDescription

// The Coppice's arrivals, grown by SeedCore and written out as numbers, so the
// fill can be simulated before any rule exists. `simulate.py` reads what this
// writes; `docs/WEB-GARDENS.md` §*The Coppice, chosen* is what it found.
//
//     swift run -c release --package-path tools/coppice coppice-sample 2000 coppice-arrival > tools/coppice/sample.json
//
// A tool, not a target of SeedCore: nothing here is a rule, and the SeedCore
// suite should not grow a test that only writes a file.
let package = Package(
    name: "CoppiceSample",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(path: "../../Packages/SeedCore")
    ],
    targets: [
        .executableTarget(
            name: "coppice-sample",
            dependencies: [.product(name: "SeedCore", package: "SeedCore")],
            path: "Sources/CoppiceSample",
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
