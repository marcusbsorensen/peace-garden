import XCTest
@testable import SeedCore

/// Pins `tools/reference/orchard_vectors.json` to where `Orchard` puts things.
///
/// The plot service places arrivals in PHP, because the server is PHP and
/// cannot run SeedCore. That makes it a port, and a port drifts unless
/// something holds it: this file is what the Swift rule does with five hundred
/// arrivals, and `tools/reference/check_orchard.php` fails CI if the PHP puts
/// any of them anywhere else.
///
/// **It matters more here than it did for the other three.** This rule's answer
/// depends on the order two loops are nested in — guild outside, rank inside —
/// and a port that got that backwards would still agree about the first four
/// plants in every plot, about every plot's total, and about most individual
/// placements. Five hundred replayed arrivals is what catches it.
///
/// **The Orchard is opened rather than empty**, so the ambassador is standing
/// under the middle tree before the first arrival and every placement below is
/// made around it — which is how the service places them too.
final class OrchardVectorTests: XCTestCase {
    static var vectorsURL: URL {
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { url.deleteLastPathComponent() }
        return url.appendingPathComponent("tools/reference/orchard_vectors.json")
    }

    static let recordingKey = "PEACE_GARDEN_RECORD_VECTORS"

    /// One arrival per line, and where it went, so a failure names the arrival.
    static func render() -> String {
        var ways = Orchard.Ways.opened()
        var lines: [String] = []
        for (seed, traits) in OrchardTests.arrivals() {
            let p = ways.plant(seed: seed, traits: traits)
            lines.append("""
                {"seed":"\(seed.hex)","height":\(traits.height),"family":\(traits.family),\
                "plot":\(p.plot),"guild":\(p.slot.guild.rawValue),"index":\(p.slot.index),\
                "nudge":[\(p.nudge.x),\(p.nudge.z)]}
                """)
        }
        return "[\n" + lines.joined(separator: ",\n") + "\n]\n"
    }

    func testTheCommittedVectorsAreWhatTheSwiftPlaces() throws {
        let rendered = Self.render()
        if ProcessInfo.processInfo.environment[Self.recordingKey] == "1" {
            try rendered.write(to: Self.vectorsURL, atomically: true, encoding: .utf8)
            print("re-recorded \(Self.vectorsURL.path) — now run php tools/reference/check_orchard.php")
        }
        guard let committed = try? String(contentsOf: Self.vectorsURL, encoding: .utf8) else {
            return XCTFail("""
                tools/reference/orchard_vectors.json is missing. Record it with \
                \(Self.recordingKey)=1 swift test --package-path Packages/SeedCore
                """)
        }
        XCTAssertEqual(committed, rendered, "the rule has moved since the vectors were recorded")
    }
}
