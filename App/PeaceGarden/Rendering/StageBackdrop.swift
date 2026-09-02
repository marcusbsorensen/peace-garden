import SwiftUI
import SeedCore

/// The stage a plant stands on: black, with a soft pool of cool light behind it
/// that falls away to nothing at the edges.
///
/// Taken from the way botanical model kits are photographed for their boxes —
/// the subject in full colour and full focus, the ground giving it somewhere to
/// be without competing for attention. The tint is nudged a little toward the
/// plant's own colour, so each person's stage is quietly theirs without the
/// backdrop ever becoming a thing you look at.
struct StageBackdrop: View {
    let palette: Genome.Palette

    /// How much of the stage the plant is taking up, `0...1`, where `1` is the
    /// plant it will grow into. The pool of light is sized from this, so the
    /// light lands on the plant rather than on the screen.
    ///
    /// Fixed, the glow said the same thing about a seedling as about a plant in
    /// full bloom: an even wash across a phone-width of screen, with something
    /// very small in the middle of it. Since the camera holds every age at the
    /// same distance — that is what makes a seedling look like a seedling —
    /// the backdrop was the one thing on screen quietly insisting the plant was
    /// the same size all along.
    ///
    /// `GrowthModel.State.heightScale` is exactly this number and costs
    /// nothing, so nothing needs measuring to get it.
    var presence: Double = 1

    /// The cool slate of a photographic backdrop.
    static let baseHue = 0.60
    /// How far the glow moves toward the plant's own colour. Kept deliberately
    /// small — at a third, a magenta flower turns the whole screen violet and
    /// the backdrop stops being a backdrop.
    static let tint = 0.12
    static let saturation = 0.30
    static let brightness = 0.26
    /// Where a grown plant carries its mass — a little above centre. A young
    /// one is a few centimetres of shoot sitting on the middle of the screen,
    /// so the pool starts centred on it and drifts up as the plant fills out.
    static let grownCentre = UnitPoint(x: 0.5, y: 0.46)
    static let youngCentre = UnitPoint(x: 0.5, y: 0.5)

    /// The pool at its widest, which is the plant in full bloom. Unchanged:
    /// a mature plant stands in exactly the light it always did.
    static let grownRadius = 0.85
    /// What is left of the pool around a seed. Small enough to read as light
    /// falling on one thing, wide enough that the screen has not become a
    /// vignette with a spotlight in it.
    static let seedRadius = 0.14
    /// Below `1`, so most of the widening happens over the early weeks when
    /// the plant is changing fastest and there is most to notice.
    static let growthCurve = 0.7

    static let falloff = 2.0
    static let stopCount = 12

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        GeometryReader { proxy in
            let span = max(proxy.size.width, proxy.size.height)
            ZStack {
                Chrome.ground
                RadialGradient(
                    gradient: Gradient(stops: Self.stops(
                        for: palette,
                        strength: scheme == .light ? 0.30 : 1
                    )),
                    center: Self.centre(presence: presence),
                    startRadius: 0,
                    endRadius: span * Self.radius(presence: presence)
                )
            }
        }
        // Deliberately not animated. Growth moves this by a hair every twenty
        // seconds, and the arrival drives it every frame — an implicit
        // animation would have nothing to smooth in the first case and would
        // lag a frame behind the camera in the second.
        .ignoresSafeArea()
    }

    static func radius(presence: Double) -> Double {
        let t = pow(min(max(presence, 0), 1), growthCurve)
        return seedRadius + (grownRadius - seedRadius) * t
    }

    static func centre(presence: Double) -> UnitPoint {
        let t = pow(min(max(presence, 0), 1), growthCurve)
        return UnitPoint(
            x: 0.5,
            y: youngCentre.y + (grownCentre.y - youngCentre.y) * t
        )
    }

    /// The falloff is spelled out over a dozen stops rather than left to a
    /// two-colour interpolation. A straight ramp between two near-black colours
    /// bands visibly on an OLED screen in a dark room, which is exactly where
    /// this app is going to be looked at.
    /// The pool of light, as a wash over the ground rather than a disc of paint.
    ///
    /// **It used to fade to black rather than to nothing.** The stops ran the
    /// brightness down to zero, which on a black ground is the same picture and
    /// on any other ground is an opaque black circle covering the screen — so
    /// the first light appearance came out entirely dark and the ground under
    /// it was never visible at all. Fading the *opacity* instead leaves the
    /// same glow on black and lets the ground through everywhere else.
    ///
    /// `strength` pulls the whole thing back on a light ground, where a
    /// saturated glow is a stain rather than a pool.
    static func stops(for palette: Genome.Palette, strength: Double) -> [Gradient.Stop] {
        let hue = glowHue(for: palette)
        return (0...stopCount).map { index in
            let t = Double(index) / Double(stopCount)
            let level = pow(1 - t, falloff)
            return Gradient.Stop(
                color: Color(hue: hue, saturation: saturation, brightness: brightness)
                    .opacity(level * strength),
                location: t
            )
        }
    }

    /// Blends the base slate toward the plant's petal hue the short way round
    /// the wheel, so a red flower warms its light rather than detouring
    /// through green to get there.
    static func glowHue(for palette: Genome.Palette) -> Double {
        var delta = palette.petalBase.hue - baseHue
        if delta > 0.5 { delta -= 1 }
        if delta < -0.5 { delta += 1 }
        let hue = (baseHue + delta * tint).truncatingRemainder(dividingBy: 1)
        return hue < 0 ? hue + 1 : hue
    }

    /// The same colour as a `UIColor`, for the lights inside the scene.
    static func glowColour(for palette: Genome.Palette) -> UIColor {
        UIColor(
            hue: CGFloat(glowHue(for: palette)),
            saturation: CGFloat(saturation),
            brightness: CGFloat(brightness),
            alpha: 1
        )
    }
}
