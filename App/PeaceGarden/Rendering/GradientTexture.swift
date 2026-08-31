import UIKit
import SeedCore

/// Bakes a plant's colouring into a small texture per material.
///
/// The mesh already carries the coordinates this needs: `v` runs from the base
/// of every blade to its tip, `u` across it. Painting a 64×64 image once and
/// letting the GPU sample it is what gives petals a throat, veins and a rim,
/// and leaves a margin or a stripe, at no cost in geometry.
enum GradientTexture {
    /// `NSCache` is documented as safe to use from several threads at once, and
    /// has been since it was introduced — it simply predates `Sendable` and has
    /// never been annotated. `nonisolated(unsafe)` says that out loud rather
    /// than putting an actor around a class that already does its own locking.
    private nonisolated(unsafe) static let cache = NSCache<NSString, UIImage>()
    private static let resolution = 64

    static func image(for role: MeshRole, palette: Genome.Palette) -> UIImage? {
        let key = cacheKey(role: role, palette: palette) as NSString
        if let cached = cache.object(forKey: key) { return cached }
        guard let image = render(role: role, palette: palette) else { return nil }
        cache.setObject(image, forKey: key)
        return image
    }

    private static func render(role: MeshRole, palette: Genome.Palette) -> UIImage? {
        let side = resolution
        var pixels = [UInt8](repeating: 255, count: side * side * 4)

        for y in 0..<side {
            // Row 0 is the top of the image, which SceneKit samples at v = 1 —
            // the tip of the blade. If a plant renders with its tip colour at
            // the base, this is the line to flip.
            let v = 1 - Double(y) / Double(side - 1)
            for x in 0..<side {
                let u = Double(x) / Double(side - 1)
                let hsb = PaletteRamp.colour(for: role, u: u, v: v, palette: palette)
                let (red, green, blue) = components(of: hsb)
                let offset = (y * side + x) * 4
                pixels[offset] = red
                pixels[offset + 1] = green
                pixels[offset + 2] = blue
                pixels[offset + 3] = 255
            }
        }

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

    private static func components(of hsb: HSB) -> (UInt8, UInt8, UInt8) {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        colour(hsb).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (
            UInt8(max(0, min(255, red * 255))),
            UInt8(max(0, min(255, green * 255))),
            UInt8(max(0, min(255, blue * 255)))
        )
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
            palette.leafAccent, palette.stem, palette.centre
        ].map(swatch).joined(separator: "|")
        return [
            role.rawValue,
            swatches,
            String(format: "%.3f", palette.veining),
            palette.variegation.rawValue,
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
