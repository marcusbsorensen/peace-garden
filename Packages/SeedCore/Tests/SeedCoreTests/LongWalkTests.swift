import XCTest
@testable import SeedCore

/// The Long Walk's rule: where an arriving plant goes, and that it stays there.
final class LongWalkTests: XCTestCase {

    private func seed(_ label: String) -> SeedID {
        SeedID(bytes: seedDigest(SeedDomain.seed, Data(label.utf8)))!
    }

    /// Arrivals with the height and colour a real garden has, without building
    /// three hundred meshes: heights drawn over the measured range, with the
    /// same thirds, and colours spread across the families.
    private func arrivals(_ count: Int) -> [(SeedID, LongWalk.Traits)] {
        var random = SplitMix64(seed: 2026)
        return (0..<count).map { n in
            let u = Double(random.next() % 10_000) / 10_000
            // Piecewise through the measured centiles: 0.21, 0.85 at a third,
            // 1.19 at two thirds, 2.22 at the top.
            let height = u < 1 / 3 ? 0.21 + u * 3 * 0.64
                : u < 2 / 3 ? 0.85 + (u - 1 / 3) * 3 * 0.34
                : 1.19 + (u - 2 / 3) * 3 * 1.03
            let family = Int(random.next() % 7)
            return (seed("arrival-\(n)"), LongWalk.Traits(height: height, family: family))
        }
    }

    private func walk(_ count: Int) -> LongWalk.Walk {
        var walk = LongWalk.Walk()
        for (seed, traits) in arrivals(count) { walk.plant(seed: seed, traits: traits) }
        return walk
    }

    // MARK: - Nothing moves

    /// **A plant never moves once planted**, whatever arrives after it. This is
    /// the one property the seed-derived grid existed to give, and the reason
    /// the walk is append-only.
    func testAPlantedPlantNeverMoves() {
        var walk = LongWalk.Walk()
        var before: [LongWalk.Planting] = []
        for (seed, traits) in arrivals(240) {
            walk.plant(seed: seed, traits: traits)
            XCTAssertEqual(Array(walk.plantings.prefix(before.count)), before,
                           "planting one more moved one already there")
            before = walk.plantings
        }
    }

    /// And the whole walk survives the file it is stored as.
    func testTheWalkRoundTrips() throws {
        let walk = walk(60)
        let back = try JSONDecoder().decode(LongWalk.Walk.self, from: JSONEncoder().encode(walk))
        XCTAssertEqual(back, walk)
    }

    // MARK: - The border

    /// **Nothing stands in front of something shorter than itself**, anywhere
    /// in the walk — the rule the rows exist to keep, checked plant by plant.
    func testNothingStandsInFrontOfSomethingShorter() {
        let walk = walk(300)
        for planting in walk.plantings {
            for other in walk.plot(planting.plot) where other.slot.side == planting.slot.side
                && other.slot.tier.rawValue > planting.slot.tier.rawValue
                && abs(other.slot.spot.z - planting.slot.spot.z) <= LongWalk.Walk.driftReach {
                XCTAssertLessThanOrEqual(planting.traits.height, other.traits.height,
                                         "a plant of \(planting.traits.height) m in front of one of \(other.traits.height) m")
            }
        }
    }

    /// And a plant is out of its own tier only by one row, never front to back.
    func testAPlantIsNeverMoreThanOneRowFromItsTier() {
        for planting in walk(300).plantings {
            XCTAssertLessThanOrEqual(abs(planting.slot.tier.rawValue - planting.traits.tier.rawValue), 1)
        }
    }

    /// No two plants in one slot.
    func testNoSlotIsTakenTwice() {
        let walk = walk(300)
        for plot in 0..<walk.plots {
            let slots = walk.plot(plot).map(\.slot)
            XCTAssertEqual(slots.count, Set(slots).count, "plot \(plot) has a slot taken twice")
        }
    }

