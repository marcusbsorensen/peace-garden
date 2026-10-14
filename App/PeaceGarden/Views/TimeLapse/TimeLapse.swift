import Foundation
import SeedCore

/// A plant's life so far, played again in twelve seconds.
///
/// Marcus, 13 October 2026: *"any way we can give the user the experience of
/// seeing their plant grow again to its current size like a time-lapse? That
/// would be beautiful and maybe even emotional for some."* He chose a play
/// glyph on the plant's own screen (1A), **the same calm length for every
/// plant whatever its age** (2A), and a sky that turns behind it as it grows —
/// *"but not one revolution per day as it will flash too fast, just a notion of
/// the sky turning with time so no one gets strobe epilepsy from it"* (3A).
///
/// This is the score: what the plant and the sky are doing at every moment of
/// the run. It is pure — no SceneKit, no view — so the screen, the film the
/// share sheet makes (`TimeLapseFilm`) and the tests all read one timeline.
///
/// ## The three movements
///
/// | | From | To | What happens |
/// |---|---|---|---|
/// | **Arriving** | 0 | `leadIn` | the plant as it is fades out, the sprout fades in, the sky comes over the stage |
/// | **Growing** | `leadIn` | `growthEnd` | sprout to the plant as it is now; the sky drifts, once |
/// | **Resting** | `growthEnd` | `duration` | the plant holds as it is now and the sky leaves |
///
/// ## How the growth is timed: steady growing
///
/// **Not by the calendar.** Growth is front-loaded: height is an ease-out over
/// the first weeks (`GrowthModel`'s exponent 2.4), so a run spaced evenly in
/// days spends its first second shooting up and the other eight on a plant that
/// barely moves — and for a plant some months old, the whole of its growing
/// would be over in a blink while the rest of the run watched a mature plant.
///
/// **By how much the plant visibly changes.** The plant's life is sampled
/// finely from the first sprouting to now, each step is measured by how far the
/// five things the mesh is drawn from moved (`visibleChange`), and the run is
/// spaced so that every second shows the same amount of growing — the way a
/// time-lapse photographer drops frames in the quiet stretches. A gentle ease is
/// laid over that (`steady`), half linear and half smoothstep, so the sprout
/// starts at half speed and the plant settles into its last frame rather than
/// stopping on it. It reads as steady growing, which is the thing asked for.
///
/// ## What is held still, so nothing flickers
///
/// - **The hour.** Petals open by day and close at night (`diurnalFactor`), so a
///   life replayed on the calendar would open and shut every simulated day —
///   ten times a second for a plant a hundred days old, which is a strobe made
///   of flowers. Every frame is read at the hour it is now
///   (`calendar(readingTheHourOf:at:)`), so the flowers open once.
/// - **The flowering cycle.** A mature plant's band of open flowers travels up
///   it over a week or a month (`flush`). Replayed, that wave would race up the
///   stem again and again. It is held at today's phase, and its depth comes up
///   with the flowers as they open, so each flower opens once, straight to how
///   open it is today.
struct TimeLapse: Sendable {
    // MARK: The score

    /// The whole run, whatever the plant's age (2A).
    static let duration: TimeInterval = 12
    /// The sky arrives and the plant hands over to the sprout.
    static let leadIn: TimeInterval = 1.2
    /// The plant rests as it is now while the sky leaves.
    static let leadOut: TimeInterval = 1.6
    /// When growing stops and the plant is as it is now.
    static var growthEnd: TimeInterval { duration - leadOut }

    /// How long the plant as it is takes to fade out at the start, and when
    /// the sprout has fully faded in. Sequential rather than overlapping: a grown
    /// plant and a sprout drawn through each other is two plants at once.
    static let liveFadesBy: TimeInterval = 0.6
    static let sproutFadesIn: ClosedRange<TimeInterval> = 0.5...1.2

    /// When the run is stopped part way, how long the sky takes to leave and
    /// the plant to come back to now. Long enough to keep the luminance change
    /// per frame as gentle as the run's own (`TimeLapseLuminanceTests`).
    static let stopSkyFade: TimeInterval = 1.4
    static let stopPlantFade: TimeInterval = 0.5

    /// Under Reduce Motion the growth is a few stills, each dissolving into the
    /// next, and the sky does not move.
    static let stillCount = 5
    static let stillDissolve: TimeInterval = 0.7

    // MARK: The plant

    let genome: Genome
    /// The plant as it is now, which is where the run ends — exactly.
    let final: GrowthModel.State
    /// The hour it is now, as a fraction, for the sky.
    let hourNow: Double
    let drift: SkyDrift

