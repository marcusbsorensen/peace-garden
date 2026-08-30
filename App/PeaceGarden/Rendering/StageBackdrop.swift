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

    /// The cool slate of a photographic backdrop.
    static let baseHue = 0.60
    /// How far the glow moves toward the plant's own colour. Kept deliberately
    /// small — at a third, a magenta flower turns the whole screen violet and
    /// the backdrop stops being a backdrop.
    static let tint = 0.12
    static let saturation = 0.30
    static let brightness = 0.26
    /// Sits a little above centre, where the mass of a plant usually is.
    static let centre = UnitPoint(x: 0.5, y: 0.46)
    static let radiusFraction = 0.85
    static let falloff = 2.0
    static let stopCount = 12

    var body: some View {
        GeometryReader { proxy in
            let span = max(proxy.size.width, proxy.size.height)
            ZStack {
                Color.black
                RadialGradient(
                    gradient: Gradient(stops: Self.stops(for: palette)),
                    center: Self.centre,
                    startRadius: 0,
                    endRadius: span * Self.radiusFraction
                )
            }
        }
        .ignoresSafeArea()
    }

    /// The falloff is spelled out over a dozen stops rather than left to a
    /// two-colour interpolation. A straight ramp between two near-black colours
    /// bands visibly on an OLED screen in a dark room, which is exactly where
    /// this app is going to be looked at.
    static func stops(for palette: Genome.Palette) -> [Gradient.Stop] {
        let hue = glowHue(for: palette)
        return (0...stopCount).map { index in
            let t = Double(index) / Double(stopCount)
            let level = pow(1 - t, falloff)
            return Gradient.Stop(
                color: Color(hue: hue, saturation: saturation, brightness: brightness * level),
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
