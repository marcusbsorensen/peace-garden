import XCTest
@testable import SeedCore

/// Pins `tools/reference/home_ground_vectors.json` to where `HomeGround` puts
/// things, so `tools/reference/check_home_ground.php` can hold the PHP port to
/// it.
///
/// **Five hundred plants of this area's own**, as `HomeGroundTests` draws them,
/// which is the simulation's fresh stream.
///
/// **The habit and the crop are compared exactly, and the height is not.** A
/// height comes out of a mesh built with `sin` and `pow`, which is what
/// `VectorFile.height` absorbs; an archetype is picked from the seed's bytes,
/// so it is the same word on every host.
final class HomeGroundVectorTests: XCTestCase {
    static var vectorsURL: URL {
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { url.deleteLastPathComponent() }
        return url.appendingPathComponent("tools/reference/home_ground_vectors.json")
    }

    static let recordingKey = "PEACE_GARDEN_RECORD_VECTORS"

    static func render() -> String {
        var ways = HomeGround.Ways.opened()
        var lines: [String] = []
        for (seed, traits) in HomeGroundTests.arrivals() {
            let p = ways.plant(seed: seed, traits: traits)
            lines.append("""
                {"seed":"\(seed.hex)","height":\(traits.height),"family":\(traits.family),\
                "habit":"\(traits.habit)","plot":\(p.plot),"bed":\(p.slot.bed),\
                "crop":"\(p.slot.crop.rawValue)","index":\(p.slot.index),\
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
            print("recorded \(Self.vectorsURL.path) — now run php tools/reference/check_home_ground.php")
        }
        guard let committed = try? String(contentsOf: Self.vectorsURL, encoding: .utf8) else {
            return XCTFail("""
                tools/reference/home_ground_vectors.json is missing. Record it with \
                \(Self.recordingKey)=1 swift test --package-path Packages/SeedCore --filter HomeGroundVectorTests
                """)
        }
        XCTAssertNotNil(VectorFile.Value(json: committed), "the file is not one JSON document")
        VectorFile.same(committed: committed, rendered: rendered,
                        tolerant: ["height": VectorFile.height],
                        recordWith: """
                            If the rule has moved and that was meant, re-record with \
                            \(Self.recordingKey)=1 swift test --package-path Packages/SeedCore \
                            --filter HomeGroundVectorTests, then run php tools/reference/check_home_ground.php.
                            """)
    }

    /// **The rule asks one question of a height: which side of its own crop's
    /// cut it falls.** It never weighs two plants against each other, so every
    /// recorded height has to clear its crop's cut by more than two hosts may
    /// disagree, and nothing more.
    ///
    /// **Per crop, not every cut against every height**, which
    /// `VectorFile.placementCannotTurn` would do: a spire in this file stands
    /// 0.005 mm from the umbel's 0.930, and a spire is never asked about it.
    func testThePlacementCannotTurnOnTheLastBitOfAHeight() throws {
        let committed = try String(contentsOf: Self.vectorsURL, encoding: .utf8)
        guard case let .list(rows)? = VectorFile.Value(json: committed) else {
            return XCTFail("the recorded vectors are not a list of arrivals")
        }
        var nearest = Double.greatestFiniteMagnitude, nearestIs = ""
        for row in rows {
            guard case let .object(fields) = row,
                  case let .number(height)? = fields["height"],
                  case let .text(root)? = fields["crop"],
                  let crop = HomeGround.Crop(rawValue: root) else {
                return XCTFail("a row without a height and a crop")
            }
            if abs(height - crop.cut) < nearest {
                nearest = abs(height - crop.cut)
                nearestIs = "a \(root) \(height) m tall against its cut at \(crop.cut) m"
            }
        }
        XCTAssertEqual(rows.count, 500)
        XCTAssertGreaterThan(nearest, VectorFile.height, """
            \(nearestIs) — closer to its cut than the \(VectorFile.height) m two hosts \
            are allowed to disagree by, so which end of the bed it takes is no longer \
            the same on every host
            """)
    }
}
