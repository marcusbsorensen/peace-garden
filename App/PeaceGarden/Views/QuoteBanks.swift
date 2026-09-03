import Foundation

/// Which bank of passages a phone reads from, and what two phones agree on when
/// they do not read the same one.
///
/// A bank is not a translation of the English one. About sixty of those three
/// hundred passages are etymologies of English words — *quiet* and *quit* are
/// one word, *daisy* is the day's eye — and those are facts about English that
/// are simply false in Dutch. Each bank is written from its own language's word
/// histories, its own literature and its own proverbs, so the four kinds are the
/// same and almost none of the lines are. `docs/LANGUAGES.md` records why that
/// had to be a commission rather than a translation job.
///
/// ## What survives two people reading different banks
///
/// The theme and the subtheme do. They are derived — the theme from the pair,
/// the subtheme from the child's own genus — and they are language-neutral,
/// because a plant's name is a synthesised Latinate binomial that reads the same
/// in Amsterdam as in Margate.
///
/// The *line* does not, and should not. Two people meeting across languages draw
/// from the same corner of the same theme and each reads it in their own
/// language. Making the line agree as well would mean the banks had to be
/// parallel translations of each other, which is the one thing they must not be.
/// So what a pair holds in common is the character of the passage rather than
/// its words, which is what the split was always for.
///
/// ## A language arrives with an interface first and a bank later
///
/// Every time. Spanish shipped for a while with a localised interface and no
/// bank of its own, reading English lines and saying so under the passage —
/// which is `isBorrowed`, and why that mechanism exists before the twenty-five
/// languages of round two need it. Adding a bank is a case here and a line in
/// `passages`.
enum QuoteBank: String, CaseIterable, Sendable {
    case english = "en"
    case dutch = "nl"
    case danish = "da"
    case french = "fr"
    case spanish = "es"
    case norwegian = "nb"
    case swedish = "sv"
    case italian = "it"
    case german = "de"
    case portuguese = "pt"
    case turkish = "tr"
    case polish = "pl"
    case czech = "cs"
    case hungarian = "hu"
    case romanian = "ro"
    case finnish = "fi"
    case catalan = "ca"
    case estonian = "et"
    case lithuanian = "lt"
    case slovene = "sl"
    case latvian = "lv"
    case ukrainian = "uk"
    case slovak = "sk"
    case welsh = "cy"
    case basque = "eu"
    case galician = "gl"
    case serbian = "sr"
    case japanese = "ja"
    case chinese = "zh"
    case icelandic = "is"
    case irish = "ga"
    case albanian = "sq"
    case korean = "ko"
    case hebrew = "he"
    case bulgarian = "bg"
    case croatian = "hr"
    case russian = "ru"
    case arabic = "ar"
    case greenlandic = "kl"
    case greek = "el"
    case macedonian = "mk"
    case maltese = "mt"

    var passages: [Passage] {
        switch self {
        case .english: return Quotes.all
        case .dutch: return Quotes.dutch
        case .danish: return Quotes.danish
        case .french: return Quotes.french
        case .spanish: return Quotes.spanish
        case .norwegian: return Quotes.norwegian
        case .swedish: return Quotes.swedish
        case .italian: return Quotes.italian
        case .german: return Quotes.german
        case .portuguese: return Quotes.portuguese
        case .turkish: return Quotes.turkish
        case .polish: return Quotes.polish
        case .czech: return Quotes.czech
        case .hungarian: return Quotes.hungarian
        case .romanian: return Quotes.romanian
        case .finnish: return Quotes.finnish
        case .catalan: return Quotes.catalan
        case .estonian: return Quotes.estonian
        case .lithuanian: return Quotes.lithuanian
        case .slovene: return Quotes.slovene
        case .latvian: return Quotes.latvian
        case .ukrainian: return Quotes.ukrainian
        case .slovak: return Quotes.slovak
        case .welsh: return Quotes.welsh
        case .basque: return Quotes.basque
        case .galician: return Quotes.galician
        case .serbian: return Quotes.serbian
        case .japanese: return Quotes.japanese
        case .chinese: return Quotes.chinese
        case .icelandic: return Quotes.icelandic
        case .irish: return Quotes.irish
        case .albanian: return Quotes.albanian
        case .korean: return Quotes.korean
        case .hebrew: return Quotes.hebrew
        case .bulgarian: return Quotes.bulgarian
        case .croatian: return Quotes.croatian
        case .russian: return Quotes.russian
        case .arabic: return Quotes.arabic
        case .greenlandic: return Quotes.greenlandic
        case .greek: return Quotes.greek
        case .macedonian: return Quotes.macedonian
        case .maltese: return Quotes.maltese
        }
    }

    /// The bank a language has of its own, where it has one.
    ///
    /// Matched on the language alone rather than the full identifier, so `nl-BE`
    /// reads the Dutch bank — Flemish is a variety of Dutch rather than a peer,
    /// and the Dutch bank was written to carry Gezelle and *Vlaams spreekwoord*
    /// alongside the rest. Norwegian is matched on both its written standards,
    /// because a Nynorsk reader would otherwise fall to English while a bank
    /// that quotes Aasen and Vinje sits unread.
    static func bank(for identifier: String) -> QuoteBank? {
        let code = identifier.split(separator: "-").first.map(String.init)?.lowercased() ?? ""
        if code == "nn" || code == "no" { return .norwegian }
        return QuoteBank(rawValue: code)
    }

    /// What the phone is set to.
    ///
    /// Read once. iOS restarts an app when its language changes, so nothing here
    /// has to survive one changing underneath it.
    static let preferred: String =
        Locale.preferredLanguages.first ?? Locale.current.identifier

    /// The bank this phone reads.
    static let current: QuoteBank = bank(for: preferred) ?? .english

    /// Whether the reader is getting English lines on a phone set to something
    /// else.
    ///
    /// This is the case `docs/LANGUAGES.md` calls option 1: the passage screen
    /// is the one moment the app speaks at length, so it is the moment English
    /// is most conspicuous, and it is defensible only if the passage says which
    /// language it is in. Dormant for every language that has a bank, and the
    /// reason the mechanism exists before the languages that need it do.
    static let isBorrowed: Bool = bank(for: preferred) == nil
}
