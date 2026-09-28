#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

/// The Knot Garden: two bands of low clipped hedging woven over and under each
/// other inside a square edging, and eight compartments filled with colour.
/// `docs/WEB-GARDENS.md`.
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
/// The rule runs in SeedCore so the plot service, the website and the app read
/// one copy. `Server/.api/KnotGarden.php` is the port, and
/// `tools/reference/check_knot.php` holds them together.
public enum KnotGarden {

    // MARK: The plot

    /// A web plot's side, the same square every area uses.
    public static let plotSide = 5.2

    /// Half the thickness of a run of hedging. The knot, the edging and every
    /// compartment boundary are the same band.
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

    /// Where the four runs of the knot lie, on each axis, from the middle of the
    /// plot: two running one way at ±`bandFrom`, two running the other.
    ///
    /// **They cross four times, and that is the knot.** At each crossing one run
    /// carries on through and the other stops against its face, and which does
    /// which alternates round the weave, so every run is over at one of its two
    /// crossings and under at the other. Two runs drawn simply overlapping are a
    /// grid; the alternation is the difference between a grid and a knot, and it
    /// is the thing this area exists to draw.
    public static let bandFrom = 0.76

    /// How far the stretch of a run between its two crossings stands in toward
    /// the middle of the plot, at its middle.
    ///
    /// **This is the difference between a knot and a parterre**, and the area
    /// was laid out without it. Four straight bands woven over and under are a
    /// weave, and a weave drawn with a ruler reads as a grid however honestly
    /// it is interlaced: there is no line for the eye to follow through a
    /// crossing. Bowed, the four inner stretches close round the empty middle
    /// as a ring of four arcs and each band becomes a ribbon that goes
    /// somewhere.
    ///
    /// **It bows into the middle because the middle is the one place with
    /// room.** Nothing is planted there, so this number costs nothing: at 0.30
    /// the nearest plant to any band is exactly as near as it was when every
    /// band was straight. The compartments are full of plants, and a band that
    /// bowed into one would stand where a plant already does.
    ///
    /// **No plant moves for this.** A bow is zero at both crossings, so every
    /// compartment keeps the four corners it had and
    /// `tools/reference/knot_garden_vectors.json` does not change.
    ///
    /// 0.30 m leaves a middle 0.74 m across, which still reads as a middle the
    /// weave closes round rather than as four bands meeting.
    public static let knotBow = 0.30

    /// How far the stretch of a run from a crossing out to the edging stands
    /// out, away from the middle of the plot, at its middle.
    ///
    /// **A band that bows one way and then the other is a ribbon**; one that
    /// bows only between its crossings is a straight band with a curve let into
    /// it. So the four arms of each run bow the other way from its inner
    /// stretch, and a run leaves a crossing turning back.
    ///
    /// **0.05, and this one is paid for**, which is why it is a sixth of the
    /// inner bow. An arm has a compartment on each side of it. The nearest
    /// place to an arm is the one at 1.03 m in a corner compartment, 0.18 m
    /// from the band's face when the band is straight; a plant stands up to
    /// `Planting.nudge` — 0.09 m on an axis — off its place, so that 0.18 is
    /// really 0.09. At
    /// 0.05 the arm takes 0.04 of what is left and a nudged plant still stands
    /// 0.048 m clear of ankle-high box, which is a planted block with its edge
    /// against the hedge. `clearance(x:z:)` is where that is measured, and
    /// `KnotGardenTests` is where it is held.
    public static let armBow = 0.05

    /// Where the square edging lies, from the middle of the plot. It is the same
    /// band as the knot, closing the four corner compartments — without it they
    /// are not compartments but the gravel round the outside.
    public static let edgingFrom = 2.20

    /// How far an under-run's cut end hides inside the band that crosses over
    /// it. Enough that no daylight shows at the joint, little enough that the
    /// two ends still read as one run diving under rather than as a band with a
    /// lump in it.
    public static let tuck = 0.04

    // MARK: The weave

