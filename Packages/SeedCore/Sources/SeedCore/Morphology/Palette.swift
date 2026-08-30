import Foundation

/// Samples a plant's surface colour at a point on one of its parts.
///
/// The renderer bakes this into a small texture per material and looks it up
/// through the mesh's own coordinates: `v` runs from the base of a blade to its
/// tip, `u` across it. Two dimensions rather than one is what lets a petal have
/// a throat, veins and a rim, and a leaf have a margin or a stripe, without any
/// extra geometry.
public enum PaletteRamp {
    public static func colour(
        for role: MeshRole,
        u: Double,
        v: Double,
        palette: Genome.Palette
    ) -> HSB {
        let u = u.clamped(to: 0...1)
        let v = v.clamped(to: 0...1)

        switch role {
        case .petal:
            return petal(u: u, v: v, palette: palette)
        case .leaf:
            return leaf(u: u, v: v, palette: palette)
        case .stem:
            var top = palette.stem
            top.brightness = min(1, palette.stem.brightness * 1.25)
            return interpolate(palette.stem, top, v)
        case .centre:
            var edge = palette.centre
            edge.brightness = max(0, palette.centre.brightness * 0.7)
            return interpolate(palette.centre, edge, v)
        case .stamen:
            return interpolate(palette.centre, palette.petalTip, v)
        }
    }

    // MARK: - Petals

    private static func petal(u: Double, v: Double, palette: Genome.Palette) -> HSB {
        // Base to tip, eased so the change happens across the middle of the
        // petal rather than smearing evenly from end to end.
        var colour = interpolate(palette.petalBase, palette.petalTip, smoothstep(v))

        // The throat sits where the petals meet, and fades out quickly.
        let throat = pow(max(0, 1 - v / 0.34), 1.6)
        colour = interpolate(colour, palette.petalThroat, throat * 0.9)

        // Veins run the length of the petal and fade as it widens.
        if palette.veining > 0 {
            let ridges = abs(sin(u * .pi * 5))
            let vein = pow(ridges, 7) * palette.veining * (1 - v * 0.45)
            colour = interpolate(colour, palette.petalVein, vein)
        }

        // A picotee rim follows the whole edge of the petal, sides and tip.
        if let picotee = palette.picotee {
            let side = 1 - min(u, 1 - u) / 0.16
            let tip = (v - 0.86) / 0.14
            let edge = max(0, min(1, max(side, tip)))
            colour = interpolate(colour, picotee, pow(edge, 1.4))
        }

        return colour
    }

    // MARK: - Leaves

    private static func leaf(u: Double, v: Double, palette: Genome.Palette) -> HSB {
        var tip = palette.leaf
        tip.brightness = min(1, palette.leaf.brightness * 1.16)
        var colour = interpolate(palette.leaf, tip, v)

        switch palette.variegation {
        case .none:
            break
        case .margin:
            let edge = max(0, min(1, 1 - min(u, 1 - u) / 0.18))
            colour = interpolate(colour, palette.leafAccent, pow(edge, 1.6) * 0.95)
        case .midrib:
            let centre = max(0, min(1, 1 - abs(u - 0.5) / 0.22))
            colour = interpolate(colour, palette.leafAccent, pow(centre, 1.8) * 0.9)
        case .speckled:
            // Hard-edged patches, the way markings on a leaf actually look.
            // Big and sparse: at a finer grain the leaf reads as damaged
            // rather than marked.
            let patch = speckle(u: u, v: v, seed: palette.speckleSeed, frequency: 4.5)
            if patch > 0.78 {
                colour = interpolate(colour, palette.leafAccent, 0.6)
            }
        }

        return colour
    }

    // MARK: - Helpers

    /// Interpolates hue the short way round the wheel, so a red-to-magenta ramp
    /// does not detour through green.
    public static func interpolate(_ from: HSB, _ to: HSB, _ t: Double) -> HSB {
        let t = t.clamped(to: 0...1)
        var delta = to.hue - from.hue
        if delta > 0.5 { delta -= 1 }
        if delta < -0.5 { delta += 1 }
        return HSB(
            hue: (from.hue + delta * t).wrappedUnit,
            saturation: from.saturation + (to.saturation - from.saturation) * t,
            brightness: from.brightness + (to.brightness - from.brightness) * t
        )
    }

    static func smoothstep(_ t: Double) -> Double {
        let x = t.clamped(to: 0...1)
        return x * x * (3 - 2 * x)
    }
}
