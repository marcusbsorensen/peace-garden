import XCTest

/// What every mass-test UI test shares: where the app keeps its garden on this
/// simulator, a garden put there before a launch, and the screen read back as
/// data as well as a picture.
///
/// **The runner writes into the app's container directly.** Both are processes
/// on a simulator, which is the Mac's own file system underneath, so the
/// runner finds the app's data container beside its own (the folder whose
/// metadata names `app.peacegarden`) and writes `garden.json` into it. No seam
/// in the app, and no launch argument the app has to understand.
@MainActor
enum MassTest {
    static let bundleID = "app.peacegarden"

    static var environment: [String: String] { ProcessInfo.processInfo.environment }

    /// The folder the results go to, on the Mac. Required.
    static func outputFolder() throws -> URL {
        guard let path = environment["PG_MT_OUT"], !path.isEmpty else {
            throw XCTSkip("PG_MT_OUT is not set")
        }
        let url = URL(fileURLWithPath: path)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    static func list(_ key: String, default value: String) -> [String] {
        (environment[key].flatMap { $0.isEmpty ? nil : $0 } ?? value)
            .split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    }

    // MARK: The app's garden

    /// The app's data container: a sibling of the runner's own.
    static func appContainer() throws -> URL {
        let mine = URL(fileURLWithPath: NSHomeDirectory())
        let applications = mine.deletingLastPathComponent()
        let candidates = try FileManager.default.contentsOfDirectory(
            at: applications, includingPropertiesForKeys: nil)
        for folder in candidates {
            let metadata = folder.appendingPathComponent(".com.apple.mobile_container_manager.metadata.plist")
            guard let plist = NSDictionary(contentsOf: metadata),
                  plist["MCMMetadataIdentifier"] as? String == bundleID else { continue }
            return folder
        }
        throw NSError(domain: "MassTest", code: 1,
                      userInfo: [NSLocalizedDescriptionKey: "no data container for \(bundleID) beside \(applications.path)"])
    }

    static func gardenFile() throws -> URL {
        try appContainer().appendingPathComponent("Library/Application Support/PeaceGarden/garden.json")
    }

    /// Puts a garden in place for the next launch, or takes it away (`nil`) so
    /// the next launch is a first one.
    static func install(garden fixture: URL?) throws {
        let target = try gardenFile()
        let manager = FileManager.default
        try manager.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
        if manager.fileExists(atPath: target.path) { try manager.removeItem(at: target) }
        if let fixture { try manager.copyItem(at: fixture, to: target) }
    }

    static func fixture(_ name: String) throws -> URL {
        guard let folder = environment["PG_MT_FIXTURES"], !folder.isEmpty else {
            throw XCTSkip("PG_MT_FIXTURES is not set")
        }
        return URL(fileURLWithPath: folder).appendingPathComponent(name)
    }

    // MARK: Reading the screen back

    /// Every element on screen, flattened: type, label, identifier, value and
    /// frame in points. One snapshot call, so it costs one round trip however
    /// many elements there are.
    static func elements(of app: XCUIApplication) -> [[String: Any]] {
        guard let root = try? app.snapshot() else { return [] }
        var out: [[String: Any]] = []
        func walk(_ node: XCUIElementSnapshot, depth: Int) {
            let frame = node.frame
            if node.elementType != .other || !node.label.isEmpty || !node.identifier.isEmpty {
                out.append([
                    "type": Self.name(of: node.elementType),
                    "label": node.label,
                    "id": node.identifier,
                    "value": (node.value as? String) ?? "",
                    "x": Double(frame.minX), "y": Double(frame.minY),
                    "w": Double(frame.width), "h": Double(frame.height),
                    "enabled": node.isEnabled,
                    "depth": depth,
                ])
            }
            for child in node.children { walk(child, depth: depth + 1) }
        }
        walk(root, depth: 0)
        return out
    }

    static func name(of type: XCUIElement.ElementType) -> String {
        switch type {
        case .application: "application"
        case .window: "window"
        case .button: "button"
        case .staticText: "text"
        case .image: "image"
        case .textField: "textField"
        case .switch: "switch"
        case .slider: "slider"
        case .scrollView: "scrollView"
        case .cell: "cell"
        case .other: "other"
        case .toggle: "toggle"
        case .link: "link"
        case .sheet: "sheet"
        case .navigationBar: "navigationBar"
        case .segmentedControl: "segmented"
        case .picker: "picker"
        case .menu: "menu"
        case .menuItem: "menuItem"
        case .alert: "alert"
        default: "type\(type.rawValue)"
        }
    }

    static func write(_ object: Any, to url: URL) throws {
        let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: url)
    }

    /// A screenshot as a JPEG: an SE's is 750 points of PNG at 2x, a Pro Max's
    /// four times that, and a few hundred of them would be gigabytes.
    static func shoot(to url: URL) throws {
        let image = XCUIScreen.main.screenshot().image
        guard let data = image.jpegData(compressionQuality: 0.72) else { return }
        try data.write(to: url)
    }

    /// Waits without asking the app anything: a sleep the test runner does
    /// not count as idle-waiting.
    static func pause(_ seconds: Double) {
        let until = Date().addingTimeInterval(seconds)
        while Date() < until { RunLoop.current.run(until: min(until, Date().addingTimeInterval(0.1))) }
    }
}
