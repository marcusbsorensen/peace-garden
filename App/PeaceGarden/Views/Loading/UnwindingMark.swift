import SwiftUI

/// **Variant A, drawn: the app's own mark lets go, then one band of light crosses
/// it.**
///
/// This is the Interfulgent launch pattern in this app's own drawing. What the
/// three suite apps share is a brand mark at rest on `#0D0D1F`, one band of light
/// crossing it once, a phase that is a function of the clock alone, and a hand
/// over where the mark leaves before the ground does. UnCubed's mark is `un³`,
/// Pfish's is a fish and FlagFans's is an `ff`; this app's is a coil, so the
/// crossing is preceded by the coil doing what a coil does in this app, which is
/// open — `UnwindingMarkGeometry` says how and why it is not a trim.
///
/// **One departure from the suite, stated.** UnCubed, Pfish and FlagFans all begin
/// with the mark already at rest and bring light over it. This begins furled and
/// ends at rest, because the blank launch screen ahead of it is the one place in
/// the app where nothing is on screen to be at rest, and *"unfolding, not
/// appearing"* (`design/Motion.dc.html`) is the app's own rule for how a thing
/// arrives. The last frame is the mark exactly, which is the suite's real
/// requirement: what the hand-over fades is the finished mark, never a frame
/// caught mid-motion.
///
/// **Two dresses, and the choice is the suite's.** On its own ground the mark
/// wears its gradient and a white bract. Everywhere else in an app of this suite
/// the mark is one colour — the arc's values are on the mark's own stroke and
/// nowhere else — so the small waiting form takes the app's ink.
enum UnwindingMark {

    /// How much of the mark is open, and where the light is.
    struct Pose: Equatable {
        var coil: Double
        var bract: Double
        var spike: Double
        /// 0…1, so the first frame is not a pop.
        var appear: Double = 1
        /// Where the band's centre is along the sweep's axis (0 at the
        /// bottom-left of the mark, 1 at the top-right); `nil` is no band at all.
        var sheen: Double?
    }

    /// The finished mark, and the last frame of the moment.
    static let resting = Pose(coil: 1, bract: 1, spike: 1, appear: 1, sheen: nil)

    // MARK: - The moment

    /// The launch moment at `t`, 0…1 across `LoadingTiming.moment`.
    ///
    /// The beats overlap on purpose, as `GerminationView`'s do: run end to end
    /// they would read as three animations queued, which is a slideshow.
    static func pose(atMoment t: Double) -> Pose {
        let travel = LoadingTiming.span(t, sheenSpan)
        return Pose(
            coil: LoadingTiming.beat(t, 0.04...0.62),
            bract: LoadingTiming.beat(t, 0.34...0.80),
            spike: LoadingTiming.beat(t, 0.58...0.86),
            appear: LoadingTiming.beat(t, 0...0.10),
            // The band starts and ends entirely off the mark, so it adds nothing
            // to the first frame or the last.
            sheen: travel > 0 && travel < 1 ? -0.25 + 1.5 * travel : nil)
    }

    /// When the light is on the mark. Half of the moment, and the second half:
    /// it crosses the mark that has opened rather than the one that is opening.
    static let sheenSpan = 0.52...0.98

    // MARK: - The waiting form

    /// The waiting mark at a point in its breath. The coil never furls all the
    /// way — a tight disc read as a different object at 40 points — and the
    /// bract narrows and widens with it, so it is one gesture and not two.
    static func pose(atBreath phase: Double) -> Pose {
        pose(openness: LoadingTiming.openness(atBreath: phase))
    }

    static func pose(openness: Double) -> Pose {
        Pose(coil: 0.3 + 0.7 * openness,
             bract: 0.45 + 0.55 * openness,
             spike: openness,
             appear: 1,
             sheen: nil)
    }

    /// **The waiting mark when motion is off**: the mark itself, still. The
    /// statement is kept and the movement is not.
    static let still = resting

    // MARK: - Dress

    enum Dress {
        /// The gradient and the white bract, on the suite's ground.
        case brand
        /// One colour, for the app's own ground in either appearance.
        case ink(Color)
    }

    /// The suite's ground, `#0D0D1F`, flat. The same in both appearances: it is
    /// the ground that travels with the mark.
    static let ground = Color(.sRGB, red: 0x0D / 255, green: 0x0D / 255, blue: 0x1F / 255, opacity: 1)

    // MARK: - Drawing

    private static func colour(_ c: (r: Double, g: Double, b: Double)) -> Color {
        Color(.sRGB, red: c.r, green: c.g, blue: c.b, opacity: 1)
    }

