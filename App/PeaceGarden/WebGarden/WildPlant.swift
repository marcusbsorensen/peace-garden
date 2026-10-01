import Foundation
import SeedCore

/// One plant this person grew that stands in the Wild Fields, as the screen
/// that says what stands beside it reads it (`WildBesideView`).
///
/// **Two ways to be one.** The other gardener released it, and this phone
/// still has its copy (`PlantRecord.wild`); or this phone released it, and
/// kept a note so it can change its mind (`Garden.released`). The screen is
/// the same for both — the same three choices, asked the same way — and only
/// its first sentence differs, so the two are one value here.
struct WildPlant: Identifiable, Equatable {
    /// The record's id, or the note's.
    let id: UUID
    let seed: SeedID
    let lineage: Lineage
    let birth: Date
    let tokens: MeetingTokens
    /// The other gardener, as this phone knows them.
    let peerDisplayName: String
    /// This phone's own account of where and when, which is what it sends.
    let place: String?
    let happenedAt: Date
    /// What the service last said, or nil before it has said anything.
    let notice: WildNotice?
    /// Whether this phone let it go.
    let releasedHere: Bool

    var genome: Genome { Genome(seed: seed, lineage: lineage) }

    /// What this person has chosen, as the service last said it.
    var choice: WildChoice { notice?.yours ?? .none }

    init(released: ReleasedPlant) {
        id = released.id
        seed = released.seed
        lineage = released.lineage
        birth = released.birth
        tokens = released.tokens
        peerDisplayName = released.peerDisplayName
        place = released.place
        happenedAt = released.happenedAt
        notice = released.notice
        releasedHere = true
    }

    /// Nil for a plant nobody released, or one with no meeting to speak of.
    init?(record: PlantRecord) {
        guard let wild = record.wild, let tokens = record.tokens, let encounter = record.encounter
        else { return nil }
        id = record.id
        seed = record.seed
        lineage = record.lineage
        birth = record.birth
        self.tokens = tokens
        peerDisplayName = encounter.peerDisplayName
        place = encounter.place
        happenedAt = encounter.happenedAt
        notice = wild.notice
        releasedHere = false
    }

    /// Where it stands, on the website: `/wild`, opened over this plant. The
    /// first twelve characters of the seed, as a postcard carries them, and
    /// the first eight of those are where it stands (`WildFields.spot`), so
    /// the page needs nothing else to go there.
    func address(on origin: URL) -> URL {
        var parts = URLComponents(url: origin.appending(path: "/wild"), resolvingAgainstBaseURL: false)
        parts?.fragment = "p=" + String(seed.hex.prefix(12))
        return parts?.url ?? origin
    }
}
