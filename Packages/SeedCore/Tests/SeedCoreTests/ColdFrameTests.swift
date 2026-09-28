import XCTest
@testable import SeedCore

/// The seventh area: four frames, a colour to a frame, two ranks graded by what
/// each plant will grow into, and every plant drawn young — around a tank of
/// water down the middle of the yard, which is where every water lily goes.
///
/// **More than half of what arrives here is a water lily**, and that is a fact
/// about the area rather than about the sample: an area is chosen from a
/// plant's genus head and the head is its archetype's own root, so
/// `Areas.genusHeads` sending `Nyx` here is the same fact as the lotus's root
/// being `Nyx`. Only this area and the Seedbed ever receive one. Every
/// measurement below is therefore made twice — once of the water and once of
/// the frames — because a single number over both says nothing about either.
///
/// **Two in three since 28 September 2026**, when the reed came, wanting water
/// as a lily does, and its many-merous root `Syr` was given to this area. Of
/// the five hundred below, 192 are lilies, 150 reeds and 158 ferns: 342 for
/// the tank and 158 for the frames.
final class ColdFrameTests: XCTestCase {

    // MARK: Arrivals

    /// **Five hundred plants whose names put them in the Cold Frame**, rather
    /// than five hundred crossings of any kind.
    ///
    /// The first suite to draw its sample this way, and it has to: this area's
    /// cut is the median of its own plants, and those are shorter than the
    /// garden's. A sample of all crossings would put two thirds of it in the
    /// back rank and measure a rule nobody will ever see run. It costs 5,805
    /// crossings to find the five hundred, but only the five hundred are grown.
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
            let a = SeedMint.mint(fromEntropy: Data("coldframe-arrival-\(n)-a".utf8))
            let b = SeedMint.mint(fromEntropy: Data("coldframe-arrival-\(n)-b".utf8))
            n += 1
            let meeting = Pollination.encounterID(seedA: a, seedB: b,
                                                  nonceA: Data("a".utf8), nonceB: Data("b".utf8))
            let child = Pollination.cross(seedA: a, seedB: b, encounterID: meeting)
            let genome = Genome(seed: child,
                                lineage: .crossed(parentA: a, parentB: b, encounterID: meeting))
            if Area(genome: genome) == .waiting { found.append((child, genome)) }
        }
        return found
    }

    private static func make(_ count: Int) -> [(SeedID, PlantTraits)] {
        crossings(count).map { ($0.seed, LongWalk.traits(of: $0.genome)) }
    }

    private static let full: ColdFrame.Ways = {
        var ways = ColdFrame.Ways.opened()
        for (seed, traits) in arrivals() { ways.plant(seed: seed, traits: traits) }
        return ways
    }()

    static func filled(_ count: Int = 500) -> ColdFrame.Ways {
        if count == 500 { return full }
        var ways = ColdFrame.Ways.opened()
        for (seed, traits) in arrivals(count) { ways.plant(seed: seed, traits: traits) }
        return ways
    }

    // MARK: The plot

    func testAPlotHoldsFourFramesOfTwelveAndATankOfTwentyOne() {
        XCTAssertEqual(ColdFrame.slots.count, 69)
        XCTAssertEqual(Set(ColdFrame.slots).count, 69)
        XCTAssertEqual(ColdFrame.slots.filter { $0.frame.isDry }.count, 48)
        XCTAssertEqual(ColdFrame.slots.filter { !$0.frame.isDry }.count, ColdFrame.tankPlaces)
        let ways = Self.full
        for plot in 0..<ways.plots {
            // Asked of the places held rather than the plants, since a plant
            // under glass may hold two.
            let held = ways.plot(plot).flatMap(\.slots)
            XCTAssertLessThanOrEqual(held.count, 69, "plot \(plot) holds \(held.count) places")
            XCTAssertEqual(Set(held).count, held.count, "two plants hold one place in plot \(plot)")
            for frame in ColdFrame.Frame.allCases {
                // **The tank's rows are not ranks.** Every place in it is
                // `.front` and the row comes out of the index, so `.back` is
                // never asked of it and nothing is ever filed there.
                for rank in frame.isDry ? ColdFrame.Rank.allCases : [.front] {
                    let row = held.filter { $0.frame == frame && $0.rank == rank }
                    XCTAssertLessThanOrEqual(row.count, frame.places)
                    // A rank fills from its west end, so its places are 0..<n;
                    // the tank fills the same way, along its rows.
                    XCTAssertEqual(Set(row.map(\.index)), Set(0..<row.count),
                                   "plot \(plot) \(frame) \(rank) has a gap in it")
                }
            }
            XCTAssertTrue(held.allSatisfy { $0.frame.isDry || $0.rank == .front },
                          "plot \(plot) filed something in the tank's back rank")
        }
    }

    func testEveryPlaceStandsInsideItsFrameWellClearOfTheWalls() {
        let wall = 0.05, nudge = 0.03
        for slot in ColdFrame.slots where slot.frame.isDry {
            let centre = slot.frame.centre
            let along = abs(slot.spot.x - centre.x) + nudge
            let across = abs(slot.spot.z - centre.z) + nudge
            XCTAssertLessThan(along, ColdFrame.frameLength / 2 - wall - 0.1, "\(slot) is against an end")
            XCTAssertLessThan(across, ColdFrame.frameDepth / 2 - wall - 0.2, "\(slot) is against a wall")
        }
        // And the frames stand clear of each other and of the plot's rim.
        let edge = ColdFrame.plotSide / 2
        XCTAssertLessThan(ColdFrame.frameX + ColdFrame.frameLength / 2, edge - 0.35)
        XCTAssertLessThan(ColdFrame.frameZ + ColdFrame.frameDepth / 2, edge - 0.35)
        XCTAssertGreaterThanOrEqual(2 * ColdFrame.frameX - ColdFrame.frameLength, 0.4 - 1e-9)
        XCTAssertGreaterThanOrEqual(2 * ColdFrame.frameZ - ColdFrame.frameDepth, 0.7 - 1e-9)
    }

    /// **Every place in the tank has water round it**, and the tank has the
    /// yard to itself: it lies between the two rows of frames, touching
    /// neither, and stops short of the plot's rim at both ends.
    ///
    /// The lip is the width the floor gives way over, so a lily nudged toward
    /// the edge still floats rather than lying up the bank.
    func testEveryPlaceInTheTankStandsInTheWaterClearOfItsLip() {
        let lip = 0.12, nudge = 0.03
        for slot in ColdFrame.slots where !slot.frame.isDry {
            XCTAssertLessThan(abs(slot.spot.x) + nudge, ColdFrame.tankAcross / 2 - lip,
                              "\(slot) is against the tank's end")
            XCTAssertLessThan(abs(slot.spot.z) + nudge, ColdFrame.tankDeep / 2 - lip,
                              "\(slot) is against the tank's side")
        }
        // Clear of the frames in front of it and behind it...
        XCTAssertLessThan(ColdFrame.tankDeep / 2, ColdFrame.frameZ - ColdFrame.frameDepth / 2 - 0.05)
        // ...and clear of the plot's rim at either end.
        XCTAssertLessThan(ColdFrame.tankAcross / 2, ColdFrame.plotSide / 2 - 0.35)
        // Three rows of seven, and no two places on top of each other.
        let spots = ColdFrame.slots.filter { !$0.frame.isDry }.map(\.spot)
        XCTAssertEqual(Set(spots.map(\.z)).count, ColdFrame.tankRows)
        XCTAssertEqual(Set(spots.map(\.x)).count, ColdFrame.tankWide)
        XCTAssertEqual(Set(spots.map { "\($0.x),\($0.z)" }).count, ColdFrame.tankPlaces)
    }

    func testTheBackRankIsFurtherBackThanTheFrontInEveryFrame() {
        for frame in ColdFrame.Frame.allCases where frame.isDry {
            let front = ColdFrame.Slot(frame: frame, rank: .front, index: 0).spot.z
            let back = ColdFrame.Slot(frame: frame, rank: .back, index: 0).spot.z
            XCTAssertLessThan(back, front, "\(frame)'s back rank is in front")
        }
        // **The tank has no ranks**: water is flat and a lily has no view to
        // be given, so asking for its back rank gives its front rank's place.
        for index in 0..<ColdFrame.tankPlaces {
            XCTAssertEqual(ColdFrame.Frame.tank.at(index, rank: .back).z,
                           ColdFrame.Frame.tank.at(index, rank: .front).z)
        }
    }

    // MARK: The rule

    /// A frame holds one colour. **The tank holds whatever floats**: a pond is
    /// not sorted by colour or by height, and sorting one would be the tell
    /// that a rule had been applied where no gardener applies one.
    func testAFrameHoldsOneColourAndTheTankHoldsThemAll() {
        let ways = Self.full
        for plot in 0..<ways.plots {
            for frame in ColdFrame.Frame.allCases where frame.isDry {
                let families = Set(ways.plot(plot).filter { $0.slot.frame == frame }.map(\.traits.family))
                XCTAssertLessThanOrEqual(families.count, 1, "plot \(plot) \(frame) holds \(families)")
            }
        }
        let inWater = Set(ways.plantings.filter { !$0.slot.frame.isDry }.map(\.traits.family))
        XCTAssertGreaterThan(inWater.count, 1, "the tank was sorted by colour")
    }

    func testNothingInTheFrontRankIsTallerThanAnythingAtTheBack() {
        let ways = Self.full
        for plot in 0..<ways.plots {
            for frame in ColdFrame.Frame.allCases where frame.isDry {
                let here = ways.plot(plot).filter { $0.slot.frame == frame }
                let front = here.filter { $0.slot.rank == .front }.map(\.traits.height)
                let back = here.filter { $0.slot.rank == .back }.map(\.traits.height)
                if let tallest = front.max(), let shortest = back.min() {
                    XCTAssertLessThanOrEqual(tallest, shortest, "plot \(plot) \(frame) is out of order")
                }
            }
        }
    }

    /// **The number that could have sent the design back**, as it was for the
    /// Knot Garden: a colour to a frame could claim frames faster than it fills
    /// them. At five hundred it was twelve plots, with 87% of every place
    /// holding a plant.
    ///
    /// **Since 25 September 2026 a lotus takes two places**, and more than
    /// half of this area's plants are lotuses, so the same five hundred hold
    /// half as many places again: eighteen plots, 90% of every place held and
    /// twenty-eight plants to a plot where there were forty-two.
    ///
    /// **Since the tank was sunk on 27 September 2026 the two must be measured
    /// apart.** A lily is in the water and holds one place there; nothing else
    /// is. So five hundred arrivals fill fourteen plots rather than eighteen,
    /// and the number over the whole plot — about half of every place held —
    /// is the average of a tank that is always full and frames that are a
    /// third full. Marcus was shown a full plot and a middling one and chose
    /// this on 27 September 2026 knowing that: the frames are thin because
    /// only 227 of every 501 arrivals here want dry compost at all, which the
    /// tank makes visible rather than causes.
    ///
    /// **Fourteen plots, twenty-five frames claimed and fourteen of them
    /// full.** Moving the cut to the dry median claimed four fewer frames and
    /// filled five more of them: a rank that is asked for is a rank that
    /// fills, and at the old cut the front ranks were being skipped.
    ///
    /// **What would fail this is the tank running short**, which is the shape
    /// of the Knot Garden's near-miss: if a plot opened before its water was
    /// full, the area would be a row of ponds with a few lilies in each.
    ///
    /// **Seventeen plots and a fifth of the glass, since 28 September 2026**,
    /// where it was at most fifteen and more than three tenths. The reed wants
    /// water and its root `Syr` is this area's, so 343 of 501 now go in the
    /// tank — the ambassador among them — and 158 under glass, where it was
    /// about 274 and 227. The tank is what opens plots here (twenty-one to
    /// one, and a full tank opens the next plot rather than putting a plant
    /// under glass), so the plots follow the water: sixteen full tanks and a
    /// seventeenth with seven, 96% of every place in the water held. The
    /// frames come with the plots and fill at the rate the dry plants arrive,
    /// which is 158 of 816 places, 0.19; seventeen frames claimed and ten of
    /// them full. The rule is doing what it says. What moved is how much of
    /// the area is water, and that is the render to look at.
    func testTheFillAtFiveHundred() {
        let ways = Self.full
        let dryPlaces = ways.plots * ColdFrame.slots.filter { $0.frame.isDry }.count
        let wetPlaces = ways.plots * ColdFrame.tankPlaces
        let dryHeld = ways.plantings.filter { $0.slot.frame.isDry }.map(\.span).reduce(0, +)
        let wetHeld = ways.plantings.filter { !$0.slot.frame.isDry }.count
        let dryFill = Double(dryHeld) / Double(dryPlaces)
        let wetFill = Double(wetHeld) / Double(wetPlaces)
        var claimed = 0, full = 0
        for plot in 0..<ways.plots {
            for frame in ColdFrame.Frame.allCases where frame.isDry {
                let count = ways.plot(plot).filter { $0.slot.frame == frame }.map(\.span).reduce(0, +)
                if count > 0 { claimed += 1 }
                if count == 12 { full += 1 }
            }
        }
        print("Cold Frame at 500: \(ways.plots) plots, \(claimed) frames claimed, \(full) full, "
              + "\(dryHeld) of \(dryPlaces) under glass (\(dryFill)), "
              + "\(wetHeld) of \(wetPlaces) in the water (\(wetFill))")
        XCTAssertLessThanOrEqual(ways.plots, 17)
        XCTAssertGreaterThan(wetFill, 0.9)
        XCTAssertGreaterThan(dryFill, 0.19)
    }

    /// **The water fills plot by plot**, which is what keeps the area from
    /// being a row of half-empty ponds: a lily takes the first free place in
    /// the oldest tank, so at most one tank is part full and every tank after
    /// it is empty.
    func testATankFillsBeforeTheNextOneIsUsed() {
        let ways = Self.full
        let lilies = (0..<ways.plots).map { plot in
            ways.plot(plot).filter { !$0.slot.frame.isDry }.count
        }
        print("Cold Frame at 500: tanks hold \(lilies)")
        let firstShort = lilies.firstIndex { $0 < ColdFrame.tankPlaces } ?? lilies.count
        for plot in 0..<firstShort {
            XCTAssertEqual(lilies[plot], ColdFrame.tankPlaces)
        }
        for plot in (firstShort + 1)..<lilies.count {
            XCTAssertEqual(lilies[plot], 0, "plot \(plot)'s tank was used before plot \(firstShort)'s was full")
        }
    }

    /// 472 of 501, where it was 485 before the plants' shapes changed on 24
    /// September 2026, and 479 of 500 on a fresh sample. **The plants crowd
    /// the cut now**: two in five of them stand within 5 cm of it, and a plant
    /// near the cut is the one sent to the other rank when its own is full.
    /// Measured by the port over this sample and a fresh one, no cut does
    /// better than the median — 0.37 m gives 476 and 473, 0.39 m 465 and 479
    /// — so the floor follows the measurement rather than the cut moving to
    /// meet the floor.
    ///
    /// **448 since a lotus takes two places**, on 25 September 2026. Three in
    /// four lotuses belong in the front rank, and a front rank holds three of
    /// them where it held six plants, so it fills sooner and more of what
    /// arrives after it is sent behind. The price of the pads' room; the floor
    /// follows it.
    ///
    /// **Asked only of the plants under glass, since 27 September 2026.** A
    /// rank is a grading by height and the tank has no ranks, so counting a
    /// lily's `.front` as a rank it asked for would measure nothing.
    ///
    /// **219 of 227**, the best this area has measured. Two things moved at
    /// once: the two-place rule never fires under glass now, so a front rank
    /// holds six plants again rather than three lotuses; and the cut moved to
    /// the dry median, so the two ranks are asked for about equally instead of
    /// four plants in five asking for the back. At the old cut of 0.38 this
    /// was 197 of 227.
    func testNearlyEveryPlantHasTheRankItsHeightAsksFor() {
        let dry = Self.full.plantings.filter { $0.slot.frame.isDry }
        let own = dry.filter { $0.slot.rank == $0.traits.frameRank }.count
        let share = Double(own) / Double(dry.count)
        print("Cold Frame at 500: \(own) of \(dry.count) under glass in their own rank")
        XCTAssertGreaterThan(share, 0.94)
    }

    /// The cut is the median of this area's plants, so it halves them. Held
    /// here because the sample is what it was measured on, and a sample that
    /// drifted from it would mean the cut no longer says what its comment does.
    func testTheCutDividesTheAreasOwnPlantsInHalf() {
        let dry = Self.arrivals().filter { !$0.1.wantsWater }.map(\.1.height).sorted()
        let all = Self.arrivals().map(\.1.height).sorted()
        print("Cold Frame cut: \(dry.count) dry of \(all.count), "
              + "dry median \(dry[dry.count / 2]), all median \(all[all.count / 2])")
        let back = Double(dry.filter { $0 >= ColdFrame.backFrom }.count) / Double(dry.count)
        XCTAssertEqual(back, 0.5, accuracy: 0.03)
    }

    /// **The ambassador is in the water**, so the first plant under glass
    /// claims the first frame however the room was opened. A second of its
    /// colour joins it rather than claiming another.
    func testAClaimedFrameIsFilledBeforeAnotherIsClaimed() {
        var ways = ColdFrame.Ways.opened()
        XCTAssertFalse(ColdFrame.ambassador.slot.frame.isDry)
        let first = ways.plant(seed: SeedMint.mint(fromEntropy: Data("cf-first".utf8)),
                               traits: PlantTraits(height: 0.6, family: 2))
        XCTAssertEqual(first.slot.frame, .backWest)
        let second = ways.plant(seed: SeedMint.mint(fromEntropy: Data("cf-same".utf8)),
                                traits: PlantTraits(height: 0.6, family: 2))
        XCTAssertEqual(second.plot, 0)
        XCTAssertEqual(second.slot.frame, first.slot.frame)
        // A plant of another colour claims the next frame.
        let third = ways.plant(seed: SeedMint.mint(fromEntropy: Data("cf-other".utf8)),
                               traits: PlantTraits(height: 0.6, family: 3))
        XCTAssertEqual(third.slot.frame, .backEast)
    }

    func testAFifthColourOpensASecondPlot() {
        var ways = ColdFrame.Ways()
        for family in 0..<5 {
            ways.plant(seed: SeedMint.mint(fromEntropy: Data("cf-colour-\(family)".utf8)),
                       traits: PlantTraits(height: 0.9, family: family))
        }
        XCTAssertEqual(ways.plots, 2)
        XCTAssertEqual(ways.plantings.last?.slot, ColdFrame.Slot(frame: .backWest, rank: .back, index: 0))
    }

    func testAFullFrontRankSendsAPlantBackOnlyIfItStaysInOrder() {
        var ways = ColdFrame.Ways()
        let seed = { (n: Int) in SeedMint.mint(fromEntropy: Data("cf-order-\(n)".utf8)) }
        for n in 0..<6 { ways.plant(seed: seed(n), traits: PlantTraits(height: 0.30, family: 2)) }
        // The front rank is full. A 0.35 m plant asks for the front and is
        // taller than all of it, so it may stand at the back.
        let displaced = ways.plant(seed: seed(6), traits: PlantTraits(height: 0.35, family: 2))
        XCTAssertEqual(displaced.slot, ColdFrame.Slot(frame: .backWest, rank: .back, index: 0))
        // A 0.25 m plant is shorter than the front rank, and at the back it
        // would stand behind taller plants, so it claims the next frame.
        let shorter = ways.plant(seed: seed(7), traits: PlantTraits(height: 0.25, family: 2))
        XCTAssertEqual(shorter.slot, ColdFrame.Slot(frame: .backEast, rank: .front, index: 0))
    }

    func testAFullBackRankSendsAPlantForwardOnlyIfItStaysInOrder() {
        var ways = ColdFrame.Ways()
        let seed = { (n: Int) in SeedMint.mint(fromEntropy: Data("cf-full-\(n)".utf8)) }
        for n in 0..<6 { ways.plant(seed: seed(n), traits: PlantTraits(height: 1.2, family: 3)) }
        // As tall as the back rank and no taller: it may stand in front of it.
        let seventh = ways.plant(seed: seed(6), traits: PlantTraits(height: 1.2, family: 3))
        XCTAssertEqual(seventh.slot, ColdFrame.Slot(frame: .backWest, rank: .front, index: 0))
        // Taller than the back rank: it may not, and claims the next frame.
        let eighth = ways.plant(seed: seed(7), traits: PlantTraits(height: 1.3, family: 3))
        XCTAssertEqual(eighth.slot, ColdFrame.Slot(frame: .backEast, rank: .back, index: 0))
    }

    func testThePlaceIsTheSameWhateverOrderTheTestsRunIn() {
        // `place(for:)` asks and does not plant.
        let ways = Self.filled(40)
        let traits = PlantTraits(height: 0.7, family: 1)
        XCTAssertEqual(ways.place(for: traits).plot, ways.place(for: traits).plot)
        XCTAssertEqual(ways.place(for: traits).slot, ways.place(for: traits).slot)
    }

    func testThePlacementIsAppendOnly() {
        let early = Self.filled(120).plantings
        let late = Self.full.plantings
        XCTAssertEqual(Array(late.prefix(early.count)), early)
    }

    // MARK: A lily is in the water

    private static func lotus(_ height: Double, _ family: Int) -> PlantTraits {
        PlantTraits(height: height, family: family, habit: Archetype.lotus.rawValue)
    }

    /// **Every water lily is in the tank and nothing else is**, since 27
    /// September 2026. It is the whole of the water rule, and it makes the
    /// two-place rule under glass unreachable here: the only plant that ever
    /// held two places is the one that no longer stands in a frame.
    ///
    /// The two-place machinery stays where it is. `span` is a stored field
    /// and rows written before today hold lilies under glass with a span of
    /// two, which must keep reading back and keep drawing until the replant
    /// moves them — `testAPlantingStoredBeforeTheRuleHoldsOnePlace` is the
    /// one that holds that.
    ///
    /// **Everything that wants water, since 28 September 2026**, when the
    /// reed joined the lily in `Archetype.wantsWater`. Asked of
    /// `traits.wantsWater`, which is what the rule asks, rather than of the
    /// lotus by name: a reed in the tank holds one place, as a lily does, and
    /// a reed under glass would be the rule broken. The count that follows was
    /// of lilies, over 200 of some 274; it is of everything in the water now,
    /// 343 of 501, the ambassador among them.
    func testEverythingThatWantsWaterIsInTheWaterAndNothingElseIs() {
        let ways = Self.full
        var wet = 0
        for p in ways.plantings {
            let wantsWater = p.traits.wantsWater
            XCTAssertEqual(p.slot.frame.isDry, !wantsWater, "\(p.seed) is in the wrong element")
            XCTAssertEqual(p.span, 1, "\(p.seed) holds \(p.span) places")
            XCTAssertLessThan(p.slot.index + p.span, p.slot.frame.places + 1, "\(p.seed) runs off its row")
            let first = p.slots.first!.spot, last = p.slots.last!.spot
            XCTAssertEqual(p.spot.x - p.nudge.x, (first.x + last.x) / 2, accuracy: 1e-12)
            XCTAssertEqual(p.spot.z - p.nudge.z, first.z, accuracy: 1e-12)
            if wantsWater { wet += 1 }
        }
        XCTAssertGreaterThan(wet, 300, "a sample of this area's own plants is two in three for the water")
    }

    /// **The reason for the rule, held as a test**: of five hundred plants
    /// drawn young, as the page draws them, a quarter stood with their stem
    /// inside a lotus's pads, and now one does.
    ///
    /// **One, not none, and the one is the rule working as designed.** A
    /// lotus among the widest tenth, its pads reaching 0.44 m, with a fern in
    /// the next place of its rank, the two nudged 0.02 m toward each other.
    /// The simulation Marcus chose from found the same one case, a lotus over
    /// a fern in its own rank. Held under one in a hundred, so a rule that let
    /// a plant into a lotus's second place again would fail it many times over.
    func testNoStemStandsInsideALotussPads() {
        let genomes = [Ambassadors.of(.waiting).genome] + Self.genomes()
        let plants = zip(Self.full.plantings, genomes).map { (p, g) in (seed: p.seed, plot: p.plot, spot: p.spot, genome: g) }
        let crowded = LotusPads.crowded(plants, growth: { _ in ColdFrame.drawn })
        let stems = Set(crowded.map(\.stem)).count
        print("Cold Frame at 500: \(stems) stems inside a lotus's pads")
        XCTAssertLessThanOrEqual(stems, plants.count / 100, crowded.prefix(5).map(\.description).joined(separator: "; "))
    }

    /// **No two lilies float closer than the tank was measured for.** 0.62 m
    /// between places is the gap a lotus's pads were measured against on 25
    /// September, and the two nudges can take 0.06 m off it and no more.
    func testNoTwoLiliesFloatCloserThanTheTankAllows() {
        let ways = Self.full
        let least = ColdFrame.tankGap - 0.06
        for plot in 0..<ways.plots {
            let water = ways.plot(plot).filter { !$0.slot.frame.isDry }
            for (i, lily) in water.enumerated() {
                for other in water[(i + 1)...] {
                    let gap = hypot(other.spot.x - lily.spot.x, other.spot.z - lily.spot.z)
                    XCTAssertGreaterThanOrEqual(gap, least - 1e-12,
                                                "\(other.seed) floats into \(lily.seed)")
                }
            }
        }
    }

    /// **The tank fills along its rows from the west**, the way a frame's
    /// rank does: seven places to a row, then the next row back.
    func testTheTankFillsAlongItsRowsFromTheWest() {
        var ways = ColdFrame.Ways()
        let seed = { (n: Int) in SeedMint.mint(fromEntropy: Data("cf-lily-\(n)".utf8)) }
        for n in 0..<ColdFrame.tankPlaces {
            let lily = ways.plant(seed: seed(n), traits: Self.lotus(0.30, n % 7))
            XCTAssertEqual(lily.slot, ColdFrame.Slot(frame: .tank, rank: .front, index: n))
            XCTAssertEqual(lily.span, 1)
        }
        // The eighth place is the west end of the second row, a row's depth
        // behind the first.
        let first = ColdFrame.Slot(frame: .tank, rank: .front, index: 0).spot
        let eighth = ColdFrame.Slot(frame: .tank, rank: .front, index: ColdFrame.tankWide).spot
        XCTAssertEqual(eighth.x, first.x, accuracy: 1e-12)
        XCTAssertEqual(eighth.z - first.z, ColdFrame.tankGap, accuracy: 1e-12)
        // And no frame was touched to hold twenty-one lilies.
        XCTAssertTrue(ways.plantings.allSatisfy { !$0.slot.frame.isDry })
        XCTAssertEqual(ways.plots, 1)
    }

    /// **A full tank opens a new plot rather than putting a lily under
    /// glass.** The frames are graded by colour and by height and a lily is
    /// sorted by neither, so there is no frame for it to fall back to — which
    /// is why a plot's water is always full before the next plot's is used.
    func testAFullTankOpensANewPlotRatherThanPuttingALilyUnderGlass() {
        var ways = ColdFrame.Ways()
        let seed = { (n: Int) in SeedMint.mint(fromEntropy: Data("cf-full-tank-\(n)".utf8)) }
        for n in 0..<ColdFrame.tankPlaces { ways.plant(seed: seed(n), traits: Self.lotus(0.30, 2)) }
        XCTAssertEqual(ways.plots, 1)
        let over = ways.plant(seed: seed(99), traits: Self.lotus(0.30, 2))
        XCTAssertEqual(over.plot, 1)
        XCTAssertEqual(over.slot, ColdFrame.Slot(frame: .tank, rank: .front, index: 0))
        XCTAssertEqual(ways.plots, 2)
        // The four frames of the first plot are still empty, though a plant
        // of that colour could have stood in one.
        XCTAssertTrue(ways.plot(0).allSatisfy { !$0.slot.frame.isDry })
    }

    /// **A planting stored before 25 September holds the one place it was
    /// given**, lotus or not, until the replant places it again; the next
    /// arrival takes the place after it.
    ///
    /// Since 27 September the next arrival, if it is a lily, takes the water
    /// instead — but a row already written with a lily under glass still
    /// decodes and still draws where it was put. That is what this holds, and
    /// it is the reason the two-place machinery stays in the source.
    func testAPlantingStoredBeforeTheRuleHoldsOnePlace() throws {
        var old = ColdFrame.Ways()
        let seed = { (n: Int) in SeedMint.mint(fromEntropy: Data("cf-old-\(n)".utf8)) }
        // As the old rule placed it: a lotus in one place, stored without a span.
        old.plant(seed: seed(0), traits: PlantTraits(height: 0.30, family: 2))
        var json = String(decoding: try JSONEncoder().encode(old), as: UTF8.self)
        json = json.replacingOccurrences(of: #""span":1,"#, with: "")
            .replacingOccurrences(of: #","span":1"#, with: "")
        XCTAssertFalse(json.contains("span"))
        var ways = try JSONDecoder().decode(ColdFrame.Ways.self, from: Data(json.utf8))
        XCTAssertEqual(ways.plantings[0].span, 1)
        // And the rule as it stands now puts the next lily in the water.
        let lotus = ways.plant(seed: seed(1), traits: Self.lotus(0.30, 2))
        XCTAssertEqual(lotus.slot, ColdFrame.Slot(frame: .tank, rank: .front, index: 0))
        XCTAssertEqual(lotus.span, 1)
    }

    /// **A lily under glass, as the live store still holds it, keeps its two
    /// places.** `span` is read back from the row rather than recomputed, so
    /// the pads a planting was given room for are the pads it is drawn with.
    func testALilyStoredUnderGlassKeepsItsTwoPlaces() throws {
        let slot = ColdFrame.Slot(frame: .backWest, rank: .front, index: 0)
        let planting = ColdFrame.Planting(seed: "ab", plot: 0, slot: slot, span: 2,
                                          traits: Self.lotus(0.30, 2), nudge: Spot(x: 0, z: 0))
        let back = try JSONDecoder().decode(ColdFrame.Planting.self,
                                            from: JSONEncoder().encode(planting))
        XCTAssertEqual(back.span, 2)
        XCTAssertEqual(back.slots.map(\.index), [0, 1])
        XCTAssertEqual(back.spot.x, (slot.spot.x + ColdFrame.alongGap / 2), accuracy: 1e-12)
    }

    // MARK: The ambassador

    /// **The ambassador is a water lily, so it opens the tank rather than a
    /// frame.** *Nyxisora crassicaulis* is the plant the Cold Frame is drawn
    /// with before anybody has released anything into it, and `Nyx` is the
    /// lotus's own root — the reason this area receives lilies at all is the
    /// reason its ambassador is one.
    func testTheAmbassadorOpensTheTank() {
        let one = ColdFrame.ambassador
        let traits = LongWalk.traits(of: Ambassadors.of(.waiting).genome)
        XCTAssertEqual(traits.habit, Archetype.lotus.rawValue)
        XCTAssertEqual(one.plot, 0)
        XCTAssertEqual(one.slot.frame, .tank)
        XCTAssertEqual(one.slot.rank, .front)
        XCTAssertEqual(one.slot.index, 0)
        XCTAssertEqual(one.seed, Ambassadors.of(.waiting).seed.hex)
        // One place, at the west end of the first row, in the water.
        XCTAssertEqual(one.span, 1)
        XCTAssertEqual(one.spot.z - one.nudge.z, -ColdFrame.tankGap, accuracy: 1e-12)
    }

    // MARK: Drawn young

    /// **Every plant stands under the glass above it**, drawn young, with the
    /// lid propped — the finding the drawn stage was chosen by, held as a test.
    ///
    /// The glass is lowest at the front, and the front rank is the one whose
    /// plants will grow shortest, which is why this holds with one stage for
    /// every plant: a young plant's height follows its grown one closely
    /// enough that grading the ranks by the one grades them by the other.
    ///
    /// **A seedling is big enough to read by its larger extent, not its
    /// height.** Since 24 September 2026 a lotus is a water lily, its pads
    /// lying on the soil, and drawn young it stands 0.05 m high and 0.26 m or
    /// more across. Low and broad is the habit, not a seedling too small to
    /// see, so the floor asks how large a young plant is in whichever direction
    /// it has grown. A height floor would have called the broadest seedlings
    /// in the frame the smallest.
    func testEveryPlantDrawnYoungStandsUnderItsGlass() {
        let genomes = Self.genomes()
        let ways = Self.full
        var shortest = Double.greatestFiniteMagnitude
        var smallest = Double.greatestFiniteMagnitude
        var tallestBy: [ColdFrame.Rank: Double] = [:]
        for (planting, genome) in zip(ways.plantings.dropFirst(), genomes) {
            let mesh = PlantBuilder(genome: genome).mesh(growth: ColdFrame.drawn)
            // **A lily in the tank has the sky over it**, so the only floor
            // it answers to is the one below, and the measurement is still
            // made of it: it is a plant in this area and has to read as one.
            guard planting.slot.frame.isDry else {
                let tall = Double(mesh.maxBounds.y - mesh.minBounds.y)
                let across = Double(max(mesh.maxBounds.x - mesh.minBounds.x,
                                        mesh.maxBounds.z - mesh.minBounds.z))
                shortest = min(shortest, tall)
                smallest = min(smallest, max(tall, across))
                continue
            }
            let tall = Double(mesh.maxBounds.y - mesh.minBounds.y)
            let across = Double(max(mesh.maxBounds.x - mesh.minBounds.x, mesh.maxBounds.z - mesh.minBounds.z))
            shortest = min(shortest, tall)
            smallest = min(smallest, max(tall, across))
            tallestBy[planting.slot.rank] = max(tallestBy[planting.slot.rank] ?? 0, tall)
            let depth = planting.spot.z - planting.slot.frame.centre.z
            XCTAssertLessThan(tall, ColdFrame.glass(atDepth: depth) - 0.02,
                              "\(planting.seed) stands \(tall) m under glass at \(ColdFrame.glass(atDepth: depth)) m")
        }
        print("Cold Frame drawn young: shortest \(shortest), smallest \(smallest), tallest front \(tallestBy[.front] ?? 0), back \(tallestBy[.back] ?? 0)")
        XCTAssertGreaterThan(smallest, 0.08, "the smallest seedling is too small to read as a plant")
    }

    func testTheDrawnStageIsYoungAndInBud() {
        let state = ColdFrame.drawn
        XCTAssertGreaterThanOrEqual(state.heightScale, 0.25, "below 0.25 the seed's husk is drawn")
        XCTAssertLessThan(state.heightScale, 0.5)
        XCTAssertGreaterThan(state.budSwell, 0.02, "no bud, and the colour that claims a frame cannot be seen")
        XCTAssertEqual(state.bloomOpen, 0)
    }

    func testTheGlassSlopesDownToTheFrontAndIsNeverBelowTheWall() {
        XCTAssertEqual(ColdFrame.glass(atDepth: -ColdFrame.frameDepth / 2), ColdFrame.backWall, accuracy: 1e-12)
        XCTAssertEqual(ColdFrame.glass(atDepth: ColdFrame.frameDepth / 2),
                       ColdFrame.frontWall + ColdFrame.propped, accuracy: 1e-12)
        XCTAssertGreaterThan(ColdFrame.glass(atDepth: -ColdFrame.rankFrom),
                             ColdFrame.glass(atDepth: ColdFrame.rankFrom))
    }
}
