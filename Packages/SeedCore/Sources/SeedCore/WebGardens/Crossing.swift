#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

/// The Crossing: four paths meeting at a centre, four quarters planted round it,
/// and a round paving where they cross. `docs/WEB-GARDENS.md`.
///
/// **The third area, and the first whose rule is about keeping four things
/// level.** The Long Walk asks how to fill a border well and the Quiet Garden
/// asks how few a plot can hold; this one asks that an arriving plant go
/// wherever there is least, so that four quarters grow together. The
/// quadripartite plan is one of the oldest there is for a meeting place, and it
/// only reads as one while all four ways look equally used.
///
/// **Twenty-four plants in a 5.2 m plot**: four quarters of six, between the
/// walk's forty-eight in the same square and the room's ten.
///
/// **What a visitor should see**: grass, with two paths mown through it crossing
/// at a round of paving, and in each of the four quarters planting that builds
/// from low along the path edges to a single tall plant at the outer corner.
/// Every quarter faces the middle, because the middle is what the place is.
///
/// **The quarters are grass and not soil**, decided by Marcus on 21 September
/// after looking at both. Bare beds with one plant standing in them read as a
/// plot waiting to be dug; grass left rough between mown paths is a garden
/// either way, whether it holds one plant or twenty-four. It also means the
/// quarters need no edge drawn at all — a mown path's own edge is the only
/// boundary in the place.
///
/// The rule runs in SeedCore so the plot service, the website and the app read
/// one copy. `Server/.api/Crossing.php` is the port, and
/// `tools/reference/check_crossing.php` holds them together.
public enum Crossing {

    // MARK: The plot

    /// A web plot's side, the same square every area uses.
    public static let plotSide = 5.2

    /// **How this area's plots vary**, from each plot's number (`PlotVariant`,
    /// Marcus's decision of 2 October 2026). Turned and mirrored: a mirror sets
    /// the four ways turning in the other way. Declared but not yet read: the
    /// area's new layout reads it.
    public static let variants = PlotVariant.Space(turns: 4, mirror: true)

    /// Half the width of a path, so the two paths are 1.2 m across. The Long
    /// Walk's figure: it is the same mown path, and a second number would only
    /// be a second thing to keep in step.
    public static let pathHalfWidth = 0.6

    /// The radius of the paving where the paths cross.
    ///
    /// **Wider than the paths that run into it**, by a quarter of a metre on
    /// each side, which is what makes a crossing read as a place rather than as
    /// a junction. A roundel flush with the path's own width is just a wider bit
    /// of path — and one much wider than this, which is where it started, is a
    /// dish sitting in a garden rather than somewhere the paths arrive.
    public static let roundelRadius = 0.85

    // MARK: The four quarters

    /// The quarters, going round. Nothing distinguishes them: they are the same
    /// bed four times, and the rule's whole business is keeping them level.
    ///
    /// The turn of a plot — which quarter faces the visitor when they come down
    /// onto it — is dressing and is chosen per plot, so nothing here decides
    /// which quarter anybody sees first.
    public enum Quarter: Int, Codable, CaseIterable, Sendable {
        case first = 0, second, third, fourth

        /// Which way this quarter lies from the middle: ±1 on each axis.
        public var lie: (x: Double, z: Double) {
            switch self {
            case .first:  return (1, 1)
            case .second: return (-1, 1)
            case .third:  return (-1, -1)
            case .fourth: return (1, -1)
            }
        }
    }

    // MARK: What the rule reads off a plant

    /// Where in a quarter a plant belongs, reading outward from the crossing:
    /// the three along the path edges, the two behind them, or the one at the
    /// outer corner.
    ///
    /// `Rank` is the Crossing's reading of a height, as `LongWalk.Tier` and
    /// `QuietGarden.Stand` are their areas'. The raw values run outward from
    /// the middle, which is also the order nothing may stand in front of
    /// something shorter — see `inOrder`.
    public enum Rank: Int, Codable, CaseIterable, Sendable {
        case path = 0, middle, corner
    }

    /// **The cuts, measured then set to fit the slots.** Across three hundred
    /// crossings of three hundred different pairs of parents, grown heights run
    /// 0.15 m to 2.31 m. A quarter is three at the path, two behind and one at
    /// the corner, so the cuts belong at the 50th and 83rd centiles, which
    /// measured 0.910 m and 1.303 m. Set at 0.91 and 1.30. They were 0.97 and
    /// 1.43 until the plants' shapes changed on 24 September 2026, and were
    /// measured again then on the Long Walk's three hundred.
    ///
    /// **0.85 and 1.34 since 29 September 2026**: the 50th and 83rd centiles
    /// of three thousand crossings after the re-roll of the 28th are 0.852 m
    /// and 1.336 m. The same three thousand as the Long Walk's cuts.
    ///
    /// They are not the walk's 0.77 and 1.20, and not the room's 1.09, and none
    /// of those is wrong: a border of 5:4:3 rows, a group of one back and two
    /// arms, and a bed of 3:2:1 divide the same population three different ways.
    /// The same plant is the middle of a border on the walk, the back of a group
    /// in the room, and one of the three at a path edge here.
    public static let middleFrom = 0.85
    public static let cornerFrom = 1.34

