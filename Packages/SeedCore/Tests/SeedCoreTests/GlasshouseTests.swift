import XCTest
@testable import SeedCore

/// The eighth area: pots on the staging in a run of colour, the tallest in a
/// border along the back, under a roof that has to clear them all.
final class GlasshouseTests: XCTestCase {

    // MARK: Arrivals

    /// **Five hundred plants whose names put them in the Glasshouse**, drawn as
    /// the Cold Frame's are, because this area's cut and its band edges are
    /// both measured over its own plants.
    ///
    /// **Not the plants the band edges were fitted to.** Those were three
    /// thousand drawn under another label; bands fitted to a sample flatter
    /// it, 98% held against 87%, so the fill this suite holds the rule to is
    /// the fill on plants the rule has never seen.
    private static let found = crossings(500)
    private static let sample: [(SeedID, PlantTraits)] = found.map { ($0.seed, LongWalk.traits(of: $0.genome)) }

    static func arrivals(_ count: Int = 500) -> [(SeedID, PlantTraits)] {
        count <= sample.count ? Array(sample.prefix(count)) : make(count)
    }

    static func genomes(_ count: Int = 500) -> [Genome] {
        count <= found.count ? Array(found.prefix(count).map(\.genome)) : crossings(count).map(\.genome)
    }

    private static func crossings(_ count: Int) -> [(seed: SeedID, genome: Genome)] {
        var found: [(seed: SeedID, genome: Genome)] = []
        var n = 0
        while found.count < count {
            let a = SeedMint.mint(fromEntropy: Data("glasshouse-arrival-\(n)-a".utf8))
            let b = SeedMint.mint(fromEntropy: Data("glasshouse-arrival-\(n)-b".utf8))
            n += 1
            let meeting = Pollination.encounterID(seedA: a, seedB: b,
                                                  nonceA: Data("a".utf8), nonceB: Data("b".utf8))
            let child = Pollination.cross(seedA: a, seedB: b, encounterID: meeting)
            let genome = Genome(seed: child,
                                lineage: .crossed(parentA: a, parentB: b, encounterID: meeting))
            if Area(genome: genome) == .light { found.append((child, genome)) }
        }
        return found
    }

    private static func make(_ count: Int) -> [(SeedID, PlantTraits)] {
        crossings(count).map { ($0.seed, LongWalk.traits(of: $0.genome)) }
    }

    private static let full: Glasshouse.Ways = {
        var ways = Glasshouse.Ways.opened()
        for (seed, traits) in arrivals() { ways.plant(seed: seed, traits: traits) }
        return ways
    }()

    static func filled(_ count: Int = 500) -> Glasshouse.Ways {
        if count == 500 { return full }
        var ways = Glasshouse.Ways.opened()
        for (seed, traits) in arrivals(count) { ways.plant(seed: seed, traits: traits) }
        return ways
    }

    // MARK: The plot

    func testAPlotHoldsTwentyFourPotsAndABorderOfEightAndNoMore() {
        XCTAssertEqual(Glasshouse.slots.count, 32)
        XCTAssertEqual(Set(Glasshouse.slots).count, 32)
        XCTAssertEqual(Glasshouse.slots.filter { $0.bed == .staging }.count, 24)
        XCTAssertEqual(Glasshouse.table.places(nudge: 0).count, 32)
        let ways = Self.full
        for plot in 0..<ways.plots {
            let here = ways.plot(plot)
            XCTAssertLessThanOrEqual(here.count, 32, "plot \(plot) holds \(here.count)")
            XCTAssertEqual(Set(here.map(\.slot)).count, here.count, "two plants in one place in plot \(plot)")
            // The bed fills in its order, so its places are 0..<n.
            let border = here.filter { $0.slot.bed == .border }.map(\.slot.index)
            XCTAssertEqual(Set(border), Set(0..<border.count), "plot \(plot)'s bed has a gap in it")
            // And each band on the staging fills its row 0 first.
            for position in 0..<Glasshouse.positions {
                let rows = here.filter { $0.slot.bed == .staging && $0.slot.index == position }.map(\.slot.row)
                XCTAssertEqual(Set(rows), Set(0..<rows.count), "plot \(plot) band \(position) skips a row")
            }
        }
    }