    /// One length of the knot's band: it runs along `x` or along `z`, from
    /// `from` to `to` on that axis, stands at `at` on the other, and its middle
    /// stands `bow` off the straight line between its two ends — away from the
    /// middle of the plot where that is positive.
    public struct Stretch: Sendable, Equatable {
        public let alongX: Bool
        public let at: Double
        public let from: Double
        public let to: Double
        public let bow: Double

        /// Where the band's line stands on the axis it is fixed to, `along`
        /// metres down the axis it runs on.
        ///
        /// `Organic.hedge`'s bow, which is `bow` at the middle and flat on the
        /// straight line between the two ends — so a stretch's two ends are on
        /// `at` however hard it bows, and a crossing does not move.
        public func line(at along: Double) -> Double {
            let fraction = 2 * (along - (from + to) / 2) / (to - from)
            let hump = 1 - fraction * fraction
            return at + bow * hump * hump
        }
    }

    /// **The knot as lengths of band**: three to each of the four runs, and
    /// four more for the square edging.
    ///
    /// A run along z at x = s dives under the run along x at z = −s; a run
    /// along x at z = s dives under the run along z at x = s. Written as the
    /// two rules rather than as a table of four, because what has to be true is
    /// that each run is over at one of its two crossings and under at the
    /// other, and a table is a thing that can be typed wrong without looking
    /// wrong.
    ///
    /// **Each run is in three**: an arm, the stretch between its two crossings,
    /// and the other arm. It is cut at its under-crossing because that gap is
    /// the weave, and cut again at its over-crossing because the two stretches
    /// meeting there bow opposite ways and one length of hedge bows one way.
    /// That second cut does not show: `Organic.hedge` leaves a bow flat at both
    /// ends, so the two stretches meet along the same line, which is the whole
    /// reason the bow is shaped the way it is.
    ///
    /// **It is here rather than in the page** for the reason
    /// `bandHalfThickness` is: a compartment's edges are where the bands' faces
    /// are, so the shape of the bands is something the rule has to be able to
    /// answer. The page draws these and keeps no copy of them.
    public static var weave: [Stretch] {
        var band: [Stretch] = []
        for s in [bandFrom, -bandFrom] {
            // Along z, standing at x = s, under the crossing at z = −s.
            band += run(alongX: false, at: s, under: -s, over: s)
            // Along x, standing at z = s, under the crossing at x = s.
            band += run(alongX: true, at: s, under: s, over: -s)
        }
        // The square edging, straight: a knot's border is the frame the pattern
        // is drawn in, and a frame that wandered would be a fifth band.
        for s in [edgingFrom, -edgingFrom] {
            band.append(Stretch(alongX: false, at: s, from: -edgingFrom, to: edgingFrom, bow: 0))
            band.append(Stretch(alongX: true, at: s, from: -edgingFrom, to: edgingFrom, bow: 0))
        }
        return band
    }

    /// One run of the weave in its three stretches, in the order they lie along
    /// the axis it runs on.
    ///
    /// **Which crossing comes first is not the same for all four runs** — the
    /// run at `+bandFrom` dives under at the near end and the one at
    /// `-bandFrom` at the far end — so the three are cut out between the two
    /// crossings sorted rather than between `under` and `over` in the order
    /// they are named. Writing it the other way round gives two of the four
    /// runs a stretch that spans the plot and one with its ends swapped, which
    /// is a mistake the drawing very nearly hides.
    ///
    /// Only the under-crossing takes a bite out of the band: that gap is the
    /// weave. At the over-crossing the two stretches meet, because one length
    /// of hedge bows one way and they bow opposite ways.
    private static func run(alongX: Bool, at: Double,
                            under: Double, over: Double) -> [Stretch] {
        let short = bandHalfThickness - tuck
        let away = at > 0 ? 1.0 : -1.0
        let first = min(under, over), second = max(under, over)
        let gapBefore = { (crossing: Double) in crossing == under ? short : 0 }
        return [
            Stretch(alongX: alongX, at: at, from: -edgingFrom,
                    to: first - gapBefore(first), bow: away * armBow),
            Stretch(alongX: alongX, at: at, from: first + gapBefore(first),
                    to: second - gapBefore(second), bow: -away * knotBow),
            Stretch(alongX: alongX, at: at, from: second + gapBefore(second),
                    to: edgingFrom, bow: away * armBow),
        ]
    }

