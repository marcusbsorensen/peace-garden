import XCTest
@testable import SeedCore

/// Pins `tools/reference/crossing_vectors.json` to where `Crossing` puts things.
///
/// The plot service places arrivals in PHP, because the server is PHP and
/// cannot run SeedCore. That makes it a port, and a port drifts unless
/// something holds it: this file is what the Swift rule does with five hundred
/// arrivals, and `tools/reference/check_crossing.php` fails CI if the PHP puts
/// any of them anywhere else.
///
/// **The Crossing is opened rather than empty**, so the ambassador is standing
/// on the first quarter's diagonal before the first arrival and every placement
/// below is made around it — which is how the service places them too.
final class CrossingVectorTests: XCTestCase {
    static var vectorsURL: URL {
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { url.deleteLastPathComponent() }
        return url.appendingPathComponent("tools/reference/crossing_vectors.json")
    }

    static let recordingKey = "PEACE_GARDEN_RECORD_VECTORS"

    /// One arrival per line, and where it went, so a failure names the arrival.
    static func render() -> String {
        var ways = Crossing.Ways.opened()
        var lines: [String] = []
        for (seed, traits) in CrossingTests.arrivals() {
            let p = ways.plant(seed: seed, traits: traits)
            // **Where it stands, turned for its plot**, since 2 October 2026:
            // the variant the plot's number deals it and the spot that gives.
            // Both are exact on every host, so the service is held to them
            // with no tolerance.
            let v = Crossing.variant(of: p.plot)
            lines.append("""
                {"seed":"\(seed.hex)","height":\(traits.height),"family":\(traits.family),\
                "plot":\(p.plot),"quarter":\(p.slot.quarter.rawValue),"index":\(p.slot.index),\
                "nudge":[\(p.nudge.x),\(p.nudge.z)],\
                "variant":[\(v.turn),\(v.mirror ? 1 : 0),\(v.nudge)],"spot":[\(p.spot.x),\(p.spot.z)]}
                """)
        }
        return "[\n" + lines.joined(separator: ",\n") + "\n]\n"
    }

    func testTheCommittedVectorsAreWhatTheSwiftPlaces() throws {
        let rendered = Self.render()
        if ProcessInfo.processInfo.environment[Self.recordingKey] == "1" {
            try rendered.write(to: Self.vectorsURL, atomically: true, encoding: .utf8)
            print("re-recorded \(Self.vectorsURL.path) — now run php tools/reference/check_crossing.php")
        }
        guard let committed = try? String(contentsOf: Self.vectorsURL, encoding: .utf8) else {
            return XCTFail("""
                tools/reference/crossing_vectors.json is missing. Record it with \
                \(Self.recordingKey)=1 swift test --package-path Packages/SeedCore
                """)
        }
        // **A grown height is allowed a hundredth of a millimetre and nothing
        // else is allowed anything.** Two C libraries do not agree to the last
        // bit about `sin`, `cos`, `pow` and `exp`, and a plant's mesh is built out
        // of all four; the plot, the slot and the nudge are arithmetic and must
        // still match exactly. `VectorFile` sets out the measurement this rests on.
        VectorFile.same(committed: committed, rendered: rendered,
                        tolerant: ["height": VectorFile.height],
                        recordWith: """
                            If the rule has moved and that was meant, re-record with \
                            \(Self.recordingKey)=1 swift test --package-path Packages/SeedCore \
                            --filter CrossingVectorTests, then run php tools/reference/check_crossing.php.
                            """)
    }

    /// **And the tolerance the comparison above allows cannot move a plant.**
    ///
    /// The rule asks two kinds of question about a height: which side of a cut
    /// it falls, and whether it is taller than another plant in one quarter of one plot.
    /// This says every recorded height clears both cuts, and every pair the
    /// rule compares is further apart than twice the tolerance — so a host that
    /// computes a height a few of a `Float`'s last bits differently still puts
    /// every one of these five hundred in the same place.
    func testThePlacementCannotTurnOnTheLastBitOfAHeight() throws {
        let committed = try String(contentsOf: Self.vectorsURL, encoding: .utf8)
        VectorFile.placementCannotTurn(on: committed,
                                       cuts: [Crossing.middleFrom, Crossing.cornerFrom],
                                       groupedBy: ["plot", "quarter"])
    }
}
