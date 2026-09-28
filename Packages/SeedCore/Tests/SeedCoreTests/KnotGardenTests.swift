import XCTest
@testable import SeedCore

/// The fifth area's rule: eight compartments in four mirror pairs, a colour to
/// a pair, and four plants graded outward in each.
///
/// **This is the first suite that has to ask about colour.** The other four
/// areas grade by height, and a height is a number that spreads smoothly over a
/// population; a colour family is one of seven buckets and they are not
/// equally full. A rule that hands a pair to a colour can therefore fail in a
/// way none of the others could — by claiming pairs faster than it fills them —
/// and the fill at five hundred is the number that would have sent the design
/// back.
final class KnotGardenTests: XCTestCase {

    /// Five hundred real crossings, which is what `docs/WEB-GARDENS.md` says a
    /// template is judged at. Cached: reading a plant's traits builds its mesh.
    private static let sample: [(SeedID, PlantTraits)] = make(500)

    static func arrivals(_ count: Int = 500) -> [(SeedID, PlantTraits)] {
        count <= sample.count ? Array(sample.prefix(count)) : make(count)
    }

    private static func make(_ count: Int) -> [(SeedID, PlantTraits)] {
        (0..<count).map { n in
            let a = SeedMint.mint(fromEntropy: Data("knot-arrival-\(n)-a".utf8))
            let b = SeedMint.mint(fromEntropy: Data("knot-arrival-\(n)-b".utf8))
            let meeting = Pollination.encounterID(seedA: a, seedB: b,
                                                  nonceA: Data("a".utf8), nonceB: Data("b".utf8))
            let child = Pollination.cross(seedA: a, seedB: b, encounterID: meeting)
            let genome = Genome(seed: child,
                                lineage: .crossed(parentA: a, parentB: b, encounterID: meeting))
            return (child, LongWalk.traits(of: genome))
        }
    }

    private static let full: KnotGarden.Ways = {
        var ways = KnotGarden.Ways.opened()
        for (seed, traits) in arrivals() { ways.plant(seed: seed, traits: traits) }
        return ways
    }()

    static func filled(_ count: Int = 500) -> KnotGarden.Ways {
        if count == 500 { return full }
        var ways = KnotGarden.Ways.opened()
        for (seed, traits) in arrivals(count) { ways.plant(seed: seed, traits: traits) }
        return ways
    }

    // MARK: The plot holds what it says it holds

    func testAPlotHoldsThirtyTwoPlantsAndNoMore() {
        XCTAssertEqual(KnotGarden.slots.count, 32)
        XCTAssertEqual(Set(KnotGarden.slots).count, 32)
        let ways = Self.filled()
        for plot in 0..<ways.plots {
            let here = ways.plot(plot)
            XCTAssertLessThanOrEqual(here.count, 32, "plot \(plot) holds \(here.count)")
            XCTAssertEqual(Set(here.map(\.slot)).count, here.count,
                           "plot \(plot) has two plants in one place")
        }
    }

    func testEveryCompartmentHoldsFourGradedOneTwoOne() {
        for compartment in KnotGarden.Compartment.allCases {
            let block = KnotGarden.slots.filter { $0.compartment == compartment }
            XCTAssertEqual(block.count, 4)
            XCTAssertEqual(block.filter { $0.rank == .heart }.count, 1)
            XCTAssertEqual(block.filter { $0.rank == .side }.count, 2)
            XCTAssertEqual(block.filter { $0.rank == .point }.count, 1)
        }
    }

