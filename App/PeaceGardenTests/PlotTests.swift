import SwiftUI
import XCTest
import SeedCore
@testable import PeaceGarden

/// The plot: the projection, the cut, and the one scale every plant is drawn at.
///
/// Most of what makes a garden read as a place has to be looked at rather than
/// asserted — `tools/preview/README.md` is emphatic about that, and the husk
/// cost five passes on a simulator to prove it. What is here is the other kind:
/// arithmetic that is either exact or silently wrong, and where being wrong
/// looks like a plausible garden rather than a broken one.
final class PlotTests: XCTestCase {

    private let mine = SeedID(bytes: seedDigest(SeedDomain.seed, Data("mine".utf8)))!

    private func crossing(_ peer: String, nonce: Int) -> PlantRecord {
        let theirs = SeedID(bytes: seedDigest(SeedDomain.seed, Data("peer-\(peer)".utf8)))!
        let enc = Pollination.encounterID(seedA: mine, seedB: theirs,
                                          nonceA: Data("a\(nonce)".utf8),
                                          nonceB: Data("b\(nonce)".utf8))
        let child = Pollination.cross(seedA: mine, seedB: theirs, encounterID: enc)
        return PlantRecord(
            seed: child,
            lineage: .crossed(parentA: mine, parentB: theirs, encounterID: enc),
            birth: Date(timeIntervalSince1970: 1_700_000_000)
        )
    }

    private let view = Isometric(pointsPerMetre: 42, centre: CGPoint(x: 195, y: 328))

    // MARK: - The projection

    /// Putting a plant down under a finger is the inverse of drawing it, and the
    /// two are written as separate arithmetic. If they ever stop agreeing, a
    /// dragged plant lands somewhere near where it was dropped and every
    /// explanation for that is wrong.
    func testAPlaceOnTheGroundSurvivesBeingDrawnAndReadBack() {
        for spot in [Spot(x: 0, z: 0), Spot(x: 2.6, z: -2.6), Spot(x: -1.4, z: 0.9),
                     Spot(x: 0.001, z: 2.599)] {
            let back = view.ground(at: view.point(spot))
            XCTAssertEqual(back.x, spot.x, accuracy: 1e-9)
            XCTAssertEqual(back.z, spot.z, accuracy: 1e-9)
        }
    }

    /// The property that makes `pointsPerMetre` one number rather than three.
    /// Lose it and a plant is drawn at a different scale from the ground it
    /// stands on, which reads as a plant that is slightly the wrong size and
    /// never as a projection fault.
    func testAMetreIsTheSameLengthUpAsItIsAcross() {
        let origin = view.point(x: 0, z: 0)
        let alongX = view.point(x: 1, z: 0)
        let alongZ = view.point(x: 0, z: 1)
        let up = view.point(x: 0, y: 1, z: 0)

        func length(_ a: CGPoint, _ b: CGPoint) -> Double {
            Double(hypot(b.x - a.x, b.y - a.y))
        }

        XCTAssertEqual(length(origin, alongX), 42, accuracy: 1e-9)
        XCTAssertEqual(length(origin, alongZ), 42, accuracy: 1e-9)
        XCTAssertEqual(length(origin, up), 42, accuracy: 1e-9)
    }

    /// Depth order is `x + z` and nothing else, so it has to agree with what the
    /// eye reads as nearer — which on this screen is *lower down*.
    func testThePlantThatIsDrawnLastIsTheOneStandingNearest() {
        let far = Spot(x: -1, z: -1)
        let near = Spot(x: 1, z: 1)

        XCTAssertLessThan(Isometric.depth(far), Isometric.depth(near))
        XCTAssertLessThan(view.point(far).y, view.point(near).y)
    }

    /// A metre of height is the same wherever it is, so a plant at the far
    /// corner is exactly as tall as the same plant at the near one. This is what
    /// the perspective camera on the stage cannot do and why the garden has its
    /// own.
    func testAPlantIsTheSameSizeWhereverItStands() {
        let farFoot = view.point(x: -2.6, z: -2.6)
        let farTop = view.point(x: -2.6, y: 1.2, z: -2.6)
        let nearFoot = view.point(x: 2.6, z: 2.6)
        let nearTop = view.point(x: 2.6, y: 1.2, z: 2.6)

        XCTAssertEqual(Double(farFoot.y - farTop.y), Double(nearFoot.y - nearTop.y), accuracy: 1e-9)
    }