    /// Everything stands in the border and not on the path or in the hedge.
    func testEverythingStandsInTheBorder() {
        for planting in walk(300).plantings {
            let out = abs(planting.spot.x)
            XCTAssertGreaterThan(out, LongWalk.pathHalfWidth, "a plant on the path")
            XCTAssertLessThan(out, LongWalk.hedgeFrom, "a plant in the hedge")
            XCTAssertLessThan(abs(planting.spot.z), LongWalk.plotSide / 2, "a plant off the end of its plot")
        }
    }

    /// **Plots fill before the walk goes on.** Measured at six hundred
    /// arrivals, with two rows a tier: every plot but the newest four is full,
    /// 48 of 48, and those four are the walk's growing end (39, 17, 13 and 3).
    /// At one row a tier it was the newest three at three hundred. Filling by
    /// row alone left eleven plots of the first fifteen at six to nine plants.
    func testPlotsFillBeforeTheWalkGoesOn() {
        let walk = walk(600)
        let perPlot = LongWalk.slots.count
        XCTAssertEqual(perPlot, 48)
        let settled = (0..<max(0, walk.plots - 4)).map { walk.plot($0).count }
        XCTAssertGreaterThan(settled.count, 8)
        for (plot, count) in settled.enumerated() {
            XCTAssertEqual(count, perPlot, "plot \(plot) left with \(count) of \(perPlot)")
        }
    }

    // MARK: - Drifts

    /// **Drifts, not dots.** Most plants stand next to another of their colour,
    /// and no drift runs past five, where a sweep becomes a block.
    func testColourGathersIntoDriftsOfAtMostFive() {
        let walk = walk(300)
        var inDrift = 0
        for plot in 0..<walk.plots {
            let here = walk.plot(plot)
            for planting in here {
                let size = walk.driftSize(from: planting, in: here)
                XCTAssertLessThanOrEqual(size, 5, "a drift of \(size) in plot \(plot)")
                if size >= 2 { inDrift += 1 }
            }
        }
        XCTAssertGreaterThan(Double(inDrift) / Double(walk.plantings.count), 0.5,
                             "only \(inDrift) of \(walk.plantings.count) plants stand in a drift")
    }

    // MARK: - Reading a real plant

    /// A real crossing's traits: a grown height in the measured range and a
    /// colour family that exists.
    func testARealPlantHasTraitsTheRuleCanUse() {
        let a = seed("walker-a"), b = seed("walker-b")
        let encounter = Pollination.encounterID(seedA: a, seedB: b,
                                                nonceA: Data("a".utf8), nonceB: Data("b".utf8))
        let child = Pollination.cross(seedA: a, seedB: b, encounterID: encounter)
        let genome = Genome(seed: child, lineage: .crossed(parentA: a, parentB: b, encounterID: encounter))
        let traits = LongWalk.traits(of: genome)
        XCTAssertTrue((0.15...2.6).contains(traits.height), "height \(traits.height)")
        XCTAssertTrue((0...LongWalk.paleFamily).contains(traits.family))
    }

    /// The cuts, where the measurement put them.
    func testTheTiersAreCutWhereTheyWereMeasured() {
        XCTAssertEqual(LongWalk.tier(height: 0.5), .edge)
        XCTAssertEqual(LongWalk.tier(height: 0.92), .edge)
        XCTAssertEqual(LongWalk.tier(height: 0.93), .middle)
        XCTAssertEqual(LongWalk.tier(height: 1.27), .middle)
        XCTAssertEqual(LongWalk.tier(height: 1.28), .back)
        XCTAssertEqual(LongWalk.family(hue: 0.1, saturation: 0.1), LongWalk.paleFamily)
        XCTAssertEqual(LongWalk.family(hue: 0.99, saturation: 0.8), 5)
        XCTAssertEqual(LongWalk.family(hue: 350, saturation: 0.8), 5)
    }
}
