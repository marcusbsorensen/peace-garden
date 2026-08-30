import UIKit
import SeedCore

/// Builds the base-to-tip colour ramps the plant's materials are painted with.
///
/// The mesh's `v` coordinate runs from the base of every blade to its tip, so a
/// single vertical gradient gives petals their colour change without any
/// per-vertex colour data.
enum GradientTexture {
    private static let cache = NSCache<NSString, UIImage>()

    static func image(for role: MeshRole, palette: Genome.Palette) -> UIImage {
        let key = cacheKey(role: role, palette: palette) as NSString
        if let cached = cache.object(forKey: key) { return cached }

        let height = 64
        let size = CGSize(width: 8, height: CGFloat(height))
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            for row in 0..<height {
                // Row 0 is the top of the image, which SceneKit samples at
                // v = 1 — the tip of the blade. If a plant ever renders with
                // its tip colour at the base, this is the line to flip.
                let t = 1.0 - Double(row) / Double(height - 1)
                let hsb = PaletteRamp.colour(for: role, at: t, palette: palette)
                UIColor(
                    hue: CGFloat(hsb.hue),
                    saturation: CGFloat(hsb.saturation),
                    brightness: CGFloat(hsb.brightness),
                    alpha: 1
                ).setFill()
                context.fill(CGRect(x: 0, y: CGFloat(row), width: size.width, height: 1))
            }
        }
        cache.setObject(image, forKey: key)
        return image
    }

    private static func cacheKey(role: MeshRole, palette: Genome.Palette) -> String {
        let parts = [palette.petalBase, palette.petalTip, palette.leaf, palette.stem, palette.centre]
            .map { String(format: "%.3f,%.3f,%.3f", $0.hue, $0.saturation, $0.brightness) }
            .joined(separator: "|")
        return "\(role.rawValue)#\(parts)"
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
