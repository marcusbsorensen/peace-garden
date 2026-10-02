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
/// **A meadow orchard since 2 October 2026** (Marcus's choice,
/// `design/garden-layouts-2026-10-02/RESEARCH.md` §*The Orchard*, option A):
/// each outer guild a crescent at its tree's drip line turned toward the
/// middle tree, the middle tree's four in a ring, the outer trees nudged off
/// the quincunx, one mown way through the long grass, and every plot turned,
/// mirrored and nudged by its number (`variants`). The rule did not change;
/// where its places stand did (`table`).
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

    /// **How this area's plots vary**, from each plot's number (`PlotVariant`,
    /// Marcus's decision of 2 October 2026): turned four ways, mirrored, and
    /// one of the meadow's three feature variants, each with its outer trees
    /// nudged its own way and its mown way bent its own way. Twenty-four in
    /// all, so a block of twenty-four plots holds every one.
    public static let variants = PlotVariant.Space(turns: 4, mirror: true, nudges: PlaceTable.orchardMeadow.nudges)

    /// **Where everything in a plot stands, worked out offline**: the meadow
    /// orchard Marcus chose on 2 October 2026
    /// (`design/garden-layouts-2026-10-02/RESEARCH.md` §*The Orchard*, option
    /// A), written into SeedCore by `tools/layouts/generate.py` from
    /// `tools/layouts/tables/orchard_meadow.py`. Its places are this file's
    /// slots, guild by guild and index by index; its curves are the five
    /// trunks, the mown way, the pond and each crescent's mown arc.
    public static let table = PlaceTable.orchardMeadow

    /// How far out the four outer trees stand, on each axis, from the middle of
    /// the plot, before each is nudged by up to 0.08 m: **old orchards are never
    /// true**. The fifth is at the middle itself and is never nudged. The
    /// table's number, written here for the page and the tests.
    ///
    /// It is set by the one spacing that could go wrong, as it always was: the
    /// middle tree's four and the near end of each crescent lean toward each
    /// other, and at 1.74 m out, whatever the nudge, they stand 0.80 m apart
    /// and more. (1.70 m until 2 October 2026, when a guild was a square of
    /// four round its trunk and the closest two guilds stood 0.90 m apart.)
    public static let treeFrom = 1.74

    /// How far an outer guild's four places stand from their trunk: **at the
    /// drip line**, a crescent just past the canopy's edge (`Organic.tree`
    /// spreads up to 1.62 m). Until 2 October 2026 a guild stood 0.75 m from
    /// its trunk on the trunk's four diagonals, a square round the tree.
    public static let guildRadius = 0.90

    /// How far the middle tree's four stand from it: on the diagonals, each
    /// facing a crescent, under the canopy's edge — the old guild's 0.75 m,
    /// and for the old reason: nearer the trunk the canopy's underside comes
    /// down to 2.23 m, under the tallest plant the garden grows.
    public static let middleRadius = 0.75

    /// The variant a plot is laid in: `PlotVariant.of(plot:area:)` for the
    /// Orchard. Plot 0 is the table as drawn.
    public static func variant(ofPlot plot: Int) -> PlotVariant {
        PlotVariant.of(plot: plot, area: .kinship)
    }

    /// The five trunks of a plot laid as `variant`: the middle first, then the
    /// four outer ones in the order their guilds fill.
    public static func trunks(on variant: PlotVariant) -> [Spot] {
        table.curve("trunks", on: variant).points
    }

    /// The mown way's centre line on a plot laid as `variant`: in at one edge,
    /// past the middle tree inside its mown disc, out at the other, and running
    /// on past the rim at both ends so the drawing cuts it where the plot's own
    /// edge is.
    public static func way(on variant: PlotVariant) -> [Spot] {
        table.curve("way", on: variant).points
    }

    /// Where the dipping pond lies on a plot laid as `variant`: in one of the
    /// two pockets the crowns frame, clear of every place by 0.80 m.
    public static func pond(on variant: PlotVariant) -> Spot {
        table.curve("pond", on: variant).points[0]
    }

    /// An outer guild's mown arc on a plot laid as `variant`: the line its
    /// crescent is mown along, a little longer than its four places.
    public static func crescent(_ guild: Guild, on variant: PlotVariant) -> [Spot] {
        precondition(guild != .middle, "the middle tree has a disc, not a crescent")
        return table.curve("crescent\(guild.rawValue)", on: variant).points
    }

    // MARK: The five guilds

    /// The five trees, in the order their guilds fill.
    ///
    /// **The middle first**, for a reason given under `Slot.rank`: it is the
    /// one guild that can take any plant at all, so it is the right one to hand
    /// the first four arrivals, whatever heights they happen to be. **Then the
    /// four outer ones farthest-first** (Marcus, 2 October 2026: every count
    /// looks finished): in the table as drawn, the far corner (`x−`, `z−`),
    /// whose crescent faces the eye before a turn, then the near corner
    /// opposite it, then the two at the sides. Until 2 October 2026 they went
    /// round the plot, so a plot of twelve was dressed on one side.
    public enum Guild: Int, Codable, CaseIterable, Sendable {
        case middle = 0, first, second, third, fourth

        /// Where this guild's trunk stands on a plot laid as `variant`, in
        /// metres from the middle of the plot.
        public func trunk(on variant: PlotVariant) -> Spot {
            Orchard.trunks(on: variant)[rawValue]
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
    /// 0.15 m to 2.31 m. An outer guild is one nearest the middle, two at the
    /// flanks and one furthest out, so the cuts belong at the 25th and 75th
    /// centiles, which measured 0.583 m and 1.202 m. Set at 0.58 and 1.20. They
    /// were 0.75 and 1.30 until the plants' shapes changed on 24 September
    /// 2026, and were measured again then on the Long Walk's three hundred.
    ///
    /// **0.48 and 1.18 since 29 September 2026**: the 25th and 75th centiles
    /// of three thousand crossings after the re-roll of the 28th are 0.476 m
    /// and 1.183 m. The same three thousand as the Long Walk's cuts; the Knot
    /// Garden, which shares these, had its own five hundred ranked 164/234/102
    /// at the old ones against about 1:2:1, and 142/250/108 at these.
    ///
    /// The middle guild is not in this count, and does not need to be: it takes
    /// any plant, so the sixteen places the cuts are for are handed a fair sample
    /// of everything that arrives.
    ///
    /// They are not the room's 1.09 and not the crossing's 0.91 and 1.30, and
    /// none of those is wrong. A border of 5:4:3 rows, a group of one back and
    /// two arms, a bed of 3:2:1 and a guild of 1:2:1 divide the same population
    /// four different ways. **The crown's is the walk's back cut, 1.20**,
    /// because both are the tallest quarter: three back slots of twelve and
    /// one place of four. Measured on one sample, one centile is one number;
    /// the two were 1.28 and 1.30 only because each area had drawn its own.
    public static let flankFrom = 0.48
    public static let crownFrom = 1.18

    public static func rank(height: Double) -> Rank {
        if height < flankFrom { return .understorey }
        if height < crownFrom { return .flank }
        return .crown
    }

    // MARK: Slots

    /// One place in one plot: which guild, and where under that guild's tree.
    public struct Slot: Codable, Equatable, Hashable, Sendable {
        public var guild: Guild
        /// In an outer guild 0 is the understorey, on the line from the trunk
        /// to the middle tree and so nearest the middle of the plot; 1 and 2 are
        /// the flanks either side of it, at one distance from the middle; 3 is
        /// the crown at the crescent's far horn, furthest out. Under the middle
        /// tree the four are its fill order.
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

        /// Where the place is in the table's frame for feature variant
        /// `nudge`, before the plot is turned or mirrored.
        ///
        /// **A literal, not an angle**, for the reason `Organic.quarter` exists:
        /// a sine taken from a host's own library is not the same number on
        /// every host, and a placement has to be the same number in Swift and
        /// in PHP for ever. The crescents were drawn with angles once, offline,
        /// and written down to the millimetre (`PlaceTable`).
        public func place(nudge: Int) -> Spot {
            Orchard.table.places(nudge: nudge)[Orchard.tableIndex[self]!].spot
        }

        /// Where the place is on a plot laid as `variant`, in metres from the
        /// middle of the plot. Exact on every host.
        public func spot(on variant: PlotVariant) -> Spot {
            variant.apply(place(nudge: variant.nudge))
        }
    }

    /// Every place in one plot, guild by guild and outward within each — the
    /// order the rule scans a guild in, and the order the table lists them.
    public static let slots: [Slot] = Guild.allCases.flatMap { guild in
        (0..<4).map { Slot(guild: guild, index: $0) }
    }

    /// Which of the table's places each slot is, read off the table's tags.
    static let tableIndex: [Slot: Int] = {
        var out: [Slot: Int] = [:]
        for (i, place) in table.places(nudge: 0).enumerated() {
            let guild = Guild(rawValue: table.tag("guild", of: place))!
            out[Slot(guild: guild, index: table.tag("index", of: place))] = i
        }
        return out
    }()

    // MARK: Planting

    /// One plant in the Orchard, placed for good.
    public struct Planting: Codable, Equatable, Sendable {
        public var seed: String
        public var plot: Int
        public var slot: Slot
        public var traits: PlantTraits
        /// A small offset from the place, from the seed: 0.13 m either way.
        /// Neighbours in a crescent stand 0.56 m apart, where the Crossing's
        /// closest stand 0.53 m apart with a nudge of 0.11, so two can close
        /// to about what the Crossing's can. (It was the Quiet Garden's 0.13
        /// when the closest two stood 0.90 m apart, and was kept.)
        public var nudge: Spot

        /// Where the plant stands: its place in the table's frame, the nudge
        /// added there, and the sum turned for its plot — so a plot turned or
        /// mirrored is the same plot seen another way round, nudges and all.
        public var spot: Spot {
            let variant = Orchard.variant(ofPlot: plot)
            let place = slot.place(nudge: variant.nudge)
            return variant.apply(Spot(x: place.x + nudge.x, z: place.z + nudge.z))
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
    /// *Vininora contorta* — `Ambassadors.of(.kinship)` — placed by this rule
    /// into an empty Orchard, which puts it under the middle tree in the
    /// ring's first place, facing the first crescent, because that is where a
    /// plot opens.
    ///
    /// **It is 1.93 m, the tallest of the ten ambassadors, and that decided
    /// something.** The finding from the walk on 20 September is that whatever
    /// place an area's first arrival takes has to be one the area's own
    /// ambassador can stand in. Here it is a plant that would read as a crown
    /// rather than an understorey — one of three of the ten since the re-roll
    /// of 28 September 2026; before it this seed grew *Cyninora contorta*, a
    /// thistle of 1.33 m, and it was the only one — and an opening place with a
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
