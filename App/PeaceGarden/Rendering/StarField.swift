import SwiftUI
import SeedCore

/// The real sky, worked out for where this phone is and drawn behind the plot.
///
/// **Both halves of it.** The plot floats: there is no ground under it, so the
/// whole celestial sphere is there to be drawn, and the half below the horizon
/// is not a leftover of that. Those are the stars somebody on the other side of
/// the world is looking up at while this person looks down at them. A garden
/// about two people meeting can hold both their skies at once, and the middle
/// of the screen — where the plot floats — is the horizon they each have and
/// neither can see past.
///
/// **It asks for nothing.** Where the phone is comes from its time zone, which
/// it was already keeping before the app existed. `Whereabouts`, and
/// `docs/PLACE.md` for why no coordinate is taken.
@MainActor
final class StarField {
    static let shared = StarField()

    /// The catalogue, read once. 8,404 stars at six bytes each: fifty
    /// kilobytes, which is a fifth of one of the app's icons.
    private lazy var catalogue: [Star] = {
        guard let url = Bundle.main.url(forResource: "stars", withExtension: "bin"),
              let data = try? Data(contentsOf: url),
              let stars = try? StarCatalogue.decode(data) else { return [] }
        return stars
    }()

    /// How faint a star has to be before it is left out.
    ///
    /// Six is a dark country sky: about five thousand stars. The catalogue
    /// carries half a magnitude more than this so the number is a decision
    /// about how the garden looks rather than about what was shipped.
    static let faintest = 6.0

    /// How much of the sky is across the screen.
    ///
    /// A little over half a turn, so the sky spills past both edges rather than
    /// ending at them. Altitude is not scaled to match: the whole hundred and
    /// eighty degrees from zenith to nadir is always on screen, because leaving
    /// the other person's half off it would be the one thing this is for.
    static let fieldOfView = 220.0

    // MARK: What is where

    /// One star, placed and dressed.
    struct Placed {
        var at: CGPoint
        var radius: Double
        var alpha: Double
        var tint: Color
        /// The clamped B−V this star's tint came from, kept so the renderer can
        /// put stars of a like colour in one band and fill them together.
        var warmth: Double
    }

    private var cachedFor: Key?
    private var cached: [Placed] = []

    private struct Key: Equatable {
        /// The sky turns a quarter of a degree a minute, which is a fifth of a
        /// point on a phone. Recomputing oftener than this buys nothing.
        var minute: Int
        var width: Double
        var height: Double
        var latitude: Double
        var longitude: Double
    }

    /// Every star on screen, for this moment and this size.
    func stars(at date: Date, in size: CGSize, place: Place) -> [Placed] {
        let key = Key(
            minute: Int(date.timeIntervalSince1970 / 60),
            width: size.width, height: size.height,
            latitude: place.latitude, longitude: place.longitude
        )
        if key == cachedFor { return cached }

        let sidereal = Sky.siderealTime(at: date, longitude: place.longitude)
        let facing = Sky.facing(fromLatitude: place.latitude)
        var placed: [Placed] = []
        placed.reserveCapacity(3_000)

        for star in catalogue {
            guard star.magnitude <= Self.faintest else { continue }
            let (altitude, azimuth) = Sky.horizon(
                rightAscension: star.rightAscension,
                declination: star.declination,
                siderealTime: sidereal,
                latitude: place.latitude
            )
            let across = Sky.offset(from: facing, to: azimuth)
            guard abs(across) <= Self.fieldOfView / 2 else { continue }

            let x = size.width * (0.5 + across / Self.fieldOfView)
            // Zenith at the top, nadir at the foot, the horizon across the
            // middle where the plot floats.
            let y = size.height * (0.5 - altitude / 180)

            placed.append(Placed(
                at: CGPoint(x: x, y: y),
                radius: Self.radius(ofMagnitude: star.magnitude),
                alpha: Self.alpha(ofMagnitude: star.magnitude),
                tint: Self.tint(ofColourIndex: star.colourIndex),
                warmth: max(-0.4, min(1.9, star.colourIndex))
            ))
        }

        cachedFor = key
        cached = placed
        return placed
    }

    // MARK: How a star is drawn

    /// Brightness is a ratio, not a number of points: each magnitude is two and
    /// a half times the light of the next. Drawn straight, Sirius would be a
    /// disc and everything else a speck, so this is flattened hard — the eye
    /// reads a bright star as *bigger* as well as brighter, and only a little
    /// of each is needed to tell them apart.
    static func radius(ofMagnitude magnitude: Double) -> Double {
        let brightness = max(0, faintest - magnitude)
        return 0.32 + pow(brightness, 1.45) * 0.24
    }

    static func alpha(ofMagnitude magnitude: Double) -> Double {
        let brightness = max(0, faintest - magnitude)
        return min(1, 0.16 + brightness * 0.16)
    }

    /// A star's colour, from B−V: how much brighter it is in blue light than in
    /// yellow. Rigel is about −0.03 and blue-white, the sun is +0.65, Betelgeuse
    /// is +1.85 and orange.
    ///
    /// **Held well short of what the numbers would give.** Real starlight at
    /// this size is almost white — the colour is there at the edge of seeing,
    /// and a sky of frank blue and orange dots is a chart of star types rather
    /// than a sky.
    static func tint(ofColourIndex index: Double) -> Color {
        let warmth = max(-0.4, min(1.9, index))
        if warmth <= 0 {
            // Blue-white.
            let t = min(1, -warmth / 0.4)
            return Color(red: 1 - 0.10 * t, green: 1 - 0.04 * t, blue: 1)
        }
        let t = min(1, warmth / 1.9)
        return Color(red: 1, green: 1 - 0.13 * t, blue: 1 - 0.28 * t)
    }
}
