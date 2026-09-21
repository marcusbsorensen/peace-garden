#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

/// The Orchard: five trees standing in a quincunx, and a guild of four planted
/// under each. `docs/WEB-GARDENS.md`.
///
/// **The fourth area, and the first where a plant stands under another thing
/// that is taller than anything a gardener can grow.** The Long Walk asks how to
/// fill a border well, the Quiet Garden how few a plot can hold, the Crossing
/// that four beds be kept level with each other. This one asks the opposite of
/// the Crossing: that a guild be *finished* before the next is begun, so a tree
/// is either dressed or bare and never one of five half-plantings.
///
/// **That unevenness is the point.** Building a fourth area that shared out its
/// arrivals as the third does would repeat an argument already won. A young
/// orchard has established trees and bare ones in the same row, and the template
/// is only worth having if it survives a rule that deliberately leaves some of
/// the plot empty while filling the rest.
///
/// **Twenty plants in a 5.2 m plot**: five guilds of four. Between the Crossing's
/// twenty-four and the Quiet Garden's ten, in the same square as both.
///
/// **The five trees belong to the garden, not to a gardener.** They are
/// structures, like the Long Walk's hedges, the Quiet Garden's bench and the
/// Crossing's paving: `Organic.tree` draws them, they stand in every plot from
/// the day it opens, and they are a row in no table. The alternative — the
/// tallest arrivals becoming the trees — leaves a new plot with five empty tree
/// slots and guild places that mean nothing until a tall plant happens along,
/// and hands the first gardener to the Orchard a tree while the second gets
/// shade. What it costs is that this is the first area where a gardener's plant
/// cannot be the tallest thing in the plot. The Quiet Garden's bench is the
/// precedent that says an area may hold something nobody planted.
///
/// The rule runs in SeedCore so the plot service, the website and the app read
/// one copy. `Server/.api/Orchard.php` is the port, and
/// `tools/reference/check_orchard.php` holds them together.
public enum Orchard {

    // MARK: The plot

    /// A web plot's side, the same square every area uses.
    public static let plotSide = 5.2

    /// How far out the four outer trees stand, on each axis, from the middle of
    /// the plot. The fifth is at the middle itself.
    ///
    /// **It is set by the one spacing that could go wrong.** The middle tree's
    /// guild and an outer tree's guild lean toward each other, and at the first
    /// spacing tried — trees 1.45 m out with guilds 0.88 m round them — the two
    /// nearest plants of those two guilds stood 0.30 m apart, which is two plants
    /// in one place. Pushing the trees out and drawing the guilds in leaves that
    /// closest pair 0.90 m apart, which is wider than the Crossing's closest
    /// neighbours at 0.53 m and the reason this area's nudge can be the Quiet
    /// Garden's 0.13 rather than the Crossing's 0.11.
    public static let treeFrom = 1.70

    /// How far a guild's four places stand from their trunk.
    ///
    /// **Inside the canopy rather than at its edge.** `Organic.tree` spreads
    /// 1.7 m, so a guild at 0.75 m is under the branches, which is what makes it
    /// a guild rather than four plants arranged round a tree.
    public static let guildRadius = 0.75

    // MARK: The five guilds

    /// The five trees, in the order their guilds fill.
    ///
    /// **The middle first, then the four outer ones going round.** The middle is
    /// where a plot opens for a reason given under `Slot.rank`: it is the one
    /// guild that can take any plant at all, so it is the right one to hand the
    /// first four arrivals, whatever heights they happen to be.
    public enum Guild: Int, Codable, CaseIterable, Sendable {
        case middle = 0, first, second, third, fourth

        /// Which way this guild lies from the middle of the plot: ±1 on each
        /// axis. The middle's own is (1, 1), which points nowhere in particular
        /// and is never read as a direction — its four places are equidistant
        /// from the plot's centre whatever sign is applied.
        public var lie: (x: Double, z: Double) {
            switch self {
            case .middle: return (1, 1)
            case .first:  return (1, 1)
            case .second: return (-1, 1)
            case .third:  return (-1, -1)
            case .fourth: return (1, -1)
            }
        }