    /// Which way a point lies from the middle of the house, as a turn from
    /// `x+` toward `z+`, the way `Glasshouse.doorTurn` is measured.
    private func turn(of spot: Spot) -> Double {
        let t = atan2(spot.z, spot.x) / (2 * .pi)
        return t < 0 ? t + 1 : t
    }

    /// How far round from the door a point is, as a turn: 0 at the door,
    /// going round toward `x−`.
    private func fromDoor(_ spot: Spot) -> Double {
        let t = turn(of: spot) - Glasshouse.doorTurn
        return t < 0 ? t + 1 : t
    }

    private func radius(_ spot: Spot) -> Double { (spot.x * spot.x + spot.z * spot.z).squareRoot() }

    /// **Every pot stands on the ring of staging, clear of the glass, and
    /// every border place in the bed**, nudges and all; and the house stands
    /// inside the slab, clear of its worn edge.
    func testEveryPlaceStandsInsideTheHouseAndClearOfItsGlass() {
        let bed = Glasshouse.table.curve("bed", on: .plain).points.map(radius)
        for slot in Glasshouse.slots {
            let r = radius(slot.spot)
            switch slot.bed {
            case .staging:
                XCTAssertEqual(r, Glasshouse.stagingRadius, accuracy: 0.015, "\(slot) is off the staging's line")
                XCTAssertLessThan(r + 0.015 + 0.09, Glasshouse.houseRadius - 0.2, "\(slot) is against the glass")
                XCTAssertGreaterThan(r - 0.015 - 0.09, Glasshouse.stagingRadius - Glasshouse.stagingDepth / 2,
                                     "\(slot) hangs off the staging's inside edge")
            case .border:
                // A nudge of 5 cm either way in x and in z, and a hand's
                // breadth of soil beyond it.
                XCTAssertLessThan(r + 0.05 * 2.0.squareRoot(), bed.min()! - 0.05, "\(slot) is at the bed's edge")
            }
        }
        let house = Glasshouse.table.curve("house", on: .plain).points.map(radius)
        XCTAssertGreaterThanOrEqual(house.min()!, Glasshouse.houseRadius - 0.001, "the wall wanders inward")
        XCTAssertLessThan(house.max()! + Organic.houseBar, Glasshouse.plotSide / 2 - 0.25)
        XCTAssertEqual(bed.min()!, Glasshouse.bedRadius, accuracy: 0.05)
        XCTAssertEqual(bed.max()!, Glasshouse.bedRadius, accuracy: 0.05)
        // The walk between the staging and the bed.
        XCTAssertGreaterThan(Glasshouse.stagingRadius - Glasshouse.stagingDepth / 2 - bed.max()!, 0.7)
    }

