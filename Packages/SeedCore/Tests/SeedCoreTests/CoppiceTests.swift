import XCTest
@testable import SeedCore

/// The ninth area: ferns on stools, cut one coupe a winter in turn, and stars
/// in the light between them, never cut.
final class CoppiceTests: XCTestCase {

    // MARK: Arrivals

    /// **Five hundred plants whose names put them in the Coppice**, drawn as
    /// the Glasshouse's are, because this area's cut is measured over its own
    /// plants.
    ///
    /// **The design's fresh sample, not the one the cut was measured on.**
    /// `tools/coppice/coppice-sample 2000 coppice-fresh` draws these same
    /// plants in this same order, so the numbers in `docs/WEB-GARDENS.md`
    /// §*The fill, simulated* and the numbers here are measured on one stream.
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
            let a = SeedMint.mint(fromEntropy: Data("coppice-fresh-\(n)-a".utf8))
            let b = SeedMint.mint(fromEntropy: Data("coppice-fresh-\(n)-b".utf8))
            n += 1
            let meeting = Pollination.encounterID(seedA: a, seedB: b,
                                                  nonceA: Data("a".utf8), nonceB: Data("b".utf8))
            let child = Pollination.cross(seedA: a, seedB: b, encounterID: meeting)
            let genome = Genome(seed: child,
                                lineage: .crossed(parentA: a, parentB: b, encounterID: meeting))
            if Area(genome: genome) == .renewal { found.append((child, genome)) }
        }
        return found
    }

    private static func make(_ count: Int) -> [(SeedID, PlantTraits)] {
        crossings(count).map { ($0.seed, LongWalk.traits(of: $0.genome)) }
    }

    private static let full: Coppice.Ways = {
        var ways = Coppice.Ways.opened()
        for (seed, traits) in arrivals() { ways.plant(seed: seed, traits: traits) }
        return ways
    }()

    static func filled(_ count: Int = 500) -> Coppice.Ways {
        if count == 500 { return full }
        var ways = Coppice.Ways.opened()
        for (seed, traits) in arrivals(count) { ways.plant(seed: seed, traits: traits) }
        return ways
    }

    private static func seed(_ label: String, _ n: Int) -> SeedID {
        SeedMint.mint(fromEntropy: Data("coppice-\(label)-\(n)".utf8))
    }
    private static func fern(_ height: Double) -> PlantTraits { PlantTraits(height: height, family: 5, habit: "fern") }
    private static func star(_ height: Double) -> PlantTraits { PlantTraits(height: height, family: 2, habit: "star") }

    // MARK: The area's own plants

    /// **Every plant in the Coppice is a fern or a star**, because the naming
    /// table gives `Dros` and `Ros` to those two archetypes and to nothing
    /// else. A fact of the table, not a tendency of the sample — so if this
    /// ever fails, the table has changed, and the rule's premise with it.
    func testEveryPlantHereIsAFernOrAStar() {
        let habits = Set(Self.arrivals().map(\.1.habit))
        XCTAssertEqual(habits, ["fern", "star"])
        let ferns = Self.arrivals().filter { $0.1.isFern }.count
        XCTAssertEqual(Double(ferns) / 500, 0.48, accuracy: 0.05)
    }

    func testTheCutDividesTheStarsInHalf() {
        let stars = Self.arrivals().map(\.1).filter { !$0.isFern }
        let back = Double(stars.filter { $0.coppiceRow == .back }.count) / Double(stars.count)
        XCTAssertEqual(back, 0.5, accuracy: 0.06)
    }

    // MARK: The plot

    func testAPlotHoldsThreeCoupesOfElevenAndNoMore() {
        XCTAssertEqual(Coppice.slots.count, 33)
        XCTAssertEqual(Set(Coppice.slots).count, 33)
        XCTAssertEqual(Coppice.slots.filter { $0.place == .stool }.count, 15)
        XCTAssertEqual(Set(Coppice.stoolOrder), Set(0..<Coppice.stools))
        XCTAssertEqual(Set(Coppice.floorOrder), Set(0..<Coppice.floorRow))
        let ways = Self.full
        for plot in 0..<ways.plots {
            let here = ways.plot(plot)
            XCTAssertLessThanOrEqual(here.count, 33, "plot \(plot) holds \(here.count)")
            XCTAssertEqual(Set(here.map(\.slot)).count, here.count, "two plants in one place in plot \(plot)")
            // A row fills from its middle outward, so what is taken is a prefix
            // of the fill order.
            for coupe in 0..<Coppice.coupes {
                for place in Coppice.Place.allCases {
                    let taken = Set(here.filter { $0.slot.coupe == coupe && $0.slot.place == place }.map(\.slot.index))
                    let order = place == .stool ? Coppice.stoolOrder : Coppice.floorOrder
                    XCTAssertEqual(taken, Set(order.prefix(taken.count)),
                                   "plot \(plot) coupe \(coupe) \(place) did not fill from the middle")
                }
            }
        }
    }

    /// **Every place clears the plot's rim and both rides**, at the worst nudge
    /// and the worst wander: 0.18 m inside the rim and 0.12 m off a ride, the
    /// numbers `simulate.py` checked before anything was built.
    func testEveryPlaceClearsTheRimAndTheRides() {
        let rimWander = 0.16
        let reach = Coppice.nudgeReach
        var rim = Double.greatestFiniteMagnitude, ride = Double.greatestFiniteMagnitude
        for slot in Coppice.slots {
            let spot = slot.spot
            rim = min(rim, Coppice.plotSide / 2 - rimWander - max(abs(spot.x), abs(spot.z)) - reach)
            for centre in [-Coppice.rideZ, Coppice.rideZ] {
                ride = min(ride, abs(spot.z - centre) - Coppice.rideWidth / 2 - Coppice.rideWander - reach)
            }
        }
        XCTAssertEqual(rim, 0.18, accuracy: 1e-9)
        XCTAssertEqual(ride, 0.12, accuracy: 1e-9)
    }

    /// **The widest stool still leaves every floor place clear**, at the worst
    /// nudge of both: 0.05 m at the closest.
    func testTheWidestStoolClearsTheFloor() {
        // Each nudge moves a plant up to `nudgeReach` along each axis, so two
        // plants can close by twice that along each.
        let closing = 2 * Coppice.nudgeReach
        var nearest = Double.greatestFiniteMagnitude
        for stool in Coppice.slots where stool.place == .stool {
            for floor in Coppice.slots where floor.place != .stool {
                let dx = max(0, abs(stool.spot.x - floor.spot.x) - closing)
                let dz = max(0, abs(stool.spot.z - floor.spot.z) - closing)
                nearest = min(nearest, (dx * dx + dz * dz).squareRoot() - Coppice.stoolAcross.upperBound / 2)
            }
        }
        XCTAssertEqual(nearest, 0.055, accuracy: 1e-9)
    }

    func testTheBackRowIsFurtherBackThanTheStoolsAndTheFrontNearer() {
        for coupe in 0..<Coppice.coupes {
            let z = { (place: Coppice.Place) in Coppice.Slot(coupe: coupe, place: place, index: 1).spot.z }
            XCTAssertLessThan(z(.back), z(.stool))
            XCTAssertLessThan(z(.stool), z(.front))
        }
        XCTAssertLessThan(Coppice.coupeZ[0], Coppice.coupeZ[2])
    }

    // MARK: The rule

    /// **No star is ever cut.** Every flower in the wood is drawn in flower
    /// every year: a star stands on the floor, always.
    func testNoStarStandsOnAStool() {
        for planting in Self.full.plantings where !planting.traits.isFern {
            XCTAssertNotEqual(planting.slot.place, .stool, "\(planting.seed) is a star on a stool")
        }
    }

    func testNoCoupesFloorHoldsMoreThanOneFern() {
        let ways = Self.full
        for plot in 0..<ways.plots {
            for coupe in 0..<Coppice.coupes {
                let ferns = ways.plot(plot).filter {
                    $0.slot.coupe == coupe && $0.slot.place != .stool && $0.traits.isFern
                }
                XCTAssertLessThanOrEqual(ferns.count, 1, "plot \(plot) coupe \(coupe)")
            }
        }
    }

    func testNothingInAFrontRowIsTallerThanAnythingInItsBackRow() {
        let ways = Self.full
        for plot in 0..<ways.plots {
            for coupe in 0..<Coppice.coupes {
                let here = ways.plot(plot).filter { $0.slot.coupe == coupe }
                let back = here.filter { $0.slot.place == .back }.map(\.traits.height)
                let front = here.filter { $0.slot.place == .front }.map(\.traits.height)
                guard let lowest = back.min(), let highest = front.max() else { continue }
                XCTAssertLessThanOrEqual(highest, lowest, "plot \(plot) coupe \(coupe) is out of order")
            }
        }
    }

    /// **The number the design was chosen by.** Simulated before the rule was
    /// written, on these same five hundred: 16 plots, 14 full, 94.9% of places
    /// held and no empty place in a settled plot.
    func testTheFillAtFiveHundred() {
        let ways = Self.full
        let places = ways.plots * Coppice.slots.count
        let fill = Double(ways.plantings.count) / Double(places)
        let full = (0..<ways.plots).filter { ways.plot($0).count == Coppice.slots.count }.count
        let settledEmpty = (0..<max(0, ways.plots - 2)).map { Coppice.slots.count - ways.plot($0).count }.reduce(0, +)
        let floor = ways.plantings.filter { $0.slot.place != .stool }
        let ownRow = floor.filter { $0.slot.place == $0.traits.coppiceRow }.count
        let floorFerns = floor.filter { $0.traits.isFern }.count
        print("""
            Coppice at 500: \(ways.plots) plots, \(full) full, fill \(fill), \
            \(settledEmpty) settled places empty, \(ownRow) of \(floor.count) on the floor in their own row, \
            \(floorFerns) ferns on the floor
            """)
        XCTAssertLessThanOrEqual(ways.plots, 17)
        XCTAssertGreaterThan(fill, 0.93)
        XCTAssertEqual(settledEmpty, 0)
        XCTAssertGreaterThan(Double(ownRow) / Double(floor.count), 0.9)
    }

    /// **A plot's three coupes stay level**: in every settled plot they hold
    /// the same number of ferns on stools, and their floors differ by one at
    /// most — so each stage of the rotation shows plants from a plot's first
    /// arrivals on.
    func testAPlotsCoupesFillLevel() {
        let ways = Self.full
        for plot in 0..<max(0, ways.plots - 2) {
            let here = ways.plot(plot)
            let stools = (0..<Coppice.coupes).map { c in here.filter { $0.slot.coupe == c && $0.slot.place == .stool }.count }
            let floors = (0..<Coppice.coupes).map { c in here.filter { $0.slot.coupe == c && $0.slot.place != .stool }.count }
            XCTAssertLessThanOrEqual(stools.max()! - stools.min()!, 1, "plot \(plot) stools \(stools)")
            XCTAssertLessThanOrEqual(floors.max()! - floors.min()!, 1, "plot \(plot) floors \(floors)")
        }
    }

    func testAFernTakesAStoolInTheCoupeWithFewest() {
        var ways = Coppice.Ways()
        let first = ways.plant(seed: Self.seed("level", 0), traits: Self.fern(0.8))
        XCTAssertEqual(first.slot, Coppice.Slot(coupe: 0, place: .stool, index: 2))
        let second = ways.plant(seed: Self.seed("level", 1), traits: Self.fern(0.8))
        XCTAssertEqual(second.slot, Coppice.Slot(coupe: 1, place: .stool, index: 2))
        let third = ways.plant(seed: Self.seed("level", 2), traits: Self.fern(0.8))
        XCTAssertEqual(third.slot, Coppice.Slot(coupe: 2, place: .stool, index: 2))
        // Level again, so the tie goes to the lowest coupe, one out from the
        // middle.
        let fourth = ways.plant(seed: Self.seed("level", 3), traits: Self.fern(0.8))
        XCTAssertEqual(fourth.slot, Coppice.Slot(coupe: 0, place: .stool, index: 1))
    }

    /// With every stool taken, a fern stands on the floor, one to a coupe; the
    /// fourth opens a new plot on its first coupe's middle stool.
    func testAFernOnTheFloorIsOneToACoupe() {
        var ways = Coppice.Ways()
        for n in 0..<15 { ways.plant(seed: Self.seed("cap", n), traits: Self.fern(0.8)) }
        XCTAssertEqual(ways.plots, 1)
        var coupes: [Int] = []
        for n in 15..<18 {
            let p = ways.plant(seed: Self.seed("cap", n), traits: Self.fern(0.8))
            XCTAssertEqual(p.plot, 0)
            XCTAssertEqual(p.slot.place, .front)
            coupes.append(p.slot.coupe)
        }
        XCTAssertEqual(coupes, [0, 1, 2])
        let fourth = ways.plant(seed: Self.seed("cap", 18), traits: Self.fern(0.8))
        XCTAssertEqual(fourth.plot, 1)
        XCTAssertEqual(fourth.slot, Coppice.Slot(coupe: 0, place: .stool, index: 2))
    }

    func testAStarTakesItsOwnRowInTheCoupeWithFewestOnItsFloor() {
        var ways = Coppice.Ways()
        let tall = ways.plant(seed: Self.seed("row", 0), traits: Self.star(1.4))
        XCTAssertEqual(tall.slot, Coppice.Slot(coupe: 0, place: .back, index: 1))
        let short = ways.plant(seed: Self.seed("row", 1), traits: Self.star(0.8))
        XCTAssertEqual(short.slot, Coppice.Slot(coupe: 1, place: .front, index: 1))
        // Stools do not count toward a floor: a fern changes nothing here.
        ways.plant(seed: Self.seed("row", 2), traits: Self.fern(0.8))
        let next = ways.plant(seed: Self.seed("row", 3), traits: Self.star(0.8))
        XCTAssertEqual(next.slot, Coppice.Slot(coupe: 2, place: .front, index: 1))
    }

    /// A star whose own row is full everywhere stands in the other only where
    /// it keeps the rows in order.
    func testAFullRowSendsAStarAcrossOnlyIfItStaysInOrder() {
        var ways = Coppice.Ways()
        for n in 0..<9 { ways.plant(seed: Self.seed("across", n), traits: Self.star(0.6 + Double(n) * 0.01)) }
        XCTAssertEqual(ways.plots, 1)
        // Every front row is full. A star of 1.0 m would stand taller than
        // any of them, so it may go to the back.
        let tallish = ways.plant(seed: Self.seed("across", 9), traits: Self.star(1.0))
        XCTAssertEqual(tallish.plot, 0)
        XCTAssertEqual(tallish.slot.place, .back)
        // A star shorter than a front row's tallest cannot stand behind it: the
        // coupe it would go to is out of order, so it goes to one that is not,
        // and failing every one, to a new plot.
        let short = ways.plant(seed: Self.seed("across", 10), traits: Self.star(0.59))
        XCTAssertEqual(short.plot, 1)
        XCTAssertEqual(short.slot, Coppice.Slot(coupe: 0, place: .front, index: 1))
    }

    func testAPlantWithNoHabitStandsInTheLight() {
        var ways = Coppice.Ways()
        let unsent = ways.plant(seed: Self.seed("unsent", 0), traits: PlantTraits(height: 0.8, family: 3))
        XCTAssertEqual(unsent.slot.place, .front)
    }

    func testThePlaceIsTheSameWhateverOrderTheTestsRunIn() {
        let ways = Self.filled(40)
        for traits in [Self.fern(0.7), Self.star(1.2)] {
            XCTAssertEqual(ways.place(for: traits).plot, ways.place(for: traits).plot)
            XCTAssertEqual(ways.place(for: traits).slot, ways.place(for: traits).slot)
        }
    }

    func testThePlacementIsAppendOnly() {
        let early = Self.filled(120).plantings
        let late = Self.full.plantings
        XCTAssertEqual(Array(late.prefix(early.count)), early)
    }

    // MARK: The rotation

    func testTheCoupesAreCutInSequenceAlongTheWood() {
        // Year 0: the first coupe of plot 0 is cut, the next regrowing, the
        // third grown, and the pattern runs on into plot 1.
        XCTAssertEqual(Coppice.stage(plot: 0, coupe: 0, year: 0), .cut)
        XCTAssertEqual(Coppice.stage(plot: 0, coupe: 1, year: 0), .grown)
        XCTAssertEqual(Coppice.stage(plot: 0, coupe: 2, year: 0), .regrowing)
        XCTAssertEqual(Coppice.stage(plot: 1, coupe: 0, year: 0), .cut)
        // A year on, the cut moves one coupe along.
        XCTAssertEqual(Coppice.stage(plot: 0, coupe: 1, year: 1), .cut)
        XCTAssertEqual(Coppice.stage(plot: 0, coupe: 0, year: 1), .regrowing)
        // And every coupe comes round again in three.
        for plot in 0..<4 {
            for coupe in 0..<3 {
                for year in -3..<9 {
                    XCTAssertEqual(Coppice.stage(plot: plot, coupe: coupe, year: year),
                                   Coppice.stage(plot: plot, coupe: coupe, year: year + 3))
                }
                let stages = (0..<3).map { Coppice.stage(plot: plot, coupe: coupe, year: $0) }
                XCTAssertEqual(Set(stages), Set(Coppice.Stage.allCases))
            }
        }
    }

    /// **In every year a third of the ferns on stools stand at each stage**:
    /// 78, 77 and 78 of 233 at five hundred in the design.
    func testEveryYearAThirdOfTheStoolsAreAtEachStage() {
        let stools = Self.full.plantings.filter { $0.slot.place == .stool }
        for year in 0..<3 {
            var counts: [Coppice.Stage: Int] = [:]
            for p in stools { counts[Coppice.stage(plot: p.plot, coupe: p.slot.coupe, year: year), default: 0] += 1 }
            for stage in Coppice.Stage.allCases {
                XCTAssertEqual(Double(counts[stage] ?? 0) / Double(stools.count), 1.0 / 3, accuracy: 0.04,
                               "year \(year): \(counts)")
            }
        }
    }

    func testTheYearTurnsAtTheWinterSolstice() {
        XCTAssertEqual(Coppice.year(utcYear: 2026, month: 9, day: 24), 0)
        XCTAssertEqual(Coppice.year(utcYear: 2026, month: 12, day: 20), 0)
        XCTAssertEqual(Coppice.year(utcYear: 2026, month: 12, day: 21), 1)
        XCTAssertEqual(Coppice.year(utcYear: 2027, month: 1, day: 1), 1)
        XCTAssertEqual(Coppice.year(utcYear: 2027, month: 12, day: 21), 2)
    }

    func testOnlyAFernOnAStoolIsDrawnYoung() {
        let ways = Self.full
        for planting in ways.plantings {
            for year in 0..<3 {
                let drawn = Coppice.drawn(planting, year: year)
                if planting.slot.place != .stool { XCTAssertNil(drawn) }
            }
        }
        XCTAssertGreaterThanOrEqual(Coppice.cutDrawn.heightScale, 0.25, "below 0.25 the seed's husk is drawn")
        XCTAssertEqual(Coppice.cutDrawn.budSwell, 0)
        XCTAssertLessThan(Coppice.cutDrawn.heightScale, Coppice.regrowingDrawn.heightScale)
    }

    /// **In a coupe's cut year every star stands over every fern in it.** The
    /// finding the design rests on: drawn cut, the tallest fern is 0.41 m and
    /// the shortest star 0.52 m, so the glade is flowers over new growth.
    func testInItsCutYearEveryStarStandsOverEveryStoolInItsCoupe() {
        let ways = Self.full
        let genomes = Self.genomes()
        var tallestCut = 0.0, closest = Double.greatestFiniteMagnitude
        for plot in 0..<ways.plots {
            for coupe in 0..<Coppice.coupes {
                let here = zip(ways.plantings.dropFirst(), genomes).filter {
                    $0.0.plot == plot && $0.0.slot.coupe == coupe
                }
                let stars = here.filter { $0.0.slot.place != .stool }.map(\.0.traits.height)
                for (planting, genome) in here where planting.slot.place == .stool {
                    let mesh = PlantBuilder(genome: genome).mesh(growth: Coppice.cutDrawn)
                    let tall = Double(mesh.maxBounds.y - mesh.minBounds.y)
                    tallestCut = max(tallestCut, tall)
                    if let lowest = stars.min() { closest = min(closest, lowest - tall) }
                }
            }
        }
        print("Coppice: the tallest cut fern is \(tallestCut) m, and the closest star over one is \(closest) m clear")
        XCTAssertGreaterThan(closest, 0.1)
    }

    // MARK: The ambassador

    func testTheAmbassadorOpensTheFrontRowOfTheFirstCoupe() {
        let one = Coppice.ambassador
        let traits = LongWalk.traits(of: Ambassadors.of(.renewal).genome)
        XCTAssertFalse(traits.isFern)
        XCTAssertEqual(one.plot, 0)
        XCTAssertEqual(one.slot, Coppice.Slot(coupe: 0, place: traits.coppiceRow, index: 1))
        XCTAssertEqual(one.seed, Ambassadors.of(.renewal).seed.hex)
    }
}
