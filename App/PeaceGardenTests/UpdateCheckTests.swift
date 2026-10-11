import XCTest
@testable import PeaceGarden

/// **The update check: one quiet question to the App Store, and a glyph only
/// when the answer is a newer version.** Marcus's choice, 11 October 2026. No
/// test here reaches the network: the session is the real one's settings with a
/// stand-in for the network underneath (`StubbedStore`).
@MainActor
final class UpdateCheckTests: XCTestCase {

    override func tearDown() {
        StubbedStore.reset()
        super.tearDown()
    }

    private func session() -> URLSession {
        let configuration = UpdateCheck.configuration()
        configuration.protocolClasses = [StubbedStore.self]
        return URLSession(configuration: configuration)
    }

    private func answer(_ json: String, status: Int = 200) {
        StubbedStore.reply = .success((status, Data(json.utf8)))
    }

    // MARK: - Versions

    /// Dotted whole numbers, compared field by field as numbers: never as text,
    /// where 1.10 would sort before 1.9.
    func testVersionsCompareAsNumbers() {
        XCTAssertTrue(StoreVersion.isNewer("1.1", than: "1.0"))
        XCTAssertTrue(StoreVersion.isNewer("1.10", than: "1.9"))
        XCTAssertTrue(StoreVersion.isNewer("2.0", than: "1.99.99"))
        XCTAssertTrue(StoreVersion.isNewer("1.0.1", than: "1.0"))
        XCTAssertTrue(StoreVersion.isNewer("1.0.1", than: "1"))
        XCTAssertFalse(StoreVersion.isNewer("1.0", than: "1.0"))
        XCTAssertFalse(StoreVersion.isNewer("1", than: "1.0"), "1 and 1.0 are the same version")
        XCTAssertFalse(StoreVersion.isNewer("1.0.0", than: "1"))
        XCTAssertFalse(StoreVersion.isNewer("0.9", than: "1.0"))
        XCTAssertFalse(StoreVersion.isNewer("1.9", than: "1.10"))
    }

    /// Anything that is not dotted whole numbers is never newer, so an odd
    /// answer shows nothing rather than a glyph that leads nowhere.
    func testAnOddVersionIsNeverNewer() {
        for odd in ["", " ", "1..2", "1.", ".1", "2.0-beta", "v2", "２.0", "+2", "-1", "1.0.0.0.0.0.0.0.0.99999999999"] {
            XCTAssertFalse(StoreVersion.isNewer(odd, than: "1.0"), "\(odd)")
        }
        XCTAssertFalse(StoreVersion.isNewer("2.0", than: ""), "a bundle with no version asks nothing of a glyph")
        XCTAssertEqual(StoreVersion.numbers(" 1.2.3 "), [1, 2, 3])
    }

    /// `1.0 (7)`: the short version and the build from the bundle, held left
    /// to right inside an isolate so right to left cannot turn it into `(7) 1.0`.
    func testTheVersionIsTheBundlesAndReadsLeftToRight() {
        let version = AppVersion(info: ["CFBundleShortVersionString": "1.0", "CFBundleVersion": "7"])
        XCTAssertEqual(version.display, "1.0 (7)")
        XCTAssertEqual(version.drawn, "\u{2066}1.0 (7)\u{2069}")
        XCTAssertEqual(AppVersion(short: "1.0", build: "1.0").display, "1.0", "a build that repeats the version is said once")
        let bundle = Bundle.main.infoDictionary
        XCTAssertEqual(AppVersion.current.short, bundle?["CFBundleShortVersionString"] as? String)
        XCTAssertEqual(AppVersion.current.build, bundle?["CFBundleVersion"] as? String)
        XCTAssertFalse(AppVersion.current.short.isEmpty)
        XCTAssertEqual(LaunchNameplate.spoken(version), "Peace Garden 1.0 (7)", "one label, name and version")
    }

    // MARK: - The question

