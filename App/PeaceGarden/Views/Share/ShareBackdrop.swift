import SeedCore
import SwiftUI
import UIKit

/// The ground a shared plant stands on, painted once at the picture's size.
///
/// **Everyone's sky is the same sky.** The garden draws the real sky for where
/// the phone is and the hour it is (`GardenSky`, `StarField`), which is right
/// on a phone and wrong in a picture somebody sends: the stars and the moon
/// would say roughly where and when it was made. So the stars here are the
/// real sky for one fixed moment and one fixed place — `skyMoment` over
/// `skyPlace` — at every hour, and the day is the garden's own palette on the
/// orbit's arc rather than the season's. A shared plant carries nothing about
/// its gardener's whereabouts, in its pixels either.
///
/// **The hour is the phone's** (Marcus, 14 October 2026). The ground he chose,
/// `ShareGround.byTheHour`, is the garden's day, dusk or night for the hour on
/// this phone's clock (`ShareSky`): when in a day, which a plant in sunlight
/// says anyway, and nothing about where.
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
                day(in: context, size: size, scale: portrait.pixelsPerPoint, hour: dayHour)
            case .stage:
                context.setFillColor(UIColor.black.cgColor)
                context.fill(CGRect(origin: .zero, size: size))
                pool(in: context, portrait: portrait, strength: 1)
            case .byTheHour:
                sky(ShareSky.at(hour: portrait.hour), in: context, portrait: portrait)
            }
        }
        return image.cgImage
    }

    // MARK: By the hour

    /// The garden's sky as it is at the hour: its day, its night with the last
    /// of the light on the side the sun went down, or its night.
    ///
    /// The stars come out as the garden's do, as the sun nears the horizon
    /// (`GardenSky.stars`), and the plant's pool of light behind it comes up
    /// with the dark, as it is a light seen against the night.
    private static func sky(_ sky: ShareSky, in context: CGContext, portrait: PlantPortrait) {
        let size = portrait.points
        switch sky {
        case .day(let hour):
            let up = GardenGround.Light.at(hour: hour).up
            day(in: context, size: size, scale: portrait.pixelsPerPoint, hour: hour)
            stars(in: context, size: size, showing: max(0, 1 - up * 5))
            pool(in: context, portrait: portrait, strength: 0.8 * (1 - SkyPalette.smooth(up / 0.2)))
        case .twilight(let hour):
            night(in: context, size: size, up: GardenGround.Light.at(hour: hour).up)
            afterglow(in: context, size: size, hour: hour)
            stars(in: context, size: size)
            pool(in: context, portrait: portrait, strength: 0.8)
        case .night(let hour):
            night(in: context, size: size, up: hour.map { GardenGround.Light.at(hour: $0).up } ?? 0)
            stars(in: context, size: size)
            pool(in: context, portrait: portrait, strength: 0.8)
        }
    }

    /// Where the sun stands in the picture at an hour: on the left in the
    /// morning and the right in the afternoon, at the horizon across the
    /// middle when it is low and no higher than a third of the way down when
    /// it is high — below a lock screen's clock, as the day ground's always
    /// was. Under the horizon it is where its last light comes from.
    static func sun(atHour hour: Double, in size: CGSize) -> CGPoint {
        let elevation = SunPath.elevation(atHour: hour)
        let across = hour.truncatingRemainder(dividingBy: 24) < 12 ? 0.14 : 0.86
        let down = elevation > 0
            ? 0.5 - 0.17 * min(1, elevation / 45)
            : 0.5 - elevation / 180
        return CGPoint(x: size.width * across, y: size.height * down)
    }

    /// `DaySky.afterglow`, the garden's own, drawn where the sun went down
    /// (or will come up), screened over the night as the garden screens it.
    private static func afterglow(in context: CGContext, size: CGSize, hour: Double) {
        let depth = -SunPath.elevation(atHour: hour)
        let sun = sun(atHour: hour, in: size)
        let glow = Canvas { canvas, canvasSize in
            DaySky.afterglow(depth: depth, sun: sun, in: &canvas, size: canvasSize)
        }
        .frame(width: size.width, height: size.height)
        let renderer = ImageRenderer(content: glow)
        // It has no edge anywhere, so a pixel a point is plenty.
        renderer.scale = 1
        guard let image = renderer.cgImage else { return }
        context.saveGState()
        context.setBlendMode(.screen)
        context.interpolationQuality = .high
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1, y: -1)
        context.draw(image, in: CGRect(origin: .zero, size: size))
        context.restoreGState()
    }

    // MARK: The night

    /// `GardenSky`'s night: a radial from a point near the top, dark blue
    /// falling to nearly black, a little lighter the higher the moon (`up`),
    /// as the garden's is. With no moon, at no light at all.
    private static func night(in context: CGContext, size: CGSize, up: Double = 0) {
        let near = UIColor(hue: 224 / 360, saturation: 0.44, brightness: 0.085 + 0.055 * up, alpha: 1)
        let middle = UIColor(hue: 222 / 360, saturation: 0.46, brightness: 0.062 + 0.030 * up, alpha: 1)
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
    /// brightness the garden draws them, `showing` of the way out.
    private static func stars(in context: CGContext, size: CGSize, showing: Double = 1) {
        guard showing > 0.01 else { return }
        let placed = StarField.shared.stars(
            at: skyMoment, in: size, place: skyPlace,
            facing: StarField.facing(fromLatitude: skyPlace.latitude, turn: 0)
        )
        for star in placed {
            let colour = UIColor(star.tint).withAlphaComponent(CGFloat(star.alpha * showing))
            context.setFillColor(colour.cgColor)
            context.fillEllipse(in: CGRect(x: star.at.x - star.radius, y: star.at.y - star.radius,
                                           width: star.radius * 2, height: star.radius * 2))
        }
    }

    // MARK: The day

    /// `DaySky`'s painting of the garden's day at an hour, on the orbit's arc,
    /// with the sun where `sun(atHour:in:)` puts it, so its halo is not behind
    /// a lock screen's clock.
    private static func day(in context: CGContext, size: CGSize, scale: CGFloat, hour: Double) {
        let palette = SkyPalette.at(hour: hour, season: .orbit)
        let sun = sun(atHour: hour, in: size)
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
        guard strength > 0.005 else { return }
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

/// The sky a shared plant stands under, by the hour on this phone's clock
/// (Marcus, 14 October 2026: *"can we follow the time of day/night on the
/// user's phone? Otherwise night sky"*).
///
/// **Read off the hour as the garden reads it**: the orbit's sun, up from six
/// until eighteen (`GardenGround.Light.at(hour:)`), and its last light lingering in the
/// sky until it is twenty-four degrees under (`DaySky.afterglow`). Nothing
/// about where the phone is: no latitude, no season, no time zone but the one
/// the clock already shows.
enum ShareSky: Equatable, Sendable {
    /// The sun up: the garden's day sky.
    case day(hour: Double)
    /// Dusk or dawn: the sun under the horizon, its light still low on the
    /// side it went down or will come up, over the night.
    case twilight(hour: Double)
    /// The night. With no hour, the night at no light at all — what a shared
    /// plant stood on before 14 October, and what it stands on when the hour
    /// cannot be had.
    case night(hour: Double?)

    /// How far under the horizon the sun's last light lasts, in degrees: where
    /// the garden's afterglow ends.
    static let afterglowDepth = 24.0

    static func at(hour: Double?) -> ShareSky {
        guard let hour, hour.isFinite else { return .night(hour: nil) }
        var clock = hour.truncatingRemainder(dividingBy: 24)
        if clock < 0 { clock += 24 }
        if GardenGround.Light.at(hour: clock).isDay { return .day(hour: clock) }
        if -SunPath.elevation(atHour: clock) < afterglowDepth { return .twilight(hour: clock) }
        return .night(hour: clock)
    }

    /// The hour on this phone's own clock, in its own time zone, with the
    /// minutes as a fraction; nil if the calendar cannot say.
    static func phoneHour(at date: Date, calendar: Calendar = .current) -> Double? {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        guard let hour = parts.hour else { return nil }
        return Double(hour) + Double(parts.minute ?? 0) / 60
    }
}
