#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

/// The ten areas of the shared garden, and which of them a plant can stand in
/// today. `docs/WEB-GARDENS.md`.
///
/// **An area is a theme with a layout.** The themes are the app's — a plant's
/// comes from its genus head, and the same ten order the passages — and each
/// one is laid out as the kind of garden its name is: the Knot Garden as a
/// knot garden, the Orchard on a quincunx, the Long Walk as a double border
/// either side of a mown path. The layout is the one that kind of garden has
/// always had, which is the whole of what best practice means here.
///
/// **This type exists because the service needed to be able to say no.** Until
/// now the plot service was a Long Walk service: one table, one rule, and a
/// plant went into it whatever it was. A garden of ten areas can only be built
/// one area at a time, so there has to be somewhere that says which ones are
/// finished — and a gardener whose plant belongs to an unbuilt one has to be
/// told that, rather than having it quietly put somewhere else.
///
/// It lives in SeedCore so the phone, the website and the plot service read one
/// list. `Server/.api/Areas.php` is the port and `tools/reference/check_areas.php`
/// holds it to this.
public enum Area: String, CaseIterable, Sendable, Codable {
    case beginnings, waiting, renewal, light, pattern
    case ground, travel, meeting, kinship, peace

    /// **Whether a plant can stand here yet.**
    ///
    /// One of ten. The Long Walk was built first because its rule is the
    /// plainest best practice there is — tall at the back, drifts, repetition —
    /// and because its plots open end to end, so the map is a line before it
    /// has to be a shape (`docs/WEB-GARDENS.md` §*What has to exist first*).
    ///
    /// **An area is open when it has a placement rule, not when it has a
    /// name.** All ten have names, layouts on paper and a place on the map.
    /// What the other nine do not have is a rule that says which slot an
    /// arriving plant takes and never moves it, which is what makes a garden
    /// curated rather than scattered.
    public var isOpen: Bool { self == .travel }

    /// The areas a plant can be offered to today.
    public static var open: [Area] { allCases.filter(\.isOpen) }

    /// What the service calls this area's plantings.
    ///
    /// **A table for each, rather than one table with an area column.** Two
    /// reasons, and the second is the one that decided it. A table of plantings
    /// with an `area` column would hold rows whose meaning depends on that
    /// column — `plot`, `side`, `tier` and `slot_index` mean a double border on
    /// a travel row and would mean a compartment and a quarter on a knot garden
    /// row — which is a table pretending to be ten tables. And the Long Walk's
    /// table is **live and append-only**: adding a column to it is a migration
    /// against real plantings, where adding an area is a new table beside it
    /// and cannot touch what is already planted.
    public var table: String {
        switch self {
        case .travel: return "long_walk"
        // The nine that are not open have no table, and a name for one here
        // would be a promise about a schema nobody has designed. They get one
        // when they get a rule.
        default: return ""
        }
    }

    /// **An area this version has never heard of reads as the Long Walk.**
    ///
    /// The same rule `Standing` follows and for the same reason: a payload
    /// written by a newer version must decode rather than throw, or one unknown
    /// word discards whatever it was part of. The fallback is the Long Walk
    /// because that is what an absent area means to the service too — one rule
    /// in two places rather than two that can differ.
    ///
    /// It is a fallback and not a guess: an area named here and unknown to this
    /// build is an area built after it, and a phone that cannot place a plant
    /// is better off treating it as the one area that has always existed than
    /// refusing to read the record at all.
    public init(from decoder: any Decoder) throws {
        let named = try decoder.singleValueContainer().decode(String.self)
        self = Area(rawValue: named) ?? .travel
    }
}
