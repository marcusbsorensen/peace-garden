#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

/// The Quiet Garden: an enclosure, hedged round, with a bench in one corner and
/// three groups of planting at the foot of the hedge. `docs/WEB-GARDENS.md`.
///
/// **The second area, and the first one whose rule is *fewer*.** Every other
/// template in the garden asks how to fit plants in well. This one asks how few
/// a plot can hold and still be a garden, because room is what a quiet garden is
/// for. **Ten plants in a 5.2 m plot**, against the Long Walk's forty-eight in
/// the same square: a quarter of the planting and four times as many plots for
/// the same number of arrivals, which `docs/WEB-GARDENS.md` says is right.
///
/// **What a visitor should see**: a lawn with a hedge round it, a bench, and
/// three quiet clumps of planting gathered into the corners. The middle of the
/// room and the middles of all four sides stay grass. The rule is visible as
/// space — which is why the hedge and the bench are not dressing here any more
/// than the path was on the walk.
///
/// The rule runs in SeedCore so the plot service, the website and the app read
/// one copy. `Server/.api/QuietGarden.php` is the port, and
/// `tools/reference/check_quiet_garden.php` holds them together.
public enum QuietGarden {

    // MARK: The room

    /// A web plot's side, the same square every area uses.
    public static let plotSide = 5.2

    /// Where the hedge's inner face stands, out from the middle of the plot, so
    /// the room is 4.6 m across. The Long Walk's figure, because it is the same
    /// hedge at the same thickness and a second number would only be a second
    /// thing to keep in step.
    public static let hedgeFrom = 2.3

    /// How far a plant at the foot of the hedge stands from the middle: 0.35 m
    /// in from the hedge's face, which is clear of it at the heights that grow
    /// here and still reads as planted against it rather than in front of it.
    public static let atTheHedge = 1.95

    /// How far the near plant of a group stands from the middle, along the
    /// other axis. The difference from `atTheHedge` is the group's spread:
    /// 0.85 m, so three plants make a triangle a metre across rather than a row.
    public static let alongTheHedge = 1.10

    /// Where the specimen stands from the middle along the bench's own side —
    /// nearer the corner than a group's arm, so it reads as belonging to the
    /// bench rather than to a group that is not there.
    public static let besideTheBench = 0.95

    /// **The pool: how wide it is, and how far from the middle a lily stands
    /// in it** (27 September 2026).
    ///
    /// The room is 4.6 m across and the nearest plant to the middle is the
    /// specimen, at 2.17 m. A pool 2.2 m wide has a rim at 1.20 and so leaves
    /// 0.97 m of lawn between the water and the nearest stem — seven times the
    /// 0.13 m a nudge can spend, so nothing dry can drift into it.
    ///
    /// The two lilies stand on the diagonal the bench looks down, so somebody
    /// sitting on it looks along the water rather than across it, and the one
    /// at the far end is the one they see first.
    public static let poolAcross = 2.2
    public static let inTheWater = 0.5

    // MARK: The four corners and the pool

    /// The corners of the room, going round. **Corner 0 holds the bench**, and
    /// is therefore the only one that is not a group.
    ///
    /// The turn of a plot — which corner faces the visitor when they come down
    /// onto it — is dressing and is chosen per plot, so nothing here decides
    /// which way the bench looks on a screen. What it decides is that the bench
    /// and the specimen are in the same corner as each other for ever.
    /// **The pool is a fifth place and not a corner**, though it rides in the
    /// same enum so that a slot stays one pair of numbers on the wire and in
    /// the store. It is appended, raw value 4, so every planting already filed
    /// decodes exactly as it did.
    public enum Corner: Int, Codable, CaseIterable, Sendable {
        case bench = 0, second, third, fourth, pool

        /// Which way this corner lies from the middle: ±1 on each axis. The
        /// pool lies in no direction, being the middle.
        public var lie: (x: Double, z: Double) {
            switch self {
            case .bench:  return (-1, -1)
            case .second: return (1, -1)
            case .third:  return (1, 1)
            case .fourth: return (-1, 1)
            case .pool:   return (0, 0)
            }
        }

        /// How many plants stand in this corner. The bench's corner holds one.
        ///
        /// **The pool holds two**, and the number is the lilies' and not the
        /// room's: grown here a lotus's pads reach a median 0.51 m from its
        /// stem and 0.69 at the ninth in ten (`Seedbed.swift` measured it), so
        /// two at `inTheWater` stand 1.0 m apart and their pads lie against
        /// each other, which is what a lily's pads do. A third would be a lily
        /// under a lily.
        public var slots: Int {
            switch self {
            case .bench: return 1
            case .pool:  return 2
            default:     return 3
            }
        }

        /// Whether plants that want dry ground stand here. The bench's corner
        /// does — it holds the specimen — and the pool does not.
        public var isDry: Bool { self != .pool }
    }

    /// Where the bench stands, on the diagonal of its own corner, facing the
    /// middle of the lawn.
    public static var benchSpot: Spot {
        let lie = Corner.bench.lie
        return Spot(x: lie.x * 1.72, z: lie.z * 1.72)
    }

    // MARK: What the rule reads off a plant

    /// Where a plant stands in a group of three: the one at the back, against
    /// the corner, or one of the two arms running out along the hedges.
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
    /// group of three one way. The same plant is the middle of a border there
    /// and the back of a group here, which is what having two areas means.
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

