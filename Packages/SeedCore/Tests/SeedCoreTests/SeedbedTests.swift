import XCTest
@testable import SeedCore

/// The sixth area: drills sown one kind to a drill, filling from the label.
final class SeedbedTests: XCTestCase {

    // MARK: Arrivals

    private static let sample: [(SeedID, PlantTraits)] = make(500)

    static func arrivals(_ count: Int = 500) -> [(SeedID, PlantTraits)] {
        count <= sample.count ? Array(sample.prefix(count)) : make(count)
    }

    private static func make(_ count: Int) -> [(SeedID, PlantTraits)] {
        (0..<count).map { n in
            let a = SeedMint.mint(fromEntropy: Data("seedbed-arrival-\(n)-a".utf8))
            let b = SeedMint.mint(fromEntropy: Data("seedbed-arrival-\(n)-b".utf8))
            let meeting = Pollination.encounterID(seedA: a, seedB: b,
                                                  nonceA: Data("a".utf8), nonceB: Data("b".utf8))
            let child = Pollination.cross(seedA: a, seedB: b, encounterID: meeting)
            let genome = Genome(seed: child,
                                lineage: .crossed(parentA: a, parentB: b, encounterID: meeting))
            return (child, LongWalk.traits(of: genome))
        }
    }

    static func filled(_ count: Int = 500) -> Seedbed.Ways {
        var ways = Seedbed.Ways.opened()
        for (seed, traits) in arrivals(count) { ways.plant(seed: seed, traits: traits) }
        return ways
    }

    private static let full: Seedbed.Ways = filled()

    // MARK: The bed

    func testAPlotHoldsSixDrillsOfEightAndNoMore() {
        XCTAssertEqual(Seedbed.slots.count, 48)
        XCTAssertEqual(Set(Seedbed.slots).count, 48)
        let ways = Self.full
        for plot in 0..<ways.plots {
            XCTAssertLessThanOrEqual(ways.plot(plot).count, 48, "plot \(plot) is overfull")
            XCTAssertEqual(Set(ways.plot(plot).map(\.slot)).count, ways.plot(plot).count,
                           "two plants in one place in plot \(plot)")
        }
    }

    func testEveryPlaceStandsInTheBedWithRoomToKneelRound() {
        let edge = Seedbed.plotSide / 2
        for slot in Seedbed.slots {
            XCTAssertLessThan(abs(slot.spot.x) + 0.035, edge - 0.5, "drill \(slot.drill) is at the rim")
            XCTAssertLessThan(abs(slot.spot.z) + 0.06, edge - 0.5, "place \(slot.index) is at the rim")
        }
        // The label stands beyond the first plant and inside the bed.
        XCTAssertLessThan(Seedbed.labelAt, Seedbed.slots[0].spot.z - 0.2)
        XCTAssertGreaterThan(Seedbed.labelAt, -edge + 0.2)
    }

    func testADrillIsALineAndNoTwoPlantsCrowd() {
        let ways = Self.full
        for plot in 0..<ways.plots {
            let here = ways.plot(plot)
            for drill in 0..<Seedbed.drills {
                let across = here.filter { $0.slot.drill == drill }.map(\.spot.x)
                guard let low = across.min(), let high = across.max() else { continue }
                XCTAssertLessThanOrEqual(high - low, 0.07 + 1e-12,
                                         "drill \(drill) of plot \(plot) wanders across itself")
            }
            for a in here.indices {
                for b in (a + 1)..<here.count {
                    let dx = here[a].spot.x - here[b].spot.x, dz = here[a].spot.z - here[b].spot.z
                    XCTAssertGreaterThan((dx * dx + dz * dz).squareRoot(), 0.39,
                                         "two plants crowd in plot \(plot)")
                }
            }
        }
    }

    // MARK: The rule

    func testADrillHoldsOneKindOnly() {
        let ways = Self.full
        for plot in 0..<ways.plots {
            for drill in 0..<Seedbed.drills {
                let kinds = Set(ways.plot(plot).filter { $0.slot.drill == drill }.map(\.traits.kind))
                XCTAssertLessThanOrEqual(kinds.count, 1,
                                         "drill \(drill) of plot \(plot) holds \(kinds)")
            }
        }
    }

    func testADrillFillsFromTheLabelWithNoGaps() {
        let ways = Self.full
        for plot in 0..<ways.plots {
            for drill in 0..<Seedbed.drills {
                let taken = ways.plot(plot).filter { $0.slot.drill == drill }.map(\.slot.index).sorted()
                XCTAssertEqual(taken, Array(0..<taken.count),
                               "drill \(drill) of plot \(plot) is sown \(taken)")
            }
        }
    }

