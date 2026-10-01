import Foundation
import SeedCore

/// The phone's side of the plot service: the asking, and letting a plant go.
///
/// **These were the first network requests the app ever made**, and the reason
/// they are one file with six calls in it. Everything about a plant is derived
/// from its seed, so there is nothing here that syncs, backs up, or fetches an
/// appearance. What crosses the wire is an offer, an answer, a bag of opaque
/// tokens to ask about, and — since 1 October 2026 — a plant released to the
/// Wild Fields.
///
/// It never sends a coordinate, or anything that identifies the device. What
/// it does send of a plant is its seed, both parents' seeds and the meeting's
/// number, and one of the two parents is this person's own seed: that is what
/// a hybrid is grown from, and `privacy6` and `privacy8` on the site say so.
/// The tokens it sends are the meeting's, they mean nothing outside it, and
/// the service holds no directory to look them up in. See `Offers.php` and
/// `WildStore.php`.
///
/// **A name goes only where its owner chose to show it** (1 October 2026):
/// beside a plant in the Wild Fields, with the meeting's place and month if
/// they chose those too (`WildShowing`). Nothing is chosen until they choose
/// it, and each is theirs to withdraw.
struct PlotService: Sendable {

    /// Where the service is. HTTPS and this host only: a service address that
    /// could be pointed elsewhere is a way to send somebody's meetings to
    /// somewhere else, and there is no reason for this to be configurable.
    static let origin = URL(string: "https://peacegarden.app")!

    let origin: URL
    let transport: PlotTransport

    init(transport: PlotTransport = URLSessionTransport(), origin: URL = PlotService.origin) {
        self.transport = transport
        self.origin = origin
    }

    // MARK: The things a phone says

    /// **Which of the garden's ten areas a plant can stand in today.**
    ///
    /// The one question here that is not about a plant, and the only one that
    /// sends nothing at all: a bare GET, no body, no token, no seed. What comes
    /// back is the list `GET /api/garden` answers — every area named, and
    /// whether it is open.
    ///
    /// **Why ask at all, when `Area.isOpen` is compiled in.** Because that list
    /// is this build's, and the garden is planted one area at a time by
    /// somebody who is not shipping an app. Until 21 September
    /// `ShowInGardenView` read the compiled list, so a phone learned that an
    /// area had opened when it was next updated rather than on the day — which
    /// is exactly what this route was built to prevent, and the app was the one
    /// caller not using it.
    ///
    /// **It is prompted, not polled.** The request is made when a gardener
    /// opens the screen that asks the question, and never otherwise. That is
    /// what keeps it clear of the *Alert me when a joint seed is shared*
    /// switch, which exists to stop an **unprompted** request — `pending` is
    /// the one a phone makes on its own, and this is not.
    ///
    /// An area this build has never heard of is dropped rather than guessed at.
    /// `Area.init(from:)` reads an unknown name as the Long Walk, which is the
    /// right fallback for a stored record and the wrong one here: it would put
    /// a second travel in the list and say nothing true. An area built after
    /// this app is an area this app has nothing to offer to.
    func garden() async throws -> OpenAreas {
        let reply: GardenReply = try await fetch("/api/garden")
        // A garden always has areas. An empty list is a reply this version
        // cannot read rather than a garden with nothing open in it, and the
        // caller falls back to what it was built believing.
        guard !reply.areas.isEmpty else { throw Trouble.unreadable }
        return OpenAreas(areas: Set(
            reply.areas.filter(\.open).compactMap { Area(rawValue: $0.area) }
        ))
    }

    // MARK: The four things a phone says about a plant

    /// Offers one plant, addressed to the token the other gardener minted.
    func offer(_ arrival: WalkArrival, tokens: MeetingTokens) async throws -> SharedOffer {
        try await askOne("/api/walk/offer", Offering(to: tokens.theirsHex, from: tokens.oursHex, plant: arrival))
    }

