import XCTest
@testable import SeedCore

/// The tenth area: three beds, a crop to a bed, tall from the north end and
/// short from the south.
final class HomeGroundTests: XCTestCase {

    // MARK: Arrivals

    /// **Five hundred plants whose names put them in the Home Ground**, drawn
    /// exactly as `tools/homeground` draws its fresh stream — the same entropy,
    /// the same nonces, in the same order — so the numbers in
    /// `docs/WEB-GARDENS.md` §*The fill, simulated* and the numbers here are
    /// measured on one stream.
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
            let a = SeedMint.mint(fromEntropy: Data("homeground-arrival-\(n)-a".utf8))
            let b = SeedMint.mint(fromEntropy: Data("homeground-arrival-\(n)-b".utf8))
            n += 1
            let meeting = Pollination.encounterID(seedA: a, seedB: b,
                                                  nonceA: Data("a\(n)".utf8), nonceB: Data("b\(n)".utf8))
            let child = Pollination.cross(seedA: a, seedB: b, encounterID: meeting)
            let genome = Genome(seed: child,
                                lineage: .crossed(parentA: a, parentB: b, encounterID: meeting))
            if Area(genome: genome) == .ground { found.append((child, genome)) }
        }
        return found
    }

    private static func make(_ count: Int) -> [(SeedID, PlantTraits)] {
        crossings(count).map { ($0.seed, LongWalk.traits(of: $0.genome)) }
    }

    private static let full: HomeGround.Ways = {
        var ways = HomeGround.Ways.opened()
        for (seed, traits) in arrivals() { ways.plant(seed: seed, traits: traits) }
        return ways
    }()

    static func filled(_ count: Int = 500) -> HomeGround.Ways {
        if count == 500 { return full }
        var ways = HomeGround.Ways.opened()
        for (seed, traits) in arrivals(count) { ways.plant(seed: seed, traits: traits) }
        return ways
    }

    private static func seed(_ label: String, _ n: Int) -> SeedID {
        SeedMint.mint(fromEntropy: Data("homeground-\(label)-\(n)".utf8))
    }
    private static func spire(_ height: Double) -> PlantTraits { PlantTraits(height: height, family: 1, habit: "spire") }
    private static func umbel(_ height: Double) -> PlantTraits { PlantTraits(height: height, family: 3, habit: "umbel") }
    private static func rosette(_ height: Double) -> PlantTraits { PlantTraits(height: height, family: 4, habit: "succulent") }

    // MARK: The area's own plants

    /// **Every plant in the Home Ground is a spire, an umbel or a succulent,
    /// and its habit names its genus root exactly.** A fact of the naming
    /// table, not a tendency of the sample: if this fails, the table has
    /// changed, and with it the reason the crop can be read off the habit.
    func testTheHabitNamesTheGenusRoot() {
        for genome in Self.genomes() {
            let traits = LongWalk.traits(of: genome)
            XCTAssertEqual(traits.crop.rawValue, genome.name.genusHead, genome.name.full)
        }
        let habits = Set(Self.arrivals().map(\.1.habit))
        XCTAssertEqual(habits, ["spire", "umbel", "succulent"])
    }

    /// Each crop's cut divides its own plants in about half: the cuts are the
    /// medians of a different two thousand.
    func testEachCutDividesItsCropInHalf() {
        for crop in HomeGround.Crop.allCases {
            let these = Self.arrivals().map(\.1).filter { $0.crop == crop }
            let north = Double(these.filter { $0.homeGroundEnd == .north }.count) / Double(these.count)
            XCTAssertEqual(north, 0.5, accuracy: 0.08, crop.rawValue)
        }
    }

    // MARK: The plot

    func testABedHoldsItsCropsCount() {
        XCTAssertEqual(HomeGround.Crop.cer.capacity, 27)
        XCTAssertEqual(HomeGround.Crop.fen.capacity, 14)
        XCTAssertEqual(HomeGround.Crop.pell.capacity, 30)
        for crop in HomeGround.Crop.allCases {
            let slots = HomeGround.slots(bed: 1, crop: crop)
            XCTAssertEqual(Set(slots.map(\.spot.x)).count, crop.sown.across)
            XCTAssertEqual(Set(slots.map(\.spot.z)).count, crop.sown.rows)
        }
    }

    /// **Every crop's rows span the same 3.6 m**, centred on the bed, so three
    /// beds of three crops end level at the headlands.
    func testEveryCropsRowsSpanTheSameLength() {
        for crop in HomeGround.Crop.allCases {
            let z = HomeGround.slots(bed: 0, crop: crop).map(\.spot.z)
            XCTAssertEqual(z.min()!, -1.8, accuracy: 1e-9, crop.rawValue)
            XCTAssertEqual(z.max()!, 1.8, accuracy: 1e-9, crop.rawValue)
        }
    }

    /// **Place 0 is the north-west corner and the last place the south-east.**
    /// North is `z−`, west `x−`, and a row runs west to east.
    func testABedIsNumberedFromItsNorthWestCorner() {
        for crop in HomeGround.Crop.allCases {
            let slots = HomeGround.slots(bed: 2, crop: crop)
            let first = slots.first!.spot, last = slots.last!.spot
            XCTAssertEqual(first.z, slots.map(\.spot.z).min()!)
            XCTAssertEqual(first.x, slots.map(\.spot.x).min()!)
            XCTAssertEqual(last.z, slots.map(\.spot.z).max()!)
            XCTAssertEqual(last.x, slots.map(\.spot.x).max()!)
            XCTAssertLessThan(slots[0].spot.x, slots[1].spot.x)
            XCTAssertEqual(slots[0].spot.z, slots[1].spot.z)
        }
    }

    /// **Every place stands inside its bed**, at the worst nudge: the outermost
    /// plant's middle is at least 0.15 m in from the bed's side and 0.28 m from
    /// its end, and every bed is 0.35 m inside the plot.
    func testEveryPlaceStandsInsideItsBed() {
        var side = Double.greatestFiniteMagnitude, end = Double.greatestFiniteMagnitude
        for bed in 0..<HomeGround.beds {
            for crop in HomeGround.Crop.allCases {
                for slot in HomeGround.slots(bed: bed, crop: crop) {
                    let spot = slot.spot
                    side = min(side, HomeGround.bedWidth / 2 - abs(spot.x - HomeGround.bedX[bed]) - HomeGround.nudgeAcross)
                    end = min(end, HomeGround.bedLength / 2 - abs(spot.z) - HomeGround.nudgeDown)
                }
            }
        }
        XCTAssertEqual(side, 0.15, accuracy: 1e-9)
        XCTAssertEqual(end, 0.275, accuracy: 1e-9)
        let outer = HomeGround.bedX.map(abs).max()! + HomeGround.bedWidth / 2
        XCTAssertEqual(HomeGround.plotSide / 2 - outer, 0.35, accuracy: 1e-9)
    }

    /// The paths between beds are 0.45 m.
    func testThePathsAreFortyFiveCentimetres() {
        for i in 1..<HomeGround.beds {
            XCTAssertEqual(HomeGround.bedX[i] - HomeGround.bedX[i - 1] - HomeGround.bedWidth, 0.45, accuracy: 1e-9)
        }
    }

    // MARK: The rule

    func testEveryBedHoldsOneCrop() {
        let ways = Self.full
        for plot in 0..<ways.plots {
            for bed in 0..<HomeGround.beds {
                let here = ways.plot(plot).filter { $0.slot.bed == bed }
                XCTAssertLessThanOrEqual(Set(here.map(\.slot.crop)).count, 1, "plot \(plot) bed \(bed)")
                for planting in here {
                    XCTAssertEqual(planting.traits.crop, planting.slot.crop, planting.seed)
                }
            }
        }
    }

    /// **Everything that came in from the north end is at least as tall as
    /// everything that came in from the south**, in every bed: the whole of the
    /// grading, and as much as an append-only bed can promise.
    func testEveryBedsNorthEndStandsOverItsSouth() {
        let ways = Self.full
        for plot in 0..<ways.plots {
            for bed in 0..<HomeGround.beds {
                let here = ways.plot(plot).filter { $0.slot.bed == bed }
                let north = here.filter { $0.traits.homeGroundEnd == .north }
                let south = here.filter { $0.traits.homeGroundEnd == .south }
                if let lowest = north.map(\.traits.height).min(), let highest = south.map(\.traits.height).max() {
                    XCTAssertGreaterThanOrEqual(lowest, highest, "plot \(plot) bed \(bed)")
                }
                // And each end is a run from its own end of the bed.
                guard let crop = here.first?.slot.crop else { continue }
                XCTAssertEqual(Set(north.map(\.slot.index)), Set(0..<north.count), "plot \(plot) bed \(bed) north")
                XCTAssertEqual(Set(south.map(\.slot.index)),
                               Set((crop.capacity - south.count)..<crop.capacity), "plot \(plot) bed \(bed) south")
            }
        }
    }

    /// **Nothing is ever displaced, and nothing stands twice in one place.**
    func testNoPlaceIsTakenTwice() {
        let ways = Self.full
        for plot in 0..<ways.plots {
            let here = ways.plot(plot)
            XCTAssertEqual(Set(here.map(\.slot)).count, here.count, "plot \(plot)")
        }
    }

    /// **The number the design was chosen by.** Simulated before the rule was
    /// written, on these same five hundred after the ambassador: 9 plots, 7 of
    /// them full, 26 beds sown and 23 full — 6 of spires, 13 of umbels, 7 of
    /// rosettes — 90% of places in sown beds held, and 4 plots holding all
    /// three crops. The simulation's rule D exactly.
    func testTheFillAtFiveHundred() {
        let ways = Self.full
        XCTAssertEqual(ways.plantings.count, 501)
        XCTAssertEqual(ways.plots, 9)
        var sown = 0, fullBeds = 0, places = 0, fullPlots = 0, allThree = 0
        var byCrop: [HomeGround.Crop: Int] = [:]
        for plot in 0..<ways.plots {
            var crops = Set<HomeGround.Crop>(), plotFull = true
            for bed in 0..<HomeGround.beds {
                guard let crop = ways.crop(of: bed, in: plot) else { plotFull = false; continue }
                let count = ways.plot(plot).filter { $0.slot.bed == bed }.count
                sown += 1
                places += crop.capacity
                byCrop[crop, default: 0] += 1
                crops.insert(crop)
                if count == crop.capacity { fullBeds += 1 } else { plotFull = false }
            }
            if plotFull { fullPlots += 1 }
            if crops.count == 3 { allThree += 1 }
        }
        XCTAssertEqual(fullPlots, 7)
        XCTAssertEqual(sown, 26)
        XCTAssertEqual(fullBeds, 23)
        XCTAssertEqual(byCrop, [.cer: 6, .fen: 13, .pell: 7])
        XCTAssertEqual(allThree, 4)
        XCTAssertEqual(Double(ways.plantings.count) / Double(places), 0.90, accuracy: 0.005)
    }

    func testAPlantTakesABedOfItsCropBeforeAnUnsownOne() {
        var ways = HomeGround.Ways()
        ways.plant(seed: Self.seed("a", 0), traits: Self.umbel(1.0))
        let spire = ways.plant(seed: Self.seed("a", 1), traits: Self.spire(1.5))
        XCTAssertEqual(spire.slot, HomeGround.Slot(bed: 1, crop: .cer, index: 0))
        let umbel = ways.plant(seed: Self.seed("a", 2), traits: Self.umbel(1.2))
        XCTAssertEqual(umbel.slot, HomeGround.Slot(bed: 0, crop: .fen, index: 1))
        let rosette = ways.plant(seed: Self.seed("a", 3), traits: Self.rosette(0.1))
        XCTAssertEqual(rosette.slot, HomeGround.Slot(bed: 2, crop: .pell, index: 29))
        // Every bed claimed: a fourth crop's worth of umbels fills bed 0, and
        // the next opens a new plot.
        for i in 0..<12 { ways.plant(seed: Self.seed("b", i), traits: Self.umbel(0.5)) }
        XCTAssertEqual(ways.plot(0).filter { $0.slot.bed == 0 }.count, 14)
        let next = ways.plant(seed: Self.seed("c", 0), traits: Self.umbel(0.5))
        XCTAssertEqual(next.plot, 1)
        XCTAssertEqual(next.slot, HomeGround.Slot(bed: 0, crop: .fen, index: 13))
    }

    /// **The tall end and the short end meet wherever the arrivals put the
    /// meeting**, and the bed is full when they do: neither end is reserved.
    func testTheTwoEndsMeetAnywhere() {
        var ways = HomeGround.Ways()
        for i in 0..<13 { ways.plant(seed: Self.seed("t", i), traits: Self.umbel(1.0 + Double(i) / 100)) }
        let last = ways.plant(seed: Self.seed("s", 0), traits: Self.umbel(0.5))
        XCTAssertEqual(last.slot, HomeGround.Slot(bed: 0, crop: .fen, index: 13))
        XCTAssertNil(ways.next(.north, bed: 0, crop: .fen, among: ways.plot(0)))
        XCTAssertNil(ways.next(.south, bed: 0, crop: .fen, among: ways.plot(0)))
    }

    func testAPlantAtItsCutGoesNorth() {
        for crop in HomeGround.Crop.allCases {
            let habit = ["Cer": "spire", "Fen": "umbel", "Pell": "succulent"][crop.rawValue]!
            XCTAssertEqual(PlantTraits(height: crop.cut, family: 0, habit: habit).homeGroundEnd, .north)
            XCTAssertEqual(PlantTraits(height: crop.cut.nextDown, family: 0, habit: habit).homeGroundEnd, .south)
        }
    }

    /// **A plant whose habit was never sent is sown as an umbel**, and planted
    /// rather than refused.
    func testAPlantWithNoHabitIsSownAsAnUmbel() {
        var ways = HomeGround.Ways()
        let unsent = ways.plant(seed: Self.seed("unsent", 0), traits: PlantTraits(height: 0.5, family: 3))
        XCTAssertEqual(unsent.slot, HomeGround.Slot(bed: 0, crop: .fen, index: 13))
    }

    func testThePlaceIsTheSameWhateverOrderTheTestsRunIn() {
        let ways = Self.filled(40)
        for traits in [Self.spire(1.1), Self.umbel(0.7), Self.rosette(0.3)] {
            XCTAssertEqual(ways.place(for: traits).plot, ways.place(for: traits).plot)
            XCTAssertEqual(ways.place(for: traits).slot, ways.place(for: traits).slot)
        }
    }

    func testThePlacementIsAppendOnly() {
        let early = Self.filled(120).plantings
        let late = Self.full.plantings
        XCTAssertEqual(Array(late.prefix(early.count)), early)
    }

    func testTheNudgeIsTighterDownTheBedThanAlongTheRow() {
        for planting in Self.full.plantings {
            XCTAssertLessThanOrEqual(abs(planting.nudge.x), HomeGround.nudgeAcross)
            XCTAssertLessThanOrEqual(abs(planting.nudge.z), HomeGround.nudgeDown)
        }
    }

    // MARK: The ambassador

    /// **The ambassador opens the west bed for umbels, at its north end**: the
    /// north-west corner of plot 0, the head of the garden.
    func testTheAmbassadorOpensTheHeadOfTheGarden() {
        let one = HomeGround.ambassador
        let traits = LongWalk.traits(of: Ambassadors.of(.ground).genome)
        XCTAssertEqual(traits.crop, .fen)
        XCTAssertEqual(traits.homeGroundEnd, .north)
        XCTAssertEqual(one.plot, 0)
        XCTAssertEqual(one.slot, HomeGround.Slot(bed: 0, crop: .fen, index: 0))
        XCTAssertEqual(one.seed, Ambassadors.of(.ground).seed.hex)
    }
}
