import XCTest
@testable import SeedCore

/// Pins `tools/reference/coppice_vectors.json` to where `Coppice` puts things,
/// so `tools/reference/check_coppice.php` can hold the PHP port to it.
///
/// **Five hundred plants of this area's own**, as `CoppiceTests` draws them,
/// because the floor's cut was measured over those.
///
/// **The habit is compared exactly, and the height is not.** A height comes
/// out of a mesh built with `sin` and `pow`, which is what `VectorFile.height`
/// absorbs; an archetype is picked from the seed's bytes, so it is the same
/// word on every host.
final class CoppiceVectorTests: XCTestCase {
    static var vectorsURL: URL {
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { url.deleteLastPathComponent() }
        return url.appendingPathComponent("tools/reference/coppice_vectors.json")
    }

    static let recordingKey = "PEACE_GARDEN_RECORD_VECTORS"

    static func render() -> String {
        var ways = Coppice.Ways.opened()
        var lines: [String] = []
        for (seed, traits) in CoppiceTests.arrivals() {
            let p = ways.plant(seed: seed, traits: traits)
            lines.append("""
                {"seed":"\(seed.hex)","height":\(traits.height),"family":\(traits.family),\
                "habit":"\(traits.habit)","plot":\(p.plot),"coupe":\(p.slot.coupe),\
                "place":\(p.slot.place.rawValue),"floor":\(p.slot.place == .stool ? 0 : 1),\
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
            print("recorded \(Self.vectorsURL.path) — now run php tools/reference/check_coppice.php")
        }
        guard let committed = try? String(contentsOf: Self.vectorsURL, encoding: .utf8) else {
            return XCTFail("""
                tools/reference/coppice_vectors.json is missing. Record it with \
                \(Self.recordingKey)=1 swift test --package-path Packages/SeedCore --filter CoppiceVectorTests
                """)
        }
        XCTAssertNotNil(VectorFile.Value(json: committed), "the file is not one JSON document")
        VectorFile.same(committed: committed, rendered: rendered,
                        tolerant: ["height": VectorFile.height],
                        recordWith: """
                            If the rule has moved and that was meant, re-record with \
                            \(Self.recordingKey)=1 swift test --package-path Packages/SeedCore \
                            --filter CoppiceVectorTests, then run php tools/reference/check_coppice.php.
                            """)
    }

    /// **The rule asks two questions of a height**: which side of 1.10 m it
    /// falls, and, on a coupe's floor, whether it is taller than a plant in
    /// the other row. So every recorded height has to clear the cut by more
    /// than two hosts may disagree, and no two plants on one floor may stand
    /// that close to each other. The stools are grouped apart: nothing there
    /// is weighed by height.
    func testThePlacementCannotTurnOnTheLastBitOfAHeight() throws {
        let committed = try String(contentsOf: Self.vectorsURL, encoding: .utf8)
        VectorFile.placementCannotTurn(on: committed, cuts: [Coppice.backFrom],
                                       groupedBy: ["plot", "coupe", "floor"])
    }
}
