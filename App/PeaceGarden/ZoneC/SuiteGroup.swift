import Foundation

/// Where the suite's shared folder is, asked of a protocol so that a test can
/// hand `SuiteGroup` a temporary directory and never touch the real one.
///
/// `nil` means iOS will not give this app the folder: the entitlement is
/// missing, the build is not signed for the group, or the app is running as an
/// iPad app on a Mac. Everything above this treats that as "Zone C is shut",
/// not as an error to report.
protocol SuiteContainer: Sendable {
    func rootURL() -> URL?
}

/// The real thing: the suite-wide App Group the Hub named on 16 October 2026.
///
/// **On a Mac** an iPad app keeps this iOS identifier and never sees the
/// container Autonaut's Mac build uses, which carries the team prefix
/// (`R94VDZ56RY.group.com.interfulgent.suite`). Peace Garden has no Mac build,
/// so nothing crosses there, and a future one would take the prefixed name.
struct AppGroupContainer: SuiteContainer {
    static let identifier = "group.com.interfulgent.suite"

    func rootURL() -> URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Self.identifier)
    }
}

/// A folder of the caller's choosing, for tests and previews.
struct DirectoryContainer: SuiteContainer {
    let url: URL

    func rootURL() -> URL? { url }
}

enum SuiteError: Error, Equatable {
    /// The suite's folder is not available on this phone.
    case noContainer
    /// A file of that name is already in place. For a presence marker this is
    /// the ordinary answer, not a failure.
    case alreadyThere(String)
    /// The fixed dates would not hold on a file, so it was never put in place.
    /// A file in the group with a real date would say when someone was in
    /// Autonaut, which can be when they were in crisis.
    case datesNotHeld(String)
    /// The caller asked for something that is not a seed.
    case notASeed
    /// The file system, or the file coordinator, refused.
    case io(String)
}

/// Everything Peace Garden does to files in the suite's shared folder, and
/// nothing about what they mean. `SuiteTransit` knows the formats.
///
/// The folder belongs to the whole suite, and an App Group cannot enforce
/// which part of it an app keeps to. So the rules are kept here, in one place,
/// where a test can watch them:
///
/// - **Every access is coordinated** (`NSFileCoordinator`), as the Hub's
///   convention for the folder asks of every app.
/// - **Every write is staged.** A file is written whole under
///   `Seeds/v1/tmp/peacegarden-<random>`, given the fixed dates and the
///   no-backup flag, and only then renamed to where it belongs. So a file in
///   `out/` or `in/` is always complete, and a reader may delete a malformed one
///   on sight. This is the order agreed with Autonaut on 17 October 2026.
/// - **Every date is 1 January 2001**, on the files and on the folders, read
///   back after it is set. A file system records when a file was made, and in
///   this folder that would be a diary. A file that cannot be given the date is
///   not put in place at all.
/// - **`tmp/` is never read.** Each app clears only the names that begin with
///   its own prefix. Listing the folder for those names is the one thing done
///   there, and no other app's file in it is opened.
///
/// The calls are synchronous and use the file coordinator, which waits if
/// another process holds a file. They are small, but call them off the main
/// actor all the same.
///
/// ## What the change time shows
///
/// A file's change time (`st_ctime`) is the file system's own record of when
/// anything about the file last changed, a rename included. Nothing can set it,
/// so it shows the real time of the last write. `SuiteTransitTests` records
/// what it reads (R6 in the build plan).
struct SuiteGroup: Sendable {
    /// 1 January 2001, 00:00 UTC. The reference date, so it is also zero.
    static let fixedDate = Date(timeIntervalSinceReferenceDate: 0)

    /// What every staged file's name begins with. Another app's begins with its
    /// own, and neither touches the other's.
    static let stagingPrefix = "peacegarden-"

    // The layout, relative to the root. Paths are strings so the audit trail a
    // test reads is plain.
    static let presenceFolder = "Presence/v1"
    static let seedsFolder = "Seeds/v1"
    static let outFolder = "Seeds/v1/out"
    static let inFolder = "Seeds/v1/in"
    static let tmpFolder = "Seeds/v1/tmp"