    /// Four compartments at the sides of the plot and four at its corners, and
    /// each one's mirror is the one opposite. Both fall out of the declaration
    /// order rather than out of a table, so this is what says the order is load
    /// bearing.
    func testTheEightAreFourSidesFourCornersAndFourMirrorPairs() {
        XCTAssertEqual(KnotGarden.Compartment.allCases.filter(\.atCorner).count, 4)
        XCTAssertEqual(KnotGarden.Compartment.allCases.filter { !$0.atCorner }.count, 4)
        for compartment in KnotGarden.Compartment.allCases {
            XCTAssertEqual(compartment.mirror.mirror, compartment)
            XCTAssertNotEqual(compartment.mirror, compartment)
            XCTAssertEqual(compartment.mirror.atCorner, compartment.atCorner,
                           "\(compartment) is mirrored by a compartment of the other kind")
            XCTAssertEqual(compartment.pair, compartment.mirror.pair)
        }
        for pair in KnotGarden.Pair.allCases {
            XCTAssertEqual(pair.compartments.count, 2)
            XCTAssertEqual(pair.compartments[0].mirror, pair.compartments[1])
            for compartment in pair.compartments { XCTAssertEqual(compartment.pair, pair) }
        }
        XCTAssertEqual(Set(KnotGarden.Compartment.allCases.map(\.pair)).count, 4)
    }

    /// A mirror pair stands opposite across the middle of the plot: the two
    /// places at one index are the same point turned half round. That is what
    /// makes a colour read as symmetric rather than as two blocks that happen
    /// to match.
    func testAMirrorPairsPlacesAreOppositeAcrossTheMiddle() {
        for compartment in KnotGarden.Compartment.allCases {
            for index in 0..<4 {
                let here = KnotGarden.Slot(compartment: compartment, index: index).spot
                let there = KnotGarden.Slot(compartment: compartment.mirror, index: index).spot
                XCTAssertEqual(there.x, -here.x, accuracy: 1e-9)
                XCTAssertEqual(there.z, -here.z, accuracy: 1e-9)
            }
        }
    }

    /// The geometry the ranks are a reading of: a place's rank has to agree
    /// with how far out it actually is, or `inOrder` orders plants by a fiction.
    func testRankAgreesWithDistanceFromTheMiddleOfThePlot() {
        func radius(_ slot: KnotGarden.Slot) -> Double {
            let s = slot.spot
            return (s.x * s.x + s.z * s.z).squareRoot()
        }
        for compartment in KnotGarden.Compartment.allCases {
            let block = KnotGarden.slots.filter { $0.compartment == compartment }
            let heart = block.first { $0.rank == .heart }!
            let sides = block.filter { $0.rank == .side }
            let point = block.first { $0.rank == .point }!
            XCTAssertLessThan(radius(heart), radius(sides[0]))
            // The two at one distance, which is what frees them from having to
            // be in order with each other.
            XCTAssertEqual(radius(sides[0]), radius(sides[1]), accuracy: 1e-9)
            XCTAssertLessThan(radius(sides[0]), radius(point))
        }
    }

    /// Every place stands inside its own compartment, between the knot's bands
    /// and the edging, with room for the nudge. **This is what says the
    /// canonical numbers are right** — they are written out by hand, so nothing
    /// derives them and nothing else would catch one mistyped.
    func testEveryPlaceIsInsideItsOwnCompartment() {
        let nudge = 0.09
        let inner = KnotGarden.bandFrom + KnotGarden.bandHalfThickness   // 0.87
        let between = KnotGarden.bandFrom - KnotGarden.bandHalfThickness // 0.65
        let outer = KnotGarden.edgingFrom - KnotGarden.bandHalfThickness // 2.09
        for slot in KnotGarden.slots {
            let s = slot.spot
            if slot.compartment.atCorner {
                // A corner compartment is the square between the two bands and
                // the edging's corner.
                XCTAssertGreaterThan(min(abs(s.x), abs(s.z)) - nudge, inner, "\(slot)")
                XCTAssertLessThan(max(abs(s.x), abs(s.z)) + nudge, outer, "\(slot)")
            } else {
                // A side compartment lies between the two bands running one way
                // and reaches from the crossing band out to the edging. Which
                // axis is which depends on the quarter turn, and the shorter of
                // the two distances is always the across-the-compartment one.
                let across = min(abs(s.x), abs(s.z)), along = max(abs(s.x), abs(s.z))
                XCTAssertLessThan(across + nudge, between, "\(slot)")
                XCTAssertGreaterThan(along - nudge, inner, "\(slot)")
                XCTAssertLessThan(along + nudge, outer, "\(slot)")
            }
        }
    }

