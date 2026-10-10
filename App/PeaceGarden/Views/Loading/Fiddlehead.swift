import SwiftUI

/// **Variant B, drawn: the garden's own fiddlehead lets go of its curl and a leaf
/// opens at the tip.**
///
/// Where `UnwindingMark` is the suite's pattern in the app's brand, this is the
/// app's own idiom with the suite's manners. The gesture is the one
/// `UnfurlingBackdrop` runs behind the seed-making screens and `SproutingRule`
/// runs at the ends of a rule — *the coil relaxes, the arc length does not
/// change, the tip travels because the curl lets go* — drawn once, alone, with a
/// peace lily's spathe on the end of it as the mark builds it. It is in gold
/// hairline on the app's own ground and follows the appearance, so it needs no
/// change to the launch screen and no separate dress.
///
/// What it takes from the suite is the manners: a phase that is a function of the
/// clock alone, a composed resting state, a hand-over where the drawing leaves
/// before the ground does, and nothing at all under Reduce Motion.
///
/// **It is not a seed sprouting, deliberately.** That was the obvious subject and
/// it is already the one performance this app has — `GerminationView`, six
/// seconds, once, on the day a seed is sown. A cheaper sprout on every launch
/// would spend that moment, and the mark's own argument (`docs/BRAND.md`, §3.5)
/// is that the plant is what the app *gives* and not what it is about.
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
    /// proportions and not sizes. **`taper` is 3.0 where the backdrop's is 5.5.**
    /// At the backdrop's value the stem is a ruler for two thirds of its length,
    /// which is fine as a ghost the height of a screen and wrong for a mark: a
    /// straight stem is the one thing this app does not draw.
    static let plan = Plan(length: 0.82, taper: 3.0, turnOpen: 0.7, turnFurled: 2.7,
                           rootX: 0.68, rootY: 1.0, hand: -1, bract: 0.24, sway: 0.2)

    static let frame = CGSize(width: 100, height: 130)

    /// What is drawn: the stem as a run of points and the bract as a closed outline.
    struct Figure {
        var stem: [CGPoint]
        var bract: [CGPoint]
    }

    /// The figure at `open`, 0 (furled) to 1 (as open as the plan goes), in the
    /// 100 × 130 frame.
    ///
    /// **The bract opens with the coil and not after it**, which is the difference
    /// from the backdrop's. There it is a fixed shape parked on the tip, and when
    /// the coil is tight it lies across the curl as an outline drawn over an
    /// outline. Here its width follows `open`, so a furled frond carries a closed
    /// bud in its curl and an open one carries a leaf.
    static func figure(open: Double, plan: Plan = Fiddlehead.plan) -> Figure {
        let held = min(max(open, 0), 1)
        let steps = 130
        let turn = Double.pi * (plan.turnOpen + (plan.turnFurled - plan.turnOpen) * (1 - held))
        let length = frame.height * plan.length
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
        let bractLength = frame.height * plan.bract
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
            // Widest a third of the way along, per the mark's construction.
            let half = 0.30 * bractLength * sin(.pi * pow(s, 0.60))
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

    /// The box the figure occupies over its whole travel, so the drawing is fitted
    /// to what it does and the mark does not drift as it opens.
    static let travel: CGRect = {
        var minX = Double.infinity, minY = Double.infinity
        var maxX = -Double.infinity, maxY = -Double.infinity
        for index in 0...20 {
            let figure = figure(open: Double(index) / 20)
            for p in figure.stem + figure.bract {
                minX = min(minX, p.x); maxX = max(maxX, p.x)
                minY = min(minY, p.y); maxY = max(maxY, p.y)
            }
        }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }()

    // MARK: - Poses

    struct Pose: Equatable {
        var open: Double
        var appear: Double = 1
    }

    /// **Where the moment ends: 0.9, not 1.** Past about 0.9 the coil has let go
    /// entirely and what is left reads as a stray hook; `SproutingRule` stops short
    /// of full for the same reason. It is the composed state, and it is where the
    /// hand-over finds it.
    static let composed = 0.9

    static func pose(atMoment t: Double) -> Pose {
        Pose(open: composed * LoadingTiming.beat(t, 0.04...0.94),
             appear: LoadingTiming.beat(t, 0...0.10))
    }

    /// The waiting form: it never furls all the way, for the reason the other
    /// variant's does not — the tightest the coil gets is still a coil.
    static func pose(atBreath phase: Double) -> Pose {
        Pose(open: 0.2 + 0.7 * LoadingTiming.openness(atBreath: phase))
    }

    /// **Where it rests when motion is off** — a tendril half open, which is
    /// `design/Motion.dc.html`'s own sentence for Reduce Motion.
    static let still = Pose(open: 0.7)

    // MARK: - Drawing

    /// The gold the backdrop already uses behind the seed-making screens: *warm,
    /// unsaturated, and never bright*.
    static let gold = Color(red: 0.86, green: 0.71, blue: 0.44)

    /// - Parameters:
    ///   - weight: the hairline, in points.
    ///   - halo: a wider, fainter pass under it, as the backdrop gives its hairline
    ///     something to sit in. Zero for the small form, where it only blurs.
    static func draw(_ pose: Pose, ink: Color, weight: CGFloat, halo: CGFloat,
                     in context: inout GraphicsContext, size: CGSize) {
        let box = travel
        let scale = min(size.width / box.width, size.height / box.height)
        let origin = CGPoint(x: (size.width - box.width * scale) / 2 - box.minX * scale,
                             y: (size.height - box.height * scale) / 2 - box.minY * scale)
        func path(_ points: [CGPoint], closed: Bool) -> Path {
            var path = Path()
            guard let first = points.first else { return path }
            path.move(to: CGPoint(x: first.x * scale + origin.x, y: first.y * scale + origin.y))
            for p in points.dropFirst() {
                path.addLine(to: CGPoint(x: p.x * scale + origin.x, y: p.y * scale + origin.y))
            }
            if closed { path.closeSubpath() }
            return path
        }
        let figure = Fiddlehead.figure(open: pose.open)
        let stem = path(figure.stem, closed: false)
        let bract = path(figure.bract, closed: true)

        context.opacity = pose.appear
        if halo > 0 {
            let style = StrokeStyle(lineWidth: halo, lineCap: .round, lineJoin: .round)
            context.stroke(stem, with: .color(gold.opacity(0.07)), style: style)
            context.stroke(bract, with: .color(gold.opacity(0.07)), style: style)
        }
        let style = StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round)
        context.stroke(stem, with: .color(ink), style: style)
        context.stroke(bract, with: .color(ink), style: style)
    }
}

/// The frond, at a pose, in a frame. A still picture, for the reason
/// `UnwindingMarkView` is.
struct FiddleheadView: View {
    let pose: Fiddlehead.Pose
    var ink: Color
    var weight: CGFloat = 1.6
    var halo: CGFloat = 9

    var body: some View {
        Canvas { context, size in
            Fiddlehead.draw(pose, ink: ink, weight: weight, halo: halo, in: &context, size: size)
        }
        .accessibilityHidden(true)
    }
}
