import SwiftUI
import UIKit
import XCTest
@testable import PeaceGarden

/// A view in a window of its own, read through the accessibility tree — the
/// one VoiceOver reads — as `PlantDrawingToggleTests` and
/// `GardenControlsTests` read theirs.
///
/// **SwiftUI builds its accessibility tree only for somebody reading it**, so
/// the host says it is automation while it is up and puts the setting back on
/// `tearDown()`. The window stays up until the next `show(_:)` or the
/// teardown, so an element can still be activated and what it presents read.
@MainActor
final class AccessibilityHost {
    /// The iPhone Air's screen, in points.
    static let screen = CGSize(width: 420, height: 912)

    private typealias AXGet = @convention(c) () -> Bool
    private typealias AXSet = @convention(c) (Bool) -> Void
    private var automationBefore: Bool?
    private var window: UIWindow?

    init() {
        guard let library = dlopen("/usr/lib/libAccessibility.dylib", RTLD_NOW),
              let get = dlsym(library, "_AXSAutomationEnabled"),
              let set = dlsym(library, "_AXSSetAutomationEnabled") else { return }
        automationBefore = unsafeBitCast(get, to: AXGet.self)()
        unsafeBitCast(set, to: AXSet.self)(true)
    }

    func tearDown() {
        window?.isHidden = true
        window = nil
        if let before = automationBefore,
           let library = dlopen("/usr/lib/libAccessibility.dylib", RTLD_NOW),
           let set = dlsym(library, "_AXSSetAutomationEnabled") {
            unsafeBitCast(set, to: AXSet.self)(before)
        }
    }

    /// Puts `view` in a fresh window and waits for it to settle.
    func show(_ view: some View) async throws {
        window?.isHidden = true
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(origin: .zero, size: Self.screen)
        window.windowLevel = .alert + 1
        window.rootViewController = UIHostingController(rootView: view)
        window.makeKeyAndVisible()
        self.window = window
        window.layoutIfNeeded()
        try await Task.sleep(for: .milliseconds(600))
        window.layoutIfNeeded()
    }

    /// Every accessibility element in the window, presented screens included,
    /// by what it is read aloud as. Where two share a label, the first found.
    func elements() -> [String: NSObject] {
        guard let window else { return [:] }
        var found: [String: NSObject] = [:]
        var stack: [NSObject] = [window]
        var visited = 0
        while let node = stack.popLast(), visited < 40_000 {
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

    /// Waits up to `seconds` for an element read aloud as `label`.
    func element(_ label: String, within seconds: Double = 3) async throws -> NSObject? {
        let deadline = Date().addingTimeInterval(seconds)
        repeat {
            window?.layoutIfNeeded()
            if let found = elements()[label] { return found }
            try await Task.sleep(for: .milliseconds(150))
        } while Date() < deadline
        return nil
    }
}
