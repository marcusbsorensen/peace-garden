#if os(WASI)
import FoundationEssentials
import WASILibc
#else
import Foundation
#endif

/// The Long Walk: a double herbaceous border either side of a mown path, one of
/// the ten areas of the shared garden on the website. `docs/WEB-GARDENS.md`.
///
/// **Curated by rule, not by hand.** Nobody places a plant here. An arriving
/// plant is given a slot once, by the rule below, and never moves; the rule is
/// what we curate. It lives in SeedCore so the plot service, the website and
/// the app all read the same one.
///
/// The rule is the oldest advice there is about a border, in the three parts
/// every border book gives it:
///
/// 1. **Tall at the back, low at the front.** Three tiers, set from the plant's
///    grown height, so nothing stands in front of something shorter.
/// 2. **Drifts, not dots.** Plants of one colour are set next to each other in
///    groups of three to five, so the eye reads a sweep of colour rather than
///    a confetti of single plants.
/// 3. **Repetition down the length.** Every plant here is unique — it grew from
///    one meeting — so a border cannot repeat a plant the way a nursery border
///    repeats a variety. It repeats a colour instead: a drift, once full, is
///    left, and the same colour starts again further down the walk.
///
/// **The plot is 5.2 m square**, the app's own, with the walk running down its
/// `z` axis so that on the isometric screen the path runs away diagonally, the
/// way a path is seen from above and to one side.
public enum LongWalk {

    // MARK: The ground

    /// A web plot's side, the app's fourteen-plant plot. Fixed: a web plot does
    /// not grow with what is in it, because the next plot is where the walk goes on.
    public static let plotSide = 5.2

    /// The mown path, either side of `x = 0`. 1.2 m: two people abreast.
    public static let pathHalfWidth = 0.6

    /// Where each border's hedge begins, measured out from the middle of the path.
    public static let hedgeFrom = 2.3

    /// The length of the walk a plot's slots are spread over, leaving a little
    /// at each end so one plot's last plant does not stand on the next plot's first.
    public static let plantedLength = 4.8

    // MARK: Tiers

    /// Front, middle and back of a border.
    public enum Tier: Int, Codable, CaseIterable, Sendable {
        case edge, middle, back

        /// How far out from the middle of the path this tier stands, in metres.
        public var depth: Double {
            switch self {
            case .edge: return 0.95
            case .middle: return 1.45
            case .back: return 1.95
            }
        }

        /// Slots in this tier on one side of one plot, in two staggered rows.
        /// Fewer at the back, where the plants are bigger and are spaced wider,
        /// as in any border.
        ///
        /// **Doubled on 18 September**, from one row of 5, 4 and 3, after the
        /// walk was looked at with 500 plants in it. One row read as single
        /// stems standing on turf, about 1.4 plants a square metre; a border is
        /// planted at three to five, and a drift of one colour only reads as a
        /// drift when its plants touch. Two rows give about 2.8 and some depth.
        /// The proportions are unchanged, so the tier cuts still fit.
        public var slots: Int { 2 * perRow }

        /// Slots in one of a tier's two rows.
        public var perRow: Int {
            switch self {
            case .edge: return 5
            case .middle: return 4
            case .back: return 3
            }
        }

        /// How far each row stands from the tier's line, in and out.
        static let rowOffset = 0.13
    }

    /// The tier a grown plant belongs in.
    ///
    ///
    /// **Measured, then set to fit the slots.** Across three hundred crossings
    /// of three hundred different pairs of parents, grown heights run 0.21 m to
    /// 2.22 m with thirds at 0.85 m and 1.19 m. A side of a plot has five front
    /// slots, four middle and three back a row, so the cuts are at the 42nd and 75th
    /// centiles instead, 0.93 m and 1.28 m: set at the thirds, the back rows
    /// filled first and every plot opened with its front edge half empty.
    ///
    /// Crossings of **one** person with forty others ran taller and were half
    /// bells, which is why the sample is three hundred different pairs.
    /// **Named, as the other four areas' cuts are.** They were literals inside
    /// this function until 22 September, which meant a test that wanted to
    /// check how close a plant stands to a tier boundary had to write 0.93 down
    /// a second time — and a second copy of a number is a number that can
    /// drift from the one it copies.
    public static let middleFrom = 0.93
    public static let backFrom = 1.28

    public static func tier(height: Double) -> Tier {
        if height < middleFrom { return .edge }
        if height < backFrom { return .middle }
        return .back
    }

    // MARK: Colour

