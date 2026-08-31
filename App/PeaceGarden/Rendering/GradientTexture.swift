import UIKit
import SeedCore

/// Bakes a plant's colouring, and its surface relief, into a texture per
/// material.
///
/// The mesh already carries the coordinates this needs: `v` runs from the base
/// of every blade to its tip, `u` across it. Painting an image once and letting
/// the GPU sample it is what gives petals a throat, veins and a rim, and leaves
/// a margin, a stripe and venation, at no cost in geometry.
///
/// Three channels come out of the same bake:
///
/// - **diffuse**, the colour, from `PaletteRamp.colour`
/// - **normal**, the relief, differentiated from `PaletteRamp.relief`
/// - **roughness**, so a vein can be glossier than the blade around it
///
/// The last two are what stop a surface reading as painted plastic. A single
/// scalar roughness and flat normals give every leaf one uniform sheen, and no
/// amount of colour detail recovers from that: the eye reads shape from how
/// light moves across a surface, not from what the surface is coloured.
enum GradientTexture {
    /// `NSCache` is documented as safe to use from several threads at once, and
    /// has been since it was introduced — it simply predates `Sendable` and has
    /// never been annotated. `nonisolated(unsafe)` says that out loud rather
    /// than putting an actor around a class that already does its own locking.
    private nonisolated(unsafe) static let cache = NSCache<NSString, UIImage>()

    /// Sixty-four carried a gradient and nothing else. Venation, quilting and
    /// a picotee rim are patterns, and a pattern needs frequency the way a
    /// gradient does not: at 64 the veins landed between texels and came out
    /// as a grey wash.
    ///
    /// Raising it is only affordable because the HSB conversion below is now
    /// arithmetic rather than a `UIColor` per texel. That change is load
    /// bearing — at this resolution the old path allocated a third of a million
    /// objects per plant and stalled the first frame.
    /// Chosen per role, because they are not looked at from the same distance.
    ///
    /// A leaf can fill a third of the screen and carries the finest pattern on
    /// the plant, so it gets the most. A stem is a few points wide however close
    /// the camera stands, and a stamen has no pattern at all. Baking every role
    /// at the largest size cost five times what the detail was worth.
    private static func resolution(for role: MeshRole) -> Int {
        switch role {
        case .leaf: return 256
        case .petal: return 192
        case .centre: return 96
        case .stem, .stamen: return 64
        }
    }

    // MARK: - Channels

    static func image(for role: MeshRole, palette: Genome.Palette) -> UIImage? {
        cached("diffuse", role: role, palette: palette) {
            renderDiffuse(role: role, palette: palette)
        }
    }

    static func normalImage(for role: MeshRole, palette: Genome.Palette) -> UIImage? {
        cached("normal", role: role, palette: palette) {
            renderNormal(role: role, palette: palette)
        }
    }

    static func roughnessImage(for role: MeshRole, palette: Genome.Palette) -> UIImage? {
        cached("rough", role: role, palette: palette) {
            renderRoughness(role: role, palette: palette)
        }
    }

    private static func cached(
        _ channel: String,
        role: MeshRole,
        palette: Genome.Palette,
        build: () -> UIImage?
    ) -> UIImage? {
        let key = "\(channel)#\(cacheKey(role: role, palette: palette))" as NSString
        if let cached = cache.object(forKey: key) { return cached }
        guard let image = build() else { return nil }
        cache.setObject(image, forKey: key)
        return image
    }

    // MARK: - Baking

    private static func renderDiffuse(role: MeshRole, palette: Genome.Palette) -> UIImage? {
        let side = resolution(for: role)
        var pixels = [UInt8](repeating: 255, count: side * side * 4)

        for y in 0..<side {
            let v = texelV(y, side)
            for x in 0..<side {
                let u = texelU(x, side)
                let hsb = PaletteRamp.colour(for: role, u: u, v: v, palette: palette)
                let (red, green, blue) = rgb(of: hsb)
                let offset = (y * side + x) * 4
                pixels[offset] = red
                pixels[offset + 1] = green
                pixels[offset + 2] = blue
                pixels[offset + 3] = 255
            }
        }
        return image(from: pixels, side: side)
    }

