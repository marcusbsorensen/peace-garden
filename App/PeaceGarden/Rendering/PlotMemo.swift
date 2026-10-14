import CoreGraphics
import Foundation
import SeedCore

/// A plant, where it stands, and whether it has anything to say.
struct PlotStanding: Identifiable {
    let record: PlantRecord
    /// Worked out once and carried, because building one is a few hundred
    /// hashes and everything drawn of a plant starts from it.
    let genome: Genome
    let spot: Spot
    var growth: GrowthModel.State
    var announces: Bool

    var id: UUID { record.id }
}

/// Where the plant or the light in hand is, moved on every frame of a drag
/// (14 October 2026).
///
/// **Read only by what is in hand.** The foot used to be in `PlotView`'s own
/// state, so every frame of a carried plant worked the screen out again, and
/// with it every plant and every shadow: 20 ms a frame at five hundred plants
/// even with everything else kept. Here only the plant or light in hand, and
/// its shadow, read it, so a drag moves those and nothing else.
@Observable
@MainActor
final class PlotHand {
    /// Where the foot of the plant in hand is, in the plot's own unzoomed points.
    var plantFoot: CGPoint = .zero
    /// The same for a light.
    var lampFoot: CGPoint = .zero
}

/// What the plot works out from the garden, kept from one frame to the next
/// (14 October 2026).
///
/// **Every frame used to work the whole garden out again.** A pan, a pinch, a
/// carried plant and the clock's every tick each asked every plant for its
/// genome — a few hundred SHA-256 hashes — two or three times over: once for
/// where the arrangement puts it, once for how grown it is, once to be drawn.
/// Measured with `sample` on a garden of a hundred, that was 86% of the main
/// thread and 110 ms a frame; 590 ms at five hundred. None of it changes while
/// the garden is being looked at. So it is kept here and worked out again only
/// when something it depends on has changed: the plants, the bed, the plot's
/// side, the person; how grown they are once the clock has moved a minute
/// (growth is in hours and days, and a picture only changes at a step of it);
/// what has been seen; and the near-to-far order when the plot turns or a plant
/// is lifted.
///
/// **A big garden's genomes are worked out off the main thread** the first
/// time it opens, a few hundred at once across the phone's cores, and the
/// plants stand on the plot as soon as they are known. A small garden's are
/// worked out on the spot, so it opens with its plants in it.
@Observable
@MainActor
final class PlotMemo {

    /// Bumped when genomes worked out off the main thread arrive. Read by
    /// `standings`, so the plot is drawn again when they do.
    private(set) var arrived = 0

    /// Counts every change to what `standings` hands back, so what is drawn
    /// from them can be kept until it changes (`PlotView`'s `Unchanged`).
    @ObservationIgnored private(set) var revision = 0

    /// How many genomes are worked out on the main thread before it hands
    /// the rest over: about ten milliseconds' worth.
    @ObservationIgnored static let inline = 48

    @ObservationIgnored private var genomes: [UUID: (seed: SeedID, genome: Genome)] = [:]
    @ObservationIgnored private var working = false

    private struct Layout: Equatable {
        let plants: [PlantRecord]
        let bed: Bed?
        let plotSide: Double
        let mine: SeedID?
    }

    private struct Order: Equatable {
        let view: Isometric
        let held: UUID?
    }

    @ObservationIgnored private var layout: Layout?
    @ObservationIgnored private var placed: [PlotStanding] = []
    @ObservationIgnored private var grownAt: Date?
    @ObservationIgnored private var seenRevision = -1
    @ObservationIgnored private var order: Order?
    @ObservationIgnored private var ordered: [PlotStanding] = []

    /// How far the clock moves before growth is asked again.
    @ObservationIgnored static let growthInterval: TimeInterval = 60

    /// Whether this one has said the garden is open, so it says it has closed.
    @ObservationIgnored private nonisolated(unsafe) var isOpen = false

    init() {}

    /// The garden is on screen: see `GardenSprites.opened()`.
    func open() {
        guard !isOpen else { return }
        isOpen = true
        GardenSprites.shared.opened()
    }

    /// Everything the garden kept while it was open is let go of with it.
    deinit {
        guard isOpen else { return }
        Task { @MainActor in GardenSprites.shared.closed() }
    }

    // MARK: Where everything stands

