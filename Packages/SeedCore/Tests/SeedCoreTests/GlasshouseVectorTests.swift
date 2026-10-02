import XCTest
@testable import SeedCore

/// Pins `tools/reference/glasshouse_vectors.json` to where `Glasshouse` puts
/// things, so `tools/reference/check_glasshouse.php` can hold the PHP port to
/// it.
///
/// **Five hundred plants of this area's own**, as `GlasshouseTests` draws them,
/// because the border cut and the band edges were both measured over those.
///
/// **And where each stands**, since the house became round on 2 October 2026:
/// the plot's variant (always the plain plan here, a colour wheel having one
/// way round) and the spot, the table's place plus the nudge. A spot from a
/// table is exact on every host, so the check compares it with no tolerance.
///
/// **The hue is compared exactly, and the height is not.** A height comes out
/// of a mesh built with `sin` and `pow`, and two hosts' C libraries may
/// disagree about its last bits, which is what `VectorFile.height` absorbs. A
/// hue is the seed's bytes through `+ − × ÷` and nothing else, so it has to be
/// the same double on every host — and this file is where that is found out,
/// because it is compared under WebAssembly as well as on the Mac.
final class GlasshouseVectorTests: XCTestCase {
    static var vectorsURL: URL {
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { url.deleteLastPathComponent() }
        return url.appendingPathComponent("tools/reference/glasshouse_vectors.json")
    }

    static let recordingKey = "PEACE_GARDEN_RECORD_VECTORS"

    static func render() -> String {
        var ways = Glasshouse.Ways.opened()
        var lines: [String] = []
        for (seed, traits) in GlasshouseTests.arrivals() {
            let p = ways.plant(seed: seed, traits: traits)
            let v = PlotVariant.of(plot: p.plot, area: .light)
            lines.append("""
                {"seed":"\(seed.hex)","height":\(traits.height),"family":\(traits.family),\
                "hue":\(traits.hue ?? -1),"plot":\(p.plot),"bed":\(p.slot.bed.rawValue),\
                "index":\(p.slot.index),"row":\(p.slot.row),"nudge":[\(p.nudge.x),\(p.nudge.z)],\
                "variant":[\(v.turn),\(v.mirror),\(v.nudge)],"spot":[\(p.spot.x),\(p.spot.z)]}
                """)
        }
        // One JSON document, not one per line: see `SeedbedVectorTests`.
        return "[\n" + lines.joined(separator: ",\n") + "\n]\n"
    }

    func testTheRecordedPlacementsAreStillWhatTheRuleDoes() throws {
        let rendered = Self.render()
        if ProcessInfo.processInfo.environment[Self.recordingKey] == "1" {
            try rendered.write(to: Self.vectorsURL, atomically: true, encoding: .utf8)
            print("recorded \(Self.vectorsURL.path) — now run php tools/reference/check_glasshouse.php")
        }
        guard let committed = try? String(contentsOf: Self.vectorsURL, encoding: .utf8) else {
            return XCTFail("""
                tools/reference/glasshouse_vectors.json is missing. Record it with \
                \(Self.recordingKey)=1 swift test --package-path Packages/SeedCore --filter GlasshouseVectorTests
                """)
        }
        // Parsed on purpose, as the Seedbed's is: on the recording host the two
        // are byte-equal and nothing below would ever parse the file.
        XCTAssertNotNil(VectorFile.Value(json: committed), "the file is not one JSON document")
        VectorFile.same(committed: committed, rendered: rendered,
                        tolerant: ["height": VectorFile.height],
                        recordWith: """
                            If the rule has moved and that was meant, re-record with \
                            \(Self.recordingKey)=1 swift test --package-path Packages/SeedCore \
                            --filter GlasshouseVectorTests, then run php tools/reference/check_glasshouse.php.
                            """)
    }

    /// **The rule asks one question of a height: which side of the border cut
    /// it falls.** It never weighs one plant's height against another's — the
    /// staging is ordered by hue and the border by arrival — so every recorded
    /// height has to clear 1.30 m by more than two hosts may disagree, and the
    /// groups are single places, which leaves no pair to compare.
    func testThePlacementCannotTurnOnTheLastBitOfAHeight() throws {
        let committed = try String(contentsOf: Self.vectorsURL, encoding: .utf8)
        VectorFile.placementCannotTurn(on: committed, cuts: [Glasshouse.borderFrom],
                                       groupedBy: ["plot", "bed", "index", "row"])
    }

    /// Every hue in the file is one the phone could have sent: a turn of the
    /// circle, from 0 up to 1. The service refuses anything else, so a file
    /// holding one would be a check of an input that can never arrive.
    func testEveryRecordedHueIsATurnOfTheCircle() throws {
        guard case let .list(rows)? = VectorFile.Value(json: try String(contentsOf: Self.vectorsURL,
                                                                        encoding: .utf8)) else {
            return XCTFail("the recorded vectors are not a list of arrivals")
        }
        for row in rows {
            guard case let .object(fields) = row, case let .number(hue)? = fields["hue"] else {
                return XCTFail("an arrival with no hue")
            }
            XCTAssertGreaterThanOrEqual(hue, 0)
            XCTAssertLessThan(hue, 1)
        }
    }
}
