import XCTest

/// **Every main screen, in every language, size of type and appearance asked
/// for** — photographed, read back as elements, and audited (mass test, 13
/// October 2026).
///
/// Driven entirely by the environment, so one build serves every device and
/// every slice of the matrix (`xcodebuild test` passes `TEST_RUNNER_X` through
/// as `X`):
///
/// - `PG_MT_OUT`: the folder on the Mac. One subfolder per configuration, with
///   `<screen>.jpg`, `<screen>.json` (every element: label, identifier,
///   frame) and `<screen>-audit.json` where the audit ran.
/// - `PG_MT_FIXTURES`: where `garden-14.json` is (`make_garden.py`).
/// - `PG_MT_CONFIGS`: `locale/size/appearance` separated by `;` — locale is a
///   catalogue language, `pseudo` (English, every string doubled) or `rtl`
///   (English, forced right to left); size is `L`, `XXXL`, `AX3` or `AX5`;
///   appearance `light` (with the garden by day) or `dark` (by night).
/// - `PG_MT_SCREENS`: any of `stage,seed,meet,settings,garden,plant,firstlight`.
/// - `PG_MT_AUDIT`: locales to run `performAccessibilityAudit` on, or `all`.
@MainActor
final class MassTestScreensUITests: XCTestCase {

    private func prepare() {
        continueAfterFailure = true
    }

    func testSweepTheScreens() throws {
        prepare()
        let out = try MassTest.outputFolder()
        let garden = try MassTest.fixture("garden-14.json")
        let configs = (MassTest.environment["PG_MT_CONFIGS"] ?? "en/L/dark")
            .split(separator: ";").map(String.init)
        let screens = MassTest.list("PG_MT_SCREENS", default: "stage,seed,meet,settings,garden,plant,firstlight")
        let audited = Set(MassTest.list("PG_MT_AUDIT", default: "en,fr,pseudo,rtl"))

        var timings: [[String: Any]] = []
        let app = XCUIApplication()
        // Installed and launched once, so the app has a data container for the
        // garden to be written into.
        app.launchArguments = ["-loading.style.v1", "off"]
        app.launch()
        app.terminate()

        for config in configs {
            let parts = config.split(separator: "/").map(String.init)
            guard parts.count == 3 else { continue }
            let (locale, size, appearance) = (parts[0], parts[1], parts[2])
            let folder = out.appendingPathComponent("\(locale)-\(size)-\(appearance)")
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let audit = audited.contains("all") || audited.contains(locale)

            for screen in screens {
                let started = Date()
                var note: [String: Any] = ["config": config, "screen": screen]
                do {
                    try shoot(screen, app: app, locale: locale, size: size, appearance: appearance,
                              garden: garden, folder: folder, audit: audit, note: &note)
                } catch {
                    note["error"] = "\(error)"
                }
                note["seconds"] = Date().timeIntervalSince(started)
                timings.append(note)
                app.terminate()
                try MassTest.write(timings, to: out.appendingPathComponent("timings.json"))
            }
        }
    }

    // MARK: One screen