    /// The figure, fitted to whichever side of `size` is shorter and centred on
    /// its own ink — the script's own fit, which has no optical bias because the
    /// mark has no open side wanting one.
    static func draw(_ pose: Pose, dress: Dress, in context: inout GraphicsContext, size: CGSize) {
        let rest = UnwindingMarkGeometry.rest
        let box = rest.inkBounds
        let scale = min(size.width / box.width, size.height / box.height)
        let origin = CGPoint(x: (size.width - box.width * scale) / 2 - box.minX * scale,
                             y: (size.height - box.height * scale) / 2 - box.minY * scale)
        func place(_ p: CGPoint) -> CGPoint {
            CGPoint(x: p.x * scale + origin.x, y: p.y * scale + origin.y)
        }

        let figure = UnwindingMarkGeometry.figure(coil: pose.coil, bract: pose.bract, spike: pose.spike)
        let width = UnwindingMarkGeometry.stroke * scale
        let style = StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)

        func path(_ points: [CGPoint], closed: Bool) -> Path {
            var path = Path()
            guard let first = points.first else { return path }
            path.move(to: place(first))
            for point in points.dropFirst() { path.addLine(to: place(point)) }
            if closed { path.closeSubpath() }
            return path
        }

        context.opacity = pose.appear

        // The bract first, then the coil, then the taper: the order the icon
        // draws them in, which is what puts the colour over the white where they
        // share ink at the mouth, so the junction reads as one stroke running on.
        let bract = path(figure.bract, closed: true)
        let coil = path(figure.coil, closed: false)
        let spike = path(figure.spike, closed: true)

        switch dress {
        case .brand:
            // Across the coil and the taper only; the bract is white and takes no
            // part. Bottom-left to top-right, like the icon's.
            let sweep = rest.sweepBounds
            let from = place(CGPoint(x: sweep.minX, y: sweep.maxY))
            let to = place(CGPoint(x: sweep.maxX, y: sweep.minY))
            let ramp = Gradient(stops: UnwindingMarkGeometry.ramp.enumerated().map { index, value in
                Gradient.Stop(color: colour(value),
                              location: Double(index) / Double(UnwindingMarkGeometry.ramp.count - 1))
            })

            context.stroke(bract, with: .color(.white), style: style)
            context.stroke(coil, with: .linearGradient(ramp, startPoint: from, endPoint: to), style: style)

            // The taper carries the ramp's last stop and blends to it only at the
            // mouth: it sits at the top *middle* of the mark, not in the corner the
            // sweep ends in, so left on the sweep it would come out mid-ramp green.
            let axis = rest.spikeAxis
            let hot = UnwindingMarkGeometry.sweepColour(at: axis.start, in: sweep)
            let yellow = colour(UnwindingMarkGeometry.ramp[UnwindingMarkGeometry.ramp.count - 1])
            let point = Gradient(stops: [
                .init(color: colour(hot), location: 0),
                .init(color: yellow, location: UnwindingMarkGeometry.taperTurnsAt),
                .init(color: yellow, location: 1),
            ])
            context.fill(spike, with: .linearGradient(point, startPoint: place(axis.start),
                                                      endPoint: place(axis.end)))

            if let centre = pose.sheen {
                // Transparent, white, transparent, centred on `centre` along the
                // sweep's axis — FlagFans's sheen, at its width and strength.
                let band = Self.sheen(at: centre)
                context.stroke(coil, with: .linearGradient(band, startPoint: from, endPoint: to),
                               style: style)
                context.fill(spike, with: .linearGradient(band, startPoint: from, endPoint: to))
            }

        case .ink(let ink):
            context.stroke(bract, with: .color(ink.opacity(0.55)), style: style)
            context.stroke(coil, with: .color(ink.opacity(0.92)), style: style)
            context.fill(spike, with: .color(ink.opacity(0.75)))
        }
    }

    /// The band: `0.55` at its peak and `0.18` of the axis either side, which is
    /// FlagFans's `sheen()` exactly. Pfish's is wider and UnCubed's wider still,
    /// because each is sized to its own mark; this mark is one thin line and the
    /// narrow band is the one that does not light all of it at once.
    static func sheen(at centre: Double) -> Gradient {
        let reach = 0.18
        func alpha(_ offset: Double) -> Double {
            0.55 * min(max(1 - abs(offset - centre) / reach, 0), 1)
        }
        let offsets = [0, centre - reach, centre, centre + reach, 1]
            .map { min(max($0, 0), 1) }
            .sorted()
        return Gradient(stops: offsets.map { Gradient.Stop(color: .white.opacity(alpha($0)), location: $0) })
    }
}

extension UnwindingMarkGeometry.Construction {
    /// The taper's own axis, from its mouth to its last kept point.
    var spikeAxis: (start: CGPoint, end: CGPoint) {
        (spine[0], spine[spikeCount - 1])
    }
}

/// The mark, at a pose, in a frame. A still picture: whatever is moving it is
/// the caller's, which is what lets a test draw frame 17 of 60 without waiting.
struct UnwindingMarkView: View {
    let pose: UnwindingMark.Pose
    var dress: UnwindingMark.Dress = .brand

    var body: some View {
        Canvas { context, size in
            UnwindingMark.draw(pose, dress: dress, in: &context, size: size)
        }
        .accessibilityHidden(true)
    }
}