    /// **No plant stands in the hedge, however it is nudged.** The bands bow
    /// now, and a bow eats into the room between a place and the band beside
    /// it — which is the whole price of curving the weave, and the number that
    /// says how far the arms may go.
    ///
    /// The margin the straight weave left was 0.18 m, and the nudge spends
    /// half of it. What is asserted here is what is left after both: a plant
    /// pushed as hard as the seed can push it still stands clear of the box.
    func testNoPlaceStandsInABandHoweverItIsNudged() {
        let nudge = 0.09
        var tightest = (Double.greatestFiniteMagnitude, "")
        for slot in KnotGarden.slots {
            let spot = slot.spot
            // The nudge is a square, so the corners of it are the hard cases.
            for dx in [-nudge, 0, nudge] {
                for dz in [-nudge, 0, nudge] {
                    let clear = KnotGarden.clearance(x: spot.x + dx, z: spot.z + dz)
                    if clear < tightest.0 { tightest = (clear, "\(slot)") }
                }
            }
        }
        XCTAssertGreaterThan(tightest.0, 0.03,
                             "a nudged plant stands \(tightest.0) m from a band: \(tightest.1)")
    }

    /// **Each run is three stretches end to end with one gap in it**, and the
    /// gap is at the crossing it dives under. Which of a run's two crossings
    /// that is differs between the run at `+bandFrom` and the one at
    /// `-bandFrom`, so this is the assertion that catches a run cut in the
    /// order its crossings are named rather than the order they lie in — which
    /// gives a stretch that spans the plot and one with its ends swapped, and
    /// still draws something that looks nearly right.
    func testEachRunIsThreeStretchesEndToEndWithOneGap() {
        let gap = 2 * (KnotGarden.bandHalfThickness - KnotGarden.tuck)
        var runs: [String: [KnotGarden.Stretch]] = [:]
        for stretch in KnotGarden.weave where abs(stretch.at) == KnotGarden.bandFrom {
            runs["\(stretch.alongX) \(stretch.at)", default: []].append(stretch)
        }
        XCTAssertEqual(runs.count, 4, "the knot is not four runs")
        for (name, stretches) in runs {
            XCTAssertEqual(stretches.count, 3, "\(name) is not in three")
            for stretch in stretches {
                XCTAssertGreaterThan(stretch.to - stretch.from, 0.5,
                                     "\(name) has a stretch of \(stretch.to - stretch.from) m")
            }
            XCTAssertEqual(stretches.first!.from, -KnotGarden.edgingFrom, accuracy: 0)
            XCTAssertEqual(stretches.last!.to, KnotGarden.edgingFrom, accuracy: 0)
            let gaps = zip(stretches, stretches.dropFirst()).map { $1.from - $0.to }
            XCTAssertEqual(gaps.filter { $0 > 1e-9 }.count, 1,
                           "\(name) is cut \(gaps.filter { $0 > 1e-9 }.count) times, not once")
            XCTAssertEqual(gaps.max()!, gap, accuracy: 1e-12, "\(name)'s gap is the wrong width")
            XCTAssertEqual(gaps.min()!, 0, accuracy: 1e-12, "\(name) has a second gap")
        }
    }

    /// **A bow is zero at every crossing**, which is what keeps the compartments
    /// where they were when the bands were straight — and therefore what keeps
    /// every plant already in the ground standing where it stands.
    func testTheBandsAreWhereTheyWereAtEveryCrossing() {
        for stretch in KnotGarden.weave {
            for end in [stretch.from, stretch.to] {
                XCTAssertEqual(stretch.line(at: end), stretch.at, accuracy: 0,
                               "a stretch stands off its own line at an end")
            }
            XCTAssertEqual(stretch.line(at: (stretch.from + stretch.to) / 2),
                           stretch.at + stretch.bow, accuracy: 0,
                           "a stretch does not stand off by its bow in the middle")
        }
        // The four inner stretches are the ones that bow in, and each of them
        // runs between the two crossings on one of the rule's own two lines.
        let inner = KnotGarden.weave.filter { abs($0.bow) == KnotGarden.knotBow }
        XCTAssertEqual(inner.count, 4, "the knot is not four inner stretches")
        for stretch in inner {
            XCTAssertEqual(abs(stretch.at), KnotGarden.bandFrom, accuracy: 0)
            XCTAssertLessThan(stretch.bow * stretch.at, 0, "an inner stretch bows outward")
        }
    }

