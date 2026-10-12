import XCTest
import SwiftUI
@testable import PeaceGarden

/// The sentences that name the other gardener, with a name and without one.
///
/// What can go wrong silently is the key: a sentence that slots *the other
/// gardener* into its `%@` reads correctly in English and comes out as *Chiedi
/// a l'altra persona* in Italian. So these check which key each sentence looks
/// up, and then that the Italian the app was built with elides.
final class OtherGardenerTests: XCTestCase {

    private let nameless = OtherGardener(name: nil)
    private let cai = OtherGardener(name: "Cai")

    // MARK: Which key

    func testWithNoNameEachSentenceIsAKeyOfItsOwn() {
        XCTAssertEqual(key(nameless.ask), "Ask the other gardener")
        XCTAssertEqual(key(nameless.waitingOn), "Waiting on the other gardener")
        XCTAssertEqual(key(nameless.letItGo), "The other gardener let it go into the Wild Fields")
        XCTAssertEqual(
            key(nameless.wouldLikeItShown),
            "The other gardener would like this plant to stand in the public website garden."
        )
        XCTAssertEqual(
            key(nameless.askWhenTheAreaOpens),
            "It goes on growing here meanwhile, and you can ask the other gardener the day its area opens."
        )
        XCTAssertEqual(
            key(nameless.grewFromBoth(beingAsked: true)),
            "It grew from your seed and the other gardener's together, so the garden carries both. That is why you are being asked."
        )
        XCTAssertEqual(
            key(nameless.grewFromBoth(beingAsked: false)),
            "It grew from your seed and the other gardener's together, so the garden carries both. They are asked before it goes anywhere."
        )
    }

    func testWithANameTheNameGoesInTheSlot() {
        XCTAssertEqual(key(cai.ask), "Ask %@")
        XCTAssertEqual(key(cai.waitingOn), "Waiting on %@")
        XCTAssertEqual(key(cai.letItGo), "%@ let it go into the Wild Fields")
        XCTAssertEqual(key(cai.wouldLikeItShown), "%@ would like this plant to stand in the public website garden.")
        XCTAssertEqual(
            key(cai.askWhenTheAreaOpens),
            "It goes on growing here meanwhile, and you can ask %@ the day its area opens."
        )
        XCTAssertEqual(
            key(cai.grewFromBoth(beingAsked: true)),
            "It grew from your seed and %@'s together, so the garden carries both. That is why you are being asked."
        )
        XCTAssertEqual(
            key(cai.grewFromBoth(beingAsked: false)),
            "It grew from your seed and %@'s together, so the garden carries both. They are asked before it goes anywhere."
        )
        // And the name is what fills it.
        XCTAssertTrue(String(describing: cai.ask).contains("\"Cai\""))
    }

    func testABlankNameIsNoName() {
        XCTAssertNil(OtherGardener(name: "").name)
        XCTAssertNil(OtherGardener(name: "  \n").name)
        XCTAssertEqual(key(OtherGardener(name: " ").ask), "Ask the other gardener")
        XCTAssertEqual(cai.name, "Cai")
    }

    // MARK: What the Italian says

    /// The fault this was made for, read back from the catalogue the app was
    /// built with: Italian elides *a* and *di* before *l'altra persona*.
    func testTheItalianElides() throws {
        let path = try XCTUnwrap(Bundle.main.path(forResource: "it", ofType: "lproj"))
        let italian = try XCTUnwrap(Bundle(path: path))
        func said(_ key: String) -> String {
            italian.localizedString(forKey: key, value: "(missing)", table: nil)
        }
        XCTAssertEqual(said("Ask the other gardener"), "Chiedi all'altra persona")
        XCTAssertEqual(said("Waiting on the other gardener"), "In attesa dell'altra persona")
    }

    // MARK: Fixtures

    /// The catalogue key a `LocalizedStringKey` looks up.
    private func key(_ key: LocalizedStringKey) -> String? {
        Mirror(reflecting: key).children.first { $0.label == "key" }?.value as? String
    }
}
