import SwiftUI
import SceneKit
import SeedCore

/// The plant itself: full colour on black, turned by dragging.
///
/// The plant rotates rather than the camera, so the lighting stays put and
/// every side of the flower is lit the way the front is. Vertical drags tilt
/// the camera instead, within a range that keeps the plant upright.
struct PlantSceneView: UIViewRepresentable {
    /// The one arrival: a seed opening, and the camera drawing back off it.
    ///
    /// Passing this puts the view under someone else's direction for a few
    /// seconds — the camera stops framing the plant and is told where to be
    /// instead. Passing `nil` hands it back.
    struct Arrival: Equatable {
        /// `0` holds the camera in tight on the closed seed. `1` is the plant's
        /// own framing, which is where it stays for the rest of its life.
        var pullBack: Double
        /// `0` is a closed seed. `1` is two halves laid back and gone.
        var huskOpen: Double
    }

    let genome: Genome
    let growth: GrowthModel.State
    var isInteractive: Bool = true
    var autoRotates: Bool = true
    var arrival: Arrival?
    /// How the plant is drawn. See `StagePlantStyle`.
    var style: StagePlantStyle = .full
    /// The colour a monochrome or wireframe plant is drawn in.
    var tint: Color = .white
    /// Where the top of the chrome band sits, measured down from the top of the
    /// view.
    ///
    /// Given one, the plant is drawn into the space above it and stands on it.
    /// `nil` gives the plant the whole view and centres it there, which is what
    /// a screen with nothing written under the plant wants.
    var bandTop: CGFloat?
    var onTap: (() -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(genome: genome, onTap: onTap)
    }

