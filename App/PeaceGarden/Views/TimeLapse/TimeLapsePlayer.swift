import SwiftUI
import SceneKit
import SeedCore

/// Plays a time-lapse in place, on the plant's own screen.
///
/// **One clock for the plant and the sky.** A display link ticks at the
/// screen's rate; each tick reads the score (`TimeLapse.frame(at:)`), hands the
/// sky its moment, and shows the newest plant the builder has finished. The
/// sky is a gradient and costs nothing, so it moves every frame. The plant is a
/// genuine mesh at every moment, built off the main thread one after another
/// and always for the moment it will be shown at, so if a phone cannot build a
/// plant in a sixtieth of a second the plant's growth steps a little less
/// often and nothing on the main thread waits for it.
///
/// **Ending.** The last frame of the score is the plant as it is now, field for
/// field, so handing the stage back to the live plant is a swap of two
/// identical meshes. Stopping part way (`stop()`) eases back instead: the
/// replay fades, the live plant fades in, and the sky leaves over
/// `TimeLapse.stopSkyFade`, slowly enough that a stop is no harsher on the eye
/// than the run's own ending.
@MainActor
@Observable
final class TimeLapsePlayer {
    /// Whether a run is under way, for the play glyph. False again the moment
    /// a stop is asked for, though the sky takes a little longer to leave.
    private(set) var isPlaying = false
    /// The sky behind the plant, for `TimeLapseSkyView`.
    private(set) var sky: TimeLapseSky.Moment = .absent
    /// Whether anything of the run is still on screen: the sky, or the
    /// replayed plant.
    private(set) var isShowing = false

    @ObservationIgnored private weak var stage: PlantSceneView.Coordinator?
    @ObservationIgnored private var lapse: TimeLapse?
    @ObservationIgnored private var nodes: TimeLapseNodes?
    @ObservationIgnored private var reduceMotion = false
    @ObservationIgnored private var link: CADisplayLink?
    @ObservationIgnored private var started: CFTimeInterval = 0
    @ObservationIgnored private var stopping: (at: CFTimeInterval, sky: TimeLapseSky.Moment, replay: Double, live: Double)?
    @ObservationIgnored private var replayAgain: (record: PlantRecord, now: Date, reduceMotion: Bool)?
    /// Bumped every run, so a plant built for an earlier run is never shown.
    @ObservationIgnored private var run = 0
    /// The newest plant shown, by the moment it was built for.
    @ObservationIgnored private var shownTime: TimeInterval = -1
    /// Under Reduce Motion, the stills, built before the run starts.
    @ObservationIgnored private var stills: [SCNNode] = []
    /// How long a plant has been taking to build, smoothed, so the builder
    /// aims at the moment its plant will be ready for.
    @ObservationIgnored private var buildTime: TimeInterval = 1.0 / 60
    /// The latest moment a builder has been given, so two builders working at
    /// once take different moments.
    @ObservationIgnored private var claimed: TimeInterval = 0
    @ObservationIgnored private var finalClaimed = false
    /// How many plants are built at once. A grown plant with a full head can
    /// take longer than a frame to build (`TimeLapseBenchTests`): two or three
    /// builders side by side keep it near the screen's rate on any phone with
    /// the cores to spare, and leave one for everything else.
    @ObservationIgnored private let builders = max(1, min(3, ProcessInfo.processInfo.activeProcessorCount - 1))
    @ObservationIgnored private let queue = DispatchQueue(label: "app.peacegarden.time-lapse", qos: .userInteractive,
                                                          attributes: .concurrent)

    /// The scene the replay is drawn in. `PlantSceneView` hands itself over
    /// when it is given this player.
    func attach(_ stage: PlantSceneView.Coordinator) {
        guard self.stage !== stage else { return }
        if isShowing { finish() }
        self.stage = stage
    }

    /// Plays from the first sprouting to `record` as it is at `now`. A tap
    /// while a stop is still easing out plays again once it has.
    func play(_ record: PlantRecord, now: Date, reduceMotion: Bool) {
        guard stage != nil, !isPlaying else { return }
        if stopping != nil {
            replayAgain = (record, now, reduceMotion)
            return
        }
        run += 1
        let thisRun = run
        self.reduceMotion = reduceMotion
        isPlaying = true
        isShowing = true
        shownTime = -1
        stills = []

        // The materials are kept between runs of the same plant: a replay is
        // just another tap, and should not bake them again.
        let genome = record.genome
        let nodes: TimeLapseNodes
        if let kept = self.nodes, kept.genome.seed == genome.seed {
            nodes = kept
        } else {
            nodes = TimeLapseNodes(genome: genome)
        }
        self.nodes = nodes
        let lapse = TimeLapse(record: record, now: now)
        self.lapse = lapse
        stage?.beginTimeLapse()

        // The sprout, or every still, before the clock starts: the first
        // thing the replay shows has to be there when it is asked for.
        let first = reduceMotion
            ? (0..<TimeLapse.stillCount).map { Double($0) / Double(TimeLapse.stillCount - 1) }
            : [0]
        queue.async {
            let built = first.map { BuiltNode(node: nodes.node(for: lapse.growth(atProgress: $0))) }
            Task { @MainActor [weak self] in
                guard let self, self.run == thisRun, self.isPlaying else { return }
                if reduceMotion {
                    self.stills = built.map(\.node)
                } else if let sprout = built.first {
                    self.show(sprout.node, at: 0)
                }
                self.startClock()
                if !reduceMotion {
                    self.claimed = 0
                    self.finalClaimed = false
                    for _ in 0..<self.builders { self.buildNext(for: thisRun) }
                }
            }
        }
    }

