import Foundation
import Observation
import SeedCore

/// What has changed in the garden since it was last looked at.
///
/// **This is the one thing the tile grid did that a free layout does not.**
/// `GardenView`'s own note said it: a garden is somewhere to come back to, and
/// what has changed since the last visit is the only thing on that screen that
/// moved. A garden somebody has arranged is a garden that never surprises them
/// again — everything is where they put it, which is the point, and it leaves a
/// plant that has just come into bloom with no way to say so.
///
/// The answer, settled 17 September: **the light finds it.** A plant that has
/// changed stands in its own small pool, the way a plant on the stage already
/// does, and the pool goes out once the plant has been opened. No badge, no
/// count, no red dot — the announcement is in the vocabulary the app already
/// has.
///
/// Local and told, like an arrangement: it lives in `UserDefaults` rather than
/// in the garden, because a garden holds seeds and birthdays and has to mean the
/// same thing in ten years, and which Tuesday somebody last looked at a plant is
/// not part of that.
@Observable
@MainActor
final class GardenVisits {
    static let shared = GardenVisits()

    private static let storageKey = "garden.seen.v1"

    /// Plant id to the growth bucket it was last seen at.
    private var seenAt: [String: Int]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        seenAt = defaults.dictionary(forKey: Self.storageKey) as? [String: Int] ?? [:]
    }

    private let defaults: UserDefaults

    /// **Growth only, never the bloom.** `GrowthModel.diurnalFactor` closes a
    /// day-opening flower overnight and opens a night-opening one in its place,
    /// so bucketing on `bloomOpen` — which is what a thumbnail key does — would
    /// light up two thirds of the garden every evening and the other third every
    /// morning. A pool that comes on nightly says nothing at all.
    nonisolated static func bucket(of growth: GrowthModel.State) -> Int {
        Int(growth.overall * 24)
    }

    /// Whether this plant has something to say today: never looked at, or grown
    /// visibly since it last was.
    func announces(_ record: PlantRecord, growth: GrowthModel.State) -> Bool {
        guard let seen = seenAt[record.id.uuidString] else { return true }
        return seen != Self.bucket(of: growth)
    }

    /// Called when a plant is opened. Looking at the garden is not looking at a
    /// plant: a pool that went out because the garden was on screen would be a
    /// pool nobody ever saw go out.
    func seen(_ record: PlantRecord, growth: GrowthModel.State) {
        seenAt[record.id.uuidString] = Self.bucket(of: growth)
        defaults.set(seenAt, forKey: Self.storageKey)
    }

    /// The first time a garden is opened, everything in it is taken as seen.
    ///
    /// **Looked at, it was obvious and it is not obvious written down.** With
    /// nothing remembered, every plant announces itself, so a garden opened for
    /// the first time comes up with a pool under all fourteen — and a garden
    /// where everything is lit says nothing about any of it. It is also untrue:
    /// nothing has changed since a visit that never happened.
    func firstSight(of plants: [PlantRecord], now: Date) {
        guard seenAt.isEmpty, !plants.isEmpty else { return }
        for plant in plants {
            seenAt[plant.id.uuidString] = Self.bucket(of: plant.growth(now: now))
        }
        defaults.set(seenAt, forKey: Self.storageKey)
    }

    /// Drops what is remembered about plants that are no longer here, so a
    /// garden that has been reset does not carry a record of plants it has never
    /// heard of.
    func forget(absentFrom plants: [PlantRecord]) {
        let present = Set(plants.map(\.id.uuidString))
        let kept = seenAt.filter { present.contains($0.key) }
        guard kept.count != seenAt.count else { return }
        seenAt = kept
        defaults.set(seenAt, forKey: Self.storageKey)
    }
}
