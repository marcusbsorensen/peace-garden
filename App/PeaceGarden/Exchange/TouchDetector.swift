import Foundation
import CoreMotion

/// Notices the moment two phones are tapped together.
///
/// iOS does not let a third-party app talk to another iPhone over NFC — the
/// tap-to-share gestures in iOS are system features, not something an app can
/// hook into. So the gesture is recognised rather than transported: the
/// accelerometer sees the knock, and the two phones tell each other about it
/// over the link they already have. See docs/EXCHANGE-PROTOCOL.md.
@MainActor
final class TouchDetector {
    /// Peak acceleration, in g above rest, that counts as a deliberate tap.
    /// Below this a pocket or a hand wave would trigger it; above it, people
    /// knock their phones together harder than they want to.
    private static let threshold = 1.6

    /// Ignore everything for a moment after a tap, so one knock is one event.
    private static let refractoryPeriod: TimeInterval = 0.8

    private let motionManager = CMMotionManager()
    private var lastTouch: Date?
    private var onTouch: (() -> Void)?

    var isAvailable: Bool { motionManager.isAccelerometerAvailable }

    func start(onTouch: @escaping () -> Void) {
        guard motionManager.isAccelerometerAvailable else { return }
        self.onTouch = onTouch
        motionManager.accelerometerUpdateInterval = 1.0 / 60.0
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self, let data else { return }
            let acceleration = data.acceleration
            let magnitude = sqrt(
                acceleration.x * acceleration.x
                    + acceleration.y * acceleration.y
                    + acceleration.z * acceleration.z
            )
            // Gravity reads as 1g at rest, so the impulse is the excess.
            let impulse = abs(magnitude - 1.0)
            guard impulse > Self.threshold else { return }

            let now = Date()
            if let lastTouch, now.timeIntervalSince(lastTouch) < Self.refractoryPeriod { return }
            self.lastTouch = now
            self.onTouch?()
        }
    }

    func stop() {
        motionManager.stopAccelerometerUpdates()
        onTouch = nil
        lastTouch = nil
    }
}
