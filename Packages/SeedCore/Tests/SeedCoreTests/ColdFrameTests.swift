import XCTest
@testable import SeedCore

/// The seventh area: four frames, a colour to a frame, two ranks graded by what
/// each plant will grow into, and every plant drawn young.
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

    func testAPlotHoldsFourFramesOfTwelveAndNoMore() {
        XCTAssertEqual(ColdFrame.slots.count, 48)
        XCTAssertEqual(Set(ColdFrame.slots).count, 48)
        let ways = Self.full
        for plot in 0..<ways.plots {
            // Asked of the places held rather than the plants, since a lotus
            // holds two.
            let held = ways.plot(plot).flatMap(\.slots)
            XCTAssertLessThanOrEqual(held.count, 48, "plot \(plot) holds \(held.count) places")
            XCTAssertEqual(Set(held).count, held.count, "two plants hold one place in plot \(plot)")
            for frame in ColdFrame.Frame.allCases {
                for rank in ColdFrame.Rank.allCases {
                    let row = held.filter { $0.frame == frame && $0.rank == rank }
                    XCTAssertLessThanOrEqual(row.count, ColdFrame.places)
                    // A rank fills from its west end, so its places are 0..<n.
                    XCTAssertEqual(Set(row.map(\.index)), Set(0..<row.count),
                                   "plot \(plot) \(frame) \(rank) has a gap in it")
                }
            }
        }
    }

    func testEveryPlaceStandsInsideItsFrameWellClearOfTheWalls() {
        let wall = 0.05, nudge = 0.03
        for slot in ColdFrame.slots {
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

    func testTheBackRankIsFurtherBackThanTheFrontInEveryFrame() {
        for frame in ColdFrame.Frame.allCases {
            let front = ColdFrame.Slot(frame: frame, rank: .front, index: 0).spot.z
            let back = ColdFrame.Slot(frame: frame, rank: .back, index: 0).spot.z
            XCTAssertLessThan(back, front, "\(frame)'s back rank is in front")
        }
    }

    // MARK: The rule

    func testAFrameHoldsOneColour() {
        let ways = Self.full
        for plot in 0..<ways.plots {
            for frame in ColdFrame.Frame.allCases {
                let families = Set(ways.plot(plot).filter { $0.slot.frame == frame }.map(\.traits.family))
                XCTAssertLessThanOrEqual(families.count, 1, "plot \(plot) \(frame) holds \(families)")
            }
        }
    }

    func testNothingInTheFrontRankIsTallerThanAnythingAtTheBack() {
        let ways = Self.full
        for plot in 0..<ways.plots {
            for frame in ColdFrame.Frame.allCases {
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
    /// twenty-eight plants to a plot where there were forty-two. The
    /// simulation Marcus chose it from, on a sample of its own, gave eighteen
    /// plots too.
    func testTheFillAtFiveHundred() {
        let ways = Self.full
        let places = ways.plots * ColdFrame.slots.count
        let held = ways.plantings.map(\.span).reduce(0, +)
        let fill = Double(held) / Double(places)
        var claimed = 0, full = 0
        for plot in 0..<ways.plots {
            for frame in ColdFrame.Frame.allCases {
                let count = ways.plot(plot).filter { $0.slot.frame == frame }.map(\.span).reduce(0, +)
                if count > 0 { claimed += 1 }
                if count == 12 { full += 1 }
            }
        }
        let lotuses = ways.plantings.filter { $0.span == 2 }.count
        print("Cold Frame at 500: \(ways.plots) plots, \(claimed) frames claimed, \(full) full, "
              + "\(held) places held of \(places) (\(fill)), \(lotuses) lotuses")
        XCTAssertLessThanOrEqual(ways.plots, 19)
        XCTAssertGreaterThan(fill, 0.8)
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
    func testNearlyEveryPlantHasTheRankItsHeightAsksFor() {
        let own = Self.full.plantings.filter { $0.slot.rank == $0.traits.frameRank }.count
        let share = Double(own) / Double(Self.full.plantings.count)
        print("Cold Frame at 500: \(own) of \(Self.full.plantings.count) in their own rank")
        XCTAssertGreaterThan(share, 0.88)
    }

    /// The cut is the median of this area's plants, so it halves them. Held
    /// here because the sample is what it was measured on, and a sample that
    /// drifted from it would mean the cut no longer says what its comment does.
    func testTheCutDividesTheAreasOwnPlantsInHalf() {
        let heights = Self.arrivals().map(\.1.height)
        let back = Double(heights.filter { $0 >= ColdFrame.backFrom }.count) / Double(heights.count)
        XCTAssertEqual(back, 0.5, accuracy: 0.03)
    }

    func testAClaimedFrameIsFilledBeforeAnotherIsClaimed() {
        // A second plant of the ambassador's colour joins its frame rather than
        // claiming another.
        var ways = ColdFrame.Ways.opened()
        let first = ColdFrame.ambassador
        let second = ways.plant(seed: SeedMint.mint(fromEntropy: Data("cf-same".utf8)),
                                traits: PlantTraits(height: 0.6, family: first.traits.family))
        XCTAssertEqual(second.plot, 0)
        XCTAssertEqual(second.slot.frame, first.slot.frame)
        // A plant of another colour claims the next frame.
        let other = (first.traits.family + 1) % 7
        let third = ways.plant(seed: SeedMint.mint(fromEntropy: Data("cf-other".utf8)),
                               traits: PlantTraits(height: 0.6, family: other))
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

    // MARK: A lotus takes two places

    private static func lotus(_ height: Double, _ family: Int) -> PlantTraits {
        PlantTraits(height: height, family: family, habit: Archetype.lotus.rawValue)
    }

    /// Every lotus holds two neighbouring places in one rank and stands at
    /// their middle; every other plant holds one and stands on it.
    func testALotusStandsCentredAcrossTwoPlaces() {
        let ways = Self.full
        var lotuses = 0
        for p in ways.plantings {
            let isLotus = p.traits.habit == Archetype.lotus.rawValue
            XCTAssertEqual(p.span, isLotus ? 2 : 1, "\(p.seed) holds \(p.span) places")
            XCTAssertLessThanOrEqual(p.slot.index + p.span, ColdFrame.places, "\(p.seed) runs off its rank")
            let first = p.slots.first!.spot, last = p.slots.last!.spot
            XCTAssertEqual(p.spot.x - p.nudge.x, (first.x + last.x) / 2, accuracy: 1e-12)
            XCTAssertEqual(p.spot.z - p.nudge.z, first.z, accuracy: 1e-12)
            if isLotus { lotuses += 1 }
        }
        XCTAssertGreaterThan(lotuses, 200, "a sample of this area's own plants is more than half lotuses")
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

    /// No stem stands between the two places a lotus holds, or nearer its own
    /// than a place and a half, less the two nudges.
    func testNoStemStandsInALotussPair() {
        let ways = Self.full
        for plot in 0..<ways.plots {
            let here = ways.plot(plot)
            for lotus in here where lotus.span == 2 {
                for other in here where other.seed != lotus.seed
                    && other.slot.frame == lotus.slot.frame && other.slot.rank == lotus.slot.rank {
                    let gap = abs(other.spot.x - lotus.spot.x)
                    let least = (1 + Double(other.span) / 2) * ColdFrame.alongGap - 0.06
                    XCTAssertGreaterThanOrEqual(gap, least - 1e-12, "\(other.seed) stands in \(lotus.seed)'s pair")
                }
            }
        }
    }

    /// The second place a lotus holds is never given to a later plant: the
    /// next plant in the rank takes the place after it.
    func testALotussSecondPlaceIsNeverGivenAway() {
        var ways = ColdFrame.Ways()
        let seed = { (n: Int) in SeedMint.mint(fromEntropy: Data("cf-lotus-\(n)".utf8)) }
        let first = ways.plant(seed: seed(0), traits: Self.lotus(0.30, 2))
        XCTAssertEqual(first.slots, [ColdFrame.Slot(frame: .backWest, rank: .front, index: 0),
                                     ColdFrame.Slot(frame: .backWest, rank: .front, index: 1)])
        let second = ways.plant(seed: seed(1), traits: PlantTraits(height: 0.30, family: 2))
        XCTAssertEqual(second.slot, ColdFrame.Slot(frame: .backWest, rank: .front, index: 2))
        let third = ways.plant(seed: seed(2), traits: Self.lotus(0.31, 2))
        XCTAssertEqual(third.slots.map(\.index), [3, 4])
        // And across five hundred no place is held twice, which
        // `testAPlotHoldsFourFramesOfTwelveAndNoMore` asks of every plot.
    }

    /// **A rank's last single place is no place for a lotus**, which goes on
    /// to the next choice as a plant finding the rank full does. The place is
    /// not given up: the next plant of one place takes it.
    func testTheLastPlaceOfARankWaitsForAPlantOfOne() {
        var ways = ColdFrame.Ways()
        let seed = { (n: Int) in SeedMint.mint(fromEntropy: Data("cf-last-\(n)".utf8)) }
        for n in 0..<5 { ways.plant(seed: seed(n), traits: PlantTraits(height: 0.30, family: 2)) }
        // One place left in the front rank. A lotus as tall as the rank may
        // stand behind it, and does.
        let behind = ways.plant(seed: seed(5), traits: Self.lotus(0.30, 2))
        XCTAssertEqual(behind.slots.map(\.index), [0, 1])
        XCTAssertEqual(behind.slot.rank, .back)
        // A shorter one may not stand behind it, and claims the next frame.
        let next = ways.plant(seed: seed(6), traits: Self.lotus(0.25, 2))
        XCTAssertEqual(next.slot, ColdFrame.Slot(frame: .backEast, rank: .front, index: 0))
        // The last place is still there for a plant of one.
        let one = ways.plant(seed: seed(7), traits: PlantTraits(height: 0.29, family: 2))
        XCTAssertEqual(one.slot, ColdFrame.Slot(frame: .backWest, rank: .front, index: 5))
    }

    /// **A planting stored before 25 September holds the one place it was
    /// given**, lotus or not, until the replant places it again; the next
    /// arrival takes the place after it.
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
        let lotus = ways.plant(seed: seed(1), traits: Self.lotus(0.30, 2))
        XCTAssertEqual(lotus.slots.map(\.index), [1, 2])
    }

    // MARK: The ambassador

    func testTheAmbassadorOpensTheFirstFrame() {
        let one = ColdFrame.ambassador
        let traits = LongWalk.traits(of: Ambassadors.of(.waiting).genome)
        XCTAssertEqual(one.plot, 0)
        XCTAssertEqual(one.slot.frame, .backWest)
        XCTAssertEqual(one.slot.rank, traits.frameRank)
        XCTAssertEqual(one.slot.index, 0)
        XCTAssertEqual(one.seed, Ambassadors.of(.waiting).seed.hex)
        // *Nyxisora crassicaulis* is a lotus, so since 25 September it holds
        // the first two places of its rank and stands between them.
        XCTAssertEqual(traits.habit, Archetype.lotus.rawValue)
        XCTAssertEqual(one.span, 2)
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
