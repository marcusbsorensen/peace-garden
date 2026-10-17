import Foundation
import Security
import SeedCore

/// Reads and writes Zone C's records as a single JSON file, `zonec.json`,
/// beside `garden.json`.
///
/// Zone C is in the device backup with the garden (Marcus's 9B, 16 October
/// 2026): a phone restored from a backup keeps its own seed and its records, so
/// the returns for seeds it sent can still be opened. So this file is in
/// Peace Garden's own container and is **not** marked excluded from backups,
/// unlike the App Group's transit files. A test holds that.
///
/// It is written the way the garden is, atomically and guarded
/// (`GardenStore.guarded`), because Zone C's own seed cannot be minted again
/// and still mean the same plants.
///
/// **Switches live elsewhere.** Whether Zone C is on is a setting the app owns
/// (A5), not something this file holds, so that turning it off never has to
/// rewrite the records.
///
/// Every read-modify-write goes through `update`, which holds one lock, so two
/// callers on different threads cannot lose each other's changes, and a
/// change that throws writes nothing. Do not call the store from inside the
/// closure `update` is given: the lock is not re-entrant.
final class ZoneCStore: @unchecked Sendable {
    enum StoreError: Error, LocalizedError {
        case unreadable(underlying: Error)
        case unwritable(underlying: Error)
        case unsupportedSchema(found: Int)
        case noRandomness(status: Int32)

        var errorDescription: String? {
            switch self {
            case .unreadable(let error):
                return "Zone C could not be read: \(error.localizedDescription)"
            case .unwritable(let error):
                return "Zone C could not be saved: \(error.localizedDescription)"
            case .unsupportedSchema(let found):
                return "Zone C was written by a newer version of the app (format \(found))."
            case .noRandomness(let status):
                return "The system gave no random bytes (status \(status))."
            }
        }
    }

    static let fileName = "zonec.json"

    let fileURL: URL
    /// How the file is written. `GardenStore.guarded` unless a test says
    /// otherwise.
    let writeOptions: Data.WritingOptions
    private let fileManager: FileManager
    private let randomBytes: @Sendable (Int) throws -> Data
    private let lock = NSLock()

    /// - Parameters:
    ///   - writeOptions: leave this alone outside tests. On a Mac the
    ///     protection class follows the screen lock, which makes a test that
    ///     passes all day fail overnight; see `GardenStore.init`.
    ///   - randomBytes: the source of Zone C's own seed. Leave this alone
    ///     outside tests.
    init(
        fileURL: URL,
        fileManager: FileManager = .default,
        writeOptions: Data.WritingOptions = GardenStore.guarded,
        randomBytes: @escaping @Sendable (Int) throws -> Data = ZoneCStore.systemRandomBytes
    ) {
        self.fileURL = fileURL
        self.fileManager = fileManager
        self.writeOptions = writeOptions
        self.randomBytes = randomBytes
    }

    /// Application Support/PeaceGarden/zonec.json, in whichever folder the
    /// garden's own file is in, so the two always travel together.
    convenience init(
        besideGardenAt garden: GardenStore,
        fileManager: FileManager = .default,
        writeOptions: Data.WritingOptions = GardenStore.guarded,
        randomBytes: @escaping @Sendable (Int) throws -> Data = ZoneCStore.systemRandomBytes
    ) {
        self.init(
            fileURL: garden.fileURL.deletingLastPathComponent().appendingPathComponent(Self.fileName),
            fileManager: fileManager,
            writeOptions: writeOptions,
            randomBytes: randomBytes
        )
    }

    /// `SecRandomCopyBytes`, the system's own source.
    @Sendable
    static func systemRandomBytes(_ count: Int) throws -> Data {
        var bytes = [UInt8](repeating: 0, count: count)
        let status = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
        guard status == errSecSuccess else { throw StoreError.noRandomness(status: status) }
        return Data(bytes)
    }

    // Made as it is used: JSONEncoder is not Sendable, so a shared one would
    // not compile under strict concurrency. No date strategy is set, because
    // nothing in the file is a date.
    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    // MARK: - Reading and writing

    /// What Zone C holds. A phone that has never used it reads as empty.
    func load() throws -> ZoneCState {
        try lock.withLock { try readLocked() }
    }

    /// Replaces what Zone C holds. Prefer `update`, which cannot lose a change
    /// made in between.
    func save(_ state: ZoneCState) throws {
        try lock.withLock { try writeLocked(state) }
    }

    /// Reads, changes and writes under one lock. Nothing is written if `change`
    /// throws or leaves the state as it found it, so a find that plants, queues
    /// a return and notes the day does all three or none.
    @discardableResult
    func update<Value>(_ change: (inout ZoneCState) throws -> Value) throws -> Value {
        try lock.withLock {
            var state = try readLocked()
            let before = state
            let result = try change(&state)
            if state != before { try writeLocked(state) }
            return result
        }
    }

    /// Zone C's own seed. Minted from 32 random bytes the first time it is
    /// asked for, written before it is returned, and the same every time after.
    func ownSeed() throws -> SeedID {
        try update { try $0.mintOwnSeedIfNeeded(using: randomBytes) }
    }

    /// Removes the file, and with it the own seed, the records and the plants.
    /// For "Reset everything" (A5). Nothing to remove is not an error.
    func erase() throws {
        try lock.withLock {
            guard fileManager.fileExists(atPath: fileURL.path) else { return }
            do {
                try fileManager.removeItem(at: fileURL)
            } catch {
                throw StoreError.unwritable(underlying: error)
            }
        }
    }

    // MARK: - Under the lock

    private func readLocked() throws -> ZoneCState {
        guard fileManager.fileExists(atPath: fileURL.path) else { return ZoneCState() }
        do {
            let data = try Data(contentsOf: fileURL)
            let state = try JSONDecoder().decode(ZoneCState.self, from: data)
            // A file from a newer version is refused rather than read and
            // written back without what this version does not know.
            guard state.schemaVersion <= ZoneCState.currentSchemaVersion else {
                throw StoreError.unsupportedSchema(found: state.schemaVersion)
            }
            return state
        } catch let error as StoreError {
            throw error
        } catch {
            throw StoreError.unreadable(underlying: error)
        }
    }

    private func writeLocked(_ state: ZoneCState) throws {
        do {
            var state = state
            state.schemaVersion = ZoneCState.currentSchemaVersion
            let data = try Self.makeEncoder().encode(state)
            try fileManager.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: fileURL, options: writeOptions)
        } catch {
            throw StoreError.unwritable(underlying: error)
        }
    }
}
