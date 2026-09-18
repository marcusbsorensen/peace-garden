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

    static let skyByDay = SIMD3<Double>(0.40, 0.48, 0.60)
    static let skyByNight = SIMD3<Double>(0.10, 0.13, 0.22)
    static let bounceByDay = SIMD3<Double>(0.27, 0.25, 0.20)
    static let bounceByNight = SIMD3<Double>(0.06, 0.07, 0.10)

    /// The light at an hour of the day, `0..<24`.
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
    static func at(hour: Double) -> GardenGround.Light {
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
            return GardenGround.Light(
                direction: direction,
                colour: SIMD3(1.00, 0.96, 0.88),
                strength: 0.24 + 0.52 * up,
                sky: skyByNight + (skyByDay - skyByNight) * warmth,
                bounce: bounceByNight + (bounceByDay - bounceByNight) * warmth,
                up: up,
                isDay: true,
                galaxy: galaxy(strength: 0.24 + 0.52 * up)
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
            galaxy: galaxy(strength: 0.035 + 0.115 * up)
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

    static func at(step: Int) -> GardenGround.Light {
        at(hour: Double((step % steps + steps) % steps) / Double(steps) * 24)
    }

    /// The two steps an hour falls between, and how far it is between them.
    static func steps(at hour: Double) -> (before: Int, after: Int, blend: Double) {
        let clock = ((hour.truncatingRemainder(dividingBy: 24)) + 24)
            .truncatingRemainder(dividingBy: 24)
        let raw = clock / 24 * Double(steps)
        let before = Int(raw.rounded(.down)) % steps
        return (before, (before + 1) % steps, raw - raw.rounded(.down))
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