    /// Stops a run part way, easing back to the plant as it is now.
    func stop() {
        guard isPlaying else { return }
        isPlaying = false
        let replay = Double(stage?.replayRoot.opacity ?? 1)
        let live = Double(stage?.livePlantOpacity ?? 0)
        stopping = (CACurrentMediaTime(), sky, replay, live)
    }

    /// Stops at once with nothing left on screen: the screen is going.
    func cancel() {
        replayAgain = nil
        finish()
    }

    // MARK: The clock

    private func startClock() {
        started = CACurrentMediaTime()
        link?.invalidate()
        let link = CADisplayLink(target: Ticker(self), selector: #selector(Ticker.tick(_:)))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60, preferred: 60)
        link.add(to: .main, forMode: .common)
        self.link = link
    }

    fileprivate func tick() {
        guard let lapse, let stage else { return finish() }
        let clock = CACurrentMediaTime()

        if let stopping {
            let since = clock - stopping.at
            sky = TimeLapse.sky(stoppedAt: stopping.sky, since: since)
            let half = TimeLapse.stopPlantFade / 2
            stage.replayRoot.opacity = CGFloat(stopping.replay * (1 - TimeLapse.smooth(since / half)))
            stage.livePlantOpacity = CGFloat(stopping.live
                + (1 - stopping.live) * TimeLapse.smooth((since - half * 0.6) / half))
            if since >= max(TimeLapse.stopSkyFade, TimeLapse.stopPlantFade) { finish() }
            return
        }

        let time = clock - started
        let frame = lapse.frame(at: time, reduceMotion: reduceMotion)
        sky = frame.sky
        stage.livePlantOpacity = CGFloat(frame.live)
        stage.replayRoot.opacity = CGFloat(frame.replay)
        if reduceMotion { showStills(frame) }

        if time >= TimeLapse.duration {
            finish()
        }
    }

    /// Under Reduce Motion: the still being held, and the next one dissolving
    /// in over it.
    private func showStills(_ frame: TimeLapse.Frame) {
        guard let stage, !stills.isEmpty else { return }
        let steps = Double(stills.count - 1)
        let held = min(stills.count - 1, Int((frame.progress * steps).rounded(.down)))
        let next = min(stills.count - 1, held + 1)
        let amount = next == held ? 0 : frame.progress * steps - Double(held)
        // The two overlap rather than meeting at half each, so the plant does
        // not thin to a ghost of itself in the middle of a dissolve.
        let incoming = TimeLapse.smooth(amount / 0.65)
        let outgoing = 1 - TimeLapse.smooth((amount - 0.35) / 0.65)
        for (index, still) in stills.enumerated() {
            let opacity: Double
            if index == held { opacity = outgoing }
            else if index == next { opacity = incoming }
            else { opacity = 0 }
            if still.parent == nil, opacity > 0 { stage.replayRoot.addChildNode(still) }
            if still.parent != nil, opacity <= 0 { still.removeFromParentNode() }
            still.opacity = CGFloat(opacity)
        }
    }

    // MARK: Building the plant

    /// Builds the plant for the moment it will be shown at, then the next.
    ///
    /// Each builder takes the moment its plant will be ready for, or the frame
    /// after the last one claimed if that is later, so builders working side
    /// by side share the frames between them rather than racing for one.
    private func buildNext(for thisRun: Int) {
        guard run == thisRun, isPlaying, let lapse, let nodes else { return }
        let ahead = buildTime * 1.1
        let time = max(CACurrentMediaTime() - started + ahead, claimed + 1.0 / 60)
        claimed = time
        guard time < TimeLapse.growthEnd else {
            // The last of the growing, built once: the plant as it is now.
            guard !finalClaimed else { return }
            finalClaimed = true
            queue.async {
                let built = BuiltNode(node: nodes.node(for: lapse.final))
                Task { @MainActor [weak self] in
                    guard let self, self.run == thisRun, self.isPlaying else { return }
                    self.show(built.node, at: TimeLapse.duration)
                }
            }
            return
        }
        let growth = lapse.frame(at: time).growth
        queue.async {
            let began = CACurrentMediaTime()
            let built = BuiltNode(node: nodes.node(for: growth))
            let took = CACurrentMediaTime() - began
            Task { @MainActor [weak self] in
                guard let self, self.run == thisRun else { return }
                self.buildTime = self.buildTime * 0.8 + took * 0.2
                self.show(built.node, at: time)
                self.buildNext(for: thisRun)
            }
        }
    }

    private func show(_ node: SCNNode, at time: TimeInterval) {
        guard let stage, time > shownTime else { return }
        shownTime = time
        for old in stage.replayRoot.childNodes { old.removeFromParentNode() }
        stage.replayRoot.addChildNode(node)
    }

    // MARK: Ending

    private func finish() {
        link?.invalidate()
        link = nil
        run += 1
        stopping = nil
        isPlaying = false
        isShowing = false
        sky = .absent
        stills = []
        stage?.endTimeLapse()
        if let again = replayAgain {
            replayAgain = nil
            play(again.record, now: again.now, reduceMotion: again.reduceMotion)
        }
    }

    /// The display link holds its target strongly; this holds the player
    /// weakly, so a screen that goes away takes its player with it.
    private final class Ticker: NSObject {
        weak var player: TimeLapsePlayer?
        init(_ player: TimeLapsePlayer) { self.player = player }
        @MainActor @objc func tick(_ link: CADisplayLink) {
            guard let player else { return link.invalidate() }
            player.tick()
        }
    }
}
