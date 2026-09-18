import simd
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

        XCTAssertLessThan(view.depth(far), view.depth(near))
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
                GardenSprites.shared.sprite(genome: plant.genome, growth: growth, step: 4)
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

    // MARK: - The orbit

    /// **The curve is pinned by its values, not by its shape.** The first pass
    /// had a full moon overhead at 0.32 against a sun on the horizon at 0.24, so
    /// midnight came out brighter than sunrise — and nothing was broken: both
    /// curves peaked correctly at their own maximum, and what nobody had done was
    /// make them agree with each other. A fault that exists only between two
    /// things shows up only when both are put on one slider, so the slider is
    /// what this holds.
    func testTheMoonIsNotBrighterThanTheDawn() {
        let expected: [(hour: Double, strength: Double)] = [
            (0, 0.150), (3, 0.1163), (6, 0.240), (9, 0.6077),
            (12, 0.760), (15, 0.6077), (18, 0.035), (21, 0.1163)
        ]

        for (hour, strength) in expected {
            XCTAssertEqual(GardenGround.Light.at(hour: hour).strength, strength,
                           accuracy: 0.001, "the light at \(hour):00")
        }

        // And the two ends of the day are in the right order against each other.
        let midnight = GardenGround.Light.at(hour: 0).strength
        let sunrise = GardenGround.Light.at(hour: 6).strength
        let noon = GardenGround.Light.at(hour: 12).strength
        XCTAssertLessThan(midnight, sunrise)
        XCTAssertLessThan(sunrise, noon)

        // The darkest hour of the day is moonrise, not midnight, which is
        // correct: the moon has only just cleared the horizon.
        let everyHour = stride(from: 0.0, to: 24.0, by: 0.25)
            .map { (hour: $0, strength: GardenGround.Light.at(hour: $0).strength) }
        let darkest = everyHour.min { $0.strength < $1.strength }!
        XCTAssertEqual(darkest.hour, 18, accuracy: 0.26)
    }

    /// One light, because exactly one body is above the horizon at any hour.
    func testExactlyOneOfThemIsUpAtAnyHour() {
        for quarter in 0..<96 {
            let hour = Double(quarter) / 4
            let light = GardenGround.Light.at(hour: hour)

            XCTAssertEqual(light.isDay, hour >= 6 && hour < 18, "at \(hour):00")
            XCTAssertGreaterThan(light.direction.y, 0, "the light came from below the ground")
            XCTAssertEqual(simd_length(light.direction), 1, accuracy: 1e-9)
        }
    }

    /// It rises at one corner of the plot and sets at the opposite one, so the
    /// two ends of a day point the same way and the middle points across.
    func testItRisesAtOneCornerAndSetsAtTheOpposite() {
        let sunrise = GardenGround.Light.at(hour: 6).direction
        let sunset = GardenGround.Light.at(hour: 17.999).direction

        XCTAssertEqual(sunrise.x, -0.70584, accuracy: 0.002)
        XCTAssertEqual(sunrise.z, -0.70584, accuracy: 0.002)
        XCTAssertEqual(sunset.x, -sunrise.z, accuracy: 0.002)
        XCTAssertEqual(sunset.z, -sunrise.x, accuracy: 0.002)
    }

    /// `noon` is written out because it is a default argument in a file the
    /// orbit is not in. This is what stops the two drifting apart.
    func testNoonIsTheSameLightWhicheverWayItIsAskedFor() {
        let spelled = GardenGround.Light.noon
        let computed = GardenGround.Light.at(hour: 12)

        // A hair of slack, because `sin(.pi / 2)` is not exactly one and the
        // ambient is mixed by it. Anything that has actually drifted is orders
        // of magnitude larger than this.
        XCTAssertEqual(spelled.strength, computed.strength, accuracy: 1e-5)
        XCTAssertEqual(spelled.up, computed.up, accuracy: 1e-5)
        XCTAssertEqual(simd_distance(spelled.direction, computed.direction), 0, accuracy: 1e-5)
        XCTAssertEqual(simd_distance(spelled.sky, computed.sky), 0, accuracy: 1e-5)
        XCTAssertEqual(simd_distance(spelled.bounce, computed.bounce), 0, accuracy: 1e-5)
    }

    /// The moon carries its real phase for the date, from one synodic month
    /// against a known new moon. Held to itself rather than to an almanac: what
    /// this catches is the month drifting or running backwards.
    func testTheMoonGoesRoundInOneMonthAndTheRightWay() {
        let new = MoonPhase.knownNew
        XCTAssertEqual(MoonPhase.lit(on: new), 0, accuracy: 0.001)

        let full = new.addingTimeInterval(MoonPhase.synodicDays / 2 * 86_400)
        XCTAssertEqual(MoonPhase.lit(on: full), 1, accuracy: 0.001)

        let monthLater = new.addingTimeInterval(MoonPhase.synodicDays * 86_400)
        XCTAssertEqual(MoonPhase.fraction(on: monthLater), 0, accuracy: 0.001)

        // Waxing before full, waning after: the first quarter is lit on the
        // opposite limb from the last.
        XCTAssertLessThan(MoonPhase.fraction(on: new.addingTimeInterval(86_400 * 7)), 0.5)
        XCTAssertGreaterThan(MoonPhase.fraction(on: new.addingTimeInterval(86_400 * 22)), 0.5)
    }

    // MARK: - Turning the plot

    /// Four renders each, settled 18 September against billboards that always
    /// face the viewer. A plant has a front and a back, and every plant here is
    /// a meeting with somebody.
    ///
    /// The turn is of the **plot's own axes**: the plant and the light rotate
    /// together, because both are drawn in plot space and the sun goes round the
    /// plot rather than round the screen.
    @MainActor
    func testAPlantTurnsWithThePlotAndComesBackAfterFour() throws {
        let plant = crossing("Ada", nonce: 2)
        let growth = plant.growth(now: plant.birth.addingTimeInterval(400 * 86_400))

        var seen: [Data] = []
        for turn in 0..<GardenSprites.turns {
            let sprite = try XCTUnwrap(
                GardenSprites.shared.sprite(genome: plant.genome, growth: growth,
                                            step: 4, turn: turn)
            )
            seen.append(try XCTUnwrap(sprite.image.pngData()))
        }

        for (a, b) in [(0, 1), (0, 2), (1, 3)] {
            XCTAssertNotEqual(seen[a], seen[b], "turns \(a) and \(b) drew the same plant")
        }

        // Four quarters is all the way round, so the key has to come back to
        // where it started rather than growing without limit.
        XCTAssertEqual(
            GardenSprites.key(genome: plant.genome, growth: growth, step: 4, turn: 4),
            GardenSprites.key(genome: plant.genome, growth: growth, step: 4, turn: 0)
        )
        XCTAssertEqual(
            GardenSprites.key(genome: plant.genome, growth: growth, step: 4, turn: -1),
            GardenSprites.key(genome: plant.genome, growth: growth, step: 4, turn: 3)
        )
    }

    /// The light turns with the plot, and comes back.
    func testTheSunTurnsWithThePlotRatherThanWithTheScreen() {
        let noon = GardenGround.Light.at(hour: 12)

        XCTAssertEqual(simd_distance(noon.turned(quarters: 0).direction, noon.direction),
                       0, accuracy: 1e-12)
        XCTAssertEqual(simd_distance(noon.turned(quarters: 4).direction, noon.direction),
                       0, accuracy: 1e-9)

        // A quarter turn swaps the two ground axes, and the height is untouched
        // because the plot turns about its own middle.
        let quarter = noon.turned(quarters: 1)
        XCTAssertEqual(quarter.direction.y, noon.direction.y, accuracy: 1e-12)
        XCTAssertEqual(quarter.direction.x, noon.direction.z, accuracy: 1e-9)
        XCTAssertEqual(quarter.direction.z, -noon.direction.x, accuracy: 1e-9)
        XCTAssertEqual(simd_length(quarter.direction), 1, accuracy: 1e-9)

        // And nothing else about the light is a direction, so nothing else moves.
        XCTAssertEqual(quarter.strength, noon.strength)
        XCTAssertEqual(quarter.isDay, noon.isDay)
    }

    /// The bank under the plot is the only part of the cut anybody ever sees, so
    /// it has to be soil at the top and rock at the bottom rather than one
    /// colour — and none of it may break the ceiling.
    func testTheCutIsSoilAtTheTopAndRockAtTheBottom() {
        let top = GardenGround.cutColour(down: 0.02, grain: 0.5, stones: 0)
        let middle = GardenGround.cutColour(down: 0.35, grain: 0.5, stones: 0)
        let bottom = GardenGround.cutColour(down: 0.95, grain: 0.5, stones: 0)

        func warmth(_ c: SIMD3<Double>) -> Double { c.x - c.z }
        XCTAssertLessThan(top.x, middle.x, "the humus is not darker than the earth under it")
        XCTAssertLessThan(warmth(bottom), warmth(middle), "the rock is as brown as the soil")

        for down in stride(from: 0.0, through: 1.0, by: 0.05) {
            for grain in [0.0, 0.3, 0.7, 1.0] {
                var saturation: CGFloat = 0
                UIColor(GardenGround.underCeiling(
                    GardenGround.cutColour(down: down, grain: grain, stones: grain)
                )).getHue(nil, saturation: &saturation, brightness: nil, alpha: nil)
                XCTAssertLessThanOrEqual(Double(saturation),
                                         GardenGround.saturationCeiling + 1e-6)
            }
        }
    }

    /// The bank is the whole of what *thick* means, because the bulge under the
    /// middle is never drawn at this angle.
    func testTheCutIsDeepEnoughToReadAsGround() {
        XCTAssertGreaterThanOrEqual(GardenGround.rimDepth, 0.9)
        XCTAssertEqual(GardenGround.cutDepth(x: 2.6, z: 0, plotSide: 5.2),
                       GardenGround.rimDepth, accuracy: 1e-9)
    }

    /// **A garden you cannot see is not a garden.** The moon's curve is right
    /// and is still pinned above — 18:00 is the darkest hour of the day — and the
    /// Milky Way is what keeps that hour from being a black screen. Held as a
    /// floor on the ground's own brightness at every quarter-hour, and as nothing
    /// at all at noon, because the sky outshines it.
    func testTheGardenCanBeSeenAtTheDarkestHour() {
        let up = SIMD3<Double>(0, 1, 0)

        for quarter in 0..<96 {
            let light = GardenGround.Light.at(hour: Double(quarter) / 4)
            let lit = GardenGround.shaded(base: GardenGround.turf, normal: up, light: light)
            let luminance = 0.2126 * lit.x + 0.7152 * lit.y + 0.0722 * lit.z
            XCTAssertGreaterThan(luminance, 0.06,
                                 "the ground is black at \(Double(quarter) / 4):00")
        }

        XCTAssertEqual(simd_length(GardenGround.Light.at(hour: 12).galaxy), 0, accuracy: 1e-9)
        XCTAssertGreaterThan(simd_length(GardenGround.Light.at(hour: 18).galaxy), 0.4)
    }

    // MARK: - Gestures

    /// Putting a plant down under a finger is the inverse of drawing it, at every
    /// quarter the plot can be turned to. A turn that the forward projection
    /// knows and the inverse does not would drop every plant in the mirror image
    /// of where it was put — and on the first turn only, which is the one nobody
    /// tests.
    func testAPlaceSurvivesBeingDrawnAndReadBackAtEveryTurn() {
        for turn in 0..<4 {
            var turned = view
            turned.turn = turn
            for spot in [Spot(x: 1.2, z: -0.4), Spot(x: -2.1, z: 2.3), Spot(x: 0, z: 0)] {
                let back = turned.ground(at: turned.point(spot))
                XCTAssertEqual(back.x, spot.x, accuracy: 1e-9, "turn \(turn)")
                XCTAssertEqual(back.z, spot.z, accuracy: 1e-9, "turn \(turn)")
            }
        }
    }

    /// **The ground and the plants have to be turned the same way.** The plot is
    /// projected through `Isometric.facing`; a plant and its light are rendered
    /// through `Light.turned`. If those two disagree about which way is a
    /// quarter-turn, every plant on a turned plot is lit and faced as if the plot
    /// had gone the other way — plausible, and wrong.
    func testThePlotAndItsPlantsTurnTheSameWay() {
        let direction = GardenGround.Light.at(hour: 9).direction
        for turn in 0..<4 {
            var turned = view
            turned.turn = turn
            let plot = turned.facing(x: direction.x, z: direction.z)
            let plant = GardenGround.Light.at(hour: 9).turned(quarters: turn).direction
            XCTAssertEqual(plot.x, plant.x, accuracy: 1e-9, "turn \(turn)")
            XCTAssertEqual(plot.z, plant.z, accuracy: 1e-9, "turn \(turn)")
        }
    }

    /// Near is a fact about the screen. Once the plot is turned half way round,
    /// what was at the back is at the front.
    func testWhatIsNearTurnsWithThePlot() {
        let back = Spot(x: -2, z: -2), front = Spot(x: 2, z: 2)
        var turned = view
        XCTAssertLessThan(turned.depth(back), turned.depth(front))
        turned.turn = 2
        XCTAssertGreaterThan(turned.depth(back), turned.depth(front))
    }

    /// **Finding the place needs the height, and the height needs the place** —
    /// and on a steep peak there are two places under one point of the screen,
    /// the face you can see and one behind it. Two passes of a fixed-point search
    /// dropped a plant eight centimetres from the finger on the alpine world, and
    /// more passes did not help, because it had found the hidden one.
    ///
    /// Held three ways: what is found draws exactly under the finger; it is never
    /// behind the place that was aimed at, since behind is out of sight; and where
    /// the place aimed at is the visible one, it is found to within a centimetre.
    func testAPlantDroppedOnAHillLandsOnTheGroundYouCanSee() throws {
        let worlds = GardenWorlds.shared
        try XCTSkipUnless(worlds.isLoaded, "the world atlas is not in this bundle")

        let side = GardenWorlds.drawnForSide
        let relief = worlds.relief(world: 2, plotSide: side)
        func height(_ spot: Spot) -> Double {
            worlds.height(world: 2, x: spot.x, z: spot.z, plotSide: side)
        }

        var landedOnTheSpot = 0
        for x in stride(from: -2.2, through: 2.2, by: 0.55) {
            for z in stride(from: -2.2, through: 2.2, by: 0.55) {
                let spot = Spot(x: x, z: z)
                let finger = view.point(spot, y: height(spot))
                let found = view.ground(at: finger, height: height,
                                        between: relief.low, and: relief.high)

                let drawn = view.point(found, y: height(found))
                XCTAssertLessThan(hypot(drawn.x - finger.x, drawn.y - finger.y), 0.5,
                                  "what was found is not under the finger")
                XCTAssertGreaterThanOrEqual(view.depth(found), view.depth(spot) - 1e-4,
                                            "it found a place hidden behind the one aimed at")

                if hypot(found.x - spot.x, found.z - spot.z) < 0.01 { landedOnTheSpot += 1 }
            }
        }

        // Most of the plot is not hidden behind anything, so most drops land on
        // the spot exactly. The rest landed on the face in front of it.
        XCTAssertGreaterThan(landedOnTheSpot, 60)
    }
}
