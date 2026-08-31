import Foundation

/// The person's own seed, minted once on first launch and kept for good.
public struct Identity: Codable, Equatable, Sendable {
    public var seed: SeedID
    /// When the seed was minted. Doubles as the plant's birthday.
    public var birth: Date
    /// Shown to the other person during an exchange. Free text, theirs to choose.
    public var displayName: String

    public init(seed: SeedID, birth: Date, displayName: String) {
        self.seed = seed
        self.birth = birth
        self.displayName = displayName
    }

    public var genome: Genome { Genome(seed: seed, lineage: .minted) }
}

/// Where on earth a meeting happened, when both people asked for it to be kept.
///
/// Plain numbers rather than `CLLocationCoordinate2D`, because `SeedCore` builds
/// on Linux and is tested there. Rounded to five decimal places, which is about
/// a metre: enough to find the spot again, and short of pretending to a
/// precision that a phone in a street does not have.
///
/// No place name is stored and none is looked up. Naming a spot means a request
/// to somebody's geocoder, and the app makes no network request at all; a
/// coordinate is also the honest record of what was actually measured. It is
/// shown as numbers, and opens in a map only if the person taps it.
public struct Coordinate: Codable, Equatable, Sendable {
    public var latitude: Double
    public var longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = (latitude * 100_000).rounded() / 100_000
        self.longitude = (longitude * 100_000).rounded() / 100_000
    }
}

/// What a person chose to remember about the meeting that made a plant.
///
/// Everything here is optional except the other person's name, and all of it is
/// theirs to change afterwards. A meeting can be described, left blank, or told
/// differently later, in the way a parent tells a child more of the story as
/// they grow.
///
/// The place is typed by hand or taken from the figurative set. A coordinate
/// appears only where both people asked for one at that meeting, which is a
/// deliberate reversal of the rule this type used to state. See docs/PLACE.md.
public struct EncounterNote: Codable, Equatable, Sendable {
    public var peerDisplayName: String
    public var happenedAt: Date
    /// Whether to show the date and time alongside the plant.
    public var showsDateTime: Bool
    /// What they called the place. Typed by hand, or the figurative one the app
    /// offered. Independent of `coordinate`, and of what the other person wrote.
    public var place: String?
    /// Where the meeting was, if both people asked for it to be kept.
    public var coordinate: Coordinate?
    /// A short line about the encounter.
    public var note: String?

    public static let noteCharacterLimit = 240

    public init(
        peerDisplayName: String,
        happenedAt: Date,
        showsDateTime: Bool = true,
        place: String? = nil,
        coordinate: Coordinate? = nil,
        note: String? = nil
    ) {
        self.peerDisplayName = peerDisplayName
        self.happenedAt = happenedAt
        self.showsDateTime = showsDateTime
        self.place = place
        self.coordinate = coordinate
        self.note = note.map { String($0.prefix(Self.noteCharacterLimit)) }
    }
}

/// One plant in a garden.
///
/// Only the seed, its lineage and its birthday are stored — the genome, the
/// name and the geometry are all derived. A garden of a hundred plants is a
/// few kilobytes, and a saved plant can never disagree with the plant it draws.
public struct PlantRecord: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var seed: SeedID
    public var lineage: Lineage
    public var birth: Date
    public var savedAt: Date
    public var encounter: EncounterNote?

    public init(
        id: UUID = UUID(),
        seed: SeedID,
        lineage: Lineage,
        birth: Date,
        savedAt: Date = Date(),
        encounter: EncounterNote? = nil
    ) {
        self.id = id
        self.seed = seed
        self.lineage = lineage
        self.birth = birth
        self.savedAt = savedAt
        self.encounter = encounter
    }

    public var genome: Genome { Genome(seed: seed, lineage: lineage) }
    public var isHybrid: Bool { lineage.isHybrid }

    public func growth(now: Date = Date()) -> GrowthModel.State {
        GrowthModel(genome: genome).state(birth: birth, now: now)
    }
}

/// Everything held on this device.
public struct Garden: Codable, Equatable, Sendable {
    /// Bumped when the on-disk shape changes, so an older file can be migrated
    /// rather than thrown away — a person's seed is not recoverable if lost.
    public static let currentSchemaVersion = 1

    public var schemaVersion: Int
    public var identity: Identity?
    public var plants: [PlantRecord]

    public init(
        schemaVersion: Int = Garden.currentSchemaVersion,
        identity: Identity? = nil,
        plants: [PlantRecord] = []
    ) {
        self.schemaVersion = schemaVersion
        self.identity = identity
        self.plants = plants
    }

    public var hybrids: [PlantRecord] {
        plants.filter(\.isHybrid).sorted { $0.savedAt > $1.savedAt }
    }
}
