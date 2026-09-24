#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

/// The Cold Frame: four low glazed frames on gravel, each holding two ranks of
/// young plants hardening off, their lids propped open by day.
/// `docs/WEB-GARDENS.md` §*The Cold Frame, built*.
///
/// **The seventh area, and the first that draws a plant as something other
/// than what it will be.** Every other area stands a plant at its best, grown
/// and in flower. A cold frame holds the young stages of what grows elsewhere,
/// so this one draws every plant young (`drawn`) and places it by what it will
/// grow into. That split — placed by the mature height, drawn at an early one
/// — is the whole of what is new here, and the rule never reads the drawn
/// height at all.
///
/// **Nobody is turned away.** The layout's first reading was *small plants
/// only*, and it was measured before it was built: plants whose name puts them
/// here grow to between 0.33 and 1.64 m (median 0.85), and a frame holds about
/// 0.4 m, so a height limit would have refused nine in ten of the area's own
/// plants. Every plant is admitted and drawn young instead, which is what a
/// cold frame is for anyway.
///
/// **Colour claims a frame and the mature height orders its ranks.** The Knot
/// Garden's claim, asked of a frame instead of a pair, and read off the plants
/// rather than stored, for the same reason: a claim that lives in a column can
/// go stale, be restored wrong, or disagree with what is standing in it.
///
/// The rule runs in SeedCore so the plot service, the website and the app read
/// one copy. `Server/.api/ColdFrame.php` is the port, and
/// `tools/reference/check_cold_frame.php` holds them together.
public enum ColdFrame {

    // MARK: The plot

    /// The same square every area uses.
    public static let plotSide = 5.2

    /// Four frames of twelve, two ranks of six in each: forty-eight a plot,
    /// Marcus's choice on 23 September.
    public static let places = 6

    /// A frame's outside, in metres: along the ranks, and from back to front.
    /// About the size of a pair of lights, which is what a cold frame is made
    /// of — two glazed lids side by side, each an arm's reach deep.
    public static let frameLength = 2.0
    public static let frameDepth = 1.1

    /// Where the middles of the four frames stand: two either side of the plot
    /// in `x`, and two rows in `z` with a path between them 0.7 m wide.
    ///
    /// **The gap between the two frames of a row is 0.4 m**, which is what
    /// makes them two frames rather than one long one. At 0.2 m they read as a
    /// single range of four lights, and a range holding two colours is not two
    /// frames each claimed by one.
    public static let frameX = 1.2
    public static let frameZ = 0.9

    /// How high the frame's walls stand at the back and at the front. The lid
    /// slopes between them toward the front, which is toward the sun.
    ///
    /// **The slope is the ranks' own grading.** A cold frame is built higher at
    /// the back so rain runs off and the glass faces the light; the rule
    /// stands the plants that will grow tallest at the back. The two were
    /// never designed together and they agree: the taller rank stands under the
    /// higher glass.
    public static let backWall = 0.50
    public static let frontWall = 0.32

    /// How far the front of a lid is propped above the front wall by day, on a
    /// block, to let the air in. That is how a frame is hardened off: propped a
    /// little at first, more each day, then the lights taken off altogether.
    ///
    /// **0.16 since 24 September 2026, up from 0.10**, so the gap at the front
    /// reads as open from the page's isometric eye; at 0.10 the lights looked
    /// shut. It stays under 0.18, the back wall's height over the front's, so
    /// the glass still falls to the front.
    public static let propped = 0.16

    /// Along a rank, between one place and the next, and how far either rank
    /// stands from the middle of its frame.
    public static let alongGap = 0.31
    public static let rankFrom = 0.24

    // MARK: The frames

    /// The four frames, in the order a plot opens them: the back row from
    /// west to east, then the front row. **The back row is `z−`**, which is
    /// the side of the plot furthest from the eye before the page is turned.
    public enum Frame: Int, Codable, CaseIterable, Sendable {
        case backWest = 0, backEast, frontWest, frontEast

        /// The middle of the frame, from the middle of the plot.
        public var centre: Spot {
            Spot(x: rawValue % 2 == 0 ? -ColdFrame.frameX : ColdFrame.frameX,
                 z: rawValue < 2 ? -ColdFrame.frameZ : ColdFrame.frameZ)
        }
    }

    /// The two ranks of a frame. Every frame's back is `z−` of its middle, so
    /// the back rank is always the one further from the eye before a turn, and
    /// the one under the higher glass.
    public enum Rank: Int, Codable, CaseIterable, Sendable {
        case front = 0, back
    }

