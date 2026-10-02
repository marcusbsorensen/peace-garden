#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

/// The Quiet Garden: an enclosure, hedged round, with a bench in one corner, a
/// pool, and its planting in groups of one, five, three and one at the foot of
/// the hedge. `docs/WEB-GARDENS.md`.
///
/// **The second area, and the first one whose rule is *fewer*.** Every other
/// template in the garden asks how to fit plants in well. This one asks how few
/// a plot can hold and still be a garden, because room is what a quiet garden is
/// for. **Ten plants in a 5.2 m plot**, against the Long Walk's forty-eight in
/// the same square: a quarter of the planting and four times as many plots for
/// the same number of arrivals, which `docs/WEB-GARDENS.md` says is right.
///
/// **What a visitor should see**: a lawn with a hedge round it, a bench, and
/// quiet clumps of planting gathered at the hedge's foot. The rule is visible
/// as space — which is why the hedge and the bench are not dressing here any
/// more than the path was on the walk.
///
/// **An asymmetric room, since 2 October 2026** (Marcus, from the research's
/// pictures: `design/garden-layouts-2026-10-02/RESEARCH.md`, option A). The
/// ten became one, five, three and one: the specimen by the bench, a group of
/// five in the far corner across the water, which is what the bench looks at,
/// a group of three along a side, and one plant alone across the lawn that
/// repeats the five's colour. The pool moved off the middle toward the bench,
/// with three stepping stones from the seat to the water. *Peace* as the
/// pause between things: the lawn is the largest part of the composition.
/// The places come from a table made offline (`PlaceTable.quietRoom`), and
/// each room is turned and mirrored by its number (`variants`), so no two
/// rooms side by side are laid alike.
///
/// The rule runs in SeedCore so the plot service, the website and the app read
/// one copy. `Server/.api/QuietGarden.php` is the port, and
/// `tools/reference/check_quiet_garden.php` holds them together.
public enum QuietGarden {

    // MARK: The room

    /// A web plot's side, the same square every area uses.
    public static let plotSide = 5.2

    /// **How this area's plots vary**, from each plot's number (`PlotVariant`,
    /// Marcus's decision of 2 October 2026). Turned and mirrored eight ways, as
    /// `quiet-a-rooms.png` turns the rooms: the bench in any corner, the five
    /// across the water from it, the three on either hand.
    public static let variants = PlotVariant.Space(turns: 4, mirror: true)

    /// The plot's variant: which way round its room is laid.
    public static func variant(of plot: Int) -> PlotVariant {
        PlotVariant.of(plot: plot, area: .peace)
    }

    /// **The room's places, the pool and the stones, made offline**
    /// (`tools/layouts/tables/quiet_room.py`): the specimen, the five, the
    /// three, the echo and the pool's two, in that order and each group in
    /// fill order, with the pool's outline as `pool` and the stepping stones'
    /// middles as `stones`.
    public static let table = PlaceTable.quietRoom

    /// Where the hedge's inner face stands, out from the middle of the plot, so
    /// the room is 4.6 m across. The Long Walk's figure, because it is the same
    /// hedge at the same thickness and a second number would only be a second
    /// thing to keep in step.
    public static let hedgeFrom = 2.3

    /// How far a plant at the foot of the hedge stands from the middle at most:
    /// 0.35 m in from the hedge's face, which is clear of it at the heights
    /// that grow here and still reads as planted against it rather than in
    /// front of it. The table keeps every place within it.
    public static let atTheHedge = 1.95

    // MARK: The groups and the pool

