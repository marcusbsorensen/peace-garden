#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

/// **Which way round a plot is laid**: turned, mirrored, and which of its
/// area's feature variants it takes, chosen from the plot's number.
///
/// At a thousand arrivals an area is twenty to a hundred plots, and a plot
/// laid the same way round as its neighbour reads as a stamp. Marcus chose on
/// 2 October 2026 to vary each plot from its number in every area but the
/// Knot Garden and the Glasshouse (`design/garden-layouts-2026-10-02/RESEARCH.md`
/// §*Three moves for every area*, 2): a knot is a pattern made to be the same
/// every time, and a colour wheel has one way round.
///
/// **A variant moves places, never counts.** A rule still chooses a slot by
/// its index in the area's table; the variant says where on the ground that
/// slot is drawn. Turning and mirroring are exact in floating point (a sign
/// and a swap), so a turned place is the same number on every host. Which
/// feature variant a plot takes picks one of the area's tables made offline
/// (`tools/layouts`), so nothing about it is computed at run time either.
///
/// **An area opts in by declaring its `Space`** in its own file
/// (`Coppice.variants`, `KnotGarden.variants`), so ten areas can each change
/// their own without touching a shared list. `Server/.api/PlotVariant.php` and
/// `Server/assets/js/variant.js` are the ports, held to this by
/// `tools/reference/plot_variant_vectors.json`.
public struct PlotVariant: Codable, Equatable, Hashable, Sendable {

    /// Quarter turns about the plot's middle, 0...3. **A quarter turn takes
    /// `x+` to `z+`**, the way `Organic.outline` runs round a plot.
    public var turn: Int
    /// Mirrored across the plot's `z` axis, `x` to `−x`, before the turn.
    public var mirror: Bool
    /// Which of the area's feature variants the plot takes, `0..<nudges`: a
    /// glade moved, a tree nudged, a curve bent the other way. What it means
    /// is the area's; here it is only a number.
    public var nudge: Int

    public init(turn: Int, mirror: Bool, nudge: Int) {
        self.turn = turn
        self.mirror = mirror
        self.nudge = nudge
    }

    /// The plot as its area's tables draw it: not turned, not mirrored, the
    /// first feature variant. **Every area's plot 0 is laid this way**, so the
    /// plot an area opens with is the plan as it was drawn.
    public static let plain = PlotVariant(turn: 0, mirror: false, nudge: 0)

    // MARK: What an area allows

    /// The variants an area allows: how many ways it may be turned, whether it
    /// may be mirrored, and how many feature variants its tables have.
    ///
    /// - `turns` is 1, 2 or 4. Two is a half turn and no quarter, for a plot
    ///   whose layout runs one way across the page, as the Long Walk's path
    ///   runs down it; with `mirror` that is four ways, each keeping the path
    ///   where it was.
    /// - `nudges` is the number of feature tables, at least one.
    public struct Space: Codable, Equatable, Hashable, Sendable {
        public var turns: Int
        public var mirror: Bool
        public var nudges: Int

        public init(turns: Int = 1, mirror: Bool = false, nudges: Int = 1) {
            precondition([1, 2, 4].contains(turns), "a plot turns one, two or four ways")
            precondition(nudges >= 1, "an area has at least one feature table")
            self.turns = turns
            self.mirror = mirror
            self.nudges = nudges
        }

        /// **Laid the same way every time**: the Knot Garden's and the
        /// Glasshouse's.
        public static let fixed = Space()

        /// How many variants there are.
        public var count: Int { turns * (mirror ? 2 : 1) * nudges }

        /// Whether plots of this area differ at all.
        public var varies: Bool { count > 1 }

        /// The `n`-th variant, `0..<count`: the turn changing fastest, then the
        /// mirror, then the feature variant. Variant 0 is `plain`.
        public func variant(_ n: Int) -> PlotVariant {
            let mirrors = mirror ? 2 : 1
            return PlotVariant(turn: (n % turns) * (4 / turns),
                               mirror: (n / turns) % mirrors == 1,
                               nudge: n / (turns * mirrors))
        }
    }

    // MARK: Which variant a plot takes

    /// **The variant of plot `plot` of `area`**, from the space the area
    /// declares.
    public static func of(plot: Int, area: Area) -> PlotVariant {
        of(plot: plot, salt: salt(of: area), in: area.plotVariants)
    }

