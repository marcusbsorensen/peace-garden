import XCTest
@testable import SeedCore

/// Pins `tools/reference/sky_vectors.json` to the sky `Sky` works out.
///
/// The web walk draws the same field in a browser, in JavaScript, because a
/// browser cannot run SeedCore. That makes it a port, and a port drifts unless
/// something holds it — the same arrangement `LongWalkVectorTests` has with the
/// plot service's placing rule. This file is what the Swift says;
/// `tools/reference/check_sky.mjs` fails CI if `Server/assets/js/sky.js` says
/// anything else.
///
/// **What is pinned is the whole pipeline**, not a handful of trig calls: the
/// last block places the real catalogue at a fixed instant, from four places on
/// the globe, onto a fixed screen, and writes down where a sample of the stars
/// landed and what colour they came out. A port that decoded the catalogue
/// half a byte out, or flipped the sky, or rounded a magnitude, fails there.
final class SkyVectorTests: XCTestCase {

    static var vectorsURL: URL {
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { url.deleteLastPathComponent() }   // …/Tests/SeedCoreTests/<this>
        return url.appendingPathComponent("tools/reference/sky_vectors.json")
    }

    static var catalogueURL: URL {
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { url.deleteLastPathComponent() }
        return url.appendingPathComponent("Server/assets/stars.bin")
    }

    static let recordingKey = "PEACE_GARDEN_RECORD_VECTORS"

    /// Four places, chosen for what each one catches: a northern latitude, a
    /// southern one (where the sky faces the other way), the equator, and
    /// inside the Arctic circle where a star can be up all day.
    static let places: [(String, Place)] = [
        ("Europe/London", Place(latitude: 51.5, longitude: -0.13)),
        ("Australia/Sydney", Place(latitude: -33.87, longitude: 151.21)),
        ("Africa/Nairobi", Place(latitude: -1.28, longitude: 36.82)),
        ("America/Nuuk", Place(latitude: 64.18, longitude: -51.72)),
    ]

    /// Instants spread through a year and round a day, so a port that lost the
    /// sidereal drift or the century term shows it.
    static let instants: [Double] = [
        946_728_000,        // J2000.0 exactly
        1_700_000_000,
        1_700_043_200,
        1_763_600_000,
        1_800_000_000.5,
    ]

    static func render() throws -> String {
        let stars = try StarCatalogue.decode(Data(contentsOf: catalogueURL))
        var lines: [String] = []

        func put(_ line: String) { lines.append("  " + line) }

        put("\"faintest\": \(Sky.faintest),")
        put("\"fieldOfView\": \(Sky.fieldOfView),")
        put("\"catalogueCount\": \(stars.count),")

        // The sky's clock.
        var clock: [String] = []
        for at in instants {
            let date = Date(timeIntervalSince1970: at)
            for longitude in [0.0, -0.13, 151.21, -179.9] {
                clock.append("""
                    {"at":\(at),"longitude":\(longitude),\
                    "sidereal":\(json(Sky.siderealTime(at: date, longitude: longitude)))}
                    """)
            }
        }
        put("\"siderealTime\": [\n    " + clock.joined(separator: ",\n    ") + "\n  ],")

        // Where a star stands.
        var stands: [String] = []
        for (rightAscension, declination) in [(0.0, 0.0), (101.287, -16.716), (37.9529, 89.2642),
                                              (359.99, -0.5), (180.0, -60.0)] {
            for sidereal in [0.0, 90.0, 217.4, 359.9] {
                for latitude in [51.5, -33.87, 0.0, 64.18] {
                    let (altitude, azimuth) = Sky.horizon(
                        rightAscension: rightAscension, declination: declination,
                        siderealTime: sidereal, latitude: latitude
                    )
                    stands.append("""
                        {"ra":\(rightAscension),"dec":\(declination),"sidereal":\(sidereal),\
                        "latitude":\(latitude),"altitude":\(json(altitude)),"azimuth":\(json(azimuth))}
                        """)
                }
            }
        }
        put("\"horizon\": [\n    " + stands.joined(separator: ",\n    ") + "\n  ],")

        // How a star is drawn.
        var drawn: [String] = []
        for magnitude in [-1.46, 0.0, 2.02, 4.5, 5.99, 6.0, 6.4] {
            drawn.append("""
                {"magnitude":\(magnitude),"radius":\(json(Sky.radius(ofMagnitude: magnitude))),\
                "alpha":\(json(Sky.alpha(ofMagnitude: magnitude)))}
                """)
        }
        put("\"brightness\": [\n    " + drawn.joined(separator: ",\n    ") + "\n  ],")

        var tints: [String] = []
        for index in [-0.6, -0.4, -0.3, 0.0, 0.65, 1.85, 1.9, 2.4] {
            let rgb = Sky.tint(ofColourIndex: index)
            tints.append("""
                {"colourIndex":\(index),"warmth":\(json(Sky.warmth(ofColourIndex: index))),\
                "tint":[\(json(rgb.red)),\(json(rgb.green)),\(json(rgb.blue))]}
                """)
        }
        put("\"tint\": [\n    " + tints.joined(separator: ",\n    ") + "\n  ],")

        // The whole field, from the real catalogue.
        var fields: [String] = []
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        for (zone, place) in places {
            let sidereal = Sky.siderealTime(at: date, longitude: place.longitude)
            let facing = Sky.facing(fromLatitude: place.latitude)
            var placed: [(Int, Sky.Placement)] = []
            for (index, star) in stars.enumerated() {
                if let spot = Sky.place(star, siderealTime: sidereal, latitude: place.latitude,
                                        facing: facing, width: 400, height: 800) {
                    placed.append((index, spot))
                }
            }
            // Every two hundredth one, so the file stays readable and a port
            // that is wrong anywhere is wrong in about forty places.
            let sample = stride(from: 0, to: placed.count, by: 200).map { placed[$0] }
            let rows = sample.map { index, spot in
                """
                {"star":\(index),"x":\(json(spot.x)),"y":\(json(spot.y)),\
                "radius":\(json(spot.radius)),"alpha":\(json(spot.alpha)),\
                "warmth":\(json(spot.warmth)),\
                "tint":[\(json(spot.tint.red)),\(json(spot.tint.green)),\(json(spot.tint.blue))]}
                """
            }
            let head = """
                {"zone":"\(zone)","latitude":\(place.latitude),\
                "longitude":\(place.longitude),"at":1700000000,"width":400,"height":800,\
                "drawn":\(placed.count),"every":200,"sample":[
                """
            fields.append(head + "\n      " + rows.joined(separator: ",\n      ") + "\n    ]}")
        }
        put("\"field\": [\n    " + fields.joined(separator: ",\n    ") + "\n  ]")

        return "{\n" + lines.joined(separator: "\n") + "\n}\n"
    }

