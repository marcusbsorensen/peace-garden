import SwiftUI
import SeedCore

/// The seed opening, once, on the day it is sown.
///
/// This is the only moment in the app that is a performance rather than a
/// state: everywhere else the plant is simply drawn as it is at that instant,
/// and coming back tomorrow is the whole mechanism. Here time is driven by
/// hand for six seconds so that the one thing nobody would otherwise ever
/// see — a seed case opening — is seen once.
///
/// It says nothing. The person has just pressed *Plant it now*, and a shoot
/// coming up out of a seed is the answer to that; a line of text over the top
/// of it would be the app explaining a thing it is in the middle of showing.
struct GerminationView: View {
    @Environment(GardenModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let identity: Identity
    let onFinished: () -> Void

    @State private var start = Date.now
    @State private var finished = false

    /// The whole arrival. Long enough to be watched rather than glimpsed,
    /// short enough that the second person to be shown the app does not have
    /// to sit through a film.
    static let duration: Double = 6.0

    // The beats, as fractions of the whole. They overlap heavily on purpose.
    // Run end to end they read as three animations queued up, which is a
    // slideshow; and the first cut of this one left the last two seconds with
    // nothing in them at all, because the husk had finished and the shoot was
    // already at its full three centimetres.
    //
    // Nothing at all happens before `huskParts` opens: a beat of a closed seed
    // sitting there, so the first thing that moves has something to move
    // against.
    private static let huskParts = 0.12...0.88
    private static let shootRises = 0.26...0.80
    private static let cameraDraws = 0.42...1.00

    var body: some View {
        let genome = identity.genome
        let live = model.growth(for: genome, birth: identity.birth)

        TimelineView(.animation(paused: finished)) { context in
            let t = reduceMotion ? 1 : progress(at: context.date)
            // Linear, alone among the three: `SeedHusk` shapes its own opening,
            // and easing it here as well would ease it twice.
            let husk = Self.span(t, Self.huskParts)
            let rise = Self.ramp(t, Self.shootRises)
            let back = Self.ramp(t, Self.cameraDraws)

            ZStack {
                StageBackdrop(
                    palette: genome.palette,
                    // The pool is glued to the subject, and during the arrival
                    // the subject is a seed held close. It tightens as the
                    // camera draws off, because the plant really is getting
                    // smaller on the screen — that is what the pull-back is.
                    presence: Self.seedPresence
                        + (live.heightScale - Self.seedPresence) * back
                )
                .ignoresSafeArea()

                PlantSceneView(
                    genome: genome,
                    growth: Self.shoot(rising: rise, toward: live),
                    isInteractive: false,
                    autoRotates: true,
                    arrival: .init(pullBack: back, huskOpen: husk)
                )
                .ignoresSafeArea()
            }
        }
        // Reduce Motion gets the plant, not the performance. The objection is
        // to being held through choreography, and six seconds of it with no
        // way past is the strongest form of that.
        .task {
            guard !reduceMotion else { return finish() }
            try? await Task.sleep(for: .seconds(Self.duration))
            finish()
        }
        // And anyone can put a hand up. The arrival happens once, which is a
        // reason to make it worth watching, not a reason to make it compulsory.
        .onTapGesture { finish() }
    }

    /// What the seed fills at the start, as a fraction of the plant it will
    /// become. Not measured — chosen, and then matched by the camera, which is
    /// the only way round that works: the seed's real size against a grown
    /// plant is a rounding error.
    private static let seedPresence = 0.34

    private func progress(at date: Date) -> Double {
        min(max(date.timeIntervalSince(start) / Self.duration, 0), 1)
    }

    private func finish() {
        guard !finished else { return }
        finished = true
        onFinished()
    }

    /// The plant as it is today, with its height wound back to nothing and let
    /// go. Everything else is left alone: this is the same growth state the
    /// plant will be drawn from a second later, so there is no moment where
    /// one plant is swapped for another.
    private static func shoot(rising: Double, toward live: GrowthModel.State) -> GrowthModel.State {
        // Not zero. `SkeletonBuilder` floors a stem at a centimetre, so below
        // this the shoot stops shrinking and only thins, and a hair-thin
        // centimetre of stem standing inside a closed case is the one thing
        // that would give the seed away as hollow.
        let hidden = 0.0035
        var state = live
        state.heightScale = hidden + (live.heightScale - hidden) * rising
        state.leafUnfurl = live.leafUnfurl * rising
        return state
    }

    /// A beat, eased, and `0` or `1` outside its own stretch of the timeline.
    private static func ramp(_ t: Double, _ range: ClosedRange<Double>) -> Double {
        let x = span(t, range)
        return x * x * (3 - 2 * x)
    }

    /// The same beat, unshaped, for anything that eases itself.
    private static func span(_ t: Double, _ range: ClosedRange<Double>) -> Double {
        let width = range.upperBound - range.lowerBound
        guard width > 0 else { return t >= range.upperBound ? 1 : 0 }
        return min(max((t - range.lowerBound) / width, 0), 1)
    }
}
