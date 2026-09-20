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
        let placed = field(turn: 0)
        guard !placed.isEmpty else {
            return XCTFail("no catalogue in the test bundle")
        }
        let below = placed.filter { $0.at.y > size.height / 2 }
        let above = placed.filter { $0.at.y < size.height / 2 }
        XCTAssertGreaterThan(below.count, 100, "the other person's half is missing")
        XCTAssertGreaterThan(above.count, 100)
    }

    func testEveryStarLandsOnTheGlass() {
        let placed = field(turn: 0)
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

    // MARK: Turning the garden turns the sky

    func testAQuarterTurnIsAQuarterOfTheSky() {
        // Turning the plot is the person walking round it, so what they can see
        // of the sky moves with it — and by the same amount, which is what makes
        // it a turn rather than a drift.
        XCTAssertEqual(StarField.facing(fromLatitude: 51.5, turn: 0), 180)
        XCTAssertEqual(StarField.facing(fromLatitude: 51.5, turn: 1), 90)
        XCTAssertEqual(StarField.facing(fromLatitude: 51.5, turn: 2), 0)
        XCTAssertEqual(StarField.facing(fromLatitude: 51.5, turn: 3), -90)
        // From the southern hemisphere the sky faces the other way to begin
        // with, and turns the same way from there.
        XCTAssertEqual(StarField.facing(fromLatitude: -33.87, turn: 1), -90)
    }

    func testFourTurnsBringTheSameStarsBack() {
        let start = field(turn: 0)
        guard !start.isEmpty else { return XCTFail("no catalogue in the test bundle") }
        let round = field(turn: 4)

        XCTAssertEqual(round.count, start.count)
        for (before, after) in zip(start, round) {
            XCTAssertEqual(after.at.x, before.at.x, accuracy: 1e-9)
            XCTAssertEqual(after.at.y, before.at.y, accuracy: 1e-9)
        }
        // And turning the other way is turning the other way.
        XCTAssertEqual(field(turn: -4).count, start.count)
        XCTAssertEqual(field(turn: -1).count, field(turn: 3).count)
    }

    func testTurningSlidesTheWholeFieldByAQuarterOfTheFieldOfView() {
        // Every star that survives both turns has moved by exactly the same
        // distance, because a turn moves the observer and not the sky.
        let before = field(turn: 0), after = field(turn: 1)
        guard !before.isEmpty, !after.isEmpty else {
            return XCTFail("no catalogue in the test bundle")
        }
        let quarter = size.width * 90 / Sky.fieldOfView

        var checked = 0
        for star in before {
            let wanted = star.at.x + quarter
            guard wanted <= size.width + 1 else { continue }   // it has gone off the edge
            guard let moved = after.first(where: {
                abs($0.at.y - star.at.y) < 1e-9 && abs($0.radius - star.radius) < 1e-12
            }) else { continue }
            XCTAssertEqual(moved.at.x, wanted, accuracy: 1e-6)
            checked += 1
        }
        XCTAssertGreaterThan(checked, 500, "not enough stars were in both views to say anything")
    }

    func testTheSkyTurnsTheWayThePlotDoes() {
        // **The load-bearing one.** The sun and the moon are placed through the
        // plot's own projection, so they already swing when it is turned. If the
        // stars swung the other way — or by the wrong amount — the sun would
        // walk out of its constellations, and nothing else in the app would
        // notice. This holds the sky's quarter turn to `Isometric`'s.
        //
        // `Isometric.point` puts a horizontal direction at screen x
        // proportional to `a − b`. The claim is that at turn *t* a direction of
        // bearing θ lands where bearing θ + 90t landed at turn 0 — which is the
        // observer having lost ninety degrees a turn, which is the sign
        // `StarField.facing(fromLatitude:turn:)` uses.
        var view = Isometric.fitting(
            plotSide: 8, in: CGSize(width: 400, height: 800), headroom: 3, soilDepth: 1
        )
        for turn in 1...3 {
            for bearing in stride(from: 0.0, to: 360.0, by: 15.0) {
                view.turn = 0
                let shifted = radians(bearing + Double(turn) * 90)
                let atRest = view.point(x: sin(shifted), z: cos(shifted)).x

                view.turn = turn
                let moved = radians(bearing)
                let turned = view.point(x: sin(moved), z: cos(moved)).x

                XCTAssertEqual(turned, atRest, accuracy: 1e-9,
                               "bearing \(bearing) at turn \(turn)")
            }
        }
    }

    // MARK: The mapping, as the field computes it

    private func y(ofAltitude altitude: Double, in size: CGSize) -> Double {
        size.height * (0.5 - altitude / 180)
    }

    private func radians(_ degrees: Double) -> Double { degrees * .pi / 180 }

    private func field(turn: Int) -> [StarField.Placed] {
        StarField.shared.stars(
            at: Date(timeIntervalSince1970: 1_700_000_000),
            in: size,
            place: london,
            facing: StarField.facing(fromLatitude: london.latitude, turn: turn)
        )
    }
}