    /// The colour families a drift is made of: six arcs of the hue circle, and
    /// pale for the flowers too unsaturated to have a hue at all.
    public static let paleFamily = 6

    public static func family(hue: Double, saturation: Double) -> Int {
        if saturation < 0.22 { return paleFamily }
        let turn = hue > 1 ? hue / 360 : hue
        let wrapped = turn - turn.rounded(.down)
        return min(5, Int(wrapped * 6))
    }

    // MARK: A plant's traits

    /// What a placement rule needs to know about a plant, and nothing else.
    ///
    /// **`PlantTraits` under another name**, since 21 September, when the Quiet
    /// Garden wanted the same two facts. The grown height and the flower's
    /// colour family are facts about a plant rather than about this area; what
    /// belongs to an area is what it reads off them, which is `tier` here and
    /// `stand` there. The spelling stays because it is in
    /// `long_walk_vectors.json` and in the PHP port, and the encoded shape is
    /// the same two fields either way.
    public typealias Traits = PlantTraits

    /// Read from the grown plant. Builds its mesh once, which is why a plant's
    /// traits are stored with it rather than read again.
    ///
    /// Not the Long Walk's alone — every area needs these two — but it lives
    /// here because this is the area that first needed it, and moving it would
    /// rename a function the port and the vectors both know.
    public static func traits(of genome: Genome) -> Traits {
        let bounds = Maturity.bounds(for: genome)
        let petal = genome.palette.petalBase
        return Traits(height: Double(bounds.max.y - bounds.min.y),
                      family: family(hue: petal.hue, saturation: petal.saturation),
                      kind: genome.name.epithet,
                      hue: petal.hue)
    }

    // MARK: Slots

    public enum Side: Int, Codable, CaseIterable, Sendable {
        case left = -1
        case right = 1
    }

    /// One place in one plot.
    public struct Slot: Codable, Equatable, Hashable, Sendable {
        public var side: Side
        public var tier: Tier
        /// Down the walk, from the start of the plot.
        public var index: Int

        public init(side: Side, tier: Tier, index: Int) {
            self.side = side
            self.tier = tier
            self.index = index
        }

        /// Where the slot is, in metres from the middle of its plot.
        ///
        /// Even indices are the tier's inner row and odd the outer, staggered
        /// by half a space so that no plant stands straight behind another. The
        /// three tiers have different numbers of slots, so they are staggered
        /// against each other too — plants in straight ranks down a border read
        /// as a nursery, not a garden.
        public var spot: Spot {
            let spacing = LongWalk.plantedLength / Double(tier.perRow)
            let row = index % 2, along = index / 2
            let depth = tier.depth + (row == 0 ? -Tier.rowOffset : Tier.rowOffset)
            return Spot(x: Double(side.rawValue) * depth,
                        z: -LongWalk.plantedLength / 2 + (Double(along) + 0.25 + 0.5 * Double(row)) * spacing)
        }
    }

    /// Every slot in one plot, in the order a tie is broken: down the walk
    /// first, so a plot fills from its start and a visitor walking down it
    /// meets the planted part first.
    public static let slots: [Slot] = {
        var all: [Slot] = []
        for tier in Tier.allCases {
            for index in 0..<tier.slots {
                for side in Side.allCases {
                    all.append(Slot(side: side, tier: tier, index: index))
                }
            }
        }
        return all.sorted { a, b in
            if a.spot.z != b.spot.z { return a.spot.z < b.spot.z }
            return a.side.rawValue < b.side.rawValue
        }
    }()

    // MARK: Planting

    /// One plant in the walk, placed for good.
    public struct Planting: Codable, Equatable, Sendable {
        public var seed: String
        public var plot: Int
        public var slot: Slot
        public var traits: Traits
        /// A small offset from the slot, from the seed, so plants set by a rule
        /// do not stand on a grid. Kept, like everything else here.
        public var nudge: Spot

        /// Where it stands in its plot.
        public var spot: Spot {
            Spot(x: slot.spot.x + nudge.x, z: slot.spot.z + nudge.z)
        }
    }

    /// The whole walk: every planting, in the order they arrived.
    ///
    /// **Append-only.** `plant` adds one and changes nothing already there. That
    /// is the property the old seed-derived grid existed to give — a place
    /// visited yesterday is the same place today — kept without deriving the
    /// place from the seed, which could not know which bed has room.
    public struct Walk: Codable, Equatable, Sendable {
        public private(set) var plantings: [Planting] = []

