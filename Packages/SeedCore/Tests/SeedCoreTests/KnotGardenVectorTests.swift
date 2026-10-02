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
/// **The Knot Garden is opened rather than empty**, so its ambassador —
/// *Quinyria obscura* since 28 September 2026 — is
/// standing in the north-east lens before the first arrival and has already
/// claimed that pair for family 4 — which is how the service places them too.
///
/// **Each row carries its spot** since the rings of 2 October 2026, and the
/// plot's variant, which here is always the plain one: where a place stands
/// is a table now (`PlaceTable.knotGardenRings`), and the port reads its own
/// copy of it. A spot is a table's millimetres plus the nudge, exact on every
/// host, so it is compared with no tolerance.
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
            let v = PlotVariant.of(plot: p.plot, area: .pattern)
            lines.append("""
                {"seed":"\(seed.hex)","height":\(traits.height),"family":\(traits.family),\
                "plot":\(p.plot),"compartment":\(p.slot.compartment.rawValue),"index":\(p.slot.index),\
                "nudge":[\(p.nudge.x),\(p.nudge.z)],\
                "variant":[\(v.turn),\(v.mirror),\(v.nudge)],"spot":[\(p.spot.x),\(p.spot.z)]}
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
                            --filter KnotGardenVectorTests, then run php tools/reference/check_knot.php.
                            """)
    }

    /// **And the tolerance the comparison above allows cannot move a plant.**
    ///
    /// The rule asks two kinds of question about a height: which side of a cut
    /// it falls, and whether it is taller than another plant in one compartment of one knot.
    /// This says every recorded height clears both cuts, and every pair the
    /// rule compares is further apart than twice the tolerance — so a host that
    /// computes a height a few of a `Float`'s last bits differently still puts
    /// every one of these five hundred in the same place.
    func testThePlacementCannotTurnOnTheLastBitOfAHeight() throws {
        let committed = try String(contentsOf: Self.vectorsURL, encoding: .utf8)
        VectorFile.placementCannotTurn(on: committed,
                                       cuts: [KnotGarden.sideFrom, KnotGarden.pointFrom],
                                       groupedBy: ["plot", "compartment"])
    }
}
