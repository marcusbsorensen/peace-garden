import CoreGraphics
import simd
import SwiftUI

/// The plot itself: a square of ground hanging in space, with the soil's own
/// depth showing at the cut.
///
/// A plane that merely stops leaves *what is off the side* unanswered; a plot
/// with a cut answers it by showing the answer. `docs/ARRANGING.md` §*The garden
/// is a floating square plot*.
///
/// **There is no terrain here yet.** The ground is flat, which is the first of
/// the two steps the handover asks for — the plot and the plants at the right
/// scale, then the worlds. Everything below is written against a height at a
/// place rather than against zero, so the heightmap drops in without the
/// drawing changing shape.
enum GardenGround {
    // MARK: The cut

    /// How deep the soil is under a place on the plot, in metres.
    ///
    /// The mockup's taper, kept exactly: a floor of 0.40 m everywhere, and a
    /// bulge of up to 1.70 m more toward the middle, measured on the Chebyshev
    /// radius so it follows the square rather than a circle inside it.
    ///
    /// **The floor is the whole point.** The only part of a floating plot's
    /// underside anybody ever sees is the part near the near edges, so a plot
    /// whose soil thins to a line at the rim reads as a tile rather than as a
    /// piece of ground with a root under it. That is why the rim is the one
    /// place the depth is not allowed to be economised.
    static func cutDepth(x: Double, z: Double, plotSide: Double) -> Double {
        let half = plotSide / 2
        guard half > 0 else { return rimDepth }
        let radius = min(1, max(abs(x), abs(z)) / half)
        let bulge = pow(max(0, 1 - pow(radius, 1.7)), 0.85)
        return rimDepth + 1.70 * bulge
    }

    /// What `cutDepth` comes to at the rim, which is the only depth ever drawn
    /// while the plot is flat, and the number the camera has to leave room for.
    static let rimDepth = 0.40

    // MARK: The light

    /// One light, and the ambient it is set against.
    ///
    /// Hemispheric rather than a studio: sky from above, bounce from the ground
    /// below, so a shadowed face is lit by the sky rather than by nothing.
    /// `StageBackdrop` is a hard key and a near-black ambient on purpose, which
    /// is right for a plant photographed for a box and exactly wrong outdoors.
    ///
    /// The orbit is not built yet, so this is noon held still. When the sun and
    /// moon go round, they replace this value and nothing that draws with it has
    /// to change.
    struct Light {
        var direction: SIMD3<Double>
        var colour: SIMD3<Double>
        var strength: Double
        var sky: SIMD3<Double>
        var bounce: SIMD3<Double>

        static let noon = Light(
            direction: SIMD3(-0.331_97, 0.882_95, 0.331_97),
            colour: SIMD3(1.00, 0.96, 0.88),
            strength: 0.76,
            sky: SIMD3(0.40, 0.48, 0.60),
            bounce: SIMD3(0.27, 0.25, 0.20)
        )
    }

    /// A surface's colour under the light.
    ///
    /// `shadow` is 1 in the open and 0 in shade; the `0.18 +` keeps a shadowed
    /// face lit by the sky rather than black. Softened Lambert, because a leaf
    /// and a bank of soil both scatter more at a grazing angle than a perfect
    /// diffuser would.
    static func shade(
        base: SIMD3<Double>,
        normal: SIMD3<Double>,
        shadow: Double = 1,
        light: Light = .noon
    ) -> Color {
        let lit = shaded(base: base, normal: normal, shadow: shadow, light: light)
        return Color(red: lit.x, green: lit.y, blue: lit.z)
    }

    /// The same answer as components, for the thousands of quads a terrain is
    /// made of — a `Color` per cell would be four thousand boxed values a frame.
    static func shaded(
        base: SIMD3<Double>,
        normal: SIMD3<Double>,
        shadow: Double = 1,
        light: Light = .noon
    ) -> SIMD3<Double> {
        let hemi = 0.5 + 0.5 * normal.y
        let key = max(0, simd_dot(normal, light.direction))
        let lit = pow(key, 0.9) * light.strength * (0.18 + 0.82 * shadow)

        var out = SIMD3<Double>()
        for channel in 0..<3 {
            let ambient = light.sky[channel] * hemi + light.bounce[channel] * (1 - hemi)
            out[channel] = min(1, max(0, base[channel] * (ambient + light.colour[channel] * lit)))
        }
        return ceilinged(out)
    }