        /// Where this guild's trunk stands, in metres from the middle of the
        /// plot.
        public var trunk: Spot {
            if self == .middle { return Spot(x: 0, z: 0) }
            let lie = self.lie
            return Spot(x: lie.x * Orchard.treeFrom, z: lie.z * Orchard.treeFrom)
        }
    }

    // MARK: What the rule reads off a plant

    /// Where in an outer guild a plant belongs, reading outward from the middle
    /// of the plot: the one nearest the middle, the two to either side of the
    /// trunk, or the one furthest out.
    ///
    /// `Rank` is the Orchard's reading of a height, as `LongWalk.Tier`,
    /// `QuietGarden.Stand` and `Crossing.Rank` are their areas'. The raw values
    /// run outward, which is also the order nothing may stand in front of
    /// something shorter — see `inOrder`.
    public enum Rank: Int, Codable, CaseIterable, Sendable {
        case understorey = 0, flank, crown
    }

    /// **The cuts, measured then set to fit the places.** Across three hundred
    /// crossings of three hundred different pairs of parents, grown heights ran
    /// 0.38 m to 2.20 m. An outer guild is one nearest the middle, two at the
    /// flanks and one furthest out, so the cuts belong at the 25th and 75th
    /// centiles, which measured 0.752 m and 1.295 m. Set at 0.75 and 1.30.
    ///
    /// The middle guild is not in this count, and does not need to be: it takes
    /// any plant, so the sixteen places the cuts are for are handed a fair sample
    /// of everything that arrives.
    ///
    /// They are not the walk's 0.93 and 1.28, not the room's 1.13 and not the
    /// crossing's 0.97 and 1.43, and none of those is wrong. A border of 5:4:3
    /// rows, a group of one back and two arms, a bed of 3:2:1 and a guild of
    /// 1:2:1 divide the same population four different ways.
    public static let flankFrom = 0.75
    public static let crownFrom = 1.30

    public static func rank(height: Double) -> Rank {
        if height < flankFrom { return .understorey }
        if height < crownFrom { return .flank }
        return .crown
    }

    // MARK: Slots

    /// One place in one plot: which guild, and where under that guild's tree.
    public struct Slot: Codable, Equatable, Hashable, Sendable {
        public var guild: Guild
        /// 0 is the place nearest the middle of the plot, 1 and 2 are the two
        /// beside the trunk, 3 is the one furthest out.
        public var index: Int

        public init(guild: Guild, index: Int) {
            self.guild = guild
            self.index = index
        }

        /// **The middle guild's four places have no rank, and that is not a
        /// special case bolted on — it is what a quincunx's middle is.**
        ///
        /// Every rule in this garden orders plants outward from the middle of
        /// the plot, so that nothing stands in front of something shorter than
        /// itself. The four places under the middle tree are all the same
        /// distance from that middle: there is no in-front of and no behind
        /// among them, because the middle tree is the one you can walk all the
        /// way round. So they are free of each other and free of any height,
        /// exactly as the Crossing's three plants sharing the path arc are free
        /// of each other — the same principle, applied to a whole guild.
        ///
        /// It is also what makes *fill one guild, then the next* work at all.
        /// The first four arrivals to a plot go under the middle tree whatever
        /// they are, so a plot never opens by turning somebody away.
        public var rank: Rank? {
            if guild == .middle { return nil }
            if index == 0 { return .understorey }
            return index < 3 ? .flank : .crown
        }

        /// Whether a plant of this rank may take this place.
        public func accepts(_ rank: Rank) -> Bool {
            self.rank == nil || self.rank == rank
        }