    /// Every folder this code creates or leaves a mark on, parents first. A
    /// folder's modified date moves whenever something is added to it or taken
    /// out of it, so all of them are set back after every write.
    static let datedFolders = [
        "Presence", presenceFolder, "Seeds", seedsFolder, outFolder, inFolder, tmpFolder,
    ]

    /// What this code does to the folder, in the order it does it.
    ///
    /// For a test to read. It is how "writes only its own files, reads only
    /// `out/`, `Presence/v1/autonaut` and its own" is checked rather than
    /// promised. Paths are relative to the root.
    enum Access: Equatable, Sendable {
        case list(String)
        case exists(String)
        case inspect(String)
        case read(String)
        case createFolder(String)
        case write(String)
        case setBackupFlag(String)
        case setDates(String)
        case move(from: String, to: String)
        case remove(String)
    }

    /// What a read of a small file found.
    enum Reading: Equatable, Sendable {
        case missing
        /// A folder, a link or anything else that is not a plain file.
        case notAFile
        /// Longer than the caller allows. Not opened.
        case tooLong
        case contents(Data)
    }

    struct Placement: Equatable, Sendable {
        /// Whether the file and every folder read back as 1 January 2001
        /// after the move.
        var datesHeld: Bool
    }

    let container: any SuiteContainer
    private let randomName: @Sendable () -> String
    private let audit: (@Sendable (Access) -> Void)?

    init(
        container: any SuiteContainer = AppGroupContainer(),
        randomName: @escaping @Sendable () -> String = SuiteGroup.randomName,
        audit: (@Sendable (Access) -> Void)? = nil
    ) {
        self.container = container
        self.randomName = randomName
        self.audit = audit
    }

    /// Sixteen random bytes as thirty-two hex characters: never a count and
    /// never a time.
    static func randomName() -> String {
        var generator = SystemRandomNumberGenerator()
        let bytes = (0..<16).map { _ in UInt8.random(in: 0...255, using: &generator) }
        return SuiteHex.encode(Data(bytes))
    }

    var isAvailable: Bool { container.rootURL() != nil }

    /// A fresh random name for a file that is to sit in `in/`.
    func newName() -> String { randomName() }

    // MARK: - The layout

    /// Makes the folders that are missing, flags `Seeds/v1` as left out of
    /// backups, and sets every folder's dates. Safe to run at every launch: when
    /// nothing is missing it changes nothing.
    func prepareLayout() throws {
        for folder in [Self.presenceFolder, Self.outFolder, Self.inFolder, Self.tmpFolder] {
            let target = try url(folder)
            guard !isFolder(target) else { continue }
            try coordinatedWrite(target) { folderURL in
                audit?(.createFolder(folder))
                try FileManager.default.createDirectory(
                    at: folderURL, withIntermediateDirectories: true
                )
            }
        }
        try excludeFromBackup(Self.seedsFolder)
        fixFolderDates()
    }

    /// The folder is left out of device backups (the Hub's rule for the suite).
    /// Zone C's own store is a different thing and is backed up with the garden.
    private func excludeFromBackup(_ relative: String) throws {
        let target = try url(relative)
        if Self.isExcluded(target) { return }
        try coordinatedWrite(target) { folderURL in
            audit?(.setBackupFlag(relative))
            try Self.exclude(folderURL)
        }
    }

    /// Whether a file or folder carries the no-backup flag. Read afresh, because
    /// a `URL` keeps the answers it has already been given.
    static func isExcluded(_ url: URL) -> Bool {
        let fresh = URL(fileURLWithPath: url.path)
        let values = try? fresh.resourceValues(forKeys: [.isExcludedFromBackupKey])
        return values?.isExcludedFromBackup == true
    }

    private static func exclude(_ url: URL) throws {
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var target = url
        try target.setResourceValues(values)
    }

    // MARK: - Dates

