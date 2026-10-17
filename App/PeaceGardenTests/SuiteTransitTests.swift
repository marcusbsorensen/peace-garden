import XCTest
@testable import PeaceGarden

/// Peace Garden's half of the hand-off with Autonaut, run against a temporary
/// folder in place of the suite's App Group.
///
/// The folder belongs to the whole suite and an App Group cannot enforce which
/// part of it an app keeps to, so what is worth testing is the discipline:
///
/// - **Strictness.** A file in `out/` is taken only if it is exactly the agreed
///   JSON; anything else is deleted, and anything that is not even a small plain
///   file is deleted without being opened.
/// - **Staging and dates.** Every file arrives by way of `tmp/` with its dates
///   already fixed, and every file and folder reads back as 1 January 2001.
/// - **Staying in its lane.** The code writes only its own files and reads only
///   what it should. `SuiteGroup` reports each thing it does (`Access`), and a
///   test reads that record rather than taking it on trust.
///
/// The test acts as Autonaut by writing straight into the folder.
final class SuiteTransitTests: XCTestCase {

    // MARK: A folder that never leaves the room

    /// What the code did, in order. Written from whichever thread the file
    /// coordinator happens to use.
    private final class Record: @unchecked Sendable {
        private let lock = NSLock()
        private var all: [SuiteGroup.Access] = []

        func add(_ access: SuiteGroup.Access) {
            lock.lock(); defer { lock.unlock() }
            all.append(access)
        }

        var events: [SuiteGroup.Access] {
            lock.lock(); defer { lock.unlock() }
            return all
        }

        func clear() {
            lock.lock(); defer { lock.unlock() }
            all = []
        }
    }

    private struct NoContainer: SuiteContainer {
        func rootURL() -> URL? { nil }
    }

    private var root = URL(fileURLWithPath: "/")
    private var record = Record()

    /// 16 bytes, as Autonaut draws `r`.
    private let r = "00112233445566778899aabbccddeeff"
    /// 32 bytes, as Zone C finds a space seed.
    private let seed = Data((0..<32).map { UInt8($0 &* 7 &+ 1) })

    override func setUp() {
        super.setUp()
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("suite-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        record = Record()
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: root)
        super.tearDown()
    }

    private func transit() -> SuiteTransit {
        let record = record
        return SuiteTransit(group: SuiteGroup(
            container: DirectoryContainer(url: root),
            audit: { record.add($0) }
        ))
    }

    private func path(_ relative: String) -> URL {
        root.appendingPathComponent(relative)
    }

    private func exists(_ relative: String) -> Bool {
        (try? FileManager.default.attributesOfItem(atPath: path(relative).path)) != nil
    }

    private func names(_ relative: String) -> [String] {
        ((try? FileManager.default.contentsOfDirectory(atPath: path(relative).path)) ?? []).sorted()
    }

    private func contents(_ relative: String) -> Data? {
        try? Data(contentsOf: path(relative))
    }

    // MARK: The other app

    /// Autonaut's marker, dated as the Hub's convention asks.
    private func autonautIsInstalled() {
        let folder = path("Presence/v1")
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let file = folder.appendingPathComponent("autonaut")
        FileManager.default.createFile(atPath: file.path, contents: Data())
        setDates(file, to: SuiteGroup.fixedDate)
    }

    /// A file where Autonaut leaves a sent seed. Returns its name.
    @discardableResult
    private func autonautSends(_ text: String, named name: String = SuiteGroup.randomName()) -> String {
        let folder = path("Seeds/v1/out")
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try? Data(text.utf8).write(to: folder.appendingPathComponent(name))
        return name
    }

    private func goodFile(_ hex: String? = nil) -> String {
        #"{"v":1,"r":"\#(hex ?? r)"}"#
    }

    private func autonautTakes(_ name: String) {
        try? FileManager.default.removeItem(at: path("Seeds/v1/in/\(name)"))
    }

    private func setDates(_ url: URL, to date: Date) {
        try? FileManager.default.setAttributes(
            [.creationDate: date, .modificationDate: date], ofItemAtPath: url.path
        )
    }

