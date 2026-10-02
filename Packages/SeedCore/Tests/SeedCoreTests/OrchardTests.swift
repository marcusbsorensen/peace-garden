import XCTest
@testable import SeedCore

/// The fourth area's rule: five guilds of four under five trees, one guild
/// finished before the next is begun.
///
/// The Long Walk's suite exists because a placement rule is the kind of thing
/// that looks right and fills badly — its own tests found a version that left
/// eleven plots of fifteen holding six to nine plants. This one asks those
/// questions of a rule that is *meant* to leave part of a plot bare, which makes
/// the usual measure of a good fill the wrong one: a half-filled plot here is
/// correct, and what would be wrong is a half-filled *guild*.
final class OrchardTests: XCTestCase {

    /// Five hundred real crossings, which is what `docs/WEB-GARDENS.md` says a
    /// template is judged at. Cached: reading a plant's traits builds its mesh,
    /// and five hundred of those per test is a minute a test.
    private static let sample: [(SeedID, PlantTraits)] = make(500)

    static func arrivals(_ count: Int = 500) -> [(SeedID, PlantTraits)] {
        count <= sample.count ? Array(sample.prefix(count)) : make(count)
    }

    private static func make(_ count: Int) -> [(SeedID, PlantTraits)] {
        (0..<count).map { n in
            let a = SeedMint.mint(fromEntropy: Data("orchard-arrival-\(n)-a".utf8))
            let b = SeedMint.mint(fromEntropy: Data("orchard-arrival-\(n)-b".utf8))
            let meeting = Pollination.encounterID(seedA: a, seedB: b,
                                                  nonceA: Data("a".utf8), nonceB: Data("b".utf8))
            let child = Pollination.cross(seedA: a, seedB: b, encounterID: meeting)
            let genome = Genome(seed: child,
                                lineage: .crossed(parentA: a, parentB: b, encounterID: meeting))
            return (child, LongWalk.traits(of: genome))
        }
    }

    private static let full: Orchard.Ways = {
        var ways = Orchard.Ways.opened()
        for (seed, traits) in arrivals() { ways.plant(seed: seed, traits: traits) }
        return ways
    }()

    static func filled(_ count: Int = 500) -> Orchard.Ways {
        if count == 500 { return full }
        var ways = Orchard.Ways.opened()
        for (seed, traits) in arrivals(count) { ways.plant(seed: seed, traits: traits) }
        return ways
    }

    // MARK: The plot holds what it says it holds

    func testAPlotHoldsTwentyPlantsAndNoMore() {
        XCTAssertEqual(Orchard.slots.count, 20)
        XCTAssertEqual(Set(Orchard.slots).count, 20)
        let ways = Self.filled()
        for plot in 0..<ways.plots {
            let here = ways.plot(plot)
            XCTAssertLessThanOrEqual(here.count, 20, "plot \(plot) holds \(here.count)")
            XCTAssertEqual(Set(here.map(\.slot)).count, here.count,
                           "plot \(plot) has two plants in one place")
        }
    }

    func testEveryGuildHoldsFourAndOnlyTheMiddleIsRankless() {
        for guild in Orchard.Guild.allCases {
            XCTAssertEqual(Orchard.slots.filter { $0.guild == guild }.count, 4)
        }
        XCTAssertEqual(Orchard.slots.filter { $0.rank == nil }.count, 4)
        for slot in Orchard.slots where slot.guild == .middle {
            XCTAssertNil(slot.rank)
        }
        // An outer guild is one nearest the middle, two flanking, one furthest.
        for guild in Orchard.Guild.allCases where guild != .middle {
            let under = Orchard.slots.filter { $0.guild == guild }
            XCTAssertEqual(under.filter { $0.rank == .understorey }.count, 1)
            XCTAssertEqual(under.filter { $0.rank == .flank }.count, 2)
            XCTAssertEqual(under.filter { $0.rank == .crown }.count, 1)
        }
    }

    private static func distance(_ a: Spot, _ b: Spot) -> Double {
        let dx = a.x - b.x, dz = a.z - b.z
        return (dx * dx + dz * dz).squareRoot()
    }

