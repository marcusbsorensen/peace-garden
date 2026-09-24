import CryptoKit
import Foundation
import SQLite3

/// One value out of a table, in the four kinds the garden's tables hold.
enum Value: Equatable, Sendable {
    case null
    case integer(Int64)
    case real(Double)
    case text(String)

    var string: String? {
        switch self {
        case .text(let s): return s
        case .integer(let i): return String(i)
        case .real(let d): return String(d)
        case .null: return nil
        }
    }

    var double: Double? {
        switch self {
        case .real(let d): return d
        case .integer(let i): return Double(i)
        case .text(let s): return Double(s)
        case .null: return nil
        }
    }

    var int: Int? {
        switch self {
        case .integer(let i): return Int(i)
        case .real(let d): return Int(d)
        case .text(let s): return Int(s)
        case .null: return nil
        }
    }
}

typealias Row = [String: Value]

struct CopyError: Error, CustomStringConvertible {
    let description: String
    init(_ said: String) { description = said }
}

/// A copy of the garden, read: whichever tables it holds, every row of each.
///
/// **Two kinds of copy, and this reads both**, because `Server/.api/backup.php`
/// writes two. On the live service, whose database is MariaDB, a copy is
/// mysqldump's SQL, gzipped behind a preamble of row counts. On a SQLite
/// service — a Mac, a rehearsal — it is the database file itself, taken with
/// `VACUUM INTO`, in the same gzip behind the same preamble. A bare `.sqlite`
/// file is read too, for rehearsals that want to skip the gzip.
///
/// Read-only throughout. The copy is opened, read and closed; a SQLite copy is
/// unpacked into a temporary file of its own and never written to.
struct Copy {
    /// The tables the replant reads: every area's, and the asking's.
    static let tables = ["long_walk", "quiet_garden", "crossing", "orchard", "knot_garden",
                         "seedbed", "cold_frame", "glasshouse", "coppice", "home_ground", "walk_offers"]

    let file: String
    /// Of the file's bytes as they are on disk, so a plan names the copy it
    /// was made from beyond doubt.
    let sha256: String
    /// When the copy was taken, from its preamble, if it says.
    let taken: String?
    let kind: String
    /// Only the tables the copy has. An older copy predates the newer areas,
    /// and a table it does not have is an area that had nothing in it.
    let rows: [String: [Row]]

    static func read(_ path: String) throws -> Copy {
        let url = URL(fileURLWithPath: path)
        let raw = try Data(contentsOf: url)
        let sha = SHA256.hash(data: raw).map { String(format: "%02x", $0) }.joined()

        if path.hasSuffix(".sqlite") || path.hasSuffix(".db") {
            return Copy(file: url.lastPathComponent, sha256: sha, taken: nil, kind: "sqlite file",
                        rows: try SQLiteReader.read(path))
        }
        let plain = path.hasSuffix(".gz") ? try gunzip(url) : raw
        let taken = preambleTaken(plain)

        let marker = Data("-- A SQLite file follows, not SQL.\n".utf8)
        if let found = plain.range(of: marker) {
            // What backup.php's `copyTheFile` wrote: the preamble, the marker,
            // the file, and the completion line after a newline of its own.
            var body = plain[found.upperBound...]
            let tail = Data("\n-- Dump completed\n".utf8)
            guard body.count >= tail.count, body.suffix(tail.count) == tail else {
                throw CopyError("the SQLite copy does not end where backup.php ends one — cut short?")
            }
            body = body.dropLast(tail.count)
            let temporary = FileManager.default.temporaryDirectory
                .appendingPathComponent("replant-\(UUID().uuidString).sqlite")
            try Data(body).write(to: temporary)
            defer { try? FileManager.default.removeItem(at: temporary) }
            return Copy(file: url.lastPathComponent, sha256: sha, taken: taken, kind: "SQLite copy",
                        rows: try SQLiteReader.read(temporary.path))
        }

        guard plain.range(of: Data("-- Dump completed".utf8)) != nil else {
            throw CopyError("the dump has no completion line — it was cut short, and a plan made from it would be short too")
        }
        return Copy(file: url.lastPathComponent, sha256: sha, taken: taken, kind: "MariaDB dump",
                    rows: try Dump.read(plain, tables: Set(tables)))
    }

    private static func gunzip(_ url: URL) throws -> Data {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/gzip")
        process.arguments = ["-dc", url.path]
        let out = Pipe()
        process.standardOutput = out
        try process.run()
        // Read to the end before waiting, or a large copy fills the pipe and
        // the two wait on each other.
        let data = out.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { throw CopyError("gzip could not read \(url.path)") }
        return data
    }

    private static func preambleTaken(_ plain: Data) -> String? {
        let head = String(decoding: plain.prefix(2048), as: UTF8.self)
        for line in head.split(separator: "\n") where line.hasPrefix("-- taken ") {
            return String(line.dropFirst("-- taken ".count))
        }
        return nil
    }
}

/// A SQLite database read through the system's own library, read-only.
enum SQLiteReader {
    static func read(_ path: String) throws -> [String: [Row]] {
        var db: OpaquePointer?
        guard sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            throw CopyError("SQLite will not open \(path)")
        }
        defer { sqlite3_close(db) }

        var present = Set<String>()
        for row in try query(db, "SELECT name FROM sqlite_master WHERE type = 'table'") {
            if let name = row["name"]?.string { present.insert(name) }
        }
        var out: [String: [Row]] = [:]
        for table in Copy.tables where present.contains(table) {
            out[table] = try query(db, "SELECT * FROM \(table)")
        }
        return out
    }

    private static func query(_ db: OpaquePointer?, _ sql: String) throws -> [Row] {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw CopyError("SQLite refused: \(sql)")
        }
        defer { sqlite3_finalize(statement) }
        var rows: [Row] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            var row: Row = [:]
            for column in 0..<sqlite3_column_count(statement) {
                let name = String(cString: sqlite3_column_name(statement, column))
                switch sqlite3_column_type(statement, column) {
                case SQLITE_INTEGER: row[name] = .integer(sqlite3_column_int64(statement, column))
                case SQLITE_FLOAT: row[name] = .real(sqlite3_column_double(statement, column))
                case SQLITE_NULL: row[name] = .null
                default:
                    if let text = sqlite3_column_text(statement, column) {
                        row[name] = .text(String(cString: text))
                    } else {
                        row[name] = .null
                    }
                }
            }
            rows.append(row)
        }
        return rows
    }
}
