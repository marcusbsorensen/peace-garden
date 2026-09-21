import XCTest
@testable import SeedCore

/// The second area's rule: an enclosure with a bench, three groups of three at
/// the foot of the hedge, and more lawn than planting.
///
/// The Long Walk's suite exists because a placement rule is the kind of thing
/// that looks right and fills badly — its own tests found a version that left
/// eleven plots of fifteen holding six to nine plants. This one asks the same
/// questions of a template whose whole point is to hold fewer.
final class QuietGardenTests: XCTestCase {

    /// Five hundred real crossings, which is what `docs/WEB-GARDENS.md` says a
    /// template is judged at: fourteen plants hide layout faults.
    /// Cached: reading a plant's traits builds its mesh, and five hundred of
    /// those per test is a minute a test.
    private static let sample: [(SeedID, PlantTraits)] = make(500)

    static func arrivals(_ count: Int = 500) -> [(SeedID, PlantTraits)] {
        count <= sample.count ? Array(sample.prefix(count)) : make(count)
    }

    private static func make(_ count: Int) -> [(SeedID, PlantTraits)] {
        (0..<count).map { n in
            let a = SeedMint.mint(fromEntropy: Data("quiet-arrival-\(n)-a".utf8))
            let b = SeedMint.mint(fromEntropy: Data("quiet-arrival-\(n)-b".utf8))
            let meeting = Pollination.encounterID(seedA: a, seedB: b,
                                                  nonceA: Data("a".utf8), nonceB: Data("b".utf8))
            let child = Pollination.cross(seedA: a, seedB: b, encounterID: meeting)
            let genome = Genome(seed: child,
                                lineage: .crossed(parentA: a, parentB: b, encounterID: meeting))
            return (child, LongWalk.traits(of: genome))
        }
    }

    private static let full: QuietGarden.Room = {
        var room = QuietGarden.Room.opened()
        for (seed, traits) in arrivals() { room.plant(seed: seed, traits: traits) }
        return room
    }()

    static func filled(_ count: Int = 500) -> QuietGarden.Room {
        if count == 500 { return full }
        var room = QuietGarden.Room.opened()
        for (seed, traits) in arrivals(count) { room.plant(seed: seed, traits: traits) }
        return room
    }

    // MARK: The room holds what it says it holds

    func testAPlotHoldsTenPlantsAndNoMore() {
        XCTAssertEqual(QuietGarden.slots.count, 10)
        XCTAssertEqual(Set(QuietGarden.slots).count, 10)
        let room = Self.filled()
        for plot in 0..<room.plots {
            XCTAssertLessThanOrEqual(room.plot(plot).count, 10)
        }
    }

    /// **The rule is fewer, and the number is the point.** A quarter of the Long
    /// Walk's forty-eight in the same 5.2 m square.
    func testItHoldsAQuarterOfWhatTheWalkDoesInTheSameSquare() {
        XCTAssertEqual(QuietGarden.plotSide, LongWalk.plotSide)
        XCTAssertLessThan(QuietGarden.slots.count * 4, LongWalk.slots.count * 2)
        XCTAssertEqual(QuietGarden.slots.count * 4, LongWalk.slots.count - 8)
    }

    func testNoTwoPlantsShareASlot() {
        let room = Self.filled()
        var taken: Set<String> = []
        for p in room.plantings {
            let key = "\(p.plot):\(p.slot.corner.rawValue):\(p.slot.index)"
            XCTAssertTrue(taken.insert(key).inserted, "two plants in \(key)")
        }
    }

    /// **The lawn is never planted.** Every plant stands in a corner, at the
    /// foot of a hedge; nothing stands in the middle of the room or the middle
    /// of a side. It is checked as a distance rather than as a slot, because the
    /// nudge moves a plant off its mark and a nudge that pushed one onto the
    /// grass would be the rule failing where nothing else would notice.
    func testNothingStandsOnTheLawn() {
        let room = Self.filled()
        for p in room.plantings {
            let spot = p.spot
            let corner = max(abs(spot.x), abs(spot.z))
            XCTAssertGreaterThan(corner, 1.5, "\(p.seed) is out on the lawn at \(spot)")
            XCTAssertLessThan(corner, QuietGarden.hedgeFrom, "\(p.seed) is in the hedge at \(spot)")
        }
    }

    // MARK: The rules a visitor can see