    /// **The variant of a plot, from its number.** Deterministic, the same on
    /// every host, and integers only.
    ///
    /// The plots are dealt in blocks of `count`, each block a shuffle of every
    /// variant the space allows, so:
    ///
    /// - **every block of `count` plots holds every variant once**, and the
    ///   area shows all its variants in as few plots as it can;
    /// - **no plot is laid as the plot before it**: where a block would begin
    ///   with the variant the last one ended on, its first two change places;
    /// - **plot 0 is `plain`**, the plan as drawn;
    /// - a space of two **alternates**, plot by plot, which is what the Home
    ///   Ground's bow was asked to do.
    ///
    /// `salt` keeps two areas with the same space from turning in step: it is
    /// `salt(of:)` of the area's name.
    public static func of(plot: Int, salt: UInt32, in space: Space) -> PlotVariant {
        let count = space.count
        guard count > 1, plot > 0 else { return space.variant(0) }
        if count == 2 { return space.variant(plot % 2) }
        return space.variant(deck(plot / count, count: count, salt: salt)[plot % count])
    }

    /// A block's shuffle, with plot 0 brought to the front of the first block
    /// and no block beginning on the variant the one before it ended on. For
    /// three or more variants the swap touches only the first two places, so
    /// a block's last is its shuffle's last, and no block needs any but the
    /// one before it.
    static func deck(_ block: Int, count: Int, salt: UInt32) -> [Int] {
        var deck = shuffle(block, count: count, salt: salt)
        if block == 0 {
            let plain = deck.firstIndex(of: 0)!
            deck.swapAt(0, plain)
        } else {
            let before = block == 1
                ? Self.deck(0, count: count, salt: salt)[count - 1]
                : shuffle(block - 1, count: count, salt: salt)[count - 1]
            if deck[0] == before { deck.swapAt(0, 1) }
        }
        return deck
    }

    /// Fisher and Yates's shuffle of `0..<count`, drawn from the block's
    /// number and the salt.
    static func shuffle(_ block: Int, count: Int, salt: UInt32) -> [Int] {
        var deck = Array(0..<count)
        let start = mix32(mix32(salt) ^ UInt32(truncatingIfNeeded: block))
        var i = count - 1
        while i > 0 {
            let j = Int(mix32(start ^ UInt32(truncatingIfNeeded: i)) % UInt32(i + 1))
            deck.swapAt(i, j)
            i -= 1
        }
        return deck
    }

    /// **An area's salt: FNV-1a over its name**, `travel`, `renewal`, as the
    /// service stores it.
    public static func salt(of area: Area) -> UInt32 {
        var hash: UInt32 = 0x811C_9DC5
        for byte in area.rawValue.utf8 {
            hash ^= UInt32(byte)
            hash = hash &* 0x0100_0193
        }
        return hash
    }

    /// Chris Wellons's `lowbias32`. Thirty-two bits rather than `mix64`'s
    /// sixty-four because the PHP port has to multiply without overflowing
    /// into a float, and does it in two halves (`PlotVariant::mul32`).
    static func mix32(_ input: UInt32) -> UInt32 {
        var x = input
        x ^= x >> 16
        x = x &* 0x7FEB_352D
        x ^= x >> 15
        x = x &* 0x846C_A68B
        x ^= x >> 16
        return x
    }

    // MARK: Where a place is drawn

    /// **Where a place in the area's table stands on this plot**: mirrored,
    /// then turned, about the plot's middle. Exact: only signs change and the
    /// axes swap, so every host draws it at the same number. A direction —
    /// which way a bench faces — turns the same way.
    ///
    /// `0 - x` rather than `-x`, so that a place on an axis stays at `+0`
    /// rather than becoming `−0`, which prints differently in a vector file.
    public func apply(_ spot: Spot) -> Spot {
        let x = mirror ? 0 - spot.x : spot.x
        let z = spot.z
        switch turn & 3 {
        case 0: return Spot(x: x, z: z)
        case 1: return Spot(x: 0 - z, z: x)
        case 2: return Spot(x: 0 - x, z: 0 - z)
        default: return Spot(x: z, z: 0 - x)
        }
    }

    /// The other way: where a point on this plot is in the area's table, for
    /// reading something on the ground back to its place.
    public func undo(_ spot: Spot) -> Spot {
        let back = PlotVariant(turn: (4 - (turn & 3)) & 3, mirror: false, nudge: nudge).apply(spot)
        return mirror ? Spot(x: 0 - back.x, z: back.z) : back
    }
}

// MARK: Each area's space

extension Area {
    /// **The variants this area allows**, as the area declares them in its
    /// own file. All but the Knot Garden and the Glasshouse vary (Marcus, 2
    /// October 2026).
    public var plotVariants: PlotVariant.Space {
        switch self {
        case .travel: return LongWalk.variants
        case .peace: return QuietGarden.variants
        case .meeting: return Crossing.variants
        case .kinship: return Orchard.variants
        case .pattern: return KnotGarden.variants
        case .beginnings: return Seedbed.variants
        case .waiting: return ColdFrame.variants
        case .light: return Glasshouse.variants
        case .renewal: return Coppice.variants
        case .ground: return HomeGround.variants
        }
    }
}