    /// **The wheel**: the twelve bands go round the staging in order from the
    /// door toward `x−`, band 0 just past the door and band 11 just before
    /// it, and nothing stands in the doorway between them.
    func testTheBandsRunRoundTheWheelFromTheDoor() {
        let middles = (0..<Glasshouse.positions).map { band -> Double in
            let both = (0..<Glasshouse.rows).map {
                fromDoor(Glasshouse.Slot(bed: .staging, index: band, row: $0).spot)
            }
            return (both[0] + both[1]) / 2
        }
        XCTAssertEqual(middles, middles.sorted(), "the bands are not in order round the wheel")
        XCTAssertLessThan(middles[0], 0.1)
        XCTAssertGreaterThan(middles[11], 0.9)
        // Band 0 lies toward x-, band 11 toward x+.
        XCTAssertLessThan(Glasshouse.Slot(bed: .staging, index: 0).spot.x, 0)
        XCTAssertGreaterThan(Glasshouse.Slot(bed: .staging, index: 11).spot.x, 0)
        // The doorway: the door and a pot's width either side of the door.
        let doorway = (Organic.doorHalf + 0.15) / (2 * .pi * Glasshouse.stagingRadius)
        for slot in Glasshouse.slots where slot.bed == .staging {
            let t = fromDoor(slot.spot)
            XCTAssertTrue(t > doorway && t < 1 - doorway, "\(slot) stands in the doorway")
        }
        // The line the staging is laid along ends either side of the door.
        let line = Glasshouse.table.curve("staging", on: .plain).points
        XCTAssertGreaterThan(fromDoor(line.first!), Organic.doorHalf / (2 * .pi * Glasshouse.stagingRadius))
        XCTAssertLessThan(fromDoor(line.last!), 1 - Organic.doorHalf / (2 * .pi * Glasshouse.stagingRadius))
        // And the door is where the table's wall says it is: the wall's point
        // a quarter of the way round is on `z+`.
        let wall = Glasshouse.table.curve("house", on: .plain).points
        XCTAssertEqual(wall.count % 4, 0)
        XCTAssertEqual(turn(of: wall[Int(Double(wall.count) * Glasshouse.doorTurn)]), Glasshouse.doorTurn,
                       accuracy: 0.0005)
    }

    /// **Pots 0.43 m apart round the ring**, against the span house's 0.30,
    /// and the bed's places 0.45 m apart or more.
    func testThePotsStandAPotGapApart() {
        let pots = Glasshouse.slots.filter { $0.bed == .staging }.map(\.spot)
            .sorted { fromDoor($0) < fromDoor($1) }
        for (a, b) in zip(pots, pots.dropFirst()) {
            let gap = ((a.x - b.x) * (a.x - b.x) + (a.z - b.z) * (a.z - b.z)).squareRoot()
            XCTAssertEqual(gap, Glasshouse.potGap, accuracy: 0.005)
        }
        let bed = Glasshouse.bedSpots
        for (i, a) in bed.enumerated() {
            for b in bed[(i + 1)...] {
                XCTAssertGreaterThan(((a.x - b.x) * (a.x - b.x) + (a.z - b.z) * (a.z - b.z)).squareRoot(), 0.44)
            }
        }
    }

    /// **Every count looks finished** (Marcus, 2 October 2026): the bed fills
    /// from its middle, then farthest-first; a pale pot is offered the pot
    /// opposite the door first, then farthest-first; and the offer order
    /// holds every pot once, each band's row 0 before its row 1.
    func testThePlacesAreOfferedFromTheFocalPlaceOutward() {
        XCTAssertLessThan(radius(Glasshouse.bedSpots[0]), 0.05, "the bed does not start in its middle")
        XCTAssertGreaterThan(radius(Glasshouse.bedSpots[1]), 0.4)
        XCTAssertEqual(fromDoor(Glasshouse.paleOrder[0].spot), 0.5, accuracy: 0.03)
        XCTAssertEqual(Set(Glasshouse.paleOrder).count, 24)
        XCTAssertEqual(Set(Glasshouse.paleOrder), Set(Glasshouse.slots.filter { $0.bed == .staging }))
        for band in 0..<Glasshouse.positions {
            let first = Glasshouse.paleOrder.firstIndex(of: Glasshouse.Slot(bed: .staging, index: band, row: 0))!
            let second = Glasshouse.paleOrder.firstIndex(of: Glasshouse.Slot(bed: .staging, index: band, row: 1))!
            XCTAssertLessThan(first, second, "band \(band)'s row 1 is offered before its row 0")
        }
        // The first four pale pots are spread round the wheel, not bunched.
        let four = Glasshouse.paleOrder.prefix(4).map { fromDoor($0.spot) }.sorted()
        for (a, b) in zip(four, four.dropFirst()) { XCTAssertGreaterThan(b - a, 0.15) }
    }

    // MARK: The spectrum

