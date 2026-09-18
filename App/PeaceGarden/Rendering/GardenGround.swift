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
/// The materials and the light live here; `GardenTerrain` does the drawing and
/// `GardenWorlds` holds the eight grounds. The flat plot below is what is drawn
/// if the world atlas is ever missing from the bundle, so that a garden without
/// it is still a place with an edge.
enum GardenGround {
    // MARK: The cut

    /// How deep the soil is under a place on the plot, in metres.
    ///
    /// The mockup's taper: a floor at the rim everywhere, and a bulge of up to
    /// 1.70 m more toward the middle, measured on the Chebyshev radius so it
    /// follows the square rather than a circle inside it.
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

    /// What `cutDepth` comes to at the rim.
    ///
    /// **The rim is the only depth that is ever seen.** Looking down at
    /// thirty-five degrees, the plot's own surface hides everything under it, so
    /// the bulge below the middle is never drawn and this number is the whole of
    /// what *thick* means. It started at the mockup's 0.40 m, which read as a
    /// tile with a lip; at 0.95 it reads as a piece of ground with a root under
    /// it, which is the thing the cut is there to say.
    static let rimDepth = 0.95

    // MARK: The light

    /// One light, and the ambient it is set against.
    ///
    /// Hemispheric rather than a studio: sky from above, bounce from the ground
    /// below, so a shadowed face is lit by the sky rather than by nothing.
    /// `StageBackdrop` is a hard key and a near-black ambient on purpose, which
    /// is right for a plant photographed for a box and exactly wrong outdoors.
    ///
    /// `GardenLight` is where one of these comes from: the sun and the moon
    /// going round, read by the ground, the plants, the shadows and the sky
    /// alike. Nothing here knows what hour it is.
    struct Light: Equatable, Sendable {
        var direction: SIMD3<Double>
        var colour: SIMD3<Double>
        var strength: Double
        var sky: SIMD3<Double>
        var bounce: SIMD3<Double>
        /// How high the body in the sky is, `0` at the horizon and `1` at its
        /// own peak. The sky, the stars and the softness of a shadow are all
        /// read off this rather than off the hour, so they agree with the light
        /// rather than merely with the clock.
        var up: Double = 1
        /// Which body is up. Exactly one of them ever is.
        var isDay: Bool = true

        /// The sun at its highest, spelled out.
        ///
        /// It is `at(hour: 12)`, and `PlotTests` holds the two to each other. It
        /// is written out rather than computed because it is a default argument
        /// in this file while the orbit is an extension in another, and the
        /// compiler will not reach across for it in that position.
        static let noon = Light(
            direction: SIMD3(-0.331_965_483_940_478_6,
                             0.882_947_592_858_926_9,
                             0.331_965_483_940_478_6),
            colour: SIMD3(1.00, 0.96, 0.88),
            strength: 0.76,
            sky: SIMD3(0.40, 0.48, 0.60),
            bounce: SIMD3(0.27, 0.25, 0.20),
            up: 1,
            isDay: true
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

    /// What a bank of cut earth is made of, top to bottom.
    ///
    /// A cut is not one colour. The dark humus is a hand's depth and no more,
    /// the earth under it holds most of the depth, and rock comes up from the
    /// bottom — which is why a road cutting reads as ground rather than as a
    /// painted edge. Drawn in cells rather than as one face so that the bands
    /// break up, because real strata do.
    /// **Lighter than the ground they sit under, on purpose.** A cut face is
    /// vertical, so it is lit by the sky and by almost none of the sun, and
    /// materials chosen to look right in the hand came out as a black band under
    /// the plot. These are chosen for how they read once the hemispheric ambient
    /// has had them, which is the only way they are ever seen.
    static let humus = SIMD3<Double>(0.205, 0.158, 0.116)
    static let earth = SIMD3<Double>(0.375, 0.300, 0.232)
    static let bedrock = SIMD3<Double>(0.340, 0.330, 0.318)
    static let stone = SIMD3<Double>(0.455, 0.437, 0.415)

    /// The colour of the cut a given fraction of the way down it, before the
    /// light, with the chunkiness already in it.
    ///
    /// `grain` is a number in `0...1` that has to be the same every time for the
    /// same place, so the bank does not crawl when anything is redrawn.
    static func cutColour(down: Double, grain: Double, stones: Double) -> SIMD3<Double> {
        let f = min(max(down, 0), 1)

        var base: SIMD3<Double>
        if f < 0.16 {
            base = humus + (earth - humus) * (f / 0.16)
        } else if f < 0.58 {
            base = earth
        } else {
            base = earth + (bedrock - earth) * ((f - 0.58) / 0.42)
        }

        // A stone here and there, more of them the deeper it goes, and each one
        // a little lighter than what it sits in. `stones` is drawn on a coarser
        // grid than the cells are, so a stone is a stone rather than a speck.
        let stoniness = 0.12 + 0.62 * f
        if stones > 1 - stoniness * 0.5 {
            base = base + (stone - base) * 0.78
        }

        // And everything else varies a little, so no two cells of a bank are the
        // same colour.
        return base * (0.86 + 0.28 * grain)
    }

    /// A fixed number for a place, so a bank of earth is the same bank every
    /// time it is drawn. The usual integer hash: cheap, and it does not matter
    /// that it is not a good one.
    static func grain(_ a: Int, _ b: Int, _ salt: Int = 0) -> Double {
        var h = UInt64(bitPattern: Int64(a &* 73_856_093 ^ b &* 19_349_663 ^ salt &* 83_492_791))
        h ^= h >> 33
        h = h &* 0xff51_afd7_ed55_8ccd
        h ^= h >> 29
        return Double(h % 100_000) / 100_000
    }

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
