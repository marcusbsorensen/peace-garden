// How wide the longest plant names set, in the app's serif italic, at every
// size the app sets a name in — against the narrowest phone's line.
//
//   swift tools/masstest/app/name_widths.swift fuzz-summary.json
//
// The app's `plantName(size:)` is `.system(size:weight: .light, design: .serif)`
// italic, which is New York on both iOS and macOS, so the Mac measures what
// the phone draws. The fuzz run's forty longest names are the input.
import AppKit
import Foundation

let path = CommandLine.arguments.dropFirst().first ?? "fuzz-summary.json"
let data = try Data(contentsOf: URL(fileURLWithPath: path))
let summary = try JSONSerialization.jsonObject(with: data) as! [String: Any]
let names = summary["longestNames"] as! [String]

func font(_ size: CGFloat) -> NSFont {
    let base = NSFont.systemFont(ofSize: size, weight: .light)
    let serif = base.fontDescriptor.withDesign(.serif) ?? base.fontDescriptor
    let italic = serif.withSymbolicTraits(.italic)
    return NSFont(descriptor: italic, size: size) ?? base
}

// Where each size is used, and the line it has on a 375-point SE: the screen
// less the padding round it on that screen.
let uses: [(size: CGFloat, where: String, line: CGFloat)] = [
    (16, "Settings row", 375 - 60 - 40),
    (18, "Seed screen, parents", 375 - 60),
    (20, "stage caption", 375 - 40),
    (24, "Seed screen, reveal", 375 - 60),
    (26, "plant screen title", 375 - 48),
    (28, "Seed screen title", 375 - 60),
]

var rows: [[String: Any]] = []
for use in uses {
    let widths = names.map { ($0, NSAttributedString(string: $0, attributes: [.font: font(use.size)]).size().width) }
    let widest = widths.max { $0.1 < $1.1 }!
    rows.append(["size": use.size, "where": use.where, "line": use.line,
                 "widest": widest.0, "width": (widest.1 * 10).rounded() / 10,
                 "fits": widest.1 <= use.line])
    print(String(format: "%4.0f pt  %-22@ widest %6.1f of %5.0f  %@  (%@)", use.size, use.where as NSString,
                 widest.1, use.line, widest.1 <= use.line ? "fits" : "WRAPS", widest.0 as NSString))
}
let out = try JSONSerialization.data(withJSONObject: rows, options: [.prettyPrinted])
try out.write(to: URL(fileURLWithPath: (path as NSString).deletingLastPathComponent + "/name-widths.json"))
