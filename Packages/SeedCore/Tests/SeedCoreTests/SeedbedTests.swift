import XCTest
@testable import SeedCore

/// The sixth area: drills sown one kind to a drill, filling from the label.
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
    /// that claims it needs.
    func testAnUnclaimedDrillIsNeitherElement() {
        var ways = Seedbed.Ways()
        XCTAssertNil(ways.isWater(0, in: 0))
        XCTAssertNil(ways.kind(of: 0, in: 0))
        ways.plant(seed: SeedMint.mint(fromEntropy: Data("sb-element".utf8)),
                   traits: Self.lotus("rubra"))
        XCTAssertEqual(ways.isWater(0, in: 0), true)
        XCTAssertNil(ways.isWater(1, in: 0))
    }

    /// **A lily and a dry plant of one kind take a drill each.** The lily
    /// arrives first here, so the dry plant of the same epithet passes the
    /// flooded drill by and claims the next one rather than wading in.
    func testALilyAndADryPlantOfOneKindDoNotShareADrill() {
        var ways = Seedbed.Ways()
        let seed = { (n: Int) in SeedMint.mint(fromEntropy: Data("sb-share-\(n)".utf8)) }
        let lily = ways.plant(seed: seed(0), traits: Self.lotus("rubra"))
        XCTAssertEqual(lily.slot, Seedbed.Slot(drill: 0, index: 0))
        let dry = ways.plant(seed: seed(1), traits: Self.dry("rubra"))
        XCTAssertEqual(dry.slot, Seedbed.Slot(drill: 1, index: 0))
        // And each joins its own drill from then on, in either order.
        XCTAssertEqual(ways.plant(seed: seed(2), traits: Self.dry("rubra")).slot,
                       Seedbed.Slot(drill: 1, index: 1))
        XCTAssertEqual(ways.plant(seed: seed(3), traits: Self.lotus("rubra")).slot,
                       Seedbed.Slot(drill: 0, index: 2))
        XCTAssertEqual(ways.isWater(0, in: 0), true)
        XCTAssertEqual(ways.isWater(1, in: 0), false)
    }

    func testADrillFillsFromTheLabelWithNoGaps() {
        let ways = Self.full
        for plot in 0..<ways.plots {
            for drill in 0..<Seedbed.drills {
                let taken = ways.plot(plot).filter { $0.slot.drill == drill }.flatMap(\.slots).map(\.index).sorted()
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

    /// Every lotus holds two neighbouring places in one drill and stands at
    /// their middle; every other plant holds one and stands on it.
    func testALotusStandsCentredAcrossTwoPlaces() {
        let ways = Self.full
        var lotuses = 0
        for p in ways.plantings {
            let isLotus = p.traits.habit == Archetype.lotus.rawValue
            XCTAssertEqual(p.span, isLotus ? 2 : 1, "\(p.seed) holds \(p.span) places")
            XCTAssertLessThanOrEqual(p.slot.index + p.span, Seedbed.places, "\(p.seed) runs off its drill")
            let first = p.slots.first!.spot, last = p.slots.last!.spot
            XCTAssertEqual(p.spot.z - p.nudge.z, (first.z + last.z) / 2, accuracy: 1e-12)
            XCTAssertEqual(p.spot.x - p.nudge.x, first.x, accuracy: 1e-12)
            if isLotus { lotuses += 1 }
        }
        XCTAssertGreaterThan(lotuses, 120, "a sample of this area's own plants is more than a third lotuses")
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
    func testNoStemStandsInsideALotussPads() {
        let genomes = [Ambassadors.of(.beginnings).genome] + Self.genomes()
        let plants = zip(Self.full.plantings, genomes).map { (p, g) in (seed: p.seed, plot: p.plot, spot: p.spot, genome: g) }
        let crowded = LotusPads.crowded(plants, growth: { Maturity.bloomPreview(for: $0) })
        let stems = Set(crowded.map(\.stem)).count
        print("SEEDBED: \(stems) stems inside a lotus's pads")
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
                    let gap = abs(other.spot.z - lotus.spot.z)
                    let least = (1 + Double(other.span) / 2) * Seedbed.alongGap - 0.12
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
        let first = ways.plant(seed: seed(0), traits: Self.lotus("rubra"))
        XCTAssertEqual(first.slots, [Seedbed.Slot(drill: 0, index: 0), Seedbed.Slot(drill: 0, index: 1)])
        let second = ways.plant(seed: seed(1), traits: Self.lotus("rubra"))
        XCTAssertEqual(second.slot, Seedbed.Slot(drill: 0, index: 2))
        XCTAssertEqual(ways.sown(0, in: 0), 4)
        // A dry plant of the same epithet passes the water by.
        let dry = ways.plant(seed: seed(2), traits: Self.dry("rubra"))
        XCTAssertEqual(dry.slot, Seedbed.Slot(drill: 1, index: 0))
    }

    /// **A drill's last single place is no place for a lotus**, which goes on
    /// as a plant finding the drill full does — to an unclaimed drill — and
    /// the place waits for a plant of one of that kind.
    ///
    /// Asked of a flooded drill, since 27 September 2026: a lotus never sees
    /// a dry drill's last place at all, so a dry drill could no longer show
    /// this. Seven lilies fill a drill to its seventh place, one place short.
    func testTheLastPlaceOfADrillWaitsForAPlantOfOne() throws {
        let seed = { (n: Int) in SeedMint.mint(fromEntropy: Data("sb-last-\(n)".utf8)) }
        // Seven lilies of one kind, each holding one place, which is how the
        // rule before 25 September sowed them: planted, then read back with
        // the span stripped, as `Self.withoutSpans` does it.
        var ways = Seedbed.Ways()
        for n in 0..<7 {
            ways.plant(seed: seed(n), traits: Self.lotus("rubra"))
            ways = try Self.withoutSpans(ways)
        }
        XCTAssertEqual(ways.sown(0, in: 0), 7)
        XCTAssertEqual(ways.isWater(0, in: 0), true)
        // One place left, and a lotus needs two, so it claims the next drill —
        // claimed for its kind and for its element.
        let lotus = ways.plant(seed: seed(7), traits: Self.lotus("rubra"))
        XCTAssertEqual(lotus.slots, [Seedbed.Slot(drill: 1, index: 0), Seedbed.Slot(drill: 1, index: 1)])
        XCTAssertEqual(ways.kind(of: 1, in: 0), "rubra", "the drill it claims is claimed for its kind")
        XCTAssertEqual(ways.isWater(1, in: 0), true, "and for its element")
        // **The place it passed over waits for a plant of one, and after the
        // replant there are none.** Only lilies go in water and every lily
        // takes two, so a flooded drill's odd place can only come from a row
        // written before 25 September. The next lily takes the next pair in
        // the new drill rather than squeezing in behind.
        let after = ways.plant(seed: seed(8), traits: Self.lotus("rubra"))
        XCTAssertEqual(after.slots, [Seedbed.Slot(drill: 1, index: 2), Seedbed.Slot(drill: 1, index: 3)])
        XCTAssertEqual(ways.sown(0, in: 0), 7, "the odd place is still empty")
    }

    /// **A flooded drill divides exactly**: eight places, two to a lily, four
    /// lilies and nothing left over. The odd place the test above leaves is a
    /// thing only the old rule could make.
    func testAFloodedDrillHoldsFourLilies() {
        var ways = Seedbed.Ways()
        let seed = { (n: Int) in SeedMint.mint(fromEntropy: Data("sb-four-\(n)".utf8)) }
        for n in 0..<4 {
            let lily = ways.plant(seed: seed(n), traits: Self.lotus("rubra"))
            XCTAssertEqual(lily.slot, Seedbed.Slot(drill: 0, index: n * 2))
        }
        XCTAssertEqual(ways.sown(0, in: 0), Seedbed.places)
        // The fifth claims the next drill, also flooded.
        let fifth = ways.plant(seed: seed(4), traits: Self.lotus("rubra"))
        XCTAssertEqual(fifth.slot, Seedbed.Slot(drill: 1, index: 0))
        XCTAssertEqual(ways.isWater(1, in: 0), true)
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
        // It holds place 0 alone, so the next lily of its kind takes 1 and 2.
        let lotus = ways.plant(seed: seed(1), traits: Self.lotus("rubra"))
        XCTAssertEqual(lotus.slots.map(\.index), [1, 2])
        // **A dry plant of the same epithet still passes the water by**, and
        // an old row says which element its drill is as plainly as a new one:
        // the habit was stored with it.
        let dry = ways.plant(seed: seed(2), traits: Self.dry("rubra"))
        XCTAssertEqual(dry.slot, Seedbed.Slot(drill: 1, index: 0))
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
