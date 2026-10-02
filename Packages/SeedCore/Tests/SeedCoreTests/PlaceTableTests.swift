import XCTest
@testable import SeedCore

/// A place table made offline (`tools/layouts`), read the way an area will
/// read one, on `PlaceTable.example`: a table no area uses, kept to show the
/// generator working end to end.
///
/// `tools/layouts/generate.py --check` holds the Swift, the PHP and the
/// JavaScript to the spec byte for byte; this holds what the spec promised —
/// that the places are where it says and already in fill order.
final class PlaceTableTests: XCTestCase {

    let table = PlaceTable.example
    let bed = 0, pool = 1, edge = 2

    func testTheExampleHoldsWhatItsSpecSays() {
        XCTAssertEqual(table.name, "example")
        XCTAssertEqual(table.fields, ["kind"])
        XCTAssertEqual(table.nudges, 2)
        for nudge in 0..<table.nudges {
            let kinds = table.places(nudge: nudge).map { table.tag("kind", of: $0) }
            XCTAssertEqual(kinds.filter { $0 == bed }.count, 9)
            XCTAssertEqual(kinds.filter { $0 == pool }.count, 7)
            XCTAssertEqual(kinds.filter { $0 == edge }.count, 5)
        }
        XCTAssertNotEqual(table.places(nudge: 0), table.places(nudge: 1), "the pool did not move")
    }

    /// Every place in the bed is in the bed's outline, and every place in the
    /// pool in the pool's: the curves and the places came out of one spec.
    func testThePlacesStandInsideTheirOutlines() {
        for nudge in 0..<table.nudges {
            let bedLine = table.curves["bed"]![nudge].points
            let poolLine = table.curves["pool"]![nudge].points
            for place in table.places(nudge: nudge) {
                switch table.tag("kind", of: place) {
                case bed: XCTAssertTrue(Organic.contains(bedLine, x: place.x, z: place.z), "\(place)")
                case pool: XCTAssertTrue(Organic.contains(poolLine, x: place.x, z: place.z), "\(place)")
                default: XCTAssertFalse(Organic.contains(poolLine, x: place.x, z: place.z), "\(place)")
                }
            }
        }
    }

    /// **The fill order is in the table.** In the bed, each place is the
    /// farthest from those before it; in the pool, each is no nearer the
    /// pool's middle than the one before. A rule that takes the first free
    /// place in order leaves every count spread and centred.
    func testTheOrderIsFarthestFirstAndCentreFirst() {
        for nudge in 0..<table.nudges {
            let places = table.places(nudge: nudge)
            let inBed = places.filter { table.tag("kind", of: $0) == bed }
            for i in 1..<inBed.count {
                func gap(_ p: PlaceTable.Place) -> Double {
                    inBed[..<i].map { ($0.x - p.x) * ($0.x - p.x) + ($0.z - p.z) * ($0.z - p.z) }.min()!
                }
                for later in inBed[(i + 1)...] {
                    // Within what writing each place to the millimetre can
                    // move a squared distance across a plot.
                    XCTAssertGreaterThanOrEqual(gap(inBed[i]) + 0.01, gap(later),
                                                "bed place \(i) of variant \(nudge) is not the farthest")
                }
            }
            let inPool = places.filter { table.tag("kind", of: $0) == pool }
            // Where the spec centres each variant's sunflower.
            let middle = [Spot(x: 1.05, z: -0.95), Spot(x: 0.80, z: -1.20)][nudge]
            let out = inPool.map { ($0.x - middle.x) * ($0.x - middle.x) + ($0.z - middle.z) * ($0.z - middle.z) }
            XCTAssertEqual(out, out.sorted(), "the pool does not fill from its middle")
        }
    }

    /// A plot's variant moves the table's places exactly, and takes its
    /// feature variant's places.
    func testAPlotsVariantTurnsTheTable() {
        let v = PlotVariant(turn: 3, mirror: true, nudge: 1)
        for (i, place) in table.places(nudge: 1).enumerated() {
            XCTAssertEqual(table.spot(i, on: v), v.apply(place.spot))
        }
        let edgeLine = table.curve("edge", on: v)
        XCTAssertFalse(edgeLine.closed)
        XCTAssertEqual(edgeLine.points, table.curves["edge"]![1].points.map(v.apply))
    }
}
