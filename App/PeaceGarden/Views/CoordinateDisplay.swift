import Foundation
import SeedCore

/// How a coordinate is shown, and where it can be opened.
///
/// Numbers, never a place name. Naming a spot means asking somebody's geocoder,
/// and this app makes no network request at all; the numbers are also the honest
/// record of what the phone actually measured, where "near the Old Quay" is a
/// guess laid over it. Anyone who wants the name can tap and let a map say it.
extension Coordinate {
    /// Five decimals, which is the precision actually stored, with hemispheres
    /// spelled out rather than signed. A minus sign in front of a latitude is
    /// easy to misread and easy to lose in a copy and paste.
    var written: String {
        let latitudeMark = latitude >= 0 ? "N" : "S"
        let longitudeMark = longitude >= 0 ? "E" : "W"
        return String(
            format: "%.5f°%@  %.5f°%@",
            abs(latitude), latitudeMark, abs(longitude), longitudeMark
        )
    }

    /// Opens wherever the phone sends geo links, which on iOS is Maps unless
    /// somebody has chosen otherwise. Built with a signed decimal pair because
    /// that is what the scheme takes, whatever the display does.
    var mapURL: URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "maps.apple.com"
        components.queryItems = [
            URLQueryItem(name: "ll", value: "\(latitude),\(longitude)"),
            // Drops a pin rather than offering directions from where the person
            // is standing now, which is a different and unasked-for question.
            // The pin's label is read in Maps, so it is looked up like anything
            // else somebody reads.
            URLQueryItem(name: "q", value: String(localized: "Where you met"))
        ]
        return components.url
    }
}
