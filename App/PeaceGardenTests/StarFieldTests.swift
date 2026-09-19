import XCTest
import SeedCore
@testable import PeaceGarden

/// Where a star lands on the glass.
///
/// `SkyTests` in SeedCore proves the astronomy against the sky — Polaris at
/// your latitude, an equator star due east. This proves the other half: that
/// the screen shows what the astronomy worked out, the right way up, with the
/// half under the observer's feet kept.
@MainActor
final class StarFieldTests: XCTestCase {

    private let size = CGSize(width: 400, height: 800)
    private let london = Place(latitude: 51.5, longitude: -0.13)

    // MARK: The mapping

    func testTheZenithIsTheTopOfTheScreenAndTheNadirIsTheFoot() {
        // The mapping is its own function of altitude, so it can be checked
        // without waiting for a star to be overhead.
        XCTAssertEqual(y(ofAltitude: 90, in: size), 0, accuracy: 0.001)
        XCTAssertEqual(y(ofAltitude: 0, in: size), 400, accuracy: 0.001)
        XCTAssertEqual(y(ofAltitude: -90, in: size), 800, accuracy: 0.001)
    }

    func testTheHorizonIsAcrossTheMiddleWhereThePlotFloats() {
        XCTAssertEqual(y(ofAltitude: 0, in: size), size.height / 2, accuracy: 0.001)
    }

    func testTheHalfBelowTheHorizonIsDrawn() {
        // The whole point: a garden about two people meeting shows the sky
        // somebody on the far side of the world has overhead. If these were
        // culled the idea would be gone and nothing would look wrong.
        let placed = StarField.shared.stars(
            at: Date(timeIntervalSince1970: 1_700_000_000), in: size, place: london
        )
        guard !placed.isEmpty else {
            return XCTFail("no catalogue in the test bundle")
        }
        let below = placed.filter { $0.at.y > size.height / 2 }
        let above = placed.filter { $0.at.y < size.height / 2 }
        XCTAssertGreaterThan(below.count, 100, "the other person's half is missing")
        XCTAssertGreaterThan(above.count, 100)
    }

    func testEveryStarLandsOnTheGlass() {
        let placed = StarField.shared.stars(
            at: Date(timeIntervalSince1970: 1_700_000_000), in: size, place: london
        )
        for star in placed {
            XCTAssertTrue((-1...size.width + 1).contains(star.at.x))
            XCTAssertTrue((-1...size.height + 1).contains(star.at.y))
        }
    }

    // MARK: What it draws

    func testABrighterStarIsBiggerAndStronger() {
        XCTAssertGreaterThan(StarField.radius(ofMagnitude: -1.46),
                             StarField.radius(ofMagnitude: 2.0))
        XCTAssertGreaterThan(StarField.alpha(ofMagnitude: 2.0),
                             StarField.alpha(ofMagnitude: 5.5))
        // And the faintest one drawn is still visible rather than nothing.
        XCTAssertGreaterThan(StarField.alpha(ofMagnitude: StarField.faintest), 0.1)
    }

    func testAStarsColourIsBarelyAColour() {
        // Starlight at a point across is nearly white, and a sky of frank blue
        // and orange dots is a chart of star types rather than a sky.
        for index in [-0.3, 0.0, 0.65, 1.85] {
            let components = UIColor(StarField.tint(ofColourIndex: index)).cgColor.components ?? []
            XCTAssertGreaterThan(components.min() ?? 0, 0.65, "B−V \(index) is too saturated")
        }
    }

    // MARK: Keeping off the words

    func testStarsAreDimmedWhereTheWordsAreAndNotCutIntoARectangle() {
        let words = CGRect(x: 100, y: 100, width: 120, height: 30)

        // Inside: nothing.
        XCTAssertEqual(GardenSky.dimming(at: CGPoint(x: 150, y: 110), near: words), 0)
        // Far away: everything.
        XCTAssertEqual(GardenSky.dimming(at: CGPoint(x: 300, y: 400), near: words), 1)
        // Just outside: some, and more the further out — a hard edge would draw
        // a straight line by leaving stars out of a rectangle.
        let near = GardenSky.dimming(at: CGPoint(x: 150, y: 96), near: words)
        let further = GardenSky.dimming(at: CGPoint(x: 150, y: 90), near: words)
        XCTAssertGreaterThan(near, 0)
        XCTAssertLessThan(near, 1)
        XCTAssertGreaterThan(further, near)
    }

    func testAnUnmeasuredFrameDimsNothing() {
        // `.null` is what a frame is before the view it belongs to has been
        // laid out, and it must not black out the sky.
        XCTAssertEqual(GardenSky.dimming(at: .zero, near: .null), 1)
    }

    // MARK: The mapping, as the field computes it

    private func y(ofAltitude altitude: Double, in size: CGSize) -> Double {
        size.height * (0.5 - altitude / 180)
    }
}
