import XCTest
@testable import SeedCore

/// Comparing a recorded vector file with what this host computes today.
///
/// **Why this is not string equality, which is what it used to be.**
///
/// Every vector file in `tools/reference/` was recorded on a Mac, and until 22
/// September each test asserted that the file and the freshly computed string
/// were the same bytes. On Linux and under WebAssembly they are not, and had
/// not been since the ambassadors were recorded on 20 September: continuous
/// integration was red for two days across six suites, and the failure was the
/// same failure six times.
///
/// **What actually differs, measured.** Of five hundred arrivals to the Knot
/// Garden, a hundred and ninety-four have a grown height that differs between
/// macOS and WebAssembly. The largest disagreement is **3.6 × 10⁻⁷ m**, which
/// is three of a `Float`'s last bits and a third of a micron. **Nothing else
/// differs at all** — not a plot, not a slot, not a nudge, not a colour family,
/// in any of the five areas.
///
/// That is not a defect in this code and it is not one anybody can fix. A
/// plant's mesh is built out of `sin`, `cos`, `pow` and `exp`, each of them a C
/// library function that Apple's libm and wasi-libc compute correct to within
/// about an ulp of the true value *without being correct to the same bit as one
/// another*. `tools/reference/check_sky.mjs` reached this conclusion first, for
/// the JavaScript port, and said it plainly: demanding equality of those is
/// demanding that two C libraries agree. This is the same finding arriving on
/// the Swift side, and it is answered the same way — **a tolerance, named in
/// the units of the thing it measures, and only on the fields that need one.**
///
/// Everything built out of `+ - * /` still has to match to the last bit, and
/// does. A nudge is seed bytes divided and multiplied, so it is exact. A plot
/// and a slot are integers, so they are exact. Only a grown height is
/// tolerated, and `placementCannotTurn(on:cuts:groupedBy:)` below — called by
/// every area's vector test — is what makes tolerating it safe rather than
/// merely convenient.
enum VectorFile {

    /// **A hundredth of a millimetre**, and the two numbers it sits between.
    ///
    /// Above it: the largest height two hosts have ever disagreed by is
    /// 3.6 × 10⁻⁷ m, so this is twenty-eight times the disagreement it has to
    /// absorb. Below it: the closest any recorded height comes to a placement
    /// cut is 3.7 × 10⁻⁴ m and the closest two heights the rules ever compare
    /// with each other is 1.0 × 10⁻⁴ m, so this is ten times finer than the
    /// finest decision any rule makes. (Measured again when the vectors were
    /// re-recorded for the plants' new shapes, 24 September 2026; it was 2.3 and
    /// 1.6 × 10⁻⁴ m, sixteen times.)
    ///
    /// It is a length rather than a ratio because a height is a length, and the
    /// thing it must stay clear of — a tier cut, a rank cut — is a length too.
    static let height = 1.0e-5

    /// A billionth of a degree, a millionth of a pixel, and a millionth of a
    /// millionth — which is what `check_sky.mjs` already allows the same three
    /// quantities, for the same reason. See `ANGLE`, `PIXEL` and `POW` there;
    /// the names are deliberately the same, because they are the same numbers
    /// answering the same finding on the other side of the same port.
    static let angle = 1.0e-9
    static let pixel = 1.0e-6
    static let power = 1.0e-12

    /// The recorded file and the freshly computed one say the same thing.
    ///
    /// `tolerant` names the fields that may differ, and by how much, in their
    /// own units. A field not named in it must match exactly. A field named in
    /// it is matched by name wherever it appears, at any depth, which is how
    /// `height` covers both a bare list of arrivals and the ambassadors nested
    /// inside an object.
    static func same(committed: String, rendered: String, tolerant: [String: Double],
                     recordWith advice: String,
                     file: StaticString = #filePath, line: UInt = #line) {
        guard committed != rendered else { return }
        guard let was = Value(json: committed), let now = Value(json: rendered) else {
            return XCTFail("one of the two is not JSON this can read. \(advice)",
                           file: file, line: line)
        }
        var quarrels: [String] = []
        Value.compare(was, now, at: "", tolerant: tolerant, quarrels: &quarrels)
        guard !quarrels.isEmpty else { return }
        XCTFail("""
            The recorded vectors and what this host computes disagree \
            about \(quarrels.count) \(quarrels.count == 1 ? "thing" : "things"):
              \(quarrels.prefix(6).joined(separator: "\n  "))
            \(advice)
            """, file: file, line: line)
    }