    // MARK: What the file system says

    private struct Stamps: Equatable {
        var inode: UInt64
        var born: Date
        var modified: Date
        var changed: Date
        var accessed: Date
    }

    /// The raw `stat`, rather than Foundation's reading of it, because the
    /// change time is only there.
    private func stamps(_ relative: String) -> Stamps? {
        var info = stat()
        guard lstat(path(relative).path, &info) == 0 else { return nil }
        func date(_ time: timespec) -> Date {
            Date(timeIntervalSince1970: Double(time.tv_sec) + Double(time.tv_nsec) / 1_000_000_000)
        }
        return Stamps(
            inode: UInt64(info.st_ino),
            born: date(info.st_birthtimespec),
            modified: date(info.st_mtimespec),
            changed: date(info.st_ctimespec),
            accessed: date(info.st_atimespec)
        )
    }

    /// Everything under the root, files and folders, as relative paths.
    private func everything() -> [String] {
        let enumerator = FileManager.default.enumerator(atPath: root.path)
        var found: [String] = []
        while let item = enumerator?.nextObject() as? String {
            found.append(item)
        }
        return found.sorted()
    }

    private func isChange(_ access: SuiteGroup.Access) -> Bool {
        switch access {
        case .createFolder, .write, .setBackupFlag, .setDates, .move, .remove: return true
        case .list, .exists, .inspect, .read: return false
        }
    }

    // MARK: Taking what Autonaut sent

    func testAWellFormedSeedIsTakenAndItsFileStaysUntilTheServerHasAnswered() throws {
        let transit = transit()
        try transit.prepare()
        let name = autonautSends(goodFile())

        let waiting = transit.seedsWaitingToLeave()

        XCTAssertEqual(waiting.count, 1)
        XCTAssertEqual(waiting.first?.name, name)
        XCTAssertEqual(waiting.first?.hex, r)
        XCTAssertEqual(waiting.first?.r.count, 16)
        XCTAssertTrue(exists("Seeds/v1/out/\(name)"), "a failed request must lose nothing")

        try transit.finish(try XCTUnwrap(waiting.first))
        XCTAssertFalse(exists("Seeds/v1/out/\(name)"))
        XCTAssertEqual(transit.seedsWaitingToLeave(), [])
    }

