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

    public var full: String { "\(genus) \(epithet)" }
    public var description: String { full }

    static let genusHeads = [
        "Ael", "Aur", "Bel", "Cal", "Cer", "Cyn", "Dros", "El", "Fen", "Hal",
        "Ith", "Lir", "Mel", "Nyx", "Ol", "Pell", "Quin", "Ros", "Sel", "Thal",
        "Umbr", "Ver", "Wyn", "Zeph"
    ]

    static let genusMiddles = [
        "a", "an", "ar", "er", "i", "in", "is", "o", "or", "yr", "ell", "ess", "ol", "un"
    ]

    static let genusTails = [
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

        let epithetHead = source.pick("name.epithetHead", from: Self.epithetHeads)
        let epithetTail = source.pick("name.epithetTail", from: Self.epithetTails)
        epithet = Self.join(epithetHead, "", epithetTail).lowercased()
    }

    public init(genus: String, epithet: String) {
        self.genus = genus
        self.epithet = epithet
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