        /// Where the place is, in metres from the middle of its plot.
        ///
        /// **Written out rather than computed from an angle**, for the reason
        /// `Organic.quarter` exists: a sine taken from a host's own library is
        /// not the same number on every host, and a placement has to be the same
        /// number in Swift and in PHP for ever. The four sit on the guild's own
        /// diagonals rather than at its compass points, which is what puts one
        /// of them squarely nearest the middle, one squarely furthest out, and
        /// the other two at the same distance as each other — and two places at
        /// one distance is what frees them from having to be in order.
        public var spot: Spot {
            let lie = guild.lie
            let trunk = guild.trunk
            let (x, z) = Slot.canonical[index]
            return Spot(x: trunk.x + lie.x * x, z: trunk.z + lie.z * z)
        }

        /// The four places under a tree, in the guild where both axes point
        /// away from the middle. Every other guild is this one with a sign
        /// flipped. 0.53 is `guildRadius` on the diagonal.
        static let canonical: [(Double, Double)] = [
            (-0.53, -0.53),   // 0  nearest the middle of the plot
            (0.53, -0.53),    // 1  beside the trunk
            (-0.53, 0.53),    // 2  beside the trunk, the same distance out as 1
            (0.53, 0.53),     // 3  furthest out
        ]
    }

    /// Every place in one plot, guild by guild and outward within each.
    public static let slots: [Slot] = Guild.allCases.flatMap { guild in
        (0..<4).map { Slot(guild: guild, index: $0) }
    }

    // MARK: Planting

    /// One plant in the Orchard, placed for good.
    public struct Planting: Codable, Equatable, Sendable {
        public var seed: String
        public var plot: Int
        public var slot: Slot
        public var traits: PlantTraits
        /// A small offset from the place, from the seed. The Quiet Garden's
        /// 0.13 rather than the Crossing's 0.11: the closest two plants in a
        /// full plot here stand 0.90 m apart, where the Crossing's stand 0.53 m
        /// apart, so there is room for it.
        public var nudge: Spot

        public var spot: Spot {
            Spot(x: slot.spot.x + nudge.x, z: slot.spot.z + nudge.z)
        }
    }

    /// The whole area: every planting, in the order they arrived. Append-only,
    /// as all three of the others are — a place somebody visited yesterday is
    /// the same place today.
    public struct Ways: Codable, Equatable, Sendable {
        public private(set) var plantings: [Planting] = []

        public init() {}

        /// **The Orchard as it opened**: the kinship ambassador under the middle
        /// tree and nothing else. `Orchard.ambassador` is the planting.
        public static func opened() -> Ways {
            var ways = Ways()
            let one = Ambassadors.of(.kinship)
            ways.plant(seed: one.seed, traits: LongWalk.traits(of: one.genome))
            return ways
        }

        public var plots: Int { (plantings.map(\.plot).max() ?? -1) + 1 }

        public func plot(_ index: Int) -> [Planting] {
            plantings.filter { $0.plot == index }
        }

        /// Where the next plant with these traits would go, without planting it.
        ///
        /// **One guild is finished before the next is begun.** That is the whole
        /// rule and it is the one Marcus chose on 21 September. It is the
        /// Crossing's loops turned inside out: the Crossing looks for a plant's
        /// own rank across every quarter before it will accept a neighbouring
        /// rank, because its business is keeping four beds level. This one looks
        /// through every rank of the earliest unfinished guild before it will
        /// move to the next guild, because its business is finishing one tree
        /// before starting another.
        ///
        /// In order:
        ///
        /// 1. **The earliest guild of the oldest plot with a place free**, taking
        ///    the plant's own rank there if it can, and otherwise a rank beside
        ///    its own — as long as nothing ends up standing in front of
        ///    something shorter than itself.
        /// 2. The next guild along, and then the next plot.
        /// 3. A new plot, opened under its middle tree.
        public func place(for traits: PlantTraits) -> (plot: Int, slot: Slot) {
            let own = Orchard.rank(height: traits.height)
            for plot in 0..<plots {
                for guild in Guild.allCases {
                    for rank in Orchard.ranks(beside: own) {
                        if let slot = slot(in: plot, guild: guild, for: traits, rank: rank) {
                            return (plot, slot)
                        }
                    }
                }
            }
            return (plots, Slot(guild: .middle, index: 0))
        }