    /// The agreed format, and the ways it can be wrong. Each is deleted, and
    /// none is taken. The version-2 case is the one a later Autonaut will send;
    /// it is deleted too, because this build cannot read it.
    func testAnythingButTheExactFormatIsDeleted() throws {
        let transit = transit()
        try transit.prepare()
        let cases: [(String, String)] = [
            ("an extra key", #"{"v":1,"r":"\#(r)","x":1}"#),
            ("uppercase hex", goodFile(r.uppercased())),
            ("one character short", goodFile(String(r.dropLast()))),
            ("one character long", goodFile(r + "0")),
            ("a letter that is not hex", goodFile("g" + String(r.dropFirst()))),
            ("version 2", #"{"v":2,"r":"\#(r)"}"#),
            ("version 0", #"{"v":0,"r":"\#(r)"}"#),
            ("version as text", #"{"v":"1","r":"\#(r)"}"#),
            ("version as true", #"{"v":true,"r":"\#(r)"}"#),
            ("version 1.5", #"{"v":1.5,"r":"\#(r)"}"#),
            ("no r", #"{"v":1}"#),
            ("no v", #"{"r":"\#(r)"}"#),
            ("r as a number", #"{"v":1,"r":12345}"#),
            ("r as null", #"{"v":1,"r":null}"#),
            ("the seed key in place of r", #"{"v":1,"seed":"\#(r + r)"}"#),
            ("an array", #"[{"v":1,"r":"\#(r)"}]"#),
            ("null", "null"),
            ("an empty file", ""),
            ("text after the object", goodFile() + "x"),
            ("not JSON", "peacegarden"),
        ]
        for (label, text) in cases {
            let name = autonautSends(text)
            XCTAssertEqual(transit.seedsWaitingToLeave(), [], label)
            XCTAssertFalse(exists("Seeds/v1/out/\(name)"), "\(label) was not deleted")
        }
    }

    /// A good file among bad ones is the only one taken, and the bad ones go.
    func testOneGoodSeedAmongBadOnesIsTheOnlyOneKept() throws {
        let transit = transit()
        try transit.prepare()
        autonautSends("{}")
        let good = autonautSends(goodFile())
        autonautSends(#"{"v":1,"r":"short"}"#)

        XCTAssertEqual(transit.seedsWaitingToLeave().map(\.name), [good])
        XCTAssertEqual(names("Seeds/v1/out"), [good])
    }

    /// The reading is of JSON, so the keys may come either way round and there
    /// may be spaces. What is exact is the set of keys, the version and the 32
    /// lowercase hex characters. Without this a harmless difference in how
    /// Autonaut writes would delete every seed without a word.
    func testKeyOrderAndSpacesDoNotMatter() throws {
        let transit = transit()
        try transit.prepare()
        let first = autonautSends(#"{"r":"\#(r)","v":1}"#)
        let second = autonautSends("{ \"v\" : 1,\n  \"r\" : \"\(r)\" }\n")

        XCTAssertEqual(Set(transit.seedsWaitingToLeave().map(\.name)), [first, second])
    }

    /// "Deleted unread" is meant literally for what is not a small plain file: a
    /// large one, a folder, and a link that points at a good seed somewhere
    /// else. None is opened, and a link is removed rather than followed.
    func testWhatIsNotASmallPlainFileIsDeletedWithoutBeingOpened() throws {
        let transit = transit()
        try transit.prepare()
        let large = autonautSends(String(repeating: "a", count: 4_096))
        let folder = SuiteGroup.randomName()
        try FileManager.default.createDirectory(
            at: path("Seeds/v1/out/\(folder)"), withIntermediateDirectories: true
        )
        try Data(goodFile().utf8).write(to: path("Seeds/v1/out/\(folder)/inside"))
        let elsewhere = root.appendingPathComponent("elsewhere")
        try Data(goodFile().utf8).write(to: elsewhere)
        let link = SuiteGroup.randomName()
        try FileManager.default.createSymbolicLink(
            at: path("Seeds/v1/out/\(link)"), withDestinationURL: elsewhere
        )
        record.clear()

        XCTAssertEqual(transit.seedsWaitingToLeave(), [])

        XCTAssertEqual(names("Seeds/v1/out"), [])
        XCTAssertTrue(FileManager.default.fileExists(atPath: elsewhere.path), "the link's target is not touched")
        XCTAssertFalse(record.events.contains {
            if case .read = $0 { return true } else { return false }
        }, "none of the three was opened: \(large) \(folder) \(link)")
    }

    // MARK: Writing what Peace Garden found

    func testAFoundSeedIsWrittenToInAsExactlyTheAgreedFile() throws {
        let transit = transit()
        try transit.prepare()

        XCTAssertEqual(try transit.deliver(foundSeed: seed), .delivered)

        let files = names("Seeds/v1/in")
        XCTAssertEqual(files.count, 1)
        let name = try XCTUnwrap(files.first)
        XCTAssertNotNil(SuiteHex.decode(name, byteCount: 16), "a random name: 32 lowercase hex, never a count or a time")
        let expected = #"{"v":1,"seed":"\#(SuiteHex.encode(seed))"}"#
        XCTAssertEqual(contents("Seeds/v1/in/\(name)"), Data(expected.utf8))
        XCTAssertEqual(names("Seeds/v1/tmp"), [], "nothing is left in staging")
    }

    func testTwoFilesGetTwoRandomNames() throws {
        let transit = transit()
        try transit.prepare()
        _ = try transit.deliver(foundSeed: seed)
        _ = try transit.deliver(foundSeed: seed)

        XCTAssertEqual(Set(names("Seeds/v1/in")).count, 2)
    }

    /// Three wait, and no more. Autonaut takes them each time it opens; if it
    /// has been deleted nobody does, and finding stops here.
    func testNoMoreThanThreeFilesWaitInIn() throws {
        let transit = transit()
        try transit.prepare()

        for _ in 0..<3 { XCTAssertEqual(try transit.deliver(foundSeed: seed), .delivered) }
        record.clear()
        XCTAssertEqual(try transit.deliver(foundSeed: seed), .full)
        XCTAssertEqual(try transit.deliver(foundSeed: seed), .full)

        XCTAssertEqual(names("Seeds/v1/in").count, 3)
        XCTAssertEqual(transit.seedsWaitingForAutonaut(), 3)
        XCTAssertFalse(record.events.contains(where: isChange), "a refusal writes nothing")

        autonautTakes(try XCTUnwrap(names("Seeds/v1/in").first))
        XCTAssertEqual(transit.seedsWaitingForAutonaut(), 2)
        XCTAssertEqual(try transit.deliver(foundSeed: seed), .delivered)
        XCTAssertEqual(names("Seeds/v1/in").count, 3)
    }

    func testOnlyAThirtyTwoByteSeedIsWritten() throws {
        let transit = transit()
        try transit.prepare()

        XCTAssertThrowsError(try transit.deliver(foundSeed: Data(count: 16))) {
            XCTAssertEqual($0 as? SuiteError, .notASeed)
        }
        XCTAssertThrowsError(try transit.deliver(foundSeed: Data(count: 33)))
        XCTAssertEqual(names("Seeds/v1/in"), [])
    }

    // MARK: Staging

    /// A file is written whole in `tmp/`, flagged and dated there, and only then
    /// renamed. Nothing is ever created in `in/` directly, so a reader of `in/`
    /// never meets a partial file or one with a real date.
    func testAFileIsStagedDatedAndFlaggedBeforeItAppears() throws {
        let transit = transit()
        try transit.prepare()
        record.clear()

        _ = try transit.deliver(foundSeed: seed)
        let events = record.events

        let written = events.compactMap { event -> String? in
            if case .write(let path) = event { return path } else { return nil }
        }
        XCTAssertEqual(written.count, 1)
        let staged = try XCTUnwrap(written.first)
        XCTAssertTrue(staged.hasPrefix("Seeds/v1/tmp/peacegarden-"))
        XCTAssertNotNil(SuiteHex.decode(String(staged.dropFirst("Seeds/v1/tmp/peacegarden-".count)), byteCount: 16))

        let write = try XCTUnwrap(events.firstIndex(of: .write(staged)))
        let flag = try XCTUnwrap(events.firstIndex(of: .setBackupFlag(staged)))
        let dates = try XCTUnwrap(events.firstIndex(of: .setDates(staged)))
        let move = try XCTUnwrap(events.firstIndex {
            if case .move(let from, let to) = $0 { return from == staged && to.hasPrefix("Seeds/v1/in/") }
            return false
        })
        XCTAssertLessThan(write, flag)
        XCTAssertLessThan(flag, dates)
        XCTAssertLessThan(dates, move)
    }

    func testLeftoversOfItsOwnAreClearedAndAnotherAppsAreLeftAlone() throws {
        try FileManager.default.createDirectory(at: path("Seeds/v1/tmp"), withIntermediateDirectories: true)
        try Data("half".utf8).write(to: path("Seeds/v1/tmp/peacegarden-0123"))
        try Data("half".utf8).write(to: path("Seeds/v1/tmp/peacegarden-4567"))
        try Data("theirs".utf8).write(to: path("Seeds/v1/tmp/autonaut-89ab"))
        try Data("neither".utf8).write(to: path("Seeds/v1/tmp/other"))
        let sentinel = Date(timeIntervalSinceReferenceDate: 400_000_000)
        setDates(path("Seeds/v1/tmp/autonaut-89ab"), to: sentinel)
        let before = stamps("Seeds/v1/tmp/autonaut-89ab")
        let transit = transit()

        try transit.prepare()

        XCTAssertEqual(names("Seeds/v1/tmp"), ["autonaut-89ab", "other"])
        XCTAssertEqual(contents("Seeds/v1/tmp/autonaut-89ab"), Data("theirs".utf8))
        XCTAssertEqual(stamps("Seeds/v1/tmp/autonaut-89ab"), before, "not so much as a date moved")
        XCTAssertEqual(
            try FileManager.default.attributesOfItem(atPath: path("Seeds/v1/tmp/autonaut-89ab").path)[.modificationDate] as? Date,
            sentinel
        )
        let touched = record.events.compactMap { event -> String? in
            switch event {
            case .read(let p), .inspect(let p), .remove(let p), .write(let p), .setDates(let p): return p
            default: return nil
            }
        }
        XCTAssertFalse(touched.contains { $0.hasPrefix("Seeds/v1/tmp/") && !$0.hasPrefix("Seeds/v1/tmp/peacegarden-") },
                       "tmp/ is listed for its own names and nothing in it of another app's is opened")
        XCTAssertFalse(record.events.contains {
            if case .read(let p) = $0 { return p.hasPrefix("Seeds/v1/tmp") } else { return false }
        })
    }

    // MARK: Presence and the exchange marker

    func testItsPresenceMarkerIsEmptyAndWrittenOnceOnly() throws {
        let transit = transit()
        try transit.prepare()

        XCTAssertEqual(contents("Presence/v1/peacegarden"), Data())

        // A date a rewrite would put back to 2001, and an inode a rewrite would
        // change. The file system's own change time says if it was touched.
        setDates(path("Presence/v1/peacegarden"), to: Date(timeIntervalSinceReferenceDate: 100_000_000))
        let before = try XCTUnwrap(stamps("Presence/v1/peacegarden"))
        record.clear()

        try transit.prepare()

        let after = try XCTUnwrap(stamps("Presence/v1/peacegarden"))
        XCTAssertEqual(after, before, "a second launch leaves the presence file alone")
        XCTAssertEqual(after.modified, Date(timeIntervalSinceReferenceDate: 100_000_000))
        XCTAssertFalse(record.events.contains(where: isChange), "and writes nothing else either: \(record.events)")
    }

    func testAutonautIsPresentOnlyWhileItsMarkerIs() throws {
        let transit = transit()
        try transit.prepare()
        XCTAssertFalse(transit.autonautIsPresent)

        autonautIsInstalled()
        XCTAssertTrue(transit.autonautIsPresent)
        XCTAssertEqual(contents("Presence/v1/autonaut"), Data(), "its marker is looked for, never opened")
        try transit.prepare()
        XCTAssertTrue(exists("Presence/v1/autonaut"), "and never touched")
    }

    func testTheExchangeMarkerFollowsTheSwitch() throws {
        let transit = transit()
        try transit.prepare()
        XCTAssertFalse(transit.exchangeMarkerIsPresent)

        try transit.setExchangeMarker(present: true)
        XCTAssertTrue(transit.exchangeMarkerIsPresent)
        XCTAssertEqual(contents("Seeds/v1/exchange"), Data())
        XCTAssertTrue(SuiteGroup().datesHold(atPath: path("Seeds/v1/exchange").path))

        record.clear()
        try transit.setExchangeMarker(present: true)
        XCTAssertFalse(record.events.contains(where: isChange), "on again changes nothing")

        try transit.setExchangeMarker(present: false)
        XCTAssertFalse(transit.exchangeMarkerIsPresent)
        XCTAssertFalse(exists("Seeds/v1/exchange"))
        XCTAssertTrue(exists("Presence/v1/peacegarden"), "the presence marker does not follow the switch")

        record.clear()
        try transit.setExchangeMarker(present: false)
        XCTAssertFalse(record.events.contains(where: isChange), "off again changes nothing")
    }

    // MARK: Dates and backups

    /// One session of everything: Autonaut's marker, a launch, the switch on, a
    /// sent seed taken and answered, and two found seeds delivered.
    private func aSession(_ transit: SuiteTransit) throws {
        autonautIsInstalled()
        try transit.prepare()
        try transit.setExchangeMarker(present: true)
        autonautSends(goodFile())
        let seeds = transit.seedsWaitingToLeave()
        try transit.finish(try XCTUnwrap(seeds.first))
        _ = try transit.deliver(foundSeed: seed)
        _ = try transit.deliver(foundSeed: seed)
    }

    func testEveryFileAndFolderReadsBackAsTheFirstOfJanuary2001() throws {
        let transit = transit()
        try aSession(transit)

        let all = everything()
        XCTAssertGreaterThanOrEqual(all.count, 12, "folders, two markers, the exchange marker and two seeds: \(all)")
        let group = SuiteGroup()
        for item in all {
            XCTAssertTrue(group.datesHold(atPath: path(item).path), "\(item) does not read back as 1 January 2001")
            let seen = try XCTUnwrap(stamps(item), item)
            XCTAssertEqual(seen.born.timeIntervalSinceReferenceDate, 0, accuracy: 1, "\(item) birth")
            XCTAssertEqual(seen.modified.timeIntervalSinceReferenceDate, 0, accuracy: 1, "\(item) modified")
        }
    }

    /// R6 in the build plan: the change time may not be settable. This test does
    /// not assume either answer. It reads `st_ctime` on every file and folder
    /// the code made and writes down what it finds, in the log and as an
    /// attachment, so the Hub and Autonaut can be told.
    func testItRecordsWhatTheChangeTimeShows() throws {
        let transit = transit()
        try aSession(transit)

        let now = Date()
        var lines = ["R6: what st_ctime shows after one session (written \(now))"]
        var fixed = 0
        let all = everything()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        for item in all {
            let seen = try XCTUnwrap(stamps(item), item)
            let isFixed = abs(seen.changed.timeIntervalSinceReferenceDate) < 1
            if isFixed { fixed += 1 }
            lines.append("\(item) | born \(formatter.string(from: seen.born)) | mtime \(formatter.string(from: seen.modified)) | ctime \(formatter.string(from: seen.changed)) | atime \(formatter.string(from: seen.accessed))")
        }
        lines.append("RESULT: st_ctime is 1 January 2001 on \(fixed) of \(all.count) files and folders.")
        let latest = all.compactMap { stamps($0)?.changed }.max() ?? now
        lines.append("RESULT: the latest st_ctime is \(Int(now.timeIntervalSince(latest) * 1000)) ms before the report was written.")
        let report = lines.joined(separator: "\n")
        print(report)
        let attachment = XCTAttachment(string: report)
        attachment.name = "R6-st_ctime"
        attachment.lifetime = .keepAlways
        add(attachment)

        // Born and modified are the dates the design promises. The change time is
        // the file system's own, and this is the only place it is looked at.
        XCTAssertGreaterThan(all.count, 0)
        for item in all {
            XCTAssertEqual(stamps(item)?.modified.timeIntervalSinceReferenceDate ?? -1, 0, accuracy: 1, item)
        }
    }

    /// Taking a seed out of `out/` changes that folder's modified date, and the
    /// code puts it back.
    func testAFolderIsDatedAgainAfterAFileLeavesIt() throws {
        let transit = transit()
        try transit.prepare()
        let name = autonautSends(goodFile())
        // Autonaut's own write left a real date on the folder, as any write does.
        XCTAssertFalse(SuiteGroup().datesHold(atPath: path("Seeds/v1/out").path))

        try transit.finish(SentSeed(name: name, r: Data()))

        XCTAssertTrue(SuiteGroup().datesHold(atPath: path("Seeds/v1/out").path))
        XCTAssertTrue(SuiteGroup().datesHold(atPath: path("Seeds/v1/in").path))
    }

    func testTheSeedsFolderAndEveryFileInItAreLeftOutOfBackups() throws {
        let transit = transit()
        try aSession(transit)

        XCTAssertTrue(SuiteGroup.isExcluded(path("Seeds/v1")), "Seeds/v1")
        for name in names("Seeds/v1/in") {
            XCTAssertTrue(SuiteGroup.isExcluded(path("Seeds/v1/in/\(name)")), "in/\(name)")
        }
        XCTAssertTrue(SuiteGroup.isExcluded(path("Seeds/v1/exchange")), "exchange")
        XCTAssertTrue(SuiteGroup.isExcluded(path("Presence/v1/peacegarden")), "presence")
    }

    // MARK: Its lane

    /// The whole session again, read from the record of what the code did. It
    /// writes only its own files, reads the contents of nothing but `out/`, looks
    /// for Autonaut's marker without opening it, and lists `tmp/` for names alone.
    func testItWritesOnlyItsOwnFilesAndReadsOnlyWhatItShould() throws {
        let transit = transit()
        try Data("theirs".utf8).write(to: path("stray"))
        try aSession(transit)
        // A file of Autonaut's own in `tmp/`, which the code must not go near.
        try Data("theirs".utf8).write(to: path("Seeds/v1/tmp/autonaut-1"))
        try transit.prepare()
        let autonautMarker = stamps("Presence/v1/autonaut")
        let theirs = stamps("Seeds/v1/tmp/autonaut-1")
        try transit.prepare()
        XCTAssertEqual(stamps("Presence/v1/autonaut"), autonautMarker)
        XCTAssertEqual(stamps("Seeds/v1/tmp/autonaut-1"), theirs)

        let folders = Set(SuiteGroup.datedFolders)
        let staging = "Seeds/v1/tmp/peacegarden-"
        var counted = 0
        for event in record.events {
            counted += 1
            switch event {
            case .read(let p):
                XCTAssertTrue(p.hasPrefix("Seeds/v1/out/"), "read \(p)")
            case .inspect(let p):
                XCTAssertTrue(p.hasPrefix("Seeds/v1/out/"), "inspected \(p)")
            case .exists(let p):
                XCTAssertTrue(
                    [SuiteTransit.autonautPresence, SuiteTransit.myPresence, SuiteTransit.exchangeMarker].contains(p),
                    "looked for \(p)"
                )
            case .list(let p):
                XCTAssertTrue([SuiteGroup.outFolder, SuiteGroup.inFolder, SuiteGroup.tmpFolder].contains(p), "listed \(p)")
            case .createFolder(let p):
                XCTAssertTrue(folders.contains(p), "made folder \(p)")
            case .write(let p):
                XCTAssertTrue(p.hasPrefix(staging), "wrote \(p)")
            case .setBackupFlag(let p):
                XCTAssertTrue(p.hasPrefix(staging) || p == SuiteGroup.seedsFolder, "flagged \(p)")
            case .setDates(let p):
                XCTAssertTrue(p.hasPrefix(staging) || folders.contains(p), "dated \(p)")
            case .move(let from, let to):
                XCTAssertTrue(from.hasPrefix(staging), "moved \(from)")
                XCTAssertTrue(
                    to == SuiteTransit.myPresence || to == SuiteTransit.exchangeMarker || to.hasPrefix("Seeds/v1/in/"),
                    "moved to \(to)"
                )
            case .remove(let p):
                XCTAssertTrue(
                    p.hasPrefix("Seeds/v1/out/") || p.hasPrefix(staging) || p == SuiteTransit.exchangeMarker,
                    "deleted \(p)"
                )
            }
        }
        XCTAssertGreaterThan(counted, 20, "the record has the session in it")
        XCTAssertEqual(contents("stray"), Data("theirs".utf8))
    }

    // MARK: Coordination

    /// A file presenter in the same process is told when a coordinated write
    /// touches what it is presenting; a plain delete would tell it nothing. So
    /// this is the proof that the code coordinates, not a claim that it does.
    private final class Watcher: NSObject, NSFilePresenter, @unchecked Sendable {
        let presentedItemURL: URL?
        let presentedItemOperationQueue = OperationQueue()
        private let lock = NSLock()
        private var told: [String] = []

        init(watching url: URL) {
            presentedItemURL = url
            super.init()
        }

        var heard: [String] {
            lock.lock(); defer { lock.unlock() }
            return told
        }

        private func hear(_ what: String) {
            lock.lock(); defer { lock.unlock() }
            told.append(what)
        }

        func accommodatePresentedSubitemDeletion(at url: URL, completionHandler: @escaping @Sendable (Error?) -> Void) {
            hear("delete \(url.lastPathComponent)")
            completionHandler(nil)
        }

        func presentedSubitemDidAppear(at url: URL) { hear("appear \(url.lastPathComponent)") }
        func presentedSubitemDidChange(at url: URL) { hear("change \(url.lastPathComponent)") }
    }

    func testDeletingASentSeedIsCoordinated() throws {
        let transit = transit()
        try transit.prepare()
        autonautSends(goodFile())
        let sent = try XCTUnwrap(transit.seedsWaitingToLeave().first)
        let watcher = Watcher(watching: path("Seeds/v1/out"))
        NSFileCoordinator.addFilePresenter(watcher)
        defer { NSFileCoordinator.removeFilePresenter(watcher) }

        try transit.finish(sent)

        waitUntil { watcher.heard.contains { $0.hasSuffix(sent.name) } }
        XCTAssertTrue(
            watcher.heard.contains { $0.hasSuffix(sent.name) },
            "the presenter of out/ heard of the deletion: \(watcher.heard)"
        )
    }

    /// The control for the two tests around it: a plain write, with no
    /// coordination, tells a presenter nothing. Without this they would pass
    /// for any code at all.
    func testAPlainWriteIsNotHeardByAPresenter() throws {
        let transit = transit()
        try transit.prepare()
        let watcher = Watcher(watching: path("Seeds/v1/in"))
        NSFileCoordinator.addFilePresenter(watcher)
        defer { NSFileCoordinator.removeFilePresenter(watcher) }

        try Data("x".utf8).write(to: path("Seeds/v1/in/plain"))
        try FileManager.default.removeItem(at: path("Seeds/v1/in/plain"))

        waitUntil(seconds: 1) { !watcher.heard.isEmpty }
        XCTAssertEqual(watcher.heard, [])
    }

    private func waitUntil(seconds: TimeInterval = 5, _ done: () -> Bool) {
        let deadline = Date().addingTimeInterval(seconds)
        while !done() && Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
    }

    func testPlacingAFileIsCoordinated() throws {
        let transit = transit()
        try transit.prepare()
        let watcher = Watcher(watching: path("Seeds/v1/in"))
        NSFileCoordinator.addFilePresenter(watcher)
        defer { NSFileCoordinator.removeFilePresenter(watcher) }

        _ = try transit.deliver(foundSeed: seed)

        let arrived = names("Seeds/v1/in")
        waitUntil { !watcher.heard.isEmpty }
        XCTAssertTrue(
            watcher.heard.contains { $0 == "appear \(arrived[0])" || $0 == "change \(arrived[0])" },
            "the presenter of in/ heard of the file: \(watcher.heard)"
        )
    }

    // MARK: No folder

    func testWithoutTheFolderNothingHappensAndNothingBreaks() throws {
        let transit = SuiteTransit(group: SuiteGroup(container: NoContainer()))

        XCTAssertFalse(transit.isAvailable)
        XCTAssertThrowsError(try transit.prepare()) { XCTAssertEqual($0 as? SuiteError, .noContainer) }
        XCTAssertThrowsError(try transit.deliver(foundSeed: seed)) { XCTAssertEqual($0 as? SuiteError, .noContainer) }
        XCTAssertThrowsError(try transit.setExchangeMarker(present: true))
        XCTAssertEqual(transit.seedsWaitingToLeave(), [])
        XCTAssertEqual(transit.seedsWaitingForAutonaut(), 0)
        XCTAssertFalse(transit.autonautIsPresent)
        XCTAssertFalse(transit.exchangeMarkerIsPresent)
    }

    // MARK: The real group

    /// The entitlement is in the build, and the test host can reach the group.
    /// Reads nothing and writes nothing there.
    func testTheRealAppGroupResolvesInTheTestHost() throws {
        let container = AppGroupContainer()
        let url = try XCTUnwrap(container.rootURL(), "group.com.interfulgent.suite is not reachable from the app")

        var isFolder: ObjCBool = false
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path, isDirectory: &isFolder))
        XCTAssertTrue(isFolder.boolValue)
        XCTAssertEqual(AppGroupContainer.identifier, "group.com.interfulgent.suite")
        XCTAssertTrue(SuiteTransit().isAvailable)
    }
}
