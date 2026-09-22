import XCTest
@testable import SeedCore

/// Pins `tools/reference/knot_garden_vectors.json` to where `KnotGarden` puts
/// things.
///
/// The plot service places arrivals in PHP, because the server is PHP and
/// cannot run SeedCore. That makes it a port, and a port drifts unless
/// something holds it: this file is what the Swift rule does with five hundred
/// arrivals, and `tools/reference/check_knot.php` fails CI if the PHP puts any
/// of them anywhere else.
///
/// **This is the first rule whose answer turns on a plant's colour**, and that
/// is what the five hundred are for rather than a sample. A port that read the
/// colour but claimed pairs in a different order would agree about the whole of
/// plot 0 and diverge somewhere in the middle of the garden, when a colour first
/// runs out of room in the plot it started in. Nothing short of playing it out
/// finds that.
///
/// **The Knot Garden is opened rather than empty**, so *Quina caerulea* is
/// standing in the north compartment before the first arrival and has already
/// claimed that pair for family 4 — which is how the service places them too.
final class KnotGardenVectorTests: XCTestCase {
    static var vectorsURL: URL {
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { url.deleteLastPathComponent() }
        return url.appendingPathComponent("tools/reference/knot_garden_vectors.json")
    }

    static let recordingKey = "PEACE_GARDEN_RECORD_VECTORS"

    /// One arrival per line, and where it went, so a failure names the arrival.
    static func render() -> String {
        var ways = KnotGarden.Ways.opened()
        var lines: [String] = []
        for (seed, traits) in KnotGardenTests.arrivals() {
            let p = ways.plant(seed: seed, traits: traits)
            lines.append("""
                {"seed":"\(seed.hex)","height":\(traits.height),"family":\(traits.family),\
                "plot":\(p.plot),"compartment":\(p.slot.compartment.rawValue),"index":\(p.slot.index),\
                "nudge":[\(p.nudge.x),\(p.nudge.z)]}
                """)
        }
        return "[\n" + lines.joined(separator: ",\n") + "\n]\n"
    }

    func testTheCommittedVectorsAreWhatTheSwiftPlaces() throws {
        let rendered = Self.render()
        if ProcessInfo.processInfo.environment[Self.recordingKey] == "1" {
            try rendered.write(to: Self.vectorsURL, atomically: true, encoding: .utf8)
            print("re-recorded \(Self.vectorsURL.path) — now run php tools/reference/check_knot.php")
        }
        guard let committed = try? String(contentsOf: Self.vectorsURL, encoding: .utf8) else {
            return XCTFail("""
                tools/reference/knot_garden_vectors.json is missing. Record it with \
                \(Self.recordingKey)=1 swift test --package-path Packages/SeedCore
                """)
        }
        XCTAssertEqual(committed, rendered, "the rule has moved since the vectors were recorded")
    }
}