    private func shoot(_ screen: String, app: XCUIApplication, locale: String, size: String,
                       appearance: String, garden: URL, folder: URL, audit: Bool,
                       note: inout [String: Any]) throws {
        try MassTest.install(garden: screen == "firstlight" ? nil : garden)
        var arguments = Self.arguments(locale: locale, size: size, appearance: appearance)
        switch screen {
        case "seed": arguments += ["-pgOpen", "seed"]
        case "meet": arguments += ["-pgOpen", "meet"]
        case "settings": arguments += ["-pgOpen", "settings"]
        case "garden": arguments += ["-pgOpen", "garden", "-pgTray", "YES"]
        // A plant's screen is reached through the developer's tile grid: a
        // plant on the plot answers a finger on its leaves through a tap
        // gesture, and a synthesised tap never opened one in this sweep (the
        // plot's plants have no accessibility element either — see the
        // audit). The grid's tiles are buttons, and open the same
        // `PlantDetailView`.
        case "plant": arguments += ["-pgOpen", "garden", "-developer.showsTileGrid", "YES"]
        default: break
        }
        app.launchArguments = arguments
        let launched = Date()
        app.launch()
        note["launchSeconds"] = Date().timeIntervalSince(launched)

        switch screen {
        case "garden":
            MassTest.pause(7)
        case "plant":
            MassTest.pause(4)
            if !(openATile(app) || openAPlant(app)) {
                // Photographed anyway, so the failure can be seen.
                note["error"] = "no plant answered a tap"
            }
            // The words are behind a veil until the plant is tapped; the tap
            // is the scene's own recogniser, which a synthesised tap may or
            // may not reach. Either way the words are in the element tree.
            MassTest.pause(3)
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.42)).tap()
            MassTest.pause(3)
        case "firstlight", "meet":
            MassTest.pause(6)
        default:
            MassTest.pause(3)
        }

        try record(screen, app: app, folder: folder, audit: audit)
        if screen == "settings" {
            // The rest of Settings, below the first screenful.
            for _ in 0..<4 {
                app.swipeUp(velocity: .fast)
                MassTest.pause(0.6)
            }
            MassTest.pause(1)
            try record("settings-end", app: app, folder: folder, audit: audit)
        }
    }

    private func record(_ name: String, app: XCUIApplication, folder: URL, audit: Bool) throws {
        try MassTest.shoot(to: folder.appendingPathComponent("\(name).jpg"))
        let frame = app.windows.firstMatch.frame
        try MassTest.write(["window": ["w": frame.width, "h": frame.height],
                            "elements": MassTest.elements(of: app)],
                           to: folder.appendingPathComponent("\(name).json"))
        guard audit else { return }
        var issues: [[String: Any]] = []
        do {
            try app.performAccessibilityAudit(for: .all) { issue in
                var entry: [String: Any] = [
                    "type": Self.name(of: issue.auditType),
                    "description": issue.compactDescription,
                    "detail": issue.detailedDescription,
                ]
                if let element = issue.element, element.exists {
                    entry["label"] = element.label
                    entry["id"] = element.identifier
                    let f = element.frame
                    entry["frame"] = [f.minX, f.minY, f.width, f.height]
                    entry["elementType"] = MassTest.name(of: element.elementType)
                }
                issues.append(entry)
                return true
            }
        } catch {
            issues.append(["type": "auditError", "description": "\(error)"])
        }
        try MassTest.write(issues, to: folder.appendingPathComponent("\(name)-audit.json"))
    }

    /// The first tile of the grid whose label reads as a plant's name, tapped.
    /// True once the grid has gone under the plant's screen.
    private func openATile(_ app: XCUIApplication) -> Bool {
        let named = NSPredicate(format: "label MATCHES %@", "^[A-Z][a-z]+ [a-z]+.*")
        let tiles = app.buttons.matching(named)
        guard tiles.firstMatch.waitForExistence(timeout: 10) else { return false }
        // The grid puts the newest first, and the newest in the fixture is a
        // day old: the last tile on screen is a grown plant with a flower.
        let tile = tiles.allElementsBoundByIndex.last { $0.isHittable } ?? tiles.firstMatch
        tile.tap()
        return true
    }

    /// Taps the plants' pictures, largest first, until a plant's screen covers
    /// the garden (the tray's plus is gone with it).
    ///
    /// A plant is an unlabelled image in the accessibility tree — a square
    /// one, since a sprite's frame is square — and it answers only where it
    /// has leaves, so each is tried low in its frame, where the stem and the
    /// leaves are, and then halfway up.
    private func openAPlant(_ app: XCUIApplication) -> Bool {
        let tray = app.buttons["garden.tray"]
        let height = app.windows.firstMatch.frame.height
        var seen = Set<String>()
        let sprites = MassTest.elements(of: app).compactMap { e -> CGRect? in
            guard e["type"] as? String == "image", (e["label"] as? String ?? "").isEmpty,
                  let x = e["x"] as? Double, let y = e["y"] as? Double,
                  let w = e["w"] as? Double, let h = e["h"] as? Double,
                  w >= 18, w < 200, abs(w - h) < 1.5, y > height * 0.12, y + h < height * 0.8 else { return nil }
            let key = "\(Int(x))-\(Int(y))-\(Int(w))"
            guard seen.insert(key).inserted else { return nil }
            return CGRect(x: x, y: y, width: w, height: h)
        }.sorted { $0.width > $1.width }

        let origin = app.coordinate(withNormalizedOffset: .zero)
        for frame in sprites.prefix(12) {
            for fraction in [0.8, 0.55] {
                origin.withOffset(CGVector(dx: frame.midX, dy: frame.minY + frame.height * fraction)).tap()
                MassTest.pause(1.4)
                if !tray.exists { return true }
            }
        }
        return false
    }

    // MARK: Arguments

    static func arguments(locale: String, size: String, appearance: String) -> [String] {
        var arguments = [
            // No launch moment over the screen being photographed; it has a
            // photograph of its own (`launch.sh`).
            "-loading.style.v1", "off",
            "-developer.clockShift", "0",
            "-garden.turn.v1", "0",
            // The Testing section folded and the turntable stopped are set by
            // `run_tests.sh` with `defaults write`: both are `Bool`s read off
            // `object(forKey:)`, and `-key NO` here would arrive as the string
            // "NO" and override the stored value with nothing.
        ]
        let language: String
        switch locale {
        case "pseudo":
            language = "en"
            arguments += ["-NSDoubleLocalizedStrings", "YES"]
        case "rtl":
            language = "en"
            arguments += ["-AppleTextDirection", "YES", "-NSForceRightToLeftWritingDirection", "YES"]
        default:
            language = locale
        }
        let region = ["en": "GB", "da": "DK", "es": "ES", "fr": "FR", "it": "IT",
                      "nb": "NO", "nl": "NL", "sv": "SE"][language] ?? "GB"
        arguments += ["-AppleLanguages", "(\(language))", "-AppleLocale", "\(language)_\(region)"]

        let category = ["L": "UICTContentSizeCategoryL",
                        "XXXL": "UICTContentSizeCategoryXXXL",
                        "AX3": "UICTContentSizeCategoryAccessibilityXL",
                        "AX5": "UICTContentSizeCategoryAccessibilityXXXL"][size] ?? "UICTContentSizeCategoryL"
        arguments += ["-UIPreferredContentSizeCategoryName", category]

        arguments += appearance == "light"
            ? ["-stage.appearance.v1", "light", "-garden.daylight.v1", "always"]
            : ["-stage.appearance.v1", "dark", "-garden.daylight.v1", "alwaysNight"]
        return arguments
    }

    static func name(of type: XCUIAccessibilityAuditType) -> String {
        switch type {
        case .contrast: "contrast"
        case .elementDetection: "elementDetection"
        case .hitRegion: "hitRegion"
        case .sufficientElementDescription: "sufficientElementDescription"
        case .dynamicType: "dynamicType"
        case .textClipped: "textClipped"
        case .trait: "trait"
        default: "audit\(type.rawValue)"
        }
    }
}
