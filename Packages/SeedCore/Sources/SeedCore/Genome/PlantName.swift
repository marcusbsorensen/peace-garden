import Foundation

/// A binomial name for a plant, built from the same gene draws as its body.
///
/// Because names come from `GeneSource`, a hybrid inherits its name the way it
/// inherits everything else: usually one parent's genus with the other's
/// epithet, occasionally something new. Two people who cross their plants can
/// see the descent in the name without being told about it.
public struct PlantName: Equatable, Codable, Sendable, CustomStringConvertible {
    public let genus: String
    public let epithet: String

    /// The syllable the genus was built from, kept rather than recovered.
    ///
    /// It could be found again by matching the genus against `genusHeads`, and
    /// that would work — every head ends in a consonant, so `join` never eats
    /// one and the head survives as an exact prefix. It would also be a
    /// coincidence that had to keep being true. Something reading meaning off
    /// the head should not depend on a spelling rule holding for syllables
    /// nobody has added yet.
    ///
    /// Never stored. A `Genome` is derived from a seed and a lineage every
    /// time, so nothing on disk has to know this exists.
    public let genusHead: String
    /// The ending, likewise. See `Quotes.Subtheme` for what it carries.
    public let genusTail: String

    public var full: String { "\(genus) \(epithet)" }
    public var description: String { full }

    /// **Frozen.** `GeneSource.pick` indexes by `unit(label) * count`, so
    /// adding one syllable here renames every plant on every phone — a
    /// twenty-fifth head would shift the boundaries between all twenty-four.
    /// The list is the file format as surely as the trait labels are.
    ///
    /// Each head carries a sense, and `Quotes.Theme` reads it. That mapping
    /// had to be made to fit these twenty-four rather than the other way
    /// round; see docs/NAMES-AND-THEMES.md for which head means what.
    public static let genusHeads = [
        "Ael", "Aur", "Bel", "Cal", "Cer", "Cyn", "Dros", "El", "Fen", "Hal",
        "Ith", "Lir", "Mel", "Nyx", "Ol", "Pell", "Quin", "Ros", "Sel", "Thal",
        "Umbr", "Ver", "Wyn", "Zeph"
    ]

    static let genusMiddles = [
        "a", "an", "ar", "er", "i", "in", "is", "o", "or", "yr", "ell", "ess", "ol", "un"
    ]

    /// Frozen for the same reason as `genusHeads`, and read the same way:
    /// the ending says which of a theme's three subthemes a plant belongs to.
    public static let genusTails = [
        "ia", "is", "a", "ea", "ina", "ora", "yne", "era", "ula", "ynth"
    ]

    static let epithetHeads = [
        "noct", "vesper", "lum", "umbr", "sol", "aur", "glaci", "pluvi", "stell",
        "sylv", "mont", "riv", "cine", "ferr", "pall", "seren", "tacit", "viv"
    ]

    static let epithetTails = [
        "urna", "alis", "ata", "ifolia", "escens", "iflora", "ina", "icola",
        "antha", "aria", "osa", "ula"
    ]

    init(source: GeneSource) {
        let head = source.pick("name.genusHead", from: Self.genusHeads)
        let middle = source.chance("name.hasMiddle", 0.45)
            ? source.pick("name.genusMiddle", from: Self.genusMiddles)
            : ""
        let tail = source.pick("name.genusTail", from: Self.genusTails)
        genus = Self.join(head, middle, tail)
        genusHead = head
        genusTail = tail

        let epithetHead = source.pick("name.epithetHead", from: Self.epithetHeads)
        let epithetTail = source.pick("name.epithetTail", from: Self.epithetTails)
        epithet = Self.join(epithetHead, "", epithetTail).lowercased()
    }

    /// For a name written by hand rather than drawn.
    ///
    /// The head and the ending are read back off the spelling, and fall back to
    /// the first of each when they cannot be, so a hand-made name still lands
    /// in a theme rather than in nothing at all.
    ///
    /// **The ending is searched in what is left after the head**, which is not
    /// fussiness. Take *Cera*: the longest ending that fits its last letters is
    /// `era`, and the answer is `a`, because `Cer` has already spoken for the
    /// C, the e and the r. Searching the whole word puts three of the twenty-
    /// four heads — Cer, Quin and Ver — in the wrong third of their own theme
    /// whenever they take the shortest ending. `ThemeMappingTests` found it;
    /// nothing on screen would have.
    ///
    /// It is still a guess, and it is allowed to be. *Cerera* is honestly
    /// ambiguous — `Cer` + `er` + `a`, or `Cer` + `era` — and a drawn name
    /// never asks, because a drawn name keeps both syllables from the start.
    public init(genus: String, epithet: String) {
        self.genus = genus
        self.epithet = epithet

        let head = Self.genusHeads
            .filter { genus.hasPrefix($0) }
            .max(by: { $0.count < $1.count }) ?? Self.genusHeads[0]
        genusHead = head

        let remainder = genus.dropFirst(genus.hasPrefix(head) ? head.count : 0)
        genusTail = Self.genusTails
            .filter { $0.count <= remainder.count && remainder.hasSuffix($0) }
            .max(by: { $0.count < $1.count }) ?? Self.genusTails[0]
    }

    /// Glues syllables together without doubling a vowel at the seam, which is
    /// what makes the difference between "Aurelia" and "Aureliia".
    private static func join(_ parts: String...) -> String {
        join(Array(parts))
    }

    private static func join(_ parts: [String]) -> String {
        var result = ""
        for part in parts where !part.isEmpty {
            if let last = result.last, let first = part.first,
               isVowel(last), isVowel(first) {
                result.removeLast()
            }
            result += part
        }
        return result
    }

    private static func isVowel(_ character: Character) -> Bool {
        "aeiouyAEIOUY".contains(character)
    }
}
