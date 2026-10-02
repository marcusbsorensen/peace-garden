#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

/// The Knot Garden: a ring of low clipped hedging round the middle and four
/// rings woven through it, over and under in turn, inside a softened square
/// edging, and eight compartments filled with colour. `docs/WEB-GARDENS.md`.
///
/// **The fifth area, and the first whose rule reads a plant's colour.**
/// `PlantTraits` has carried `family` since the Long Walk and no rule has ever
/// looked at it: four areas have graded by height and nothing else. A knot
/// garden cannot. Its compartments are blocks of one colour, and a block of one
/// colour is the only thing that makes an interlaced pattern legible from the
/// side of it — the hedging draws the knot and the planting colours it in.
///
/// **Thirty-two plants in a 5.2 m plot**: eight compartments of four, between
/// the Long Walk's forty-eight in the same square and the Crossing's
/// twenty-four. Four to a compartment because three does not read as a block.
///
/// **The eight are four mirror pairs, and a pair shares a colour family.** That
/// is what symmetry means here: the knot is symmetric in colour, which is what
/// a knot garden looks like from above. So a plot carries four of the seven
/// families, eight places each, and the two compartments of a pair fill
/// together.
///
/// **Nothing is ever reserved.** The literal reading of *a slot has a mirror* —
/// taking a place holds the opposite place open for a matching plant — was
/// rejected, for a reason already written into four areas' comments: nothing in
/// this garden reserves a slot, not even for an ambassador. The Orchard also
/// showed that a merely *constrained* place can wait hundreds of arrivals, and a
/// reserved one would wait on a plant nobody has grown. A pair is claimed by the
/// first plant to stand in it and filled by whoever of that colour arrives next.
///
/// **Interlaced rings since 2 October 2026**, option A of the layouts Marcus
/// approved that day (`design/garden-layouts-2026-10-02/RESEARCH.md`). The
/// rule did not change: the eight compartments are now four lenses and four
/// crescents rather than four sides and four corners, and every slot is the
/// slot it was, so a plant standing in the old knot stands in the same
/// compartment of the new one. Where the places are is a table made offline,
/// `PlaceTable.knotGardenRings`, from `tools/layouts/tables/knot_garden_rings.py`.
///
/// The rule runs in SeedCore so the plot service, the website and the app read
/// one copy. `Server/.api/KnotGarden.php` is the port, and
/// `tools/reference/check_knot.php` holds them together.
public enum KnotGarden {

    // MARK: The plot

    /// A web plot's side, the same square every area uses.
    public static let plotSide = 5.2

    /// **How this area's plots vary**, from each plot's number (`PlotVariant`,
    /// Marcus's decision of 2 October 2026). **Fixed**: a knot is a pattern made
    /// to be the same every time, so every plot is laid as the table draws it.
    public static let variants = PlotVariant.Space.fixed

    /// **The knot, made offline**: where the thirty-two places are, and the
    /// lines of the middle ring, the four small rings, the edging and the eight
    /// crossings. `tools/layouts/tables/knot_garden_rings.py` says how each was laid.
    public static let table = PlaceTable.knotGardenRings

    /// Half the thickness of a run of hedging. The rings and the edging are all
    /// the same band.
    ///
    /// **Thin, because knot hedging is.** The Long Walk's hedge is 0.36 m
    /// through and stands 2.0 m; this is clipped box at ankle height, and a knot
    /// drawn in the walk's hedge would be green walls rather than a pattern. It
    /// is in the rule rather than only in the drawing because a compartment's
    /// edges are where the bands' faces are: the page has to be able to ask,
    /// rather than keep a second copy of the number.
    ///
    /// **0.09, not the 0.11 first tried.** At 0.22 through and 0.32 high the
    /// bands came out as thick as a third of a compartment and the plot read as
    /// nine boxes with walls between them. A knot is drawn in ribbon, and a
    /// ribbon is much thinner than the thing it encloses.
    public static let bandHalfThickness = 0.09