        /// A free place under this guild's tree that a plant of this rank and
        /// this height may stand in.
        func slot(in plot: Int, guild: Guild, for traits: PlantTraits, rank: Rank) -> Slot? {
            let here = self.plot(plot)
            let taken = Set(here.map(\.slot))
            let under = here.filter { $0.slot.guild == guild }
            return Orchard.slots.first {
                $0.guild == guild && $0.accepts(rank) && !taken.contains($0)
                    && inOrder(traits.height, at: $0, among: under)
            }
        }

        /// Whether a plant this tall can stand in this place: reading outward
        /// from the middle of the plot, nothing stands in front of something
        /// shorter than itself.
        ///
        /// It is the Long Walk's rule about a border, the Quiet Garden's about a
        /// group of three and the Crossing's about a quarter, asked of a ring of
        /// four round a trunk. Ranks are compared, not distances, so the two
        /// plants flanking a trunk are free of each other — which is why they
        /// were put at the same distance out. A place with no rank at all, which
        /// is every place under the middle tree, is free of everything.
        func inOrder(_ height: Double, at slot: Slot, among under: [Planting]) -> Bool {
            guard let mine = slot.rank else { return true }
            for other in under {
                guard let theirs = other.slot.rank else { continue }
                if mine.rawValue < theirs.rawValue, height > other.traits.height {
                    return false
                }
                if mine.rawValue > theirs.rawValue, height < other.traits.height {
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
                                    nudge: Spot(x: jitter(24, 0.13), z: jitter(25, 0.13)))
            plantings.append(planting)
            return planting
        }
    }

    /// The ranks to try, in order: a plant's own, then the one or two beside it.
    ///
    /// The same shape as the Crossing's and the Long Walk's, and for the same
    /// finding: a plant that cannot have its own rank is better one step out of
    /// place than in a plot of its own. `inOrder` is what keeps one step from
    /// becoming a mess.
    static func ranks(beside rank: Rank) -> [Rank] {
        switch rank {
        case .understorey: return [.understorey, .flank]
        case .flank:       return [.flank, .understorey, .crown]
        case .crown:       return [.crown, .flank]
        }
    }

    // MARK: The ambassador

    /// **The plant under the middle tree of the first plot.**
    ///
    /// *Cyninora contorta* — `Ambassadors.of(.kinship)` — placed by this rule
    /// into an empty Orchard, which puts it under the middle tree in the place
    /// nearest the plot's own middle, because that is where a plot opens.
    ///
    /// **It is 1.33 m, the tallest of the ten ambassadors, and that decided
    /// something.** The finding from the walk on 20 September is that whatever
    /// place an area's first arrival takes has to be one the area's own
    /// ambassador can stand in. Here it is the one plant of the ten that would
    /// read as a crown rather than an understorey, and an opening place with a
    /// rank on it would have put the Orchard's ambassador at the back of a guild
    /// with a tree between it and the visitor. The middle guild taking any plant
    /// at all is what makes that a non-question — and it is a property of a
    /// quincunx rather than an accommodation, which is the only reason it is
    /// allowed to be the answer.
    ///
    /// Derived rather than stored, as the other three are: the place and the
    /// nudge are pure functions of the pinned seed, so there is no row for a
    /// withdrawal, a report or a backup to reach.
    public static let ambassador: Planting = Ways.opened().plantings[0]
}

/// The Orchard's reading of a plant: which of the three ranks of a guild it
/// belongs in, counting outward from the middle of the plot.
extension PlantTraits {
    public var guildRank: Orchard.Rank { Orchard.rank(height: height) }
}
