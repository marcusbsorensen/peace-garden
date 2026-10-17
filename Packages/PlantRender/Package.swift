// swift-tools-version: 6.0
import PackageDescription

// PlantRender draws a SeedCore plant with SceneKit: the node, the lit scene and
// camera it stands in, the live view, and the still a grid shows.
//
// It is the code Peace Garden draws its plants with, moved out of the app so a
// second app can link it and draw them the same way — products `SeedCore` and
// `PlantRender` from this repository at a pinned commit.
//
// iOS only. The scene is built from UIColor, the view is a UIViewRepresentable
// and the thumbnail is a UIImage; a macOS build would be a second port, not a
// platform line in this file.
let package = Package(
    name: "PlantRender",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "PlantRender", targets: ["PlantRender"])
    ],
    dependencies: [
        .package(path: "../SeedCore")
    ],
    targets: [
        .target(
            name: "PlantRender",
            dependencies: [
                .product(name: "SeedCore", package: "SeedCore")
            ],
            path: "Sources/PlantRender",
            // The app builds at this bar, and the code was written under it.
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "PlantRenderTests",
            dependencies: [
                "PlantRender",
                .product(name: "SeedCore", package: "SeedCore")
            ],
            path: "Tests/PlantRenderTests"
        )
    ]
)
