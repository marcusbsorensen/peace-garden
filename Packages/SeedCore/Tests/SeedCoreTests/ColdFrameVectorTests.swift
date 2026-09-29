import XCTest
@testable import SeedCore

/// Pins `tools/reference/cold_frame_vectors.json` to where `ColdFrame` puts
/// things, so `tools/reference/check_cold_frame.php` can hold the PHP port to
/// it.
///
/// **Five hundred plants of this area's own**, as `ColdFrameTests` draws them,
/// because the cut is the median of those and a file of any crossing would
/// crowd the back rank and check the port against a rule nobody sees run.
///
/// **This area reads a height again**, as the Seedbed did not, so the file is
/// only as trustworthy as the margin between each plant and the cut — see
/// `VectorFile` — and `testThePlacementCannotTurnOnTheLastBitOfAHeight` is
/// here for the reason it is in the Knot Garden's suite.
///
/// **The habit and the span since 25 September 2026**, when a lotus began to
/// take two places. The habit is a word and the span a count, exact on every
/// host, so the port is held to both with no tolerance.
///
/// **Re-recorded on 27 September 2026, when the tank was sunk.** Every lily
/// is now filed in frame 4 with one place, and the cut moved from 0.38 to the
/// dry median of 0.50, so almost every line in the file moved. The habit is
/// what routes a plant to the water and it is read from bytes with no `sin`
/// or `pow` in it, so the two hosts cannot disagree about which element a
/// plant is in — only, within a tolerance, about its height.
///
/// **Re-recorded on 29 September 2026**, when the tank grew to thirty-nine
/// places in the front row's ground and the cut moved to 0.49: nine plots
/// where there were seventeen, and every plant's place with them.
final class ColdFrameVectorTests: XCTestCase {
    static var vectorsURL: URL {
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { url.deleteLastPathComponent() }
        return url.appendingPathComponent("tools/reference/cold_frame_vectors.json")
    }

    static let recordingKey = "PEACE_GARDEN_RECORD_VECTORS"

    static func render() -> String {
        var ways = ColdFrame.Ways.opened()
        var lines: [String] = []
        for (seed, traits) in ColdFrameTests.arrivals() {
            let p = ways.plant(seed: seed, traits: traits)
            lines.append("""
                {"seed":"\(seed.hex)","height":\(traits.height),"family":\(traits.family),\
                "habit":"\(traits.habit)","plot":\(p.plot),"frame":\(p.slot.frame.rawValue),\
                "rank":\(p.slot.rank.rawValue),"index":\(p.slot.index),"span":\(p.span),\
                "nudge":[\(p.nudge.x),\(p.nudge.z)]}
                """)
        }
        // One JSON document, not one per line: see `SeedbedVectorTests`.
        return "[\n" + lines.joined(separator: ",\n") + "\n]\n"
    }

    func testTheRecordedPlacementsAreStillWhatTheRuleDoes() throws {
        let rendered = Self.render()
        if ProcessInfo.processInfo.environment[Self.recordingKey] == "1" {
            try rendered.write(to: Self.vectorsURL, atomically: true, encoding: .utf8)
            print("recorded \(Self.vectorsURL.path) — now run php tools/reference/check_cold_frame.php")
        }
        guard let committed = try? String(contentsOf: Self.vectorsURL, encoding: .utf8) else {
            return XCTFail("""
                tools/reference/cold_frame_vectors.json is missing. Record it with \
                \(Self.recordingKey)=1 swift test --package-path Packages/SeedCore --filter ColdFrameVectorTests
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
                            --filter ColdFrameVectorTests, then run php tools/reference/check_cold_frame.php.
                            """)
    }

    /// The rule asks which side of `backFrom` a height falls, and whether it is
    /// taller than another plant in the same frame. Every recorded height has
    /// to clear the one and every pair in a frame the other by more than two
    /// hosts are allowed to disagree.
    ///
    /// **Asked of the plants under glass only, since 29 September 2026.** The
    /// water reads no height — what wants water goes in the first free place of
    /// the oldest tank, whatever its height — so a tank is not a group whose
    /// heights are ever weighed. It was asked of the tank as well while a tank
    /// held twenty-one; at thirty-nine, two lilies in one of them stand 4.8 µm
    /// apart, which would matter only to a rule that compared them.
    func testThePlacementCannotTurnOnTheLastBitOfAHeight() throws {
        let committed = try String(contentsOf: Self.vectorsURL, encoding: .utf8)
        let tank = "\"frame\":\(ColdFrame.Frame.tank.rawValue),"
        let dry = committed.split(separator: "\n")
            .filter { $0.hasPrefix("{") && !$0.contains(tank) }
            .map { $0.hasSuffix(",") ? String($0.dropLast()) : String($0) }
        XCTAssertGreaterThan(dry.count, 100)
        VectorFile.placementCannotTurn(on: "[\n" + dry.joined(separator: ",\n") + "\n]\n",
                                       cuts: [ColdFrame.backFrom], groupedBy: ["plot", "frame"])
    }
}
