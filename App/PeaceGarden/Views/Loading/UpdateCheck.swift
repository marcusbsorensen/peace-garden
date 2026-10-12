import Foundation
import Observation
import StoreKit

/// **The version this copy of the app is, as the launch moment writes it:
/// `1.0 (7)`.** `CFBundleShortVersionString` and `CFBundleVersion`, which
/// `project.yml` sets as `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION`.
struct AppVersion: Equatable, Sendable {
    /// The version people are offered, `1.0`.
    var short: String
    /// The build, `7`.
    var build: String

    init(short: String, build: String) {
        self.short = short
        self.build = build
    }

    init(info: [String: Any]?) {
        self.init(short: info?["CFBundleShortVersionString"] as? String ?? "",
                  build: info?["CFBundleVersion"] as? String ?? "")
    }

    static let current = AppVersion(info: Bundle.main.infoDictionary)

    /// `1.0 (7)`, the way App Store Connect and TestFlight write a build.
    var display: String {
        build.isEmpty || build == short ? short : "\(short) (\(build))"
    }

    /// The same, held left to right whatever the language. Under right to left
    /// the bidirectional algorithm would otherwise lay `1.0 (7)` out as
    /// `(7) 1.0`: the numbers stay in order, and the space and brackets between
    /// them take the paragraph's direction. A left-to-right isolate keeps it
    /// one run without changing how anything around it is ordered.
    var drawn: String { "\u{2066}\(display)\u{2069}" }
}

/// **Whether the App Store has a newer version than this one**, asked once a
/// launch while the launch moment plays. Marcus's choice, 11 October 2026: a
/// small up-arrow beside the version when there is one, opening the app's page
/// in the App Store, and nothing at all otherwise.
///
/// - **It never holds anything up.** It starts when the moment does and the
///   moment does not wait for it: the request may take `LoadingTiming.moment`,
///   2 s, the length of the moment, because an answer after that has nowhere to
///   be shown. Offline, slow, refused or unreadable all end the same way, in
///   silence.
/// - **It asks the person's own App Store**, Marcus, 11 October 2026: *"we do
///   NOT want to be US dependent or force people from non-US-friendly countries
///   to have to check with a US app store in case their web traffic is
///   tracked."* The country is StoreKit's `Storefront.current`, the store this
///   phone already uses, turned from its three letters into the lookup's two
///   (`StoreCountry`). **With no storefront there is no question**: signed out,
///   unavailable, or a code that does not convert, it skips the check silently
///   and never falls back to the US store, which is the lookup's own default.
/// - **It sends nothing about the person beyond that country.** Apple's public
///   lookup, `itunes.apple.com/lookup?bundleId=app.peacegarden&country=dk`,
///   names the app and the store and nothing else. The session keeps no cookies
///   and no cache, and the two headers a phone adds on its own are replaced: the
///   user agent, which names the system's version, by the app's name alone, and
///   the preferred languages by `en`, since the answer is read for two numbers
///   and no words. Low Data Mode is honoured: the question is not asked on a
///   constrained network.
/// - **Once a launch.** The answer is kept for the rest of the session in
///   `storePage`.
/// - **No results, no glyph.** Until the app is publicly released the lookup
///   finds nothing (TestFlight builds are not in it), and the version stands
///   alone.
///
/// Debug builds take `-pgUpdateGlyph YES` to show the glyph without asking, so
/// it can be seen and drawn.
@MainActor
@Observable
final class UpdateCheck {

    static let shared = UpdateCheck()

    /// The app's page in the App Store, once the store has said it has a newer
    /// version than this one. Nil until then, and for good if it never does.
    private(set) var storePage: URL?

    @ObservationIgnored private var started = false
    @ObservationIgnored private let session: URLSession
    @ObservationIgnored private let current: String
    @ObservationIgnored private let asks: Bool
    @ObservationIgnored private let storefront: @Sendable () async -> String?

    /// `asks` is false inside a unit-test run, whose host is this app: the
    /// launch moment plays there too, and a test run asks nothing of the
    /// network unless a test hands this its own session. `storefront` gives the
    /// App Store's country as StoreKit writes it, three letters, or nil.
    init(session: URLSession = UpdateCheck.session, current: String = AppVersion.current.short,
         asks: Bool = !UpdateCheck.isHostingTests,
         storefront: @escaping @Sendable () async -> String? = { await Storefront.current?.countryCode }) {
        self.session = session
        self.current = current
        self.asks = asks
        self.storefront = storefront
    }

    /// The app's own bundle id, typed rather than read so the one question this
    /// sends can be read off the page. `testTheLookupAsksAboutThisApp` holds it
    /// to `Bundle.main`.
    nonisolated static let bundleID = "app.peacegarden"

    /// The question, in the store of `country`, two lowercase letters. The
    /// country is always given: the lookup would otherwise answer from the US
    /// store.
    nonisolated static func lookup(country: String) -> URL {
        var components = URLComponents(string: "https://itunes.apple.com/lookup")!
        components.queryItems = [URLQueryItem(name: "bundleId", value: bundleID),
                                 URLQueryItem(name: "country", value: country)]
        return components.url!
    }

    /// The debug override's launch argument.
    nonisolated static let showKey = "pgUpdateGlyph"