    // MARK: - Fitting the plot on a screen

    /// The corners are what say the plot is a square rather than a blob, and
    /// they are the first thing to go off the side of a phone. The cut below and
    /// the tallest plant above have to fit too, or the garden is drawn with its
    /// plants cropped at the top of the screen.
    func testTheWholePlotAndWhatStandsOnItFitsOnTheScreen() {
        let sizes = [CGSize(width: 390, height: 844),   // iPhone
                     CGSize(width: 1024, height: 768),  // iPad, landscape
                     CGSize(width: 320, height: 900)]   // a Split View column

        for size in sizes {
            for side in [Garden.smallestPlot, 5.2, 9.0] {
                let fitted = Isometric.fitting(
                    plotSide: side,
                    in: size,
                    headroom: GardenSprites.tallestExpected,
                    soilDepth: GardenGround.rimDepth
                )
                let half = side / 2
                let corners = [(-half, -half), (half, -half), (half, half), (-half, half)]
                    .map { fitted.point(x: $0.0, z: $0.1) }

                for corner in corners {
                    XCTAssertGreaterThanOrEqual(corner.x, 0)
                    XCTAssertLessThanOrEqual(corner.x, size.width)
                }

                let top = fitted.point(x: -half, y: GardenSprites.tallestExpected, z: -half).y
                let bottom = fitted.point(x: half, y: -GardenGround.rimDepth, z: half).y
                XCTAssertGreaterThanOrEqual(top, 0, "a plant at the far corner is off the top")
                XCTAssertLessThanOrEqual(bottom, size.height, "the cut hangs off the bottom")
            }
        }
    }

    // MARK: - The cut

    /// The only part of a floating plot's underside anybody ever sees is the
    /// part near the rim, so the rim is the one place the depth may not be
    /// economised. A taper to nothing reads as a tile rather than as ground.
    func testTheSoilHasRealDepthExactlyWhereItIsEasiestToEconomise() {
        let side = 5.2
        XCTAssertEqual(GardenGround.cutDepth(x: 2.6, z: 0, plotSide: side),
                       GardenGround.rimDepth, accuracy: 1e-9)
        XCTAssertEqual(GardenGround.cutDepth(x: -2.6, z: 2.6, plotSide: side),
                       GardenGround.rimDepth, accuracy: 1e-9)
        XCTAssertGreaterThan(GardenGround.cutDepth(x: 0, z: 0, plotSide: side), 2.0)

        for x in stride(from: -2.6, through: 2.6, by: 0.13) {
            for z in stride(from: -2.6, through: 2.6, by: 0.13) {
                XCTAssertGreaterThanOrEqual(
                    GardenGround.cutDepth(x: x, z: z, plotSide: side),
                    GardenGround.rimDepth
                )
            }
        }
    }

    // MARK: - The saturation ceiling

    /// `Chrome`'s rule is that the plant is the only saturated thing on screen.
    /// Enforced in one function rather than trusted to each material, so a world
    /// written too bright later cannot quietly take the rule away — which it
    /// would do by looking rather better than the ones that keep it.
    func testNoGroundColourIsMoreSaturatedThanThePlantIsAllowedToBe() {
        let tooBright: [SIMD3<Double>] = [
            SIMD3(0.10, 0.85, 0.15),   // a lawn in full chroma
            SIMD3(0.90, 0.10, 0.10),
            SIMD3(0.20, 0.40, 0.95)
        ]

        for base in tooBright + [GardenGround.turf, GardenGround.soil] {
            var saturation: CGFloat = 0
            UIColor(GardenGround.underCeiling(base))
                .getHue(nil, saturation: &saturation, brightness: nil, alpha: nil)
            XCTAssertLessThanOrEqual(Double(saturation),
                                     GardenGround.saturationCeiling + 1e-6)
        }
    }

    // MARK: - The sprites

