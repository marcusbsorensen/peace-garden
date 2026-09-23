import XCTest
@testable import SeedCore

/// The Seedbed's label: the sixth thing `Organic` knows how to draw.
final class RowLabelTests: XCTestCase {

    private let label = Organic.rowLabel(seed: 909)

    func testItStandsOnTheGroundAndNoHigherThanItIsAskedTo() {
        let ys = label.positions.map { Double($0.y) }
        XCTAssertEqual(ys.min() ?? -1, 0, accuracy: 0.002, "the stake does not reach the soil")
        XCTAssertEqual(ys.max() ?? 0, 0.30, accuracy: 0.02, "the label is not the height it was asked for")
        let xs = label.positions.map { abs(Double($0.x)) }
        XCTAssertLessThan(xs.max() ?? 0, 0.15 / 2 + 0.01, "the tongue is wider than it was asked for")
    }

    /// The whole reason it exists: seen from the garden's fixed eye, a plate
    /// standing upright is a line. The top has to stand back from the foot.
    func testItLeansBack() {
        let low = label.positions.filter { $0.y < 0.05 }.map { Double($0.z) }
        let high = label.positions.filter { $0.y > 0.25 }.map { Double($0.z) }
        let lean = (high.reduce(0, +) / Double(max(high.count, 1)))
            - (low.reduce(0, +) / Double(max(low.count, 1)))
        XCTAssertGreaterThan(lean, 0.06, "the tongue stands too upright to be read")
    }

    /// The hedge was wound inside out once and drew a hole. Signed volume says
    /// which way a closed mesh faces, and it is positive when it faces out.
    func testItIsWoundOutward() {
        var volume = 0.0
        var t = 0
        while t + 2 < label.indices.count {
            let a = label.positions[Int(label.indices[t])]
            let b = label.positions[Int(label.indices[t + 1])]
            let c = label.positions[Int(label.indices[t + 2])]
            let cross = SIMD3<Double>(Double(b.y - a.y) * Double(c.z - a.z) - Double(b.z - a.z) * Double(c.y - a.y),
                                      Double(b.z - a.z) * Double(c.x - a.x) - Double(b.x - a.x) * Double(c.z - a.z),
                                      Double(b.x - a.x) * Double(c.y - a.y) - Double(b.y - a.y) * Double(c.x - a.x))
            volume += (Double(a.x) * cross.x + Double(a.y) * cross.y + Double(a.z) * cross.z) / 6
            t += 3
        }
        XCTAssertGreaterThan(volume, 0, "the label is inside out")
    }

    func testEveryNormalIsAUnitVector() {
        for n in label.normals {
            let length = (n.x * n.x + n.y * n.y + n.z * n.z).squareRoot()
            XCTAssertEqual(Double(length), 1, accuracy: 1e-5)
        }
    }

    /// Pinned, like the rest of `Organic`: the app, the website and the
    /// WebAssembly build have to draw the same label from the same seed.
    func testTheSameSeedDrawsTheSameLabelOnEveryHost() {
        XCTAssertEqual(label.positions.count, 450)
        XCTAssertEqual(label.indices.count, 2304)
        let pinned = label.positions[200]
        XCTAssertEqual(Double(pinned.x), -0.075, accuracy: 1e-6)
        XCTAssertEqual(Double(pinned.y), 0.29055, accuracy: 1e-5)
        XCTAssertEqual(Double(pinned.z), 0.10984572, accuracy: 1e-5)
    }
}
