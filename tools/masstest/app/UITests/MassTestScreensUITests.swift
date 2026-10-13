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
        case "plant": arguments += ["-pgOpen", "garden", "-pgTray", "NO"]
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
            MassTest.pause(7)
            guard openAPlant(app) else {
                note["error"] = "no plant answered a tap"
                return
            }
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

    /// Taps across the middle of the plot, nearest the centre first, until a
    /// plant's screen covers the garden (the tray's plus is gone with it).
    /// The plants are drawn pictures with no accessibility element, so a
    /// coordinate is the only way to one.
    private func openAPlant(_ app: XCUIApplication) -> Bool {
        let tray = app.buttons["garden.tray"]
        var points: [CGVector] = []
        for y in stride(from: 0.30, through: 0.62, by: 0.04) {
            for x in stride(from: 0.22, through: 0.78, by: 0.08) {
                points.append(CGVector(dx: x, dy: y))
            }
        }
        points.sort { hypot($0.dx - 0.5, $0.dy - 0.46) < hypot($1.dx - 0.5, $1.dy - 0.46) }
        for point in points.prefix(40) {
            app.coordinate(withNormalizedOffset: point).tap()
            MassTest.pause(1.1)
            if !tray.exists { return true }
        }
        return false
    }

    // MARK: Arguments

    static func arguments(locale: String, size: String, appearance: String) -> [String] {
        var arguments = [
            // No launch moment over the screen being photographed; it has a
            // photograph of its own (`launch.sh`).
            "-loading.style.v1", "off",
            // The Testing section is a Debug build's, in English on purpose,
            // and not what anybody installing the app sees.
            "-developer.showsSection", "NO",
            "-developer.clockShift", "0",
            "-garden.turn.v1", "0",
            // Still, so two photographs of one screen differ only in what is
            // being tested.
            "-stage.turntable.v1", "NO",
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
