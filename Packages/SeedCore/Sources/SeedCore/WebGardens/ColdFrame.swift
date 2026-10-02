#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

/// The Cold Frame: low glazed frames on gravel, each holding two ranks of
/// young plants hardening off, their lids propped open by day, and a tank of
/// water in front of them. Two frames since 29 September 2026; four until then.
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
/// cold frame is for anyway. Since the plants' shapes changed on 24 September
/// 2026 every one of them is a lotus or a fern, 0.23 to 0.82 m (median 0.38),
/// and a limit would still refuse four in ten.
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

    /// **How this area's plots vary**, from each plot's number (`PlotVariant`,
    /// Marcus's decision of 2 October 2026). Mirrored only, so the frames stay at
    /// the back under their high side. Declared but not yet read: the area's new
    /// layout reads it.
    public static let variants = PlotVariant.Space(mirror: true)

    /// Two ranks of six in each frame: twelve a frame. Four frames of twelve,
    /// forty-eight a plot, was Marcus's choice on 23 September; **two frames,
    /// twenty-four, since 29 September 2026**, when the tank grew into the
    /// front row's ground (`frames`).
    public static let places = 6

    /// A frame's outside, in metres: along the ranks, and from back to front.
    /// About the size of a pair of lights, which is what a cold frame is made
    /// of — two glazed lids side by side, each an arm's reach deep.
    public static let frameLength = 2.0
    public static let frameDepth = 1.1

    /// Where the middles of the frames stand: either side of the plot in `x`,
    /// and in `z` along the back of the yard.
    ///
    /// **The gap between the two frames of a row is 0.4 m**, which is what
    /// makes them two frames rather than one long one. At 0.2 m they read as a
    /// single range of four lights, and a range holding two colours is not two
    /// frames each claimed by one.
    public static let frameX = 1.2
    /// **Pushed out from 0.9 on 27 September 2026 to make room for the tank.**
    /// The two rows used to sit either side of a 0.7 m path; they now sit
    /// either side of 1.8 m of water. A frame is 1.1 m deep, so at 1.55 the
    /// rows run from 1.0 to 2.1 m out against the plot's own half of 2.6.
    /// Nothing inside a frame moved: the ranks are still 0.24 m either side of
    /// its middle, and a frame still holds two ranks of six.
    ///
    /// **1.65 since 29 September 2026**, a tenth further back, so the grown
    /// tank has the room in front of the frames: the back row runs from 1.1
    /// to 2.2 m out, 0.4 m inside the plot's half, as the frames' ends are.
    public static let frameZ = 1.65

    /// **The tank down the middle of the yard** (27 September 2026).
    ///
    /// **This is one of only two areas a water lily can be in, and that is
    /// not luck.** An area is chosen from a plant's genus head and the head is
    /// its archetype's own root, so the two are one fact: `Areas.genusHeads`
    /// sends `Nyx` here and `Lir` to the Seedbed, and those are the lotus's
    /// two roots. Nothing else in the garden ever receives one. Until the
    /// tank was sunk, the 274 lilies in every 501 arrivals here were sown in
    /// dry compost, two places each, because a lily's pads are wider than one.
    ///
    /// It was sunk seven along the yard by three across, 0.62 m apart — the
    /// gap two places in a frame gave a lotus, and the gap its pads were
    /// measured against on 25 September. Twenty-one to a plot, until 29
    /// September 2026.
    ///
    /// **What it costs, measured rather than guessed**: five hundred arrivals
    /// now fill fourteen plots where they filled eighteen, because a lily no
    /// longer eats two places under glass. The frames are emptier for it —
    /// about sixteen dry plants to a plot against forty-eight places — and
    /// that is this area being mostly water rather than the rule failing.
    /// Fewer frames and smaller frames were both measured and both are worse:
    /// a frame holds one colour, so fewer frames strand more plots and smaller
    /// frames are claimed faster and never fill. That was measured with the
    /// water at about half of what arrives; at two in three it reverses.
    ///
    /// **A bigger tank, Marcus, 29 September 2026: thirty-nine places, and the
    /// front row of frames gives up its ground to it.** Since the re-roll the
    /// water takes 343 of every 501 arrivals here and the glass 158, and at
    /// twenty-one to a tank the water opened seventeen plots while the frames'
    /// plants were all standing in the first five — frames empty in twelve
    /// plots of seventeen. He asked for the two to fill in step. Measured on
    /// this area's own five hundred (`ColdFrameTests`), the frames alone need
    /// nine plots at two frames of twelve and five at four; the water fills
    /// nine plots at thirty-nine a tank, and would need about seventy to be
    /// in step with four frames, which is more water than a plot has ground.
    /// So the front row went and the tank took its ground: the water fills
    /// nine plots and the frames stand in all nine, where it was seventeen
    /// plots and frames in five. Each frame is as it was, two ranks of six
    /// under a pair of lights.
    ///
    /// **Six rows, seven and six in turn**, each row shifted half a place
    /// from the one behind it, 0.57 m apart. Two places a row apart are then
    /// `hypot(0.31, 0.57)`, 0.649 m, and two nudges pulling toward each other
    /// along that slant take up to 0.081 m off it, leaving 0.567 — no closer
    /// than two places 0.62 m apart along a row come, less the 0.06 m their
    /// nudges take. At 0.54 m the slant came 0.02 m closer than that, which
    /// `testNoTwoLiliesFloatCloserThanTheTankAllows` caught. Staggered rather than square
    /// because a square lattice of six rows would not fit in front of the
    /// frames, and because lilies in a grid read as a planting plan rather
    /// than as a pond. The tank lies across the yard in front of the frames,
    /// its middle `tankZ` toward the front.
    public static let tankAcross = 4.4
    public static let tankDeep = 3.16
    public static let tankZ = 0.6
    public static let tankGap = 0.62
    public static let tankRowGap = 0.57
    public static let tankWide = 7
    public static let tankRows = 6
    /// Seven in the rows at the back and every other row after it, six in the
    /// rows between: thirty-nine.
    public static let tankPlaces = (tankRows + 1) / 2 * tankWide + tankRows / 2 * (tankWide - 1)

    /// The frames a plant can be set in: **the back row, since 29 September
    /// 2026.** The front row's two stay in `Frame`, retired, so a planting
    /// filed in one before today still decodes and still draws where it was
    /// put until the replant places it again; nothing is placed in them now.
    public static let frames: [Frame] = [.backWest, .backEast]

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

    /// The four frames, in the order a plot opened them: the back row from
    /// west to east, then the front row. **Only the back row is opened since
    /// 29 September 2026** (`frames`); the front row's two are retired and
    /// keep their numbers. **The back row is `z−`**, which is
    /// the side of the plot furthest from the eye before the page is turned.
    /// **The tank is a fifth frame and not a frame**, for the reason
    /// `QuietGarden.Corner.pool` is a fifth corner: a slot stays one set of
    /// numbers in the table and on the wire, and appending it leaves every
    /// planting already filed decoding as it did.
    public enum Frame: Int, Codable, CaseIterable, Sendable {
        case backWest = 0, backEast, frontWest, frontEast, tank

        /// The middle of the frame, from the middle of the plot. The tank
        /// lies across the yard in front of the frames. A retired front frame
        /// keeps the place the formula gives it, which is in the water now:
        /// what stands there is waiting to be replanted.
        public var centre: Spot {
            if self == .tank { return Spot(x: 0, z: ColdFrame.tankZ) }
            return Spot(x: rawValue % 2 == 0 ? -ColdFrame.frameX : ColdFrame.frameX,
                        z: rawValue < 2 ? -ColdFrame.frameZ : ColdFrame.frameZ)
        }

        /// Whether plants that want dry compost are set here.
        public var isDry: Bool { self != .tank }

        /// How many places it holds: two ranks of six under a pair of lights,
        /// or thirty-nine in open water.
        public var places: Int { self == .tank ? ColdFrame.tankPlaces : ColdFrame.places }

        /// Where a place lies within it, from its own middle. **The tank's
        /// rows are not ranks** — water is flat and a lily has no view to be
        /// given, so every place in it is `.front` and the row comes out of
        /// the index instead: thirteen to each pair of rows, seven in the one
        /// behind and six in the one in front, shifted half a place.
        public func at(_ index: Int, rank: Rank) -> Spot {
            if self == .tank {
                let pair = 2 * ColdFrame.tankWide - 1
                let long = index % pair < ColdFrame.tankWide
                let row = 2 * (index / pair) + (long ? 0 : 1)
                let along = long ? index % pair : index % pair - ColdFrame.tankWide
                let wide = long ? ColdFrame.tankWide : ColdFrame.tankWide - 1
                return Spot(
                    x: (Double(along) - Double(wide - 1) / 2) * ColdFrame.tankGap,
                    z: (Double(row) - Double(ColdFrame.tankRows - 1) / 2) * ColdFrame.tankRowGap)
            }
            return Spot(x: (Double(index) - Double(ColdFrame.places - 1) / 2) * ColdFrame.alongGap,
                        z: rank == .back ? -ColdFrame.rankFrom : ColdFrame.rankFrom)
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
    /// median of 0.379 m, set at 0.38. Two ranks of six divide a frame in
    /// half, so the cut that divides the population in half is the one that
    /// lets the most plants have their own rank. It was 0.85 until the
    /// plants' shapes changed on 24 September 2026, measured the same way.
    ///
    /// **Measured over this area's plants rather than all of them**, which no
    /// earlier area needed to do. The Cold Frame's plants are shorter than the
    /// garden's — a quarter of all arrivals are under 0.55 m, and a quarter of
    /// these are under 0.32 m, because every one is a water lily's pads or a
    /// fern's young vase — so a cut borrowed from another area would divide
    /// them unevenly: the Orchard's 0.58 puts 12% of them at the back, the
    /// Long Walk's 0.77 puts 1%.
    ///
    /// **0.50 since the tank was sunk on 27 September 2026, up from 0.38.**
    /// The cut divides the plants that stand in the frames, and until the tank
    /// was sunk that was every arrival. It is now the 227 in every 501 that
    /// want dry compost, and they are the taller half: the 274 lilies were
    /// pulling the median down by 0.12 m. Left at 0.38 the cut put 81% of the
    /// frames' plants at the back, and it showed — the front ranks stood empty
    /// under the glass while the back ranks filled. 0.50 is the dry median and
    /// puts 50.2% at the back.
    ///
    /// **0.49 since 29 September 2026**, measured the same way after the
    /// re-roll of the 28th: the 158 of these five hundred that want dry
    /// compost — ferns, every one — stand at a median of 0.486 m.
    public static let backFrom = 0.49

    public static func rank(height: Double) -> Rank {
        height < backFrom ? .front : .back
    }

    // MARK: A lotus takes two places

    /// How many places along a rank a plant takes: **two for a lotus, one for
    /// everything else.** Marcus's choice on 25 September 2026.
    ///
    /// Since the plants' shapes changed on 24 September a lotus is a water
    /// lily, low and wide: drawn young here its pads reach a median 0.31 m
    /// from the stem (0.40 m at the ninetieth percentile), which is exactly the
    /// 0.31 m between places, and a quarter of the Cold Frame's plants stood
    /// with their stem inside a lotus's pads. A lotus standing centred across
    /// two places has 0.46 m either side of its stem to the next, and in the
    /// simulation made before this was chosen no stem stood inside a lotus's
    /// pads at all. It costs room: five hundred arrivals take eighteen plots
    /// where they took twelve.
    ///
    /// **The habit is read, not a width.** A habit is picked from the seed's
    /// bytes with no `sin` or `pow` in it, so the phone and the service agree
    /// about it exactly and this needs no tolerance. A plant whose habit was
    /// never sent is not a lotus, and takes one place.
    public static func span(of traits: PlantTraits) -> Int {
        traits.habit == Archetype.lotus.rawValue ? 2 : 1
    }

    /// The first place along a rank that nothing holds, given the plants
    /// standing in it. **A rank fills from its west end without a gap**, so
    /// this is the place after the furthest one held — and, for a rank of
    /// single places, how many stand in it, which is what it was before a
    /// lotus took two.
    static func next(along rank: [Planting]) -> Int {
        rank.map { $0.slot.index + $0.span }.max() ?? 0
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
            let centre = frame.centre, at = frame.at(index, rank: rank)
            return Spot(x: centre.x + at.x, z: centre.z + at.z)
        }
    }

    /// Every place in a plot, frame by frame, the front rank before the back.
    /// The frames in use and then the tank; a retired front frame has none.
    public static let slots: [Slot] = (frames + [.tank]).flatMap { frame in
        (frame.isDry ? Rank.allCases : [.front]).flatMap { rank in
            (0..<frame.places).map { Slot(frame: frame, rank: rank, index: $0) }
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
    /// That draws the five hundred between 0.05 and 0.34 m tall, and none of
    /// them under 0.15 m in whichever direction it has grown: the shortest are
    /// young water lilies, their pads lying on the soil 0.26 m and more across.
    /// Every one reads as a plant, and `ColdFrameTests` holds the tallest of
    /// each rank under the glass it stands beneath.
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
        /// The first place it holds, the west one of a lotus's two.
        public var slot: Slot
        /// How many places along the rank it holds, from `slot` eastward:
        /// `ColdFrame.span(of:)`, decided when it was planted and kept, as
        /// its place is. **Stored rather than read again off the traits**,
        /// because a planting made before 25 September holds one place
        /// whatever it is, and reads as holding one until the replant places
        /// it again.
        public var span: Int
        /// The plant's traits, **the grown height among them**. The young
        /// height it is drawn at is never stored: it is a matter of drawing,
        /// and nothing is decided by it.
        public var traits: PlantTraits
        /// A small offset from the place, from the seed: 0.03 m either way.
        /// Places along a rank are 0.31 m apart and a rank is meant to read as
        /// one, so this is the tightest nudge in the garden after the
        /// Seedbed's across a drill.
        public var nudge: Spot

        /// Where it stands: the middle of the places it holds, and its nudge.
        /// **A lotus stands centred across its two**, half a place east of
        /// its first. Worked out from a place counted in halves rather than
        /// as the first place's spot moved along, so a plant holding one
        /// place stands exactly where `Slot.spot` puts it, to the last bit.
        public var spot: Spot {
            let centre = slot.frame.centre
            let first = slot.frame.at(slot.index, rank: slot.rank)
            let last = slot.frame.at(slot.index + span - 1, rank: slot.rank)
            return Spot(x: centre.x + (first.x + last.x) / 2 + nudge.x,
                        z: centre.z + (first.z + last.z) / 2 + nudge.z)
        }

        /// Every place it holds, west to east.
        public var slots: [Slot] {
            (0..<span).map { Slot(frame: slot.frame, rank: slot.rank, index: slot.index + $0) }
        }

        public init(seed: String, plot: Int, slot: Slot, span: Int = 1, traits: PlantTraits, nudge: Spot) {
            self.seed = seed
            self.plot = plot
            self.slot = slot
            self.span = span
            self.traits = traits
            self.nudge = nudge
        }

        /// **A planting stored before 25 September has no span**, and holds
        /// one place: the one it was given, lotus or not.
        public init(from decoder: any Decoder) throws {
            let fields = try decoder.container(keyedBy: CodingKeys.self)
            seed = try fields.decode(String.self, forKey: .seed)
            plot = try fields.decode(Int.self, forKey: .plot)
            slot = try fields.decode(Slot.self, forKey: .slot)
            span = try fields.decodeIfPresent(Int.self, forKey: .span) ?? 1
            traits = try fields.decode(PlantTraits.self, forKey: .traits)
            nudge = try fields.decode(Spot.self, forKey: .nudge)
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
        ///
        /// **A lotus asks each rank for two places side by side** — the next
        /// two its rank would fill, from the west — and a rank with one place
        /// left has no room for it, so it goes on to the next choice as a
        /// plant finding a full rank does. That last place is not given up: a
        /// plant of one place can still take it. A frame nobody has claimed
        /// and a new plot always have two.
        public func place(for traits: PlantTraits) -> (plot: Int, slot: Slot) {
            // **What wants water goes in the tank, and nothing else does.**
            // The frames are sorted by colour and by height and a lily is
            // sorted by neither: it is in the water, which is where it has
            // belonged since its shape became a water lily's on 24 September.
            // The tank fills along its rows, the way a frame's rank does.
            if traits.wantsWater {
                for plot in 0..<plots {
                    let taken = Set(self.plot(plot).flatMap(\.slots))
                    if let free = ColdFrame.slots.first(where: {
                        !$0.frame.isDry && !taken.contains($0)
                    }) { return (plot, free) }
                }
                return (plots, Slot(frame: .tank, rank: .front, index: 0))
            }
            let own = ColdFrame.rank(height: traits.height)
            let span = ColdFrame.span(of: traits)
            let opened = plots
            let byPlot = (0..<opened).map { self.plot($0) }

            for plot in 0..<opened {
                for frame in ColdFrame.frames {
                    let here = byPlot[plot].filter { $0.slot.frame == frame }
                    guard here.first?.traits.family == traits.family else { continue }
                    for rank in [own, own == .back ? .front : .back] {
                        let next = ColdFrame.next(along: here.filter { $0.slot.rank == rank })
                        if next + span <= ColdFrame.places, inOrder(traits.height, in: rank, among: here) {
                            return (plot, Slot(frame: frame, rank: rank, index: next))
                        }
                    }
                }
            }
            for plot in 0..<opened {
                for frame in ColdFrame.frames
                    where !byPlot[plot].contains(where: { $0.slot.frame == frame }) {
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
            // **A lily in the tank holds one place.** The two it holds under
            // glass are 0.31 m apart and a lotus's pads need more than one of
            // them; the tank's are 0.62 m and were measured for a lily. The
            // span is a fact about the place as much as about the plant.
            let span = slot.frame.isDry ? ColdFrame.span(of: traits) : 1
            let planting = Planting(seed: seed.hex, plot: plot, slot: slot, span: span,
                                    traits: traits, nudge: Spot(x: jitter(26, 0.03), z: jitter(27, 0.03)))
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