    /// The plant's life, sampled from its first sprouting to now.
    private let path: [GrowthModel.State]
    /// How far through the visible growing each sample is, `0...1`, rising.
    private let reach: [Double]
    /// The sky's drift, sampled in the sun's height, and how far through its
    /// visible change each sample is: the sky is re-timed the way the plant is.
    private let skyPath: [Double]
    private let skyReach: [Double]

    init(record: PlantRecord, now: Date, drift: SkyDrift = .chosen, calendar: Calendar = .current) {
        self.init(genome: record.genome, birth: record.birth, now: now, drift: drift, calendar: calendar)
    }

    init(genome: Genome, birth: Date, now: Date, drift: SkyDrift = .chosen,
         calendar: Calendar = .current, samples: Int = 960) {
        self.genome = genome
        self.drift = drift
        let model = GrowthModel(genome: genome)
        let here = calendar.dateComponents([.hour, .minute], from: now)
        hourNow = Double(here.hour ?? 12) + Double(here.minute ?? 0) / 60
        (skyPath, skyReach) = Self.skyTiming(TimeLapseSky.drift(drift, hourNow: hourNow))

        let age = max(0, now.timeIntervalSince(birth))
        let matureAt = model.start(of: .mature)
        let grownBy = min(age, matureAt)

        // Read at the hour it is now, every one of them. The last of these is
        // the moment it is now, on a calendar that reads the hour exactly as the
        // phone's does, so it *is* the plant on the screen.
        func state(atAge seconds: TimeInterval) -> GrowthModel.State {
            let moment = birth.addingTimeInterval(seconds)
            return model.state(birth: birth, now: moment,
                               calendar: Self.calendar(readingTheHourOf: now, at: moment, from: calendar))
        }

        var path: [GrowthModel.State] = []
        let growing = max(2, samples)
        path.reserveCapacity(growing + 1)
        for index in 0...growing {
            path.append(state(atAge: grownBy * Double(index) / Double(growing)))
        }

        let live = model.state(birth: birth, now: now, calendar: calendar)
        // **The flowering cycle comes up with the flowers, at today's phase.**
        // Replayed on the calendar its wave would race up the stem again and
        // again. Brought in after the flowers had opened, it shut half of them
        // again at the end of the run: the plant bloomed and then wilted into
        // its own present, which is a reversal on screen. So today's phase is
        // held from the first frame, and its depth rises as the buds swell, as
        // the square root of their swelling. The cycle pulls a bud's swell and
        // a flower's opening back by up to `0.55 × depth`
        // (`PlantBuilder.flushFactor`); `b × (1 − k√b)` only ever rises for
        // any `k` under two thirds, so every bud swells and every flower opens
        // once, straight to how it is today. The buds have finished swelling
        // before a flower opens, so the depth is already today's by then.
        let fullBud = path.map(\.budSwell).max() ?? 0
        for index in path.indices {
            let swollen = fullBud > 1e-9
                ? min(1, path[index].budSwell / fullBud)
                : Double(index) / Double(growing)
            path[index].flush = live.flush
            path[index].flushDepth = live.flushDepth * swollen.squareRoot()
        }
        // The last frame is the plant on the screen, field for field.
        path[path.count - 1] = live
        self.final = live
        self.path = path

        var reach = [0.0]
        reach.reserveCapacity(path.count)
        for index in 1..<path.count {
            reach.append(reach[index - 1] + Self.visibleChange(from: path[index - 1], to: path[index]))
        }
        let total = reach[reach.count - 1]
        if total > 1e-9 {
            self.reach = reach.map { $0 / total }
        } else {
            // A plant sown this minute has nothing to replay; space it evenly.
            self.reach = (0..<path.count).map { Double($0) / Double(max(1, path.count - 1)) }
        }
    }

    /// How much the plant visibly changed between two moments.
    ///
    /// Weighted by what the eye takes in: height is the plant getting bigger and
    /// counts most; the leaves opening and the flowers opening next; the bud
    /// swelling and the flowering cycle least, because each is a small part of
    /// the plant changing.
    static func visibleChange(from a: GrowthModel.State, to b: GrowthModel.State) -> Double {
        abs(b.heightScale - a.heightScale) * 1.0
            + abs(b.leafUnfurl - a.leafUnfurl) * 0.6
            + abs(b.bloomOpen - a.bloomOpen) * 0.6
            + abs(b.budSwell - a.budSwell) * 0.4
            + abs(b.flushDepth - a.flushDepth) * 0.4
    }