    /// **A plot's first plant stands by the bench.** That is what makes the
    /// specimen the plot's oldest plant rather than a slot somebody reserved.
    func testEveryPlotsFirstPlantIsTheOneBesideTheBench() {
        let room = Self.filled()
        for plot in 0..<room.plots {
            let here = room.plot(plot)
            XCTAssertEqual(here.first?.slot, .specimen, "plot \(plot) opened somewhere else")
            XCTAssertEqual(here.filter { $0.slot.corner == .bench }.count, 1,
                           "plot \(plot) has more than one plant by the bench")
        }
    }

    /// **Nothing stands in front of something shorter.** The Long Walk's rule at
    /// the scale of a group of three: the back is at least as tall as its arms.
    func testTheBackOfEveryGroupIsTallerThanItsArms() {
        let room = Self.filled()
        for plot in 0..<room.plots {
            for corner in QuietGarden.Corner.allCases where corner != .bench {
                let group = room.plot(plot).filter { $0.slot.corner == corner }
                guard let back = group.first(where: { $0.slot.index == 0 }) else { continue }
                for arm in group where arm.slot.index != 0 {
                    XCTAssertGreaterThanOrEqual(
                        back.traits.height, arm.traits.height,
                        "plot \(plot) \(corner): a \(arm.traits.height) m arm in front of a "
                            + "\(back.traits.height) m back"
                    )
                }
            }
        }
    }

    /// **A group is one colour, or a tone of it.** Never two colours from
    /// opposite sides of the circle in one clump, which is the thing that would
    /// make the planting read as scattered rather than grouped.
    func testEveryGroupIsOneColourOrATonalNeighbourOfIt() {
        let room = Self.filled()
        for plot in 0..<room.plots {
            for corner in QuietGarden.Corner.allCases where corner != .bench {
                let group = room.plot(plot).filter { $0.slot.corner == corner }
                guard let founder = group.first else { continue }
                let allowed = Set([founder.traits.family] + QuietGarden.near(founder.traits.family))
                for plant in group {
                    XCTAssertTrue(allowed.contains(plant.traits.family),
                                  "plot \(plot) \(corner): a \(plant.traits.family) in a "
                                      + "\(founder.traits.family) group")
                }
            }
        }
    }

    // MARK: How it fills

    /// **Every plot but the newest few is full.** The Long Walk's suite found
    /// the opposite on its first rule and that is what the two fallbacks are
    /// for; this checks the same thing of this template's.
    func testItFillsItsPlotsRatherThanStrandingThem() {
        let room = Self.filled()
        let counts = (0..<room.plots).map { room.plot($0).count }
        let full = counts.filter { $0 == 10 }.count
        let holdings = counts.enumerated()
            .map { "plot \($0.offset): \($0.element)" }.joined(separator: ", ")
        XCTAssertGreaterThanOrEqual(
            full, room.plots - 3,
            "only \(full) of \(room.plots) plots are full — \(holdings)"
        )
    }

    /// **It opens about four times as many plots as the walk** for the same
    /// arrivals, which is the rule being fewer rather than the rule failing.
    func testItOpensFarMorePlotsThanTheWalkForTheSameArrivals() {
        let room = Self.filled()
        var walk = LongWalk.Walk.opened()
        for (seed, traits) in Self.arrivals() { walk.plant(seed: seed, traits: traits) }
        XCTAssertGreaterThan(room.plots, walk.plots * 3)
    }

    // MARK: The ambassador

    func testOlyneStandsBesideTheBenchInTheFirstPlot() {
        let standing = QuietGarden.ambassador
        let peace = Ambassadors.of(.peace)
        XCTAssertEqual(standing.seed, peace.seed.hex)
        XCTAssertEqual(standing.plot, 0)
        XCTAssertEqual(standing.slot, .specimen)
        XCTAssertEqual(QuietGarden.Room.opened().plantings.count, 1)
    }

    func testItsPlacementIsDerivedAndNotDrawnAfresh() {
        XCTAssertEqual(QuietGarden.ambassador, QuietGarden.Room.opened().plantings[0])
    }

    func testTheRoomFillsAroundIt() {
        let room = Self.filled()
        XCTAssertEqual(room.plantings.first, QuietGarden.ambassador, "the ambassador moved")
        let onIt = room.plantings.dropFirst().filter { $0.plot == 0 && $0.slot == .specimen }
        XCTAssertTrue(onIt.isEmpty, "something was planted on the ambassador")
    }
}