    /// The room's groups, which ride in what was its corners' numbering, so a
    /// slot stays one pair of numbers on the wire and in the store. **Group 0
    /// holds the bench's specimen**, and is not a group of anything.
    ///
    /// **One, five, three and one since 2 October 2026**, where it was the
    /// specimen and three groups of three, one to a corner. The numbers are the
    /// corners' numbers: `five` is what `second` was, and so on, and a planting
    /// filed before then reads as standing in the group of the same number
    /// until the replant places it again (`Slot.spot` keeps an old echo's arm
    /// on the echo's own place).
    ///
    /// **The pool is a fifth place and not a group**, appended as raw value 4
    /// on 27 September 2026. The live garden never sends this area a lily
    /// (`Areas.genusHeads`), so it stays empty; the rule still has a place for
    /// one, so a lily handed to it is never put on the lawn.
    public enum Corner: Int, Codable, CaseIterable, Sendable {
        case bench = 0, five, three, echo, pool

        /// How many plants stand in it.
        ///
        /// **The pool holds two**, and the number is the lilies' and not the
        /// room's: grown here a lotus's pads reach a median 0.51 m from its
        /// stem and 0.69 at the ninth in ten (`Seedbed.swift` measured it), so
        /// two 0.9 m apart lie against each other, which is what a lily's pads
        /// do. A third would be a lily under a lily.
        public var slots: Int {
            switch self {
            case .bench, .echo: return 1
            case .five: return 5
            case .three: return 3
            case .pool: return 2
            }
        }

        /// Whether plants that want dry ground stand here. The bench's corner
        /// does — it holds the specimen — and the pool does not.
        public var isDry: Bool { self != .pool }

        /// Whether it is a group a colour claims: the five and the three. The
        /// echo is claimed by the five's colour and the specimen by nobody.
        public var isGroup: Bool { self == .five || self == .three }

        /// Where its places begin in the table.
        var first: Int {
            Corner.allCases.prefix(while: { $0 != self }).map(\.slots).reduce(0, +)
        }
    }

    /// Where the bench stands in the table's frame, on the diagonal of its own
    /// corner, facing the middle of the lawn and the five beyond the water.
    public static let benchSpot = Spot(x: -1.72, z: -1.72)

    /// Where the bench stands on a plot laid this way round.
    public static func bench(on variant: PlotVariant) -> Spot {
        variant.apply(benchSpot)
    }

    // MARK: What the rule reads off a plant

    /// Where a plant stands in a group: at the back, toward the corner, or one
    /// of the arms running out along the hedges and toward the lawn. The five
    /// has two at the back and three arms, the three one and two.
    public enum Stand: Int, Codable, CaseIterable, Sendable {
        case arm, back
    }

    /// **The cut, measured then set to fit the slots.** Across three hundred
    /// crossings of three hundred different pairs of parents, grown heights run
    /// 0.15 m to 2.31 m. A group is one back and two arms, so the back wants the
    /// tallest third of the population and the cut belongs at the 67th centile,
    /// which measured 1.090 m. Set at 1.09. It was 1.13 until the plants'
    /// shapes changed on 24 September 2026, and was measured again then on the
    /// Long Walk's three hundred.
    ///
    /// **1.08 since 29 September 2026**: the 67th centile of three thousand
    /// crossings after the re-roll of the 28th is 1.076 m. Measured on the
    /// same three thousand as the Long Walk's cuts, for the reason given there.
    ///
    /// It is not the Long Walk's 1.20 m and should not be: that cut divides
    /// three tiers of a border in the proportion 5:4:3, and this one divides a
    /// group one way. The same plant is the middle of a border there and the
    /// back of a group here, which is what having two areas means.
    ///
    /// **Kept at 1.08 when the groups became a five and a three** (2 October
    /// 2026): three backs in eight group places is 37.5%, against the third
    /// it was cut for, and the specimen and the echo take any height, so the
    /// tallest third of ten places is still about right. The fill, measured on
    /// SeedCore's own plants by `tools/layouts/harness`, is what says so.
    public static let backFrom = 1.08

    public static func stand(height: Double) -> Stand {
        height < backFrom ? .arm : .back
    }

    // MARK: Colour