    func testTheBandsRunRoundTheCircleFromTheCut() {
        XCTAssertEqual(Glasshouse.bandEdges.count, Glasshouse.positions - 1)
        XCTAssertEqual(Glasshouse.bandEdges, Glasshouse.bandEdges.sorted())
        XCTAssertEqual(Glasshouse.band(hue: Glasshouse.cut), 0)
        XCTAssertEqual(Glasshouse.band(hue: Glasshouse.cut - 1e-9), 11)
        // Blue-green at the door, violet in the middle, red in the ninth band
        // and yellow at the far end.
        XCTAssertEqual(Glasshouse.band(hue: 150.0 / 360), 0)
        XCTAssertEqual(Glasshouse.band(hue: 280.0 / 360), 5)
        XCTAssertEqual(Glasshouse.band(hue: 0.0), 8)
        XCTAssertEqual(Glasshouse.band(hue: 80.0 / 360), 11)
    }

    /// **The edges hold on plants they were not fitted to.** Each band should
    /// take a twelfth of the hued plants; on the five hundred here, none takes
    /// fewer than half that or more than half as many again.
    func testEachBandHoldsAboutATwelfthOfAFreshSample() {
        let bands = Self.arrivals().compactMap { $0.1.glasshouseBand }
        var counts = [Int](repeating: 0, count: Glasshouse.positions)
        for band in bands { counts[band] += 1 }
        print("Glasshouse bands on a fresh 500: \(counts)")
        let twelfth = Double(bands.count) / 12
        for (band, count) in counts.enumerated() {
            XCTAssertGreaterThan(Double(count), twelfth * 0.5, "band \(band) holds \(count)")
            XCTAssertLessThan(Double(count), twelfth * 1.5, "band \(band) holds \(count)")
        }
    }

    // MARK: The rule

    func testTheTallestQuarterGoInTheBorder() {
        let ways = Self.full
        for planting in ways.plantings {
            XCTAssertEqual(planting.slot.bed, planting.traits.glasshouseBed,
                           "\(planting.seed) at \(planting.traits.height) m")
        }
        let heights = Self.arrivals().map(\.1.height)
        let border = Double(heights.filter { $0 >= Glasshouse.borderFrom }.count) / Double(heights.count)
        XCTAssertEqual(border, 0.25, accuracy: 0.04)
    }

    /// **Every pot stands in its own band or the one beside it**, and most in
    /// their own. Pale plants, which have no band, stand anywhere.
    func testNearlyEveryPotStandsInItsOwnBand() {
        var own = 0, off = 0
        for planting in Self.full.plantings where planting.slot.bed == .staging {
            guard let band = planting.traits.glasshouseBand else { continue }
            let by = abs(planting.slot.index - band)
            XCTAssertLessThanOrEqual(by, 1, "\(planting.seed) stands \(by) places from its band")
            if by == 0 { own += 1 } else { off += 1 }
        }
        let share = Double(own) / Double(own + off)
        print("Glasshouse at 500: \(own) of \(own + off) hued pots in their own band")
        XCTAssertGreaterThan(share, 0.8)
    }

    /// **The number that could have sent the design back.** Simulated before
    /// the rule was written: 87% of places held and the staging 92% full on a
    /// fresh five hundred. The rule as built does a little better on its own
    /// fresh five hundred — 17 plots, 92% held, the staging and the border
    /// both 91–92% full, and 322 of 364 hued pots in their own band — because
    /// the band edges were fitted to three thousand plants rather than five
    /// hundred, and a pot one band off tries the side its hue leans to first.
    func testTheFillAtFiveHundred() {
        let ways = Self.full
        let places = ways.plots * Glasshouse.slots.count
        let pots = ways.plantings.filter { $0.slot.bed == .staging }.count
        let border = ways.plantings.count - pots
        let fill = Double(ways.plantings.count) / Double(places)
        let staging = Double(pots) / Double(ways.plots * Glasshouse.positions * Glasshouse.rows)
        let borderFill = Double(border) / Double(ways.plots * Glasshouse.borderPlaces)
        print("Glasshouse at 500: \(ways.plots) plots, fill \(fill), staging \(staging), border \(borderFill)")
        XCTAssertLessThanOrEqual(ways.plots, 19)
        XCTAssertGreaterThan(fill, 0.8)
        XCTAssertGreaterThan(staging, 0.85)
    }