    public static func rank(height: Double) -> Rank {
        if height < middleFrom { return .path }
        if height < cornerFrom { return .middle }
        return .corner
    }

    // MARK: Slots

    /// One place in one plot: which quarter, and where in that quarter's bed.
    public struct Slot: Codable, Equatable, Hashable, Sendable {
        public var quarter: Quarter
        /// 0, 1 and 2 are the three along the path edges, 0 being the one on the
        /// quarter's own diagonal, squarely facing the roundel. 3 and 4 stand
        /// behind them, 5 at the outer corner.
        public var index: Int

        public init(quarter: Quarter, index: Int) {
            self.quarter = quarter
            self.index = index
        }

        public var rank: Rank {
            if index < 3 { return .path }
            return index < 5 ? .middle : .corner
        }

        /// Where the slot is, in metres from the middle of its plot.
        ///
        /// **Written out rather than computed from an angle**, for the reason
        /// `Organic.quarter` exists: a sine taken from a host's own library is
        /// not the same number on every host, and a placement has to be the same
        /// number in Swift and in PHP for ever. These are three arcs at 1.90,
        /// 2.42 and 2.95 m from the middle, rounded where they were written
        /// down, and the arcs are what keeps the rule from having to say which
        /// of three plants at the same rank stands in front of which.
        public var spot: Spot {
            let lie = quarter.lie
            let (x, z) = Slot.canonical[index]
            return Spot(x: lie.x * x, z: lie.z * z)
        }

        /// The six places in a quarter, in the quarter where both axes are
        /// positive. Every other quarter is this one with a sign flipped.
        static let canonical: [(Double, Double)] = [
            (1.34, 1.34),   // 0  the path rank, on the quarter's own diagonal
            (0.92, 1.66),   // 1  the path rank, along one path edge
            (1.66, 0.92),   // 2  the path rank, along the other
            (1.39, 1.98),   // 3  behind 1
            (1.98, 1.39),   // 4  behind 2
            (2.09, 2.09),   // 5  the corner, behind 0
        ]
    }

    /// Every slot in one plot, quarter by quarter and outward within each.
    ///
    /// **Slot 0 of quarter 0 is where a plot starts**, so a plot's oldest plant
    /// stands on its own quarter's diagonal looking straight down it at the
    /// paving — which is the same answer the other two areas gave to *where does
    /// the first one stand*: where a visitor arriving meets it.
    public static let slots: [Slot] = Quarter.allCases.flatMap { quarter in
        (0..<6).map { Slot(quarter: quarter, index: $0) }
    }

    /// The first slot of a rank, used to open a quarter nobody has planted.
    static func firstSlot(of rank: Rank, in quarter: Quarter) -> Slot {
        Slot(quarter: quarter, index: rank == .path ? 0 : (rank == .middle ? 3 : 5))
    }

    // MARK: Planting

    /// One plant at the Crossing, placed for good.
    public struct Planting: Codable, Equatable, Sendable {
        public var seed: String
        public var plot: Int
        public var slot: Slot
        public var traits: PlantTraits
        /// A small offset from the slot, from the seed. Smaller than the room's
        /// 0.13, because a bed of six has neighbours 0.53 m apart at the closest
        /// and a nudge that ate half of that would have plants touching.
        public var nudge: Spot

        public var spot: Spot {
            Spot(x: slot.spot.x + nudge.x, z: slot.spot.z + nudge.z)
        }
    }

    /// The whole area: every planting, in the order they arrived. Append-only,
    /// as both the others are — a place somebody visited yesterday is the same
    /// place today.
    public struct Ways: Codable, Equatable, Sendable {
        public private(set) var plantings: [Planting] = []

        public init() {}

        /// **The Crossing as it opened**: the meeting ambassador in the first
        /// quarter and nothing else. `Crossing.ambassador` is the planting.
        public static func opened() -> Ways {
            var ways = Ways()
            let one = Ambassadors.of(.meeting)
            ways.plant(seed: one.seed, traits: LongWalk.traits(of: one.genome))
            return ways
        }

        public var plots: Int { (plantings.map(\.plot).max() ?? -1) + 1 }

        public func plot(_ index: Int) -> [Planting] {
            plantings.filter { $0.plot == index }
        }

