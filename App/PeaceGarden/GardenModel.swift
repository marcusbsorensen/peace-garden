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

    /// The phone's side of the shared garden. Held rather than made per call so
    /// a test can hand the model a service that never touches a network.
    let plots: PlotService

    /// Growth is measured in hours and days, so a slow tick is plenty and
    /// leaves the battery alone.
    private static let tickInterval: Duration = .seconds(20)

    init(store: GardenStore, plots: PlotService? = nil) {
        self.store = store
#if DEBUG
        // A developer's own service, when one is named on the command line.
        self.plots = plots ?? PlotService(origin: Developer.shared.plotService ?? PlotService.origin)
#else
        self.plots = plots ?? PlotService()
#endif
        do {
            garden = try store.load()
        } catch {
            garden = Garden()
            loadError = error.localizedDescription
        }
#if DEBUG
        // Seed words on a fresh install mean a particular plant is wanted on
        // screen, so it is minted here rather than at first light: that is a
        // tap an injected one can reach, but not from a script that is
        // photographing ten seeds.
        if garden.identity == nil, Developer.shared.mintWords != nil {
            mintIdentity()
        }
        // Before the first reading of the clock, so the stage is on screen from
        // the first frame rather than after the first tick.
        if let stage = Developer.shared.stageOnLaunch, let identity = garden.identity {
            Developer.shared.wind(to: stage, genome: identity.genome, birth: identity.birth)
        }
#endif
        now = Self.currentDate()
        startClock()
    }

    /// The wall clock, and in a debug build the developer clock over the top of
    /// it. Every date this app writes down or measures against goes through
    /// here, so winding the garden on moves all of it together rather than
    /// leaving a plant sown after the shift instantly middle-aged.
    ///
    /// In a Release build `Developer` does not exist and this is `Date()`.
    static func currentDate() -> Date {
#if DEBUG
        Developer.now
#else
        Date()
#endif
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
            // Looked up here rather than at the banner that draws it, because
            // it ends on the system's own account of what went wrong and that
            // arrives already translated.
            failure = String(
                localized: "This garden cannot be saved on this device: \(error.localizedDescription)"
            )
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
#if DEBUG
        let seed = Developer.shared.mintWords.map { SeedMint.mint(fromEntropy: Data($0.utf8)) }
            ?? SeedMint.mintOnThisDevice()
#else
        let seed = SeedMint.mintOnThisDevice()
#endif
        garden.identity = Identity(
            seed: seed,
            birth: Self.currentDate(),
            displayName: ""
        )
        isArriving = true
        persist()
#if DEBUG
        // A seed minted to be looked at in a stage goes straight there. The
        // arrival is six seconds of a seed opening, and on a plant already in
        // bloom it would be a flower bursting out of a husk.
        if let stage = Developer.shared.stageOnLaunch, let identity = garden.identity {
            Developer.shared.wind(to: stage, genome: identity.genome, birth: identity.birth)
            isArriving = false
            refreshNow()
        }
#endif
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
        return name.isEmpty ? String(localized: "Gardener") : name
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
            savedAt: Self.currentDate(),
            encounter: note,
            // The one moment this can be kept. A plant saved without them is a
            // meeting that can never carry an invitation, and no later version
            // can repair it. See `MeetingTokens`.
            tokens: outcome.tokens
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

    // MARK: - The shared garden

    /// Plants this phone has been asked about and has not answered.
    var invited: [PlantRecord] {
        garden.plants.filter { $0.standingOrHere.state == .invited }
    }

    /// Plants standing in the peace garden.
    var shown: [PlantRecord] {
        garden.plants.filter(\.standingOrHere.isShown)
    }

    /// **Which areas of the shared garden are open**, from the service rather
    /// than from what this build was compiled believing.
    ///
    /// The garden is planted one area at a time by somebody who is not shipping
    /// an app, so a phone that read its own list learned that an area had
    /// opened when it was next updated. `GET /api/garden` exists so it need not
    /// be told by a version of itself, and until 21 September the app was the
    /// one caller not using it.
    ///
    /// **Asked once a session.** A gardener opening this screen for four plants
    /// in a row is one question, not four. The window that leaves is a session:
    /// an area that opens while the app is in the foreground is learned the
    /// next time it starts, which is a different order of wrong from the next
    /// time it is updated.
    ///
    /// If the service cannot be reached, what this build believes — which says
    /// *not yet* about anything it has not heard of, and so cannot promise a
    /// planting that would be refused.
    func openAreas() async -> OpenAreas {
        if let learned { return learned }
        let answer = (try? await plots.garden()) ?? .builtIn
        learned = answer
        return answer
    }

    private var learned: OpenAreas?

    /// Offers this plant to the peace garden, addressed to the gardener it was
    /// grown with.
    ///
    /// **It does not go up.** It goes into the asking, and stands in the garden
    /// only if the other gardener says yes — showing it publishes their seed
    /// along with this one's, so it was never one person's to publish.
    @discardableResult
    func offer(_ record: PlantRecord) async -> Result<Standing, PlotService.Trouble> {
        // **The area is the plant's own**, which is the area its genus head
        // belongs to and not the one it was offered from. The service keeps
        // the unbuilt areas shut, so a plant whose area is still to be planted
        // comes back refused; `ShowInGardenView` asks `openAreas()` and says so
        // before anybody presses anything, and the refusal is the second line
        // of defence for a phone that could not reach the service to ask.
        guard let tokens = record.tokens,
              let arrival = WalkArrival(record: record, area: Arrangement.area(of: record))
        else {
            return .failure(.unreadable)
        }
        do {
            let offer = try await plots.offer(arrival, tokens: tokens)
            return .success(settle(offer, on: record))
        } catch let trouble as PlotService.Trouble {
            return .failure(trouble)
        } catch {
            return .failure(.unreachable)
        }
    }

    /// The answer to somebody else's offer of a plant this person helped make.
    ///
    /// No is final for this plant. There is one invitation per plant and this
    /// was it, which is what lets the app have no block list at all: declining
    /// *is* the block, and a list would need to name a person.
    @discardableResult
    func answer(_ record: PlantRecord, yes: Bool) async -> Result<Standing, PlotService.Trouble> {
        guard let tokens = record.tokens else { return .failure(.unreadable) }
        do {
            let offer = try await plots.answer(seed: record.seed, to: tokens.oursHex, yes: yes)
            return .success(settle(offer, on: record))
        } catch let trouble as PlotService.Trouble {
            return .failure(trouble)
        } catch {
            return .failure(.unreachable)
        }
    }

    /// Takes a plant back out of the peace garden.
    ///
    /// Either gardener, at any time, without the other being involved, and
    /// whether it was them who offered it. A consent that cannot be withdrawn
    /// is not worth much; this is the same reasoning that made dropping a
    /// coordinate a real deletion rather than a hidden flag.
    @discardableResult
    func withdraw(_ record: PlantRecord) async -> Result<Standing, PlotService.Trouble> {
        guard let tokens = record.tokens else { return .failure(.unreadable) }
        do {
            let offer = try await plots.withdraw(seed: record.seed, token: tokens.oursHex)
            return .success(settle(offer, on: record))
        } catch let trouble as PlotService.Trouble {
            return .failure(trouble)
        } catch {
            return .failure(.unreachable)
        }
    }

    /// Plants the peace garden is still holding something of.
    ///
    /// Standing there, offered and unanswered, or offered to this phone and
    /// unanswered. A plant with no tokens is not in it: nothing of it ever
    /// reached the service.
    var stillInTheAsking: [PlantRecord] {
        garden.plants.filter { $0.tokens != nil && $0.standingOrHere.canTakeBack }
    }

    /// Takes every one of them back, and returns the ones still standing.
    ///
    /// **Why starting again has to do this first.** A plant's contact tokens
    /// live in this garden and nowhere else — that is the whole point of them,
    /// and it is what lets the service hold no account. The cost is that a
    /// reset which wipes them while a plant is standing in the peace garden
    /// leaves it standing for good: the row stays, the plant stays drawn, and
    /// there is no longer a phone anywhere that can ask for it to come down.
    /// *Reset everything* is already the irreversible row on that screen; this
    /// keeps it from being irreversible somewhere the person cannot see.
    ///
    /// One at a time rather than all at once, because the service counts
    /// withdrawals per address per hour and a garden emptied in parallel would
    /// spend the whole allowance in a second and lose the tail of it.
    func takeEverythingBack() async -> [PlantRecord] {
        var left: [PlantRecord] = []
        for record in stillInTheAsking {
            if case .failure = await withdraw(record) {
                left.append(record)
            }
        }
        return left
    }

    /// Asks the service whether anything has happened to any of this garden's
    /// meetings, and writes down what it says.
    ///
    /// **Off means no request.** `Sharing.wantsInvitations` is read here and
    /// nowhere further in: a switch that suppressed the answer while the
    /// question was still being asked would be a lie of the kind this project
    /// has avoided everywhere else, and off is the reason the service can
    /// honestly be told nothing.
    ///
    /// Quiet about failure. Nobody asked for this — it runs when the app opens
    /// — so a phone with no signal simply learns nothing this time.
    func catchUpOnTheAsking() async {
        guard Sharing.wantsInvitations else { return }
        let tokens = garden.plants.compactMap(\.tokens?.oursHex)
        guard !tokens.isEmpty else { return }
        guard let offers = try? await plots.pending(tokens: tokens) else { return }

        for offer in offers {
            guard let index = Self.plant(for: offer, in: garden.plants),
                  let ours = garden.plants[index].tokens?.oursHex,
                  let standing = offer.standing(forOurToken: ours, unknownAt: Self.currentDate())
            else { continue }
            garden.plants[index].standing = standing
        }
        persist()
    }

    /// Which plant a row from the service is about.
    ///
    /// By its seed, and **by this phone's own token when the service sends no
    /// seed**. Since 24 September a withdrawn offer is erased on the server: it
    /// keeps a fingerprint of the seed rather than the seed, so it cannot say
    /// which plant it was, and answers with an empty seed and the token this
    /// phone asked with. That token was minted here for one meeting, and one
    /// meeting grows one plant, so it names the plant as surely as the seed
    /// did. Only an empty seed falls back to it: a row that names a seed is
    /// about that seed or about nothing here.
    static func plant(for offer: SharedOffer, in plants: [PlantRecord]) -> Int? {
        if !offer.seed.isEmpty {
            return plants.firstIndex(where: { $0.seed.hex == offer.seed })
        }
        return plants.firstIndex(where: { plant in
            guard let ours = plant.tokens?.oursHex else { return false }
            return ours == offer.to || ours == offer.from
        })
    }

    /// Writes down where a plant stands after the service has spoken.
    @discardableResult
    private func settle(_ offer: SharedOffer, on record: PlantRecord) -> Standing {
        let ours = record.tokens?.oursHex ?? ""
        let standing = offer.standing(forOurToken: ours, unknownAt: Self.currentDate())
            ?? Standing(state: .unknown, changedAt: Self.currentDate())
        if let index = garden.plants.firstIndex(where: { $0.id == record.id }) {
            garden.plants[index].standing = standing
            persist()
        }
        return standing
    }

    // MARK: - Starting again

    /// Draws a new seed, and keeps the garden.
    ///
    /// The plant standing on the first screen is replaced by one drawn fresh.
    /// Everything grown with somebody else stays exactly where it is: those
    /// plants carry their own seeds and their own birthdays, and none of them
    /// is reachable from this one.
    ///
    /// What the other person holds is untouched by this, and unreachable from
    /// here. A hybrid was derived on their phone from a child seed; it does not
    /// point back at the parent seed, and nothing this device does can reach
    /// into a garden it has no address for.
    ///
    /// The arrival runs again, because a seed opening is what a new seed does.
    func resetSeed() {
        garden.identity = Identity(
            seed: SeedMint.mintOnThisDevice(),
            birth: Self.currentDate(),
            // The name is a setting rather than a property of the seed: it is
            // how somebody is seen, and drawing a new plant is not a decision
            // to become anonymous again.
            displayName: garden.identity?.displayName ?? ""
        )
        isArriving = true
        persist()
    }

    /// Empties this phone.
    ///
    /// The seed, the garden and everything kept about every meeting. Plants
    /// other people grew with this person stay in their gardens, where they have
    /// always lived.
    ///
    /// Leaves no identity behind, so the app returns to first light and the
    /// next seed is minted the way the first one was.
    func resetEverything() {
        garden = Garden()
        incoming = .none
        pendingLink = nil
        isArriving = false
        persist()
    }

    /// Forgets every plant grown with somebody, and keeps this person's seed.
    func forgetPlants() {
        garden.plants.removeAll()
        persist()
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
            // The system's own, already in this phone's language.
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
            incoming = .failed(String(
                localized: "That seed and this one would grow different plants on each phone, so nothing was planted."
            ))
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

    /// Stand the garden on a different ground.
    ///
    /// Told, not inherited: it goes on the bed beside the template, where the
    /// arrangement and the note already live. Nothing about a plant changes, and
    /// a plant standing where the ground is about to become a gorge keeps its
    /// `x` and `z` and is simply lower — a spot is a place on the plot rather
    /// than a place on a particular surface.
    func choose(world: Int) {
        if garden.beds?.isEmpty ?? true {
            garden.beds = [Bed(name: "", template: .thematic, world: world)]
        } else {
            garden.beds?[0].world = world
        }
        persist()
    }

    /// Put a plant somewhere by hand, in the bed being looked at.
    ///
    /// Only what somebody has moved is kept — the rest of the garden stays where
    /// its template puts it, so a plant grown tomorrow still appears without
    /// anybody having to place it. A hand placement is an opinion about one
    /// arrangement, not about the plant.
    func place(_ plant: PlantRecord, at spot: Spot) {
        if garden.beds?.isEmpty ?? true {
            garden.beds = [Bed(name: "", template: .thematic)]
        }
        garden.beds?[0].place(plant, at: spot)
        persist()
    }

    /// Let a plant go back to where its template puts it.
    ///
    /// Deleting its entry rather than recomputing one: `placed` records only
    /// what somebody moved, so a plant with no entry is exactly a plant nobody
    /// has moved, and it stands wherever the arrangement says — including
    /// wherever that has become since.
    func putBack(_ plant: PlantRecord) {
        guard garden.beds?.isEmpty == false else { return }
        garden.beds?[0].putBack(plant)
        persist()
    }

    // MARK: Lights

    /// The bed being looked at, made real if it was only the default. Every
    /// change to a bed goes through here so a garden that has never had one gets
    /// exactly one, rather than a fresh one per change.
    private func touchBed() {
        if garden.beds?.isEmpty ?? true {
            garden.beds = [Bed(name: "", template: .thematic)]
        }
    }

    func addLamp(_ kind: LampKind, at spot: Spot) {
        touchBed()
        garden.beds?[0].add(Lamp(kind: kind, spot: spot))
        persist()
    }

    func moveLamp(_ id: UUID, to spot: Spot) {
        touchBed()
        garden.beds?[0].move(lamp: id, to: spot)
        persist()
    }

    /// Taken out of the garden by being carried off the edge of it — the
    /// physical answer, and one that needs no word on the screen.
    func removeLamp(_ id: UUID) {
        touchBed()
        garden.beds?[0].remove(lamp: id)
        persist()
    }

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
                self.now = Self.currentDate()
            }
        }
    }

    func refreshNow() {
        now = Self.currentDate()
    }
}
