import XCTest
@testable import SeedCore

/// The sixth area: drills on the contour, sown one kind to a drill from the
/// drill's middle, the dry kinds at the head of the bed and the water at its foot.
final class SeedbedTests: XCTestCase {

    // MARK: Arrivals

    /// **Five hundred plants whose names put them in the Seedbed**, as
    /// `ColdFrameTests` draws the Cold Frame's, since 25 September 2026.
    ///
    /// Until then any crossing would do: the rule read only a kind and the
    /// order of arrival, and neither cared which area a name belonged to. Now
    /// it reads the habit too, and the area's own plants are more than a third
    /// lotuses where the garden's are one in twelve, so a sample of any
    /// crossing would measure a lotus rule that hardly ever runs.
    ///
    /// **Since 28 September 2026 the reed's root `Don` is this area's too**,
    /// and a reed wants water. Of the five hundred below, 140 are lotuses and
    /// 122 reeds, so a little over half of them go in flooded drills; the
    /// garden's lotuses are one in fourteen now.
    private static let found = crossings(500)
    private static let sample: [(SeedID, PlantTraits)] = found.map { ($0.seed, LongWalk.traits(of: $0.genome)) }

    static func arrivals(_ count: Int = 500) -> [(SeedID, PlantTraits)] {
        count <= sample.count ? Array(sample.prefix(count)) : crossings(count).map { ($0.seed, LongWalk.traits(of: $0.genome)) }
    }

    static func genomes(_ count: Int = 500) -> [Genome] {
        count <= found.count ? found.prefix(count).map(\.genome) : crossings(count).map(\.genome)
    }

