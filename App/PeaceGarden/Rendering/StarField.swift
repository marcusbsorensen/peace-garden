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
///
/// **The arithmetic is not here.** Where a star lands, how big it is drawn and
/// what colour it is are all in `Sky`, in SeedCore, because the web walk draws
/// the same field with `Server/assets/js/sky.js` and a constant kept in one
/// renderer would be a second sky. What is here is the part only a phone does:
/// reading the catalogue out of the bundle once, and not working the field out
/// again while nothing has moved.
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

    /// How faint a star has to be before it is left out. `Sky` decides; this is
    /// here because the tests and the renderer both ask for it by this name.
    static var faintest: Double { Sky.faintest }

    // MARK: What is where

    /// One star, placed and dressed for a SwiftUI canvas.
    struct Placed {
        var at: CGPoint
        var radius: Double
        var alpha: Double
        var tint: Color
        /// The clamped B−V this star's tint came from, kept so the renderer can
        /// put stars of a like colour in one band and fill them together.
        var warmth: Double
    }

    /// **Two caches, because a turn is not a minute.**
    ///
    /// Where a star stands — its altitude and azimuth — depends on the hour and
    /// on where the phone is, and on nothing else: turning round does not move
    /// the stars, it moves you. So the trigonometry is worked out once a minute
    /// and kept, and turning the plot only remaps what is already worked out,
    /// which is a subtraction a star. Without the split, a quarter turn would
    /// be eight thousand stars' worth of `asin` and `atan2` on the main thread
    /// while the plot is mid-gesture.
    private var aimedFor: Aiming?
    private var aimed: [Sky.Aim] = []

    private var cachedFor: Key?
    private var cached: [Placed] = []

    private struct Aiming: Equatable {
        /// The sky turns a quarter of a degree a minute, which is a fifth of a
        /// point on a phone. Recomputing oftener than this buys nothing.
        var minute: Int
        var latitude: Double
        var longitude: Double
    }

    private struct Key: Equatable {
        var aiming: Aiming
        var facing: Double
        var width: Double
        var height: Double
    }

    /// Every star on screen, for this moment, this size, and whichever way the
    /// garden has been turned to face.
    func stars(at date: Date, in size: CGSize, place: Place, facing towards: Double) -> [Placed] {
        let aiming = Aiming(
            minute: Int(date.timeIntervalSince1970 / 60),
            latitude: place.latitude, longitude: place.longitude
        )
        let key = Key(aiming: aiming, facing: towards, width: size.width, height: size.height)
        if key == cachedFor { return cached }

        if aiming != aimedFor {
            let sidereal = Sky.siderealTime(at: date, longitude: place.longitude)
            aimed = catalogue.compactMap {
                Sky.aim($0, siderealTime: sidereal, latitude: place.latitude)
            }
            aimedFor = aiming
        }

        var placed: [Placed] = []
        placed.reserveCapacity(3_000)
        for aim in aimed {
            guard let spot = Sky.onGlass(
                aim, facing: towards, width: size.width, height: size.height
            ) else { continue }

            placed.append(Placed(
                at: CGPoint(x: spot.x, y: spot.y),
                radius: spot.radius,
                alpha: spot.alpha,
                tint: Color(red: spot.tint.red, green: spot.tint.green, blue: spot.tint.blue),
                warmth: spot.warmth
            ))
        }

        cachedFor = key
        cached = placed
        return placed
    }

    /// Which way somebody looking at the plot at this turn is facing.
    ///
    /// **Ninety degrees a quarter turn, and the sign is not a preference.** The
    /// sun and the moon are already placed through the plot's own projection —
    /// `GardenSky.body` hands the light direction to `Isometric.point` — so they
    /// swing when the plot is turned, whether or not anybody meant them to. If
    /// the stars did not swing with them by the same amount in the same
    /// direction, the sun would walk out of its constellations, which is a
    /// thing a sky cannot do.
    ///
    /// Working out which direction that is: `Isometric.point` puts a horizontal
    /// direction at `x = (a − b)·cos30`, and `facing(x:z:)` at quarter *t*
    /// makes that `√2·sin(bearing − 45° + 90t)`. So a turn of +1 draws the
    /// world as if every bearing had gained ninety degrees — which is the
    /// observer having lost them.
    static func facing(fromLatitude latitude: Double, turn: Int) -> Double {
        Sky.facing(fromLatitude: latitude) - Double(turn) * 90
    }

    // MARK: How a star is drawn

    static func radius(ofMagnitude magnitude: Double) -> Double {
        Sky.radius(ofMagnitude: magnitude)
    }

    static func alpha(ofMagnitude magnitude: Double) -> Double {
        Sky.alpha(ofMagnitude: magnitude)
    }

    static func tint(ofColourIndex index: Double) -> Color {
        let rgb = Sky.tint(ofColourIndex: index)
        return Color(red: rgb.red, green: rgb.green, blue: rgb.blue)
    }
}