    /// How far a point on the ground stands from the nearest face of the
    /// nearest band, in metres. Negative inside a band.
    ///
    /// Walked rather than solved, because the nearest point on `Stretch.line`
    /// is a cubic to solve and this is asked by tests rather than by a page
    /// drawing a frame.
    public static func clearance(x: Double, z: Double, steps: Int = 400) -> Double {
        var nearest = Double.greatestFiniteMagnitude
        for stretch in weave {
            let length = stretch.to - stretch.from
            for step in 0...steps {
                let along = stretch.from + length * Double(step) / Double(steps)
                let stands = stretch.line(at: along)
                let dx = x - (stretch.alongX ? along : stands)
                let dz = z - (stretch.alongX ? stands : along)
                nearest = min(nearest, (dx * dx + dz * dz).squareRoot())
            }
        }
        return nearest - bandHalfThickness
    }

    // MARK: The eight compartments

    /// The eight compartments: four at the sides of the plot and four at its
    /// corners, with the weave between them and nothing planted in the middle.
    ///
    /// **Declared sides first, then corners**, so that `rawValue % 4` is the
    /// number of quarter turns from the compartment's own canonical place and
    /// `rawValue ^ 2` is its mirror. Both come out of the declaration order
    /// rather than out of a table that could disagree with it.
    public enum Compartment: Int, Codable, CaseIterable, Sendable {
        case north = 0, east, south, west
        case northEast, southEast, southWest, northWest

        /// Whether this one sits at a corner of the plot rather than at a side.
        /// The two kinds are different shapes — a corner compartment is a
        /// square, a side one is wider than it is deep — so they have canonical
        /// places of their own.
        public var atCorner: Bool { rawValue >= 4 }

        /// Quarter turns clockwise from the canonical compartment of its kind,
        /// which is the north one and the north-east one.
        var turns: Int { rawValue % 4 }

        /// The compartment opposite this one, which holds the same colour.
        ///
        /// Two quarter turns, which for both kinds is the opposite side of the
        /// plot: north against south, east against west, north-east against
        /// south-west, south-east against north-west.
        public var mirror: Compartment { Compartment(rawValue: rawValue ^ 2)! }

        /// Which of the four pairs this compartment belongs to.
        public var pair: Pair { Pair(rawValue: rawValue % 2 + (atCorner ? 2 : 0))! }
    }

    /// The four mirror pairs, each named for the lower-numbered of its two
    /// compartments. A pair is what a colour claims.
    public enum Pair: Int, Codable, CaseIterable, Sendable {
        case north = 0, east, northEast, southEast

        /// The two compartments of this pair, the named one first. A pair is
        /// opened in the first of them, which is what makes a plot's oldest
        /// plant stand at its north side.
        public var compartments: [Compartment] {
            switch self {
            case .north:     return [.north, .south]
            case .east:      return [.east, .west]
            case .northEast: return [.northEast, .southWest]
            case .southEast: return [.southEast, .northWest]
            }
        }
    }

    // MARK: What the rule reads off a plant

    /// Where in a compartment a plant belongs, reading outward from the middle
    /// of the plot: the one nearest the knot, the two to either side of it, or
    /// the one at the outer edge.
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
    /// and 1.30).
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
        /// beside it at the same distance out, 3 is the one at the outer edge.
        public var index: Int

        public init(compartment: Compartment, index: Int) {
            self.compartment = compartment
            self.index = index
        }

        public var rank: Rank {
            if index == 0 { return .heart }
            return index < 3 ? .side : .point
        }

