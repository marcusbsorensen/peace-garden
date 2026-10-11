import Foundation
import Observation

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
/// - **It sends nothing about the person.** Apple's public lookup by bundle id,
///   `itunes.apple.com/lookup?bundleId=app.peacegarden`, which names the app
///   and nothing else. The session keeps no cookies and no cache, and the two
///   headers a phone adds on its own are replaced: the user agent, which names
///   the system's version, by the app's name alone, and the preferred languages
///   by `en`, since the answer is read for two numbers and no words. Low Data
///   Mode is honoured: the question is not asked on a constrained network.
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

    /// `asks` is false inside a unit-test run, whose host is this app: the
    /// launch moment plays there too, and a test run asks nothing of the
    /// network unless a test hands this its own session.
    init(session: URLSession = UpdateCheck.session, current: String = AppVersion.current.short,
         asks: Bool = !UpdateCheck.isHostingTests) {
        self.session = session
        self.current = current
        self.asks = asks
    }

    /// The app's own bundle id, typed rather than read so the one question this
    /// sends can be read off the page. `testTheLookupAsksAboutThisApp` holds it
    /// to `Bundle.main`.
    nonisolated static let bundleID = "app.peacegarden"

    nonisolated static let lookup = URL(string: "https://itunes.apple.com/lookup?bundleId=\(bundleID)")!

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
        let session = session, current = current
        Task {
            storePage = await Self.ask(session: session, current: current)
        }
    }

    /// One question and its answer: the App Store page if the store has a newer
    /// version than `current`, and nil for every other outcome.
    nonisolated static func ask(session: URLSession, current: String, url: URL = lookup) async -> URL? {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData,
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
