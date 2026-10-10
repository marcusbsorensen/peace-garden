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
///   or 2D with no soil below, and a drawn line matches none of them. What
///   replaces it is a choice of two anchors (`Anchor`), both with nothing under
///   the stem.
///
/// It is in the app's own colours: the icon's greens along the stem, bottom to
/// tip, and the icon's white bract for the leaf. See `Palette`.
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
    ///
    /// **The bract opens with the coil and not after it.** There it is a fixed
    /// shape parked on the tip, and when the coil is tight it lies across the curl
    /// as an outline drawn over an outline. Here it is a bud scaled about its mouth
    /// by `open`, so a furled frond carries a closed bud in its curl and an open one
    /// carries a leaf.
    static func figure(open: Double, rise: Double = 1, plan: Plan = Fiddlehead.plan) -> Figure {
        let held = min(max(open, 0), 1)
        let grown = emerging + (1 - emerging) * min(max(rise, 0), 1)
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
    /// opening — so the drawing is fitted to what it does and the mark does not
    /// drift as it grows. The root is the bottom of it.
    static let travel: CGRect = {
        var minX = Double.infinity, minY = Double.infinity
        var maxX = -Double.infinity, maxY = -Double.infinity
        for rise in 0...10 {
            for open in 0...10 {
                let figure = figure(open: Double(open) / 10, rise: Double(rise) / 10)
                for p in figure.stem + figure.bract {
                    minX = min(minX, p.x); maxX = max(maxX, p.x)
                    minY = min(minY, p.y); maxY = max(maxY, p.y)
                }
            }
        }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }()

    /// Where the stem leaves, in the 100 × 130 frame.
    static var rootPoint: CGPoint {
        CGPoint(x: frame.width * plan.rootX, y: frame.height * plan.rootY)
    }

    // MARK: - Where it is anchored

    /// **What the stem grows from, now that there is no ground.** Marcus's note of
    /// 10 October 2026 offered two, and both are kept behind the style switch until
    /// he picks.
    enum Anchor: Sendable {
        /// *The stem enters from the very bottom edge of the screen* and grows
        /// upward as it unfurls. The screen edge is the only ground, and nothing is
        /// drawn there. The root is below the edge, so that the curl that begins
        /// the moment is just out of sight and rises into view through it.
        case bottomEdge
        /// *A fixed point in space, with nothing beneath it*, like the app's 2D
        /// plants. The root is a point that does not move, placed so that the grown
        /// plant is centred in its frame, and the stem lengthens upward from it.
        case fixedPoint
    }

    /// Where the 100 × 130 frame lands on the canvas: a scale and an origin.
    struct Placement: Equatable {
        var scale: CGFloat
        var origin: CGPoint

        func place(_ p: CGPoint) -> CGPoint {
            CGPoint(x: p.x * scale + origin.x, y: p.y * scale + origin.y)
        }

        /// The drawing's whole travel — every rising and every opening — centred in
        /// `size`, so the root is a fixed point and the grown plant fills the frame.
        static func fixedPoint(in size: CGSize, margin: CGFloat = 0.92) -> Placement {
            let box = Fiddlehead.travel
            let scale = min(size.height * margin / box.height, size.width * margin / box.width)
            return Placement(scale: scale, origin: CGPoint(x: size.width / 2 - box.midX * scale,
                                                           y: size.height / 2 - box.midY * scale))
        }

        /// The whole screen, with the root below its bottom edge by exactly the height
        /// the curl has when it begins, so at the first moment the tip is at the edge
        /// and nothing is on the screen. The grown plant is centred across, and is as
        /// wide as 86 % of the screen or as tall as 95 % of it, whichever comes first
        /// — on a phone, the width: the plant ends about half way up the screen.
        static func bottomEdge(in size: CGSize) -> Placement {
            let box = Fiddlehead.travel
            let scale = min(size.height * 0.95 / box.height, size.width * 0.86 / box.width)
            let root = Fiddlehead.rootPoint
            let first = Fiddlehead.figure(open: 0, rise: 0)
            let tip = (first.stem + first.bract).map(\.y).min() ?? root.y
            let entry = CGFloat(root.y - tip) * scale
            return Placement(scale: scale, origin: CGPoint(x: size.width / 2 - box.midX * scale,
                                                           y: size.height + entry - root.y * scale))
        }

        static func make(_ anchor: Anchor, in size: CGSize) -> Placement {
            switch anchor {
            case .bottomEdge: return bottomEdge(in: size)
            case .fixedPoint: return fixedPoint(in: size)
            }
        }
    }

    // MARK: - Poses

    struct Pose: Equatable {
        var open: Double
        var rise: Double
        var appear: Double = 1
    }

    /// **Where the moment ends: open 0.9, not 1.** Past about 0.9 the coil has let
    /// go entirely and what is left reads as a stray hook; `SproutingRule` stops
    /// short of full for the same reason. It is the composed state, and it is
    /// where the hand-over finds it.
    static let composed = 0.9

    /// The launch moment at `t`, 0…1 across `LoadingTiming.moment`.
    ///
    /// **Rising and opening share almost all of their length**: the stem is
    /// growing from the first beat to the last and the curl is letting go from
    /// just after the first, so there is no moment at which one has finished and
    /// the other is about to start.
    static func pose(atMoment t: Double) -> Pose {
        Pose(open: composed * LoadingTiming.beat(t, 0.06...0.96),
             rise: LoadingTiming.beat(t, 0.02...0.94),
             appear: LoadingTiming.beat(t, 0...0.08))
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

    /// **The app's own colours, and what they are measured against.**
    ///
    /// The stem carries the icon's three greens bottom to tip — forest green,
    /// lime, yellow, 140° → 60°, isoluminant, 13.00:1 on the suite's ground
    /// (`docs/BRAND.md`, `tools/icon/make_icon.py`) — and the leaf is the icon's
    /// white bract. Marcus asked for this on 10 October 2026 in place of the gold
    /// the first drawing used.
    ///
    /// **Two palettes, because the contrast is a property of the ground.** The
    /// launch moment is always on `#0D0D1F`, in both appearances, so it takes the
    /// icon's own values. The waiting mark sits inside the app's screens and
    /// follows the app's appearance, and on the light ground the icon's yellow is
    /// 1.4:1, which is a mark nobody can see. So on light the same three hues are
    /// solved to 4.5:1 against the ground, by the script's own method
    /// (`stop_at`: lightness solved per hue at its saturation, not chosen) — which
    /// takes the yellow to an olive, the cost the script's own notes record at
    /// 9.1:1 — and the leaf, which cannot be white on near-white, is the app's ink.
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
            stem: [RGB(hex: 0x06F556), RGB(hex: 0x55F306), RGB(hex: 0xDCDC06)],
            leaf: RGB(1, 1, 1),
            halo: 0.07)

        /// On the light ground: the icon's hues at 4.5:1, and the app's ink.
        static let onLight = Palette(
            stem: [RGB(hex: 0x03842E), RGB(hex: 0x2E8203), RGB(hex: 0x757503)],
            leaf: lightInk,
            halo: 0)

        /// The same two with the halo taken off, for the small form.
        var small: Palette {
            var copy = self
            copy.halo = 0
            return copy
        }
    }

    // MARK: - Drawing

    /// - Parameters:
    ///   - weight: the hairline, in points.
    ///   - halo: width of the faint pass under it, in points. Ignored when the
    ///     palette's `halo` is zero.
    ///   - anchor: what the stem grows from. See `Anchor`.
    static func draw(_ pose: Pose, palette: Palette, weight: CGFloat, halo: CGFloat, anchor: Anchor,
                     in context: inout GraphicsContext, size: CGSize) {
        let placement = Placement.make(anchor, in: size)
        func path(_ points: [CGPoint], closed: Bool) -> Path {
            var path = Path()
            guard let first = points.first else { return path }
            path.move(to: placement.place(first))
            for p in points.dropFirst() { path.addLine(to: placement.place(p)) }
            if closed { path.closeSubpath() }
            return path
        }

        let figure = Fiddlehead.figure(open: pose.open, rise: pose.rise)
        let stem = path(figure.stem, closed: false)
        let bract = path(figure.bract, closed: true)

        context.opacity = pose.appear

        // The stem's colour runs bottom to tip along the height it can reach, so a
        // short stem is the green end of it and a grown one reaches the yellow.
        let ramp = Gradient(stops: palette.stem.enumerated().map { index, rgb in
            Gradient.Stop(color: rgb.color, location: Double(index) / Double(palette.stem.count - 1))
        })
        let root = placement.place(rootPoint)
        let top = placement.place(CGPoint(x: rootPoint.x, y: travel.minY))

        if palette.halo > 0, halo > 0 {
            let style = StrokeStyle(lineWidth: halo, lineCap: .round, lineJoin: .round)
            let glow = palette.stem[palette.stem.count / 2].color.opacity(palette.halo)
            context.stroke(stem, with: .color(glow), style: style)
            context.stroke(bract, with: .color(glow), style: style)
        }
        let style = StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round)
        context.stroke(stem, with: .linearGradient(ramp, startPoint: root, endPoint: top), style: style)
        context.stroke(bract, with: .color(palette.leaf.color), style: style)
    }
}

/// The fiddlehead, at a pose, in a frame. A still picture: whatever is moving it is
/// the caller's, which is what lets a test draw frame 17 of 60 without waiting.
struct FiddleheadView: View {
    let pose: Fiddlehead.Pose
    var palette: Fiddlehead.Palette
    var weight: CGFloat = 1.8
    var halo: CGFloat = 10
    var anchor: Fiddlehead.Anchor = .fixedPoint

    var body: some View {
        Canvas { context, size in
            Fiddlehead.draw(pose, palette: palette, weight: weight, halo: halo, anchor: anchor,
                            in: &context, size: size)
        }
        .accessibilityHidden(true)
    }
}