    /// Whether the file or folder reads back as 1 January 2001, created and
    /// modified.
    func datesHold(atPath path: String) -> Bool {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: path) else {
            return false
        }
        return Self.isFixed(attributes[.creationDate] as? Date)
            && Self.isFixed(attributes[.modificationDate] as? Date)
    }

    private static func isFixed(_ date: Date?) -> Bool {
        guard let date else { return false }
        return abs(date.timeIntervalSince(fixedDate)) < 1
    }

    /// Sets both dates and reads them back. Leaves a file alone that already
    /// holds them, so a launch with nothing to do writes nothing.
    private func fixDates(atPath path: String) -> Bool {
        if datesHold(atPath: path) { return true }
        try? FileManager.default.setAttributes(
            [.creationDate: Self.fixedDate, .modificationDate: Self.fixedDate],
            ofItemAtPath: path
        )
        return datesHold(atPath: path)
    }

    /// Sets the dates of every folder that is there and not already right.
    /// True when all of them read back correctly.
    @discardableResult
    func fixFolderDates() -> Bool {
        var allHold = true
        for folder in Self.datedFolders {
            guard let target = try? url(folder), isFolder(target) else { continue }
            if datesHold(atPath: target.path) { continue }
            let held = (try? coordinatedWrite(target) { folderURL in
                audit?(.setDates(folder))
                return fixDates(atPath: folderURL.path)
            }) ?? false
            if !held { allHold = false }
        }
        return allHold
    }

    // MARK: - Looking

    /// The names in a folder, sorted, and nothing about the files. A folder that
    /// is not there has no names.
    func names(in folder: String) throws -> [String] {
        let target = try url(folder)
        audit?(.list(folder))
        let found: [String] = try coordinatedRead(target) { folderURL in
            guard isFolder(folderURL) else { return [] }
            return try FileManager.default.contentsOfDirectory(atPath: folderURL.path)
        }
        return found.sorted()
    }

    /// Whether anything is at the path, a link included. Opens nothing.
    func exists(_ relative: String) -> Bool {
        guard let target = try? url(relative) else { return false }
        audit?(.exists(relative))
        let found = try? coordinatedRead(target) { fileURL in
            (try? FileManager.default.attributesOfItem(atPath: fileURL.path)) != nil
        }
        return found ?? false
    }

    /// Opens a small file, but only if it is a plain file no longer than
    /// `maxBytes`. Anything else is reported without being opened, so a caller
    /// that means to delete it never reads what it is deleting.
    func readSmallFile(_ relative: String, maxBytes: Int) throws -> Reading {
        let target = try url(relative)
        return try coordinatedRead(target) { fileURL in
            audit?(.inspect(relative))
            guard let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path)
            else { return .missing }
            guard attributes[.type] as? FileAttributeType == .typeRegular else { return .notAFile }
            guard let size = attributes[.size] as? NSNumber, size.intValue <= maxBytes else {
                return .tooLong
            }
            audit?(.read(relative))
            let handle = try FileHandle(forReadingFrom: fileURL)
            defer { try? handle.close() }
            // One byte past the limit: a file that grew since it was measured is
            // still not read in full.
            let data = try handle.read(upToCount: maxBytes + 1) ?? Data()
            return data.count > maxBytes ? .tooLong : .contents(data)
        }
    }

    // MARK: - Writing

    /// Puts `data` at `destination`, a path relative to the root, by way of
    /// `tmp/`.
    ///
    /// The file is written whole under `Seeds/v1/tmp/peacegarden-<random>`,
    /// flagged as left out of backups, dated 1 January 2001 and checked. Then it
    /// is renamed to `destination`, and the folders are dated again, since the
    /// rename changed them. A rename keeps a file's dates, so there is no moment
    /// at which it is visible with a real one.
    ///
    /// - Throws: `alreadyThere` if something is at `destination`, with the staged
    ///   file removed again; `datesNotHeld` if the dates would not stick, with
    ///   the file removed and nothing put in place.
    @discardableResult
    func stage(_ data: Data, to destination: String) throws -> Placement {
        try prepareLayout()
        let stagedPath = "\(Self.tmpFolder)/\(Self.stagingPrefix)\(randomName())"
        let staged = try url(stagedPath)
        let target = try url(destination)

        let datesHeld: Bool = try coordinatedWrite(staged) { fileURL in
            audit?(.write(stagedPath))
            try data.write(to: fileURL, options: .withoutOverwriting)
            audit?(.setBackupFlag(stagedPath))
            try Self.exclude(fileURL)
            audit?(.setDates(stagedPath))
            return fixDates(atPath: fileURL.path)
        }
        guard datesHeld else {
            try? discard(stagedPath)
            throw SuiteError.datesNotHeld(destination)
        }

        do {
            try coordinatedMove(from: staged, to: target) {
                audit?(.move(from: stagedPath, to: destination))
            }
        } catch let error as CocoaError where error.code == .fileWriteFileExists {
            try? discard(stagedPath)
            fixFolderDates()
            throw SuiteError.alreadyThere(destination)
        } catch {
            try? discard(stagedPath)
            fixFolderDates()
            throw error
        }

        let fileHeld = fixDates(atPath: target.path)
        let foldersHeld = fixFolderDates()
        return Placement(datesHeld: fileHeld && foldersHeld)
    }

    /// Deletes one path. Nothing there is not a failure.
    func remove(_ relative: String) throws {
        let target = try url(relative)
        try coordinatedWrite(target, options: .forDeleting) { fileURL in
            guard (try? FileManager.default.attributesOfItem(atPath: fileURL.path)) != nil else {
                return
            }
            audit?(.remove(relative))
            try FileManager.default.removeItem(at: fileURL)
        }
        fixFolderDates()
    }

    /// Deletes what this app left in `tmp/` and nothing else: the names that
    /// begin with `peacegarden-`. Returns how many went.
    @discardableResult
    func removeOwnStaging() throws -> Int {
        var removed = 0
        for name in try names(in: Self.tmpFolder) where name.hasPrefix(Self.stagingPrefix) {
            try remove("\(Self.tmpFolder)/\(name)")
            removed += 1
        }
        return removed
    }

    private func discard(_ relative: String) throws {
        try remove(relative)
    }

    // MARK: - Coordination and paths

    private func url(_ relative: String) throws -> URL {
        guard let root = container.rootURL() else { throw SuiteError.noContainer }
        return root.appendingPathComponent(relative)
    }

    private func isFolder(_ url: URL) -> Bool {
        var isFolder: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isFolder)
            && isFolder.boolValue
    }

    private func coordinatedRead<T>(
        _ url: URL, _ body: (URL) throws -> T
    ) throws -> T {
        var coordinationError: NSError?
        var outcome: Result<T, Error>?
        NSFileCoordinator(filePresenter: nil).coordinate(
            readingItemAt: url, options: .withoutChanges, error: &coordinationError
        ) { granted in
            outcome = Result { try body(granted) }
        }
        return try finish(outcome, coordinationError)
    }

    private func coordinatedWrite<T>(
        _ url: URL, options: NSFileCoordinator.WritingOptions = [], _ body: (URL) throws -> T
    ) throws -> T {
        var coordinationError: NSError?
        var outcome: Result<T, Error>?
        NSFileCoordinator(filePresenter: nil).coordinate(
            writingItemAt: url, options: options, error: &coordinationError
        ) { granted in
            outcome = Result { try body(granted) }
        }
        return try finish(outcome, coordinationError)
    }

    private func coordinatedMove(from source: URL, to destination: URL, _ before: () -> Void) throws {
        var coordinationError: NSError?
        var outcome: Result<Void, Error>?
        NSFileCoordinator(filePresenter: nil).coordinate(
            writingItemAt: source, options: .forMoving,
            writingItemAt: destination, options: .forReplacing,
            error: &coordinationError
        ) { from, to in
            before()
            outcome = Result { try FileManager.default.moveItem(at: from, to: to) }
        }
        try finish(outcome, coordinationError)
    }

    @discardableResult
    private func finish<T>(_ outcome: Result<T, Error>?, _ coordinationError: NSError?) throws -> T {
        if let coordinationError { throw SuiteError.io(coordinationError.localizedDescription) }
        guard let outcome else { throw SuiteError.io("the file coordinator did not run") }
        do {
            return try outcome.get()
        } catch let error as SuiteError {
            throw error
        } catch let error as CocoaError where error.code == .fileWriteFileExists {
            throw error
        } catch {
            throw SuiteError.io(error.localizedDescription)
        }
    }
}