    /// Differentiates the relief field into a tangent-space normal map.
    ///
    /// If a plant's veins read as grooves cut into the blade rather than as
    /// ridges standing off it, the green channel's sign is the line to flip.
    /// SceneKit reads these the OpenGL way round, with +Y up the texture, and
    /// row 0 of this image is `v = 1` — so the two conventions already disagree
    /// once, and the negation below is what settles it.
    private static func renderNormal(role: MeshRole, palette: Genome.Palette) -> UIImage? {
        let side = resolution(for: role)
        let heights = reliefField(role: role, palette: palette)
        var pixels = [UInt8](repeating: 255, count: side * side * 4)

        func height(_ x: Int, _ y: Int) -> Double {
            heights[min(side - 1, max(0, y)) * side + min(side - 1, max(0, x))]
        }

        // How much apparent depth the relief stands for. Enough for the light
        // to find it across a leaf that fills a third of the screen, and short
        // of the point where a plant looks hammered out of metal.
        let strength = reliefStrength(for: role)

        for y in 0..<side {
            for x in 0..<side {
                let dx = (height(x + 1, y) - height(x - 1, y)) * strength
                let dy = (height(x, y + 1) - height(x, y - 1)) * strength
                var nx = -dx
                var ny = dy
                var nz = 1.0
                let length = (nx * nx + ny * ny + nz * nz).squareRoot()
                nx /= length; ny /= length; nz /= length

                let offset = (y * side + x) * 4
                pixels[offset] = byte((nx + 1) * 0.5)
                pixels[offset + 1] = byte((ny + 1) * 0.5)
                pixels[offset + 2] = byte((nz + 1) * 0.5)
                pixels[offset + 3] = 255
            }
        }
        return image(from: pixels, side: side)
    }

    /// Breaks up the single uniform sheen.
    ///
    /// A vein holds moisture and shines; the blade between veins is matte. One
    /// scalar for the whole surface is what makes a leaf look moulded, and this
    /// is a cheaper fix than any amount of extra geometry.
    private static func renderRoughness(role: MeshRole, palette: Genome.Palette) -> UIImage? {
        let side = resolution(for: role)
        let heights = reliefField(role: role, palette: palette)
        let (base, swing) = roughnessRange(for: role, palette: palette)
        var pixels = [UInt8](repeating: 255, count: side * side * 4)

        for index in 0..<(side * side) {
            // Raised ground is smoother, which is the way a vein or a rib
            // actually catches light against the tissue either side of it.
            let value = clamp(base - (heights[index] - 0.5) * swing, 0.05, 1)
            let level = byte(value)
            let offset = index * 4
            pixels[offset] = level
            pixels[offset + 1] = level
            pixels[offset + 2] = level
            pixels[offset + 3] = 255
        }
        return image(from: pixels, side: side)
    }

    /// The relief sampled once and shared by the normal and roughness bakes, so
    /// the ridge the light catches and the gloss on it are the same ridge.
    private static func reliefField(role: MeshRole, palette: Genome.Palette) -> [Double] {
        let side = resolution(for: role)
        var heights = [Double](repeating: 0, count: side * side)
        for y in 0..<side {
            let v = texelV(y, side)
            for x in 0..<side {
                heights[y * side + x] = PaletteRamp.relief(
                    for: role, u: texelU(x, side), v: v, palette: palette
                )
            }
        }
        return heights
    }

    private static func reliefStrength(for role: MeshRole) -> Double {
        switch role {
        // Every one of these came down after the first render. Relief that
        // reads as convincing in the abstract reads as corrugated iron on a
        // blade the size of a thumb, and the failure is not subtle: the leaves
        // came out as pleated card and the flower centres as woven basket.
        case .leaf: return 14
        case .petal: return 10
        case .stem: return 9
        case .centre: return 8
        case .stamen: return 0
        }
    }

    private static func roughnessRange(for role: MeshRole, palette: Genome.Palette) -> (Double, Double) {
        switch role {
        // The swings are deliberately small. Taking roughness far down on the
        // raised ground gave every ridge a hot specular, and with HDR and a
        // bloom threshold of 0.82 above it those clipped to white — so the
        // detail that was supposed to appear was the detail that burnt out.
        case .stem: return (0.75, 0.12)
        case .leaf: return (0.62 - palette.sheen * 0.3, 0.16)
        case .petal: return (0.45 - palette.sheen * 0.3, 0.10)
        case .centre: return (0.55, 0.12)
        case .stamen: return (0.4, 0)
        }
    }