    /// Two plants in one plot may not stand on top of each other. The closest
    /// pair here is tighter than any other area's, which is the price of
    /// thirty-two in the square — and the reason the nudge is the smallest in
    /// the garden.
    func testNoTwoPlacesInAPlotAreTooCloseTogether() {
        var closest = Double.greatestFiniteMagnitude
        for (i, a) in KnotGarden.slots.enumerated() {
            for b in KnotGarden.slots.dropFirst(i + 1) {
                let dx = a.spot.x - b.spot.x, dz = a.spot.z - b.spot.z
                closest = min(closest, (dx * dx + dz * dz).squareRoot())
            }
        }
        XCTAssertGreaterThan(closest, 0.55, "closest two places are \(closest) m apart")
    }

    // MARK: The rule the area is for

    /// **A pair holds one colour, for ever.** This is the whole of what
    /// *symmetrical* means once nothing is reserved: a pair is claimed by the
    /// first plant to stand in it and only plants of that colour may join it.
    func testAPairHoldsOneColourOnly() {
        let ways = Self.filled()
        for plot in 0..<ways.plots {
            let here = ways.plot(plot)
            for pair in KnotGarden.Pair.allCases {
                let block = here.filter { $0.slot.compartment.pair == pair }
                let families = Set(block.map(\.traits.family))
                XCTAssertLessThanOrEqual(families.count, 1,
                    "plot \(plot) pair \(pair) holds families \(families.sorted())")
            }
        }
    }

    /// **The two compartments of a pair fill together**, which is the Crossing's
    /// *wherever there is least* asked of two instead of four. A pair that
    /// filled one compartment and then the other would be one block of colour
    /// and one bare compartment for eight arrivals, which is not a mirror.
    ///
    /// *Not* "the two never differ by more than one" — that is false, and
    /// asserting it was this suite's first failure. A plant goes to the emptier
    /// compartment only if the emptier one has a free place **of the rank being
    /// tried** that it may stand in; a compartment whose remaining places are
    /// the wrong rank is passed over however empty it is. At five hundred
    /// exactly one pair of sixty-six ends uneven, at 4 and 2.
    ///
    /// So the rule is checked as the rule: replayed arrival by arrival, and
    /// every time a plant passes over the emptier compartment, that
    /// compartment had nothing of that rank to offer it. Replayed rather than
    /// read off the finished plot because *which of the two was emptier* is a
    /// fact about the moment, and the finished plot cannot say.
    func testAPairsTwoCompartmentsFillTogetherUnlessOneCannotTakeThePlant() {
        var ways = KnotGarden.Ways.opened()
        for (seed, traits) in Self.arrivals() {
            let (plot, slot) = ways.place(for: traits)
            let here = plot < ways.plots ? ways.plot(plot) : []
            let partner = slot.compartment.mirror
            let mine = here.filter { $0.slot.compartment == slot.compartment }
            let theirs = here.filter { $0.slot.compartment == partner }
            if theirs.count < mine.count {
                let taken = Set(here.map(\.slot))
                for free in KnotGarden.slots
                where free.compartment == partner && free.rank == slot.rank && !taken.contains(free) {
                    XCTAssertFalse(ways.inOrder(traits.height, at: free, among: theirs), """
                        a \(traits.height) m plant went to \(slot.compartment) holding \(mine.count) \
                        while \(partner) held \(theirs.count) with \(free.index) free
                        """)
                }
            }
            ways.plant(seed: seed, traits: traits)
        }
        let uneven = (0..<ways.plots).flatMap { plot in
            KnotGarden.Pair.allCases.filter { pair in
                let counts = pair.compartments.map { c in
                    ways.plot(plot).filter { $0.slot.compartment == c }.count
                }
                return abs(counts[0] - counts[1]) > 1
            }
        }
        XCTAssertLessThanOrEqual(uneven.count, 1, "\(uneven.count) pairs of the knot are uneven")
    }