    /// **The colour families a group will take besides its own.**
    ///
    /// A group is one colour: that is the whole of what makes planting read as
    /// deliberate in a room with this much grass in it. But the families are
    /// nothing like evenly drawn — measured over three hundred crossings, two of
    /// the seven take 43% of plants between them and pale takes 3.7% — so a rule
    /// that took nothing but its own colour would leave pale groups that never
    /// filled and plots that opened for want of a match. So a group also takes
    /// **the two arcs either side of its own, and pale**, which is a tonal group
    /// rather than a single hue and is what a quiet planting actually is. Pale
    /// takes anything, because white goes with everything and because a pale
    /// group on its own would be three plants in eighty.
    ///
    /// It is the same shape as the Long Walk's *the tier beside its own*: a
    /// first choice, a near-enough second, and a new plot only when neither
    /// fits.
    public static func near(_ family: Int) -> [Int] {
        if family == LongWalk.paleFamily { return Array(0..<LongWalk.paleFamily) }
        let arcs = LongWalk.paleFamily
        return [(family + arcs - 1) % arcs, (family + 1) % arcs, LongWalk.paleFamily]
    }

    // MARK: Slots

    /// One place in one plot: which group, and which place in it.
    public struct Slot: Codable, Equatable, Hashable, Sendable {
        public var corner: Corner
        /// The place within its group, in the group's fill order: the place
        /// nearest the corner first, then each the farthest from those before
        /// it. The bench's corner and the echo have only 0.
        public var index: Int

        public init(corner: Corner, index: Int) {
            self.corner = corner
            self.index = index
        }

        /// The plant beside the bench.
        public static let specimen = Slot(corner: .bench, index: 0)

        /// Where its place is in the table, and so in `QuietGarden.table`.
        /// **A planting filed before 2 October 2026 can hold an index its group
        /// no longer has** — the arms of what was the fourth corner's group of
        /// three, now the echo — and reads as standing on the group's last
        /// place until the replant places it again.
        var row: Int { corner.first + min(index, corner.slots - 1) }

        /// Where the slot is, in metres from the middle of the plot **as the
        /// table draws it**, before the room is turned: `spot(on:)` turns it.
        public var spot: Spot {
            QuietGarden.table.places(nudge: 0)[row].spot
        }

        /// Where the slot is on a plot laid this way round.
        public func spot(on variant: PlotVariant) -> Spot {
            QuietGarden.table.spot(row, on: variant)
        }

        /// Whether this slot is the back of its group, as the table says: two
        /// of the five's, one of the three's. The specimen and the echo stand
        /// alone, so there is nothing for either to be at the back of, and nor
        /// is a lily — the pool is not a group and nothing stands behind
        /// anything in it.
        public var stand: Stand {
            QuietGarden.table.tag("stand", of: QuietGarden.table.places(nudge: 0)[row]) == 1 ? .back : .arm
        }

        /// The first place in the water.
        public static let firstInTheWater = Slot(corner: .pool, index: 0)
    }

    /// Every slot in one plot, in the order a tie is broken: the bench's corner
    /// first, so a plot's oldest plant is the one beside the bench, then the
    /// five, the three, the echo and the pool, each in its fill order.
    public static let slots: [Slot] = Corner.allCases.flatMap { corner in
        (0..<corner.slots).map { Slot(corner: corner, index: $0) }
    }

    // MARK: Planting

    /// One plant in the room, placed for good.
    public struct Planting: Codable, Equatable, Sendable {
        public var seed: String
        public var plot: Int
        public var slot: Slot
        public var traits: PlantTraits
        /// A small offset from the slot, from the seed, in the table's frame.
        /// Larger than the walk's, because there is room here and a group on
        /// exact marks reads as a planting plan rather than as a clump.
        public var nudge: Spot

        /// **Where it stands**: its place and its nudge, turned and mirrored
        /// as its room is laid. The nudge is added in the table's frame and the
        /// sum turned (`tools/layouts/README.md`), so a turn moves a plant
        /// exactly and the same on every host.
        public var spot: Spot {
            QuietGarden.variant(of: plot).apply(Spot(x: slot.spot.x + nudge.x, z: slot.spot.z + nudge.z))
        }
    }

