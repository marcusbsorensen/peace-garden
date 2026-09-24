// swift-tools-version: 6.0
import PackageDescription

// The Home Ground's fill, simulated before any rule is written.
//
//     swift run -c release --package-path tools/homeground
//
// docs/WEB-GARDENS.md §"The Home Ground, chosen" is the record of what it
// found. It links SeedCore rather than copying it, so the plants it places are
// the plants the garden grows: their heights and footprints come from
// `Maturity.bounds`, their family from the name. Nothing in it is the rule
// itself — `HomeGround.swift` does not exist yet, and this is how the rule it
// will hold was chosen.
let package = Package(
    name: "HomeGroundFill",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(path: "../../Packages/SeedCore")
    ],
    targets: [
        .executableTarget(
            name: "HomeGroundFill",
            dependencies: [.product(name: "SeedCore", package: "SeedCore")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