    /// The geometry the ranks are a reading of: a place's rank has to agree with
    /// how far out it actually is, or `inOrder` is ordering plants by a fiction.
    /// In every feature variant, because each nudges its trees its own way.
    ///
    /// **The two flanks stand at one distance from the middle**, which is
    /// what frees them from having to be in order with each other. To the
    /// millimetre, which is what the table is written in: they were drawn
    /// either side of the line from their trunk to the middle tree.
    func testRankAgreesWithDistanceFromTheMiddleOfThePlot() {
        let middleOfPlot = Spot(x: 0, z: 0)
        for nudge in 0..<Orchard.table.nudges {
            func radius(_ slot: Orchard.Slot) -> Double { Self.distance(slot.place(nudge: nudge), middleOfPlot) }
            for guild in Orchard.Guild.allCases where guild != .middle {
                let under = Orchard.slots.filter { $0.guild == guild }
                let near = under.first { $0.rank == .understorey }!
                let flanks = under.filter { $0.rank == .flank }
                let far = under.first { $0.rank == .crown }!
                XCTAssertLessThan(radius(near), radius(flanks[0]))
                XCTAssertEqual(radius(flanks[0]), radius(flanks[1]), accuracy: 0.002)
                XCTAssertLessThan(radius(flanks[0]), radius(far))
            }
            // And the middle guild's four are all at one distance, which is why
            // they have no rank at all.
            let middle = Orchard.slots.filter { $0.guild == .middle }.map(radius)
            for r in middle { XCTAssertEqual(r, Orchard.middleRadius, accuracy: 0.001) }
        }
    }

    /// **A crescent at the drip line, turned toward the middle tree**: an
    /// outer guild's four all stand `guildRadius` from their own trunk, and its
    /// understorey is the one nearest the middle tree.
    func testAnOuterGuildIsACrescentTurnedTowardTheMiddleTree() {
        for nudge in 0..<Orchard.table.nudges {
            let trunks = Orchard.trunks(on: PlotVariant(turn: 0, mirror: false, nudge: nudge))
            XCTAssertEqual(trunks.count, 5)
            XCTAssertEqual(trunks[0].x, 0)
            XCTAssertEqual(trunks[0].z, 0)
            for guild in Orchard.Guild.allCases where guild != .middle {
                let trunk = trunks[guild.rawValue]
                // Off the quincunx by no more than 0.08 m each way.
                XCTAssertEqual(abs(trunk.x), Orchard.treeFrom, accuracy: 0.081)
                XCTAssertEqual(abs(trunk.z), Orchard.treeFrom, accuracy: 0.081)
                let under = Orchard.slots.filter { $0.guild == guild }
                for slot in under {
                    XCTAssertEqual(Self.distance(slot.place(nudge: nudge), trunk), Orchard.guildRadius, accuracy: 0.001)
                }
                let nearest = under.min { Self.distance($0.place(nudge: nudge), trunks[0])
                    < Self.distance($1.place(nudge: nudge), trunks[0]) }!
                XCTAssertEqual(nearest.rank, .understorey)
            }
        }
    }

    /// Two plants in one plot may not stand on top of each other. The closest
    /// two places are neighbours in a crescent, 0.56 m apart, and the spacing
    /// that decided `treeFrom` — the middle tree's four against the near end
    /// of a crescent — leaves those 0.80 m apart and more. Nothing stands in a
    /// trunk.
    func testNoTwoPlacesInAPlotAreTooCloseTogether() {
        var closest = Double.greatestFiniteMagnitude
        var acrossGuilds = Double.greatestFiniteMagnitude
        var trunk = Double.greatestFiniteMagnitude
        for nudge in 0..<Orchard.table.nudges {
            let trunks = Orchard.trunks(on: PlotVariant(turn: 0, mirror: false, nudge: nudge))
            for (i, a) in Orchard.slots.enumerated() {
                for b in Orchard.slots.dropFirst(i + 1) {
                    let d = Self.distance(a.place(nudge: nudge), b.place(nudge: nudge))
                    closest = min(closest, d)
                    if a.guild != b.guild { acrossGuilds = min(acrossGuilds, d) }
                }
                for t in trunks { trunk = min(trunk, Self.distance(a.place(nudge: nudge), t)) }
            }
        }
        XCTAssertGreaterThan(closest, 0.55, "closest two places are \(closest) m apart")
        XCTAssertGreaterThanOrEqual(acrossGuilds, 0.80 - 0.001, "two guilds' places are \(acrossGuilds) m apart")
        XCTAssertGreaterThanOrEqual(trunk, Orchard.middleRadius - 0.001, "a place is \(trunk) m from a trunk")
    }