    /// It names the app and nothing else: Apple's lookup by this app's own
    /// bundle id, with no cookies, no cache, a user agent that is the app's name
    /// alone and a fixed language, and it gives up inside the moment.
    func testTheLookupAsksAboutThisAppAndNothingElse() async throws {
        XCTAssertEqual(UpdateCheck.bundleID, Bundle.main.bundleIdentifier)
        let components = try XCTUnwrap(URLComponents(url: UpdateCheck.lookup, resolvingAgainstBaseURL: false))
        XCTAssertEqual(components.scheme, "https")
        XCTAssertEqual(components.host, "itunes.apple.com")
        XCTAssertEqual(components.path, "/lookup")
        XCTAssertEqual(components.queryItems, [URLQueryItem(name: "bundleId", value: "app.peacegarden")])

        let configuration = UpdateCheck.configuration()
        XCTAssertNil(configuration.httpCookieStorage)
        XCTAssertNil(configuration.urlCache)
        XCTAssertFalse(configuration.httpShouldSetCookies)
        XCTAssertFalse(configuration.waitsForConnectivity, "offline is an answer, not a wait")
        XCTAssertFalse(configuration.allowsConstrainedNetworkAccess, "Low Data Mode is honoured")
        XCTAssertLessThanOrEqual(configuration.timeoutIntervalForResource, LoadingTiming.moment)
        let headers = configuration.httpAdditionalHeaders as? [String: String]
        XCTAssertEqual(headers?["User-Agent"], "PeaceGarden")
        XCTAssertEqual(headers?["Accept-Language"], "en")

        answer(#"{"resultCount":0,"results":[]}"#)
        _ = await UpdateCheck.ask(session: session(), current: "1.0")
        let sent = try XCTUnwrap(StubbedStore.seen.first)
        XCTAssertEqual(sent.url, UpdateCheck.lookup)
        XCTAssertEqual(sent.httpMethod ?? "GET", "GET")
        XCTAssertNil(sent.httpBody)
        XCTAssertNil(sent.value(forHTTPHeaderField: "Cookie"))
    }

    // MARK: - The answer

    /// Until the app is publicly released the lookup finds nothing — TestFlight
    /// builds are not in it — and there is no glyph.
    func testNoResultsMeansNoGlyph() async {
        answer(#"{"resultCount":0,"results":[]}"#)
        let page = await UpdateCheck.ask(session: session(), current: "1.0")
        XCTAssertNil(page)
    }

    /// A newer version opens the app's own page in the App Store, built from the
    /// store's numeric id and not taken from the answer as a link.
    func testANewerVersionOpensItsStorePage() async {
        answer(#"{"resultCount":1,"results":[{"version":"1.1","trackId":6700000001,"trackViewUrl":"https://elsewhere.example/"}]}"#)
        let page = await UpdateCheck.ask(session: session(), current: "1.0")
        XCTAssertEqual(page, URL(string: "https://apps.apple.com/app/id6700000001"))
    }

    /// The same version, or an older one while a new release is still
    /// propagating, shows nothing.
    func testTheSameOrAnOlderVersionShowsNothing() async {
        for store in ["1.0", "1", "0.9"] {
            answer(#"{"resultCount":1,"results":[{"version":"\#(store)","trackId":6700000001}]}"#)
            let page = await UpdateCheck.ask(session: session(), current: "1.0")
            XCTAssertNil(page, store)
        }
    }

    /// Every way of failing ends the same way: in silence.
    func testFailingIsSilent() async {
        answer(#"{"resultCount":1,"results":[{"version":"9.0","trackId":6700000001}]}"#, status: 503)
        let refused = await UpdateCheck.ask(session: session(), current: "1.0")
        XCTAssertNil(refused, "not a 200")
        answer("<html>not json</html>")
        let unreadable = await UpdateCheck.ask(session: session(), current: "1.0")
        XCTAssertNil(unreadable)
        answer(#"{"resultCount":1,"results":[{"version":"9.0"}]}"#)
        let noID = await UpdateCheck.ask(session: session(), current: "1.0")
        XCTAssertNil(noID, "no store id, nowhere to send anyone")
        StubbedStore.reply = .failure(URLError(.notConnectedToInternet))
        let offline = await UpdateCheck.ask(session: session(), current: "1.0")
        XCTAssertNil(offline)
    }

    /// Asked once a launch however often the moment asks, and the answer kept
    /// for the session.
    func testItAsksOnceALaunchAndKeepsTheAnswer() async throws {
        answer(#"{"resultCount":1,"results":[{"version":"1.1","trackId":6700000001}]}"#)
        let check = UpdateCheck(session: session(), current: "1.0", asks: true)
        check.start()
        check.start()
        for _ in 0..<200 where check.storePage == nil {
            try await Task.sleep(for: .milliseconds(10))
        }
        XCTAssertEqual(check.storePage, URL(string: "https://apps.apple.com/app/id6700000001"))
        check.start()
        try await Task.sleep(for: .milliseconds(50))
        XCTAssertEqual(StubbedStore.seen.count, 1)
    }

    /// Inside a test run the shared check asks nothing of the network, though
    /// the launch moment plays in the test host.
    func testATestRunAsksNothing() async throws {
        XCTAssertTrue(UpdateCheck.isHostingTests)
        let check = UpdateCheck(session: session(), current: "1.0")
        check.start()
        try await Task.sleep(for: .milliseconds(50))
        XCTAssertTrue(StubbedStore.seen.isEmpty)
        XCTAssertNil(check.storePage)
    }
}

/// A stand-in for the network: answers every request with `reply` and keeps
/// what was asked in `seen`.
final class StubbedStore: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var reply: Result<(Int, Data), Error> = .failure(URLError(.notConnectedToInternet))
    nonisolated(unsafe) static var seen: [URLRequest] = []

    static func reset() {
        reply = .failure(URLError(.notConnectedToInternet))
        seen = []
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.seen.append(request)
        switch Self.reply {
        case .success(let (status, data)):
            let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: "HTTP/1.1",
                                           headerFields: ["Content-Type": "application/json"])!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        case .failure(let error):
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
