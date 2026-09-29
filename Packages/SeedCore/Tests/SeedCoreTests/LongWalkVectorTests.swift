import XCTest
@testable import SeedCore

/// Pins `tools/reference/long_walk_vectors.json` to where `LongWalk` puts things.
///
/// The plot service places arrivals in PHP, because the server is PHP and
/// cannot run SeedCore. That makes it a port, and a port drifts unless
/// something holds it: this file is what the Swift rule does with six hundred
/// arrivals, and `tools/reference/check_long_walk.php` fails CI if the PHP puts
/// any of them anywhere else. Both have to pass for the service and the app to
/// be walking the same walk.
final class LongWalkVectorTests: XCTestCase {
    static var vectorsURL: URL {
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { url.deleteLastPathComponent() }   // …/Tests/SeedCoreTests/<this>
        return url.appendingPathComponent("tools/reference/long_walk_vectors.json")
    }

    static let recordingKey = "PEACE_GARDEN_RECORD_VECTORS"

    /// Six hundred arrivals: enough to fill a dozen plots, reach the fallbacks
    /// (the tier beside, a new plot) and refuse slots that would overfill a drift.
    /// Heights follow the measured spread, and colours all seven families.
    static func arrivals() -> [(SeedID, LongWalk.Traits)] {
        var random = SplitMix64(seed: 1809)
        return (0..<600).map { n in
            let u = Double(random.next() % 10_000) / 10_000
            // The measured thirds, as `LongWalkTests` draws them: 0.12, 0.62,
            // 1.07 and 2.47 since 29 September 2026.
            let height = u < 1 / 3 ? 0.12 + u * 3 * 0.50
                : u < 2 / 3 ? 0.62 + (u - 1 / 3) * 3 * 0.45
                : 1.07 + (u - 2 / 3) * 3 * 1.40
            let family = Int(random.next() % 7)
            let seed = SeedMint.mint(fromEntropy: Data("long-walk-vector-\(n)".utf8))
            return (seed, LongWalk.Traits(height: height, family: family))
        }
    }

    /// One arrival per line, and where it went, so a failure names the arrival.
    static func render() -> String {
        var walk = LongWalk.Walk()
        var lines: [String] = []
        for (seed, traits) in arrivals() {
            let p = walk.plant(seed: seed, traits: traits)
            lines.append("""
                {"seed":"\(seed.hex)","height":\(traits.height),"family":\(traits.family),\
                "plot":\(p.plot),"side":\(p.slot.side.rawValue),"tier":\(p.slot.tier.rawValue),\
                "index":\(p.slot.index),"nudge":[\(p.nudge.x),\(p.nudge.z)]}
                """)
        }
        return "[\n" + lines.joined(separator: ",\n") + "\n]\n"
    }

    func testTheCommittedVectorsAreWhatTheSwiftPlaces() throws {
        let rendered = Self.render()
        if ProcessInfo.processInfo.environment[Self.recordingKey] == "1" {
            try rendered.write(to: Self.vectorsURL, atomically: true, encoding: .utf8)
            print("re-recorded \(Self.vectorsURL.path) — now run php tools/reference/check_long_walk.php")
        }
        let committed: String
        do {
            committed = try String(contentsOf: Self.vectorsURL, encoding: .utf8)
        } catch {
            return XCTFail("""
                tools/reference/long_walk_vectors.json is missing. Record it with \
                `\(Self.recordingKey)=1 swift test --package-path Packages/SeedCore \
                --filter LongWalkVectorTests`.
                """)
        }
        // **A grown height is allowed a hundredth of a millimetre and nothing
        // else is allowed anything.** Two C libraries do not agree to the last
        // bit about `sin`, `cos`, `pow` and `exp`, and a plant's mesh is built out
        // of all four; the side, the tier, the slot and the nudge are arithmetic
        // and must still match exactly. `VectorFile` sets out the measurement
        // this rests on.
        VectorFile.same(committed: committed, rendered: rendered,
                        tolerant: ["height": VectorFile.height],
                        recordWith: """
                            If the rule changed on purpose, re-record with \
                            \(Self.recordingKey)=1 swift test --package-path Packages/SeedCore \
                            --filter LongWalkVectorTests, and bring Server/.api/LongWalk.php along \
                            until tools/reference/check_long_walk.php passes.
                            """)
    }

    /// **And the tolerance the comparison above allows cannot move a plant.**
    ///
    /// The rule asks two kinds of question about a height: which side of a cut
    /// it falls, and whether it is taller than another plant in a tier of one side of one plot.
    /// This says every recorded height clears both cuts, and every pair the
    /// rule compares is further apart than twice the tolerance — so a host that
    /// computes a height a few of a `Float`'s last bits differently still puts
    /// every one of these five hundred in the same place.
    func testThePlacementCannotTurnOnTheLastBitOfAHeight() throws {
        let committed = try String(contentsOf: Self.vectorsURL, encoding: .utf8)
        VectorFile.placementCannotTurn(on: committed,
                                       cuts: [LongWalk.middleFrom, LongWalk.backFrom],
                                       groupedBy: ["plot", "side", "tier"])
    }
}
