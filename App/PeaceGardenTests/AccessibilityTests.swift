import SeedCore
import SwiftUI
import UIKit
import XCTest
@testable import PeaceGarden

/// The mass test's accessibility findings of 13 October, held fixed (Marcus,
/// 14 October: 15A, 16A): the garden said to VoiceOver, type that follows the
/// size setting, the stage out of reach behind Settings, a held row read once,
/// and the faint grey at AA.
///
/// Read through the accessibility tree, the one VoiceOver reads, as
/// `GardenControlsTests` reads the garden's controls.
@MainActor
final class AccessibilityTests: XCTestCase {

    /// The iPhone Air's screen, in points.
    private static let screen = CGSize(width: 420, height: 912)

    // MARK: The garden, said (finding 3)

    /// **Every plant on the plot is an element**: its name, what it is doing
    /// and who it was grown with, a button, standing over the plot rather than
    /// over the whole screen. And the lights on the plot are said by name.
    func testEveryPlantInTheGardenIsSaid() async throws {
        let (model, names) = Self.garden(plants: 3, lamps: [.fox])
        let found = try await elements(of: PlotView().environment(model))

        for name in names {
            let plant = try XCTUnwrap(found.first { $0.label == name }, "\(name) is said")
            XCTAssertTrue(plant.traits.contains(.button), "\(name) is a button")
            XCTAssertTrue(plant.value.hasPrefix(String(localized: GrowthModel.Stage.mature.label))
                          || GrowthModel.Stage.allCases.contains { plant.value.hasPrefix(String(localized: $0.label)) },
                          "\(name) says what it is doing: \(plant.value)")
            XCTAssertTrue(plant.value.contains("Ash"), "and who it was grown with: \(plant.value)")
            XCTAssertLessThan(plant.frame.width, Self.screen.width / 2, "\(name) is its own box, not the screen")
            XCTAssertTrue(CGRect(origin: .zero, size: Self.screen).contains(plant.frame.center),
                          "\(name) stands on the screen")
        }
        XCTAssertNotNil(found.first { $0.label == String(localized: LampKind.fox.label) && $0.frame.width < 200 },
                        "the fox on the plot is said")
        XCTAssertFalse(found.contains { $0.label.isEmpty && $0.traits.contains(.image) },
                       "no picture on the garden screen is left unsaid")
    }

    /// **Activating a plant opens its screen**, as a tap on its leaves does.
    func testActivatingAPlantOpensItsScreen() async throws {
        let (model, names) = Self.garden(plants: 1, lamps: [])
        let host = try await hosted(PlotView().environment(model))
        let found = Self.walk(host.window)
        let plant = try XCTUnwrap(found.first { $0.label == names[0] })
        XCTAssertTrue(plant.node.accessibilityActivate())
        var presented: UIViewController?
        for _ in 0..<20 where presented == nil {
            try await Task.sleep(for: .milliseconds(100))
            presented = host.controller.presentedViewController
        }
        XCTAssertNotNil(presented, "the plant's screen is presented")
        presented?.dismiss(animated: false)
    }

    /// **The tray's figures and grounds say what they are**, and the chosen
    /// ground says it is chosen.
    func testTheTraysFiguresAndGroundsAreSaid() async throws {
        UserDefaults.standard.set(true, forKey: "pgTray")
        defer { UserDefaults.standard.removeObject(forKey: "pgTray") }
        let (model, _) = Self.garden(plants: 1, lamps: [])
        let found = try await elements(of: PlotView().environment(model), settle: 1.5)

        for kind in LampKind.allCases {
            let label = String(localized: kind.label)
            XCTAssertTrue(found.contains { $0.label == label && $0.traits.contains(.button) && $0.frame.minY > Self.screen.height / 2 },
                          "\(label) in the tray is said")
        }
        if GardenWorlds.shared.isLoaded {
            // By label: the walk can reach one element by two paths.
            let grounds = found.filter { $0.label.hasPrefix("Ground ") }
            XCTAssertEqual(Set(grounds.map(\.label)).count, GardenWorlds.shared.count, "every ground is said")
            XCTAssertEqual(Set(grounds.filter { $0.traits.contains(.selected) }.map(\.label)).count, 1,
                           "and one is chosen")
        }
    }