    func testAPotLooksForItsOwnBandInEveryPlotBeforeStandingOneOff() {
        var ways = Glasshouse.Ways()
        let seed = { (n: Int) in SeedMint.mint(fromEntropy: Data("gh-band-\(n)".utf8)) }
        let hue = 280.0 / 360
        let violet = PlantTraits(height: 0.8, family: 4, hue: hue)
        let band = Glasshouse.band(hue: hue)
        let nearer = Glasshouse.leansOn(hue: hue) ? band + 1 : band - 1
        // Two pots fill the position. With one plot open, the third stands one
        // off in it, on the side its hue leans to, rather than opening a plot.
        ways.plant(seed: seed(0), traits: violet)
        ways.plant(seed: seed(1), traits: violet)
        let third = ways.plant(seed: seed(2), traits: violet)
        XCTAssertEqual(third.plot, 0)
        XCTAssertEqual(third.slot.index, nearer)
        // Nine border plants open a second plot.
        for n in 3..<12 {
            ways.plant(seed: seed(n), traits: PlantTraits(height: 1.5, family: 2, hue: 0.5))
        }
        XCTAssertEqual(ways.plots, 2)
        // Now its own band in the second plot comes before the room still left
        // one off in the first.
        let fourth = ways.plant(seed: seed(20), traits: violet)
        XCTAssertEqual(fourth.plot, 1)
        XCTAssertEqual(fourth.slot, Glasshouse.Slot(bed: .staging, index: band, row: 0))
    }

    func testTheEndsOfTheBenchAreNotNeighbours() {
        var ways = Glasshouse.Ways()
        let seed = { (n: Int) in SeedMint.mint(fromEntropy: Data("gh-ends-\(n)".utf8)) }
        let yellow = PlantTraits(height: 0.8, family: 1, hue: 80.0 / 360)
        for n in 0..<4 { ways.plant(seed: seed(n), traits: yellow) }
        // Band 11 and band 10 are full; the fifth yellow opens a new plot rather
        // than going round the cut to band 0.
        let fifth = ways.plant(seed: seed(4), traits: yellow)
        XCTAssertEqual(fifth.plot, 1)
        XCTAssertEqual(fifth.slot.index, 11)
        XCTAssertFalse(ways.plantings.contains { $0.slot.index == 0 })
    }

    func testAPalePlantTakesTheFirstFreePotInTheOfferOrder() {
        var ways = Glasshouse.Ways()
        let seed = { (n: Int) in SeedMint.mint(fromEntropy: Data("gh-pale-\(n)".utf8)) }
        let blueGreen = ways.plant(seed: seed(0), traits: PlantTraits(height: 0.8, family: 1, hue: 160.0 / 360))
        XCTAssertEqual(blueGreen.slot, Glasshouse.Slot(bed: .staging, index: 0, row: 0))
        let pale = ways.plant(seed: seed(1), traits: PlantTraits(height: 0.8, family: LongWalk.paleFamily,
                                                                 hue: 0.5))
        XCTAssertEqual(pale.slot, Glasshouse.paleOrder[0])
        // A plant whose hue was never sent is placed as a pale one is.
        let unsent = ways.plant(seed: seed(2), traits: PlantTraits(height: 0.8, family: 3))
        XCTAssertEqual(unsent.slot, Glasshouse.paleOrder[1])
        // Pale pots alone fill a plot in the offer order, then open the next
        // at its first pot.
        var full = Glasshouse.Ways()
        let pallid = PlantTraits(height: 0.8, family: LongWalk.paleFamily, hue: 0.5)
        for n in 0..<24 { full.plant(seed: seed(10 + n), traits: pallid) }
        XCTAssertEqual(full.plantings.map(\.slot), Glasshouse.paleOrder)
        XCTAssertEqual(full.plots, 1)
        let next = full.plant(seed: seed(40), traits: pallid)
        XCTAssertEqual(next.plot, 1)
        XCTAssertEqual(next.slot, Glasshouse.paleOrder[0])
    }

