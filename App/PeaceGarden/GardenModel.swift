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

        if let pendingLink {
            self.pendingLink = nil
            try? accept(pendingLink)
        }
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

    // MARK: - Seeds by link

    /// Where a seed link points. The host has to serve an
    /// apple-app-site-association file and carry the App Clip experience;
    /// see docs/SEEDS-ON-THE-WIND.md.
    static let linkHost = "peacegarden.app"

    enum Incoming: Equatable {
        case none
        /// A seed arrived before this person had one of their own; it is held
        /// until they have drawn theirs.
        case waitingForIdentity
        case arrived(ExchangeOutcome, reply: URL?)
        case failed(String)
    }

    private(set) var incoming: Incoming = .none
    private var pendingLink: PollenLink?

    /// A link offering this person's seed, with a fresh nonce each time so two
    /// people who do this twice grow two different plants.
    func makeOffer() -> URL? {
        guard let identity else { return nil }
        let link = PollenLink(
            kind: .offer,
            seed: identity.seed,
            nonce: Pollination.makeNonce(byteCount: ExchangeProtocol.nonceByteCount),
            displayName: identity.displayName,
            plantName: identity.genome.name.full,
            birth: identity.birth
        )
        return link.url(host: Self.linkHost)
    }

    /// Handles a seed that arrived by link, from wherever.
    func receive(url: URL) {
        do {
            try accept(PollenLink.parse(url))
        } catch {
            incoming = .failed(error.localizedDescription)
        }
    }

    private func accept(_ link: PollenLink) throws {
        guard let identity else {
            // Someone opened a seed before they had one. Hold it until they
            // have drawn their own, rather than minting one behind their back.
            pendingLink = link
            incoming = .waitingForIdentity
            return
        }

        let localNonce = Pollination.makeNonce(byteCount: ExchangeProtocol.nonceByteCount)
        guard let result = link.cross(withLocalSeed: identity.seed, localNonce: localNonce) else {
            incoming = .failed("That seed and this one would grow different plants on each phone, so nothing was planted.")
            return
        }

        let outcome = ExchangeOutcome(
            result: result,
            peerDisplayName: link.displayName,
            peerPlantName: link.plantName,
            happenedAt: Date()
        )

        // Only an offer needs answering: a reply is the end of the exchange.
        let reply: URL? = link.kind == .offer
            ? PollenLink.reply(
                to: link,
                seed: identity.seed,
                nonce: localNonce,
                displayName: identity.displayName,
                plantName: identity.genome.name.full,
                birth: identity.birth,
                result: result
              ).url(host: Self.linkHost)
            : nil

        incoming = .arrived(outcome, reply: reply)
    }

    func clearIncoming() {
        incoming = .none
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
