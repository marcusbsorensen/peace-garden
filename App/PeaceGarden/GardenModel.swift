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

    /// Whether the seed is in the middle of coming up out of its husk.
    ///
    /// Deliberately not persisted. It happens once, it takes six seconds, and
    /// an app closed halfway through should come back to a plant rather than to
    /// a seed waiting to start again.
    private(set) var isArriving = false

    /// Mints this person's seed. Called once, on first launch.
    ///
    /// No name is taken here. A name is for somebody else, and on the first
    /// screen there is nobody else yet — it is asked for at the first meeting,
    /// which is the moment it first does anything.
    func mintIdentity() {
        guard garden.identity == nil else { return }
        garden.identity = Identity(
            seed: SeedMint.mintOnThisDevice(),
            birth: Date(),
            displayName: ""
        )
        isArriving = true
        persist()
    }

    /// The arrival has been watched, or waved past.
    func arrivalWatched() {
        isArriving = false
        // A seed that was already waiting waited a few seconds longer. Letting
        // it through during the arrival would put a full-screen cover over the
        // one moment the app has, which is the app talking over itself.
        if let pendingLink {
            self.pendingLink = nil
            try? accept(pendingLink)
        }
    }

    /// What the other person sees. Falls back until they have been asked.
    var shownName: String {
        let name = identity?.displayName ?? ""
        return name.isEmpty ? "Gardener" : name
    }

    /// Whether this person has chosen how they are seen. Asked at the first
    /// meeting; false until then.
    var hasChosenName: Bool { !(identity?.displayName ?? "").isEmpty }

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

    /// Change what a kept plant says about its meeting.
    ///
    /// The name, the place, and whether the coordinate is still held. Only the
    /// told half of a plant: the seed, the lineage and the birthday stay exactly
    /// as they were, so what grows never moves. A parent may tell a child more
    /// of the story, or correct a part of it, without altering whose child it is.
    ///
    /// Dropping the coordinate is a real deletion rather than a hidden flag,
    /// because consent that cannot be withdrawn is not worth much.
    func updateEncounter(
        of record: PlantRecord,
        peerDisplayName: String? = nil,
        place: String?? = nil,
        keepsCoordinate: Bool? = nil
    ) {
        guard let index = garden.plants.firstIndex(where: { $0.id == record.id }),
              var encounter = garden.plants[index].encounter else { return }

        if let peerDisplayName {
            let trimmed = peerDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
            // An empty name would leave the plant saying "with" and nothing
            // else, so a blank is treated as no change rather than as an erasure.
            if !trimmed.isEmpty { encounter.peerDisplayName = trimmed }
        }
        if let place {
            let trimmed = place?.trimmingCharacters(in: .whitespacesAndNewlines)
            encounter.place = (trimmed?.isEmpty ?? true) ? nil : trimmed
        }
        if keepsCoordinate == false {
            encounter.coordinate = nil
        }

        garden.plants[index].encounter = encounter
        persist()
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

    /// Where a seed link points.
    ///
    /// The host has to serve the apple-app-site-association file in `Server/`
    /// and carry the App Clip experience before a link will open the app rather
    /// than a web page. See Server/README.md.
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
            displayName: shownName,
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
                displayName: shownName,
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
