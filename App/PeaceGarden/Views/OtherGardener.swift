import SwiftUI
import SeedCore

/// The other gardener of a meeting, in the sentences that name them.
///
/// **A sentence of its own when there is no name.** A meeting's note can be
/// without a name, and until 12 October these sentences put the phrase *the
/// other gardener* where the name goes. A phrase in a slot cannot change the
/// words around it: Italian came out as *Chiedi a l'altra persona* and *In
/// attesa di l'altra persona*, where it has to elide to *all'* and *dell'*;
/// Swedish as *trädgårdsmästaren:s*, a name's genitive on a noun; and English
/// opened sentences with a small *the*. So each sentence is two keys, one with
/// the name and one without, and a translator writes each of them whole.
///
/// The phrase on its own stays a key, for the one place it is still a list
/// item rather than a sentence: `PlotView.gardenersAsking`.
struct OtherGardener {
    /// The name the other phone gave, or `nil` when there is none to say.
    ///
    /// A blank counts as none, as it does under a tile in the grid
    /// (`GardenGridView.caption`): a sentence with an empty slot reads as
    /// *Ask* and nothing after it.
    let name: String?

    init(name: String?) {
        let blank = name?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true
        self.name = blank ? nil : name
    }

    init(_ record: PlantRecord) {
        self.init(name: record.encounter?.peerDisplayName)
    }

    /// The button that puts the question to them (`ShowInGardenView`).
    var ask: LocalizedStringKey {
        guard let name else { return "Ask the other gardener" }
        return "Ask \(name)"
    }

    /// A plant offered to the public website garden, still unanswered
    /// (`PlantDetailView`).
    var waitingOn: LocalizedStringKey {
        guard let name else { return "Waiting on the other gardener" }
        return "Waiting on \(name)"
    }

    /// They released their copy into the Wild Fields (`PlantDetailView`).
    var letItGo: LocalizedStringKey {
        guard let name else { return "The other gardener let it go into the Wild Fields" }
        return "\(name) let it go into the Wild Fields"
    }

    /// The headline when they are the one asking (`ShowInGardenView`).
    var wouldLikeItShown: LocalizedStringKey {
        guard let name else { return "The other gardener would like this plant to stand in the public website garden." }
        return "\(name) would like this plant to stand in the public website garden."
    }

    /// When the plant's area is not planted yet (`ShowInGardenView`).
    var askWhenTheAreaOpens: LocalizedStringKey {
        guard let name else { return "It goes on growing here meanwhile, and you can ask the other gardener the day its area opens." }
        return "It goes on growing here meanwhile, and you can ask \(name) the day its area opens."
    }

    /// Why both of them are asked (`ShowInGardenView`): said to the one being
    /// asked, or to the one asking.
    func grewFromBoth(beingAsked: Bool) -> LocalizedStringKey {
        switch (name, beingAsked) {
        case (nil, true):
            return "It grew from your seed and the other gardener's together, so the garden carries both. That is why you are being asked."
        case (nil, false):
            return "It grew from your seed and the other gardener's together, so the garden carries both. They are asked before it goes anywhere."
        case (let name?, true):
            return "It grew from your seed and \(name)'s together, so the garden carries both. That is why you are being asked."
        case (let name?, false):
            return "It grew from your seed and \(name)'s together, so the garden carries both. They are asked before it goes anywhere."
        }
    }
}
