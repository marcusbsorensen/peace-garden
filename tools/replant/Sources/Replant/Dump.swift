import Foundation

/// Reads the rows out of mysqldump's SQL without a database to load it into.
///
/// **Why parse it rather than load it.** The live copies are MariaDB's, and
/// this Mac has no MariaDB; `tools/backup.sh --restore-test` borrows one from
/// Docker for the length of a test. A plan should not need that. What mysqldump
/// writes is narrow and regular: a `CREATE TABLE` naming the columns in order,
/// then `INSERT INTO `t` VALUES (...),(...);` with no column list. The values
/// are `NULL`, numbers, `0x` hex (the copies are taken with `--hex-blob`) and
/// single-quoted strings with backslash escapes. That is all this reads, and
/// anything else is refused rather than guessed at.
enum Dump {
    static func read(_ data: Data, tables wanted: Set<String>) throws -> [String: [Row]] {
        let bytes = [UInt8](data)
        var columns: [String: [String]] = [:]
        var rows: [String: [Row]] = [:]
        var i = 0

        func startsWith(_ text: String, at: Int) -> Bool {
            let t = Array(text.utf8)
            guard at + t.count <= bytes.count else { return false }
            return Array(bytes[at..<(at + t.count)]) == t
        }
        func lineEnd(from: Int) -> Int {
            var j = from
            while j < bytes.count, bytes[j] != 0x0A { j += 1 }
            return j
        }
        func name(from: Int) -> (String, Int) {
            // `name`
            var j = from
            while j < bytes.count, bytes[j] != 0x60 { j += 1 }
            let start = j + 1
            j = start
            while j < bytes.count, bytes[j] != 0x60 { j += 1 }
            return (String(decoding: bytes[start..<j], as: UTF8.self), j + 1)
        }

        while i < bytes.count {
            // Only ever at the start of a line.
            if startsWith("CREATE TABLE `", at: i) {
                let (table, after) = name(from: i)
                var names: [String] = []
                var j = lineEnd(from: after) + 1
                while j < bytes.count {
                    let end = lineEnd(from: j)
                    let line = String(decoding: bytes[j..<end], as: UTF8.self)
                    if line.hasPrefix(")") { break }
                    let trimmed = line.drop(while: { $0 == " " })
                    if trimmed.hasPrefix("`") {
                        let inner = trimmed.dropFirst()
                        if let close = inner.firstIndex(of: "`") { names.append(String(inner[..<close])) }
                    }
                    j = end + 1
                }
                columns[table] = names
                i = j
            } else if startsWith("INSERT INTO `", at: i) {
                let (table, after) = name(from: i)
                var j = after
                // To the word VALUES.
                while j < bytes.count, !startsWith("VALUES", at: j) { j += 1 }
                j += 6
                var tuples: [[Value]] = []
                j = try parseTuples(bytes, from: j, into: &tuples)
                if wanted.contains(table) {
                    guard let names = columns[table] else {
                        throw CopyError("rows for \(table) come before its CREATE TABLE")
                    }
                    for tuple in tuples {
                        guard tuple.count == names.count else {
                            throw CopyError("a row of \(table) has \(tuple.count) values for \(names.count) columns")
                        }
                        rows[table, default: []].append(Dictionary(uniqueKeysWithValues: zip(names, tuple)))
                    }
                }
                i = j
            }
            // A table the copy created but put no rows in is a table with no rows.
            i = lineEnd(from: i) + 1
        }
        for table in wanted where columns[table] != nil && rows[table] == nil { rows[table] = [] }
        return rows
    }

    /// `(v, v, ...),(v, ...);` from `from`, returning the index after the `;`.
    private static func parseTuples(_ b: [UInt8], from: Int, into tuples: inout [[Value]]) throws -> Int {
        var i = from
        func skipSpace() { while i < b.count, b[i] == 0x20 || b[i] == 0x0A || b[i] == 0x0D || b[i] == 0x09 { i += 1 } }
        while true {
            skipSpace()
            guard i < b.count else { throw CopyError("an INSERT runs off the end of the dump") }
            if b[i] == 0x3B { return i + 1 }                 // ;
            if b[i] == 0x2C { i += 1; continue }             // , between tuples
            guard b[i] == 0x28 else { throw CopyError("expected ( in an INSERT at byte \(i)") }
            i += 1
            var tuple: [Value] = []
            while true {
                skipSpace()
                guard i < b.count else { throw CopyError("a row runs off the end of the dump") }
                if b[i] == 0x29 { i += 1; break }            // )
                if b[i] == 0x2C { i += 1; continue }         // , between values
                if b[i] == 0x27 {                            // 'string'
                    i += 1
                    var out: [UInt8] = []
                    while true {
                        guard i < b.count else { throw CopyError("a string runs off the end of the dump") }
                        let c = b[i]
                        if c == 0x5C {                        // backslash escape
                            let e = b[i + 1]
                            switch e {
                            case 0x30: out.append(0)          // \0
                            case 0x6E: out.append(0x0A)       // \n
                            case 0x72: out.append(0x0D)       // \r
                            case 0x74: out.append(0x09)       // \t
                            case 0x62: out.append(0x08)       // \b
                            case 0x5A: out.append(0x1A)       // \Z
                            default: out.append(e)            // \\ \' \"
                            }
                            i += 2
                        } else if c == 0x27 {
                            if i + 1 < b.count, b[i + 1] == 0x27 { out.append(0x27); i += 2; continue }
                            i += 1
                            break
                        } else {
                            out.append(c)
                            i += 1
                        }
                    }
                    tuple.append(.text(String(decoding: out, as: UTF8.self)))
                } else {
                    let start = i
                    while i < b.count, b[i] != 0x2C, b[i] != 0x29 { i += 1 }
                    let word = String(decoding: b[start..<i], as: UTF8.self).trimmingCharacters(in: .whitespaces)
                    if word == "NULL" {
                        tuple.append(.null)
                    } else if word.hasPrefix("0x") {
                        // --hex-blob: the bytes, which in these tables are text.
                        let hex = Array(word.dropFirst(2).utf8)
                        var out: [UInt8] = []
                        var k = 0
                        while k + 1 < hex.count {
                            guard let byte = UInt8(String(decoding: hex[k...k + 1], as: UTF8.self), radix: 16) else {
                                throw CopyError("bad hex \(word)")
                            }
                            out.append(byte)
                            k += 2
                        }
                        tuple.append(.text(String(decoding: out, as: UTF8.self)))
                    } else if let integer = Int64(word) {
                        tuple.append(.integer(integer))
                    } else if let real = Double(word) {
                        tuple.append(.real(real))
                    } else {
                        throw CopyError("a value this does not read: \(word)")
                    }
                }
            }
            tuples.append(tuple)
        }
    }
}