    /// **The range in `ARRANGING.md` is the mockup's fourteen crossings, not the
    /// range.** That document records the plants as 0.46 m to 1.36 m and calls
    /// it real, which it is — of those fourteen. Across a hundred and twenty the
    /// tallest is over 2.3 m, and a frame sized from the smaller number drew that
    /// plant with its head cut off. A cropped plant looks like a tall plant.
    ///
    /// So a frame is per plant, and this holds the two things that depend on the
    /// range: that a plant always fits its own frame, and that the headroom the
    /// plot reserves is still roughly the tallest thing that will stand in it.
    @MainActor
    func testEveryPlantFitsInsideItsOwnFrame() {
        var tallest = 0.0
        for nonce in 0..<120 {
            let plant = crossing(["Ada", "Rune", "Sofia", "Jonas"][nonce % 4], nonce: nonce)
            let bounds = PlantSceneBuilder.matureBounds(for: plant.genome)
            let height = Double(bounds.max.y - bounds.min.y)
            tallest = max(tallest, height)

            let needed = GardenSprites.needed(of: plant.genome)
            let framed = GardenSprites.shared.frameMetres(for: plant.genome)
            XCTAssertLessThanOrEqual(height, framed, "a plant is taller than its own frame")
            XCTAssertLessThanOrEqual(needed, framed, "a plant is wider than its own frame")
            XCTAssertLessThan(framed - needed, GardenSprites.frameStep + 1e-6,
                              "a frame is more than one step bigger than what it holds")
        }

        XCTAssertGreaterThan(tallest, 2.0, "the measured range has moved; the headroom was set from it")
        XCTAssertLessThanOrEqual(tallest, GardenSprites.tallestExpected)
    }

    /// Which way a plant faces comes from its own seed, so a garden looks the
    /// same every time it is opened and adding a plant turns nothing that was
    /// already there.
    func testAPlantFacesTheSameWayEveryTimeTheGardenIsOpened() {
        let plants = (0..<8).map { crossing("Ada", nonce: $0) }
        let turns = plants.map { GardenSprites.turn(for: $0.seed) }

        for (plant, turn) in zip(plants, turns) {
            XCTAssertEqual(GardenSprites.turn(for: plant.seed), turn)
        }
        XCTAssertGreaterThan(Set(turns).count, 1, "every plant faces the same way")
    }

    // MARK: - What announces itself

    /// **The pool must not come on with the evening.**
    /// `GrowthModel.diurnalFactor` shuts a day-opening flower overnight and opens
    /// a night-opening one in its place, so a bucket that included `bloomOpen` —
    /// which is what a thumbnail's cache key does — would light the whole garden
    /// up every evening and again every morning. A pool that comes on nightly
    /// says nothing.
    func testAFlowerClosingForTheNightIsNotSomethingThatHasChanged() {
        let plant = crossing("Ada", nonce: 1)
        let born = plant.birth

        let noon = plant.growth(now: born.addingTimeInterval(30 * 86_400 + 12 * 3600))
        let midnight = plant.growth(now: born.addingTimeInterval(30 * 86_400 + 24 * 3600))

        XCTAssertNotEqual(noon.bloomOpen, midnight.bloomOpen, "the flower did not move at all")
        XCTAssertEqual(GardenVisits.bucket(of: noon), GardenVisits.bucket(of: midnight))
    }

    /// The other half of the pool: it has to come *on* when a plant has actually
    /// grown, or the whole announcement is a mechanism that never fires.
    @MainActor
    func testAPlantThatHasGrownSinceItWasOpenedSaysSo() {
        let plant = crossing("Ada", nonce: 3)
        let visits = GardenVisits(defaults: UserDefaults(suiteName: "plot-tests-\(UUID())")!)

        let sown = plant.growth(now: plant.birth.addingTimeInterval(3 * 86_400))
        visits.seen(plant, growth: sown)
        XCTAssertFalse(visits.announces(plant, growth: sown))

        let later = plant.growth(now: plant.birth.addingTimeInterval(63 * 86_400))
        XCTAssertGreaterThan(later.overall, sown.overall, "the plant did not grow at all")
        XCTAssertTrue(visits.announces(plant, growth: later))
    }

