// Measures the chrome, in every language, against the narrowest phone.
//
//     swift tools/type/measure.swift
//
// The chrome is set at 11 points, light, tracked out by 2.4 and uppercased —
// which is a great deal wider per letter than the size suggests, and the widths
// are the thing that breaks first when the app stops being written in English.
// docs/LANGUAGES.md §"Type" is the record of what this found; this is how to
// find it again after a translation changes.
//
// It reads `Localizable.xcstrings` rather than a list typed in here, so a
// language added to the catalogue is measured without touching this file.
//
// **Widths are CoreText's, from the same font at the same size.** SwiftUI's
// `tracking` adds its value to every glyph's advance, the trailing one
// included, so a tracked run is `sum(advances) + tracking × count`. Checked
// against the one measurement taken off a phone: the four English mark labels
// unrolled at once came to about 440 points, and the model below says 441.

import CoreText
import Foundation

// MARK: - Measuring

/// Uppercased, tracked, and measured at the weight the chrome actually uses.
func width(_ text: String, size: CGFloat, tracking: CGFloat, locale: Locale) -> CGFloat {
    let cased = text.uppercased(with: locale)
    let descriptor = CTFontDescriptorCreateWithAttributes([
        kCTFontSizeAttribute: size,
        kCTFontTraitsAttribute: [kCTFontWeightTrait: -0.4],  // .light
        kCTFontFamilyNameAttribute: "SF Pro Text",
    ] as CFDictionary)
    let font = CTFontCreateWithFontDescriptor(descriptor, size, nil)
    let line = CTLineCreateWithAttributedString(
        NSAttributedString(
            string: cased,
            attributes: [NSAttributedString.Key(kCTFontAttributeName as String): font]
        )
    )
    let advance = CTLineGetTypographicBounds(line, nil, nil, nil)
    return CGFloat(advance) + tracking * CGFloat(cased.count)
}

// MARK: - The catalogue

struct Catalogue {
    let byKey: [String: [String: String]]  // key -> language -> value

    init(path: String) throws {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let root = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let strings = root["strings"] as! [String: Any]
        var byKey: [String: [String: String]] = [:]
        for (key, raw) in strings {
            let entry = raw as! [String: Any]
            var values = ["en": key]
            for (language, rawLocalisation) in (entry["localizations"] as? [String: Any]) ?? [:] {
                let localisation = rawLocalisation as! [String: Any]
                if let unit = localisation["stringUnit"] as? [String: Any],
                   let value = unit["value"] as? String {
                    values[language] = value
                }
            }
            byKey[key] = values
        }
        self.byKey = byKey
    }

    /// Every language the catalogue carries, English first.
    var languages: [String] {
        let all = Set(byKey.values.flatMap(\.keys))
        return ["en"] + all.subtracting(["en"]).sorted()
    }

    func value(_ key: String, _ language: String) -> String {
        byKey[key]?[language] ?? key
    }
}

// MARK: - The layouts that can overflow

/// The screen the chrome is measured against, in points. 402 is an iPhone 17
/// Pro and the width the app is designed to; pass a narrower one to see what a
/// smaller phone would do — an iPhone SE, which the iOS 17 deployment target
/// still admits, is 375.
///
///     swift tools/type/measure.swift 375
let phone = CGFloat(CommandLine.arguments.dropFirst().first.flatMap(Double.init) ?? 402)

let label: (size: CGFloat, tracking: CGFloat) = (11, 2.4)

struct Row {
    let name: String
    let available: CGFloat
    /// Everything that is not type: padding, glyphs, gaps.
    let furniture: CGFloat
    let keys: [String]
    /// A layout that is measured but is not in the app — kept as a reference
    /// point, so the numbers here can be checked against one taken off a phone.
    var reference: Bool = false
}