    /// Everything waiting on these tokens, in either direction.
    ///
    /// **Not made at all when the person has turned invitations off.** That is
    /// the caller's business rather than this type's, and `Sharing.swift` says
    /// why it has to be the request that stops and not a banner.
    ///
    /// **And the Wild Fields', on the same request** (1 October 2026): every
    /// plant one of these meetings grew that either gardener released, with
    /// what each chose to show beside it. One poll, so the one switch stops
    /// both.
    func pending(tokens: [String]) async throws -> Pending {
        guard !tokens.isEmpty else { return Pending() }
        var heard = Pending()
        // The service takes 128 at a time; a long-standing garden asks twice.
        for batch in stride(from: 0, to: tokens.count, by: Self.batch) {
            let some = Array(tokens[batch..<min(batch + Self.batch, tokens.count)])
            let reply = try await ask("/api/walk/pending", Asking(tokens: some))
            heard.offers += reply.offers ?? []
            heard.wild += reply.wild ?? []
        }
        return heard
    }

    /// What `pending` hears: the asking's rows and the Wild Fields'.
    struct Pending: Sendable, Equatable {
        var offers: [SharedOffer] = []
        var wild: [WildNotice] = []
    }

    /// Yes or no, from the gardener the offer was addressed to.
    func answer(seed: SeedID, to token: String, yes: Bool) async throws -> SharedOffer {
        try await askOne("/api/walk/answer", Answering(seed: seed.hex, to: token, yes: yes))
    }

    /// Taken back, by either of them.
    func withdraw(seed: SeedID, token: String) async throws -> SharedOffer {
        try await askOne("/api/walk/withdraw", Withdrawing(seed: seed.hex, token: token))
    }

    // MARK: Letting a plant go

    /// Releases one plant into the Wild Fields, and returns once the service
    /// says it is standing there.
    ///
    /// **Prompted, never polled**: it is made when a gardener has held Release
    /// for three seconds, and at no other time, which is why the *Alert me*
    /// switch has nothing to say about it — that switch stops the one request
    /// a phone makes on its own (`pending`), and this is not that.
    ///
    /// **It succeeds only on the planting**, not on a status code. The service
    /// answers with the planting it stands in the field, and a reply that does
    /// not carry this plant's seed is treated as a failure: the caller removes
    /// the plant from this garden on success, and a plant must never be removed
    /// on the strength of a reply that does not say it arrived. A second
    /// release of a plant already standing is answered with that planting, so
    /// a phone that lost the first answer is told the truth by the second.
    ///
    /// Returns what the service says stands beside it, when the plant went
    /// with a meeting's tokens, so the phone can keep it to change later.
    @discardableResult
    func release(_ plant: WildRelease) async throws -> WildNotice? {
        let reply = try await ask("/api/wild/release", plant)
        guard reply.planting?.seed == plant.seed else { throw Trouble.unreadable }
        return reply.beside
    }

    /// What of this gardener's stands beside a released plant: the whole of
    /// it, each time, so a first answer, a change and a withdrawal are one
    /// request. **Prompted**, like release — made when somebody chooses, and
    /// so not behind the *Alert me* switch.
    func beside(seed: String, token: String, shown: WildShowing) async throws -> WildNotice {
        guard let notice = try await ask("/api/wild/answer", Beside(seed: seed, token: token, shown: shown)).beside
        else { throw Trouble.unreadable }
        return notice
    }

    // MARK: What can go wrong

    enum Trouble: Error, Equatable {
        /// The phone could not reach the service at all.
        case unreachable
        /// The service answered, and said no. Carries its own sentence where it
        /// gave one, which is for the log rather than for a screen: the service
        /// writes in English and a person is owed their own language.
        case refused(status: Int, said: String?)
        /// The service answered with something this version cannot read.
        case unreadable
    }

    // MARK: Underneath

    private static let batch = 128

    private struct Reply: Decodable {
        var offer: SharedOffer?
        var offers: [SharedOffer]?
        /// A plant standing in the Wild Fields: all a phone reads of it is the
        /// seed, to know it is this plant that arrived.
        var planting: Planted?
        /// What stands beside a released plant, as one phone is told it.
        var beside: WildNotice?
        /// Every released plant touching the tokens `pending` asked with.
        var wild: [WildNotice]?
        var error: String?
    }

    private struct Planted: Decodable { var seed: String }