    func makeUIView(context: Context) -> SCNView {
        let view = ResizingSceneView()
        view.onLayout = { [weak coordinator = context.coordinator] size in
            coordinator?.viewSizeChanged(to: size)
        }
        view.scene = PlantSceneBuilder.makeScene(palette: genome.palette)
        // Transparent: `StageBackdrop` behind this view paints the ground.
        view.backgroundColor = .clear
        view.isOpaque = false
        view.antialiasingMode = .multisampling4X
        view.preferredFramesPerSecond = 60
        view.rendersContinuously = false
        view.allowsCameraControl = false

        let coordinator = context.coordinator
        view.scene?.rootNode.addChildNode(coordinator.plantPivot)
        view.scene?.rootNode.addChildNode(coordinator.cameraRig)
        coordinator.cameraRig.addChildNode(coordinator.cameraNode)
        view.pointOfView = coordinator.cameraNode

        if isInteractive {
            let pan = UIPanGestureRecognizer(target: coordinator, action: #selector(Coordinator.handlePan(_:)))
            view.addGestureRecognizer(pan)
            let tap = UITapGestureRecognizer(target: coordinator, action: #selector(Coordinator.handleTap(_:)))
            view.addGestureRecognizer(tap)
        }

        coordinator.setStyle(style, tint: tint)
        coordinator.setBandTop(bandTop)
        coordinator.rebuildIfNeeded(genome: genome, growth: growth)
        coordinator.setArrival(arrival)
        coordinator.setAutoRotation(autoRotates)
        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        context.coordinator.onTap = onTap
        context.coordinator.setStyle(style, tint: tint)
        context.coordinator.setBandTop(bandTop)
        context.coordinator.rebuildIfNeeded(genome: genome, growth: growth)
        context.coordinator.setArrival(arrival)
        context.coordinator.setAutoRotation(autoRotates)
    }

    static func dismantleUIView(_ uiView: SCNView, coordinator: Coordinator) {
        coordinator.plantPivot.removeAllActions()
    }

    /// Reports its own size changes. An iPad rotating, or being resized in
    /// Split View, changes the shape of the viewport without anything in
    /// SwiftUI necessarily re-running, and the plant has to be re-framed.
    final class ResizingSceneView: SCNView {
        var onLayout: ((CGSize) -> Void)?

        override func layoutSubviews() {
            super.layoutSubviews()
            onLayout?(bounds.size)
        }
    }

    final class Coordinator: NSObject {
        let plantPivot = SCNNode()
        let cameraRig = SCNNode()
        let cameraNode = PlantSceneBuilder.makeCameraNode()

        var onTap: (() -> Void)?

        private var genome: Genome
        private var currentKey: String = ""
        private var plantNode: SCNNode?
        /// What the plant will grow into. Sets how far away the camera stands.
        private var reference: (min: SIMD3<Float>, max: SIMD3<Float>)?
        private var referenceSeed: SeedID?
        /// The plant as it is now. Sets what the camera aims at.
        private var meshBounds: (min: SIMD3<Float>, max: SIMD3<Float>)?
        private var viewSize: CGSize = .zero
        private var style: StagePlantStyle = .full
        private var tint: UIColor = .white
        /// Where the chrome band begins. See `PlantSceneView.bandTop`.
        private var bandTop: CGFloat?
        /// How far below the middle of the screen the plant settles, as a
        /// fraction of half the visible world height.
        ///
        /// About four per cent of the screen's height. Enough that the eye
        /// reads it as standing rather than floating, and not so much that a
        /// mature plant's crown runs off the top.
        ///
        /// Only for a screen with no band under the plant. Where there is one,
        /// the plant stands on it and the composition follows from that instead.
        static let settle: Float = 0.08

        /// How far above the band the plant stands, in points.
        ///
        /// A plant whose base met the top of its own name would read as one
        /// thing rather than two. This is the gap that keeps them apart, and it
        /// is small on purpose: the plant is still growing out of the foot of
        /// the screen, not hanging above it.
        static let clearance: CGFloat = 14

        /// The height of the screen the plant does not have, as a fraction.
        ///
        /// `nil` when nothing is written under the plant, and then the plant is
        /// framed into the whole view as it always was.
        private var standingLine: Float? {
            guard let bandTop, viewSize.height > 1 else { return nil }
            let foot = (viewSize.height - bandTop + Self.clearance) / viewSize.height
            // The ceiling is a guard against a band that has somehow eaten the
            // screen, not a design value.
            return Float(min(max(foot, 0), 0.5))
        }

        func setBandTop(_ y: CGFloat?) {
            guard y != bandTop else { return }
            bandTop = y
            applyFraming()
        }

        /// Set only while the seed is opening. `nil` the rest of the time, and
        /// the rest of the time is all but six seconds of the app's life.
        private var arrival: PlantSceneView.Arrival?
        private var husk: SeedHusk?
        private var yaw: Float = 0
        private var pitch: Float = 0
        private var autoRotating = false
        private var resumeWorkItem: DispatchWorkItem?

        private static let autoRotationKey = "turntable"
        private static let maximumPitch: Float = 0.55
        /// How far the husk has to have opened before there is a gap to see
        /// anything through.
        private static let seamOpens = 0.05

        init(genome: Genome, onTap: (() -> Void)?) {
            self.genome = genome
            self.onTap = onTap
            super.init()
        }

        /// Geometry is rebuilt only when the plant has visibly moved on.
        /// Growth ticks arrive far more often than they change anything, and
        /// rebuilding a mesh per tick would burn battery for nothing.
        func rebuildIfNeeded(genome: Genome, growth: GrowthModel.State) {
            let key = Self.key(genome: genome, growth: growth)
            guard key != currentKey else { return }
            currentKey = key
            self.genome = genome

            let mesh = PlantBuilder(genome: genome).mesh(growth: growth)
            let node = PlantSceneBuilder.node(for: mesh, palette: genome.palette)
            PlantSceneBuilder.restyle(node, as: style, tint: tint)

            plantNode?.removeFromParentNode()
            plantPivot.addChildNode(node)
            plantNode = node
            meshBounds = (mesh.minBounds, mesh.maxBounds)

            // Recomputed only when the plant itself changes, not on every
            // growth tick: it is one extra mesh, and it is the same mesh for
            // the whole life of that seed.
            if referenceSeed != genome.seed {
                reference = PlantSceneBuilder.matureBounds(for: genome)
                referenceSeed = genome.seed
            }
            applyFraming()
        }

        /// The husk hangs off the turntable rather than the scene root, so it
        /// turns with the plant that is coming out of it. Two things opening in
        /// the same place have to be one object or the seam shows.
        func setArrival(_ arrival: PlantSceneView.Arrival?) {
            guard arrival != self.arrival else { return }
            self.arrival = arrival

            if let arrival {
                let husk = self.husk ?? {
                    let made = SeedHusk(genome: genome)
                    plantPivot.addChildNode(made.node)
                    self.husk = made
                    return made
                }()
                husk.apply(open: arrival.huskOpen)
            } else {
                husk?.node.removeFromParentNode()
                husk = nil
            }
            // Kept out of sight until the seam has opened, rather than trusted
            // to be hidden inside the seed. `SkeletonBuilder` floors a stem at
            // a centimetre however far the arrival winds its height back, and a
            // genome is free to be tall and thin — for those the floored shoot
            // stood a few millimetres proud of a seed sized off the stem's
            // thickness, and a closed seed had a spike out of the top of it.
            // Sizing round that is arithmetic against two unrelated traits;
            // this is the same thing said once.
            plantNode?.isHidden = (arrival?.huskOpen ?? 1) < Self.seamOpens

            applyFraming()
        }

        /// Changing how the plant is drawn rebuilds it, because `restyle` is a
        /// one-way pass over the materials rather than something to undo.
        func setStyle(_ style: StagePlantStyle, tint: Color) {
            let colour = UIColor(tint)
            guard style != self.style || !colour.isEqual(self.tint) else { return }
            self.style = style
            self.tint = colour
            currentKey = ""
        }

        func viewSizeChanged(to size: CGSize) {
            guard size.width > 1, size.height > 1, size != viewSize else { return }
            viewSize = size
            applyFraming()
        }

        private func applyFraming() {
            guard let reference, let plantNode, let here = meshBounds, viewSize.height > 1 else { return }
            // Framed into the part of the view above the band, and standing on
            // it. It used to be framed into the whole view, on the argument
            // that the band is hidden most of the time and a plant sized to
            // clear a band that is not there is drawn small for no reason —
            // and the foot of the stem passing behind the band was read as
            // growing out of it. On a phone it read as a stem going through the
            // plant's own name, which is not the same thing.
            //
            // The band is measured rather than assumed, so this holds for a
            // name that has been turned off, a stage caption that has, and a
            // safe area that differs on every device.
            let standingLine = standingLine
            let framing = PlantSceneBuilder.framing(
                min: reference.min,
                max: reference.max,
                aspect: Float(viewSize.width / viewSize.height),
                reserved: standingLine ?? 0
            )
            // The plant stands on its own origin and turns about its stem,
            // which is what a plant does. Offsetting it to spin about the middle
            // of its bounding box swings a seedling in a wide circle around a
            // point somewhere above its own head.
            plantNode.position = SCNVector3Zero
            plantPivot.position = SCNVector3Zero

            // Two different plants decide the two halves of this. The DISTANCE
            // comes from the grown plant, which is what keeps a seedling small
            // in a large space instead of filling the screen. The AIM comes
            // from the plant as it is now, so its middle sits at the middle of
            // the screen and it opens outward in every direction from there as
            // it grows, rather than climbing the frame from the bottom.
            //
            // Aimed along the stem axis rather than at the mesh's own centre:
            // the plant turns about that axis, and a leaning plant whose centre
            // is off it would swing the whole frame round as the turntable went.
            let distance = framing.distance * 1.12
            let halfWorldHeight = distance * tan(PlantSceneBuilder.verticalHalfAngle)
            // **The base of the plant is put on the standing line**, and the
            // rest of the composition follows from that. Raising the aim is
            // what lowers the picture, so the aim is however far above the base
            // puts the base where it belongs.
            //
            // Anchored on the base rather than on the plant's middle, which is
            // what a plant does: a seedling stands on the same line a mature
            // plant stands on and climbs the frame as it grows, instead of the
            // whole picture sliding down around a middle that keeps moving.
            // The distance still comes from the grown plant, so a seedling is
            // small in a large space rather than filling it.
            //
            // With no band there is no line to stand on, and the plant is
            // centred and biased a little down — a subject at the exact centre
            // of a tall frame reads as high.
            let aim: Float
            if let standingLine {
                aim = here.min.y - (2 * standingLine - 1) * halfWorldHeight
            } else {
                aim = (here.min.y + here.max.y) * 0.5 + Self.settle * halfWorldHeight
            }

            guard let arrival else {
                cameraRig.position = SCNVector3(0, aim, 0)
                cameraNode.position = SCNVector3(0, 0, distance)
                return
            }

            // The seed sits on the plant's own origin, so the camera aims at
            // nothing and travels up to the plant's middle as the shoot rises.
            let seedDistance = PlantSceneBuilder.seedDistance(
                halfHeight: SeedHusk.halfHeight(for: genome)
            )
            let t = Float(Self.easeInOut(arrival.pullBack))

            // Interpolated in ratio rather than in metres. The camera has five
            // times as far to travel at the end as at the start, and a straight
            // lerp spends the first half of the move covering ground the eye
            // reads as barely moving, then lurches. A constant *rate of zoom*
            // is what reads as one steady draw back.
            cameraNode.position = SCNVector3(
                0, 0, seedDistance * pow(distance / seedDistance, t)
            )
            cameraRig.position = SCNVector3(0, aim * t, 0)
        }

        /// Smoothstep. The scene's own easing, kept here because SeedCore's is
        /// internal to it and this is the only place in the app that needs one.
        static func easeInOut(_ t: Double) -> Double {
            let x = min(max(t, 0), 1)
            return x * x * (3 - 2 * x)
        }

        func setAutoRotation(_ enabled: Bool) {
            guard enabled != autoRotating else { return }
            autoRotating = enabled
            if enabled {
                let turn = SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 90)
                plantPivot.runAction(.repeatForever(turn), forKey: Self.autoRotationKey)
            } else {
                plantPivot.removeAction(forKey: Self.autoRotationKey)
            }
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard gesture.state == .ended else { return }
            onTap?()
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let view = gesture.view else { return }
            switch gesture.state {
            case .began:
                resumeWorkItem?.cancel()
                // Take the angle the turntable has drifted to, so the plant
                // does not jump back when a drag starts.
                yaw = plantPivot.presentation.eulerAngles.y
                plantPivot.removeAction(forKey: Self.autoRotationKey)
                plantPivot.eulerAngles.y = yaw
                autoRotating = false
            case .changed:
                let translation = gesture.translation(in: view)
                gesture.setTranslation(.zero, in: view)
                yaw += Float(translation.x) * 0.006
                pitch = max(-Self.maximumPitch, min(Self.maximumPitch, pitch - Float(translation.y) * 0.004))
                plantPivot.eulerAngles.y = yaw
                cameraRig.eulerAngles.x = pitch
            case .ended, .cancelled:
                scheduleAutoRotationResume()
            default:
                break
            }
        }

        /// The turntable picks up again once the plant has been left alone.
        private func scheduleAutoRotationResume() {
            resumeWorkItem?.cancel()
            let item = DispatchWorkItem { [weak self] in
                self?.setAutoRotation(true)
            }
            resumeWorkItem = item
            DispatchQueue.main.asyncAfter(deadline: .now() + 4, execute: item)
        }

        private static func key(genome: Genome, growth: GrowthModel.State) -> String {
            func step(_ value: Double) -> Int { Int(value * 400) }
            return [
                genome.seed.hex,
                String(step(growth.heightScale)),
                String(step(growth.leafUnfurl)),
                String(step(growth.budSwell)),
                String(step(growth.bloomOpen))
            ].joined(separator: ":")
        }
    }
}