    /// How high the hedging stands: **a little less than it is wide, which was
    /// the second thing the drawing taught.** Thinning the bands and leaving
    /// them 0.32 m tall still drew walls, because what reads as a wall is a run
    /// taller than it is broad. Young clipped box in a knot is a ribbon laid on
    /// the ground — wider than it is high — and it is drawn as one.
    ///
    /// Low also because the pattern is seen from above: hedging tall enough to
    /// hide a compartment hides the knot, which is the whole of what a knot
    /// garden is for.
    public static let bandHeight = 0.17

    /// **Where a band rides over another it swells**, as a clipped hedge does
    /// where two runs have grown into each other: this much thicker each side
    /// and this much taller, over this far along it either way from the
    /// crossing. That lump is what turns a band passing a broken one into a
    /// band passing *over* it. In the rule because it takes room a plant might
    /// otherwise stand in, and `clearance(x:z:)` has to count it.
    public static let swellThicker = 0.0275
    public static let swellTaller = 0.055
    public static let swellReach = 0.29

    /// How far an under-band's cut end hides inside the band that rides over
    /// it, measured from the over-band's face. Enough that no daylight shows at
    /// the joint, little enough that the two ends still read as one band diving
    /// under rather than as a band with a lump in it.
    public static let tuck = 0.04

    /// How far a plant stands off its place, either way on each axis, from the
    /// seed. **The smallest in the garden**: a compartment is meant to read as
    /// a block rather than as four plants that have wandered.
    public static let nudge = 0.09

    // MARK: The knot

    /// **The five rings and the edging, as lines**: the middle ring, the four
    /// small rings in compartment order (north-east, south-east, south-west,
    /// north-west), and the softened square. Each is closed and hand-laid,
    /// straying off its true line by up to a centimetre.
    public static var bands: [PlaceTable.Curve] {
        ["middle", "ring0", "ring1", "ring2", "ring3", "edging"].map {
            table.curve($0, on: .plain)
        }
    }

    /// **The eight crossings**, in order round the middle ring from the
    /// north-east ring's first. **The middle ring rides over at the even ones
    /// and dives under at the odd**, so going round it the band is over, under,
    /// over, under, and each small ring is over at one of its two crossings and
    /// under at the other: that alternation is the difference between a knot
    /// and five rings lying on top of each other.
    public static var crossings: [Spot] {
        table.curve("crossings", on: .plain).points
    }

    /// Which band rides over at the `i`-th crossing: the middle ring at the even
    /// ones, the small ring at the odd. Index into `bands`.
    public static func over(at i: Int) -> Int { i % 2 == 0 ? 0 : 1 + i / 2 }

    /// How far a point on the ground stands from the nearest face of the
    /// nearest band, in metres, the swellings counted. Negative inside a band.
    ///
    /// Measured against the lines as laid rather than solved, because it is
    /// asked by tests rather than by a page drawing a frame.
    public static func clearance(x: Double, z: Double) -> Double {
        let p = Spot(x: x, z: z)
        var nearest = Double.greatestFiniteMagnitude
        for band in bands {
            nearest = min(nearest, distance(p, to: band.points, closed: band.closed) - bandHalfThickness)
        }
        let all = bands
        for (i, crossing) in crossings.enumerated() {
            let swollen = all[over(at: i)].points.filter { distance(crossing, $0) <= swellReach }
            nearest = min(nearest, distance(p, to: swollen, closed: false) - bandHalfThickness - swellThicker)
        }
        return nearest
    }

    static func distance(_ a: Spot, _ b: Spot) -> Double {
        ((a.x - b.x) * (a.x - b.x) + (a.z - b.z) * (a.z - b.z)).squareRoot()
    }

