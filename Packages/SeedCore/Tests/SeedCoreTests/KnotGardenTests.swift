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

    /// Four lenses and four crescents, and each one's mirror is the one
    /// opposite. Both fall out of the declaration order rather than out of a
    /// table, so this is what says the order is load bearing.
    func testTheEightAreFourLensesFourCrescentsAndFourMirrorPairs() {
        XCTAssertEqual(KnotGarden.Compartment.allCases.filter(\.isCrescent).count, 4)
        XCTAssertEqual(KnotGarden.Compartment.allCases.filter { !$0.isCrescent }.count, 4)
        for compartment in KnotGarden.Compartment.allCases {
            XCTAssertEqual(compartment.mirror.mirror, compartment)
            XCTAssertNotEqual(compartment.mirror, compartment)
            XCTAssertEqual(compartment.mirror.isCrescent, compartment.isCrescent,
                           "\(compartment) is mirrored by a compartment of the other kind")
            XCTAssertEqual(compartment.pair, compartment.mirror.pair)
        }
        for pair in KnotGarden.Pair.allCases {
            XCTAssertEqual(pair.compartments.count, 2)
            XCTAssertEqual(pair.compartments[0].mirror, pair.compartments[1])
            for compartment in pair.compartments { XCTAssertEqual(compartment.pair, pair) }
        }
        XCTAssertEqual(Set(KnotGarden.Compartment.allCases.map(\.pair)).count, 4)
        // The lenses are claimed before the crescents.
        XCTAssertEqual(KnotGarden.Pair.allCases.map { $0.compartments[0].isCrescent },
                       [false, false, true, true])
    }

    /// **The table holds the places in the rule's order**: compartment by
    /// compartment, four to each, so `Slot.spot` reading place
    /// `compartment × 4 + index` reads the place the table tagged with that
    /// compartment and that index.
    func testTheTableIsInTheRulesOrder() {
        let table = KnotGarden.table
        XCTAssertEqual(table.nudges, 1, "the knot is laid one way")
        let places = table.places(nudge: 0)
        XCTAssertEqual(places.count, KnotGarden.slots.count)
        for (i, slot) in KnotGarden.slots.enumerated() {
            XCTAssertEqual(table.tag("compartment", of: places[i]), slot.compartment.rawValue)
            XCTAssertEqual(table.tag("index", of: places[i]), slot.index)
            XCTAssertEqual(slot.spot, places[i].spot)
        }
    }

    /// A mirror pair stands opposite across the middle of the plot: the two
    /// places at one index are the same point turned half round. That is what
    /// makes a colour read as symmetric rather than as two blocks that happen
    /// to match. **Exactly**: the generator turns the north-east compartment by
    /// whole quarters after rounding it to the millimetre.
    func testAMirrorPairsPlacesAreOppositeAcrossTheMiddle() {
        for compartment in KnotGarden.Compartment.allCases {
            for index in 0..<4 {
                let here = KnotGarden.Slot(compartment: compartment, index: index).spot
                let there = KnotGarden.Slot(compartment: compartment.mirror, index: index).spot
                XCTAssertEqual(there.x, -here.x, accuracy: 0)
                XCTAssertEqual(there.z, -here.z, accuracy: 0)
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

    /// Whether a point is inside a closed line, by the even-odd rule.
    private func inside(_ p: Spot, _ line: [Spot]) -> Bool {
        var within = false
        var j = line.count - 1
        for i in line.indices {
            let a = line[i], b = line[j]
            if (a.z > p.z) != (b.z > p.z), p.x < (b.x - a.x) * (p.z - a.z) / (b.z - a.z) + a.x {
                within.toggle()
            }
            j = i
        }
        return within
    }

    /// **Every place stands inside its own compartment**: a lens's inside its
    /// small ring and the middle one, a crescent's inside its small ring and
    /// outside the middle one, nudged however the seed can push it.
    func testEveryPlaceIsInsideItsOwnCompartment() {
        let bands = KnotGarden.bands
        let middle = bands[0].points
        for slot in KnotGarden.slots {
            let ring = bands[1 + slot.compartment.ring].points
            for dx in [-KnotGarden.nudge, 0, KnotGarden.nudge] {
                for dz in [-KnotGarden.nudge, 0, KnotGarden.nudge] {
                    let p = Spot(x: slot.spot.x + dx, z: slot.spot.z + dz)
                    XCTAssertTrue(inside(p, ring), "\(slot) nudged \(dx), \(dz) is outside its ring")
                    XCTAssertEqual(inside(p, middle), !slot.compartment.isCrescent,
                                   "\(slot) nudged \(dx), \(dz) is on the wrong side of the middle ring")
                }
            }
        }
    }

    /// **No plant stands in the hedge, however it is nudged.** The bands are
    /// curves now and swell where they ride over, and both eat into the room
    /// between a place and the band beside it: what is asserted is what is
    /// left after the nudge as well. A plant pushed as hard as the seed can
    /// push it still stands clear of the box.
    func testNoPlaceStandsInABandHoweverItIsNudged() {
        let nudge = KnotGarden.nudge
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

    /// **The knot is woven over and under in turn.** Eight crossings, each on
    /// the middle ring and on its own small ring; going round the middle ring
    /// they come in order, the middle ring over at one and under at the next;
    /// and each small ring is over at one of its two and under at the other.
    /// Two rings simply lying on each other would be a drawing of circles; the
    /// alternation is the knot.
    func testTheKnotIsWovenOverAndUnderInTurn() {
        let bands = KnotGarden.bands
        let crossings = KnotGarden.crossings
        XCTAssertEqual(crossings.count, 8)
        for (i, crossing) in crossings.enumerated() {
            let ring = 1 + i / 2
            XCTAssertLessThan(KnotGarden.distance(crossing, to: bands[0].points, closed: true), 0.002,
                              "crossing \(i) is not on the middle ring")
            XCTAssertLessThan(KnotGarden.distance(crossing, to: bands[ring].points, closed: true), 0.002,
                              "crossing \(i) is not on ring \(ring - 1)")
            XCTAssertEqual(KnotGarden.over(at: i), i % 2 == 0 ? 0 : ring)
        }
        // Round the middle ring in order: each crossing a little further round
        // than the one before, x+ toward z+, and all eight in one turn. The
        // turn is read as a "diamond angle", 0 to 4 round the middle, which
        // rises with the true angle and needs no host's arctangent.
        func turn(_ p: Spot) -> Double {
            if p.z >= 0 { return p.x >= 0 ? p.z / (p.x + p.z) : 1 - p.x / (-p.x + p.z) }
            return p.x < 0 ? 2 - p.z / (-p.x - p.z) : 3 + p.x / (p.x - p.z)
        }
        var travelled = 0.0
        for i in 0..<8 {
            var step = turn(crossings[(i + 1) % 8]) - turn(crossings[i])
            if step < 0 { step += 4 }
            XCTAssertGreaterThan(step, 0.08, "crossings \(i) and \((i + 1) % 8) are out of order")
            travelled += step
        }
        XCTAssertEqual(travelled, 4, accuracy: 1e-9, "the crossings go round more than once")
    }

    /// **No two bands touch but where they cross**: two small rings side by
    /// side, a small ring and the edging, the middle ring and the edging. Two
    /// runs of box with no gravel between them read as one wide band, and the
    /// knot as a blot.
    func testNoTwoBandsTouchButWhereTheyCross() {
        let bands = KnotGarden.bands
        func gap(_ a: Int, _ b: Int) -> Double {
            bands[a].points.map { KnotGarden.distance($0, to: bands[b].points, closed: true) }.min()!
                - 2 * KnotGarden.bandHalfThickness
        }
        for k in 0..<4 {
            XCTAssertGreaterThan(gap(1 + k, 1 + (k + 1) % 4), 0.03, "rings \(k) and \((k + 1) % 4) touch")
            XCTAssertGreaterThan(gap(1 + k, 5), 0.03, "ring \(k) touches the edging")
        }
        XCTAssertGreaterThan(gap(0, 5), 0.03, "the middle ring touches the edging")
    }

    /// **The edging stands on the slab.** The plot's outline wanders inward by
    /// up to 0.22 m from the 5.2 m square (`Organic.outline`), so no part of
    /// the edging's outer face may stand further out than 2.38 m on either
    /// axis; it is held 3 cm inside that, and 7 cm inside where this slab comes
    /// nearest.
    func testTheEdgingStandsOnTheSlab() {
        let edging = KnotGarden.bands[5].points
        let reach = edging.map { max(abs($0.x), abs($0.z)) }.max()! + KnotGarden.bandHalfThickness
        XCTAssertLessThan(reach, KnotGarden.plotSide / 2 - 0.22 - 0.03)
    }

    /// Two plants in one plot may not stand on top of each other. **0.42 m**,
    /// the depth of a lens less the band and the nudge on both sides of it:
    /// tighter than the 0.56 m the sides and corners allowed, and why the
    /// rings stand on the diagonals, where on the axes the lenses held their
    /// four 0.22 m apart.
    func testNoTwoPlacesInAPlotAreTooCloseTogether() {
        var closest = Double.greatestFiniteMagnitude
        for (i, a) in KnotGarden.slots.enumerated() {
            for b in KnotGarden.slots.dropFirst(i + 1) {
                let dx = a.spot.x - b.spot.x, dz = a.spot.z - b.spot.z
                closest = min(closest, (dx * dx + dz * dz).squareRoot())
            }
        }
        XCTAssertGreaterThan(closest, 0.40, "closest two places are \(closest) m apart")
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

    func testTheAmbassadorStandsInTheNorthEastLens() {
        let one = KnotGarden.ambassador
        XCTAssertEqual(one.plot, 0)
        XCTAssertEqual(one.slot.compartment, .northEastLens)
        XCTAssertEqual(one.slot.compartment.pair, .northEastLenses)
        XCTAssertEqual(one.seed, Ambassadors.of(.pattern).seed.hex)
        // *Quinyria obscura*, since 28 September 2026, is 1.22 m: over the
        // 1.20 cut, so it reads as a point and takes index 3, the place at
        // the lens's outer edge. (*Quina caerulea* was a side, index 1.)
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
        XCTAssertEqual(ways.family(of: .northEastLenses, in: 0), 4)
        for planting in ways.plot(0) where planting.slot.compartment.pair == .northEastLenses {
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
    ///
    /// **Seventeen plots and 93% since 29 September 2026**, when the cuts were
    /// asked that question and measured again on three thousand crossings:
    /// the Orchard's are 0.48 and 1.18 now, and the ranks here 142, 250 and
    /// 109 with the ambassador. Sixty-seven pairs claimed, fifty-six of them
    /// full, 93% of every claimed place held.
    func testHowFiveHundredLandOnTheKnotGarden() {
        let ways = Self.filled()
        let counts = (0..<ways.plots).map { ways.plot($0).count }
        XCTAssertEqual(counts.reduce(0, +), 501)
        XCTAssertEqual(ways.plots, 17, "\(ways.plots) plots for 501 plants: \(counts)")
        let claimed = (0..<ways.plots).reduce(0) { total, plot in
            total + KnotGarden.Pair.allCases.filter { ways.family(of: $0, in: plot) != nil }.count
        }
        let full = (0..<ways.plots).reduce(0) { total, plot in
            total + KnotGarden.Pair.allCases.filter { pair in
                ways.plot(plot).filter { $0.slot.compartment.pair == pair }.count == 8
            }.count
        }
        let ranks = KnotGarden.Rank.allCases.map { rank in
            ways.plantings.filter { KnotGarden.rank(height: $0.traits.height) == rank }.count
        }
        print("Knot Garden at 500: \(ways.plots) plots, \(claimed) pairs claimed, \(full) full, "
              + "\(Double(501) / Double(claimed * 8)) of claimed places held, ranks \(ranks)")
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