    /// **Every place is on the plot at the worst nudge**: inside the rounded
    /// square the plot's wandering edge never comes in past (`Organic.outline`:
    /// 2.38 m on a side, its corners round by 0.35 m), with the 0.13 m nudge
    /// added each way.
    func testEveryPlaceIsInsideThePlot() {
        let side = Orchard.plotSide / 2 - 0.22, round = 0.35, reach = 0.13
        for nudge in 0..<Orchard.table.nudges {
            for slot in Orchard.slots {
                let p = slot.place(nudge: nudge)
                let x = abs(p.x) + reach, z = abs(p.z) + reach
                XCTAssertLessThan(max(x, z), side, "\(slot) in variant \(nudge)")
                let c = side - round
                if x > c, z > c {
                    XCTAssertLessThan(Self.distance(Spot(x: x, z: z), Spot(x: c, z: c)), round,
                                      "\(slot) in variant \(nudge) is off the corner")
                }
            }
        }
    }

    /// **The pond and the way keep clear of the planting.** The pond's middle
    /// is 0.80 m from every place, so 0.64 m of water and its wet rim leave a
    /// plant's leaves on the grass; the mown way's line passes 0.55 m from
    /// every outer guild's place, and wanders through the middle tree's mown
    /// disc, where its four stand in mown grass anyway.
    func testThePondAndTheWayKeepClearOfThePlanting() {
        for nudge in 0..<Orchard.table.nudges {
            let plain = PlotVariant(turn: 0, mirror: false, nudge: nudge)
            let pond = Orchard.pond(on: plain)
            let way = Orchard.way(on: plain)
            for slot in Orchard.slots {
                let p = slot.place(nudge: nudge)
                XCTAssertGreaterThanOrEqual(Self.distance(p, pond), 0.80 - 0.001)
                guard slot.guild != .middle else { continue }
                let near = zip(way, way.dropFirst()).map { a, b -> Double in
                    let dx = b.x - a.x, dz = b.z - a.z
                    let t = max(0, min(1, ((p.x - a.x) * dx + (p.z - a.z) * dz) / (dx * dx + dz * dz)))
                    return Self.distance(p, Spot(x: a.x + dx * t, z: a.z + dz * t))
                }.min()!
                XCTAssertGreaterThan(near, 0.54, "\(slot) is \(near) m from the way in variant \(nudge)")
            }
        }
    }

    /// **A plot turned or mirrored is the same plot seen another way round.**
    /// Every planting's spot is its place in the table's frame with its nudge
    /// added there, turned for its plot; and the plots dealt so far hold more
    /// than one variant.
    func testEveryPlotIsTurnedByItsNumberAndItsPlantsWithIt() {
        let ways = Self.filled()
        var seen = Set<PlotVariant>()
        for planting in ways.plantings {
            let variant = Orchard.variant(ofPlot: planting.plot)
            seen.insert(variant)
            let place = planting.slot.place(nudge: variant.nudge)
            let back = variant.undo(planting.spot)
            XCTAssertEqual(back.x - planting.nudge.x, place.x, accuracy: 1e-12)
            XCTAssertEqual(back.z - planting.nudge.z, place.z, accuracy: 1e-12)
        }
        XCTAssertEqual(Orchard.variant(ofPlot: 0), .plain)
        XCTAssertGreaterThan(seen.count, 12, "only \(seen.count) variants in \(ways.plots) plots")
        XCTAssertEqual(Orchard.variants.count, 24)
    }

    /// The table's places carry the same tags in the same order in every
    /// feature variant, so a slot is the same place of every one.
    func testEveryFeatureVariantListsTheSlotsAlike() {
        let table = Orchard.table
        for nudge in 0..<table.nudges {
            let tags = table.places(nudge: nudge).map { [table.tag("guild", of: $0), table.tag("index", of: $0)] }
            XCTAssertEqual(tags, Orchard.slots.map { [$0.guild.rawValue, $0.index] })
        }
    }

    // MARK: The rule the area is for