    /// How far a point is from the nearest part of a line through `points`.
    static func distance(_ p: Spot, to points: [Spot], closed: Bool) -> Double {
        guard points.count > 1 else { return points.first.map { distance(p, $0) } ?? .greatestFiniteMagnitude }
        var best = Double.greatestFiniteMagnitude
        let spans = closed ? points.count : points.count - 1
        for i in 0..<spans {
            let a = points[i], b = points[(i + 1) % points.count]
            let ax = b.x - a.x, az = b.z - a.z
            let m = ax * ax + az * az
            let t = m == 0 ? 0 : max(0, min(1, ((p.x - a.x) * ax + (p.z - a.z) * az) / m))
            best = min(best, distance(p, Spot(x: a.x + ax * t, z: a.z + az * t)))
        }
        return best
    }

    // MARK: The eight compartments

    /// The eight compartments: the four lenses where a small ring overlaps the
    /// middle one, then the four crescents of the small rings outside it, each
    /// four going round from the north-east. The basin in the middle and the
    /// gravel round the rings hold no plant.
    ///
    /// **Declared lenses first, then crescents**, so that `rawValue % 4` is the
    /// number of quarter turns from the compartment's north-east one and
    /// `rawValue ^ 2` is its mirror. Both come out of the declaration order
    /// rather than out of a table that could disagree with it. The raw values
    /// are the ones the four sides and four corners had, so a stored
    /// compartment is the same compartment of the new knot.
    public enum Compartment: Int, Codable, CaseIterable, Sendable {
        case northEastLens = 0, southEastLens, southWestLens, northWestLens
        case northEastCrescent, southEastCrescent, southWestCrescent, northWestCrescent

        /// Whether this is one of the outer crescents rather than a lens. The
        /// two kinds are different shapes, so each has its own four places.
        public var isCrescent: Bool { rawValue >= 4 }

        /// Quarter turns from the north-east compartment of its kind.
        var turns: Int { rawValue % 4 }

        /// The compartment opposite this one, which holds the same colour.
        ///
        /// Two quarter turns, which for both kinds is the opposite side of the
        /// plot: the north-east lens against the south-west, the south-east
        /// crescent against the north-west.
        public var mirror: Compartment { Compartment(rawValue: rawValue ^ 2)! }

        /// Which of the four pairs this compartment belongs to.
        public var pair: Pair { Pair(rawValue: rawValue % 2 + (isCrescent ? 2 : 0))! }

        /// Which small ring this compartment is part of: an index into the
        /// rings, `ring0` to `ring3` of the table.
        public var ring: Int { rawValue % 4 }
    }

    /// The four mirror pairs, each named for the lower-numbered of its two
    /// compartments. A pair is what a colour claims.
    ///
    /// **The lenses are claimed first, and they are nearest the basin**: the
    /// first colours in a plot close round the middle as four ribbons, and the
    /// crescents come after, so a plot of ten looks like a knot planted from
    /// its heart rather than half of one.
    public enum Pair: Int, Codable, CaseIterable, Sendable {
        case northEastLenses = 0, southEastLenses, northEastCrescents, southEastCrescents

        /// The two compartments of this pair, the named one first. A pair is
        /// opened in the first of them, which is what makes a plot's oldest
        /// plant stand in its north-east lens.
        public var compartments: [Compartment] {
            switch self {
            case .northEastLenses:    return [.northEastLens, .southWestLens]
            case .southEastLenses:    return [.southEastLens, .northWestLens]
            case .northEastCrescents: return [.northEastCrescent, .southWestCrescent]
            case .southEastCrescents: return [.southEastCrescent, .northWestCrescent]
            }
        }
    }

    // MARK: What the rule reads off a plant

    /// Where in a compartment a plant belongs, reading outward from the middle
    /// of the plot: the one nearest the basin, the two to either side of it, or
    /// the one farthest out.
    ///
    /// `Rank` is the Knot Garden's reading of a height, as `LongWalk.Tier`,
    /// `QuietGarden.Stand`, `Crossing.Rank` and `Orchard.Rank` are their areas'.
    /// The raw values run outward, which is also the order nothing may stand in
    /// front of something shorter — see `inOrder`.
    public enum Rank: Int, Codable, CaseIterable, Sendable {
        case heart = 0, side, point
    }

