import SwiftUI
import UIKit
import XCTest
@testable import PeaceGarden

/// How the plant is drawn, on the seed screen as well as in Settings (Marcus,
/// 13 October): one setting, two doors.
///
/// **The seam is the key.** Settings' *How the plant is drawn* and the stage
/// both read `Chrome.plantStyleKey`; these host the seed screen's control on
/// its own and check that it writes that key and shows whatever is in it, so
/// the two doors cannot disagree. Read through the accessibility tree, the
/// one VoiceOver reads, as `GardenControlsTests` reads the garden's controls.
@MainActor
final class PlantDrawingToggleTests: XCTestCase {

    /// The iPhone Air's screen, in points.
    private static let screen = CGSize(width: 420, height: 912)

    // MARK: The marks

    /// A known mark for each answer, three different ones, and every one the
    /// system can draw.
    func testEveryAnswerHasItsOwnSystemMark() {
        let symbols = StagePlantStyle.allCases.map(\.symbol)
        XCTAssertEqual(Set(symbols).count, StagePlantStyle.allCases.count)
        for symbol in symbols {
            XCTAssertNotNil(UIImage(systemName: symbol), "\(symbol) is a system mark")
        }
    }

    /// Stored in people's preferences; renaming a case would reset them.
    func testStoredNamesStay() {
        XCTAssertEqual(StagePlantStyle.allCases, [.full, .monochrome, .wireframe])
        XCTAssertEqual(StagePlantStyle.full.rawValue, "full")
        XCTAssertEqual(StagePlantStyle.monochrome.rawValue, "monochrome")
        XCTAssertEqual(StagePlantStyle.wireframe.rawValue, "wireframe")
    }

    // MARK: One setting, two doors

    /// **Chosen on the seed screen, it is what Settings and the stage read.**
    func testTheSeedScreenWritesTheKeySettingsReads() async throws {
        UserDefaults.standard.set(StagePlantStyle.full.rawValue, forKey: Chrome.plantStyleKey)
        let found = try await elements(of: PlantDrawingToggle())

        let wireframe = try XCTUnwrap(found["Wireframe"], "the wireframe mark is read aloud as Settings words it")
        XCTAssertTrue(wireframe.accessibilityActivate(), "the mark can be chosen")
        try await Task.sleep(for: .milliseconds(300))
        XCTAssertEqual(UserDefaults.standard.string(forKey: Chrome.plantStyleKey),
                       StagePlantStyle.wireframe.rawValue)
    }

    /// **Chosen in Settings, it is what the seed screen shows**, including the
    /// answer a colour-or-wireframe switch would have had no mark for.
    func testTheSeedScreenShowsWhatSettingsChose() async throws {
        for style in StagePlantStyle.allCases {
            UserDefaults.standard.set(style.rawValue, forKey: Chrome.plantStyleKey)
            let found = try await elements(of: PlantDrawingToggle())
            for other in StagePlantStyle.allCases {
                let label = String(localized: other.label)
                let element = try XCTUnwrap(found[label], "\(label) is on the seed screen")
                XCTAssertEqual(element.accessibilityTraits.contains(.selected), other == style,
                               "\(label) with \(style.rawValue) chosen")
            }
        }
    }

    // MARK: Hosting it

    private var styleBefore: Any?

    /// **SwiftUI builds its accessibility tree only for somebody reading it**,
    /// so the test says it is automation while it reads, as
    /// `GardenControlsTests` does, and puts the setting back.
    private typealias AXGet = @convention(c) () -> Bool
    private typealias AXSet = @convention(c) (Bool) -> Void
    private var automationBefore: Bool?

    override func setUp() async throws {
        try await super.setUp()
        styleBefore = UserDefaults.standard.object(forKey: Chrome.plantStyleKey)
        guard let library = dlopen("/usr/lib/libAccessibility.dylib", RTLD_NOW),
              let get = dlsym(library, "_AXSAutomationEnabled"),
              let set = dlsym(library, "_AXSSetAutomationEnabled") else { return }
        automationBefore = unsafeBitCast(get, to: AXGet.self)()
        unsafeBitCast(set, to: AXSet.self)(true)
    }

    override func tearDown() async throws {
        if let styleBefore {
            UserDefaults.standard.set(styleBefore, forKey: Chrome.plantStyleKey)
        } else {
            UserDefaults.standard.removeObject(forKey: Chrome.plantStyleKey)
        }
        if let before = automationBefore,
           let library = dlopen("/usr/lib/libAccessibility.dylib", RTLD_NOW),
           let set = dlsym(library, "_AXSSetAutomationEnabled") {
            unsafeBitCast(set, to: AXSet.self)(before)
        }
        try await super.tearDown()
    }

    /// `view` in a window, and every accessibility element in it by what it is
    /// read aloud as. The window stays up until the next call, so an element
    /// can still be activated.
    private var window: UIWindow?

    private func elements(of view: some View) async throws -> [String: NSObject] {
        window?.isHidden = true
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(origin: .zero, size: Self.screen)
        window.windowLevel = .alert + 1
        window.rootViewController = UIHostingController(rootView: view)
        window.makeKeyAndVisible()
        self.window = window
        addTeardownBlock { @MainActor in window.isHidden = true }
        window.layoutIfNeeded()
        try await Task.sleep(for: .milliseconds(600))
        window.layoutIfNeeded()

        var found: [String: NSObject] = [:]
        var stack: [NSObject] = [window]
        var visited = 0
        while let node = stack.popLast(), visited < 20_000 {
            visited += 1
            if let label = node.accessibilityLabel, !label.isEmpty, found[label] == nil,
               node.isAccessibilityElement {
                found[label] = node
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
