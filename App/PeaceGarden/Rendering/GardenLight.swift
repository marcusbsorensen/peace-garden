import Foundation
import simd

/// The sun and the moon going round the plot.
///
/// The sun is up from 06:00 to 18:00 and the moon does the same twelve hours out
/// of phase, so **exactly one of them is above the horizon at any hour** — which
/// is why there is one light direction here rather than two. Each rises at one
/// corner of the plot and sets at the opposite one, highest at its own midpoint.
///
/// **Written once and read by everything.** The ground, the plants, the shadows
/// and the sky all take their light from this function. Two models that merely
/// look alike is how a plant ends up lit from the left on ground lit from the
/// right, with nobody able to say why the picture is wrong.
extension GardenGround.Light {

    /// How high either body climbs at its peak: sixty-two degrees.
    static let peak = 1.082_104_136_236_484_3

    /// The Milky Way at its fullest: cool, faint, and straight overhead.
    ///
    /// **Added 18 September, because a garden you cannot see is not a garden.**
    /// The orbit is right that 18:00 is the darkest hour of the day — the moon has
    /// only just cleared the horizon — and it is also an ordinary time to open the
    /// app, at which point the plot was very nearly black.
    ///
    /// The moon's curve is not what changed, and it is still pinned by its values:
    /// the moon is still a fifth of the sun at best. This is a second light, from
    /// far above, that is there at every hour and is only *noticed* when the sun
    /// is not up — which is true of the real one. So it fades with the sun's
    /// strength rather than switching on at dusk, and at noon it adds nothing,
    /// because the sky outshines it.
    static let galaxyAtFullest = SIMD3<Double>(0.30, 0.34, 0.46)

    /// How much of the galaxy is seen at a given strength of sun or moon.
    static func galaxy(strength: Double) -> SIMD3<Double> {
        galaxyAtFullest * max(0, 1 - strength / 0.5)
    }

    /// The sky's light on the plot at noon under the orbit's own sun. Through
    /// the rest of the day it is mixed down towards `skyByNight` as the sun
    /// sinks, and coloured by the sky that is actually drawn: `skylight`.
    static let skyByDay = SIMD3<Double>(0.40, 0.48, 0.60)
    static let skyByNight = SIMD3<Double>(0.10, 0.13, 0.22)
    static let bounceByDay = SIMD3<Double>(0.27, 0.25, 0.20)
    static let bounceByNight = SIMD3<Double>(0.06, 0.07, 0.10)

    /// The sun's own colour high in a clear sky: a little warm of white.
    static let sunHigh = SIMD3<Double>(1.00, 0.96, 0.88)

    // MARK: Warmed by the sky it is under

    /// How far the sun's colour goes to the drawn glow when the sun is on the
    /// horizon. Not all the way: the glow is the air round the disc, and the
    /// light that reaches the ground through it is a shade paler.
    static let sunWarming = 0.85

    /// How much of the drawn sky's change of colour the sky's light takes:
    /// enough that the ground under a gold sky is warm, and short of all of
    /// it, so the shade — which is lit by the sky alone — stays cooler than
    /// the sunlit ground beside it. That difference is what lets a long
    /// evening shadow read as shade rather than as a dark patch.
    static let skyWarming = 0.6

    /// The sun's light at the height this palette was drawn for.
    ///
    /// **Warmed by 2 October's sky, on Marcus's word.** He chose the day sky
    /// that goes gold and rose as the sun gets low, and then asked for the
    /// plot to be lit by it: until then the sky warmed through the evening
    /// and the ground under it stayed noon-white. So the sun's colour is the
    /// palette's own `glow` — the colour drawn round the sun's disc — taken
    /// in by how low the palette says the sun is. Above thirty degrees that
    /// is nothing, so a summer noon is the noon it always was; at five on a
    /// summer evening, sixteen degrees up, it is a pale gold; on the horizon
    /// it is the orange of the disc going down. A December noon in London
    /// stands fifteen degrees up, and is lit like a summer evening.
    ///
    /// **Warmer, not darker.** Gold is white with blue taken out, and taken
    /// out of a light that was already weak it read as dusk. So the colour
    /// keeps the brightness the sun had high in the sky, which leaves its red
    /// a little over one: the ground's arithmetic takes that as it is, and a
    /// plant's lamp is handed it as a colour and an intensity
    /// (`GardenSprites.makeScene`).
    static func sunlight(under palette: SkyPalette) -> SIMD3<Double> {
        let warm = SkyPalette.mix(sunHigh, palette.glow, sunWarming * palette.low)
        return warm * (luminance(sunHigh) / luminance(warm))
    }