    /// Every plant with a place on the plot, far to near — except the one in
    /// hand, which is drawn last, above everything until it is put down.
    func standings(garden: Garden, plotSide: Double, now: Date, view: Isometric,
                   held: UUID?, visits: GardenVisits) -> [PlotStanding] {
        _ = arrived
        let seen = visits.revision
        let wanted = Layout(plants: garden.plants, bed: garden.arrangements.first,
                            plotSide: plotSide, mine: garden.identity?.seed)

        if wanted != layout {
            guard lay(wanted, now: now, visits: visits) else { return [] }
        }
        if let grownAt, abs(now.timeIntervalSince(grownAt)) < Self.growthInterval, seen == seenRevision {
            // Still as grown as it was.
        } else {
            grow(now: now, visits: visits)
        }
        let wantedOrder = Order(view: view, held: held)
        if wantedOrder != order {
            ordered = placed.sorted { a, b in
                if a.id == held { return false }
                if b.id == held { return true }
                return view.depth(a.spot) < view.depth(b.spot)
            }
            order = wantedOrder
            revision += 1
        }
        return ordered
    }

    /// How grown every plant is, and whether it has grown since it was last
    /// looked at.
    private func grow(now: Date, visits: GardenVisits) {
        for index in placed.indices {
            let standing = placed[index]
            let growth = GrowthModel(genome: standing.genome).state(birth: standing.record.birth, now: now)
            placed[index].growth = growth
            placed[index].announces = visits.announces(standing.record, growth: growth)
        }
        grownAt = now
        seenRevision = visits.revision
        order = nil
    }

    /// The arrangement, with anything moved by hand standing where it was put.
    /// False while the genomes it needs are still being worked out.
    private func lay(_ wanted: Layout, now: Date, visits: GardenVisits) -> Bool {
        let plants = wanted.plants.filter(\.isHybrid).sorted { $0.savedAt > $1.savedAt }
        let missing = plants.filter { genomes[$0.id]?.seed != $0.seed }
        if missing.count > Self.inline {
            workOut(missing)
            return false
        }
        for record in missing { genomes[record.id] = (record.seed, record.genome) }

        let known = self.genomes
        let laidOut = Arrangement.spots(
            for: plants,
            template: wanted.bed?.template ?? .thematic,
            plotSide: wanted.plotSide,
            mine: wanted.mine,
            genome: { known[$0.id]?.genome ?? $0.genome }
        )
        // A hand placement made before the rim wandered may be past it; it is
        // shown on the ground, and kept as it was until it is moved again.
        let outline = PlotOutline.of(plotSide: wanted.plotSide)
        placed = plants.compactMap { record -> PlotStanding? in
            guard let spot = wanted.bed?.spot(for: record).map({ outline.keepOn($0) }) ?? laidOut[record.id],
                  let genome = known[record.id]?.genome
            else { return nil }
            let growth = GrowthModel(genome: genome).state(birth: record.birth, now: now)
            return PlotStanding(record: record, genome: genome, spot: spot, growth: growth,
                                announces: visits.announces(record, growth: growth))
        }
        layout = wanted
        grownAt = now
        seenRevision = visits.revision
        order = nil
        return true
    }

    /// A genome already worked out, or worked out now.
    func genome(of record: PlantRecord) -> Genome {
        if let held = genomes[record.id], held.seed == record.seed { return held.genome }
        let genome = record.genome
        genomes[record.id] = (record.seed, genome)
        return genome
    }

    private func workOut(_ records: [PlantRecord]) {
        guard !working else { return }
        working = true
        Task {
            let made = await Self.genomes(of: records)
            for (id, seed, genome) in made { genomes[id] = (seed, genome) }
            working = false
            arrived += 1
        }
    }

    /// Genomes in parallel, a slice to each core.
    private nonisolated static func genomes(of records: [PlantRecord]) async -> [(UUID, SeedID, Genome)] {
        let slices = max(1, min(8, ProcessInfo.processInfo.activeProcessorCount))
        let size = (records.count + slices - 1) / slices
        return await withTaskGroup(of: [(UUID, SeedID, Genome)].self) { group in
            for start in stride(from: 0, to: records.count, by: max(1, size)) {
                let slice = Array(records[start..<min(records.count, start + size)])
                group.addTask(priority: .userInitiated) {
                    slice.map { ($0.id, $0.seed, $0.genome) }
                }
            }
            var all: [(UUID, SeedID, Genome)] = []
            for await part in group { all += part }
            return all
        }
    }
}
