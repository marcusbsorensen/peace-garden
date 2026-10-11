import SwiftUI

/// **The loading animation: a fiddlehead grows upward while its curl lets go, and a
/// leaf opens at the top as it arrives.**
///
/// The gesture is the one `UnfurlingBackdrop` runs behind the seed-making screens
/// and `SproutingRule` runs at the ends of a rule — *the coil relaxes, the tip
/// travels because the curl lets go* — drawn once, alone, with a peace lily's
/// spathe on the end of it as the mark builds it. Marcus chose it on 10 October
/// 2026 and asked for two things on top of the first drawing:
///
/// - **Rising and unfurling overlap; they are not two steps.** It begins as a
///   small tight curl just emerging and over the moment the stem lengthens
///   upward while the crozier uncoils, so the leaf is opening at the top as the top
///   arrives (`pose(atMoment:)`, whose two beats share most of their length).
/// - **There is no ground.** The first drawing had a swell of soil under the stem
///   and Marcus took it out (10 October 2026): every plant in the app is 3D and
///   attached to a 3D ground, or 3D and floating in space (the main plant view),
///   or 2D with no soil below, and a drawn line matches none of them. The stem
///   grows from a fixed point in space with nothing beneath it, like the 2D
///   plants (`Placement`); a variant that entered from the screen's bottom edge
///   was drawn beside it and Marcus chose this one.
///
/// It is in the colours of the logo Marcus chose on 11 October 2026 (D-suite,
/// `design/logo-2026-10-11/`): its calm sage, moss and green-gold along the stem,
/// bottom to tip, and its warm white for the leaf. See `Palette`. The same day
/// the leaf was made to **finish lifted, up and a little outward**, as the
/// logo's tall frond carries its leaf, where on 10 October it ended hanging from
/// the hook (`Lift`, `Pose.lift`).
///
/// **It is not a seed sprouting, deliberately.** That was the obvious subject and
/// it is already the one performance this app has — `GerminationView`, six
/// seconds, once, on the day a seed is sown. The mark's own argument
/// (`docs/BRAND.md`, §3.5) is that the plant is what the app *gives* and not what
/// it is about; this is the medium the app works in, which is something opening.
enum Fiddlehead {

    /// How the stem leaves and curls. The field names are `Frond.Plan`'s, and the
    /// construction is `Frond.path(in:)`'s: the turn accumulates as a power of the
    /// distance travelled, so the base leaves almost straight and the coil lives at
    /// the far end.
    struct Plan {
        var length: Double
        var taper: Double
        var turnOpen: Double
        var turnFurled: Double
        var rootX: Double
        var rootY: Double
        var hand: Double
        var bract: Double
        /// How far the stem leans the other way on its way up, in radians, and
        /// comes back: a gentle S, so there is no stretch of it that is a ruler.
        var sway: Double
    }

    /// Drawn in a 100 × 130 frame and fitted to its own ink, so these are
    /// proportions and not sizes. **`taper` is 3.0 where the backdrop's is 5.5,
    /// and the stem sways.** At the backdrop's value the stem is a ruler for two
    /// thirds of its length, which is fine as a ghost the height of a screen and
    /// wrong for a mark: a straight stem is the one thing this app does not draw.
    /// At 3.0 the base was still within three degrees of straight for a third of
    /// its length, so it leans the other way a little on the way up and comes back
    /// (`LoadingTests.testNeitherDrawingHasAStraightRun`).
    static let plan = Plan(length: 0.82, taper: 3.0, turnOpen: 0.7, turnFurled: 2.7,
                           rootX: 0.68, rootY: 1.0, hand: -1, bract: 0.24, sway: 0.2)

    static let frame = CGSize(width: 100, height: 130)

    /// **How much of the stem is there at `rise == 0`**, as a share of its full
    /// length: enough that what first appears is a curl and not a dot. The whole
    /// stem is the same shape at every length — the turning is measured along it as
    /// a fraction of itself — so a short one is a small tight crozier and a long one
    /// is a large one, which is how a fiddlehead grows.
    static let emerging = 0.16

