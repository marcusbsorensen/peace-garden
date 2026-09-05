import Foundation
import MultipeerConnectivity
import Observation
import SeedCore

/// Runs one face-to-face exchange, from finding the other phone to agreeing on
/// the plant that grew out of it.
///
/// Nothing is saved and nothing is shown until both phones have computed the
/// same offspring seed and proved it to each other with a checksum. If they
/// disagree — different app versions, a dropped connection — the exchange is
/// abandoned rather than leaving two people holding two different plants and
/// believing they are the same one.
/// What an exchange produced.
///
/// Declared outside the service rather than nested inside it: the service is
/// main-actor isolated, and a type nested in it would carry that isolation into
/// `Identifiable` conformance, which has to be free of it.
struct ExchangeOutcome: Equatable, Identifiable {
    var result: CrossPollinationResult
    var peerDisplayName: String
    var peerPlantName: String
    var happenedAt: Date
    /// Where this phone was, if both people agreed the meeting could carry it.
    /// Measured here and never received from the other side.
    var coordinate: Coordinate?

    var id: String { result.childSeed.hex }
}

@Observable
@MainActor
final class PollenExchangeService: NSObject {

    enum Phase: Equatable {
        case idle
        case searching
        /// Connected, waiting for the two phones to be touched together.
        case awaitingTouch(peerName: String)
        /// Both touches seen; seeds crossing.
        case crossing(peerName: String)
        case grown(ExchangeOutcome)
        case failed(String)

        var peerName: String? {
            switch self {
            case .awaitingTouch(let name), .crossing(let name): return name
            case .grown(let outcome): return outcome.peerDisplayName
            default: return nil
            }
        }
    }

    private(set) var phase: Phase = .idle
    /// True once this phone has felt its own tap, so the UI can say it is
    /// waiting on the other person rather than on the gesture.
    private(set) var hasFeltLocalTouch = false

    /// Whether this device can feel the knock at all. False only on a
    /// simulator, which has no accelerometer — every iPhone and iPad has one.
    /// The UI reads this to offer a stand-in there; see `standInForTouch()`.
    var canFeelTouch: Bool { touchDetector.isAvailable }

    private let touchDetector = TouchDetector()
    /// Decides which side sends the invitation, so the two phones do not invite
    /// each other at the same moment and drop both connections.
    private let sessionToken = UUID().uuidString

    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    private var localPeerID: MCPeerID?
    private var connectedPeerName: String?

    private var card: PollenCard?
    private var localNonce: Data?
    private var remoteCard: PollenCard?
    private var remoteNonce: Data?
    private var localTouchAt: Date?
    private var remoteTouchAt: Date?
    private var localResult: CrossPollinationResult?
    private var remoteChecksum: Data?
    private var searchTimeout: Task<Void, Never>?
    /// This phone's own reading, taken while the exchange is being set up rather
    /// than at the moment of the crossing, because the fix takes a moment and
    /// the two people are standing in the same spot the whole time.
    private var placeReading: Coordinate?
    private var placeTask: Task<Void, Never>?

    private static let searchTimeoutSeconds: UInt64 = 90

#if DEBUG
    /// Whether the other side of this meeting is nobody. See
    /// `meetAnImaginaryGardener(as:place:)`.
    private var isImaginary = false
#endif

    /// Real time, except in a debug build where the garden's clock may have
    /// been wound forward. A plant made now should be a seedling now, whenever
    /// now has been set to.
    private static var now: Date {
#if DEBUG
        Developer.now
#else
        Date()
#endif
    }

    // MARK: - Lifecycle

    func start(identity: Identity, place: PlaceKeeping? = nil) {
        stop()
        phase = .searching

        // `canProvide` rather than the standing switch, so the card promises
        // only what this phone can actually do. iOS can revoke the permission
        // from Settings without the app being told at a convenient moment.
        let willing = place?.canProvide == true
        let card = PollenCard(
            seed: identity.seed,
            displayName: identity.displayName,
            plantName: identity.genome.name.full,
            birth: identity.birth,
            sharesPlace: willing,
            // Minted here, per meeting, and never kept: nothing in this app
            // holds a token after the exchange it belonged to. See
            // `PollenCard.contactToken`.
            contactToken: PollenCard.makeContactToken(),
            arrival: .met
        )
        self.card = card

        if willing, let place {
            placeTask = Task { [weak self] in
                let reading = await place.reading()
                self?.placeReading = reading
            }
        }

        let peerID = MCPeerID(displayName: Self.peerDisplayName(from: identity.displayName))
        localPeerID = peerID

        let session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        self.session = session

        let advertiser = MCNearbyServiceAdvertiser(
            peer: peerID,
            discoveryInfo: ["token": sessionToken, "v": String(ExchangeProtocol.version)],
            serviceType: ExchangeProtocol.serviceType
        )
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
        self.advertiser = advertiser

        let browser = MCNearbyServiceBrowser(peer: peerID, serviceType: ExchangeProtocol.serviceType)
        browser.delegate = self
        browser.startBrowsingForPeers()
        self.browser = browser

        touchDetector.start { [weak self] in
            self?.registerLocalTouch()
        }

        searchTimeout = Task { [weak self] in
            try? await Task.sleep(for: .seconds(Self.searchTimeoutSeconds))
            guard !Task.isCancelled else { return }
            guard let self, case .searching = self.phase else { return }
            self.fail("No one nearby. Both phones need this screen open.")
        }
    }