    /// **The one Marcus chose: a guild is finished before the next is begun** —
    /// stated the way the rule actually keeps it.
    ///
    /// *Not* "a later guild never holds more than an earlier one". That is
    /// false, and asserting it was this test's own first bug: it passed on this
    /// sample and the workbench at `/dev/orchard`, on a different five hundred,
    /// showed a plot filling 4 4 4 3 4. A guild's last place carries the
    /// tightest constraint in the plot, so a guild can sit at three while the
    /// next fills, waiting for a plant tall enough for its crown.
    ///
    /// Two things are guaranteed instead. **An occupied guild is never preceded
    /// by an empty one**, because an empty guild refuses nobody — `inOrder` has
    /// nothing there to compare against — so a plant only reaches guild n by
    /// being turned away from guilds that already hold something. And **a free
    /// place in an earlier guild is one no plant in a later guild could have
    /// stood in**, or that plant would have taken it, since `place` reaches the
    /// earlier guild first.
    ///
    /// The second is checked against the finished plot rather than by replaying
    /// arrivals because `inOrder` only ever gets stricter as a guild fills: if
    /// the full guild would accept a plant, the part-filled guild it passed
    /// through would have too.
    func testAGuildIsFinishedBeforeTheNextIsBegun() {
        let ways = Self.filled()
        for plot in 0..<ways.plots {
            let here = ways.plot(plot)
            let counts = Orchard.Guild.allCases.map { g in
                here.filter { $0.slot.guild == g }.count
            }
            guard let started = counts.lastIndex(where: { $0 > 0 }) else { continue }
            for g in 0...started {
                XCTAssertGreaterThan(counts[g], 0,
                    "plot \(plot) holds \(counts) — guild \(g) was skipped")
            }

            let taken = Set(here.map(\.slot))
            for g in 0..<started {
                let guild = Orchard.Guild.allCases[g]
                let under = here.filter { $0.slot.guild == guild }
                for free in Orchard.slots where free.guild == guild && !taken.contains(free) {
                    for later in here where later.slot.guild.rawValue > g {
                        if let rank = free.rank,
                           !Orchard.ranks(beside: Orchard.rank(height: later.traits.height)).contains(rank) {
                            continue
                        }
                        XCTAssertFalse(ways.inOrder(later.traits.height, at: free, among: under),
                            "plot \(plot) left \(guild)/\(free.index) free, but a \(later.traits.height) m plant went to \(later.slot.guild) and could have stood there")
                    }
                }
            }
        }
    }

    /// **An older plot is full, or the places left in it are ones nobody who
    /// has arrived since could stand in.** This is the Long Walk's measure —
    /// leaving a guild bare is the rule, abandoning a plot is not — stated the
    /// way this rule actually keeps it.
    ///
    /// At five hundred, twenty-five plots of twenty-six are exactly full and one
    /// holds nineteen. That one is not abandoned: its free place is an
    /// understorey under the fourth tree whose guild already holds a 0.77 m
    /// flank, so it wants a plant of 0.77 m or less — and the last of the five
    /// hundred went into that very plot, so nothing has arrived since at all.
    /// The next short arrival takes it.
    ///
    /// **An older plot goes on receiving after a newer one opens**, because
    /// `place` scans plots oldest first every time. A new plot is opened by one
    /// arrival that did not fit anywhere; it does not close the plots behind it.
    /// The difference from the Crossing, which never trails, is the guild-first
    /// rule: filling a guild to its last place leaves that place holding the
    /// tightest constraint in the plot.
    func testAnOlderPlotIsFullOrIsWaitingForAPlantNobodyHasSent() {
        let ways = Self.filled()
        for plot in 0..<(ways.plots - 1) {
            let here = ways.plot(plot)
            if here.count == 20 { continue }
            XCTAssertGreaterThanOrEqual(here.count, 19,
                "plot \(plot) holds only \(here.count) and is not the newest")

            // Everything that arrived after this plot's last planting. `place`
            // scans plots oldest first, so any of them that could have stood in
            // a free place here would have.
            let last = ways.plantings.lastIndex { $0.plot == plot }!
            let since = ways.plantings[(last + 1)...]

            let taken = Set(here.map(\.slot))
            for free in Orchard.slots where !taken.contains(free) {
                let under = here.filter { $0.slot.guild == free.guild }
                for later in since {
                    XCTAssertFalse(ways.inOrder(later.traits.height, at: free, among: under),
                        "plot \(plot) left \(free.guild)/\(free.index) free although a \(later.traits.height) m plant arrived after it")
                }
            }
        }
    }