    /// **The Orchard's cuts, and said to be the Orchard's rather than measured
    /// again.** A compartment of four graded outward is one nearest the middle,
    /// two at the sides and one furthest out — the same 1:2:1 an orchard guild
    /// is — so it divides the same population of grown heights the same way, and
    /// the 25th and 75th centiles of three hundred crossings are where they were
    /// when `Orchard` measured them: 0.583 m and 1.202 m, set at 0.58 and 1.20,
    /// since the plants' shapes changed on 24 September 2026 (they were 0.75
    /// and 1.30). **0.48 and 1.18 since 29 September 2026**, when the Orchard's
    /// were measured again after the re-roll, on three thousand crossings:
    /// this area's own five hundred ranked 164/234/102 at 0.58 and 1.20, and
    /// rank 142/250/108 at these.
    ///
    /// This is the first area to share its cuts with another, and naming the
    /// reuse is the honest thing. Re-measuring would have produced the same two
    /// numbers and presented them as an independent finding, which is a way of
    /// making one fact look like two.
    ///
    /// They are not the walk's 0.77, not the room's 1.09 and not the
    /// crossing's 0.91 and 1.30, and none of those is wrong: a border of 5:4:3
    /// rows, a group of one back and two arms, and a bed of 3:2:1 divide the
    /// same population differently again.
    public static let sideFrom = Orchard.flankFrom
    public static let pointFrom = Orchard.crownFrom

    public static func rank(height: Double) -> Rank {
        if height < sideFrom { return .heart }
        if height < pointFrom { return .side }
        return .point
    }

    // MARK: Slots

    /// One place in one plot: which compartment, and where in it.
    public struct Slot: Codable, Equatable, Hashable, Sendable {
        public var compartment: Compartment
        /// 0 is the place nearest the middle of the plot, 1 and 2 are the two
        /// beside it at the same distance out, 3 is the one farthest out.
        public var index: Int

        public init(compartment: Compartment, index: Int) {
            self.compartment = compartment
            self.index = index
        }

        public var rank: Rank {
            if index == 0 { return .heart }
            return index < 3 ? .side : .point
        }

        /// Where the place is, in metres from the middle of its plot: the
        /// table's, which lists the compartments in order and four places to
        /// each.
        ///
        /// **Read from the table rather than computed from an angle**, for the
        /// reason `Organic.quarter` exists: a sine taken from a host's own
        /// library is not the same number on every host, and a placement has to
        /// be the same number in Swift and in PHP for ever. Every compartment is
        /// the north-east one of its kind turned by whole quarters, so a pair's
        /// places are exactly opposite.
        ///
        /// The two at index 1 and 2 stand at one distance from the middle of the
        /// plot, which is what frees them from having to be in order with each
        /// other — the Crossing's three sharing an arc, and the Orchard's two
        /// flanking a trunk, asked of a compartment.
        public var spot: Spot {
            KnotGarden.table.spot(compartment.rawValue * 4 + index, on: .plain)
        }
    }

    /// Every place in one plot, compartment by compartment and outward within
    /// each.
    public static let slots: [Slot] = Compartment.allCases.flatMap { compartment in
        (0..<4).map { Slot(compartment: compartment, index: $0) }
    }

    /// The first place of a rank, used to open a compartment nobody has planted.
    static func firstSlot(of rank: Rank, in compartment: Compartment) -> Slot {
        Slot(compartment: compartment, index: rank == .heart ? 0 : (rank == .side ? 1 : 3))
    }

    // MARK: Planting

    /// One plant in the Knot Garden, placed for good.
    public struct Planting: Codable, Equatable, Sendable {
        public var seed: String
        public var plot: Int
        public var slot: Slot
        public var traits: PlantTraits
        /// A small offset from the place, from the seed, up to
        /// `KnotGarden.nudge` either way on each axis. Smaller than every
        /// other area's: the closest two places in a compartment stand 0.42 m
        /// apart, and a compartment is meant to read as a block rather than as
        /// four plants that have wandered.
        public var nudge: Spot

