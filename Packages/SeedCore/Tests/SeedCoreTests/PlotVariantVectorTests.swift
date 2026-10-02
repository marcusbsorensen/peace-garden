import XCTest
@testable import SeedCore

/// Pins `tools/reference/plot_variant_vectors.json` to what `PlotVariant`
/// deals, so `tools/reference/check_plot_variant.php` and
/// `check_plot_variant.mjs` can hold the PHP and the browser's ports to it.
///
/// **Every space an area could declare, not the ten the areas declare
/// today.** Each area settles its own space as its layout is built, in its own
/// file; a shared file listing all ten would be re-recorded by every one of
/// them. So this pins the function, with each space dealt under a different
/// area's salt, and an area that reads its variant pins its own plots in its
/// own vector file.
///
/// **Compared exactly**, every field: a variant is integers, and a turned
/// place is the same two numbers with their signs changed.
final class PlotVariantVectorTests: XCTestCase {
    static var vectorsURL: URL {
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { url.deleteLastPathComponent() }
        return url.appendingPathComponent("tools/reference/plot_variant_vectors.json")
    }

    static let recordingKey = "PEACE_GARDEN_RECORD_VECTORS"

    /// How many plots of each space are dealt: past a hundred blocks of the
    /// smallest dealt space and twelve of the largest.
    static let plots = 300

    static func render() -> String {
        var out: [String] = []
        let salts = Area.allCases.map { "\"\($0.rawValue)\":\(PlotVariant.salt(of: $0))" }
        out.append("\"salts\":{\(salts.joined(separator: ","))}")

        var dealt: [String] = []
        for (n, space) in PlotVariantTests.spaces.enumerated() {
            let area = Area.allCases[n % Area.allCases.count]
            let row = (0..<plots).map { plot -> String in
                let v = PlotVariant.of(plot: plot, salt: PlotVariant.salt(of: area), in: space)
                return "[\(v.turn),\(v.mirror ? 1 : 0),\(v.nudge)]"
            }
            dealt.append("""
                {"area":"\(area.rawValue)","turns":\(space.turns),"mirror":\(space.mirror),\
                "nudges":\(space.nudges),"plots":[\(row.joined(separator: ","))]}
                """)
        }
        out.append("\"dealt\":[\n" + dealt.joined(separator: ",\n") + "\n]")

        var spots: [String] = []
        let points = [Spot(x: 1.234, z: -0.567), Spot(x: 0, z: 2.1), Spot(x: -2.45, z: 0),
                      Spot(x: -0.875, z: -1.5), Spot(x: 0.333, z: 0.333)]
        for point in points {
            for turn in 0..<4 {
                for mirror in [false, true] {
                    let v = PlotVariant(turn: turn, mirror: mirror, nudge: 0)
                    let to = v.apply(point)
                    spots.append("""
                        {"turn":\(turn),"mirror":\(mirror),"from":[\(point.x),\(point.z)],"to":[\(to.x),\(to.z)]}
                        """)
                }
            }
        }
        out.append("\"spots\":[\n" + spots.joined(separator: ",\n") + "\n]")
        return "{\n" + out.joined(separator: ",\n") + "\n}\n"
    }

    func testTheRecordedVariantsAreStillWhatIsDealt() throws {
        let rendered = Self.render()
        if ProcessInfo.processInfo.environment[Self.recordingKey] == "1" {
            try rendered.write(to: Self.vectorsURL, atomically: true, encoding: .utf8)
            print("recorded \(Self.vectorsURL.path) — now run php tools/reference/check_plot_variant.php")
        }
        guard let committed = try? String(contentsOf: Self.vectorsURL, encoding: .utf8) else {
            return XCTFail("""
                tools/reference/plot_variant_vectors.json is missing. Record it with \
                \(Self.recordingKey)=1 swift test --package-path Packages/SeedCore --filter PlotVariantVectorTests
                """)
        }
        XCTAssertNotNil(VectorFile.Value(json: committed), "the file is not one JSON document")
        VectorFile.same(committed: committed, rendered: rendered, tolerant: [:],
                        recordWith: """
                            If the deal has moved and that was meant, re-record with \
                            \(Self.recordingKey)=1 swift test --package-path Packages/SeedCore \
                            --filter PlotVariantVectorTests, then run php tools/reference/check_plot_variant.php \
                            and node tools/reference/check_plot_variant.mjs.
                            """)
    }
}