    func testTheDrillsAreSownInTheirOwnOrderWithinAPlot() {
        let ways = Self.full
        for plot in 0..<ways.plots {
            let claimed = Set(ways.plot(plot).map(\.slot.drill)).sorted()
            XCTAssertEqual(claimed, Array(0..<claimed.count),
                           "plot \(plot) claimed drills \(claimed) out of order")
        }
    }

    func testNoOlderPlotIsLeftWithAnUnclaimedDrill() {
        let ways = Self.full
        guard ways.plots > 1 else { return XCTFail("five hundred should open more than one plot") }
        for plot in 0..<(ways.plots - 1) {
            for drill in 0..<Seedbed.drills {
                XCTAssertNotNil(ways.kind(of: drill, in: plot),
                                "drill \(drill) of plot \(plot) was passed over")
            }
        }
    }

    /// The whole of what makes this area different: a height decides nothing.
    func testAPlantsHeightChangesNothing() {
        var asGrown = Seedbed.Ways.opened()
        var flattened = Seedbed.Ways.opened()
        for (seed, traits) in Self.arrivals() {
            asGrown.plant(seed: seed, traits: traits)
            flattened.plant(seed: seed,
                            traits: PlantTraits(height: 0.42, family: traits.family, kind: traits.kind))
        }
        XCTAssertEqual(asGrown.plantings.map(\.plot), flattened.plantings.map(\.plot))
        XCTAssertEqual(asGrown.plantings.map(\.slot), flattened.plantings.map(\.slot))
    }

    /// Nor does a colour: the Knot Garden's question is not this one.
    func testAPlantsColourChangesNothing() {
        var asGrown = Seedbed.Ways.opened()
        var oneColour = Seedbed.Ways.opened()
        for (seed, traits) in Self.arrivals() {
            asGrown.plant(seed: seed, traits: traits)
            oneColour.plant(seed: seed,
                            traits: PlantTraits(height: traits.height, family: 3, kind: traits.kind))
        }
        XCTAssertEqual(asGrown.plantings.map(\.slot), oneColour.plantings.map(\.slot))
    }

    func testAPlantNeverMoves() {
        let ways = Self.full
        var replayed = Seedbed.Ways.opened()
        for (n, (seed, traits)) in Self.arrivals().enumerated() {
            let planting = replayed.plant(seed: seed, traits: traits)
            XCTAssertEqual(planting.plot, ways.plantings[n + 1].plot, "arrival \(n) moved plots")
            XCTAssertEqual(planting.slot, ways.plantings[n + 1].slot, "arrival \(n) moved places")
        }
    }

    /// A kind that has not arrived holds nothing. Were a drill reserved for
    /// every kind, forty-six kinds would want more drills than a plot has.
    func testARareKindClaimsADrillOnlyWhenItArrives() {
        var ways = Seedbed.Ways.opened()
        let arrivals = Self.arrivals()
        for (seed, traits) in arrivals.prefix(40) { ways.plant(seed: seed, traits: traits) }
        let claimed = (0..<Seedbed.drills).compactMap { ways.kind(of: $0, in: 0) }
        XCTAssertEqual(Set(claimed).count, claimed.count, "a kind claimed two drills in one plot")
        for kind in claimed {
            XCTAssertTrue(arrivals.prefix(40).contains { $0.1.kind == kind }
                          || Ambassadors.of(.beginnings).genome.name.epithet == kind,
                          "\(kind) claimed a drill without arriving")
        }
    }

    // MARK: The ambassador

    func testTheAmbassadorStandsAtTheHeadOfTheFirstDrill() {
        let one = Seedbed.ambassador
        XCTAssertEqual(one.plot, 0)
        XCTAssertEqual(one.slot, Seedbed.Slot(drill: 0, index: 0))
        XCTAssertEqual(one.seed, Ambassadors.of(.beginnings).seed.hex)
        XCTAssertFalse(one.traits.kind.isEmpty, "the first drill is claimed by nothing")
        XCTAssertEqual(Seedbed.Ways.opened().plantings, [one])
    }

    // MARK: The outcome

    func testHowFiveHundredLandOnTheSeedbed() {
        let ways = Self.full
        var claimed = 0, full = 0
        for plot in 0..<ways.plots {
            for drill in 0..<Seedbed.drills where ways.kind(of: drill, in: plot) != nil {
                claimed += 1
                if ways.sown(drill, in: plot) == Seedbed.places { full += 1 }
            }
        }
        let held = ways.plantings.count
        let capacity = ways.plots * 48
        print("SEEDBED: \(held) plants, \(ways.plots) plots, \(claimed) drills claimed, "
              + "\(full) full, \(held * 100 / capacity)% of places held")
        XCTAssertEqual(held, 501)
        XCTAssertGreaterThan(full, 30, "hardly a drill filled")
        XCTAssertGreaterThan(held * 100 / capacity, 60, "the bed is too empty to read")
    }
}
