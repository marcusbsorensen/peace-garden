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
                "plot":\(p.plot),"frame":\(p.slot.frame.rawValue),"rank":\(p.slot.rank.rawValue),\
                "index":\(p.slot.index),"nudge":[\(p.nudge.x),\(p.nudge.z)]}
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
    func testThePlacementCannotTurnOnTheLastBitOfAHeight() throws {
        let committed = try String(contentsOf: Self.vectorsURL, encoding: .utf8)
        VectorFile.placementCannotTurn(on: committed, cuts: [ColdFrame.backFrom],
                                       groupedBy: ["plot", "frame"])
    }
}
