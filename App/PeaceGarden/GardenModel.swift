import Foundation
import Observation
import SeedCore

/// Everything the app knows: the person's seed, the plants they have kept, and
/// what time it is for the purpose of growing.
@Observable
@MainActor
final class GardenModel {
    private(set) var garden: Garden
    private(set) var loadError: String?

    /// Ticked on a timer so plants visibly move on without every view holding
    /// its own clock.
    private(set) var now: Date = Date()

    private let store: GardenStore
    private var clock: Task<Void, Never>?

    /// Growth is measured in hours and days, so a slow tick is plenty and
    /// leaves the battery alone.
    private static let tickInterval: Duration = .seconds(20)

    init(store: GardenStore) {
        self.store = store
        do {
            garden = try store.load()
        } catch {
            garden = Garden()
            loadError = error.localizedDescription
        }
        startClock()
    }

    convenience init() {
        let store: GardenStore
        var failure: String?
        do {
            store = try GardenStore.defaultStore()
        } catch {
            // Falling back to a temporary file keeps the app usable rather than
            // dead on launch; the banner tells the person their garden will not
            // survive being closed.
            store = GardenStore(
                fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("garden.json")
            )
            failure = "This garden cannot be saved on this device: \(error.localizedDescription)"
        }
        self.init(store: store)
        if let failure { loadError = failure }
    }

    var identity: Identity? { garden.identity }
    var hasIdentity: Bool { garden.identity != nil }
    var hybrids: [PlantRecord] { garden.hybrids }

    // MARK: - Identity

    /// Mints this person's seed. Called once, on first launch.
    func mintIdentity(displayName: String) {
        guard garden.identity == nil else { return }
        let name = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        garden.identity = Identity(
            seed: SeedMint.mintOnThisDevice(),
            birth: Date(),
            displayName: name.isEmpty ? "Gardener" : name
        )
        persist()
    }

    func rename(to displayName: String) {
        guard var identity = garden.identity else { return }
        let name = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        identity.displayName = name
        garden.identity = identity
        persist()
    }

    // MARK: - Plants

    func growth(for genome: Genome, birth: Date) -> GrowthModel.State {
        GrowthModel(genome: genome).state(birth: birth, now: now)
    }

    func ownPlantGrowth() -> GrowthModel.State? {
        guard let identity else { return nil }
        return growth(for: identity.genome, birth: identity.birth)
    }

    @discardableResult
    func save(outcome: ExchangeOutcome, note: EncounterNote) -> PlantRecord {
        let record = PlantRecord(
            seed: outcome.result.childSeed,
            lineage: outcome.result.lineage,
            birth: outcome.happenedAt,
            savedAt: Date(),
            encounter: note
        )
        garden.plants.append(record)
        persist()
        return record
    }

    func delete(_ record: PlantRecord) {
        garden.plants.removeAll { $0.id == record.id }
        persist()
    }

    /// Has this exact plant already been kept? Guards against a double tap on
    /// Keep growing this plant.
    func contains(seed: SeedID) -> Bool {
        garden.plants.contains { $0.seed == seed }
    }

    // MARK: - Plumbing

    private func persist() {
        do {
            try store.save(garden)
            loadError = nil
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func startClock() {
        clock?.cancel()
        clock = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: Self.tickInterval)
                guard let self else { return }
                self.now = Date()
            }
        }
    }

    func refreshNow() {
        now = Date()
    }
}
