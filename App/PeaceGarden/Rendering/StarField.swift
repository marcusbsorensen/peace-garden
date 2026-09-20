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
/// the same field with `tools/wasm/web/sky.js` and a constant kept in one
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
            guard let spot = Sky.place(
                star,
                siderealTime: sidereal,
                latitude: place.latitude,
                facing: facing,
                width: size.width,
                height: size.height
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