    /// **A sprite is placed by its bottom edge, so the bottom edge has to be the
    /// plant's foot.** Nothing on screen says whether it is: a garden of plants
    /// all floating three centimetres above the ground, or all sunk into it,
    /// looks like a garden. It is only wrong once something else — a shadow, a
    /// ravine — is drawn against the ground the plants are supposed to be on.
    ///
    /// Measured off the rendered pixels rather than off the camera arithmetic,
    /// because the arithmetic is what is in doubt.
    @MainActor
    func testEveryPlantStandsOnTheBottomEdgeOfItsOwnFrame() throws {
        for nonce in 0..<6 {
            let plant = crossing(["Ada", "Rune", "Sofia", "Jonas"][nonce % 4], nonce: nonce)
            let growth = plant.growth(now: plant.birth.addingTimeInterval(400 * 86_400))
            let sprite = try XCTUnwrap(
                GardenSprites.shared.sprite(genome: plant.genome, growth: growth)
            )

            let image = try XCTUnwrap(sprite.image.cgImage)
            let width = image.width, height = image.height
            var pixels = [UInt8](repeating: 0, count: width * height * 4)
            let context = try XCTUnwrap(CGContext(
                data: &pixels, width: width, height: height,
                bitsPerComponent: 8, bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ))
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

            var lowest = -1
            for row in stride(from: height - 1, through: 0, by: -1) {
                for column in 0..<width where pixels[(row * width + column) * 4 + 3] > 24 {
                    lowest = row
                    break
                }
                if lowest >= 0 { break }
            }

            XCTAssertGreaterThanOrEqual(lowest, 0, "the sprite is empty")
            let gap = Double(height - 1 - lowest) / Double(height)
            XCTAssertLessThan(gap, 0.04,
                              "the plant floats \(String(format: "%.1f", gap * 100))% of its frame above the ground")
        }
    }

    // MARK: - The worlds

    /// **A height is a sixteen-bit number hidden in two colour channels**, and
    /// every step of ordinary image handling is entitled to move a colour by a
    /// value or two while keeping it the same colour. A value or two here is a
    /// centimetre of hill in the wrong place, which nothing on screen would ever
    /// look wrong enough to catch.
    ///
    /// So each world's relief is held against what the exporter measured. If a
    /// decode ever starts going through a colour space, this is what says so.
    func testEveryWorldIsTheShapeItWasExportedAs() throws {
        let worlds = GardenWorlds.shared
        try XCTSkipUnless(worlds.isLoaded, "the world atlas is not in this bundle")
        XCTAssertEqual(worlds.count, 8)

        let exported: [(low: Double, high: Double)] = [
            (-0.1241, 0.1584),   // meadow
            (-0.4320, 0.3545),   // hillside
            (-0.1000, 0.9689),   // alpine
            (0.0000, 0.2669),    // lake
            (-1.1360, 0.3465),   // ravine
            (-0.1613, 0.1486),   // verge
            (-0.0500, 0.2323),   // raised beds
            (-0.0976, 0.1213)    // parterre
        ]

        for (world, expected) in exported.enumerated() {
            let measured = worlds.relief(world: world, plotSide: GardenWorlds.drawnForSide)
            XCTAssertEqual(measured.low, expected.low, accuracy: 0.002, "world \(world) floor")
            XCTAssertEqual(measured.high, expected.high, accuracy: 0.002, "world \(world) peak")
        }
    }

    /// The relief is scaled with the plot, so a garden of fifty meetings gets a
    /// bigger hill rather than the same hill with more ground round it — and a
    /// plant on that hill stands on it rather than inside it.
    func testAHillGrowsWithThePlotItIsOn() throws {
        let worlds = GardenWorlds.shared
        try XCTSkipUnless(worlds.isLoaded, "the world atlas is not in this bundle")

        let small = worlds.relief(world: 2, plotSide: GardenWorlds.drawnForSide)
        let large = worlds.relief(world: 2, plotSide: GardenWorlds.drawnForSide * 2)
        XCTAssertEqual(large.high, small.high * 2, accuracy: 1e-9)

        // And the ground under a place is the ground the drawing puts there.
        let onThePeak = worlds.height(world: 2, x: 0, z: 0, plotSide: GardenWorlds.drawnForSide)
        XCTAssertGreaterThanOrEqual(onThePeak, small.low)
        XCTAssertLessThanOrEqual(onThePeak, small.high)
    }
}
