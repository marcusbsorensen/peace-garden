import XCTest
@testable import SeedCore

/// The third area's rule: four quarters of six round a paved crossing, kept
/// level with each other.
///
/// The Long Walk's suite exists because a placement rule is the kind of thing
/// that looks right and fills badly — its own tests found a version that left
/// eleven plots of fifteen holding six to nine plants. This one asks the same
/// questions of a template whose whole point is that four beds grow together.
final class CrossingTests: XCTestCase {

    /// Five hundred real crossings, which is what `docs/WEB-GARDENS.md` says a
    /// template is judged at: twenty-four plants hide layout faults.
    /// Cached: reading a plant's traits builds its mesh, and five hundred of
    /// those per test is a minute a test.
    private static let sample: [(SeedID, PlantTraits)] = make(500)

    static func arrivals(_ count: Int = 500) -> [(SeedID, PlantTraits)] {
        count <= sample.count ? Array(sample.prefix(count)) : make(count)
    }

    private static func make(_ count: Int) -> [(SeedID, PlantTraits)] {
        (0..<count).map { n in
            let a = SeedMint.mint(fromEntropy: Data("cross-arrival-\(n)-a".utf8))
            let b = SeedMint.mint(fromEntropy: Data("cross-arrival-\(n)-b".utf8))
            let meeting = Pollination.encounterID(seedA: a, seedB: b,
                                                  nonceA: Data("a".utf8), nonceB: Data("b".utf8))
            let child = Pollination.cross(seedA: a, seedB: b, encounterID: meeting)
            let genome = Genome(seed: child,
                                lineage: .crossed(parentA: a, parentB: b, encounterID: meeting))
            return (child, LongWalk.traits(of: genome))
        }
    }

    private static let full: Crossing.Ways = {
        var ways = Crossing.Ways.opened()
        for (seed, traits) in arrivals() { ways.plant(seed: seed, traits: traits) }
        return ways
    }()

    static func filled(_ count: Int = 500) -> Crossing.Ways {
        if count == 500 { return full }
        var ways = Crossing.Ways.opened()
        for (seed, traits) in arrivals(count) { ways.plant(seed: seed, traits: traits) }
        return ways
    }

    // MARK: The plot holds what it says it holds

    func testAPlotHoldsTwentyFourPlantsAndNoMore() {
        XCTAssertEqual(Crossing.slots.count, 24)
        XCTAssertEqual(Set(Crossing.slots).count, 24)
        let ways = Self.filled()
        for plot in 0..<ways.plots {
            let here = ways.plot(plot)
            XCTAssertLessThanOrEqual(here.count, 24, "plot \(plot) holds \(here.count)")
            XCTAssertEqual(Set(here.map(\.slot)).count, here.count,
                           "plot \(plot) has two plants in one slot")
        }
    }

    func testEveryQuarterHoldsSix() {
        for quarter in Crossing.Quarter.allCases {
            XCTAssertEqual(Crossing.slots.filter { $0.quarter == quarter }.count, 6)
        }
        for rank in Crossing.Rank.allCases {
            let want = rank == .path ? 3 : (rank == .middle ? 2 : 1)
            XCTAssertEqual(Crossing.slots.filter { $0.quarter == .first && $0.rank == rank }.count, want)
        }
    }

    // MARK: The rule the area is for

    /// The one Marcus chose: an arrival goes where there is least, so the four
    /// quarters grow together. A plot that is not the newest is full, and in a
    /// plot that is filling no quarter runs away from the others.
    func testTheFourQuartersStayLevel() {
        let ways = Self.filled()
        for plot in 0..<ways.plots {
            let here = ways.plot(plot)
            let counts = Crossing.Quarter.allCases.map { quarter in
                here.filter { $0.slot.quarter == quarter }.count
            }
            let spread = (counts.max() ?? 0) - (counts.min() ?? 0)
            XCTAssertLessThanOrEqual(spread, 2,
                "plot \(plot) quarters hold \(counts), which is not four ways equally used")
        }
    }

    /// The fault the Long Walk's suite caught: plots opening while earlier ones
    /// stand half empty.
    func testPlotsFillBeforeTheNextOpens() {
        let ways = Self.filled()
        let sizes = (0..<ways.plots).map { ways.plot($0).count }
        // Everything but the growing end is full.
        for (plot, size) in sizes.dropLast(2).enumerated() {
            XCTAssertEqual(size, 24, "plot \(plot) holds \(size) of 24")
        }
        XCTAssertGreaterThan(Double(sizes.reduce(0, +)) / Double(sizes.count * 24), 0.9,
                             "the Crossing is filling at \(sizes)")
    }