    /// **Where the stem goes once the leaf has lifted** — Marcus, 11 October 2026,
    /// with the logo's D-suite: its tall frond carries the leaf up and outward, and
    /// round one's leaf hanging head-down from a hook was rejected because a flower
    /// facing the ground looks sad. On 10 October this drawing ended exactly
    /// there, the leaf hanging from the hook at open 0.9.
    ///
    /// A second heading for the stem, which `figure(open:rise:lift:)` moves
    /// towards as `lift` goes from 0 to 1. It turns the same way round as the curl
    /// but only `turn` radians, so the tip ends pointing up and a little outward
    /// and the leaf, which leaves on the tip's tangent, points the same way. The
    /// whole stem `lean`s the leaf's way about its root, so the lifted plant
    /// stands over its root rather than off to one side of it.
    ///
    /// **`sway` is twice the plan's, and it has to be.** A stem that stands up is
    /// most of the way to a ruler, and at the plan's 0.2 the stretch where its
    /// lean turns into its curl turned 1.6° in a fifth of its length, which the
    /// straight-run test (2°) rightly fails. At 0.4 the gentlest fifth turns
    /// 2.4°. The sway keeps the plan's sign, so on the way from curled to lifted
    /// it never passes through zero and leaves the base straight for a frame.
    struct Lift {
        var turn: Double
        var taper: Double
        var sway: Double
        var lean: Double
    }

    static let lifted = Lift(turn: 0.2, taper: 3.0, sway: 0.4, lean: 0.25)

    /// What is drawn: the stem as a run of points and the bract as a closed outline.
    struct Figure {
        var stem: [CGPoint]
        var bract: [CGPoint]
    }

