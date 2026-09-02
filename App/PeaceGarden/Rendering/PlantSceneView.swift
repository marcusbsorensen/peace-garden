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
        coordinator.rebuildIfNeeded(genome: genome, growth: growth)
        coordinator.setArrival(arrival)
        coordinator.setAutoRotation(autoRotates)
        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        context.coordinator.onTap = onTap
        context.coordinator.setStyle(style, tint: tint)
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
        /// How far below the middle of the screen the plant settles, as a
        /// fraction of half the visible world height.
        ///
        /// About four per cent of the screen's height. Enough that the eye
        /// reads it as standing rather than floating, and not so much that a
        /// mature plant's crown runs off the top.
        static let settle: Float = 0.08

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
            // Framed into the whole view rather than into the part of it the
            // chrome leaves. The band is hidden most of the time, and a plant
            // sized to clear a band that is not there is a plant drawn small
            // for no reason. When the band *is* up, the foot of the stem passes
            // behind it, which is what growing out of it looks like.
            let framing = PlantSceneBuilder.framing(
                min: reference.min,
                max: reference.max,
                aspect: Float(viewSize.width / viewSize.height)
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
            // Centred on the screen, and then a little below its middle.
            //
            // It used to be centred on *what was left of* the screen once the
            // band at the foot had taken its share — the aim was lowered by the
            // band's height, which slides the picture up by exactly that much.
            // That is the right answer to the wrong question. **The band is
            // hidden most of the time**: it fades out after six seconds and
            // stays gone until somebody touches the screen, so the state it was
            // being composed for is the rarer one, and in the common state the
            // plant simply sat too high.
            //
            // Composed for the bare screen instead, and biased a little *down*
            // from its middle, because a subject placed at the exact centre of
            // a tall frame reads as high — and because this one is supposed to
            // be growing out of the foot of the screen, where its name and its
            // marks are, rather than hanging in the middle of it. Raising the
            // aim is what lowers the picture.
            let halfWorldHeight = distance * tan(PlantSceneBuilder.verticalHalfAngle)
            let aim = (here.min.y + here.max.y) * 0.5 + Self.settle * halfWorldHeight

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