        /// Where the plant stands: its place and its nudge, the sum laid as
        /// the plot is (`PlotVariant`), which here is always as the table
        /// draws it.
        public var spot: Spot {
            let place = slot.spot
            return PlotVariant.of(plot: plot, area: .pattern)
                .apply(Spot(x: place.x + nudge.x, z: place.z + nudge.z))
        }
    }

    /// The whole area: every planting, in the order they arrived. Append-only,
    /// as all four of the others are — a place somebody visited yesterday is the
    /// same place today.
    public struct Ways: Codable, Equatable, Sendable {
        public private(set) var plantings: [Planting] = []

        public init() {}

        /// **The Knot Garden as it opened**: the pattern ambassador in the
        /// north-east lens and nothing else. `KnotGarden.ambassador` is the planting.
        public static func opened() -> Ways {
            var ways = Ways()
            let one = Ambassadors.of(.pattern)
            ways.plant(seed: one.seed, traits: LongWalk.traits(of: one.genome))
            return ways
        }

        public var plots: Int { (plantings.map(\.plot).max() ?? -1) + 1 }

        public func plot(_ index: Int) -> [Planting] {
            plantings.filter { $0.plot == index }
        }

        /// The colour family standing in this pair of this plot, or nil if
        /// nobody has claimed it.
        ///
        /// Read off the plants rather than stored, which is what keeps a claim
        /// from being a thing that can go stale or be restored wrong: a pair
        /// holds a family because plants of that family are standing in it.
        public func family(of pair: Pair, in plot: Int) -> Int? {
            self.plot(plot).first { $0.slot.compartment.pair == pair }?.traits.family
        }

        /// Where the next plant with these traits would go, without planting it.
        ///
        /// **Colour picks the pair, height picks the place in it.** That is the
        /// whole rule and it is the one Marcus chose on 21 September. Both
        /// fields of `PlantTraits` are used here for the first time, and the
        /// height grammar every other area shares is kept rather than thrown
        /// away — a knot garden is symmetrical in colour and graded in height,
        /// not one instead of the other.
        ///
        /// In order:
        ///
        /// 1. **A pair already holding this plant's colour**, in the oldest plot
        ///    that has one with room — its own rank there if it can, and
        ///    otherwise a rank beside its own, as long as nothing ends up
        ///    standing in front of something shorter than itself.
        /// 2. **A pair nobody has claimed**, in the oldest plot that has one,
        ///    claimed by this plant for its colour.
        /// 3. A new plot, opened in its north-east lens.
        ///
        /// **Note the nesting in the first step: plot outside, rank inside.**
        /// That is the Orchard's order rather than the Crossing's, and for a
        /// kindred reason — what this area is for is that a compartment reads as
        /// one colour, so filling the oldest claimed pair matters more than
        /// getting the rank a height asks for. A port with the two loops the
        /// other way round would agree about most plants and disagree about
        /// exactly the ones that decide whether a pair fills.
        public func place(for traits: PlantTraits) -> (plot: Int, slot: Slot) {
            let own = KnotGarden.rank(height: traits.height)
            let opened = plots
            // Each plot read once and its pairs' colours read off it once. The
            // answer is the same either way; a plot re-filtered for every pair
            // and every rank is the same arithmetic done twenty times.
            let byPlot = (0..<opened).map { self.plot($0) }
            func claimed(_ here: [Planting]) -> [Pair: Int] {
                var families: [Pair: Int] = [:]
                for p in here where families[p.slot.compartment.pair] == nil {
                    families[p.slot.compartment.pair] = p.traits.family
                }
                return families
            }
            let families = byPlot.map(claimed)

            for plot in 0..<opened {
                for pair in Pair.allCases where families[plot][pair] == traits.family {
                    for rank in KnotGarden.ranks(beside: own) {
                        if let slot = slot(in: byPlot[plot], pair: pair, for: traits, rank: rank) {
                            return (plot, slot)
                        }
                    }
                }
            }
            for plot in 0..<opened {
                for pair in Pair.allCases where families[plot][pair] == nil {
                    return (plot, KnotGarden.firstSlot(of: own, in: pair.compartments[0]))
                }
            }
            return (opened, KnotGarden.firstSlot(of: own, in: .northEastLens))
        }