    // MARK: Behind Settings (finding 9)

    /// **With Settings open, the stage underneath is out of VoiceOver's
    /// reach**: no mark of the stage's row and no plant name under it.
    func testTheStageIsHiddenBehindSettings() async throws {
        let model = Self.garden(plants: 0, lamps: []).0
        model.mintIdentity()
        Developer.shared.openOnLaunch = .settings
        defer { Developer.shared.openOnLaunch = nil }
        let found = try await elements(of: PlantStageView().environment(model).environment(PlaceKeeping()),
                                       settle: 1.5)
        XCTAssertTrue(found.contains { $0.label == String(localized: "Show plant name") }, "Settings is open")
        for mark in ["Seed", "Meet", "Garden"] {
            XCTAssertFalse(found.contains { $0.label == String(localized: String.LocalizationValue(mark)) },
                           "the stage's \(mark) mark is hidden behind Settings")
        }
        if let name = model.identity?.genome.name.full {
            XCTAssertFalse(found.contains { $0.label == name }, "the plant's name is hidden behind Settings")
        }
    }

    // MARK: Read once (finding 10)

    /// **A held row is read once**: the copy the fill wipes across is ink,
    /// not a second label.
    func testAHeldRowIsReadOnce() async throws {
        let found = try await elements(of: HoldToConfirm(
            title: "Reset everything", consequence: "Your seed, your plant and your garden all go.",
            glyph: AnyShape(CycleGlyph()), tint: Chrome.crimson, filledForeground: Chrome.ink,
            action: {}, askInstead: {}))
        let label = String(localized: "Reset everything")
        XCTAssertEqual(found.filter { $0.label == label }.count, 1, "said once")
        XCTAssertFalse(found.contains { $0.label.contains("\(label), \(label)") || $0.label == "\(label) \(label)" })
    }

    // MARK: Capitals for the eye

    /// **The capitals are drawn, not read**: a label or a heading in the
    /// tracked capitals is read to VoiceOver as the words it was written in.
    func testCapitalsAreReadAsWritten() async throws {
        let found = try await elements(of: VStack {
            Text(verbatim: "Location description").chromeLabel()
            Text(verbatim: "Starting again").chromeHeading(size: 13)
        })
        XCTAssertTrue(found.contains { $0.label == "Location description" }, "the label voice: \(found.map(\.label))")
        XCTAssertTrue(found.contains { $0.label == "Starting again" }, "the heading voice: \(found.map(\.label))")
        XCTAssertFalse(found.contains { $0.label == "LOCATION DESCRIPTION" || $0.label == "STARTING AGAIN" })
    }

    // MARK: Dynamic Type (finding 4)

    /// **Each designed size grows at the rate of the text style nearest it.**
    func testEachSizeScalesByTheNearestTextStyle() {
        // Not caption 2, which does not move below Large.
        XCTAssertEqual(ScaledSystemFont.style(near: 10), .caption)
        XCTAssertEqual(ScaledSystemFont.style(near: 11), .caption)
        XCTAssertEqual(ScaledSystemFont.style(near: 12), .caption)
        XCTAssertEqual(ScaledSystemFont.style(near: 13), .footnote)
        XCTAssertEqual(ScaledSystemFont.style(near: 15), .subheadline)
        XCTAssertEqual(ScaledSystemFont.style(near: 17), .body)
        XCTAssertEqual(ScaledSystemFont.style(near: 20), .title3)
        XCTAssertEqual(ScaledSystemFont.style(near: 28), .title)
    }