let rows: [Row] = [
    // PlantStageView: three marks collapsed (15pt glyph + 2×13 padding each),
    // three 6pt gaps, and one unrolled (15 glyph + 7 gap + 2×16 padding).
    Row(name: "stage · one mark unrolled", available: phone,
        furniture: 3 * 41 + 3 * 6 + 54, keys: ["Seed"]),
    Row(name: "stage · one mark unrolled", available: phone,
        furniture: 3 * 41 + 3 * 6 + 54, keys: ["Meet"]),
    Row(name: "stage · one mark unrolled", available: phone,
        furniture: 3 * 41 + 3 * 6 + 54, keys: ["Garden"]),
    Row(name: "stage · one mark unrolled", available: phone,
        furniture: 3 * 41 + 3 * 6 + 54, keys: ["Settings"]),
    // The arrangement that was tried and abandoned, kept as the calibration
    // point: four unrolled at once measured about 440 on a phone, and the model
    // here says 449. Everything else below is trusted on the strength of that.
    Row(name: "stage · all four unrolled (reference)", available: phone,
        furniture: 4 * 54 + 3 * 6,
        keys: ["Seed", "Meet", "Garden", "Settings"], reference: true),
    // SeedOfferView: two capsules on one line, 2×18 padding each, 8pt apart.
    Row(name: "a seed on the wind · sending row", available: phone,
        furniture: 2 * 36 + 8, keys: ["Copy link", "Send QR code"]),
    // ExchangeView: two capsules, 2×18 padding each, 14pt apart, inside 40pt
    // margins.
    Row(name: "where you meet · two buttons", available: phone - 80,
        furniture: 2 * 36 + 14, keys: ["Not now", "Log places"]),
    // EncounterNoteView and EncounterEditView: Keep it … Discard, with a
    // Spacer between them, inside 30pt margins.
    Row(name: "the note · keep or discard", available: phone - 60,
        furniture: 2 * 36 + 8, keys: ["Keep it", "Discard"]),
    Row(name: "tell it differently · keep or leave", available: phone - 60,
        furniture: 2 * 36 + 8, keys: ["Keep it", "Leave it"]),
]

/// Single labels that have to fit their own line rather than wrap.
struct Single {
    let name: String
    let available: CGFloat
    let size: CGFloat
    let keys: [String]
    /// A label inside a capsule is clipped when it overruns; a label standing on
    /// its own wraps, which costs a line rather than a word.
    var wraps: Bool = false
}

let singles: [Single] = [
    // GardenView tile: 150pt wide, one line, shrunk to 0.75 before truncating —
    // so the real budget is 150 / 0.75 at the drawn size. The stage is the
    // fixed half of the caption; what is left over is what a name has.
    Single(name: "garden tile · stage", available: 150 / 0.75, size: 9,
           keys: ["Germinating", "Seedling", "Growing", "In bud", "In bloom", "Mature"]),
    // ExchangeView's naming step: one button inside 46pt margins.
    Single(name: "what they will see · button", available: phone - 92 - 36, size: 11,
           keys: ["Meet as Gardener", "That's me"]),
    // PlantDetailView: two buttons, each on its own line, inside 40pt margins.
    Single(name: "a kept plant · buttons", available: phone - 80 - 36, size: 11,
           keys: ["Tell it differently", "Let it go"]),
    // Settings section labels, in a 30pt-margined column. These may wrap, so an
    // overflow here is a second line rather than a clipped word.
    Single(name: "settings · section label", available: phone - 60, size: 11,
           keys: ["Your Peace Garden username", "Default seed planting location",
                  "Starting again"],
           wraps: true),
    // The top-corner Close, which has 12pt of trailing padding and a capsule.
    Single(name: "top corner", available: phone - 24 - 36, size: 11,
           keys: ["Close", "Cancel", "Not this time", "Done"]),
]

// MARK: - The report

let root = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()
let catalogue = try Catalogue(
    path: root.appendingPathComponent("App/PeaceGarden/Resources/Localizable.xcstrings").path
)

var failures = 0

func report(
    _ name: String, _ language: String, _ used: CGFloat, _ available: CGFloat,
    _ what: String, wraps: Bool = false, reference: Bool = false
) {
    let over = used - available
    let mark = over > 0 ? (wraps ? "WRAP" : (reference ? "ref " : "OVER")) : "    "
    if over > 0, !wraps, !reference { failures += 1 }
    print(String(format: "%@ %-38@ %-3@ %6.1f / %6.1f  %@",
                 mark, name as NSString, language as NSString, used, available, what))
}

print("Chrome at \(label.size)pt, tracking \(label.tracking), uppercased.")
print("Measured against a screen \(Int(phone))pt wide.\n")

for language in catalogue.languages {
    let locale = Locale(identifier: language)
    for row in rows {
        let words = row.keys.map { catalogue.value($0, language) }
        let used = row.furniture + words.reduce(0) {
            $0 + width($1, size: label.size, tracking: label.tracking, locale: locale)
        }
        report(row.name, language, used, row.available,
               words.joined(separator: " · "), reference: row.reference)
    }
    for single in singles {
        for key in single.keys {
            let word = catalogue.value(key, language)
            let used = width(word, size: single.size, tracking: label.tracking, locale: locale)
            report(single.name, language, used, single.available, word, wraps: single.wraps)
        }
    }
}

print("\n\(failures) over.")
