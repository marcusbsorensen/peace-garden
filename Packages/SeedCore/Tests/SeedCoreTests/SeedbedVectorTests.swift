import XCTest
@testable import SeedCore

/// The Seedbed's placements, recorded so the PHP port can be held to them.
///
/// **No `placementCannotTurn` here, and that is not an omission.** The other
/// five areas record a height that decides something, so a file of them is only
/// as trustworthy as the margin between a plant and the nearest cut — see
/// `.claude/HANDOVER.md` §*The libm divergence*. This rule reads no height at
/// all: a drill comes from the kind and a place from the order of arrival, both
/// of them exact on every host. The height is in the file because it is stored
/// with a planting and drawn, not because anything is decided by it, and
/// `SeedbedTests.testAPlantsHeightChangesNothing` is the proof.
///
/// **The habit and the span since 25 September 2026**, when a lotus began to
/// take two places. Both exact on every host, like the kind, so this file
/// still needs no tolerance but the height's. Its arrivals are the area's own
/// plants since the same day (`SeedbedTests.arrivals`), so it carries a third
/// of them lotuses rather than one in twelve.
final class SeedbedVectorTests: XCTestCase {

    static var vectorsURL: URL {
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { url.deleteLastPathComponent() }
        return url.appendingPathComponent("tools/reference/seedbed_vectors.json")
    }

    static let recordingKey = "PEACE_GARDEN_RECORD_VECTORS"

    static func render() -> String {
        var ways = Seedbed.Ways.opened()
        var lines: [String] = []
        for (seed, traits) in SeedbedTests.arrivals() {
            let p = ways.plant(seed: seed, traits: traits)
            lines.append("""
                {"seed":"\(seed.hex)","height":\(traits.height),"family":\(traits.family),\
                "kind":"\(traits.kind)","habit":"\(traits.habit)","plot":\(p.plot),\
                "drill":\(p.slot.drill),"index":\(p.slot.index),"span":\(p.span),\
                "nudge":[\(p.nudge.x),\(p.nudge.z)]}
                """)
        }
        // One JSON document, not one per line, because a file that differs from
        // the render by a height's last bits has to be parsed to be compared —
        // and on the Mac, where the two are byte-for-byte equal, nothing ever
        // parses it, so a file of lines passes here and fails on another host.
        return "[\n" + lines.joined(separator: ",\n") + "\n]\n"
    }

    func testTheRecordedPlacementsAreStillWhatTheRuleDoes() throws {
        let rendered = Self.render()
        if ProcessInfo.processInfo.environment[Self.recordingKey] == "1" {
            try rendered.write(to: Self.vectorsURL, atomically: true, encoding: .utf8)
            print("recorded \(Self.vectorsURL.path)")
            return
        }
        let committed = try String(contentsOf: Self.vectorsURL, encoding: .utf8)
        VectorFile.same(committed: committed, rendered: rendered,
                        tolerant: ["height": VectorFile.height],
                        recordWith: """
                            re-record with PEACE_GARDEN_RECORD_VECTORS=1 swift test \
                            --package-path Packages/SeedCore --filter SeedbedVectorTests, \
                            then run php tools/reference/check_seedbed.php.
                            """)
    }

    /// A kind is a string the phone sends, so the file has to carry one that
    /// two plants can actually share, or the port would be checked against a
    /// garden of drills holding one plant each.
    func testTheRecordedArrivalsShareTheirKinds() throws {
        let committed = try String(contentsOf: Self.vectorsURL, encoding: .utf8)
        // Parsed here on purpose. The comparison above only parses when the two
        // differ, which on the host that recorded the file is never, so this is
        // the only place a file another host cannot read is caught at home.
        XCTAssertNotNil(VectorFile.Value(json: committed), "the file is not one JSON document")
        var kinds: [String: Int] = [:]
        for line in committed.split(separator: "\n") {
            guard let start = line.range(of: "\"kind\":\"") else { continue }
            let rest = line[start.upperBound...]
            guard let end = rest.firstIndex(of: "\"") else { continue }
            kinds[String(rest[..<end]), default: 0] += 1
        }
        XCTAssertGreaterThan(kinds.count, 20, "too few kinds to be a real sample")
        XCTAssertGreaterThan(kinds.values.max() ?? 0, 8,
                             "no kind arrives often enough to fill a drill")
    }
}