    /// **The three voices grow with the size setting, and stand as they did at
    /// Large.**
    func testTheVoicesGrowWithTheSizeSetting() {
        func height(_ view: some View, _ size: DynamicTypeSize) -> CGFloat {
            UIHostingController(rootView: view.environment(\.dynamicTypeSize, size))
                .sizeThatFits(in: CGSize(width: 1_000, height: 1_000)).height
        }
        let voices: [(String, AnyView)] = [
            ("label", AnyView(Text(verbatim: "MATURE").chromeLabel())),
            ("heading", AnyView(Text(verbatim: "SETTINGS").chromeHeading())),
            ("name", AnyView(Text(verbatim: "Zephessea paniculata").plantName())),
            ("paragraph", AnyView(Text(verbatim: "A line").scaledFont(size: 15))),
        ]
        for (name, view) in voices {
            let large = height(view, .large)
            XCTAssertGreaterThan(height(view, .accessibility3), large * 1.6, "the \(name) voice grows")
            XCTAssertGreaterThan(height(view, .xxxLarge), large, "the \(name) voice grows a little")
        }
        let atLarge = height(Text(verbatim: "A line").scaledFont(size: 15), .large)
        let fixed = height(Text(verbatim: "A line").font(.system(size: 15, weight: .light)), .large)
        XCTAssertEqual(atLarge, fixed, accuracy: 0.5, "at Large it is the size the design set")
    }

    // MARK: The faint grey (finding 8)