    /// **An unclaimed pair is never passed over.** A plant that cannot join a
    /// pair of its own colour claims a fresh one in the oldest plot that has
    /// one, so a plot with an empty pair and a newer plot beside it holding
    /// anything at all is the rule having skipped a place it should have taken.
    func testAnUnclaimedPairIsNeverPassedOver() {
        let ways = Self.filled()
        for plot in 0..<(ways.plots - 1) {
            let here = ways.plot(plot)
            let unclaimed = KnotGarden.Pair.allCases.filter { ways.family(of: $0, in: plot) == nil }
            guard !unclaimed.isEmpty else { continue }
            // Anything that arrived after this plot's last planting would have
            // claimed one of them, since `place` scans plots oldest first.
            let last = ways.plantings.lastIndex { $0.plot == plot }!
            XCTAssertEqual(Array(ways.plantings[(last + 1)...]), [],
                "plot \(plot) left \(unclaimed) unclaimed although plants arrived after it")
            _ = here
        }
    }

    /// Nothing stands in front of something shorter than itself, read outward
    /// from the middle of the plot.
    func testNothingStandsInFrontOfSomethingShorter() {
        let ways = Self.filled()
        for plot in 0..<ways.plots {
            for compartment in KnotGarden.Compartment.allCases {
                let block = ways.plot(plot).filter { $0.slot.compartment == compartment }
                for a in block {
                    for b in block where a.slot.rank.rawValue < b.slot.rank.rawValue {
                        XCTAssertLessThanOrEqual(a.traits.height, b.traits.height,
                            "plot \(plot) \(compartment): \(a.traits.height) stands in front of \(b.traits.height)")
                    }
                }
            }
        }
    }

    func testAPlantNeverMoves() {
        let five = Self.filled(5)
        let fiveHundred = Self.filled()
        for early in five.plantings {
            let later = fiveHundred.plantings.first { $0.seed == early.seed }
            XCTAssertEqual(later, early, "a plant moved after it was planted")
        }
    }

    // MARK: The ambassador

    func testTheAmbassadorStandsInTheNorthCompartment() {
        let one = KnotGarden.ambassador
        XCTAssertEqual(one.plot, 0)
        XCTAssertEqual(one.slot.compartment, .north)
        XCTAssertEqual(one.slot.compartment.pair, .north)
        XCTAssertEqual(one.seed, Ambassadors.of(.pattern).seed.hex)
        // *Quinyria obscura*, since 28 September 2026, is 1.22 m: over the
        // 1.20 cut, so it reads as a point and takes index 3, the place at
        // the compartment's outer edge. (*Quina caerulea* was a side, index 1.)
        XCTAssertEqual(KnotGarden.rank(height: one.traits.height), .point)
        XCTAssertEqual(one.slot.index, 3)
        XCTAssertEqual(one.traits.family, 4)
    }

    func testTheAmbassadorIsTheOldestPlantInTheArea() {
        let ways = Self.filled()
        XCTAssertEqual(ways.plantings.first?.seed, KnotGarden.ambassador.seed)
    }

    /// **The colour the ambassador claims is claimed by nothing else in plot 0
    /// until its pair is full.** Said because it is the one thing a colour-led
    /// rule could get wrong about its own first plant: a pair claimed and then
    /// quietly re-claimed is a pair of two colours.
    func testTheAmbassadorsPairIsItsOwnColour() {
        let ways = Self.filled()
        XCTAssertEqual(ways.family(of: .north, in: 0), 4)
        for planting in ways.plot(0) where planting.slot.compartment.pair == .north {
            XCTAssertEqual(planting.traits.family, 4)
        }
    }

    // MARK: How it actually fills

