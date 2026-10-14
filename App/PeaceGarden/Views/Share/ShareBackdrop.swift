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
/// `ShareGround.byTheHour`, follows the hour on this phone's clock
/// (`ShareSky`): when in a day, which a plant in sunlight says anyway, and
/// nothing about where. **Its dusk is the time-lapse's** (21C, the same day):
/// the garden's day by day, the time-lapse's rose and mauve at dusk and dawn,
/// and the garden's starry night at night.
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
                let sky = ShareSky.at(hour: portrait.hour)
                draw(sky, in: context, size: size, scale: portrait.pixelsPerPoint)
                pool(in: context, portrait: portrait, strength: sky.pool)
            }
        }
        return image.cgImage
    }

    // MARK: By the hour

    /// The sky of the hour, as `ShareSky` weighs it: the garden's night
    /// underneath; the time-lapse's sky for the sun's height over it
    /// (`TimeLapseSky`), drawn as the time-lapse draws it over a dark stage;
    /// the garden's day over that once the sun is up; then the fixed stars, out
    /// as far as the time-lapse has its own. Each comes in over the one before
    /// as the sun moves, so no minute of the clock is a jump.
    private static func draw(_ sky: ShareSky, in context: CGContext, size: CGSize, scale: CGFloat) {
        if sky.day < 0.999 {
            night(in: context, size: size, up: sky.moon)
            if sky.twilight > 0.001 {
                TimeLapseSky.draw(TimeLapseSky.Moment(elevation: sky.elevation, presence: 1),
                                  in: context, size: size, look: ShareSky.twilightLook(sky.twilight))
            }
        }
        if sky.day > 0.001, let hour = sky.hour {
            context.saveGState()
            context.setAlpha(CGFloat(min(1, sky.day)))
            day(in: context, size: size, scale: scale, hour: hour)
            context.restoreGState()
        }
        stars(in: context, size: size, showing: sky.stars)
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
/// **21C** (Marcus, 14 October 2026, from
/// `design/ui-followups-2026-10-14/backgrounds-hours.png`): the garden's day by
/// day, **the time-lapse's rose and mauve for dusk and dawn**
/// (`TimeLapseSky`), and the garden's starry night at night. The garden's own
/// dusk is short and faint; at ten past six it already read as night.
///
/// **Three skies, handed over rather than switched.** Each is a weight, and
/// `ShareBackdrop` lays them one over another:
/// - `twilight`, the time-lapse's sky over the garden's night: all of it from
///   the height where the time-lapse's colours have become the night's own
///   (`TimeLapseSky.twilightSpan`'s lower end) upwards, thinning to nothing by
///   `afterglowDepth`, so the dusk deepens into the starry night;
/// - `day`, the garden's day over both: coming in over the first degrees of
///   the sun's climb, up to where the time-lapse's colours are the day's
///   (`twilightSpan`'s upper end). Six o'clock, the sun on the horizon, is dawn;
/// - `stars`, the fixed stars: out as far as the time-lapse has its own.
///
/// **Read off the hour as the garden reads it**: the orbit's sun, up from six
/// until eighteen (`SunPath`, `GardenGround.Light.at(hour:)`). Nothing about
/// where the phone is: no latitude, no season, no time zone but the one the
/// clock already shows.
struct ShareSky: Equatable, Sendable {
    /// The hour on the clock, `0..<24`; nil when it could not be had.
    var hour: Double?
    /// The sun's height at that hour in degrees, negative under the horizon.
    var elevation: Double
    /// How much of the garden's day is laid over the rest, `0...1`.
    var day: Double
    /// How much of the time-lapse's sky is laid over the garden's night.
    var twilight: Double
    /// How far out the fixed stars are.
    var stars: Double
    /// How strong the plant's pool of light is behind it: it comes up with the
    /// dark, as it is a light seen against the night.
    var pool: Double
    /// How high the moon is, `0...1`, which lightens the garden's night a
    /// little, as it does in the garden.
    var moon: Double

    /// How far under the horizon the time-lapse's sky lasts, in degrees: where
    /// the garden's afterglow ends, and the night is the garden's alone.
    static let afterglowDepth = 24.0

    /// The pool at night, as it was on the night ground.
    static let poolAtNight = 0.8

    /// The night at no light at all — what a shared plant stood on before
    /// 14 October, and what it stands on when the hour cannot be had.
    static let noHour = ShareSky(hour: nil, elevation: -90, day: 0, twilight: 0,
                                 stars: 1, pool: poolAtNight, moon: 0)

    static func at(hour: Double?) -> ShareSky {
        guard let hour, hour.isFinite else { return .noHour }
        var clock = hour.truncatingRemainder(dividingBy: 24)
        if clock < 0 { clock += 24 }
        let elevation = SunPath.elevation(atHour: clock)
        let light = GardenGround.Light.at(hour: clock)
        let span = TimeLapseSky.twilightSpan
        return ShareSky(
            hour: clock,
            elevation: elevation,
            day: SkyPalette.smooth(elevation / span.upperBound),
            twilight: SkyPalette.smooth((elevation + afterglowDepth) / (span.lowerBound + afterglowDepth)),
            stars: TimeLapseSky.colours(elevation: elevation).stars,
            pool: poolAtNight * (light.isDay ? 1 - SkyPalette.smooth(light.up / 0.2) : 1),
            moon: light.isDay ? 0 : light.up
        )
    }

    /// How the time-lapse's sky is laid over the night: as the time-lapse lays
    /// it over a dark stage (`TimeLapseSky.Look.dark`), `weight` of the way in,
    /// and with the fixed stars in place of its own.
    static func twilightLook(_ weight: Double) -> TimeLapseSky.Look {
        var look = TimeLapseSky.Look.dark
        look.strength *= min(1, max(0, weight))
        look.drawsStars = false
        return look
    }

    /// The hour on this phone's own clock, in its own time zone, with the
    /// minutes as a fraction; nil if the calendar cannot say.
    static func phoneHour(at date: Date, calendar: Calendar = .current) -> Double? {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        guard let hour = parts.hour else { return nil }
        return Double(hour) + Double(parts.minute ?? 0) / 60
    }
}
