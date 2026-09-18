#if os(WASI)
import FoundationEssentials
import WASILibc
#else
import Foundation
#endif
#if canImport(simd)
import simd
#endif

/// A plant as it will be when it is grown, and the space it will fill.
///
/// Moved here from the app's `PlantSceneBuilder` on 18 September, which kept
/// forwarding to it. Nothing in either needed SceneKit, and the web gardens
/// need the same answer the app frames its plants by: a Long Walk that put a
/// plant at the back of the border by a different height from the one the app
/// draws it at would be two gardens that disagree about one plant.
public enum Maturity {

    /// The plant at its best: grown, and pinned to the hour it opens widest.
    public static func bloomPreview(for genome: Genome) -> GrowthModel.State {
        let birth = Date(timeIntervalSince1970: 0)
        let atBloom = birth.addingTimeInterval(
            (genome.tempo.daysToBloom + genome.tempo.bloomDays * 0.45) * 86_400
        )
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        let hour = genome.tempo.opensByDay ? 13 : 1
        let pinned = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: atBloom) ?? atBloom
        return GrowthModel(genome: genome).state(birth: birth, now: pinned, calendar: calendar)
    }

    /// The box the grown plant fills, in metres, foot at the origin.
    ///
    /// Builds a whole mesh, so it is worth holding on to per seed.
    public static func bounds(for genome: Genome) -> (min: SIMD3<Float>, max: SIMD3<Float>) {
        let mesh = PlantBuilder(genome: genome).mesh(growth: bloomPreview(for: genome))
        return (mesh.minBounds, mesh.maxBounds)
    }
}