    /// The whole area: every planting, in the order they arrived. Append-only,
    /// for the reason the Long Walk is — a place somebody visited yesterday is
    /// the same place today.
    public struct Room: Codable, Equatable, Sendable {
        public private(set) var plantings: [Planting] = []

        public init() {}

        /// **The room as it opened**: the peace ambassador beside the bench, and
        /// nothing else. `QuietGarden.ambassador` is the planting.
        public static func opened() -> Room {
            var room = Room()
            let one = Ambassadors.of(.peace)
            room.plant(seed: one.seed, traits: LongWalk.traits(of: one.genome))
            return room
        }

        public var plots: Int { (plantings.map(\.plot).max() ?? -1) + 1 }

        public func plot(_ index: Int) -> [Planting] {
            plantings.filter { $0.plot == index }
        }

        /// Where the next plant with these traits would go, without planting it.
        ///
        /// **A plot's first plant stands by the bench**, always: a new plot is
        /// opened by taking its specimen slot, so no plot ever exists without
        /// one. That is also what makes the ambassador the specimen of plot 0
        /// without a rule saying so, and it is the same answer the Long Walk
        /// gave — the oldest plant in the area stands where you meet it.
        ///
        /// After that, in order, each in the oldest plot that has room:
        ///
        /// 1. **A group of its own colour** with a slot it fits — the five,
        ///    then the three, then the echo, which shows the five's colour —
        ///    so a colour finishes rather than several starting.
        /// 2. **A group nobody has planted yet**, the five before the three,
        ///    which the plant opens as a group of its own colour. The echo is
        ///    never opened: it waits for the five's colour.
        /// 3. **A group of a colour near its own** — the two arcs either side,
        ///    or pale — which is a tonal group and is still a group; and the
        ///    echo, if its colour is near the five's.
        /// 4. A new plot.
        public func place(for traits: PlantTraits) -> (plot: Int, slot: Slot) {
            // **A plant that wants water goes in water, or nowhere it can be
            // seen to be wrong.** The colour rules above are about groups, and
            // a lily is not in a group — it is in the pool, and the pool is
            // the only place in this room it can stand. So it is asked first
            // and asked separately: the first plot with a free place in its
            // water, or a new plot if every pool is full. The live garden
            // never sends this area one, so this is the rule keeping its
            // promise rather than anything a visitor sees.
            if traits.wantsWater {
                for plot in 0..<plots {
                    let taken = Set(self.plot(plot).map(\.slot))
                    if let free = QuietGarden.slots.first(where: {
                        $0.corner == .pool && !taken.contains($0)
                    }) { return (plot, free) }
                }
                return (plots, .firstInTheWater)
            }
            for kinship in Kinship.allCases {
                for plot in 0..<plots {
                    if let slot = slot(in: plot, for: traits, kinship: kinship) {
                        return (plot, slot)
                    }
                }
            }
            return (plots, .specimen)
        }

        /// How willing the rule is, on this pass, to put a plant somewhere that
        /// is not a group of its own colour.
        enum Kinship: CaseIterable {
            /// A group already showing this plant's colour.
            case own
            /// A group with nothing in it, opened as a group of this colour.
            case fresh
            /// A group of a colour near this one.
            case near
        }

        /// The groups a dry plant may join, in the order they are asked: the
        /// five, the three, and the echo.
        static let groups: [Corner] = [.five, .three, .echo]

        func slot(in plot: Int, for traits: PlantTraits, kinship: Kinship) -> Slot? {
            let here = self.plot(plot)
            let taken = Set(here.map(\.slot))
            // The plant's own stand first, then the other one — the same shape
            // as the walk's *its own tier, then the tier beside it*. A back
            // plant that finds the back taken may still stand in an arm, as
            // long as nothing ends up in front of something shorter.
            let own = stand(height: traits.height)
            let stands: [Stand] = own == .back ? [.back, .arm] : [.arm, .back]
            // **The echo shows the five's colour**: the five's first plant
            // claims both, and the echo is never opened on its own.
            let five = here.first { $0.slot.corner == .five }?.traits.family

            for wanted in stands {
                for corner in Room.groups {
                    let group = here.filter { $0.slot.corner == corner }
                    let claim = corner == .echo ? five : group.first?.traits.family
                    switch kinship {
                    case .own:
                        guard claim == traits.family else { continue }
                    case .fresh:
                        guard corner.isGroup, group.isEmpty else { continue }
                    case .near:
                        guard let claim, near(claim).contains(traits.family) else { continue }
                    }
                    let open = QuietGarden.slots.filter {
                        $0.corner == corner && $0.stand == wanted && !taken.contains($0)
                            && inOrder(traits.height, at: $0, among: group)
                    }
                    if let first = open.first { return first }
                }
            }
            return nil
        }