    func stop() {
        searchTimeout?.cancel()
        searchTimeout = nil
        touchDetector.stop()
        advertiser?.stopAdvertisingPeer()
        advertiser?.delegate = nil
        browser?.stopBrowsingForPeers()
        browser?.delegate = nil
        session?.disconnect()
        session?.delegate = nil
        advertiser = nil
        browser = nil
        session = nil
        localPeerID = nil
        connectedPeerName = nil
        card = nil
        localNonce = nil
        remoteCard = nil
        placeTask?.cancel()
        placeTask = nil
        placeReading = nil
        remoteNonce = nil
        localTouchAt = nil
        remoteTouchAt = nil
        localResult = nil
        remoteChecksum = nil
        hasFeltLocalTouch = false
#if DEBUG
        isImaginary = false
#endif
    }

    func reset() {
        stop()
        phase = .idle
    }

#if DEBUG
    /// Stands in for the knock.
    ///
    /// A simulator can do everything else in a meeting — advertise, browse,
    /// connect, cross — and then stops dead at the one gesture it has no
    /// hardware for, which left the crossing and the passage after it
    /// unwatchable for three sessions.
    ///
    /// **`#if DEBUG` rather than `#if targetEnvironment(simulator)`**, because
    /// a phone needs it too now, for one path only: an imaginary gardener
    /// knocks the instant you do, and a knock firm enough to register while
    /// you are watching the screen is a knack a developer control should not
    /// require. `ExchangeView` calls this on a device only while the meeting
    /// is imaginary. Either way it is compiled out of every build that could
    /// reach the App Store, so the shipping app still holds the line that the
    /// tap is a gesture and not a button.
    func standInForTouch() {
        registerLocalTouch()
    }
#endif

#if DEBUG
    /// Meets somebody who is not there.
    ///
    /// A meeting needs two phones, which makes everything after the knock —
    /// the crossing, the child, the passage both sides derive without speaking
    /// — the part of this app that is hardest to look at. This stands a second
    /// phone in without pretending to be one.
    ///
    /// **Only the transport is imaginary.** There is no fake result and no
    /// short cut through the crossing: a seed is minted the way any seed is
    /// minted, a nonce is drawn the way any nonce is drawn, and both go through
    /// `CrossPollinationResult` exactly as they would if they had arrived over
    /// the air. What grows is a plant that a real meeting could have produced,
    /// which is the only kind worth looking at.
    ///
    /// **The knock is real too.** This goes to `awaitingTouch` and waits, so a
    /// phone still has to be knocked and the accelerometer still has to feel
    /// it; the imaginary gardener simply knocks at the same instant, which is
    /// what the touch window is there to insist on. On a simulator the existing
    /// stand-in serves, since there is nothing to feel it with.
    ///
    /// Debug builds only, so a shipped app has no idea this exists.
    func meetAnImaginaryGardener(as identity: Identity, place: PlaceKeeping? = nil) {
        stop()
        isImaginary = true

        let willing = place?.canProvide == true
        let card = PollenCard(
            seed: identity.seed,
            displayName: identity.displayName,
            plantName: identity.genome.name.full,
            birth: identity.birth,
            sharesPlace: willing,
            // Minted here, per meeting, and never kept: nothing in this app
            // holds a token after the exchange it belonged to. See
            // `PollenCard.contactToken`.
            contactToken: PollenCard.makeContactToken(),
            arrival: .met
        )
        self.card = card

        if willing, let place {
            placeTask = Task { [weak self] in
                let reading = await place.reading()
                self?.placeReading = reading
            }
        }

        let strangerSeed = SeedMint.mintOnThisDevice()
        let stranger = PollenCard(
            seed: strangerSeed,
            displayName: Self.imaginaryNames.randomElement() ?? "Gardener",
            plantName: Genome(seed: strangerSeed, lineage: .minted).name.full,
            birth: Self.imaginaryBirth(),
            // Willing, so the place half of a meeting can be watched too. This
            // phone's own switch still decides whether a reading is taken at
            // all, and the gate in `finishIfAgreed` is unchanged.
            sharesPlace: true
        )
        remoteCard = stranger
        remoteNonce = Pollination.makeNonce(byteCount: ExchangeProtocol.nonceByteCount)
        connectedPeerName = stranger.displayName

        // Straight to the knock. There is nobody to find, and a search that
        // always succeeds after a contrived pause teaches nothing about the
        // screen that does the finding.
        touchDetector.start { [weak self] in
            self?.registerLocalTouch()
        }
        phase = .awaitingTouch(peerName: stranger.displayName)
    }
#endif

