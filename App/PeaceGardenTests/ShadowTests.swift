import SceneKit
import SeedCore
import simd
import SwiftUI
import UIKit
import XCTest
@testable import PeaceGarden

/// The shadows' arithmetic, held to what it is for.
@MainActor
final class ShadowTests: XCTestCase {

    private func genome(_ n: Int) -> (Genome, GrowthModel.State) {
        let a = SeedID(bytes: seedDigest(SeedDomain.seed, Data("shadow-a-\(n)".utf8)))!
        let b = SeedID(bytes: seedDigest(SeedDomain.seed, Data("shadow-b-\(n)".utf8)))!
        let encounter = Pollination.encounterID(seedA: a, seedB: b,
                                                nonceA: Data("na\(n)".utf8), nonceB: Data("nb\(n)".utf8))
        let genome = Genome(seed: Pollination.cross(seedA: a, seedB: b, encounterID: encounter),
                            lineage: .crossed(parentA: a, parentB: b, encounterID: encounter))
        let birth = Date(timeIntervalSince1970: 0)
        return (genome, GrowthModel(genome: genome).state(birth: birth, now: birth.addingTimeInterval(200 * 86_400)))
    }

    /// Every figure's model gives up its triangles, primitives and swept
    /// surfaces alike — a figure with none would stand on the grass with no
    /// shadow and nobody would know why.
    func testEveryFigureCasts() {
        for kind in LampKind.allCases where GardenCreatures.figure(of: kind) != nil {
            let model = GardenCreatures.model(of: kind)!
            let caster = ShadowCaster(node: model)
            XCTAssertFalse(caster.isEmpty, "\(kind) has nothing to cast")
            let sheet = caster.cast(toward: GardenShadows.light(step: 24).direction, turn: 0, scale: 1,
                                    look: .figure, salt: 0)
            XCTAssertNotNil(sheet, "\(kind) cast nothing at noon")
        }
    }

    /// The shadow leans away from the light: at nine in the morning the sun is
    /// on one side of the plot and the shadow's weight on the other.
    func testTheShadowLeansAwayFromTheLight() throws {
        let (genome, growth) = genome(3)
        let caster = ShadowCaster(mesh: PlantBuilder(genome: genome).mesh(growth: growth))
        let light = GardenShadows.light(step: 18)
        let sheet = try XCTUnwrap(caster.cast(toward: light.direction, turn: 0, scale: 1,
                                              look: .plant, salt: 0))
        let middle = try weightedMiddle(of: sheet)
        let away = SIMD2(-light.direction.x, -light.direction.z)
        XCTAssertGreaterThan(simd_dot(middle, away), 0.02, "the shadow's middle is toward the light")
    }

    /// At the moment the sun hands over to the moon there is no shadow at all,
    /// so nothing swings round.
    func testNoShadowAtTheHandover() {
        XCTAssertEqual(GardenShadows.presence(of: GardenGround.Light.at(hour: 6)), 0, accuracy: 1e-9)
        XCTAssertEqual(GardenShadows.presence(of: GardenGround.Light.at(hour: 18)), 0, accuracy: 1e-9)
        XCTAssertEqual(GardenShadows.presence(of: GardenGround.Light.at(hour: 12)), 1, accuracy: 1e-9)
        XCTAssertLessThan(GardenShadows.presence(of: GardenGround.Light.at(hour: 17.9)), 0.05)
        XCTAssertLessThan(GardenShadows.presence(of: GardenGround.Light.at(hour: 18.1)), 0.05)
    }