        public init() {}

        /// **The walk as it opened**: the travel ambassador standing in it, and
        /// nothing else. `LongWalk.ambassador` is the planting.
        ///
        /// Kept apart from `init()` deliberately. An empty walk is what the rule
        /// is judged against — `LongWalkVectorTests` plants six hundred arrivals
        /// into one and pins where each went — and a walk that arrived with a
        /// plant already in it would move every one of those placements.
        public static func opened() -> Walk {
            var walk = Walk()
            let one = Ambassadors.of(.travel)
            walk.plant(seed: one.seed, traits: LongWalk.traits(of: one.genome))
            return walk
        }

        /// Plots opened so far.
        public var plots: Int { (plantings.map(\.plot).max() ?? -1) + 1 }

        /// Where the next plant with these traits would go, without planting it.
        ///
        /// **The rule is not "tall ones in the back row".** It is that nothing
        /// stands in front of something shorter than itself, which is what the
        /// back row is for. Filling by row alone broke on the first real mix:
        /// a few more tall plants than back slots, and each surplus one opened a
        /// plot of its own, so the walk trailed off into beds holding six back-row
        /// plants each and nothing in front of them.
        ///
        /// So, in order:
        ///
        /// 1. Its own tier, in the oldest plot with room, so gaps left behind
        ///    are filled before the walk goes on.
        /// 2. The tier next to its own, in the oldest plot with room, where
        ///    everything near it in front is shorter and everything behind is
        ///    taller.
        /// 3. Its own tier in a new plot.
        ///
        /// The ordering is checked for every placement, its own tier included,
        /// so it holds everywhere and not on average.
        public func place(for traits: Traits) -> (plot: Int, slot: Slot) {
            let own = traits.tier
            let beside = Tier.allCases.filter { abs($0.rawValue - own.rawValue) == 1 }

            for tiers in [[own], beside] {
                for plot in 0..<plots {
                    let taken = Set(plantings.filter { $0.plot == plot }.map(\.slot))
                    let open = LongWalk.slots.filter {
                        tiers.contains($0.tier) && !taken.contains($0)
                            && inOrder(traits.height, at: $0, in: plot)
                    }
                    if let best = best(of: open, in: plot, for: traits) { return (plot, best) }
                }
            }
            let open = LongWalk.slots.filter { $0.tier == own }
            return (plots, best(of: open, in: plots, for: traits) ?? open[0])
        }

        /// Whether a plant this tall can stand in this slot: shorter than what
        /// is near it behind, taller than what is near it in front.
        func inOrder(_ height: Double, at slot: Slot, in plot: Int) -> Bool {
            for other in plantings where other.plot == plot
                && other.slot.side == slot.side
                && abs(other.slot.spot.z - slot.spot.z) <= Self.orderReach {
                let behind = other.slot.tier.rawValue > slot.tier.rawValue
                let inFront = other.slot.tier.rawValue < slot.tier.rawValue
                if behind && other.traits.height < height { return false }
                if inFront && other.traits.height > height { return false }
            }
            return true
        }

        /// Plant one arrival, and say where it went.
        @discardableResult
        public mutating func plant(seed: SeedID, traits: Traits) -> Planting {
            let (plot, slot) = place(for: traits)
            let bytes = [UInt8](seed.bytes)
            func jitter(_ i: Int, _ reach: Double) -> Double {
                guard bytes.count > i else { return 0 }
                return (Double(bytes[i]) / 255 - 0.5) * 2 * reach
            }
            let planting = Planting(seed: seed.hex, plot: plot, slot: slot, traits: traits,
                                    nudge: Spot(x: jitter(20, 0.1), z: jitter(21, 0.14)))
            plantings.append(planting)
            return planting
        }

        /// The plantings in one plot.
        public func plot(_ index: Int) -> [Planting] {
            plantings.filter { $0.plot == index }
        }

        // MARK: Choosing among open slots

        /// How far along the walk "in front of" and "behind" reach, for the
        /// rule that nothing stands in front of something shorter.
        static let orderReach = 1.3

        /// How near two plants must be to count as one drift: the plant
        /// staggered beside it in the other row, or the nearest row of the tier
        /// behind or in front. Set for two rows a tier; at one row it was 1.3 m
        /// along and 0.6 m across, and with two it let drifts chain to seven.
        static let driftReach = 0.85
        static let driftDepth = 0.3