        /// Where the place is, in metres from the middle of its plot.
        ///
        /// **Written out rather than computed from an angle**, for the reason
        /// `Organic.quarter` exists: a sine taken from a host's own library is
        /// not the same number on every host, and a placement has to be the same
        /// number in Swift and in PHP for ever. Every compartment is one of two
        /// canonical sets of four turned by a whole number of quarters, so the
        /// turning is sign swaps and nothing else.
        ///
        /// The two at index 1 and 2 stand at one distance from the middle of the
        /// plot, which is what frees them from having to be in order with each
        /// other — the Crossing's three sharing an arc, and the Orchard's two
        /// flanking a trunk, asked of a compartment.
        public var spot: Spot {
            let (x, z) = (compartment.atCorner ? Slot.corner : Slot.side)[index]
            return KnotGarden.turned(x, z, by: compartment.turns)
        }

        /// The four places in the north compartment, which is 1.37 m across
        /// and 1.29 m deep between the knot's two runs and the edging.
        static let side: [(Double, Double)] = [
            (0, 1.16),        // 0  nearest the knot's middle
            (-0.43, 1.53),    // 1  beside it
            (0.43, 1.53),     // 2  beside it, the same distance out as 1
            (0, 1.89),        // 3  at the edging
        ]

        /// The four places in the north-east compartment, a 1.22 m square
        /// between the two runs and the edging's corner. Graded along its own
        /// diagonal, which is the direction the middle of the plot lies in.
        static let corner: [(Double, Double)] = [
            (1.09, 1.09),     // 0  nearest the knot's middle
            (1.03, 1.72),     // 1  beside it
            (1.72, 1.03),     // 2  beside it, the same distance out as 1
            (1.80, 1.80),     // 3  at the edging's corner
        ]
    }

    /// A point turned by `turns` quarter turns clockwise about the middle of the
    /// plot. Sign swaps only, so every host agrees to the bit.
    static func turned(_ x: Double, _ z: Double, by turns: Int) -> Spot {
        switch turns % 4 {
        case 1:  return Spot(x: z, z: -x)
        case 2:  return Spot(x: -x, z: -z)
        case 3:  return Spot(x: -z, z: x)
        default: return Spot(x: x, z: z)
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
        /// A small offset from the place, from the seed. Smaller than every
        /// other area's: the closest two places in a compartment stand 0.56 m
        /// apart, tighter than the Crossing's 0.53 only by virtue of the
        /// compartment walls, and a compartment is meant to read as a block
        /// rather than as four plants that have wandered.
        public var nudge: Spot

        public var spot: Spot {
            Spot(x: slot.spot.x + nudge.x, z: slot.spot.z + nudge.z)
        }
    }

    /// The whole area: every planting, in the order they arrived. Append-only,
    /// as all four of the others are — a place somebody visited yesterday is the
    /// same place today.
    public struct Ways: Codable, Equatable, Sendable {
        public private(set) var plantings: [Planting] = []

        public init() {}

        /// **The Knot Garden as it opened**: the pattern ambassador in the north
        /// compartment and nothing else. `KnotGarden.ambassador` is the planting.
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
        /// 3. A new plot, opened in the north compartment.
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
            return (opened, KnotGarden.firstSlot(of: own, in: .north))
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
                                    nudge: Spot(x: jitter(26, 0.09), z: jitter(27, 0.09)))
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

    /// **The plant in the north compartment of the first plot.**
    ///
    /// *Quinyria obscura* — `Ambassadors.of(.pattern)` since the re-roll of 28
    /// September 2026 — placed by this rule into an empty Knot Garden. An
    /// empty plot has no claimed pairs, so it claims the first one for its own
    /// colour, family 4, and stands in the north compartment.
    ///
    /// **It is 1.22 m, which reads as a point**, so it takes index 3: the
    /// place at the compartment's outer edge. (*Quina caerulea*, until then,
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
/// compartment it belongs in, counting outward from the knot.
extension PlantTraits {
    public var compartmentRank: KnotGarden.Rank { KnotGarden.rank(height: height) }
}
