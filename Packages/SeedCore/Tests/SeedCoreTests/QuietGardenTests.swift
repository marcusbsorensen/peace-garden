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

    /// **Ten on the ground and two in the water**, since the pool was dug on
    /// 27 September 2026. The ten are unchanged: the pool was put in the middle
    /// of the lawn, which held nothing, so it took no planting place to pay for
    /// itself and the room is two larger than it was.
    func testAPlotHoldsTenOnTheGroundAndTwoInTheWater() {
        let dry = QuietGarden.slots.filter { $0.corner.isDry }
        XCTAssertEqual(dry.count, 10)
        XCTAssertEqual(QuietGarden.slots.count, 12)
        XCTAssertEqual(Set(QuietGarden.slots).count, 12)
        let room = Self.filled()
        for plot in 0..<room.plots {
            XCTAssertLessThanOrEqual(room.plot(plot).filter { $0.slot.corner.isDry }.count, 10)
            XCTAssertLessThanOrEqual(room.plot(plot).filter { !$0.slot.corner.isDry }.count, 2)
        }
    }

    /// **The rule is fewer, and the number is the point.** A quarter of the Long
    /// Walk's forty-eight in the same 5.2 m square.
    ///
    /// **Counted dry**, from 27 September: the comparison is about how thinly a
    /// room plants beside a border, and a pool is not planting. The ten that
    /// this measures have not moved — what changed is that there is now water
    /// in the middle as well, which the walk has no answer to.
    func testItHoldsAQuarterOfWhatTheWalkDoesInTheSameSquare() {
        let dry = QuietGarden.slots.filter { $0.corner.isDry }.count
        XCTAssertEqual(QuietGarden.plotSide, LongWalk.plotSide)
        XCTAssertLessThan(dry * 4, LongWalk.slots.count * 2)
        XCTAssertEqual(dry * 4, LongWalk.slots.count - 8)
    }

    func testNoTwoPlantsShareASlot() {
        let room = Self.filled()
        var taken: Set<String> = []
        for p in room.plantings {
            let key = "\(p.plot):\(p.slot.corner.rawValue):\(p.slot.index)"
            XCTAssertTrue(taken.insert(key).inserted, "two plants in \(key)")
        }
    }

    /// **The lawn is never planted.** Every dry plant stands at the foot of a
    /// hedge, inside it, and well clear of the water; the pool's middle and the
    /// lawn round it stay grass. It is checked as a distance rather than as a
    /// slot, because the nudge moves a plant off its mark and a nudge that
    /// pushed one onto the grass would be the rule failing where nothing else
    /// would notice.
    ///
    /// **And a lily keeps inside the water**, the same invariant from the
    /// other side, which would catch a lily drifting out onto the grass.
    ///
    /// **Measured against the pool as each room lays it**, since the room was
    /// made asymmetric on 2 October 2026: the table's outline, turned for the
    /// plot.
    func testNothingStandsOnTheLawn() {
        let room = Self.filled()
        var nearest = Double.infinity
        for p in room.plantings {
            let spot = p.spot
            let pool = QuietGarden.table.curve("pool", on: QuietGarden.variant(of: p.plot)).points
            guard p.slot.corner.isDry else {
                XCTAssertTrue(Self.inside(spot, pool), "\(p.seed) is out of the water at \(spot)")
                XCTAssertGreaterThan(Self.distance(spot, to: pool), 0.3, "\(p.seed) is at the water's edge")
                continue
            }
            XCTAssertFalse(Self.inside(spot, pool), "\(p.seed) is in the water at \(spot)")
            let toWater = Self.distance(spot, to: pool)
            nearest = min(nearest, toWater)
            XCTAssertGreaterThan(toWater, 0.45, "\(p.seed) is at the water's edge at \(spot)")
            let out = max(abs(spot.x), abs(spot.z))
            XCTAssertGreaterThan(out, 0.8, "\(p.seed) is out on the lawn at \(spot)")
            XCTAssertLessThan(out, QuietGarden.hedgeFrom - 0.15, "\(p.seed) is in the hedge at \(spot)")
        }
        print("Quiet Garden: the nearest dry plant stands \(nearest) m from the water")
    }

    /// **The bench looks across the water at the five.** The pool lies between
    /// them, on the line from the seat to the group, and nearer the seat.
    func testTheBenchLooksAcrossTheWaterAtTheFive() {
        for n in 0..<QuietGarden.variants.count {
            let v = QuietGarden.variants.variant(n)
            let bench = QuietGarden.bench(on: v)
            let five = QuietGarden.slots.filter { $0.corner == .five }.map { $0.spot(on: v) }
            let at = Spot(x: five.map(\.x).reduce(0, +) / 5, z: five.map(\.z).reduce(0, +) / 5)
            let pool = QuietGarden.table.curve("pool", on: v).points
            let middle = Spot(x: pool.map(\.x).reduce(0, +) / Double(pool.count),
                              z: pool.map(\.z).reduce(0, +) / Double(pool.count))
            // The water's middle is near the line from the seat to the five...
            let lx = at.x - bench.x, lz = at.z - bench.z
            let length = hypot(lx, lz)
            let off = abs((middle.x - bench.x) * lz - (middle.z - bench.z) * lx) / length
            XCTAssertLessThan(off, 0.25, "variant \(n): the pool is off the bench's line of sight")
            // ...and nearer the seat than the group.
            XCTAssertLessThan(hypot(middle.x - bench.x, middle.z - bench.z), length / 2,
                              "variant \(n): the pool is not off the middle toward the bench")
            // And the stepping stones lead from the seat to the water.
            let stones = QuietGarden.table.curve("stones", on: v).points
            XCTAssertEqual(stones.count, 3)
            XCTAssertLessThan(hypot(stones[0].x - bench.x, stones[0].z - bench.z), 0.5)
            XCTAssertLessThan(Self.distance(stones[2], to: pool), 0.25)
        }
    }

    /// Whether a point is inside a closed outline: the even-odd rule.
    static func inside(_ p: Spot, _ loop: [Spot]) -> Bool {
        var hit = false
        var j = loop.count - 1
        for i in loop.indices {
            let a = loop[i], b = loop[j]
            if (a.z > p.z) != (b.z > p.z), p.x < (b.x - a.x) * (p.z - a.z) / (b.z - a.z) + a.x { hit.toggle() }
            j = i
        }
        return hit
    }

    /// How far a point is from the nearest part of a closed outline.
    static func distance(_ p: Spot, to loop: [Spot]) -> Double {
        var best = Double.infinity
        for i in loop.indices {
            let a = loop[i], b = loop[(i + 1) % loop.count]
            let ax = b.x - a.x, az = b.z - a.z
            let m = ax * ax + az * az
            let t = m == 0 ? 0 : max(0, min(1, ((p.x - a.x) * ax + (p.z - a.z) * az) / m))
            best = min(best, hypot(p.x - a.x - ax * t, p.z - a.z - az * t))
        }
        return best
    }

    /// **Only what wants water is in the water, and everything that wants it
    /// is.** The pool is the one slot in this room chosen by what a plant is
    /// rather than by what colour it is or how tall, so it is the one that can
    /// go wrong silently: a lily in a border reads as a planting mistake, and a
    /// thistle in a pond reads as a bug.
    func testTheWaterHoldsLiliesAndNothingElse() {
        let room = Self.filled()
        for p in room.plantings {
            XCTAssertEqual(p.slot.corner == .pool, p.traits.wantsWater,
                           "\(p.seed) is a \(p.traits.habit) in \(p.slot.corner)")
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

    /// **One, five, three and one** (2 October 2026): the specimen, a group of
    /// five with two at its back, a group of three with one, and the echo, and
    /// the pool's two. Ten on the ground, as before.
    func testTheRoomIsOneFiveThreeAndOne() {
        let counts = QuietGarden.Corner.allCases.map { c in QuietGarden.slots.filter { $0.corner == c }.count }
        XCTAssertEqual(counts, [1, 5, 3, 1, 2])
        let backs = QuietGarden.Corner.allCases.map { c in
            QuietGarden.slots.filter { $0.corner == c && $0.stand == .back }.count
        }
        XCTAssertEqual(backs, [0, 2, 1, 0, 0])
        // A group's back stands nearer its corner of the room than its arms.
        for corner in [QuietGarden.Corner.five, .three] {
            let group = QuietGarden.slots.filter { $0.corner == corner }
            let out = { (s: QuietGarden.Slot) in max(abs(s.spot.x), abs(s.spot.z)) }
            let backs = group.filter { $0.stand == .back }.map(out)
            let arms = group.filter { $0.stand == .arm }.map(out)
            XCTAssertGreaterThan(backs.reduce(0, +) / Double(backs.count), arms.reduce(0, +) / Double(arms.count) - 0.3,
                                 "\(corner)'s back is not toward the hedge")
        }
    }

    /// **Nothing stands in front of something shorter.** The Long Walk's rule at
    /// the scale of a group: every plant at its back is at least as tall as
    /// every one of its arms.
    func testTheBackOfEveryGroupIsTallerThanItsArms() {
        let room = Self.filled()
        for plot in 0..<room.plots {
            for corner in QuietGarden.Corner.allCases where corner.isGroup {
                let group = room.plot(plot).filter { $0.slot.corner == corner }
                for back in group where back.slot.stand == .back {
                    for arm in group where arm.slot.stand == .arm {
                        XCTAssertGreaterThanOrEqual(
                            back.traits.height, arm.traits.height,
                            "plot \(plot) \(corner): a \(arm.traits.height) m arm in front of a "
                                + "\(back.traits.height) m back"
                        )
                    }
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
            for corner in QuietGarden.Corner.allCases where corner.isGroup {
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

    /// **The echo repeats the five's colour, or a tone of it**, across the
    /// lawn, and stands only once the five has a colour to repeat. At five
    /// hundred, 20 of 43 are the five's own colour: a plant of that colour goes
    /// to the five while it has room, and a tone of it may take the echo first.
    func testTheEchoRepeatsTheFive() {
        let room = Self.filled()
        var same = 0, echoes = 0
        for plot in 0..<room.plots {
            let here = room.plot(plot)
            guard let echo = here.first(where: { $0.slot.corner == .echo }) else { continue }
            echoes += 1
            let five = here.first { $0.slot.corner == .five }
            XCTAssertNotNil(five, "plot \(plot) has an echo of nothing")
            guard let five else { continue }
            XCTAssertLessThan(room.plantings.firstIndex(of: five)!, room.plantings.firstIndex(of: echo)!,
                              "plot \(plot)'s echo stood before the five")
            let family = five.traits.family
            XCTAssertTrue(([family] + QuietGarden.near(family)).contains(echo.traits.family),
                          "plot \(plot): a \(echo.traits.family) echo of a \(family) five")
            if echo.traits.family == family { same += 1 }
        }
        print("Quiet Garden at 500: \(same) of \(echoes) echoes are the five's own colour")
        XCTAssertGreaterThan(echoes, room.plots / 2)
        XCTAssertGreaterThan(same * 3, echoes, "too few echoes are the five's own colour")
    }

    /// **Every room is laid as its number says**: a plant stands at its place
    /// and nudge, turned and mirrored for its plot, and the rooms are laid all
    /// eight ways.
    func testEveryRoomIsTurnedAsItsNumberSays() {
        let room = Self.filled()
        var seen = Set<String>()
        for planting in room.plantings {
            let v = QuietGarden.variant(of: planting.plot)
            XCTAssertEqual(v, PlotVariant.of(plot: planting.plot, area: .peace))
            let plain = Spot(x: planting.slot.spot.x + planting.nudge.x,
                             z: planting.slot.spot.z + planting.nudge.z)
            XCTAssertEqual(planting.spot, v.apply(plain))
            seen.insert("\(v.turn) \(v.mirror)")
        }
        XCTAssertEqual(QuietGarden.variant(of: 0), .plain)
        XCTAssertEqual(seen.count, 8, "the rooms are not laid all eight ways")
    }

    /// **A planting filed before the room changed reads back** on a place its
    /// group still has, so the page draws it until the replant moves it.
    func testAnOldEchoArmStandsOnTheEcho() {
        let old = QuietGarden.Slot(corner: .echo, index: 2)
        XCTAssertEqual(old.spot, QuietGarden.Slot(corner: .echo, index: 0).spot)
    }

    // MARK: How it fills

    /// **Every plot but the newest few is full.** The Long Walk's suite found
    /// the opposite on its first rule and that is what the two fallbacks are
    /// for; this checks the same thing of this template's.
    ///
    /// **Full means its ground is full**, from 27 September. A pool fills only
    /// when a lily arrives and lilies are one arrival in twelve (a lily or a
    /// reed since 28 September 2026, two in fourteen), so a plot
    /// measured with its water in would almost never be full and this would be
    /// measuring how many lotuses the seeds happened to draw rather than
    /// whether the rule strands a plot. The water is checked for its own sake
    /// in `testTheWaterHoldsLiliesAndNothingElse`.
    func testItFillsItsPlotsRatherThanStrandingThem() {
        let room = Self.filled()
        let counts = (0..<room.plots).map { room.plot($0).filter { $0.slot.corner.isDry }.count }
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

    /// *Bela caerulea* since the re-roll of 28 September 2026, where it was
    /// *Olyne paniculata*: the first plant stands by the bench whoever it is.
    func testTheAmbassadorStandsBesideTheBenchInTheFirstPlot() {
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
