import SeedCore
import SwiftUI
import UIKit
import XCTest
@testable import PeaceGarden

/// Contact sheets of the lights and figures, for looking at.
///
/// Not a test of anything: what a figure looks like is looked at, not asserted.
/// It writes one sheet per light, by day and by night at two facings each, on
/// the ground's own colour at that hour, into the folder named by `PG_RENDERS`
/// — which `xcodebuild test` passes through as `TEST_RUNNER_PG_RENDERS`. Without
/// it, nothing is drawn.
@MainActor
final class LampSheetTests: XCTestCase {

    private static let pointsPerMetre = 260.0
    private static let grass = SIMD3<Double>(0.36, 0.46, 0.22)

    func testDrawContactSheets() throws {
        guard let folder = ProcessInfo.processInfo.environment["PG_RENDERS"] else {
            throw XCTSkip("PG_RENDERS is not set")
        }
        let prefix = ProcessInfo.processInfo.environment["PG_RENDERS_PREFIX"] ?? "sheet"
        try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true)

        // Mid-morning, mid-afternoon, and midnight, unless asked for others.
        let environment = ProcessInfo.processInfo.environment
        let hours = environment["PG_RENDERS_HOURS"]?.split(separator: ",").compactMap { Double($0) }
            ?? [9, 15, 0]
        let seeds = environment["PG_RENDERS_SEEDS"]?.split(separator: ",").compactMap { Int($0) }
            ?? [1, 6]
        let kinds = environment["PG_RENDERS_KINDS"]?.split(separator: ",").compactMap { LampKind(rawValue: String($0)) }
            ?? [.lantern, .paperLamp, .hare, .fox, .moth, .snail]

        for kind in kinds {
            let row = HStack(spacing: 0) {
                ForEach(hours, id: \.self) { hour in
                    ForEach(seeds, id: \.self) { seed in
                        Self.cell(kind, hour: hour, seed: seed)
                    }
                }
            }
            let renderer = ImageRenderer(content: row)
            renderer.scale = 2
            let image = try XCTUnwrap(renderer.uiImage, "\(kind) did not draw")
            let data = try XCTUnwrap(image.pngData())
            try data.write(to: URL(fileURLWithPath: folder)
                .appendingPathComponent("\(prefix)-\(kind.rawValue).png"))
            // And its own light alone, which is the picture hardest to judge
            // inside the sheet.
            if let shine = GardenCreatures.shared.picture(kind, step: nil, turn: 0, facing: 1),
               let png = shine.pngData() {
                try png.write(to: URL(fileURLWithPath: folder)
                    .appendingPathComponent("\(prefix)-\(kind.rawValue)-shine.png"))
            }
        }
    }

    private static func cell(_ kind: LampKind, hour: Double, seed: Int) -> some View {
        let light = GardenGround.Light.at(hour: hour)
        let glow = GardenLamps.glow(in: light)
        let metre = Self.pointsPerMetre
        // Taken first, so the figure finds its pictures already held.
        if GardenCreatures.figure(of: kind) != nil {
            let facing = GardenCreatures.facing(seed: seed)
            let between = GardenGround.Light.steps(at: hour)
            _ = GardenCreatures.shared.picture(kind, step: between.before, turn: 0, facing: facing)
            _ = GardenCreatures.shared.picture(kind, step: between.after, turn: 0, facing: facing)
            _ = GardenCreatures.shared.picture(kind, step: nil, turn: 0, facing: facing)
        }
        let colour = GardenLamps.swiftUIColour(GardenLamps.colour(of: kind))

        return ZStack(alignment: .bottom) {
            GardenGround.shade(base: Self.grass, normal: SIMD3(0, 1, 0), light: light)
            // The pool the plot lays under every light.
            Ellipse()
                .fill(EllipticalGradient(
                    colors: [colour.opacity(0.34 * glow * GardenLamps.pool(of: kind)), colour.opacity(0)],
                    center: .center, startRadiusFraction: 0, endRadiusFraction: 0.5
                ))
                .frame(width: GardenLamps.reach(of: kind) * 0.72 * 2 * metre * 0.87,
                       height: GardenLamps.reach(of: kind) * 0.72 * metre * 0.5)
                .offset(y: GardenLamps.reach(of: kind) * 0.72 * metre * 0.25 - 0.2 * metre)
                .blendMode(.plusLighter)
            LampFigure(kind: kind, glow: glow, pointsPerMetre: metre, seed: seed, hour: hour, turn: 0)
                .offset(y: -0.2 * metre)
        }
        .frame(width: 1.0 * metre, height: 1.4 * metre)
        .clipped()
    }
}