    /// The figure, in the 100 × 130 frame, with its root fixed where it leaves the
    /// ground.
    ///
    /// - Parameters:
    ///   - open: 0 (furled) to 1 (as open as the plan goes).
    ///   - rise: 0 (the tip just emerging) to 1 (fully grown). The arc
    ///     length changes with it, so unlike the backdrop's frond this one *does*
    ///     grow, and the root does not move.
    ///   - lift: 0 (the stem wherever the curl leaves it) to 1 (standing, the
    ///     leaf up and a little outward, `lifted`). The length does not change
    ///     with it; only where the stem heads.
    ///
    /// **The bract opens with the coil and not after it.** There it is a fixed
    /// shape parked on the tip, and when the coil is tight it lies across the curl
    /// as an outline drawn over an outline. Here it is a bud scaled about its mouth
    /// by `open`, so a furled frond carries a closed bud in its curl and an open one
    /// carries a leaf.
    static func figure(open: Double, rise: Double = 1, lift: Double = 0,
                       plan: Plan = Fiddlehead.plan, lifted: Lift = Fiddlehead.lifted) -> Figure {
        let held = min(max(open, 0), 1)
        let grown = emerging + (1 - emerging) * min(max(rise, 0), 1)
        let raised = min(max(lift, 0), 1)
        let steps = 130
        let turn = Double.pi * (plan.turnOpen + (plan.turnFurled - plan.turnOpen) * (1 - held))
        let length = frame.height * plan.length * grown
        let step = length / Double(steps)

        var point = CGPoint(x: frame.width * plan.rootX, y: frame.height * plan.rootY)
        var stem: [CGPoint] = [point]
        let base = -Double.pi / 2
        var heading = base
        for index in 1...steps {
            let s = Double(index) / Double(steps)
            heading = base + plan.hand * turn * pow(s, plan.taper) + plan.sway * sin(.pi * s)
            if raised > 0 {
                let standing = base + plan.hand * (lifted.lean + lifted.turn * pow(s, lifted.taper))
                    + lifted.sway * sin(.pi * s)
                heading += (standing - heading) * raised
            }
            point.x += cos(heading) * step
            point.y += sin(heading) * step
            stem.append(point)
        }

        // The spathe, leaving on the tangent the stem actually ends on and
        // continuing the same way round — the mark's own construction.
        let ribs = 20
        let bractLength = frame.height * plan.bract * grown
        let sweep = 0.34 * plan.hand
        var spine: [CGPoint] = [point]
        var tip = point
        for index in 1...ribs {
            let angle = heading + sweep * Double(index) / Double(ribs)
            tip.x += cos(angle) * bractLength / Double(ribs)
            tip.y += sin(angle) * bractLength / Double(ribs)
            spine.append(tip)
        }
        var near: [CGPoint] = []
        var far: [CGPoint] = []
        for index in 0...ribs {
            let s = Double(index) / Double(ribs)
            // The mark's construction, with the profile's exponent eased from
            // 0.60 to 0.85. At 0.60 the outline leaves its mouth almost square,
            // which the mark hides under the end of a coil 48 units wide; on a
            // hairline stem it showed as a flat cap on the leaf, and a flat cap
            // is a short straight line.
            let half = 0.30 * bractLength * sin(.pi * pow(s, 0.85))
            let j = min(index, ribs - 1)
            let angle = atan2(spine[j + 1].y - spine[j].y, spine[j + 1].x - spine[j].x)
            near.append(CGPoint(x: spine[index].x - sin(angle) * half,
                                y: spine[index].y + cos(angle) * half))
            far.append(CGPoint(x: spine[index].x + sin(angle) * half,
                               y: spine[index].y - cos(angle) * half))
        }
        // **A bud that grows, not a line that widens**: scaled about its mouth,
        // after the curl has begun to let go. Narrowing the outline alone leaves
        // the spine, and at zero width what is stroked is a bar the length of the
        // bract — the first version put a stick out of the coil.
        let bud = LoadingTiming.beat(held, 0.2...1.0)
        let outline = (near + far.reversed()).map {
            CGPoint(x: point.x + ($0.x - point.x) * bud, y: point.y + ($0.y - point.y) * bud)
        }
        return Figure(stem: stem, bract: outline)
    }

    /// The box the figure occupies over its whole travel — every rise and every
    /// opening, with the leaf where the curl leaves it — so the drawing is fitted
    /// to what it does and the mark does not drift as it grows. The root is the
    /// bottom of it. The waiting mark is fitted to this: it never lifts.
    static let travel: CGRect = bounds(of: (0...10).flatMap { rise in
        (0...10).map { open in Pose(open: Double(open) / 10, rise: Double(rise) / 10) }
    })

    /// **The launch moment's own travel**: every pose it passes through, at 240
    /// a moment, so twice the frames of a 120 Hz screen. It is its own box
    /// because the lifted plant stands taller than anything the waiting mark
    /// does, and fitting the waiting mark to it would shrink a 40 pt drawing
    /// for a pose it never takes.
    static let momentTravel: CGRect = bounds(of: (0...240).map { pose(atMoment: Double($0) / 240) })

    /// The box of the plant where the moment ends, which is what the hand-over
    /// finds and so what is centred across the screen.
    static let composedBounds: CGRect = bounds(of: [pose(atMoment: 1)])

