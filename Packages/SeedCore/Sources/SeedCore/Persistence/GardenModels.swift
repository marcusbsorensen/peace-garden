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

/// What a person chose to remember about the meeting that made a plant.
///
/// Everything except the other person's display name is optional and entered
/// by hand: no location permission, no automatic capture. A meeting is theirs
/// to describe or leave blank.
public struct EncounterNote: Codable, Equatable, Sendable {
    public var peerDisplayName: String
    public var happenedAt: Date
    /// Whether to show the date and time alongside the plant.
    public var showsDateTime: Bool
    /// A place, if they typed one. Never derived from the device's location.
    public var place: String?
    /// A short line about the encounter.
    public var note: String?

    public static let noteCharacterLimit = 240

    public init(
        peerDisplayName: String,
        happenedAt: Date,
        showsDateTime: Bool = true,
        place: String? = nil,
        note: String? = nil
    ) {
        self.peerDisplayName = peerDisplayName
        self.happenedAt = happenedAt
        self.showsDateTime = showsDateTime
        self.place = place
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