    /// Full shade multiplies the ground and takes less under the moon, and the
    /// moon's keeps more blue than red.
    func testShadeIsAMultiplyAndTheMoonsIsFaintAndCool() {
        let noon = GardenShadows.fullShade(under: GardenGround.Light.at(hour: 12))
        let midnight = GardenShadows.fullShade(under: GardenGround.Light.at(hour: 0))
        for channel in 0..<3 {
            XCTAssertGreaterThanOrEqual(noon[channel], 0.19)
            XCTAssertLessThan(noon[channel], 0.8)
            XCTAssertGreaterThan(midnight[channel], noon[channel])
            XCTAssertLessThanOrEqual(midnight[channel], 1)
        }
        XCTAssertGreaterThan(midnight.z, midnight.x)
    }

    private func weightedMiddle(of sheet: ShadowSheet) throws -> SIMD2<Double> {
        let image = sheet.image
        let width = image.width, height = image.height
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        let context = try XCTUnwrap(CGContext(data: &bytes, width: width, height: height, bitsPerComponent: 8,
                                              bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                                              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        var sum = SIMD2<Double>(), total = 0.0
        for j in 0..<height {
            for i in 0..<width {
                // A bitmap context's rows run bottom up.
                let row = height - 1 - j
                let alpha = Double(bytes[(row * width + i) * 4 + 3])
                let x: Double = sheet.x0 + (Double(i) + 0.5) * sheet.cell
                let z: Double = sheet.z0 + (Double(j) + 0.5) * sheet.cell
                sum += SIMD2(x, z) * alpha
                total += alpha
            }
        }
        return sum / max(total, 1)
    }

    /// The sheets themselves, for looking at, when `PG_RENDERS` is set.
    func testDrawSheets() throws {
        guard let folder = ProcessInfo.processInfo.environment["PG_RENDERS"] else {
            throw XCTSkip("PG_RENDERS is not set")
        }
        try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true)
        var lines: [String] = []
        for n in [0, 3, 7] {
            let (genome, growth) = genome(n)
            var start = Date()
            let mesh = PlantBuilder(genome: genome).mesh(growth: growth)
            let built = Date().timeIntervalSince(start)
            start = Date()
            let caster = ShadowCaster(mesh: mesh)
            let boiled = Date().timeIntervalSince(start)
            for step in [16, 24, 34] {
                start = Date()
                let sheet = caster.cast(toward: GardenShadows.light(step: step).direction, turn: 0, scale: 1,
                                        look: .plant, salt: 0)
                let took = Date().timeIntervalSince(start)
                lines.append(String(format: "plant %d: %d triangles, mesh %.1f ms, caster %.1f ms (%d pieces), step %d sheet %.1f ms %dx%d",
                                    n, mesh.triangleCount, built * 1000, boiled * 1000, caster.points.count,
                                    step, took * 1000, sheet?.image.width ?? 0, sheet?.image.height ?? 0))
                if let sheet {
                    try XCTUnwrap(UIImage(cgImage: sheet.image).pngData())
                        .write(to: URL(fileURLWithPath: folder).appendingPathComponent("sheet-\(n)-\(step).png"))
                }
            }
        }
        for kind in LampKind.allCases where GardenCreatures.figure(of: kind) != nil {
            var start = Date()
            let caster = ShadowCaster(node: GardenCreatures.model(of: kind)!)
            let boiled = Date().timeIntervalSince(start)
            start = Date()
            let sheet = caster.cast(toward: GardenShadows.light(step: 18).direction, turn: 0, scale: 1,
                                    look: .figure, salt: 0)
            let took = Date().timeIntervalSince(start)
            lines.append(String(format: "%@: caster %.1f ms (%d pieces), sheet %.1f ms",
                                kind.rawValue, boiled * 1000, caster.points.count, took * 1000))
            if let sheet {
                try XCTUnwrap(UIImage(cgImage: sheet.image).pngData())
                    .write(to: URL(fileURLWithPath: folder).appendingPathComponent("sheet-\(kind.rawValue).png"))
            }
        }
        try lines.joined(separator: "\n").write(to: URL(fileURLWithPath: folder).appendingPathComponent("sheets.txt"),
                                                atomically: true, encoding: .utf8)
    }
}