    private static func bounds(of poses: [Pose]) -> CGRect {
        var minX = Double.infinity, minY = Double.infinity
        var maxX = -Double.infinity, maxY = -Double.infinity
        for pose in poses {
            let figure = figure(open: pose.open, rise: pose.rise, lift: pose.lift)
            for p in figure.stem + figure.bract {
                minX = min(minX, p.x); maxX = max(maxX, p.x)
                minY = min(minY, p.y); maxY = max(maxY, p.y)
            }
        }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    /// Where the stem leaves, in the 100 × 130 frame.
    static var rootPoint: CGPoint {
        CGPoint(x: frame.width * plan.rootX, y: frame.height * plan.rootY)
    }

    // MARK: - Where it is placed

    /// Where the 100 × 130 frame lands on the canvas: a scale and an origin.
    ///
    /// **A fixed point in space, with nothing beneath it**, like the app's 2D plants.
    /// Marcus chose it on 10 October 2026 over a stem that entered from the screen's
    /// bottom edge, which is a ground just off the screen, undrawn. The root is a
    /// point that does not move, and the stem lengthens upward from it.
    struct Placement: Equatable {
        var scale: CGFloat
        var origin: CGPoint

        func place(_ p: CGPoint) -> CGPoint {
            CGPoint(x: p.x * scale + origin.x, y: p.y * scale + origin.y)
        }

        /// The drawing's whole travel fitted to `size`, so the root is a fixed point
        /// and the grown plant fills the frame: centred top to bottom, and across on
        /// `fit.centre`, as far as the whole travel can stay inside the frame.
        static func fixedPoint(in size: CGSize, fit: Fit = .waiting, margin: CGFloat = 0.92) -> Placement {
            let box = fit.travel
            let scale = min(size.height * margin / box.height, size.width * margin / box.width)
            var x = size.width / 2 - fit.centre.midX * scale
            x = min(max(x, -box.minX * scale), size.width - box.maxX * scale)
            return Placement(scale: scale, origin: CGPoint(x: x, y: size.height / 2 - box.midY * scale))
        }
    }

    /// **What a drawing is fitted to, and what it centres across its frame.**
    ///
    /// The waiting mark is fitted to `travel` and centres it, as on 10 October.
    /// The launch moment is fitted to its own travel and centres the plant it
    /// ends on: the lifted plant stands over its root, while the hook it passes
    /// through on the way reaches out to the leaf's side, so centring the whole
    /// travel would leave the plant the hand-over finds off to one side.
    struct Fit: Equatable {
        var travel: CGRect
        var centre: CGRect

        static let waiting = Fit(travel: Fiddlehead.travel, centre: Fiddlehead.travel)
        static let moment = Fit(travel: Fiddlehead.momentTravel, centre: Fiddlehead.composedBounds)
    }

    // MARK: - Poses

    struct Pose: Equatable {
        var open: Double
        var rise: Double
        var appear: Double = 1
        /// 0, the leaf where the curl leaves it, to 1, lifted (`Lift`).
        var lift: Double = 0
    }

    /// **How far the curl itself lets go: open 0.9, not 1.** Past about 0.9 the
    /// coil has let go entirely and what is left reads as a stray hook;
    /// `SproutingRule` stops short of full for the same reason. On 10 October
    /// this was where the moment ended, the leaf hanging from that hook; since 11
    /// October the lift carries the stem on from it to standing.
    static let composed = 0.9

    /// **When the leaf lifts: from 40 % of the moment to 98 %**, the second half
    /// of the gesture and not a step after it. It starts while the curl is still
    /// letting go, so the tip that the uncoiling carries round keeps travelling
    /// the same way until it points up, and it ends with the other beats, eased
    /// to a standstill (smoothstep), so it settles and does not bounce. The last
    /// 40 ms are still.
    static let liftBeat = 0.4...0.98

    /// The launch moment at `t`, 0…1 across `LoadingTiming.moment`.
    ///
    /// **Rising and opening share almost all of their length**: the stem is
    /// growing from the first beat to the last and the curl is letting go from
    /// just after the first, so there is no moment at which one has finished and
    /// the other is about to start. The lift overlaps the second half of both.
    static func pose(atMoment t: Double) -> Pose {
        Pose(open: composed * LoadingTiming.beat(t, 0.06...0.96),
             rise: LoadingTiming.beat(t, 0.02...0.94),
             appear: LoadingTiming.beat(t, 0...0.08),
             lift: LoadingTiming.beat(t, liftBeat))
    }

    /// **The waiting form: a smaller version of the same thing.** The tip comes
    /// up, uncurls a little and settles back, and never rises far or opens far —
    /// the tightest it gets is still a curl and the highest it gets is still
    /// short.
    static func pose(atBreath phase: Double) -> Pose {
        pose(openness: LoadingTiming.openness(atBreath: phase))
    }

    static func pose(openness: Double) -> Pose {
        Pose(open: 0.15 + 0.55 * openness, rise: 0.42 + 0.4 * openness)
    }

    /// **Where it rests when motion is off** — a tendril half open, which is
    /// `design/Motion.dc.html`'s own sentence for Reduce Motion, and standing.
    static let still = Pose(open: 0.7, rise: 0.8)

    // MARK: - Colour

    /// **The logo's colours, and what they are measured against.**
    ///
    /// The stem carries the chosen logo's three stops bottom to tip — sage
    /// `#9CC29E`, moss `#9DC386`, green-gold `#A9C263`, 123° → 76°, saturation
    /// 0.24 → 0.44, isoluminant at 9.7:1 on the suite's ground — and the leaf is
    /// its warm white, `#F4F3EF`, 17.3:1 (`design/logo-2026-10-11/README.md`
    /// §3 and §6, D-suite, chosen by Marcus on 11 October 2026). On 10 October
    /// these were the old icon's neon greens, 13:1, and its pure white bract.
    ///
    /// **Two palettes, because the contrast is a property of the ground.** The
    /// launch moment is always on `#0D0D1F`, in both appearances, so it takes the
    /// logo's own values. The waiting mark sits inside the app's screens and
    /// follows the app's appearance, and on the light ground the logo's
    /// green-gold is 1.8:1, which is a mark nobody can see. So on light it takes
    /// the logo's own light-ground version: the same three hues darkened to 4.6:1
    /// on `#F6F6F6`, which is `lightGround`, and the leaf, which cannot be warm
    /// white on near-white, is the app's ink.
    ///
    /// **The halo is 0.04, lowered from 0.07.** It is a flat band ten points wide,
    /// not a blur, and in the old neon green at 0.07 that band read as a glow.
    /// In the pale sage at 0.07 it reads as a grey casing round the line, a
    /// second edge; at 0.04 it is half as far from the ground (about six levels
    /// in each channel) and stays a softness the line sits in, which is what the
    /// pass is for (`design/loading-2026-10-11/option-halo.png`, which shows
    /// 0.07, 0.04 and none).
    struct Palette: Sendable {
        struct RGB: Sendable, Equatable {
            var r: Double, g: Double, b: Double

            init(_ r: Double, _ g: Double, _ b: Double) {
                self.r = r; self.g = g; self.b = b
            }

            init(hex: UInt32) {
                self.init(Double((hex >> 16) & 0xFF) / 255, Double((hex >> 8) & 0xFF) / 255,
                          Double(hex & 0xFF) / 255)
            }

            var color: Color { Color(.sRGB, red: r, green: g, blue: b, opacity: 1) }

            /// WCAG relative luminance.
            var luminance: Double {
                func channel(_ v: Double) -> Double {
                    v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
                }
                return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
            }

            /// WCAG contrast ratio against `other`.
            func contrast(with other: RGB) -> Double {
                let a = luminance, b = other.luminance
                return (max(a, b) + 0.05) / (min(a, b) + 0.05)
            }
        }

        /// Root to tip, evenly spaced.
        var stem: [RGB]
        var leaf: RGB
        /// The wide faint pass the stem sits in, as the backdrop gives its hairline
        /// something to sit in. Zero for the small form, where it only blurs.
        var halo: Double

        /// The suite's ground, `#0D0D1F`, which `Assets.xcassets/LaunchGround` is
        /// and which the launch screen paints. The moment is drawn on it in both
        /// appearances.
        static let launchGround = RGB(hex: 0x0D0D1F)
        /// `Chrome.ground` in the light appearance: white 0.965.
        static let lightGround = RGB(0.965, 0.965, 0.965)
        /// `Chrome.ink` in the light appearance: white 0.07.
        static let lightInk = RGB(0.07, 0.07, 0.07)

        /// On the dark ground — the launch moment, and the waiting mark in the
        /// dark appearance, where the app's ground is black and every one of
        /// these is further from it than from `#0D0D1F`.
        static let onDark = Palette(
            stem: [RGB(hex: 0x9CC29E), RGB(hex: 0x9DC386), RGB(hex: 0xA9C263)],
            leaf: RGB(hex: 0xF4F3EF),
            halo: 0.04)

        /// On the light ground: the logo's light-ground stops, 4.6:1, and the
        /// app's ink.
        static let onLight = Palette(
            stem: [RGB(hex: 0x397E3D), RGB(hex: 0x467D25), RGB(hex: 0x60781E)],
            leaf: lightInk,
            halo: 0)

        /// The same two with the halo taken off, for the small form.
        var small: Palette {
            var copy = self
            copy.halo = 0
            return copy
        }
    }

    // MARK: - The two open choices

    /// **The two things Marcus has still to choose, 11 October 2026**, each a
    /// launch argument (`LoadingSwitch`) that defaults to the recommendation.
    ///
    /// - `stem`: the logo's coil thins as it spirals in and its stem thins a
    ///   little towards the leaf, so the leaf reads chunkier. `tapered` is a
    ///   gentle version of that here, root to tip; `even` is 10 October's
    ///   hairline.
    /// - `leaf`: the logo's leaf is a stroked outline, and so is this one;
    ///   `filled` fills it, for the case where an outline closes up small.
    struct Style: Equatable, Sendable {
        var stem: LoadingStem
        var leaf: LoadingLeaf

        /// The recommendation, which is what the app draws unless a launch
        /// argument says otherwise.
        static let standard = Style(stem: LoadingSwitch.stemFallback, leaf: LoadingSwitch.leafFallback)

        /// **The tapered stem ends at 0.6 of its root's width.** Gentle on
        /// purpose: at the launch moment's 1.8 pt the tip is 1.1 pt, and at the
        /// waiting mark's 1.5 pt it is 0.9 pt, three pixels on a 3× screen,
        /// which is as fine as a line can go there and still be a line.
        static let taperedTip: CGFloat = 0.6

        /// The stem's width at its tip as a share of its width at the root.
        var tipShare: CGFloat { stem == .tapered ? Self.taperedTip : 1 }
    }

    // MARK: - Drawing

    /// - Parameters:
    ///   - weight: the hairline, in points: the stem's width at its root.
    ///   - halo: width of the faint pass under it, in points. Ignored when the
    ///     palette's `halo` is zero.
    ///   - style: the two open choices (`Style`).
    ///   - fit: what the drawing is fitted to: the moment's travel or the
    ///     waiting mark's.
    static func draw(_ pose: Pose, palette: Palette, weight: CGFloat, halo: CGFloat,
                     style: Style = .standard, fit: Fit = .waiting,
                     in context: inout GraphicsContext, size: CGSize) {
        let placement = Placement.fixedPoint(in: size, fit: fit)
        func path(_ points: [CGPoint], closed: Bool) -> Path {
            var path = Path()
            guard let first = points.first else { return path }
            path.move(to: placement.place(first))
            for p in points.dropFirst() { path.addLine(to: placement.place(p)) }
            if closed { path.closeSubpath() }
            return path
        }

        let figure = Fiddlehead.figure(open: pose.open, rise: pose.rise, lift: pose.lift)
        let stem = path(figure.stem, closed: false)
        let bract = path(figure.bract, closed: true)

        context.opacity = pose.appear

        // The stem's colour runs bottom to tip along the height it can reach, so a
        // short stem is the sage end of it and a grown one reaches the green-gold.
        let ramp = Gradient(stops: palette.stem.enumerated().map { index, rgb in
            Gradient.Stop(color: rgb.color, location: Double(index) / Double(palette.stem.count - 1))
        })
        let root = placement.place(rootPoint)
        let top = placement.place(CGPoint(x: rootPoint.x, y: fit.travel.minY))
        let shading = GraphicsContext.Shading.linearGradient(ramp, startPoint: root, endPoint: top)

        if palette.halo > 0, halo > 0 {
            let style = StrokeStyle(lineWidth: halo, lineCap: .round, lineJoin: .round)
            let glow = palette.stem[palette.stem.count / 2].color.opacity(palette.halo)
            context.stroke(stem, with: .color(glow), style: style)
            context.stroke(bract, with: .color(glow), style: style)
        }
        let line = StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round)
        if style.tipShare < 1 {
            context.fill(ribbon(figure.stem.map(placement.place), from: weight, to: weight * style.tipShare),
                         with: shading)
        } else {
            context.stroke(stem, with: shading, style: line)
        }
        if style.leaf == .filled {
            context.fill(bract, with: .color(palette.leaf.color))
        }
        context.stroke(bract, with: .color(palette.leaf.color), style: line)
    }

