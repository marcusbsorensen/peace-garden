import simd
import SwiftUI
import UIKit
import XCTest
@testable import PeaceGarden

/// **The worlds drawn as the app draws them, to be looked at.**
///
/// Skipped unless `PG_RENDER_WORLDS` names a folder (passed to the test runner
/// as `TEST_RUNNER_PG_RENDER_WORLDS`). Every defect the worlds have had was
/// caught by eye — a gorge that swallowed the plot, a parterre that read as a
/// lizard's scales — and none of them by a test, so this writes the pictures
/// rather than asserting anything about them. Posts at half a metre and a metre
/// stand on the ground for scale: a lantern and a middling plant.
final class WorldRenderTests: XCTestCase {
    private static let size = CGSize(width: 390, height: 520)

    func testDrawEveryWorld() async throws {
        guard let path = ProcessInfo.processInfo.environment["PG_RENDER_WORLDS"], !path.isEmpty else {
            throw XCTSkip("PG_RENDER_WORLDS is not set")
        }
        let folder = URL(fileURLWithPath: path, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let worlds = GardenWorlds.shared
        try XCTSkipUnless(worlds.isLoaded)
        let side = GardenWorlds.drawnForSide
        let light = GardenGround.Light.at(hour: 10)

        var timings: [String] = []
        for world in 0..<worlds.count {
            let relief = worlds.relief(world: world, plotSide: side)
            let view = Isometric.fitting(plotSide: side, in: Self.size,
                                         headroom: 1.1 + relief.high,
                                         soilDepth: GardenGround.rimDepth - relief.low)
            await GardenTerrain.shared.forget()
            let start = Date()
            let ground = await GardenTerrain.shared.image(world: world, plotSide: side, view: view,
                                                          size: Self.size, light: light)
            let took = Date().timeIntervalSince(start)
            timings.append("world \(world): \(String(format: "%.3f", took)) s")
            guard let ground else { continue }
            try write(posts(on: ground, world: world, view: view, side: side),
                      to: folder.appendingPathComponent("world-\(world).png"))

            // Close: the same plot at three times, a phone's worth of it round
            // the middle, as the zoomed redraw draws it.
            let big = CGSize(width: Self.size.width * 3, height: Self.size.height * 3)
            let close = Isometric.fitting(plotSide: side, in: big,
                                          headroom: 1.1 + relief.high,
                                          soilDepth: GardenGround.rimDepth - relief.low)
            let region = CGRect(x: big.width / 2 - 195, y: big.height / 2 - 130, width: 390, height: 260)
            if let near = await GardenTerrain.shared.image(world: world, plotSide: side, view: close,
                                                           size: big, light: light, region: region) {
                try write(near, to: folder.appendingPathComponent("world-\(world)-close.png"))
            }
        }
        try timings.joined(separator: "\n").write(to: folder.appendingPathComponent("timings.txt"),
                                                   atomically: true, encoding: .utf8)
    }

    /// Half-metre and one-metre posts on a few places of the plot.
    private func posts(on ground: UIImage, world: Int, view: Isometric, side: Double) -> UIImage {
        let worlds = GardenWorlds.shared
        let spots: [(x: Double, z: Double, tall: Double)] = [
            (-1.6, -1.6, 0.5), (-0.4, -1.9, 1.0), (0.6, 0.6, 0.5), (1.4, -0.4, 1.0), (-1.2, 1.0, 1.0)
        ]
        let format = UIGraphicsImageRendererFormat.preferred()
        format.scale = ground.scale
        return UIGraphicsImageRenderer(size: ground.size, format: format).image { context in
            ground.draw(at: .zero)
            let cg = context.cgContext
            for spot in spots {
                let y = worlds.height(world: world, x: spot.x, z: spot.z, plotSide: side)
                let foot = view.point(x: spot.x, y: y, z: spot.z)
                let top = view.point(x: spot.x, y: y + spot.tall, z: spot.z)
                cg.setStrokeColor(UIColor(white: 0.08, alpha: 1).cgColor)
                cg.setLineWidth(2)
                cg.move(to: foot)
                cg.addLine(to: top)
                cg.strokePath()
                cg.setFillColor(spot.tall < 0.7 ? UIColor.orange.cgColor : UIColor.magenta.cgColor)
                cg.fillEllipse(in: CGRect(x: top.x - 4, y: top.y - 4, width: 8, height: 8))
            }
        }
    }

    private func write(_ image: UIImage, to url: URL) throws {
        let data = try XCTUnwrap(image.pngData())
        try data.write(to: url)
    }
}