        /// A free place of this rank in this pair that this plant may stand in.
        ///
        /// **The emptier of the pair's two compartments**, ties to the one the
        /// pair is named for. It is the Crossing's *wherever there is least*
        /// asked of two compartments instead of four quarters, and it is what
        /// makes a pair fill as a mirror rather than as one block and then
        /// another — which is the only reading of *symmetrical* this area can
        /// have, given that nothing is reserved.
        func slot(in here: [Planting], pair: Pair, for traits: PlantTraits, rank: Rank) -> Slot? {
            let taken = Set(here.map(\.slot))
            var best: Slot?
            var fewest = Int.max
            for compartment in pair.compartments {
                let block = here.filter { $0.slot.compartment == compartment }
                guard block.count < fewest else { continue }
                let open = KnotGarden.slots.first {
                    $0.compartment == compartment && $0.rank == rank && !taken.contains($0)
                        && inOrder(traits.height, at: $0, among: block)
                }
                if let open {
                    best = open
                    fewest = block.count
                }
            }
            return best
        }

        /// Whether a plant this tall can stand in this place: reading outward
        /// from the middle of the plot, nothing stands in front of something
        /// shorter than itself.
        ///
        /// It is the Long Walk's rule about a border, the Quiet Garden's about a
        /// group of three, the Crossing's about a quarter and the Orchard's
        /// about a ring round a trunk, asked of a compartment looked into from
        /// the knot's own middle. Ranks are compared, not distances, so the two
        /// plants at index 1 and 2 are free of each other — which is why they
        /// were put at one distance out.
        func inOrder(_ height: Double, at slot: Slot, among block: [Planting]) -> Bool {
            for other in block {
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
                                    nudge: Spot(x: jitter(26, KnotGarden.nudge),
                                                z: jitter(27, KnotGarden.nudge)))
            plantings.append(planting)
            return planting
        }
    }

    /// The ranks to try, in order: a plant's own, then the one or two beside it.
    ///
    /// The same shape as the other four areas', and for the same finding: a
    /// plant that cannot have its own rank is better one step out of place than
    /// in a plot of its own. `inOrder` is what keeps one step from becoming a
    /// mess.
    static func ranks(beside rank: Rank) -> [Rank] {
        switch rank {
        case .heart: return [.heart, .side]
        case .side:  return [.side, .heart, .point]
        case .point: return [.point, .side]
        }
    }

    // MARK: The ambassador

    /// **The plant in the north-east lens of the first plot.**
    ///
    /// *Quinyria obscura* — `Ambassadors.of(.pattern)` since the re-roll of 28
    /// September 2026 — placed by this rule into an empty Knot Garden. An
    /// empty plot has no claimed pairs, so it claims the first one for its own
    /// colour, family 4, and stands in the north-east lens (the north
    /// compartment until the rings of 2 October 2026: the same slot).
    ///
    /// **It is 1.22 m, which reads as a point**, so it takes index 3: the
    /// place at the lens's outer edge, against the middle ring. (*Quina caerulea*, until then,
    /// was 1.0064 m, a side, and took index 1, beside the middle of its
    /// compartment.) There is nothing awkward in that, and it is worth having
    /// confirmed rather than assumed — the finding from the walk on 20 September
    /// is that whatever place an area's first arrival takes has to be one the
    /// area's own ambassador can stand in, and here every place in an empty
    /// compartment is, because an empty compartment refuses nobody.
    ///
    /// Derived rather than stored, as the other four are: the place and the
    /// nudge are pure functions of the pinned seed, so there is no row for a
    /// withdrawal, a report or a backup to reach.
    public static let ambassador: Planting = Ways.opened().plantings[0]
}

/// The Knot Garden's reading of a plant: which of the three ranks of a
/// compartment it belongs in, counting outward from the middle of the knot.
extension PlantTraits {
    public var compartmentRank: KnotGarden.Rank { KnotGarden.rank(height: height) }
}