        /// Where the next plant with these traits would go, without planting it.
        ///
        /// **The quarter with the fewest in it, every time.** That is the whole
        /// rule and it is the one Marcus chose on 21 September: a quadripartite
        /// garden reads as four ways arriving at one place only while the four
        /// look equally used, so an arrival goes where there is least. Ties go
        /// to the lowest-numbered quarter, which is what makes it a rule rather
        /// than a preference and lets the PHP reproduce it exactly.
        ///
        /// In order:
        ///
        /// 1. **A slot of the plant's own rank**, in the emptiest quarter of the
        ///    oldest plot that has one.
        /// 2. **A slot of the rank beside its own** — the same shape as the
        ///    walk's *the tier beside its own* — as long as nothing ends up
        ///    standing in front of something shorter than itself.
        /// 3. A new plot, opened by this plant standing in its own rank in the
        ///    first quarter.
        public func place(for traits: PlantTraits) -> (plot: Int, slot: Slot) {
            for rank in Crossing.ranks(beside: rank(height: traits.height)) {
                for plot in 0..<plots {
                    if let slot = slot(in: plot, for: traits, rank: rank) {
                        return (plot, slot)
                    }
                }
            }
            return (plots, firstSlot(of: rank(height: traits.height), in: .first))
        }

        /// The emptiest quarter of this plot with a free slot of `rank` that
        /// this plant may stand in.
        func slot(in plot: Int, for traits: PlantTraits, rank: Rank) -> Slot? {
            let here = self.plot(plot)
            let taken = Set(here.map(\.slot))
            var best: Slot?
            var fewest = Int.max
            for quarter in Quarter.allCases {
                let bed = here.filter { $0.slot.quarter == quarter }
                guard bed.count < fewest else { continue }
                let open = Crossing.slots.first {
                    $0.quarter == quarter && $0.rank == rank && !taken.contains($0)
                        && inOrder(traits.height, at: $0, among: bed)
                }
                if let open {
                    best = open
                    fewest = bed.count
                }
            }
            return best
        }

        /// Whether a plant this tall can stand in this slot: reading outward
        /// from the crossing, nothing stands in front of something shorter than
        /// itself.
        ///
        /// It is the Long Walk's rule about a border and the Quiet Garden's
        /// about a group of three, asked of a bed that is looked at from one
        /// corner of itself. Ranks are compared, not distances, so the three
        /// plants sharing the path rank's arc are free of each other — which is
        /// why they were put on an arc.
        func inOrder(_ height: Double, at slot: Slot, among bed: [Planting]) -> Bool {
            for other in bed {
                if slot.rank.rawValue < other.slot.rank.rawValue, height > other.traits.height {
                    return false
                }
                if slot.rank.rawValue > other.slot.rank.rawValue, height < other.traits.height {
                    return false
                }
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
            let planting = Planting(seed: seed.hex, plot: plot, slot: slot, traits: traits,
                                    nudge: Spot(x: jitter(22, 0.11), z: jitter(23, 0.11)))
            plantings.append(planting)
            return planting
        }
    }

    /// The ranks to try, in order: a plant's own, then the one or two beside it.
    ///
    /// A plant that cannot have its own rank is better one step out of place
    /// than in a plot of its own, which is the finding the Long Walk's suite
    /// made when eleven plots of fifteen were holding six to nine of
    /// forty-eight. `inOrder` is what keeps one step from becoming a mess.
    static func ranks(beside rank: Rank) -> [Rank] {
        switch rank {
        case .path:   return [.path, .middle]
        case .middle: return [.middle, .path, .corner]
        case .corner: return [.corner, .middle]
        }
    }

    // MARK: The ambassador

    /// **The first plant in the first quarter of the first plot.**
    ///
    /// *Ithula obscura* — `Ambassadors.of(.meeting)` since the re-roll of 28
    /// September 2026 — placed by this rule into an empty Crossing, which puts
    /// it in the middle rank because that is what its height, 1.20 m, reads
    /// as, and in slot 3 because that is where a quarter's middle rank starts:
    /// behind slot 1, along the path edge. The diagonal in front of it waits
    /// for the first arrival short enough for the path rank.
    ///
    /// *Melyrina latifolia*, its ambassador until then, was a path-rank plant
    /// and stood in slot 0, looking straight down its quarter's diagonal at the
    /// paving. **It was 0.61 m, and the template was written knowing that.** The finding
    /// from the walk on 20 September is that whatever slot an area's first
    /// arrival takes has to be one the area's own ambassador can stand in, and
    /// nine of the ten ambassadors are short. A centre holding a specimen would
    /// have failed that test here, which is one of the reasons the paving holds
    /// no plant.
    ///
    /// Derived rather than stored, as the other two are: the slot and the nudge
    /// are pure functions of the pinned seed, so there is no row for a
    /// withdrawal, a report or a backup to reach.
    public static let ambassador: Planting = Ways.opened().plantings[0]
}

/// The Crossing's reading of a plant: which of the three ranks of a quarter it
/// belongs in, counting outward from the paving.
extension PlantTraits {
    public var rank: Crossing.Rank { Crossing.rank(height: height) }
}