    // MARK: - The exchange, step by step

    private func registerLocalTouch() {
        guard case .awaitingTouch = phase else { return }
        localTouchAt = Date()
        hasFeltLocalTouch = true
#if DEBUG
        // An imaginary gardener knocks at exactly the moment you do, so the
        // touch window is satisfied by the gesture rather than around it.
        if isImaginary { remoteTouchAt = localTouchAt }
#endif
        send(.touch())
        advanceIfBothTouched()
    }

    private func registerRemoteTouch() {
        guard case .awaitingTouch = phase else { return }
        // Recorded against this phone's clock, on receipt. The two devices
        // never compare clocks with each other, only elapsed time on their own.
        remoteTouchAt = Date()
        advanceIfBothTouched()
    }

    /// Whether two touches count as one knock.
    ///
    /// On a device this is the whole point. Two phones tapped together are
    /// within a moment of each other, and two touches further apart than that
    /// are two separate gestures rather than one meeting.
    ///
    /// A simulator has no knock to time. The stand-in is driven by hand or by
    /// a tool, seconds apart, so the window can only ever reject a meeting
    /// somebody meant to make. `ExchangeProtocol.touchWindow` itself is left
    /// alone: it is protocol vocabulary, it compiles on Linux, and changing it
    /// would change what the constant means everywhere. Only this side's
    /// acceptance is relaxed, and only where there is no accelerometer.
    ///
    /// One consequence, for whoever meets it: a simulator paired with a real
    /// phone will disagree about a slow pair of taps, because the simulator
    /// accepts what the phone rejects. Cross two simulators or two phones,
    /// rather than one of each.
    private func touchesCountAsOneKnock(_ local: Date, _ remote: Date) -> Bool {
#if targetEnvironment(simulator)
        return true
#else
        return abs(local.timeIntervalSince(remote)) <= ExchangeProtocol.touchWindow
#endif
    }

    private func advanceIfBothTouched() {
        guard let localTouchAt, let remoteTouchAt, let peerName = connectedPeerName else { return }
        guard touchesCountAsOneKnock(localTouchAt, remoteTouchAt) else { return }
        guard let card else { return }

        phase = .crossing(peerName: peerName)
        touchDetector.stop()

        let nonce = Pollination.makeNonce(byteCount: ExchangeProtocol.nonceByteCount)
        localNonce = nonce
        send(.hello(card: card, nonce: nonce))
        crossIfReady()
    }

    private func handle(_ envelope: ExchangeEnvelope) {
        guard envelope.protocolVersion == ExchangeProtocol.version else {
            send(.abort(reason: "protocol version mismatch"))
            fail("The other phone is running a different version of Peace Garden.")
            return
        }

        switch envelope.kind {
        case .touch:
            registerRemoteTouch()
        case .hello:
            guard let card = envelope.card, let nonce = envelope.nonce else {
                fail("The other phone sent an incomplete greeting.")
                return
            }
            remoteCard = card
            remoteNonce = nonce
            crossIfReady()
        case .confirm:
            remoteChecksum = envelope.checksum
            finishIfAgreed()
        case .abort:
            // The reason is a wire token — "same seed", "checksum mismatch" —
            // and stays English on purpose: it is for whoever is reading a bug
            // report, and inventing a translation for each would put seven
            // versions of a diagnostic into the catalogue.
            fail(envelope.reason.map { "The other phone stopped: \($0)." } ?? "The other phone stopped.")
        case .unknown:
            send(.abort(reason: "unrecognised message"))
            fail("The other phone sent something this version does not understand.")
        }
    }

    /// Both halves have to be in hand before the cross can be computed: this
    /// phone's nonce and the other's seed and nonce.
    private func crossIfReady() {
        guard localResult == nil,
              let card,
              let localNonce,
              let remoteCard,
              let remoteNonce else { return }

        guard remoteCard.seed != card.seed else {
            send(.abort(reason: "same seed"))
            fail("Both phones are carrying the same seed.")
            return
        }

        let result = CrossPollinationResult(
            localSeed: card.seed,
            remoteSeed: remoteCard.seed,
            localNonce: localNonce,
            remoteNonce: remoteNonce
        )
        localResult = result
        send(.confirm(checksum: result.checksum))
#if DEBUG
        // The other side would send back a checksum over the same four values,
        // so it can only be this one. Computing it rather than asserting it
        // keeps the comparison below doing its real work.
        if isImaginary { remoteChecksum = result.checksum }
#endif
        finishIfAgreed()
    }

