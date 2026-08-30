import Foundation

/// Samples the base-to-tip colour ramp for a role.
///
/// The renderer bakes these into small gradient textures and looks them up
/// through the mesh's `v` coordinate, which runs from the base of a blade to
/// its tip. Keeping the ramp here means the colour of a plant is part of its
/// genome rather than a renderer decision.
public enum PaletteRamp {
    public static func colour(for role: MeshRole, at t: Double, palette: Genome.Palette) -> HSB {
        let clamped = t.clamped(to: 0...1)
        switch role {
        case .petal:
            return interpolate(palette.petalBase, palette.petalTip, clamped)
        case .leaf:
            // Leaves darken very slightly toward the tip.
            var tip = palette.leaf
            tip.brightness = min(1, palette.leaf.brightness * 1.18)
            return interpolate(palette.leaf, tip, clamped)
        case .stem:
            var top = palette.stem
            top.brightness = min(1, palette.stem.brightness * 1.25)
            return interpolate(palette.stem, top, clamped)
        case .centre:
            var edge = palette.centre
            edge.brightness = max(0, palette.centre.brightness * 0.7)
            return interpolate(palette.centre, edge, clamped)
        case .stamen:
            return interpolate(palette.centre, palette.petalTip, clamped)
        }
    }

    /// Interpolates hue the short way round the wheel, so a red-to-magenta ramp
    /// does not detour through green.
    public static func interpolate(_ from: HSB, _ to: HSB, _ t: Double) -> HSB {
        var delta = to.hue - from.hue
        if delta > 0.5 { delta -= 1 }
        if delta < -0.5 { delta += 1 }
        return HSB(
            hue: (from.hue + delta * t).wrappedUnit,
            saturation: from.saturation + (to.saturation - from.saturation) * t,
            brightness: from.brightness + (to.brightness - from.brightness) * t
        )
    }
}
