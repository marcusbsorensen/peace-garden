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
    }

    /// **Each crop's table holds every bed's places in the slots' order**, so
    /// `Slot.spot` reading place `bed × capacity + index` reads the place the
    /// table tagged with that bed and that index.
    func testEachCropsTableIsInTheSlotsOrder() {
        for crop in HomeGround.Crop.allCases {
            let table = crop.table
            XCTAssertEqual(table.nudges, 1, "a crop's places do not change with the plot; the mirror does")
            let places = table.places(nudge: 0)
            XCTAssertEqual(places.count, HomeGround.beds * crop.capacity, crop.rawValue)
            for bed in 0..<HomeGround.beds {
                for slot in HomeGround.slots(bed: bed, crop: crop) {
                    let place = places[bed * crop.capacity + slot.index]
                    XCTAssertEqual(table.tag("bed", of: place), bed)
                    XCTAssertEqual(table.tag("index", of: place), slot.index)
                    XCTAssertEqual(slot.spot, place.spot)
                }
            }
        }
    }

    /// The middle of each row of a bed sown with this crop, north end first.
    private func rowMiddles(bed: Int, crop: HomeGround.Crop) -> [Spot] {
        let slots = HomeGround.slots(bed: bed, crop: crop)
        let across = crop.sown.across
        return stride(from: 0, to: slots.count, by: across).map { first in
            let row = slots[first..<(first + across)].map(\.spot)
            return Spot(x: row.map(\.x).reduce(0, +) / Double(across), z: row.map(\.z).reduce(0, +) / Double(across))
        }
    }

    /// How far a point is from the nearest part of a bed's line.
    private func fromLine(_ p: Spot, _ line: [Spot]) -> Double {
        var best = Double.greatestFiniteMagnitude
        for (a, b) in zip(line, line.dropFirst()) {
            let dx = b.x - a.x, dz = b.z - a.z
            let t = max(0, min(1, ((p.x - a.x) * dx + (p.z - a.z) * dz) / (dx * dx + dz * dz)))
            best = min(best, ((p.x - a.x - dx * t) * (p.x - a.x - dx * t) + (p.z - a.z - dz * t) * (p.z - a.z - dz * t)).squareRoot())
        }
        return best
    }

    /// **Every crop's rows span the same 3.6 m of the bed's line**, centred on
    /// it, so three beds of three crops end level at the headlands; each row's
    /// middle is on the line, and its places run square to it.
    func testEveryCropsRowsSpanTheSameLengthOfTheLine() {
        for bed in 0..<HomeGround.beds {
            let line = HomeGround.line(of: bed)
            for crop in HomeGround.Crop.allCases {
                let middles = rowMiddles(bed: bed, crop: crop)
                var span = 0.0
                for (a, b) in zip(middles, middles.dropFirst()) {
                    span += ((b.x - a.x) * (b.x - a.x) + (b.z - a.z) * (b.z - a.z)).squareRoot()
                }
                // Chords, a little shorter than the curve between them.
                XCTAssertEqual(span, 3.6, accuracy: 0.01, "bed \(bed) \(crop.rawValue)")
                for middle in middles {
                    XCTAssertLessThan(fromLine(middle, line), 0.002, "bed \(bed) \(crop.rawValue): a row is off the line")
                }
                // An outer bed is the middle one's line moved square to it, so
                // the half of it on the outside of its bend is the longer, and
                // its rows, centred along the line, sit up to 1.6 cm toward
                // that half (since the sway became 0.15 m).
                XCTAssertEqual(middles.first!.z + middles.last!.z, 0, accuracy: 0.035,
                               "bed \(bed) \(crop.rawValue) is not centred down the plot")
            }
        }
    }

    /// **Place 0 is the north-west corner and the last place the south-east.**
    /// North is `z−`, west `x−`, and a row runs west to east.
    func testABedIsNumberedFromItsNorthWestCorner() {
        for crop in HomeGround.Crop.allCases {
            let slots = HomeGround.slots(bed: 2, crop: crop)
            let middles = rowMiddles(bed: 2, crop: crop)
            XCTAssertEqual(middles.map(\.z), middles.map(\.z).sorted(), "\(crop.rawValue): rows are not north to south")
            let across = crop.sown.across
            for first in stride(from: 0, to: slots.count, by: across) {
                let row = slots[first..<(first + across)].map(\.spot.x)
                XCTAssertEqual(row, row.sorted(), "\(crop.rawValue): a row does not run west to east")
            }
        }
    }

    /// **Every place stands inside its bed**, at the worst nudge: a plant's
    /// middle at least 0.14 m in from the bed's side (0.15 when the beds were
    /// straight; the nudge is the table's x and z, and a row leans up to
    /// fourteen degrees off x) and 0.20 m from its end (0.275 when straight,
    /// 0.22 at a sway of 0.10 m: the rows near an end lean too, and a lean
    /// takes a row's outer places a little toward it).
    func testEveryPlaceStandsInsideItsBed() {
        var side = Double.greatestFiniteMagnitude, end = Double.greatestFiniteMagnitude
        for bed in 0..<HomeGround.beds {
            let line = HomeGround.line(of: bed)
            for crop in HomeGround.Crop.allCases {
                for slot in HomeGround.slots(bed: bed, crop: crop) {
                    for dx in [-HomeGround.nudgeAcross, HomeGround.nudgeAcross] {
                        for dz in [-HomeGround.nudgeDown, HomeGround.nudgeDown] {
                            let p = Spot(x: slot.spot.x + dx, z: slot.spot.z + dz)
                            side = min(side, HomeGround.bedWidth / 2 - fromLine(p, line))
                            end = min(end, HomeGround.bedLength / 2 - abs(p.z))
                        }
                    }
                }
            }
        }
        XCTAssertGreaterThan(side, 0.14)
        XCTAssertGreaterThan(end, 0.20)
    }

    /// **The beds stay on the slab however they sway.** A plot's outline
    /// wanders inward by up to 0.22 m from the 5.2 m square (`Organic.outline`),
    /// so no slab's edge comes nearer than 2.38 m; a bed's side, wandering by
    /// up to 2.5 cm as the page draws it, stays inside that.
    func testTheBedsStayOnTheSlab() {
        var reach = 0.0
        for bed in 0..<HomeGround.beds {
            reach = max(reach, HomeGround.line(of: bed).map { abs($0.x) }.max()!)
        }
        XCTAssertLessThan(reach + HomeGround.bedWidth / 2 + 0.025, HomeGround.plotSide / 2 - 0.22)
    }

    /// **The beds sway together**, so the paths between them stay 0.40 m (0.45
    /// until 2 October 2026, when Marcus chose a bolder sway), give or take
    /// what a spade leaves: 1 cm either side.
    func testThePathsAreFortyCentimetres() {
        let lines = (0..<HomeGround.beds).map { HomeGround.line(of: $0) }
        for i in 1..<HomeGround.beds {
            for p in lines[i] {
                let path = fromLine(p, lines[i - 1]) - HomeGround.bedWidth
                XCTAssertEqual(path, 0.40, accuracy: 0.025, "the path west of bed \(i) at z \(p.z)")
            }
        }
    }

    /// **The beds sway**: a bed's middle stands 0.15 m off its straight line at
    /// most (0.10 until 2 October 2026), and the three sway the same way at once.
    func testTheBedsSwayTogetherAsAnS() {
        for bed in 0..<HomeGround.beds {
            let off = HomeGround.line(of: bed).map { $0.x - HomeGround.bedX[bed] }
            XCTAssertEqual(off.map(abs).max()!, 0.15, accuracy: 0.012, "bed \(bed)")
            // North half west of the line, south half east: the lazy S.
            let line = HomeGround.line(of: bed)
            let north = line.filter { $0.z < -0.5 && $0.z > -1.5 }.map { $0.x - HomeGround.bedX[bed] }
            let south = line.filter { $0.z > 0.5 && $0.z < 1.5 }.map { $0.x - HomeGround.bedX[bed] }
            XCTAssertLessThan(north.max()!, 0)
            XCTAssertGreaterThan(south.min()!, 0)
        }
    }

    /// **A plot is mirrored or not by its number, alternately**, and a planting
    /// stands where its place and nudge are, mirrored with it: the nudge is
    /// added before the mirror, so it turns with its row.
    func testAlternatePlotsAreMirrored() {
        for plot in 0..<12 {
            let v = PlotVariant.of(plot: plot, area: .ground)
            XCTAssertEqual(v.turn, 0, "north stays north")
            XCTAssertEqual(v.mirror, plot % 2 == 1, "plot \(plot)")
        }
        let ways = Self.filled()
        for planting in ways.plantings {
            let place = planting.slot.spot
            let x = place.x + planting.nudge.x, z = place.z + planting.nudge.z
            XCTAssertEqual(planting.spot.x, planting.plot % 2 == 1 ? 0 - x : x, accuracy: 0)
            XCTAssertEqual(planting.spot.z, z, accuracy: 0)
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
    ///
    /// **Five plots holding all three since 28 September 2026**, where it was
    /// four; every other number is where it was. The re-roll dealt the Home
    /// Ground a different five hundred — 139 spires, 170 umbels and 191
    /// rosettes where there were 145, 169 and 186 — and a crop claims the
    /// first bed nobody has sown in the order its plants arrive, so which
    /// plots end up with all three is the order of arrival and nothing else.
    /// The rule is unchanged: plots 0, 2, 4, 5 and 6 hold all three, and
    /// plot 3 is umbels in every bed.
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
        XCTAssertEqual(allThree, 5)
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