    private static func crossings(_ count: Int) -> [(seed: SeedID, genome: Genome)] {
        var found: [(seed: SeedID, genome: Genome)] = []
        var n = 0
        while found.count < count {
            let a = SeedMint.mint(fromEntropy: Data("seedbed-arrival-\(n)-a".utf8))
            let b = SeedMint.mint(fromEntropy: Data("seedbed-arrival-\(n)-b".utf8))
            n += 1
            let meeting = Pollination.encounterID(seedA: a, seedB: b,
                                                  nonceA: Data("a".utf8), nonceB: Data("b".utf8))
            let child = Pollination.cross(seedA: a, seedB: b, encounterID: meeting)
            let genome = Genome(seed: child,
                                lineage: .crossed(parentA: a, parentB: b, encounterID: meeting))
            if Area(genome: genome) == .beginnings { found.append((child, genome)) }
        }
        return found
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
            // The places held, not the plants: a lotus holds two.
            let held = ways.plot(plot).flatMap(\.slots)
            XCTAssertLessThanOrEqual(held.count, 48, "plot \(plot) is overfull")
            XCTAssertEqual(Set(held).count, held.count, "two plants hold one place in plot \(plot)")
        }
    }

    func testEveryPlaceStandsInTheBedWithRoomToKneelRound() {
        let edge = Seedbed.plotSide / 2
        for slot in Seedbed.slots {
            XCTAssertLessThan(abs(slot.spot.x) + 0.06, edge - 0.5, "place \(slot.index) is at the rim")
            XCTAssertLessThan(abs(slot.spot.z) + 0.035, edge - 0.5, "drill \(slot.drill) is at the rim")
        }
        // Each label stands beyond its drill's first place, at its west end,
        // and inside the bed. **Measured along the drill since it curved
        // more**, on 2 October 2026: at the foot a drill's ends turn down the
        // bed, so its label is a third of a metre before its first place but
        // much less than that to the west of it.
        for drill in 0..<Seedbed.drills {
            let label = Seedbed.label(of: drill)
            let first = Seedbed.Slot(drill: drill, index: 0).spot, last = Seedbed.Slot(drill: drill, index: 7).spot
            let toFirst = ((label.x - first.x) * (label.x - first.x) + (label.z - first.z) * (label.z - first.z)).squareRoot()
            let toLast = ((label.x - last.x) * (label.x - last.x) + (label.z - last.z) * (label.z - last.z)).squareRoot()
            XCTAssertGreaterThan(toFirst, 0.3, "drill \(drill)'s label crowds its first place")
            XCTAssertGreaterThan(toLast, toFirst + 2.5, "drill \(drill)'s label is not at its head")
            XCTAssertLessThan(label.x, first.x, "drill \(drill)'s label is not at its west end")
            XCTAssertGreaterThan(label.x, -edge + 0.2, "drill \(drill)'s label is at the rim")
            XCTAssertLessThan(abs(label.z), edge - 0.2, "drill \(drill)'s label is at the rim")
        }
    }

    /// **The drills are on the contour**: each is an arc, curving the same way
    /// as the one beside it, and they stand `drillGap` apart all along their
    /// length: 0.74 m until they curved more on 2 October 2026.
    ///
    /// **And every one of them reads as an arc**, the dry drills at the head
    /// included: each bows more than 0.32 m over its eight places, where at
    /// 0.74 m apart the top drill bowed 0.17 m and read nearly straight.
    func testTheDrillsFollowTheContour() {
        for drill in 0..<Seedbed.drills {
            let ends = (Seedbed.Slot(drill: drill, index: 0).spot, Seedbed.Slot(drill: drill, index: 7).spot)
            let middle = Seedbed.Slot(drill: drill, index: 4).spot
            // Bowed toward the head of the bed: its middle higher than its ends.
            XCTAssertLessThan(middle.z, min(ends.0.z, ends.1.z) - 0.1, "drill \(drill) is not bowed")
            // How far the drill stands off the straight line between its ends.
            let ax = ends.1.x - ends.0.x, az = ends.1.z - ends.0.z
            let chord = (ax * ax + az * az).squareRoot()
            let bow = (0..<Seedbed.places).map { i -> Double in
                let p = Seedbed.Slot(drill: drill, index: i).spot
                return abs(ax * (ends.0.z - p.z) - az * (ends.0.x - p.x)) / chord
            }.max()!
            XCTAssertGreaterThan(bow, 0.32, "drill \(drill) reads nearly straight")
            guard drill > 0 else { continue }
            for index in 0..<Seedbed.places {
                let here = Seedbed.Slot(drill: drill, index: index).spot
                let nearest = (0..<Seedbed.places).map { i -> Double in
                    let there = Seedbed.Slot(drill: drill - 1, index: i).spot
                    return ((here.x - there.x) * (here.x - there.x) + (here.z - there.z) * (here.z - there.z)).squareRoot()
                }.min()!
                XCTAssertGreaterThan(nearest, Seedbed.drillGap - 0.06, "drill \(drill) crowds the one above it")
            }
        }
        // And the water is low: the last drill is the foot of the bed.
        XCTAssertGreaterThan(Seedbed.Slot(drill: 5, index: 4).spot.z,
                             Seedbed.Slot(drill: 0, index: 4).spot.z + 5 * Seedbed.drillGap - 0.1)
    }

    /// How far a point stands from a drill's line, in the table.
    private static func offLine(_ spot: Spot, drill: Int) -> Double {
        let line = Seedbed.table.curve("drill\(drill)", on: PlotVariant.plain).points
        var best = Double.infinity
        for (a, b) in zip(line, line.dropFirst()) {
            let ax = b.x - a.x, az = b.z - a.z
            let t = max(0, min(1, ((spot.x - a.x) * ax + (spot.z - a.z) * az) / (ax * ax + az * az)))
            let dx = spot.x - a.x - ax * t, dz = spot.z - a.z - az * t
            best = min(best, (dx * dx + dz * dz).squareRoot())
        }
        return best
    }

    func testADrillIsALineAndNoTwoPlantsCrowd() {
        let ways = Self.full
        for plot in 0..<ways.plots {
            let here = ways.plot(plot)
            let variant = Seedbed.variant(of: plot)
            for p in here {
                // Read back into the table, then measured from its drill's line.
                let off = Self.offLine(variant.undo(p.spot), drill: p.slot.drill)
                XCTAssertLessThanOrEqual(off, 0.06, "\(p.seed) wanders off drill \(p.slot.drill) of plot \(plot)")
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

    /// **A drill is dry or it is under water, and never half of each.** An
    /// epithet says what is most so about a plant rather than what it is, so
    /// two plants of one kind can want different ground — *rubra* is red and
    /// a water lily can be red. The element is the second half of the claim.
    ///
    /// **More water than tilth since 28 September 2026: 67 drills flooded and
    /// 52 dry**, where the dry had the majority. The reed wants water and its
    /// root `Don` is this area's, so 262 of these five hundred want a flooded
    /// drill — 140 lotuses at two places each and 122 reeds at one — against
    /// 238 that want tilth. The rule is doing what it says: an epithet claims
    /// a drill of each element it arrives in. The floor that stays is that
    /// the tilth is not swamped: at least three dry drills to every four
    /// flooded, which is what was measured (0.78).
    func testADrillIsAllWaterOrAllDry() {
        let ways = Self.full
        var wet = 0, dry = 0
        for plot in 0..<ways.plots {
            for drill in 0..<Seedbed.drills {
                let here = ways.plot(plot).filter { $0.slot.drill == drill }
                guard let first = here.first else { continue }
                let elements = Set(here.map(\.traits.wantsWater))
                XCTAssertEqual(elements.count, 1,
                               "drill \(drill) of plot \(plot) is half flooded")
                XCTAssertEqual(ways.isWater(drill, in: plot), first.traits.wantsWater)
                if first.traits.wantsWater { wet += 1 } else { dry += 1 }
            }
        }
        print("SEEDBED: \(wet) drills under water, \(dry) dry")
        XCTAssertGreaterThan(wet, 0, "half of this area's arrivals want water")
        XCTAssertGreaterThan(Double(dry) / Double(wet), 0.75, "the tilth is swamped by the water")
    }

    /// An unclaimed drill is neither element, and becomes whichever the plant
    /// that claims it needs. A lily claims the lowest, at the foot of the bed.
    func testAnUnclaimedDrillIsNeitherElement() {
        var ways = Seedbed.Ways()
        XCTAssertNil(ways.isWater(5, in: 0))
        XCTAssertNil(ways.kind(of: 5, in: 0))
        ways.plant(seed: SeedMint.mint(fromEntropy: Data("sb-element".utf8)),
                   traits: Self.lotus("rubra"))
        XCTAssertEqual(ways.isWater(5, in: 0), true)
        XCTAssertNil(ways.isWater(4, in: 0))
        XCTAssertNil(ways.isWater(0, in: 0))
    }

    /// The first place a drill is sown in, for a plant of one place or a lily.
    private static func first(_ drill: Int, wet: Bool) -> Int {
        wet ? Seedbed.wetOrder[drill][0] : Seedbed.dryOrder[drill][0]
    }

    /// **A lily and a dry plant of one kind take a drill each**, and from
    /// opposite sides of the bed: the lily the lowest drill and the dry plant
    /// the highest, so the dry plant passes the water by rather than wading in.
    func testALilyAndADryPlantOfOneKindDoNotShareADrill() {
        var ways = Seedbed.Ways()
        let seed = { (n: Int) in SeedMint.mint(fromEntropy: Data("sb-share-\(n)".utf8)) }
        let lily = ways.plant(seed: seed(0), traits: Self.lotus("rubra"))
        XCTAssertEqual(lily.slot, Seedbed.Slot(drill: 5, index: Self.first(5, wet: true)))
        let dry = ways.plant(seed: seed(1), traits: Self.dry("rubra"))
        XCTAssertEqual(dry.slot, Seedbed.Slot(drill: 0, index: Self.first(0, wet: false)))
        // And each joins its own drill from then on, in either order.
        XCTAssertEqual(ways.plant(seed: seed(2), traits: Self.dry("rubra")).slot,
                       Seedbed.Slot(drill: 0, index: Seedbed.dryOrder[0][1]))
        XCTAssertEqual(ways.plant(seed: seed(3), traits: Self.lotus("rubra")).slot,
                       Seedbed.Slot(drill: 5, index: Seedbed.wetOrder[5][2]))
        XCTAssertEqual(ways.isWater(5, in: 0), true)
        XCTAssertEqual(ways.isWater(0, in: 0), false)
    }

    /// **A drill is sown from its middle**, since 2 October 2026: a dry
    /// drill's places are taken in the table's order, the one nearest its
    /// middle first and then farthest-first, so what is sown is always the
    /// start of that order with nothing skipped. A flooded drill is sown in
    /// pairs, and the pairs it has touched are always the first in its order:
    /// a lily passes a pair a reed has half taken, and the next reed fills it.
    func testADrillIsSownInItsOwnOrder() {
        let ways = Self.full
        for plot in 0..<ways.plots {
            for drill in 0..<Seedbed.drills {
                let here = ways.plot(plot).filter { $0.slot.drill == drill }
                guard let first = here.first else { continue }
                let taken = Set(here.flatMap(\.slots).map(\.index))
                if first.traits.wantsWater {
                    let pairs = Seedbed.wetOrder[drill].map { $0 / 2 }
                    var order: [Int] = []
                    for pair in pairs where !order.contains(pair) { order.append(pair) }
                    let touched = Set(taken.map { $0 / 2 })
                    XCTAssertEqual(touched, Set(order.prefix(touched.count)),
                                   "flooded drill \(drill) of plot \(plot) is sown \(taken.sorted())")
                } else {
                    XCTAssertEqual(taken, Set(Seedbed.dryOrder[drill].prefix(taken.count)),
                                   "drill \(drill) of plot \(plot) is sown \(taken.sorted())")
                }
            }
        }
    }

    /// **Dry kinds claim from the head of the bed and water kinds from its
    /// foot**, so the flooded drills lie together. Replayed in the order the
    /// plants arrived: each drill claimed was the highest nobody had sown for a
    /// dry plant and the lowest for a lily or a reed.
    func testTheDrillsAreClaimedFromTheirOwnSideOfTheBed() {
        let ways = Self.full
        for plot in 0..<ways.plots {
            var unclaimed = Set(0..<Seedbed.drills)
            for p in ways.plot(plot) where unclaimed.contains(p.slot.drill) {
                let expected = p.traits.wantsWater ? unclaimed.max()! : unclaimed.min()!
                XCTAssertEqual(p.slot.drill, expected, "\(p.seed) claimed drill \(p.slot.drill) of plot \(plot)")
                unclaimed.remove(p.slot.drill)
            }
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
                            traits: PlantTraits(height: 0.42, family: traits.family, kind: traits.kind,
                                                habit: traits.habit))
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
                            traits: PlantTraits(height: traits.height, family: 3, kind: traits.kind,
                                                habit: traits.habit))
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
        // **A kind and an element claim one drill between them**, since 27
        // September 2026: one epithet can claim two drills in a plot, but
        // only by being a lily in one and a dry plant in the other.
        let claimed = (0..<Seedbed.drills).compactMap { drill -> (String, Bool)? in
            guard let kind = ways.kind(of: drill, in: 0), let wet = ways.isWater(drill, in: 0)
            else { return nil }
            return (kind, wet)
        }
        XCTAssertEqual(Set(claimed.map { "\($0.0)/\($0.1)" }).count, claimed.count,
                       "a kind and an element claimed two drills in one plot")
        for (kind, _) in claimed {
            XCTAssertTrue(arrivals.prefix(40).contains { $0.1.kind == kind }
                          || Ambassadors.of(.beginnings).genome.name.epithet == kind,
                          "\(kind) claimed a drill without arriving")
        }
    }

    // MARK: A lotus takes two places

    private static func lotus(_ kind: String) -> PlantTraits {
        PlantTraits(height: 0.3, family: 1, kind: kind, habit: Archetype.lotus.rawValue)
    }

    /// The same kind that wants dry tilth: a fern, which shares an epithet
    /// with a lily as readily as anything else does.
    private static func dry(_ kind: String) -> PlantTraits {
        PlantTraits(height: 0.3, family: 1, kind: kind, habit: Archetype.fern.rawValue)
    }

    /// A reed: it wants water as a lily does and takes one place.
    private static func reed(_ kind: String) -> PlantTraits {
        PlantTraits(height: 0.6, family: 1, kind: kind, habit: Archetype.reed.rawValue)
    }

    /// A planting's nudge as it is laid in the table: along its drill where
    /// it stands and across it, since the drills curved more on 2 October 2026.
    private static func laid(_ p: Seedbed.Planting) -> Spot {
        let along = Seedbed.along(drill: p.slot.drill, index: p.slot.index, span: p.span)
        return Spot(x: p.nudge.x * along.x - p.nudge.z * along.z, z: p.nudge.x * along.z + p.nudge.z * along.x)
    }

    /// Every lotus holds two neighbouring places in one drill and stands at
    /// their middle; every other plant holds one and stands on it. Read back
    /// into the table, since a plot may be mirrored.
    func testALotusStandsCentredAcrossTwoPlaces() {
        let ways = Self.full
        var lotuses = 0
        for p in ways.plantings {
            let isLotus = p.traits.habit == Archetype.lotus.rawValue
            XCTAssertEqual(p.span, isLotus ? 2 : 1, "\(p.seed) holds \(p.span) places")
            XCTAssertLessThanOrEqual(p.slot.index + p.span, Seedbed.places, "\(p.seed) runs off its drill")
            if isLotus { XCTAssertEqual(p.slot.index % 2, 0, "\(p.seed) holds two places of different pairs") }
            let first = p.slots.first!.spot, last = p.slots.last!.spot
            let at = Seedbed.variant(of: p.plot).undo(p.spot), laid = Self.laid(p)
            XCTAssertEqual(at.x - laid.x, (first.x + last.x) / 2, accuracy: 1e-12)
            XCTAssertEqual(at.z - laid.z, (first.z + last.z) / 2, accuracy: 1e-12)
            if isLotus { lotuses += 1 }
        }
        XCTAssertGreaterThan(lotuses, 120, "a sample of this area's own plants is more than a third lotuses")
    }

    /// **Plots alternate**: every other plot is the plan mirrored across the
    /// bed, so its labels stand at the east end; the water stays low.
    func testPlotsAreMirroredAlternately() {
        XCTAssertEqual(Seedbed.variant(of: 0), .plain)
        for plot in 1..<8 {
            let variant = Seedbed.variant(of: plot)
            XCTAssertEqual(variant.turn, 0)
            XCTAssertEqual(variant.mirror, plot % 2 == 1)
        }
        let ways = Self.full
        for p in ways.plantings where p.plot % 2 == 1 {
            let at = p.slots.map(\.spot).reduce(0) { $0 + $1.x } / Double(p.span)
            XCTAssertEqual(p.spot.x, -(at + Self.laid(p).x), accuracy: 1e-12)
        }
    }

    /// **The reason for the rule, held as a test**: of five hundred plants
    /// drawn as the page draws them, one in twelve stood with its stem inside
    /// a lotus's pads, and now one does.
    ///
    /// **The one is across a drill, where the rule does not reach.** Two
    /// lotuses side by side in neighbouring drills, 0.69 m apart, and one of
    /// them among the widest tenth. Places along a drill are what a lotus
    /// takes two of; the drills stay 0.74 m apart, as Marcus chose. The
    /// simulation he chose from found the same kind of case, a lotus over a
    /// lotus in the next drill.
    ///
    /// **Three since the drills curved on 2 October 2026**: the one across a
    /// drill, and two reeds sown in the place beside a lily's pair, each
    /// nudged toward the lily, 0.69 m from its stem. That is the 0.78 m a
    /// lotus has had to the next stem along its drill since 25 September,
    /// less the two nudges, and the widest tenth of pads reach it; the
    /// straight bed's sample happened not to put a reed there.
    ///
    /// **Five since the drills came to 0.60 m apart**, later on 2 October
    /// 2026, when Marcus chose *curve more, narrower gaps*: one along a drill,
    /// a reed beside a lily's pair as above, and four across one. Those four
    /// are lilies with a lily or a reed beside them in the next drill,
    /// 0.54–0.65 m apart where the drills had 0.74 m between them, so the
    /// wider pads now reach across. Two are in one plot whose water climbed
    /// to the second drill. Five is the bar. The rule along a drill is
    /// untouched: a lotus still takes two places.
    func testNoStemStandsInsideALotussPads() {
        let genomes = [Ambassadors.of(.beginnings).genome] + Self.genomes()
        let plants = zip(Self.full.plantings, genomes).map { (p, g) in (seed: p.seed, plot: p.plot, spot: p.spot, genome: g) }
        let crowded = LotusPads.crowded(plants, growth: { Maturity.bloomPreview(for: $0) })
        let stems = Set(crowded.map(\.stem)).count
        let drill = Dictionary(uniqueKeysWithValues: Self.full.plantings.map { ($0.seed, $0.slot.drill) })
        let along = crowded.filter { drill[$0.lotus] == drill[$0.stem] }.count
        print("SEEDBED: \(stems) stems inside a lotus's pads, \(along) of them along a drill")
        XCTAssertLessThanOrEqual(stems, plants.count / 100, crowded.prefix(5).map(\.description).joined(separator: "; "))
    }

    /// No stem stands between the two places a lotus holds, or nearer its own
    /// than a place and a half, less the two nudges along the drill.
    func testNoStemStandsInALotussPair() {
        let ways = Self.full
        for plot in 0..<ways.plots {
            let here = ways.plot(plot)
            for lotus in here where lotus.span == 2 {
                for other in here where other.seed != lotus.seed && other.slot.drill == lotus.slot.drill {
                    let dx = other.spot.x - lotus.spot.x, dz = other.spot.z - lotus.spot.z
                    let gap = (dx * dx + dz * dz).squareRoot()
                    // Less the two nudges along the drill, and a centimetre
                    // for the chord of a curved drill being shorter than it.
                    let least = (1 + Double(other.span) / 2) * Seedbed.alongGap - 0.13
                    XCTAssertGreaterThanOrEqual(gap, least - 1e-12, "\(other.seed) stands in \(lotus.seed)'s pair")
                }
            }
        }
    }

    /// The second place a lotus holds is never given to a later plant. Asked
    /// of two lilies, since a dry plant of the same kind now takes a drill of
    /// its own rather than the place after it.
    func testALotussSecondPlaceIsNeverGivenAway() {
        var ways = Seedbed.Ways()
        let seed = { (n: Int) in SeedMint.mint(fromEntropy: Data("sb-lotus-\(n)".utf8)) }
        let pair = Seedbed.wetOrder[5]
        let first = ways.plant(seed: seed(0), traits: Self.lotus("rubra"))
        XCTAssertEqual(first.slots, [Seedbed.Slot(drill: 5, index: pair[0]), Seedbed.Slot(drill: 5, index: pair[1])])
        let second = ways.plant(seed: seed(1), traits: Self.lotus("rubra"))
        XCTAssertEqual(second.slot, Seedbed.Slot(drill: 5, index: pair[2]))
        XCTAssertEqual(ways.sown(5, in: 0), 4)
        // A dry plant of the same epithet passes the water by.
        let dry = ways.plant(seed: seed(2), traits: Self.dry("rubra"))
        XCTAssertEqual(dry.slot, Seedbed.Slot(drill: 0, index: Self.first(0, wet: false)))
    }

    /// **A drill's last single place is no place for a lotus**, which goes on
    /// as a plant finding the drill full does — to an unclaimed drill — and
    /// the place waits for a plant of one of that kind.
    ///
    /// Asked of a flooded drill, since 27 September 2026: a lotus never sees
    /// a dry drill's last place at all, so a dry drill could no longer show
    /// this. Seven reeds of one kind, a place each, fill a flooded drill to one
    /// short, and the place left is half of a pair a reed has the other half of.
    func testTheLastPlaceOfADrillWaitsForAPlantOfOne() throws {
        let seed = { (n: Int) in SeedMint.mint(fromEntropy: Data("sb-last-\(n)".utf8)) }
        var ways = Seedbed.Ways()
        for n in 0..<7 {
            let reed = ways.plant(seed: seed(n), traits: Self.reed("rubra"))
            XCTAssertEqual(reed.slot, Seedbed.Slot(drill: 5, index: Seedbed.wetOrder[5][n]),
                           "two reeds share a pair before a third opens another")
        }
        XCTAssertEqual(ways.sown(5, in: 0), 7)
        XCTAssertEqual(ways.isWater(5, in: 0), true)
        // One place left, and a lotus needs two, so it claims the next drill
        // up — claimed for its kind and for its element.
        let lotus = ways.plant(seed: seed(7), traits: Self.lotus("rubra"))
        let pair = Seedbed.wetOrder[4]
        XCTAssertEqual(lotus.slots, [Seedbed.Slot(drill: 4, index: pair[0]), Seedbed.Slot(drill: 4, index: pair[1])])
        XCTAssertEqual(ways.kind(of: 4, in: 0), "rubra", "the drill it claims is claimed for its kind")
        XCTAssertEqual(ways.isWater(4, in: 0), true, "and for its element")
        // **The place it passed over waits for a plant of one**, and the next
        // reed of that kind takes it.
        XCTAssertEqual(ways.sown(5, in: 0), 7, "the odd place is still empty")
        let eighth = ways.plant(seed: seed(8), traits: Self.reed("rubra"))
        XCTAssertEqual(eighth.slot, Seedbed.Slot(drill: 5, index: Seedbed.wetOrder[5][7]))
        XCTAssertEqual(ways.sown(5, in: 0), Seedbed.places)
    }

    /// **A flooded drill divides exactly**: eight places, two to a lily, four
    /// lilies and nothing left over. Sown in pairs from the middle of the drill.
    func testAFloodedDrillHoldsFourLilies() {
        var ways = Seedbed.Ways()
        let seed = { (n: Int) in SeedMint.mint(fromEntropy: Data("sb-four-\(n)".utf8)) }
        for n in 0..<4 {
            let lily = ways.plant(seed: seed(n), traits: Self.lotus("rubra"))
            XCTAssertEqual(lily.slot, Seedbed.Slot(drill: 5, index: Seedbed.wetOrder[5][n * 2]))
        }
        XCTAssertEqual(ways.sown(5, in: 0), Seedbed.places)
        // The fifth claims the next drill up, also flooded.
        let fifth = ways.plant(seed: seed(4), traits: Self.lotus("rubra"))
        XCTAssertEqual(fifth.slot, Seedbed.Slot(drill: 4, index: Self.first(4, wet: true)))
        XCTAssertEqual(ways.isWater(4, in: 0), true)
    }

    /// **The orders change which places are taken and never how many.** The
    /// straight bed sowed a drill from its label; a flooded drill sown that way
    /// takes a lily while `(8 − reeds) / 2` lilies fit, and sown in pairs it
    /// takes one while a whole pair is free, which is the same number. So for
    /// every mix of reeds and lilies arriving into one flooded drill, the two
    /// orders let in the same plants and turn away the same ones.
    func testSowingInPairsHoldsWhatSowingFromTheLabelHeld() {
        for mask in 0..<(1 << 9) {
            var ways = Seedbed.Ways()
            var label = 0   // the next place from the label, as the straight bed sowed
            for n in 0..<9 {
                let lily = mask & (1 << n) != 0
                let seed = SeedMint.mint(fromEntropy: Data("sb-mix-\(mask)-\(n)".utf8))
                let p = ways.plant(seed: seed, traits: lily ? Self.lotus("rubra") : Self.reed("rubra"))
                let fitted = label + (lily ? 2 : 1) <= Seedbed.places
                if fitted { label += lily ? 2 : 1 }
                XCTAssertEqual(p.slot.drill == 5, fitted, "mix \(mask), plant \(n): the two orders disagree")
            }
        }
    }

    /// The area as a store written before 25 September holds it: every
    /// planting with its span stripped, so each holds the one place it was
    /// sown in. `Planting.init(from:)` reads a missing span as one.
    private static func withoutSpans(_ ways: Seedbed.Ways) throws -> Seedbed.Ways {
        var json = String(decoding: try JSONEncoder().encode(ways), as: UTF8.self)
        json = json.replacingOccurrences(of: #""span":2,"#, with: "")
            .replacingOccurrences(of: #","span":2"#, with: "")
            .replacingOccurrences(of: #""span":1,"#, with: "")
            .replacingOccurrences(of: #","span":1"#, with: "")
        return try JSONDecoder().decode(Seedbed.Ways.self, from: Data(json.utf8))
    }

    /// **A planting stored before 25 September holds the one place it was
    /// sown in**, lotus or not, until the replant sows it again.
    func testAPlantingStoredBeforeTheRuleHoldsOnePlace() throws {
        var old = Seedbed.Ways()
        let seed = { (n: Int) in SeedMint.mint(fromEntropy: Data("sb-old-\(n)".utf8)) }
        // A lily, stored without a span, which is how the old rule stored it.
        old.plant(seed: seed(0), traits: Self.lotus("rubra"))
        var ways = try Self.withoutSpans(old)
        XCTAssertEqual(ways.plantings[0].span, 1)
        // It holds the first place of its pair alone, so the next lily of its
        // kind passes that pair by and takes the next whole one.
        let pair = Seedbed.wetOrder[5]
        let lotus = ways.plant(seed: seed(1), traits: Self.lotus("rubra"))
        XCTAssertEqual(lotus.slots.map(\.index), [pair[2], pair[3]])
        // **A dry plant of the same epithet still passes the water by**, and
        // an old row says which element its drill is as plainly as a new one:
        // the habit was stored with it.
        let dry = ways.plant(seed: seed(2), traits: Self.dry("rubra"))
        XCTAssertEqual(dry.slot, Seedbed.Slot(drill: 0, index: Self.first(0, wet: false)))
    }

    // MARK: The ambassador

    /// The ambassador is a spire, so it claims the top drill, on the dry side
    /// of the bed, and stands at its middle, where a drill is sown from.
    func testTheAmbassadorStandsInTheMiddleOfTheTopDrill() {
        let one = Seedbed.ambassador
        XCTAssertEqual(one.plot, 0)
        XCTAssertEqual(one.slot, Seedbed.Slot(drill: 0, index: Self.first(0, wet: false)))
        XCTAssertEqual(one.seed, Ambassadors.of(.beginnings).seed.hex)
        XCTAssertFalse(one.traits.kind.isEmpty, "the first drill is claimed by nothing")
        XCTAssertEqual(Seedbed.Ways.opened().plantings, [one])
    }

    // MARK: The outcome

    /// Five hundred of the area's own plants, 173 of them lotuses, take
    /// nineteen plots with 73% of every place held. The simulation Marcus
    /// chose the lotus rule from gave nineteen too, and fifteen without it.
    ///
    /// **Twenty-one plots and 66% since the drills were flooded** on 27
    /// September 2026. **The two plots are what the water costs, and they are
    /// the price of the whole feature**: an epithet that arrives as both a
    /// lily and a dry plant now claims a drill of each, so a plot claims 124
    /// drills where it claimed 112 and fills 57 where it filled 66. Nothing
    /// else moved — a lotus holds the same two places it held on 25
    /// September, and they are now two places of water.
    func testHowFiveHundredLandOnTheSeedbed() {
        let ways = Self.full
        var claimed = 0, full = 0, flooded = 0
        for plot in 0..<ways.plots {
            for drill in 0..<Seedbed.drills where ways.kind(of: drill, in: plot) != nil {
                claimed += 1
                if ways.sown(drill, in: plot) == Seedbed.places { full += 1 }
                if ways.isWater(drill, in: plot) == true { flooded += 1 }
            }
        }
        let held = ways.plantings.map(\.span).reduce(0, +)
        let capacity = ways.plots * 48
        let lotuses = ways.plantings.filter { $0.span == 2 }.count
        print("SEEDBED: \(ways.plantings.count) plants, \(lotuses) lotuses, \(ways.plots) plots, \(claimed) drills claimed, "
              + "\(flooded) of them flooded, \(full) full, \(held * 100 / capacity)% of places held")
        XCTAssertEqual(ways.plantings.count, 501)
        XCTAssertLessThanOrEqual(ways.plots, 22)
        XCTAssertGreaterThan(full, 30, "hardly a drill filled")
        XCTAssertGreaterThan(held * 100 / capacity, 60, "the bed is too empty to read")
        // **The water is a third of the bed**, which is the share of arrivals
        // that are lilies: a wet row here is ordinary, not an ornament.
        // **Over half since 28 September 2026** — 67 of 119 drills, 56% —
        // because reeds want water too; twenty plots, 66% of places held.
        // Inside the bounds, and close to the upper one.
        XCTAssertGreaterThan(flooded * 100 / claimed, 30)
        XCTAssertLessThan(flooded * 100 / claimed, 60)
    }
}
