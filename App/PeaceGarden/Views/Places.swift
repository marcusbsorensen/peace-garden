import Foundation
import SeedCore

/// Where a meeting happened, when nobody has said where a meeting happened.
///
/// The "Where" field on the note is offered already filled, with a figurative
/// place drawn from the child seed. It is a real answer rather than a
/// placeholder: a seed that arrives on the wind did travel, and saying so is
/// truer than leaving the line empty. Anyone who would rather record the café
/// types over it, and what they type stays on their own phone — `EncounterNote`
/// is made after the exchange and never enters `ExchangePayload`, so two people
/// at one meeting can remember it by different names.
///
/// Drawn from the child seed rather than the pair, so each meeting has its own
/// place while both phones suggest the same one. It asks for no permission,
/// stores nothing beyond what the person keeps, and sends nothing — which is
/// also why it is the only kind of place a seed arriving by link can have,
/// there being no shared moment to locate.
///
/// The register is the seed's journey rather than the earth's geography: these
/// are the places a seed passes through on the way to the ground.
enum Places {
    static let all: [String] = [
        "In the aether",
        "On the winds",
        "After the storm",
        "On a warm updraft",
        "Somewhere over the water",
        "At the edge of the map",
        "On the way to somewhere else",
        "In the drift",
        "Under an open sky",
        "On the last of the light",
        "In the quiet before rain",
        "Where the path forks",
        "At the turn of the tide",
        "Beyond the hedgerow",
        "In the long grass",
        "Between two gardens",
        "On a passing current",
        "In the gap in the hedge",
        "Adrift, and then not",
        "Where the wind dropped",
        "On the seaward side",
        "In the lee of something",
        "At the far end of a field",
        "On the thermals",
        "Where the ground rises",
        "In the shelter of a wall",
        "On the near bank",
        "Somewhere with swallows",
        "In the shade of a bigger thing",
        "Where the light came through",
        "At the top of the lane",
        "On open ground",
        "In the hour before dusk",
        "Where two paths cross",
        "On the wind off the sea",
        "In a break in the weather",
        "Between one field and the next",
        "Where the rain had been",
        "On the long way round",
        "At the edge of the wood"
    ]

    /// The place suggested for one meeting.
    ///
    /// A pure function of the child seed, so both phones offer the same place
    /// and it does not move if the note is opened again later.
    static func place(for childSeed: SeedID) -> String {
        precondition(!all.isEmpty, "the places must never be empty")
        return all[Int(deterministicFold(childSeed.bytes) % UInt64(all.count))]
    }

    /// The key behind a standing preference for one of these.
    ///
    /// Somebody who always wants "On the winds" can say so once. It changes
    /// only what the Where field arrives holding, and it stays on this phone
    /// like everything else about a note.
    static let preferredKey = "place.figurative.preferred.v1"

    /// The place this person would rather be offered, if they have chosen one.
    ///
    /// Read through `UserDefaults` rather than passed in, because it is a
    /// preference and not a property of the meeting — and because the drawn
    /// place has to stay available as the answer when nobody has chosen.
    static var preferred: String? {
        let stored = UserDefaults.standard.string(forKey: preferredKey)
        guard let stored, all.contains(stored) else { return nil }
        return stored
    }

    /// What the Where field arrives holding: the standing choice if there is
    /// one, and otherwise the place this particular seed travelled through.
    static func offered(for childSeed: SeedID) -> String {
        preferred ?? place(for: childSeed)
    }
}
