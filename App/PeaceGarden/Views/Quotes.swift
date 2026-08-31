import Foundation
import SeedCore

/// The lines shown when two people's plants have made a seed together.
///
/// These are placeholders written for the app, and they are meant to be
/// replaced by a real curation. They are original on purpose: a line still in
/// copyright cannot be shipped in a binary, and the good ones mostly are.
///
/// The choice is a pure function of the seed, so a given encounter always shows
/// the same line — on both phones, and again later. That follows the rule the
/// rest of the app runs on: a plant is a seed plus a birthday, and everything
/// else is derived.
enum Quotes {
    static let all: [String] = [
        "Two strangers met, and something grew that belongs to them both.",
        "A seed carries the whole plant, and waits.",
        "Every garden begins with someone deciding to plant.",
        "What grows here remembers the moment you met.",
        "Peace is a thing you tend.",
        "A garden keeps its own time, and everything arrives.",
        "The meeting is brief. What it makes outlasts it.",
        "Two hands, one seed, and time to spare.",
    ]

    /// The line for a given seed. Stable for that seed, on any device.
    static func line(for seed: SeedID) -> String {
        guard !all.isEmpty else { return "" }
        // The seed's own bytes pick the line, so both phones land on the same
        // one without either of them sending anything.
        let index = seed.bytes.reduce(into: UInt64(0)) { total, byte in
            total = total &* 31 &+ UInt64(byte)
        }
        return all[Int(index % UInt64(all.count))]
    }
}