    // MARK: What the ground is made of

    /// Cut soil, from the mockup. The one material the plot has while there are
    /// no worlds to choose from.
    static let soil = SIMD3<Double>(0.215, 0.185, 0.160)

    /// The flat plot's surface: a plain turf, deliberately duller than any world
    /// will be. It is a stand-in for a chosen ground and should look like one.
    static let turf = SIMD3<Double>(0.235, 0.265, 0.190)

    /// Every colour the ground puts on screen passes through here.
    ///
    /// `Chrome`'s rule is that the plant is the only saturated thing on screen,
    /// and a lawn in full chroma takes that away. Enforcing it in one function
    /// rather than trusting each material means a material written too bright
    /// later cannot quietly break the rule.
    ///
    /// **The ceiling is 0.28 and it is a decision, not a measurement.** The
    /// generator that held the original number was never committed; 0.28 sits
    /// just under `StageBackdrop.saturation`, which is the most saturated thing
    /// the app already puts behind a plant.
    static let saturationCeiling = 0.28

    static func underCeiling(_ rgb: SIMD3<Double>) -> Color {
        let held = ceilinged(rgb)
        return Color(red: held.x, green: held.y, blue: held.z)
    }

    static func ceilinged(_ rgb: SIMD3<Double>) -> SIMD3<Double> {
        let high = max(rgb.x, max(rgb.y, rgb.z))
        let low = min(rgb.x, min(rgb.y, rgb.z))
        guard high > 0 else { return SIMD3(repeating: 0) }

        let saturation = (high - low) / high
        guard saturation > saturationCeiling else { return rgb }

        // Pulled toward its own grey rather than desaturated to it, so the
        // material keeps its hue and loses only what it was not allowed.
        let keep = saturationCeiling / saturation
        let grey = high * (1 - keep)
        return rgb * keep + SIMD3(repeating: grey)
    }

    // MARK: The shapes

    /// The plot's surface, corner to corner.
    static func topFace(plotSide: Double, in view: Isometric) -> Path {
        let half = plotSide / 2
        let corners = [
            (-half, -half), (half, -half), (half, half), (-half, half)
        ].map { view.point(x: $0.0, z: $0.1) }

        var path = Path()
        path.addLines(corners)
        path.closeSubpath()
        return path
    }

    /// The two faces of the cut that face the viewer, far one first.
    ///
    /// Only two of the four are ever seen: depth runs on `x + z`, so the `+x`
    /// and `+z` edges are the near ones and the other two are behind the plot's
    /// own surface. Each is sampled along its edge rather than drawn as a single
    /// quad, so a terrain that lifts or drops the rim will take the top of the
    /// face with it.
    static func nearFaces(plotSide: Double, in view: Isometric, samples: Int = 16) -> [(Path, Color)] {
        let half = plotSide / 2

        let faces: [(normal: SIMD3<Double>, along: (Double) -> (x: Double, z: Double))] = [
            (SIMD3(0, 0, 1), { t in (x: -half + t * plotSide, z: half) }),
            (SIMD3(1, 0, 0), { t in (x: half, z: half - t * plotSide) })
        ]

        return faces.map { face in
            var path = Path()
            let steps = max(2, samples)

            for step in 0...steps {
                let place = face.along(Double(step) / Double(steps))
                let point = view.point(x: place.x, z: place.z)
                if step == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            for step in stride(from: steps, through: 0, by: -1) {
                let place = face.along(Double(step) / Double(steps))
                let depth = cutDepth(x: place.x, z: place.z, plotSide: plotSide)
                path.addLine(to: view.point(x: place.x, y: -depth, z: place.z))
            }
            path.closeSubpath()

            return (path, shade(base: soil, normal: face.normal, shadow: 0.55))
        }
    }
}