    /// **The number that could have sent the design back**, and a record of it
    /// so a change that quietly wrecks the fill shows up as a diff.
    ///
    /// With seven colour families and four pairs to a plot, a rule that claimed
    /// pairs greedily would open a plot for every colour that turned up and
    /// leave the garden half empty. This one claims a pair only when a plant
    /// needs one, so the pairs claimed for a colour are as few as that colour's
    /// own numbers allow, and the waste is the last pair of each colour rather
    /// than one pair per colour per plot.
    ///
    /// **Measured: seventeen plots, sixty-six pairs claimed, fifty-six of them
    /// exactly full, and 92% of every place in the garden holding a plant.**
    /// The rarest colour is pale, nineteen plants of five hundred and one, and
    /// it claimed three pairs in the whole garden rather than one in every plot
    /// — which is what says the worry the brief raised was unfounded.
    ///
    /// **Eighteen plots and 87% since 28 September 2026**, where it was
    /// seventeen and more than nine tenths. The five hundred are the same
    /// seeds in the same colours, but four hundred and nine of them grow to
    /// another height now: the re-roll dealt new families, a cushion stands 0.13 to
    /// 0.27 m, and the lower quartile fell from 0.52 m to 0.42. The cuts are
    /// still the Orchard's 0.58 and 1.20, so where the ranks were 147, 258 and
    /// 95 they are 164, 234 and 102. A pair has one heart place to each
    /// compartment, so a colour whose hearts are full sends its next short
    /// plant to a side place only where the order outward allows it, and
    /// otherwise claims another pair: sixty-nine claimed where there were
    /// sixty-six, fifty-seven of them full, 91% of every claimed place held.
    /// The rule is doing what it says. Whether the shared cuts still divide
    /// the garden 1:2:1 is a question for the cuts, not for this test.
    func testHowFiveHundredLandOnTheKnotGarden() {
        let ways = Self.filled()
        let counts = (0..<ways.plots).map { ways.plot($0).count }
        XCTAssertEqual(counts.reduce(0, +), 501)
        XCTAssertEqual(ways.plots, 18, "\(ways.plots) plots for 501 plants: \(counts)")
        let claimed = (0..<ways.plots).reduce(0) { total, plot in
            total + KnotGarden.Pair.allCases.filter { ways.family(of: $0, in: plot) != nil }.count
        }
        XCTAssertGreaterThan(Double(501) / Double(claimed * 8), 0.9,
            "501 plants filled \(claimed) claimed pairs badly: \(counts)")
        XCTAssertGreaterThan(Double(501) / Double(ways.plots * 32), 0.86,
            "\(ways.plots) plots for 501 plants: \(counts)")
    }

    /// **Five plants in six get the rank their height asks for, and the rest
    /// are out by exactly one.**
    ///
    /// Measured at five hundred: 420 of 501 in their own rank, 48 one step out,
    /// 33 one step in, none further. Between the Crossing's 96.6% and the
    /// Orchard's 75%, and for a reason worth naming — preferring the pair over
    /// the rank displaces plants as the Orchard's guild-first rule does, but a
    /// pair holds eight places against a guild's four, so there is twice as
    /// much room to find the right one before settling for its neighbour.
    ///
    /// **It is not a visual fault, and that is why it is allowed.** `inOrder`
    /// is what guarantees the picture — nothing stands in front of something
    /// shorter — and it holds for every plant whatever rank it ended in.
    func testFivePlantsInSixGetTheirOwnRankAndNoneIsTwoStepsOut() {
        let ways = Self.filled()
        var steps: [Int: Int] = [:]
        for planting in ways.plantings {
            let own = KnotGarden.rank(height: planting.traits.height)
            steps[planting.slot.rank.rawValue - own.rawValue, default: 0] += 1
        }
        XCTAssertEqual(steps.keys.filter { abs($0) > 1 }.sorted(), [],
                       "a plant is two ranks from its own: \(steps)")
        XCTAssertGreaterThan(Double(steps[0] ?? 0) / Double(ways.plantings.count), 0.8,
                             "only \(steps[0] ?? 0) of \(ways.plantings.count) got their own rank")
    }
}
