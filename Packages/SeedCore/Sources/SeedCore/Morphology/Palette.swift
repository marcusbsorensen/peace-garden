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

        // Broken pigment, where a flower has it. Laid over the veins and under
        // the rim: a flame runs through the vein pattern rather than round it,
        // and a picotee edge survives the break, which is what keeps a marbled
        // flower looking like one flower rather than two patterns arguing.
        if palette.marbling != .none {
            colour = interpolate(colour, palette.marble, breaking(u: u, v: v, palette: palette))
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

    /// How far the pigment has broken at a point on a petal, 0 to 1.
    ///
    /// All three patterns are the same noise read through a different
    /// coordinate, which is what keeps them relatives rather than three
    /// unrelated effects: flames stretch it along the petal, brushing stretches
    /// it much further, and marbling warps the coordinate by more noise before
    /// reading it — the warp is the whole trick, and it is the difference
    /// between clouds and swirls.
    ///
    /// The result is pushed toward its ends, because pigment that has half
    /// broken everywhere is a wash. A break wants an edge.
    public static func breaking(u: Double, v: Double, palette: Genome.Palette) -> Double {
        let scale = palette.marbleScale
        let seed = palette.marbleSeed

        var field: Double
        switch palette.marbling {
        case .none:
            return 0
        case .flamed:
            // Stretched along the petal, so the pattern runs base to tip.
            field = fbm(x: u * scale * 2.4, y: v * scale * 0.5, seed: seed)
        case .brushed:
            field = fbm(x: u * scale * 4.5, y: v * scale * 0.22, seed: seed, octaves: 3)
        case .marbled:
            // Domain warp: read the noise at a point the noise itself moved.
            let warpX = fbm(x: u * scale, y: v * scale, seed: seed &+ 101)
            let warpY = fbm(x: u * scale, y: v * scale, seed: seed &+ 202)
            field = fbm(
                x: u * scale + (warpX - 0.5) * 2.6,
                y: v * scale + (warpY - 0.5) * 2.6,
                seed: seed
            )
        }

        // Harden the edge. Smoothstep across a narrow band around the middle
        // turns a cloud into a flame with a boundary you can see.
        let contrast = smoothstep((field - 0.42) / 0.26 + 0.5)

        // A flower breaks from the base outward, and the tip is the last to go.
        let fromBase = palette.marbling == .flamed ? (1 - pow(v, 1.7) * 0.55) : 1
        return (contrast * fromBase).clamped(to: 0...1)
    }

    // MARK: - Leaves

    private static func leaf(u: Double, v: Double, palette: Genome.Palette) -> HSB {
        // A real leaf is oldest and darkest where it joins the stem and
        // youngest at the tip. Sixteen percent of brightness was not enough of
        // a journey to see across a blade that fills a third of the screen.
        var tip = palette.leaf
        tip.brightness = min(1, palette.leaf.brightness * 1.42)
        tip.saturation = palette.leaf.saturation * 0.86
        var base = palette.leaf
        base.brightness = palette.leaf.brightness * 0.72
        var colour = interpolate(base, tip, smoothstep(v))

        // The margin catches the light and runs slightly paler, which is what
        // gives a blade an edge instead of ending at a silhouette.
        let fromMidrib = abs(u - 0.5) * 2
        var rim = colour
        rim.brightness = min(1, colour.brightness * 1.18)
        colour = interpolate(colour, rim, pow(fromMidrib, 3.5) * 0.5)

        if palette.leafVeining > 0 {
            // Held to well under a full swap even at the top of the gene's
            // range. A vein darker than the blade is a vein; a vein that
            // replaces the blade is a stripe.
            let strength = venation(u: u, v: v, palette: palette) * palette.leafVeining * 0.6
            colour = interpolate(colour, palette.leafVein, strength)
        }

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

    /// How strongly a leaf's veins show at a point, 0 to 1.
    ///
    /// Pinnate venation: one midrib the length of the blade, and secondaries
    /// leaving it at an angle and running out toward the margin. The angle is
    /// what matters — veins drawn straight across read as a grille, and veins
    /// drawn straight up read as celery. Sweeping them back toward the base as
    /// they travel outward is the shape almost every broad leaf actually has.
    ///
    /// Shared with `relief`, so the ridges the light catches sit exactly where
    /// the darker colour is rather than a fraction beside it.
    public static func venation(u: Double, v: Double, palette: Genome.Palette) -> Double {
        let fromMidrib = abs(u - 0.5) * 2

        // The midrib itself: narrow, and tapering away before the tip so the
        // blade closes rather than ending on a stripe.
        let midrib = pow(max(0, 1 - fromMidrib / 0.11), 1.4) * (1 - pow(v, 6))

        // Secondaries. The count rides on the same gene as the strength, so a
        // strongly veined leaf is also a finely veined one.
        let count = 5.0 + palette.leafVeining * 7
        let swept = v - fromMidrib * 0.42
        let ridges = abs(sin(swept * .pi * count))
        // Fade them into the midrib, so they appear to leave it rather than
        // cross it, and out at the margin where a real vein has thinned away.
        let root = min(1, fromMidrib / 0.14)
        let margin = 1 - pow(fromMidrib, 4)
        // The exponent is what decides whether these are lines or bands, and
        // bands are what a corrugated roof is made of. A strongly veined genome
        // sat at the top of the range and came out as pleated metal; the veins
        // have to stay thin however far the gene is pushed.
        let secondary = pow(ridges, 16) * root * margin * 0.6

        return min(1, max(midrib, secondary))
    }

    /// The height of a surface above its own plane at a point, 0 to 1.
    ///
    /// This is not colour. The renderer differentiates it to build a normal
    /// map, which is the whole of why a leaf stops reading as a painted panel:
    /// a blade quilted between its veins catches the light in a hundred places
    /// that flat geometry has no way to show. It costs one more texture and no
    /// triangles at all.
    ///
    /// Kept beside `colour` on purpose. The two are sampled at the same `(u, v)`
    /// from the same genes, so relief and marking can never drift apart.
    public static func relief(for role: MeshRole, u: Double, v: Double, palette: Genome.Palette) -> Double {
        let u = u.clamped(to: 0...1)
        let v = v.clamped(to: 0...1)

        switch role {
        case .leaf:
            // Veins stand proud of the blade, and the blade sinks between them.
            let veins = venation(u: u, v: v, palette: palette)
            let quilt = quilting(u: u, v: v, palette: palette) * palette.leafQuilting
            return (0.45 + veins * 0.4 - quilt * 0.16).clamped(to: 0...1)
        case .petal:
            // Much softer. A petal that reads as quilted reads as crumpled.
            let ridges = abs(sin(u * .pi * 5))
            let veins = pow(ridges, 7) * palette.veining * (1 - v * 0.45)
            return (0.5 + veins * 0.22).clamped(to: 0...1)
        case .stem:
            // Longitudinal ribbing, the way a stem carries its vascular bundles.
            let ribs = abs(sin(u * .pi * 6))
            return (0.5 + pow(ribs, 3) * 0.16).clamped(to: 0...1)
        case .centre:
            // The packed florets of a composite head.
            //
            // The frequency is low on purpose. `speckle` hashes a cell, so its
            // edges are hard by design — which is right for a marking on a leaf
            // and wrong here, where at a fine grain it aliased into something
            // woven. Big soft cells read as florets; small hard ones read as
            // burlap.
            let bumps = speckle(u: u, v: v, seed: palette.speckleSeed &+ 977, frequency: 8)
            return (0.42 + bumps * 0.4).clamped(to: 0...1)
        case .stamen:
            return 0.5
        }
    }

    /// The puckering of a blade between its veins.
    ///
    /// Two frequencies rather than one: a single sine is a corrugated roof.
    private static func quilting(u: Double, v: Double, palette: Genome.Palette) -> Double {
        let fromMidrib = abs(u - 0.5) * 2
        let count = 5.0 + palette.leafVeining * 7
        let swept = v - fromMidrib * 0.42
        let coarse = sin(swept * .pi * count) * 0.5 + 0.5
        // The second frequency follows the veins too. Running it off `u` alone
        // laid ribs down the length of the blade regardless of where the veins
        // were, and a leaf ribbed lengthwise is corduroy: the puckering has to
        // belong to the vein structure or it fights it.
        let fine = sin(swept * .pi * count * 2.3 + fromMidrib * 4.1) * 0.5 + 0.5
        return (coarse * 0.72 + fine * 0.28) * (1 - pow(fromMidrib, 3))
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