    /// Steady growing, eased in and out: half linear, half smoothstep. The run
    /// starts and settles at half speed and is a little over speed between.
    static func steady(_ u: Double) -> Double {
        let x = min(max(u, 0), 1)
        return 0.5 * x + 0.5 * x * x * (3 - 2 * x)
    }

    /// The plant `progress` of the way through its visible growing, `0...1`.
    func growth(atProgress progress: Double) -> GrowthModel.State {
        let target = min(max(progress, 0), 1)
        if target >= 1 { return final }
        if target <= 0 { return path[0] }
        // The first sample at or past the target.
        var low = 0, high = reach.count - 1
        while low < high {
            let middle = (low + high) / 2
            if reach[middle] < target { low = middle + 1 } else { high = middle }
        }
        let upper = low, lower = max(0, low - 1)
        let span = reach[upper] - reach[lower]
        let t = span > 1e-12 ? (target - reach[lower]) / span : 1
        return Self.mix(path[lower], path[upper], t)
    }

    /// Field by field. Every field the mesh is drawn from moves one way along
    /// the path, so a mix of two neighbours sits between them.
    static func mix(_ a: GrowthModel.State, _ b: GrowthModel.State, _ t: Double) -> GrowthModel.State {
        func lerp(_ x: Double, _ y: Double) -> Double { x + (y - x) * t }
        var out = t < 0.5 ? a : b
        out.heightScale = lerp(a.heightScale, b.heightScale)
        out.leafUnfurl = lerp(a.leafUnfurl, b.leafUnfurl)
        out.budSwell = lerp(a.budSwell, b.budSwell)
        out.bloomOpen = lerp(a.bloomOpen, b.bloomOpen)
        out.flushDepth = lerp(a.flushDepth, b.flushDepth)
        out.overall = lerp(a.overall, b.overall)
        out.age = lerp(a.age, b.age)
        // The phase is held from maturity on and both sides agree there;
        // before maturity the depth is nought and the phase draws nothing.
        out.flush = b.flush
        return out
    }

    // MARK: Moments

    /// One moment of the run.
    struct Frame: Sendable {
        var time: TimeInterval
        /// How far through the plant's visible growing, `0...1`.
        var progress: Double
        /// The plant at this moment.
        var growth: GrowthModel.State
        /// Under Reduce Motion, the still this one is dissolving into, and how
        /// far. `nil` the rest of the time.
        var dissolve: (growth: GrowthModel.State, amount: Double)?
        /// How much of the plant as it was before the run is still showing,
        /// `1...0` over the first `liveFadesBy` seconds.
        var live: Double
        /// How much of the replayed plant is showing.
        var replay: Double
        var sky: TimeLapseSky.Moment
    }

    /// The run at `time` seconds in.
    ///
    /// `reduceMotion` holds the sky at the hour it is now and plays the growth as
    /// a few stills, each dissolving into the next.
    func frame(at time: TimeInterval, reduceMotion: Bool = false) -> Frame {
        let t = min(max(time, 0), Self.duration)
        let live = 1 - Self.smooth(t / Self.liveFadesBy)
        let replay = Self.smooth((t - Self.sproutFadesIn.lowerBound)
                                 / (Self.sproutFadesIn.upperBound - Self.sproutFadesIn.lowerBound))
        let along = (t - Self.leadIn) / (Self.growthEnd - Self.leadIn)
        let sky = sky(at: t, reduceMotion: reduceMotion)

        guard reduceMotion else {
            let progress = Self.steady(along)
            return Frame(time: t, progress: progress, growth: growth(atProgress: progress),
                         dissolve: nil, live: live, replay: replay, sky: sky)
        }

        // Stills at even steps of the growing, each held and then dissolved
        // into the next over `stillDissolve`.
        let steps = Double(Self.stillCount - 1)
        let segment = (Self.growthEnd - Self.leadIn) / steps
        let into = max(0, t - Self.leadIn)
        let index = min(steps, floor(into / segment))
        let within = into - index * segment
        let held = growth(atProgress: index / steps)
        guard index < steps else {
            return Frame(time: t, progress: 1, growth: final, dissolve: nil,
                         live: live, replay: replay, sky: sky)
        }
        let dissolving = Self.smooth((within - (segment - Self.stillDissolve)) / Self.stillDissolve)
        let next = growth(atProgress: (index + 1) / steps)
        return Frame(time: t, progress: (index + dissolving) / steps, growth: held,
                     dissolve: dissolving > 0 ? (next, dissolving) : nil,
                     live: live, replay: replay, sky: sky)
    }

