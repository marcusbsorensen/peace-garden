import XCTest
@testable import PeaceGarden

/// The sun and moon keep off the screen's words.
final class SkyTests: XCTestCase {
    private let screen = CGSize(width: 402, height: 874)
    private let heading = CGRect(x: 26, y: 106, width: 230, height: 44)
    private let close = CGRect(x: 310, y: 62, width: 80, height: 34)

    func testABodyOnTheHeadingMovesOffIt() {
        let reach: CGFloat = 25
        let moved = GardenSky.clear(CGPoint(x: 20, y: 130), of: [heading, close], by: reach, within: screen)
        XCTAssertFalse(heading.insetBy(dx: -reach, dy: -reach).contains(moved), "still on the heading at \(moved)")
        XCTAssertGreaterThanOrEqual(moved.y, 130, "moved up, off the top of the screen")
    }

    func testABodyOnCloseMovesOffIt() {
        let reach: CGFloat = 18
        let moved = GardenSky.clear(CGPoint(x: 350, y: 80), of: [heading, close], by: reach, within: screen)
        XCTAssertFalse(close.insetBy(dx: -reach, dy: -reach).contains(moved), "still on Close at \(moved)")
    }

    func testABodyInOpenSkyStaysWhereTheLightPutsIt() {
        let open = CGPoint(x: 200, y: 400)
        XCTAssertEqual(GardenSky.clear(open, of: [heading, close], by: 25, within: screen), open)
    }

    /// Before either has been measured the frames are null, and nothing moves.
    func testUnmeasuredWordsMoveNothing() {
        let point = CGPoint(x: 40, y: 120)
        XCTAssertEqual(GardenSky.clear(point, of: [.null, .null], by: 25, within: screen), point)
    }
}
