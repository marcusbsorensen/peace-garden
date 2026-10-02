// swift-tools-version: 6.0
import PackageDescription

// The ten areas' rules, run over a stream of SeedCore's own plants, to say how
// a layout fills: plots used and places held at 10, 100 and 1,000 arrivals.
//
//     swift run -c release --package-path tools/layouts/harness layouts-harness
//
// It links SeedCore from this checkout, so it measures whatever rules the
// checkout has: run it on main and on a branch to compare an area's old layout
// with its new one. `tools/layouts/README.md` says how; `BASELINE.md` is what
// it found on 2 October 2026, before any area's layout changed.
//
// A tool, not a target of SeedCore: nothing here is a rule, and growing ten
// thousand plants is no test for every run of the suite.
let package = Package(
    name: "LayoutsHarness",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(path: "../../../Packages/SeedCore")
    ],
    targets: [
        .executableTarget(
            name: "layouts-harness",
            dependencies: [.product(name: "SeedCore", package: "SeedCore")],
            path: "Sources/LayoutsHarness",
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