    /// The sky at `time` seconds in.
    func sky(at time: TimeInterval, reduceMotion: Bool = false) -> TimeLapseSky.Moment {
        let t = min(max(time, 0), Self.duration)
        let arriving = Self.smooth(t / Self.leadIn)
        let leaving = Self.smooth((Self.duration - t) / Self.leadOut)
        let presence = min(arriving, leaving)
        if reduceMotion {
            let still = TimeLapseSky.drift(.still, hourNow: hourNow)
            return TimeLapseSky.Moment(elevation: still.to, presence: presence)
        }
        // **One drift, across the whole of the growing.** It starts as the
        // sky arrives and is over as the growing is, smoothstepped so it never
        // starts or stops with a jolt, and spaced by how much the sky visibly
        // changes rather than by the sun's height — which would put the whole
        // of twilight, and nearly all the change there is, into two seconds.
        let p = Self.smooth(t / Self.growthEnd)
        return TimeLapseSky.Moment(elevation: Self.lookUp(p, reach: skyReach, values: skyPath),
                                   presence: presence)
    }

    /// The drift sampled finely in the sun's height, with how far through
    /// its visible change each sample is.
    static func skyTiming(_ ends: (from: Double, to: Double)) -> ([Double], [Double]) {
        let steps = 240
        let path = (0...steps).map { ends.from + (ends.to - ends.from) * Double($0) / Double(steps) }
        var reach = [0.0]
        for index in 1...steps {
            reach.append(reach[index - 1] + TimeLapseSky.visibleChange(from: path[index - 1], to: path[index]))
        }
        let total = reach[steps]
        guard total > 1e-9 else {
            return (path, (0...steps).map { Double($0) / Double(steps) })
        }
        return (path, reach.map { $0 / total })
    }

    /// The value `target` of the way along a rising `reach`, between samples.
    static func lookUp(_ target: Double, reach: [Double], values: [Double]) -> Double {
        let goal = min(max(target, 0), 1)
        var low = 0, high = reach.count - 1
        while low < high {
            let middle = (low + high) / 2
            if reach[middle] < goal { low = middle + 1 } else { high = middle }
        }
        let upper = low, lower = max(0, low - 1)
        let span = reach[upper] - reach[lower]
        let t = span > 1e-12 ? (goal - reach[lower]) / span : 1
        return values[lower] + (values[upper] - values[lower]) * t
    }

    /// The sky `since` seconds after a run was stopped with the sky at `sky`:
    /// held where it was, and leaving over `stopSkyFade`.
    static func sky(stoppedAt sky: TimeLapseSky.Moment, since: TimeInterval) -> TimeLapseSky.Moment {
        TimeLapseSky.Moment(elevation: sky.elevation,
                            presence: sky.presence * (1 - smooth(since / stopSkyFade)))
    }

    /// Every frame of the run at `fps`, from the first to the last.
    func frames(fps: Int, reduceMotion: Bool = false) -> [Frame] {
        let count = Int((Self.duration * Double(fps)).rounded())
        return (0...count).map { frame(at: Double($0) / Double(fps), reduceMotion: reduceMotion) }
    }

    static func smooth(_ x: Double) -> Double {
        let c = min(max(x, 0), 1)
        return c * c * (3 - 2 * c)
    }

    // MARK: The hour, held

    /// A calendar on which `moment` reads as the hour and minute `now` reads
    /// as on `calendar`.
    ///
    /// `GrowthModel` takes the hour for its petals from the calendar it is
    /// handed, which is the door `Maturity.bloomPreview` already uses to pin a
    /// plant to the hour it opens widest. Here it pins every frame to the hour
    /// it is now, so the flowers open once, to how open they are at this
    /// moment, instead of opening and closing with every simulated day.
    static func calendar(readingTheHourOf now: Date, at moment: Date, from calendar: Calendar) -> Calendar {
        let here = calendar.dateComponents([.hour, .minute], from: now)
        let wanted = Double((here.hour ?? 0) * 3600 + (here.minute ?? 0) * 60)
        var intoDay = moment.timeIntervalSince1970.truncatingRemainder(dividingBy: 86_400)
        if intoDay < 0 { intoDay += 86_400 }
        // Whole minutes, which is what the petals read, rounded up so the
        // moment lands inside the wanted minute rather than in the one before,
        // and kept within a day.
        var offset = ((wanted - intoDay) / 60).rounded(.up) * 60
        offset = offset.truncatingRemainder(dividingBy: 86_400)
        if offset >= 43_200 { offset -= 86_400 }
        if offset < -43_200 { offset += 86_400 }
        var held = Calendar(identifier: .gregorian)
        held.timeZone = TimeZone(secondsFromGMT: Int(offset)) ?? calendar.timeZone
        return held
    }
}