    /// Reading outward from the paving, nothing stands in front of something
    /// shorter than itself.
    func testNothingStandsInFrontOfSomethingShorter() {
        let ways = Self.filled()
        for plot in 0..<ways.plots {
            let here = ways.plot(plot)
            for quarter in Crossing.Quarter.allCases {
                let bed = here.filter { $0.slot.quarter == quarter }
                for one in bed {
                    for other in bed where one.slot.rank.rawValue < other.slot.rank.rawValue {
                        XCTAssertLessThanOrEqual(one.traits.height, other.traits.height,
                            "in plot \(plot) quarter \(quarter) a \(one.traits.height) m plant stands in front of a \(other.traits.height) m one")
                    }
                }
            }
        }
    }

    // MARK: Where a plant goes never changes

    func testAPlantNeverMoves() {
        let early = Self.filled(120)
        let late = Self.filled(500)
        for (n, planting) in early.plantings.enumerated() {
            XCTAssertEqual(planting.slot, late.plantings[n].slot, "arrival \(n) moved")
            XCTAssertEqual(planting.plot, late.plantings[n].plot, "arrival \(n) changed plot")
        }
    }

    func testThePlacementIsTheSameEveryRun() {
        let once = Self.filled(200), twice = Self.filled(200)
        XCTAssertEqual(once.plantings, twice.plantings)
    }

    // MARK: The slots themselves

    /// Every plant stands inside its plot, off both paths, and clear of the
    /// paving the paths run into.
    func testNoPlantStandsOnAPathOrOnThePaving() {
        let ways = Self.filled()
        let edge = Crossing.plotSide / 2
        for planting in ways.plantings {
            let spot = planting.spot
            XCTAssertLessThan(abs(spot.x), edge, "a plant is off the plot")
            XCTAssertLessThan(abs(spot.z), edge, "a plant is off the plot")
            XCTAssertGreaterThan(min(abs(spot.x), abs(spot.z)), Crossing.pathHalfWidth,
                                 "a plant stands on a path")
            let fromMiddle = (spot.x * spot.x + spot.z * spot.z).squareRoot()
            XCTAssertGreaterThan(fromMiddle, Crossing.roundelRadius,
                                 "a plant stands on the paving")
        }
    }

    /// The three at the path rank share an arc, which is what frees them from
    /// having to be in order with each other.
    func testThePathRankIsAnArc() {
        let radius = { (slot: Crossing.Slot) -> Double in
            let spot = slot.spot
            return (spot.x * spot.x + spot.z * spot.z).squareRoot()
        }
        let bed = Crossing.slots.filter { $0.quarter == .first }
        let path = bed.filter { $0.rank == .path }.map(radius)
        for r in path { XCTAssertEqual(r, path[0], accuracy: 0.01) }
        let middle = bed.filter { $0.rank == .middle }.map(radius)
        for r in middle { XCTAssertEqual(r, middle[0], accuracy: 0.01) }
        XCTAssertLessThan(path[0], middle[0])
        XCTAssertLessThan(middle[0], radius(bed.first { $0.rank == .corner }!))
    }

    // MARK: The ambassador

    func testTheAmbassadorStandsOnTheFirstQuartersDiagonal() {
        let one = Crossing.ambassador
        XCTAssertEqual(one.plot, 0)
        XCTAssertEqual(one.slot, Crossing.Slot(quarter: .first, index: 0))
        XCTAssertEqual(one.slot.rank, .path)
        XCTAssertEqual(one.seed, Ambassadors.of(.meeting).seed.hex)
        // The reason the paving holds no plant: the meeting ambassador is short.
        XCTAssertLessThan(one.traits.height, Crossing.middleFrom)
    }

    /// **This area is `meeting`, and it says so here rather than anywhere else.**
    ///
    /// The whole list of open areas used to be asserted here too, and that was
    /// wrong: opening the Orchard broke the *Crossing's* suite, which tells
    /// somebody nothing about the Crossing. `AreaVectorTests` is the one place
    /// the list is written down, deliberately, so that opening an area fails in
    /// exactly one test and somebody edits one line on purpose.
    func testTheCrossingIsTheMeetingArea() {
        XCTAssertTrue(Area.meeting.isOpen)
        XCTAssertEqual(Area.meeting.table, "crossing")
    }

    // MARK: The cuts

    func testTheCutsAreTheCrossingsOwn() {
        XCTAssertEqual(Crossing.rank(height: 0.5), .path)
        XCTAssertEqual(Crossing.rank(height: 0.90), .path)
        XCTAssertEqual(Crossing.rank(height: 0.91), .middle)
        XCTAssertEqual(Crossing.rank(height: 1.29), .middle)
        XCTAssertEqual(Crossing.rank(height: 1.30), .corner)
        // Deliberately not the walk's or the room's.
        XCTAssertNotEqual(Crossing.middleFrom, QuietGarden.backFrom)
        XCTAssertNotEqual(Crossing.cornerFrom, LongWalk.backFrom)
    }
}
