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
            let here = ways.plot(plot)
            XCTAssertLessThanOrEqual(here.count, 48, "plot \(plot) holds \(here.count)")
            XCTAssertEqual(Set(here.map(\.slot)).count, here.count, "two plants in one place in plot \(plot)")
            for frame in ColdFrame.Frame.allCases {
                for rank in ColdFrame.Rank.allCases {
                    let row = here.filter { $0.slot.frame == frame && $0.slot.rank == rank }
                    XCTAssertLessThanOrEqual(row.count, ColdFrame.places)
                    // A rank fills from its west end, so its indices are 0..<n.
                    XCTAssertEqual(Set(row.map(\.slot.index)), Set(0..<row.count),
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
    /// them. At five hundred it is twelve plots, and 87% of every place holds a
    /// plant.
    func testTheFillAtFiveHundred() {
        let ways = Self.full
        let places = ways.plots * ColdFrame.slots.count
        let fill = Double(ways.plantings.count) / Double(places)
        var claimed = 0, full = 0
        for plot in 0..<ways.plots {
            for frame in ColdFrame.Frame.allCases {
                let count = ways.plot(plot).filter { $0.slot.frame == frame }.count
                if count > 0 { claimed += 1 }
                if count == 12 { full += 1 }
            }
        }
        print("Cold Frame at 500: \(ways.plots) plots, \(claimed) frames claimed, \(full) full, fill \(fill)")
        XCTAssertLessThanOrEqual(ways.plots, 13)
        XCTAssertGreaterThan(fill, 0.8)
    }

    func testNearlyEveryPlantHasTheRankItsHeightAsksFor() {
        let own = Self.full.plantings.filter { $0.slot.rank == $0.traits.frameRank }.count
        let share = Double(own) / Double(Self.full.plantings.count)
        print("Cold Frame at 500: \(own) of \(Self.full.plantings.count) in their own rank")
        XCTAssertGreaterThan(share, 0.95)
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
        for n in 0..<6 { ways.plant(seed: seed(n), traits: PlantTraits(height: 0.60, family: 2)) }
        // The front rank is full. A 0.70 m plant asks for the front and is
        // taller than all of it, so it may stand at the back.
        let displaced = ways.plant(seed: seed(6), traits: PlantTraits(height: 0.70, family: 2))
        XCTAssertEqual(displaced.slot, ColdFrame.Slot(frame: .backWest, rank: .back, index: 0))
        // A 0.55 m plant is shorter than the front rank, and at the back it
        // would stand behind taller plants, so it claims the next frame.
        let shorter = ways.plant(seed: seed(7), traits: PlantTraits(height: 0.55, family: 2))
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

    // MARK: The ambassador

    func testTheAmbassadorOpensTheFirstFrame() {
        let one = ColdFrame.ambassador
        let traits = LongWalk.traits(of: Ambassadors.of(.waiting).genome)
        XCTAssertEqual(one.plot, 0)
        XCTAssertEqual(one.slot.frame, .backWest)
        XCTAssertEqual(one.slot.rank, traits.frameRank)
        XCTAssertEqual(one.slot.index, 0)
        XCTAssertEqual(one.seed, Ambassadors.of(.waiting).seed.hex)
    }

    // MARK: Drawn young

    /// **Every plant stands under the glass above it**, drawn young, with the
    /// lid propped — the finding the drawn stage was chosen by, held as a test.
    ///
    /// The glass is lowest at the front, and the front rank is the one whose
    /// plants will grow shortest, which is why this holds with one stage for
    /// every plant: a young plant's height follows its grown one closely
    /// enough that grading the ranks by the one grades them by the other.
    func testEveryPlantDrawnYoungStandsUnderItsGlass() {
        let genomes = Self.genomes()
        let ways = Self.full
        var shortest = Double.greatestFiniteMagnitude
        var tallestBy: [ColdFrame.Rank: Double] = [:]
        for (planting, genome) in zip(ways.plantings.dropFirst(), genomes) {
            let mesh = PlantBuilder(genome: genome).mesh(growth: ColdFrame.drawn)
            let tall = Double(mesh.maxBounds.y - mesh.minBounds.y)
            shortest = min(shortest, tall)
            tallestBy[planting.slot.rank] = max(tallestBy[planting.slot.rank] ?? 0, tall)
            let depth = planting.spot.z - planting.slot.frame.centre.z
            XCTAssertLessThan(tall, ColdFrame.glass(atDepth: depth) - 0.02,
                              "\(planting.seed) stands \(tall) m under glass at \(ColdFrame.glass(atDepth: depth)) m")
        }
        print("Cold Frame drawn young: shortest \(shortest), tallest front \(tallestBy[.front] ?? 0), back \(tallestBy[.back] ?? 0)")
        XCTAssertGreaterThan(shortest, 0.08, "the shortest seedling is too small to read as a plant")
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