    /// **The median of the area's own plants.** Five hundred arrivals whose
    /// names put them in the Cold Frame, out of 5,805 crossings, grow to a
    /// median of 0.848 m, set at 0.85. Two ranks of six divide a frame in
    /// half, so the cut that divides the population in half is the one that
    /// lets the most plants have their own rank.
    ///
    /// **Measured over this area's plants rather than all of them**, which no
    /// earlier area needed to do. The Cold Frame's plants are shorter than the
    /// garden's — a quarter of all arrivals are under 0.75 m, and a quarter of
    /// these are under 0.69 m — so a cut borrowed from another area would
    /// divide them unevenly: the Orchard's 0.75 puts 65% of them at the back,
    /// the Long Walk's 0.93 puts 39%. This one puts 49.8%.
    public static let backFrom = 0.85

    public static func rank(height: Double) -> Rank {
        height < backFrom ? .front : .back
    }

    // MARK: Slots

    /// One place in one plot: which frame, which rank, and how far along it.
    public struct Slot: Codable, Equatable, Hashable, Sendable {
        public var frame: Frame
        public var rank: Rank
        /// 0 is the west end of the rank. A rank fills from there, the way
        /// trays are set into a frame from the end a gardener reaches in at.
        public var index: Int

        public init(frame: Frame, rank: Rank, index: Int) {
            self.frame = frame
            self.rank = rank
            self.index = index
        }

        /// Where the place is, in metres from the middle of its plot.
        public var spot: Spot {
            let centre = frame.centre
            return Spot(x: centre.x + (Double(index) - Double(ColdFrame.places - 1) / 2) * ColdFrame.alongGap,
                        z: centre.z + (rank == .back ? -ColdFrame.rankFrom : ColdFrame.rankFrom))
        }
    }

    /// Every place in a plot, frame by frame, the front rank before the back.
    public static let slots: [Slot] = Frame.allCases.flatMap { frame in
        Rank.allCases.flatMap { rank in
            (0..<places).map { Slot(frame: frame, rank: rank, index: $0) }
        }
    }

    // MARK: Drawn young

    /// **How every plant in the Cold Frame is drawn**: a young plant with its
    /// leaves most of the way open and its first buds just showing colour.
    ///
    /// Not a moment on the plant's own timeline. `GrowthModel` grows height
    /// first and buds only once the height is done, so a plant young enough to
    /// stand under glass has never shown its colour — and colour is what claims
    /// a frame. A plant hardening off is often in its first bud all the same,
    /// so the state is put together rather than read off a clock.
    ///
    /// **Chosen by measuring**, over the five hundred arrivals `backFrom` was
    /// measured on:
    ///
    /// - `heightScale` 0.30. Below 0.25 `PlantBuilder` draws the seed's husk
    ///   at the foot of the stem, which belongs to the day a seed is sown.
    /// - `leafUnfurl` 0.7. Fully open, a young plant's leaves are drawn at
    ///   nearly half their grown size on a stem a third of its height, and the
    ///   tallest of them stood above the glass.
    /// - `budSwell` 0.2 and nothing open. Enough to show which colour a plant
    ///   is; a bud swollen further stands a full-size flower head on a young
    ///   stem, and at 0.8 the tallest plant was 0.9 m.
    ///
    /// That draws the five hundred between 0.11 and 0.45 m tall. The shortest
    /// still reads as a plant, and `ColdFrameTests` holds the tallest of each
    /// rank under the glass it stands beneath.
    public static let drawn = GrowthModel.State(
        stage: .growing, stageProgress: 0.5, overall: 0.3,
        heightScale: 0.30, leafUnfurl: 0.7, budSwell: 0.2, bloomOpen: 0,
        age: 0, timeToNextStage: nil, flush: 0, flushDepth: 0
    )

    /// How high the underside of the glass stands above the ground at a point
    /// `z` metres toward the front from the middle of a frame, with the lights
    /// propped. Asked of `Organic`, which draws them, so the plants are
    /// measured against the glass the page actually shows.
    public static func glass(atDepth z: Double) -> Double {
        Organic.lightUnderside(atDepth: z, depth: frameDepth, back: backWall,
                               front: frontWall, propped: propped)
    }

    // MARK: Planting