    /// The sky's light on the plot: `plain` — the old curve, which says how
    /// much of it there is — in the colour of the sky that is drawn.
    ///
    /// **The colour moves; the amount does not.** The sky's light is most of
    /// what lights the ground once the sun is low — at five o'clock between
    /// two and three times the sun's — so a warm sun over a cold sky would
    /// barely have read as warm. The colour is the air half way between the
    /// drawn zenith and the drawn horizon, measured against that same air
    /// under the orbit's noon, so a summer noon keeps exactly the light it
    /// had, and taken in by `skyWarming`. Its brightness is then put back to
    /// `plain`'s, so an evening is no brighter and no darker for being warm,
    /// and the shadows keep the depth Marcus set for them.
    static func skylight(under palette: SkyPalette, plain: SIMD3<Double>) -> SIMD3<Double> {
        let shift = air(palette) / air(clearNoon)
        let tint = SIMD3(pow(shift.x, skyWarming), pow(shift.y, skyWarming), pow(shift.z, skyWarming))
        let tinted = plain * tint
        let lum = luminance(tinted)
        return lum > 1e-9 ? tinted * (luminance(plain) / lum) : plain
    }

    /// The sky's colour as the ground sees it: overhead and the horizon, half
    /// and half.
    private static func air(_ palette: SkyPalette) -> SIMD3<Double> {
        (palette.zenith + palette.horizon) / 2
    }

    /// The sky the plot's light was set against: the orbit's noon, in no
    /// season's air.
    private static let clearNoon = SkyPalette.at(hour: 12, season: .orbit)

    static func luminance(_ c: SIMD3<Double>) -> Double {
        0.2126 * c.x + 0.7152 * c.y + 0.0722 * c.z
    }

    /// The light at an hour of the day, `0..<24`.
    ///
    /// **The season colours it and does not move it.** The direction and the
    /// strength are the orbit's, whatever the date, so the shadows and the
    /// shading of the hills are as they were; the season moves only the
    /// colour of the sun and of the sky's light, through the palette the day
    /// sky is painted with. The night is the moon's and has no season.
    ///
    /// **The moon was brighter than the dawn**, and it is worth knowing why,
    /// because nothing was broken. The first pass had a full moon overhead at
    /// 0.32 against a sun on the horizon at 0.24, so midnight came out brighter
    /// than sunrise. Both curves peaked correctly at their own maximum; what
    /// nobody had done was make them agree with each other.
    ///
    /// The moon is about a hundred thousand times weaker than the sun. A fifth
    /// is already a generous lie, so that a night garden can be seen at all.
    /// Midnight now reads 0.150 against sunrise at 0.240 and noon at 0.760, and
    /// the darkest hour of the day is moonrise at 18:00 — which is correct: the
    /// moon has only just cleared the horizon.
    ///
    /// **It is a fault that exists only between two things**, and it showed up
    /// only when both were put on one slider. No test would have had an opinion
    /// about it, which is why the curve is pinned by its values rather than by
    /// its shape.
    static func at(hour: Double, season: Season = .orbit) -> GardenGround.Light {
        let clock = ((hour.truncatingRemainder(dividingBy: 24)) + 24)
            .truncatingRemainder(dividingBy: 24)
        let isDay = clock >= 6 && clock < 18
        let through = isDay ? (clock - 6) / 12 : (clock + 6).truncatingRemainder(dividingBy: 24) / 12

        let up = sin(through * .pi)
        let altitude = up * peak
        let azimuth = -Double.pi * 0.75 + through * .pi

        // The floor under the rise keeps a body on the horizon from giving a
        // direction with no height in it at all, which would light the ground
        // edge-on and the plants not at all.
        let direction = simd_normalize(SIMD3(
            cos(altitude) * sin(azimuth),
            max(0.06, sin(altitude)),
            cos(altitude) * cos(azimuth)
        ))

        if isDay {
            let warmth = 0.35 + 0.65 * up
            // The sky that is drawn behind the plot at this hour, from the
            // same sun: see `SkyPalette.at(hour:season:)`.
            let palette = SkyPalette.at(hour: clock, season: season)
            return GardenGround.Light(
                direction: direction,
                colour: sunlight(under: palette),
                strength: 0.24 + 0.52 * up,
                sky: skylight(under: palette, plain: skyByNight + (skyByDay - skyByNight) * warmth),
                bounce: bounceByNight + (bounceByDay - bounceByNight) * warmth,
                up: up,
                isDay: true,
                galaxy: galaxy(strength: 0.24 + 0.52 * up),
                season: season
            )
        }

        let cool = 0.52 + 0.42 * up
        return GardenGround.Light(
            direction: direction,
            colour: SIMD3(0.62, 0.74, 1.00),
            strength: 0.035 + 0.115 * up,
            sky: skyByNight * cool,
            bounce: bounceByNight * cool,
            up: up,
            isDay: false,
            galaxy: galaxy(strength: 0.035 + 0.115 * up),
            season: season
        )
    }

