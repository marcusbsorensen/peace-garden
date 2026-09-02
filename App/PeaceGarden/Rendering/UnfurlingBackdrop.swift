import SwiftUI

/// The ground for the two screens where a seed is being made: a frond, or a
/// pair of them, opening across the whole height of the screen in a gold so low
/// you are meant to notice it only after you have read the words.
///
///     UnfurlingBackdrop(.single)   // first light — one seed being drawn
///     UnfurlingBackdrop(.pair)     // a meeting — two seeds crossing
///
/// It is a background and behaves like one: it ignores the safe area, takes no
/// touches, and is hidden from VoiceOver. Put it in a `ZStack` under the screen,
/// or hand it to `.background()`.
///
/// **The gesture is `Chrome.Tendril`'s, scaled up.** The coil *relaxes* — total
/// turn falls as the frond opens while its arc length stays fixed — so the tip
/// travels because the curl lets go, not because a line is being drawn on. At
/// full-screen size that distinction is the whole difference between a plant
/// opening and a progress bar filling.
struct UnfurlingBackdrop: View {
    /// Which of the two seed-making screens this is standing behind.
    enum Style {
        /// One frond, the height of the screen. For first light, where a single
        /// seed is being drawn for one person.
        case single
        /// Two, reaching into the same space from opposite sides at different
        /// heights and on different clocks. For a meeting, where two seeds
        /// cross. Deliberately not a mirror pair: mirroring reads as one thing
        /// and its reflection, which is the opposite of two people meeting.
        case pair
    }

    private let style: Style
    private let seed: UInt64

