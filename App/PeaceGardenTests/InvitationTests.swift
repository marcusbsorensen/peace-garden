import XCTest
import SwiftUI
import SeedCore
@testable import PeaceGarden

/// How the garden says somebody is waiting on an answer.
///
/// The notice at the foot, the threads that join it to the plants it is about,
/// and the chevrons that walk between them. What is checked here is the part
/// that can be got wrong silently: who the notice names, and that a thread is
/// a thread rather than a ruled line.
final class InvitationTests: XCTestCase {

    // MARK: Who is asking

    func testEachGardenerIsNamedOnceHoweverManyPlantsTheyHaveAskedAbout() {
        let waiting = [invitation(from: "Cai"), invitation(from: "Ines"), invitation(from: "Cai")]
        // Two plants from one meeting are two questions and one person. Saying
        // "Cai and Cai" would be counting plants while appearing to count people.
        XCTAssertEqual(PlotView.gardenersAsking(waiting), ["Cai", "Ines"])
    }

    func testTheOrderIsTheOrderTheirPlantsArrived() {
        let waiting = [invitation(from: "Ines"), invitation(from: "Ada"), invitation(from: "Cai")]
        XCTAssertEqual(PlotView.gardenersAsking(waiting), ["Ines", "Ada", "Cai"])
    }

    func testAMeetingWithNoNameStillNamesSomebody() {
        // A name is a claim the other phone made and it may not have made one.
        // The sentence still has to have a subject.
        let waiting = [invitation(from: nil)]
        XCTAssertEqual(PlotView.gardenersAsking(waiting).count, 1)
        XCTAssertFalse(PlotView.gardenersAsking(waiting)[0].isEmpty)
    }

    @MainActor
    func testAMeetingWithNoNameIsListedLastSoItNeverOpensTheSentence() {
        let waiting = [invitation(from: nil), invitation(from: "Cai")]
        XCTAssertEqual(PlotView.gardenersAsking(waiting), ["Cai", String(localized: "the other gardener")])
    }

    @MainActor
    func testWithNobodyNamedTheNoticeIsASentenceOfItsOwn() {
        // Not *the other gardener* in the name's slot: see `OtherGardener`.
        XCTAssertEqual(
            key(PlotView.asked(by: [invitation(from: nil)])),
            "The other gardener has asked to show a plant you grew together"
        )
        XCTAssertEqual(
            key(PlotView.asked(by: [invitation(from: nil), invitation(from: nil)])),
            "The other gardener has asked to show plants you grew together"
        )
    }

    @MainActor
    func testWithSomebodyNamedTheNoticeNamesThem() {
        XCTAssertEqual(
            key(PlotView.asked(by: [invitation(from: "Cai")])),
            "%@ has asked to show a plant you grew together"
        )
        XCTAssertEqual(
            key(PlotView.asked(by: [invitation(from: nil), invitation(from: "Cai")])),
            "%@ have asked to show plants you grew together"
        )
    }

    // The verb agrees with the people and the rest with the plants (Marcus,
    // 12 October: 3A). Until then the plants decided both, and one person
    // asking about two plants read *Cai have asked*.

    @MainActor
    func testOnePersonAndOnePlant() {
        XCTAssertEqual(
            key(PlotView.asked(by: [invitation(from: "Cai")])),
            "%@ has asked to show a plant you grew together"
        )
    }

    @MainActor
    func testOnePersonAndSeveralPlantsHasAskedToShowPlants() {
        XCTAssertEqual(
            key(PlotView.asked(by: [invitation(from: "Cai"), invitation(from: "Cai")])),
            "%@ has asked to show plants you grew together"
        )
    }

    @MainActor
    func testSeveralPeopleAndSeveralPlants() {
        XCTAssertEqual(
            key(PlotView.asked(by: [invitation(from: "Cai"), invitation(from: "Nadia")])),
            "%@ have asked to show plants you grew together"
        )
    }

    @MainActor
    func testSomebodyUnnamedIsAPersonForTheVerb() {
        // Cai, and the other gardener after *and*: two people, so two plants.
        XCTAssertEqual(
            key(PlotView.asked(by: [OtherGardener(name: nil), OtherGardener(name: "Cai")], plants: 2)),
            "%@ have asked to show plants you grew together"
        )
    }

    // MARK: The chevrons

    func testAChevronPointsTheWayItSaysItDoes() {
        let box = CGRect(x: 0, y: 0, width: 20, height: 40)
        let trailing = ChevronGlyph(towardsTrailing: true).path(in: box)
        let leading = ChevronGlyph(towardsTrailing: false).path(in: box)

        // The point is the far side of the bend, and it is on the side the
        // chevron is sending you to.
        XCTAssertGreaterThan(trailing.boundingRect.maxX, box.midX)
        XCTAssertLessThan(leading.boundingRect.minX, box.midX)
        XCTAssertEqual(trailing.boundingRect.width, leading.boundingRect.width, accuracy: 0.001)
    }

    func testAChevronIsTallerThanItIsWideSoItReadsAsOneAtAnySize() {
        let path = ChevronGlyph().path(in: CGRect(x: 0, y: 0, width: 20, height: 40))
        XCTAssertGreaterThan(path.boundingRect.height, path.boundingRect.width)
    }

    // MARK: Fixtures

    /// The catalogue key a `LocalizedStringKey` looks up.
    private func key(_ key: LocalizedStringKey) -> String? {
        Mirror(reflecting: key).children.first { $0.label == "key" }?.value as? String
    }

    private func seed(_ of: String) -> SeedID {
        SeedID(bytes: seedDigest(SeedDomain.seed, Data(of.utf8)))!
    }

    private func invitation(from peer: String?) -> PlantRecord {
        let mine = seed("mine")
        let theirs = seed(peer ?? "nameless")
        let encounter = Pollination.encounterID(
            seedA: mine, seedB: theirs,
            nonceA: Data("a".utf8), nonceB: Data("b".utf8)
        )
        return PlantRecord(
            seed: Pollination.cross(seedA: mine, seedB: theirs, encounterID: encounter),
            lineage: .crossed(parentA: mine, parentB: theirs, encounterID: encounter),
            birth: Date(timeIntervalSince1970: 0),
            encounter: peer.map {
                EncounterNote(peerDisplayName: $0, happenedAt: Date(timeIntervalSince1970: 0))
            },
            standing: Standing(state: .invited, changedAt: .distantPast)
        )
    }
}
