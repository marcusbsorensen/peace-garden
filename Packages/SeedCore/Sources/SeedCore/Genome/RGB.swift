#if os(WASI)
import FoundationEssentials
import WASILibc
#else
import Foundation
#endif

public extension HSB {
    /// The colour as 8-bit red, green and blue.
    ///
    /// Here rather than in the app's texture baker because the website bakes
    /// the same textures from the same palette: a plant's colour on a web page
    /// comes from this one conversion, the same one the phone uses.
    ///
    /// Arithmetic rather than `UIColor.getRed(_:green:blue:alpha:)`, which
    /// allocates an object per texel. At 256 square that is the difference
    /// between a texture that bakes in milliseconds and one that visibly stalls
    /// the first frame of a plant.
    var rgb8: (red: UInt8, green: UInt8, blue: UInt8) {
        let saturation = Swift.min(1, Swift.max(0, self.saturation))
        let brightness = Swift.min(1, Swift.max(0, self.brightness))
        var hue = self.hue.truncatingRemainder(dividingBy: 1)
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
        return (Self.byte(red + floor), Self.byte(green + floor), Self.byte(blue + floor))
    }

    private static func byte(_ value: Double) -> UInt8 {
        UInt8(Swift.max(0, Swift.min(255, (value * 255).rounded())))
    }
}
