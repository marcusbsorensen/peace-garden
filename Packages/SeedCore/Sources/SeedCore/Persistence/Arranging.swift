import Foundation

/// Where a plant stands, and how a garden is arranged.
///
/// All of it is **told** rather than inherited, in the sense `docs/PLACE.md`
/// gives those words: local, optional, absent from `ExchangePayload`, and unable
/// to reach a seed. Where a plant stands is a fact about the person, not about
/// the plant, so two gardeners holding the same plant may stand it in quite
/// different places — the same property as two gardeners remembering one meeting
/// by two different names.
///
/// See `docs/ARRANGING.md` for the whole of the reasoning.

// MARK: - Where a plant stands

/// Metres from the middle of the plot, on the two ground axes.
///
/// **Not a fraction of the plot's width**, and that is the one thing about this
/// type worth knowing. The plot grows as the garden does (`Garden.plotSide`), so
/// a fraction would spread the whole garden apart every time somebody met a
/// stranger. Metres keep every plant exactly where it was put and let the new
/// ground appear at the edge — which is why the oldest plants end up at the
/// heart of a garden and the newest at its rim, as they do in a real one.
public struct Spot: Codable, Equatable, Sendable {
    public var x: Double
    public var z: Double

    public init(x: Double, z: Double) {
        self.x = x
        self.z = z
    }
}

/// How a bed arranges the plants nobody has placed by hand.
///
/// The raw values are **the file format**: a garden on disk names its template
/// by this string, so renaming a case silently drops every bed that used it back
/// to the default. Add cases freely; do not rename them.
public enum Template: String, Codable, CaseIterable, Sendable {
    /// The site's own map of ten areas, so a plant stands in The Crossing on the
    /// phone and in The Crossing on the web.
    case thematic
    /// Midnight to noon and back, off `Genome.Tempo.opensByDay` — the trait, and
    /// never the genus head, which carries a mood rather than a behaviour.
    case nightAndDay = "nightAndDay"
    /// Palette hue, swept into drifts.
    case colours
    /// Oldest to newest: a walk through the meetings in order.
    case meetings
    /// Plants sharing a parent stand together.
    case kinship
}

// MARK: - A bed

/// One arrangement of the whole garden.
///
/// A bed holds a template and **only the plants somebody moved by hand**. That
/// sparseness is the design rather than an optimisation:
///
/// - a plant grown tomorrow appears in every bed without being placed, where its
///   template says it goes;
/// - changing the template re-flows everything except what was placed on
///   purpose;
/// - putting one back is removing an entry, and resetting the bed is emptying
///   the dictionary.
public struct Bed: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    public var template: Template

    /// Keyed by `PlantRecord.id.uuidString`, and that is deliberate.
    ///
    /// `JSONEncoder` writes a dictionary whose key is neither `String` nor `Int`
    /// as a **flat array of alternating keys and values**, not as an object. A
    /// `[UUID: Spot]` would encode to
    /// `["9F2C…", {"x":1,"z":2}, "A81B…", {"x":3,"z":4}]`, which round-trips
    /// through Swift and is unreadable to anything else that ever has to look at
    /// a garden file. Keying by the string keeps it an object.
    ///
    /// Reach it through `spot(for:)` and `place(_:at:)` rather than directly, so
    /// nothing has to remember that.
    public var placed: [String: Spot]

    /// Which ground this bed stands on, as a row in the world atlas.
    ///
    /// **Told, not inherited.** Settled 18 September. The ground could have been
    /// grown from the gardener's own seed, which would have made it one more
    /// thing about them that they did not choose — and put it on the wrong side
    /// of the line `docs/PLACE.md` draws and `docs/ARRANGING.md` opens with. It
    /// sits here beside the template, with the arrangement and the note and the
    /// display name.
    ///
    /// **A number, because the worlds have no names.** A named world is
    /// forty-two translations; `docs/ARRANGING.md` records why the fiftieth world
    /// has to cost a render and nothing else. So the order of the rows in the
    /// atlas is the file format, the way the trait labels are: a world may be
    /// added at the end, and none may be reordered or removed.
    ///
    /// Optional so that nothing migrates. A bed written before this decodes as
    /// no choice, and no choice is the first world.
    public var world: Int?

    public init(
        id: UUID = UUID(),
        name: String,
        template: Template = .thematic,
        placed: [String: Spot] = [:],
        world: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.template = template
        self.placed = placed
        self.world = world
    }

    public func spot(for plant: PlantRecord) -> Spot? {
        placed[plant.id.uuidString]
    }

    public mutating func place(_ plant: PlantRecord, at spot: Spot) {
        placed[plant.id.uuidString] = spot
    }

    /// Hands one plant back to the template.
    public mutating func putBack(_ plant: PlantRecord) {
        placed.removeValue(forKey: plant.id.uuidString)
    }

    /// Hands every plant back to the template.
    public mutating func reset() {
        placed.removeAll()
    }

    /// Drops placements for plants the garden no longer holds.
    ///
    /// A spot pointing at a plant that has gone decodes perfectly well and draws
    /// nothing, which is the kind of fault that survives every test and shows up
    /// as a garden that is quietly one plant short.
    public mutating func forget(absentFrom plants: [PlantRecord]) {
        let alive = Set(plants.map(\.id.uuidString))
        placed = placed.filter { alive.contains($0.key) }
    }
}

// MARK: - The plot

extension Garden {
    /// Every bed, or the one every garden starts with.
    ///
    /// `beds` is optional on disk so that a file written before this existed
    /// decodes as a garden with no beds rather than as a failure; this is what
    /// the rest of the app reads, so nothing else has to know that.
    public var arrangements: [Bed] {
        if let beds, !beds.isEmpty { return beds }
        return [Bed(name: "", template: .thematic)]
    }

    /// The smallest plot, in metres: what a garden of one or two plants stands on.
    public static let smallestPlot = 2.2

    /// Roughly the ground one plant wants to itself, squared.
    ///
    /// Fixed against the mockup: fourteen plants on a 5.2 m plot read as a
    /// garden with room to walk in it, so `5.2 / sqrt(14)`.
    public static let plotPerPlant = 1.39

    /// How wide the plot is, in metres.
    ///
    /// **It grows with the garden**, so its size is a record of how many people
    /// you have met with no number anywhere.
    ///
    /// The side goes as the *square root* of the count, because what each plant
    /// wants is an area rather than a width. Growing the side in proportion to
    /// the count would quadruple the ground for twice the plants and leave a
    /// large garden looking abandoned.
    public var plotSide: Double {
        max(Self.smallestPlot, Self.plotPerPlant * Double(hybrids.count).squareRoot())
    }

    /// Whether a spot is on the plot at all.
    ///
    /// The plot only ever grows, so this can go from false to true and never the
    /// other way — nothing that has been placed can be stranded by it.
    public func holds(_ spot: Spot) -> Bool {
        let half = plotSide / 2
        return abs(spot.x) <= half && abs(spot.z) <= half
    }
}