    /// One plant in the Cold Frame, placed for good.
    public struct Planting: Codable, Equatable, Sendable {
        public var seed: String
        public var plot: Int
        public var slot: Slot
        /// The plant's traits, **the grown height among them**. The young
        /// height it is drawn at is never stored: it is a matter of drawing,
        /// and nothing is decided by it.
        public var traits: PlantTraits
        /// A small offset from the place, from the seed: 0.03 m either way.
        /// Places along a rank are 0.31 m apart and a rank is meant to read as
        /// one, so this is the tightest nudge in the garden after the
        /// Seedbed's across a drill.
        public var nudge: Spot

        public var spot: Spot {
            Spot(x: slot.spot.x + nudge.x, z: slot.spot.z + nudge.z)
        }
    }

    /// The whole area: every planting, in the order they arrived. Append-only,
    /// as the other six are.
    public struct Ways: Codable, Equatable, Sendable {
        public private(set) var plantings: [Planting] = []

        public init() {}

        /// **The Cold Frame as it opened**: the waiting ambassador in the first
        /// frame, and nothing else.
        public static func opened() -> Ways {
            var ways = Ways()
            let one = Ambassadors.of(.waiting)
            ways.plant(seed: one.seed, traits: LongWalk.traits(of: one.genome))
            return ways
        }

        public var plots: Int { (plantings.map(\.plot).max() ?? -1) + 1 }

        public func plot(_ index: Int) -> [Planting] {
            plantings.filter { $0.plot == index }
        }

        /// The colour family standing in this frame of this plot, or nil if
        /// nobody has claimed it. Read off the plants, as the Knot Garden's
        /// pairs and the Seedbed's drills are.
        public func family(of frame: Frame, in plot: Int) -> Int? {
            self.plot(plot).first { $0.slot.frame == frame }?.traits.family
        }

        /// Where the next plant with these traits would go, without planting
        /// it.
        ///
        /// **Colour picks the frame, the grown height picks the rank.** In
        /// order:
        ///
        /// 1. **A frame already holding this plant's colour**, oldest plot
        ///    first — its own rank if there is room and nothing would stand
        ///    out of order, otherwise the other rank on the same terms.
        /// 2. **A frame nobody has claimed**, oldest plot first, in its own
        ///    rank.
        /// 3. A new plot, opened in the first frame.
        ///
        /// Plot outside, rank inside, as the Knot Garden and the Orchard have
        /// it: a frame reading as one colour matters more than a plant getting
        /// the rank its height asks for.
        public func place(for traits: PlantTraits) -> (plot: Int, slot: Slot) {
            let own = ColdFrame.rank(height: traits.height)
            let opened = plots
            let byPlot = (0..<opened).map { self.plot($0) }

            for plot in 0..<opened {
                for frame in Frame.allCases {
                    let here = byPlot[plot].filter { $0.slot.frame == frame }
                    guard here.first?.traits.family == traits.family else { continue }
                    for rank in [own, own == .back ? .front : .back] {
                        let taken = here.filter { $0.slot.rank == rank }.count
                        if taken < ColdFrame.places, inOrder(traits.height, in: rank, among: here) {
                            return (plot, Slot(frame: frame, rank: rank, index: taken))
                        }
                    }
                }
            }
            for plot in 0..<opened {
                for frame in Frame.allCases where !byPlot[plot].contains(where: { $0.slot.frame == frame }) {
                    return (plot, Slot(frame: frame, rank: own, index: 0))
                }
            }
            return (opened, Slot(frame: .backWest, rank: own, index: 0))
        }

        /// Whether a plant this tall can stand in this rank of a frame: nothing
        /// in the front rank taller than anything in the back.
        ///
        /// The Long Walk's rule about a border, asked of a frame. Places along
        /// one rank are free of each other, because the ranks are what is
        /// graded and a rank is one row.
        func inOrder(_ height: Double, in rank: Rank, among frame: [Planting]) -> Bool {
            for other in frame where other.slot.rank != rank {
                if rank == .back, height < other.traits.height { return false }
                if rank == .front, height > other.traits.height { return false }
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
                                    nudge: Spot(x: jitter(26, 0.03), z: jitter(27, 0.03)))
            plantings.append(planting)
            return planting
        }
    }

    /// **The first plant in the Cold Frame**, and the one it is drawn with
    /// before anybody has released anything into it: `Ambassadors.of(.waiting)`
    /// placed by this rule into an empty area. Derived rather than stored, as
    /// the other six are.
    public static let ambassador: Planting = Ways.opened().plantings[0]
}

/// The Cold Frame's reading of a plant: which rank of a frame it belongs in.
extension PlantTraits {
    public var frameRank: ColdFrame.Rank { ColdFrame.rank(height: height) }
}
