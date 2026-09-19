#if os(WASI)
import FoundationEssentials
import WASILibc
#else
import Foundation
#endif

/// Somewhere on the globe, near enough to draw a sky from.
public struct Place: Equatable, Sendable {
    public var latitude: Double
    public var longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    /// The opposite point on the globe: where it is midnight when it is noon
    /// here, and where the stars under this garden's feet are overhead.
    public var antipode: Place {
        Place(latitude: -latitude, longitude: longitude > 0 ? longitude - 180 : longitude + 180)
    }
}

/// Where the person looking at the screen is, as far as the app is willing to know.
///
/// **A time zone and nothing else.** The tz database gives a representative
/// coordinate for every zone it keeps, the phone is already keeping time by
/// one, and so the sky can be right without the app asking for anything or
/// making a single request. `docs/PLACE.md` sets out why a coordinate is taken
/// only when two people at a meeting both ask for it; this is what the app does
/// instead of reaching for one.
///
/// What it costs: a zone's coordinate is its principal city, so Aberdeen is
/// given London's sky. Six degrees of tilt — three fingers at arm's length —
/// and nobody notices unless they are checking.
public enum Whereabouts {

    /// Parsed once, on first use. 418 lines rather than 418 dictionary
    /// entries, because a literal that size costs a minute of the type
    /// checker on every clean build.
    static let byZone: [String: Place] = {
        var found: [String: Place] = [:]
        found.reserveCapacity(Places.count)
        for line in Places.table.split(separator: "\n") {
            let field = line.split(separator: ",")
            guard field.count == 3,
                  let latitude = Double(field[1]),
                  let longitude = Double(field[2]) else { continue }
            found[String(field[0])] = Place(latitude: latitude, longitude: longitude)
        }
        return found
    }()

    /// Where this zone is, or nil where the tz database has no coordinate for it.
    public static func place(ofZone identifier: String) -> Place? {
        byZone[identifier]
    }

    /// Where somebody keeping this time is, always.
    ///
    /// **The fallback is the equator**, and its longitude comes from the zone's
    /// standard offset from GMT — fifteen degrees to the hour. A zone this
    /// table has never heard of is nearly always an alias for one it has, so
    /// the longitude is right and only the latitude is a guess; the equator is
    /// the guess that favours neither hemisphere and puts the whole sphere
    /// through the sky in a night, which is the least wrong thing to show
    /// somebody whose latitude is unknown.
    ///
    /// **Standard offset, not the current one.** Using the offset in force
    /// would swing the sky fifteen degrees every spring, and daylight saving
    /// is a fact about clocks rather than about where anybody is.
    public static func place(of zone: TimeZone, at date: Date = Date()) -> Place {
        if let known = place(ofZone: zone.identifier) { return known }
        let standard = Double(zone.secondsFromGMT(for: date)) - zone.daylightSavingTimeOffset(for: date)
        return Place(latitude: 0, longitude: standard / 240)
    }
}
