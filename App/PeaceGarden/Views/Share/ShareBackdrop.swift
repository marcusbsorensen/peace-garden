import SeedCore
import SwiftUI
import UIKit

/// The ground a shared plant stands on, painted once at the picture's size.
///
/// **Everyone's sky is the same sky.** The garden draws the real sky for where
/// the phone is and the hour it is (`GardenSky`, `StarField`), which is right
/// on a phone and wrong in a picture somebody sends: the stars and the moon
/// would say roughly where and when it was made. So the night here is the real
/// sky for one fixed moment and one fixed place — `skyMoment` over `skyPlace`
/// — and the day is the garden's own palette at a fixed hour. A shared plant
/// carries nothing about its gardener, in its pixels either.
///
/// On the main actor because the star catalogue is (`StarField`); one picture
/// is a few thousand dots and a few gradients, and the frames drawn over it are
/// drawn elsewhere.
@MainActor
enum ShareBackdrop {

    /// Midnight at the turn of the year 2026, by the clock at Greenwich.
    static let skyMoment = Date(timeIntervalSince1970: 1_767_225_600)

    /// On the equator at Greenwich, where both halves of the sky turn
    /// overhead: the horizon across the middle has the northern stars above it
    /// and the southern ones below, which is the garden's own idea of a sky
    /// (`GardenSky.stars`) and belongs to nobody in particular.
    static let skyPlace = Place(latitude: 0, longitude: 0)

    /// The hour the day sky is painted at: mid-morning, the sun well up and
    /// still a little gold.
    static let dayHour = 10.5

    static func image(for portrait: PlantPortrait) -> CGImage? {
        let size = portrait.points
        let format = UIGraphicsImageRendererFormat()
        format.scale = portrait.pixelsPerPoint
        format.opaque = true
        format.preferredRange = .standard
        let image = UIGraphicsImageRenderer(size: size, format: format).image { drawing in
            let context = drawing.cgContext
            switch portrait.ground {
            case .nightSky:
                night(in: context, size: size)
                stars(in: context, size: size)
                pool(in: context, portrait: portrait, strength: 0.8)
            case .daySky:
                day(in: context, size: size, scale: portrait.pixelsPerPoint)
            case .stage:
                context.setFillColor(UIColor.black.cgColor)
                context.fill(CGRect(origin: .zero, size: size))
                pool(in: context, portrait: portrait, strength: 1)
            }
        }
        return image.cgImage
    }

    // MARK: The night

    /// `GardenSky`'s night: a radial from a point near the top, dark blue
    /// falling to nearly black. The same three colours, at no light at all.
    private static func night(in context: CGContext, size: CGSize) {
        let near = UIColor(hue: 224 / 360, saturation: 0.44, brightness: 0.085, alpha: 1)
        let middle = UIColor(hue: 222 / 360, saturation: 0.46, brightness: 0.062, alpha: 1)
        let far = UIColor(red: 0.030, green: 0.036, blue: 0.062, alpha: 1)
        guard let gradient = CGGradient(
            colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
            colors: [near.cgColor, middle.cgColor, far.cgColor] as CFArray,
            locations: [0, 0.58, 1]
        ) else { return }
        let centre = CGPoint(x: size.width / 2, y: size.height * 0.24)
        context.drawRadialGradient(
            gradient,
            startCenter: centre, startRadius: size.width * 0.025,
            endCenter: centre, endRadius: max(size.width, size.height) * 1.6,
            options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
        )
    }

    /// The real stars for `skyMoment` over `skyPlace`, drawn the size and the
    /// brightness the garden draws them.
    private static func stars(in context: CGContext, size: CGSize) {
        let placed = StarField.shared.stars(
            at: skyMoment, in: size, place: skyPlace,
            facing: StarField.facing(fromLatitude: skyPlace.latitude, turn: 0)
        )
        for star in placed {
            let colour = UIColor(star.tint).withAlphaComponent(CGFloat(star.alpha))
            context.setFillColor(colour.cgColor)
            context.fillEllipse(in: CGRect(x: star.at.x - star.radius, y: star.at.y - star.radius,
                                           width: star.radius * 2, height: star.radius * 2))
        }
    }

    // MARK: The day

    /// `DaySky`'s painting of the garden's day, with the sun high on the left.
    private static func day(in context: CGContext, size: CGSize, scale: CGFloat) {
        let palette = SkyPalette.at(hour: dayHour, season: .orbit)
        let sun = CGPoint(x: size.width * 0.22, y: size.height * 0.16)
        // Painted at half the picture's pixels: the softest thing in the sky is
        // still dozens of pixels across, as `DaySky.perPoint` says.
        guard let sky = DaySky.paint(palette, sun: sun, size: size, perPoint: max(1, scale / 2))
        else { return }
        context.saveGState()
        context.interpolationQuality = .high
        // `UIGraphicsImageRenderer` draws with y down; a CGImage drawn straight
        // in would land upside down, so it is turned back over for the draw.
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1, y: -1)
        context.draw(sky, in: CGRect(origin: .zero, size: size))
        context.restoreGState()
    }

    // MARK: The pool of light

    /// `StageBackdrop`'s pool, behind the plant: the slate glow nudged toward
    /// the plant's own colour, fading out rather than down so the ground shows
    /// through. Sized by how grown the plant is, as on the stage.
    private static func pool(in context: CGContext, portrait: PlantPortrait, strength: Double) {
        let size = portrait.points
        let hue = StageBackdrop.glowHue(for: portrait.genome.palette)
        var colours: [CGColor] = []
        var locations: [CGFloat] = []
        for index in 0...StageBackdrop.stopCount {
            let t = Double(index) / Double(StageBackdrop.stopCount)
            let level = pow(1 - t, StageBackdrop.falloff) * strength
            colours.append(UIColor(hue: hue, saturation: StageBackdrop.saturation,
                                   brightness: StageBackdrop.brightness, alpha: level).cgColor)
            locations.append(t)
        }
        guard let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                                        colors: colours as CFArray, locations: locations)
        else { return }
        let span = max(size.width, size.height)
        let centre = CGPoint(x: size.width / 2, y: size.height * portrait.plantCentre)
        context.drawRadialGradient(
            gradient,
            startCenter: centre, startRadius: 0,
            endCenter: centre,
            endRadius: span * StageBackdrop.radius(presence: portrait.growth.heightScale),
            options: []
        )
    }
}
