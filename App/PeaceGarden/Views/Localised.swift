import Foundation
import SeedCore

/// The words the app puts on things `SeedCore` only has names for.
///
/// `SeedCore` is a model package with no interface in it and no bundle of its
/// own worth localising: its `displayName`s are English identifiers for a stage
/// and a plant form, useful in a log and in the developer panel, and they are
/// left exactly as they are. Everything a person reads is looked up here
/// instead, against the app's `Localizable.xcstrings`, so there is one
/// catalogue rather than one per package.
///
/// Written as a `switch` over literals rather than as a table keyed on
/// `displayName`, so that the compiler extracts each string and a translator
/// sees them all. A lookup built from a runtime string extracts nothing.

// MARK: - What a plant is doing

extension GrowthModel.Stage {
    var label: LocalizedStringResource {
        switch self {
        case .germinating: return "Germinating"
        case .seedling: return "Seedling"
        case .growing: return "Growing"
        case .budding: return "In bud"
        case .blooming: return "In bloom"
        case .mature: return "Mature"
        }
    }
}

extension GrowthModel.State {
    /// The caption under a plant: what it is doing, and how long until it does
    /// the next thing.
    ///
    /// **The stage is no longer lowercased on its way in.** It used to be —
    /// `summary()` in `SeedCore` still does it — which was invisible here
    /// because every site that draws this caption puts it through
    /// `chromeLabel`, and that uppercases. It stops being invisible in a
    /// language that writes its nouns with a capital, or one that is on
    /// `Chrome.keepsWrittenCase` and is not uppercased at all. The stage
    /// arrives in the case its translator wrote it in.
    ///
    /// The interval is `DateComponentsFormatter`'s, which is localised by the
    /// system: nothing here has to know that Dutch says *3 dagen*.
    func caption(formatter: DateComponentsFormatter = .growthDefault) -> String {
        let stageName = String(localized: stage.label)
        guard let timeToNextStage, stage != .mature else { return stageName }
        let remaining = formatter.string(from: max(60, timeToNextStage)) ?? ""
        return String(
            localized: "stage.caption",
            defaultValue: "\(stageName) · \(remaining)",
            comment: "Under a plant. First the growth stage, then how long until the next one."
        )
    }
}

// MARK: - What kind of plant it is

extension Archetype {
    var label: LocalizedStringResource {
        switch self {
        case .spire: return "Spire"
        case .umbel: return "Umbel"
        case .fern: return "Fern"
        case .orchid: return "Orchid"
        case .lotus: return "Lotus"
        case .thistle: return "Thistle"
        case .vine: return "Vine"
        case .bell: return "Bell"
        case .star: return "Star"
        case .poppy: return "Poppy"
        case .succulent: return "Succulent"
        case .plume: return "Plume"
        }
    }
}