        /// Whether a plant this tall can stand in this slot: nothing at the
        /// back of a group is shorter than anything in its arms.
        ///
        /// The Long Walk's rule said the same thing about a border and is why
        /// this one is a check rather than a row: *nothing stands in front of
        /// something shorter than itself*. A group seen from the middle of a
        /// lawn is a small border, and a short plant at its back is the same
        /// fault at a smaller scale. Two at the back of the five are free of
        /// each other, and so are its three arms, as the Crossing's three on
        /// an arc are.
        func inOrder(_ height: Double, at slot: Slot, among group: [Planting]) -> Bool {
            for other in group {
                if slot.stand == .back, other.slot.stand == .arm, other.traits.height > height { return false }
                if slot.stand == .arm, other.slot.stand == .back, other.traits.height < height { return false }
            }
            return true
        }

        /// Plant one arrival, and say where it went.
        @discardableResult
        public mutating func plant(seed: SeedID, traits: PlantTraits) -> Planting {
            let (plot, slot) = place(for: traits)
            let bytes = [UInt8](seed.bytes)
            func jitter(_ i: Int, _ reach: Double) -> Double {
                guard bytes.count > i else { return 0 }
                return (Double(bytes[i]) / 255 - 0.5) * 2 * reach
            }
            // **A lily takes no nudge.** The nudge is there so that a group on
            // exact marks reads as a clump rather than a planting plan, and two
            // lilies in a pool two metres long are neither: the water is small
            // enough that where they float is a decision and not a chance, and
            // 0.13 m either way would put their pads over each other more
            // often than not.
            let reach = slot.corner.isDry ? 0.13 : 0.0
            let planting = Planting(seed: seed.hex, plot: plot, slot: slot, traits: traits,
                                    nudge: Spot(x: jitter(22, reach), z: jitter(23, reach)))
            plantings.append(planting)
            return planting
        }
    }

    // MARK: The ambassador

    /// **The plant beside the bench in the first plot.**
    ///
    /// *Bela caerulea* — `Ambassadors.of(.peace)` — placed by this rule into
    /// an empty room, which puts it in the specimen slot because a plot's first
    /// plant always stands by the bench. The same answer the Long Walk gave to
    /// *which slot is the specimen*, reached by a different template: the oldest
    /// plant in an area stands where a visitor arriving meets it.
    ///
    /// **It was *Olyne paniculata*, 0.75 m, until the re-roll of 28 September
    /// 2026, and that was the point.** *Bela caerulea*, a poppy, is 1.06 m and
    /// stands beside the bench for the same reason. Yesterday's finding on the walk
    /// was that a specimen slot has to be one the area's own ambassador can
    /// actually stand in — nine of the ten are edge or middle plants. A specimen
    /// standing alone in lawn beside a seat has no height to live up to, where
    /// the back of a group would have. This template was written round that.
    ///
    /// Derived rather than stored, as the walk's is: the slot and the nudge are
    /// pure functions of the pinned seed, so there is no row for a withdrawal, a
    /// report or a backup to reach.
    public static let ambassador: Planting = Room.opened().plantings[0]
}

/// The Quiet Garden's reading of a plant: the back of a group, or one of its
/// arms.
extension PlantTraits {
    public var stand: QuietGarden.Stand { QuietGarden.stand(height: height) }
}