    // MARK: - Sampling

    /// Row 0 is the top of the image, which SceneKit samples at v = 1 — the tip
    /// of the blade. If a plant renders with its tip colour at the base, this is
    /// the line to flip.
    private static func texelV(_ y: Int, _ side: Int) -> Double {
        1 - Double(y) / Double(side - 1)
    }

    private static func texelU(_ x: Int, _ side: Int) -> Double {
        Double(x) / Double(side - 1)
    }

    // MARK: - Colour

    /// HSB to RGB as arithmetic.
    ///
    /// This was `UIColor.getRed(_:green:blue:alpha:)`, which is correct and
    /// allocates an object per texel. At 64 square nobody noticed; at 256 it is
    /// the difference between a texture that bakes in milliseconds and one that
    /// visibly stalls the first frame of a plant.
    static func rgb(of hsb: HSB) -> (UInt8, UInt8, UInt8) {
        let saturation = clamp(hsb.saturation, 0, 1)
        let brightness = clamp(hsb.brightness, 0, 1)
        var hue = hsb.hue.truncatingRemainder(dividingBy: 1)
        if hue < 0 { hue += 1 }

        let sector = hue * 6
        let chroma = brightness * saturation
        let second = chroma * (1 - abs(sector.truncatingRemainder(dividingBy: 2) - 1))
        let floor = brightness - chroma

        let (red, green, blue): (Double, Double, Double)
        switch Int(sector) % 6 {
        case 0: (red, green, blue) = (chroma, second, 0)
        case 1: (red, green, blue) = (second, chroma, 0)
        case 2: (red, green, blue) = (0, chroma, second)
        case 3: (red, green, blue) = (0, second, chroma)
        case 4: (red, green, blue) = (second, 0, chroma)
        default: (red, green, blue) = (chroma, 0, second)
        }
        return (byte(red + floor), byte(green + floor), byte(blue + floor))
    }

    private static func clamp(_ value: Double, _ low: Double, _ high: Double) -> Double {
        Swift.min(high, Swift.max(low, value))
    }

    private static func byte(_ value: Double) -> UInt8 {
        UInt8(max(0, min(255, (value * 255).rounded())))
    }

    private static func image(from pixels: [UInt8], side: Int) -> UIImage? {
        guard let provider = CGDataProvider(data: Data(pixels) as CFData),
              let cgImage = CGImage(
                width: side,
                height: side,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: side * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                provider: provider,
                decode: nil,
                shouldInterpolate: true,
                intent: .defaultIntent
              )
        else { return nil }

        return UIImage(cgImage: cgImage)
    }

    /// Every field that changes a pixel has to be in the key, or two plants
    /// that differ only in their markings would share one texture.
    private static func cacheKey(role: MeshRole, palette: Genome.Palette) -> String {
        func swatch(_ hsb: HSB?) -> String {
            guard let hsb else { return "-" }
            return String(format: "%.3f,%.3f,%.3f", hsb.hue, hsb.saturation, hsb.brightness)
        }
        let swatches = [
            palette.petalBase, palette.petalTip, palette.petalThroat,
            palette.petalVein, palette.picotee, palette.leaf,
            palette.leafAccent, palette.leafVein, palette.stem, palette.centre,
            palette.marble
        ].map(swatch).joined(separator: "|")
        return [
            role.rawValue,
            swatches,
            String(format: "%.3f", palette.veining),
            String(format: "%.3f", palette.leafVeining),
            String(format: "%.3f", palette.leafQuilting),
            String(format: "%.3f", palette.sheen),
            palette.variegation.rawValue,
            palette.marbling.rawValue,
            String(format: "%.3f", palette.marbleScale),
            String(palette.marbleSeed),
            String(palette.speckleSeed)
        ].joined(separator: "#")
    }

    static func colour(_ hsb: HSB, alpha: CGFloat = 1) -> UIColor {
        UIColor(
            hue: CGFloat(hsb.hue),
            saturation: CGFloat(hsb.saturation),
            brightness: CGFloat(hsb.brightness),
            alpha: alpha
        )
    }
}