    /// Nothing stands in front of something shorter than itself, read outward
    /// from the middle of the plot. The middle guild is exempt by construction
    /// and the test says so rather than skipping it quietly.
    func testNothingStandsInFrontOfSomethingShorter() {
        let ways = Self.filled()
        for plot in 0..<ways.plots {
            for guild in Orchard.Guild.allCases {
                let under = ways.plot(plot).filter { $0.slot.guild == guild }
                for a in under {
                    for b in under {
                        guard let ra = a.slot.rank, let rb = b.slot.rank else { continue }
                        if ra.rawValue < rb.rawValue {
                            XCTAssertLessThanOrEqual(a.traits.height, b.traits.height,
                                "plot \(plot) guild \(guild): \(a.traits.height) stands in front of \(b.traits.height)")
                        }
                    }
                }
            }
        }
    }

    func testAPlantNeverMoves() {
        let five = Self.filled(5)
        let fiveHundred = Self.filled()
        for early in five.plantings {
            let later = fiveHundred.plantings.first { $0.seed == early.seed }
            XCTAssertEqual(later, early, "a plant moved after it was planted")
        }
    }

    /// **Three plants in four get the rank their height asks for, and the rest
    /// are out by exactly one — never two.**
    ///
    /// This is the price of the rule and it is worth stating plainly, because
    /// the Crossing gets 96.6% on the same population. Preferring the guild over
    /// the rank means a guild of four has to take whoever arrives next rather
    /// than waiting for the right height, so displacement is four times as
    /// common here as there. Measured at five hundred: 301 of 399 in their own
    /// rank, 58 one step out, 40 one step in, none further.
    ///
    /// **It is not a visual fault, and that is why it is allowed.** `inOrder` is
    /// what guarantees the picture — nothing stands in front of something
    /// shorter — and it holds for every plant regardless of rank. A rank is the
    /// height a place was *meant* for; `inOrder` is what a visitor actually
    /// sees. If this number falls much further it is still worth looking at,
    /// which is what the assertion is for.
    func testThreePlantsInFourGetTheirOwnRankAndNoneIsTwoStepsOut() {
        let ways = Self.filled()
        var steps: [Int: Int] = [:]
        for planting in ways.plantings {
            guard let rank = planting.slot.rank else { continue }
            let own = Orchard.rank(height: planting.traits.height)
            steps[rank.rawValue - own.rawValue, default: 0] += 1
        }
        let ranked = steps.values.reduce(0, +)
        XCTAssertEqual(steps.keys.filter { abs($0) > 1 }, [],
                       "a plant is two ranks from its own: \(steps)")
        XCTAssertGreaterThan(Double(steps[0] ?? 0) / Double(ranked), 0.7,
                             "only \(steps[0] ?? 0) of \(ranked) ranked plants got their own rank")
    }

    // MARK: The ambassador

    func testTheAmbassadorStandsUnderTheMiddleTree() {
        let one = Orchard.ambassador
        XCTAssertEqual(one.plot, 0)
        XCTAssertEqual(one.slot.guild, .middle)
        XCTAssertEqual(one.slot.index, 0)
        XCTAssertNil(one.slot.rank)
        XCTAssertEqual(one.seed, Ambassadors.of(.kinship).seed.hex)
        // It is the tallest of the ten, and it reads as a crown — which is the
        // whole reason the middle guild takes any plant at all.
        XCTAssertEqual(Orchard.rank(height: one.traits.height), .crown)
    }

    func testTheAmbassadorIsTheOldestPlantInTheArea() {
        let ways = Self.filled()
        XCTAssertEqual(ways.plantings.first?.seed, Orchard.ambassador.seed)
    }

    // MARK: How it actually fills

    /// Not an assertion about a number so much as a record of one, so that a
    /// change to the rule that quietly wrecks the fill shows up as a diff.
    func testHowFiveHundredLandOnTheOrchard() {
        let ways = Self.filled()
        let counts = (0..<ways.plots).map { ways.plot($0).count }
        XCTAssertEqual(counts.reduce(0, +), 501)
        XCTAssertEqual(ways.plots, (501 + 19) / 20, "\(ways.plots) plots for 501 plants: \(counts)")
    }
}