    /// - Parameters:
    ///   - style: `.single` or `.pair`.
    ///   - seed: shifts the composition slightly and repeatably. The same seed
    ///     always draws the same backdrop; the default is the drawn one. Pass a
    ///     person's own seed if you want their first light to be theirs.
    init(_ style: Style, seed: UInt64 = 0) {
        self.style = style
        self.seed = seed
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: Double = 0

    var body: some View {
        ZStack {
            ForEach(Array(plans.enumerated()), id: \.offset) { _, plan in
                frond(plan)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .animation(motion, value: phase)
        // Advanced rather than set, so a view that is put away and brought back
        // starts moving again. `unfurl` has period 1, so which cycle we are on
        // makes no difference to what is drawn.
        .onAppear { phase += 1 }
    }

    // MARK: - Composition

    private var plans: [Frond.Plan] {
        switch style {
        case .single: return [Frond.Plan.solitary.jittered(by: seed, salt: 0)]
        case .pair: return [
            Frond.Plan.early.jittered(by: seed, salt: 1),
            Frond.Plan.late.jittered(by: seed, salt: 2)
        ]
        }
    }

    /// Where the cycle is held when motion is off. Not frozen mid-stride: the
    /// pair is parked at the moment one frond is still curled and the other has
    /// nearly opened, which is the composition the animation is *for*.
    private var restingPhase: Double {
        switch style {
        case .single: return 0.30
        case .pair: return 0.15
        }
    }

    /// Linear in `phase`, cosine in the frond — see `Frond.unfurl(at:)`. A
    /// `repeatForever(autoreverses:)` ease would run the whole screen backwards
    /// every cycle; at 40pt in `SproutingRule` that is invisible, and at 900pt
    /// it is a rewind.
    private var motion: Animation? {
        reduceMotion ? nil : .linear(duration: Self.cycle).repeatForever(autoreverses: false)
    }

    @ViewBuilder
    private func frond(_ plan: Frond.Plan) -> some View {
        let p = reduceMotion ? restingPhase : phase
        ZStack {
            // The wide pass is not a blur — it is the same path stroked fat and
            // almost transparent, which costs one more path build and gives the
            // hairline something to sit in. A stack of blurred layers over a
            // live SceneKit render would not be worth this.
            Frond(phase: p, plan: plan)
                .stroke(
                    Self.gold.opacity(Self.haloOpacity * plan.weight),
                    style: StrokeStyle(lineWidth: Self.haloWidth, lineCap: .round, lineJoin: .round)
                )
            Frond(phase: p, plan: plan)
                .stroke(
                    Self.gold.opacity(Self.hairOpacity * plan.weight),
                    style: StrokeStyle(lineWidth: Self.hairWidth, lineCap: .round, lineJoin: .round)
                )
        }
    }

    // MARK: - The one colour, and how quiet it is

    /// Warm, unsaturated, and never bright. The plant is the only saturated
    /// thing in this app and a backdrop may not join it.
    static let gold = Color(red: 0.86, green: 0.71, blue: 0.44)

    static let hairWidth: CGFloat = 1.2      // `Chrome`'s own stroke weight
    static let haloWidth: CGFloat = 9
    static let hairOpacity: Double = 0.20
    static let haloOpacity: Double = 0.035

    /// One furl-and-open, in seconds. Slow enough that nothing on this screen
    /// moves fast enough to be caught in peripheral vision, and not so slow it
    /// stops reading as motion: frames 2.8s apart differ across about 3% of the
    /// screen for `.single` and 5% for `.pair`, measured on device.
    static let cycle: Double = 17
}

// MARK: - The frond

/// One frond, part way through opening — `Chrome.Tendril`'s gesture at the
/// scale of a screen, with a peace lily's spathe on the end of it.
///
/// `phase` rather than `unfurl` is the animated value on purpose. SwiftUI
/// interpolates `animatableData` between the old and new value and does not
/// re-run the view body per frame, so a non-linear mapping applied *outside*
/// the shape would be flattened back into a straight line — and a cycle that
/// returns to where it started would be interpolated as no motion at all. The
/// cosine has to live inside `path(in:)`, and it does.
struct Frond: Shape {
    var phase: Double
    var plan: Plan

    var animatableData: Double {
        get { phase }
        set { phase = newValue }
    }

    struct Plan {
        /// Arc length, as a fraction of the frame's height. Constant through
        /// the whole cycle: the frond does not grow, it uncurls.
        var length: Double
        /// How hard the turn is pushed toward the tip. High values leave the
        /// stem near-straight and put the whole coil in the last third, which
        /// is where a fiddlehead keeps it.
        var taper: Double
        /// Total turn at the tip, in half-turns, when open and when furled.
        var turnOpen: Double
        var turnFurled: Double
        /// Where the stem leaves the bottom edge, in fractions of the frame.
        var rootX: Double
        var rootY: Double
        /// A constant lean along the whole stem, so it is not a ruler.
        var lean: Double
        /// `+1` curls toward the right of the screen, `-1` toward the left.
        var hand: Double
        /// Fraction of a cycle this frond runs behind the others.
        var lag: Double
        /// Multiplies the ink. The second frond of a pair sits back a little.
        var weight: Double
        /// Spathe length, as a fraction of the frame's height. Fixed rather
        /// than derived from the tip's curvature, which balloons the bract
        /// every time the coil relaxes.
        var bract: Double

        /// First light: one frond, rooted right of centre and standing the full
        /// height, so the coil has the whole width to open into. Its apex
        /// travels between 0.03 and 0.17 of the height and the coil never
        /// reaches left of 0.11 of the width — so it stays above the headline
        /// and inside the frame at every point in the cycle. The first draft
        /// was a third of a screen lower and sat behind the words.
        static let solitary = Plan(
            length: 1.34, taper: 5.5, turnOpen: 1.30, turnFurled: 2.90,
            rootX: 0.84, rootY: 1.05, lean: 0, hand: -1,
            lag: 0, weight: 1, bract: 0.038
        )

        /// A meeting, first arrival: the taller one, rooted left and reaching
        /// right across the top.
        static let early = Plan(
            length: 1.32, taper: 5.5, turnOpen: 1.50, turnFurled: 2.95,
            rootX: 0.10, rootY: 1.05, lean: 0.06, hand: +1,
            lag: 0, weight: 1, bract: 0.036
        )

        /// A meeting, second arrival: shorter, a fifth of a cycle behind, and
        /// turning the other way — so the two sweep past each other rather than
        /// mirroring. Its apex rides about a tenth of the screen below the
        /// first's, which is what keeps the pair from reading as one shape and
        /// its reflection.
        static let late = Plan(
            length: 1.08, taper: 5.5, turnOpen: 1.30, turnFurled: 2.75,
            rootX: 0.90, rootY: 1.04, lean: -0.10, hand: -1,
            lag: 0.19, weight: 0.82, bract: 0.032
        )

        /// Small, repeatable variation. Deliberately below the threshold at
        /// which the composition changes — it moves a root and a lean, and it
        /// cannot turn a designed frond into an accident.
        func jittered(by seed: UInt64, salt: UInt64) -> Plan {
            guard seed != 0 else { return self }
            var copy = self
            copy.rootX += Self.wobble(seed, salt &* 3 &+ 1) * 0.05
            // Lean rotates the whole frond, so a little of it moves the coil a
            // long way. Held to two degrees: at four the tip clears the left
            // edge at the open end of the cycle.
            copy.lean += Self.wobble(seed, salt &* 3 &+ 2) * 0.035
            copy.lag += Self.wobble(seed, salt &* 3 &+ 3) * 0.05
            return copy
        }

        /// SplitMix64, folded to −1…1. Any stable hash would do; what matters
        /// is that it is a pure function of the seed and never of the clock.
        private static func wobble(_ seed: UInt64, _ salt: UInt64) -> Double {
            var z = seed &+ (salt &* 0x9E37_79B9_7F4A_7C15)
            z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
            z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
            z = z ^ (z >> 31)
            return Double(z % 2_000) / 1_000 - 1
        }
    }

    /// Cosine of the phase, so the frond eases to rest at both ends of its
    /// travel and the cycle joins itself invisibly at the wrap.
    static func unfurl(at phase: Double) -> Double {
        0.5 - 0.5 * cos(2 * .pi * phase)
    }

    /// The number of segments the spine is walked in. Enough that the tightest
    /// coil this plan reaches is smooth at a 1.2pt stroke on a 3× screen.
    static let steps = 130

    func path(in rect: CGRect) -> Path {
        let u = Self.unfurl(at: phase + plan.lag)
        let turn = .pi * (plan.turnOpen + (plan.turnFurled - plan.turnOpen) * (1 - u))
        let length = rect.height * plan.length
        let step = length / Double(Self.steps)

        var point = CGPoint(
            x: rect.minX + rect.width * plan.rootX,
            y: rect.minY + rect.height * plan.rootY
        )
        var path = Path()
        path.move(to: point)

        // Straight up, then bending: the turn accumulates as a power of the
        // distance travelled, so the base leaves almost vertical and the coil
        // lives at the far end. Lowering `turn` unwinds the coil without
        // shortening the line by so much as a point.
        let base = -Double.pi / 2 + plan.lean
        var heading = base
        for index in 1...Self.steps {
            let s = Double(index) / Double(Self.steps)
            heading = base + plan.hand * turn * pow(s, plan.taper)
            point.x += cos(heading) * step
            point.y += sin(heading) * step
            path.addLine(to: point)
        }

        addBract(to: &path, at: point, heading: heading, in: rect)
        return path
    }

    /// The spathe, leaving on the tangent the spine actually ends on and
    /// continuing the same way round — the mark's own construction, from
    /// `docs/BRAND.md`. Parked on the end at a new angle it would read as two
    /// shapes introduced to each other rather than one gesture.
    private func addBract(to path: inout Path, at tip: CGPoint, heading: Double, in rect: CGRect) {
        let length = rect.height * plan.bract
        let ribs = 20
        let sweep = 0.34 * plan.hand

        var spine: [CGPoint] = [tip]
        var point = tip
        for index in 1...ribs {
            let angle = heading + sweep * (Double(index) / Double(ribs))
            point.x += cos(angle) * length / Double(ribs)
            point.y += sin(angle) * length / Double(ribs)
            spine.append(point)
        }

        // Widest a third of the way along, per the mark's construction.
        var near: [CGPoint] = []
        var far: [CGPoint] = []
        for index in 0...ribs {
            let s = Double(index) / Double(ribs)
            let halfWidth = 0.30 * length * sin(.pi * pow(s, 0.60))
            let j = min(index, ribs - 1)
            let angle = atan2(spine[j + 1].y - spine[j].y, spine[j + 1].x - spine[j].x)
            let nx = -sin(angle) * halfWidth
            let ny = cos(angle) * halfWidth
            near.append(CGPoint(x: spine[index].x + nx, y: spine[index].y + ny))
            far.append(CGPoint(x: spine[index].x - nx, y: spine[index].y - ny))
        }

        path.move(to: near[0])
        for p in near.dropFirst() { path.addLine(to: p) }
        for p in far.reversed() { path.addLine(to: p) }
        path.closeSubpath()
    }
}

#Preview("single") {
    ZStack {
        Color.black
        UnfurlingBackdrop(.single)
        Text("A seed is about to be created for you")
            .font(.system(size: 28, weight: .light))
            .foregroundStyle(Chrome.ink)
            .multilineTextAlignment(.center)
            .padding(40)
    }
    .ignoresSafeArea()
}

#Preview("pair") {
    ZStack {
        Color.black
        UnfurlingBackdrop(.pair)
        Text("Touch the tops of your phones together")
            .font(.system(size: 20, weight: .light, design: .serif))
            .foregroundStyle(Chrome.ink)
            .multilineTextAlignment(.center)
            .padding(40)
    }
    .ignoresSafeArea()
}