    /// One value out of a vector file. Written by hand rather than reached for
    /// through `JSONSerialization`, which is not in the Foundation the
    /// WebAssembly build links — and this file has to run there above all,
    /// because WebAssembly is one of the two hosts it exists to reconcile.
    indirect enum Value: Decodable, Sendable {
        case text(String)
        case number(Double)
        case flag(Bool)
        case list([Value])
        case object([String: Value])
        case nothing

        init(from decoder: any Decoder) throws {
            let one = try decoder.singleValueContainer()
            if one.decodeNil() { self = .nothing }
            // Bool before Double: `true` is not a number, but a bare `1` would
            // decode as either and must stay a number.
            else if let flag = try? one.decode(Bool.self) { self = .flag(flag) }
            else if let number = try? one.decode(Double.self) { self = .number(number) }
            else if let text = try? one.decode(String.self) { self = .text(text) }
            else if let list = try? one.decode([Value].self) { self = .list(list) }
            else { self = .object(try one.decode([String: Value].self)) }
        }

        init?(json: String) {
            guard let data = json.data(using: .utf8),
                  let value = try? JSONDecoder().decode(Value.self, from: data) else { return nil }
            self = value
        }

        /// Walks the two together and writes down where they part company.
        ///
        /// The tolerance is looked up by the **last named field** on the way
        /// down, so `ambassadors[4].height` and `[12].height` are both a
        /// height, and `nudge[0]` is a nudge whether or not anybody tolerates
        /// one.
        static func compare(_ was: Value, _ now: Value, at path: String,
                            tolerant: [String: Double], field: String = "",
                            quarrels: inout [String]) {
            guard quarrels.count < 24 else { return }
            switch (was, now) {
            case let (.text(a), .text(b)) where a == b: return
            case let (.flag(a), .flag(b)) where a == b: return
            case (.nothing, .nothing): return
            case let (.number(a), .number(b)):
                let slack = tolerant[field] ?? 0
                let by = abs(a - b)
                if a == b || by <= slack { return }
                quarrels.append("\(path): \(a) against \(b)"
                    + (slack > 0 ? ", which is \(by) apart and \(slack) is allowed" : ""))
            case let (.list(a), .list(b)):
                guard a.count == b.count else {
                    return quarrels.append("\(path): \(a.count) of them against \(b.count)")
                }
                for (i, pair) in zip(a, b).enumerated() {
                    compare(pair.0, pair.1, at: "\(path)[\(i)]", tolerant: tolerant,
                            field: field, quarrels: &quarrels)
                }
            case let (.object(a), .object(b)):
                let keys = Set(a.keys).union(b.keys)
                for key in keys.sorted() {
                    guard let mine = a[key] else { return quarrels.append("\(path).\(key): only the new one has it") }
                    guard let theirs = b[key] else { return quarrels.append("\(path).\(key): only the recorded one has it") }
                    compare(mine, theirs, at: "\(path).\(key)", tolerant: tolerant,
                            field: key, quarrels: &quarrels)
                }
            default:
                quarrels.append("\(path): the two are not even the same kind of thing")
            }
        }
    }
}

/// **The placement cannot turn on the last bit of a height**, said as the thing
/// that has to be true rather than as a sample of it.
///
/// A tolerance on a recorded height is only honest if no rule's answer could
/// change inside it. Every placement rule in this garden decides two kinds of
/// question about a height and nothing else: which side of a **cut** it falls,
/// and whether it is taller or shorter than **another plant the rule compares
/// it with**. So if every recorded height clears every cut by more than the
/// tolerance, and every pair a rule compares differs by more than twice it, no
/// disagreement smaller than the tolerance can move a single plant.
///
/// That is a proof rather than a replay, and it is what lets the vector files
/// stop demanding a bit-equality that no two C libraries will ever give.
///
/// It is also a live measurement. The day a crossing throws up a plant standing
/// 0.9299999 m tall, this fails and says so, and somebody decides whether to
/// move the cut or narrow the tolerance. As recorded, the tightest margin in
/// the whole garden is 1.0 × 10⁻⁴ m, two ferns on one coupe's floor — ten
/// times the tolerance and nearly three hundred times the disagreement.
extension VectorFile {

    /// `cuts` are the numbers the area's rule compares a height against, and
    /// `groupedBy` names the fields that say which plants are ever weighed
    /// against each other — a plot and a tier of one side, a plot and a guild,
    /// a plot and a compartment.
    static func placementCannotTurn(on committed: String, cuts: [Double], groupedBy: [String],
                                    tolerance: Double = VectorFile.height,
                                    file: StaticString = #filePath, line: UInt = #line) {
        guard case let .list(rows)? = Value(json: committed) else {
            return XCTFail("the recorded vectors are not a list of arrivals", file: file, line: line)
        }
        var nearestCut = Double.greatestFiniteMagnitude
        var nearestIs = ""
        var groups: [String: [Double]] = [:]
        for row in rows {
            guard case let .object(fields) = row,
                  case let .number(height)? = fields["height"] else { continue }
            for cut in cuts where abs(height - cut) < nearestCut {
                nearestCut = abs(height - cut)
                nearestIs = "\(height) m against a cut at \(cut) m"
            }
            let key = groupedBy.map { name -> String in
                if case let .number(value)? = fields[name] { return "\(value)" }
                return "?"
            }.joined(separator: "/")
            groups[key, default: []].append(height)
        }

        XCTAssertGreaterThan(nearestCut, tolerance, """
            \(nearestIs) — closer to a cut than the \(tolerance) m two hosts are \
            allowed to disagree by, so which side of it that plant falls is no longer \
            the same on every host
            """, file: file, line: line)

        var closestPair = Double.greatestFiniteMagnitude
        var closestIs = ""
        for (key, group) in groups {
            for (i, a) in group.enumerated() {
                for b in group.dropFirst(i + 1) where abs(a - b) < closestPair {
                    closestPair = abs(a - b)
                    closestIs = "\(a) m and \(b) m in \(groupedBy.joined(separator: "/")) \(key)"
                }
            }
        }
        XCTAssertGreaterThan(closestPair, 2 * tolerance, """
            \(closestIs) — two plants a rule compares, closer to each other than twice \
            the \(tolerance) m each of them is allowed to move, so which is the taller \
            is no longer the same on every host
            """, file: file, line: line)
    }
}
