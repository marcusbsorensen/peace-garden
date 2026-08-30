import SwiftUI
import SceneKit
import SeedCore

/// The plant itself: full colour on black, turned by dragging.
///
/// The plant rotates rather than the camera, so the lighting stays put and
/// every side of the flower is lit the way the front is. Vertical drags tilt
/// the camera instead, within a range that keeps the plant upright.
struct PlantSceneView: UIViewRepresentable {
    let genome: Genome
    let growth: GrowthModel.State
    var isInteractive: Bool = true
    var autoRotates: Bool = true
    var onTap: (() -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(genome: genome, onTap: onTap)
    }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = PlantSceneBuilder.makeScene()
        view.backgroundColor = .black
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

        coordinator.rebuildIfNeeded(genome: genome, growth: growth)
        coordinator.setAutoRotation(autoRotates)
        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        context.coordinator.onTap = onTap
        context.coordinator.rebuildIfNeeded(genome: genome, growth: growth)
        context.coordinator.setAutoRotation(autoRotates)
    }

    static func dismantleUIView(_ uiView: SCNView, coordinator: Coordinator) {
        coordinator.plantPivot.removeAllActions()
    }

    final class Coordinator: NSObject {
        let plantPivot = SCNNode()
        let cameraRig = SCNNode()
        let cameraNode = PlantSceneBuilder.makeCameraNode()

        var onTap: (() -> Void)?

        private var genome: Genome
        private var currentKey: String = ""
        private var plantNode: SCNNode?
        private var yaw: Float = 0
        private var pitch: Float = 0
        private var autoRotating = false
        private var resumeWorkItem: DispatchWorkItem?

        private static let autoRotationKey = "turntable"
        private static let maximumPitch: Float = 0.55

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
            let framing = PlantSceneBuilder.framing(for: mesh)

            // Offset the plant so it turns about its own middle rather than
            // swinging around the origin at its base.
            node.position = SCNVector3(-framing.target.x, -framing.target.y, -framing.target.z)

            plantNode?.removeFromParentNode()
            plantPivot.addChildNode(node)
            plantNode = node

            plantPivot.position = framing.target
            cameraRig.position = framing.target
            cameraNode.position = SCNVector3(0, 0, framing.distance)
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
