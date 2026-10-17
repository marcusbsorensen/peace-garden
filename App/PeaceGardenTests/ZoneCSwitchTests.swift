import SeedCore
import SwiftUI
import XCTest
@testable import PeaceGarden

/// The two switches of Zone C and what they do to the suite's folder (package
/// A5; `DESIGN.md` §7, item 16, Marcus, 17 October 2026).
///
/// - **News from the garden** is the old launch-request switch under its new
///   name, on the same stored key.
/// - **Zone C** is a second switch, shown only while Autonaut has been on the
///   phone, off until the person turns it on.
/// - `Seeds/v1/exchange` is there only while both are on, and "Reset everything"
///   erases Zone C and leaves both switches where they were.
///
/// The folder is a temporary directory, the service is `AskingTests.Stub`, and
/// the two keys in `UserDefaults` are cleared before and after, so nothing here
/// touches the real App Group or a network.
@MainActor
final class ZoneCSwitchTests: XCTestCase {
    private var host: AccessibilityHost!
    private var stub = AskingTests.Stub()
    private var base = URL(fileURLWithPath: "/")
    private var root = URL(fileURLWithPath: "/")
    private var gardenFile = URL(fileURLWithPath: "/")

    private let r = "00112233445566778899aabbccddeeff"

    override func setUp() async throws {
        try await super.setUp()
        host = AccessibilityHost()
        stub = AskingTests.Stub()
        base = FileManager.default.temporaryDirectory
            .appendingPathComponent("zonec-switch-\(UUID().uuidString)", isDirectory: true)
        root = base.appendingPathComponent("suite", isDirectory: true)
        gardenFile = base.appendingPathComponent("app", isDirectory: true)
            .appendingPathComponent("garden.json")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(
            at: gardenFile.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        clearSwitches()
    }

    override func tearDown() async throws {
        host.tearDown()
        host = nil
        clearSwitches()
        try? FileManager.default.removeItem(at: base)
        try await super.tearDown()
    }

    private func clearSwitches() {
        UserDefaults.standard.removeObject(forKey: Sharing.invitationsKey)
        UserDefaults.standard.removeObject(forKey: ZoneCExchange.enabledKey)
    }

    // MARK: Things that stand in

    private func suite() -> SuiteTransit {
        SuiteTransit(group: SuiteGroup(container: DirectoryContainer(url: root)))
    }

    /// What Autonaut leaves when it is installed.
    private func autonautIsInstalled() throws {
        try suite().prepare()
        try suite().group.stage(Data(), to: SuiteTransit.autonautPresence)
    }

    private func model() -> GardenModel {
        let store = GardenStore(fileURL: gardenFile, writeOptions: [.atomic])
        return GardenModel(
            store: store,
            plots: PlotService(transport: stub, origin: URL(string: "https://example.invalid")!),
            suite: suite()
        )
    }

    private func settings(_ model: GardenModel) -> some View {
        SettingsView(close: {})
            .environment(model)
            .environment(PlaceKeeping())
    }

    private func exists(_ relative: String) -> Bool {
        FileManager.default.fileExists(atPath: root.appendingPathComponent(relative).path)
    }

    private func names(in folder: String) -> [String] {
        let path = root.appendingPathComponent(folder).path
        return ((try? FileManager.default.contentsOfDirectory(atPath: path)) ?? []).sorted()
    }

    private func put(_ text: String, in folder: String, named name: String) throws {
        let url = root.appendingPathComponent(folder)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        try Data(text.utf8).write(to: url.appendingPathComponent(name))
    }

    private func label(_ english: String) -> String {
        String(localized: String.LocalizationValue(english))
    }

    // MARK: The rows

    private static let newsNote = "The app asks the web garden each time it starts."
    private static let zoneCNote = "Seeds can pass between this app and Autonaut."

    /// **The launch-request row, relabelled.** One short line under it, and the
    /// old words gone.
    func testTheNewsSwitchHasItsLabelAndItsNote() async throws {
        try await host.show(settings(model()))
        let found = host.elements()

        let news = try XCTUnwrap(found[label("News from the garden")], "\(found.keys.sorted())")
        XCTAssertTrue(news.accessibilityTraits.contains(.button) || news.accessibilityValue != nil,
                      "it is a switch")
        XCTAssertNotNil(found[label(Self.newsNote)], "with its one line")
        XCTAssertNil(found[label("Alert me when a joint seed is shared")], "the old label is gone")
        XCTAssertNil(found[label("A plant you both share goes to the web garden without your username.")],
                     "and so is the old note")
    }

    /// The stored names stay, so nobody's choice moves with the label.
    func testTheStoredNamesStay() {
        XCTAssertEqual(Sharing.invitationsKey, "sharing.invitations.v1")
        XCTAssertEqual(ZoneCExchange.enabledKey, "zonec.enabled.v1")
        XCTAssertTrue(Sharing.invitationsDefault, "the news is on until someone says otherwise")
    }

    /// **Without Autonaut there is no Zone C row**, and no word of it anywhere
    /// on the screen.
    func testTheZoneCRowIsHiddenWithoutAutonaut() async throws {
        try await host.show(settings(model()))
        // The look-up runs off the main actor; give it its time.
        try await Task.sleep(for: .milliseconds(500))
        let found = host.elements()

        XCTAssertNotNil(found[label("News from the garden")], "the other row is there")
        XCTAssertNil(found[label("Zone C")])
        XCTAssertNil(found[label(Self.zoneCNote)])
    }

    /// **With Autonaut the row is there, with its label and its one line, and
    /// off.** Nothing is stored until the person turns it on.
    func testTheZoneCRowIsThereAndOffByDefaultWithAutonaut() async throws {
        try autonautIsInstalled()
        try await host.show(settings(model()))

        let row = try await host.element(label("Zone C"))
        let zoneC = try XCTUnwrap(row, "\(host.elements().keys.sorted())")
        let found = host.elements()
        XCTAssertNotNil(found[label(Self.zoneCNote)], "with its one line")

        let news = try XCTUnwrap(found[label("News from the garden")])
        XCTAssertNotEqual(zoneC.accessibilityValue, news.accessibilityValue,
                          "News is on by default and Zone C is not")
        XCTAssertNil(UserDefaults.standard.object(forKey: ZoneCExchange.enabledKey), "nothing stored yet")
        XCTAssertFalse(ZoneCExchange.switchFromDefaults())
    }

    /// **Turning it on is the consent, and takes effect at once**: the marker
    /// Autonaut looks for appears without waiting for the next start, and goes
    /// again when it is turned off.
    func testTurningTheRowOnWritesTheKeyAndBringsTheMarker() async throws {
        try autonautIsInstalled()
        try await host.show(settings(model()))
        let row = try await host.element(label("Zone C"))
        let zoneC = try XCTUnwrap(row)
        XCTAssertFalse(exists(SuiteTransit.exchangeMarker))

        XCTAssertTrue(zoneC.accessibilityActivate())
        try await waitUntil { UserDefaults.standard.bool(forKey: ZoneCExchange.enabledKey) }
        try await waitUntil { self.exists(SuiteTransit.exchangeMarker) }

        let again = try XCTUnwrap(host.elements()[label("Zone C")])
        XCTAssertTrue(again.accessibilityActivate())
        try await waitUntil { !UserDefaults.standard.bool(forKey: ZoneCExchange.enabledKey) }
        try await waitUntil { !self.exists(SuiteTransit.exchangeMarker) }
    }

    private func waitUntil(
        _ condition: @escaping () -> Bool, file: StaticString = #filePath, line: UInt = #line
    ) async throws {
        let deadline = Date().addingTimeInterval(4)
        while !condition() && Date() < deadline { try await Task.sleep(for: .milliseconds(100)) }
        XCTAssertTrue(condition(), "not in time", file: file, line: line)
    }

    // MARK: The marker

    /// **The marker is there only while both switches are on**, reconciled at
    /// the start; the presence marker is Peace Garden's own and follows neither.
    func testTheExchangeMarkerExistsOnlyWhileBothSwitchesAreOn() async throws {
        let model = model()

        // Off by default for Zone C: the folders and the presence marker, no
        // exchange.
        await model.reconcileSuite()
        XCTAssertTrue(exists(SuiteTransit.myPresence), "Peace Garden says it is installed")
        XCTAssertTrue(exists(SuiteGroup.outFolder) && exists(SuiteGroup.inFolder))
        XCTAssertFalse(exists(SuiteTransit.exchangeMarker), "Zone C is off")

        UserDefaults.standard.set(true, forKey: ZoneCExchange.enabledKey)
        await model.reconcileSuite()
        XCTAssertTrue(exists(SuiteTransit.exchangeMarker), "both are on")

        UserDefaults.standard.set(false, forKey: Sharing.invitationsKey)
        await model.reconcileSuite()
        XCTAssertFalse(exists(SuiteTransit.exchangeMarker), "News is off")
        XCTAssertTrue(exists(SuiteTransit.myPresence), "the presence marker stays")

        UserDefaults.standard.set(true, forKey: Sharing.invitationsKey)
        await model.reconcileSuite()
        XCTAssertTrue(exists(SuiteTransit.exchangeMarker), "News on restores it")

        UserDefaults.standard.set(false, forKey: ZoneCExchange.enabledKey)
        await model.reconcileSuite()
        XCTAssertFalse(exists(SuiteTransit.exchangeMarker), "Zone C off removes it")
        XCTAssertTrue(exists(SuiteTransit.myPresence))
    }

    /// What the group did, from whichever thread the file coordinator used.
    private final class Changes: @unchecked Sendable {
        private let lock = NSLock()
        private var all: [SuiteGroup.Access] = []

        func add(_ access: SuiteGroup.Access) { lock.withLock { all.append(access) } }

        /// Everything that is not a look: a second launch with nothing to do
        /// makes none of these.
        var writes: [SuiteGroup.Access] {
            lock.withLock {
                all.filter {
                    switch $0 {
                    case .list, .exists, .inspect, .read: return false
                    default: return true
                    }
                }
            }
        }

        func clear() { lock.withLock { all = [] } }
    }

    /// Run twice it changes nothing: the second launch writes no file and moves
    /// no date.
    func testReconcilingTwiceChangesNothing() async throws {
        UserDefaults.standard.set(true, forKey: ZoneCExchange.enabledKey)
        let changes = Changes()
        let store = GardenStore(fileURL: gardenFile, writeOptions: [.atomic])
        let model = GardenModel(
            store: store,
            plots: PlotService(transport: stub, origin: URL(string: "https://example.invalid")!),
            suite: SuiteTransit(group: SuiteGroup(
                container: DirectoryContainer(url: root), audit: { changes.add($0) }
            ))
        )
        await model.reconcileSuite()
        XCTAssertFalse(changes.writes.isEmpty, "the first launch made the folders and markers")
        XCTAssertTrue(exists(SuiteTransit.exchangeMarker))

        changes.clear()
        await model.reconcileSuite()
        XCTAssertEqual(changes.writes, [])
        XCTAssertTrue(exists(SuiteTransit.exchangeMarker))
    }

    /// A phone without the suite's folder has nothing to bring in line, and
    /// says nothing about it.
    func testWithoutTheSuiteFolderReconcilingIsQuiet() async {
        struct None: SuiteContainer { func rootURL() -> URL? { nil } }
        let store = GardenStore(fileURL: gardenFile, writeOptions: [.atomic])
        let model = GardenModel(
            store: store,
            plots: PlotService(transport: stub, origin: URL(string: "https://example.invalid")!),
            suite: SuiteTransit(group: SuiteGroup(container: None()))
        )
        UserDefaults.standard.set(true, forKey: ZoneCExchange.enabledKey)
        await model.reconcileSuite()
        XCTAssertEqual(names(in: ""), [], "nothing was made")
    }

    // MARK: The request

    private func pendingRequests() -> [Int] {
        stub.asked.enumerated().filter { $0.element == "/api/walk/pending" }.map(\.offset)
    }

    /// **News off sends no request, and removes the marker; on sends one and
    /// restores it.**
    func testNewsOffSendsNothingAndRemovesTheMarkerAndOnRestoresBoth() async throws {
        UserDefaults.standard.set(true, forKey: ZoneCExchange.enabledKey)
        UserDefaults.standard.set(false, forKey: Sharing.invitationsKey)
        let off = model()
        await off.reconcileSuite()
        await off.catchUpOnTheAsking()
        XCTAssertEqual(stub.asked, [], "News off: no request at all")
        XCTAssertFalse(exists(SuiteTransit.exchangeMarker))

        UserDefaults.standard.set(true, forKey: Sharing.invitationsKey)
        let on = model()
        await on.reconcileSuite()
        await on.catchUpOnTheAsking()
        XCTAssertEqual(pendingRequests().count, 1, "News on: the request goes, once")
        XCTAssertTrue(exists(SuiteTransit.exchangeMarker))
    }

    /// **Zone C off keeps the padded request and sends padding only.** A seed
    /// waiting in `out/` is not opened, so it is still there, and its bytes are
    /// nowhere in the request. The marker is gone.
    func testZoneCOffStillAsksButSendsPaddingOnly() async throws {
        try put(#"{"v":1,"r":"\#(r)"}"#, in: SuiteGroup.outFolder, named: "11111111111111111111111111111111")
        let model = model()
        await model.reconcileSuite()
        await model.catchUpOnTheAsking()

        XCTAssertEqual(pendingRequests().count, 1, "the padded request still goes")
        let body = try XCTUnwrap(JSONSerialization.jsonObject(
            with: Data(try XCTUnwrap(stub.bodies.first).utf8)
        ) as? [String: Any])
        let aloft = try XCTUnwrap(body["aloft"] as? String)
        let back = try XCTUnwrap(body["back"] as? String)
        XCTAssertEqual(aloft.count, 128)
        XCTAssertEqual(back.count, 208)
        XCTAssertFalse(aloft.hasPrefix(r), "the seed is not in the slot")
        XCTAssertEqual(names(in: SuiteGroup.outFolder), ["11111111111111111111111111111111"],
                       "and nothing was taken from out/")
        XCTAssertFalse(exists(SuiteTransit.exchangeMarker))
    }

    // MARK: Resetting

    private func zoneCStore() -> ZoneCStore {
        ZoneCStore(
            fileURL: gardenFile.deletingLastPathComponent().appendingPathComponent(ZoneCStore.fileName),
            writeOptions: [.atomic]
        )
    }

    private func seed(_ n: UInt8) -> SeedID {
        SeedID(bytes: Data(repeating: n, count: SeedID.byteCount))!
    }

    /// **Reset erases Zone C and leaves both switches as they were.** The own
    /// seed, the records and the plants go with `zonec.json`; every file in
    /// `out/` and `in/` goes, well-formed or not; the folders and the markers
    /// stay.
    func testResetEverythingErasesZoneCAndLeavesTheSwitches() async throws {
        UserDefaults.standard.set(true, forKey: ZoneCExchange.enabledKey)
        UserDefaults.standard.set(false, forKey: Sharing.invitationsKey)

        let model = model()
        model.mintIdentity()
        let zoneC = zoneCStore()
        _ = try zoneC.ownSeed()
        try zoneC.update { state in
            state.addSentSeed(ZoneCSentSeed(r: Data(repeating: 7, count: 16),
                                            privateKey: Data(repeating: 9, count: 32))!)
            state.addPlant(ZoneCPlant(childSeed: seed(1), parentA: seed(2), parentB: seed(3),
                                      encounterID: Data(repeating: 4, count: 32), side: .finder))
            // A record that has ended, which leaves its mark behind.
            state.addSentSeed(ZoneCSentSeed(r: Data(repeating: 8, count: 16),
                                            privateKey: Data(repeating: 9, count: 32), launchesLeft: 1)!)
            state.countLaunch()
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: zoneC.fileURL.path))
        XCTAssertEqual(try zoneC.load().plants.count, 1)
        XCTAssertEqual(try zoneC.load().retiredMarks.count, 1)

        try autonautIsInstalled()
        try put(#"{"v":1,"r":"\#(r)"}"#, in: SuiteGroup.outFolder, named: "a")
        try put("not a seed", in: SuiteGroup.outFolder, named: "b")
        try put(#"{"v":1,"seed":"\#(String(repeating: "ab", count: 32))"}"#,
                in: SuiteGroup.inFolder, named: "c")
        await model.reconcileSuite()
        let markerBefore = exists(SuiteTransit.exchangeMarker)

        model.resetEverything()

        XCTAssertNil(model.identity, "the garden is empty")
        XCTAssertFalse(FileManager.default.fileExists(atPath: zoneC.fileURL.path), "zonec.json is gone")
        XCTAssertEqual(try zoneC.load(), ZoneCState(), "and Zone C reads as never used")
        XCTAssertEqual(try zoneC.load().retiredMarks, [], "with no mark of a seed it sent")
        XCTAssertEqual(names(in: SuiteGroup.outFolder), [])
        XCTAssertEqual(names(in: SuiteGroup.inFolder), [])
        XCTAssertTrue(exists(SuiteGroup.outFolder) && exists(SuiteGroup.inFolder), "the folders stay")
        XCTAssertTrue(exists(SuiteTransit.myPresence) && exists(SuiteTransit.autonautPresence),
                      "so do the presence markers")
        XCTAssertEqual(exists(SuiteTransit.exchangeMarker), markerBefore)

        XCTAssertEqual(UserDefaults.standard.object(forKey: ZoneCExchange.enabledKey) as? Bool, true,
                       "Zone C is as it was")
        XCTAssertEqual(UserDefaults.standard.object(forKey: Sharing.invitationsKey) as? Bool, false,
                       "and so is News")
    }

    /// A reset with nothing of Zone C's to erase, and no suite folder, is just
    /// a reset.
    func testResetEverythingWithNothingOfZoneCIsQuiet() async throws {
        let model = model()
        model.mintIdentity()
        model.resetEverything()
        XCTAssertNil(model.identity)
        XCTAssertNil(UserDefaults.standard.object(forKey: ZoneCExchange.enabledKey))
    }
}