    private func finishIfAgreed() {
        guard let localResult, let remoteChecksum, let remoteCard else { return }
        guard remoteChecksum == localResult.checksum else {
            send(.abort(reason: "checksum mismatch"))
            fail("The two phones grew different plants, so nothing was saved. Please try again.")
            return
        }

        searchTimeout?.cancel()
        // The one gate. A reading taken on this phone is still discarded unless
        // the other person agreed, because they were standing here too.
        let agreed = card.map { PollenCard.permitPlace($0, remoteCard) } ?? false
        phase = .grown(
            ExchangeOutcome(
                result: localResult,
                peerDisplayName: remoteCard.displayName,
                peerPlantName: remoteCard.plantName,
                happenedAt: Self.now,
                coordinate: agreed ? placeReading : nil
            )
        )
        // Hold the connection open briefly so the other side's confirm is not
        // cut off mid-flight, then let it go.
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(2))
            self?.session?.disconnect()
        }
    }

    /// Every way this can go wrong, in one place, and looked up here rather
    /// than at the screen that shows it — several of these end on a system
    /// error whose own text arrives already translated, so the phrase around it
    /// has to be resolved at the same moment.
    private func fail(_ message: LocalizedStringResource) {
        // A finished exchange is not undone by a late disconnect.
        if case .grown = phase { return }
        phase = .failed(String(localized: message))
        touchDetector.stop()
        searchTimeout?.cancel()
    }

    private func send(_ envelope: ExchangeEnvelope) {
        guard let session, let peer = session.connectedPeers.first else { return }
        do {
            try session.send(envelope.encoded(), toPeers: [peer], with: .reliable)
        } catch {
            fail("The connection dropped: \(error.localizedDescription)")
        }
    }

    /// `MCPeerID` display names are limited to 63 bytes of UTF-8.
    private static func peerDisplayName(from name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallback = trimmed.isEmpty ? String(localized: "Gardener") : trimmed
        var result = fallback
        while result.utf8.count > 63 {
            result = String(result.dropLast())
        }
        return result
    }
}

// MARK: - MCSessionDelegate

extension PollenExchangeService: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        let name = peerID.displayName
        Task { @MainActor [weak self] in
            guard let self else { return }
            switch state {
            case .connected:
                self.searchTimeout?.cancel()
                self.connectedPeerName = name
                if case .searching = self.phase {
                    self.phase = .awaitingTouch(peerName: name)
                }
            case .notConnected:
                guard self.connectedPeerName == name else { return }
                self.connectedPeerName = nil
                switch self.phase {
                case .grown, .failed, .idle:
                    break
                default:
                    self.fail("\(name) moved out of range before the plant took.")
                }
            case .connecting:
                break
            @unknown default:
                break
            }
        }
    }

    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                self.handle(try ExchangeEnvelope.decode(data))
            } catch {
                self.fail("The other phone sent something unreadable.")
            }
        }
    }

    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}

    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}

    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - Discovery

extension PollenExchangeService: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(
        _ browser: MCNearbyServiceBrowser,
        foundPeer peerID: MCPeerID,
        withDiscoveryInfo info: [String: String]?
    ) {
        let peerToken = info?["token"]
        // Multipeer's own types predate `Sendable` and have never been
        // annotated, so handing one to the main actor reads as a data race to
        // the compiler. `MCPeerID` is immutable, and the browser is documented
        // as callable from any thread; the decision below genuinely does need
        // main-actor state to make, so the hop is the point rather than an
        // accident. Saying that here is more honest than an actor around a
        // framework object this file does not own.
        nonisolated(unsafe) let browser = browser
        nonisolated(unsafe) let peerID = peerID
        Task { @MainActor [weak self] in
            guard let self, let session = self.session else { return }
            guard session.connectedPeers.isEmpty else { return }
            // Exactly one side invites; the lower token wins the toss.
            guard let peerToken, self.sessionToken < peerToken else { return }
            browser.invitePeer(peerID, to: session, withContext: nil, timeout: 20)
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        Task { @MainActor [weak self] in
            self?.fail("Could not look for nearby phones: \(error.localizedDescription)")
        }
    }
}

extension PollenExchangeService: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        // As above: the answer depends on main-actor state, and the handler is
        // a plain framework callback with no `Sendable` annotation on it.
        nonisolated(unsafe) let invitationHandler = invitationHandler
        Task { @MainActor [weak self] in
            guard let self, let session = self.session, session.connectedPeers.isEmpty else {
                invitationHandler(false, nil)
                return
            }
            invitationHandler(true, session)
        }
    }

    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        Task { @MainActor [weak self] in
            self?.fail("Could not make this phone visible: \(error.localizedDescription)")
        }
    }
}