    func testTheBorderFillsInItsOrderWhateverItsColour() {
        var ways = Glasshouse.Ways()
        let seed = { (n: Int) in SeedMint.mint(fromEntropy: Data("gh-border-\(n)".utf8)) }
        for n in 0..<9 {
            let p = ways.plant(seed: seed(n), traits: PlantTraits(height: 1.4 + Double(n) * 0.01,
                                                                  family: n % 7, hue: Double(n) / 9))
            XCTAssertEqual(p.slot.bed, .border)
            XCTAssertEqual(p.slot.index, n % 8)
            XCTAssertEqual(p.plot, n / 8)
        }
    }

    func testThePlaceIsTheSameWhateverOrderTheTestsRunIn() {
        let ways = Self.filled(40)
        let traits = PlantTraits(height: 0.9, family: 4, hue: 0.8)
        XCTAssertEqual(ways.place(for: traits).plot, ways.place(for: traits).plot)
        XCTAssertEqual(ways.place(for: traits).slot, ways.place(for: traits).slot)
    }

    func testThePlacementIsAppendOnly() {
        let early = Self.filled(120).plantings
        let late = Self.full.plantings
        XCTAssertEqual(Array(late.prefix(early.count)), early)
    }

    // MARK: The ambassador

    /// **The ambassador opens the border**, since 28 September 2026, and
    /// since 2 October stands in the middle of the round bed, under the
    /// crown. *Elora elata*, a star of 1.45 m, is over the border's 1.16, so
    /// it is planted in the soil rather than potted, and the staging opens
    /// empty. (*Aurea pallida*, 0.74 m, opened the staging at its own band.)
    func testTheAmbassadorOpensTheBorderInTheMiddleOfTheBed() {
        let one = Glasshouse.ambassador
        let traits = LongWalk.traits(of: Ambassadors.of(.light).genome)
        XCTAssertGreaterThanOrEqual(traits.height, Glasshouse.borderFrom)
        XCTAssertEqual(one.plot, 0)
        XCTAssertEqual(one.slot.bed, .border)
        XCTAssertEqual(one.slot.index, 0)
        XCTAssertEqual(one.slot.row, 0)
        XCTAssertEqual(one.seed, Ambassadors.of(.light).seed.hex)
        XCTAssertLessThan(radius(one.spot), 0.1)
    }

    // MARK: The roof

    /// **Every plant stands under the dome above it**, grown and in flower,
    /// with a tenth of a metre to spare — the measurement the house's eaves
    /// and crown were set by, held as a test.
    func testEveryPlantStandsUnderTheRoof() {
        var nearest = Double.greatestFiniteMagnitude
        for planting in Self.full.plantings {
            let top = planting.slot.lift + planting.traits.height
            let roof = Glasshouse.roof(atRadius: radius(planting.spot))
            nearest = min(nearest, roof - top)
            XCTAssertLessThan(top, roof - 0.1, "\(planting.seed) stands \(top) m under a roof at \(roof) m")
        }
        print("Glasshouse: the nearest plant to the roof is \(nearest) m under it")
    }

    func testTheRoofRisesFromTheEavesToTheCrown() {
        XCTAssertEqual(Glasshouse.roof(atRadius: 0), Glasshouse.crown, accuracy: 1e-12)
        XCTAssertEqual(Glasshouse.roof(atRadius: Glasshouse.houseRadius), Glasshouse.eaves, accuracy: 1e-12)
        XCTAssertLessThan(Glasshouse.roof(atRadius: 1.8), Glasshouse.roof(atRadius: 0.9))
    }
}