    /// Seventeen significant digits, which is what a double round-trips in.
    /// Anything shorter would let a port be wrong by an amount this file could
    /// not see.
    private static func json(_ value: Double) -> String {
        String(format: "%.17g", value)
    }

    func testTheCommittedVectorsAreWhatTheSwiftSees() throws {
        let rendered = try Self.render()
        if ProcessInfo.processInfo.environment[Self.recordingKey] == "1" {
            try rendered.write(to: Self.vectorsURL, atomically: true, encoding: .utf8)
            print("re-recorded \(Self.vectorsURL.path) — now run node tools/reference/check_sky.mjs")
        }
        let committed: String
        do {
            committed = try String(contentsOf: Self.vectorsURL, encoding: .utf8)
        } catch {
            return XCTFail("""
                tools/reference/sky_vectors.json is missing. Record it with \
                `\(Self.recordingKey)=1 swift test --package-path Packages/SeedCore \
                --filter SkyVectorTests`.
                """)
        }
        // **The same tolerances `check_sky.mjs` already allows the JavaScript,
        // allowed to the Swift for the same reason.** That file worked this out
        // first and said it plainly: `sin`, `cos`, `asin`, `atan2` and `pow` are
        // library functions, two libms are each correct to within about an ulp
        // of the true value without being correct to the same bit as each other,
        // and demanding equality of them is demanding that two C libraries
        // agree. It allowed a billionth of a degree on an angle, a millionth of
        // a pixel on a position and 10⁻¹² on a radius; so does this. Everything
        // built out of `+ - * /` — a sidereal time, a star count, the field's
        // own width and height — still has to match to the last bit.
        //
        // Until 22 September this compared the two as strings, which is what
        // left continuous integration red for two days: the same sky, drawn on
        // Linux, differed in the last digit of one star's x.
        VectorFile.same(committed: committed, rendered: rendered,
                        tolerant: ["altitude": VectorFile.angle, "azimuth": VectorFile.angle,
                                   "x": VectorFile.pixel, "y": VectorFile.pixel,
                                   "radius": VectorFile.power],
                        recordWith: """
                            If the sky changed on purpose, re-record with \
                            \(Self.recordingKey)=1 swift test --package-path Packages/SeedCore \
                            --filter SkyVectorTests, then run node tools/reference/check_sky.mjs.
                            """)
    }
}