    /// Ephemeral, and keeping nothing a second request could be told apart by.
    /// A function so a test can hand the same settings a stand-in for the
    /// network.
    nonisolated static func configuration() -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpCookieStorage = nil
        configuration.httpShouldSetCookies = false
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.waitsForConnectivity = false
        configuration.allowsConstrainedNetworkAccess = false
        configuration.timeoutIntervalForRequest = LoadingTiming.moment
        configuration.timeoutIntervalForResource = LoadingTiming.moment
        configuration.httpAdditionalHeaders = ["User-Agent": "PeaceGarden", "Accept-Language": "en"]
        return configuration
    }

    nonisolated static let session = URLSession(configuration: configuration())

    /// True inside a unit-test run, whose host is this app.
    nonisolated static var isHostingTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    /// Asks, the first time it is called in a launch, and never again.
    func start() {
        guard !started else { return }
        started = true
        #if DEBUG
        if UserDefaults.standard.bool(forKey: Self.showKey) {
            storePage = URL(string: "https://apps.apple.com/")
            return
        }
        #endif
        guard asks else { return }
        let session = session, current = current, storefront = storefront
        // An answer that comes after the moment has gone has nowhere to be
        // shown, wherever the time went: the storefront or the request.
        let deadline = Date().addingTimeInterval(LoadingTiming.moment)
        Task {
            let page = await Self.check(session: session, current: current, storefront: storefront)
            if Date() < deadline { storePage = page }
        }
    }

    /// The whole check: the storefront's country, and then the question in its
    /// store. No country, no question.
    nonisolated static func check(session: URLSession, current: String,
                                  storefront: @Sendable () async -> String?) async -> URL? {
        guard let code = await storefront(), let country = StoreCountry.alpha2(fromAlpha3: code) else {
            return nil
        }
        return await ask(session: session, current: current, country: country)
    }

    /// One question and its answer: the App Store page if the store of
    /// `country` has a newer version than `current`, and nil for every other
    /// outcome.
    nonisolated static func ask(session: URLSession, current: String, country: String) async -> URL? {
        var request = URLRequest(url: lookup(country: country), cachePolicy: .reloadIgnoringLocalCacheData,
                                 timeoutInterval: LoadingTiming.moment)
        request.httpShouldHandleCookies = false
        guard let (data, response) = try? await session.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        return storePage(in: data, newerThan: current)
    }

    /// What the lookup answers, as far as this reads it.
    private struct Lookup: Decodable {
        struct Entry: Decodable {
            let version: String
            let trackId: Int
        }
        let results: [Entry]
    }

    /// The store's page for the first result, if its version is newer than
    /// `current`. No results — the app before its public release — is nil. The
    /// page is built from the store's numeric id rather than taken from the
    /// answer as a link, so what opens is always an App Store page.
    nonisolated static func storePage(in data: Data, newerThan current: String) -> URL? {
        guard let entry = (try? JSONDecoder().decode(Lookup.self, from: data))?.results.first,
              entry.trackId > 0,
              StoreVersion.isNewer(entry.version, than: current) else { return nil }
        return URL(string: "https://apps.apple.com/app/id\(entry.trackId)")
    }
}

/// **The App Store's country, from the three letters StoreKit gives to the two
/// the lookup takes**: `DNK` to `dk`. Foundation does the converting, through the
/// region aliases every locale carries (`und_DNK` reads as the region `DK`), so
/// there is no table here to fall out of date; what comes back is accepted only
/// if it is two letters and an ISO region Foundation knows. Anything else is
/// nil, and nil means the check is skipped.
///
/// **One code is Apple's own, and is read before Foundation is asked.**
/// Kosovo's storefront is `XKS`. ISO 3166 has no code for Kosovo, so Foundation
/// refuses it and a phone in Kosovo would never be asked; its App Store is `xk`,
/// from the user-assigned range Apple and the EU use for it.
enum StoreCountry {
    /// Apple's storefront codes that are not ISO's, to the lookup's two letters.
    static let notISO = ["XKS": "xk"]

    static func alpha2(fromAlpha3 code: String) -> String? {
        guard code.count == 3, code.allSatisfy({ $0.isASCII && $0.isLetter }) else { return nil }
        if let country = notISO[code.uppercased()] { return country }
        guard let region = Locale(identifier: "und_\(code.uppercased())").region?.identifier,
              region.count == 2, region.allSatisfy({ $0.isASCII && $0.isUppercase }),
              Locale.Region.isoRegions.contains(Locale.Region(region)) else { return nil }
        return region.lowercased()
    }
}

/// **Dotted version numbers, compared as numbers**: `1.10` is newer than `1.9`,
/// `1.0.1` than `1.0`, and `1.0` and `1` are the same. Anything that is not
/// dotted whole numbers is never newer, so an odd answer shows nothing.
enum StoreVersion {
    static func isNewer(_ candidate: String, than current: String) -> Bool {
        guard let a = numbers(candidate), let b = numbers(current) else { return false }
        for index in 0..<max(a.count, b.count) {
            let x = index < a.count ? a[index] : 0
            let y = index < b.count ? b[index] : 0
            if x != y { return x > y }
        }
        return false
    }

    static func numbers(_ version: String) -> [Int]? {
        let fields = version.trimmingCharacters(in: .whitespaces)
            .split(separator: ".", omittingEmptySubsequences: false)
        var out: [Int] = []
        for field in fields {
            guard !field.isEmpty, field.count <= 9,
                  field.allSatisfy({ $0.isASCII && $0.isNumber }),
                  let value = Int(field) else { return nil }
            out.append(value)
        }
        return out.isEmpty ? nil : out
    }
}