    /// One place in one plot: which corner, and where in that corner's group.
    public struct Slot: Codable, Equatable, Hashable, Sendable {
        public var corner: Corner
        /// 0 is the back of a group, against the corner; 1 and 2 are its arms,
        /// running out along each hedge. The bench's corner has only 0, and
        /// that one plant is the specimen.
        public var index: Int

        public init(corner: Corner, index: Int) {
            self.corner = corner
            self.index = index
        }

        /// The plant beside the bench.
        public static let specimen = Slot(corner: .bench, index: 0)

        /// Where the slot is, in metres from the middle of its plot.
        public var spot: Spot {
            let lie = corner.lie
            if corner == .pool {
                // On the bench's own diagonal, one either side of the middle:
                // index 0 is the far one, which is the one the bench sees
                // first, so the oldest lily in a plot is the one you look at.
                let away = Corner.bench.lie
                let step = index == 0 ? -inTheWater : inTheWater
                return Spot(x: away.x * step, z: away.z * step)
            }
            if corner == .bench {
                return Spot(x: lie.x * atTheHedge, z: lie.z * besideTheBench)
            }
            switch index {
            case 0:  return Spot(x: lie.x * atTheHedge, z: lie.z * atTheHedge)
            case 1:  return Spot(x: lie.x * atTheHedge, z: lie.z * alongTheHedge)
            default: return Spot(x: lie.x * alongTheHedge, z: lie.z * atTheHedge)
            }
        }

        /// Whether this slot is the back of its group. The specimen is not: it
        /// stands alone, so there is nothing for it to be at the back of, and
        /// nor is a lily — the pool is not a group and nothing stands behind
        /// anything in it.
        public var stand: Stand {
            corner.isDry && corner != .bench && index == 0 ? .back : .arm
        }

        /// The first place in the water, which is the one the bench looks at.
        public static let firstInTheWater = Slot(corner: .pool, index: 0)
    }

    /// Every slot in one plot, in the order a tie is broken: the bench's corner
    /// first, so a plot's oldest plant is the one beside the bench, then round
    /// the room.
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
        /// A small offset from the slot, from the seed. Larger than the walk's,
        /// because there is room here and a group of three on exact marks reads
        /// as a planting plan rather than as a clump.
        public var nudge: Spot

        public var spot: Spot {
            Spot(x: slot.spot.x + nudge.x, z: slot.spot.z + nudge.z)
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
        /// After that, in order:
        ///
        /// 1. **A group of its own colour** with a slot it fits, in the oldest
        ///    plot that has one, so a colour finishes rather than several
        ///    starting.
        /// 2. **A corner nobody has planted yet**, which the plant opens as a
        ///    group of its own colour.
        /// 3. **A group of a colour near its own** — the two arcs either side,
        ///    or pale — which is a tonal group and is still a group.
        /// 4. A new plot.
        public func place(for traits: PlantTraits) -> (plot: Int, slot: Slot) {
            // **A plant that wants water goes in water, or nowhere it can be
            // seen to be wrong.** The colour rules above are about groups, and
            // a lily is not in a group — it is in the pool, and the pool is
            // the only place in this room it can stand. So it is asked first
            // and asked separately: the first plot with a free place in its
            // water, or a new plot if every pool is full.
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
            /// A corner with nothing in it, opened as a group of this colour.
            case fresh
            /// A group of a colour near this one.
            case near
        }

        func slot(in plot: Int, for traits: PlantTraits, kinship: Kinship) -> Slot? {
            let here = self.plot(plot)
            let taken = Set(here.map(\.slot))
            // The plant's own stand first, then the other one — the same shape
            // as the walk's *its own tier, then the tier beside it*. A back
            // plant that finds the back taken may still stand in an arm, as
            // long as nothing ends up in front of something shorter.
            let own = stand(height: traits.height)
            let stands: [Stand] = own == .back ? [.back, .arm] : [.arm, .back]

            for wanted in stands {
                // The bench's corner holds the specimen and the pool holds
                // lilies; neither is a group, and a dry plant goes in neither.
                for corner in Corner.allCases where corner != .bench && corner.isDry {
                    let group = here.filter { $0.slot.corner == corner }
                    switch kinship {
                    case .own where group.isEmpty: continue
                    case .own where group[0].traits.family != traits.family: continue
                    case .fresh where !group.isEmpty: continue
                    case .near where group.isEmpty: continue
                    case .near where !near(group[0].traits.family).contains(traits.family): continue
                    default: break
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

        /// Whether a plant this tall can stand in this slot: the back of a group
        /// is at least as tall as either of its arms.
        ///
        /// The Long Walk's rule said the same thing about a border and is why
        /// this one is a check rather than a row: *nothing stands in front of
        /// something shorter than itself*. A group of three seen from the middle
        /// of a lawn is a small border, and a short plant at its back is the
        /// same fault at a smaller scale.
        func inOrder(_ height: Double, at slot: Slot, among group: [Planting]) -> Bool {
            for other in group {
                if slot.index == 0 && other.traits.height > height { return false }
                if slot.index != 0 && other.slot.index == 0 && other.traits.height < height { return false }
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
            // **A lily takes no nudge.** The nudge is there so that a group of
            // three on exact marks reads as a clump rather than a planting
            // plan, and two lilies in a pool 2.2 m across are neither: the
            // water is small enough that where they float is a decision and
            // not a chance, and 0.13 m either way would put their pads over
            // each other more often than not.
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

/// The Quiet Garden's reading of a plant: the back of a group of three, or one
/// of its arms.
extension PlantTraits {
    public var stand: QuietGarden.Stand { QuietGarden.stand(height: height) }
}