    /// **`faint` clears AA's 4.5 : 1 on the screen's own ground in both
    /// appearances**, and stays the faintest of the three.
    func testTheFaintGreyClearsAAInBothAppearances() {
        for style in [UIUserInterfaceStyle.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: style)
            let ground = UIColor(Chrome.ground).resolvedColor(with: traits)
            let faint = Self.contrast(UIColor(Chrome.faint).resolvedColor(with: traits), on: ground)
            let muted = Self.contrast(UIColor(Chrome.muted).resolvedColor(with: traits), on: ground)
            XCTAssertGreaterThanOrEqual(faint, 4.5, "faint in \(style == .light ? "Light" : "Dark")")
            XCTAssertLessThan(faint, muted, "faint is still fainter than muted")
        }
    }

    // MARK: Helpers

    /// WCAG contrast of a colour laid over an opaque ground.
    private static func contrast(_ colour: UIColor, on ground: UIColor) -> Double {
        var (r, g, b, a): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        var (gr, gg, gb, ga): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        colour.getRed(&r, green: &g, blue: &b, alpha: &a)
        ground.getRed(&gr, green: &gg, blue: &gb, alpha: &ga)
        func linear(_ c: CGFloat) -> Double {
            let c = Double(c)
            return c <= 0.040_45 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        func luminance(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> Double {
            0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b)
        }
        let over = luminance(r * a + gr * (1 - a), g * a + gg * (1 - a), b * a + gb * (1 - a))
        let under = luminance(gr, gg, gb)
        return (max(over, under) + 0.05) / (min(over, under) + 0.05)
    }

    /// A garden of `plants` crossed plants, all met with Ash, and the lights
    /// asked for; and the names of the plants.
    private static func garden(plants count: Int, lamps: [LampKind]) -> (GardenModel, [String]) {
        let met = Date(timeIntervalSince1970: 1_700_000_000)
        let plants = (0..<count).map { index -> PlantRecord in
            let a = SeedID(bytes: seedDigest(SeedDomain.seed, Data("a11y-a-\(index)".utf8)))!
            let b = SeedID(bytes: seedDigest(SeedDomain.seed, Data("a11y-b-\(index)".utf8)))!
            let encounter = Pollination.encounterID(seedA: a, seedB: b,
                                                    nonceA: Data("na".utf8), nonceB: Data("nb".utf8))
            return PlantRecord(
                id: UUID(),
                seed: Pollination.cross(seedA: a, seedB: b, encounterID: encounter),
                lineage: .crossed(parentA: a, parentB: b, encounterID: encounter),
                birth: met, savedAt: met,
                encounter: EncounterNote(peerDisplayName: "Ash", happenedAt: met, place: "Here")
            )
        }
        let file = FileManager.default.temporaryDirectory
            .appendingPathComponent("a11y-\(UUID().uuidString).json")
        let store = GardenStore(fileURL: file)
        try? store.save(Garden(identity: nil, plants: plants))
        let model = GardenModel(store: store)
        for (index, kind) in lamps.enumerated() {
            model.addLamp(kind, at: Spot(x: 0.3 * Double(index + 1), z: -0.2))
        }
        return (model, plants.map(\.genome.name.full))
    }

    // MARK: Hosting it

    /// **SwiftUI builds its accessibility tree only for somebody reading it**,
    /// so the test says it is automation while it reads, as
    /// `GardenControlsTests` does, and puts the setting back.
    private typealias AXGet = @convention(c) () -> Bool
    private typealias AXSet = @convention(c) (Bool) -> Void
    private var automationBefore: Bool?

    override func setUp() async throws {
        try await super.setUp()
        guard let library = dlopen("/usr/lib/libAccessibility.dylib", RTLD_NOW),
              let get = dlsym(library, "_AXSAutomationEnabled"),
              let set = dlsym(library, "_AXSSetAutomationEnabled") else { return }
        automationBefore = unsafeBitCast(get, to: AXGet.self)()
        unsafeBitCast(set, to: AXSet.self)(true)
    }

    override func tearDown() async throws {
        if let before = automationBefore,
           let library = dlopen("/usr/lib/libAccessibility.dylib", RTLD_NOW),
           let set = dlsym(library, "_AXSSetAutomationEnabled") {
            unsafeBitCast(set, to: AXSet.self)(before)
        }
        try await super.tearDown()
    }

    struct Element {
        let label: String
        let value: String
        let frame: CGRect
        let traits: UIAccessibilityTraits
        let node: NSObject
    }

    private func hosted(_ view: some View, settle: Double = 0.8) async throws
        -> (window: UIWindow, controller: UIViewController) {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(origin: .zero, size: Self.screen)
        window.windowLevel = .alert + 1
        let controller = UIHostingController(rootView: view)
        window.rootViewController = controller
        window.makeKeyAndVisible()
        addTeardownBlock { @MainActor in window.isHidden = true }
        window.layoutIfNeeded()
        try await Task.sleep(for: .seconds(settle))
        window.layoutIfNeeded()
        return (window, controller)
    }

    private func elements(of view: some View, settle: Double = 0.8) async throws -> [Element] {
        Self.walk(try await hosted(view, settle: settle).window)
    }

    /// Every accessibility element under `window`, in no particular order.
    private static func walk(_ window: UIWindow) -> [Element] {
        var found: [Element] = []
        var stack: [NSObject] = [window]
        var visited = 0
        while let node = stack.popLast(), visited < 40_000 {
            visited += 1
            if node.isAccessibilityElement {
                found.append(Element(label: node.accessibilityLabel ?? "",
                                     value: node.accessibilityValue ?? "",
                                     frame: node.accessibilityFrame,
                                     traits: node.accessibilityTraits, node: node))
            }
            if let children = node.accessibilityElements as? [NSObject] {
                stack.append(contentsOf: children)
            } else {
                let count = node.accessibilityElementCount()
                if count != NSNotFound, count > 0 {
                    for index in 0..<count {
                        if let element = node.accessibilityElement(at: index) as? NSObject {
                            stack.append(element)
                        }
                    }
                }
            }
            if let view = node as? UIView { stack.append(contentsOf: view.subviews) }
        }
        return found
    }
}

private extension CGRect {
    var center: CGPoint { CGPoint(x: midX, y: midY) }
}