    private struct Offering: Encodable {
        var to: String
        var from: String
        var plant: WalkArrival
    }

    private struct GardenReply: Decodable {
        struct Row: Decodable { var area: String; var open: Bool }
        var areas: [Row]
    }

    private struct Asking: Encodable { var tokens: [String] }
    private struct Answering: Encodable { var seed: String; var to: String; var yes: Bool }
    private struct Withdrawing: Encodable { var seed: String; var token: String }
    private struct Beside: Encodable { var seed: String; var token: String; var shown: WildShowing }

    private func askOne(_ path: String, _ body: some Encodable) async throws -> SharedOffer {
        guard let offer = try await ask(path, body).offer else { throw Trouble.unreadable }
        return offer
    }

    /// A read, which is the only kind of request here with no body.
    ///
    /// **Eight seconds rather than twenty.** The calls below are a
    /// gardener pressing a button and waiting for it to happen; this one runs
    /// while they are reading, and an answer that arrives after they have
    /// decided is no answer. Failing quickly is what lets the caller fall back
    /// to what it already knew.
    private func fetch<Answer: Decodable>(_ path: String) async throws -> Answer {
        var request = URLRequest(url: origin.appending(path: path))
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        // Nothing of this phone's is cached or revalidated. Which areas are
        // open is exactly the thing a stale answer gets wrong.
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 8

        let data: Data
        let response: HTTPURLResponse
        do {
            (data, response) = try await transport.send(request)
        } catch {
            throw Trouble.unreachable
        }
        guard (200..<300).contains(response.statusCode) else {
            throw Trouble.refused(status: response.statusCode, said: nil)
        }
        guard let answer = try? JSONDecoder().decode(Answer.self, from: data) else {
            throw Trouble.unreadable
        }
        return answer
    }

    private func ask(_ path: String, _ body: some Encodable) async throws -> Reply {
        var request = URLRequest(url: origin.appending(path: path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Nothing of this phone's is cached or revalidated, and an offer
        // answered twice from a cache would be a different answer.
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 20
        request.httpBody = try JSONEncoder().encode(body)

        let data: Data
        let response: HTTPURLResponse
        do {
            (data, response) = try await transport.send(request)
        } catch {
            throw Trouble.unreachable
        }

        let reply = try? JSONDecoder().decode(Reply.self, from: data)
        guard (200..<300).contains(response.statusCode) else {
            throw Trouble.refused(status: response.statusCode, said: reply?.error)
        }
        guard let reply else { throw Trouble.unreadable }
        return reply
    }
}

// MARK: - What is open

/// The areas of the shared garden a plant can be offered to.
///
/// **A value rather than a list of names**, so the one question a screen asks
/// it — *can this plant go anywhere yet* — has one answer and no place to put a
/// second copy of the rule.
struct OpenAreas: Sendable, Equatable {
    var areas: Set<Area>

    /// What this build was compiled believing, for when the service cannot be
    /// reached.
    ///
    /// **It errs the safe way.** A build that has not heard of an area says
    /// *not yet* about it, which is a gardener waiting rather than a gardener
    /// promised a planting the service would refuse. The reverse is already
    /// covered further down: a plant offered to an area the service keeps shut
    /// comes back 409, with its own sentence.
    static let builtIn = OpenAreas(areas: Set(Area.open))

    func has(_ area: Area) -> Bool { areas.contains(area) }
}

// MARK: - Sending it

/// How a request actually goes out. A protocol so the asking can be exercised
/// without a network, and so nothing in the app reaches `URLSession` directly.
protocol PlotTransport: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

struct URLSessionTransport: PlotTransport {
    /// Ephemeral: no cookie store, no credential store, no disk cache. There is
    /// nothing to keep between two requests, and a session that kept something
    /// would be the first thing in this app that could tell two of them apart.
    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpCookieStorage = nil
        configuration.urlCache = nil
        configuration.httpShouldSetCookies = false
        configuration.waitsForConnectivity = false
        return URLSession(configuration: configuration)
    }()

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await Self.session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw PlotService.Trouble.unreadable
        }
        return (data, http)
    }
}