    /// The same light seen from a plot that has been turned a quarter at a time.
    ///
    /// **The plot turns, not the sun.** The sun and moon go round the plot, so
    /// when somebody turns the plot to look at the ravine's other wall, the
    /// light's direction in the plot's own axes turns with it. Rotating the
    /// scene rather than the camera is what keeps the plants' renders and the
    /// ground's shading in step, because both are drawn in plot space.
    func turned(quarters: Int) -> GardenGround.Light {
        let quarter = ((quarters % 4) + 4) % 4
        guard quarter != 0 else { return self }

        let angle = Double(quarter) * .pi / 2
        var turned = self
        turned.direction = SIMD3(
            direction.x * cos(angle) + direction.z * sin(angle),
            direction.y,
            -direction.x * sin(angle) + direction.z * cos(angle)
        )
        return turned
    }

    // MARK: Round the clock in eight

    /// How many points round the clock anything expensive is drawn at.
    ///
    /// The ground is computed and could be drawn at any hour for nothing; the
    /// plants are meshes nobody wants to rebuild at sixty frames a second. Eight
    /// is what the mockup settled on: close enough that a crossfade between two
    /// of them reads as the light moving, and few enough that a whole garden's
    /// worth fits in a cache. The ground uses the same eight so that it and the
    /// plants are never lit from different hours.
    static let steps = 8

    /// **The two hand-overs, each seen from the side it is reached from.**
    ///
    /// At six the sun and the moon change places on opposite horizons, so the
    /// step at six is two lights, not one. Until 2 October it was whichever
    /// the clock said: six in the morning was the sun rising, six in the
    /// evening the moon rising. So from three o'clock every afternoon a
    /// plant was crossfaded towards a moonlit picture of itself, two thirds
    /// moonlit by five, while the ground beside it was still in the sun; and
    /// from three in the morning towards the dawn, while the ground was in
    /// moonlight. Once the evening sun was gold that showed: a gold lawn and
    /// moonlit flowers on it.
    ///
    /// So a step is read from the side of the hour that wants it. The last
    /// afternoon step reaches towards `dusk`, the sun on the horizon as it
    /// goes down; the last step before dawn reaches towards `dawn`, the moon
    /// on the horizon as it goes down. Numbered past the eight, so that they
    /// are kept under keys of their own. Plants and ground are now lit by one
    /// body at every hour, and change together at six, as the ground always
    /// has.
    static let dusk = steps
    static let dawn = steps + 1

    static func at(step: Int, season: Season = .orbit) -> GardenGround.Light {
        switch step {
        case dusk: return at(hour: 18 - edge, season: season)
        case dawn: return at(hour: 6 - edge, season: season)
        default: return at(hour: Double((step % steps + steps) % steps) / Double(steps) * 24, season: season)
        }
    }

    /// How far short of six a hand-over is seen from: as near as makes no
    /// difference to the light, and on the right side of the clock.
    private static let edge = 1e-6

    /// The two steps an hour falls between, and how far it is between them.
    static func steps(at hour: Double) -> (before: Int, after: Int, blend: Double) {
        let clock = ((hour.truncatingRemainder(dividingBy: 24)) + 24)
            .truncatingRemainder(dividingBy: 24)
        let raw = clock / 24 * Double(steps)
        let before = Int(raw.rounded(.down)) % steps
        var after = (before + 1) % steps
        if after == steps * 3 / 4 { after = dusk }
        if after == steps / 4 { after = dawn }
        return (before, after, raw - raw.rounded(.down))
    }
}

/// Tonight's moon, in the phase it is actually in.
///
/// One synodic month against a known new moon. It ignores the orbit's
/// ellipticity and is a few hours out at worst, which is finer than a drawing
/// nineteen points across can show.
enum MoonPhase {
    static let synodicDays = 29.530_588_853

    /// 6 January 2000, 18:14 UTC.
    static let knownNew = Date(timeIntervalSince1970: 947_182_440)

    /// Where in the month tonight is: `0` new, `0.5` full, and round again.
    static func fraction(on date: Date) -> Double {
        let days = date.timeIntervalSince(knownNew) / 86_400
        let through = (days / synodicDays).truncatingRemainder(dividingBy: 1)
        return through < 0 ? through + 1 : through
    }

    /// How much of the disc is lit, `0` to `1`. Only for saying it out loud;
    /// the drawing uses the phase itself.
    static func lit(on date: Date) -> Double {
        (1 - cos(2 * .pi * fraction(on: date))) / 2
    }
}
