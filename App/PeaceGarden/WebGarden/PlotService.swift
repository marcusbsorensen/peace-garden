import Foundation
import SeedCore

/// The phone's side of the plot service: the asking, and nothing else.
///
/// **This is the first network request the app has ever made**, and the reason
/// it is one file with four calls in it. Everything about a plant is derived
/// from its seed, so there is nothing here that syncs, backs up, or fetches an
/// appearance. What crosses the wire is an offer, an answer, and a bag of
/// opaque tokens to ask about.
///
/// It never sends a name, a seed of this person's own, a coordinate, or
/// anything that identifies the device. The tokens it sends are the meeting's,
/// they mean nothing outside it, and the service holds no directory to look
/// them up in. See `Offers.php`.
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

    // MARK: The four things a phone says

    /// Offers one plant, addressed to the token the other gardener minted.
    func offer(_ arrival: WalkArrival, tokens: MeetingTokens) async throws -> SharedOffer {
        try await askOne("/api/walk/offer", Offering(to: tokens.theirsHex, from: tokens.oursHex, plant: arrival))
    }

    /// Everything waiting on these tokens, in either direction.
    ///
    /// **Not made at all when the person has turned invitations off.** That is
    /// the caller's business rather than this type's, and `Sharing.swift` says
    /// why it has to be the request that stops and not a banner.
    func pending(tokens: [String]) async throws -> [SharedOffer] {
        guard !tokens.isEmpty else { return [] }
        var offers: [SharedOffer] = []
        // The service takes 128 at a time; a long-standing garden asks twice.
        for batch in stride(from: 0, to: tokens.count, by: Self.batch) {
            let some = Array(tokens[batch..<min(batch + Self.batch, tokens.count)])
            offers += try await askMany("/api/walk/pending", Asking(tokens: some))
        }
        return offers
    }

    /// Yes or no, from the gardener the offer was addressed to.
    func answer(seed: SeedID, to token: String, yes: Bool) async throws -> SharedOffer {
        try await askOne("/api/walk/answer", Answering(seed: seed.hex, to: token, yes: yes))
    }

    /// Taken back, by either of them.
    func withdraw(seed: SeedID, token: String) async throws -> SharedOffer {
        try await askOne("/api/walk/withdraw", Withdrawing(seed: seed.hex, token: token))
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
        var error: String?
    }

    private struct Offering: Encodable {
        var to: String
        var from: String
        var plant: WalkArrival
    }

    private struct Asking: Encodable { var tokens: [String] }
    private struct Answering: Encodable { var seed: String; var to: String; var yes: Bool }
    private struct Withdrawing: Encodable { var seed: String; var token: String }

    private func askOne(_ path: String, _ body: some Encodable) async throws -> SharedOffer {
        guard let offer = try await ask(path, body).offer else { throw Trouble.unreadable }
        return offer
    }

    private func askMany(_ path: String, _ body: some Encodable) async throws -> [SharedOffer] {
        try await ask(path, body).offers ?? []
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