        /// The best open slot for a plant of this colour:
        ///
        /// - **Beside a drift of its colour that is still short of five.** The
        ///   larger the drift the better, so drifts finish rather than several
        ///   starting and none reaching three.
        /// - **Otherwise, away from any of its colour.** A drift that is full
        ///   stays full, and a new one starts somewhere else down the walk —
        ///   which is the repetition.
        /// - **Never beside a full drift of its colour**, or between drifts that
        ///   would join past five. Nil if that leaves nothing.
        /// - Ties go down the walk, then left before right.
        func best(of open: [Slot], in plot: Int, for traits: Traits) -> Slot? {
            let here = plantings.filter { $0.plot == plot }
            var bestSlot: Slot?
            var bestScore = Int.min
            for slot in open {
                let near = here.filter {
                    $0.slot.side == slot.side
                        && abs($0.slot.spot.z - slot.spot.z) <= Self.driftReach
                        && abs($0.slot.spot.x - slot.spot.x) <= Self.driftDepth
                }
                let kin = near.filter { $0.traits.family == traits.family }
                let score: Int
                if kin.isEmpty {
                    score = 0
                } else {
                    // Every drift it would touch, joined: a slot between two
                    // short drifts of one colour makes one long one.
                    var joined: Set<Slot> = []
                    for neighbour in kin { joined.formUnion(drift(from: neighbour, in: here)) }
                    // Never past five: a slot that would make a longer drift
                    // is no slot for this colour, and the rule looks in the
                    // next tier or plot instead. Another colour will take it.
                    guard joined.count < 5 else { continue }
                    score = 10 + joined.count
                }
                if score > bestScore {
                    bestScore = score
                    bestSlot = slot
                }
            }
            return bestSlot
        }

        /// How many plants of one colour are joined, neighbour to neighbour, to
        /// this one.
        func driftSize(from start: Planting, in here: [Planting]) -> Int {
            drift(from: start, in: here).count
        }

        /// The slots of the plants in that drift.
        func drift(from start: Planting, in here: [Planting]) -> Set<Slot> {
            var seen: Set<Slot> = [start.slot]
            var frontier = [start]
            while let next = frontier.popLast() {
                for other in here where !seen.contains(other.slot)
                    && other.traits.family == start.traits.family
                    && other.slot.side == next.slot.side
                    && abs(other.slot.spot.z - next.slot.spot.z) <= Self.driftReach
                    && abs(other.slot.spot.x - next.slot.spot.x) <= Self.driftDepth {
                    seen.insert(other.slot)
                    frontier.append(other)
                }
            }
            return seen
        }
    }

    // MARK: The ambassador

    /// **The plant standing where the walk begins.**
    ///
    /// *Halula crassicaulis* — `Ambassadors.of(.travel)`, sown a month before
    /// the garden opened — placed by this rule into an empty walk, which is the
    /// whole of what makes it the specimen. `docs/WEB-GARDENS.md` asks which
    /// slot of a template an ambassador stands in; for this area the answer is
    /// that it stands in the first one the rule filled. A double border's
    /// feature belongs at the end of its vista, and this walk has no end — its
    /// plots open end to end for as long as people go on meeting — so what it
    /// has instead is a head, and the oldest plant in the area stands at it.
    ///
    /// **It takes its own tier, like anything else.** *Halula* is 1.02 m, which
    /// is the middle of a border rather than the back of one, and only one of
    /// the ten ambassadors is a back-tier plant at all. A specimen slot fixed at
    /// the back of a border would have stood a short plant behind taller ones in
    /// nine areas out of ten, which is the one rule the walk is built on.
    ///
    /// **It is not a row anywhere.** A slot and a nudge are both pure functions
    /// of the seed, and the seed is pinned, so asking for the placement again
    /// gives the same answer for ever — there is nothing to store. That is also
    /// what keeps it out of `long_walk`: nobody offered it, so it is not in the
    /// table of things people offered, and there is no row for a withdrawal or a
    /// report to reach. The rule still sees it, because the service hands it to
    /// the rule ahead of the stored arrivals, so everything planted afterwards
    /// is graded against a plant that is standing there.
    public static let ambassador: Planting = Walk.opened().plantings[0]
}

/// The Long Walk's reading of a plant: which tier of a border it belongs in.
///
/// An extension rather than a property of `PlantTraits`, because the reading
/// belongs to the area and not to the plant. The Quiet Garden's `stand` sits
/// beside it in that area's own file, and a third area will add a third.
extension PlantTraits {
    public var tier: LongWalk.Tier { LongWalk.tier(height: height) }
}