    /// **A stroke whose weight changes along it**: the stem as one filled outline,
    /// `start` wide at the root and `end` wide at the tip, with round ends, so
    /// it is one shape and one fill and nothing is drawn over itself. Each side
    /// is the stem's own points moved out along the normal by half the width
    /// there, which is the construction the leaf's outline already uses.
    static func ribbon(_ points: [CGPoint], from start: CGFloat, to end: CGFloat) -> Path {
        var path = Path()
        guard points.count > 1 else { return path }
        let last = points.count - 1
        var left: [CGPoint] = []
        var right: [CGPoint] = []
        var headings: [Double] = []
        for index in 0...last {
            let a = points[max(index - 1, 0)], b = points[min(index + 1, last)]
            let heading = atan2(Double(b.y - a.y), Double(b.x - a.x))
            let half = Double(start + (end - start) * CGFloat(index) / CGFloat(last)) / 2
            left.append(CGPoint(x: points[index].x - sin(heading) * half, y: points[index].y + cos(heading) * half))
            right.append(CGPoint(x: points[index].x + sin(heading) * half, y: points[index].y - cos(heading) * half))
            headings.append(heading)
        }
        // Half a turn of a circle about `centre`, from `angle` round through the
        // way the stem is leaving: the round end, as points.
        func cap(_ centre: CGPoint, _ radius: Double, from angle: Double) -> [CGPoint] {
            (1..<12).map { k in
                let a = angle - .pi * Double(k) / 12
                return CGPoint(x: centre.x + cos(a) * radius, y: centre.y + sin(a) * radius)
            }
        }
        let outline = left
            + cap(points[last], Double(end) / 2, from: headings[last] + .pi / 2)
            + right.reversed()
            + cap(points[0], Double(start) / 2, from: headings[0] - .pi / 2)
        path.move(to: outline[0])
        for p in outline.dropFirst() { path.addLine(to: p) }
        path.closeSubpath()
        return path
    }
}

/// The fiddlehead, at a pose, in a frame. A still picture: whatever is moving it is
/// the caller's, which is what lets a test draw frame 17 of 60 without waiting.
struct FiddleheadView: View {
    let pose: Fiddlehead.Pose
    var palette: Fiddlehead.Palette
    var weight: CGFloat = 1.8
    var halo: CGFloat = 10
    var style: Fiddlehead.Style = .standard
    var fit: Fiddlehead.Fit = .waiting

    var body: some View {
        Canvas { context, size in
            Fiddlehead.draw(pose, palette: palette, weight: weight, halo: halo, style: style, fit: fit,
                            in: &context, size: size)
        }
        .accessibilityHidden(true)
    }
}
